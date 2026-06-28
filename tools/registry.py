"""
Maya 2.0 - Ultra Tool Registry
--------------------------------
সব tools এর central registry। Smart tool selection।
"""

from typing import Dict, Any, Callable, List, Optional
import time


class ToolRegistry:
    """
    Maya-র tool management system.
    - Tools register করে
    - Smart tool execution করে
    - Usage statistics রাখে
    - Tool health monitor করে
    - Tool descriptions manage করে
    """

    def __init__(self):
        self._tools: Dict[str, Callable] = {}
        self._descriptions: Dict[str, str] = {}
        self._categories: Dict[str, str] = {}
        self._usage_stats: Dict[str, Dict] = {}
        self._schemas: Dict[str, Dict] = {}

    def register(self, name: str, func: Callable, description: str = "",
                 category: str = "general", schema: Dict = None):
        """
        Tool register করে।
        """
        self._tools[name] = func
        self._descriptions[name] = description
        self._categories[name] = category
        self._schemas[name] = schema or {}
        self._usage_stats[name] = {
            "calls": 0,
            "successes": 0,
            "failures": 0,
            "avg_time": 0,
            "last_error": None
        }

    def run(self, name: str, inputs: Dict = None) -> Any:
        """
        Tool execute করে। Stats update করে।
        """
        if name not in self._tools:
            raise ValueError(f"Tool '{name}' not found. Available: {self.tool_names()}")

        inputs = inputs or {}
        start = time.time()

        try:
            result = self._tools[name](**inputs)
            elapsed = time.time() - start
            self._update_stats(name, success=True, elapsed=elapsed)
            return result

        except Exception as e:
            elapsed = time.time() - start
            self._update_stats(name, success=False, elapsed=elapsed, error=str(e))
            raise

    def has(self, name: str) -> bool:
        """Tool আছে কিনা check করে।"""
        return name in self._tools

    def tool_names(self) -> List[str]:
        """সব tool এর নাম।"""
        return list(self._tools.keys())

    def list_tools(self) -> List[Dict]:
        """সব tool এর details।"""
        return [
            {
                "name": name,
                "description": self._descriptions.get(name, ""),
                "category": self._categories.get(name, "general"),
                "calls": self._usage_stats.get(name, {}).get("calls", 0)
            }
            for name in self._tools
        ]

    def tools_by_category(self, category: str) -> List[str]:
        """Category অনুযায়ী tools।"""
        return [name for name, cat in self._categories.items() if cat == category]

    def get_description(self, name: str) -> str:
        """Tool description।"""
        return self._descriptions.get(name, "")

    def get_stats(self) -> Dict:
        """Usage statistics।"""
        return self._usage_stats

    def most_used(self, n: int = 5) -> List[str]:
        """সবচেয়ে বেশি use হওয়া tools।"""
        sorted_tools = sorted(
            self._usage_stats.items(),
            key=lambda x: x[1].get("calls", 0),
            reverse=True
        )
        return [name for name, _ in sorted_tools[:n]]

    def best_tools_for_task(self, task_description: str) -> List[str]:
        """Task description দেখে সম্ভাব্য tools suggest করে।"""
        task_lower = task_description.lower()
        suggestions = []

        keyword_map = {
            "search": ["web_search"],
            "scrape": ["web_scrape"],
            "read": ["read_file"],
            "write": ["write_file"],
            "code": ["run_code"],
            "execute": ["run_shell", "run_terminal"],
            "file": ["read_file", "write_file", "list_files"],
            "web": ["web_search", "web_scrape"],
            "github": ["web_scrape", "web_search"],
            "youtube": ["web_scrape", "web_search"],
            "install": ["run_shell"],
            "python": ["run_code"],
            "bash": ["run_shell"],
        }

        for keyword, tools in keyword_map.items():
            if keyword in task_lower:
                for tool in tools:
                    if tool in self._tools and tool not in suggestions:
                        suggestions.append(tool)

        return suggestions or self.tool_names()[:3]

    def _update_stats(self, name: str, success: bool, elapsed: float = 0, error: str = None):
        """Usage stats update করে।"""
        stats = self._usage_stats.get(name, {})
        stats["calls"] = stats.get("calls", 0) + 1
        if success:
            stats["successes"] = stats.get("successes", 0) + 1
        else:
            stats["failures"] = stats.get("failures", 0) + 1
            stats["last_error"] = error
        if elapsed:
            prev_avg = stats.get("avg_time", 0)
            stats["avg_time"] = (prev_avg + elapsed) / 2
        self._usage_stats[name] = stats
