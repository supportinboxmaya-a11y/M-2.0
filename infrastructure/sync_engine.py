"""
Maya 2.0 - Offline Sync Engine
------------------------------
Makes the mobile/PWA client work offline: while disconnected, the client
queues user actions locally; when back online it POSTs the batch here and
we replay them in order, idempotently.

Idempotency is the crux — a flaky mobile connection means the same batch
may be sent twice. Every queued action carries a client-generated `op_id`;
we record processed op_ids so replays are deduped and never double-apply.

An action = {op_id, type, payload, client_ts}. Handlers for each `type`
are registered by the caller (e.g. "add_memory", "create_prompt"), so the
engine stays decoupled from the rest of the app. Unknown types are
rejected, not silently dropped.

Storage: SQLite (WAL). We keep a bounded log of applied op_ids plus the
result/status of each, so the client can reconcile what actually landed.
"""

import json
import sqlite3
import threading
import time
from contextlib import contextmanager
from typing import Callable, Dict, List, Optional

from config.settings import STORAGE_DIR

SYNC_DIR = STORAGE_DIR / "sync"
SYNC_DIR.mkdir(parents=True, exist_ok=True)
SYNC_DB = str(SYNC_DIR / "sync.db")


class SyncEngine:
    """Replays offline-queued client actions idempotently."""

    def __init__(self, db_path: str = SYNC_DB):
        self.db = db_path
        self._lock = threading.Lock()
        self._handlers: Dict[str, Callable] = {}
        self._init_db()

    def _init_db(self):
        with self._conn() as c:
            c.execute("""CREATE TABLE IF NOT EXISTS sync_ops (
                op_id TEXT PRIMARY KEY,
                user TEXT DEFAULT '',
                type TEXT NOT NULL,
                status TEXT NOT NULL,          -- applied | failed | rejected
                result TEXT,
                client_ts REAL,
                applied_at REAL
            )""")
            c.execute("CREATE INDEX IF NOT EXISTS idx_sync_user "
                      "ON sync_ops(user, applied_at)")

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

    # ── handler registry ──────────────────────────────────────────
    def register(self, action_type: str, handler: Callable) -> None:
        """handler(payload, user) -> result. May be sync or async-free.
        Raising inside a handler marks that op 'failed' (others continue)."""
        self._handlers[action_type] = handler

    def known_types(self) -> List[str]:
        return sorted(self._handlers)

    # ── core: apply a batch ───────────────────────────────────────
    def apply_batch(self, actions: List[Dict], user: str = "") -> Dict:
        """Replay a batch of queued actions in order. Returns a per-op
        report. Already-applied op_ids are skipped (idempotent)."""
        results = []
        applied = failed = skipped = rejected = 0

        for action in actions or []:
            op_id = (action.get("op_id") or "").strip()
            atype = (action.get("type") or "").strip()
            if not op_id:
                results.append({"op_id": None, "status": "rejected",
                                "error": "missing op_id"})
                rejected += 1
                continue

            existing = self._get_op(op_id)
            if existing is not None:
                results.append({"op_id": op_id, "status": "skipped",
                                "previous": existing["status"]})
                skipped += 1
                continue

            handler = self._handlers.get(atype)
            if handler is None:
                self._record(op_id, user, atype, "rejected",
                             {"error": f"unknown action type '{atype}'"},
                             action.get("client_ts"))
                results.append({"op_id": op_id, "status": "rejected",
                                "error": f"unknown action type '{atype}'"})
                rejected += 1
                continue

            try:
                res = handler(action.get("payload") or {}, user)
                self._record(op_id, user, atype, "applied", res,
                             action.get("client_ts"))
                results.append({"op_id": op_id, "status": "applied",
                                "result": res})
                applied += 1
            except Exception as e:
                self._record(op_id, user, atype, "failed", {"error": str(e)},
                             action.get("client_ts"))
                results.append({"op_id": op_id, "status": "failed",
                                "error": str(e)})
                failed += 1

        return {"summary": {"applied": applied, "failed": failed,
                            "skipped": skipped, "rejected": rejected,
                            "total": len(actions or [])},
                "results": results,
                "server_ts": time.time()}

    # ── reads ─────────────────────────────────────────────────────
    def _get_op(self, op_id: str) -> Optional[Dict]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM sync_ops WHERE op_id=?",
                            (op_id,)).fetchone()
        return dict(row) if row else None

    def status(self, op_id: str) -> Optional[Dict]:
        op = self._get_op(op_id)
        if op and op.get("result"):
            try:
                op["result"] = json.loads(op["result"])
            except Exception:
                pass
        return op

    def recent(self, user: str = "", limit: int = 50) -> List[Dict]:
        with self._conn() as c:
            if user:
                rows = c.execute("SELECT op_id, type, status, applied_at "
                                 "FROM sync_ops WHERE user=? "
                                 "ORDER BY applied_at DESC LIMIT ?",
                                 (user, limit)).fetchall()
            else:
                rows = c.execute("SELECT op_id, type, status, applied_at "
                                 "FROM sync_ops ORDER BY applied_at DESC "
                                 "LIMIT ?", (limit,)).fetchall()
        return [dict(r) for r in rows]

    # ── writes ────────────────────────────────────────────────────
    def _record(self, op_id: str, user: str, atype: str, status: str,
                result, client_ts) -> None:
        with self._lock, self._conn() as c:
            c.execute("INSERT OR IGNORE INTO sync_ops "
                      "(op_id, user, type, status, result, client_ts, applied_at) "
                      "VALUES (?,?,?,?,?,?,?)",
                      (op_id, user, atype, status,
                       json.dumps(result) if result is not None else None,
                       client_ts, time.time()))
