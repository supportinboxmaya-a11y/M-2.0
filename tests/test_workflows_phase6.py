"""Phase 6 workflow engine tests — offline, async."""
import asyncio, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from workflows import WorkflowEngine, MemoryCheckpoint
from workflows.engine import WorkflowRun

GOAL = "Search the web for news, then write a python script to save results to a file"


def ok_exec(agent, node):
    return f"{agent.name} completed {node.description} successfully", True


def test_full_pipeline():
    e = WorkflowEngine()
    run = e.create(GOAL)
    rep = asyncio.run(e.execute(run, ok_exec))
    assert rep["status"] == "completed" and rep["progress"]["finished"]
    assert rep["plan_confidence"] > 0.7
    print("PASS full_pipeline")


def test_parallel_execution():
    e = WorkflowEngine()
    # independent nodes: build graph manually via orchestrator brain
    steps = [{"description": f"task {i}", "tool": None, "depends_on": []} for i in range(3)]
    g = e.orch.brain.build_graph(steps)
    run = WorkflowRun("three parallel tasks", g)
    run.conditions = {}
    e.runs[run.id] = run
    async def slow_exec(agent, node):
        await asyncio.sleep(0.15)
        return "done successfully", True
    t0 = time.time()
    rep = asyncio.run(e.execute(run, slow_exec))
    elapsed = time.time() - t0
    assert rep["status"] == "completed"
    assert elapsed < 0.4, f"not parallel: {elapsed:.2f}s"       # 3×0.15 serial ≈ 0.45+
    print(f"PASS parallel ({elapsed:.2f}s for 3x0.15s tasks)")


def test_conditional_skip():
    e = WorkflowEngine()
    run = e.create(GOAL, conditions={"write a python": lambda results: False})
    rep = asyncio.run(e.execute(run, ok_exec))
    assert rep["status"] == "completed"
    assert any(r.get("skipped") for r in rep["results"])
    print("PASS conditional_skip")


def test_cancellation():
    e = WorkflowEngine()
    run = e.create(GOAL)
    async def cancelling_exec(agent, node):
        run.cancel()                      # cancel after the first node
        return "done successfully", True
    rep = asyncio.run(e.execute(run, cancelling_exec))
    assert rep["status"] == "cancelled" and not rep["progress"]["finished"]
    print("PASS cancellation")


def test_checkpoint_and_resume():
    cp = MemoryCheckpoint()
    e = WorkflowEngine(checkpoint=cp)
    run = e.create(GOAL)
    async def first_then_crash(agent, node):
        if "search" in node.description:
            return "search done successfully", True
        raise RuntimeError("power cut!")
    rep = asyncio.run(e.execute(run, first_then_crash, retry_failed=0))
    assert rep["status"] == "failed"
    assert run.id in cp.list()
    # resume in a "new process"
    e2 = WorkflowEngine(checkpoint=cp)
    run2 = e2.resume(run.id)
    assert run2 is not None
    done_before = sum(1 for n in run2.graph.nodes.values() if n.state == "done")
    assert done_before >= 1                                     # first step preserved
    for n in run2.graph.nodes.values():                         # unblock failed for retry
        if n.state == "failed":
            run2.graph.retry(n.id)
    rep2 = asyncio.run(e2.execute(run2, ok_exec))
    assert rep2["status"] == "completed"
    print("PASS checkpoint_resume")


def test_retry_stage():
    e = WorkflowEngine()
    calls = {"n": 0}
    def flaky(agent, node):
        if "search" in node.description:
            calls["n"] += 1
            if calls["n"] == 1:
                return "error failed traceback", False          # first attempt fails
        return "completed successfully", True
    run = e.create(GOAL)
    rep = asyncio.run(e.execute(run, flaky, retry_failed=1))
    assert rep["status"] == "completed" and calls["n"] == 2
    print("PASS retry_stage")


if __name__ == "__main__":
    test_full_pipeline(); test_parallel_execution(); test_conditional_skip()
    test_cancellation(); test_checkpoint_and_resume(); test_retry_stage()
    print("\nAll Phase 6 workflow tests passed!")
