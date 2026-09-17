import os
import shutil
from typing import List, Dict
from config.settings import WORKSPACE_DIR

class FileManager:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)

    def list_files(self, path: str = ".") -> List[str]:
        target = os.path.join(self.workspace, path)
        if os.path.exists(target):
            return os.listdir(target)
        return []

    def delete(self, filename: str) -> Dict:
        target = os.path.join(self.workspace, filename)
        try:
            if os.path.isfile(target):
                os.remove(target)
            elif os.path.isdir(target):
                shutil.rmtree(target)
            return {"success": True, "deleted": filename}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def create_dir(self, dirname: str) -> Dict:
        target = os.path.join(self.workspace, dirname)
        os.makedirs(target, exist_ok=True)
        return {"success": True, "path": target}
