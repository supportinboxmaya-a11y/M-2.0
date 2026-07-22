import subprocess

# Same blocked-command list as tools/system/shell.py
BLOCKED_COMMANDS = [
    "rm -rf /", "rm -rf ~", "mkfs", "dd if=/dev/",
    ":(){ :|:& };:", "chmod -r 777 /", "wget | sh", "curl | sh"
]


class TerminalTool:
    def execute(self, command: str, cwd: str = None, timeout: int = 60) -> dict:
        # Block dangerous commands (mirrors ShellTool)
        cmd_lower = command.lower()
        for blocked in BLOCKED_COMMANDS:
            if blocked in cmd_lower:
                return {"success": False, "output": "", "error": f"Blocked: {blocked}"}

        try:
            result = subprocess.run(
                command, shell=True, capture_output=True,
                text=True, cwd=cwd, timeout=timeout
            )
            return {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr,
                "returncode": result.returncode
            }
        except Exception as e:
            return {"success": False, "output": "", "error": str(e), "returncode": -1}
