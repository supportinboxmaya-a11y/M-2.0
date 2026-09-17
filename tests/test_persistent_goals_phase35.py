"""Phase 35 tests — persistent goal pursuit.

Goals survive kernel restarts (SQLite persistence + _load_state) and can be
listed and resumed through the unified loop. Resumption is propose-only by
default; execution is always explicit.
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


class _RestartableKernel:
    """Simulates a process restart: same db dir, brand-new kernel instance."""

    def __init__(self):
        self.dir = Path(tempfile.mkdtemp(prefix="maya_p35_"))

    def new(self) -> CognitiveKernel:
        ck.COG_KERNEL_DB = str(self.dir / "kernel.db")
        ck.CHECKPOINT_DIR = self.dir / "checkpoints"
        return CognitiveKernel()


def test_incomplete_goals_listing():
    r = _RestartableKernel()
    k = r.new()

    def ok(d, c):
        return {"success": True, "result": "done"}

    def fail(d, c):
        return {"success": False, "result": "nope"}

    k.register_executor(ok)
    k.process_goal("finishable goal", execute=True)
    k.register_executor(fail)
    k.process_goal("stuck goal", execute=True)
    k.process_goal("proposed only", execute=False)

    inc = k.get_incomplete_goals()
    descs = [g.description for g in inc]
    assert "stuck goal" in descs          # blocked -> incomplete
    assert "proposed only" in descs       # suspended -> incomplete
    assert "finishable goal" not in descs # completed


def test_goal_survives_restart_and_resumes_propose_only():
    r = _RestartableKernel()
    k1 = r.new()
    k1.register_executor(lambda d, c: {"success": False, "result": "crash"})
    res = k1.process_goal("multi-day research task", execute=True)
    gid = res["goal_id"]

    k2 = r.new()  # "restart": fresh instance over the same db
    # Production: Maya's boot re-registers the pipeline executor on the
    # singleton; simulate that here.
    k2.register_executor(lambda d, c: {"success": True, "result": "unused"})
    inc = k2.get_incomplete_goals()
    assert [g.id for g in inc] == [gid]

    out = k2.resume_goal(gid)  # default execute=False
    assert out["resumed"] is True
    assert out["executed"] is False
    assert out["mode"] == "propose_only"
    g = k2.get_goal(gid)
    assert g.status.value == "suspended"


def test_resume_with_execute_completes_goal():
    r = _RestartableKernel()
    k1 = r.new()
    k1.register_executor(lambda d, c: {"success": False, "result": "down"})
    gid = k1.process_goal("deploy the thing", execute=True)["goal_id"]

    k2 = r.new()
    calls = []
    k2.register_executor(lambda d, c: calls.append(d) or
                         {"success": True, "result": "redeployed"})
    out = k2.resume_goal(gid, execute=True)
    assert out["executed"] is True and out["success"] is True
    assert calls == ["deploy the thing"]
    g = k2.get_goal(gid)
    assert g.status.value == "completed"
    assert g.progress == 1.0


def test_cannot_resume_finished_or_unknown_goals():
    r = _RestartableKernel()
    k = r.new()
    k.register_executor(lambda d, c: {"success": True, "result": "ok"})
    done_id = k.process_goal("already finished", execute=True)["goal_id"]
    out = k.resume_goal(done_id, execute=True)
    assert out["success"] is False
    assert "already completed" in out["error"]
    out = k.resume_goal("nonexistent", execute=True)
    assert out["success"] is False


def test_resume_audited():
    r = _RestartableKernel()
    k1 = r.new()
    k1.register_executor(lambda d, c: {"success": False})
    gid = k1.process_goal("audited goal", execute=True)["goal_id"]
    k2 = r.new()
    k2.resume_goal(gid)
    starts = [a for a in k2.get_recent_audit(20)
              if a["event_type"] == "unified_goal_start"]
    assert any("resume" in a["details"] for a in starts)
