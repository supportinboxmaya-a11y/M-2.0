"""BrainEngine facade: analyze -> graph -> execute-loop helpers.

Adapts the EXISTING planner's plan format (list of steps) into a
TaskGraph, then drives confidence + reflection + replanning decisions.
"""
from .task_graph import TaskGraph, TaskNode
from .confidence import ConfidenceScorer
from .reflection import Reflector
from .goal_analyzer import GoalAnalyzer


class BrainEngine:
    def __init__(self, llm_fn=None):
        self.analyzer = GoalAnalyzer()
        self.scorer = ConfidenceScorer()
        self.reflector = Reflector(llm_fn)

    def analyze(self, goal: str) -> dict:
        return self.analyzer.analyze(goal)

    def build_graph(self, steps: list) -> TaskGraph:
        """steps: [{'description':…, 'tool':…, 'agent':…, 'depends_on':[idx…]}]
        depends_on uses indexes into the same list (planner-friendly)."""
        g = TaskGraph()
        ids = []
        for i, s in enumerate(steps):
            deps = [ids[j] for j in s.get("depends_on", []) if 0 <= j < len(ids)]
            if not deps and i > 0 and s.get("sequential", True) and not s.get("depends_on") == []:
                deps = [ids[i - 1]] if s.get("depends_on") is None else []
            node = g.add(TaskNode(s.get("description", f"step {i+1}"),
                                  tool=s.get("tool"), agent=s.get("agent"),
                                  depends_on=deps))
            ids.append(node.id)
        return g

    def record(self, graph: TaskGraph, node_id: str, output: str,
               verified: bool | None = None, goal: str = "") -> dict:
        """Score + reflect on a step result; complete or fail the node."""
        node = graph.nodes[node_id]
        conf = self.scorer.score_step(output, verified, node.attempts)
        review = self.reflector.critique(goal or node.description, output)
        if verified is False or (not review["acceptable"] and conf < 0.4):
            graph.fail(node_id, error="; ".join(review["issues"]) or "low confidence")
            ok = False
        else:
            graph.complete(node_id, result=output)
            ok = True
        return {"node": node_id, "ok": ok, "confidence": conf, "review": review}

    def plan_confidence(self, results: list) -> dict:
        scores = [r["confidence"] for r in results]
        plan = self.scorer.score_plan(scores)
        return {"plan_confidence": plan,
                "should_replan": self.scorer.should_replan(plan)}
