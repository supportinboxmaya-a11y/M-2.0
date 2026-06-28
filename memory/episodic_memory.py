import json
import sqlite3
import uuid
from typing import List, Dict
from config.settings import DB_FILE

class EpisodicMemory:
    """Stores episodes — completed task runs with outcomes."""

    def __init__(self):
        self.db = DB_FILE
        self._init_db()

    def _init_db(self):
        conn = sqlite3.connect(self.db)
        conn.execute("""CREATE TABLE IF NOT EXISTS episodes (
            id TEXT PRIMARY KEY, goal TEXT, steps TEXT,
            result TEXT, success INTEGER, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)""")
        conn.commit()
        conn.close()

    def add_episode(self, goal: str, steps: List, result: str, success: bool):
        eid = str(uuid.uuid4())[:8]
        conn = sqlite3.connect(self.db)
        conn.execute("INSERT INTO episodes VALUES (?,?,?,?,?,CURRENT_TIMESTAMP)",
                    (eid, goal, json.dumps(steps), result, int(success)))
        conn.commit()
        conn.close()

    def get_similar(self, goal: str, limit: int = 3) -> List[Dict]:
        conn = sqlite3.connect(self.db)
        rows = conn.execute(
            "SELECT goal, steps, result, success FROM episodes WHERE goal LIKE ? ORDER BY timestamp DESC LIMIT ?",
            (f"%{goal[:30]}%", limit)).fetchall()
        conn.close()
        return [{"goal": r[0], "steps": json.loads(r[1]), "result": r[2], "success": bool(r[3])} for r in rows]
