"""Phase 7 autonomous mode tests — offline with fakes."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from types import SimpleNamespace
from autonomous import ExecutorBridge, OutputImprover, ReportGenerator, AutonomousMaya
from tools.framework import ToolFramework, ToolPolicy

GOAL = "Search the web for news, then write a python script to save results to a file"


def _agent(perms=("web", "code", "file")):
    return SimpleNamespace(permissions=perms, system_prompt="You are agent.")


def _node(tool=None, desc="do the thing"):
    return SimpleNamespace(tool=tool, description=desc)


def test_bridge_tool_path():
    fw = ToolFramework(logger=lambda m: None)
    fw.register("websearch", lambda i: f"results for {i['query']}", ToolPolicy(category="web"))
    b = ExecutorBridge(framework=fw)
    out, verified = b(_agent(), _node(tool="web", desc="find AI news"))
    assert "results for" in out and verified is True
    print("PASS bridge_tool")


def test_bridge_fallback_to_llm():
    fw = ToolFramework(logger=lambda m: None)
    fw.register("broken", lambda i: 1 / 0, ToolPolicy(category="web", retries=1))
    b = ExecutorBridge(framework=fw, llm_fn=lambda p: "llm rescued the task")
    out, verified = b(_agent(), _node(tool="web"))
    assert "rescued" in out
    # no tool for category -> llm directly
    out2, _ = b(_agent(), _node(tool="media"))
    assert "rescued" in out2
    # nothing configured
    out3, v3 = ExecutorBridge()(_agent(), _node(tool="web"))
    assert v3 is False and "error" in out3
    print("PASS bridge_fallback")


def test_bridge_respects_permissions():
    fw = ToolFramework(logger=lambda m: None)
    fw.register("shellrun", lambda i: "ran", ToolPolicy(category="shell", dangerous=True))
    b = ExecutorBridge(framework=fw)   # approve_dangerous=False
    out, verified = b(_agent(perms=("shell",)), _node(tool="shell"))
    assert verified is False and "approved" in out
    b2 = ExecutorBridge(framework=fw, approve_dangerous=True)
    out2, v2 = b2(_agent(perms=("shell",)), _node(tool="shell"))
    assert v2 is True and out2 == "ran"
    print("PASS bridge_permissions")


def test_improver():
    calls = {"n": 0}
    def llm(prompt):
        calls["n"] += 1
        return "A complete, detailed migration plan for the database cluster with steps."
    imp = OutputImprover(llm_fn=llm)
    r = imp.improve("write a detailed migration plan for the database cluster", "TODO")
    assert r["improved"] and r["acceptable"] and "migration plan" in r["output"]
    ok = OutputImprover().improve("say hi", "hi there friend, greetings!")
    assert not ok["improved"]
    print("PASS improver")


def test_reporter():
    rep = ReportGenerator().generate(GOAL, {
        "status": "completed", "plan_confidence": 0.9,
        "progress": {"total": 2, "states": {"done": 2}},
        "results": [{"node": "a", "ok": True, "confidence": 0.9, "review": {"issues": []}},
                    {"node": "b", "ok": False, "confidence": 0.1,
                     "review": {"issues": ["timeout"]}}]},
        final_output="hello world")
    assert "# Maya Autonomous Run Report" in rep and "[FAIL]" in rep
    assert "Failures & recovery" in rep and "hello world" in rep
    print("PASS reporter")


def test_full_autonomous_run():
    fw = ToolFramework(logger=lambda m: None)
    fw.register("websearch", lambda i: "found 5 news articles successfully",
                ToolPolicy(category="web"))
    fw.register("codegen", lambda i: "python script written and saved successfully",
                ToolPolicy(category="code"))
    maya = AutonomousMaya(framework=fw, llm_fn=lambda p: "completed successfully via llm")
    result = maya.run_sync(GOAL)
    assert result["status"] == "completed"
    assert result["plan_confidence"] > 0.6
    assert "Report" in result["report"]
    print("PASS full_autonomous_run")


def test_failure_recovery():
    calls = {"n": 0}
    def flaky(i):
        calls["n"] += 1
        if calls["n"] == 1:
            raise RuntimeError("network blip")
        return "search completed successfully"
    fw = ToolFramework(logger=lambda m: None)
    fw.register("websearch", flaky, ToolPolicy(category="web", retries=2))
    fw.register("codegen", lambda i: "script saved successfully", ToolPolicy(category="code"))
    maya = AutonomousMaya(framework=fw)
    result = maya.run_sync(GOAL)
    assert result["status"] == "completed" and calls["n"] == 2   # auto-recovered
    print("PASS failure_recovery")


if __name__ == "__main__":
    test_bridge_tool_path(); test_bridge_fallback_to_llm(); test_bridge_respects_permissions()
    test_improver(); test_reporter(); test_full_autonomous_run(); test_failure_recovery()
    print("\nAll Phase 7 autonomous tests passed!")
