"""Phase 3 Brain Engine tests — offline, stdlib-only."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from brain.task_graph import TaskGraph, TaskNode
from brain.confidence import ConfidenceScorer
from brain.reflection import Reflector
from brain.goal_analyzer import GoalAnalyzer
from brain.brain_engine import BrainEngine


def test_graph_order_and_ready():
    g = TaskGraph()
    a = g.add(TaskNode("fetch data"))
    b = g.add(TaskNode("clean data", depends_on=[a.id]))
    c = g.add(TaskNode("report", depends_on=[b.id]))
    assert [n.id for n in g.ready()] == [a.id]
    g.start(a.id); g.complete(a.id)
    assert [n.id for n in g.ready()] == [b.id]
    g.start(b.id); g.complete(b.id)
    g.start(c.id); g.complete(c.id)
    p = g.progress()
    assert p["finished"] and p["percent"] == 100.0
    print("PASS graph_order")


def test_graph_cycle_and_fail():
    g = TaskGraph()
    a = g.add(TaskNode("a"))
    b = g.add(TaskNode("b", depends_on=[a.id]))
    try:
        g.add(TaskNode("bad", depends_on=["nope"])); assert False
    except ValueError: pass
    # fail propagates blocking
    c = g.add(TaskNode("c", depends_on=[b.id]))
    g.start(a.id); blocked = g.fail(a.id, "boom")
    assert set(blocked) == {b.id, c.id} and g.progress()["stuck"]
    g.retry(a.id)                       # replan: reset
    assert g.nodes[b.id].state == "pending" and g.ready()[0].id == a.id
    print("PASS graph_cycle_fail")


def test_confidence():
    s = ConfidenceScorer()
    good = s.score_step("Task completed successfully, file created", verified=True)
    bad = s.score_step("Traceback: error, failed", verified=False, attempts=3)
    assert good > 0.8 > 0.4 > bad
    assert s.score_step("") < 0.5
    plan = s.score_plan([good, bad])
    assert s.should_replan(plan) is (plan < 0.45)
    assert s.score_plan([]) == 0.0
    print("PASS confidence")


def test_reflection():
    r = Reflector()
    ok = r.critique("write a python function to sort numbers",
                    "def sort_numbers(nums): return sorted(nums)  # python function")
    assert ok["acceptable"]
    bad = r.critique("write a detailed migration plan for the database cluster", "TODO")
    assert not bad["acceptable"] and bad["suggestion"]
    def llm(p): return "Missing error handling"
    deep = Reflector(llm).critique("goal here", "some reasonable long output text ok")
    assert any("error handling" in i.lower() for i in deep["issues"])
    print("PASS reflection")


def test_goal_analyzer():
    a = GoalAnalyzer()
    simple = a.analyze("What is the capital of France")
    assert simple["complexity"] == "simple" and simple["estimated_steps"] == 1
    multi = a.analyze("Search the web for news, then write a python script to save it to a file")
    assert multi["complexity"] == "multi_step"
    assert {"web", "code", "file"} <= set(multi["suggested_tools"])
    print("PASS goal_analyzer")


def test_brain_engine_flow():
    e = BrainEngine()
    steps = [{"description": "search web", "tool": "web", "depends_on": []},
             {"description": "write code", "tool": "code", "depends_on": [0]},
             {"description": "save file", "tool": "file", "depends_on": [1]}]
    g = e.build_graph(steps)
    assert len(g.ready()) == 1
    results = []
    n = g.ready()[0]; g.start(n.id)
    results.append(e.record(g, n.id, "Search completed successfully with results", verified=True))
    n = g.ready()[0]; g.start(n.id)
    results.append(e.record(g, n.id, "", verified=False))          # fails
    assert results[-1]["ok"] is False and g.progress()["stuck"]
    pc = e.plan_confidence(results)
    assert pc["should_replan"] is True
    g.retry(results[-1]["node"])                                    # replan + succeed
    n = g.ready()[0]; g.start(n.id)
    results[-1] = e.record(g, n.id, "code written and passed tests ok", verified=True)
    n = g.ready()[0]; g.start(n.id)
    results.append(e.record(g, n.id, "file saved successfully", verified=True))
    assert g.progress()["finished"]
    print("PASS brain_engine_flow")


if __name__ == "__main__":
    test_graph_order_and_ready(); test_graph_cycle_and_fail(); test_confidence()
    test_reflection(); test_goal_analyzer(); test_brain_engine_flow()
    print("\nAll Phase 3 brain tests passed!")
