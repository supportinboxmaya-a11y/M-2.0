
"""
BrainEngine Facade: analyze -> graph -> execute-loop helpers.
Adapts the EXISTING planner's plan format into a TaskGraph, 
then drives confidence + reflection + replanning decisions with fallbacks.
"""

from brain.task_graph import TaskGraph, TaskNode
from brain.confidence import ConfidenceScorer
from brain.reflection import Reflector
from brain.goal_analyzer import GoalAnalyzer

class BrainEngine:
    def __init__(self, llm_fn=None, router=None):
        self.analyzer = GoalAnalyzer()
        self.scorer = ConfidenceScorer()
        self.reflector = Reflector(llm_fn)
        self.router = router
        self._fallback_mgr = None

    @property
    def fallback_mgr(self):
        """Lazy load FallbackManager to cleanly avoid circular imports."""
        if self._fallback_mgr is None:
            from core.fallback_manager import FallbackManager
            self._fallback_mgr = FallbackManager(planner=self, router=self.router)
        return self._fallback_mgr

    def analyze(self, goal: str) -> dict:
        return self.analyzer.analyze(goal)

    def build_graph(self, steps: list) -> TaskGraph:
        """
        steps: [{'description':..., 'tool':..., 'agent':..., 'depends_on':[idx...]}]
        Depends on uses indexes into the same list (planner-friendly).
        """
        g = TaskGraph()
        ids = []
        for i, s in enumerate(steps):
            deps = [ids[j] for j in s.get("depends_on", []) if 0 <= j < len(ids)]
            if not deps and i > 0 and s.get("sequential", True) and not s.get("depends_on") == []:
                deps = [ids[i - 1]] if s.get("depends_on") is None else []
            
            node = g.add(TaskNode(
                description=s.get("description", f"Step {i+1}"),
                tool=s.get("tool"),
                agent=s.get("agent"),
                depends_on=deps
            ))
            ids.append(node.id)
        return g

    def record(self, graph: TaskGraph, node_id: str, output: str, 
               verified: bool = None, goal: str = "") -> dict:
        """Score + reflect on a step result; complete or fail the node with fallback mitigation."""
        node = graph.nodes[node_id]
        conf = self.scorer.score_step(output, verified, node.attempts)
        review = self.reflector.critique(goal, node.description, output)
        
        if verified is False or (not review["acceptable"] and conf < 0.4):
            error_msg = ". ".join(review.get("issues", [])) or "low confidence"
            graph.fail(node_id, error=error_msg)
            
            # Active fallback recovery seamlessly triggered here
            completed_steps = [
                {"step": n.id, "description": n.description, "success": n.status == "completed", "result": n.output} 
                for n in graph.nodes.values()
            ]
            failed_step_dict = {"step": node.id, "description": node.description, "tool": node.tool, "agent": node.agent}
            
            recovery_action = self.fallback_mgr.recover(
                goal=goal, 
                error=error_msg, 
                completed_steps=completed_steps, 
                failed_step=failed_step_dict
            )
            
            return {
                "node": node_id, 
                "ok": False, 
                "confidence": conf, 
                "review": review,
                "fallback_triggered": True,
                "recovery": recovery_action
            }
        else:
            graph.complete(node_id, result=output)
            return {"node": node_id, "ok": True, "confidence": conf, "review": review, "fallback_triggered": False}

    def plan_confidence(self, results: list) -> dict:
        scores = [r["confidence"] for r in results]
        plan_conf = self.scorer.score_plan(scores)
        return {
            "plan_confidence": plan_conf,
            "should_replan": self.scorer.should_replan(plan_conf)
        }

    def replan(self, goal: str, error: str, completed_summary: str, failed_step: dict) -> dict:
        """Fallback callback to contextually inject a sub-routing mitigation graph branch."""
        simplified_step = {
            "description": f"Retry alternative route for: {failed_step.get('description')}",
            "tool": self.fallback_mgr._get_alternative_tool(failed_step.get("tool")),
            "agent": failed_step.get("agent"),
            "depends_on": []
        }
        return {
            "recovery_strategy": "inject_mitigation_nodes",
            "new_steps": [simplified_step]
        }
