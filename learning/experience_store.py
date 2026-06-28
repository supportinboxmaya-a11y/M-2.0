"""
Maya 2.0 - Experience Store (Fixed)
"""

import sqlite3
import json
import uuid
import threading
from typing import List, Dict
from contextlib import contextmanager
from config.settings import DB_FILE


class ExperienceStore:
    def __init__(self):
        self.db = DB_FILE
        self._lock = threading.Lock()
        self._init_db()

    def _init_db(self):
        try:
            with self._get_conn() as conn:
                conn.execute("""CREATE TABLE IF NOT EXISTS experiences (
                    id TEXT PRIMARY KEY,
                    task TEXT NOT NULL,
                    lesson TEXT DEFAULT '',
                    pattern TEXT DEFAULT '',
                    future_tip TEXT DEFAULT '',
                    success INTEGER DEFAULT 0,
                    metadata TEXT DEFAULT '{}',
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
                )""")
                conn.execute("CREATE INDEX IF NOT EXISTS idx_exp_task ON experiences(task)")
        except Exception as e:
            print(f"ExperienceStore init warning: {e}")

    @contextmanager
    def _get_conn(self):
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

    def add(self, task: str, lesson: str = "", pattern: str = "", 
            future_tip: str = "", success: bool = True, metadata: Dict = None) -> str:
        try:
            eid = str(uuid.uuid4())[:12]
            with self._lock:
                with self._get_conn() as conn:
                    conn.execute(
                        "INSERT INTO experiences (id, task, lesson, pattern, future_tip, success, metadata) VALUES (?,?,?,?,?,?,?)",
                        (eid, task[:500], lesson[:500], pattern[:200], future_tip[:200], int(success), json.dumps(metadata or {}))
                    )
            return eid
        except Exception as e:
            print(f"ExperienceStore.add warning: {e}")
            return ""

    def get_relevant(self, query: str, limit: int = 3) -> List[Dict]:
        try:
            with self._lock:
                with self._get_conn() as conn:
                    rows = conn.execute(
                        "SELECT task, lesson, pattern, future_tip, success FROM experiences WHERE task LIKE ? ORDER BY timestamp DESC LIMIT ?",
                        (f"%{query[:50]}%", limit)
                    ).fetchall()
            return [{"task": r["task"], "lesson": r["lesson"], "pattern": r["pattern"], "tip": r["future_tip"], "success": bool(r["success"])} for r in rows]
        except Exception as e:
            print(f"ExperienceStore.get_relevant warning: {e}")
            return []

    def get_all(self, limit: int = 50) -> List[Dict]:
        try:
            with self._lock:
                with self._get_conn() as conn:
                    rows = conn.execute(
                        "SELECT * FROM experiences ORDER BY timestamp DESC LIMIT ?", (limit,)
                    ).fetchall()
            return [dict(r) for r in rows]
        except:
            return []
