"""
Maya 2.0 - Ultra Reasoner
--------------------------
Maya-র চিন্তা করার engine।
Deep analysis, decision making, tool selection সব এখানে।
"""

import json
from typing import Dict, List, Optional, Tuple
from llm.router import LLMRouter
from llm.prompt_builder import PromptBuilder


class Reasoner:
    """
    Maya-র reasoning engine.
    - যেকোনো সমস্যা গভীরভাবে বিশ্লেষণ করে
    - কোন tool use করবে সিদ্ধান্ত নেয়
    - কোন LLM provider সবচেয়ে ভালো হবে বেছে নেয়
    - Chain-of-thought reasoning করে
    - Failure root cause বের করে
    """

    def __init__(self, router: LLMRouter):
        self.router = router
        self.prompt_builder = PromptBuilder()
        self.reasoning_log: List[Dict] = []

    def think(self, problem: str, context: str = "", depth: str = "deep") -> Dict:
        """
        কোনো সমস্যা নিয়ে গভীরভাবে চিন্তা করে।
        depth: quick | normal | deep
        """
        system = """You are Maya's reasoning core — the most intelligent part of the system.

You think step by step, like a genius problem solver.
You consider multiple approaches before deciding.
You are honest about uncertainty.
You identify the root cause of problems, not just symptoms.

Always respond with ONLY valid JSON."""

        depth_instruction = {
            "quick": "Give a quick, concise analysis in 2-3 points.",
            "normal": "Give a balanced analysis with clear reasoning.",
            "deep": "Give an extremely thorough analysis. Consider all angles, edge cases, and implications."
        }.get(depth, "Give a thorough analysis.")

        user = f"""Problem/Question: {problem}
Context: {context or 'None'}

{depth_instruction}

Return JSON:
{{
  "understanding": "what exactly needs to be solved",
  "key_insights": ["insight1", "insight2"],
  "approach": "best approach to solve this",
  "reasoning_steps": [
    {{"step": 1, "thought": "...", "conclusion": "..."}}
  ],
  "final_answer": "the actual answer or solution",
  "confidence": "high|medium|low",
  "alternatives": ["alternative approach 1", "alternative approach 2"],
  "warnings": ["potential issues to watch out for"]
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        response = self.router.chat(messages, max_tokens=3000)
        result = self._parse_json(response)

        if not result:
            result = {"understanding": problem, "final_answer": response, "confidence": "medium"}

        self.reasoning_log.append({"problem": problem, "result": result})
        return result

    def decide_tool(self, task: str, available_tools: List[str], context: str = "") -> Tuple[Optional[str], Dict]:
        """
        কোন tool use করবে এবং কী input দেবে সেটা বেছে নেয়।
        Returns: (tool_name, tool_input)
        """
        system = """You are Maya's tool selection expert.
Given a task, choose the BEST tool and its exact input parameters.
If no tool is needed, return null for tool.
Always respond with ONLY valid JSON."""

        user = f"""Task: {task}
Context: {context or 'None'}
Available tools: {json.dumps(available_tools)}

Choose the best tool. Return JSON:
{{
  "reasoning": "why this tool is best",
  "tool": "tool_name or null",
  "tool_input": {{"param": "value"}},
  "fallback_tool": "backup tool if primary fails or null",
  "no_tool_reason": "why no tool needed (if tool is null)"
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        response = self.router.chat(messages)
        result = self._parse_json(response)

        if result:
            return result.get("tool"), result.get("tool_input", {})
        return None, {}

    def analyze_failure(self, goal: str, error: str, steps_done: List[Dict], context: str = "") -> Dict:
        """
        কোনো failure এর root cause বের করে এবং recovery strategy দেয়।
        """
        system = """You are Maya's failure analysis expert.
When something goes wrong, you find the ROOT CAUSE and suggest the BEST recovery.
Be specific and actionable. Never say "try again" without explaining HOW to try differently.
Always respond with ONLY valid JSON."""

        steps_summary = "\n".join([
            f"Step {i+1}: {s.get('description', '')} → {'✅' if s.get('success') else '❌'} {s.get('error', s.get('result', ''))}"
            for i, s in enumerate(steps_done)
        ])

        user = f"""Goal: {goal}
Error: {error}
Steps attempted:
{steps_summary or 'No steps completed'}
Context: {context or 'None'}

Return JSON:
{{
  "root_cause": "exact root cause of the failure",
  "error_type": "network|permission|logic|timeout|api|data|unknown",
  "is_recoverable": true/false,
  "recovery_strategy": "specific steps to recover",
  "alternative_approaches": [
    {{"approach": "...", "pros": "...", "cons": "..."}}
  ],
  "lessons_learned": "what to avoid next time",
  "recommended_action": "retry|replan|abort|ask_user"
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        response = self.router.chat(messages, max_tokens=2000)
        return self._parse_json(response) or {
            "root_cause": error,
            "error_type": "unknown",
            "is_recoverable": True,
            "recovery_strategy": "retry with different approach",
            "recommended_action": "replan"
        }

    def evaluate_result(self, goal: str, result: str, context: str = "") -> Dict:
        """
        কোনো result কতটা ভালো সেটা evaluate করে।
        """
        system = """You are Maya's result evaluation expert.
Critically assess if a result truly satisfies the original goal.
Be strict but fair. Consider quality, completeness, and accuracy.
Always respond with ONLY valid JSON."""

        user = f"""Goal: {goal}
Result: {result}
Context: {context or 'None'}

Return JSON:
{{
  "satisfies_goal": true/false,
  "quality_score": <0-10>,
  "completeness": "complete|partial|incomplete",
  "what_was_achieved": "...",
  "what_is_missing": "... or null if complete",
  "improvement_suggestions": ["suggestion1"],
  "verdict": "success|partial_success|failure"
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        response = self.router.chat(messages)
        return self._parse_json(response) or {
            "satisfies_goal": True,
            "quality_score": 7,
            "verdict": "success"
        }

    def choose_best_provider(self, task_type: str, available_providers: List[str]) -> str:
        """
        Task এর ধরন অনুযায়ী সেরা LLM provider বেছে নেয়।
        """
        provider_strengths = {
            "groq": ["fast", "coding", "quick_answer", "simple"],
            "gemini": ["research", "analysis", "multimodal", "long_context"],
            "openai": ["reasoning", "complex", "creative", "coding"],
            "claude": ["analysis", "writing", "careful", "nuanced"],
            "deepseek": ["coding", "math", "technical"],
        }

        task_lower = task_type.lower()
        best_score = -1
        best_provider = available_providers[0] if available_providers else "groq"

        for provider in available_providers:
            strengths = provider_strengths.get(provider, [])
            score = sum(1 for s in strengths if s in task_lower)
            if score > best_score:
                best_score = score
                best_provider = provider

        return best_provider

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

    def get_reasoning_log(self) -> List[Dict]:
        return self.reasoning_log
