"""
Maya 2.0 - RAG Retriever (Facade)
---------------------------------
Single entry point for the whole RAG pipeline:

    rag = RAGRetriever()
    rag.ingest_text("...facts...", title="notes")
    rag.ingest_file("docs/guide.pdf")
    hits = rag.search("how does X work", limit=5)          # ranked hits
    ctx  = rag.get_context("how does X work")              # LLM-ready

Keyword and vector indexes are kept in sync on every write. The whole
module works with zero optional dependencies (FTS5 + TF-IDF) and gets
better automatically when chromadb / PyPDF2 are installed.
"""

import threading
from typing import Dict, List, Optional

from .chunker import Chunker
from .ingestion import DocumentIngestor
from .index import KnowledgeIndex
from .vectors import VectorIndex
from .attribution import HybridSearch, SourceAttributor


class RAGRetriever:
    """Facade over ingestion → index → hybrid search → attribution."""

    _instance = None
    _instance_lock = threading.Lock()

    def __init__(self, chunk_size: int = 900, overlap: int = 150):
        self.chunker = Chunker(chunk_size=chunk_size, overlap=overlap)
        self.ingestor = DocumentIngestor(self.chunker)
        self.index = KnowledgeIndex()
        self.vectors = VectorIndex(knowledge_index=self.index)
        self.hybrid = HybridSearch(self.index, self.vectors)
        self.attributor = SourceAttributor(self.index)

    # ── singleton for API layer ───────────────────────────────────
    @classmethod
    def shared(cls) -> "RAGRetriever":
        with cls._instance_lock:
            if cls._instance is None:
                cls._instance = cls()
            return cls._instance

    # ── ingestion ─────────────────────────────────────────────────
    def ingest_text(self, text: str, title: str = "untitled",
                    doc_type: str = "text", source: str = "inline",
                    metadata: Optional[Dict] = None) -> Dict:
        doc = self.ingestor.ingest_text(text, title=title,
                                        doc_type=doc_type, source=source)
        return self._store(doc, metadata)

    def ingest_file(self, path: str, metadata: Optional[Dict] = None) -> Dict:
        doc = self.ingestor.ingest_file(path)
        return self._store(doc, metadata)

    def _store(self, doc: Dict, metadata: Optional[Dict]) -> Dict:
        if not doc["chunks"]:
            return {"success": False, "error": "No extractable text found"}
        result = self.index.add_document(
            title=doc["title"], chunks=doc["chunks"], doc_type=doc["doc_type"],
            source=doc["source"], char_count=doc["char_count"],
            metadata=metadata)
        if not result["deduplicated"]:
            if result.get("version", 1) > 1:      # replaced → purge old vectors
                self.vectors.remove_document(result["doc_id"])
            self.vectors.add_chunks([
                {"chunk_id": f"{result['doc_id']}:{i}",
                 "doc_id": result["doc_id"], "seq": i,
                 "content": c["content"], "section": c.get("section", ""),
                 "start": c.get("start", 0), "end": c.get("end", 0)}
                for i, c in enumerate(doc["chunks"])])
        result.update({"success": True, "title": doc["title"],
                       "doc_type": doc["doc_type"]})
        return result

    # ── retrieval ─────────────────────────────────────────────────
    def search(self, query: str, limit: int = 5,
               mode: str = "hybrid") -> List[Dict]:
        """Ranked, source-attributed hits."""
        hits = self.hybrid.search(query, limit=limit, mode=mode)
        return self.attributor.attribute(hits)

    def get_context(self, query: str, limit: int = 5, mode: str = "hybrid",
                    max_chars: int = 6000) -> Dict:
        """LLM-ready numbered context block + citation list."""
        cited = self.search(query, limit=limit, mode=mode)
        return {"query": query,
                "context": self.attributor.build_context(cited, max_chars),
                "citations": self.attributor.format_citations(cited)}

    # ── management ────────────────────────────────────────────────
    def delete_document(self, doc_id: str) -> bool:
        ok = self.index.delete_document(doc_id)
        if ok:
            self.vectors.remove_document(doc_id)
        return ok

    def list_documents(self, limit: int = 200) -> List[Dict]:
        return self.index.list_documents(limit=limit)

    def stats(self) -> Dict:
        s = self.index.stats()
        s["vector_engine"] = self.vectors.engine
        return s
