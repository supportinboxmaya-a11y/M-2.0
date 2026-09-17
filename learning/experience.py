"""Experience replay: store run episodes, recall similar past work."""
import json
import re
import time

from enterprise._db import DB

_WORD = re.compile(r"[a-z0-9]{3,}")


def _tokens(text: str) -> set:
    return set(_WORD.findall((text or "").lower()))


class ExperienceReplay:
    def __init__(self, db: DB | None = None, path: str = "storage/learning.db"):
        self.db = db or DB(path)
        self.db.execute("""CREATE TABLE IF NOT EXISTS episodes(
            id INTEGER PRIMARY KEY AUTOINCREMENT, ts REAL, goal TEXT,
            steps TEXT, outcome TEXT, confidence REAL)""")

    def store(self, goal: str, steps: list, outcome: str,
              confidence: float = 0.0) -> None:
        self.db.execute(
            "INSERT INTO episodes(ts,goal,steps,outcome,confidence) VALUES(?,?,?,?,?)",
            (time.time(), goal[:500], json.dumps(steps)[:4000],
             outcome, float(confidence)))

    def similar(self, goal: str, limit: int = 3) -> list:
        """Past episodes ranked by goal token overlap (project knowledge retention)."""
        q = _tokens(goal)
        scored = []
        for row in self.db.query("SELECT * FROM episodes ORDER BY ts DESC LIMIT 500"):
            t = _tokens(row["goal"])
            overlap = len(q & t) / len(q | t) if (q | t) else 0.0
            if overlap > 0:
                row["similarity"] = round(overlap, 3)
                row["steps"] = json.loads(row["steps"])
                scored.append(row)
        scored.sort(key=lambda r: (r["similarity"], r["confidence"]), reverse=True)
        return scored[:limit]

    def success_rate(self, goal_keyword: str = "") -> dict:
        rows = self.db.query(
            "SELECT outcome, COUNT(*) n FROM episodes WHERE goal LIKE ? GROUP BY outcome",
            (f"%{goal_keyword}%",))
        counts = {r["outcome"]: r["n"] for r in rows}
        total = sum(counts.values())
        return {"total": total, "by_outcome": counts,
                "success_rate": round(counts.get("completed", 0) / total, 3)
                if total else None}

    def history(self, limit: int = 50) -> list:
        rows = self.db.query(
            "SELECT id, ts, goal, outcome, confidence FROM episodes "
            "ORDER BY ts DESC LIMIT ?", (limit,))
        return rows
