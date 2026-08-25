
"""
Maya 2.0 - Ultra Executor
--------------------------
Plan এর প্রতিটা step execute করে।
Tool calls, error handling, retry সব manage করে।
"""

import json
import time
from typing import Dict, Any, List, Optional
from tools.registry import ToolRegistry
from llm.router import LLMRouter
from llm.prompt_builder import PromptBuilder


class Executor:
    """
    Maya-র execution engine.
    - Tool calls execute করে
    - LLM দিয়ে steps handle করে
    - Automatic retry করে
    - Step dependencies handle করে
    - Execution history রাখে
    """

    def __init__(self, router: LLMRouter, tool_registry: ToolRegistry):
        self.router = router
        self.tools = tool_registry
        self.prompt_builder = PromptBuilder()
        self.execution_history: List[Dict] = []
        self.max_retries = 3

    def execute_step(self, step: Dict, context: str = "", previous_results: List[Dict] = None, stream_emitter=None) -> Dict:
        """
        একটা step execute করে। Tool বা LLM যেটা দরকার সেটা use করে।
        """
        description = step.get("description", "")
        tool_name = step.get("tool")
        tool_input = step.get("tool_input", {}) or {}
        step_num = step.get("step", "?")

        print(f"   ▶ Step {step_num}: {description[:70]}...")

        # Previous results থেকে context তৈরি
        prev_context = self._build_context(previous_results or [], context)

        # Tool input এ dynamic values inject করি
        if tool_input:
            tool_input = self._inject_context(tool_input, prev_context)

        result = None
        last_error = None

        for attempt in range(self.max_retries):
            try:
                if tool_name and self.tools.has(tool_name):
                    if stream_emitter and attempt == 0:
                        import asyncio
                        asyncio.run(stream_emitter.tool_started(tool_name, tool_input))
                    result = self._execute_tool(tool_name, tool_input, step_num, attempt)
                    if stream_emitter:
                        import asyncio
                        if result.get("success"):
                            asyncio.run(stream_emitter.tool_completed(tool_name, tool_input, result.get("result")))
                        else:
                            asyncio.run(stream_emitter.tool_failed(tool_name, tool_input, result.get("error", "Unknown error")))
                else:
                    result = self._execute_with_llm(description, prev_context, step_num)

                if result.get("success"):
                    break
                else:
                    last_error = result.get("error", "Unknown error")
                    if attempt < self.max_retries - 1:
                        print(f"     ⚠️ Attempt {attempt+1} failed, retrying...")
                        if stream_emitter:
                            import asyncio
                            asyncio.run(stream_emitter.step_retrying(step, attempt + 1))
                        time.sleep(1)

            except Exception as e:
                last_error = str(e)
                if attempt < self.max_retries - 1:
                    time.sleep(1)
                else:
                    result = {"success": False, "result": None, "error": str(e)}

        if not result:
            result = {"success": False, "result": None, "error": last_error or "Execution failed"}

        # History তে save করি
        result["step"] = step_num
        result["description"] = description
        result["tool_used"] = tool_name or "llm"
        self.execution_history.append(result)

        status = "✅" if result.get("success") else "❌"
        print(f"     {status} {str(result.get('result', result.get('error', '')))[:80]}")

        return result

    def execute_plan(self, plan: Dict, context: str = "") -> List[Dict]:
        """
        পুরো plan execute করে। Dependencies handle করে।
        """
        steps = plan.get("steps", [])
        results = []
        completed_steps = {}

        for step in steps:
            # Dependency check
            depends_on = step.get("depends_on", [])
            if depends_on:
                for dep in depends_on:
                    if dep not in completed_steps or not completed_steps[dep].get("success"):
                        print(f"   ⏭️ Skipping step {step.get('step')} - dependency {dep} not satisfied")
                        results.append({"step": step.get("step"), "success": False, "error": f"Dependency {dep} failed", "skipped": True})
                        continue

            result = self.execute_step(step, context, results)
            results.append(result)
            completed_steps[step.get("step", len(results))] = result

            # Critical step fail হলে stop
            if not result.get("success") and not step.get("optional", False):
                print(f"   🛑 Critical step failed, stopping execution")
                break

        return results

    def _execute_tool(self, tool_name: str, tool_input: Dict, step_num: Any, attempt: int) -> Dict:
        """Tool execute করে।"""
        try:
            print(f"     🔧 Using tool: {tool_name}" + (f" (attempt {attempt+1})" if attempt > 0 else ""))
            output = self.tools.run(tool_name, tool_input)
            # Many Maya tools report failures by RETURNING an error payload
            # instead of raising (e.g. read_file -> "Error: File not found",
            # writer -> {'success': False}). Treat those as step failures so
            # retry/recovery actually engages.
            failed = False
            err_text = None
            if isinstance(output, dict):
                if output.get("success") is False:
                    failed = True
                    err_text = str(output.get("error") or output)[:300]
            elif isinstance(output, str) and output.lstrip()[:6].lower() == "error:":
                failed = True
                err_text = output.strip()[:300]
            if failed:
                return {
                    "success": False,
                    "result": None,
                    "error": err_text or f"Tool '{tool_name}' reported failure",
                    "raw_output": output,
                    "tool_used": tool_name
                }
            return {
                "success": True,
                "result": str(output)[:3000] if output else "Done",
                "raw_output": output,
                "tool_used": tool_name
            }
        except Exception as e:
            return {
                "success": False,
                "result": None,
                "error": f"Tool '{tool_name}' failed: {str(e)}",
                "tool_used": tool_name
            }

    def _execute_with_llm(self, description: str, context: str, step_num: Any) -> Dict:
        """LLM দিয়ে step execute করে।"""
        system = """You are Maya's execution engine. Execute the given task precisely.
Be specific, accurate, and complete. Return ONLY valid JSON."""

        user = f"""Task: {description}
Context from previous steps: {context or 'None'}

Execute this task and return JSON:
{{
  "success": true/false,
  "result": "the actual output/answer/content",
  "summary": "brief summary of what was done",
  "next_hint": "suggestion for next step if any"
}}"""

        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ]

        try:
            response = self.router.chat(messages, max_tokens=2000)
            parsed = self._parse_json(response)
            if parsed:
                return {"success": parsed.get("success", True), "result": parsed.get("result", response), "tool_used": "llm"}
            return {"success": True, "result": response, "tool_used": "llm"}
        except Exception as e:
            return {"success": False, "result": None, "error": str(e), "tool_used": "llm"}

    def _build_context(self, previous_results: List[Dict], base_context: str = "") -> str:
        """Previous results থেকে context string তৈরি করে।

        Carries what earlier steps DID and what they produced so later steps can
        build on them instead of starting blind — this is the inter-step
        'communication' that makes multi-step goals actually chain together."""
        parts = []
        if base_context:
            parts.append(f"Base context: {base_context}")
        for r in previous_results[-5:]:  # last 5 steps
            if not r.get("success"):
                continue
            step_no = r.get("step", "?")
            did = r.get("description") or r.get("summary") or ""
            out = r.get("result", "")
            out = str(out.get("output") if isinstance(out, dict) and out.get("output") else out)
            line = f"Step {step_no}"
            if did:
                line += f" ({str(did)[:120]})"
            if out and out.strip():
                line += f" produced: {out.strip()[:1200]}"
            parts.append(line)
        return "\n".join(parts)

    def _inject_context(self, tool_input: Dict, context: str) -> Dict:
        """Tool input এ context inject করে।"""
        injected = {}
        for k, v in tool_input.items():
            if isinstance(v, str) and "{context}" in v:
                injected[k] = v.replace("{context}", context[:500])
            else:
                injected[k] = v
        return injected

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
        return self.execution_history

    def clear_history(self):
        self.execution_history = []
