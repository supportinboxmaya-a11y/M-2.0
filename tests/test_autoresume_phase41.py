"""Phase 41 tests — automatic resume of incomplete goals across restarts.

Policy under test:
  - resume_incomplete() defaults to propose-only unless MAYA_AUTO_RESUME.
  - With execute=True, only previously-ACTIVE goals re-execute;
    SUSPENDED/BLOCKED goals never auto-execute.
  - Every resumed goal writes an auto_resume audit row; method never raises.
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
from infrastructure.cognitive_kernel import CognitiveKernel, GoalStatus  # noqa: E402


def _fresh_kernel() -> CognitiveKernel:
    d = Path(tempfile.mkdtemp(prefix="maya_p41_"))
    ck.COG_KERNEL_DB = str(d / "kernel.db")
    ck.CHECKPOINT_DIR = d / "checkpoints"
    k = CognitiveKernel()
    executed = []

    def executor(description, ctx, **opts):
        executed.append(description)
        return {"success": True, "result": f"did: {description[:30]}"}

    k.register_executor(executor)
    k._executed = executed
    return k


def _seed(k: CognitiveKernel):
    active = k.create_goal("active goal mid-flight when process died")
    active.status = GoalStatus.ACTIVE
    k._save_goal(active)
    k.goals[active.id] = active
    suspended = k.create_goal("suspended proposal awaiting approval")
    suspended.status = GoalStatus.SUSPENDED
    k._save_goal(suspended)
    blocked = k.create_goal("blocked goal that failed earlier")
    blocked.status = GoalStatus.BLOCKED
    k._save_goal(blocked)
    return [active.id, suspended.id, blocked.id]


def test_default_is_propose_only_without_env_flag():
    old = os.environ.pop("MAYA_AUTO_RESUME", None)
    try:
        k = _fresh_kernel()
        ids = _seed(k)
        results = k.resume_incomplete()
        assert len(results) == 3
        assert all(r["auto_executed"] is False for r in results)
        assert all(r.get("executed") is not True for r in results)
        assert k._executed == []
    finally:
        if old is not None:
            os.environ["MAYA_AUTO_RESUME"] = old


def test_auto_execute_only_previously_active_goals():
    k = _fresh_kernel()
    ids = _seed(k)
    results = k.resume_incomplete(execute=True)
    by_id = {r["goal_id"]: r for r in results}
    assert by_id[ids[0]]["auto_executed"] is True
    assert by_id[ids[0]]["success"] is True
    assert by_id[ids[1]]["auto_executed"] is False
    assert by_id[ids[2]]["auto_executed"] is False
    # exactly one real execution — the previously-ACTIVE goal
    assert len(k._executed) == 1


def test_audit_rows_written_and_method_never_raises():
    k = _fresh_kernel()
    _seed(k)
    results = k.resume_incomplete(execute=True)
    audits = [a["event_type"] for a in k.get_recent_audit(100)]
    assert audits.count("auto_resume") == 3


def test_respects_max_goals_and_skips_completed():
    k = _fresh_kernel()
    ids = _seed(k)
    k.update_goal(ids[2], status=GoalStatus.COMPLETED)
    results = k.resume_incomplete(max_goals=1)
    assert len(results) == 1
    assert results[0]["goal_id"] in (ids[0], ids[1])


def test_env_flag_drives_execute_default():
    os.environ["MAYA_AUTO_RESUME"] = "true"
    try:
        k = _fresh_kernel()
        ids = _seed(k)
        results = k.resume_incomplete()
        by_id = {r["goal_id"]: r for r in results}
        assert by_id[ids[0]]["auto_executed"] is True
        assert len(k._executed) == 1
    finally:
        os.environ.pop("MAYA_AUTO_RESUME", None)


def test_scan_mode_covers_backlog_without_planning():
    """Regression (live push validation, 2026-08): get_incomplete_goals
    returns stale goals oldest-first, so a fixed max_goals cap hides
    freshly-created goals behind a big backlog; and re-planning every
    stale goal costs one LLM call each. plan_proposals=False is the
    cheap scan: full backlog visible, zero planning calls, statuses
    untouched, auto-execution policy unchanged."""
    old = os.environ.pop("MAYA_AUTO_RESUME", None)
    try:
        k = _fresh_kernel()
        # 60 stale suspended goals, then one fresh suspended goal LAST.
        for i in range(60):
            g = k.create_goal(f"stale backlog filler {i}")
            g.status = GoalStatus.SUSPENDED
            k._save_goal(g)
            k.goals[g.id] = g
        fresh = k.create_goal("fresh proposal created just now")
        fresh.status = GoalStatus.SUSPENDED
        k._save_goal(fresh)
        k.goals[fresh.id] = fresh

        results = k.resume_incomplete(execute=False,
                                      max_goals=len(k.goals) + 10,
                                      plan_proposals=False)
        by_id = {r["goal_id"]: r for r in results}
        assert len(results) == 61
        assert fresh.id in by_id, "fresh goal hidden behind stale backlog"
        assert by_id[fresh.id]["auto_executed"] is False
        # Scan touches nothing: no execution, status still suspended.
        assert k._executed == []
        assert k.get_goal(fresh.id).status == GoalStatus.SUSPENDED
    finally:
        if old is not None:
            os.environ["MAYA_AUTO_RESUME"] = old
