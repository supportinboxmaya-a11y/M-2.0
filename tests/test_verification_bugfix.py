"""Regression tests for the live-validation verification bug (2026-08-25).

A genuinely-complete goal ("compute X AND write it to a file") was rejected
by the verifier because _combine_results() stripped all action evidence —
the verifier only saw "385" and judged the file-write missing. Verification
must receive structured per-step evidence instead.
"""
import os
import sys

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

from core.workflow_engine import WorkflowEngine  # noqa: E402


def _engine() -> WorkflowEngine:
    return WorkflowEngine.__new__(WorkflowEngine)  # no deps needed


def test_evidence_includes_side_effect_steps():
    eng = _engine()
    results = [{
        "step": 1,
        "success": True,
        "tool_used": "run_code",
        "description": "compute sum of squares and write 385 to "
                       "maya_e2e/live_result.txt",
        "result": {"success": True, "output": "385\n", "error": "",
                   "returncode": 0},
    }]
    evidence = eng._verification_evidence(results)
    assert evidence is not None
    assert "1/1 planned steps executed successfully" in evidence
    assert "run_code" in evidence
    assert "live_result.txt" in evidence       # the action is visible now
    assert "385" in evidence                    # and its output


def test_evidence_reports_failures_and_skips():
    eng = _engine()
    results = [
        {"step": 1, "success": True, "tool_used": "run_code",
         "description": "do a thing",
         "result": {"success": True, "output": "ok"}},
        {"step": 2, "success": False, "error": "boom"},
        {"step": 3, "skipped": True},
    ]
    ev = eng._verification_evidence(results)
    assert "1/2 planned steps executed successfully" in ev
    assert "FAILED" in ev and "boom" in ev
    assert "skipped" not in ev.lower().replace("successfully", "")


def test_empty_results_give_empty_evidence():
    eng = _engine()
    assert eng._verification_evidence([]) == ""
    assert eng._verification_evidence(None) == ""


def test_combine_still_clean_for_user_output():
    """User-facing result stays the clean answer, not raw dicts."""
    eng = _engine()
    out = eng._combine_results([{
        "success": True,
        "result": {"success": True, "output": "385\n", "returncode": 0},
    }])
    assert out.strip() == "385"
