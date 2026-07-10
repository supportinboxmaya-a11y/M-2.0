"""
Maya 2.0 - Scheduler (Persistent, Cron-based)
---------------------------------------------
Runs registered jobs on a cron schedule. Schedules are stored in SQLite
so they survive restarts, and each firing is dispatched through the
persistent TaskQueue — so a scheduled run is itself restart-proof.

Design:
- A schedule = {id, name, cron, job, args, enabled, last_run, next_run}.
  `job` must be a handler already registered on the TaskQueue.
- One async ticker wakes every `tick_seconds` (default 30s), finds
  schedules whose next_run has passed, and submits them to the queue.
- `catch_up=False` by default: if the server was down across several
  firings, only ONE run is triggered on recovery (not a burst). Missed
  slots are skipped and next_run is advanced.

No external scheduler service; stdlib + the existing queue only.
"""

import asyncio
import json
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from datetime import datetime
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR
from .cron import CronExpression

SCHED_DIR = STORAGE_DIR / "scheduler"
SCHED_DIR.mkdir(parents=True, exist_ok=True)
SCHED_DB = str(SCHED_DIR / "schedules.db")


class Scheduler:
    def __init__(self, task_queue, db_path: str = SCHED_DB,
                 tick_seconds: int = 30):
        self.queue = task_queue
        self.db = db_path
        self.tick_seconds = max(5, int(tick_seconds))
        self._lock = threading.Lock()
        self._running = False
        self._task = None
        self._init_db()

    # ── storage ───────────────────────────────────────────────────
    def _init_db(self):
        with self._conn() as c:
            c.execute("""CREATE TABLE IF NOT EXISTS schedules (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                cron TEXT NOT NULL,
                job TEXT NOT NULL,
                args TEXT DEFAULT '[]',
                kwargs TEXT DEFAULT '{}',
                enabled INTEGER DEFAULT 1,
                created_at REAL,
                last_run REAL,
                next_run REAL
            )""")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.db, check_same_thread=False, timeout=10)
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

    # ── management ────────────────────────────────────────────────
    def add(self, name: str, cron: str, job: str, args: Optional[list] = None,
            kwargs: Optional[dict] = None) -> Dict:
        """Create a schedule. Validates the cron and that the job handler
        is registered on the queue."""
        expr = CronExpression(cron)   # raises ValueError on bad cron
        if hasattr(self.queue, "_handlers") and job not in self.queue._handlers:
            raise ValueError(f"job '{job}' is not a registered queue handler")
        try:
            json.dumps(args or [])
            json.dumps(kwargs or {})
        except (TypeError, ValueError) as e:
            raise ValueError(f"args/kwargs must be JSON-serializable: {e}")

        sid = uuid.uuid4().hex[:12]
        now = datetime.now()
        nxt = expr.next_after(now)
        rec = {"id": sid, "name": name, "cron": cron, "job": job,
               "args": args or [], "kwargs": kwargs or {}, "enabled": True,
               "created_at": time.time(), "last_run": None,
               "next_run": nxt.timestamp() if nxt else None}
        with self._lock, self._conn() as c:
            c.execute("""INSERT INTO schedules
                (id, name, cron, job, args, kwargs, enabled, created_at,
                 last_run, next_run) VALUES (?,?,?,?,?,?,?,?,?,?)""",
                (sid, name, cron, job, json.dumps(args or []),
                 json.dumps(kwargs or {}), 1, rec["created_at"],
                 None, rec["next_run"]))
        return rec

    def remove(self, sid: str) -> bool:
        with self._lock, self._conn() as c:
            cur = c.execute("DELETE FROM schedules WHERE id = ?", (sid,))
            return cur.rowcount > 0

    def set_enabled(self, sid: str, enabled: bool) -> bool:
        with self._lock, self._conn() as c:
            cur = c.execute("UPDATE schedules SET enabled = ? WHERE id = ?",
                            (1 if enabled else 0, sid))
            return cur.rowcount > 0

    def list(self) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute("SELECT * FROM schedules ORDER BY created_at").fetchall()
        return [self._row(r) for r in rows]

    def get(self, sid: str) -> Optional[Dict]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM schedules WHERE id = ?",
                            (sid,)).fetchone()
        return self._row(row) if row else None

    # ── run loop ──────────────────────────────────────────────────
    async def start(self):
        if self._running:
            return
        self._running = True
        self._task = asyncio.create_task(self._loop(), name="scheduler")

    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()

    async def _loop(self):
        while self._running:
            try:
                await self.tick()
            except Exception:
                pass   # a bad schedule must never kill the ticker
            await asyncio.sleep(self.tick_seconds)

    async def tick(self, now: Optional[datetime] = None) -> List[str]:
        """Fire every due schedule once. Returns the list of task_ids
        submitted. Exposed (and awaitable) so tests can drive it."""
        now = now or datetime.now()
        now_ts = now.timestamp()
        submitted: List[str] = []
        with self._conn() as c:
            due = c.execute(
                "SELECT * FROM schedules WHERE enabled = 1 AND "
                "next_run IS NOT NULL AND next_run <= ?", (now_ts,)).fetchall()
        for row in due:
            rec = self._row(row)
            try:
                task_id = await self.queue.submit_job(
                    rec["job"], *rec["args"],
                    label=f"scheduled:{rec['name']}", **rec["kwargs"])
                submitted.append(task_id)
            except Exception:
                task_id = None
            # advance next_run past `now` (skip missed slots; no catch-up burst)
            expr = CronExpression(rec["cron"])
            nxt = expr.next_after(now)
            with self._lock, self._conn() as c:
                c.execute("UPDATE schedules SET last_run = ?, next_run = ? "
                          "WHERE id = ?",
                          (now_ts, nxt.timestamp() if nxt else None, rec["id"]))
        return submitted

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _row(row) -> Dict:
        return {
            "id": row["id"], "name": row["name"], "cron": row["cron"],
            "job": row["job"], "args": json.loads(row["args"] or "[]"),
            "kwargs": json.loads(row["kwargs"] or "{}"),
            "enabled": bool(row["enabled"]), "created_at": row["created_at"],
            "last_run": row["last_run"], "next_run": row["next_run"],
        }
