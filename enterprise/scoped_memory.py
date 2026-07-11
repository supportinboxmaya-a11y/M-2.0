"""
Maya 2.0 - Scoped Workspace Memory
----------------------------------
A per-workspace memory store. Each workspace scope ("default",
"user:<uid>", "team:<team_id>") gets its own isolated set of notes, so
users don't see each other's memory and teams get a genuinely shared
space.

This lives alongside the existing global memory system rather than
replacing it: single-user flows keep using MemoryManager unchanged,
while multi-user flows route through here. Storage is one SQLite table
keyed by scope (thread-safe, WAL), matching the rest of the codebase.
"""

import json
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR

WS_DIR = STORAGE_DIR / "workspaces"
WS_DIR.mkdir(parents=True, exist_ok=True)
WS_DB = str(WS_DIR / "workspace_memory.db")


class ScopedMemory:
    """Workspace-partitioned memory (add / search / list / delete / stats)."""

    def __init__(self, db_path: str = WS_DB):
        self.db = db_path
        self._lock = threading.Lock()
        self._init_db()

    def _init_db(self):
        with self._conn() as c:
            c.execute("""CREATE TABLE IF NOT EXISTS ws_memories (
                id TEXT PRIMARY KEY,
                scope TEXT NOT NULL,
                content TEXT NOT NULL,
                author TEXT DEFAULT '',
                memory_type TEXT DEFAULT 'general',
                metadata TEXT DEFAULT '{}',
                created_at REAL
            )""")
            c.execute("CREATE INDEX IF NOT EXISTS idx_ws_scope "
                      "ON ws_memories(scope)")
            c.execute("CREATE INDEX IF NOT EXISTS idx_ws_scope_type "
                      "ON ws_memories(scope, memory_type)")

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

    # ── writes ────────────────────────────────────────────────────
    def add(self, scope: str, content: str, author: str = "",
            memory_type: str = "general", metadata: Optional[Dict] = None) -> str:
        content = (content or "").strip()
        if not content:
            raise ValueError("content is required")
        mid = uuid.uuid4().hex[:12]
        with self._lock, self._conn() as c:
            c.execute("INSERT INTO ws_memories "
                      "(id, scope, content, author, memory_type, metadata, created_at)"
                      " VALUES (?,?,?,?,?,?,?)",
                      (mid, scope, content, author, memory_type,
                       json.dumps(metadata or {}), time.time()))
        return mid

    def delete(self, scope: str, memory_id: str) -> bool:
        with self._lock, self._conn() as c:
            cur = c.execute("DELETE FROM ws_memories WHERE id=? AND scope=?",
                            (memory_id, scope))
            return cur.rowcount > 0

    def clear_scope(self, scope: str) -> int:
        with self._lock, self._conn() as c:
            cur = c.execute("DELETE FROM ws_memories WHERE scope=?", (scope,))
            return cur.rowcount

    # ── reads (always scoped — never leaks across workspaces) ─────
    def search(self, scope: str, query: str, limit: int = 10) -> List[Dict]:
        query = (query or "").strip()
        with self._conn() as c:
            if query:
                rows = c.execute(
                    "SELECT * FROM ws_memories WHERE scope=? AND content LIKE ? "
                    "ORDER BY created_at DESC LIMIT ?",
                    (scope, f"%{query}%", limit)).fetchall()
            else:
                rows = c.execute(
                    "SELECT * FROM ws_memories WHERE scope=? "
                    "ORDER BY created_at DESC LIMIT ?", (scope, limit)).fetchall()
        return [self._row(r) for r in rows]

    def list(self, scope: str, limit: int = 100) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM ws_memories WHERE scope=? "
                "ORDER BY created_at DESC LIMIT ?", (scope, limit)).fetchall()
        return [self._row(r) for r in rows]

    def get(self, scope: str, memory_id: str) -> Optional[Dict]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM ws_memories WHERE id=? AND scope=?",
                            (memory_id, scope)).fetchone()
        return self._row(row) if row else None

    def stats(self, scope: str) -> Dict:
        with self._conn() as c:
            total = c.execute("SELECT COUNT(*) AS n FROM ws_memories "
                              "WHERE scope=?", (scope,)).fetchone()["n"]
            by_type = c.execute(
                "SELECT memory_type, COUNT(*) AS n FROM ws_memories "
                "WHERE scope=? GROUP BY memory_type", (scope,)).fetchall()
        return {"scope": scope, "total": total,
                "by_type": {r["memory_type"]: r["n"] for r in by_type}}

    @staticmethod
    def _row(row) -> Dict:
        return {"id": row["id"], "scope": row["scope"],
                "content": row["content"], "author": row["author"],
                "memory_type": row["memory_type"],
                "metadata": json.loads(row["metadata"] or "{}"),
                "created_at": row["created_at"]}
