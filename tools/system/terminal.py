import subprocess

class TerminalTool:
    def execute(self, command: str, cwd: str = None, timeout: int = 60) -> dict:
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
