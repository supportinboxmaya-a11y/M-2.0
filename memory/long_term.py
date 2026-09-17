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
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                version INTEGER DEFAULT 1
            )""")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_memory_type ON memories(memory_type)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_memory_time ON memories(timestamp)")
            # Older DBs created before the `version` column existed won't have
            # it — add it rather than requiring a fresh database.
            cols = [r["name"] for r in conn.execute("PRAGMA table_info(memories)").fetchall()]
            if "version" not in cols:
                conn.execute("ALTER TABLE memories ADD COLUMN version INTEGER DEFAULT 1")
            conn.execute("""CREATE TABLE IF NOT EXISTS memory_versions (
                memory_id TEXT NOT NULL,
                version INTEGER NOT NULL,
                content TEXT NOT NULL,
                metadata TEXT DEFAULT '{}',
                superseded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (memory_id, version)
            )""")

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
                conn.execute("DELETE FROM memory_versions WHERE memory_id = ?", (memory_id,))
        return True

    def update(self, memory_id: str, new_content: str, new_metadata: Dict = None) -> Optional[Dict]:
        """Edits a memory's content, keeping the previous version in
        memory_versions instead of just overwriting it — this is what
        'Memory Versioning' actually means: being able to see what a memory
        used to say, not just what it says now."""
        with self._lock:
            with self._get_conn() as conn:
                row = conn.execute("SELECT * FROM memories WHERE id = ?", (memory_id,)).fetchone()
                if not row:
                    return None
                current_version = row["version"] or 1
                conn.execute(
                    "INSERT INTO memory_versions (memory_id, version, content, metadata) VALUES (?, ?, ?, ?)",
                    (memory_id, current_version, row["content"], row["metadata"])
                )
                merged_metadata = json.loads(row["metadata"] or "{}")
                merged_metadata.update(new_metadata or {})
                conn.execute(
                    "UPDATE memories SET content = ?, metadata = ?, version = ? WHERE id = ?",
                    (new_content, json.dumps(merged_metadata), current_version + 1, memory_id)
                )
                updated = conn.execute("SELECT * FROM memories WHERE id = ?", (memory_id,)).fetchone()
        return self._row_to_dict(updated)

    def get_versions(self, memory_id: str) -> List[Dict]:
        """Full edit history for a memory, oldest first, including the
        current version at the end."""
        with self._lock:
            with self._get_conn() as conn:
                current = conn.execute("SELECT * FROM memories WHERE id = ?", (memory_id,)).fetchone()
                past = conn.execute(
                    "SELECT * FROM memory_versions WHERE memory_id = ? ORDER BY version ASC",
                    (memory_id,)
                ).fetchall()
        history = [{
            "version": r["version"], "content": r["content"],
            "metadata": json.loads(r["metadata"] or "{}"), "superseded_at": r["superseded_at"],
        } for r in past]
        if current:
            history.append({
                "version": current["version"] or 1, "content": current["content"],
                "metadata": json.loads(current["metadata"] or "{}"), "superseded_at": None,
            })
        return history

    def count(self) -> int:
        with self._lock:
            with self._get_conn() as conn:
                return conn.execute("SELECT COUNT(*) FROM memories").fetchone()[0]

    def get_analytics(self) -> Dict:
        """Type breakdown, importance distribution, and a 14-day creation
        trend — the 'total: N' that /memory/stats used to return alone
        wasn't much of an 'analytics' feature."""
        with self._lock:
            with self._get_conn() as conn:
                by_type_rows = conn.execute(
                    "SELECT memory_type, COUNT(*) as c FROM memories GROUP BY memory_type"
                ).fetchall()
                trend_rows = conn.execute(
                    "SELECT date(timestamp) as day, COUNT(*) as c FROM memories "
                    "WHERE timestamp >= date('now', '-14 days') GROUP BY day ORDER BY day"
                ).fetchall()
                all_rows = conn.execute("SELECT metadata FROM memories").fetchall()

        importances = []
        for r in all_rows:
            try:
                meta = json.loads(r["metadata"] or "{}")
                if isinstance(meta.get("importance"), (int, float)):
                    importances.append(meta["importance"])
            except (ValueError, TypeError):
                continue

        buckets = {"high": 0, "medium": 0, "low": 0}
        for score in importances:
            if score >= 0.7:
                buckets["high"] += 1
            elif score >= 0.4:
                buckets["medium"] += 1
            else:
                buckets["low"] += 1

        return {
            "by_type": {r["memory_type"]: r["c"] for r in by_type_rows},
            "importance_avg": round(sum(importances) / len(importances), 3) if importances else None,
            "importance_scored_count": len(importances),
            "importance_buckets": buckets,
            "created_by_day": {r["day"]: r["c"] for r in trend_rows},
        }

    def _row_to_dict(self, row) -> Dict:
        return {
            "id": row["id"],
            "content": row["content"],
            "type": row["memory_type"],
            "metadata": json.loads(row["metadata"] or "{}"),
            "timestamp": row["timestamp"],
            "version": row["version"] if "version" in row.keys() else 1,
        }
