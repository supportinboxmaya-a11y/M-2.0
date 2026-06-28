"""Tests for Maya Planner"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from unittest.mock import MagicMock
from core.planner import Planner

def test_planner_basic():
    router = MagicMock()
    router.chat.return_value = '{"reasoning": "test", "complexity": "low", "estimated_steps": 1, "steps": [{"step": 1, "title": "Test", "description": "Do something", "tool": null, "tool_input": null, "expected_output": "done", "on_failure": "retry", "depends_on": []}], "success_criteria": "done", "risks": []}'
    planner = Planner(router)
    plan = planner.plan("Search for AI news")
    assert "steps" in plan
    assert len(plan["steps"]) > 0
    print("PASS test_planner_basic")

def test_planner_fallback():
    router = MagicMock()
    router.chat.return_value = "invalid json response"
    planner = Planner(router)
    plan = planner.plan("Do something")
    assert "steps" in plan
    print("PASS test_planner_fallback")

def test_planner_complexity():
    router = MagicMock()
    router.chat.return_value = '{}'
    planner = Planner(router)
    assert planner.estimate_complexity("what is AI") == "low"
    assert planner.estimate_complexity("build a web scraper") == "high"
    print("PASS test_planner_complexity")

if __name__ == "__main__":
    test_planner_basic()
    test_planner_fallback()
    test_planner_complexity()
    print("\nAll planner tests passed!")
