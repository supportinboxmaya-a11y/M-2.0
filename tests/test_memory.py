"""Tests for Memory System"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from memory.short_term import ShortTermMemory
from memory.context_manager import ContextManager

def test_short_term_memory():
    mem = ShortTermMemory(capacity=5)
    mem.add("Hello world", {"type": "test"})
    mem.add("AI is great")
    all_items = mem.get_all()
    assert len(all_items) == 2
    print("PASS test_short_term_memory")

def test_short_term_capacity():
    mem = ShortTermMemory(capacity=3)
    for i in range(5):
        mem.add(f"Item {i}")
    assert len(mem.get_all()) == 3
    print("PASS test_short_term_capacity")

def test_short_term_search():
    mem = ShortTermMemory()
    mem.add("Python is awesome")
    mem.add("JavaScript is fun")
    results = mem.search("Python")
    assert len(results) == 1
    print("PASS test_short_term_search")

def test_context_manager():
    ctx = ContextManager()
    ctx.set_goal("Test goal")
    assert ctx.current_goal == "Test goal"
    ctx.add_step_result({"step": 1, "description": "test"}, {"success": True, "result": "done"})
    assert ctx.total_steps == 1
    assert ctx.successful_steps == 1
    print("PASS test_context_manager")

def test_context_clear():
    ctx = ContextManager()
    ctx.set_goal("Test")
    ctx.clear()
    assert ctx.current_goal is None
    print("PASS test_context_clear")

if __name__ == "__main__":
    test_short_term_memory()
    test_short_term_capacity()
    test_short_term_search()
    test_context_manager()
    test_context_clear()
    print("\nAll memory tests passed!")
