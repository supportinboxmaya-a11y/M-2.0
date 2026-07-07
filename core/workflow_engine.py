"""
Maya 2.0 - Ultra Workflow Engine
----------------------------------
Orchestrates the Plan -> Execute -> Verify -> Learn workflow.
"""

from typing import Dict, List, Optional
from config.constants import TASK_RUNNING, TASK_DONE, TASK_FAILED, TASK_RETRYING
from maya_logging.logger import get_logger

log = get_logger("workflow")


class WorkflowEngine:
    """
    Plan -> Execute -> Verify -> Learn loop.
    - Memory context inject করে planning এ
    - Step results track করে
    - Failure recovery করে
    - Learning engine কে feed করে
    """

    def __init__(self, planner, executor, verifier, task_manager,
                 fallback_manager, memory_manager=None, learning_engine=None):
        self.planner = planner
        self.executor = executor
        self.verifier = verifier
        self.task_manager = task_manager
        self.fallback = fallback_manager
        self.memory = memory_manager
        self.learning = learning_engine

    def run(self, goal: str, max_retries: int = 3) -> Dict:
        task = self.task_manager.create_task(goal)
        log.info(f"Starting task: {goal[:80]}")
        print(f"\n{'='*60}")
        print(f"Goal: {goal}")
        print(f"{'='*60}")

        all_results = []
        tools_used = []
        errors = []

        for attempt in range(max_retries):
            print(f"\nPlanning... (attempt {attempt+1}/{max_retries})")
            self.task_manager.update_status(task.id, TASK_RUNNING)

            # Memory context inject করি
            context = self._get_context(goal)
            memory_hints = self._get_memory_hints(goal)
            past_tips = self._get_past_tips(goal)

            # Plan
            plan = self.planner.plan(
                goal,
                context=context,
                memory_hints=memory_hints,
                past_failures="\n".join(errors[-3:]) if errors else ""
            )
            steps = plan.get("steps", [])
            complexity = plan.get("complexity", "medium")
            log.info(f"Plan created: {len(steps)} steps, complexity={complexity}")
            print(f"Steps: {len(steps)} | Complexity: {complexity}")

            if not steps:
                errors.append("Planner returned no steps")
                continue

            # Execute
            results = []
            failed_step = None

            for step in steps:
                result = self.executor.execute_step(step, context=context, previous_results=results)
                results.append(result)
                all_results.append(result)

                # Track tools used
                tool = result.get("tool_used")
                if tool and tool != "llm" and tool not in tools_used:
                    tools_used.append(tool)

                # Memory এ step result add করি
                if self.memory:
                    self.memory.add_step_result(step, result)

                if not result.get("success"):
                    error = result.get("error", "Unknown error")
                    errors.append(error)
                    failed_step = step
                    log.warning(f"Step {step.get('step')} failed: {error[:80]}")

                    # Fallback
                    if self.fallback:
                        recovery = self.fallback.recover(goal, error, results, step, context)
                        if recovery.get("should_abort"):
                            log.error(f"Aborting: {recovery.get('reason')}")
                            break
                    break

            # Verify
            final_result = self._combine_results(results)
            verification = self.verifier.verify(goal, final_result, context=context)
            verdict = verification.get("verdict", "failure")
            quality = verification.get("quality_score", 0)

            log.info(f"Verification: {verdict} | quality={quality}")
            print(f"\nVerification: {verdict.upper()} | Quality: {quality}/10")

            if verification.get("success"):
                self.task_manager.update_status(task.id, TASK_DONE, result=final_result)

                # Learn
                if self.learning:
                    self.learning.learn(
                        goal=goal,
                        result=final_result,
                        success=True,
                        steps=results,
                        tools_used=tools_used
                    )

                # Memory এ save করি
                if self.memory:
                    self.memory.remember_task(goal, results, final_result, True, tools_used, errors)

                print(f"\nTask completed successfully!")
                return {
                    "success": True,
                    "result": final_result,
                    "task_id": task.id,
                    "quality_score": quality,
                    "attempts": attempt + 1,
                    "tools_used": tools_used,
                    "steps": all_results,
                }

            # Partial success হলেও কিছু return করি
            missing = verification.get("what_is_missing", "")
            print(f"\nVerification failed: {missing[:100]}")

            if attempt < max_retries - 1:
                self.task_manager.increment_retry(task.id)
                self.task_manager.update_status(task.id, TASK_RETRYING)
                log.info(f"Retrying... (attempt {attempt+2})")

        # All retries failed
        self.task_manager.update_status(task.id, TASK_FAILED, error="Max retries reached")

        if self.learning:
            self.learning.learn(
                goal=goal,
                result=final_result if 'final_result' in locals() else "",
                success=False,
                steps=all_results,
                errors=errors,
                tools_used=tools_used
            )

        if self.memory:
            self.memory.remember_task(goal, all_results, "", False, tools_used, errors)

        print(f"\nTask failed after {max_retries} attempts.")
        return {
            "success": False,
            "result": final_result if 'final_result' in locals() else "",
            "task_id": task.id,
            "attempts": max_retries,
            "errors": errors,
            "tools_used": tools_used,
            "steps": all_results,
        }

    def _get_context(self, goal: str) -> str:
        if not self.memory:
            return ""
        try:
            return self.memory.get_context()
        except:
            return ""

    def _get_memory_hints(self, goal: str) -> str:
        if not self.memory:
            return ""
        try:
            return self.memory.get_relevant_memories(goal, limit=3)
        except:
            return ""

    def _get_past_tips(self, goal: str) -> str:
        if not self.memory:
            return ""
        try:
            return self.memory.get_tips_for_goal(goal)
        except:
            return ""

    def _combine_results(self, results: List[Dict]) -> str:
        parts = []
        for r in results:
            if r.get("success") and r.get("result"):
                content = str(r.get("result", ""))
                if content.strip():
                    parts.append(content)
        return "\n\n".join(parts)
