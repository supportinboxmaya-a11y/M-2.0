"""
Maya 2.0 ULTRA - Extended Agent Capabilities (Phase 5)
=======================================================
Adds capabilities beyond standard "Jarvis" voice assistant:

1. Persistent Long-Term Memory (cross-session)
2. Proactive Task Execution (scheduled/background jobs)
3. Multi-Step Autonomous Planning with Self-Verification
4. Tool/Plugin Expansion (calendar, search, file management, etc.)
5. Interruption Handling (voice command interrupt mid-task)

All built on existing Maya infrastructure without breaking the agentic pipeline.
Uses PermissionEngine for safety.
"""
import asyncio
import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from datetime import datetime, timedelta
from typing import Any, Callable, Dict, List, Optional, Set
from dataclasses import dataclass, field
from enum import Enum

# Import existing Maya infrastructure
from memory.memory_manager import MemoryManager
from infrastructure.cognition import CognitionEngine, cognition_engine
from tools.registry import ToolRegistry
from maya_logging.logger import get_logger

# Import Permission System
from infrastructure.permissions import get_permission_engine, PermissionEngine, ActionCategory, RiskLevel

log = get_logger("extended_agent")

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

EXTENDED_AGENT_ENABLED = os.environ.get("EXTENDED_AGENT_ENABLED", "true").lower() == "true"
PROACTIVE_TASKS_ENABLED = os.environ.get("PROACTIVE_TASKS_ENABLED", "true").lower() == "true"
INTERRUPTION_ENABLED = os.environ.get("INTERRUPTION_ENABLED", "true").lower() == "true"

# ════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ════════════════════════════════════════════════════════════════════════════

class TaskStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    INTERRUPTED = "interrupted"
    CANCELLED = "cancelled"

class TaskType(Enum):
    USER_REQUEST = "user_request"
    PROACTIVE = "proactive"
    SCHEDULED = "scheduled"
    BACKGROUND = "background"

@dataclass
class ExtendedTask:
    """Extended task with full planning and verification metadata."""
    id: str
    goal: str
    task_type: TaskType = TaskType.USER_REQUEST
    status: TaskStatus = TaskStatus.PENDING
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    
    # Planning
    plan: List[Dict] = field(default_factory=list)  # Step-by-step plan
    current_step: int = 0
    total_steps: int = 0
    
    # Verification
    verification_results: List[Dict] = field(default_factory=list)
    retry_count: int = 0
    max_retries: int = 3
    
    # Interruption
    interrupted: bool = False
    interruption_reason: str = ""
    
    # Context
    session_id: str = ""
    user_id: str = ""
    metadata: Dict = field(default_factory=dict)
    
    # Results
    final_result: str = ""
    error: str = ""

@dataclass
class ProactiveJob:
    """Scheduled proactive background job."""
    id: str
    name: str
    description: str
    cron: str  # Cron expression
    enabled: bool = True
    last_run: Optional[float] = None
    next_run: Optional[float] = None
    run_count: int = 0
    last_result: str = ""
    last_success: bool = True
    notify_on_failure: bool = True
    notify_on_success: bool = False

@dataclass
class InterruptionEvent:
    """Voice interruption event."""
    id: str
    session_id: str
    timestamp: float
    transcript: str
    handled: bool = False
    action_taken: str = ""

# ════════════════════════════════════════════════════════════════════════════
# PERSISTENT LONG-TERM MEMORY (Cross-Session)
# ════════════════════════════════════════════════════════════════════════════

class PersistentMemory:
    """
    Cross-session persistent memory that survives restarts.
    Builds on existing MemoryManager but adds:
    - User preferences and facts
    - Project state tracking
    - Conversation summaries
    - Learned patterns
    """
    
    def __init__(self, memory_manager: MemoryManager):
        self.mm = memory_manager
        self._init_tables()
    
    def _init_tables(self):
        """Add extended memory tables to the long-term DB."""
        # The long_term DB already exists; we just ensure our memory types work
        pass
    
    def remember_preference(self, user_id: str, key: str, value: str, confidence: float = 1.0):
        """Store a user preference (e.g., 'prefers_dark_mode', 'timezone')."""
        content = f"User preference: {key} = {value}"
        self.mm.add(content, memory_type="preference", metadata={
            "user_id": user_id, "key": key, "value": value, "confidence": confidence
        })
    
    def get_preference(self, user_id: str, key: str) -> Optional[str]:
        """Retrieve a user preference."""
        results = self.mm.search(f"User preference: {key} =", memory_type="preference")
        for r in results:
            meta = r.get("metadata", {})
            if meta.get("user_id") == user_id and meta.get("key") == key:
                return meta.get("value")
        return None
    
    def remember_fact(self, user_id: str, fact: str, topic: str = "general"):
        """Store a learned fact about the user or project."""
        content = f"Fact [{topic}]: {fact}"
        self.mm.add(content, memory_type="learned_fact", metadata={
            "user_id": user_id, "topic": topic
        })
    
    def get_facts(self, user_id: str, topic: str = None) -> List[Dict]:
        """Retrieve learned facts."""
        results = self.mm.search("Fact [", memory_type="learned_fact")
        filtered = [r for r in results if r.get("metadata", {}).get("user_id") == user_id]
        if topic:
            filtered = [r for r in filtered if r.get("metadata", {}).get("topic") == topic]
        return filtered
    
    def save_project_state(self, project_id: str, state: Dict):
        """Save project state (files, progress, next steps)."""
        content = f"Project state [{project_id}]: {json.dumps(state)}"
        self.mm.add(content, memory_type="project_state", metadata={
            "project_id": project_id, **state
        })
    
    def load_project_state(self, project_id: str) -> Optional[Dict]:
        """Load project state."""
        results = self.mm.search(f"Project state [{project_id}]", memory_type="project_state")
        for r in results:
            meta = r.get("metadata", {})
            if meta.get("project_id") == project_id:
                return meta
        return None
    
    def save_conversation_summary(self, session_id: str, summary: str, key_topics: List[str]):
        """Save a conversation summary for future reference."""
        content = f"Conversation summary [{session_id}]: {summary}"
        self.mm.add(content, memory_type="conversation_summary", metadata={
            "session_id": session_id, "key_topics": key_topics
        })
    
    def get_relevant_context(self, query: str, user_id: str = None, limit: int = 10) -> str:
        """Get relevant cross-session context for a query."""
        results = self.mm.search(query, limit=limit)
        if user_id:
            results = [r for r in results if r.get("metadata", {}).get("user_id") in (None, user_id)]
        
        if not results:
            return ""
        
        lines = ["Relevant cross-session context:"]
        for r in results:
            content = r.get("content", "")[:300]
            mtype = r.get("type", "")
            lines.append(f"- [{mtype}] {content}")
        return "\n".join(lines)


# ════════════════════════════════════════════════════════════════════════════
# PROACTIVE TASK EXECUTION
# ════════════════════════════════════════════════════════════════════════════

class ProactiveTaskScheduler:
    """
    Schedules and runs proactive background jobs.
    Integrates with existing scheduler and cognition engine.
    """
    
    def __init__(self, memory_manager: MemoryManager, cognition: CognitionEngine = None):
        self.mm = memory_manager
        self.cognition = cognition
        self.jobs: Dict[str, ProactiveJob] = {}
        self._running = False
        self._task = None
        self._db_path = "/home/ubuntu/M-2.0/storage/proactive_jobs.db"
        self._init_db()
        self._load_jobs()
    
    def _init_db(self):
        import pathlib
        pathlib.Path(self._db_path).parent.mkdir(parents=True, exist_ok=True)
        with sqlite3.connect(self._db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS proactive_jobs (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    cron TEXT NOT NULL,
                    enabled INTEGER DEFAULT 1,
                    last_run REAL,
                    next_run REAL,
                    run_count INTEGER DEFAULT 0,
                    last_result TEXT,
                    last_success INTEGER DEFAULT 1,
                    notify_on_failure INTEGER DEFAULT 1,
                    notify_on_success INTEGER DEFAULT 0,
                    created_at REAL DEFAULT (strftime('%s','now'))
                )
            """)
    
    def _load_jobs(self):
        with sqlite3.connect(self._db_path) as conn:
            conn.row_factory = sqlite3.Row
            rows = conn.execute("SELECT * FROM proactive_jobs WHERE enabled = 1").fetchall()
            for row in rows:
                job = ProactiveJob(
                    id=row["id"], name=row["name"], description=row["description"],
                    cron=row["cron"], enabled=bool(row["enabled"]),
                    last_run=row["last_run"], next_run=row["next_run"],
                    run_count=row["run_count"], last_result=row["last_result"],
                    last_success=bool(row["last_success"]),
                    notify_on_failure=bool(row["notify_on_failure"]),
                    notify_on_success=bool(row["notify_on_success"]),
                )
                self.jobs[job.id] = job
    
    def add_job(self, name: str, description: str, cron: str,
                notify_on_failure: bool = True, notify_on_success: bool = False) -> str:
        """Add a new proactive job."""
        job_id = uuid.uuid4().hex[:12]
        job = ProactiveJob(
            id=job_id, name=name, description=description, cron=cron,
            notify_on_failure=notify_on_failure, notify_on_success=notify_on_success,
        )
        self.jobs[job_id] = job
        
        with sqlite3.connect(self._db_path) as conn:
            conn.execute("""
                INSERT INTO proactive_jobs (id, name, description, cron, enabled,
                    notify_on_failure, notify_on_success)
                VALUES (?, ?, ?, ?, 1, ?, ?)
            """, (job_id, name, description, cron, int(notify_on_failure), int(notify_on_success)))
        
        log.info(f"Added proactive job: {name} ({cron})")
        return job_id
    
    def remove_job(self, job_id: str) -> bool:
        """Remove a proactive job."""
        if job_id not in self.jobs:
            return False
        del self.jobs[job_id]
        with sqlite3.connect(self._db_path) as conn:
            conn.execute("DELETE FROM proactive_jobs WHERE id = ?", (job_id,))
        return True
    
    def _cron_to_next(self, cron: str, from_time: float = None) -> float:
        """Simple cron parser for common patterns (minute, hour, day)."""
        # This is a simplified version - in production use croniter
        from_time = from_time or time.time()
        dt = datetime.fromtimestamp(from_time)
        
        parts = cron.split()
        if len(parts) != 5:
            return from_time + 3600  # Default 1 hour
        
        minute, hour, day, month, dow = parts
        
        # Simple: if minute is */N, run every N minutes
        if minute.startswith("*/"):
            interval = int(minute[2:])
            return from_time + interval * 60
        
        # Default: next hour
        next_dt = dt.replace(minute=0, second=0, microsecond=0) + timedelta(hours=1)
        if hour != "*":
            next_dt = next_dt.replace(hour=int(hour))
        return next_dt.timestamp()
    
    async def run_job(self, job: ProactiveJob) -> Dict:
        """Execute a proactive job through the cognition engine."""
        job.last_run = time.time()
        job.run_count += 1
        job.next_run = self._cron_to_next(job.cron, job.last_run)
        
        log.info(f"Running proactive job: {job.name}")
        
        try:
            if self.cognition and self.cognition.llm_fn:
                # Create a mission/objective for this proactive job
                mission = self.cognition.create_mission(
                    name=f"Proactive: {job.name}",
                    description=job.description,
                    self_gen=False,
                    mission_type="maintenance"
                )
                obj = self.cognition.add_objective(
                    mission_id=mission["id"],
                    description=job.description,
                    priority=30.0,  # Lower priority than user tasks
                    requires_approval=False
                )
                
                # Execute via cognition (propose-only mode by default)
                result = await self.cognition.cycle()
                
                job.last_result = result.get("detail", "Completed")
                job.last_success = result.get("action") == "done"
            else:
                # Fallback: just log
                job.last_result = "Executed (no cognition engine)"
                job.last_success = True
            
            self._save_job(job)
            return {"success": job.last_success, "result": job.last_result}
            
        except Exception as e:
            job.last_result = f"Error: {e}"
            job.last_success = False
            self._save_job(job)
            log.error(f"Proactive job {job.name} failed: {e}")
            return {"success": False, "error": str(e)}
    
    def _save_job(self, job: ProactiveJob):
        with sqlite3.connect(self._db_path) as conn:
            conn.execute("""
                UPDATE proactive_jobs SET last_run = ?, next_run = ?, run_count = ?,
                    last_result = ?, last_success = ?
                WHERE id = ?
            """, (job.last_run, job.next_run, job.run_count,
                  job.last_result, int(job.last_success), job.id))
    
    async def scheduler_loop(self):
        """Main scheduler loop - checks for due jobs every minute."""
        self._running = True
        while self._running:
            try:
                now = time.time()
                due_jobs = [j for j in self.jobs.values() 
                           if j.enabled and j.next_run and j.next_run <= now]
                
                for job in due_jobs:
                    await self.run_job(job)
                
                await asyncio.sleep(60)  # Check every minute
            except Exception as e:
                log.error(f"Scheduler loop error: {e}")
                await asyncio.sleep(60)
    
    def start(self):
        """Start the proactive scheduler."""
        if self._task is None or self._task.done():
            self._task = asyncio.create_task(self.scheduler_loop())
    
    def stop(self):
        """Stop the proactive scheduler."""
        self._running = False
        if self._task and not self._task.done():
            self._task.cancel()
    
    def get_jobs(self) -> List[Dict]:
        """Get all jobs status."""
        return [{
            "id": j.id, "name": j.name, "description": j.description,
            "cron": j.cron, "enabled": j.enabled,
            "last_run": j.last_run, "next_run": j.next_run,
            "run_count": j.run_count, "last_result": j.last_result,
            "last_success": j.last_success,
        } for j in self.jobs.values()]


# ════════════════════════════════════════════════════════════════════════════
# MULTI-STEP AUTONOMOUS PLANNING WITH SELF-VERIFICATION
# ════════════════════════════════════════════════════════════════════════════

class AutonomousPlanner:
    """
    Extends Maya's planning to general tasks with self-verification.
    Uses the existing hierarchical planner but adds:
    - Plan decomposition for general tasks
    - Step-by-step execution with verification
    - Automatic retry on failure
    - Progress tracking
    """
    
    def __init__(self, memory_manager: MemoryManager, llm_fn: Callable = None):
        self.mm = memory_manager
        self.llm_fn = llm_fn
        self.active_tasks: Dict[str, ExtendedTask] = {}
        self._lock = threading.Lock()
        
        # Permission engine
        self.permission_engine = get_permission_engine()
    
    def create_task(self, goal: str, task_type: TaskType = TaskType.USER_REQUEST,
                    session_id: str = "", user_id: str = "") -> ExtendedTask:
        """Create a new extended task with auto-generated plan."""
        task_id = uuid.uuid4().hex[:12]
        task = ExtendedTask(
            id=task_id,
            goal=goal,
            task_type=task_type,
            session_id=session_id,
            user_id=user_id,
        )
        
        # Generate plan using LLM
        if self.llm_fn:
            task.plan = self._generate_plan(goal)
            task.total_steps = len(task.plan)
        
        with self._lock:
            self.active_tasks[task_id] = task
        
        log.info(f"Created task {task_id}: {goal} ({task.total_steps} steps)")
        return task
    
    def _generate_plan(self, goal: str) -> List[Dict]:
        """Generate a step-by-step plan using LLM."""
        prompt = f"""Goal: {goal}

Create a detailed step-by-step plan to achieve this goal. Each step should be specific and actionable.
Return ONLY a JSON array of step objects:
[
  {{"step": 1, "action": "description of action", "tool": "tool_name_or_none", "expected_result": "what should happen"}},
  {{"step": 2, "action": "...", "tool": "...", "expected_result": "..."}}
]

Available tools: web_search, web_scrape, file operations, code execution, shell commands, etc.
Only use tools that are actually needed."""
        
        try:
            response = self.llm_fn(prompt)
            # Extract JSON array
            if "[" in response and "]" in response:
                response = response[response.index("["):response.rindex("]") + 1]
            plan = json.loads(response)
            return plan if isinstance(plan, list) else []
        except Exception as e:
            log.warning(f"Plan generation failed: {e}")
            return [{"step": 1, "action": goal, "tool": "auto", "expected_result": "Goal completed"}]
    
    async def execute_task(self, task_id: str, 
                          interruption_check: Callable[[], bool] = None) -> Dict:
        """Execute a task step by step with verification and interruption handling."""
        with self._lock:
            task = self.active_tasks.get(task_id)
        if not task:
            return {"success": False, "error": "Task not found"}
        
        task.status = TaskStatus.RUNNING
        task.started_at = time.time()
        
        try:
            for i, step in enumerate(task.plan):
                task.current_step = i + 1
                
                # Check for interruption
                if interruption_check and interruption_check():
                    task.interrupted = True
                    task.interruption_reason = "New voice command received"
                    task.status = TaskStatus.INTERRUPTED
                    log.info(f"Task {task_id} interrupted at step {task.current_step}")
                    return {"success": False, "interrupted": True, "reason": task.interruption_reason}
                
                # Execute step
                step_result = await self._execute_step(task, step)
                task.verification_results.append(step_result)
                
                # Verify step success
                if not step_result.get("success", False):
                    if task.retry_count < task.max_retries:
                        task.retry_count += 1
                        log.warning(f"Step {i+1} failed, retry {task.retry_count}/{task.max_retries}")
                        continue
                    else:
                        task.status = TaskStatus.FAILED
                        task.error = step_result.get("error", "Step verification failed")
                        return {"success": False, "error": task.error}
                
                task.updated_at = time.time()
            
            # All steps completed
            task.status = TaskStatus.COMPLETED
            task.completed_at = time.time()
            task.final_result = "Task completed successfully"
            
            # Save to memory
            self.mm.remember_task(
                goal=task.goal,
                steps=task.plan,
                result=task.final_result,
                success=True,
                tools_used=[s.get("tool") for s in task.plan if s.get("tool")]
            )
            
            return {"success": True, "result": task.final_result, "steps": task.verification_results}
            
        except Exception as e:
            task.status = TaskStatus.FAILED
            task.error = str(e)
            log.error(f"Task {task_id} failed: {e}")
            return {"success": False, "error": str(e)}
    
    async def _execute_step(self, task: ExtendedTask, step: Dict) -> Dict:
        """Execute a single plan step using available tools with permission checks."""
        action = step.get("action", "")
        tool_name = step.get("tool", "auto")
        expected = step.get("expected_result", "")
        
        log.info(f"Executing step {task.current_step}/{task.total_steps}: {action}")
        
        # Check permissions for tool execution
        if tool_name and tool_name != "auto":
            perm_decision = self.permission_engine.check_tool_permission(
                tool_name=tool_name,
                parameters={"goal": action},
                session_id=task.session_id,
                user_id=task.user_id,
            )
            if not perm_decision.approved:
                return {"success": False, "error": f"Permission denied: {perm_decision.reason}", "action": action}
        
        try:
            if tool_name and tool_name != "auto":
                # Use specific tool
                result = await tool_manager.execute_tool(tool_name, {"goal": action})
            else:
                # Use Maya's autonomous execution
                from core.maya import Maya
                maya = Maya()
                result = await maya.run(action)
            
            # Verify result matches expectation
            verification = await self._verify_step(action, expected, result)
            return verification
            
        except Exception as e:
            return {"success": False, "error": str(e), "action": action}
    
    async def _verify_step(self, action: str, expected: str, actual_result: Any) -> Dict:
        """Verify step output matches expectation using LLM."""
        if not self.llm_fn or not expected:
            return {"success": True, "verified": "no_verification", "result": str(actual_result)}
        
        prompt = f"""Action: {action}
Expected: {expected}
Actual result: {str(actual_result)[:1000]}

Did the actual result satisfy the expected outcome? Answer YES or NO with brief reason."""
        
        try:
            verdict = self.llm_fn(prompt)
            success = "YES" in verdict.upper()
            return {
                "success": success,
                "verified": "llm_verified",
                "verdict": verdict,
                "result": str(actual_result)[:500]
            }
        except Exception:
            return {"success": True, "verified": "error_fallback", "result": str(actual_result)}
    
    def get_task_status(self, task_id: str) -> Optional[Dict]:
        """Get current task status."""
        with self._lock:
            task = self.active_tasks.get(task_id)
        if not task:
            return None
        return {
            "id": task.id, "goal": task.goal, "status": task.status.value,
            "current_step": task.current_step, "total_steps": task.total_steps,
            "interrupted": task.interrupted, "error": task.error,
        }
    
    def interrupt_task(self, task_id: str, reason: str = "User interruption"):
        """Mark a task as interrupted."""
        with self._lock:
            task = self.active_tasks.get(task_id)
        if task and task.status == TaskStatus.RUNNING:
            task.interrupted = True
            task.interruption_reason = reason
            task.status = TaskStatus.INTERRUPTED
            log.info(f"Task {task_id} interrupted: {reason}")
    
    def cancel_task(self, task_id: str):
        """Cancel a task."""
        with self._lock:
            task = self.active_tasks.get(task_id)
        if task:
            task.status = TaskStatus.CANCELLED
            log.info(f"Task {task_id} cancelled")


# ════════════════════════════════════════════════════════════════════════════
# ═════════════════════════════════════════════════════════════════════════════
# TOOL/PLUGIN EXPANSION
# ════════════════════════════════════════════════════════════════════════════

# Local registry for extended tools
_extended_registry = ToolRegistry()

def register_extended_tools():
    """Register additional tools for calendar, search, file management, etc."""
    
    # Calendar tools
    def calendar_create_event(title: str, start_time: str, end_time: str = None,
                              description: str = "", calendar_id: str = "primary") -> Dict:
        """Create a calendar event. Requires Google Calendar API setup."""
        return {"success": True, "event_id": "placeholder", "message": "Calendar integration requires API setup"}
    _extended_registry.register("calendar_create_event", calendar_create_event, 
                                "Create a calendar event", category="calendar")
    
    def calendar_list_events(start_date: str, end_date: str = None, 
                             calendar_id: str = "primary", max_results: int = 10) -> Dict:
        """List calendar events in date range."""
        return {"success": True, "events": [], "message": "Calendar integration requires API setup"}
    _extended_registry.register("calendar_list_events", calendar_list_events,
                                "List calendar events in date range", category="calendar")
    
    # File management tools
    def file_find(pattern: str, root: str = "/home/ubuntu/M-2.0/workspace") -> Dict:
        """Find files matching pattern."""
        import glob
        matches = glob.glob(f"{root}/**/{pattern}", recursive=True)
        return {"success": True, "files": matches[:50]}
    _extended_registry.register("file_find", file_find, "Find files matching pattern", category="files")
    
    def file_grep(pattern: str, root: str = "/home/ubuntu/M-2.0/workspace",
                  file_pattern: str = "*") -> Dict:
        """Search for text in files."""
        import subprocess
        try:
            result = subprocess.run(
                ["grep", "-r", "-l", pattern, "--include", file_pattern, root],
                capture_output=True, text=True, timeout=30
            )
            files = result.stdout.strip().split("\n") if result.stdout else []
            return {"success": True, "files": files[:50]}
        except Exception as e:
            return {"success": False, "error": str(e)}
    _extended_registry.register("file_grep", file_grep, "Search for text in files", category="files")
    
    def dir_tree(path: str = "/home/ubuntu/M-2.0/workspace", max_depth: int = 3) -> Dict:
        """Show directory tree structure."""
        import os
        tree = []
        for root, dirs, files in os.walk(path):
            depth = root[len(path):].count(os.sep)
            if depth > max_depth:
                del dirs[:]
                continue
            indent = "  " * depth
            tree.append(f"{indent}{os.path.basename(root)}/")
            for f in files[:10]:  # Limit files per dir
                tree.append(f"{indent}  {f}")
        return {"success": True, "tree": "\n".join(tree[:100])}
    _extended_registry.register("dir_tree", dir_tree, "Show directory tree structure", category="files")
    
    # System monitoring
    def system_status() -> Dict:
        """Get system resource status."""
        import psutil
        return {
            "success": True,
            "cpu_percent": psutil.cpu_percent(interval=0.1),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_percent": psutil.disk_usage("/").percent,
            "load_avg": os.getloadavg() if hasattr(os, "getloadavg") else None,
        }
    _extended_registry.register("system_status", system_status, "Get system resource status", category="system")
    
    def process_list(filter_str: str = "") -> Dict:
        """List running processes."""
        import psutil
        procs = []
        for p in psutil.process_iter(["pid", "name", "cpu_percent", "memory_percent"]):
            try:
                info = p.info
                if filter_str and filter_str.lower() not in (info["name"] or "").lower():
                    continue
                procs.append(info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        procs.sort(key=lambda x: x.get("cpu_percent", 0) or 0, reverse=True)
        return {"success": True, "processes": procs[:20]}
    _extended_registry.register("process_list", process_list, "List running processes", category="system")
    
    # Web search enhancements
    def deep_research(topic: str, max_sources: int = 5) -> Dict:
        """Perform deep research on a topic using multiple searches."""
        return {"success": True, "topic": topic, "summary": f"Research on {topic} - requires implementation"}
    _extended_registry.register("deep_research", deep_research, "Perform deep research on a topic", category="research")
    
    log.info("Extended tools registered")

# ════════════════════════════════════════════════════════════════════════════
# INTERRUPTION HANDLING
# ════════════════════════════════════════════════════════════════════════════

class InterruptionHandler:
    """
    Handles voice command interruptions during Maya's execution.
    Integrates with voice gateway and autonomous planner.
    """
    
    def __init__(self, voice_gateway, autonomous_planner: AutonomousPlanner):
        self.voice_gateway = voice_gateway
        self.planner = autonomous_planner
        self.interruption_events: List[InterruptionEvent] = []
        self._lock = threading.Lock()
    
    def handle_interruption(self, session_id: str, transcript: str) -> InterruptionEvent:
        """Process a voice interruption."""
        event = InterruptionEvent(
            id=uuid.uuid4().hex[:12],
            session_id=session_id,
            timestamp=time.time(),
            transcript=transcript,
        )
        
        with self._lock:
            self.interruption_events.append(event)
        
        # Find active task for this session
        for task in self.planner.active_tasks.values():
            if task.session_id == session_id and task.status == TaskStatus.RUNNING:
                # Interrupt the task
                self.planner.interrupt_task(task.id, f"Voice command: {transcript}")
                event.handled = True
                event.action_taken = f"Interrupted task {task.id}"
                log.info(f"Interrupted task {task.id} for session {session_id}")
                break
        
        return event
    
    def get_interruption_history(self, session_id: str = None, limit: int = 20) -> List[Dict]:
        """Get interruption history."""
        with self._lock:
            events = self.interruption_events
        if session_id:
            events = [e for e in events if e.session_id == session_id]
        return [{
            "id": e.id, "session_id": e.session_id,
            "timestamp": e.timestamp, "transcript": e.transcript,
            "handled": e.handled, "action_taken": e.action_taken,
        } for e in events[-limit:]]


# ════════════════════════════════════════════════════════════════════════════
# EXTENDED AGENT ORCHESTRATOR
# ════════════════════════════════════════════════════════════════════════════

class ExtendedAgent:
    """
    Main orchestrator for all Phase 5 extended capabilities.
    Integrates with existing Maya without breaking the agentic pipeline.
    """
    
    def __init__(self):
        self.memory_manager = MemoryManager()
        self.persistent_memory = PersistentMemory(self.memory_manager)
        self.proactive_scheduler = ProactiveTaskScheduler(self.memory_manager, cognition_engine)
        self.autonomous_planner = AutonomousPlanner(self.memory_manager, self._get_llm_fn())
        self.interruption_handler = InterruptionHandler(None, self.autonomous_planner)
        
        # Register extended tools
        register_extended_tools()
        
# Add default proactive jobs
        self._setup_default_jobs()
        
        log.info("Extended Agent initialized")
    
    def _get_llm_fn(self) -> Callable:
        """Get LLM function from router."""
        try:
            from llm.router import LLMRouter
            router = LLMRouter()
            def llm_fn(prompt: str) -> str:
                return router.chat([{"role": "user", "content": prompt}], provider="openrouter")
            return llm_fn
        except Exception:
            return None
    
    def _setup_default_jobs(self):
        """Add default proactive maintenance jobs."""
        if not PROACTIVE_TASKS_ENABLED:
            return
        
        # Daily system health check
        self.proactive_scheduler.add_job(
            name="Daily Health Check",
            description="Check system resources, disk space, and service status",
            cron="0 6 * * *",  # 6 AM daily
            notify_on_failure=True,
        )
        
        # Hourly memory cleanup
        self.proactive_scheduler.add_job(
            name="Memory Cleanup",
            description="Run memory lifecycle cleanup to prune old/low-importance memories",
            cron="0 * * * *",  # Hourly
            notify_on_failure=False,
        )
        
        # Weekly project summary
        self.proactive_scheduler.add_job(
            name="Weekly Project Summary",
            description="Generate summary of all active projects and their progress",
            cron="0 9 * * 1",  # Monday 9 AM
            notify_on_success=True,
        )
    
    async def start(self):
        """Start all background services."""
        if PROACTIVE_TASKS_ENABLED:
            self.proactive_scheduler.start()
        log.info("Extended Agent started")
    
    async def stop(self):
        """Stop all background services."""
        self.proactive_scheduler.stop()
        log.info("Extended Agent stopped")
    
    # --- Voice command processing with interruption support ---
    
    async def process_voice_command(self, session_id: str, transcript: str, 
                                   user_id: str = "") -> Dict:
        """
        Process a voice command with full extended capabilities:
        1. Check permissions
        2. Check for interruption
        3. Get cross-session context
        4. Create and execute task with planning
        5. Save to persistent memory
        """
        # 1. Check permissions for voice command
        active_scopes = ["read_only"]  # Default safe scopes for voice
        perm_decision = self.permission_engine.check_voice_permission(
            transcript=transcript,
            session_id=session_id,
            user_id=user_id,
            active_scopes=active_scopes,
        )
        
        if not perm_decision.approved:
            return {
                "task_id": None,
                "success": False,
                "result": "",
                "error": f"Permission denied: {perm_decision.reason}",
                "interrupted": False,
                "steps_completed": 0,
                "total_steps": 0,
            }
        
        # 2. Handle interruption
        if INTERRUPTION_ENABLED:
            self.interruption_handler.handle_interruption(session_id, transcript)
        
        # 3. Get cross-session context
        context = self.persistent_memory.get_relevant_context(transcript, user_id)
        
        # 4. Create task with planning
        task = self.autonomous_planner.create_task(
            goal=transcript,
            task_type=TaskType.USER_REQUEST,
            session_id=session_id,
            user_id=user_id,
        )
        task.metadata["context"] = context
        
        # 5. Execute with interruption checking
        def check_interrupt():
            # Check if new interruption occurred for this session
            recent = self.interruption_handler.get_interruption_history(session_id, limit=1)
            return recent and recent[0]["timestamp"] > task.started_at
        
        result = await self.autonomous_planner.execute_task(task.id, check_interrupt)
        
        # 6. Save to persistent memory
        if result.get("success"):
            self.persistent_memory.save_conversation_summary(
                session_id=session_id,
                summary=f"User: {transcript} | Maya: {result.get('result', '')[:200]}",
                key_topics=[transcript[:50]]
            )
        
        return {
            "task_id": task.id,
            "success": result.get("success", False),
            "result": result.get("result", ""),
            "error": result.get("error", ""),
            "interrupted": result.get("interrupted", False),
            "steps_completed": task.current_step,
            "total_steps": task.total_steps,
        }
    
    # --- API methods for external access ---
    
    def get_status(self) -> Dict:
        """Get overall system status."""
        return {
            "extended_agent_enabled": EXTENDED_AGENT_ENABLED,
            "proactive_tasks_enabled": PROACTIVE_TASKS_ENABLED,
            "interruption_enabled": INTERRUPTION_ENABLED,
            "active_tasks": len(self.autonomous_planner.active_tasks),
            "proactive_jobs": len(self.proactive_scheduler.jobs),
            "memory_stats": self.memory_manager.get_stats(),
        }
    
    def get_task_status(self, task_id: str) -> Optional[Dict]:
        return self.autonomous_planner.get_task_status(task_id)
    
    def interrupt_current_task(self, session_id: str, reason: str = "User command") -> bool:
        """Interrupt the current task for a session."""
        for task in self.autonomous_planner.active_tasks.values():
            if task.session_id == session_id and task.status == TaskStatus.RUNNING:
                self.autonomous_planner.interrupt_task(task.id, reason)
                return True
        return False
    
    def add_proactive_job(self, name: str, description: str, cron: str) -> str:
        return self.proactive_scheduler.add_job(name, description, cron)
    
    def list_proactive_jobs(self) -> List[Dict]:
        return self.proactive_scheduler.get_jobs()
    
    def remember_user_preference(self, user_id: str, key: str, value: str):
        self.persistent_memory.remember_preference(user_id, key, value)
    
    def get_user_preference(self, user_id: str, key: str) -> Optional[str]:
        return self.persistent_memory.get_preference(user_id, key)
    
    def save_project_state(self, project_id: str, state: Dict):
        self.persistent_memory.save_project_state(project_id, state)
    
    def load_project_state(self, project_id: str) -> Optional[Dict]:
        return self.persistent_memory.load_project_state(project_id)


# ════════════════════════════════════════════════════════════════════════════
# MODULE SINGLETON
# ════════════════════════════════════════════════════════════════════════════

_extended_agent: Optional[ExtendedAgent] = None

def get_extended_agent() -> ExtendedAgent:
    """Get or create the global ExtendedAgent instance."""
    global _extended_agent
    if _extended_agent is None:
        _extended_agent = ExtendedAgent()
    return _extended_agent

def reset_extended_agent():
    global _extended_agent
    if _extended_agent:
        asyncio.create_task(_extended_agent.stop())
    _extended_agent = None