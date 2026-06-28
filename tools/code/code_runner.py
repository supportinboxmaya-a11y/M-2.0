"""
Maya 2.0 - Code Runner (Secure)
---------------------------------
Executes code in a sandboxed environment.
"""

import subprocess
import sys
import tempfile
import os
import re
from typing import Dict
from config.settings import WORKSPACE_DIR

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

class CodeRunner:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)
        self.max_output_size = 10000

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
                [sys.executable, tmp],
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=self.workspace,
                env={**os.environ, "PYTHONPATH": ""}
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
                cwd=self.workspace
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
