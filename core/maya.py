"""
Maya 2.0 ULTRA - Main Agent
-----------------------------
Autonomous AI Agent that plans, executes, verifies, and learns.
"""

import os
import sys
import asyncio
from typing import List, Dict, Optional
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

from llm.router import LLMRouter
from llm.prompt_builder import PromptBuilder
from core.planner import Planner
from core.reasoner import Reasoner
from core.executor import Executor
from core.verifier import Verifier
from core.task_manager import TaskManager
from core.workflow_engine import WorkflowEngine
from core.fallback_manager import FallbackManager
from memory.memory_manager import MemoryManager
from learning.improvement_engine import ImprovementEngine
from tools.tool_manager import ToolManager
from human.approval import ApprovalManager
from security.risk_checker import RiskChecker
from security.permissions import PermissionManager
from skills.plugin_loader import PluginLoader
from utils.cost_tracker import CostTracker
from maya_logging.logger import get_logger

# Phase 18: AGI Cognitive Architecture
from infrastructure.cognitive_kernel import CognitiveKernel, get_cognitive_kernel
from infrastructure.capability_registry import CapabilityRegistry, get_capability_registry
from infrastructure.tool_synthesizer import ToolSynthesizer, get_tool_synthesizer
from infrastructure.world_models import create_world_models
from infrastructure.hierarchical_planner import HierarchicalPlanner, get_hierarchical_planner
from infrastructure.metacognitive import MetacognitiveMonitor, get_metacognitive_monitor
from infrastructure.agent_society import AgentSociety, get_agent_society
from infrastructure.procedural_memory import (
    get_episodic_memory, get_procedural_memory, 
    get_experience_distiller, get_experience_replay
)
from infrastructure.streaming import get_stream_manager, StreamEmitter
from infrastructure.unified_checkpoint import get_checkpoint_manager, CheckpointManager

log = get_logger("maya")


class Maya:
    """
    Maya 2.0 ULTRA - Autonomous AI Agent

    Features:
    - Multi-LLM support with smart routing
    - Plan → Execute → Verify → Learn workflow
    - Persistent memory across sessions
    - Plugin system for extensibility
    - Cost tracking
    - Security and sandboxing
    - Cloudflare Workers integration
    """

    VERSION = "2.0.0"

    def __init__(self, budget_usd: float = None):
        log.info(f"Starting Maya {self.VERSION}...")

        # Core systems
        self.router = LLMRouter()
        self.memory = MemoryManager()
        self.cost = CostTracker(budget_usd=budget_usd or float(os.environ.get("BUDGET_USD", "1.0")))

        # Tools
        self.tool_manager = ToolManager()

        # Phase 38: MCP servers as capabilities (ships OFF — MCP_ENABLED).
        # External MCP tools register as ordinary registry entries prefixed
        # mcp_<server>_; Maya uses them, they never control Maya.
        self.mcp_manager = None
        if os.getenv("MCP_ENABLED", "false").lower() == "true":
            try:
                from infrastructure.mcp_client import get_mcp_manager
                self.mcp_manager = get_mcp_manager()
                _mcp_count = self.mcp_manager.connect_all_and_register(
                    self.tool_manager.get_registry())
                if _mcp_count:
                    print(f"  MCP servers         : {_mcp_count} tools registered")
            except Exception as e:
                log.warning(f"MCP init skipped: {e}")
                print(f"Warning: MCP init partial: {e}")

        # Plugins
        self.plugins = PluginLoader(tool_registry=self.tool_manager.get_registry())
        plugin_count = self.plugins.load_all()

        # Core agent components
        self.planner = Planner(self.router)
        self.reasoner = Reasoner(self.router)
        self.executor = Executor(self.router, self.tool_manager.get_registry())
        self.verifier = Verifier(self.router)
        self.fallback = FallbackManager(self.planner, self.router)
        self.learning = ImprovementEngine(self.router)
        # RAG auto-connect: consult the knowledge base before answering when
        # enabled (RAG_AUTOCONNECT env, default on). Lazy so it never breaks
        # startup if the rag package is unavailable.
        self._rag_augmenter = None
        self.task_manager = TaskManager()

        # Human in the loop
        self.approval = ApprovalManager(mode=os.environ.get("APPROVAL_MODE", "auto"))

        # Self-tool-creation: lets Maya write and register a brand-new
        # tool mid-task instead of being limited to the fixed set above.
        # Needs both self.plugins and self.approval, so it's wired here
        # rather than inside ToolManager (which is built before either
        # of those exists).
        from tools.system.tool_creator import ToolCreator
        self.tool_creator = ToolCreator(self.plugins, self.approval)
        self.tool_manager.get_registry().register(
            "create_tool", self.tool_creator.create_tool,
            "Write and register a brand-new tool for yourself when none "
            "of your existing tools can do the job. Args: name, code "
            "(must define register_tools(registry)), reason. Goes "
            "through a safety scan and human approval before it's loaded.",
            category="meta",
        )

        # Device Bridge: lets Maya reach a person's own paired desktop
        # for things a headless browser can't do. Does nothing unless a
        # device has actually been paired via Settings > Device Bridge.
        from infrastructure.device_bridge import DeviceBridge
        from tools.system.device_control import DeviceControlTool
        self.device_bridge = DeviceBridge()
        self._device_control_tool = DeviceControlTool(self.device_bridge, self.approval)
        self.tool_manager.get_registry().register(
            "device_control", self._device_control_tool.control,
            "Queue a GUI action (move_mouse, click, type_text, press_key, "
            "screenshot) on the person's own PAIRED desktop — for native "
            "apps a browser can't reach. Fails clearly if no device is "
            "paired. Requires human approval. Args: action, device_id?, "
            "reason, plus action-specific kwargs (x, y, text, key).",
            category="meta",
        )
        self.tool_manager.get_registry().register(
            "device_result", self._device_control_tool.device_result,
            "Check the status/result of a command queued with "
            "device_control. Args: command_id.",
            category="meta",
        )

        # Security
        self.risk = RiskChecker()
        self.permissions = PermissionManager()

        # Workflow
        self.workflow = WorkflowEngine(
            planner=self.planner,
            executor=self.executor,
            verifier=self.verifier,
            task_manager=self.task_manager,
            fallback_manager=self.fallback,
            memory_manager=self.memory,
            learning_engine=self.learning,
        )

        # Unified Checkpoint/Recovery System
        self._init_checkpoint_system()

        # Phase 18: AGI Cognitive Architecture
        self._init_cognitive_architecture()

        # Status report
        providers = self.router.available_providers()
        tools = self.tool_manager.get_registry().tool_names()

        log.info(f"Maya ready! Providers: {providers} | Tools: {len(tools)} | Plugins: {plugin_count}")
        print(f"\n{'='*50}")
        print(f"  Maya {self.VERSION} ULTRA - Ready")
        print(f"{'='*50}")
        print(f"  Providers : {', '.join(providers) or 'None (set API keys!)'}")
        print(f"  Tools     : {len(tools)}")
        print(f"  Plugins   : {plugin_count}")
        print(f"  Budget    : ${self.cost.budget_usd:.2f}")
        print(f"{'='*50}\n")

    def _init_cognitive_architecture(self):
        """Initialize Phase 18 cognitive architecture components."""
        try:
            # LLM function for cognitive components
            def llm_fn(prompt: str) -> str:
                return self.router.chat([{"role": "user", "content": prompt}])

            # Stream manager for real-time events
            self.stream_manager = get_stream_manager()
            self.stream_manager.set_storage_path("storage/streaming_sessions")

            # Cognitive Kernel - persistent cognitive process
            self.cognitive_kernel = get_cognitive_kernel(
                llm_fn=llm_fn,
                capability_registry=None,  # Will be set after registry init
                world_models=None,  # Will be set after world models init
                approval_manager=self.approval,
            )

            # Capability Registry - dynamic tool/agent/skill registration
            self.capability_registry = get_capability_registry(
                tool_registry=self.tool_manager.get_registry()
            )
            # Link registry to cognitive kernel
            self.cognitive_kernel.capability_registry = self.capability_registry

            # World Models - symbolic simulators for environments
            remote_deployer = None
            try:
                from infrastructure.remote_deploy import remote_deployer as _rd
                remote_deployer = _rd
            except Exception:
                pass
            self.world_models = create_world_models(remote_deployer)
            self.cognitive_kernel.world_models = self.world_models

            # Hierarchical Planner - HTN + MCTS
            self.hierarchical_planner = get_hierarchical_planner(
                kernel=self.cognitive_kernel,
                world_models=self.world_models,
                capability_registry=self.capability_registry,
            )

            # Metacognitive Monitor - confidence, surprise, recovery
            self.metacognitive_monitor = get_metacognitive_monitor(
                kernel=self.cognitive_kernel,
                world_models=self.world_models,
                hierarchical_planner=self.hierarchical_planner,
                capability_registry=self.capability_registry,
                approval_manager=self.approval,
            )

            # Agent Society - dynamic agent spawning and coordination
            self.agent_society = get_agent_society(
                kernel=self.cognitive_kernel,
                capability_registry=self.capability_registry,
                llm_fn=llm_fn,
                approval_manager=self.approval,
            )

            # Procedural Memory - episodic + procedural with distillation
            self.episodic_memory = get_episodic_memory()
            self.procedural_memory = get_procedural_memory()
            # Phase 37: kernel consults learned skills during goal grounding
            self.cognitive_kernel.procedural_memory = self.procedural_memory
            self.experience_distiller = get_experience_distiller(
                llm_fn=llm_fn,
                capability_registry=self.capability_registry,
            )
            self.experience_replay = get_experience_replay(
                kernel=self.cognitive_kernel,
            )

            # Tool Synthesizer - autonomous skill acquisition
            self.tool_synthesizer = get_tool_synthesizer(
                llm_fn=llm_fn,
                capability_registry=self.capability_registry,
                approval_manager=self.approval,
            )

            # Link tool registry to capability registry for dynamic tools
            self.tool_manager.get_registry().register(
                "synthesize_tool", self.tool_synthesizer.synthesize,
                "Autonomously research, experiment, and synthesize a new tool from a goal. "
                "Args: goal (str), requirements (dict, optional), async (bool, default true). "
                "Returns job_id. Goes through safety scan, sandbox testing, verification, and approval.",
                category="meta",
            )

            # Start cognitive kernel background threads
            self.cognitive_kernel.start()

            # Phase 34: register this Maya instance's pipeline as the ONE
            # execution backend of the unified control loop.
            self.cognitive_kernel.register_executor(self._unified_executor)
            self.cognitive_kernel.unified_loop_enabled = (
                os.getenv("MAYA_UNIFIED_LOOP", "false").lower() == "true"
            )

            # Phase 35: surface goals left incomplete by a previous run.
            # Log/audit ONLY — resumption is explicit via the resume API
            # (propose-only default), never auto-executed at boot.
            try:
                _incomplete = self.cognitive_kernel.get_incomplete_goals()
                if _incomplete:
                    log.info(
                        f"{len(_incomplete)} incomplete goal(s) from previous "
                        f"runs awaiting explicit resume"
                    )
                    self.cognitive_kernel._audit(
                        "incomplete_goals_on_boot",
                        "; ".join(g.description[:60] for g in _incomplete[:5]),
                    )
                    print(f"  Incomplete goals    : {len(_incomplete)} (resume via /cognitive/kernel/goals)")
            except Exception as e:
                log.debug(f"incomplete-goal scan skipped: {e}")

            # Start agent society
            self.agent_society.start()

            log.info("Phase 18 Cognitive Architecture initialized")
            print(f"\n{'='*50}")
            print(f"  Phase 18: AGI Cognitive Architecture Active")
            print(f"{'='*50}")
            print(f"  Cognitive Kernel    : Running (background threads)")
            print(f"  Capability Registry : {len(self.capability_registry._capabilities)} capabilities")
            print(f"  World Models        : {len(self.world_models)} domains")
            print(f"  Hierarchical Planner: HTN + MCTS")
            print(f"  Metacognitive Monitor: Confidence/Surprise/Recovery")
            print(f"  Agent Society       : Dynamic spawning + blackboard")
            print(f"  Procedural Memory   : Episodic + Skill distillation")
            print(f"  Tool Synthesizer    : Research -> Experiment -> Verify -> Register")
            print(f"{'='*50}\n")

        except Exception as e:
            log.warning(f"Phase 18 initialization partial: {e}")
            print(f"Warning: Phase 18 partial initialization: {e}")

    def _init_checkpoint_system(self):
        """Initialize the unified checkpoint/recovery system."""
        try:
            self.checkpoint_manager = get_checkpoint_manager()
            
            # Register core subsystems
            self.checkpoint_manager.register_subsystem(
                "memory",
                self.memory,
                self.memory.get_state if hasattr(self.memory, 'get_state') else lambda: {},
                self.memory.restore_state if hasattr(self.memory, 'restore_state') else lambda s: None,
                version="1.0",
            )
            
            self.checkpoint_manager.register_subsystem(
                "learning",
                self.learning,
                self.learning.get_state if hasattr(self.learning, 'get_state') else lambda: {},
                self.learning.restore_state if hasattr(self.learning, 'restore_state') else lambda s: None,
                version="1.0",
            )
            
            self.checkpoint_manager.register_subsystem(
                "task_manager",
                self.task_manager,
                self.task_manager.get_state if hasattr(self.task_manager, 'get_state') else lambda: {},
                self.task_manager.restore_state if hasattr(self.task_manager, 'restore_state') else lambda s: None,
                version="1.0",
            )
            
            # Register Phase 18 subsystems if available
            if hasattr(self, 'cognitive_kernel') and self.cognitive_kernel:
                self.checkpoint_manager.register_subsystem(
                    "cognitive_kernel",
                    self.cognitive_kernel,
                    self.cognitive_kernel.get_state,
                    self.cognitive_kernel.restore_state,
                    version="1.0",
                )
            
            if hasattr(self, 'agent_society') and self.agent_society:
                self.checkpoint_manager.register_subsystem(
                    "agent_society",
                    self.agent_society,
                    self.agent_society.get_state,
                    self.agent_society.restore_state,
                    version="1.0",
                )
            
            if hasattr(self, 'tool_synthesizer') and self.tool_synthesizer:
                self.checkpoint_manager.register_subsystem(
                    "tool_synthesizer",
                    self.tool_synthesizer,
                    self.tool_synthesizer.get_state if hasattr(self.tool_synthesizer, 'get_state') else lambda: {},
                    self.tool_synthesizer.restore_state if hasattr(self.tool_synthesizer, 'restore_state') else lambda s: None,
                    version="1.0",
                )
            
            # Start auto-checkpoint thread (every 5 minutes)
            self.checkpoint_manager.auto_checkpoint_loop(interval_seconds=300)
            
            log.info("Unified checkpoint system initialized")
            
        except Exception as e:
            log.warning(f"Checkpoint system initialization partial: {e}")
            print(f"Warning: Checkpoint system partial initialization: {e}")

    def create_checkpoint(self, metadata: Dict = None) -> str:
        """Create a unified checkpoint of all subsystems. Returns checkpoint ID."""
        if hasattr(self, 'checkpoint_manager'):
            checkpoint = self.checkpoint_manager.create_checkpoint(metadata)
            return checkpoint.id
        return ""

    def list_checkpoints(self, status: str = None, limit: int = 20) -> List[Dict]:
        """List available checkpoints."""
        if hasattr(self, 'checkpoint_manager'):
            from infrastructure.unified_checkpoint import CheckpointStatus
            status_enum = CheckpointStatus(status) if status else None
            checkpoints = self.checkpoint_manager.list_checkpoints(status_enum, limit)
            return [cp.to_dict() for cp in checkpoints]
        return []

    def recover_from_checkpoint(self, checkpoint_id: str) -> bool:
        """Recover all subsystems from a checkpoint."""
        if hasattr(self, 'checkpoint_manager'):
            return self.checkpoint_manager.recover_from_checkpoint(checkpoint_id)
        return False

    def get_latest_checkpoint(self) -> Optional[Dict]:
        """Get the most recent completed checkpoint."""
        if hasattr(self, 'checkpoint_manager'):
            cp = self.checkpoint_manager.get_latest_checkpoint()
            return cp.to_dict() if cp else None
        return None

    # ── scoped memory helper ────────────────────────────────────────
    _scoped_memory_instance = None

    def _scoped_memory(self):
        """Lazy singleton ScopedMemory instance (thread-safe SQLite)."""
        if self._scoped_memory_instance is None:
            try:
                from enterprise.scoped_memory import ScopedMemory
                self._scoped_memory_instance = ScopedMemory()
            except Exception:
                self._scoped_memory_instance = False  # sentinel
        return self._scoped_memory_instance if self._scoped_memory_instance else None

    def _scoped_search(self, scope: str, query: str, limit: int = 5) -> str:
        """Search scoped memory and format as text, or return empty string."""
        sm = self._scoped_memory()
        if not sm:
            return ""
        try:
            results = sm.search(scope, query, limit=limit)
            if results:
                lines = [f"- {r['content'][:200]}" for r in results]
                return "\n".join(lines)
        except Exception:
            pass
        return ""

    def _scoped_add(self, scope: str, content: str, memory_type: str = "general"):
        """Write to scoped memory.  Never raises."""
        sm = self._scoped_memory()
        if not sm:
            return
        try:
            sm.add(scope, content, author="system", memory_type=memory_type)
        except Exception:
            pass

    def run(self, goal: str, max_retries: int = 3, task_id: str = None,
            progress_callback=None, scope: str = "", stream_emitter=None) -> dict:
        """
        Single control entry for goals (Phase 34).

        When MAYA_UNIFIED_LOOP=true and the cognitive kernel is available,
        every goal goes through the kernel's unified cognitive loop
        (persistent goal -> memory/belief grounding -> execution -> learning).
        The kernel delegates actual work back to this Maya instance's
        pipeline — the workflow engine, agents and tools are capabilities,
        never controllers.

        Otherwise falls through to the direct pipeline (legacy behavior).
        """
        kernel = getattr(self, "cognitive_kernel", None)
        if (
            os.getenv("MAYA_UNIFIED_LOOP", "false").lower() == "true"
            and kernel is not None
            and hasattr(kernel, "process_goal")
            and getattr(kernel, "has_executor", False)
        ):
            log.info(f"Unified loop: goal via kernel | {goal[:80]}")
            return self._kernel_process(goal)
        return self._run_pipeline(
            goal, max_retries=max_retries, task_id=task_id,
            progress_callback=progress_callback, scope=scope,
            stream_emitter=stream_emitter,
        )

    def _unified_executor(self, description: str, cognitive_context: dict) -> dict:
        """Execution backend called BY the kernel's unified loop.

        This is the inverse of run(): the kernel controls, the pipeline
        executes. Risk checking, approval gates and memory all stay inside
        the pipeline, so every safety property of a direct run() is preserved.
        """
        result = self._run_pipeline(description)
        return {
            "success": bool(result.get("success")),
            "result": str(result.get("result", "")),
            "task_id": result.get("task_id"),
            "quality_score": result.get("quality_score"),
        }

    def _kernel_process(self, goal: str) -> dict:
        """Run a goal through the kernel's unified loop."""
        try:
            kr = self.cognitive_kernel.process_goal(goal, execute=True)
        except Exception as e:
            log.warning(f"Unified loop failed, falling back to pipeline: {e}")
            return self._run_pipeline(goal)

        outcome = kr.get("outcome", {})
        result = {
            "success": bool(kr.get("success")),
            "result": str(outcome.get("result", "")),
            "goal_id": kr.get("goal_id"),
            "unified_loop": True,
        }
        if not kr.get("success") and outcome.get("error"):
            result["error"] = outcome["error"]
        return result

    def _run_pipeline(self, goal: str, max_retries: int = 3, task_id: str = None,
                      progress_callback=None, scope: str = "", stream_emitter=None) -> dict:
        """
        Goal achieve করার জন্য full autonomous workflow run করে.
        `progress_callback`, if given, is called live as planning/execution/
        verification happen — see WorkflowEngine.run() for the payload shapes.
        *scope* — when non-empty, routes memory reads/writes through the
        per-scope ScopedMemory store instead of the global MemoryManager.
        *stream_emitter* — if given, emits structured streaming events for
        real-time UI updates (WebSocket/SSE).
        """
        log.info(f"New goal: {goal}")

        # Budget check
        if self.cost.is_over_budget():
            return {"success": False, "result": "Budget exceeded. Reset cost tracker."}

        # Risk check
        risk = self.risk.check(goal)
        if not risk.get("allow"):
            log.warning(f"Goal blocked by risk checker: {risk.get('reason')}")
            return {"success": False, "result": f"Blocked: {risk.get('reason')}"}

        # Human approval if needed
        if self.approval.needs_approval(goal, risk.get("level", "low")):
            approved = self.approval.request_approval(
                goal, reason=risk.get("reason", ""),
                risk_level=risk.get("level", "high"), task_id=task_id,
            )
            if not approved:
                return {"success": False, "result": "User denied approval"}
            if stream_emitter:
                import asyncio
                asyncio.run(stream_emitter.approval_result(True))

        # Memory context — use scoped store when scope is set
        self.memory.set_goal(goal)
        if scope:
            memory_hints = self._scoped_search(scope, goal, limit=10)
            past_tips = ""  # episodic tips stay global; cross-instance reads
                             # are blocked by ScopedMemory WHERE scope=?
        else:
            memory_hints = self.memory.get_relevant_memories(goal)
            past_tips = self.memory.get_tips_for_goal(goal)

        # Knowledge hints (Phase 36): what Maya already knows relevant to
        # this goal, from its own belief store — consulted during planning.
        _kernel = getattr(self, "cognitive_kernel", None)
        if _kernel is not None and hasattr(_kernel, "knowledge_query"):
            try:
                hits = _kernel.knowledge_query(goal, limit=3)
                if hits:
                    k_lines = "\n".join(
                        f"- {h['proposition']} (confidence {h['confidence']})"
                        for h in hits
                    )
                    memory_hints = (
                        (memory_hints + "\n" if memory_hints else "")
                        + "Relevant knowledge:\n" + k_lines
                    )
            except Exception:
                pass

        # Skill hints (Phase 37): learned skills relevant to this goal are
        # surfaced to the planner so distilled experience generalizes to
        # new but similar situations.
        _pm = getattr(self, "procedural_memory", None)
        if _pm is not None and hasattr(_pm, "search_skills"):
            try:
                skill_hits = _pm.search_skills(goal, limit=2)
                if skill_hits:
                    s_lines = "\n".join(
                        f"- {h['name']}: {h['description']} "
                        f"(success rate {h['success_rate']})"
                        for h in skill_hits
                    )
                    memory_hints = (
                        (memory_hints + "\n" if memory_hints else "")
                        + "Applicable learned skills:\n" + s_lines
                    )
            except Exception:
                pass

        # Run workflow
        result = self.workflow.run(goal, max_retries=max_retries, 
                                   progress_callback=progress_callback,
                                   stream_emitter=stream_emitter)

        # Persist result to scoped memory if scope is set
        if scope and result.get("success"):
            summary = f"Goal: {goal[:200]}\nResult: {str(result.get('result', ''))[:500]}"
            self._scoped_add(scope, summary, memory_type="task")

        # Cost summary
        self.cost.print_summary()

        return result

    def chat(self, message: str, history: list = None, scope: str = "") -> str:
        """Simple chat without full agent workflow.

        `history` is an optional list of {"role": "user"|"assistant", "content": str}
        from earlier turns in the same conversation. Without it, every call is a
        fresh single-turn exchange and Maya has no memory of prior messages in
        the thread — pass the conversation's stored history (e.g. from Supabase
        chat_messages) to make follow-up questions actually work.

        *scope* — when non-empty, routes the memory write through the per-scope
        ScopedMemory store instead of the global MemoryManager.
        """
        system_prompt = (
            f"You are Maya {self.VERSION}, an autonomous AI assistant created "
            "by Urmi Mam. If anyone asks who made you, who created you, or who "
            "built you, say that Urmi Mam created you. Be helpful, precise, "
            "and concise."
        )
        # RAG auto-connect: ground the answer in indexed knowledge when relevant.
        citations = []
        addon, citations = self._augment_with_knowledge(message)
        if addon:
            system_prompt += addon

        # Prepend scoped memory context when scope is set
        if scope:
            ctx = self._scoped_search(scope, message, limit=5)
            if ctx:
                system_prompt += (
                    "\n\nRelevant past memories for this instance:\n" + ctx
                )

        messages = [{"role": "system", "content": system_prompt}]
        if history:
            messages.extend(history)
        messages.append({"role": "user", "content": message})
        response = self.router.chat(messages)

        if citations:
            from rag.augmenter import RAGAugmenter
            footer = RAGAugmenter.format_sources(citations)
            if footer:
                response = f"{response}\n\n{footer}"
        if scope:
            self._scoped_add(scope, f"Chat: {message[:100]}", memory_type="chat")
        else:
            self.memory.add(f"Chat: {message[:100]}", memory_type="chat")
        return response

    def _augment_with_knowledge(self, message: str):
        """Return (system_addon, citations) from the knowledge base, or
        ("", []) when RAG auto-connect is off or nothing relevant is found."""
        import os
        if os.getenv("RAG_AUTOCONNECT", "true").lower() == "false":
            return "", []
        try:
            if self._rag_augmenter is None:
                from rag.augmenter import RAGAugmenter
                self._rag_augmenter = RAGAugmenter()
            return self._rag_augmenter.augment(message)
        except Exception:
            return "", []

    def think(self, problem: str) -> str:
        """Deep reasoning about a problem."""
        result = self.reasoner.think(problem, depth="deep")
        return result.get("final_answer", str(result))

    def remember(self, content: str, memory_type: str = "general") -> str:
        """Manually add to memory. Returns the real memory id."""
        return self.memory.add(content, memory_type)

    def recall(self, query: str, limit: int = 5):
        """Search memory."""
        return self.memory.search(query, limit=limit)

    def add_tool(self, name: str, func, description: str = "", category: str = "custom"):
        """Runtime এ নতুন tool add করে।"""
        self.tool_manager.get_registry().register(name, func, description, category)
        log.info(f"Tool added: {name}")

    def load_plugin(self, path: str) -> bool:
        """Plugin load করে।"""
        return self.plugins.load_plugin(path)

    def status(self) -> dict:
        """Maya-র current status।"""
        return {
            "version": self.VERSION,
            "providers": self.router.available_providers(),
            "tools": self.tool_manager.get_registry().tool_names(),
            "plugins": self.plugins.list_plugins(),
            "memory": self.memory.get_stats(),
            "cost": self.cost.get_summary(),
            "tasks": len(self.task_manager.all_tasks()),
        }
