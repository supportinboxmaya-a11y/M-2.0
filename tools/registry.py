
"""
Maya 2.0 - Ultra Tool Registry
--------------------------------
সব tools এর central registry। Smart tool selection।
"""

from typing import Dict, Any, Callable, List, Optional
import time
import inspect
from datetime import datetime, timezone


# Common ways an LLM names a tool argument, mapped to the canonical parameter
# name the tools actually use. Applied only when the tool really has that
# parameter and the LLM didn't already supply it. This keeps tool calls from
# crashing with TypeError just because the model wrote "path" instead of
# "filename" or added an extra "language" key.
_ARG_ALIASES = {
    "filename": ["path", "filepath", "file", "file_name", "file_path"],
    "content": ["text", "data", "body", "file_content"],
    "name": ["project_name", "project", "site_name", "app_name"],
    "files": ["file_map", "filemap", "file_dict"],
    "code": ["source", "script", "snippet", "program"],
    "url": ["link", "address", "uri"],
    "query": ["q", "search", "search_query", "keyword", "keywords", "term"],
    "command": ["cmd", "shell_command", "shell"],
}


def _adapt_inputs(func: Callable, inputs: Dict) -> Dict:
    """Reshape LLM-provided inputs to match a tool's real signature.

    - If the tool accepts **kwargs, pass everything through untouched.
    - Otherwise: fill canonical params from known aliases, then drop any
      keys the function doesn't accept (prevents 'unexpected keyword
      argument' TypeErrors from stray keys like 'language').
    """
    if not inputs:
        return inputs or {}
    try:
        params = inspect.signature(func).parameters
    except (TypeError, ValueError):
        return inputs
    # If the function takes **kwargs, it can absorb anything.
    if any(p.kind == inspect.Parameter.VAR_KEYWORD for p in params.values()):
        return inputs
    accepted = set(params.keys())
    adapted = dict(inputs)
    # Map aliases into canonical names the function accepts.
    for canonical, aliases in _ARG_ALIASES.items():
        if canonical in accepted and canonical not in adapted:
            for alias in aliases:
                if alias in adapted:
                    adapted[canonical] = adapted.pop(alias)
                    break
    # Drop anything the function can't accept, so **inputs won't raise.
    return {k: v for k, v in adapted.items() if k in accepted}


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

    def unregister(self, name: str) -> bool:
        """Remove a tool completely so it can no longer be called.

        Plugins rely on this to actually retract their tools when a
        plugin is disabled or uninstalled — before this existed, a
        'disabled' plugin's tools stayed callable until the next restart.
        Returns True if a tool was removed.
        """
        if name not in self._tools:
            return False
        self._tools.pop(name, None)
        self._descriptions.pop(name, None)
        self._categories.pop(name, None)
        self._schemas.pop(name, None)
        self._usage_stats.pop(name, None)
        return True

    def names_in_category(self, category: str) -> List[str]:
        """Every registered tool name in a given category."""
        return [n for n, c in self._categories.items() if c == category]

    def run(self, name: str, inputs: Dict = None) -> Any:
        """
        Tool execute করে। Stats update করে।
        """
        if name not in self._tools:
            raise ValueError(f"Tool '{name}' not found. Available: {self.tool_names()}")

        inputs = inputs or {}
        start = time.time()

        try:
            call_args = _adapt_inputs(self._tools[name], inputs)
            result = self._tools[name](**call_args)
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
        """সব tool এর details। Frontend's Tool type expects call_count /
        success_rate / avg_duration_ms / last_used — this used to only send
        a raw 'calls' number, so the Tools page always showed "undefined"
        for the other three fields even when they were being tracked fine
        internally."""
        out = []
        for name in self._tools:
            stats = self._usage_stats.get(name, {})
            calls = stats.get("calls", 0)
            successes = stats.get("successes", 0)
            out.append({
                "name": name,
                "description": self._descriptions.get(name, ""),
                "category": self._categories.get(name, "general"),
                "calls": calls,  # kept for backwards compatibility with any other caller
                "call_count": calls,
                "success_rate": round((successes / calls) * 100, 1) if calls else 0,
                "avg_duration_ms": round(stats.get("avg_time", 0) * 1000, 1),
                "last_used": stats.get("last_used"),
            })
        return out

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
        stats["last_used"] = datetime.now(timezone.utc).isoformat()
        if success:
            stats["successes"] = stats.get("successes", 0) + 1
        else:
            stats["failures"] = stats.get("failures", 0) + 1
            stats["last_error"] = error
        if elapsed:
            prev_avg = stats.get("avg_time", 0)
            stats["avg_time"] = (prev_avg + elapsed) / 2
        self._usage_stats[name] = stats
