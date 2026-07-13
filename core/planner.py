
"""
Maya 2.0 - Code Runner (Secure, Hardened)
-----------------------------------------
Executes code in a sandboxed environment:
- pattern blocklist (as before)
- scrubbed environment: executed code can no longer read the parent
  process's API keys via os.environ
- kernel resource limits: memory, CPU, process count (fork bombs),
  and max file size — one runaway snippet can't take the server down
- python runs with -I (isolated mode: no user site-packages, no
  PYTHONPATH injection)
Return shape is unchanged: {success, output, error, returncode}.
"""

import subprocess
import sys
import tempfile
import os
import re
from typing import Dict
from config.settings import WORKSPACE_DIR
from security.sandbox import Sandbox

# Dangerous patterns to block
BLOCKED_PATTERNS = [
    r"import\s+os.*system",
    r"subprocess\.call",
    r"__import__\s*\(\s*['\"]os",
    r"eval\s*\(",
    r"exec\s*\(",
    r"open\s*\(['\"]\/",
    r"shutil\.rmtree",
    r"os\.remove",
]

# Desktop-GUI libraries that cannot run on a headless server (no display).
# Trying to execute these just crashes with an obscure shared-object error
# (e.g. "libtk8.6.so: cannot open shared object file"). Instead of running
# them, we stop early and steer the work toward a real web app.
GUI_IMPORTS = [
    r"import\s+tkinter", r"from\s+tkinter", r"import\s+Tkinter",
    r"import\s+PyQt5", r"from\s+PyQt5", r"import\s+PyQt6", r"from\s+PyQt6",
    r"import\s+PySide2", r"import\s+PySide6",
    r"import\s+pygame", r"from\s+pygame",
    r"import\s+wx\b", r"import\s+kivy", r"from\s+kivy",
    r"import\s+pyglet", r"import\s+turtle", r"from\s+turtle",
]
GUI_HINT = (
    "This environment is a headless server with no display, so desktop-GUI "
    "toolkits (tkinter, PyQt, pygame, turtle, etc.) cannot run here. "
    "To build an app or UI, generate an HTML/CSS/JS web app and hand it to "
    "the web_build tool (or web_deploy for a live URL) instead of running "
    "GUI code."
)

class CodeRunner:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)
        self.max_output_size = 10000
        self.sandbox = Sandbox()

    def run(self, code: str, language: str = "python", timeout: int = 30) -> Dict:
        if not code or not code.strip():
            return {"success": False, "output": "", "error": "No code provided"}

        # Security check
        security_check = self._check_security(code)
        if not security_check["safe"]:
            return {"success": False, "output": "", "error": f"Security blocked: {security_check['reason']}"}

        if language == "python":
            return self._run_python(code, timeout)
        elif language in ["bash", "shell"]:
            return self._run_shell_safe(code, timeout)
        return {"success": False, "output": "", "error": f"Unsupported language: {language}"}

    def _check_security(self, code: str) -> Dict:
        """Dangerous code patterns check করে।"""
        for pattern in BLOCKED_PATTERNS:
            if re.search(pattern, code, re.IGNORECASE):
                return {"safe": False, "reason": f"Blocked pattern: {pattern}"}
        # Desktop-GUI code can't run headless — stop early with a useful hint
        # instead of letting it crash on a missing shared library.
        for pattern in GUI_IMPORTS:
            if re.search(pattern, code, re.IGNORECASE):
                return {"safe": False, "reason": GUI_HINT}
        return {"safe": True}

    def _run_python(self, code: str, timeout: int) -> Dict:
        """Python code safely execute করে।"""
        with tempfile.NamedTemporaryFile(
            suffix=".py", mode="w", delete=False,
            dir=self.workspace, encoding="utf-8"
        ) as f:
            f.write(code)
            tmp = f.name

        try:
            result = subprocess.run(
                [sys.executable, "-I", tmp],
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=self.workspace,
                env=self.sandbox.scrubbed_env(),
                preexec_fn=self.sandbox.resource_limiter(cpu_seconds=timeout + 5),
            )
            output = result.stdout[:self.max_output_size]
            error = result.stderr[:self.max_output_size]
            return {
                "success": result.returncode == 0,
                "output": output,
                "error": error,
                "returncode": result.returncode
            }
        except subprocess.TimeoutExpired:
            return {"success": False, "output": "", "error": f"Timeout after {timeout}s"}
        except Exception as e:
            return {"success": False, "output": "", "error": str(e)}
        finally:
            try:
                os.unlink(tmp)
            except:
                pass

    def _run_shell_safe(self, code: str, timeout: int) -> Dict:
        """Shell commands safely execute করে।"""
        # Dangerous shell commands block করি
        blocked = ["rm -rf", "mkfs", "dd if=", ":(){ :|:& };:", "chmod 777 /", "curl | sh"]
        code_lower = code.lower()
        for b in blocked:
            if b in code_lower:
                return {"success": False, "output": "", "error": f"Blocked dangerous command: {b}"}

        try:
            result = subprocess.run(
                code,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=self.workspace,
                env=self.sandbox.scrubbed_env(),
                preexec_fn=self.sandbox.resource_limiter(cpu_seconds=timeout + 5),
            )
            return {
                "success": result.returncode == 0,
                "output": result.stdout[:self.max_output_size],
                "error": result.stderr[:self.max_output_size],
                "returncode": result.returncode
            }
        except subprocess.TimeoutExpired:
            return {"success": False, "output": "", "error": "Timeout"}
        except Exception as e:
            return {"success": False, "output": "", "error": str(e)}
