"""
Maya 2.0 - Tool Creator
------------------------
Lets Maya write and register a brand-new tool for itself, mid-task,
instead of being limited to whatever tools it started with.

This reuses two things that already existed rather than inventing new
infrastructure:
  - skills/plugin_loader.py's install_from_code() — the same mechanism
    already used by POST /api/v1/plugins/install-code — to actually
    parse, save, and load the generated code as a plugin.
  - human/approval.py's ApprovalManager — the same human-approval gate
    already used for other risky actions (POST /api/v1/agent/run etc.),
    so a person can review generated code on the Approvals page before
    it's ever loaded, exactly like any other risky action.

Safety note: install_from_code() loads the plugin's code in-process
(importlib exec_module), the same way a hand-written plugin file does.
That means this is NOT a sandboxed execution — a static AST scan below
blocks obviously dangerous constructs (shelling out, raw sockets, eval)
as a first line of defense, but it is not a substitute for the approval
gate. Both layers are on by default.
"""
import ast


# Anything that could reach outside the process (network, subprocess,
# raw eval) or destroy data outright. Not exhaustive — a determined
# attacker could still obfuscate around a static scan — which is why
# this is paired with human approval rather than relied on alone.
_BLOCKED_CALLS = {
    "os.system", "os.popen", "os.execv", "os.execve", "os.execl",
    "os.remove", "os.unlink", "os.rmdir", "os.removedirs",
    "shutil.rmtree", "eval", "exec", "__import__", "compile",
}
_BLOCKED_MODULES = {
    "subprocess", "socket", "ctypes", "shutil", "pty",
    "ftplib", "telnetlib", "smtplib",
}


def scan_risk(code: str) -> list:
    """Static AST scan for obviously dangerous constructs. Returns a
    list of human-readable issues; empty list means it looked clean."""
    issues = []
    try:
        tree = ast.parse(code)
    except SyntaxError as e:
        return [f"syntax error: {e}"]

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                top = alias.name.split(".")[0]
                if top in _BLOCKED_MODULES:
                    issues.append(f"imports blocked module: {alias.name}")
        elif isinstance(node, ast.ImportFrom):
            top = (node.module or "").split(".")[0]
            if top in _BLOCKED_MODULES:
                issues.append(f"imports blocked module: {node.module}")
        elif isinstance(node, ast.Call):
            fn = node.func
            name = None
            if isinstance(fn, ast.Attribute) and isinstance(fn.value, ast.Name):
                name = f"{fn.value.id}.{fn.attr}"
            elif isinstance(fn, ast.Name):
                name = fn.id
            if name in _BLOCKED_CALLS:
                issues.append(f"calls blocked function: {name}")
    return issues


class ToolCreator:
    def __init__(self, plugin_loader, approval=None):
        self.plugin_loader = plugin_loader
        self.approval = approval  # human.approval.ApprovalManager, or None

    def create_tool(self, name: str = "", code: str = "", reason: str = "", **kwargs) -> str:
        """Write and register a brand-new tool.

        `code` must define register_tools(registry), exactly like a
        hand-written plugin file — this is the same contract
        skills/plugin_loader.py already enforces, just triggered by the
        agent itself instead of a person pasting code into the UI.
        """
        if not name or not name.strip():
            return "Error: tool name is required"
        if not code or not code.strip():
            return "Error: tool code is required"

        issues = scan_risk(code)
        if issues:
            return "Blocked by safety scan — will not create this tool: " + "; ".join(issues)

        if self.approval is not None and self.approval.needs_approval(
            f"create_tool:{name}", risk_level="high"
        ):
            approved = self.approval.request_approval(
                action=f"Create new tool '{name}'",
                reason=reason or "(Maya did not give a reason)",
                risk_level="high",
            )
            if not approved:
                return f"Not created — human approval denied for tool '{name}'"

        try:
            info = self.plugin_loader.install_from_code(name, code)
        except ValueError as e:
            return f"Error: {e}"

        tools = info.get("registered_tools", [])
        if not tools:
            return f"Plugin '{name}' loaded but registered no tools — check register_tools(registry) actually calls registry.register(...)"
        return f"Created and registered new tool(s): {', '.join(tools)}. They're usable immediately, including for the rest of this task."
