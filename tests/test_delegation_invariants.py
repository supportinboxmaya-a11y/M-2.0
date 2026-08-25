"""Single-controller delegation regression tests.

Locks the architecture invariant that every legacy execution entry point
delegates through CognitiveKernel (the ONE controller) when its unified
loop is live:
  - Phase 17 CognitionEngine AUTORUN cycle -> kernel.process_goal
  - with the loop off / kernel absent, nothing executes in parallel.
"""
import asyncio
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

import infrastructure.cognition as cog_mod  # noqa: E402
from infrastructure.cognitive_kernel import (  # noqa: E402
    CognitiveKernel,
)
from infrastructure.cognition import CognitionEngine  # noqa: E402


def _fresh_kernel() -> CognitiveKernel:
    d = Path(tempfile.mkdtemp(prefix="delg_"))
    ck = sys.modules["infrastructure.cognitive_kernel"]
    ck.COG_KERNEL_DB = str(d / "kernel.db")
    ck.CHECKPOINT_DIR = d / "checkpoints"
    k = CognitiveKernel()
    k._calls = []

    def executor(desc, ctx, **opts):
        k._calls.append(desc)
        return {"success": True, "result": f"kernel did: {desc[:30]}"}

    k.register_executor(executor)
    k.unified_loop_enabled = True
    return k


def _engine(kernel) -> CognitionEngine:
    cog_mod.COG_DB = str(Path(tempfile.mkdtemp(prefix="delgcog_")) / "c.db")
    eng = CognitionEngine(llm_fn=lambda p: "ok", cognitive_kernel=kernel)
    return eng


def _seed(eng: CognitionEngine) -> None:
    m = eng.create_mission("m", "delegation mission")
    eng.add_objective(m["id"], "do a thing via the single controller")


def test_cognition_cycle_delegates_through_kernel(monkeypatch=None):
    kernel = _fresh_kernel()
    eng = _engine(kernel)
    _seed(eng)
    old = cog_mod.COGNITION_AUTORUN
    cog_mod.COGNITION_AUTORUN = True
    try:
        result = asyncio.run(eng.cycle())
    finally:
        cog_mod.COGNITION_AUTORUN = old
    assert kernel._calls, "kernel executor must have been invoked"
    assert result["action"] == "done"
    audits = [a["action"] for a in eng._recent_audit(20)]
    assert any(a == "run" for a in audits)


def test_cognition_without_kernel_never_executes():
    kernel = _fresh_kernel()
    eng = _engine(None)          # no kernel attached
    _seed(eng)
    old = cog_mod.COGNITION_AUTORUN
    cog_mod.COGNITION_AUTORUN = True
    try:
        result = asyncio.run(eng.cycle())
    finally:
        cog_mod.COGNITION_AUTORUN = old
    assert kernel._calls == []   # no parallel loop ran
    assert result["action"] in ("done", "proposed")


def test_unified_loop_off_means_no_execution():
    kernel = _fresh_kernel()
    kernel.unified_loop_enabled = False
    eng = _engine(kernel)
    _seed(eng)
    old = cog_mod.COGNITION_AUTORUN
    cog_mod.COGNITION_AUTORUN = True
    try:
        result = asyncio.run(eng.cycle())
    finally:
        cog_mod.COGNITION_AUTORUN = old
    assert kernel._calls == []
    assert result["action"] in ("done", "proposed")
