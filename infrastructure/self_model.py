"""Phase 39 — Self-model.

Maya's persistent model of ITSELF: what it can do, how well it performs
each kind of task, and where its weaknesses are. Planning consults this
before choosing an approach; the owner can inspect it at any time.

Persisted in its own SQLite store so identity survives restarts.
Pure introspection — no execution, no external effects.
"""
import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from pathlib import Path
from typing import Dict, List, Optional

from maya_logging.logger import get_logger

log = get_logger("selfmodel")

STORAGE_DIR = Path(os.getenv("STORAGE_DIR", "storage"))
SELF_MODEL_DIR = STORAGE_DIR / "self_model"
SELF_MODEL_DIR.mkdir(parents=True, exist_ok=True)
SELF_MODEL_DB = str(SELF_MODEL_DIR / "self_model.db")

# Keyword -> task-type bucket. Ordered: first match wins.
_TASK_TYPES = [
    ("deploy",   ["deploy", "hosting", "publish", "release", "ship"]),
    ("docker",   ["docker", "container", "image"]),
    ("server",   ["ssh", "vps", "server", "systemctl", "journalctl", "nginx"]),
    ("web",      ["scrape", "website", "browser", "http", "url", "crawl"]),
    ("code",     ["code", "build", "compile", "refactor", "bug", "script", "app"]),
    ("research", ["research", "analyze", "market", "compare", "summarize",
                  "investigate"]),
    ("file",     ["csv", "document", "pdf", "spreadsheet", "xlsx"]),
    ("api",      ["api", "rest", "graphql", "endpoint", "request"]),
    ("communication", ["email", "slack", "discord", "webhook", "notify"]),
]


def classify_task(text: str) -> str:
    t = (text or "").lower()
    for task_type, keywords in _TASK_TYPES:
        if any(k in t for k in keywords):
            return task_type
    return "general"


class SelfModel:
    """Persistent, queryable model of Maya's own capabilities."""

    def __init__(self, db_path: str = None):
        self.db_path = db_path or SELF_MODEL_DB
        self._lock = threading.Lock()
        self._init_db()

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.db_path, check_same_thread=False,
                               timeout=30)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def _init_db(self) -> None:
        with self._conn() as c:
            c.executescript("""
            CREATE TABLE IF NOT EXISTS outcomes (
                id TEXT PRIMARY KEY,
                timestamp REAL,
                task_type TEXT,
                goal TEXT,
                success INTEGER,
                duration REAL,
                quality REAL,
                source TEXT DEFAULT 'unified_loop'
            );
            CREATE INDEX IF NOT EXISTS idx_outcome_type
                ON outcomes(task_type, timestamp);
            CREATE TABLE IF NOT EXISTS traits (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at REAL
            );
            """)

    # ── Recording ─────────────────────────────────────────────────────

    def record_outcome(self, goal: str, success: bool, duration: float = 0.0,
                       quality: float = None, task_type: str = None,
                       source: str = "unified_loop") -> str:
        oid = uuid.uuid4().hex[:12]
        tt = task_type or classify_task(goal)
        with self._lock, self._conn() as c:
            c.execute(
                "INSERT INTO outcomes VALUES (?,?,?,?,?,?,?,?)",
                (oid, time.time(), tt, (goal or "")[:300],
                 1 if success else 0, float(duration),
                 quality, source))
        return oid

    def set_trait(self, key: str, value) -> None:
        with self._lock, self._conn() as c:
            c.execute(
                "INSERT INTO traits(key,value,updated_at) VALUES(?,?,?) "
                "ON CONFLICT(key) DO UPDATE SET value=excluded.value, "
                "updated_at=excluded.updated_at",
                (key, json.dumps(value), time.time()))

    def get_trait(self, key: str, default=None):
        with self._lock, self._conn() as c:
            row = c.execute("SELECT value FROM traits WHERE key=?",
                            (key,)).fetchone()
        return json.loads(row["value"]) if row else default

    # ── Introspection ─────────────────────────────────────────────────

    def type_stats(self, task_type: str = None) -> List[Dict]:
        q = ("SELECT task_type, COUNT(*) n, SUM(success) s, AVG(duration) d, "
             "AVG(quality) q FROM outcomes")
        args = []
        if task_type:
            q += " WHERE task_type=?"
            args.append(task_type)
        q += " GROUP BY task_type"
        with self._lock, self._conn() as c:
            rows = c.execute(q, args).fetchall()
        return [{
            "task_type": r["task_type"],
            "attempts": r["n"],
            "success_rate": round(r["s"] / r["n"], 3) if r["n"] else 0.0,
            "avg_duration": round(r["d"], 2) if r["d"] is not None else 0.0,
            "avg_quality": round(r["q"], 2) if r["q"] is not None else None,
        } for r in rows]

    def weaknesses(self, min_attempts: int = 2,
                   max_success_rate: float = 0.5) -> List[Dict]:
        return [s for s in self.type_stats()
                if s["attempts"] >= min_attempts
                and s["success_rate"] <= max_success_rate]

    def strengths(self, min_attempts: int = 2,
                  min_success_rate: float = 0.8) -> List[Dict]:
        return [s for s in self.type_stats()
                if s["attempts"] >= min_attempts
                and s["success_rate"] >= min_success_rate]

    def assess(self, goal: str) -> Dict:
        """Pre-planning self-check: have I done this before? How did it go?"""
        tt = classify_task(goal)
        stats = {s["task_type"]: s for s in self.type_stats()}
        mine = stats.get(tt)
        weak = mine is not None and mine["success_rate"] < 0.5
        recommendation = "attempt directly"
        if weak:
            recommendation = ("attempt with extra verification; this task "
                              "type has failed repeatedly")
        elif mine is None:
            recommendation = ("novel task type — plan carefully and learn "
                              "from the outcome")
        return {
            "task_type": tt,
            "experience": mine,
            "novel": mine is None,
            "known_weakness": weak,
            "recommendation": recommendation,
        }

    def profile(self) -> Dict:
        """Full self-description for the owner and for planning."""
        all_stats = self.type_stats()
        total_attempts = sum(s["attempts"] for s in all_stats)
        overall = (
            round(sum(s["success_rate"] * s["attempts"]
                      for s in all_stats) / total_attempts, 3)
            if total_attempts else None
        )
        return {
            "total_outcomes": total_attempts,
            "overall_success_rate": overall,
            "by_task_type": all_stats,
            "strengths": self.strengths(),
            "weaknesses": self.weaknesses(),
            "traits": self.get_trait("traits", {}),
        }

    def summary_line(self, goal: str) -> str:
        """One-line self-assessment to inject into planner hints."""
        a = self.assess(goal)
        exp = a.get("experience")
        if exp is None:
            return (f"Self-model: '{a['task_type']}' tasks are new to you — "
                    f"plan carefully and learn from the result.")
        pct = int(exp["success_rate"] * 100)
        line = (f"Self-model: you have attempted {exp['attempts']} "
                f"'{a['task_type']}' task(s) with {pct}% success")
        if a["known_weakness"]:
            line += "; this is a known weakness — add extra verification"
        return line + "."


_self_model: Optional[SelfModel] = None


def get_self_model() -> SelfModel:
    global _self_model
    if _self_model is None:
        _self_model = SelfModel()
    return _self_model
