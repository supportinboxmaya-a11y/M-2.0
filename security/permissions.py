from typing import List

class PermissionManager:
    def __init__(self):
        self.allowed_tools: List[str] = ["web_search", "web_scrape", "read_file", "write_file", "run_code", "run_shell"]
        self.blocked_tools: List[str] = []

    def is_allowed(self, tool: str) -> bool:
        if tool in self.blocked_tools:
            return False
        return True

    def block_tool(self, tool: str):
        self.blocked_tools.append(tool)

    def allow_tool(self, tool: str):
        if tool in self.blocked_tools:
            self.blocked_tools.remove(tool)
