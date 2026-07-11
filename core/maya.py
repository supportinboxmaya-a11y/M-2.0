"""
Maya 2.0 ULTRA - Main Agent
-----------------------------
Autonomous AI Agent that plans, executes, verifies, and learns.
"""

import os
import sys
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

    def run(self, goal: str, max_retries: int = 3, task_id: str = None, progress_callback=None) -> dict:
        """
        Goal achieve করার জন্য full autonomous workflow run করে.
        `progress_callback`, if given, is called live as planning/execution/
        verification happen — see WorkflowEngine.run() for the payload shapes.
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

        # Memory context
        self.memory.set_goal(goal)
        memory_hints = self.memory.get_relevant_memories(goal)
        past_tips = self.memory.get_tips_for_goal(goal)

        # Run workflow
        result = self.workflow.run(goal, max_retries=max_retries, progress_callback=progress_callback)

        # Cost summary
        self.cost.print_summary()

        return result

    def chat(self, message: str, history: list = None) -> str:
        """Simple chat without full agent workflow.

        `history` is an optional list of {"role": "user"|"assistant", "content": str}
        from earlier turns in the same conversation. Without it, every call is a
        fresh single-turn exchange and Maya has no memory of prior messages in
        the thread — pass the conversation's stored history (e.g. from Supabase
        chat_messages) to make follow-up questions actually work.
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
