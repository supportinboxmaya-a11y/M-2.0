"""
Maya 2.0 — Episodic & Procedural Memory (Phase 18)
===================================================
Experience replay, episode distillation into reusable skills,
and procedural memory for learned capabilities.
"""

import json
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple

from config.settings import STORAGE_DIR


PROC_MEM_DIR = STORAGE_DIR / "procedural_memory"
PROC_MEM_DIR.mkdir(parents=True, exist_ok=True)
PROC_MEM_DB = str(PROC_MEM_DIR / "procedural.db")


@dataclass
class Episode:
    """A complete episode of task execution."""
    id: str
    goal: str
    plan_id: Optional[str] = None
    steps: List[Dict] = field(default_factory=list)  # Executed steps with results
    outcome: str = "unknown"  # success, failure, partial
    success: bool = False
    reward: float = 0.0
    duration: float = 0.0
    start_time: float = field(default_factory=time.time)
    end_time: Optional[float] = None
    context: Dict = field(default_factory=dict)  # Environment state, beliefs
    lessons: List[str] = field(default_factory=list)
    metadata: Dict = field(default_factory=dict)


@dataclass
class Skill:
    """A distilled procedural skill."""
    id: str
    name: str
    description: str
    trigger_conditions: List[str] = field(default_factory=list)  # When to use this skill
    preconditions: List[str] = field(default_factory=list)
    procedure: List[Dict] = field(default_factory=list)  # Parameterized steps
    parameters: Dict = field(default_factory=dict)  # Parameter schema
    success_rate: float = 0.0
    avg_reward: float = 0.0
    usage_count: int = 0
    source_episodes: List[str] = field(default_factory=list)  # Episode IDs
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    version: int = 1
    verified: bool = False
    confidence: float = 0.0  # Confidence in this skill's reliability


class EpisodicMemory:
    """Episodic memory for storing and retrieving task execution episodes."""
    
    def __init__(self):
        self._init_db()
    
    def _init_db(self) -> None:
        with self._conn() as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS episodes (
                    id TEXT PRIMARY KEY,
                    goal TEXT NOT NULL,
                    plan_id TEXT,
                    steps TEXT DEFAULT '[]',
                    outcome TEXT DEFAULT 'unknown',
                    success INTEGER DEFAULT 0,
                    reward REAL DEFAULT 0.0,
                    duration REAL DEFAULT 0.0,
                    start_time REAL,
                    end_time REAL,
                    context TEXT DEFAULT '{}',
                    lessons TEXT DEFAULT '[]',
                    metadata TEXT DEFAULT '{}'
                )
            """)
            c.execute("CREATE INDEX IF NOT EXISTS idx_ep_goal ON episodes(goal)")
            c.execute("CREATE INDEX IF NOT EXISTS idx_ep_success ON episodes(success)")
            c.execute("CREATE INDEX IF NOT EXISTS idx_ep_time ON episodes(start_time)")
    
    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(PROC_MEM_DB, check_same_thread=False, timeout=30)
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
    
    def add_episode(self, episode: Episode) -> str:
        with self._conn() as c:
            c.execute("""
                INSERT INTO episodes 
                (id, goal, plan_id, steps, outcome, success, reward, duration,
                 start_time, end_time, context, lessons, metadata)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
            """, (
                episode.id, episode.goal, episode.plan_id,
                json.dumps(episode.steps), episode.outcome,
                int(episode.success), episode.reward, episode.duration,
                episode.start_time, episode.end_time,
                json.dumps(episode.context), json.dumps(episode.lessons),
                json.dumps(episode.metadata)
            ))
        return episode.id
    
    def get_episode(self, episode_id: str) -> Optional[Episode]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM episodes WHERE id = ?", (episode_id,)).fetchone()
        if row:
            return self._row_to_episode(row)
        return None
    
    def get_recent(self, limit: int = 50) -> List[Episode]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM episodes ORDER BY start_time DESC LIMIT ?", (limit,)
            ).fetchall()
        return [self._row_to_episode(r) for r in rows]
    
    def get_successful(self, limit: int = 100) -> List[Episode]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM episodes WHERE success = 1 ORDER BY reward DESC LIMIT ?", (limit,)
            ).fetchall()
        return [self._row_to_episode(r) for r in rows]
    
    def get_similar(self, goal: str, limit: int = 10) -> List[Episode]:
        """Find episodes with similar goals (simple keyword matching)."""
        goal_tokens = set(goal.lower().split())
        with self._conn() as c:
            rows = c.execute("SELECT * FROM episodes").fetchall()
        
        scored = []
        for row in rows:
            ep = self._row_to_episode(row)
            ep_tokens = set(ep.goal.lower().split())
            overlap = len(goal_tokens & ep_tokens) / max(1, len(goal_tokens | ep_tokens))
            if overlap > 0.2:
                scored.append((overlap, ep))
        
        scored.sort(key=lambda x: x[0], reverse=True)
        return [ep for _, ep in scored[:limit]]
    
    def get_by_outcome(self, outcome: str, limit: int = 50) -> List[Episode]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM episodes WHERE outcome = ? ORDER BY start_time DESC LIMIT ?",
                (outcome, limit)
            ).fetchall()
        return [self._row_to_episode(r) for r in rows]
    
    def _row_to_episode(self, row) -> Episode:
        return Episode(
            id=row["id"],
            goal=row["goal"],
            plan_id=row["plan_id"],
            steps=json.loads(row["steps"]),
            outcome=row["outcome"],
            success=bool(row["success"]),
            reward=row["reward"],
            duration=row["duration"],
            start_time=row["start_time"],
            end_time=row["end_time"],
            context=json.loads(row["context"]),
            lessons=json.loads(row["lessons"]),
            metadata=json.dumps(row["metadata"]),
        )
    
    def stats(self) -> Dict:
        with self._conn() as c:
            total = c.execute("SELECT COUNT(*) FROM episodes").fetchone()[0]
            successful = c.execute("SELECT COUNT(*) FROM episodes WHERE success = 1").fetchone()[0]
            avg_reward = c.execute("SELECT AVG(reward) FROM episodes").fetchone()[0] or 0
            avg_duration = c.execute("SELECT AVG(duration) FROM episodes").fetchone()[0] or 0
        return {
            "total_episodes": total,
            "successful": successful,
            "success_rate": successful / max(1, total),
            "avg_reward": avg_reward,
            "avg_duration": avg_duration,
        }


class ProceduralMemory:
    """Procedural memory for storing and retrieving distilled skills."""
    
    def __init__(self):
        self._init_db()
        self._skills: Dict[str, Skill] = {}
        self._load_skills()
    
    def _init_db(self) -> None:
        with self._conn() as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS skills (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    trigger_conditions TEXT DEFAULT '[]',
                    preconditions TEXT DEFAULT '[]',
                    procedure TEXT DEFAULT '[]',
                    parameters TEXT DEFAULT '{}',
                    success_rate REAL DEFAULT 0.0,
                    avg_reward REAL DEFAULT 0.0,
                    usage_count INTEGER DEFAULT 0,
                    source_episodes TEXT DEFAULT '[]',
                    created_at REAL,
                    updated_at REAL,
                    version INTEGER DEFAULT 1,
                    verified INTEGER DEFAULT 0,
                    confidence REAL DEFAULT 0.0
                )
            """)
            c.execute("CREATE INDEX IF NOT EXISTS idx_skill_name ON skills(name)")
            c.execute("CREATE INDEX IF NOT EXISTS idx_skill_verified ON skills(verified)")
    
    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(PROC_MEM_DB, check_same_thread=False, timeout=30)
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
    
    def _load_skills(self) -> None:
        with self._conn() as c:
            rows = c.execute("SELECT * FROM skills").fetchall()
            for row in rows:
                skill = self._row_to_skill(row)
                self._skills[skill.id] = skill
    
    def _row_to_skill(self, row) -> Skill:
        return Skill(
            id=row["id"],
            name=row["name"],
            description=row["description"],
            trigger_conditions=json.loads(row["trigger_conditions"]),
            preconditions=json.loads(row["preconditions"]),
            procedure=json.loads(row["procedure"]),
            parameters=json.loads(row["parameters"]),
            success_rate=row["success_rate"],
            avg_reward=row["avg_reward"],
            usage_count=row["usage_count"],
            source_episodes=json.loads(row["source_episodes"]),
            created_at=row["created_at"],
            updated_at=row["updated_at"],
            version=row["version"],
            verified=bool(row["verified"]),
            confidence=row["confidence"],
        )
    
    def store_skill(self, skill: Skill) -> str:
        with self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO skills
                (id, name, description, trigger_conditions, preconditions, procedure,
                 parameters, success_rate, avg_reward, usage_count, source_episodes,
                 created_at, updated_at, version, verified, confidence)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            """, (
                skill.id, skill.name, skill.description,
                json.dumps(skill.trigger_conditions), json.dumps(skill.preconditions),
                json.dumps(skill.procedure), json.dumps(skill.parameters),
                skill.success_rate, skill.avg_reward, skill.usage_count,
                json.dumps(skill.source_episodes),
                skill.created_at, skill.updated_at, skill.version,
                int(skill.verified), skill.confidence
            ))
        self._skills[skill.id] = skill
        return skill.id
    
    def get_skill(self, skill_id: str) -> Optional[Skill]:
        return self._skills.get(skill_id)
    
    def get_skill_by_name(self, name: str) -> Optional[Skill]:
        for skill in self._skills.values():
            if skill.name == name:
                return skill
        return None
    
    def list_skills(self, verified_only: bool = False, limit: int = 100) -> List[Skill]:
        skills = list(self._skills.values())
        if verified_only:
            skills = [s for s in skills if s.verified]
        skills.sort(key=lambda s: s.confidence * s.success_rate, reverse=True)
        return skills[:limit]
    
    def find_applicable_skills(self, context: Dict, goal: str) -> List[Skill]:
        """Find skills applicable to current context and goal."""
        applicable = []
        goal_tokens = set(goal.lower().split())
        
        for skill in self._skills.values():
            if not skill.verified and skill.confidence < 0.5:
                continue
            
            # Check trigger conditions
            triggered = False
            for condition in skill.trigger_conditions:
                if self._match_condition(condition, context, goal):
                    triggered = True
                    break
            
            if triggered or not skill.trigger_conditions:
                # Check preconditions
                preconditions_met = all(
                    self._match_condition(p, context, goal) 
                    for p in skill.preconditions
                )
                if preconditions_met:
                    applicable.append(skill)
        
        applicable.sort(key=lambda s: s.confidence * s.success_rate, reverse=True)
        return applicable
    
    def _match_condition(self, condition: str, context: Dict, goal: str) -> bool:
        """Simple condition matching."""
        condition_lower = condition.lower()
        goal_lower = goal.lower()
        
        # Check goal keywords
        if any(word in goal_lower for word in condition_lower.split()):
            return True
        
        # Check context
        for key, value in context.items():
            if condition_lower in str(key).lower() or condition_lower in str(value).lower():
                return True
        
        return False
    
    def record_usage(self, skill_id: str, success: bool, reward: float) -> None:
        skill = self.get_skill(skill_id)
        if not skill:
            return

        skill.usage_count += 1
        skill.success_rate = ((skill.usage_count - 1) * skill.success_rate + (1 if success else 0)) / skill.usage_count
        skill.avg_reward = ((skill.usage_count - 1) * skill.avg_reward + reward) / skill.usage_count
        skill.updated_at = time.time()
        self.store_skill(skill)

    # ── Phase 37: generalization — retrieval + composition ───────────

    @staticmethod
    def _relevance(query_tokens: set, text: str) -> float:
        t = set(text.lower().split())
        if not query_tokens or not t:
            return 0.0
        return len(query_tokens & t) / max(1, min(len(query_tokens), len(t)))

    def search_skills(self, query: str, limit: int = 5) -> List[Dict]:
        """Ranked skill retrieval by relevance x reliability.

        This is what lets a distilled skill generalize: a skill learned
        from past episodes surfaces for any goal lexically similar to what
        it knows how to do.
        """
        query = (query or "").strip()
        if not query:
            return []
        q = set(query.lower().split())
        scored = []
        for skill in self._skills.values():
            if not skill.verified and skill.confidence < 0.3:
                continue
            texts = [skill.name, skill.description] + list(skill.trigger_conditions)
            rel = max((self._relevance(q, t) for t in texts), default=0.0)
            if rel <= 0:
                continue
            reliability = skill.confidence * max(skill.success_rate, 0.1) + 0.1
            scored.append((rel * 0.7 + reliability * 0.3, skill))
        scored.sort(key=lambda sb: sb[0], reverse=True)
        return [{
            "skill_id": s.id,
            "name": s.name,
            "description": s.description,
            "confidence": round(s.confidence, 3),
            "success_rate": round(s.success_rate, 3),
            "usage_count": s.usage_count,
            "score": round(score, 3),
        } for score, s in scored[:limit]]

    def compose_skills(self, skill_ids: List[str], name: str,
                       description: str = "") -> Optional[Skill]:
        """Compose existing skills into a new higher-order skill.

        The composite's procedure chains its components; it starts
        unverified with conservative confidence and earns reliability
        through record_usage() like any other skill.
        """
        parts = []
        for sid in skill_ids:
            s = self.get_skill(sid)
            if s is None:
                return None
            parts.append(s)
        if not parts:
            return None
        composite = Skill(
            id=uuid.uuid4().hex[:12],
            name=name,
            description=description or f"Composite of: {', '.join(p.name for p in parts)}",
            trigger_conditions=[],
            preconditions=[p for s in parts[:1] for p in s.preconditions],
            procedure=[
                {"step": i + 1, "type": "skill_call", "skill_id": p.id,
                 "skill_name": p.name}
                for i, p in enumerate(parts)
            ],
            parameters={},
            success_rate=0.0,
            confidence=round(min(p.confidence for p in parts) * 0.8, 3),
            source_episodes=[ep for s in parts for ep in s.source_episodes][:20],
        )
        self.store_skill(composite)
        return composite

    def stats(self) -> Dict:
        verified = sum(1 for s in self._skills.values() if s.verified)
        total_usage = sum(s.usage_count for s in self._skills.values())
        return {
            "total_skills": len(self._skills),
            "verified": verified,
            "total_usage": total_usage,
            "avg_confidence": sum(s.confidence for s in self._skills.values()) / max(1, len(self._skills)),
        }


class ExperienceDistiller:
    """
    Distills episodes into reusable procedural skills.
    """
    
    def __init__(
        self,
        episodic_memory: EpisodicMemory,
        procedural_memory: ProceduralMemory,
        llm_fn: Callable,
        capability_registry=None,
    ):
        self.episodic = episodic_memory
        self.procedural = procedural_memory
        self.llm_fn = llm_fn
        self.capability_registry = capability_registry
    
    def distill_episodes(self, episodes: List[Episode], min_episodes: int = 3) -> List[Skill]:
        """Distill multiple episodes into a skill."""
        if len(episodes) < min_episodes:
            return []
        
        # Filter successful episodes
        successful = [e for e in episodes if e.success]
        if len(successful) < min_episodes:
            return []
        
        # Analyze common patterns
        skill = self._analyze_and_create_skill(successful)
        if skill:
            self.procedural.store_skill(skill)
            return [skill]
        return []
    
    def _analyze_and_create_skill(self, episodes: List[Episode]) -> Optional[Skill]:
        """Use LLM to analyze episodes and create a skill."""
        # Prepare episode summaries
        summaries = []
        for ep in episodes:
            step_summary = []
            for step in ep.steps:
                step_summary.append({
                    "action": step.get("action", {}),
                    "success": step.get("success"),
                    "tool": step.get("tool", step.get("required_capability", "")),
                })
            summaries.append({
                "goal": ep.goal,
                "steps": step_summary,
                "reward": ep.reward,
            })
        
        prompt = f"""
Analyze these successful episodes and create a reusable skill:

Episodes: {json.dumps(summaries, indent=2)}

Create a skill that captures the common pattern. Return JSON:
{{
  "name": "skill_name",
  "description": "What this skill does",
  "trigger_conditions": ["condition1", "condition2"],
  "preconditions": ["precondition1"],
  "procedure": [
    {{"step": 1, "action": "...", "tool": "...", "params": {{}}}}
  ],
  "parameters": {{"param1": {{"type": "string", "description": "..."}}}},
  "confidence": 0.8
}}
"""
        try:
            raw = self.llm_fn(prompt)
            raw = raw.strip()
            if "{" in raw and "}" in raw:
                raw = raw[raw.index("{"):raw.rindex("}")+1]
            skill_data = json.loads(raw)
        except Exception as e:
            print(f"Distillation failed: {e}")
            return None
        
        skill_id = f"skill_{uuid.uuid4().hex[:10]}"
        skill = Skill(
            id=skill_id,
            name=skill_data.get("name", f"skill_{skill_id}"),
            description=skill_data.get("description", ""),
            trigger_conditions=skill_data.get("trigger_conditions", []),
            preconditions=skill_data.get("preconditions", []),
            procedure=skill_data.get("procedure", []),
            parameters=skill_data.get("parameters", {}),
            source_episodes=[ep.id for ep in episodes],
            confidence=skill_data.get("confidence", 0.5),
            success_rate=sum(ep.reward for ep in episodes) / len(episodes),
            avg_reward=sum(ep.reward for ep in episodes) / len(episodes),
        )
        
        return skill
    
    def distill_from_goal(self, goal: str, min_success_rate: float = 0.7) -> List[Skill]:
        """Find episodes for a goal and distill them."""
        similar = self.episodic.get_similar(goal, limit=20)
        successful = [e for e in similar if e.success and e.reward >= min_success_rate]
        return self.distill_episodes(successful)
    
    def auto_distill(self, batch_size: int = 10) -> int:
        """Automatically distill recent successful episodes."""
        recent = self.episodic.get_successful(limit=100)
        
        # Group by similar goals
        groups = {}
        for ep in recent:
            key = self._group_key(ep.goal)
            groups.setdefault(key, []).append(ep)
        
        skills_created = 0
        for group_episodes in groups.values():
            if len(group_episodes) >= 3:
                skills = self.distill_episodes(group_episodes)
                skills_created += len(skills)
        
        return skills_created
    
    def _group_key(self, goal: str) -> str:
        """Generate grouping key from goal."""
        # Simple: first 3 significant words
        words = [w for w in goal.lower().split() if len(w) > 3]
        return "_".join(words[:3])


class ExperienceReplay:
    """Experience replay for learning from past episodes."""
    
    def __init__(
        self,
        episodic_memory: EpisodicMemory,
        procedural_memory: ProceduralMemory,
        distiller: ExperienceDistiller,
        kernel=None,
    ):
        self.episodic = episodic_memory
        self.procedural = procedural_memory
        self.distiller = distiller
        self.kernel = kernel
        
        self._replay_buffer: List[Episode] = []
        self._buffer_size = 1000
        self._priorities: Dict[str, float] = {}  # episode_id -> priority
    
    def add_experience(self, episode: Episode) -> None:
        """Add episode to replay buffer."""
        self._replay_buffer.append(episode)
        if len(self._replay_buffer) > self._buffer_size:
            self._replay_buffer.pop(0)
        
        # Priority based on reward and novelty
        priority = episode.reward * (2.0 if episode.success else 0.5)
        self._priorities[episode.id] = priority
    
    def sample(self, batch_size: int = 32, prioritized: bool = True) -> List[Episode]:
        """Sample episodes for replay."""
        if not self._replay_buffer:
            return []
        
        if prioritized and self._priorities:
            # Prioritized sampling
            episodes = self._replay_buffer
            weights = [self._priorities.get(ep.id, 1.0) for ep in episodes]
            total = sum(weights)
            probs = [w / total for w in weights]
            
            import random
            indices = random.choices(range(len(episodes)), weights=probs, k=min(batch_size, len(episodes)))
            return [episodes[i] for i in indices]
        else:
            import random
            return random.sample(self._replay_buffer, min(batch_size, len(self._replay_buffer)))
    
    def replay_batch(self, batch_size: int = 32) -> Dict:
        """Process a batch of episodes for learning."""
        batch = self.sample(batch_size)
        if not batch:
            return {"processed": 0, "skills_created": 0}
        
        # Group by goal similarity
        skills_created = 0
        for ep in batch:
            if ep.success:
                similar = self.episodic.get_similar(ep.goal, limit=5)
                if len(similar) >= 3:
                    skills = self.distiller.distill_episodes(similar)
                    skills_created += len(skills)
        
        return {"processed": len(batch), "skills_created": skills_created}
    
    def get_replay_stats(self) -> Dict:
        if not self._replay_buffer:
            return {"buffer_size": 0}
        
        successes = sum(1 for e in self._replay_buffer if e.success)
        avg_reward = sum(e.reward for e in self._replay_buffer) / len(self._replay_buffer)
        
        return {
            "buffer_size": len(self._replay_buffer),
            "success_rate": successes / len(self._replay_buffer),
            "avg_reward": avg_reward,
            "unique_goals": len(set(e.goal for e in self._replay_buffer)),
        }


# Module singletons
_episodic_memory: Optional[EpisodicMemory] = None
_procedural_memory: Optional[ProceduralMemory] = None
_distiller: Optional[ExperienceDistiller] = None
_replay: Optional[ExperienceReplay] = None


def get_episodic_memory() -> EpisodicMemory:
    global _episodic_memory
    if _episodic_memory is None:
        _episodic_memory = EpisodicMemory()
    return _episodic_memory


def get_procedural_memory() -> ProceduralMemory:
    global _procedural_memory
    if _procedural_memory is None:
        _procedural_memory = ProceduralMemory()
    return _procedural_memory


def get_experience_distiller(llm_fn=None, **kwargs) -> ExperienceDistiller:
    global _distiller
    if _distiller is None and llm_fn:
        _distiller = ExperienceDistiller(
            get_episodic_memory(), get_procedural_memory(), llm_fn, **kwargs
        )
    return _distiller


def get_experience_replay(kernel=None, **kwargs) -> ExperienceReplay:
    global _replay
    if _replay is None:
        _replay = ExperienceReplay(
            get_episodic_memory(), get_procedural_memory(),
            get_experience_distiller(**kwargs), kernel
        )
    return _replay


def set_episodic_memory(mem: EpisodicMemory) -> None:
    global _episodic_memory
    _episodic_memory = mem


def set_procedural_memory(mem: ProceduralMemory) -> None:
    global _procedural_memory
    _procedural_memory = mem