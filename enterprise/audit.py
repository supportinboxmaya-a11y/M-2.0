"""Audit log for every important action + billing hooks (cost events)."""
import json
import time

from ._db import DB


class AuditLog:
    def __init__(self, db: DB | None = None, path: str = "storage/enterprise.db"):
        self.db = db or DB(path)
        self.db.execute("""CREATE TABLE IF NOT EXISTS audit(
            id INTEGER PRIMARY KEY AUTOINCREMENT, ts REAL, actor TEXT,
            action TEXT, resource TEXT, detail TEXT, cost REAL DEFAULT 0)""")

    def record(self, actor: str, action: str, resource: str = "",
               detail: dict | None = None, cost: float = 0.0) -> None:
        self.db.execute(
            "INSERT INTO audit(ts,actor,action,resource,detail,cost) VALUES(?,?,?,?,?,?)",
            (time.time(), actor, action, resource,
             json.dumps(detail or {})[:2000], cost))

    def query(self, actor: str | None = None, action: str | None = None,
              limit: int = 100) -> list:
        sql, params = "SELECT * FROM audit WHERE 1=1", []
        if actor:
            sql += " AND actor=?"; params.append(actor)
        if action:
            sql += " AND action=?"; params.append(action)
        sql += " ORDER BY ts DESC LIMIT ?"; params.append(limit)
        return self.db.query(sql, tuple(params))

    # billing hooks
    def usage_summary(self, since_ts: float = 0.0) -> dict:
        rows = self.db.query(
            "SELECT actor, COUNT(*) n, SUM(cost) total FROM audit "
            "WHERE ts>=? GROUP BY actor", (since_ts,))
        return {"by_actor": rows,
                "total_cost": round(sum(r["total"] or 0 for r in rows), 6),
                "total_events": sum(r["n"] for r in rows)}
