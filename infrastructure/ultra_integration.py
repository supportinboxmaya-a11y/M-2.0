"""
Maya 2.0 ULTRA — Integration Layer (Phase 2)
=============================================
Connects all 4 core capabilities into a unified autonomous AI system.

Capabilities integrated:
1. Dynamic Tool Creation (Self-Evolution Loop)
2. Vision & Computer Use (Browser Automation)
3. Isolated Sandbox Security
4. Multi-Agent Swarm Framework

This module provides:
- Unified initialization and lifecycle management
- Cross-capability workflows
- High-level API for autonomous task execution
- Event-driven coordination between components
"""

import asyncio
import json
import os
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, AsyncGenerator
from enum import Enum

from config.settings import STORAGE_DIR

# Import all four capabilities
from infrastructure.dynamic_tool_framework import (
    DynamicToolManager, DynamicToolSpec, DynamicToolRecord,
    ToolCreationStatus, SafetyLevel, create_dynamic_tool_from_goal
)
from infrastructure.vision_browser import (
    VisionBrowserManager, VisionBrowserAgent, BrowserTask,
    InteractionStep, InteractionType, ComputerUseTools,
    get_vision_browser_manager, init_vision_browser
)
from infrastructure.secure_sandbox import (
    SecureSandboxManager, SandboxConfig, SandboxLimits,
    SandboxLanguage, ExecutionStatus, execute_dynamic_tool_securely,
    get_secure_sandbox_manager
)
from infrastructure.swarm import (
    SwarmManager, CoordinatorAgent, ArchitectAgent, CoderAgent,
    TesterAgent, ReviewerAgent, RedisTaskQueue, SwarmTask,
    AgentRole, TaskPriority, TaskStatus, init_swarm, get_swarm_manager
)
from infrastructure.capability_registry import get_capability_registry
from tools.tool_manager import ToolManager


# ─── Configuration ───────────────────────────────────────────────
ULTRA_DIR = STORAGE_DIR / "ultra"
ULTRA_DIR.mkdir(parents=True, exist_ok=True)
ULTRA_DB = str(ULTRA_DIR / "ultra.db")


# ─── Enums ───────────────────────────────────────────────────────
class UltraMode(Enum):
    """Operation modes for the ultra system."""
    ASSISTIVE = "assistive"      # Human-in-the-loop, propose only
    AUTONOMOUS = "autonomous"    # Full autonomy with approval gates
    SWARM = "swarm"              # Multi-agent collaborative mode
    LEARNING = "learning"        # Self-improvement mode


class TaskComplexity(Enum):
    SIMPLE = "simple"           # Single tool/action
    MODERATE = "moderate"       # Few steps, single agent
    COMPLEX = "complex"         # Multi-step, requires planning
    SWARM = "swarm"             # Requires multi-agent coordination


# ─── Data Classes ────────────────────────────────────────────────
@dataclass
class UltraTask:
    """A high-level task for the ultra system."""
    task_id: str
    goal: str
    mode: UltraMode = UltraMode.ASSISTIVE
    complexity: TaskComplexity = TaskComplexity.MODERATE
    context: Dict = field(default_factory=dict)
    status: str = "pending"  # pending, running, completed, failed
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    result: Dict = field(default_factory=dict)
    error: str = ""
    metadata: Dict = field(default_factory=dict)


@dataclass
class UltraCapabilities:
    """Status of all ultra capabilities."""
    dynamic_tools: bool = False
    vision_browser: bool = False
    secure_sandbox: bool = False
    swarm: bool = False
    all_ready: bool = False


# ─── Main Ultra System ───────────────────────────────────────────
class MayaUltra:
    """
    Maya 2.0 ULTRA - Unified autonomous AI system.
    Integrates all four core capabilities into a cohesive whole.
    """
    
    def __init__(
        self,
        llm_fn: Callable = None,
        mode: UltraMode = UltraMode.ASSISTIVE,
        enable_dynamic_tools: bool = True,
        enable_vision_browser: bool = True,
        enable_secure_sandbox: bool = True,
        enable_swarm: bool = True,
        swarm_config: Dict = None,
    ):
        self.llm_fn = llm_fn
        self.mode = mode
        self.swarm_config = swarm_config or {}
        
        # Capability flags
        self.enable_dynamic_tools = enable_dynamic_tools
        self.enable_vision_browser = enable_vision_browser
        self.enable_secure_sandbox = enable_secure_sandbox
        self.enable_swarm = enable_swarm
        
        # Components (initialized lazily)
        self._dynamic_tools: Optional[DynamicToolManager] = None
        self._vision_browser: Optional[VisionBrowserManager] = None
        self._secure_sandbox: Optional[SecureSandboxManager] = None
        self._swarm: Optional[SwarmManager] = None
        self._tool_manager: Optional[ToolManager] = None
        self._capability_registry = get_capability_registry()
        
        # State
        self._initialized = False
        self._running = False
        self._active_tasks: Dict[str, UltraTask] = {}
        self._event_handlers: Dict[str, List[Callable]] = {}
        
        # Stats
        self._stats = {
            "tasks_completed": 0,
            "tasks_failed": 0,
            "tools_created": 0,
            "browser_actions": 0,
            "sandbox_executions": 0,
            "swarm_tasks": 0,
        }
    
    async def initialize(self) -> UltraCapabilities:
        """Initialize all enabled capabilities."""
        caps = UltraCapabilities()
        
        # Initialize dynamic tools
        if self.enable_dynamic_tools:
            try:
                self._dynamic_tools = DynamicToolManager(
                    llm_fn=self.llm_fn,
                    tool_manager=self._tool_manager,
                )
                caps.dynamic_tools = True
                print("✅ Dynamic Tool Framework initialized")
            except Exception as e:
                print(f"⚠️ Dynamic Tool Framework failed: {e}")
        
        # Initialize vision browser
        if self.enable_vision_browser:
            try:
                self._vision_browser = await init_vision_browser(
                    llm_fn=self.llm_fn,
                    max_contexts=5,
                    headless=True,
                )
                caps.vision_browser = True
                print("✅ Vision Browser initialized")
            except Exception as e:
                print(f"⚠️ Vision Browser failed: {e}")
        
        # Initialize secure sandbox
        if self.enable_secure_sandbox:
            try:
                self._secure_sandbox = get_secure_sandbox_manager()
                caps.secure_sandbox = True
                print("✅ Secure Sandbox initialized")
            except Exception as e:
                print(f"⚠️ Secure Sandbox failed: {e}")
        
        # Initialize swarm
        if self.enable_swarm and self.llm_fn:
            try:
                self._swarm = await init_swarm(
                    llm_fn=self.llm_fn,
                    **self.swarm_config
                )
                caps.swarm = True
                print("✅ Multi-Agent Swarm initialized")
            except Exception as e:
                print(f"⚠️ Multi-Agent Swarm failed: {e}")
        
        # Initialize tool manager
        self._tool_manager = ToolManager()
        
        # Register ultra tools
        self._register_ultra_tools()
        
        caps.all_ready = all([
            caps.dynamic_tools or not self.enable_dynamic_tools,
            caps.vision_browser or not self.enable_vision_browser,
            caps.secure_sandbox or not self.enable_secure_sandbox,
            caps.swarm or not self.enable_swarm,
        ])
        
        self._initialized = True
        return caps
    
    def _register_ultra_tools(self) -> None:
        """Register ultra-specific tools with the tool manager."""
        if not self._tool_manager:
            return
        
        registry = self._tool_manager.get_registry()
        
        # Dynamic tool creation
        if self._dynamic_tools:
            async def create_tool(goal: str, requirements: str = "") -> Dict:
                return await create_dynamic_tool_from_goal(
                    goal, self._dynamic_tools, {"requirements": requirements}
                )
            
            registry.register(
                "create_dynamic_tool", create_tool,
                "Create a new tool from a natural language goal",
                category="ultra"
            )
        
        # Vision browser tools
        if self._vision_browser:
            computer_tools = self._vision_browser.get_computer_tools()
            
            registry.register(
                "browser_autonomous", computer_tools.browse_and_act,
                "Autonomously browse and act to achieve a goal",
                category="ultra"
            )
            registry.register(
                "browser_click", computer_tools.click_element,
                "Click element by visual description",
                category="ultra"
            )
            registry.register(
                "browser_type", computer_tools.type_text,
                "Type text into element by visual description",
                category="ultra"
            )
            registry.register(
                "browser_extract", computer_tools.extract_data,
                "Extract data from page using vision",
                category="ultra"
            )
        
        # Secure sandbox tools
        if self._secure_sandbox:
            async def sandbox_execute(
                code: str, 
                language: str = "python",
                limits: Dict = None
            ) -> Dict:
                result = await self._secure_sandbox.execute(
                    code=code,
                    language=SandboxLanguage(language),
                    limits=SandboxLimits(**limits) if limits else None,
                )
                return {
                    "success": result.status == ExecutionStatus.COMPLETED,
                    "stdout": result.stdout,
                    "stderr": result.stderr,
                    "exit_code": result.exit_code,
                    "duration_ms": result.duration_ms,
                    "artifacts": result.artifacts,
                }
            
            registry.register(
                "sandbox_execute", sandbox_execute,
                "Execute code in secure sandbox",
                category="ultra"
            )
        
        # Swarm tools
        if self._swarm:
            async def swarm_execute(goal: str, context: Dict = None) -> Dict:
                return await self._swarm.execute_goal(goal, context)
            
            registry.register(
                "swarm_execute", swarm_execute,
                "Execute a goal using the multi-agent swarm",
                category="ultra"
            )
    
    async def start(self) -> None:
        """Start the ultra system."""
        if not self._initialized:
            await self.initialize()
        
        self._running = True
        print("🚀 Maya 2.0 ULTRA started")
    
    async def stop(self) -> None:
        """Stop the ultra system."""
        self._running = False
        
        if self._swarm:
            await self._swarm.stop()
        
        if self._vision_browser:
            await self._vision_browser.shutdown()
        
        print("🛑 Maya 2.0 ULTRA stopped")
    
    # ─── High-Level Task Execution ──────────────────────────────
    async def execute_task(self, task: UltraTask) -> UltraTask:
        """Execute a high-level task using appropriate capabilities."""
        task.status = "running"
        task.updated_at = time.time()
        self._active_tasks[task.task_id] = task
        
        try:
            if task.complexity == TaskComplexity.SIMPLE:
                result = await self._execute_simple(task)
            elif task.complexity == TaskComplexity.MODERATE:
                result = await self._execute_moderate(task)
            elif task.complexity == TaskComplexity.COMPLEX:
                result = await self._execute_complex(task)
            elif task.complexity == TaskComplexity.SWARM:
                result = await self._execute_swarm(task)
            else:
                result = await self._execute_moderate(task)
            
            task.status = "completed"
            task.result = result
            self._stats["tasks_completed"] += 1
            
        except Exception as e:
            task.status = "failed"
            task.error = str(e)
            self._stats["tasks_failed"] += 1
        
        task.updated_at = time.time()
        return task
    
    async def _execute_simple(self, task: UltraTask) -> Dict:
        """Execute simple task - single tool or action."""
        # Use LLM to determine what tool/action to use
        if not self.llm_fn:
            raise ValueError("LLM function required for task execution")
        
        prompt = f"""Determine the best action for this simple task:
Goal: {task.goal}
Context: {json.dumps(task.context)}
Available capabilities:
- Dynamic tools: {self.enable_dynamic_tools}
- Vision browser: {self.enable_vision_browser}
- Secure sandbox: {self.enable_secure_sandbox}

Return JSON with: action, tool, parameters"""
        
        response = await self.llm_fn(prompt)
        action = json.loads(response)
        
        # Execute based on action
        # (Simplified - would route to appropriate capability)
        return {"action": action, "result": "executed"}
    
    async def _execute_moderate(self, task: UltraTask) -> Dict:
        """Execute moderate task - few steps, may need planning."""
        if self._swarm and self.mode == UltraMode.SWARM:
            return await self._execute_swarm(task)
        
        # Use coordinator agent for planning
        if self._swarm and self._swarm.coordinator:
            tasks = await self._swarm.coordinator.decompose_goal(task.goal, task.context)
            for t in tasks:
                await self._swarm.task_queue.enqueue_task(t)
            
            results = await self._swarm.coordinator._wait_for_completion(tasks)
            return await self._swarm.coordinator._aggregate_results(task.goal, tasks, results)
        
        # Fallback: use dynamic tools + browser
        return await self._execute_with_tools(task)
    
    async def _execute_complex(self, task: UltraTask) -> Dict:
        """Execute complex task - multi-step, requires planning."""
        return await self._execute_swarm(task)
    
    async def _execute_swarm(self, task: UltraTask) -> Dict:
        """Execute task using the multi-agent swarm."""
        if not self._swarm:
            raise ValueError("Swarm not enabled")
        
        self._stats["swarm_tasks"] += 1
        return await self._swarm.execute_goal(task.goal, task.context)
    
    async def _execute_with_tools(self, task: UltraTask) -> Dict:
        """Execute task using dynamic tools and browser."""
        results = {}
        
        # Create tools if needed
        if self._dynamic_tools and "create_tool" in task.goal.lower():
            tool_result = await create_dynamic_tool_from_goal(
                task.goal, self._dynamic_tools, task.context
            )
            results["tool_creation"] = tool_result.__dict__
            self._stats["tools_created"] += 1
        
        # Use browser if needed
        if self._vision_browser and ("browse" in task.goal.lower() or "web" in task.goal.lower()):
            browser_result = await self._vision_browser.execute_goal(task.goal)
            results["browser"] = browser_result
            self._stats["browser_actions"] += 1
        
        return results
    
    # ─── Convenience Methods ────────────────────────────────────
    async def create_tool(self, goal: str, requirements: str = "") -> DynamicToolRecord:
        """Create a dynamic tool from a goal."""
        if not self._dynamic_tools:
            raise ValueError("Dynamic tools not enabled")
        
        self._stats["tools_created"] += 1
        return await create_dynamic_tool_from_goal(goal, self._dynamic_tools, {"requirements": requirements})
    
    async def browse_and_act(self, goal: str, url: str = "") -> Dict:
        """Autonomous browser action."""
        if not self._vision_browser:
            raise ValueError("Vision browser not enabled")
        
        self._stats["browser_actions"] += 1
        return await self._vision_browser.execute_goal(goal, url)
    
    async def execute_code(self, code: str, language: str = "python", limits: Dict = None) -> Dict:
        """Execute code in secure sandbox."""
        if not self._secure_sandbox:
            raise ValueError("Secure sandbox not enabled")
        
        self._stats["sandbox_executions"] += 1
        result = await self._secure_sandbox.execute(
            code=code,
            language=SandboxLanguage(language),
            limits=SandboxLimits(**limits) if limits else None,
        )
        return {
            "success": result.status == ExecutionStatus.COMPLETED,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "exit_code": result.exit_code,
            "duration_ms": result.duration_ms,
            "artifacts": result.artifacts,
        }
    
    async def run_swarm(self, goal: str, context: Dict = None) -> Dict:
        """Run multi-agent swarm on a goal."""
        if not self._swarm:
            raise ValueError("Swarm not enabled")
        
        self._stats["swarm_tasks"] += 1
        return await self._swarm.execute_goal(goal, context)
    
    def get_capabilities(self) -> UltraCapabilities:
        """Get status of all capabilities."""
        return UltraCapabilities(
            dynamic_tools=self._dynamic_tools is not None,
            vision_browser=self._vision_browser is not None,
            secure_sandbox=self._secure_sandbox is not None,
            swarm=self._swarm is not None,
            all_ready=self._initialized and self._running,
        )
    
    def get_stats(self) -> Dict:
        """Get system statistics."""
        return {
            **self._stats,
            "active_tasks": len(self._active_tasks),
            "mode": self.mode.value,
            "capabilities": self.get_capabilities().__dict__,
        }
    
    def get_active_tasks(self) -> List[UltraTask]:
        """Get all active tasks."""
        return list(self._active_tasks.values())
    
    def register_event_handler(self, event: str, handler: Callable) -> None:
        """Register an event handler."""
        if event not in self._event_handlers:
            self._event_handlers[event] = []
        self._event_handlers[event].append(handler)
    
    async def _emit_event(self, event: str, data: Dict) -> None:
        """Emit an event to all handlers."""
        for handler in self._event_handlers.get(event, []):
            try:
                if asyncio.iscoroutinefunction(handler):
                    await handler(data)
                else:
                    handler(data)
            except Exception as e:
                print(f"Event handler error: {e}")


# ─── API Endpoint Helpers ────────────────────────────────────────
def create_ultra_api_routes(app, ultra: MayaUltra):
    """Create FastAPI routes for the ultra system."""
    from fastapi import HTTPException
    from pydantic import BaseModel
    
    class UltraTaskRequest(BaseModel):
        goal: str
        mode: str = "assistive"
        complexity: str = "moderate"
        context: Dict = {}
    
    class ToolCreationRequest(BaseModel):
        goal: str
        requirements: str = ""
    
    class BrowserRequest(BaseModel):
        goal: str
        url: str = ""
    
    class SandboxRequest(BaseModel):
        code: str
        language: str = "python"
        limits: Dict = {}
    
    class SwarmRequest(BaseModel):
        goal: str
        context: Dict = {}
    
    @app.post("/api/v1/ultra/task")
    async def create_ultra_task(req: UltraTaskRequest):
        """Create and execute an ultra task."""
        task = UltraTask(
            task_id=uuid.uuid4().hex[:12],
            goal=req.goal,
            mode=UltraMode(req.mode),
            complexity=TaskComplexity(req.complexity),
            context=req.context,
        )
        result = await ultra.execute_task(task)
        return result.__dict__
    
    @app.post("/api/v1/ultra/tool/create")
    async def create_ultra_tool(req: ToolCreationRequest):
        """Create a dynamic tool."""
        if not ultra.enable_dynamic_tools:
            raise HTTPException(503, "Dynamic tools not enabled")
        tool = await ultra.create_tool(req.goal, req.requirements)
        return tool.__dict__
    
    @app.post("/api/v1/ultra/browser/act")
    async def ultra_browser_act(req: BrowserRequest):
        """Autonomous browser action."""
        if not ultra.enable_vision_browser:
            raise HTTPException(503, "Vision browser not enabled")
        return await ultra.browse_and_act(req.goal, req.url)
    
    @app.post("/api/v1/ultra/sandbox/execute")
    async def ultra_sandbox_execute(req: SandboxRequest):
        """Execute code in secure sandbox."""
        if not ultra.enable_secure_sandbox:
            raise HTTPException(503, "Secure sandbox not enabled")
        return await ultra.execute_code(req.code, req.language, req.limits)
    
    @app.post("/api/v1/ultra/swarm/execute")
    async def ultra_swarm_execute(req: SwarmRequest):
        """Execute goal with multi-agent swarm."""
        if not ultra.enable_swarm:
            raise HTTPException(503, "Swarm not enabled")
        return await ultra.run_swarm(req.goal, req.context)
    
    @app.get("/api/v1/ultra/status")
    async def ultra_status():
        """Get ultra system status."""
        return {
            "capabilities": ultra.get_capabilities().__dict__,
            "stats": ultra.get_stats(),
            "active_tasks": [t.__dict__ for t in ultra.get_active_tasks()],
        }
    
    @app.get("/api/v1/ultra/capabilities")
    async def ultra_capabilities():
        """Get detailed capability status."""
        caps = ultra.get_capabilities()
        details = {
            "dynamic_tools": {
                "enabled": caps.dynamic_tools,
                "tools_count": len(ultra._dynamic_tools.list_tools()) if ultra._dynamic_tools else 0,
            },
            "vision_browser": {
                "enabled": caps.vision_browser,
                "pool_status": await ultra._vision_browser.get_status() if ultra._vision_browser else {},
            },
            "secure_sandbox": {
                "enabled": caps.secure_sandbox,
                "stats": ultra._secure_sandbox.get_stats() if ultra._secure_sandbox else {},
            },
            "swarm": {
                "enabled": caps.swarm,
                "status": ultra._swarm.get_status() if ultra._swarm else {},
            },
        }
        return details


# ─── Module Singleton ────────────────────────────────────────────
_ultra_instance: Optional[MayaUltra] = None


def get_ultra_instance(**kwargs) -> MayaUltra:
    global _ultra_instance
    if _ultra_instance is None:
        _ultra_instance = MayaUltra(**kwargs)
    return _ultra_instance


async def init_ultra(**kwargs) -> MayaUltra:
    ultra = get_ultra_instance(**kwargs)
    await ultra.initialize()
    await ultra.start()
    return ultra


# ─── Export ──────────────────────────────────────────────────────
__all__ = [
    "MayaUltra",
    "UltraTask",
    "UltraCapabilities",
    "UltraMode",
    "TaskComplexity",
    "create_ultra_api_routes",
    "get_ultra_instance",
    "init_ultra",
]