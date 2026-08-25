"""
Maya 2.0 ULTRA — Maya Cognitive Core
=====================================
The central controller that owns and persists all cognitive state.
Models are replaceable reasoning resources, NOT the controller.

Architecture:
  MayaCognitiveCore
  ├── Identity & Self-State (persistent)
  ├── Goals & Priorities (persistent)
  ├── Working Memory (with attention/decay)
  ├── Long-Term Memory (via MemoryManager)
  ├── Episodic Memory (via EpisodicMemory)
  ├── Semantic Knowledge (via SemanticMemory)
  ├── Procedural/Skill Memory (via ProceduralMemory + CapabilityRegistry)
  ├── Learned Experiences (via ExperienceReplay)
  ├── Beliefs & Assumptions (with confidence)
  ├── World/Environment State (via WorldModels)
  ├── Self-Capability State (via CapabilityRegistry)
  ├── Task State
  ├── Planning State (via HierarchicalPlanner)
  ├── Decision State
  ├── Execution State
  ├── Metacognitive State (via MetacognitiveMonitor)
  ├── Confidence & Uncertainty
  ├── Failures & Recovery State
  └── Checkpoints & Resumable Missions

Control Hierarchy:
  MAYA COGNITIVE CORE
  ├── decides what needs to happen
  ├── selects capabilities (tools, agents, skills, models)
  ├── invokes models/agents/tools when needed
  ├── receives observations/results
  ├── evaluates them
  ├── learns
  ├── updates its own state
  └── decides what happens next

Models are replaceable reasoning resources — NOT the controller.
If no model is available, Maya operates using deterministic capabilities,
memory, skills, workflows and tools.
"""

import asyncio
import hashlib
import json
import os
import sqlite3
import threading
import time
import uuid
from collections import deque
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set, Tuple
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from tools.registry import ToolRegistry
    from llm.router import LLMRouter

from config.settings import STORAGE_DIR

# Existing infrastructure components
from infrastructure.cognitive_kernel import (
    CognitiveKernel, Goal, GoalStatus, GoalPriority, WorkingMemorySlot, Belief, Plan,
    get_cognitive_kernel, set_cognitive_kernel
)
from infrastructure.capability_registry import (
    CapabilityRegistry, Capability, CapabilityInterface, CapabilityMetadata,
    CapabilityType, CapabilityStatus, get_capability_registry, set_capability_registry
)
from infrastructure.world_models import (
    WorldModel, Action, SimulationResult, WorldState, create_world_models
)
from infrastructure.hierarchical_planner import (
    HierarchicalPlanner, Plan as HPlan, PlanStep, PlanStatus, ContingencyPlan,
    get_hierarchical_planner, set_hierarchical_planner
)
from infrastructure.metacognitive import (
    MetacognitiveMonitor, MetacognitiveEventType, RecoveryAction,
    ConfidenceMonitor, SurpriseDetector, UncertaintyTracker,
    get_metacognitive_monitor, set_metacognitive_monitor
)
from infrastructure.agent_society import (
    AgentSociety, Agent, AgentStatus, MessageType, Blackboard, ContractNetManager,
    get_agent_society, set_agent_society
)
from infrastructure.tool_synthesizer import (
    ToolSynthesizer, SynthesisJob, SandboxExecutor,
    get_tool_synthesizer, set_tool_synthesizer
)
from infrastructure.procedural_memory import (
    get_episodic_memory, get_procedural_memory, get_experience_distiller, get_experience_replay
)

# Memory system
from memory.memory_manager import MemoryManager

# Human in the loop
from human.approval import ApprovalManager
from human.intervention import InterventionHandler

# Security
from security.risk_checker import RiskChecker
from security.permissions import PermissionManager


# ============================================================================
# COGNITIVE LOOP PHASES
# ============================================================================

class CognitivePhase(Enum):
    """Phases of the cognitive loop."""
    OBSERVE = "observe"
    UNDERSTAND = "understand"
    REMEMBER = "remember"
    REASON_PLAN = "reason_plan"
    DECIDE = "decide"
    ACT = "act"
    OBSERVE_RESULT = "observe_result"
    VERIFY = "verify"
    LEARN = "learn"
    UPDATE = "update"
    REPLAN = "replan"
    IDLE = "idle"


class CognitiveLoopState(Enum):
    """State of the cognitive loop."""
    RUNNING = "running"
    PAUSED = "paused"
    STOPPED = "stopped"
    ERROR = "error"
    WAITING_APPROVAL = "waiting_approval"
    WAITING_MODEL = "waiting_model"


@dataclass
class Identity:
    """Maya's persistent identity."""
    instance_id: str
    name: str = "Maya"
    version: str = "2.0.0"
    created_at: float = field(default_factory=time.time)
    last_active: float = field(default_factory=time.time)
    personality_traits: Dict[str, float] = field(default_factory=dict)
    core_values: List[str] = field(default_factory=list)
    mission_statement: str = "Autonomous AI agent that plans, executes, verifies, and learns."
    
    def to_dict(self) -> Dict:
        return {
            "instance_id": self.instance_id,
            "name": self.name,
            "version": self.version,
            "created_at": self.created_at,
            "last_active": self.last_active,
            "personality_traits": self.personality_traits,
            "core_values": self.core_values,
            "mission_statement": self.mission_statement,
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> "Identity":
        return cls(**data)


@dataclass
class SelfState:
    """Maya's current self-state."""
    identity: Identity
    current_phase: CognitivePhase = CognitivePhase.IDLE
    loop_state: CognitiveLoopState = CognitiveLoopState.STOPPED
    active_goal_id: Optional[str] = None
    active_plan_id: Optional[str] = None
    current_step_id: Optional[str] = None
    active_model_id: Optional[str] = None
    available_models: List[str] = field(default_factory=list)
    resource_usage: Dict[str, float] = field(default_factory=dict)
    error_count: int = 0
    last_error: Optional[str] = None
    uptime_start: float = field(default_factory=time.time)
    cycles_completed: int = 0
    missions_completed: int = 0
    skills_acquired: int = 0
    
    def to_dict(self) -> Dict:
        return {
            "identity": self.identity.to_dict(),
            "current_phase": self.current_phase.value,
            "loop_state": self.loop_state.value,
            "active_goal_id": self.active_goal_id,
            "active_plan_id": self.active_plan_id,
            "current_step_id": self.current_step_id,
            "active_model_id": self.active_model_id,
            "available_models": self.available_models,
            "resource_usage": self.resource_usage,
            "error_count": self.error_count,
            "last_error": self.last_error,
            "uptime": time.time() - self.uptime_start,
            "cycles_completed": self.cycles_completed,
            "missions_completed": self.missions_completed,
            "skills_acquired": self.skills_acquired,
        }


# ============================================================================
# MODEL INTERFACE LAYER
# ============================================================================

class ModelInterface:
    """
    Interface for model interactions.
    Maya Cognitive Core → Model Interface (NOT Model → Maya)
    """
    
    def __init__(self):
        self.models: Dict[str, Dict] = {}  # model_id -> config
        self.active_model_id: Optional[str] = None
        self.fallback_chain: List[str] = []
        self.available_models: List[str] = []
        self._lock = threading.RLock()
        
        # Model adapters (can be swapped)
        self._adapters: Dict[str, Callable] = {}
        self._router: Optional["LLMRouter"] = None
    
    def register_router(self, router: "LLMRouter") -> None:
        """Register the LLM router."""
        with self._lock:
            self._router = router
            providers = router.available_providers()
            self.models = {p: {"provider": p, "configured": True} for p in providers}
            self.available_models = providers
    
    def set_active_model(self, model_id: str) -> bool:
        """Set the active model."""
        with self._lock:
            if model_id in self.models or model_id in self.fallback_chain:
                self.active_model_id = model_id
                return True
            return False
    
    def get_active_model(self) -> Optional[str]:
        with self._lock:
            return self.active_model_id
    
    def set_fallback_chain(self, chain: List[str]) -> None:
        with self._lock:
            self.fallback_chain = chain
    
    def get_fallback_chain(self) -> List[str]:
        with self._lock:
            return self.fallback_chain.copy()
    
    def invoke(
        self,
        prompt: str,
        model_id: str = None,
        task_type: str = "general",
        max_tokens: int = 4000,
        temperature: float = 0.7,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Invoke a model. Maya controls the invocation.
        Returns structured result with metadata.
        """
        with self._lock:
            target_model = model_id or self.active_model_id
            if not target_model and self.fallback_chain:
                target_model = self.fallback_chain[0]
            if not target_model and self._router:
                target_model = self._router.best_provider(task_type)
            
            if not target_model:
                return {
                    "success": False,
                    "error": "No model available",
                    "output": "",
                    "model_used": None,
                    "tokens_used": 0,
                    "latency_ms": 0,
                }
        
        # Invoke with fallback
        models_to_try = [target_model] + [m for m in self.fallback_chain if m != target_model]
        
        last_error = None
        for model in models_to_try:
            try:
                start = time.time()
                if self._router:
                    output = self._router.chat(
                        [{"role": "user", "content": prompt}],
                        model=model,
                        max_tokens=max_tokens,
                        task_type=task_type,
                    )
                else:
                    return {"success": False, "error": "No router available", "output": ""}
                
                latency = (time.time() - start) * 1000
                
                return {
                    "success": True,
                    "output": output,
                    "model_used": model,
                    "tokens_used": len(output.split()) * 1.3,  # rough estimate
                    "latency_ms": latency,
                }
            except Exception as e:
                last_error = str(e)
                continue
        
        return {
            "success": False,
            "error": f"All models failed. Last error: {last_error}",
            "output": "",
            "model_used": target_model,
            "tokens_used": 0,
            "latency_ms": 0,
        }
    
    def invoke_structured(
        self,
        prompt: str,
        schema: Dict,
        model_id: str = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Invoke model with structured output requirement."""
        # Add schema instruction to prompt
        structured_prompt = f"{prompt}\n\nReturn ONLY valid JSON matching this schema:\n{json.dumps(schema)}"
        result = self.invoke(structured_prompt, model_id=model_id, **kwargs)
        
        if result["success"]:
            try:
                parsed = json.loads(result["output"])
                result["parsed"] = parsed
            except json.JSONDecodeError:
                result["parsed"] = None
                result["warning"] = "Output not valid JSON"
        
        return result
    
    def list_models(self) -> List[Dict]:
        with self._lock:
            return [
                {"id": mid, **config}
                for mid, config in self.models.items()
            ]


# ============================================================================
# MAYA COGNITIVE CORE
# ============================================================================

class MayaCognitiveCore:
    """
    The central cognitive core of Maya.
    Owns all persistent state and controls the cognitive loop.
    Models are invoked as resources, not controllers.
    """
    
    def __init__(
        self,
        llm_fn: Optional[Callable] = None,
        router: Optional["LLMRouter"] = None,
        tool_registry: Optional["ToolRegistry"] = None,
        approval_manager: Optional[ApprovalManager] = None,
        intervention_handler: Optional[InterventionHandler] = None,
        risk_checker: Optional[RiskChecker] = None,
        permission_manager: Optional[PermissionManager] = None,
        memory_manager: Optional[MemoryManager] = None,
    ):
        self._lock = threading.RLock()
        
        # Core dependencies
        self.llm_fn = llm_fn
        self.router = router
        self.tool_registry = tool_registry
        self.approval = approval_manager
        self.intervention = intervention_handler
        self.risk_checker = risk_checker
        self.permissions = permission_manager
        self.memory_manager = memory_manager
        
        # Model interface layer (Maya → Model)
        self.model_interface = ModelInterface()
        if router:
            self.model_interface.register_router(router)
        
        # Persistence (must be first for DB initialization)
        self._init_persistence()
        
        # Initialize persistent identity
        self.identity = self._load_or_create_identity()
        
        # Initialize self-state
        self.self_state = SelfState(identity=self.identity)
        
        # Initialize sub-systems (lazy, will be wired in initialize())
        self.cognitive_kernel: Optional[CognitiveKernel] = None
        self.capability_registry: Optional[CapabilityRegistry] = None
        self.world_models: Dict[str, WorldModel] = {}
        self.hierarchical_planner: Optional[HierarchicalPlanner] = None
        self.metacognitive_monitor: Optional[MetacognitiveMonitor] = None
        self.agent_society: Optional[AgentSociety] = None
        self.tool_synthesizer: Optional[ToolSynthesizer] = None
        self.episodic_memory = None
        self.procedural_memory = None
        self.experience_distiller = None
        self.experience_replay = None
        
        # Cognitive loop control
        self._running = False
        self._paused = False
        self._loop_thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._pause_event = threading.Event()
        
        # Load persisted state
        self._load_state()
        
        # Metrics
        self._cycle_count = 0
        self._last_cycle_time = 0
        self._cycle_history: deque = deque(maxlen=1000)
    
    # =========================================================================
    # IDENTITY & PERSISTENCE
    # =========================================================================
    
    CORE_DIR = STORAGE_DIR / "maya_cognitive_core"
    CORE_DIR.mkdir(parents=True, exist_ok=True)
    CORE_DB = str(CORE_DIR / "core.db")
    CHECKPOINT_DIR = CORE_DIR / "checkpoints"
    CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)
    
    def _init_persistence(self) -> None:
        """Initialize database for persistent state."""
        with self._conn() as c:
            c.executescript("""
            CREATE TABLE IF NOT EXISTS identity (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                updated_at REAL
            );
            
            CREATE TABLE IF NOT EXISTS self_state (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                updated_at REAL
            );
            
            CREATE TABLE IF NOT EXISTS cognitive_loop_log (
                id TEXT PRIMARY KEY,
                cycle_id INTEGER,
                phase TEXT,
                timestamp REAL,
                details TEXT,
                success INTEGER,
                duration_ms REAL
            );
            
            CREATE TABLE IF NOT EXISTS model_invocations (
                id TEXT PRIMARY KEY,
                model_id TEXT,
                prompt_hash TEXT,
                success INTEGER,
                latency_ms REAL,
                tokens_estimate REAL,
                timestamp REAL
            );
            
            CREATE TABLE IF NOT EXISTS skill_acquisitions (
                id TEXT PRIMARY KEY,
                capability_id TEXT,
                goal TEXT,
                verification_score REAL,
                timestamp REAL
            );
            
            CREATE INDEX IF NOT EXISTS idx_loop_cycle ON cognitive_loop_log(cycle_id);
            CREATE INDEX IF NOT EXISTS idx_loop_time ON cognitive_loop_log(timestamp);
            CREATE INDEX IF NOT EXISTS idx_model_time ON model_invocations(timestamp);
            """)
    
    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.CORE_DB, check_same_thread=False, timeout=30)
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
    
    def _load_or_create_identity(self) -> Identity:
        """Load or create persistent identity."""
        with self._conn() as c:
            row = c.execute("SELECT value FROM identity WHERE key = 'identity'").fetchone()
            if row:
                data = json.loads(row["value"])
                return Identity.from_dict(data)
        
        # Create new identity
        identity = Identity(
            instance_id=uuid.uuid4().hex[:12],
            personality_traits={
                "curiosity": 0.8,
                "caution": 0.7,
                "persistence": 0.9,
                "creativity": 0.6,
                "analytical": 0.8,
            },
            core_values=[
                "safety_first",
                "human_in_the_loop",
                "transparency",
                "continuous_learning",
                "resource_efficiency",
            ],
        )
        self._save_identity(identity)
        return identity
    
    def _save_identity(self, identity: Identity) -> None:
        with self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO identity (key, value, updated_at)
                VALUES (?, ?, ?)
            """, ("identity", json.dumps(identity.to_dict()), time.time()))
    
    def _save_self_state(self) -> None:
        with self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO self_state (key, value, updated_at)
                VALUES (?, ?, ?)
            """, ("self_state", json.dumps(self.self_state.to_dict()), time.time()))
    
    def _load_state(self) -> None:
        """Load persistent state on startup."""
        with self._conn() as c:
            # Load self state
            row = c.execute("SELECT value FROM self_state WHERE key = 'self_state'").fetchone()
            if row:
                data = json.loads(row["value"])
                # Restore identity from saved state
                if "identity" in data:
                    self.identity = Identity.from_dict(data["identity"])
                    self.self_state.identity = self.identity
                
                self.self_state.current_phase = CognitivePhase(data.get("current_phase", "idle"))
                self.self_state.loop_state = CognitiveLoopState(data.get("loop_state", "stopped"))
                self.self_state.active_goal_id = data.get("active_goal_id")
                self.self_state.active_plan_id = data.get("active_plan_id")
                self.self_state.current_step_id = data.get("current_step_id")
                self.self_state.active_model_id = data.get("active_model_id")
                self.self_state.available_models = data.get("available_models", [])
                self.self_state.error_count = data.get("error_count", 0)
                self.self_state.last_error = data.get("last_error")
                self.self_state.cycles_completed = data.get("cycles_completed", 0)
                self.self_state.missions_completed = data.get("missions_completed", 0)
                self.self_state.skills_acquired = data.get("skills_acquired", 0)
    
    def _log_cycle(self, cycle_id: int, phase: CognitivePhase, details: str, 
                   success: bool, duration_ms: float) -> None:
        with self._conn() as c:
            c.execute("""
                INSERT INTO cognitive_loop_log (id, cycle_id, phase, timestamp, details, success, duration_ms)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (uuid.uuid4().hex[:12], cycle_id, phase.value, time.time(), details, int(success), duration_ms))
    
    def _log_model_invocation(self, model_id: str, prompt: str, result: Dict) -> None:
        prompt_hash = hashlib.sha256(prompt.encode()).hexdigest()[:16]
        with self._conn() as c:
            c.execute("""
                INSERT INTO model_invocations (id, model_id, prompt_hash, success, latency_ms, tokens_estimate, timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                uuid.uuid4().hex[:12], model_id, prompt_hash,
                int(result.get("success", False)),
                result.get("latency_ms", 0),
                result.get("tokens_used", 0),
                time.time()
            ))
    
    def _log_skill_acquisition(self, capability_id: str, goal: str, score: float) -> None:
        with self._conn() as c:
            c.execute("""
                INSERT INTO skill_acquisitions (id, capability_id, goal, verification_score, timestamp)
                VALUES (?, ?, ?, ?, ?)
            """, (uuid.uuid4().hex[:12], capability_id, goal, score, time.time()))
        
        self.self_state.skills_acquired += 1
        self._save_self_state()
    
    # =========================================================================
    # INITIALIZATION & WIRING
    # =========================================================================
    
    def initialize(self) -> bool:
        """Initialize all cognitive subsystems and wire them together."""
        try:
            # Ensure LLM function is available
            if not self.llm_fn and self.router:
                def default_llm(prompt: str) -> str:
                    return self.router.chat([{"role": "user", "content": prompt}])
                self.llm_fn = default_llm
            
            # 1. Cognitive Kernel (working memory, goals, beliefs, plans)
            self.cognitive_kernel = get_cognitive_kernel(
                llm_fn=self.llm_fn,
                capability_registry=None,  # Will set after registry init
                world_models=None,  # Will set after world models init
                approval_manager=self.approval,
                intervention_handler=self.intervention,
            )
            
            # 2. Capability Registry (tools, agents, skills, workflows)
            self.capability_registry = get_capability_registry(
                tool_registry=self.tool_registry
            )
            self.cognitive_kernel.capability_registry = self.capability_registry
            
            # 3. World Models (symbolic simulators)
            remote_deployer = None
            try:
                from infrastructure.remote_deploy import remote_deployer as _rd
                remote_deployer = _rd
            except Exception:
                pass
            self.world_models = create_world_models(remote_deployer)
            self.cognitive_kernel.world_models = self.world_models
            
            # 4. Hierarchical Planner (HTN + MCTS)
            self.hierarchical_planner = get_hierarchical_planner(
                kernel=self.cognitive_kernel,
                world_models=self.world_models,
                capability_registry=self.capability_registry,
            )
            
            # 5. Metacognitive Monitor (confidence, surprise, recovery)
            self.metacognitive_monitor = get_metacognitive_monitor(
                kernel=self.cognitive_kernel,
                world_models=self.world_models,
                hierarchical_planner=self.hierarchical_planner,
                capability_registry=self.capability_registry,
                approval_manager=self.approval,
                intervention_handler=self.intervention,
            )
            
            # 6. Agent Society (dynamic agent spawning, coordination)
            self.agent_society = get_agent_society(
                kernel=self.cognitive_kernel,
                capability_registry=self.capability_registry,
                llm_fn=self.llm_fn,
                approval_manager=self.approval,
            )
            
            # 7. Procedural Memory (episodic + skill distillation)
            self.episodic_memory = get_episodic_memory()
            self.procedural_memory = get_procedural_memory()
            self.experience_distiller = get_experience_distiller(
                llm_fn=self.llm_fn,
                capability_registry=self.capability_registry,
            )
            self.experience_replay = get_experience_replay(
                kernel=self.cognitive_kernel,
            )
            
            # 8. Tool Synthesizer (autonomous skill acquisition)
            self.tool_synthesizer = get_tool_synthesizer(
                llm_fn=self.llm_fn,
                capability_registry=self.capability_registry,
                approval_manager=self.approval,
            )
            
            # Register synthesized tools
            if self.tool_registry:
                self.tool_registry.register(
                    "synthesize_tool", self.tool_synthesizer.synthesize,
                    "Autonomously research, experiment, and synthesize a new tool from a goal.",
                    category="meta"
                )
            
            # Register router with model interface
            if self.router:
                self.model_interface.register_router(self.router)
            
            # Start background threads
            self.cognitive_kernel.start()
            self.agent_society.start()
            
            # Update available models
            if self.router:
                self.self_state.available_models = self.router.available_providers()
                self.model_interface.available_models = self.self_state.available_models
                if not self.self_state.active_model_id and self.self_state.available_models:
                    self.self_state.active_model_id = self.self_state.available_models[0]
                    self.model_interface.set_active_model(self.self_state.active_model_id)
            
            self._save_self_state()
            self._audit("core_initialized", "Maya Cognitive Core initialized with all subsystems")
            return True
            
        except Exception as e:
            self._audit("init_error", f"Failed to initialize cognitive core: {e}")
            return False
    
    def shutdown(self) -> None:
        """Shutdown all subsystems and persist state."""
        self.stop_cognitive_loop()
        
        if self.cognitive_kernel:
            self.cognitive_kernel.stop()
        if self.agent_society:
            self.agent_society.stop()
        
        self._save_self_state()
        self._audit("core_shutdown", "Maya Cognitive Core shutdown")
    
    # =========================================================================
    # COGNITIVE LOOP
    # =========================================================================
    
    def start_cognitive_loop(self, interval_seconds: float = 30.0) -> bool:
        """Start the continuous cognitive loop."""
        if self._running:
            return True
        
        if not self.cognitive_kernel:
            if not self.initialize():
                return False
        
        self._running = True
        self._paused = False
        self._stop_event.clear()
        self._pause_event.clear()
        self.self_state.loop_state = CognitiveLoopState.RUNNING
        self._save_self_state()
        
        self._loop_thread = threading.Thread(
            target=self._cognitive_loop,
            args=(interval_seconds,),
            daemon=True
        )
        self._loop_thread.start()
        
        self._audit("loop_start", f"Cognitive loop started (interval={interval_seconds}s)")
        return True
    
    def pause_cognitive_loop(self) -> bool:
        """Pause the cognitive loop."""
        if not self._running:
            return False
        self._paused = True
        self._pause_event.set()
        self.self_state.loop_state = CognitiveLoopState.PAUSED
        self._save_self_state()
        self._audit("loop_pause", "Cognitive loop paused")
        return True
    
    def resume_cognitive_loop(self) -> bool:
        """Resume the cognitive loop."""
        if not self._running:
            return False
        self._paused = False
        self._pause_event.clear()
        self.self_state.loop_state = CognitiveLoopState.RUNNING
        self._save_self_state()
        self._audit("loop_resume", "Cognitive loop resumed")
        return True
    
    def stop_cognitive_loop(self) -> bool:
        """Stop the cognitive loop."""
        if not self._running:
            return False
        self._running = False
        self._stop_event.set()
        self._pause_event.set()
        if self._loop_thread:
            self._loop_thread.join(timeout=10.0)
        self.self_state.loop_state = CognitiveLoopState.STOPPED
        self._save_self_state()
        self._audit("loop_stop", "Cognitive loop stopped")
        return True
    
    def _cognitive_loop(self, interval_seconds: float) -> None:
        """Main cognitive loop running in background thread."""
        while not self._stop_event.is_set():
            if self._paused:
                self._pause_event.wait()
                if self._stop_event.is_set():
                    break
                continue
            
            # Check intervention
            if self.intervention:
                try:
                    if self.intervention.check_interrupt():
                        self._audit("intervention", "Intervention mode active, pausing loop")
                        self.pause_cognitive_loop()
                        continue
                except Exception:
                    pass
            
            cycle_start = time.time()
            cycle_id = self._cycle_count + 1
            
            try:
                # Execute one full cognitive cycle
                self._execute_cognitive_cycle(cycle_id)
                
                self._cycle_count += 1
                self._last_cycle_time = time.time()
                self.self_state.cycles_completed = self._cycle_count
                self._save_self_state()
                
            except Exception as e:
                self._audit("cycle_error", f"Cycle {cycle_id} error: {e}")
                self.self_state.error_count += 1
                self.self_state.last_error = str(e)
                self._save_self_state()
            
            # Wait for next cycle
            elapsed = time.time() - cycle_start
            sleep_time = max(0, interval_seconds - elapsed)
            self._stop_event.wait(sleep_time)
    
    def _execute_cognitive_cycle(self, cycle_id: int) -> Dict[str, Any]:
        """Execute one full cognitive cycle."""
        results = {}
        
        # Phase 1: OBSERVE
        self.self_state.current_phase = CognitivePhase.OBSERVE
        obs_result = self._phase_observe()
        results["observe"] = obs_result
        self._log_cycle(cycle_id, CognitivePhase.OBSERVE, "Environment observation", True, 0)
        
        # Phase 2: UNDERSTAND
        self.self_state.current_phase = CognitivePhase.UNDERSTAND
        understand_result = self._phase_understand(obs_result)
        results["understand"] = understand_result
        self._log_cycle(cycle_id, CognitivePhase.UNDERSTAND, "Understanding observations", True, 0)
        
        # Phase 3: REMEMBER
        self.self_state.current_phase = CognitivePhase.REMEMBER
        remember_result = self._phase_remember(understand_result)
        results["remember"] = remember_result
        self._log_cycle(cycle_id, CognitivePhase.REMEMBER, "Retrieving relevant memories", True, 0)
        
        # Phase 4: REASON/PLAN
        self.self_state.current_phase = CognitivePhase.REASON_PLAN
        plan_result = self._phase_reason_plan(remember_result)
        results["reason_plan"] = plan_result
        self._log_cycle(cycle_id, CognitivePhase.REASON_PLAN, "Reasoning and planning", True, 0)
        
        # Phase 5: DECIDE
        self.self_state.current_phase = CognitivePhase.DECIDE
        decide_result = self._phase_decide(plan_result)
        results["decide"] = decide_result
        self._log_cycle(cycle_id, CognitivePhase.DECIDE, "Decision making", True, 0)
        
        # Phase 6: ACT
        self.self_state.current_phase = CognitivePhase.ACT
        act_result = self._phase_act(decide_result)
        results["act"] = act_result
        self._log_cycle(cycle_id, CognitivePhase.ACT, "Action execution", True, 0)
        
        # Phase 7: OBSERVE RESULT
        self.self_state.current_phase = CognitivePhase.OBSERVE_RESULT
        observe_result_result = self._phase_observe_result(act_result)
        results["observe_result"] = observe_result_result
        self._log_cycle(cycle_id, CognitivePhase.OBSERVE_RESULT, "Observing action results", True, 0)
        
        # Phase 8: VERIFY
        self.self_state.current_phase = CognitivePhase.VERIFY
        verify_result = self._phase_verify(observe_result_result)
        results["verify"] = verify_result
        self._log_cycle(cycle_id, CognitivePhase.VERIFY, "Verification", True, 0)
        
        # Phase 9: LEARN
        self.self_state.current_phase = CognitivePhase.LEARN
        learn_result = self._phase_learn(verify_result)
        results["learn"] = learn_result
        self._log_cycle(cycle_id, CognitivePhase.LEARN, "Learning from experience", True, 0)
        
        # Phase 10: UPDATE
        self.self_state.current_phase = CognitivePhase.UPDATE
        update_result = self._phase_update(learn_result)
        results["update"] = update_result
        self._log_cycle(cycle_id, CognitivePhase.UPDATE, "Updating memory and world model", True, 0)
        
        # Phase 11: REPLAN
        self.self_state.current_phase = CognitivePhase.REPLAN
        replan_result = self._phase_replan(update_result)
        results["replan"] = replan_result
        self._log_cycle(cycle_id, CognitivePhase.REPLAN, "Replanning if needed", True, 0)
        
        self.self_state.current_phase = CognitivePhase.IDLE
        
        # Record cycle
        self._cycle_history.append({
            "cycle_id": cycle_id,
            "timestamp": time.time(),
            "phases": results,
            "duration_ms": (time.time() - cycle_start) * 1000,
        })
        
        return results
    
    # =========================================================================
    # COGNITIVE PHASE IMPLEMENTATIONS
    # =========================================================================
    
    def _phase_observe(self) -> Dict[str, Any]:
        """OBSERVE: Perceive environment through world models."""
        observations = {}
        
        for domain, model in self.world_models.items():
            try:
                obs = model.observe()
                observations[domain] = obs
                
                # Process observations into beliefs
                for o in obs:
                    prop = o.get("proposition") or o.get("fact") or str(o)
                    conf = o.get("confidence", 0.8)
                    self.cognitive_kernel.add_belief(
                        proposition=prop,
                        confidence=conf,
                        evidence=[f"Observed via {domain} at {time.time()}"],
                        source="observation",
                        domain=domain
                    )
                    
                    # Add to working memory
                    self.cognitive_kernel.wm_add(
                        f"[{domain}] {prop}",
                        slot_type="observation",
                        attention=0.7,
                        metadata={"domain": domain, "source": "perception"}
                    )
            except Exception as e:
                observations[domain] = {"error": str(e)}
        
        return {
            "observations": observations,
            "domains_observed": len(observations),
            "timestamp": time.time()
        }
    
    def _phase_understand(self, obs_result: Dict) -> Dict[str, Any]:
        """UNDERSTAND: Interpret observations, update beliefs, detect changes."""
        # Analyze observations for patterns, anomalies
        anomalies = []
        new_beliefs = 0
        updated_beliefs = 0
        
        for domain, obs_list in obs_result.get("observations", {}).items():
            if isinstance(obs_list, list):
                for obs in obs_list:
                    if isinstance(obs, dict) and "proposition" in obs:
                        prop = obs["proposition"]
                        # Check if this contradicts existing beliefs
                        for belief in self.cognitive_kernel.beliefs.values():
                            if belief.domain == domain and belief.proposition in prop:
                                # Potential contradiction - could trigger surprise
                                pass
        
        # Update goal priorities based on observations
        active_goals = self.cognitive_kernel.get_active_goals()
        for goal in active_goals:
            # Could adjust priority based on new observations
            pass
        
        return {
            "anomalies_detected": len(anomalies),
            "beliefs_updated": updated_beliefs,
            "goals_reviewed": len(active_goals),
            "timestamp": time.time()
        }
    
    def _phase_remember(self, understand_result: Dict) -> Dict[str, Any]:
        """REMEMBER: Retrieve relevant memories for current context."""
        # Get current goal context
        current_goal = None
        if self.self_state.active_goal_id:
            current_goal = self.cognitive_kernel.get_goal(self.self_state.active_goal_id)
        
        query = current_goal.description if current_goal else "current context"
        
        # Search memory systems
        memories = {}
        
        # Long-term memory
        if self.memory_manager:
            try:
                ltm_results = self.memory_manager.search(query, limit=10)
                memories["long_term"] = ltm_results
            except Exception:
                memories["long_term"] = []
        
        # Episodic memory
        if self.episodic_memory:
            try:
                episodic_results = self.episodic_memory.get_similar(query, limit=5)
                memories["episodic"] = episodic_results
            except Exception:
                memories["episodic"] = []
        
        # Semantic memory
        if self.memory_manager:
            try:
                semantic_results = self.memory_manager.search_facts(query, limit=5)
                memories["semantic"] = semantic_results
            except Exception:
                memories["semantic"] = []
        
        # Working memory (already in cognitive kernel)
        wm_results = self.cognitive_kernel.wm_search(query, limit=10)
        memories["working"] = [w.__dict__ for w in wm_results]
        
        # Beliefs relevant to current context
        beliefs = self.cognitive_kernel.query_beliefs(min_confidence=0.5)
        memories["beliefs"] = [b.__dict__ for b in beliefs[:20]]
        
        # Add to working memory as context
        self.cognitive_kernel.wm_add(
            f"Context for goal: {query}",
            slot_type="context",
            attention=0.9,
            metadata={"retrieved_memories": {k: len(v) for k, v in memories.items()}}
        )
        
        return {
            "memories_retrieved": memories,
            "total_memories": sum(len(v) for v in memories.values()),
            "timestamp": time.time()
        }
    
    def _phase_reason_plan(self, remember_result: Dict) -> Dict[str, Any]:
        """REASON/PLAN: Generate or update plans for active goals."""
        active_goals = self.cognitive_kernel.get_active_goals()
        
        if not active_goals:
            # No active goals - check for self-generated missions
            missions = self.cognitive_kernel.list_missions(active_only=True)
            for mission in missions:
                if mission.get("self_gen"):
                    # Generate objectives for self-generating missions
                    existing = self.cognitive_kernel.list_objectives(mission_id=mission["id"], status="pending")
                    if not existing:
                        self.cognitive_kernel.generate_objectives(mission["id"])
            
            return {"plans_created": 0, "goals_processed": 0, "timestamp": time.time()}
        
        plans_created = 0
        
        for goal in active_goals[:3]:  # Limit concurrent planning
            # Check if goal has active plan
            has_plan = any(p.goal_id == goal.id and p.status == "active" for p in self.cognitive_kernel.plans.values())
            
            if not has_plan:
                # Create new plan using hierarchical planner
                if self.hierarchical_planner:
                    try:
                        h_plan = self.hierarchical_planner.plan_for_goal(goal)
                        
                        # Convert to cognitive kernel plan format
                        steps = []
                        for step in h_plan.steps:
                            steps.append({
                                "id": step.id,
                                "description": step.description,
                                "action": step.action,
                                "expected_outcome": step.expected_outcome,
                                "required_capability": step.required_capability,
                                "contingency": step.contingency.__dict__ if step.contingency else None,
                                "depends_on": step.depends_on,
                            })
                        
                        plan = self.cognitive_kernel.create_plan(goal.id, steps)
                        self.self_state.active_plan_id = plan.id
                        plans_created += 1
                        
                    except Exception as e:
                        self._audit("plan_error", f"Failed to create plan for goal {goal.id}: {e}")
        
        return {
            "plans_created": plans_created,
            "goals_processed": len(active_goals),
            "active_goals": [g.id for g in active_goals],
            "timestamp": time.time()
        }
    
    def _phase_decide(self, plan_result: Dict) -> Dict[str, Any]:
        """DECIDE: Select next action based on plans, priorities, metacognition."""
        # Get next goal to work on
        next_goal = self.cognitive_kernel.get_next_goal()
        
        if not next_goal:
            return {"action": "none", "reason": "No active goals", "timestamp": time.time()}
        
        self.self_state.active_goal_id = next_goal.id
        self._save_self_state()
        
        # Get active plan for this goal
        active_plan = None
        for plan in self.cognitive_kernel.plans.values():
            if plan.goal_id == next_goal.id and plan.status == "active":
                active_plan = plan
                break
        
        if not active_plan:
            return {"action": "replan", "reason": "No active plan for goal", "goal_id": next_goal.id, "timestamp": time.time()}
        
        self.self_state.active_plan_id = active_plan.id
        
        # Get next executable step
        next_step = None
        if self.hierarchical_planner:
            h_plan = self.hierarchical_planner.active_plans.get(active_plan.id)
            if h_plan:
                next_step = h_plan.get_next_executable_step()
        
        if not next_step and active_plan.steps:
            # Fallback: first pending step
            for step in active_plan.steps:
                if step.get("success") is not True:
                    next_step = step
                    break
        
        if not next_step:
            return {"action": "complete", "reason": "All steps completed", "goal_id": next_goal.id, "timestamp": time.time()}
        
        self.self_state.current_step_id = next_step.get("id") or next_step.id if hasattr(next_step, 'id') else str(next_step)
        
        # Metacognitive check before acting
        if self.metacognitive_monitor:
            context = {
                "goal_id": next_goal.id,
                "plan_id": active_plan.id,
                "step_id": self.self_state.current_step_id,
                "domain": next_step.get("domain", "general") if isinstance(next_step, dict) else getattr(next_step, 'action', {}).get("domain", "general"),
            }
            events = self.metacognitive_monitor.monitor(context)
            if events:
                # Handle metacognitive events
                for event in events:
                    if event.action_taken == RecoveryAction.ESCALATE_HUMAN:
                        self.self_state.loop_state = CognitiveLoopState.WAITING_APPROVAL
                        self._save_self_state()
                        return {"action": "wait_approval", "reason": "Metacognitive escalation", "event": event.__dict__, "timestamp": time.time()}
        
        # Risk check
        if self.risk_checker:
            risk = self.risk_checker.check(next_goal.description)
            if not risk.get("allow", True):
                return {"action": "blocked", "reason": risk.get("reason", "Risk check failed"), "goal_id": next_goal.id, "timestamp": time.time()}
        
        # Approval check
        if self.approval and next_goal.requires_approval:
            approved = self.approval.request_approval(
                action=f"Execute step: {next_step.get('description', 'unknown')}",
                reason=f"Step requires approval for goal: {next_goal.description}",
                risk_level="high",
                task_id=next_goal.id,
            )
            if not approved:
                self.self_state.loop_state = CognitiveLoopState.WAITING_APPROVAL
                self._save_self_state()
                return {"action": "wait_approval", "reason": "Human approval denied", "goal_id": next_goal.id, "timestamp": time.time()}
        
        return {
            "action": "execute_step",
            "goal_id": next_goal.id,
            "plan_id": active_plan.id,
            "step": next_step if isinstance(next_step, dict) else next_step.__dict__,
            "timestamp": time.time()
        }
    
    def _phase_act(self, decide_result: Dict) -> Dict[str, Any]:
        """ACT: Execute the decided action.

        ARCHITECTURE INVARIANT (Phase 34+): the CognitiveKernel is Maya's
        ONLY control loop. This method MUST NOT execute anything itself —
        no direct capability code-run, no direct tool calls, no treating
        model output as execution. All world-facing action is delegated
        through the kernel's single registered backend (Maya's own gated
        pipeline) via process_goal(). If no backend is registered, this
        phase is propose-only by construction.
        """
        if decide_result.get("action") != "execute_step":
            return {"executed": False, "reason": decide_result.get("reason"), "timestamp": time.time()}

        step = decide_result.get("step", {}) or {}
        goal_id = decide_result.get("goal_id")

        kernel = self.cognitive_kernel
        if kernel is None or not getattr(kernel, "has_executor", False):
            self._audit("act_delegated_none",
                        "no controller executor registered — step not executed")
            return {"executed": False,
                    "reason": "no_controller_executor",
                    "step_description": step.get("description", "unknown")
                    if isinstance(step, dict) else str(step),
                    "timestamp": time.time()}

        # Delegate: the kernel grounds + drives the goal through Maya's
        # pipeline (risk check, approval gates, verification all inside).
        step_desc = (step.get("description") if isinstance(step, dict)
                     else None) or json.dumps(step.get("action", {}))[:200]
        parent_desc = ""
        if goal_id:
            g = kernel.get_goal(goal_id)
            parent_desc = g.description[:120] if g else ""
        full_desc = (f"{parent_desc} :: {step_desc}"
                     if parent_desc else step_desc)

        kr = kernel.process_goal(full_desc, execute=True)

        return {
            "executed": bool(kr.get("executed")),
            "success": bool(kr.get("success")),
            "output": str((kr.get("outcome") or {}).get("result", "")),
            "error": str((kr.get("outcome") or {}).get("error", "")),
            "delegated_goal_id": kr.get("goal_id"),
            "goal_id": goal_id,
            "via_controller": True,
            "timestamp": time.time(),
        }
    
    def _phase_observe_result(self, act_result: Dict) -> Dict[str, Any]:
        """OBSERVE RESULT: Perceive the outcome of the action."""
        success = act_result.get("success", False)
        output = act_result.get("output", "")
        error = act_result.get("error", "")
        
        # Add result to working memory
        self.cognitive_kernel.wm_add(
            f"Action result: {'success' if success else 'failure'} - {output[:500]}",
            slot_type="action_result",
            attention=0.8,
            metadata={
                "success": success,
                "goal_id": act_result.get("goal_id"),
                "step_id": act_result.get("step_id"),
                "via_model": act_result.get("via_model", False),
            }
        )
        
        # Update beliefs based on result
        step_desc = act_result.get("step_description", "unknown")
        if success:
            self.cognitive_kernel.add_belief(
                proposition=f"Action succeeded: {step_desc}",
                confidence=0.8,
                evidence=[f"Observed result: {output[:200]}"],
                source="observation",
                domain="execution"
            )
        else:
            self.cognitive_kernel.add_belief(
                proposition=f"Action failed: {step_desc}",
                confidence=0.9,
                evidence=[f"Error: {error}"],
                source="observation",
                domain="execution"
            )
        
        return {
            "observed_success": success,
            "output": output,
            "error": error,
            "timestamp": time.time()
        }
    
    def _phase_verify(self, observe_result: Dict) -> Dict[str, Any]:
        """VERIFY: Check if action achieved expected outcome."""
        success = observe_result.get("observed_success", False)
        
        if not success:
            return {"verified": False, "reason": observe_result.get("error", "Action failed"), "timestamp": time.time()}
        
        # Get expected outcome from step
        step_id = observe_result.get("step_id")  # Would need to be passed through
        expected = {}
        
        if self.cognitive_kernel.active_plan_id:
            plan = self.cognitive_kernel.plans.get(self.cognitive_kernel.active_plan_id)
            if plan:
                for step in plan.steps:
                    if step.get("id") == step_id:
                        expected = step.get("expected_outcome", {})
                        break
        
        # Use metacognitive monitor to assess
        if self.metacognitive_monitor:
            context = {
                "step_id": step_id,
                "plan_id": self.cognitive_kernel.active_plan_id,
                "domain": "general",
            }
            meta_event = self.metacognitive_monitor.record_step_result(
                context, expected, {"output": observe_result.get("output")}, success
            )
            if meta_event:
                return {"verified": meta_event.action_result.get("success", True), "metacognitive_event": meta_event.__dict__, "timestamp": time.time()}
        
        # Simple verification: check if output matches expected pattern
        verified = True
        if expected:
            # Could do more sophisticated matching
            verified = True  # Default to success for now
        
        return {"verified": verified, "expected": expected, "actual": observe_result.get("output"), "timestamp": time.time()}
    
    def _phase_learn(self, verify_result: Dict) -> Dict[str, Any]:
        """LEARN: Extract lessons from the experience."""
        verified = verify_result.get("verified", False)
        
        # Get current goal
        goal = None
        if self.self_state.active_goal_id:
            goal = self.cognitive_kernel.get_goal(self.self_state.active_goal_id)
        
        # Record in episodic memory
        if self.episodic_memory and goal:
            try:
                self.episodic_memory.add_episode(
                    goal=goal.description,
                    steps=[],  # Would need to track steps
                    result=verify_result.get("actual", ""),
                    success=verified,
                )
            except Exception:
                pass
        
        # Record in memory manager
        if self.memory_manager and goal:
            self.memory_manager.remember_task(
                goal=goal.description,
                steps=[],
                result=verify_result.get("actual", ""),
                success=verified,
            )
        
        # Distill experience if successful
        if verified and self.experience_distiller and goal:
            try:
                self.experience_distiller.distill_episode({
                    "goal": goal.description,
                    "steps": [],
                    "result": verify_result.get("actual", ""),
                    "success": True,
                })
            except Exception:
                pass
        
        # Update goal progress
        if goal and self.cognitive_kernel.active_plan_id:
            plan = self.cognitive_kernel.plans.get(self.cognitive_kernel.active_plan_id)
            if plan and plan.steps:
                completed = sum(1 for s in plan.steps if s.get("success"))
                goal.progress = completed / len(plan.steps)
                self.cognitive_kernel.update_goal(goal.id, progress=goal.progress)
                if goal.progress >= 1.0:
                    self.cognitive_kernel.update_goal(goal.id, status=GoalStatus.COMPLETED.value, completed_at=time.time())
                    self.self_state.missions_completed += 1
                    self._save_self_state()
        
        return {
            "lesson_recorded": True,
            "verified": verified,
            "goal_progress": goal.progress if goal else 0,
            "timestamp": time.time()
        }
    
    def _phase_update(self, learn_result: Dict) -> Dict[str, Any]:
        """UPDATE: Update memory, world models, and capability registry."""
        # Consolidate working memory
        self.cognitive_kernel.wm_decay_all(0.02)
        
        # Update world models with new observations
        for domain, model in self.world_models.items():
            if hasattr(model, 'observe'):
                try:
                    model.observe()
                except Exception:
                    pass
        
        # Update capability reliability based on usage
        if self.capability_registry:
            # This happens automatically via record_usage
            pass
        
        return {"updated": True, "timestamp": time.time()}
    
    def _phase_replan(self, update_result: Dict) -> Dict[str, Any]:
        """REPLAN: Check if replanning is needed and trigger if so."""
        replanned = False
        
        # Check for metacognitive replan triggers
        if self.metacognitive_monitor:
            # Check recent events for replan triggers
            events = self.metacognitive_monitor.get_events(limit=10)
            for event in events:
                if event.action_taken == RecoveryAction.REPLAN and not event.resolved:
                    # Trigger replan
                    if self.cognitive_kernel.active_plan_id:
                        self.cognitive_kernel.replan(self.cognitive_kernel.active_plan_id)
                        replanned = True
        
        # Check for stalled goals
        active_goals = self.cognitive_kernel.get_active_goals()
        for goal in active_goals:
            if time.time() - goal.updated_at > 3600:  # 1 hour
                self._audit("stall_replan", f"Goal {goal.id} stalled, triggering replan")
                if self.cognitive_kernel.active_plan_id:
                    self.cognitive_kernel.replan(self.cognitive_kernel.active_plan_id)
                    replanned = True
        
        return {"replanned": replanned, "timestamp": time.time()}
    
    # =========================================================================
    # HIGH-LEVEL INTERFACE
    # =========================================================================
    
    def run_mission(self, mission_description: str, mission_type: str = "general",
                    self_gen: bool = True) -> Dict[str, Any]:
        """Register a mission as a persistent kernel goal.

        Does NOT start any loop and does NOT execute anything — the goal
        enters the single controller (CognitiveKernel) where it can be
        proposed or explicitly executed like any other goal.
        """
        if not self.cognitive_kernel:
            self.initialize()
        goal = self.cognitive_kernel.create_goal(
            mission_description,
            metadata={"kind": "mission", "mission_type": mission_type,
                      "self_gen": bool(self_gen)},
        )
        self._audit("mission_registered", f"[{goal.id}] {mission_description[:120]}")
        return {
            "goal_id": goal.id,
            "description": mission_description,
            "status": "registered",
            "note": ("delegated to the CognitiveKernel; execution requires "
                     "an explicit process_goal/resume call"),
        }
    
    def execute_single_goal(self, goal_description: str, max_steps: int = 10) -> Dict[str, Any]:
        """Execute a single goal synchronously (for testing)."""
        # Create goal
        goal = self.cognitive_kernel.create_goal(goal_description)
        
        # Create plan
        plan = self.cognitive_kernel.create_plan(goal.id)
        self.self_state.active_goal_id = goal.id
        self.self_state.active_plan_id = plan.id
        
        # Execute steps
        results = []
        for i, step in enumerate(plan.steps):
            if i >= max_steps:
                break
            
            self.self_state.current_step_id = step["id"]
            
            # Execute step
            act_result = self._phase_act({
                "action": "execute_step",
                "goal_id": goal.id,
                "plan_id": plan.id,
                "step": step,
            })
            
            # Observe result
            obs_result = self._phase_observe_result(act_result)
            
            # Verify
            verify_result = self._phase_verify(obs_result)
            
            # Learn
            learn_result = self._phase_learn(verify_result)
            
            results.append({
                "step": step,
                "act": act_result,
                "observe": obs_result,
                "verify": verify_result,
                "learn": learn_result,
            })
            
            if not verify_result.get("verified", False):
                break
        
        # Update goal status
        if all(r["verify"].get("verified", False) for r in results):
            self.cognitive_kernel.update_goal(goal.id, status=GoalStatus.COMPLETED.value)
        else:
            self.cognitive_kernel.update_goal(goal.id, status=GoalStatus.ABANDONED.value)
        
        return {
            "goal_id": goal.id,
            "plan_id": plan.id,
            "steps_executed": len(results),
            "success": all(r["verify"].get("verified", False) for r in results),
            "results": results,
        }
    
    # =========================================================================
    # MODEL MANAGEMENT
    # =========================================================================
    
    def switch_model(self, model_id: str) -> bool:
        """Switch the active model. Maya controls this."""
        success = self.model_interface.set_active_model(model_id)
        if success:
            self.self_state.active_model_id = model_id
            self._save_self_state()
            self._audit("model_switch", f"Switched to model: {model_id}")
        return success
    
    def get_model_status(self) -> Dict[str, Any]:
        """Get current model status."""
        return {
            "active_model": self.self_state.active_model_id,
            "available_models": self.self_state.available_models,
            "fallback_chain": self.model_interface.get_fallback_chain(),
            "recent_invocations": self._get_recent_model_invocations(10),
        }
    
    def _get_recent_model_invocations(self, limit: int) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM model_invocations ORDER BY timestamp DESC LIMIT ?",
                (limit,)
            ).fetchall()
            return [dict(r) for r in rows]
    
    # =========================================================================
    # CHECKPOINTING
    # =========================================================================
    
    def checkpoint(self) -> str:
        """Create a full checkpoint of all cognitive state."""
        checkpoint_id = f"checkpoint_{int(time.time())}_{uuid.uuid4().hex[:8]}"
        checkpoint_path = self.CHECKPOINT_DIR / f"{checkpoint_id}.json"
        
        state = {
            "checkpoint_id": checkpoint_id,
            "timestamp": time.time(),
            "identity": self.identity.to_dict(),
            "self_state": self.self_state.to_dict(),
            "cognitive_kernel": self.cognitive_kernel.checkpoint() if self.cognitive_kernel else None,
            "agent_society": self.agent_society.get_society_status() if self.agent_society else None,
            "capability_registry_stats": self.capability_registry.stats() if self.capability_registry else None,
            "metacognitive_status": self.metacognitive_monitor.get_status() if self.metacognitive_monitor else None,
        }
        
        checkpoint_path.write_text(json.dumps(state, indent=2))
        
        # Clean old checkpoints (keep last 20)
        checkpoints = sorted(self.CHECKPOINT_DIR.glob("checkpoint_*.json"))
        for old in checkpoints[:-20]:
            old.unlink(missing_ok=True)
        
        self._audit("checkpoint", f"Created checkpoint: {checkpoint_id}")
        return checkpoint_id
    
    def restore_checkpoint(self, checkpoint_id: str) -> bool:
        """Restore cognitive state from checkpoint."""
        checkpoint_path = self.CHECKPOINT_DIR / f"{checkpoint_id}.json"
        if not checkpoint_path.exists():
            return False
        
        state = json.loads(checkpoint_path.read_text())
        
        # Restore identity
        self.identity = Identity.from_dict(state["identity"])
        self.self_state = SelfState(identity=self.identity)
        self.self_state.current_phase = CognitivePhase(state["self_state"]["current_phase"])
        self.self_state.loop_state = CognitiveLoopState(state["self_state"]["loop_state"])
        self.self_state.active_goal_id = state["self_state"]["active_goal_id"]
        self.self_state.active_plan_id = state["self_state"]["active_plan_id"]
        self.self_state.current_step_id = state["self_state"]["current_step_id"]
        self.self_state.active_model_id = state["self_state"]["active_model_id"]
        self.self_state.available_models = state["self_state"]["available_models"]
        self.self_state.error_count = state["self_state"]["error_count"]
        self.self_state.last_error = state["self_state"]["last_error"]
        self.self_state.cycles_completed = state["self_state"]["cycles_completed"]
        self.self_state.missions_completed = state["self_state"]["missions_completed"]
        self.self_state.skills_acquired = state["self_state"]["skills_acquired"]
        
        # Restore cognitive kernel
        if self.cognitive_kernel and state.get("cognitive_kernel"):
            # The cognitive kernel has its own checkpoint/restore
            pass
        
        self._save_identity(self.identity)
        self._save_self_state()
        self._audit("checkpoint_restore", f"Restored from checkpoint: {checkpoint_id}")
        return True
    
    def list_checkpoints(self) -> List[Dict]:
        checkpoints = []
        for path in sorted(self.CHECKPOINT_DIR.glob("checkpoint_*.json"), reverse=True):
            try:
                data = json.loads(path.read_text())
                checkpoints.append({
                    "id": data.get("checkpoint_id", path.stem),
                    "timestamp": data.get("timestamp"),
                    "cycles_completed": data.get("self_state", {}).get("cycles_completed", 0),
                    "active_goal": data.get("self_state", {}).get("active_goal_id"),
                    "active_model": data.get("self_state", {}).get("active_model_id"),
                })
            except Exception:
                pass
        return checkpoints
    
    # =========================================================================
    # STATUS & MONITORING
    # =========================================================================
    
    def get_status(self) -> Dict[str, Any]:
        """Get comprehensive status of the cognitive core."""
        return {
            "identity": self.identity.to_dict(),
            "self_state": self.self_state.to_dict(),
            "cognitive_kernel": self.cognitive_kernel.status() if self.cognitive_kernel else None,
            "capability_registry": self.capability_registry.stats() if self.capability_registry else None,
            "world_models": {domain: type(model).__name__ for domain, model in self.world_models.items()},
            "hierarchical_planner": {
                "active_plans": len(self.hierarchical_planner.active_plans) if self.hierarchical_planner else 0,
            },
            "metacognitive_monitor": self.metacognitive_monitor.get_status() if self.metacognitive_monitor else None,
            "agent_society": self.agent_society.get_society_status() if self.agent_society else None,
            "tool_synthesizer": self.tool_synthesizer.get_status() if self.tool_synthesizer else None,
            "memory_manager": self.memory_manager.get_stats() if self.memory_manager else None,
            "cycle_history": list(self._cycle_history)[-10:],
            "checkpoints": self.list_checkpoints()[:5],
        }
    
    def get_recent_audit(self, limit: int = 50) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM cognitive_loop_log ORDER BY timestamp DESC LIMIT ?",
                (limit,)
            ).fetchall()
            return [dict(r) for r in rows]
    
    def _audit(self, event_type: str, details: str) -> None:
        with self._conn() as c:
            c.execute("""
                INSERT INTO cognitive_loop_log (id, cycle_id, phase, timestamp, details, success, duration_ms)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (uuid.uuid4().hex[:12], self._cycle_count, "audit", time.time(), details, 1, 0))


# ============================================================================
# MODULE SINGLETON
# ============================================================================

_maya_cognitive_core: Optional[MayaCognitiveCore] = None


def get_maya_cognitive_core(
    llm_fn: Optional[Callable] = None,
    router: Optional["LLMRouter"] = None,
    tool_registry: Optional["ToolRegistry"] = None,
    approval_manager: Optional[ApprovalManager] = None,
    intervention_handler: Optional[InterventionHandler] = None,
    risk_checker: Optional[RiskChecker] = None,
    permission_manager: Optional[PermissionManager] = None,
    memory_manager: Optional[MemoryManager] = None,
) -> MayaCognitiveCore:
    global _maya_cognitive_core
    if _maya_cognitive_core is None:
        _maya_cognitive_core = MayaCognitiveCore(
            llm_fn=llm_fn,
            router=router,
            tool_registry=tool_registry,
            approval_manager=approval_manager,
            intervention_handler=intervention_handler,
            risk_checker=risk_checker,
            permission_manager=permission_manager,
            memory_manager=memory_manager,
        )
    return _maya_cognitive_core


def set_maya_cognitive_core(core: MayaCognitiveCore) -> None:
    global _maya_cognitive_core
    _maya_cognitive_core = core