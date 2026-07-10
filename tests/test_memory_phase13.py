"""Phase 13 vector-memory tests — offline, TF-IDF fallback, temp DB."""
import os, sys, types, tempfile, shutil
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Stub optional heavy deps so tests run on any machine (Colab/CI/local)
for _name in ("loguru", "dotenv"):
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
# Force the TF-IDF fallback even if chromadb is installed (offline tests)
sys.modules["chromadb"] = types.ModuleType("chromadb")

_tmp = tempfile.mkdtemp(prefix="maya_mem13_")

import memory.long_term as _lt_mod
_lt_mod.DB_FILE = os.path.join(_tmp, "test_memory.db")

from memory.long_term import LongTermMemory
from memory.vector_memory import VectorMemory, VECTOR_DIR
from memory.memory_manager import MemoryManager


def _manager() -> MemoryManager:
    m = MemoryManager()
    assert m.vector.engine == "tfidf"      # fallback active in tests
    return m


def test_persistence_contract():
    """Chroma must use the persistent on-disk client, not the in-memory
    one that wiped all vectors on every restart."""
    src = open(os.path.join(os.path.dirname(os.path.dirname(
        os.path.abspath(__file__))), "memory", "vector_memory.py")).read()
    assert "PersistentClient" in src
    assert "chromadb.Client()" not in src
    assert str(VECTOR_DIR).endswith(os.path.join("storage", "vectors"))
    print("PASS persistence contract")


def test_fallback_semantic_scoring():
    vm = VectorMemory(fallback_store=None)
    vm.add("Rockets launch satellites into orbit", doc_id="a")
    vm.add("Cats purr when they are happy", doc_id="b")
    hits = vm.search("satellite orbit rocket", limit=2)
    assert hits and hits[0]["id"] == "a"
    assert hits[0]["score"] > 0 and hits[0]["engine"] == "tfidf"
    assert "content" in hits[0] and "metadata" in hits[0]   # back-compat
    assert vm.search("", limit=3) == []
    print("PASS fallback semantic scoring")


def test_delete_removes_ghost_results():
    m = _manager()
    mid = m.add("The staging server password rotates every Friday",
                memory_type="general")
    assert any(h["id"] == mid for h in m.vector.search("staging password"))
    assert m.delete(mid) is True
    assert not any(h["id"] == mid for h in m.vector.search("staging password"))
    print("PASS delete removes ghost results")


def test_update_reembeds_and_keeps_versions():
    m = _manager()
    mid = m.add("Deploy target is the blue cluster", memory_type="general")
    assert m.update(mid, "Deploy target is now the green cluster")
    hits = m.vector.search("deploy target cluster", limit=3)
    top = next(h for h in hits if h["id"] == mid)
    assert "green" in top["content"] and "blue" not in top["content"]
    versions = m.get_versions(mid)
    assert len(versions) >= 2 and "blue" in versions[0]["content"]
    print("PASS update re-embeds + versions kept")


def test_compress_syncs_vectors():
    m = _manager()
    topics = ["deploy pipeline flakiness", "database index bloat",
              "frontend bundle size growth", "oncall alert fatigue",
              "staging environment drift", "code review turnaround",
              "flaky websocket reconnects", "docker image cache misses"]
    ids = [m.add(f"Retro item {i}: team discussed {t} this sprint",
                 memory_type="retro") for i, t in enumerate(topics)]
    report = m.compress(memory_type="retro", keep_recent=2, dry_run=False)
    assert report["compressed"] == 6
    remaining = {x["id"] for x in m.get_all(limit=1000)}
    for h in m.vector.search("retro sprint team discussed", limit=20):
        assert h["id"] in remaining          # no vectors for deleted rows
    assert any("Compressed summary" in h["content"]
               for h in m.vector.search("retro sprint team", limit=20))
    print("PASS compress syncs vectors")


def test_cleanup_prunes_orphans():
    m = _manager()
    mid = m.add("Orphan vector candidate about quantum tunneling",
                memory_type="general")
    # simulate drift: row deleted behind the manager's back
    m.long_term.delete(mid)
    m.vector.invalidate()
    report = m.cleanup(dry_run=False)
    assert "vectors_pruned" in report
    assert not any(h["id"] == mid
                   for h in m.vector.search("quantum tunneling", limit=10))
    print("PASS cleanup prunes orphans")


def test_stats_expose_engine():
    m = _manager()
    s = m.get_stats()
    assert s["vector_engine"] == "tfidf" and "vector_count" in s
    print("PASS stats expose engine")


try:
    test_persistence_contract()
    test_fallback_semantic_scoring()
    test_delete_removes_ghost_results()
    test_update_reembeds_and_keeps_versions()
    test_compress_syncs_vectors()
    test_cleanup_prunes_orphans()
    test_stats_expose_engine()
    print("\nAll vector-memory tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
