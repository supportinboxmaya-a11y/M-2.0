"""Maya 2.0 - Secure File Writer"""
import os
from config.settings import WORKSPACE_DIR
from security.sandbox import Sandbox

class FileWriter:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)
        self.sandbox = Sandbox()
        self.max_size = 10 * 1024 * 1024  # 10MB

    def write(self, filename: str, content: str, mode: str = "w") -> dict:
        # Sandbox check
        try:
            safe_path = self.sandbox.safe_path(filename)
        except PermissionError as e:
            return {"success": False, "error": str(e)}

        if len(content.encode("utf-8")) > self.max_size:
            return {"success": False, "error": "Content too large (max 10MB)"}

        try:
            os.makedirs(os.path.dirname(safe_path), exist_ok=True)
            with open(safe_path, mode, encoding="utf-8") as f:
                f.write(content)
            return {"success": True, "path": safe_path, "size": len(content)}
        except Exception as e:
            return {"success": False, "error": str(e)}
