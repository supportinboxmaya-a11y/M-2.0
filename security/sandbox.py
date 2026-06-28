import os
from config.settings import WORKSPACE_DIR

class Sandbox:
    """Restricts file operations to workspace directory."""

    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)

    def safe_path(self, path: str) -> str:
        full = os.path.abspath(os.path.join(self.workspace, path))
        if not full.startswith(self.workspace):
            raise PermissionError(f"Access denied: {path} is outside workspace")
        return full

    def is_safe_path(self, path: str) -> bool:
        try:
            self.safe_path(path)
            return True
        except PermissionError:
            return False
