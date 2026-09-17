"""Maya 2.0 - Enterprise RAG package.

Hybrid retrieval (FTS5 BM25 keyword + vector semantic search with RRF
fusion), document ingestion (PDF/Markdown/code/text), persistent
knowledge index with dedup + versioning, and source attribution.
"""

from .chunker import Chunker
from .ingestion import DocumentIngestor, detect_doc_type
from .index import KnowledgeIndex, RAG_DB_FILE
from .vectors import VectorIndex
from .attribution import HybridSearch, SourceAttributor
from .retriever import RAGRetriever

__all__ = [
    "Chunker", "DocumentIngestor", "detect_doc_type",
    "KnowledgeIndex", "RAG_DB_FILE", "VectorIndex",
    "HybridSearch", "SourceAttributor", "RAGRetriever",
]
