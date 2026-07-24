"""Phase 4 multi-agent tests — offline."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agents.base import BaseAgent
from agents.registry import AgentRegistry
from agents.messaging import MessageBus
from agents.roster import build_default_agents
from agents.orchestrator import Orchestrator


def test_base_agent():
    a = BaseAgent("coder", "Coding", skills=("code",), permissions=("code", "file"))
    assert a.can_use("code") and a.can_use(None) and not a.can_use("shell")
    out = a.handle("write hello", llm_fn=lambda p: "print('hello')")
    assert "hello" in out
    a.record_success(); a.record_error("x"); a.record_error("y"); a.record_error("z")
    h = a.health()
    assert h["errors"] == 3 and h["status"] == "degraded"
    a.remember("note"); assert a.memory == ["note"]
    print("PASS base_agent")


def test_registry_routing():
    r = AgentRegistry()
    for ag in build_default_agents():
        r.register(ag)
    assert len(r.list()) == 15                                   # 11 core + 4 business (Phase 20)
    assert r.route("search the web for AI news").name == "research"
    assert r.route("write a python function", tool="code").name == "coding"
    assert r.route("deploy to render server").name == "deployment"
    assert r.route("xyz nothing matches", tool="web").can_use("web")   # permission fallback
    assert r.route("anything", preferred="security").name == "security"
    assert len(r.health_report()) == 15
    print("PASS registry_routing")


def test_message_bus():
    b = MessageBus()
    b.send("coding", "reviewer", {"pr": 1})
    b.send("coding", "reviewer", {"pr": 2})
    msgs = b.receive("reviewer")
    assert len(msgs) == 2 and b.receive("reviewer") == []        # drained
    b.broadcast("orchestrator", ["a", "b", "orchestrator"], "hi")
    assert len(b.receive("a")) == 1 and len(b.history()) >= 3
    print("PASS message_bus")


def test_orchestrator_plan():
    o = Orchestrator()
    p = o.plan("Search the web for FastAPI news, then write a python script to save it to a file")
    assert p["analysis"]["complexity"] == "multi_step"
    assert len(p["graph"].nodes) >= 2
    assert all(v for v in p["assignments"].values())             # every node assigned
    print("PASS orchestrator_plan")


def test_orchestrator_run_success():
    o = Orchestrator()
    def exec_fn(agent, node):
        return f"{agent.name} completed: {node.description} successfully", True
    rep = o.run("Search the web for news, then write a python script to save results to a file",
                execute_fn=exec_fn)
    assert rep["progress"]["finished"] and rep["plan_confidence"] > 0.7
    assert not rep["should_replan"]
    healthy = {h["name"]: h for h in o.registry.health_report()}
    assert any(h["ok"] > 0 for h in healthy.values())
    assert len(o.bus.history()) >= 1                             # agents reported in
    print("PASS orchestrator_run")


def test_orchestrator_permission_enforced():
    o = Orchestrator()
    # force an impossible assignment: planner (no tool perms) on a web step
    p = o.plan("search the web for news")
    def bad_exec(agent, node):
        return "should never run", True
    # monkeypatch route to return planner (no 'web' permission)
    o.registry.route = lambda *a, **kw: o.registry.get("planner")
    rep = o.run("search the web for news", execute_fn=bad_exec)
    assert any("permission denied" in str(r["review"]["issues"]) for r in rep["results"])
    assert not rep["progress"]["finished"]
    print("PASS permission_enforced")


def test_orchestrator_failure_and_replan_signal():
    o = Orchestrator()
    def flaky(agent, node):
        return "error: failed traceback", False
    rep = o.run("write a python function", execute_fn=flaky)
    assert rep["should_replan"] and not rep["progress"]["finished"]
    print("PASS failure_replan")


if __name__ == "__main__":
    test_base_agent(); test_registry_routing(); test_message_bus()
    test_orchestrator_plan(); test_orchestrator_run_success()
    test_orchestrator_permission_enforced(); test_orchestrator_failure_and_replan_signal()
    print("\nAll Phase 4 agent tests passed!")
