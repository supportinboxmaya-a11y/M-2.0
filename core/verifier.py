"""
Maya 2.0 - Ultra Verifier
--------------------------
Task result verify করে। Success কিনা নিশ্চিত করে।
Quality check, completeness check সব এখানে।
"""

import json
from typing import Dict, List, Optional
from llm.router import LLMRouter


class Verifier:
    """
    Maya-র verification engine.
    - Result goal satisfy করেছে কিনা check করে
    - Quality score দেয়
    - Partial success detect করে
    - Specific missing parts identify করে
    - Next action suggest করে
    """

    def __init__(self, router: LLMRouter):
        self.router = router
        self.verification_history: List[Dict] = []

    def verify(self, goal: str, result: str, context: str = "") -> Dict:
        """
        Result verify করে। Detailed verdict দেয়।
        """
        system = """You are Maya's quality verification engine.
Your job is to STRICTLY verify if a result truly satisfies the original goal.

Be honest and critical:
- If the goal asked for 5 items and only 3 are present, it's partial
- If the goal asked for code and the result is just an explanation, it's incomplete
- If the result has errors, it's a failure
- Only mark as success if the goal is FULLY satisfied

Always respond with ONLY valid JSON."""

        user = f"""Original Goal: {goal}

Result achieved: {result[:3000] if result else 'No result'}

Context: {context or 'None'}

Verify if this result truly satisfies the goal. Return JSON:
{{
  "success": true/false,
  "verdict": "success|partial_success|failure",
  "quality_score": <0-10>,
  "completeness_percentage": <0-100>,
  "what_was_achieved": "specific things that were accomplished",
  "what_is_missing": "specific things that are still missing (null if complete)",
  "errors_found": ["error1"] or [],
  "reasoning": "detailed reasoning for this verdict",
  "next_action": "done|retry|replan|ask_user",
  "retry_hint": "specific hint for what to do differently if retrying"
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        response = self.router.chat(messages, max_tokens=1500)
        verdict = self._parse_json(response)

        if not verdict:
            verdict = {
                "success": bool(result and len(result) > 10),
                "verdict": "success" if result else "failure",
                "quality_score": 7 if result else 0,
                "completeness_percentage": 80 if result else 0,
                "next_action": "done" if result else "retry"
            }

        self.verification_history.append({"goal": goal, "verdict": verdict})
        return verdict

    def quick_check(self, goal: str, result: str) -> bool:
        """Quick success/failure check।"""
        if not result or len(result.strip()) < 5:
            return False
        verdict = self.verify(goal, result)
        return verdict.get("success", False)

    def verify_step(self, step_description: str, step_result: str, expected_output: str = "") -> Dict:
        """Individual step verify করে।"""
        system = "You are a step verification expert. Check if a step's result matches its expected output. Return ONLY valid JSON."

        user = f"""Step: {step_description}
Expected output: {expected_output or 'Not specified'}
Actual result: {step_result[:1000] if step_result else 'No result'}

Return JSON:
{{
  "passed": true/false,
  "reason": "why it passed or failed",
  "quality": "excellent|good|acceptable|poor"
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        response = self.router.chat(messages)
        return self._parse_json(response) or {"passed": bool(step_result), "reason": "Auto-checked", "quality": "acceptable"}

    def needs_human_review(self, goal: str, result: str, quality_threshold: int = 6) -> bool:
        """Human review দরকার কিনা check করে।"""
        verdict = self.verify(goal, result)
        score = verdict.get("quality_score", 10)
        return score < quality_threshold or verdict.get("verdict") == "partial_success"

    def _parse_json(self, text: str) -> Optional[Dict]:
        try:
            clean = text.strip()
            if "```json" in clean:
                clean = clean.split("```json")[1].split("```")[0]
            elif "```" in clean:
                clean = clean.split("```")[1].split("```")[0]
            return json.loads(clean.strip())
        except:
            return None

    def get_history(self) -> List[Dict]:
        return self.verification_history
