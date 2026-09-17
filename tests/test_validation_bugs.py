"""Regression tests for bugs found during final real-world validation.

1. WorkflowEngine must EXECUTE recovery new_steps (replan/switch_tool/
   simplify) instead of computing then dropping them.
2. Executor must treat tools' error-string/dict returns as step failures
   (read_file returns "Error: File not found" without raising).
3. WorkflowEngine.run must merge caller-provided memory_hints (kernel
   knowledge/skills/self-model) with its own — not drop them.
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

from core.executor import Executor  # noqa: E402
from core.fallback_manager import FallbackManager  # noqa: E402
from core.workflow_engine import WorkflowEngine  # noqa: E402


class FakeRouter:
    def chat(self, messages, **kw):
        return "ok"

    def secondary_provider(self, exclude=None):
        return "fake"


class FakeTools:
    """Registry stand-in: read_file returns an error STRING (real behavior),
    run_code works."""

    def has(self, name):
        return name in ("read_file", "run_code")

    def run(self, name, inputs):
        if name == "read_file":
            path = (inputs or {}).get("filename", "")
            if "missing" in path:
                return f"Error: File not found: {path}"
            return "file-content"
        if name == "run_code":
            import subprocess
            out = subprocess.run([sys.executable, "-c", inputs["code"]],
                                 capture_output=True, text=True)
            return out.stdout.strip() or out.stderr[:200]
        raise ValueError(name)


class FakePlanner:
    def plan(self, goal, context="", memory_hints="", past_failures=""):
        self.last_memory_hints = memory_hints
        return {"goal_analysis": "g", "complexity": "low", "approach": "a",
                "steps": [{"step": 1, "title": "t",
                           "description": goal,
                           "tool": "read_file",
                           "tool_input": {"filename": "missing_1.txt"},
                           "expected_output": "x", "on_failure": "recover",
                           "depends_on": []}],
                "success_criteria": "sc"}

    def replan(self, goal, error, completed_summary, failed_step):
        # recovery plan: create the file with run_code
        return {"failure_analysis": "missing",
                "recovery_strategy": "create it",
                "new_steps": [{"step": 1, "title": "create",
                               "description": "create the file",
                               "tool": "run_code",
                               "tool_input": {"code":
                                   "print('RECOVERED-OK')"},
                               "expected_output": "RECOVERED-OK",
                               "on_failure": "abort", "depends_on": []}]}


class FakeVerifier:
    def verify(self, goal, result, context=""):
        ok = "RECOVERED-OK" in str(result)
        return {"success": ok, "verdict": "success" if ok else "failure",
                "quality_score": 8 if ok else 3,
                "what_is_missing": None if ok else "marker missing"}


class FakeTM:
    def create_task(self, goal):
        class T:
            id = "t1"
        return T()

    def update_status(self, *a, **k):
        pass

    def increment_retry(self, *a, **k):
        pass


def _engine():
    planner = FakePlanner()
    ex = Executor(FakeRouter(), FakeTools())
    fm = FallbackManager(planner=planner)
    wf = WorkflowEngine(planner=planner, executor=ex,
                        verifier=FakeVerifier(), task_manager=FakeTM(),
                        fallback_manager=fm)
    return wf, planner, fm


def test_recovery_new_steps_are_executed():
    """A failed step whose replan produces a working recovery step must end
    in overall success (previously the replan was computed then dropped)."""
    wf, _, fm = _engine()
    result = wf.run("read the file that is missing")
    assert result["success"] is True, str(result)[:200]
    assert any("RECOVERED-OK" in str(r.get("result"))
               for r in result.get("steps", []))
    assert fm.recovery_history[-1]["success"] is True


def test_tool_error_strings_are_step_failures():
    ex = Executor(FakeRouter(), FakeTools())
    res = ex.execute_step({"step": 1, "description": "d", "tool": "read_file",
                           "tool_input": {"filename": "missing_x.txt"}})
    assert res["success"] is False          # was True before the fix
    assert "not found" in (res.get("error") or "").lower()


def test_caller_memory_hints_reach_planner():
    """Knowledge/skill/self-model hints passed to run() must reach the
    planner prompt alongside the engine's own memory hints."""
    wf, planner, _ = _engine()
    wf.run("read any file", memory_hints="Self-model: you are experienced.")
    assert "Self-model:" in planner.last_memory_hints
