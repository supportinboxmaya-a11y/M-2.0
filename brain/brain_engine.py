"""
BrainEngine — Planning intelligence for Maya 3.0.

Orchestrates the Phase 3 sub-modules:
  - GoalAnalyzer  → decompose a goal into steps
  - TaskGraph     → build a DAG of those steps
  - ConfidenceScorer → score step / plan quality
  - Reflector     → critique results before returning them

All sub-modules are stdlib-only and have no I/O.  BrowserTool safe.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from .goal_analyzer import GoalAnalyzer
from .task_graph import TaskGraph, TaskNode
from .confidence import ConfidenceScorer
from .reflection import Reflector


class BrainEngine:
    """Goal decomposition, step graph building, execution recording,
    confidence scoring, and reflection — the core planning intelligence."""

    def __init__(self, llm_fn=None, router=None):
        self.analyzer = GoalAnalyzer()
        self.scorer = ConfidenceScorer()
        self.reflector = Reflector(llm_fn)
        self._router = router

    # ── Goal analysis ────────────────────────────────────────────────

    def analyze(self, goal: str) -> Dict[str, Any]:
        """Decompose *goal* into structured steps with tool hints."""
        return self.analyzer.analyze(goal)

    # ── Graph building ───────────────────────────────────────────────

    def build_graph(self, steps: List[Dict]) -> TaskGraph:
        """Convert a list of step dicts (with 'description', 'tool',
        and optional 'depends_on') into a TaskGraph DAG.

        Each dict may also carry an 'agent' key for the orchestrator.
        """
        graph = TaskGraph()
        for i, s in enumerate(steps):
            deps = s.get("depends_on")
            if deps is None:
                # Sequential: each step depends on the previous one
                deps = [steps[i - 1].get("_node_id")] if i > 0 else []
            else:
                deps = [steps[d].get("_node_id", str(d)) if isinstance(d, int) else d
                        for d in deps]

            node = TaskNode(
                description=s.get("description", ""),
                tool=s.get("tool"),
                agent=s.get("agent"),
                depends_on=deps,
            )
            graph.add(node)
            s["_node_id"] = node.id
        return graph

    # ── Execution recording ──────────────────────────────────────────

    def record(self, graph: TaskGraph, node_id: str,
               output: str, verified: bool = False,
               goal: str = "") -> Dict[str, Any]:
        """Record a step result, run reflection, and return a structured
        result dict with confidence and recovery info."""
        node = graph.nodes.get(node_id)
        if not node:
            return {"ok": False, "error": f"Unknown node: {node_id}"}

        confidence = self.scorer.score_step(output, verified=verified,
                                            attempts=node.attempts)
        reflection = self.reflector.critique(goal, output)

        # The executor's verified flag is the primary gate. Reflection is
        # advisory — it provides issues for debugging and suggestion text
        # but does not override a verified, non-empty result.
        ok = verified
        fallback_triggered = not ok and node.attempts > 1
        should_abort = fallback_triggered and confidence < 0.2

        if ok:
            graph.complete(node_id, output)
        else:
            graph.fail(node_id, error=reflection.get("suggestion") or
                       reflection.get("issues", ["unknown"])[0])

        return {
            "ok": ok,
            "node": node_id,
            "confidence": confidence,
            "output": output[:2000],
            "review": reflection,
            "fallback_triggered": fallback_triggered,
            "recovery": {
                "should_abort": should_abort,
                "message": f"Node {node_id} failed after {node.attempts} attempts"
                           if fallback_triggered else "",
                "new_steps": [],
                "reason": f"Confidence {confidence} too low, aborting"
                          if should_abort else "",
            } if fallback_triggered or not ok else {},
        }

    # ── Plan confidence ──────────────────────────────────────────────

    def plan_confidence(self, results: List[Dict]) -> Dict[str, Any]:
        """Score the whole plan from individual step results."""
        scores = [r.get("confidence", 0.0) for r in results]
        plan_score = self.scorer.score_plan(scores)
        return {
            "plan_confidence": plan_score,
            "should_replan": self.scorer.should_replan(plan_score),
            "step_count": len(results),
        }
