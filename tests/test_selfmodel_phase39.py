"""Phase 39 tests — Self-model.

Persistent self-assessment: outcomes aggregate by task type, weaknesses and
strengths are detected, planning gets a one-line self-check, and the kernel
updates the model on every unified-loop outcome.
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
import infrastructure.self_model as sm_mod  # noqa: E402
from infrastructure.cognitive_kernel import CognitiveKernel  # noqa: E402
from infrastructure.self_model import SelfModel, classify_task  # noqa: E402


def _fresh_sm() -> SelfModel:
    d = Path(tempfile.mkdtemp(prefix="p39_"))
    return SelfModel(db_path=str(d / "self.db"))


def test_classify_task():
    assert classify_task("deploy the flask app to vps") == "deploy"
    assert classify_task("scrape product prices from website") == "web"
    assert classify_task("write a poem") == "general"


def test_outcomes_aggregate_and_persist_across_restart():
    dbdir = Path(tempfile.mkdtemp(prefix="p39b_"))
    db = str(dbdir / "self.db")
    sm1 = SelfModel(db_path=db)
    sm1.record_outcome("deploy app to server", True, duration=12.0)
    sm1.record_outcome("deploy another service", True, duration=8.0)
    sm1.record_outcome("deploy broken build", False, duration=30.0)

    sm2 = SelfModel(db_path=db)  # restart persistence
    stats = {s["task_type"]: s for s in sm2.type_stats()}
    dep = stats["deploy"]
    assert dep["attempts"] == 3
    assert abs(dep["success_rate"] - 2 / 3) < 0.01


def test_weakness_and_strength_detection():
    sm = _fresh_sm()
    for _ in range(3):
        sm.record_outcome("scrape competitor pricing site", False)
    for _ in range(4):
        sm.record_outcome("docker container cleanup", True)
    weak = [w["task_type"] for w in sm.weaknesses()]
    strong = [s["task_type"] for s in sm.strengths()]
    assert "web" in weak
    assert "docker" in strong
    assert "web" not in strong and "docker" not in weak


def test_assess_recommends_based_on_track_record():
    sm = _fresh_sm()
    a = sm.assess("research the market for X")
    assert a["novel"] is True
    assert "novel" in a["recommendation"]
    for _ in range(3):
        sm.record_outcome("research market trends", False)
    b = sm.assess("research the market for Y")
    assert b["known_weakness"] is True
    assert "extra verification" in b["recommendation"]


def test_summary_line_feeds_planning():
    sm = _fresh_sm()
    line_new = sm.summary_line("build me a rocket")
    assert "new to you" in line_new
    sm.record_outcome("build a web scraper", True)
    line_known = sm.summary_line("build a web scraper for amazon")
    assert "100% success" in line_known or "success" in line_known


def test_kernel_updates_self_model_on_goal_completion():
    d = Path(tempfile.mkdtemp(prefix="p39k_"))
    ck.COG_KERNEL_DB = str(d / "kernel.db")
    ck.CHECKPOINT_DIR = d / "checkpoints"
    k = CognitiveKernel()
    sm = _fresh_sm()
    k.self_model = sm
    k.register_executor(
        lambda desc, ctx: {"success": True, "result": "ok"})
    r = k.process_goal("docker deploy the api service", execute=True)
    assert r["success"]
    stats = sm.type_stats()
    assert len(stats) == 1 and stats[0]["task_type"] == "deploy"
    assert stats[0]["attempts"] == 1
