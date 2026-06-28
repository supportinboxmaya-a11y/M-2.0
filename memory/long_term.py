"""
Maya 2.0 - Long Term Memory (Thread-safe)
------------------------------------------
SQLite based persistent memory with connection pooling.
"""

import sqlite3
import json
import uuid
import threading
from typing import List, Dict, Optional
from contextlib import contextmanager
from config.settings import DB_FILE


class LongTermMemory:
    """Thread-safe SQLite memory with connection pooling."""

    def __init__(self):
        self.db = DB_FILE
        self._lock = threading.Lock()
        self._init_db()

    def _init_db(self):
        with self._get_conn() as conn:
            conn.execute("""CREATE TABLE IF NOT EXISTS memories (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                memory_type TEXT DEFAULT 'general',
                metadata TEXT DEFAULT '{}',
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )""")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_memory_type ON memories(memory_type)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_memory_time ON memories(timestamp)")

    @contextmanager
    def _get_conn(self):
        """Thread-safe connection context manager."""
        conn = sqlite3.connect(self.db, check_same_thread=False, timeout=10)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()

    def add(self, content: str, memory_type: str = "general", metadata: Dict = None) -> str:
        mid = str(uuid.uuid4())[:12]
        with self._lock:
            with self._get_conn() as conn:
                conn.execute(
                    "INSERT INTO memories (id, content, memory_type, metadata) VALUES (?, ?, ?, ?)",
                    (mid, content, memory_type, json.dumps(metadata or {}))
                )
        return mid

    def search(self, query: str, limit: int = 5, memory_type: str = None) -> List[Dict]:
        with self._lock:
            with self._get_conn() as conn:
                if memory_type:
                    rows = conn.execute(
                        "SELECT * FROM memories WHERE content LIKE ? AND memory_type = ? ORDER BY timestamp DESC LIMIT ?",
                        (f"%{query}%", memory_type, limit)
                    ).fetchall()
                else:
                    rows = conn.execute(
                        "SELECT * FROM memories WHERE content LIKE ? ORDER BY timestamp DESC LIMIT ?",
                        (f"%{query}%", limit)
                    ).fetchall()
        return [self._row_to_dict(r) for r in rows]

    def get_all(self, limit: int = 50, memory_type: str = None) -> List[Dict]:
        with self._lock:
            with self._get_conn() as conn:
                if memory_type:
                    rows = conn.execute(
                        "SELECT * FROM memories WHERE memory_type = ? ORDER BY timestamp DESC LIMIT ?",
                        (memory_type, limit)
                    ).fetchall()
                else:
                    rows = conn.execute(
                        "SELECT * FROM memories ORDER BY timestamp DESC LIMIT ?",
                        (limit,)
                    ).fetchall()
        return [self._row_to_dict(r) for r in rows]

    def delete(self, memory_id: str) -> bool:
        with self._lock:
            with self._get_conn() as conn:
                conn.execute("DELETE FROM memories WHERE id = ?", (memory_id,))
        return True

    def count(self) -> int:
        with self._lock:
            with self._get_conn() as conn:
                return conn.execute("SELECT COUNT(*) FROM memories").fetchone()[0]

    def _row_to_dict(self, row) -> Dict:
        return {
            "id": row["id"],
            "content": row["content"],
            "type": row["memory_type"],
            "metadata": json.loads(row["metadata"] or "{}"),
            "timestamp": row["timestamp"]
        }
