"""User feedback learning: record ratings, surface lessons."""
import json
import time

from enterprise._db import DB


class FeedbackStore:
    def __init__(self, db: DB | None = None, path: str = "storage/learning.db"):
        self.db = db or DB(path)
        self.db.execute("""CREATE TABLE IF NOT EXISTS feedback(
            id INTEGER PRIMARY KEY AUTOINCREMENT, ts REAL, goal TEXT,
            output TEXT, rating INTEGER, comment TEXT)""")

    def record(self, goal: str, output: str, rating: int,
               comment: str = "") -> None:
        """rating: 1 (good) | 0 (neutral) | -1 (bad)."""
        self.db.execute(
            "INSERT INTO feedback(ts,goal,output,rating,comment) VALUES(?,?,?,?,?)",
            (time.time(), goal[:500], (output or "")[:2000],
             max(-1, min(1, int(rating))), comment[:500]))

    def stats(self) -> dict:
        rows = self.db.query(
            "SELECT rating, COUNT(*) n FROM feedback GROUP BY rating")
        counts = {r["rating"]: r["n"] for r in rows}
        total = sum(counts.values())
        pos = counts.get(1, 0)
        return {"total": total, "positive": pos,
                "negative": counts.get(-1, 0),
                "satisfaction": round(pos / total, 3) if total else None}

    def lessons(self, limit: int = 10) -> list:
        """Recent negative feedback with comments = concrete lessons."""
        return self.db.query(
            "SELECT ts, goal, comment FROM feedback "
            "WHERE rating<0 AND comment!='' ORDER BY ts DESC LIMIT ?", (limit,))
