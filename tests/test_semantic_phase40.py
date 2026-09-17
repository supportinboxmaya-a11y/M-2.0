"""Phase 40 tests — vector-based semantic retrieval.

Skills and beliefs must be retrievable through the SemanticIndex
(TF-IDF cosine fallback, real embeddings when SEMANTIC_EMBEDDINGS=true),
index stays in sync on writes/deletes, and belief-revision dedup keeps
its conservative semantics.
"""
import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

for _name in ("loguru", "dotenv"):
    if _name not in sys.modules:
        try:
            __import__(_name)
        except ImportError:
            import types as _t
            sys.modules[_name] = _t.SimpleNamespace()
            if _name == "loguru":
                class _L:
                    def __getattr__(self, item):
                        return lambda *a, **k: None
                sys.modules[_name].logger = _L()

import infrastructure.cognitive_kernel as ck  # noqa: E402
from infrastructure.cognitive_kernel import CognitiveKernel  # noqa: E402
from infrastructure.semantic_index import SemanticIndex  # noqa: E402


def _fresh_kernel() -> CognitiveKernel:
    d = Path(tempfile.mkdtemp(prefix="maya_p40_"))
    ck.COG_KERNEL_DB = str(d / "kernel.db")
    ck.CHECKPOINT_DIR = d / "checkpoints"
    return CognitiveKernel()


def test_index_ranks_relevant_doc_first():
    idx = SemanticIndex()
    idx.add("a", "deploy docker container to remote VPS server")
    idx.add("b", "bake chocolate chip cookies in the oven")
    hits = idx.search("ship my flask app to production server")
    assert hits and hits[0][0] == "a"
    assert all(h[0] != "b" for h in hits)


def test_index_unrelated_query_returns_nothing():
    idx = SemanticIndex()
    idx.add("a", "ssh port for production vps is 20045")
    assert idx.search("quantum banana republic") == []


def test_index_stays_in_sync():
    idx = SemanticIndex()
    idx.add("a", "restart nginx container")
    idx.add("b", "rotate api keys quarterly")
    idx.remove("a")
    assert idx.search("restart nginx") == [("b",)][:0] or all(
        h[0] != "a" for h in idx.search("restart nginx"))
    idx.clear()
    assert len(idx) == 0


def test_knowledge_query_ranks_semantically_not_by_stopwords():
    """Rare shared terms must dominate over incidental common words."""
    k = _fresh_kernel()
    k.learn("ssh port for the production VPS is 20045", confidence=0.95,
            domain="server")
    k.learn("nginx container id is 7213ab4ab5a8", confidence=0.5,
            domain="server")
    res = k.knowledge_query(
        "which network port do I use to reach the vps")
    assert res and "20045" in res[0]["proposition"]


def test_learn_dedup_unchanged_under_fallback():
    k = _fresh_kernel()
    b1 = k.learn("docker restart requires approval on the VPS",
                 confidence=0.7)
    n_before = len(k.beliefs)
    k.learn("docker restart requires approval on the VPS always",
            confidence=0.8)
    assert len(k.beliefs) == n_before
    assert b1.confidence > 0.7


def test_conflicting_near_duplicate_revises_not_duplicates():
    k = _fresh_kernel()
    k.learn("deploying to server X always succeeds", confidence=0.9)
    n_before = len(k.beliefs)
    k.learn("deploying to server X always fails", confidence=0.15)
    assert len(k.beliefs) == n_before


def test_delete_belief_updates_index():
    k = _fresh_kernel()
    b = k.learn("temporary fact about staging host", confidence=0.6)
    k._delete_belief(b.id)
    assert k.knowledge_query("staging host fact") == []


def test_stats_expose_retrieval_engine():
    k = _fresh_kernel()
    st = k.knowledge_stats()
    assert st["retrieval_engine"] in ("tfidf", "embeddings")


def test_goal_grounding_uses_semantic_belief_retrieval():
    k = _fresh_kernel()
    k.learn("postgres database backups run nightly at 3am", confidence=0.9)
    ctx = k._gather_cognitive_context("check on the postgres backups setup")
    assert any("backups" in b["proposition"] for b in ctx["beliefs"])
