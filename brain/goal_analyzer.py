"""Goal understanding: complexity, deliverables, suggested tool categories."""
import re

TOOL_HINTS = {
    "web": ("search", "find", "lookup", "news", "website", "url", "browse"),
    "code": ("code", "script", "function", "debug", "python", "javascript", "api"),
    "file": ("file", "save", "write", "read", "document", "pdf", "csv"),
    "shell": ("install", "run", "command", "deploy", "server"),
    "memory": ("remember", "recall", "forget", "preference"),
}
MULTI_STEP = ("and then", "after that", "first", "finally", "step",
              " and ", ", then", "; ")


class GoalAnalyzer:
    def analyze(self, goal: str) -> dict:
        g = (goal or "").strip()
        low = g.lower()
        tools = [t for t, kws in TOOL_HINTS.items() if any(k in low for k in kws)]
        parts = [p.strip() for p in re.split(r"\bthen\b|;|\. ", low) if len(p.strip()) > 8]
        multi = len(parts) > 1 or any(m in low for m in MULTI_STEP) or len(tools) > 1
        return {
            "goal": g,
            "complexity": "multi_step" if multi else "simple",
            "estimated_steps": max(1, len(parts)) if multi else 1,
            "suggested_tools": tools or ["llm"],
            "sub_goals": parts if multi else [low] if low else [],
        }
