from typing import List, Dict, Optional

class VectorMemory:
    """Vector-based semantic search memory (uses ChromaDB if available)."""

    def __init__(self):
        self.collection = None
        self._init()

    def _init(self):
        try:
            import chromadb
            client = chromadb.Client()
            self.collection = client.get_or_create_collection("maya_memory")
        except:
            self.collection = None
            self._fallback = []

    def add(self, content: str, doc_id: str = None, metadata: Dict = None):
        if self.collection:
            import uuid
            self.collection.add(
                documents=[content],
                ids=[doc_id or str(uuid.uuid4())[:8]],
                metadatas=[metadata or {}]
            )
        else:
            self._fallback.append({"content": content, "metadata": metadata or {}})

    def search(self, query: str, limit: int = 5) -> List[Dict]:
        if self.collection:
            results = self.collection.query(query_texts=[query], n_results=limit)
            docs = results.get("documents", [[]])[0]
            return [{"content": d} for d in docs]
        else:
            return [m for m in self._fallback if query.lower() in m["content"].lower()][:limit]
