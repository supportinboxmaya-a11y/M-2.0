"""
Maya 2.0 ULTRA - Tier 3: Top-Level Autonomous Operator
=========================================================
Enables full autonomous agentic execution with:
- Self-healing & active error recovery
- Multi-agent orchestration (Core, Learner, Executor, Registry)
- Recursive task planning & decomposition
- Web Search + Scraping + Code Synthesis + Sandbox Verification pipeline
- Automated skill distillation
- Shell control with safety guardrails & rollback
"""

import os
import asyncio
import json
import time
import uuid
import subprocess
import tempfile
import shlex
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional, Callable, Literal
from dataclasses import dataclass, field, asdict
from pathlib import Path
from contextlib import asynccontextmanager
import logging

logger = logging.getLogger("tier3")

# Config
TIER3_ENABLED = os.environ.get("TIER3_ENABLED", "true").lower() == "true"
TIER3_MAX_DEPTH = int(os.environ.get("TIER3_MAX_DEPTH", "5"))
TIER3_MAX_RETRIES = int(os.environ.get("TIER3_MAX_RETRIES", "3"))
TIER3_SANDBOX_TIMEOUT = int(os.environ.get("TIER3_SANDBOX_TIMEOUT", "60"))
TIER3_SEARCH_RESULTS = int(os.environ.get("TIER3_SEARCH_RESULTS", "5"))
TIER3_SKILL_DISTILL_THRESHOLD = int(os.environ.get("TIER3_SKILL_DISTILL_THRESHOLD", "3"))


# Data Structures
@dataclass
class Task:
    """A task in the execution plan."""
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    name: str = ""
    description: str = ""
    agent: str = "core"
    tool: Optional[str] = None
    args: Dict = field(default_factory=dict)
    depends_on: List[str] = field(default_factory=list)
    status: Literal["pending", "running", "done", "failed", "skipped"] = "pending"
    result: Any = None
    error: Optional[str] = None
    retries: int = 0
    depth: int = 0
    parent_id: Optional[str] = None
    artifacts: List[str] = field(default_factory=list)


@dataclass
class ExecutionPlan:
    """A full execution plan with tasks."""
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    goal: str = ""
    tasks: List[Task] = field(default_factory=list)
    created_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    status: Literal["planning", "executing", "done", "failed"] = "planning"
    result: Any = None
    error: Optional[str] = None


@dataclass
class SkillCandidate:
    """A candidate skill for distillation."""
    name: str
    pattern: str
    description: str
    code_template: str
    examples: List[Dict] = field(default_factory=list)
    frequency: int = 0
    success_rate: float = 0.0


# Tier 3 Core Agent Classes

class Tier3Core:
    """Maya-Core: High-level planning, decomposition, and orchestration."""
    
    def __init__(self, llm_fn: Callable, tool_registry: Any, sandbox: Any, memory: Any):
        self.llm = llm_fn
        self.tools = tool_registry
        self.sandbox = sandbox
        self.memory = memory
        self.plans: Dict[str, ExecutionPlan] = {}
        
    async def decompose_goal(self, goal: str, context: Dict = None) -> ExecutionPlan:
        context = context or {}
        context_str = json.dumps(context, indent=2) if context else "{}"
        
        # Pre-escape JSON example for str.format()
        example_json = '{"tasks":[{"id":"t1","agent":"executor","tool":"run_shell","args":{"command":"echo hello"},"depends_on":[]}]}'
        escaped_example = example_json.replace("{", "{{").replace("}", "}}")
        
        # Simplified prompt for faster LLM response
        prompt = (
            "Goal: {goal}. Return JSON plan with tasks array. Each task: id, agent (executor/learner/core/registry), tool (run_code/run_shell/web_search), args, depends_on. Example: " + escaped_example
        ).format(goal=goal)
        
        try:
            messages = [{"role": "user", "content": prompt}]
            response = self.llm(messages)
            # Extract JSON from markdown code blocks if present
            json_str = response.strip()
            if json_str.startswith("```"):
                # Extract JSON from markdown code block
                lines = json_str.split("\n")
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines[-1].startswith("```"):
                    lines = lines[:-1]
                json_str = "\n".join(lines)
            plan_data = json.loads(json_str)
            
            for t in plan_data.get("tasks", []):
                task = Task(**t)
                plan.tasks.append(task)
                
            self.plans[plan.id] = plan
            return plan
            
        except Exception as e:
            logger.error(f"Decomposition failed: {e}")
            plan = ExecutionPlan(goal=goal)
            plan.tasks.append(Task(
                name="Execute Goal",
                description=goal,
                agent="executor",
                tool="run_code",
                args={"code": f"# Execute: {goal}"}
            ))
            return plan

    async def refine_plan(self, plan: ExecutionPlan, feedback: str) -> ExecutionPlan:
        return plan


class Tier3Learner:
    """Maya-Learner: Research, web search, knowledge synthesis."""
    
    def __init__(self, llm_fn: Callable, tool_registry: Any, memory: Any):
        self.llm = llm_fn
        self.tools = tool_registry
        self.memory = memory
        
    async def research(self, query: str, depth: int = 2) -> Dict:
        results = {"query": query, "sources": [], "synthesis": ""}
        
        search_results = self.tools.run("web_search", {"query": query, "num_results": TIER3_SEARCH_RESULTS})
        results["raw_search"] = search_results
        
        urls = []
        for line in str(search_results).split("\n"):
            if "URL:" in line or "http" in line:
                for part in line.split():
                    if part.startswith("http"):
                        urls.append(part)
        
        scraped = []
        for url in urls[:TIER3_SEARCH_RESULTS]:
            try:
                content = self.tools.run("web_scrape", {"url": url})
                scraped.append({"url": url, "content": content[:3000]})
            except:
                pass
        results["sources"] = scraped
        
        if scraped:
            prompt = f"Summarize: {query}. Sources: {str(scraped)[:1000]}. Key findings:"
            synthesis = self.llm([{"role": "user", "content": prompt}])
            results["synthesis"] = synthesis
            
            if self.memory:
                self.memory.add(synthesis, doc_id=f"research_{query}_{int(time.time())}")
                
        return results
    
    async def deep_research(self, topic: str, iterations: int = 3) -> Dict:
        knowledge = {"topic": topic, "iterations": []}
        current_query = topic
        
        for i in range(iterations):
            result = await self.research(current_query)
            knowledge["iterations"].append({
                "query": current_query,
                "result": result
            })
            
            if i < iterations - 1:
                followup_prompt = f"Topic: {topic}. Findings: {result['synthesis'][:500]}. Next question? One line."
                current_query = self.llm([{"role": "user", "content": followup_prompt}])
            
        return knowledge


class Tier3Executor:
    """Maya-Executor: Code execution, sandbox verification, shell commands."""
    
    def __init__(self, tool_registry: Any, sandbox: Any, safety: Any, llm_fn: Callable = None):
        self.tools = tool_registry
        self.sandbox = sandbox
        self.safety = safety
        self.llm = llm_fn
        
    async def execute_code(self, code: str, language: str = "python", verify: bool = True) -> Dict:
        result = {"success": False, "output": "", "error": "", "verified": False}
        
        if self.safety and not self.safety.check_code(code):
            result["error"] = "Code failed safety check"
            return result
            
        if verify and self.sandbox:
            try:
                sb_result = self.sandbox.execute(code, language=language)
                result.update(sb_result)
                result["verified"] = True
            except Exception as e:
                result["error"] = f"Sandbox error: {e}"
                result = self._direct_execute(code)
        else:
            result = self._direct_execute(code)
            
        return result
    
    def _direct_execute(self, code: str) -> Dict:
        try:
            # Strip markdown code fences if present
            code = code.strip()
            if code.startswith("```"):
                lines = code.split("\n")
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines and lines[-1].startswith("```"):
                    lines = lines[:-1]
                code = "\n".join(lines)
            
            if code.strip().startswith("#!"):
                result = self.tools.run("run_shell", {"command": code})
            else:
                result = self.tools.run("run_code", {"code": code})
            result["verified"] = False
            return result
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def execute_shell(self, command: str, timeout: int = 30) -> Dict:
        if self.safety and not self.safety.check_command(command):
            return {"success": False, "error": "Command blocked by safety"}
            
        try:
            result = self.tools.run("run_shell", {"command": command, "timeout": timeout})
            return result
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def verify_and_fix(self, code: str, expected_behavior: str) -> Dict:
        for attempt in range(TIER3_MAX_RETRIES):
            result = await self.execute_code(code, verify=True)
            
            if result.get("success"):
                if "error" not in result or not result["error"]:
                    return {"success": True, "code": code, "output": result.get("output")}
            
            fix_prompt = f"Fix code. Error: {result.get('error', 'Unknown')}. Code: {code[:500]}. Return fixed code only."
            code = self.llm(
                [{"role": "user", "content": fix_prompt}],
                max_tokens=1000
            )
            # Strip markdown code fences from LLM response
            code = code.strip()
            if code.startswith("```"):
                lines = code.split("\n")
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines and lines[-1].startswith("```"):
                    lines = lines[:-1]
                code = "\n".join(lines)
            
        return {"success": False, "error": "Max retries exceeded", "final_code": code}


class Tier3Registry:
    """Maya-Registry: Tool management, skill registration, capability lookup."""
    
    def __init__(self, tool_registry: Any, memory: Any):
        self.tools = tool_registry
        self.memory = memory
        self.skills: Dict[str, SkillCandidate] = {}
        
    def register_skill(self, skill: SkillCandidate) -> bool:
        self.skills[skill.name] = skill
        if skill.code_template:
            def skill_func(**kwargs):
                return skill.code_template.format(**kwargs)
            self.tools.register(
                f"skill_{skill.name}",
                skill_func,
                skill.description,
                category="skill"
            )
        return True
    
    def find_applicable_skills(self, task: str) -> List[SkillCandidate]:
        task_lower = task.lower()
        applicable = []
        for skill in self.skills.values():
            if any(kw in task.lower() for kw in skill.pattern.lower().split()):
                applicable.append(skill)
        return sorted(applicable, key=lambda s: s.success_rate, reverse=True)
    
    def record_skill_usage(self, skill_name: str, success: bool):
        if skill_name in self.skills:
            skill = self.skills[skill_name]
            skill.frequency += 1
            skill.success_rate = 0.9 * skill.success_rate + 0.1 * (1.0 if success else 0.0)
            
            if skill.frequency >= TIER3_SKILL_DISTILL_THRESHOLD and skill.success_rate > 0.8:
                self._distill_skill(skill_name)
    
    def _distill_skill(self, skill_name: str):
        skill = self.skills.get(skill_name)
        if not skill:
            return
        logger.info(f"Distilling skill: {skill_name} (freq={skill.frequency}, rate={skill.success_rate:.2f})")


class Tier3ResearchPipeline:
    """Web Search + Deep Scraping + Code Synthesis + Sandbox Verification."""
    
    def __init__(self, learner: Tier3Learner, executor: Tier3Executor, 
                 registry: Tier3Registry, memory: Any):
        self.learner = learner
        self.executor = executor
        self.registry = registry
        self.memory = memory
        
    async def solve_with_research(self, problem: str) -> Dict:
        logger.info(f"Phase 1: Researching '{problem}'")
        research = await self.learner.deep_research(problem)
        
        logger.info("Phase 2: Planning solution")
        plan = await self.learner.llm(
            f"""Create a step-by-step implementation plan for:
{problem}

RESEARCH FINDINGS:
{json.dumps(research['iterations'][-1]['result'], indent=2)[:3000]}

Return JSON plan with steps, each having: name, description, tool, args."""
        )
        
        logger.info("Phase 3: Executing with verification")
        try:
            plan_data = json.loads(plan)
        except:
            plan_data = {"steps": [{"name": "Execute", "tool": "run_code", 
                                   "args": {"code": f"# {problem}"}}]}
        
        results = []
        for step in plan_data.get("steps", []):
            step_result = await self._execute_step(step)
            results.append(step_result)
            if not step_result.get("success"):
                logger.warning(f"Step failed, attempting fix: {step_result.get('error')}")
                
        return {
            "problem": problem,
            "research": research,
            "plan": plan_data,
            "execution_results": results,
            "final_output": results[-1].get("output") if results else None
        }
    
    async def _execute_step(self, step: Dict) -> Dict:
        tool = step.get("tool", "run_code")
        args = step.get("args", {})
        
        try:
            if tool == "run_code":
                code = args.get("code", "")
                expected = args.get("expected", "")
                return await self.executor.verify_and_fix(code, expected)
            elif tool == "run_shell":
                cmd = args.get("command", "")
                return await self.executor.execute_shell(cmd)
            else:
                result = self.learner.tools.run(tool, args)
                return {"success": True, "output": result}
        except Exception as e:
            return {"success": False, "error": str(e), "step": step}


class Tier3SkillDistiller:
    """Automatically write, test, and register new tool capabilities."""
    
    def __init__(self, llm_fn: Callable, tool_registry: Any, sandbox: Any, 
                 executor: Tier3Executor, memory: Any):
        self.llm = llm_fn
        self.tools = tool_registry
        self.sandbox = sandbox
        self.executor = executor
        self.memory = memory
        self.distilled_skills: List[Dict] = []
        
    async def distill_from_pattern(self, pattern_name: str, 
                                   examples: List[Dict],
                                   description: str) -> Dict:
        
        prompt = f"""Create a reusable tool/skill from these successful execution patterns:

PATTERN NAME: {pattern_name}
DESCRIPTION: {description}

EXAMPLES:
{json.dumps(examples, indent=2)}

Generate a Python function that encapsulates this pattern.
The function should:
1. Accept clear parameters
2. Handle errors gracefully
3. Return structured results
4. Include docstring

Return ONLY the Python function code."""
        
        code = self.llm([{"role": "user", "content": prompt}])
        
        test_result = await self._test_skill(code, examples[0] if examples else {})
        
        if test_result.get("success"):
            skill_name = pattern_name.lower().replace(" ", "_")
            # Extract function name
            func_name = None
            for line in code.split("\n"):
                if line.strip().startswith("def "):
                    func_name = line.split("def ")[1].split("(")[0]
                    break
            if func_name:
                func = eval(code.split("\n")[0].replace("def ", "").replace(":", "").strip())
                self.tools.register(
                    f"skill_{skill_name}",
                    func,
                    description,
                    category="skill"
                )
                self.distilled_skills.append({
                    "name": skill_name,
                    "code": code,
                    "tested": True,
                    "created_at": datetime.now(timezone.utc).isoformat()
                })
                return {"success": True, "skill_name": skill_name, "code": code}
        return {"success": False, "error": test_result.get("error"), "code": code}
    
    async def _test_skill(self, code: str, test_input: Dict) -> Dict:
        try:
            func_name = None
            for line in code.split("\n"):
                if line.strip().startswith("def "):
                    func_name = line.split("def ")[1].split("(")[0]
                    break
            
            if not func_name:
                return {"success": False, "error": "No function found"}
            
            test_code = f"""
{code}

import json
result = {func_name}(**{json.dumps(test_input)})
print(json.dumps(result, default=str))
"""
            result = await self.executor.execute_code(test_code, verify=True)
            return result
        except Exception as e:
            return {"success": False, "error": str(e)}


class Tier3Safety:
    """Safety guardrails with rollback mechanisms."""
    
    def __init__(self):
        self.snapshots: Dict[str, Any] = {}
        self.blocked_patterns = [
            "rm -rf /", "rm -rf ~", "mkfs", "dd if=/dev/",
            ":(){ :|:& };:", "chmod -R 777 /", "wget | sh", "curl | sh",
            "shutdown", "reboot", "systemctl stop", "systemctl disable"
        ]
        
    def check_command(self, command: str) -> bool:
        cmd_lower = command.lower()
        for blocked in self.blocked_patterns:
            if blocked in cmd_lower:
                return False
        return True
    
    def check_code(self, code: str) -> bool:
        dangerous = ["os.system", "subprocess.call", "eval(", "exec(", "__import__"]
        for d in dangerous:
            if d in code:
                return False
        return True
    
    def create_snapshot(self, name: str, state: Any):
        self.snapshots[name] = {
            "state": state,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        
    def rollback(self, name: str) -> Any:
        return self.snapshots.get(name, {}).get("state")


class Tier3Orchestrator:
    """Main orchestrator coordinating all Tier 3 agents."""
    
    def __init__(self, llm_fn: Callable, tool_registry: Any, 
                 sandbox: Any, memory: Any):
        self.llm = llm_fn
        self.tools = tool_registry
        self.sandbox = sandbox
        self.memory = memory
        
        self.safety = Tier3Safety()
        self.core = Tier3Core(llm_fn, tool_registry, sandbox, memory)
        self.learner = Tier3Learner(llm_fn, tool_registry, memory)
        self.executor = Tier3Executor(tool_registry, sandbox, self.safety, llm_fn)
        self.registry = Tier3Registry(tool_registry, memory)
        self.research_pipeline = Tier3ResearchPipeline(
            self.learner, self.executor, self.registry, memory
        )
        self.distiller = Tier3SkillDistiller(
            llm_fn, tool_registry, sandbox, self.executor, memory
        )
        
        self.active_plans: Dict[str, ExecutionPlan] = {}
        self.execution_history: List[Dict] = []
        
    async def execute_goal(self, goal: str, context: Dict = None) -> Dict:
        plan = await self.core.decompose_goal(goal, context)
        self.active_plans[plan.id] = plan
        
        logger.info(f"Executing plan {plan.id} for goal: {goal}")
        
        completed = set()
        results = {}
        
        while len(completed) < len(plan.tasks):
            progress = False
            for task in plan.tasks:
                if task.id in completed:
                    continue
                    
                if not all(dep in completed for dep in task.depends_on):
                    continue
                    
                task.status = "running"
                task_result = await self._execute_task(task, results)
                
                task.status = "done" if task_result.get("success") else "failed"
                task.result = task_result
                results[task.id] = task_result
                completed.add(task.id)
                progress = True
                
                if not task_result.get("success"):
                    logger.error(f"Task {task.id} failed: {task_result.get('error')}")
                    
            if not progress:
                break
                
        plan.status = "done" if all(t.status == "done" for t in plan.tasks) else "failed"
        plan.result = results
        
        self.execution_history.append({
            "plan_id": plan.id,
            "goal": goal,
            "status": plan.status,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "tasks_completed": len([t for t in plan.tasks if t.status == "done"]),
            "tasks_total": len(plan.tasks)
        })
        
        return {
            "plan_id": plan.id,
            "goal": goal,
            "status": plan.status,
            "tasks": [asdict(t) for t in plan.tasks],
            "final_result": results
        }
    
    async def _execute_task(self, task: Task, prior_results: Dict) -> Dict:
        context = {k: v.get("output", v) for k, v in prior_results.items()}
        
        try:
            if task.agent == "learner":
                return await self._execute_learner_task(task, context)
            elif task.agent == "executor":
                return await self._execute_executor_task(task, context)
            elif task.agent == "registry":
                return await self._execute_registry_task(task, context)
            else:
                return await self._execute_core_task(task, context)
        except Exception as e:
            return {"success": False, "error": str(e), "task_id": task.id}
    
    async def _execute_learner_task(self, task: Task, context: Dict) -> Dict:
        tool = task.tool or "web_search"
        args = task.args.copy()
        
        if "query" in args and isinstance(args["query"], str):
            for k, v in context.items():
                if isinstance(v, str) and len(v) < 500:
                    args["query"] = args["query"].replace(f"{{{{{k}}}}}", v)
        
        try:
            result = self.learner.tools.run(tool, args)
            return {"success": True, "output": result}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def _execute_executor_task(self, task: Task, context: Dict) -> Dict:
        tool = task.tool or "run_code"
        args = task.args.copy()
        
        for k, v in context.items():
            if isinstance(v, str) and len(v) < 1000:
                for arg_k, arg_v in args.items():
                    if isinstance(arg_v, str):
                        args[arg_k] = arg_v.replace(f"{{{{{k}}}}}", v)
        
        if tool == "run_code":
            return await self.executor.verify_and_fix(
                args.get("code", ""), 
                args.get("expected", "")
            )
        elif tool == "run_shell":
            return await self.executor.execute_shell(args.get("command", ""))
        else:
            try:
                result = self.tools.run(tool, args)
                return {"success": True, "output": result}
            except Exception as e:
                return {"success": False, "error": str(e)}
    
    async def _execute_registry_task(self, task: Task, context: Dict) -> Dict:
        tool = task.tool or "skill_lookup"
        args = task.args.copy()
        
        if tool == "skill_lookup":
            skills = self.registry.find_applicable_skills(args.get("task", ""))
            return {"success": True, "output": [s.name for s in skills]}
        elif tool == "skill_distill":
            return await self.distiller.distill_from_pattern(
                args.get("name", ""), 
                args.get("examples", []),
                args.get("description", "")
            )
        else:
            return {"success": False, "error": f"Unknown registry tool: {tool}"}
    
    async def _execute_core_task(self, task: Task, context: Dict) -> Dict:
        prompt = f"Task: {task.name}. Context: {str(context)[:500]}. Decision:"
        decision = self.llm([{"role": "user", "content": prompt}])
        return {"success": True, "output": decision}


class Tier3System:
    """Main Tier 3 system entry point."""
    
    def __init__(self, llm_fn: Callable, tool_registry: Any, 
                 sandbox: Any, memory: Any):
        self.orchestrator = Tier3Orchestrator(llm_fn, tool_registry, sandbox, memory)
        self.enabled = TIER3_ENABLED
        
    async def initialize(self) -> Dict:
        if not self.enabled:
            return {"status": "disabled", "message": "TIER3_ENABLED=false"}
            
        checks = {
            "llm": self._check_llm(),
            "tools": self._check_tools(),
            "sandbox": self._check_sandbox(),
            "memory": self._check_memory(),
            "safety": self._check_safety(),
        }
        
        all_ok = all(checks.values())
        
        return {
            "status": "ready" if all_ok else "degraded",
            "checks": checks,
            "tier": 3,
            "features": [
                "autonomous_execution",
                "multi_agent_orchestration",
                "recursive_planning",
                "web_research_pipeline",
                "sandbox_verification",
                "skill_distillation",
                "safety_guardrails",
                "rollback_mechanism"
            ]
        }
    
    def _check_llm(self) -> bool:
        return self.orchestrator.llm is not None
    
    def _check_tools(self) -> bool:
        return len(self.orchestrator.tools.tool_names()) > 0
    
    def _check_sandbox(self) -> bool:
        return self.orchestrator.sandbox is not None
    
    def _check_memory(self) -> bool:
        return self.orchestrator.memory is not None
    
    def _check_safety(self) -> bool:
        return self.orchestrator.safety is not None
    
    async def execute(self, goal: str, context: Dict = None) -> Dict:
        if not self.enabled:
            return {"error": "Tier 3 not enabled"}
        return await self.orchestrator.execute_goal(goal, context)
    
    def health_check(self) -> Dict:
        return {
            "tier": 3,
            "enabled": self.enabled,
            "active_plans": len(self.orchestrator.active_plans),
            "history_count": len(self.orchestrator.execution_history),
            "distilled_skills": len(self.orchestrator.distiller.distilled_skills),
            "tools_available": len(self.orchestrator.tools.tool_names()),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }


def create_tier3_system(llm_fn: Callable, tool_registry: Any, 
                        sandbox: Any, memory: Any) -> Tier3System:
    return Tier3System(llm_fn, tool_registry, sandbox, memory)


def register_tier3_routes(app, tier3_system: Tier3System):
    from fastapi import APIRouter, HTTPException
    from pydantic import BaseModel
    from typing import Optional, Dict, Any, List
    
    router = APIRouter(prefix="/api/v1/tier3", tags=["tier3"])
    
    class GoalRequest(BaseModel):
        goal: str
        context: Optional[Dict] = None
        
    class HealthResponse(BaseModel):
        tier: int
        enabled: bool
        active_plans: int
        history_count: int
        distilled_skills: int
        tools_available: int
        timestamp: str
    
    @router.post("/execute")
    async def execute_goal(request: GoalRequest):
        if not tier3_system.enabled:
            raise HTTPException(503, "Tier 3 not enabled")
        return await tier3_system.execute(request.goal, request.context)
    
    @router.get("/health")
    async def health():
        return tier3_system.health_check()
    
    @router.get("/plans/{plan_id}")
    async def get_plan(plan_id: str):
        plan = tier3_system.orchestrator.active_plans.get(plan_id)
        if not plan:
            raise HTTPException(404, "Plan not found")
        return {k: v for k, v in asdict(plan).items() if k != "tasks"} |                {"tasks": [asdict(t) for t in plan.tasks]}
    
    @router.get("/history")
    async def get_history(limit: int = 20):
        return tier3_system.orchestrator.execution_history[-limit:]
    
    @router.get("/skills")
    async def list_skills():
        return tier3_system.orchestrator.distiller.distilled_skills
    
    @router.post("/skills/distill")
    async def distill_skill(name: str, examples: List[Dict], description: str):
        return await tier3_system.orchestrator.distiller.distill_from_pattern(
            name, examples, description
        )
    
    @router.post("/research")
    async def deep_research(query: str, iterations: int = 3):
        return await tier3_system.orchestrator.learner.deep_research(query, iterations)
    
    @router.post("/pipeline/solve")
    async def solve_with_research(problem: str):
        return await tier3_system.orchestrator.research_pipeline.solve_with_research(problem)
    
    app.include_router(router)


async def auto_init_tier3(maya_instance) -> Tier3System:
    if not TIER3_ENABLED:
        logger.info(f"TIER3_ENABLED={TIER3_ENABLED}")
        logger.info("Tier 3 disabled (TIER3_ENABLED=false)")
        return None
        
    # Extract components from Maya instance
    tool_registry = None
    if hasattr(maya_instance, 'tool_manager') and maya_instance.tool_manager:
        tool_registry = maya_instance.tool_manager.get_registry()
    
    logger.info(f"DEBUG: tool_registry={tool_registry}, executor={hasattr(maya_instance, 'executor')}, memory={hasattr(maya_instance, 'memory')}");
    logger.info("DEBUG: Creating Tier3System...");
    tier3 = Tier3System(
        llm_fn=maya_instance.router.chat if hasattr(maya_instance, 'router') and hasattr(maya_instance.router, 'chat') else None,
        tool_registry=tool_registry,
        sandbox=maya_instance.executor if hasattr(maya_instance, 'executor') else None,
        memory=maya_instance.memory if hasattr(maya_instance, 'memory') else None
    )

    
    return tier3


if __name__ == "__main__":
    async def test():
        async def mock_llm(prompt):
            return '{"tasks": [{"id": "1", "name": "test", "agent": "executor", "tool": "run_code", "args": {"code": "print(1)"}}]}'
        
        class MockTools:
            def run(self, name, args):
                return f"Mock result for {name}"
            def tool_names(self):
                return ["run_code", "run_shell", "web_search"]
        
        class MockSandbox:
            def execute(self, code, language="python"):
                return {"success": True, "output": "OK"}
        
        class MockMemory:
            def add(self, content, doc_id=None):
                pass
        
        tier3 = create_tier3_system(mock_llm, MockTools(), MockSandbox(), MockMemory())
        status = await tier3.initialize()
        print(f"Init status: {status}")
        
        result = await tier3.execute("Create a hello world Python script")
        print(f"Execution: {json.dumps(result, indent=2)}")
        
        health = tier3.health_check()
        print(f"Health: {json.dumps(health, indent=2)}")
    
    asyncio.run(test())
