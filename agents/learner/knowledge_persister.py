"""
Knowledge persistence for Maya-Learner.
Saves learned capabilities, skills, and execution history to SQLite.
"""
import json
import sqlite3
import uuid
import threading
import os
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, field
from datetime import datetime
from contextlib import contextmanager

from agents.learner.config import LearnerConfig


@dataclass
class LearnedSkill:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    name: str = ""
    description: str = ""
    capability_type: str = ""
    code: str = ""
    input_schema: Dict = field(default_factory=dict)
    output_schema: Dict = field(default_factory=dict)
    success_rate: float = 0.0
    usage_count: int = 0
    source_urls: List[str] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)


@dataclass
class LearningRecord:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    goal: str = ""
    missing_capability: str = ""
    status: str = "pending"
    search_results: List[Dict] = field(default_factory=list)
    scraped_sources: List[Dict] = field(default_factory=list)
    synthesized_code: str = ""
    execution_result: Dict = field(default_factory=dict)
    skill_id: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = None


class KnowledgePersister:
    """Persists learner knowledge to SQLite with thread safety."""

    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or LearnerConfig.KNOWLEDGE_DB
        self._lock = threading.Lock()
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self._init_db()

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.db_path, check_same_thread=False, timeout=10)
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

    def _init_db(self) -> None:
        with self._conn() as c:
            c.executescript("""
            CREATE TABLE IF NOT EXISTS learned_skills (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                capability_type TEXT,
                code TEXT NOT NULL,
                input_schema TEXT DEFAULT '{}',
                output_schema TEXT DEFAULT '{}',
                success_rate REAL DEFAULT 0.0,
                usage_count INTEGER DEFAULT 0,
                source_urls TEXT DEFAULT '[]',
                created_at REAL,
                updated_at REAL
            );

            CREATE TABLE IF NOT EXISTS learning_records (
                id TEXT PRIMARY KEY,
                goal TEXT NOT NULL,
                missing_capability TEXT NOT NULL,
                status TEXT DEFAULT 'pending',
                search_results TEXT DEFAULT '[]',
                scraped_sources TEXT DEFAULT '[]',
                synthesized_code TEXT,
                execution_result TEXT DEFAULT '{}',
                skill_id TEXT,
                error TEXT,
                created_at REAL,
                completed_at REAL
            );

            CREATE INDEX IF NOT EXISTS idx_skills_capability
                ON learned_skills(capability_type);
            CREATE INDEX IF NOT EXISTS idx_records_capability
                ON learning_records(missing_capability);
            CREATE INDEX IF NOT EXISTS idx_records_status
                ON learning_records(status);
            """)

    # ── Skills ────────────────────────────────────────────────────────────────

    def save_skill(self, skill: LearnedSkill) -> str:
        """Save or update a learned skill."""
        with self._lock:
            with self._conn() as c:
                c.execute("""
                    INSERT OR REPLACE INTO learned_skills
                    (id, name, description, capability_type, code, input_schema, output_schema,
                     success_rate, usage_count, source_urls, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    skill.id, skill.name, skill.description, skill.capability_type,
                    skill.code, json.dumps(skill.input_schema), json.dumps(skill.output_schema),
                    skill.success_rate, skill.usage_count, json.dumps(skill.source_urls),
                    skill.created_at.timestamp(), datetime.utcnow().timestamp(),
                ))
        return skill.id

    def get_skill(self, skill_id: str) -> Optional[LearnedSkill]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM learned_skills WHERE id = ?", (skill_id,)).fetchone()
            if not row:
                return None
            return self._row_to_skill(row)

    def get_skill_by_capability(self, capability_type: str) -> Optional[LearnedSkill]:
        """Find a skill that handles a given capability type."""
        with self._conn() as c:
            row = c.execute(
                "SELECT * FROM learned_skills WHERE capability_type = ? ORDER BY success_rate DESC, usage_count DESC LIMIT 1",
                (capability_type,)
            ).fetchone()
            if not row:
                return None
            return self._row_to_skill(row)

    def list_skills(self, limit: int = 50, capability_type: Optional[str] = None) -> List[LearnedSkill]:
        with self._conn() as c:
            if capability_type:
                rows = c.execute(
                    "SELECT * FROM learned_skills WHERE capability_type = ? ORDER BY success_rate DESC LIMIT ?",
                    (capability_type, limit)
                ).fetchall()
            else:
                rows = c.execute(
                    "SELECT * FROM learned_skills ORDER BY success_rate DESC, usage_count DESC LIMIT ?",
                    (limit,)
                ).fetchall()
            return [self._row_to_skill(r) for r in rows]

    def update_skill_stats(self, skill_id: str, success: bool, reward: float = 0.0) -> None:
        """Update skill success rate and usage count."""
        with self._lock:
            with self._conn() as c:
                row = c.execute("SELECT success_rate, usage_count FROM learned_skills WHERE id = ?", (skill_id,)).fetchone()
                if not row:
                    return
                old_rate, count = row["success_rate"], row["usage_count"]
                new_count = count + 1
                new_rate = (old_rate * count + (1.0 if success else 0.0)) / new_count
                c.execute(
                    "UPDATE learned_skills SET success_rate = ?, usage_count = ?, updated_at = ? WHERE id = ?",
                    (new_rate, new_count, datetime.utcnow().timestamp(), skill_id)
                )

    # ── Learning Records ──────────────────────────────────────────────────────

    def save_record(self, record: LearningRecord) -> str:
        with self._lock:
            with self._conn() as c:
                c.execute("""
                    INSERT OR REPLACE INTO learning_records
                    (id, goal, missing_capability, status, search_results, scraped_sources,
                     synthesized_code, execution_result, skill_id, error, created_at, completed_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    record.id, record.goal, record.missing_capability, record.status,
                    json.dumps(record.search_results), json.dumps(record.scraped_sources),
                    record.synthesized_code, json.dumps(record.execution_result),
                    record.skill_id, record.error,
                    record.created_at.timestamp(),
                    record.completed_at.timestamp() if record.completed_at else None,
                ))
        return record.id

    def get_record(self, record_id: str) -> Optional[LearningRecord]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM learning_records WHERE id = ?", (record_id,)).fetchone()
            if not row:
                return None
            return self._row_to_record(row)

    def get_records_by_capability(self, capability: str, limit: int = 20) -> List[LearningRecord]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM learning_records WHERE missing_capability = ? ORDER BY created_at DESC LIMIT ?",
                (capability, limit)
            ).fetchall()
            return [self._row_to_record(r) for r in rows]

    def get_recent_records(self, limit: int = 50, status: Optional[str] = None) -> List[LearningRecord]:
        with self._conn() as c:
            if status:
                rows = c.execute(
                    "SELECT * FROM learning_records WHERE status = ? ORDER BY created_at DESC LIMIT ?",
                    (status, limit)
                ).fetchall()
            else:
                rows = c.execute(
                    "SELECT * FROM learning_records ORDER BY created_at DESC LIMIT ?",
                    (limit,)
                ).fetchall()
            return [self._row_to_record(r) for r in rows]

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _row_to_skill(self, row: sqlite3.Row) -> LearnedSkill:
        return LearnedSkill(
            id=row["id"],
            name=row["name"],
            description=row["description"] or "",
            capability_type=row["capability_type"] or "",
            code=row["code"] or "",
            input_schema=json.loads(row["input_schema"] or "{}"),
            output_schema=json.loads(row["output_schema"] or "{}"),
            success_rate=row["success_rate"] or 0.0,
            usage_count=row["usage_count"] or 0,
            source_urls=json.loads(row["source_urls"] or "[]"),
            created_at=datetime.fromtimestamp(row["created_at"]),
            updated_at=datetime.fromtimestamp(row["updated_at"]),
        )

    def _row_to_record(self, row: sqlite3.Row) -> LearningRecord:
        return LearningRecord(
            id=row["id"],
            goal=row["goal"],
            missing_capability=row["missing_capability"],
            status=row["status"],
            search_results=json.loads(row["search_results"] or "[]"),
            scraped_sources=json.loads(row["scraped_sources"] or "[]"),
            synthesized_code=row["synthesized_code"] or "",
            execution_result=json.loads(row["execution_result"] or "{}"),
            skill_id=row["skill_id"],
            error=row["error"],
            created_at=datetime.fromtimestamp(row["created_at"]),
            completed_at=datetime.fromtimestamp(row["completed_at"]) if row["completed_at"] else None,
        )