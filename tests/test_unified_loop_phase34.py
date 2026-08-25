"""Phase 34 tests — Unified Cognitive Loop.

The CognitiveKernel is the single central controller: goals enter through
process_goal(), the registered executor (Maya's pipeline stand-in here) is
a capability the kernel uses, and every run leaves persistent traces
(goal, belief, working memory, audit).
"""
import os
import sys
import tempfile

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

from infrastructure.cognitive_kernel import CognitiveKernel  # noqa: E402


def _fresh_kernel() -> CognitiveKernel:
    """Kernel with its own empty SQLite db + checkpoint dir per test."""
    import infrastructure.cognitive_kernel as ck
    from pathlib import Path
    d = Path(tempfile.mkdtemp(prefix="maya_p34_"))
    ck.COG_KERNEL_DB = str(d / "kernel.db")
    ck.CHECKPOINT_DIR = d / "checkpoints"
    return CognitiveKernel()


def test_propose_only_when_no_executor():
    k = _fresh_kernel()
    assert not k.has_executor
    r = k.process_goal("Write a haiku about databases", execute=True)
    assert r["success"] is True
    assert r["executed"] is False
    assert r["mode"] == "no_executor"
    assert r["plan_id"]
    # goal must NOT be completed — it is suspended awaiting a backend
    g = k.get_goal(r["goal_id"])
    assert g.status.value == "suspended"


def test_execute_through_registered_executor():
    k = _fresh_kernel()
    calls = []

    def fake_pipeline(description, cognitive_context):
        calls.append((description, cognitive_context))
        return {"success": True, "result": f"done: {description}"}

    k.register_executor(fake_pipeline)
    r = k.process_goal("Summarize report X", execute=True)
    assert r["executed"] is True
    assert r["success"] is True
    assert len(calls) == 1
    # executor received grounded cognitive context
    desc, ctx = calls[0]
    assert isinstance(ctx.get("beliefs"), list)
    # goal completed + outcome recorded in memory/beliefs/audit
    g = k.get_goal(r["goal_id"])
    assert g.status.value == "completed"
    assert any("OUTCOME(ok)" in s.content for s in k.working_memory.values())
    beliefs = [b.proposition for b in k.beliefs.values()]
    assert any("Summarize report X" in p for p in beliefs)
    audits = [a["event_type"] for a in k.get_recent_audit(10)]
    assert "unified_goal_start" in audits and "unified_goal_done" in audits


def test_executor_failure_marks_blocked_and_learns():
    k = _fresh_kernel()

    def failing(description, cognitive_context):
        return {"success": False, "result": "boom"}

    k.register_executor(failing)
    r = k.process_goal("Do an impossible thing", execute=True)
    assert r["success"] is False
    g = k.get_goal(r["goal_id"])
    assert g.status.value == "blocked"
    beliefs = list(k.beliefs.values())
    assert any("failure" in b.proposition and b.confidence <= 0.4 for b in beliefs)


def test_single_controller_replaces_executor():
    """Only ONE executor may exist — re-registration replaces, never stacks."""
    k = _fresh_kernel()
    k.register_executor(lambda d, c: {"success": True, "result": "a"})
    k.register_executor(lambda d, c: {"success": True, "result": "b"})
    r = k.process_goal("Which backend runs?", execute=True)
    assert r["outcome"]["result"] == "b"


def test_status_reports_controller_state():
    k = _fresh_kernel()
    st = k.status()
    assert st["controller"]["has_executor"] is False
    k.register_executor(lambda d, c: {"success": True})
    assert k.status()["controller"]["has_executor"] is True
