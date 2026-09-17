from typing import List, Dict
from collections import deque

class ShortTermMemory:
    def __init__(self, capacity: int = 20):
        self.memory = deque(maxlen=capacity)

    def add(self, content: str, metadata: Dict = None):
        self.memory.append({"content": content, "metadata": metadata or {}})

    def get_all(self) -> List[Dict]:
        return list(self.memory)

    def clear(self):
        self.memory.clear()

    def search(self, query: str) -> List[Dict]:
        return [m for m in self.memory if query.lower() in m["content"].lower()]
