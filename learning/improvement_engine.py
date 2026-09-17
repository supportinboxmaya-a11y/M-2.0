"""
Maya 2.0 - Ultra Improvement Engine
--------------------------------------
প্রতিটা task থেকে শেখে এবং নিজেকে improve করে।
"""

import json
from typing import Dict, List, Optional
from llm.router import LLMRouter
from .experience_store import ExperienceStore


class ImprovementEngine:
    """
    Maya-র self-improvement engine.
    - প্রতিটা task execution থেকে lessons extract করে
    - Patterns identify করে
    - Future tasks এর জন্য tips তৈরি করে
    - Success patterns reinforce করে
    - Failure patterns avoid করে
    - Performance metrics track করে
    """

    def __init__(self, router: LLMRouter):
        self.router = router
        self.store = ExperienceStore()
        self.session_lessons: List[Dict] = []
        self.performance_metrics = {
            "total_tasks": 0,
            "successful_tasks": 0,
            "failed_tasks": 0,
            "avg_steps_to_success": 0,
            "most_used_tools": {},
            "common_errors": {}
        }

    def learn(self, goal: str, result: str, success: bool,
              steps: List[Dict] = None, errors: List[str] = None,
              tools_used: List[str] = None):
        """
        Task execution থেকে শেখে।
        """
        system = """You are Maya's learning engine.
Extract deep, actionable lessons from task executions.
Focus on WHAT worked, WHAT failed, and HOW to do better next time.
Be specific and practical. Return ONLY valid JSON."""

        steps_summary = ""
        if steps:
            steps_summary = "\n".join([
                f"Step {i+1}: {s.get('description', '')[:80]} → {'✅' if s.get('success') else '❌'}"
                for i, s in enumerate(steps)
            ])

        user = f"""Task: {goal}
Outcome: {'SUCCESS ✅' if success else 'FAILURE ❌'}
Result: {result[:500] if result else 'No result'}
Steps taken:
{steps_summary or 'Not recorded'}
Errors encountered: {json.dumps(errors or [])}
Tools used: {json.dumps(tools_used or [])}

Extract lessons. Return JSON:
{{
  "lesson": "main lesson learned from this task",
  "pattern": "pattern identified (what type of task this is)",
  "success_factors": ["what made it succeed or could have made it succeed"],
  "failure_factors": ["what caused failure or risks"],
  "future_tip": "specific tip for next time this type of task comes up",
  "tool_insights": "insights about which tools worked well or poorly",
  "estimated_difficulty": "easy|medium|hard|very_hard",
  "tags": ["tag1", "tag2"]
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        try:
            response = self.router.chat(messages, max_tokens=1000)
            data = self._parse_json(response)

            if data:
                self.store.add(
                    task=goal,
                    lesson=data.get("lesson", ""),
                    pattern=data.get("pattern", ""),
                    future_tip=data.get("future_tip", ""),
                    success=success,
                    metadata={
                        "success_factors": data.get("success_factors", []),
                        "failure_factors": data.get("failure_factors", []),
                        "tool_insights": data.get("tool_insights", ""),
                        "tags": data.get("tags", [])
                    }
                )
                self.session_lessons.append(data)
                print(f"   📚 Learned: {data.get('lesson', '')[:80]}")
            else:
                self.store.add(task=goal, lesson=f"{'Success' if success else 'Failure'}: {result[:100]}", success=success)

        except Exception as e:
            print(f"   ⚠️ Learning failed: {e}")
            self.store.add(task=goal, lesson=result[:100] if result else "No result", success=success)

        # Update metrics
        self._update_metrics(success, tools_used or [], errors or [])

    def get_tips(self, goal: str, limit: int = 3) -> str:
        """
        Similar past experiences থেকে tips দেয়।
        """
        experiences = self.store.get_relevant(goal, limit=limit)
        if not experiences:
            return ""

        tips = []
        for exp in experiences:
            tip = exp.get("tip", "")
            lesson = exp.get("lesson", "")
            success = exp.get("success", True)

            if tip:
                status = "✅ What worked" if success else "❌ What failed"
                tips.append(f"{status}: {tip}")
            elif lesson:
                tips.append(f"Past experience: {lesson[:100]}")

        return "\n".join(tips) if tips else ""

    def get_best_approach(self, goal: str) -> Optional[Dict]:
        """
        Similar tasks এর best approach suggest করে।
        """
        experiences = self.store.get_relevant(goal, limit=5)
        successful = [e for e in experiences if e.get("success")]

        if not successful:
            return None

        # Best experience return করি (most recent successful)
        best = successful[0]
        return {
            "suggested_approach": best.get("lesson", ""),
            "tip": best.get("tip", ""),
            "confidence": "high" if len(successful) > 2 else "medium"
        }

    def generate_improvement_report(self) -> str:
        """
        Session improvement report তৈরি করে।
        """
        metrics = self.performance_metrics
        total = metrics["total_tasks"]
        if total == 0:
            return "No tasks completed yet."

        success_rate = (metrics["successful_tasks"] / total * 100) if total > 0 else 0

        report = f"""
📊 Maya Performance Report
==========================
Total Tasks: {total}
Success Rate: {success_rate:.1f}%
Successful: {metrics['successful_tasks']}
Failed: {metrics['failed_tasks']}

Most Used Tools: {', '.join(list(metrics['most_used_tools'].keys())[:3]) or 'None'}
Common Errors: {', '.join(list(metrics['common_errors'].keys())[:3]) or 'None'}

Session Lessons: {len(self.session_lessons)}
"""
        return report.strip()

    def _update_metrics(self, success: bool, tools_used: List[str], errors: List[str]):
        """Performance metrics update করে।"""
        m = self.performance_metrics
        m["total_tasks"] += 1
        if success:
            m["successful_tasks"] += 1
        else:
            m["failed_tasks"] += 1

        for tool in tools_used:
            m["most_used_tools"][tool] = m["most_used_tools"].get(tool, 0) + 1

        for error in errors:
            error_type = error[:30] if error else "unknown"
            m["common_errors"][error_type] = m["common_errors"].get(error_type, 0) + 1

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
