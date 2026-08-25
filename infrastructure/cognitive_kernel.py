"""
Maya 2.0 — Cognitive Kernel (Phase 18)
=======================================
The persistent cognitive process that provides:
- Working memory with attention and decay
- Goal stack with hierarchical decomposition
- Background cognitive threads (perception, consolidation, planning, monitoring)
- Persistent identity with checkpointing
- World model integration for simulation-based planning
- Metacognitive monitoring (confidence, surprise, replanning triggers)
"""

import asyncio
import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
from pathlib import Path

from config.settings import STORAGE_DIR


COG_KERNEL_DIR = STORAGE_DIR / "cognitive_kernel"
COG_KERNEL_DIR.mkdir(parents=True, exist_ok=True)
COG_KERNEL_DB = str(COG_KERNEL_DIR / "kernel.db")
CHECKPOINT_DIR = COG_KERNEL_DIR / "checkpoints"
CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)


class GoalStatus(Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    COMPLETED = "completed"
    ABANDONED = "abandoned"
    BLOCKED = "blocked"


class GoalPriority(Enum):
    CRITICAL = 100
    HIGH = 75
    NORMAL = 50
    LOW = 25
    BACKGROUND = 10


@dataclass
class WorkingMemorySlot:
    """A slot in working memory with attention weight and decay."""
    content: str
    slot_type: str  # "fact", "goal", "plan", "observation", "hypothesis"
    attention: float = 1.0
    created_at: float = field(default_factory=time.time)
    last_accessed: float = field(default_factory=time.time)
    access_count: int = 0
    metadata: Dict = field(default_factory=dict)
    bindings: Dict[str, str] = field(default_factory=dict)  # variable bindings

    def access(self) -> None:
        self.last_accessed = time.time()
        self.access_count += 1
        self.attention = min(1.0, self.attention + 0.1)

    def decay(self, rate: float = 0.05) -> None:
        self.attention = max(0.0, self.attention - rate)


@dataclass
class Goal:
    """Hierarchical goal with decomposition and success criteria."""
    id: str
    description: str
    parent_id: Optional[str] = None
    children: List[str] = field(default_factory=list)
    status: GoalStatus = GoalStatus.ACTIVE
    priority: float = GoalPriority.NORMAL.value
    success_criteria: List[str] = field(default_factory=list)
    constraints: Dict = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    completed_at: Optional[float] = None
    progress: float = 0.0
    metadata: Dict = field(default_factory=dict)
    assigned_agent: Optional[str] = None
    required_capabilities: List[str] = field(default_factory=list)


@dataclass
class Belief:
    """A belief about the world with confidence and evidence."""
    id: str
    proposition: str
    confidence: float  # 0.0 to 1.0
    evidence: List[str] = field(default_factory=list)
    source: str = "observation"  # observation, inference, testimony, assumption
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    domain: str = "general"  # filesystem, codebase, server, browser, api, database


@dataclass
class Plan:
    """A hierarchical plan with contingencies."""
    id: str
    goal_id: str
    steps: List[Dict] = field(default_factory=list)  # Each step: {id, description, action, expected_outcome, contingency}
    status: str = "draft"  # draft, active, completed, failed, replanning
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    resource_budget: Dict = field(default_factory=dict)  # compute, time, api_calls, cost
    checkpoints: List[Dict] = field(default_factory=list)


class CognitiveKernel:
    """
    The persistent cognitive core of Maya.
    Runs as a long-lived process with background threads for continuous cognition.
    """

    def __init__(
        self,
        llm_fn: Optional[Callable] = None,
        capability_registry: Optional[Any] = None,
        memory_manager: Optional[Any] = None,
        world_models: Optional[Dict[str, Any]] = None,
        approval_manager: Optional[Any] = None,
        intervention_handler: Optional[Any] = None,
    ):
        self._lock = threading.RLock()
        self.llm_fn = llm_fn
        self.capability_registry = capability_registry
        self.memory_manager = memory_manager
        self.world_models = world_models or {}
        self.approval = approval_manager
        self.intervention = intervention_handler

        # Core cognitive state
        self.working_memory: Dict[str, WorkingMemorySlot] = {}
        self.goals: Dict[str, Goal] = {}
        self.goal_stack: List[str] = []  # Active goal IDs in priority order
        self.beliefs: Dict[str, Belief] = {}
        self.plans: Dict[str, Plan] = {}
        self.active_plan_id: Optional[str] = None

        # Identity and persistence
        self.instance_id = uuid.uuid4().hex[:12]
        self.created_at = time.time()
        self.last_checkpoint = 0
        self.checkpoint_interval = 300  # 5 minutes
        self.version = "1.0"

        # Background thread control
        self._running = False
        self._threads: Dict[str, threading.Thread] = {}
        self._stop_events: Dict[str, threading.Event] = {}

        # Metacognitive state
        self.confidence_threshold = 0.6
        self.surprise_threshold = 0.3
        self.replan_triggers: List[Dict] = []
        self.performance_history: List[Dict] = []

        # Attention and resource allocation
        self.attention_budget = 100.0
        self.allocated_attention: Dict[str, float] = {}

        # Phase 34 — Unified control loop.
        # The kernel is Maya's single central controller. Exactly ONE execution
        # backend (Maya's own pipeline) may be registered; models, agents,
        # tools and workflows are capabilities this loop uses — never controllers.
        self._executor: Optional[Callable] = None
        self.unified_loop_enabled: bool = False

        # Phase 37: procedural memory reference (set by Maya after init)
        # so goal grounding can surface learned, reusable skills.
        self.procedural_memory = None

        # Phase 39: self-model reference (set by Maya after init) so every
        # unified-loop outcome updates Maya's persistent model of itself.
        self.self_model = None

        self._init_db()
        self._load_state()

    # =========================================================================
    # Database & Persistence
    # =========================================================================

    def _init_db(self) -> None:
        with self._conn() as c:
            c.executescript("""
            CREATE TABLE IF NOT EXISTS kernel_state (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at REAL
            );

            CREATE TABLE IF NOT EXISTS goals (
                id TEXT PRIMARY KEY,
                description TEXT NOT NULL,
                parent_id TEXT,
                children TEXT DEFAULT '[]',
                status TEXT DEFAULT 'active',
                priority REAL DEFAULT 50.0,
                success_criteria TEXT DEFAULT '[]',
                constraints TEXT DEFAULT '{}',
                created_at REAL,
                updated_at REAL,
                completed_at REAL,
                progress REAL DEFAULT 0.0,
                metadata TEXT DEFAULT '{}',
                assigned_agent TEXT,
                required_capabilities TEXT DEFAULT '[]'
            );

            CREATE TABLE IF NOT EXISTS working_memory (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                slot_type TEXT DEFAULT 'fact',
                attention REAL DEFAULT 1.0,
                created_at REAL,
                last_accessed REAL,
                access_count INTEGER DEFAULT 0,
                metadata TEXT DEFAULT '{}',
                bindings TEXT DEFAULT '{}'
            );

            CREATE TABLE IF NOT EXISTS beliefs (
                id TEXT PRIMARY KEY,
                proposition TEXT NOT NULL,
                confidence REAL DEFAULT 0.5,
                evidence TEXT DEFAULT '[]',
                source TEXT DEFAULT 'observation',
                created_at REAL,
                updated_at REAL,
                domain TEXT DEFAULT 'general'
            );

            CREATE TABLE IF NOT EXISTS plans (
                id TEXT PRIMARY KEY,
                goal_id TEXT NOT NULL,
                steps TEXT DEFAULT '[]',
                status TEXT DEFAULT 'draft',
                created_at REAL,
                updated_at REAL,
                resource_budget TEXT DEFAULT '{}',
                checkpoints TEXT DEFAULT '[]'
            );

            CREATE TABLE IF NOT EXISTS cognitive_audit (
                id TEXT PRIMARY KEY,
                timestamp REAL,
                event_type TEXT,
                details TEXT
            );

            CREATE TABLE IF NOT EXISTS metacognitive_log (
                id TEXT PRIMARY KEY,
                timestamp REAL,
                confidence REAL,
                surprise REAL,
                trigger TEXT,
                action_taken TEXT
            );

            CREATE INDEX IF NOT EXISTS idx_goals_parent ON goals(parent_id);
            CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);
            CREATE INDEX IF NOT EXISTS idx_wm_attention ON working_memory(attention DESC);
            CREATE INDEX IF NOT EXISTS idx_beliefs_domain ON beliefs(domain);
            CREATE INDEX IF NOT EXISTS idx_plans_goal ON plans(goal_id);
            """)

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(COG_KERNEL_DB, check_same_thread=False, timeout=30)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            conn.execute("PRAGMA synchronous=NORMAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def _load_state(self) -> None:
        with self._lock, self._conn() as c:
            # Load goals
            for row in c.execute("SELECT * FROM goals WHERE status IN ('active', 'suspended', 'blocked')"):
                goal = Goal(
                    id=row["id"],
                    description=row["description"],
                    parent_id=row["parent_id"],
                    children=json.loads(row["children"]),
                    status=GoalStatus(row["status"]),
                    priority=row["priority"],
                    success_criteria=json.loads(row["success_criteria"]),
                    constraints=json.loads(row["constraints"]),
                    created_at=row["created_at"],
                    updated_at=row["updated_at"],
                    completed_at=row["completed_at"],
                    progress=row["progress"],
                    metadata=json.loads(row["metadata"]),
                    assigned_agent=row["assigned_agent"],
                    required_capabilities=json.loads(row["required_capabilities"]),
                )
                self.goals[goal.id] = goal
                if goal.status == GoalStatus.ACTIVE:
                    self.goal_stack.append(goal.id)

            # Load working memory
            for row in c.execute("SELECT * FROM working_memory ORDER BY attention DESC LIMIT 200"):
                slot = WorkingMemorySlot(
                    content=row["content"],
                    slot_type=row["slot_type"],
                    attention=row["attention"],
                    created_at=row["created_at"],
                    last_accessed=row["last_accessed"],
                    access_count=row["access_count"],
                    metadata=json.loads(row["metadata"]),
                    bindings=json.loads(row["bindings"]),
                )
                self.working_memory[row["id"]] = slot

            # Load beliefs
            for row in c.execute("SELECT * FROM beliefs"):
                self.beliefs[row["id"]] = Belief(
                    id=row["id"],
                    proposition=row["proposition"],
                    confidence=row["confidence"],
                    evidence=json.loads(row["evidence"]),
                    source=row["source"],
                    created_at=row["created_at"],
                    updated_at=row["updated_at"],
                    domain=row["domain"],
                )

            # Load plans
            for row in c.execute("SELECT * FROM plans WHERE status IN ('draft', 'active')"):
                self.plans[row["id"]] = Plan(
                    id=row["id"],
                    goal_id=row["goal_id"],
                    steps=json.loads(row["steps"]),
                    status=row["status"],
                    created_at=row["created_at"],
                    updated_at=row["updated_at"],
                    resource_budget=json.loads(row["resource_budget"]),
                    checkpoints=json.loads(row["checkpoints"]),
                )

            # Load kernel state
            for row in c.execute("SELECT * FROM kernel_state"):
                if row["key"] == "active_plan_id":
                    self.active_plan_id = row["value"]
                elif row["key"] == "instance_id":
                    self.instance_id = row["value"]
                elif row["key"] == "created_at":
                    self.created_at = float(row["value"])

        # Sort goal stack by priority
        self.goal_stack.sort(key=lambda gid: self.goals[gid].priority, reverse=True)
        self._audit("kernel_load", f"Loaded {len(self.goals)} goals, {len(self.working_memory)} WM slots, {len(self.beliefs)} beliefs")

    def _save_goal(self, goal: Goal) -> None:
        with self._lock, self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO goals 
                (id, description, parent_id, children, status, priority, success_criteria,
                 constraints, created_at, updated_at, completed_at, progress, metadata,
                 assigned_agent, required_capabilities)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            """, (
                goal.id, goal.description, goal.parent_id, json.dumps(goal.children),
                goal.status.value, goal.priority, json.dumps(goal.success_criteria),
                json.dumps(goal.constraints), goal.created_at, goal.updated_at,
                goal.completed_at, goal.progress, json.dumps(goal.metadata),
                goal.assigned_agent, json.dumps(goal.required_capabilities)
            ))

    def _save_working_memory(self, slot_id: str, slot: WorkingMemorySlot) -> None:
        with self._lock, self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO working_memory
                (id, content, slot_type, attention, created_at, last_accessed, access_count, metadata, bindings)
                VALUES (?,?,?,?,?,?,?,?,?)
            """, (
                slot_id, slot.content, slot.slot_type, slot.attention,
                slot.created_at, slot.last_accessed, slot.access_count,
                json.dumps(slot.metadata), json.dumps(slot.bindings)
            ))

    def _save_belief(self, belief: Belief) -> None:
        with self._lock, self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO beliefs
                (id, proposition, confidence, evidence, source, created_at, updated_at, domain)
                VALUES (?,?,?,?,?,?,?,?)
            """, (
                belief.id, belief.proposition, belief.confidence,
                json.dumps(belief.evidence), belief.source,
                belief.created_at, belief.updated_at, belief.domain
            ))

    def _save_plan(self, plan: Plan) -> None:
        with self._lock, self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO plans
                (id, goal_id, steps, status, created_at, updated_at, resource_budget, checkpoints)
                VALUES (?,?,?,?,?,?,?,?)
            """, (
                plan.id, plan.goal_id, json.dumps(plan.steps), plan.status,
                plan.created_at, plan.updated_at, json.dumps(plan.resource_budget),
                json.dumps(plan.checkpoints)
            ))

    def _set_kernel_state(self, key: str, value: str) -> None:
        with self._lock, self._conn() as c:
            c.execute("INSERT OR REPLACE INTO kernel_state (key, value, updated_at) VALUES (?,?,?)",
                      (key, value, time.time()))

    def _audit(self, event_type: str, details: str) -> None:
        with self._lock, self._conn() as c:
            c.execute("INSERT INTO cognitive_audit (id, timestamp, event_type, details) VALUES (?,?,?,?)",
                      (uuid.uuid4().hex[:12], time.time(), event_type, details[:1000]))

    def _log_metacognitive(self, confidence: float, surprise: float, trigger: str, action: str) -> None:
        with self._lock, self._conn() as c:
            c.execute("INSERT INTO metacognitive_log (id, timestamp, confidence, surprise, trigger, action_taken) VALUES (?,?,?,?,?,?)",
                      (uuid.uuid4().hex[:12], time.time(), confidence, surprise, trigger, action))

    # =========================================================================
    # Working Memory Operations
    # =========================================================================

    def wm_add(self, content: str, slot_type: str = "fact", attention: float = 1.0,
               metadata: Dict = None, bindings: Dict = None) -> str:
        """Add item to working memory."""
        slot_id = uuid.uuid4().hex[:12]
        slot = WorkingMemorySlot(
            content=content,
            slot_type=slot_type,
            attention=attention,
            metadata=metadata or {},
            bindings=bindings or {}
        )
        with self._lock:
            self.working_memory[slot_id] = slot
            self._save_working_memory(slot_id, slot)
        return slot_id

    def wm_get(self, slot_id: str) -> Optional[WorkingMemorySlot]:
        with self._lock:
            slot = self.working_memory.get(slot_id)
            if slot:
                slot.access()
                self._save_working_memory(slot_id, slot)
            return slot

    def wm_search(self, query: str, limit: int = 10, slot_type: str = None) -> List[WorkingMemorySlot]:
        """Search working memory by content similarity (simple token overlap)."""
        query_tokens = set(query.lower().split())
        results = []
        with self._lock:
            for slot in self.working_memory.values():
                if slot_type and slot.slot_type != slot_type:
                    continue
                content_tokens = set(slot.content.lower().split())
                if query_tokens & content_tokens:
                    overlap = len(query_tokens & content_tokens) / len(query_tokens | content_tokens)
                    results.append((overlap, slot))
        results.sort(key=lambda x: x[0], reverse=True)
        return [r[1] for r in results[:limit]]

    def wm_decay_all(self, rate: float = 0.05) -> int:
        """Apply decay to all working memory slots. Returns count of slots decayed to zero."""
        removed = 0
        with self._lock:
            to_remove = []
            for slot_id, slot in self.working_memory.items():
                slot.decay(rate)
                if slot.attention <= 0.05:
                    to_remove.append(slot_id)
                else:
                    self._save_working_memory(slot_id, slot)
            for slot_id in to_remove:
                del self.working_memory[slot_id]
                with self._conn() as c:
                    c.execute("DELETE FROM working_memory WHERE id = ?", (slot_id,))
                removed += 1
        return removed

    def wm_capacity(self) -> Dict:
        with self._lock:
            by_type = {}
            for slot in self.working_memory.values():
                by_type[slot.slot_type] = by_type.get(slot.slot_type, 0) + 1
            return {
                "total_slots": len(self.working_memory),
                "by_type": by_type,
                "total_attention": sum(s.attention for s in self.working_memory.values()),
                "attention_budget": self.attention_budget
            }

    # =========================================================================
    # Goal Management
    # =========================================================================

    def create_goal(self, description: str, parent_id: str = None,
                    priority: float = GoalPriority.NORMAL.value,
                    success_criteria: List[str] = None,
                    constraints: Dict = None,
                    required_capabilities: List[str] = None) -> Goal:
        """Create a new goal, optionally as child of parent."""
        goal_id = uuid.uuid4().hex[:12]
        goal = Goal(
            id=goal_id,
            description=description,
            parent_id=parent_id,
            priority=priority,
            success_criteria=success_criteria or [],
            constraints=constraints or {},
            required_capabilities=required_capabilities or []
        )
        with self._lock:
            self.goals[goal_id] = goal
            self._save_goal(goal)
            if parent_id and parent_id in self.goals:
                self.goals[parent_id].children.append(goal_id)
                self._save_goal(self.goals[parent_id])
            if goal.status == GoalStatus.ACTIVE:
                self.goal_stack.append(goal_id)
                self.goal_stack.sort(key=lambda gid: self.goals[gid].priority, reverse=True)
        self._audit("goal_create", f"Created goal {goal_id}: {description[:80]}")
        return goal

    def get_goal(self, goal_id: str) -> Optional[Goal]:
        with self._lock:
            return self.goals.get(goal_id)

    def update_goal(self, goal_id: str, **kwargs) -> Optional[Goal]:
        with self._lock:
            goal = self.goals.get(goal_id)
            if not goal:
                return None
            for key, value in kwargs.items():
                if hasattr(goal, key):
                    setattr(goal, key, value)
            goal.updated_at = time.time()
            if "status" in kwargs:
                status_val = kwargs["status"]
                if isinstance(status_val, str):
                    goal.status = GoalStatus(status_val)
                elif isinstance(status_val, GoalStatus):
                    goal.status = status_val
            self._save_goal(goal)
            if goal.status == GoalStatus.ACTIVE and goal_id not in self.goal_stack:
                self.goal_stack.append(goal_id)
            elif goal.status != GoalStatus.ACTIVE and goal_id in self.goal_stack:
                self.goal_stack.remove(goal_id)
            self.goal_stack.sort(key=lambda gid: self.goals[gid].priority, reverse=True)
        return goal

    def decompose_goal(self, goal_id: str, num_subgoals: int = 5) -> List[Goal]:
        """Decompose a goal into subgoals using LLM."""
        goal = self.get_goal(goal_id)
        if not goal or not self.llm_fn:
            return []

        prompt = f"""
Goal: {goal.description}

Decompose this goal into {num_subgoals} concrete, actionable subgoals.
Each subgoal should be a single sentence describing a specific task.
Return ONLY a JSON array of strings, no other text:
["subgoal one", "subgoal two", ...]
"""
        try:
            raw = self.llm_fn(prompt)
            raw = raw.strip()
            if "[" in raw and "]" in raw:
                raw = raw[raw.index("["):raw.rindex("]") + 1]
            subgoals = json.loads(raw)
            if not isinstance(subgoals, list):
                return []
        except Exception:
            return []

        created = []
        for desc in subgoals:
            if not isinstance(desc, str) or len(desc.strip()) < 5:
                continue
            subgoal = self.create_goal(
                description=desc.strip(),
                parent_id=goal_id,
                priority=goal.priority * 0.9,
                required_capabilities=goal.required_capabilities
            )
            created.append(subgoal)
        return created

    def get_active_goals(self) -> List[Goal]:
        with self._lock:
            return [self.goals[gid] for gid in self.goal_stack if gid in self.goals]

    def get_next_goal(self) -> Optional[Goal]:
        """Get the highest priority active goal that can be worked on."""
        with self._lock:
            for gid in self.goal_stack:
                goal = self.goals.get(gid)
                if goal and goal.status == GoalStatus.ACTIVE:
                    # Check if dependencies are met
                    if goal.parent_id:
                        parent = self.goals.get(goal.parent_id)
                        if parent and parent.status not in (GoalStatus.COMPLETED, GoalStatus.ABANDONED):
                            continue
                    return goal
        return None

    # =========================================================================
    # Belief Management (World Model Interface)
    # =========================================================================

    def add_belief(self, proposition: str, confidence: float = 0.5,
                   evidence: List[str] = None, source: str = "observation",
                   domain: str = "general") -> Belief:
        """Add or update a belief about the world."""
        belief_id = uuid.uuid4().hex[:12]
        belief = Belief(
            id=belief_id,
            proposition=proposition,
            confidence=max(0.0, min(1.0, confidence)),
            evidence=evidence or [],
            source=source,
            domain=domain
        )
        with self._lock:
            self.beliefs[belief_id] = belief
            self._save_belief(belief)
        return belief

    def update_belief(self, belief_id: str, confidence: float = None,
                      evidence: List[str] = None, proposition: str = None,
                      source: str = None) -> Optional[Belief]:
        with self._lock:
            belief = self.beliefs.get(belief_id)
            if not belief:
                return None
            if confidence is not None:
                belief.confidence = max(0.0, min(1.0, confidence))
            if evidence is not None:
                belief.evidence = evidence
            if proposition is not None:
                belief.proposition = proposition
            if source is not None:
                belief.source = source
            belief.updated_at = time.time()
            self._save_belief(belief)
        return belief

    def query_beliefs(self, domain: str = None, min_confidence: float = 0.0) -> List[Belief]:
        with self._lock:
            results = [b for b in self.beliefs.values() if b.confidence >= min_confidence]
            if domain:
                results = [b for b in results if b.domain == domain]
            return sorted(results, key=lambda b: b.confidence, reverse=True)

    def simulate(self, action: Dict, domain: str = "general") -> Dict:
        """Simulate an action using the world model for the domain."""
        model = self.world_models.get(domain)
        if not model or not hasattr(model, 'simulate'):
            return {"error": f"No world model for domain: {domain}", "predicted_state": None}
        try:
            return model.simulate(action)
        except Exception as e:
            return {"error": str(e), "predicted_state": None}

    # =========================================================================
    # Planning
    # =========================================================================

    def create_plan(self, goal_id: str, steps: List[Dict] = None) -> Plan:
        """Create a plan for a goal. If steps not provided, generate via LLM."""
        goal = self.get_goal(goal_id)
        if not goal:
            raise ValueError(f"Goal not found: {goal_id}")

        plan_id = uuid.uuid4().hex[:12]
        
        if steps is None and self.llm_fn:
            steps = self._generate_plan_steps(goal)
        
        plan = Plan(
            id=plan_id,
            goal_id=goal_id,
            steps=steps or [],
            resource_budget=self._estimate_resources(steps or [])
        )
        with self._lock:
            self.plans[plan_id] = plan
            self._save_plan(plan)
            self.active_plan_id = plan_id
            self._set_kernel_state("active_plan_id", plan_id)
        self._audit("plan_create", f"Created plan {plan_id} for goal {goal_id} with {len(plan.steps)} steps")
        return plan

    def _generate_plan_steps(self, goal: Goal) -> List[Dict]:
        """Generate plan steps using LLM."""
        available_caps = []
        if self.capability_registry:
            available_caps = self.capability_registry.list_capabilities()
        
        prompt = f"""
Goal: {goal.description}
Success criteria: {goal.success_criteria}
Constraints: {goal.constraints}
Required capabilities: {goal.required_capabilities}

Available capabilities: {available_caps[:20]}

Generate a step-by-step plan as JSON array. Each step:
{{"id": "step_1", "description": "...", "action": "...", "expected_outcome": "...", 
  "required_capability": "...", "contingency": "..."}}
Return ONLY the JSON array.
"""
        try:
            raw = self.llm_fn(prompt)
            raw = raw.strip()
            if "[" in raw and "]" in raw:
                raw = raw[raw.index("["):raw.rindex("]") + 1]
            steps = json.loads(raw)
            if isinstance(steps, list):
                return steps
        except Exception:
            pass
        return []

    def _estimate_resources(self, steps: List[Dict]) -> Dict:
        return {
            "estimated_steps": len(steps),
            "estimated_api_calls": sum(1 for s in steps if s.get("required_capability")),
            "estimated_time_minutes": len(steps) * 5,
            "estimated_cost_usd": len(steps) * 0.01
        }

    def execute_plan_step(self, plan_id: str, step_index: int, 
                          executor: Callable) -> Dict:
        """Execute a single plan step with monitoring."""
        plan = self.plans.get(plan_id)
        if not plan or step_index >= len(plan.steps):
            return {"error": "Invalid plan or step index"}

        step = plan.steps[step_index]
        self._audit("plan_step_start", f"Plan {plan_id} step {step_index}: {step.get('description')}")

        # Pre-execution simulation if world model available
        domain = step.get("domain", "general")
        if domain in self.world_models:
            sim_result = self.simulate({"action": step.get("action"), "params": step}, domain)
            if sim_result.get("error"):
                self._log_metacognitive(0.0, 0.8, "simulation_error", "proceed_despite_warning")

        # Execute
        start_time = time.time()
        try:
            result = executor(step)
            success = result.get("success", False)
            output = result.get("output", "")
            duration = time.time() - start_time

            # Update step with result
            step["result"] = output
            step["success"] = success
            step["duration"] = duration
            step["executed_at"] = time.time()
            
            plan.updated_at = time.time()
            plan.checkpoints.append({
                "step_index": step_index,
                "timestamp": time.time(),
                "success": success
            })
            self._save_plan(plan)

            # Metacognitive assessment
            confidence = 1.0 if success else 0.0
            surprise = 0.0 if success else 0.7
            self._log_metacognitive(confidence, surprise, f"step_{step_index}", 
                                   "completed" if success else "failed")

            # Check for replanning trigger
            if not success and confidence < self.confidence_threshold:
                self._trigger_replan(plan_id, step_index, "step_failed")

            return {"success": success, "output": output, "confidence": confidence}

        except Exception as e:
            duration = time.time() - start_time
            step["error"] = str(e)
            step["success"] = False
            step["duration"] = duration
            plan.updated_at = time.time()
            self._save_plan(plan)
            self._log_metacognitive(0.0, 0.9, f"step_{step_index}", "exception")
            self._trigger_replan(plan_id, step_index, "exception")
            return {"success": False, "error": str(e), "confidence": 0.0}

    def _trigger_replan(self, plan_id: str, failed_step: int, reason: str) -> None:
        """Trigger replanning from failure point."""
        plan = self.plans.get(plan_id)
        if not plan:
            return
        plan.status = "replanning"
        self.replan_triggers.append({
            "plan_id": plan_id,
            "failed_step": failed_step,
            "reason": reason,
            "timestamp": time.time()
        })
        self._audit("replan_trigger", f"Plan {plan_id} replanning triggered at step {failed_step}: {reason}")

    def replan(self, plan_id: str, from_step: int = 0) -> Plan:
        """Replan from a given step."""
        plan = self.plans.get(plan_id)
        if not plan:
            raise ValueError(f"Plan not found: {plan_id}")
        
        goal = self.get_goal(plan.goal_id)
        if not goal:
            raise ValueError(f"Goal not found: {plan.goal_id}")

        # Keep completed steps, regenerate from failure point
        completed_steps = plan.steps[:from_step]
        remaining_goal = f"Continue from step {from_step}: {goal.description}"
        
        new_steps = self._generate_plan_steps(goal)
        plan.steps = completed_steps + new_steps[from_step:]
        plan.status = "active"
        plan.updated_at = time.time()
        self._save_plan(plan)
        self._audit("replan", f"Plan {plan_id} replanned from step {from_step}")
        return plan

    # =========================================================================
    # Background Cognitive Threads
    # =========================================================================

    def start(self) -> None:
        """Start background cognitive threads."""
        if self._running:
            return
        self._running = True

        self._stop_events = {
            "perception": threading.Event(),
            "consolidation": threading.Event(),
            "planning": threading.Event(),
            "monitoring": threading.Event(),
            "curiosity": threading.Event(),
            "checkpoint": threading.Event(),
        }

        self._threads = {
            "perception": threading.Thread(target=self._perception_loop, daemon=True),
            "consolidation": threading.Thread(target=self._consolidation_loop, daemon=True),
            "planning": threading.Thread(target=self._planning_loop, daemon=True),
            "monitoring": threading.Thread(target=self._monitoring_loop, daemon=True),
            "curiosity": threading.Thread(target=self._curiosity_loop, daemon=True),
            "checkpoint": threading.Thread(target=self._checkpoint_loop, daemon=True),
        }

        for t in self._threads.values():
            t.start()

        self._audit("kernel_start", "Cognitive kernel started")

    def stop(self) -> None:
        """Stop background threads and checkpoint."""
        self._running = False
        for event in self._stop_events.values():
            event.set()
        for name, thread in self._threads.items():
            thread.join(timeout=5.0)
        self.checkpoint()
        self._audit("kernel_stop", "Cognitive kernel stopped")

    def _perception_loop(self) -> None:
        """Perceive environment changes, update beliefs."""
        while not self._stop_events["perception"].wait(30):  # Every 30s
            try:
                self._perceive_environments()
            except Exception as e:
                self._audit("perception_error", str(e))

    def _perceive_environments(self) -> None:
        """Query each world model for state changes."""
        for domain, model in self.world_models.items():
            if hasattr(model, 'observe'):
                try:
                    observations = model.observe()
                    for obs in observations:
                        self._process_observation(obs, domain)
                except Exception:
                    pass

    def _process_observation(self, observation: Dict, domain: str) -> None:
        """Process an observation, update beliefs and working memory."""
        # Extract proposition from observation
        prop = observation.get("proposition") or observation.get("fact") or str(observation)
        confidence = observation.get("confidence", 0.8)
        
        # Check if belief exists
        existing = None
        for b in self.beliefs.values():
            if b.proposition == prop and b.domain == domain:
                existing = b
                break
        
        if existing:
            # Update confidence (Bayesian-ish update)
            new_conf = min(1.0, existing.confidence + (confidence - existing.confidence) * 0.3)
            self.update_belief(existing.id, confidence=new_conf, 
                              evidence=existing.evidence + [f"Observed at {time.time()}"])
        else:
            self.add_belief(prop, confidence=confidence, 
                           evidence=[f"Observed at {time.time()}"], domain=domain)

        # Add to working memory as observation
        self.wm_add(f"[{domain}] {prop}", slot_type="observation", attention=0.7,
                   metadata={"domain": domain, "source": "perception"})

    def _consolidation_loop(self) -> None:
        """Consolidate working memory to long-term, distill episodes to skills."""
        while not self._stop_events["consolidation"].wait(300):  # Every 5 min
            try:
                self._consolidate()
            except Exception as e:
                self._audit("consolidation_error", str(e))

    def _consolidate(self) -> None:
        """Move high-attention WM items to long-term memory, distill episodes."""
        with self._lock:
            # Promote high-attention WM slots
            for slot_id, slot in list(self.working_memory.items()):
                if slot.attention > 0.8 and slot.access_count > 2:
                    if self.memory_manager:
                        self.memory_manager.add(slot.content, memory_type=slot.slot_type,
                                              metadata={**slot.metadata, "consolidated_from_wm": True})
                    slot.attention *= 0.5  # Reduce but keep in WM
                    self._save_working_memory(slot_id, slot)

            # Decay all
            self.wm_decay_all(0.02)

        # Phase 36: knowledge maintenance — stale beliefs weaken and fade,
        # keeping the knowledge base from ossifying around outdated facts.
        try:
            self.decay_beliefs()
            self.forget_low_confidence()
        except Exception as e:
            self._audit("knowledge_maintenance_error", str(e))

        # Episode distillation (if we have episodic memory)
        if self.memory_manager and hasattr(self.memory_manager, 'episodic'):
            try:
                recent = self.memory_manager.episodic.get_recent(limit=50)
                for ep in recent:
                    if ep.get("success") and ep.get("goal"):
                        # Distill successful episodes into procedural knowledge
                        self._distill_episode(ep)
            except Exception:
                pass

    def _distill_episode(self, episode: Dict) -> None:
        """Distill a successful episode into a reusable skill pattern."""
        # This would create a skill in the capability registry
        if self.capability_registry:
            pass  # Implementation depends on capability registry design

    def _planning_loop(self) -> None:
        """Maintain and update plans for active goals."""
        while not self._stop_events["planning"].wait(60):  # Every minute
            try:
                self._maintain_plans()
            except Exception as e:
                self._audit("planning_error", str(e))

    def _maintain_plans(self) -> None:
        """Ensure active goals have plans, update progress."""
        with self._lock:
            active_goals = self.get_active_goals()
        
        for goal in active_goals[:3]:  # Limit concurrent planning
            # Check if goal has active plan
            has_plan = any(p.goal_id == goal.id and p.status == "active" for p in self.plans.values())
            if not has_plan:
                self.create_plan(goal.id)
            
            # Update goal progress based on plan checkpoints
            for plan in self.plans.values():
                if plan.goal_id == goal.id and plan.steps:
                    completed = sum(1 for s in plan.steps if s.get("success"))
                    goal.progress = completed / len(plan.steps)
                    self.update_goal(goal.id, progress=goal.progress)
                    if goal.progress >= 1.0:
                        self.update_goal(goal.id, status=GoalStatus.COMPLETED.value,
                                       completed_at=time.time())

    def _monitoring_loop(self) -> None:
        """Monitor progress, detect anomalies, trigger recovery."""
        while not self._stop_events["monitoring"].wait(15):  # Every 15s
            try:
                self._monitor()
            except Exception as e:
                self._audit("monitoring_error", str(e))

    def _monitor(self) -> None:
        """Check for stalls, resource exhaustion, surprises."""
        # Check for stalled goals
        for goal in self.get_active_goals():
            if time.time() - goal.updated_at > 3600:  # 1 hour no update
                self._audit("stall_detected", f"Goal {goal.id} stalled: {goal.description[:80]}")
                # Could trigger replanning or escalation

        # Check intervention
        if self.intervention:
            try:
                if self.intervention.check_interrupt():
                    self._audit("intervention", "Intervention mode activated")
            except Exception:
                pass

    def _curiosity_loop(self) -> None:
        """Identify knowledge gaps, trigger exploration."""
        while not self._stop_events["curiosity"].wait(600):  # Every 10 min
            try:
                self._seek_novelty()
            except Exception as e:
                self._audit("curiosity_error", str(e))

    def _seek_novelty(self) -> None:
        """Find domains with low belief coverage, spawn research goals."""
        domains = ["filesystem", "codebase", "server", "browser", "api", "database"]
        for domain in domains:
            beliefs = self.query_beliefs(domain=domain, min_confidence=0.3)
            if len(beliefs) < 5:  # Low knowledge in this domain
                # Could spawn a research goal
                self._audit("curiosity_gap", f"Low knowledge in domain: {domain} ({len(beliefs)} beliefs)")

    def _checkpoint_loop(self) -> None:
        """Periodic checkpointing of kernel state."""
        while not self._stop_events["checkpoint"].wait(self.checkpoint_interval):
            try:
                self.checkpoint()
            except Exception as e:
                self._audit("checkpoint_error", str(e))

    def checkpoint(self) -> str:
        """Save full kernel state to checkpoint file."""
        checkpoint_id = f"checkpoint_{int(time.time())}_{uuid.uuid4().hex[:8]}"
        checkpoint_path = CHECKPOINT_DIR / f"{checkpoint_id}.json"
        
        state = {
            "instance_id": self.instance_id,
            "version": self.version,
            "timestamp": time.time(),
            "goals": {gid: {
                "id": g.id, "description": g.description, "parent_id": g.parent_id,
                "children": g.children, "status": g.status.value, "priority": g.priority,
                "success_criteria": g.success_criteria, "constraints": g.constraints,
                "created_at": g.created_at, "updated_at": g.updated_at,
                "completed_at": g.completed_at, "progress": g.progress,
                "metadata": g.metadata, "assigned_agent": g.assigned_agent,
                "required_capabilities": g.required_capabilities
            } for gid, g in self.goals.items()},
            "working_memory": {sid: {
                "content": s.content, "slot_type": s.slot_type, "attention": s.attention,
                "created_at": s.created_at, "last_accessed": s.last_accessed,
                "access_count": s.access_count, "metadata": s.metadata, "bindings": s.bindings
            } for sid, s in self.working_memory.items()},
            "beliefs": {bid: {
                "proposition": b.proposition, "confidence": b.confidence,
                "evidence": b.evidence, "source": b.source,
                "created_at": b.created_at, "updated_at": b.updated_at, "domain": b.domain
            } for bid, b in self.beliefs.items()},
            "plans": {pid: {
                "id": p.id, "goal_id": p.goal_id, "steps": p.steps, "status": p.status,
                "created_at": p.created_at, "updated_at": p.updated_at,
                "resource_budget": p.resource_budget, "checkpoints": p.checkpoints
            } for pid, p in self.plans.items()},
            "active_plan_id": self.active_plan_id,
            "goal_stack": self.goal_stack,
        }
        
        checkpoint_path.write_text(json.dumps(state, indent=2))
        self.last_checkpoint = time.time()
        
        # Clean old checkpoints (keep last 10)
        checkpoints = sorted(CHECKPOINT_DIR.glob("checkpoint_*.json"))
        for old in checkpoints[:-10]:
            old.unlink(missing_ok=True)
        
        return checkpoint_id

    def restore_checkpoint(self, checkpoint_id: str) -> bool:
        """Restore kernel state from checkpoint."""
        checkpoint_path = CHECKPOINT_DIR / f"{checkpoint_id}.json"
        if not checkpoint_path.exists():
            return False
        
        state = json.loads(checkpoint_path.read_text())
        
        with self._lock:
            # Restore goals
            self.goals.clear()
            self.goal_stack.clear()
            for gid, gdata in state.get("goals", {}).items():
                goal = Goal(**gdata)
                goal.status = GoalStatus(gdata["status"])
                self.goals[gid] = goal
                if goal.status == GoalStatus.ACTIVE:
                    self.goal_stack.append(gid)
            self.goal_stack.sort(key=lambda gid: self.goals[gid].priority, reverse=True)
            
            # Restore working memory
            self.working_memory.clear()
            for sid, sdata in state.get("working_memory", {}).items():
                self.working_memory[sid] = WorkingMemorySlot(**sdata)
            
            # Restore beliefs
            self.beliefs.clear()
            for bid, bdata in state.get("beliefs", {}).items():
                self.beliefs[bid] = Belief(**bdata)
            
            # Restore plans
            self.plans.clear()
            for pid, pdata in state.get("plans", {}).items():
                self.plans[pid] = Plan(**pdata)
            
            self.active_plan_id = state.get("active_plan_id")
            self._set_kernel_state("active_plan_id", self.active_plan_id or "")
        
        self._audit("checkpoint_restore", f"Restored from {checkpoint_id}")
        return True

    def list_checkpoints(self) -> List[Dict]:
        checkpoints = []
        for path in sorted(CHECKPOINT_DIR.glob("checkpoint_*.json"), reverse=True):
            try:
                data = json.loads(path.read_text())
                checkpoints.append({
                    "id": path.stem,
                    "timestamp": data.get("timestamp"),
                    "goals": len(data.get("goals", {})),
                    "wm_slots": len(data.get("working_memory", {})),
                    "beliefs": len(data.get("beliefs", {})),
                    "plans": len(data.get("plans", {})),
                })
            except Exception:
                pass
        return checkpoints

    # =========================================================================
    # Metacognitive Interface
    # =========================================================================

    def assess_confidence(self, context: str = "") -> float:
        """Assess overall confidence in current trajectory."""
        if not self.active_plan_id:
            return 0.5
        plan = self.plans.get(self.active_plan_id)
        if not plan or not plan.steps:
            return 0.5
        
        completed = [s for s in plan.steps if s.get("success") is not None]
        if not completed:
            return 0.5
        
        success_rate = sum(1 for s in completed if s.get("success")) / len(completed)
        return success_rate

    def detect_surprise(self, expected: Dict, actual: Dict) -> float:
        """Compute surprise as KL divergence between expected and actual outcome."""
        # Simplified: surprise = 1 - similarity
        expected_str = json.dumps(expected, sort_keys=True)
        actual_str = json.dumps(actual, sort_keys=True)
        
        # Simple token overlap
        exp_tokens = set(expected_str.lower().split())
        act_tokens = set(actual_str.lower().split())
        if not exp_tokens or not act_tokens:
            return 0.5
        overlap = len(exp_tokens & act_tokens) / len(exp_tokens | act_tokens)
        return 1.0 - overlap

    def get_metacognitive_state(self) -> Dict:
        return {
            "overall_confidence": self.assess_confidence(),
            "active_goals": len(self.get_active_goals()),
            "active_plan": self.active_plan_id,
            "working_memory_load": self.wm_capacity(),
            "belief_count": len(self.beliefs),
            "recent_replans": len([r for r in self.replan_triggers 
                                   if time.time() - r["timestamp"] < 3600]),
            "performance_history": self.performance_history[-10:],
        }

    # =========================================================================
    # Phase 34 — Unified Cognitive Loop (single central control path)
    # =========================================================================

    def register_executor(self, fn: Callable) -> None:
        """Register the ONE execution backend (Maya's own pipeline).

        The backend contract: fn(description, cognitive_context) -> dict with
        at least {"success": bool, "result": str}.  Everything the backend
        uses internally (LLM providers, workflow engine, agents, tools) is a
        capability of Maya — none of them may register themselves as a second
        controller.  Calling this again REPLACES the previous backend.
        """
        self._executor = fn

    @property
    def has_executor(self) -> bool:
        return self._executor is not None

    def _gather_cognitive_context(self, description: str) -> Dict:
        """Collect what Maya already knows relevant to this goal."""
        wm_hits = [
            {"content": s.content, "slot_type": s.slot_type, "attention": s.attention}
            for s in self.wm_search(description, limit=5)
        ]
        tokens = set(description.lower().split())
        relevant_beliefs = [
            {"proposition": b.proposition, "confidence": b.confidence,
             "domain": b.domain}
            for b in self.query_beliefs(min_confidence=0.4)
            if len(tokens & set(b.proposition.lower().split())) >= 1
        ][:10]
        return {
            "working_memory": wm_hits,
            "beliefs": relevant_beliefs,
            "skills": self._relevant_skills(description),
            "overall_confidence": self.assess_confidence(),
        }

    def _relevant_skills(self, description: str) -> List[Dict]:
        """Learned skills applicable to this goal (Phase 37)."""
        pm = self.procedural_memory
        if pm is None or not hasattr(pm, "search_skills"):
            return []
        try:
            return pm.search_skills(description, limit=3)
        except Exception:
            return []

    def process_goal(self, description: str,
                     priority: float = GoalPriority.NORMAL.value,
                     metadata: Dict = None,
                     execute: bool = True) -> Dict:
        """THE single control entry for goals.

        Creates a persistent kernel goal, grounds it in memory and beliefs,
        then either delegates execution to the registered backend (Maya's
        pipeline — which keeps its own risk/approval gates) or, when execution
        is not requested/backend missing, returns a propose-only plan.
        """
        description = (description or "").strip()
        if not description:
            return {"success": False, "error": "empty goal description"}

        goal = self.create_goal(description, priority=priority)
        if metadata:
            self.update_goal(goal.id, metadata=dict(metadata))
        self.wm_add(f"GOAL: {description}", slot_type="goal")
        return self._drive_goal(goal, execute=execute, resumed=False)

    # ── Phase 35: persistent goal pursuit ────────────────────────────

    def get_incomplete_goals(self) -> List[Goal]:
        """Goals that survived a restart but were never finished."""
        with self._lock:
            incomplete = [
                g for g in self.goals.values()
                if g.status in (GoalStatus.ACTIVE, GoalStatus.SUSPENDED,
                                GoalStatus.BLOCKED)
                and g.progress < 1.0
            ]
        incomplete.sort(key=lambda g: g.priority, reverse=True)
        return incomplete

    def resume_goal(self, goal_id: str, execute: bool = False) -> Dict:
        """Continue an incomplete goal through the unified loop.

        Propose-only by default even for previously-executing goals —
        resumption that acts on the world is always explicit.
        """
        goal = self.get_goal(goal_id)
        if not goal:
            return {"success": False, "error": f"goal not found: {goal_id}"}
        if goal.status in (GoalStatus.COMPLETED, GoalStatus.ABANDONED):
            return {"success": False,
                    "error": f"goal already {goal.status.value}: {goal_id}"}
        self.wm_add(f"RESUME: {goal.description[:100]}", slot_type="goal")
        result = self._drive_goal(goal, execute=execute, resumed=True)
        result["resumed"] = True
        return result

    def _drive_goal(self, goal: Goal, execute: bool, resumed: bool) -> Dict:
        """Run one goal through the unified loop (shared by new + resumed)."""
        ctx = self._gather_cognitive_context(goal.description)
        self._audit(
            "unified_goal_start",
            f"[{goal.id}] {'resume' if resumed else 'new'} "
            f"{goal.description[:120]}",
        )

        result: Dict = {
            "goal_id": goal.id,
            "description": goal.description,
            "cognitive_context": ctx,
        }

        executor = self._executor
        if not execute or executor is None:
            # Propose-only: build a plan, do NOT act on the world.
            plan = self.create_plan(goal.id)
            self.update_goal(goal.id, status=GoalStatus.SUSPENDED.value)
            result.update({
                "mode": "propose_only" if executor is not None else "no_executor",
                "success": True,
                "plan_id": plan.id,
                "plan_steps": plan.steps,
                "executed": False,
            })
            self._audit("unified_goal_proposed", f"[{goal.id}] plan {plan.id}")
            return result

        start_time = time.time()
        try:
            outcome = executor(goal.description, ctx)
        except Exception as e:
            outcome = {"success": False, "result": f"executor exception: {e}"}
        duration = time.time() - start_time

        success = bool(outcome.get("success"))
        if success:
            self.update_goal(goal.id, status=GoalStatus.COMPLETED.value,
                             progress=1.0, completed_at=time.time())
        else:
            self.update_goal(goal.id, status=GoalStatus.BLOCKED.value)

        # Learn: record outcome as a performance data point and a belief.
        self.performance_history.append({
            "goal_id": goal.id, "success": success,
            "duration": duration, "timestamp": time.time(),
        })
        proposition = f"Goal pattern '{goal.description[:80]}' -> {'success' if success else 'failure'}"
        self.add_belief(
            proposition,
            confidence=0.85 if success else 0.3,
            evidence=[f"goal:{goal.id}"],
            source="observation",
        )
        self.wm_add(
            f"OUTCOME({'ok' if success else 'fail'}): {goal.description[:100]}",
            slot_type="observation",
        )
        self._audit(
            "unified_goal_done",
            f"[{goal.id}] success={success} duration={duration:.1f}s",
        )

        # Phase 39: every outcome updates Maya's model of itself.
        sm = self.self_model
        if sm is not None and hasattr(sm, "record_outcome"):
            try:
                quality = outcome.get("quality_score")
                sm.record_outcome(goal.description, success, duration,
                                  quality=float(quality)
                                  if isinstance(quality, (int, float)) else None)
            except Exception as e:
                self._audit("self_model_error", str(e))

        result.update({
            "executed": True,
            "success": success,
            "outcome": {
                k: v for k, v in outcome.items()
                if k in ("success", "result", "error", "task_id", "quality_score")
            },
            "duration": duration,
        })
        return result

    # ── Phase 36: knowledge engine (belief revision + retrieval) ─────

    @staticmethod
    def _token_overlap(a: str, b: str) -> float:
        ta = set(a.lower().split())
        tb = set(b.lower().split())
        if not ta or not tb:
            return 0.0
        return len(ta & tb) / max(1, min(len(ta), len(tb)))

    def learn(self, proposition: str, confidence: float = 0.5,
              source: str = "observation", domain: str = "general",
              evidence: List[str] = None) -> Belief:
        """Acquire or revise knowledge with belief revision.

        If a closely-matching belief exists, the new evidence is fused via an
        odds-form Bayesian update — agreeing evidence strengthens, conflicting
        evidence weakens — instead of creating duplicate rows.
        """
        proposition = (proposition or "").strip()
        if not proposition:
            raise ValueError("empty proposition")
        confidence = max(0.01, min(0.99, float(confidence)))

        match = None
        best = 0.0
        with self._lock:
            candidates = list(self.beliefs.values())
        for b in candidates:
            sim = self._token_overlap(proposition, b.proposition)
            if sim > best:
                best = sim
                match = b

        if best >= 0.8 and match is not None:
            p_old, p_new = match.confidence, confidence
            denom = p_old * p_new + (1 - p_old) * (1 - p_new)
            fused = (p_old * p_new / denom) if denom > 0 else 0.5
            merged_ev = list(match.evidence) + (evidence or [])
            return self.update_belief(
                match.id,
                confidence=max(0.01, min(0.99, fused)),
                evidence=merged_ev[-10:],
                source=source,
            )

        return self.add_belief(
            proposition, confidence=confidence, evidence=evidence,
            source=source, domain=domain,
        )

    def knowledge_query(self, query: str, domain: str = None,
                        limit: int = 5, min_confidence: float = 0.2) -> List[Dict]:
        """Ranked knowledge retrieval feeding planning.

        Score = lexical relevance * 0.7 + confidence * 0.3, with a small
        recency bonus so freshly learned facts surface first.
        """
        query = (query or "").strip()
        if not query:
            return []
        now = time.time()
        scored = []
        with self._lock:
            beliefs = [b for b in self.beliefs.values()
                       if b.confidence >= min_confidence]
        for b in beliefs:
            if domain and b.domain != domain:
                continue
            rel = self._token_overlap(query, b.proposition)
            if rel <= 0:
                continue
            recency = max(0.0, 1.0 - (now - b.updated_at) / (30 * 86400))
            score = rel * 0.7 + b.confidence * 0.3 + 0.05 * recency
            scored.append((score, b))
        scored.sort(key=lambda sb: sb[0], reverse=True)
        return [{
            "proposition": b.proposition,
            "confidence": round(b.confidence, 3),
            "domain": b.domain,
            "source": b.source,
            "score": round(score, 3),
        } for score, b in scored[:limit]]

    def decay_beliefs(self, stale_after_days: float = 7.0,
                      factor: float = 0.95) -> int:
        """Weaken beliefs not touched recently (called from consolidation)."""
        cutoff = time.time() - stale_after_days * 86400
        n = 0
        with self._lock:
            targets = [b for b in self.beliefs.values() if b.updated_at < cutoff]
        for b in targets:
            new_c = b.confidence * factor
            if new_c < 0.02:
                self._delete_belief(b.id)
            else:
                self.update_belief(b.id, confidence=new_c)
            n += 1
        return n

    def forget_low_confidence(self, threshold: float = 0.05) -> int:
        """Prune beliefs that have decayed into noise."""
        with self._lock:
            doomed = [b.id for b in self.beliefs.values()
                      if b.confidence < threshold]
        for bid in doomed:
            self._delete_belief(bid)
        return len(doomed)

    def _delete_belief(self, belief_id: str) -> None:
        with self._lock:
            self.beliefs.pop(belief_id, None)
            try:
                with self._conn() as c:
                    c.execute("DELETE FROM beliefs WHERE id=?", (belief_id,))
            except Exception:
                pass

    def knowledge_stats(self) -> Dict:
        with self._lock:
            beliefs = list(self.beliefs.values())
        domains: Dict[str, int] = {}
        for b in beliefs:
            domains[b.domain] = domains.get(b.domain, 0) + 1
        return {
            "total": len(beliefs),
            "domains": domains,
            "avg_confidence": (
                round(sum(b.confidence for b in beliefs) / len(beliefs), 3)
                if beliefs else 0.0
            ),
        }

    def controller_status(self) -> Dict:
        """Expose unified-loop wiring state for /status routes."""
        return {
            "unified_loop_enabled": self.unified_loop_enabled,
            "has_executor": self._executor is not None,
        }

    # =========================================================================
    # Status & Control
    # =========================================================================

    def status(self) -> Dict:
        with self._lock:
            return {
                "instance_id": self.instance_id,
                "version": self.version,
                "uptime": time.time() - self.created_at,
                "running": self._running,
                "goals": {
                    "total": len(self.goals),
                    "active": len([g for g in self.goals.values() if g.status == GoalStatus.ACTIVE]),
                    "suspended": len([g for g in self.goals.values() if g.status == GoalStatus.SUSPENDED]),
                    "completed": len([g for g in self.goals.values() if g.status == GoalStatus.COMPLETED]),
                },
                "working_memory": self.wm_capacity(),
                "beliefs": len(self.beliefs),
                "plans": {
                    "total": len(self.plans),
                    "active": len([p for p in self.plans.values() if p.status == "active"]),
                },
                "active_plan_id": self.active_plan_id,
                "controller": self.controller_status(),
                "metacognitive": self.get_metacognitive_state(),
                "threads": {name: t.is_alive() for name, t in self._threads.items()},
                "last_checkpoint": self.last_checkpoint,
            }

    def get_recent_audit(self, limit: int = 20) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM cognitive_audit ORDER BY timestamp DESC LIMIT ?", (limit,)
            ).fetchall()
            return [dict(r) for r in rows]


# Module singleton
_cognitive_kernel: Optional[CognitiveKernel] = None


def get_cognitive_kernel(**kwargs) -> CognitiveKernel:
    global _cognitive_kernel
    if _cognitive_kernel is None:
        _cognitive_kernel = CognitiveKernel(**kwargs)
    return _cognitive_kernel


def set_cognitive_kernel(kernel: CognitiveKernel) -> None:
    global _cognitive_kernel
    _cognitive_kernel = kernel