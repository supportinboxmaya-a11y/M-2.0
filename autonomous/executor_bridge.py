"""Bridge: workflow nodes -> real tool execution (Phase 5) or LLM fallback."""


class ExecutorBridge:
    def __init__(self, framework=None, llm_fn=None, approve_dangerous: bool = False):
        self.fw = framework           # tools.framework.ToolFramework (optional)
        self.llm_fn = llm_fn          # callable(prompt)->str (optional)
        self.approve_dangerous = approve_dangerous

    def __call__(self, agent, node):
        """execute_fn contract: (output, verified). Never raises."""
        # On a retry, the recovery strategy leaves a reflection note that
        # tells this attempt what went wrong last time and how to adapt.
        note = getattr(node, "recovery_note", "") or ""
        hint = ("\n" + note) if note else ""
        # 1) try a real tool matching the node's category
        if self.fw is not None and node.tool:
            name = self._pick_tool(node.tool)
            if name:
                res = self.fw.execute(name, {"query": node.description,
                                             "task": node.description},
                                      caller_permissions=agent.permissions,
                                      approved=self.approve_dangerous)
                if res["ok"]:
                    return str(res["output"]), True
                # tool failed -> fall through to LLM with the error as context
                if self.llm_fn:
                    try:
                        return self.llm_fn(
                            f"{agent.system_prompt}\nTool '{name}' failed with: "
                            f"{res['error']}. Complete this task without it: "
                            f"{node.description}{hint}"), None
                    except Exception as e:
                        return f"error: {e}", False
                return f"error: {res['error']}", False
        # 2) pure-LLM step
        if self.llm_fn:
            try:
                return self.llm_fn(
                    f"{agent.system_prompt}\nTask: {node.description}{hint}"), None
            except Exception as e:
                return f"error: {e}", False
        return "error: no tool framework and no llm_fn configured", False

    def _pick_tool(self, category: str) -> str | None:
        if not self.fw:
            return None
        for t in self.fw.list():
            if t["category"] == category:
                return t["name"]
        return None
