"""Reflection & self-critique of results before returning them.

Heuristic checks offline; optional llm_fn for deeper critique.
"""


class Reflector:
    def __init__(self, llm_fn=None):
        self.llm_fn = llm_fn

    def critique(self, goal: str, output: str) -> dict:
        issues = []
        text = (output or "").strip()
        if not text:
            issues.append("Output is empty")
        if len(text) < 30 and len((goal or "")) > 40:
            issues.append("Output looks too short for the goal")
        # Only check goal-word overlap for substantive outputs. A short
        # generic response like "done successfully" should not trigger
        # a false "doesn't address the goal" issue.
        if len(text) > 100:
            goal_words = {w for w in (goal or "").lower().split() if len(w) > 4}
            hit = sum(1 for w in goal_words if w in text.lower())
            if goal_words and hit / len(goal_words) < 0.2:
                issues.append("Output may not address the goal")
        for bad in ("todo", "placeholder", "lorem ipsum", "not implemented"):
            if bad in text.lower():
                issues.append(f"Contains '{bad}'")

        if self.llm_fn:
            try:
                extra = self.llm_fn(
                    f"Goal: {goal}\nOutput: {text[:3000]}\n"
                    "List concrete problems with this output, or say OK.")
                if extra and "ok" != extra.strip().lower():
                    issues.append(extra.strip()[:500])
            except Exception:
                pass  # heuristics still stand

        return {"acceptable": not issues, "issues": issues,
                "suggestion": "Revise addressing: " + "; ".join(issues) if issues else None}
