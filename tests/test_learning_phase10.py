"""Phase 10 learning layer tests — offline, temp SQLite."""
import os, random, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# stub heavy deps for the memory import chain
import types
for _n in ("loguru", "dotenv", "chromadb"):
    try:
        __import__(_n)
    except ImportError:
        _m = types.ModuleType(_n)
        if _n == "loguru":
            class _L:
                def __getattr__(self, k): return lambda *a, **kw: None
            _m.logger = _L()
        if _n == "dotenv":
            _m.load_dotenv = lambda *a, **k: None
        sys.modules[_n] = _m

from enterprise._db import DB
from learning import FeedbackStore, ExperienceReplay, PromptOptimizer, MemoryCompressor

TMP = tempfile.mkdtemp()


def _db(name):
    return DB(os.path.join(TMP, name + ".db"))


def test_feedback():
    f = FeedbackStore(db=_db("fb"))
    f.record("write code", "def x(): pass", 1)
    f.record("write docs", "TODO", -1, comment="left placeholders")
    f.record("deploy", "done", 0)
    s = f.stats()
    assert s["total"] == 3 and s["positive"] == 1 and s["negative"] == 1
    lessons = f.lessons()
    assert len(lessons) == 1 and "placeholder" in lessons[0]["comment"]
    print("PASS feedback")


def test_experience_replay():
    e = ExperienceReplay(db=_db("exp"))
    e.store("deploy backend to render", [{"step": "build"}], "completed", 0.9)
    e.store("deploy frontend to vercel", [{"step": "build"}], "completed", 0.8)
    e.store("write a poem", [{"step": "write"}], "failed", 0.2)
    sim = e.similar("deploy the backend service to render cloud")
    assert sim and "render" in sim[0]["goal"] and sim[0]["similarity"] > 0
    assert sim[0]["steps"] == [{"step": "build"}]
    sr = e.success_rate("deploy")
    assert sr["total"] == 2 and sr["success_rate"] == 1.0
    assert e.success_rate("poem")["success_rate"] == 0.0
    assert len(e.history()) == 3
    print("PASS experience")


def test_prompt_optimizer():
    po = PromptOptimizer(epsilon=0.0)              # pure exploitation for determinism
    for _ in range(8):
        po.record("summarize", "v1: short prompt", True)
    for _ in range(8):
        po.record("summarize", "v2: long prompt", False)
    assert po.best("summarize") == "v1: short prompt"
    assert po.choose("summarize") == "v1: short prompt"
    # exploration path
    po2 = PromptOptimizer(epsilon=1.0, rng=random.Random(42))
    po2.record("t", "a", True); po2.record("t", "b", False)
    assert po2.choose("t") in ("a", "b")
    assert po.choose("unknown_task") is None
    improved = po.improve_from_feedback("Summarize this.", ["Output looks too short"])
    assert "detailed" in improved
    rep = po.report()
    assert rep["summarize"]["v1: short prompt"]["score"] > 0.5
    print("PASS prompt_optimizer")


class FakeMemStore:
    def __init__(self, n):
        self.rows = [{"id": str(i), "type": "chat",
                      "content": f"Conversation number {i} about deploying maya to render. " * 3,
                      "timestamp": f"2026-01-{(i % 27) + 1:02d}"} for i in range(n)]
        self.added, self.deleted = [], []
    def get_all(self, limit=100000): return list(self.rows)
    def add(self, content, memory_type="general", metadata=None): self.added.append(memory_type)
    def delete(self, mid): self.deleted.append(mid)


def test_memory_compression():
    store = FakeMemStore(40)
    c = MemoryCompressor(store)
    rep = c.compress("chat", keep_recent=10, dry_run=True)
    assert rep["compressed"] == 30 and rep["dry_run"] and not store.deleted
    assert rep["saving_pct"] > 50
    rep2 = c.compress("chat", keep_recent=10, dry_run=False)
    assert rep2["digest_created"] and len(store.deleted) == 30
    assert store.added == ["chat_digest"]
    small = MemoryCompressor(FakeMemStore(5)).compress("chat")
    assert small["compressed"] == 0                 # too few to bother
    print("PASS compression")


if __name__ == "__main__":
    test_feedback(); test_experience_replay(); test_prompt_optimizer(); test_memory_compression()
    print("\nAll Phase 10 learning tests passed!")
