"""Four-layer memory facade (Phase 2, per MAYA 3.0 spec).

Conversation / User / Project / Semantic — routed onto the EXISTING
stores via memory_manager. A thin, additive layer; nothing replaced.
"""


class MemoryLayers:
    def __init__(self, manager):
        """manager: the existing memory_manager.MemoryManager instance."""
        self.m = manager

    # 1. Conversation memory (short-term context)
    def conversation_add(self, role: str, message: str) -> None:
        if role == "user":
            self.m.short_term.add_user_message(message)
        else:
            self.m.short_term.add_assistant_message(message)

    def conversation_context(self) -> str:
        return self.m.get_context()

    # 2. User memory (preferences, identity)
    def user_remember(self, content: str, kind: str = "preference") -> str:
        return self.m.add(content, memory_type=kind, metadata={"layer": "user"})

    def user_recall(self, query: str, limit: int = 5) -> list:
        return self.m.search(query, limit=limit, memory_type="preference")

    # 3. Project memory
    def project_remember(self, content: str, project: str) -> str:
        return self.m.add(content, memory_type="project", metadata={"project": project})

    def project_recall(self, query: str, limit: int = 5) -> list:
        return self.m.search(query, limit=limit, memory_type="project")

    # 4. Long-term semantic (facts + vectors, RAG-ready)
    def semantic_remember(self, fact: str, topic: str = "general") -> None:
        self.m.add_fact(fact, topic)

    def semantic_recall(self, query: str, limit: int = 5) -> list:
        return self.m.search_facts(query, limit=limit)
