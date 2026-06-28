"""Tests for Tool Registry"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from tools.registry import ToolRegistry

def test_tool_registration():
    registry = ToolRegistry()
    registry.register("test_tool", lambda text="": f"Result: {text}", description="Test tool")
    assert registry.has("test_tool")
    print("PASS test_tool_registration")

def test_tool_execution():
    registry = ToolRegistry()
    registry.register("echo", lambda text="hello": text)
    result = registry.run("echo", {"text": "Maya"})
    assert result == "Maya"
    print("PASS test_tool_execution")

def test_tool_not_found():
    registry = ToolRegistry()
    try:
        registry.run("nonexistent_tool", {})
        assert False, "Should have raised ValueError"
    except ValueError:
        print("PASS test_tool_not_found")

def test_tool_stats():
    registry = ToolRegistry()
    registry.register("stat_tool", lambda: "ok")
    registry.run("stat_tool", {})
    stats = registry.get_stats()
    assert stats["stat_tool"]["calls"] == 1
    assert stats["stat_tool"]["successes"] == 1
    print("PASS test_tool_stats")

def test_tool_suggestions():
    registry = ToolRegistry()
    registry.register("web_search", lambda query="": [])
    suggestions = registry.best_tools_for_task("search the web for AI news")
    assert "web_search" in suggestions
    print("PASS test_tool_suggestions")

if __name__ == "__main__":
    test_tool_registration()
    test_tool_execution()
    test_tool_not_found()
    test_tool_stats()
    test_tool_suggestions()
    print("\nAll tool tests passed!")
