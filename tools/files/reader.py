"""Maya 2.0 - Secure File Reader"""
import os
from config.settings import WORKSPACE_DIR
from security.sandbox import Sandbox

class FileReader:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)
        self.sandbox = Sandbox()
        self.max_size = 5 * 1024 * 1024  # 5MB

    def read(self, filename: str) -> str:
        # Sandbox check
        try:
            safe_path = self.sandbox.safe_path(filename)
        except PermissionError as e:
            return f"Error: {e}"

        if not os.path.exists(safe_path):
            return f"Error: File not found: {filename}"

        if os.path.getsize(safe_path) > self.max_size:
            return f"Error: File too large (max 5MB)"

        try:
            with open(safe_path, "r", encoding="utf-8", errors="replace") as f:
                return f.read()
        except Exception as e:
            return f"Error reading file: {e}"
