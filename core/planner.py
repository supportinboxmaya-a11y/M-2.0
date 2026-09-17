
"""
Maya 2.0 - Ultra Planner
-------------------------
Goal থেকে intelligent, multi-step plan তৈরি করে।
Context, memory, past experience সব বিবেচনা করে।
"""

import json
from typing import List, Dict, Optional
from llm.router import LLMRouter
from llm.prompt_builder import PromptBuilder


class Planner:
    """
    Maya-র planning engine.
    - Goal বিশ্লেষণ করে
    - Sub-tasks এ ভাগ করে
    - প্রতিটা step এর জন্য সঠিক tool বেছে নেয়
    - Past experience থেকে শেখে
    - Complex goal হলে hierarchical plan বানায়
    """

    AVAILABLE_TOOLS = [
        "web_search", "web_scrape", "read_file", "write_file",
        "run_code", "run_shell", "list_files", "delete_file",
        "run_terminal", "list_processes", "web_build", "web_deploy"
    ]

    def __init__(self, router: LLMRouter):
        self.router = router
        self.prompt_builder = PromptBuilder()
        self.plan_history: List[Dict] = []

    def plan(self, goal: str, context: str = "", memory_hints: str = "", past_failures: str = "") -> Dict:
        """
        Goal থেকে detailed execution plan তৈরি করে।
        """
        system = """You are Maya's ultra-intelligent planning engine.

Your job is to analyze a goal deeply and create the BEST possible step-by-step execution plan.

Rules:
1. Break complex goals into small, executable steps
2. Each step must have a clear action and expected output
3. Choose the RIGHT tool for each step
4. Consider dependencies between steps
5. If a step might fail, add a verification step after it
6. Think like a senior engineer solving this problem

CRITICAL rules for run_code (read carefully — most failures come from breaking these):
- Every run_code step runs in a BRAND-NEW, ISOLATED Python process. Nothing carries over between run_code steps: variables, functions, imports, and state from an earlier run_code call DO NOT exist in a later one.
- Therefore, when a goal needs code (e.g. "build a calculator app", "write a script"), write the ENTIRE program in ONE single run_code step: all imports, all function definitions, AND the code that calls/tests them, together in one self-contained snippet that runs top to bottom and prints its result.
- NEVER split a program across multiple run_code steps (do not define a function in one step and call it in another — it will fail with NameError).
- Prefer the fewest steps possible. For a typical "build/write me a <program>" goal, a single run_code step that contains the complete, runnable program (with a small demo/test at the bottom) is the correct plan.
- Make the code complete and runnable on the first try: include every definition it uses, handle obvious edge cases, and end with a demonstration so its output is visible.

CRITICAL rules for building apps, websites, or any UI (read carefully):
- This runs on a HEADLESS SERVER with no screen. Desktop-GUI toolkits (tkinter, PyQt, PySide, pygame, turtle, kivy, wx) CANNOT run here — run_code on such code crashes with errors like "libtk8.6.so: cannot open shared object file". NEVER use run_code to build a GUI/desktop app.
- To build ANY app, website, tool, game, dashboard, or UI, you MUST use the web_build tool. Do NOT use write_file for this, and do NOT use run_code. write_file writes ONE file at a time and is the wrong tool for delivering a web app — it will fail the goal.
- Put ALL the files (index.html, styles.css, app.js, etc.) into a SINGLE web_build step as one {path: content} map. web_build packages them together and returns a zip; web_deploy then publishes them and returns a live URL. Keep it to at most two steps: one web_build, then one web_deploy.
- Prefer a single self-contained index.html (inline CSS and JS inside the one file) unless the goal specifically needs separate files — fewer files means fewer things to go wrong.
- The tool_input for web_build must look like this shape:
  {"name": "weather_site", "files": {"index.html": "<!doctype html>...full page..."}}
  and web_deploy: {"name": "weather_site"}
- The user must end up with a live link (or a downloadable zip) — never console text, never a single written file.

Example of a CORRECT plan for "build a weather website and deploy it":
  step 1 — web_build, tool_input {"name":"weather_site","files":{"index.html":"<full self-contained page with input, button, and inline JS that fetches weather>"}}
  step 2 — web_deploy, tool_input {"name":"weather_site"}
Do NOT add write_file or run_code steps to a web-app plan.

Available tools:
- web_search: Search the internet for information
- web_scrape: Read content from a specific URL
- read_file: Read a file from disk
- write_file: Write content to a file
- run_code: Execute Python code (text/logic only — NOT for GUIs or apps)
- run_shell: Run shell/bash commands
- run_terminal: Execute terminal commands
- list_files: List files in a directory
- delete_file: Delete a file
- web_build: Package a set of {path: content} web files into a project + zip (use this to build apps/websites)
- web_deploy: Deploy a built web project to the internet and return a live URL

Always respond with ONLY valid JSON, no extra text."""

        user = f"""Goal: {goal}

Available context: {context or 'None'}
Relevant memories: {memory_hints or 'None'}
Previous failures to avoid: {past_failures or 'None'}

Create the most intelligent and complete plan. Return JSON:
{{
  "goal_analysis": "deep analysis of what needs to be done",
  "complexity": "low|medium|high|very_high",
  "approach": "overall strategy to achieve this goal",
  "estimated_steps": <number>,
  "steps": [
    {{
      "step": <number>,
      "title": "short title",
      "description": "detailed description of what to do",
      "tool": "tool_name or null if LLM can handle it",
      "tool_input": {{"param": "value"}} or null,
      "expected_output": "what we expect from this step",
      "on_failure": "what to do if this step fails",
      "depends_on": [<step numbers this depends on>]
    }}
  ],
  "success_criteria": "how to know when the goal is fully achieved",
  "risks": ["potential risks or challenges"]
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        response = self.router.chat(messages, max_tokens=4000)
        plan = self._parse_json(response)

        if not plan:
            plan = self._fallback_plan(goal)

        self.plan_history.append({"goal": goal, "plan": plan})
        return plan

    def replan(self, goal: str, error: str, completed_steps: List[Dict], failed_step: Dict) -> Dict:
        """
        কোনো step fail হলে intelligent recovery plan তৈরি করে।
        """
        system = """You are Maya's recovery planning engine.
A task failed. Analyze what went wrong and create a smart recovery plan.
Do NOT repeat the same approach that failed.
Think of alternative strategies, different tools, or different approaches.
Always respond with ONLY valid JSON."""

        completed_summary = "\n".join([
            f"Step {s.get('step', i+1)}: {s.get('description', '')} → {s.get('result', 'done')}"
            for i, s in enumerate(completed_steps)
        ])

        user = f"""Original Goal: {goal}

What was completed:
{completed_summary or 'Nothing completed yet'}

Failed step: {json.dumps(failed_step, indent=2)}
Error: {error}

Create a smart recovery plan. Return JSON:
{{
  "failure_analysis": "what went wrong and why",
  "recovery_strategy": "new approach to try",
  "skip_completed": true,
  "new_steps": [
    {{
      "step": <number>,
      "title": "short title",
      "description": "what to do differently",
      "tool": "tool_name or null",
      "tool_input": {{}},
      "expected_output": "expected result"
    }}
  ]
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        response = self.router.chat(messages, max_tokens=2000)
        return self._parse_json(response) or {
            "failure_analysis": error,
            "recovery_strategy": "retry with different approach",
            "new_steps": [{"step": 1, "title": "Retry", "description": goal, "tool": None, "tool_input": None, "expected_output": "success"}]
        }

    def decompose_goal(self, goal: str) -> List[str]:
        """
        Complex goal কে sub-goals এ ভাগ করে।
        """
        system = "You are a goal decomposition expert. Break complex goals into simple sub-goals. Return ONLY a JSON array of strings."
        user = f"Decompose this goal into 2-5 sub-goals: {goal}"
        messages = [{"role": "system", "content": system}, {"role": "user", "content": user}]
        response = self.router.chat(messages)
        result = self._parse_json(response)
        if isinstance(result, list):
            return result
        return [goal]

    def estimate_complexity(self, goal: str) -> str:
        """Goal এর complexity estimate করে।"""
        words = goal.lower().split()
        complex_keywords = ["research", "analyze", "build", "create", "develop", "implement", "compare", "scrape", "automate"]
        simple_keywords = ["what", "who", "when", "define", "explain"]
        if any(k in words for k in complex_keywords):
            return "high"
        if any(k in words for k in simple_keywords):
            return "low"
        return "medium"

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

    def _fallback_plan(self, goal: str) -> Dict:
        return {
            "goal_analysis": goal,
            "complexity": self.estimate_complexity(goal),
            "approach": "Direct LLM execution",
            "estimated_steps": 1,
            "steps": [{
                "step": 1,
                "title": "Execute Goal",
                "description": goal,
                "tool": None,
                "tool_input": None,
                "expected_output": "Goal achieved",
                "on_failure": "retry",
                "depends_on": []
            }],
            "success_criteria": "Goal completed successfully",
            "risks": []
        }

