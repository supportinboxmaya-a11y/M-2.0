from typing import List, Dict
from .long_term import LongTermMemory

class SemanticMemory:
    """Stores facts, concepts, and knowledge."""

    def __init__(self):
        self.store = LongTermMemory()

    def add_fact(self, fact: str, topic: str = "general"):
        self.store.add(fact, memory_type=f"semantic:{topic}")

    def search_facts(self, query: str, limit: int = 5) -> List[Dict]:
        results = self.store.search(query, limit=limit)
        return [r for r in results if "semantic" in r.get("type", "")]
