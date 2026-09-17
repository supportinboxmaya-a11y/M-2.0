"""Maya 2.0 - Secure Shell Tool"""
import subprocess
from config.settings import WORKSPACE_DIR

BLOCKED_COMMANDS = [
    "rm -rf /", "rm -rf ~", "mkfs", "dd if=/dev/",
    ":(){ :|:& };:", "chmod -r 777 /", "wget | sh", "curl | sh"
]

class ShellTool:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)

    def run(self, command: str, timeout: int = 30) -> dict:
        # Block dangerous commands
        cmd_lower = command.lower()
        for blocked in BLOCKED_COMMANDS:
            if blocked in cmd_lower:
                return {"success": False, "output": "", "error": f"Blocked: {blocked}"}

        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=self.workspace
            )
            return {
                "success": result.returncode == 0,
                "output": result.stdout[:5000],
                "error": result.stderr[:2000],
                "returncode": result.returncode
            }
        except subprocess.TimeoutExpired:
            return {"success": False, "output": "", "error": "Command timed out"}
        except Exception as e:
            return {"success": False, "output": "", "error": str(e)}
