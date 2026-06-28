from typing import List, Dict, Optional

class PromptBuilder:
    """Builds prompts for different Maya tasks."""

    SYSTEM_BASE = """You are Maya, an autonomous AI agent. You are intelligent, precise, and goal-oriented.
You follow a Plan → Execute → Verify → Learn workflow.
Always respond in valid JSON when asked for structured output."""

    def planning_prompt(self, goal: str, context: str = "", history: str = "") -> List[Dict]:
        system = self.SYSTEM_BASE + "\nYour job is to create a step-by-step plan to achieve the given goal."
        user = f"""Goal: {goal}

Context: {context or 'None'}
Previous attempts: {history or 'None'}

Create a JSON plan with this structure:
{{
  "reasoning": "why you chose these steps",
  "estimated_complexity": "low|medium|high",
  "steps": [
    {{"step": 1, "description": "...", "tool": "tool_name or null", "tool_input": {{...}} or null}}
  ]
}}"""
        return [{"role": "system", "content": system}, {"role": "user", "content": user}]

    def execution_prompt(self, step: str, context: str = "") -> List[Dict]:
        system = self.SYSTEM_BASE + "\nExecute the given step and return the result."
        user = f"Step: {step}\nContext: {context or 'None'}\n\nExecute and return result as JSON: {{\"result\": \"...\", \"success\": true/false}}"
        return [{"role": "system", "content": system}, {"role": "user", "content": user}]

    def verification_prompt(self, goal: str, result: str) -> List[Dict]:
        system = self.SYSTEM_BASE + "\nVerify if the result satisfies the goal."
        user = f"""Goal: {goal}
Result: {result}

Return JSON: {{"success": true/false, "reason": "...", "missing": "what is missing if failed"}}"""
        return [{"role": "system", "content": system}, {"role": "user", "content": user}]

    def reasoning_prompt(self, problem: str, context: str = "") -> List[Dict]:
        system = self.SYSTEM_BASE + "\nAnalyze the problem deeply and provide reasoning."
        user = f"Problem: {problem}\nContext: {context or 'None'}\n\nProvide detailed reasoning and solution."
        return [{"role": "system", "content": system}, {"role": "user", "content": user}]

    def recovery_prompt(self, goal: str, error: str, previous_steps: str) -> List[Dict]:
        system = self.SYSTEM_BASE + "\nA task failed. Analyze the failure and suggest a recovery strategy."
        user = f"""Goal: {goal}
Error: {error}
Previous steps: {previous_steps}

Return JSON: {{"analysis": "...", "recovery_strategy": "...", "new_steps": [...]}}"""
        return [{"role": "system", "content": system}, {"role": "user", "content": user}]

    def learning_prompt(self, task: str, result: str, success: bool) -> List[Dict]:
        system = self.SYSTEM_BASE + "\nExtract lessons learned from this task execution."
        user = f"""Task: {task}
Result: {result}
Success: {success}

Return JSON: {{"lesson": "...", "pattern": "...", "future_tip": "..."}}"""
        return [{"role": "system", "content": system}, {"role": "user", "content": user}]
