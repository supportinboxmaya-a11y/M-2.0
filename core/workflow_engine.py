
"""
Maya 2.0 - Ultra Workflow Engine
----------------------------------
Orchestrates the Plan -> Execute -> Verify -> Learn workflow.
"""

import asyncio
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

    def run(self, goal: str, max_retries: int = 3, progress_callback=None,
            stream_emitter=None, memory_hints: str = "") -> Dict:
        """`progress_callback(dict)` — if given, called live as the workflow
        moves through phases and steps (planning -> executing each step with
        its tool -> verifying), instead of the caller only finding out what
        happened after everything finishes. Never lets a callback error break
        the actual task.
        `stream_emitter` — if given, emits structured streaming events for real-time UI."""
        def notify(payload: Dict):
            if progress_callback:
                try:
                    progress_callback(payload)
                except Exception:
                    pass

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
            notify({"phase": "planning", "attempt": attempt + 1})
            if stream_emitter:
                import asyncio
                asyncio.run(stream_emitter.planning_started())

            # Memory context inject করি
            context = self._get_context(goal)
            # Caller-provided hints (kernel knowledge/skills/self-model)
            # are merged with Maya's own memory hints — neither is dropped.
            own_hints = self._get_memory_hints(goal)
            merged_hints = (
                memory_hints + "\n" if memory_hints else ""
            ) + own_hints
            past_tips = self._get_past_tips(goal)

            # Plan
            plan = self.planner.plan(
                goal,
                context=context,
                memory_hints=merged_hints,
                past_failures="\n".join(errors[-3:]) if errors else ""
            )
            steps = plan.get("steps", [])
            complexity = plan.get("complexity", "medium")
            log.info(f"Plan created: {len(steps)} steps, complexity={complexity}")
            print(f"Steps: {len(steps)} | Complexity: {complexity}")
            notify({"phase": "planned", "total_steps": len(steps), "complexity": complexity})
            if stream_emitter:
                asyncio.run(stream_emitter.plan_created(plan))

            if not steps:
                errors.append("Planner returned no steps")
                continue

            # Execute
            results = []
            failed_step = None

            for step in steps:
                notify({"phase": "step_start", "step": step.get("step"),
                        "description": step.get("description", ""), "tool": step.get("tool")})
                if stream_emitter:
                    asyncio.run(stream_emitter.step_started(step))
                result = self.executor.execute_step(step, context=context, previous_results=results, stream_emitter=stream_emitter)
                results.append(result)
                all_results.append(result)
                notify({"phase": "step_done", "step": result.get("step"),
                        "description": result.get("description", ""),
                        "tool": result.get("tool_used"), "success": result.get("success"),
                        "result": result.get("result")})
                if stream_emitter:
                    if result.get("success"):
                        asyncio.run(stream_emitter.step_completed(step, result))
                    else:
                        asyncio.run(stream_emitter.step_failed(step, result.get("error", "Unknown error")))

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
                        if stream_emitter:
                            asyncio.run(stream_emitter.recovery_action(recovery.get("recovery_strategy", ""), recovery))
                        if recovery.get("should_abort"):
                            log.error(f"Aborting: {recovery.get('reason')}")
                            break

                        # Execute the recovery steps (switch_tool / replan /
                        # simplify all produce concrete new_steps). Without
                        # this, recovery was computed then silently dropped.
                        recovered = False
                        for new_step in recovery.get("new_steps", [])[:3]:
                            if stream_emitter:
                                asyncio.run(stream_emitter.step_started(new_step))
                            rec_result = self.executor.execute_step(
                                new_step, context=context,
                                previous_results=results,
                                stream_emitter=stream_emitter)
                            all_results.append(rec_result)
                            if stream_emitter:
                                if rec_result.get("success"):
                                    asyncio.run(stream_emitter.step_completed(new_step, rec_result))
                                else:
                                    asyncio.run(stream_emitter.step_failed(
                                        new_step, rec_result.get("error", "Unknown error")))
                            if rec_result.get("success"):
                                recovered = True
                                errors.pop()  # the failure was repaired
                                results.append(rec_result)
                                break

                        # record outcome on the strategy history
                        try:
                            self.fallback.recovery_history[-1]["success"] = recovered
                        except Exception:
                            pass
                        if not recovered:
                            errors.append(f"recovery ({recovery.get('recovery_strategy')}) did not repair the failure")
                    break

            # Verify
            final_result = self._combine_results(results)
            notify({"phase": "verifying"})
            if stream_emitter:
                asyncio.run(stream_emitter.verification_started())
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

                if stream_emitter:
                    asyncio.run(stream_emitter.verification_completed(verification))
                    asyncio.run(stream_emitter.task_completed(final_result, quality))

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

            if stream_emitter:
                asyncio.run(stream_emitter.task_failed(missing))

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

        if stream_emitter:
            asyncio.run(stream_emitter.task_failed("Max retries reached"))

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
            if not r.get("success"):
                continue
            content = self._clean_text(r.get("result", ""))
            if content and content.strip():
                parts.append(content.strip())
        return "\n\n".join(parts)

    @staticmethod
    def _clean_text(value) -> str:
        """Turn a step result into clean human-readable text.

        Tool results are often dicts like {'success': True, 'output': '4\\n',
        'error': '', 'returncode': 0}. Surfacing that raw dict to the user is
        ugly, so pull out the meaningful field (the program's actual output /
        answer) instead of str(dict)."""
        if value is None:
            return ""
        if isinstance(value, str):
            return value
        if isinstance(value, (int, float, bool)):
            return str(value)
        if isinstance(value, dict):
            for key in ("output", "result", "reply", "message", "text", "content", "answer", "stdout"):
                v = value.get(key)
                if isinstance(v, str) and v.strip():
                    return v
                if isinstance(v, dict):
                    inner = WorkflowEngine._clean_text(v)
                    if inner.strip():
                        return inner
            err = value.get("error")
            if isinstance(err, str) and err.strip():
                return ""  # a failed sub-result: don't dump the raw error dict into the answer
            # nothing useful found — avoid dumping the raw dict
            return ""
        return str(value)
