"""AutonomousMaya: the full self-running loop (spec Phase 7)."""
import asyncio
import time

from workflows import WorkflowEngine

from .executor_bridge import ExecutorBridge
from .improver import OutputImprover
from .reporter import ReportGenerator


class AutonomousMaya:
    def __init__(self, framework=None, llm_fn=None,
                 engine: WorkflowEngine | None = None,
                 approve_dangerous: bool = False, retry_failed: int = 1):
        self.engine = engine or WorkflowEngine()
        self.bridge = ExecutorBridge(framework, llm_fn, approve_dangerous)
        self.improver = OutputImprover(llm_fn)
        self.reporter = ReportGenerator()
        self.retry_failed = retry_failed

    async def run(self, goal: str) -> dict:
        """Plan independently → execute tools → verify → retry → improve → report."""
        started = time.time()
        run = self.engine.create(goal)
        result = await self.engine.execute(run, self.bridge,
                                           retry_failed=self.retry_failed)
        # improve the final combined output before returning (spec: improve outputs)
        outputs = [str(n.result) for n in run.graph.nodes.values()
                   if n.state == "done" and n.result]
        combined = "\n".join(outputs)
        improved = self.improver.improve(goal, combined) if combined else \
            {"output": "", "improved": False, "rounds": [], "acceptable": False}
        report = self.reporter.generate(goal, result, improved["output"], started)
        return {"run_id": run.id, "status": result["status"],
                "progress": result["progress"],
                "plan_confidence": result["plan_confidence"],
                "output": improved["output"],
                "improvement": {"improved": improved["improved"],
                                "acceptable": improved["acceptable"]},
                "report": report}

    def run_sync(self, goal: str) -> dict:
        return asyncio.run(self.run(goal))
