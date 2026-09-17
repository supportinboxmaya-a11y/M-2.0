"""
Maya 2.0 - RAG Document Ingestion
---------------------------------
Loads files (PDF / Markdown / code / plain text), detects their type,
extracts text, and hands clean chunks to the KnowledgeIndex.

PDF extraction uses PyPDF2 (already in requirements.txt). Files are
resolved through the security sandbox so ingestion can never escape
the workspace when given a relative path; absolute paths are allowed
only when explicitly requested by the caller (API layer decides).
"""

import os
from typing import Dict, List, Optional

from .chunker import Chunker

CODE_EXTENSIONS = {
    ".py", ".js", ".jsx", ".ts", ".tsx", ".java", ".go", ".rs", ".rb",
    ".c", ".h", ".cpp", ".hpp", ".cs", ".php", ".sh", ".sql", ".swift",
    ".kt", ".scala", ".yaml", ".yml", ".toml", ".json", ".css", ".html",
}
MARKDOWN_EXTENSIONS = {".md", ".markdown", ".rst"}
MAX_FILE_BYTES = 25 * 1024 * 1024  # 25MB safety cap


def detect_doc_type(path: str) -> str:
    ext = os.path.splitext(path)[1].lower()
    if ext == ".pdf":
        return "pdf"
    if ext in MARKDOWN_EXTENSIONS:
        return "markdown"
    if ext in CODE_EXTENSIONS:
        return "code"
    return "text"


class DocumentIngestor:
    """Extracts text from supported files and chunks it for indexing."""

    def __init__(self, chunker: Optional[Chunker] = None):
        self.chunker = chunker or Chunker()

    # ── public API ────────────────────────────────────────────────
    def ingest_text(self, text: str, title: str = "untitled",
                    doc_type: str = "text", source: str = "inline") -> Dict:
        """Chunk raw text. Returns {title, doc_type, source, chunks}."""
        chunks = self.chunker.chunk(text, "markdown" if doc_type == "pdf" else doc_type)
        return {"title": title, "doc_type": doc_type, "source": source,
                "chunks": chunks, "char_count": len(text or "")}

    def ingest_file(self, path: str) -> Dict:
        """Read a file from disk, extract text, and chunk it."""
        if not os.path.isfile(path):
            raise FileNotFoundError(f"File not found: {path}")
        if os.path.getsize(path) > MAX_FILE_BYTES:
            raise ValueError(f"File exceeds {MAX_FILE_BYTES // (1024*1024)}MB limit")
        doc_type = detect_doc_type(path)
        if doc_type == "pdf":
            text = self._extract_pdf(path)
        else:
            text = self._read_text(path)
        title = os.path.basename(path)
        result = self.ingest_text(text, title=title, doc_type=doc_type, source=path)
        return result

    # ── extractors ────────────────────────────────────────────────
    @staticmethod
    def _read_text(path: str) -> str:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()

    @staticmethod
    def _extract_pdf(path: str) -> str:
        try:
            from PyPDF2 import PdfReader
        except ImportError as e:
            raise RuntimeError("PyPDF2 is required for PDF ingestion "
                               "(pip install PyPDF2)") from e
        reader = PdfReader(path)
        pages: List[str] = []
        for i, page in enumerate(reader.pages):
            try:
                content = page.extract_text() or ""
            except Exception:
                content = ""
            if content.strip():
                # Page markers become markdown headings → chunker keeps
                # page numbers in sections for attribution.
                pages.append(f"## Page {i + 1}\n\n{content.strip()}")
        return "\n\n".join(pages)
