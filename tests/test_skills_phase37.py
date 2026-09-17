"""Phase 37 tests — skill generalization.

Learned skills must be retrievable for novel-but-similar goals, composable
into higher-order skills, and surfaced in goal grounding + planning hints.
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
import infrastructure.procedural_memory as pm_mod  # noqa: E402
from infrastructure.cognitive_kernel import CognitiveKernel  # noqa: E402
from infrastructure.procedural_memory import ProceduralMemory, Skill  # noqa: E402


def _fresh_pm(tmpname: str) -> ProceduralMemory:
    d = Path(tempfile.mkdtemp(prefix=tmpname))
    old = pm_mod.PROC_MEM_DB
    pm_mod.PROC_MEM_DB = str(d / "skills.db")
    pm = ProceduralMemory()
    pm_mod.PROC_MEM_DB = old
    return pm


def _skill(pm: ProceduralMemory, name: str, desc: str,
           conf: float = 0.8) -> Skill:
    s = Skill(id=uuid4hex(), name=name, description=desc)
    s.confidence = conf
    s.success_rate = 0.9
    pm.store_skill(s)
    return s


def uuid4hex() -> str:
    import uuid
    return uuid.uuid4().hex[:12]


def test_search_ranks_relevant_skill_for_novel_goal():
    pm = _fresh_pm("p37a_")
    _skill(pm, "deploy_docker_app", "Build and deploy a docker app to the VPS")
    _skill(pm, "bake_cookies", "Bake chocolate chip cookies in oven")
    res = pm.search_skills("deploy my new flask app to production server")
    assert res and res[0]["name"] == "deploy_docker_app"
    assert all(r["name"] != "bake_cookies" for r in res)


def test_search_respects_confidence_floor():
    pm = _fresh_pm("p37b_")
    s = _skill(pm, "flaky_skill", "scrape websites with proxy rotation",
               conf=0.1)
    s.success_rate = 0.0
    assert not s.verified
    assert pm.search_skills("scrape some websites") == []


def test_compose_creates_higher_order_skill():
    pm = _fresh_pm("p37c_")
    a = _skill(pm, "build_app", "build the application code")
    b = _skill(pm, "deploy_app", "deploy app via docker to vps")
    comp = pm.compose_skills([a.id, b.id], "ship_app",
                             "build then deploy end-to-end")
    assert comp is not None
    steps = [st["type"] for st in comp.procedure]
    assert steps == ["skill_call", "skill_call"]
    assert comp.procedure[0]["skill_id"] == a.id
    # conservative confidence until proven by usage
    assert comp.confidence == round(min(a.confidence, b.confidence) * 0.8, 3)
    assert comp.verified is False
    # usage feedback works on composites like any skill
    pm.record_usage(comp.id, success=True, reward=1.0)
    assert pm.get_skill(comp.id).usage_count == 1


def test_compose_unknown_skill_fails_clean():
    pm = _fresh_pm("p37d_")
    assert pm.compose_skills(["nonexistent"], "x") is None


def test_kernel_goal_grounding_includes_skills():
    import tempfile as tf
    d = Path(tf.mkdtemp(prefix="p37e_"))
    ck.COG_KERNEL_DB = str(d / "kernel.db")
    ck.CHECKPOINT_DIR = d / "checkpoints"
    k = CognitiveKernel()
    pm = _fresh_pm("p37e_pm_")
    _skill(pm, "docker_deploy", "deploy docker container to remote VPS")
    k.procedural_memory = pm
    ctx = k._gather_cognitive_context("please deploy this container to my vps")
    assert any(h["name"] == "docker_deploy" for h in ctx["skills"])
