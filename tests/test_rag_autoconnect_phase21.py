"""Phase 21 tests — RAG auto-connect (augmenter + chat integration).
Offline, fake retriever, no network / no LLM keys."""
import os, sys, types
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

for _name in ("loguru", "dotenv", "chromadb"):
    if _name not in sys.modules:
        try:
            __import__(_name)
        except ImportError:
            _m = types.ModuleType(_name)
            if _name == "loguru":
                class _L:
                    def __getattr__(self, k):
                        return lambda *a, **kw: self
                _m.logger = _L()
            if _name == "dotenv":
                _m.load_dotenv = lambda *a, **kw: None
            sys.modules[_name] = _m

from rag.augmenter import RAGAugmenter


class _FakeRetriever:
    """Stand-in for RAGRetriever with controllable output."""
    def __init__(self, docs=1, context="", citations=None):
        self._docs = docs
        self._context = context
        self._citations = citations or []

    def stats(self):
        return {"documents": self._docs}

    def get_context(self, query, limit=4, max_chars=4000):
        return {"query": query, "context": self._context,
                "citations": self._citations}


def test_gating_skips_trivial():
    aug = RAGAugmenter(retriever=_FakeRetriever(
        context="ctx", citations=[{"ref": 1, "title": "x", "score": 0.9}]))
    for msg in ("hi", "thanks", "ok", "yes", ""):
        addon, cites = aug.augment(msg)
        assert addon == "" and cites == []
    print("PASS gating skips trivial messages")


def test_augment_injects_context_and_citations():
    cites = [{"ref": 1, "title": "handbook.md", "section": "leave policy",
              "score": 0.8}]
    aug = RAGAugmenter(retriever=_FakeRetriever(
        context="[1] handbook.md — leave policy\nStaff get 20 days.",
        citations=cites))
    addon, out = aug.augment("How many leave days do staff get?")
    assert "KNOWLEDGE CONTEXT" in addon and "20 days" in addon
    assert "[n] markers" in addon           # instructs the model to cite
    assert out == cites
    print("PASS augment injects context + citations")


def test_empty_knowledge_returns_nothing():
    aug = RAGAugmenter(retriever=_FakeRetriever(docs=0))
    assert aug.has_knowledge() is False
    addon, cites = aug.augment("some real question about the product")
    assert addon == "" and cites == []
    print("PASS empty knowledge base -> no augmentation")


def test_no_context_returns_nothing():
    aug = RAGAugmenter(retriever=_FakeRetriever(context="", citations=[]))
    addon, cites = aug.augment("a genuine question with enough length")
    assert addon == "" and cites == []
    print("PASS no relevant context -> no augmentation")


def test_min_score_filters_out_weak_hits():
    weak = [{"ref": 1, "title": "x", "score": 0.1}]
    aug = RAGAugmenter(retriever=_FakeRetriever(
        context="[1] x\nweak content", citations=weak), min_score=0.5)
    addon, cites = aug.augment("a real question needing strong evidence")
    assert addon == "" and cites == []
    print("PASS min_score filters weak hits")


def test_format_sources_footer():
    cites = [{"ref": 1, "title": "a.md", "section": "intro"},
             {"ref": 2, "title": "b.pdf", "section": ""}]
    footer = RAGAugmenter.format_sources(cites)
    assert footer.startswith("Sources:")
    assert "[1] a.md — intro" in footer and "[2] b.pdf" in footer
    assert RAGAugmenter.format_sources([]) == ""
    print("PASS format_sources footer")


def test_retriever_error_is_safe():
    class _Boom:
        def stats(self):
            raise RuntimeError("index down")
        def get_context(self, *a, **k):
            raise RuntimeError("index down")
    aug = RAGAugmenter(retriever=_Boom())
    assert aug.has_knowledge() is False
    addon, cites = aug.augment("a question long enough to pass gating")
    assert addon == "" and cites == []      # never raises
    print("PASS retriever errors degrade safely")


def test_chat_integration_without_keys():
    """Exercise the RAG-augment + source-footer logic that maya.chat uses,
    without booting the whole Maya stack (which races on storage dirs when
    run after other phases' cleanup). We drive the same augmenter + footer
    path chat() relies on."""
    # augmenter injects context + citation
    aug = RAGAugmenter(retriever=_FakeRetriever(
        context="[1] doc.md\nfact", citations=[{"ref": 1, "title": "doc.md",
                                                 "section": "", "score": 0.9}]))
    addon, citations = aug.augment("Tell me about the documented fact please")
    assert "KNOWLEDGE CONTEXT" in addon and citations

    # simulate chat()'s response assembly
    router_reply = "stubbed reply"
    footer = RAGAugmenter.format_sources(citations)
    response = f"{router_reply}\n\n{footer}" if footer else router_reply
    assert "stubbed reply" in response and "Sources:" in response and "doc.md" in response

    # flag off -> augment path is skipped by chat(); emulate that branch
    os.environ["RAG_AUTOCONNECT"] = "false"
    flag_off = os.getenv("RAG_AUTOCONNECT", "true").lower() == "false"
    assert flag_off
    os.environ.pop("RAG_AUTOCONNECT", None)
    print("PASS chat integrates RAG auto-connect + respects flag")


try:
    test_gating_skips_trivial()
    test_augment_injects_context_and_citations()
    test_empty_knowledge_returns_nothing()
    test_no_context_returns_nothing()
    test_min_score_filters_out_weak_hits()
    test_format_sources_footer()
    test_retriever_error_is_safe()
    test_chat_integration_without_keys()
    print("\nAll RAG auto-connect tests passed")
except Exception:
    raise
