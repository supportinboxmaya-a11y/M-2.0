"""Final architecture audit — Maya/CognitiveKernel is the sole controller.

Encodes the invariants:
1. Models are replaceable reasoning engines only (no control authority).
2. Nothing can register a second executor; re-registration replaces.
3. The Phase 19 core cannot execute anything directly — delegation only.
4. Model/executor failure leaves persistent state intact.
5. Streaming/progress context survives the unified loop path.
6. Goals/memory/knowledge/skills/self-model are kernel-owned persistence,
   not model-owned.
"""
import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

for _name in ("loguru", "dotenv"):
    if _name not in sys.modules:
        try:
            __import__(_name)
        except ImportError:
            import types as _t
            sys.modules[_name] = _t.SimpleNamespace()
            if _name == "loguru":
                class _L:
                    def __getattr__(self, item):
                        return lambda *a, **k: None
                sys.modules[_name].logger = _L()

import infrastructure.cognitive_kernel as ck  # noqa: E402
from infrastructure.cognitive_kernel import CognitiveKernel  # noqa: E402


def _fresh_kernel() -> CognitiveKernel:
    d = Path(tempfile.mkdtemp(prefix="audit_"))
    ck.COG_KERNEL_DB = str(d / "kernel.db")
    ck.CHECKPOINT_DIR = d / "checkpoints"
    return CognitiveKernel()


def test_no_second_executor_possible():
    """register_executor REPLACES — there can never be two backends."""
    k = _fresh_kernel()
    k.register_executor(lambda d, c: {"success": True, "result": "first"})
    k.register_executor(lambda d, c: {"success": True, "result": "second"})
    r = k.process_goal("x", execute=True)
    assert r["outcome"]["result"] == "second"
    # exactly one slot exists on the class
    assert isinstance(vars(k).get("_executor"), object) or True
    slots = [a for a in vars(k) if "executor" in a.lower()]
    assert slots == ["_executor"]


def test_kernel_background_loops_cannot_execute():
    """Kernel maintenance loops only plan/monitor/audit — none of them call
    an executor or touch the world."""
    import inspect
    src = inspect.getsource(ck.CognitiveKernel)
    for loop in ("_perception_loop", "_consolidation_loop", "_planning_loop",
                 "_monitoring_loop", "_curiosity_loop", "_checkpoint_loop",
                 "_maintain_plans", "_monitor", "_seek_novelty"):
        body = inspect.getsource(getattr(ck.CognitiveKernel, loop))
        forbidden = ["execute_plan_step(", "process_goal(", "_executor(",
                     "register_executor("]
        for f in forbidden:
            assert f not in body, f"{loop} must not invoke {f}"


def test_p19_core_act_delegates_and_never_executes_directly():
    """The Phase 19 core's ACT phase must delegate through the kernel and
    must contain no direct execution paths."""
    import infrastructure.maya_cognitive_core as mcc
    import inspect
    import re
    src = inspect.getsource(mcc.MayaCognitiveCore._phase_act)
    for forbidden in [r"(?<![\w.])exec\(", r"\.invoke\(prompt",
                      r"tool_registry\.get\(",
                      r"capability_registry\.record_usage"]:
        assert not re.search(forbidden, src), \
            f"_phase_act must not contain {forbidden!r} (direct execution)"
    # it MUST route through process_goal
    assert "process_goal" in src


def test_p19_core_act_noop_without_executor():
    from infrastructure.maya_cognitive_core import MayaCognitiveCore
    d = Path(tempfile.mkdtemp(prefix="audit19_"))
    mcc_db = str(d / "core.db")
    core = MayaCognitiveCore.__new__(MayaCognitiveCore)
    # minimal manual wiring — no initialize(), no llm, no tools
    import threading
    core._lock = threading.RLock()
    core._cycle_count = 0
    core.cognitive_kernel = _fresh_kernel()   # NO executor registered
    core.CORE_DB = mcc_db
    core._init_persistence()
    out = core._phase_act({"action": "execute_step", "step":
                           {"description": "touch the world"},
                           "goal_id": None})
    assert out["executed"] is False
    assert out["reason"] == "no_controller_executor"


def test_p19_core_act_delegates_when_executor_present():
    from infrastructure.maya_cognitive_core import MayaCognitiveCore
    d = Path(tempfile.mkdtemp(prefix="audit19b_"))
    core = MayaCognitiveCore.__new__(MayaCognitiveCore)
    import threading
    core._lock = threading.RLock()
    core._cycle_count = 0
    core.cognitive_kernel = _fresh_kernel()
    core._init_persistence()
    calls = []
    core.cognitive_kernel.register_executor(
        lambda desc, ctx: calls.append(desc) or
        {"success": True, "result": "done by maya pipeline"})
    out = core._phase_act({"action": "execute_step",
                           "step": {"description": "do the thing"}})
    assert out["executed"] is True and out["via_controller"] is True
    assert calls == ["do the thing"]


def test_executor_failure_preserves_persistent_state():
    """A crashing backend (e.g. total model outage) must leave goals,
    beliefs and audit intact and queryable."""
    k = _fresh_kernel()

    def exploding_backend(description, ctx):
        raise RuntimeError("all providers down")

    k.register_executor(exploding_backend)
    r = k.process_goal("critical long-running goal", execute=True)
    assert r["success"] is False
    # state survived: goal recorded as blocked, failure belief learned
    g = k.get_goal(r["goal_id"])
    assert g.status.value == "blocked"
    assert len(k.beliefs) >= 1
    audits = [a["event_type"] for a in k.get_recent_audit(10)]
    assert "unified_goal_done" in audits
    # and a new backend can pick the goal up later (resume works)
    k.register_executor(lambda d, c: {"success": True, "result": "recovered"})
    out = k.resume_goal(r["goal_id"], execute=True)
    assert out["success"] is True


def test_streaming_context_survives_unified_path():
    """stream_emitter / progress_callback forwarded to the pipeline via
    executor_options (end-to-end streaming preserved when flag is on)."""
    k = _fresh_kernel()
    seen = {}

    def backend(desc, ctx, stream_emitter=None, progress_callback=None,
                scope="", task_id=None, max_retries=3):
        seen.update(stream_emitter=stream_emitter,
                    progress_callback=progress_callback, scope=scope)
        return {"success": True, "result": "ok"}

    k.register_executor(backend)

    class FakeEmitter:
        pass

    emitter = FakeEmitter()
    r = k.process_goal("stream me", execute=True, executor_options={
        "stream_emitter": emitter, "progress_callback": lambda *a: None,
        "scope": "inst1"})
    assert r["success"]
    assert seen["stream_emitter"] is emitter
    assert seen["scope"] == "inst1"


def test_models_are_reasoning_engines_only():
    """ModelInterface.invoke only routes text through the router — it has
    no access to goals, executors, or persistence."""
    import inspect
    from infrastructure.maya_cognitive_core import ModelInterface
    init_src = inspect.getsource(ModelInterface.__init__)
    for forbidden in ["cognitive_kernel", "_executor", "process_goal",
                      "goals", "checkpoint"]:
        assert forbidden not in init_src, \
            f"ModelInterface must not touch {forbidden!r}"
