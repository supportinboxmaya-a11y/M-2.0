"""Phase 36 tests — knowledge engine.

Belief revision (learn merges/weakens/strengthens), ranked retrieval that
feeds planning, decay + pruning, and the Maya pipeline consulting knowledge.
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


def _fresh_kernel() -> CognitiveKernel:
    d = Path(tempfile.mkdtemp(prefix="maya_p36_"))
    ck.COG_KERNEL_DB = str(d / "kernel.db")
    ck.CHECKPOINT_DIR = d / "checkpoints"
    return CognitiveKernel()


def test_learn_creates_then_merges_without_duplicates():
    k = _fresh_kernel()
    b1 = k.learn("docker restart requires approval on the VPS",
                 confidence=0.7, source="experience")
    c1 = b1.confidence
    n_before = len(k.beliefs)
    k.learn("docker restart requires approval on the VPS always",
            confidence=0.8, source="observation")
    assert len(k.beliefs) == n_before          # merged, not duplicated
    assert b1.confidence > c1                  # agreeing evidence strengthens


def test_conflicting_evidence_weakens_belief():
    k = _fresh_kernel()
    k.learn("deploying to server X always succeeds", confidence=0.9)
    c_before = list(k.beliefs.values())[0].confidence
    n_before = len(k.beliefs)
    k.learn("deploying to server X always fails", confidence=0.15)
    assert len(k.beliefs) == n_before           # revised, not duplicated
    revised = list(k.beliefs.values())[0]
    assert revised.confidence < c_before        # conflict weakened it


def test_knowledge_query_ranks_by_relevance_and_confidence():
    k = _fresh_kernel()
    k.learn("ssh port for the production VPS is 20045", confidence=0.95,
            domain="server")
    k.learn("nginx container id is 7213ab4ab5a8", confidence=0.5, domain="server")
    res = k.knowledge_query("what ssh port does the vps use")
    assert res and "20045" in res[0]["proposition"]
    assert res[0]["confidence"] >= 0.9
    assert k.knowledge_query("unrelated quantum banana") == []


def test_decay_and_forget():
    k = _fresh_kernel()
    b = k.learn("old fact about legacy host", confidence=0.5)
    # force staleness
    b.updated_at = 0.0
    k._save_belief(b)
    decayed = k.decay_beliefs(stale_after_days=1, factor=0.5)
    assert decayed >= 1
    assert k.beliefs[b.id].confidence < 0.5
    # repeated decay fades the belief out of the knowledge base entirely:
    # each pass halves confidence until it falls below the auto-prune floor
    for _ in range(8):
        if b.id not in k.beliefs:
            break
        k.beliefs[b.id].updated_at = 0.0
        k._save_belief(k.beliefs[b.id])
        k.decay_beliefs(stale_after_days=1, factor=0.5)
    assert b.id not in k.beliefs


def test_knowledge_stats():
    k = _fresh_kernel()
    k.learn("fact one about servers", domain="server")
    k.learn("fact two about servers", domain="server")
    st = k.knowledge_stats()
    assert st["total"] == 2
    assert st["domains"]["server"] == 2
