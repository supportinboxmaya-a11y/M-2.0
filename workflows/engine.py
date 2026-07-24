"""WorkflowEngine: supervised, resumable, parallel workflow runs."""
import asyncio
import time
import uuid

from agents import Orchestrator
from brain.task_graph import TaskGraph, TaskNode

from .checkpoint import MemoryCheckpoint

# Recovery strategy constants (imported lazily in __init__ to avoid a
# circular import: autonomous package imports WorkflowEngine).
RETRY, ALTERNATE, REPLAN, ABORT = "retry", "alternate", "replan", "abort"

_FINAL = ("done", "failed", "blocked", "skipped")


class WorkflowRun:
    """State of one workflow: graph + results + status. Serializable."""

    def __init__(self, goal: str, graph: TaskGraph, run_id: str | None = None):
        self.id = run_id or uuid.uuid4().hex[:12]
        self.goal = goal
        self.graph = graph
        self.results: list = []
        self.status = "pending"           # pending|running|completed|failed|cancelled
        self.created = time.time()
        self._cancel = False
        self.recovery_log: list = []      # every recovery decision made
        self.replan_count = 0
        self.replans_left = 2             # cap replans to avoid loops

    def cancel(self) -> None:
        self._cancel = True

    def to_state(self) -> dict:
        return {"id": self.id, "goal": self.goal, "status": self.status,
                "created": self.created, "results": self.results,
                "nodes": [n.to_dict() for n in self.graph.nodes.values()]}

    @classmethod
    def from_state(cls, state: dict) -> "WorkflowRun":
        g = TaskGraph()
        # two passes: create nodes, then wire deps (add() validates deps exist)
        raw = state.get("nodes", [])
        for nd in raw:
            g.nodes[nd["id"]] = TaskNode(nd["description"], tool=nd.get("tool"),
                                         agent=nd.get("agent"), node_id=nd["id"])
        for nd in raw:
            node = g.nodes[nd["id"]]
            node.depends_on = list(nd.get("depends_on", []))
            node.state = nd.get("state", "pending")
            node.attempts = nd.get("attempts", 0)
            node.error = nd.get("error")
            if node.state == "running":   # crashed mid-step -> retry it
                node.state = "pending"
        run = cls(state["goal"], g, run_id=state["id"])
        run.results = list(state.get("results", []))
        run.status = "pending"
        return run


class WorkflowEngine:
    def __init__(self, orchestrator: Orchestrator | None = None,
                 checkpoint=None, max_rounds: int = 30,
                 recovery=None):
        self.orch = orchestrator or Orchestrator()
        self.checkpoint = checkpoint or MemoryCheckpoint()
        self.max_rounds = max_rounds
        self.runs: dict[str, WorkflowRun] = {}
        # Recovery intelligence: classifies failures and decides how to
        # recover (retry with backoff / alternate approach / replan / abort).
        if recovery is None:
            from autonomous.recovery import RecoveryStrategy
            recovery = RecoveryStrategy()
        self.recovery = recovery

    # ── pipeline: goal → plan → assign ──
    def create(self, goal: str, conditions: dict | None = None) -> WorkflowRun:
        planned = self.orch.plan(goal)
        run = WorkflowRun(goal, planned["graph"])
        run.conditions = conditions or {}
        self.runs[run.id] = run
        self.checkpoint.save(run.id, run.to_state())
        return run

    def resume(self, run_id: str) -> WorkflowRun | None:
        state = self.checkpoint.load(run_id)
        if state is None:
            return None
        run = WorkflowRun.from_state(state)
        run.conditions = {}
        self.runs[run.id] = run
        return run

    # ── execution loop ──
    async def execute(self, run: WorkflowRun, execute_fn,
                      retry_failed: int = 1) -> dict:
        """execute_fn(agent, node) -> (output, verified) — sync or async.

        Parallel: all ready nodes run concurrently each round.
        Conditional: run.conditions[node_description_substring] -> callable(results)->bool
        Cancellation: run.cancel() stops before the next round.
        Checkpoint: saved after every round.
        """
        run.status = "running"
        # retry_failed is the caller's explicit retry budget. The recovery
        # module's max_attempts only caps it — never overrides downwards.
        budget = min(retry_failed, self.recovery.max_attempts - 1)
        retries_left = {nid: budget for nid in run.graph.nodes}
        for _ in range(self.max_rounds):
            if run._cancel:
                run.status = "cancelled"
                break
            ready = run.graph.ready()
            if not ready:
                # recovery stage: inspect each failure and act on its kind
                failed = [n for n in run.graph.nodes.values()
                          if n.state == "failed"]
                actionable = [n for n in failed
                              if retries_left.get(n.id, 0) > 0]
                if not actionable:
                    break
                replan_needed = False
                for n in actionable:
                    attempt = budget - retries_left[n.id] + 1
                    decision = self.recovery.decide(
                        n.id, n.error or "", attempt,
                        goal=run.goal, description=n.description)
                    run.recovery_log.append({"node": n.id, **decision.to_dict()})
                    if decision.strategy == ABORT:
                        retries_left[n.id] = 0            # stop trying this node
                        continue
                    retries_left[n.id] -= 1
                    if decision.strategy == REPLAN:
                        replan_needed = True
                    # Feed the reflection back so the next attempt adapts.
                    n.recovery_note = decision.reflection
                    if decision.backoff_seconds > 0:
                        await asyncio.sleep(min(decision.backoff_seconds, 5.0))
                    run.graph.retry(n.id)
                if replan_needed and run.replans_left > 0:
                    run.replans_left -= 1
                    self._replan(run, retries_left)
                continue
            # conditional skip
            for node in list(ready):
                cond = self._condition_for(run, node)
                if cond is not None and not cond(run.results):
                    node.state = "skipped" if hasattr(node, "state") else node.state
                    run.graph.nodes[node.id].state = "done"   # treated as satisfied
                    run.results.append({"node": node.id, "ok": True,
                                        "skipped": True, "confidence": 1.0})
                    ready.remove(node)
            # parallel execution of the remaining ready set
            await asyncio.gather(*[
                self._run_node(run, node, execute_fn) for node in ready])
            self.checkpoint.save(run.id, run.to_state())
        prog = run.graph.progress()
        if run.status != "cancelled":
            run.status = "completed" if prog["finished"] else "failed"
        self.checkpoint.save(run.id, run.to_state())
        conf = self.orch.brain.plan_confidence(
            [r for r in run.results if "confidence" in r]) if run.results else \
            {"plan_confidence": 0.0, "should_replan": True}
        return {"run_id": run.id, "status": run.status, "progress": prog,
                "results": run.results, "recovery_log": run.recovery_log,
                "replans_used": run.replan_count, **conf}

    def _replan(self, run: WorkflowRun, retries_left: dict) -> None:
        """Re-plan the remaining goal when a step's premise was invalid.
        New nodes are appended and get their own retry budget; already
        completed work is preserved."""
        run.replan_count += 1
        try:
            done = [n.description for n in run.graph.nodes.values()
                    if n.state == "done"]
            planned = self.orch.plan(run.goal)
            for nid, node in planned["graph"].nodes.items():
                if node.description in done or nid in run.graph.nodes:
                    continue
                run.graph.nodes[nid] = node
                retries_left[nid] = self.recovery.max_attempts
        except Exception:
            pass   # replanning is best-effort; the run continues regardless

    async def _run_node(self, run: WorkflowRun, node, execute_fn) -> None:
        agent = self.orch.registry.get(node.agent) or self.orch.registry.route(
            node.description, tool=node.tool)
        run.graph.start(node.id)
        if agent is None or not agent.can_use(node.tool):
            run.graph.fail(node.id, "permission denied")
            run.results.append({"node": node.id, "ok": False, "confidence": 0.0,
                                "review": {"acceptable": False,
                                           "issues": ["permission denied"],
                                           "suggestion": None}})
            return
        try:
            if asyncio.iscoroutinefunction(execute_fn):
                output, verified = await execute_fn(agent, node)
            else:
                output, verified = await asyncio.to_thread(execute_fn, agent, node)
            node.recovery_note = ""   # consumed for this attempt
            rec = self.orch.brain.record(run.graph, node.id, output, verified, run.goal)
            if rec["ok"]:
                agent.record_success()
            else:
                agent.record_error(str(rec["review"]["issues"]))
            run.results.append(rec)
        except Exception as e:
            run.graph.fail(node.id, str(e))
            agent.record_error(str(e))
            run.results.append({"node": node.id, "ok": False, "confidence": 0.0,
                                "review": {"acceptable": False, "issues": [str(e)],
                                           "suggestion": None}})

    @staticmethod
    def _condition_for(run, node):
        for key, fn in getattr(run, "conditions", {}).items():
            if key.lower() in node.description.lower():
                return fn
        return None
