"""Phase 2 memory tests — offline, dependency-injected fakes."""
import os, sys, types
from datetime import datetime, timedelta, timezone
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

from memory.importance import ImportanceScorer
from memory.ranker import MemoryRanker
from memory.lifecycle import MemoryLifecycle
from memory.summarizer import MemorySummarizer
from memory.layers import MemoryLayers


def _ts(days_ago=0):
    return (datetime.now(timezone.utc) - timedelta(days=days_ago)).isoformat()


def test_importance():
    s = ImportanceScorer()
    hi = s.score("User always prefers dark mode, remember this", "preference", _ts(0))
    lo = s.score("hi", "chat", _ts(100))
    assert hi > lo and 0 <= lo <= hi <= 1.0
    assert s.score("x", "general", "not-a-date") > 0     # bad timestamp safe
    print("PASS importance")


def test_ranker():
    r = MemoryRanker()
    mems = [
        {"id": "1", "content": "Deploy backend to Render cloud", "type": "task", "timestamp": _ts(1)},
        {"id": "2", "content": "User likes mango juice", "type": "preference", "timestamp": _ts(1)},
        {"id": "3", "content": "Render deployment failed with docker error", "type": "task", "timestamp": _ts(1)},
    ]
    out = r.rank("render deploy error", mems, limit=2)
    assert len(out) == 2 and out[0]["id"] == "3" and "_score" in out[0]
    print("PASS ranker")


class FakeStore:
    def __init__(self, rows): self.rows = list(rows); self.deleted = []
    def get_all(self, limit=100000): return list(self.rows)
    def delete(self, mid): self.deleted.append(mid); return True


def test_lifecycle():
    rows = [
        {"id": "old_chat", "content": "hey", "type": "chat", "timestamp": _ts(30)},
        {"id": "new_chat", "content": "hello", "type": "chat", "timestamp": _ts(1)},
        {"id": "pref", "content": "likes tea", "type": "preference", "timestamp": _ts(400)},
        {"id": "no_ts", "content": "mystery", "type": "general", "timestamp": "bad"},
    ]
    store = FakeStore(rows)
    lc = MemoryLifecycle(store)
    rep = lc.cleanup(dry_run=True)                     # dry run: nothing deleted
    assert rep["expired"] == 1 and rep["deleted"] == 0 and store.deleted == []
    rep = lc.cleanup(dry_run=False)
    assert store.deleted == ["old_chat"]               # pref=forever, bad ts=safe
    # overflow cap
    store2 = FakeStore([{"id": str(i), "content": f"m{i}", "type": "general",
                         "timestamp": _ts(1)} for i in range(10)])
    rep = MemoryLifecycle(store2, max_memories=7).cleanup(dry_run=False)
    assert rep["overflow"] == 3 and len(store2.deleted) == 3
    print("PASS lifecycle")


def test_summarizer():
    s = MemorySummarizer()
    texts = ["The user prefers Python for backend work. " * 2,
             "Deployment happens on Render with Docker. The API uses FastAPI routes.",
             "Random tiny note."]
    out = s.summarize(texts, max_sentences=2)
    assert 0 < len(out) < sum(len(t) for t in texts)
    assert s.summarize([]) == ""
    def fake_llm(prompt): return "LLM DIGEST"
    assert MemorySummarizer(fake_llm).summarize(["a sentence here ok."]) == "LLM DIGEST"
    def bad_llm(prompt): raise RuntimeError("down")
    assert MemorySummarizer(bad_llm).summarize(["Fallback works fine here."])  # falls back
    print("PASS summarizer")


class FakeManager:
    def __init__(self):
        self.calls = []
        class ST:
            def __init__(s): s.msgs = []
            def add_user_message(s, m): s.msgs.append(("user", m))
            def add_assistant_message(s, m): s.msgs.append(("assistant", m))
        self.short_term = ST()
    def get_context(self): return "ctx"
    def add(self, content, memory_type="general", metadata=None):
        self.calls.append(("add", content, memory_type)); return "id1"
    def search(self, q, limit=5, memory_type=None):
        return [{"content": "found", "type": memory_type}]
    def add_fact(self, fact, topic="general"): self.calls.append(("fact", fact, topic))
    def search_facts(self, q, limit=5): return [{"content": "fact"}]


def test_layers():
    L = MemoryLayers(FakeManager())
    L.conversation_add("user", "hi"); L.conversation_add("assistant", "hello")
    assert L.m.short_term.msgs == [("user", "hi"), ("assistant", "hello")]
    assert L.conversation_context() == "ctx"
    assert L.user_remember("dark mode") == "id1"
    assert L.user_recall("mode")[0]["type"] == "preference"
    L.project_remember("uses FastAPI", "maya")
    assert L.project_recall("api")
    L.semantic_remember("sky is blue")
    assert L.semantic_recall("sky")
    print("PASS layers")


if __name__ == "__main__":
    test_importance(); test_ranker(); test_lifecycle(); test_summarizer(); test_layers()
    print("\nAll Phase 2 memory tests passed!")
