"""
Maya 2.0 ULTRA — Multi-Agent Swarm Framework (Phase 1.4)
=========================================================
Specialized multi-agent architecture with Redis task queues for coordination.

Agents:
- Architect: System design, planning, architecture decisions
- Coder: Implementation, code generation, refactoring
- Tester: Test creation, execution, validation
- Reviewer: Code review, quality assurance, security audit

Features:
- Redis-based task queue for distributed coordination
- Agent specialization with distinct roles and capabilities
- Inter-agent communication protocol
- Task delegation and result aggregation
- Health monitoring and load balancing
"""

import asyncio
import json
import os
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set, AsyncGenerator
from abc import ABC, abstractmethod

import redis.asyncio as redis

from config.settings import STORAGE_DIR
from agents.base import BaseAgent
from agents.messaging import MessageBus
from agents.registry import AgentRegistry
from infrastructure.secure_sandbox import SecureSandboxManager, SandboxLanguage, ExecutionStatus
from infrastructure.dynamic_tool_framework import DynamicToolManager, DynamicToolSpec
from infrastructure.vision_browser import VisionBrowserManager, ComputerUseTools


# ─── Configuration ───────────────────────────────────────────────
SWARM_DIR = STORAGE_DIR / "swarm"
SWARM_DIR.mkdir(parents=True, exist_ok=True)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")


# ─── Enums ───────────────────────────────────────────────────────
class AgentRole(Enum):
    ARCHITECT = "architect"
    CODER = "coder"
    TESTER = "tester"
    REVIEWER = "reviewer"
    COORDINATOR = "coordinator"


class TaskPriority(Enum):
    LOW = 1
    NORMAL = 5
    HIGH = 10
    CRITICAL = 20


class TaskStatus(Enum):
    PENDING = "pending"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    REQUIRES_REVIEW = "requires_review"


class MessageType(Enum):
    TASK_ASSIGN = "task_assign"
    TASK_RESULT = "task_result"
    TASK_REQUEST = "task_request"
    STATUS_UPDATE = "status_update"
    HEARTBEAT = "heartbeat"
    COORDINATION = "coordination"
    ERROR = "error"


# ─── Data Classes ────────────────────────────────────────────────
@dataclass
class SwarmTask:
    """A task in the swarm."""
    task_id: str
    role: AgentRole
    title: str
    description: str
    payload: Dict = field(default_factory=dict)
    priority: TaskPriority = TaskPriority.NORMAL
    status: TaskStatus = TaskStatus.PENDING
    assigned_agent: str = ""
    created_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    result: Dict = field(default_factory=dict)
    error: str = ""
    dependencies: List[str] = field(default_factory=list)  # Task IDs
    metadata: Dict = field(default_factory=dict)


@dataclass
class AgentMessage:
    """Message between agents."""
    message_id: str
    sender: str
    recipient: str  # Agent ID or "broadcast"
    message_type: MessageType
    payload: Dict
    timestamp: float = field(default_factory=time.time)
    correlation_id: str = ""  # For request-response


@dataclass
class AgentCapabilities:
    """Capabilities of a specialized agent."""
    role: AgentRole
    skills: List[str] = field(default_factory=list)
    tools: List[str] = field(default_factory=list)
    max_concurrent_tasks: int = 3
    preferred_task_types: List[str] = field(default_factory=list)


# ─── Redis Task Queue ────────────────────────────────────────────
class RedisTaskQueue:
    """Redis-backed task queue for multi-agent coordination."""
    
    def __init__(self, redis_url: str = REDIS_URL):
        self.redis_url = redis_url
        self._redis: Optional[redis.Redis] = None
        self._pubsub: Optional[redis.client.PubSub] = None
        self._connected = False
    
    async def connect(self) -> None:
        """Connect to Redis."""
        if self._connected:
            return
        self._redis = redis.from_url(self.redis_url, decode_responses=True)
        await self._redis.ping()
        self._connected = True
        print("✅ Connected to Redis task queue")
    
    async def disconnect(self) -> None:
        """Disconnect from Redis."""
        if self._pubsub:
            await self._pubsub.close()
        if self._redis:
            await self._redis.close()
        self._connected = False
    
    # ─── Task Queue Operations ─────────────────────────────────
    async def enqueue_task(self, task: SwarmTask) -> bool:
        """Add task to queue."""
        await self.connect()
        
        task_data = json.dumps({
            "task_id": task.task_id,
            "role": task.role.value,
            "title": task.title,
            "description": task.description,
            "payload": task.payload,
            "priority": task.priority.value,
            "status": task.status.value,
            "assigned_agent": task.assigned_agent,
            "created_at": task.created_at,
            "dependencies": task.dependencies,
            "metadata": task.metadata,
        })
        
        # Add to sorted set (priority queue)
        await self._redis.zadd(
            "swarm:task_queue",
            {task_data: task.priority.value}
        )
        
        # Store task details
        await self._redis.hset(
            f"swarm:task:{task.task_id}",
            mapping={
                "data": task_data,
                "status": task.status.value,
            }
        )
        
        # Notify waiting agents
        await self._redis.publish("swarm:tasks", f"new:{task.task_id}")
        
        return True
    
    async def dequeue_task(self, agent_id: str, role: AgentRole, 
                           max_tasks: int = 1) -> List[SwarmTask]:
        """Dequeue tasks for an agent."""
        await self.connect()
        
        tasks = []
        for _ in range(max_tasks):
            # Get highest priority task for this role
            result = await self._redis.zpopmax("swarm:task_queue", count=1)
            if not result:
                break
            
            task_data_str, priority = result[0]
            task_data = json.loads(task_data_str)
            
            # Check if task matches agent role
            if task_data["role"] != role.value:
                # Put back
                await self._redis.zadd("swarm:task_queue", {task_data_str: priority})
                break
            
            # Check dependencies
            deps_met = True
            for dep_id in task_data.get("dependencies", []):
                dep_status = await self._redis.hget(f"swarm:task:{dep_id}", "status")
                if dep_status != TaskStatus.COMPLETED.value:
                    deps_met = False
                    break
            
            if not deps_met:
                # Put back
                await self._redis.zadd("swarm:task_queue", {task_data_str: priority})
                break
            
            # Assign to agent
            task_data["status"] = TaskStatus.ASSIGNED.value
            task_data["assigned_agent"] = agent_id
            task_data["started_at"] = time.time()
            
            task = SwarmTask(**task_data)
            tasks.append(task)
            
            # Update stored task
            await self._redis.hset(
                f"swarm:task:{task.task_id}",
                mapping={
                    "data": json.dumps(task_data),
                    "status": TaskStatus.ASSIGNED.value,
                }
            )
        
        return tasks
    
    async def complete_task(self, task: SwarmTask, result: Dict = None, 
                            error: str = "") -> bool:
        """Mark task as completed."""
        await self.connect()
        
        task.status = TaskStatus.COMPLETED if not error else TaskStatus.FAILED
        task.completed_at = time.time()
        task.result = result or {}
        task.error = error
        
        task_data = {
            "task_id": task.task_id,
            "role": task.role.value,
            "title": task.title,
            "description": task.description,
            "payload": task.payload,
            "priority": task.priority.value,
            "status": task.status.value,
            "assigned_agent": task.assigned_agent,
            "created_at": task.created_at,
            "started_at": task.started_at,
            "completed_at": task.completed_at,
            "result": task.result,
            "error": task.error,
            "dependencies": task.dependencies,
            "metadata": task.metadata,
        }
        
        await self._redis.hset(
            f"swarm:task:{task.task_id}",
            mapping={
                "data": json.dumps(task_data),
                "status": task.status.value,
            }
        )
        
        # Notify completion
        await self._redis.publish("swarm:tasks", f"completed:{task.task_id}")
        
        return True
    
    async def get_task(self, task_id: str) -> Optional[SwarmTask]:
        """Get task by ID."""
        await self.connect()
        
        task_data = await self._redis.hget(f"swarm:task:{task_id}", "data")
        if task_data:
            data = json.loads(task_data)
            return SwarmTask(**data)
        return None
    
    async def get_queue_stats(self) -> Dict:
        """Get queue statistics."""
        await self.connect()
        
        pending = await self._redis.zcard("swarm:task_queue")
        
        # Count by status
        status_counts = {}
        for status in TaskStatus:
            count = 0
            async for key in self._redis.scan_iter("swarm:task:*"):
                task_status = await self._redis.hget(key, "status")
                if task_status == status.value:
                    count += 1
            status_counts[status.value] = count
        
        return {
            "pending": pending,
            "by_status": status_counts,
        }
    
    # ─── Pub/Sub for Real-time Communication ───────────────────
    async def subscribe(self, channel: str) -> AsyncGenerator[str, None]:
        """Subscribe to a channel."""
        await self.connect()
        self._pubsub = self._redis.pubsub()
        await self._pubsub.subscribe(channel)
        
        async for message in self._pubsub.listen():
            if message["type"] == "message":
                yield message["data"]
    
    async def publish(self, channel: str, message: str) -> int:
        """Publish to a channel."""
        await self.connect()
        return await self._redis.publish(channel, message)


# ─── Specialized Agents ──────────────────────────────────────────
class ArchitectAgent(BaseAgent):
    """System architect - designs solutions, creates plans, makes architecture decisions."""
    
    def __init__(self, agent_id: str, llm_fn: Callable, 
                 task_queue: RedisTaskQueue, sandbox: SecureSandboxManager,
                 dynamic_tools: DynamicToolManager, browser: VisionBrowserManager):
        super().__init__(
            name=f"Architect-{agent_id}",
            role="architect",
            skills=("system_design", "planning", "architecture", "api_design", 
                   "database_design", "security_architecture", "scalability"),
            permissions=("web", "developer", "file", "system"),
            system_prompt="""You are the System Architect agent. Your role is to:
1. Analyze requirements and create technical specifications
2. Design system architecture and component interactions
3. Create implementation plans with clear task breakdowns
4. Make technology choices and justify them
5. Identify risks and mitigation strategies
6. Define APIs, data models, and interfaces

Always think holistically about the system. Consider:
- Scalability and performance
- Security and compliance
- Maintainability and extensibility
- Cost and resource efficiency
- Integration with existing systems

Output structured plans that other agents can execute."""
        )
        self.llm_fn = llm_fn
        self.task_queue = task_queue
        self.sandbox = sandbox
        self.dynamic_tools = dynamic_tools
        self.browser = browser
        self.capabilities = AgentCapabilities(
            role=AgentRole.ARCHITECT,
            skills=["system_design", "api_design", "database_design", "security_review"],
            tools=["browser_browse_and_act", "run_code", "write_file", "read_file"],
            max_concurrent_tasks=2,
            preferred_task_types=["design", "plan", "architecture", "specification"],
        )
    
    async def handle_task(self, task: SwarmTask) -> Dict:
        """Handle an architecture task."""
        self._last_active = time.time()
        
        prompt = f"""As the System Architect, create a comprehensive plan for:

Task: {task.title}
Description: {task.description}
Context: {json.dumps(task.payload)}

Provide a detailed response with:
1. **Architecture Overview** - High-level design
2. **Component Breakdown** - Major components and their responsibilities
3. **API Design** - Key interfaces and data flows
4. **Data Model** - Schema design if applicable
5. **Implementation Plan** - Step-by-step tasks for Coder agents
6. **Risk Assessment** - Technical risks and mitigations
7. **Technology Choices** - Justified selections

Format as JSON with these keys: architecture, components, apis, data_model, implementation_plan, risks, technologies"""
        
        try:
            response = await self.llm_fn(prompt)
            plan = json.loads(response)
            
            # Create subtasks for implementation
            subtasks = []
            for i, step in enumerate(plan.get("implementation_plan", [])):
                subtask = SwarmTask(
                    task_id=uuid.uuid4().hex[:12],
                    role=AgentRole.CODER,
                    title=f"Implement: {step.get('title', f'Step {i+1}')}",
                    description=step.get("description", ""),
                    payload={
                        "architecture_context": plan,
                        "step": step,
                        "parent_task": task.task_id,
                    },
                    priority=TaskPriority.HIGH,
                    dependencies=[task.task_id] if i == 0 else [subtasks[-1].task_id],
                )
                subtasks.append(subtask)
                await self.task_queue.enqueue_task(subtask)
            
            return {
                "success": True,
                "plan": plan,
                "subtasks_created": len(subtasks),
                "subtask_ids": [s.task_id for s in subtasks],
            }
        except Exception as e:
            self.record_error(str(e))
            return {"success": False, "error": str(e)}


class CoderAgent(BaseAgent):
    """Coder agent - implements code, generates solutions, refactors."""
    
    def __init__(self, agent_id: str, llm_fn: Callable,
                 task_queue: RedisTaskQueue, sandbox: SecureSandboxManager,
                 dynamic_tools: DynamicToolManager, browser: VisionBrowserManager):
        super().__init__(
            name=f"Coder-{agent_id}",
            role="coder",
            skills=("python", "javascript", "typescript", "go", "rust", "sql",
                   "api_development", "database", "testing", "refactoring",
                   "debugging", "optimization"),
            permissions=("developer", "file", "system", "web"),
            system_prompt="""You are the Coder agent. Your role is to:
1. Implement code based on architectural specifications
2. Write clean, maintainable, well-documented code
3. Follow best practices and design patterns
4. Create tests for your implementations
5. Refactor and optimize existing code
6. Debug and fix issues

Guidelines:
- Write production-ready code with error handling
- Include type hints and docstrings
- Follow the project's coding standards
- Create comprehensive tests
- Consider security implications
- Optimize for readability first, performance second

Output complete, runnable code with tests."""
        )
        self.llm_fn = llm_fn
        self.task_queue = task_queue
        self.sandbox = sandbox
        self.dynamic_tools = dynamic_tools
        self.browser = browser
        self.capabilities = AgentCapabilities(
            role=AgentRole.CODER,
            skills=["python", "javascript", "api_dev", "database", "testing"],
            tools=["run_code", "write_file", "read_file", "run_shell", "git_commit"],
            max_concurrent_tasks=3,
            preferred_task_types=["implement", "code", "develop", "refactor", "fix"],
        )
    
    async def handle_task(self, task: SwarmTask) -> Dict:
        """Handle a coding task."""
        self._last_active = time.time()
        
        context = task.payload.get("architecture_context", {})
        step = task.payload.get("step", {})
        
        prompt = f"""As the Coder agent, implement this task:

Task: {task.title}
Description: {task.description}

Architecture Context:
{json.dumps(context, indent=2)}

Implementation Step:
{json.dumps(step, indent=2)}

Requirements:
1. Write complete, production-ready code
2. Include type hints and comprehensive docstrings
3. Handle errors gracefully
4. Follow security best practices
5. Create unit tests
6. Return the code as a single file or multiple files

Output format:
{{
    "files": {{"path/to/file.py": "file content"}},
    "tests": {{"path/to/test_file.py": "test content"}},
    "dependencies": ["package1", "package2"],
    "notes": "Any important notes"
}}"""
        
        try:
            response = await self.llm_fn(prompt)
            result = json.loads(response)
            
            # Write files
            for file_path, content in result.get("files", {}).items():
                full_path = Path(file_path)
                full_path.parent.mkdir(parents=True, exist_ok=True)
                full_path.write_text(content)
            
            # Write tests
            for file_path, content in result.get("tests", {}).items():
                full_path = Path(file_path)
                full_path.parent.mkdir(parents=True, exist_ok=True)
                full_path.write_text(content)
            
            # Run tests in sandbox
            if result.get("tests"):
                test_results = await self._run_tests(result["tests"])
                result["test_results"] = test_results
            
            return {
                "success": True,
                "files_created": list(result.get("files", {}).keys()),
                "tests_created": list(result.get("tests", {}).keys()),
                "test_results": result.get("test_results", {}),
                "dependencies": result.get("dependencies", []),
            }
        except Exception as e:
            self.record_error(str(e))
            return {"success": False, "error": str(e)}
    
    async def _run_tests(self, tests: Dict[str, str]) -> Dict:
        """Run tests in sandbox."""
        results = {}
        for test_file, content in tests.items():
            result = await self.sandbox.execute(
                code=content,
                language=SandboxLanguage.PYTHON,
                limits=self.sandbox.default_config.limits,
            )
            results[test_file] = {
                "success": result.status == ExecutionStatus.COMPLETED,
                "stdout": result.stdout,
                "stderr": result.stderr,
            }
        return results


class TesterAgent(BaseAgent):
    """Tester agent - creates and runs tests, validates implementations."""
    
    def __init__(self, agent_id: str, llm_fn: Callable,
                 task_queue: RedisTaskQueue, sandbox: SecureSandboxManager,
                 dynamic_tools: DynamicToolManager, browser: VisionBrowserManager):
        super().__init__(
            name=f"Tester-{agent_id}",
            role="tester",
            skills=("unit_testing", "integration_testing", "e2e_testing", 
                   "test_automation", "performance_testing", "security_testing",
                   "test_design", "qa_processes"),
            permissions=("developer", "file", "system", "web"),
            system_prompt="""You are the Tester agent. Your role is to:
1. Create comprehensive test suites for implementations
2. Design test cases covering happy paths, edge cases, and error conditions
3. Execute tests and analyze results
4. Perform integration and end-to-end testing
5. Validate requirements are met
6. Report defects with clear reproduction steps

Testing philosophy:
- Test behavior, not implementation
- Cover edge cases and failure modes
- Automate everything possible
- Make tests fast and reliable
- Document test strategy and coverage

Output test code that can be executed directly."""
        )
        self.llm_fn = llm_fn
        self.task_queue = task_queue
        self.sandbox = sandbox
        self.dynamic_tools = dynamic_tools
        self.browser = browser
        self.capabilities = AgentCapabilities(
            role=AgentRole.TESTER,
            skills=["unit_testing", "integration_testing", "e2e_testing", "test_design"],
            tools=["run_code", "write_file", "read_file", "browser_browse_and_act"],
            max_concurrent_tasks=3,
            preferred_task_types=["test", "validate", "verify", "qa"],
        )
    
    async def handle_task(self, task: SwarmTask) -> Dict:
        """Handle a testing task."""
        self._last_active = time.time()
        
        # Get implementation to test
        implementation_files = task.payload.get("implementation_files", {})
        requirements = task.payload.get("requirements", "")
        
        prompt = f"""As the Tester agent, create comprehensive tests for:

Task: {task.title}
Description: {task.description}

Requirements to validate:
{requirements}

Implementation files:
{json.dumps(implementation_files, indent=2)}

Create tests that cover:
1. Happy path scenarios
2. Edge cases and boundary conditions
3. Error handling and invalid inputs
4. Performance benchmarks (if applicable)
5. Security test cases (if applicable)

Output format:
{{
    "test_files": {{"path/to/test_file.py": "test content"}},
    "test_strategy": "Description of testing approach",
    "coverage_targets": ["feature1", "feature2"],
    "special_cases": ["case1", "case2"]
}}"""
        
        try:
            response = await self.llm_fn(prompt)
            result = json.loads(response)
            
            # Write test files
            for file_path, content in result.get("test_files", {}).items():
                full_path = Path(file_path)
                full_path.parent.mkdir(parents=True, exist_ok=True)
                full_path.write_text(content)
            
            # Run tests in sandbox
            test_results = await self._run_tests(result["test_files"])
            
            # Analyze results
            passed = sum(1 for r in test_results.values() if r.get("success"))
            total = len(test_results)
            
            return {
                "success": passed == total,
                "tests_created": list(result.get("test_files", {}).keys()),
                "test_results": test_results,
                "passed": passed,
                "total": total,
                "coverage": result.get("coverage_targets", []),
            }
        except Exception as e:
            self.record_error(str(e))
            return {"success": False, "error": str(e)}
    
    async def _run_tests(self, tests: Dict[str, str]) -> Dict:
        """Run tests in sandbox."""
        results = {}
        for test_file, content in tests.items():
            result = await self.sandbox.execute(
                code=content,
                language=SandboxLanguage.PYTHON,
            )
            results[test_file] = {
                "success": result.status == ExecutionStatus.COMPLETED,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "exit_code": result.exit_code,
            }
        return results


class ReviewerAgent(BaseAgent):
    """Reviewer agent - code review, quality assurance, security audit."""
    
    def __init__(self, agent_id: str, llm_fn: Callable,
                 task_queue: RedisTaskQueue, sandbox: SecureSandboxManager,
                 dynamic_tools: DynamicToolManager, browser: VisionBrowserManager):
        super().__init__(
            name=f"Reviewer-{agent_id}",
            role="reviewer",
            skills=("code_review", "security_audit", "performance_review",
                   "architecture_review", "best_practices", "compliance",
                   "documentation_review", "technical_debt"),
            permissions=("developer", "file", "system"),
            system_prompt="""You are the Reviewer agent. Your role is to:
1. Perform thorough code reviews
2. Identify security vulnerabilities
3. Check for performance issues
4. Validate adherence to architecture
4. Ensure code quality and maintainability
5. Verify documentation completeness
6. Identify technical debt

Review criteria:
- **Security**: Input validation, authentication, authorization, data protection
- **Performance**: Algorithmic complexity, resource usage, scalability
- **Correctness**: Logic errors, edge cases, error handling
- **Maintainability**: Code organization, naming, documentation, testability
- **Architecture**: Consistency with design, separation of concerns
- **Standards**: Coding standards, best practices, patterns

Output structured review with severity levels: CRITICAL, HIGH, MEDIUM, LOW, INFO"""
        )
        self.llm_fn = llm_fn
        self.task_queue = task_queue
        self.sandbox = sandbox
        self.dynamic_tools = dynamic_tools
        self.browser = browser
        self.capabilities = AgentCapabilities(
            role=AgentRole.REVIEWER,
            skills=["code_review", "security_audit", "performance_review"],
            tools=["read_file", "run_code", "run_shell"],
            max_concurrent_tasks=2,
            preferred_task_types=["review", "audit", "analyze", "inspect"],
        )
    
    async def handle_task(self, task: SwarmTask) -> Dict:
        """Handle a code review task."""
        self._last_active = time.time()
        
        files_to_review = task.payload.get("files", {})
        context = task.payload.get("context", {})
        
        prompt = f"""As the Reviewer agent, perform a comprehensive code review:

Task: {task.title}
Description: {task.description}

Context: {json.dumps(context, indent=2)}

Files to review:
{json.dumps(files_to_review, indent=2)}

Provide a detailed review with:
1. **Summary** - Overall assessment
2. **Issues** - List of issues with severity (CRITICAL/HIGH/MEDIUM/LOW/INFO)
3. **Security Findings** - Specific security concerns
4. **Performance Concerns** - Bottlenecks or inefficiencies
5. **Code Quality** - Style, patterns, maintainability
6. **Architecture Alignment** - Consistency with design
7. **Recommendations** - Specific improvements
8. **Approval** - APPROVED / CHANGES_REQUESTED / REJECTED

Output format:
{{
    "summary": "...",
    "issues": [
        {{"severity": "HIGH", "file": "path", "line": 10, "issue": "...", "suggestion": "..."}}
    ],
    "security_findings": [...],
    "performance_concerns": [...],
    "code_quality": [...],
    "architecture_alignment": "...",
    "recommendations": [...],
    "approval": "APPROVED|CHANGES_REQUESTED|REJECTED"
}}"""
        
        try:
            response = await self.llm_fn(prompt)
            review = json.loads(response)
            
            return {
                "success": True,
                "review": review,
                "approval": review.get("approval", "CHANGES_REQUESTED"),
                "issue_count": len(review.get("issues", [])),
            }
        except Exception as e:
            self.record_error(str(e))
            return {"success": False, "error": str(e)}


# ─── Coordinator Agent ───────────────────────────────────────────
class CoordinatorAgent(BaseAgent):
    """Coordinator agent - orchestrates the swarm, manages workflow."""
    
    def __init__(self, agent_id: str, llm_fn: Callable,
                 task_queue: RedisTaskQueue, sandbox: SecureSandboxManager,
                 dynamic_tools: DynamicToolManager, browser: VisionBrowserManager,
                 swarm_manager: "SwarmManager"):
        super().__init__(
            name=f"Coordinator-{agent_id}",
            role="coordinator",
            skills=("orchestration", "workflow_management", "task_decomposition",
                   "progress_tracking", "conflict_resolution", "resource_allocation"),
            permissions=("developer", "file", "system", "web"),
            system_prompt="""You are the Coordinator agent. Your role is to:
1. Decompose high-level goals into executable tasks
2. Assign tasks to appropriate specialized agents
3. Monitor progress and handle failures
4. Coordinate between agents
5. Aggregate results and deliver final output
6. Manage task dependencies and scheduling

Always ensure:
- Clear task definitions with success criteria
- Proper dependency management
- Balanced workload distribution
- Timely intervention when issues arise
- Comprehensive final reporting"""
        )
        self.llm_fn = llm_fn
        self.task_queue = task_queue
        self.sandbox = sandbox
        self.dynamic_tools = dynamic_tools
        self.browser = browser
        self.swarm_manager = swarm_manager
        self.capabilities = AgentCapabilities(
            role=AgentRole.COORDINATOR,
            skills=["orchestration", "planning", "coordination"],
            tools=["run_code", "write_file", "read_file"],
            max_concurrent_tasks=1,
            preferred_task_types=["coordinate", "orchestrate", "manage"],
        )
    
    async def decompose_goal(self, goal: str, context: Dict = None) -> List[SwarmTask]:
        """Decompose a high-level goal into tasks for the swarm."""
        prompt = f"""Decompose this goal into tasks for a multi-agent swarm:

Goal: {goal}
Context: {json.dumps(context or {})}

Available agent roles:
- ARCHITECT: System design, planning, architecture
- CODER: Implementation, coding, refactoring
- TESTER: Test creation, execution, validation
- REVIEWER: Code review, security audit, quality assurance

Create a task breakdown with dependencies. Each task should specify:
- role: which agent type should handle it
- title: brief task name
- description: detailed description
- payload: any data needed
- priority: LOW/NORMAL/HIGH/CRITICAL
- dependencies: list of task IDs this depends on

Output as JSON array of tasks."""
        
        response = await self.llm_fn(prompt)
        tasks_data = json.loads(response)
        
        tasks = []
        for i, task_data in enumerate(tasks_data):
            task = SwarmTask(
                task_id=task_data.get("task_id", uuid.uuid4().hex[:12]),
                role=AgentRole(task_data["role"]),
                title=task_data["title"],
                description=task_data["description"],
                payload=task_data.get("payload", {}),
                priority=TaskPriority[task_data.get("priority", "NORMAL")],
                dependencies=task_data.get("dependencies", []),
            )
            tasks.append(task)
        
        return tasks
    
    async def run_swarm(self, goal: str, context: Dict = None) -> Dict:
        """Run the full swarm to achieve a goal."""
        # Decompose goal
        tasks = await self.decompose_goal(goal, context)
        
        # Enqueue all tasks
        for task in tasks:
            await self.task_queue.enqueue_task(task)
        
        # Wait for completion
        results = await self._wait_for_completion(tasks)
        
        # Aggregate results
        return await self._aggregate_results(goal, tasks, results)
    
    async def _wait_for_completion(self, tasks: List[SwarmTask], 
                                   timeout: float = 300) -> Dict[str, Dict]:
        """Wait for all tasks to complete."""
        start_time = time.time()
        results = {}
        pending = {t.task_id for t in tasks}
        
        while pending and (time.time() - start_time) < timeout:
            for task_id in list(pending):
                task = await self.task_queue.get_task(task_id)
                if task and task.status in [TaskStatus.COMPLETED, TaskStatus.FAILED]:
                    results[task_id] = {
                        "status": task.status.value,
                        "result": task.result,
                        "error": task.error,
                    }
                    pending.remove(task_id)
            
            if pending:
                await asyncio.sleep(2)
        
        # Handle timeouts
        for task_id in pending:
            results[task_id] = {"status": "timeout", "error": "Task timed out"}
        
        return results
    
    async def _aggregate_results(self, goal: str, tasks: List[SwarmTask], 
                                 results: Dict) -> Dict:
        """Aggregate results from all agents."""
        prompt = f"""Aggregate results from swarm execution:

Original Goal: {goal}

Tasks and Results:
{json.dumps({t.task_id: {"title": t.title, "role": t.role.value, "result": results.get(t.task_id, {})} for t in tasks}, indent=2)}

Provide a final summary with:
1. Goal achievement status
2. Key deliverables
3. Any issues or failures
4. Recommendations for next steps"""
        
        response = await self.llm_fn(prompt)
        
        return {
            "goal": goal,
            "completed": all(r.get("status") == "completed" for r in results.values()),
            "task_results": results,
            "summary": response,
        }


# ─── Swarm Manager ───────────────────────────────────────────────
class SwarmManager:
    """Main manager for the multi-agent swarm."""
    
    def __init__(
        self,
        llm_fn: Callable,
        redis_url: str = REDIS_URL,
        num_architects: int = 1,
        num_coders: int = 2,
        num_testers: int = 1,
        num_reviewers: int = 1,
    ):
        self.llm_fn = llm_fn
        self.task_queue = RedisTaskQueue(redis_url)
        self.sandbox = get_secure_sandbox_manager()
        self.dynamic_tools = DynamicToolManager(llm_fn=llm_fn)
        self.browser = get_vision_browser_manager()
        
        # Agent pools
        self.architects: List[ArchitectAgent] = []
        self.coders: List[CoderAgent] = []
        self.testers: List[TesterAgent] = []
        self.reviewers: List[ReviewerAgent] = []
        self.coordinator: Optional[CoordinatorAgent] = None
        
        self._agent_counts = {
            AgentRole.ARCHITECT: num_architects,
            AgentRole.CODER: num_coders,
            AgentRole.TESTER: num_testers,
            AgentRole.REVIEWER: num_reviewers,
        }
        
        self._running = False
        self._worker_tasks: List[asyncio.Task] = []
    
    async def initialize(self) -> None:
        """Initialize the swarm."""
        await self.task_queue.connect()
        
        # Create agents
        for i in range(self._agent_counts[AgentRole.ARCHITECT]):
            self.architects.append(ArchitectAgent(
                f"arch-{i}", self.llm_fn, self.task_queue, self.sandbox,
                self.dynamic_tools, self.browser
            ))
        
        for i in range(self._agent_counts[AgentRole.CODER]):
            self.coders.append(CoderAgent(
                f"cod-{i}", self.llm_fn, self.task_queue, self.sandbox,
                self.dynamic_tools, self.browser
            ))
        
        for i in range(self._agent_counts[AgentRole.TESTER]):
            self.testers.append(TesterAgent(
                f"test-{i}", self.llm_fn, self.task_queue, self.sandbox,
                self.dynamic_tools, self.browser
            ))
        
        for i in range(self._agent_counts[AgentRole.REVIEWER]):
            self.reviewers.append(ReviewerAgent(
                f"rev-{i}", self.llm_fn, self.task_queue, self.sandbox,
                self.dynamic_tools, self.browser
            ))
        
        self.coordinator = CoordinatorAgent(
            "coord-0", self.llm_fn, self.task_queue, self.sandbox,
            self.dynamic_tools, self.browser, self
        )
        
        print(f"✅ Swarm initialized with {len(self.architects)} architects, "
              f"{len(self.coders)} coders, {len(self.testers)} testers, "
              f"{len(self.reviewers)} reviewers")
    
    async def start(self) -> None:
        """Start the swarm workers."""
        if self._running:
            return
        
        self._running = True
        
        # Start worker loops for each agent
        for agent in self.architects:
            self._worker_tasks.append(asyncio.create_task(self._agent_worker(agent)))
        
        for agent in self.coders:
            self._worker_tasks.append(asyncio.create_task(self._agent_worker(agent)))
        
        for agent in self.testers:
            self._worker_tasks.append(asyncio.create_task(self._agent_worker(agent)))
        
        for agent in self.reviewers:
            self._worker_tasks.append(asyncio.create_task(self._agent_worker(agent)))
        
        print("✅ Swarm workers started")
    
    async def stop(self) -> None:
        """Stop the swarm workers."""
        self._running = False
        
        for task in self._worker_tasks:
            task.cancel()
        
        await asyncio.gather(*self._worker_tasks, return_exceptions=True)
        self._worker_tasks.clear()
        
        await self.task_queue.disconnect()
        print("✅ Swarm stopped")
    
    async def _agent_worker(self, agent: BaseAgent) -> None:
        """Worker loop for an agent."""
        role = AgentRole(agent.role)
        
        while self._running:
            try:
                # Dequeue tasks
                tasks = await self.task_queue.dequeue_task(
                    agent.name, role, agent.capabilities.max_concurrent_tasks
                )
                
                for task in tasks:
                    # Execute task
                    result = await agent.handle_task(task)
                    
                    # Complete task
                    await self.task_queue.complete_task(
                        task, result.get("result"), result.get("error", "")
                    )
                    
                    # Handle follow-up based on role
                    await self._handle_task_completion(agent, task, result)
                
                if not tasks:
                    await asyncio.sleep(1)  # No tasks, wait a bit
                    
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"Agent {agent.name} error: {e}")
                await asyncio.sleep(5)
    
    async def _handle_task_completion(self, agent: BaseAgent, task: SwarmTask, result: Dict):
        """Handle task completion - create follow-up tasks."""
        if task.role == AgentRole.ARCHITECT and result.get("success"):
            # Architecture done, create review task
            review_task = SwarmTask(
                task_id=uuid.uuid4().hex[:12],
                role=AgentRole.REVIEWER,
                title=f"Review architecture: {task.title}",
                description=f"Review the architecture plan for {task.title}",
                payload={
                    "files": {"architecture_plan.json": json.dumps(result.get("plan", {}))},
                    "context": {"type": "architecture_review"},
                },
                priority=TaskPriority.HIGH,
                dependencies=[task.task_id],
            )
            await self.task_queue.enqueue_task(review_task)
        
        elif task.role == AgentRole.CODER and result.get("success"):
            # Code implemented, create test task
            test_task = SwarmTask(
                task_id=uuid.uuid4().hex[:12],
                role=AgentRole.TESTER,
                title=f"Test implementation: {task.title}",
                description=f"Create and run tests for {task.title}",
                payload={
                    "implementation_files": result.get("files_created", {}),
                    "requirements": task.payload.get("step", {}).get("requirements", ""),
                },
                priority=TaskPriority.HIGH,
                dependencies=[task.task_id],
            )
            await self.task_queue.enqueue_task(test_task)
        
        elif task.role == AgentRole.TESTER and result.get("success"):
            # Tests passed, create review task
            review_task = SwarmTask(
                task_id=uuid.uuid4().hex[:12],
                role=AgentRole.REVIEWER,
                title=f"Review code: {task.title}",
                description=f"Review the implementation and tests for {task.title}",
                payload={
                    "files": task.payload.get("implementation_files", {}),
                    "context": {"type": "code_review", "test_results": result.get("test_results")},
                },
                priority=TaskPriority.NORMAL,
                dependencies=[task.task_id],
            )
            await self.task_queue.enqueue_task(review_task)
    
    async def execute_goal(self, goal: str, context: Dict = None) -> Dict:
        """Execute a high-level goal using the swarm."""
        if not self._running:
            await self.start()
        
        return await self.coordinator.run_swarm(goal, context)
    
    def get_status(self) -> Dict:
        """Get swarm status."""
        return {
            "running": self._running,
            "agents": {
                "architects": len(self.architects),
                "coders": len(self.coders),
                "testers": len(self.testers),
                "reviewers": len(self.reviewers),
            },
            "queue_stats": asyncio.create_task(self.task_queue.get_queue_stats()) if self._running else {},
        }


# ─── Module Singleton ────────────────────────────────────────────
_swarm_manager: Optional[SwarmManager] = None


def get_swarm_manager(**kwargs) -> SwarmManager:
    global _swarm_manager
    if _swarm_manager is None:
        _swarm_manager = SwarmManager(**kwargs)
    return _swarm_manager


async def init_swarm(**kwargs) -> SwarmManager:
    manager = get_swarm_manager(**kwargs)
    await manager.initialize()
    await manager.start()
    return manager


# ─── Export ──────────────────────────────────────────────────────
__all__ = [
    "SwarmManager",
    "CoordinatorAgent",
    "ArchitectAgent",
    "CoderAgent",
    "TesterAgent",
    "ReviewerAgent",
    "RedisTaskQueue",
    "SwarmTask",
    "AgentMessage",
    "AgentCapabilities",
    "AgentRole",
    "TaskPriority",
    "TaskStatus",
    "MessageType",
    "get_swarm_manager",
    "init_swarm",
]