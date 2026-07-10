"""Phase 11 RAG tests — offline, zero optional dependencies required."""
import os, sys, types, tempfile, shutil
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Stub optional heavy deps so tests run on any machine (Colab/CI/local)
for _name in ("loguru", "dotenv", "chromadb"):
    if _name not in sys.modules:
        try:
            __import__(_name)
        except ImportError:
            _m = types.ModuleType(_name)
            if _name == "loguru":
                class _L:
                    def __getattr__(self, k): return lambda *a, **kw: None
                _m.logger = _L()
            if _name == "dotenv":
                _m.load_dotenv = lambda *a, **kw: None
            sys.modules[_name] = _m

from rag.chunker import Chunker
from rag.ingestion import DocumentIngestor, detect_doc_type
from rag.index import KnowledgeIndex
from rag.vectors import VectorIndex
from rag.attribution import HybridSearch, SourceAttributor

_tmp = tempfile.mkdtemp(prefix="maya_rag_test_")
_DB = os.path.join(_tmp, "test_knowledge.db")


def _fresh_stack():
    """Build an isolated index+vector+hybrid stack on a temp DB."""
    ki = KnowledgeIndex(db_path=_DB)
    vi = VectorIndex(knowledge_index=ki)
    vi._collection = None            # force TF-IDF fallback (offline)
    return ki, vi, HybridSearch(ki, vi), SourceAttributor(ki)


def test_chunker_text():
    c = Chunker(chunk_size=300, overlap=50)
    text = "\n\n".join(f"Paragraph {i} " + "word " * 30 for i in range(10))
    chunks = c.chunk(text, "text")
    assert len(chunks) > 1
    assert all(ch["content"] for ch in chunks)
    assert all(ch["end"] > ch["start"] for ch in chunks)
    assert c.chunk("", "text") == []
    print("PASS chunker text")


def test_chunker_markdown_and_code():
    c = Chunker(chunk_size=400)
    md = "# Intro\n\nHello world.\n\n## Setup\n\nInstall things here.\n"
    chunks = c.chunk(md, "markdown")
    assert any("Setup" in ch["content"] for ch in chunks)
    assert any(ch["section"] for ch in chunks)
    code = "def alpha():\n    return 1\n\ndef beta():\n    return 2\n"
    cc = c.chunk(code, "code")
    assert cc and "alpha" in cc[0]["content"]
    print("PASS chunker markdown+code")


def test_doc_type_detection():
    assert detect_doc_type("a.pdf") == "pdf"
    assert detect_doc_type("a.md") == "markdown"
    assert detect_doc_type("a.py") == "code"
    assert detect_doc_type("a.log") == "text"
    print("PASS doc type detection")


def test_ingest_file_roundtrip():
    ing = DocumentIngestor()
    p = os.path.join(_tmp, "notes.md")
    with open(p, "w") as f:
        f.write("# Maya Notes\n\nMaya is an autonomous agent system.\n")
    doc = ing.ingest_file(p)
    assert doc["doc_type"] == "markdown" and doc["chunks"]
    try:
        ing.ingest_file(os.path.join(_tmp, "missing.md"))
        assert False, "should raise"
    except FileNotFoundError:
        pass
    print("PASS ingest file roundtrip")


def test_index_add_search_dedupe_version():
    ki, _, _, _ = _fresh_stack()
    chunks = [{"content": "The rate limiter allows 120 requests per minute.",
               "start": 0, "end": 48, "section": "limits"}]
    r1 = ki.add_document("limits.md", chunks, source="docs/limits.md")
    assert r1["chunks"] == 1 and not r1["deduplicated"]
    r2 = ki.add_document("limits.md", chunks, source="docs/limits.md")
    assert r2["deduplicated"]                       # exact dupe blocked
    chunks2 = [{"content": "The rate limiter now allows 240 requests per minute.",
                "start": 0, "end": 52, "section": "limits"}]
    r3 = ki.add_document("limits.md", chunks2, source="docs/limits.md")
    assert r3["version"] == 2                        # same source → v2
    hits = ki.keyword_search("rate limiter requests", limit=5)
    assert hits and "240" in hits[0]["content"]      # old version gone
    print("PASS index add/search/dedupe/version")


def test_hybrid_and_attribution():
    ki, vi, hy, attr = _fresh_stack()
    ki.add_document("animals.md", [
        {"content": "Cats are small domesticated felines that purr.",
         "start": 0, "end": 46, "section": "cats"},
        {"content": "Dogs are loyal domesticated canines that bark.",
         "start": 47, "end": 93, "section": "dogs"},
    ], source="docs/animals.md")
    vi._dirty = True
    hits = hy.search("domesticated felines purr", limit=3, mode="hybrid")
    assert hits and "felines" in hits[0]["content"]
    cited = attr.attribute(hits)
    assert cited[0]["ref"] == 1 and cited[0]["title"] == "animals.md"
    ctx = attr.build_context(cited, max_chars=500)
    assert "[1]" in ctx and "felines" in ctx
    pub = attr.format_citations(cited)
    assert "content" not in pub[0] and pub[0]["source"] == "docs/animals.md"
    print("PASS hybrid + attribution")


def test_vector_tfidf_fallback():
    ki, vi, _, _ = _fresh_stack()
    ki.add_document("space.md", [
        {"content": "Rockets launch satellites into orbit around Earth.",
         "start": 0, "end": 50, "section": ""},
    ], source="docs/space.md")
    vi._dirty = True
    hits = vi.search("satellite orbit launch", limit=3)
    assert hits and hits[0]["engine"] == "vector" and hits[0]["score"] > 0
    assert vi.search("", limit=3) == []
    print("PASS tf-idf vector fallback")


def test_delete_and_stats():
    ki, vi, _, _ = _fresh_stack()
    r = ki.add_document("tmp.md", [
        {"content": "Temporary document about quantum tunneling.",
         "start": 0, "end": 43, "section": ""},
    ], source="docs/tmp.md")
    assert ki.stats()["documents"] >= 1
    assert ki.delete_document(r["doc_id"]) is True
    assert ki.delete_document(r["doc_id"]) is False
    assert not ki.keyword_search("quantum tunneling")
    s = ki.stats()
    assert "chunks" in s and "fts5" in s
    print("PASS delete + stats")


if __name__ == "__main__" or True:
    try:
        test_chunker_text()
        test_chunker_markdown_and_code()
        test_doc_type_detection()
        test_ingest_file_roundtrip()
        test_index_add_search_dedupe_version()
        test_hybrid_and_attribution()
        test_vector_tfidf_fallback()
        test_delete_and_stats()
        print("\nAll RAG tests passed")
    finally:
        shutil.rmtree(_tmp, ignore_errors=True)
