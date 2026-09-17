"""
Maya 2.0 - Reflection Engine
-----------------------------
Self-critique for completed tasks: did the result actually satisfy the
goal? What's wrong with it, and what's one concrete way to improve it?

This is deliberately a separate, opt-in pass over an already-finished
task (called from POST /api/v1/tasks/{id}/reflect) rather than being
wired into the main task pipeline — so it doesn't change the behavior
or latency of every existing task run, only ones a person or the agent
explicitly asks to have reviewed.
"""
import json
import re


class ReflectionEngine:
    def __init__(self, router):
        self.router = router  # llm.router.LLMRouter — same one Maya's core uses

    def critique(self, goal: str, result: str) -> dict:
        """Ask the model to grade its own (or another run's) result
        against the original goal. Returns
        {score: 1-10, issues: [str], suggestion: str, raw: str}."""
        prompt = (
            "You are reviewing a completed AI task, playing devil's advocate "
            "against your own work.\n\n"
            f"GOAL: {goal}\n\nRESULT:\n{result}\n\n"
            "Rate how well the result actually satisfies the goal, 1-10 "
            "(10 = fully and correctly done). List concrete issues, if any "
            "(empty list if none). Suggest ONE specific, actionable next step "
            "to improve it, or \"none\" if it's already good enough.\n\n"
            "Reply with ONLY this JSON, no other text:\n"
            '{"score": <int 1-10>, "issues": ["..."], "suggestion": "..."}'
        )
        raw = self.router.chat([{"role": "user", "content": prompt}])
        parsed = self._parse(raw)
        parsed["raw"] = raw
        return parsed

    def should_retry(self, critique: dict, threshold: int = 6) -> bool:
        return critique.get("score", 10) < threshold and bool(
            critique.get("suggestion") and critique["suggestion"].lower() != "none"
        )

    def retry_prompt(self, goal: str, result: str, critique: dict) -> str:
        """Builds a follow-up goal that folds the critique back in, for
        callers that want to re-run the task once with the feedback."""
        issues = "; ".join(critique.get("issues", [])) or "(none listed)"
        return (
            f"Redo this task, addressing the feedback below.\n\n"
            f"Original goal: {goal}\n\nPrevious result:\n{result}\n\n"
            f"Issues found: {issues}\nSuggested fix: {critique.get('suggestion', '')}"
        )

    @staticmethod
    def _parse(raw: str) -> dict:
        """Best-effort JSON extraction — models sometimes wrap the JSON
        in prose or a code fence despite being asked not to."""
        text = (raw or "").strip()
        match = re.search(r"\{.*\}", text, re.S)
        if match:
            try:
                data = json.loads(match.group(0))
                return {
                    "score": int(data.get("score", 5)),
                    "issues": list(data.get("issues", [])) if isinstance(data.get("issues"), list) else [],
                    "suggestion": str(data.get("suggestion", "")),
                }
            except (json.JSONDecodeError, ValueError, TypeError):
                pass
        return {"score": 5, "issues": ["could not parse model's critique"], "suggestion": ""}
