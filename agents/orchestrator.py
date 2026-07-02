"""Orchestrator: goal -> brain graph -> agent assignment -> supervised run.

Execution is injected (execute_fn) so the orchestrator stays decoupled
from the existing executor and fully testable offline.
"""
from brain import BrainEngine

from .messaging import MessageBus
from .registry import AgentRegistry
from .roster import build_default_agents


class Orchestrator:
    def __init__(self, registry: AgentRegistry | None = None, llm_fn=None):
        self.registry = registry or self._default_registry()
        self.bus = MessageBus()
        self.brain = BrainEngine(llm_fn)
        self.llm_fn = llm_fn

    @staticmethod
    def _default_registry() -> AgentRegistry:
        r = AgentRegistry()
        for a in build_default_agents():
            r.register(a)
        return r

    def plan(self, goal: str) -> dict:
        """Analyze the goal, build the graph, assign agents. No execution."""
        analysis = self.brain.analyze(goal)
        steps = [{"description": sg, "tool": self._pick_tool(sg, analysis)}
                 for sg in analysis["sub_goals"]] or [{"description": goal, "tool": None}]
        graph = self.brain.build_graph(steps)
        assignments = {}
        for node in graph.nodes.values():
            agent = self.registry.route(node.description, node.agent, node.tool)
            node.agent = agent.name if agent else None
            assignments[node.id] = node.agent
        return {"analysis": analysis, "graph": graph, "assignments": assignments}

    def run(self, goal: str, execute_fn=None, max_rounds: int = 20) -> dict:
        """Supervised loop. execute_fn(agent, node) -> (output, verified).

        Defaults to each agent's LLM handle() when execute_fn is None.
        Permissions are enforced HERE and never bypassed.
        """
        planned = self.plan(goal)
        graph = planned["graph"]
        results = []
        for _ in range(max_rounds):
            ready = graph.ready()
            if not ready:
                break
            for node in ready:                       # parallel-ready set
                agent = self.registry.get(node.agent)
                graph.start(node.id)
                if agent is None or not agent.can_use(node.tool):
                    graph.fail(node.id, f"permission denied: {node.agent} cannot use {node.tool}")
                    if agent:
                        agent.record_error("permission denied")
                    results.append({"node": node.id, "ok": False,
                                    "confidence": 0.0,
                                    "review": {"acceptable": False,
                                               "issues": ["permission denied"],
                                               "suggestion": None}})
                    continue
                try:
                    if execute_fn:
                        output, verified = execute_fn(agent, node)
                    else:
                        output, verified = agent.handle(node.description,
                                                        llm_fn=self.llm_fn), None
                    rec = self.brain.record(graph, node.id, output, verified, goal)
                    if rec["ok"]:
                        agent.record_success()
                    else:
                        agent.record_error(str(rec["review"]["issues"]))
                    self.bus.send(agent.name, "orchestrator",
                                  {"node": node.id, "ok": rec["ok"]})
                    results.append(rec)
                except Exception as e:               # no silent failures
                    graph.fail(node.id, str(e))
                    agent.record_error(str(e))
                    results.append({"node": node.id, "ok": False, "confidence": 0.0,
                                    "review": {"acceptable": False,
                                               "issues": [str(e)], "suggestion": None}})
        conf = self.brain.plan_confidence(results) if results else \
            {"plan_confidence": 0.0, "should_replan": True}
        return {"goal": goal, "progress": graph.progress(),
                "results": results, **conf,
                "assignments": planned["assignments"],
                "graph": graph.to_dict()}

    @staticmethod
    def _pick_tool(sub_goal: str, analysis: dict) -> str | None:
        from brain.goal_analyzer import TOOL_HINTS
        low = sub_goal.lower()
        for tool, kws in TOOL_HINTS.items():
            if any(k in low for k in kws):
                return tool
        return None
