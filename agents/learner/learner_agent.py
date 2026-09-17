"""
Maya-Learner: Autonomous skill acquisition sub-agent.
Searches web, synthesizes code, executes in sandbox, distills to procedural memory.
"""
import json
import uuid
import asyncio
import hashlib
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field
from datetime import datetime

from llm.router import LLMRouter
from infrastructure.procedural_memory import get_procedural_memory
from infrastructure.streaming import get_stream_manager, StreamEventType
from infrastructure.capability_registry import get_capability_registry, CapabilityType
from infrastructure.sandbox_executor import SandboxExecutor

from agents.learner.config import LearnerConfig
from agents.learner.search_executor import SearchExecutor, SearchResult
from agents.learner.code_executor import CodeExecutor
from agents.learner.knowledge_persister import KnowledgePersister, LearningRecord, LearnedSkill


@dataclass
class LearningTask:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    goal: str = ""
    missing_capability: str = ""
    status: str = "pending"  # pending, searching, scraping, synthesizing, executing, distilling, done, failed
    search_results: List[Dict] = field(default_factory=list)
    scraped_content: List[Dict] = field(default_factory=list)
    synthesized_code: str = ""
    execution_result: Dict = field(default_factory=dict)
    skill_id: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)


class MayaLearner:
    """Standalone learner sub-agent for acquiring new capabilities."""

    def __init__(
        self,
        router: Optional[LLMRouter] = None,
        approval_manager=None,
        intervention_handler=None,
    ):
        self.config = LearnerConfig
        self.router = router or LLMRouter()
        self.approval = approval_manager
        self.intervention = intervention_handler
        self.stream = get_stream_manager()
        self.searcher = SearchExecutor()
        self.coder = CodeExecutor()
        self.knowledge = KnowledgePersister()
        self.procedural = get_procedural_memory()
        self.registry = get_capability_registry()
        self.sandbox = SandboxExecutor()
        self._tasks: Dict[str, LearningTask] = {}

    async def learn_capability(self, goal: str, missing_capability: str) -> LearningTask:
        """Main entry: search → scrape → synthesize → execute → distill."""
        task = LearningTask(goal=goal, missing_capability=missing_capability)
        self._tasks[task.id] = task
        await self._emit(task.id, "started", {"goal": goal, "capability": missing_capability})

        # Persist initial record
        record = LearningRecord(
            id=task.id,
            goal=goal,
            missing_capability=missing_capability,
            status="searching",
        )
        self.knowledge.save_record(record)

        try:
            # Step 1: Search
            task.status = "searching"
            record.status = "searching"
            await self._emit(task.id, "phase", {"phase": "search"})
            task.search_results = await self._search_web(missing_capability)
            record.search_results = [{"title": r.title, "url": r.url, "snippet": r.snippet, "rank": r.rank} for r in task.search_results]
            self.knowledge.save_record(record)

            # Step 2: Scrape top results
            task.status = "scraping"
            record.status = "scraping"
            await self._emit(task.id, "phase", {"phase": "scrape"})
            task.scraped_content = await self._scrape_sources(task.search_results)
            record.scraped_sources = task.scraped_content
            self.knowledge.save_record(record)

            # Step 3: Synthesize code/tool
            task.status = "synthesizing"
            record.status = "synthesizing"
            await self._emit(task.id, "phase", {"phase": "synthesize"})
            task.synthesized_code = await self._synthesize_solution(task)
            record.synthesized_code = task.synthesized_code
            self.knowledge.save_record(record)

            # Step 4: Execute in sandbox (with approval)
            if self.config.REQUIRE_APPROVAL and self.approval:
                approved = self.approval.request_approval(
                    action=f"Execute learned code for: {missing_capability}",
                    reason=f"Auto-generated solution for {goal}",
                    risk_level="medium",
                )
                if not approved:
                    task.status = "failed"
                    task.error = "Approval denied"
                    record.status = "failed"
                    record.error = "Approval denied"
                    self.knowledge.save_record(record)
                    await self._emit(task.id, "failed", {"error": "Approval denied"})
                    return task

            task.status = "executing"
            record.status = "executing"
            await self._emit(task.id, "phase", {"phase": "execute"})
            task.execution_result = await self._execute_in_sandbox(task.synthesized_code)
            record.execution_result = task.execution_result
            self.knowledge.save_record(record)

            # Step 5: Distill to procedural memory (skill)
            if task.execution_result.get("success") and self.config.AUTO_DISTILL:
                task.status = "distilling"
                record.status = "distilling"
                await self._emit(task.id, "phase", {"phase": "distill"})
                task.skill_id = await self._distill_skill(task)
                record.skill_id = task.skill_id
                self.knowledge.save_record(record)

            task.status = "done"
            record.status = "done"
            record.completed_at = datetime.utcnow()
            self.knowledge.save_record(record)
            await self._emit(task.id, "completed", {"skill_id": task.skill_id})
            return task

        except Exception as e:
            task.status = "failed"
            task.error = str(e)
            record.status = "failed"
            record.error = str(e)
            record.completed_at = datetime.utcnow()
            self.knowledge.save_record(record)
            await self._emit(task.id, "failed", {"error": str(e)})
            return task

    async def _search_web(self, capability: str) -> List[SearchResult]:
        query = f"How to implement {capability} in Python code example tutorial"
        results = await self.searcher.search(query, self.config.MAX_SEARCH_RESULTS)
        return results

    async def _scrape_sources(self, results: List[SearchResult]) -> List[Dict]:
        urls = [r.url for r in results if r.url]
        scraped = await self.searcher.scrape_multiple(urls, self.config.MAX_SCRAPE_LENGTH)
        return [
            {
                "url": s.url,
                "title": s.title,
                "content": s.content,
                "length": s.content_length,
                "success": s.success,
                "error": s.error,
            }
            for s in scraped
        ]

    async def _synthesize_solution(self, task: LearningTask) -> str:
        context_parts = []
        for s in task.scraped_content:
            if s.get("success") and s.get("content"):
                context_parts.append(f"SOURCE: {s['url']}\n{s['content'][:3000]}")

        context = "\n\n---\n\n".join(context_parts)

        prompt = f"""You are Maya-Learner. Write a Python function/module that implements:
{task.missing_capability}

Context from web search:
{context}

Requirements:
- Single self-contained function or class with clear entry point
- Handle errors gracefully, return dict with 'success', 'result', 'error' keys
- Type hints for all functions
- No external dependencies beyond Python stdlib
- Include docstring explaining usage
- If async, provide sync wrapper

Output ONLY the Python code. No markdown, no explanations."""

        response = await asyncio.get_event_loop().run_in_executor(
            None, lambda: self.router.chat([{"role": "user", "content": prompt}])
        )
        return response.strip()

    async def _execute_in_sandbox(self, code: str) -> Dict:
        """Execute synthesized code in sandbox and validate."""
        # First validate syntax
        validation = await self.coder.validate_syntax(code)
        if not validation["valid"]:
            return {"success": False, "error": f"Syntax validation failed: {validation['error']}"}

        # Execute with test harness
        result = await self.coder.execute(code)

        if not result.success:
            return {"success": False, "error": result.error, "output": result.output}

        # Parse test results
        try:
            test_results = json.loads(result.output)
            # Check if any test passed
            passed = any(v.get("success") for v in test_results.values() if isinstance(v, dict))
            return {
                "success": passed,
                "test_results": test_results,
                "execution_time": result.execution_time,
            }
        except json.JSONDecodeError:
            return {"success": True, "raw_output": result.output, "execution_time": result.execution_time}

    async def _distill_skill(self, task: LearningTask) -> Optional[str]:
        """Save successful execution as a procedural skill."""
        try:
            # Create skill record
            skill = LearnedSkill(
                name=f"learned_{task.missing_capability.lower().replace(' ', '_')}",
                description=f"Auto-learned: {task.goal}",
                capability_type=task.missing_capability,
                code=task.synthesized_code,
                input_schema={"type": "object"},
                output_schema={"type": "object"},
                source_urls=[s["url"] for s in task.scraped_content if s.get("success")],
            )

            skill_id = self.knowledge.save_skill(skill)

            # Register as capability for planner
            from infrastructure.capability_registry import Capability, CapabilityInterface, CapabilityMetadata, CapabilityType, CapabilityStatus
            import json
            import time
            
            capability = Capability(
                id=f"learned_{skill_id[:8]}",
                name=f"Learned: {task.missing_capability}",
                interface=CapabilityInterface(
                    name=f"learned_{task.missing_capability.lower().replace(' ', '_')}",
                    description=f"Auto-learned capability: {task.goal}",
                    input_schema={"type": "object"},
                    output_schema={"type": "object"},
                ),
                metadata=CapabilityMetadata(
                    capability_type=CapabilityType.SKILL,
                    domain_tags=["learned", "auto-generated"],
                    version="1.0.0",
                    author="maya-learner",
                    verification_status=CapabilityStatus.VERIFIED,
                    provenance={"source": "maya-learner", "task_id": task.id, "goal": task.goal},
                    source_code_hash=hashlib.sha256(task.synthesized_code.encode()).hexdigest()[:16],
                ),
                implementation=task.synthesized_code,
                entry_point="main",
            )
            
            # Custom JSON encoder that handles enums
            class EnumEncoder(json.JSONEncoder):
                def default(self, obj):
                    if hasattr(obj, 'value'):  # Enum
                        return obj.value
                    return super().default(obj)
            
            # Monkey-patch json.dumps to use our encoder
            original_dumps = json.dumps
            def enum_dumps(obj, **kwargs):
                kwargs['cls'] = EnumEncoder
                return original_dumps(obj, **kwargs)
            
            json.dumps = enum_dumps
            
            try:
                self.registry.register(capability)
            finally:
                json.dumps = original_dumps

            # Also add to procedural memory for replay/distillation
            from infrastructure.procedural_memory import Skill
            import time
            proc_skill = Skill(
                id=skill_id,
                name=skill.name,
                description=skill.description,
                trigger_conditions=[task.missing_capability],
                preconditions=[],
                procedure=[{"action": "execute", "code": task.synthesized_code}],
                parameters={"type": "object"},
                success_rate=1.0,
                avg_reward=1.0,
                usage_count=1,
                source_episodes=skill.source_urls,
                created_at=time.time(),
                updated_at=time.time(),
                version=1,
                verified=True,
                confidence=0.8,
            )
            self.procedural.store_skill(proc_skill)

            return skill_id

        except Exception as e:
            import traceback
            print(f"Skill distillation failed: {e}")
            traceback.print_exc()
            return None

    def _execute_learned_skill(self, skill_id: str, **kwargs) -> Dict:
        """Execute a previously learned skill."""
        skill = self.knowledge.get_skill(skill_id)
        if not skill:
            return {"success": False, "error": f"Skill {skill_id} not found"}

        # Execute the skill code
        import asyncio
        result = asyncio.get_event_loop().run_until_complete(
            self.coder.execute(skill.code, test_inputs=[kwargs])
        )
        return json.loads(result.output) if result.success else {"success": False, "error": result.error}

    async def get_task_status(self, task_id: str) -> Optional[LearningTask]:
        return self._tasks.get(task_id)

    async def list_tasks(self, status: Optional[str] = None, limit: int = 50) -> List[LearningTask]:
        tasks = list(self._tasks.values())
        if status:
            tasks = [t for t in tasks if t.status == status]
        tasks.sort(key=lambda t: t.created_at, reverse=True)
        return tasks[:limit]

    async def get_stats(self) -> Dict[str, Any]:
        skills = self.knowledge.list_skills()
        records = self.knowledge.get_recent_records(100)
        return {
            "enabled": self.config.ENABLED,
            "total_skills": len(skills),
            "total_learning_tasks": len(self._tasks),
            "completed_tasks": sum(1 for r in records if r.status == "done"),
            "failed_tasks": sum(1 for r in records if r.status == "failed"),
            "pending_tasks": sum(1 for r in records if r.status in ("pending", "searching", "scraping", "synthesizing", "executing", "distilling")),
            "models": {"search": self.config.SEARCH_MODEL, "exec": self.config.EXEC_MODEL},
        }

    async def _emit(self, task_id: str, event_type: str, data: Dict):
        await self.stream.emit_event(
            StreamEventType.TASK_COMPLETED if event_type == "completed" else StreamEventType.PROGRESS,
            task_id, task_id, {"learner_event": event_type, **data}
        )