"""
Maya 2.0 - Persistent Background Task Queue
-------------------------------------------
An asyncio task queue whose status/history AND pending work survive a
server restart or crash.

Why a job registry?
    Python coroutines can't be serialized, so we can't just pickle a
    submitted task. Instead callers register named job handlers once at
    startup; only the job name + JSON-safe args are persisted. On
    restart, unfinished tasks are re-enqueued and run again by looking
    the handler up by name. This is the same pattern Celery/RQ use.

Storage: SQLite (thread-safe, WAL), matching memory/long_term.py and
the RAG index. Zero external services.

Backward compatible:
    - submit(coro_fn, ...) still works for fire-and-forget in-process
      tasks (not persisted across restart, exactly as before).
    - submit_job(name, ...) is the new persistent path.
    - status(), all_status(), start() keep their old signatures.
"""

import asyncio
import json
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from typing import Any, Callable, Dict, Optional

from config.settings import STORAGE_DIR

QUEUE_DIR = STORAGE_DIR / "queue"
QUEUE_DIR.mkdir(parents=True, exist_ok=True)
QUEUE_DB = str(QUEUE_DIR / "tasks.db")

_TERMINAL = ("done", "failed", "cancelled")


class TaskQueue:
    def __init__(self, workers: int = 2, max_history: int = 200,
                 db_path: str = QUEUE_DB, persist: bool = True):
        self._queue: asyncio.Queue = asyncio.Queue()
        self._status: Dict[str, dict] = {}      # in-memory mirror (fast reads)
        self._workers = workers
        self._max_history = max_history
        self._running = False
        self._persist = persist
        self._db = db_path
        self._lock = threading.Lock()
        self._handlers: Dict[str, Callable] = {}
        if self._persist:
            self._init_db()

    # ── persistence layer ─────────────────────────────────────────
    def _init_db(self):
        with self._conn() as c:
            c.execute("""CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                job TEXT,                         -- registered handler name
                args TEXT DEFAULT '[]',           -- JSON args
                kwargs TEXT DEFAULT '{}',         -- JSON kwargs
                state TEXT NOT NULL,              -- queued|running|done|failed|cancelled
                result TEXT,
                error TEXT,
                attempts INTEGER DEFAULT 0,
                queued_at REAL, started_at REAL, finished_at REAL
            )""")
            c.execute("CREATE INDEX IF NOT EXISTS idx_task_state "
                      "ON tasks(state)")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self._db, check_same_thread=False, timeout=10)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def _save(self, task_id: str, rec: dict):
        if not self._persist:
            return
        with self._lock, self._conn() as c:
            c.execute("""INSERT INTO tasks
                (id, name, job, args, kwargs, state, result, error, attempts,
                 queued_at, started_at, finished_at)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
                ON CONFLICT(id) DO UPDATE SET
                    state=excluded.state, result=excluded.result,
                    error=excluded.error, attempts=excluded.attempts,
                    started_at=excluded.started_at,
                    finished_at=excluded.finished_at""",
                (task_id, rec.get("name", "task"), rec.get("job"),
                 json.dumps(rec.get("args", [])),
                 json.dumps(rec.get("kwargs", {})),
                 rec.get("state", "queued"),
                 json.dumps(rec.get("result")) if rec.get("result") is not None else None,
                 rec.get("error"), rec.get("attempts", 0),
                 rec.get("queued_at"), rec.get("started_at"),
                 rec.get("finished_at")))

    # ── job registry ──────────────────────────────────────────────
    def register(self, name: str, handler: Callable) -> None:
        """Register a named async handler that persistent jobs can call."""
        self._handlers[name] = handler

    # ── lifecycle ─────────────────────────────────────────────────
    async def start(self) -> None:
        if self._running:
            return
        self._running = True
        if self._persist:
            await self._recover()
        for i in range(self._workers):
            asyncio.create_task(self._worker(i), name=f"taskq-worker-{i}")

    async def _recover(self) -> None:
        """Re-enqueue jobs that were queued/running when we stopped.

        Only jobs with a registered handler can be resumed; orphans
        (in-process submit() tasks, or jobs whose handler no longer
        exists) are marked failed so they don't hang forever."""
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM tasks WHERE state IN ('queued','running')"
            ).fetchall()
        for r in rows:
            rec = self._row_to_rec(r)
            job = rec.get("job")
            if job and job in self._handlers:
                rec["state"] = "queued"
                rec["started_at"] = None
                self._status[r["id"]] = rec
                self._save(r["id"], rec)
                await self._queue.put((r["id"], None, None, None))
            else:
                rec["state"] = "failed"
                rec["error"] = ("interrupted by restart; no registered handler "
                                "to resume" if not job else
                                f"interrupted by restart; handler '{job}' "
                                "not registered")
                rec["finished_at"] = time.time()
                self._status[r["id"]] = rec
                self._save(r["id"], rec)

    # ── submit paths ──────────────────────────────────────────────
    async def submit(self, coro_fn, *args, name: str = "task", **kwargs) -> str:
        """Fire-and-forget in-process task (NOT persisted across restart).
        Kept for backward compatibility."""
        task_id = uuid.uuid4().hex[:12]
        rec = {"name": name, "job": None, "state": "queued",
               "queued_at": time.time(), "error": None, "result": None,
               "attempts": 0, "args": [], "kwargs": {}}
        self._status[task_id] = rec
        self._save(task_id, rec)
        self._trim()
        await self._queue.put((task_id, coro_fn, args, kwargs))
        return task_id

    async def submit_job(self, name: str, *args, label: str = None,
                         **kwargs) -> str:
        """Submit a persistent job by registered handler name. Survives
        restart: name + JSON args are stored and re-run on recovery."""
        if name not in self._handlers:
            raise ValueError(f"No registered job handler named '{name}'")
        try:
            json.dumps(args)
            json.dumps(kwargs)
        except (TypeError, ValueError) as e:
            raise ValueError(f"Job args must be JSON-serializable: {e}")
        task_id = uuid.uuid4().hex[:12]
        rec = {"name": label or name, "job": name, "state": "queued",
               "queued_at": time.time(), "error": None, "result": None,
               "attempts": 0, "args": list(args), "kwargs": kwargs}
        self._status[task_id] = rec
        self._save(task_id, rec)
        self._trim()
        await self._queue.put((task_id, None, args, kwargs))
        return task_id

    def cancel(self, task_id: str) -> bool:
        """Cancel a task that hasn't started yet."""
        rec = self._status.get(task_id)
        if not rec or rec["state"] != "queued":
            return False
        rec.update(state="cancelled", finished_at=time.time())
        self._save(task_id, rec)
        return True

    # ── worker ────────────────────────────────────────────────────
    async def _worker(self, n: int) -> None:
        while True:
            task_id, fn, args, kwargs = await self._queue.get()
            rec = self._status.get(task_id, {})
            if rec.get("state") == "cancelled":
                self._queue.task_done()
                continue
            rec.update(state="running", started_at=time.time(),
                       attempts=rec.get("attempts", 0) + 1)
            self._save(task_id, rec)
            try:
                if fn is None:                      # persistent job path
                    job = rec.get("job")
                    handler = self._handlers.get(job)
                    if handler is None:
                        raise RuntimeError(f"handler '{job}' not registered")
                    call_args = args if args is not None else rec.get("args", [])
                    call_kwargs = kwargs if kwargs is not None else rec.get("kwargs", {})
                    result = await handler(*call_args, **call_kwargs)
                else:                               # in-process task path
                    result = await fn(*args, **kwargs)
                rec.update(state="done", result=result, finished_at=time.time())
            except Exception as e:
                rec.update(state="failed", error=str(e), finished_at=time.time())
            finally:
                self._save(task_id, rec)
                self._queue.task_done()

    # ── reads ─────────────────────────────────────────────────────
    def status(self, task_id: str) -> Optional[dict]:
        rec = self._status.get(task_id)
        if rec is not None:
            return rec
        if self._persist:
            with self._conn() as c:
                row = c.execute("SELECT * FROM tasks WHERE id = ?",
                                (task_id,)).fetchone()
                return self._row_to_rec(row) if row else None
        return None

    def all_status(self) -> dict:
        if self._persist:
            with self._conn() as c:
                rows = c.execute("SELECT * FROM tasks ORDER BY queued_at DESC "
                                 "LIMIT ?", (self._max_history,)).fetchall()
            return {r["id"]: self._row_to_rec(r) for r in rows}
        return dict(self._status)

    def stats(self) -> dict:
        counts = {"queued": 0, "running": 0, "done": 0,
                  "failed": 0, "cancelled": 0}
        src = self.all_status()
        for rec in src.values():
            counts[rec.get("state", "queued")] = \
                counts.get(rec.get("state", "queued"), 0) + 1
        return {"persist": self._persist, "workers": self._workers,
                "registered_jobs": sorted(self._handlers), "counts": counts}

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _row_to_rec(row) -> dict:
        return {
            "name": row["name"], "job": row["job"], "state": row["state"],
            "result": json.loads(row["result"]) if row["result"] else None,
            "error": row["error"], "attempts": row["attempts"],
            "args": json.loads(row["args"] or "[]"),
            "kwargs": json.loads(row["kwargs"] or "{}"),
            "queued_at": row["queued_at"], "started_at": row["started_at"],
            "finished_at": row["finished_at"],
        }

    def _trim(self) -> None:
        # trim in-memory mirror
        if len(self._status) > self._max_history:
            done = [k for k, v in self._status.items()
                    if v["state"] in _TERMINAL]
            for k in done[: len(self._status) - self._max_history]:
                self._status.pop(k, None)
        # trim persisted history
        if self._persist:
            with self._lock, self._conn() as c:
                c.execute("""DELETE FROM tasks WHERE id IN (
                    SELECT id FROM tasks WHERE state IN ('done','failed','cancelled')
                    ORDER BY finished_at ASC
                    LIMIT MAX(0, (SELECT COUNT(*) FROM tasks) - ?))""",
                    (self._max_history * 3,))
