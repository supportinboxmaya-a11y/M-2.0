"""
Maya 2.0 — Semantic Index (Phase 40)
====================================
Vector-based retrieval upgrade for skills and beliefs. Previously both
ProceduralMemory.search_skills() and CognitiveKernel.knowledge_query()
ranked with raw token-overlap, which misses novel-but-similar phrasings
("ship my flask app" vs "deploy docker container").

Engines (best available wins):
  1. Real embeddings via chromadb's DefaultEmbeddingFunction (ONNX MiniLM)
     — only attempted when SEMANTIC_EMBEDDINGS=true (first use downloads
     a local model, so it ships OFF per Safety Rule 3).
  2. TF-IDF cosine similarity over the indexed corpus — zero dependencies,
     always available. Still strictly better than token overlap: IDF
     weighting downgrades ubiquitous words, partial-match credit, and
     proper cosine geometry instead of set ratios.

The index lives in memory only; callers (kernel beliefs, procedural
skills) keep their own persistence and re-index on load.
"""

import math
import os
import re
import threading
from collections import Counter
from typing import Dict, List, Optional, Tuple

_TOKEN = re.compile(r"[A-Za-z0-9_\u0980-\u09FF]+")   # latin + bangla


def _tokenize(text: str) -> List[str]:
    return [t.lower() for t in _TOKEN.findall(text or "")]


def _cosine(a: Dict[str, float], b: Dict[str, float]) -> float:
    if not a or not b:
        return 0.0
    if len(b) < len(a):
        a, b = b, a
    dot = sum(v * b.get(t, 0.0) for t, v in a.items())
    if dot <= 0:
        return 0.0
    na = math.sqrt(sum(v * v for v in a.values()))
    nb = math.sqrt(sum(v * v for v in b.values()))
    if na <= 0 or nb <= 0:
        return 0.0
    return dot / (na * nb)


def _load_embed_fn():
    """Try to build an embedding function. Returns None when unavailable."""
    try:
        from chromadb.utils import embedding_functions
        return embedding_functions.DefaultEmbeddingFunction()
    except Exception:
        return None


class SemanticIndex:
    """In-memory semantic index with automatic engine selection."""

    def __init__(self):
        self._lock = threading.Lock()
        self._docs: Dict[str, str] = {}
        # tf-idf state
        self._vecs: Dict[str, Dict[str, float]] = {}
        self._df: Counter = Counter()
        self._dirty = True
        # embedding state (lazy)
        self._embed_fn = None
        self._embed_tried = False
        self._emb: Dict[str, List[float]] = {}

    @property
    def engine(self) -> str:
        return "embeddings" if self._use_embeddings() else "tfidf"

    def _use_embeddings(self) -> bool:
        if os.getenv("SEMANTIC_EMBEDDINGS", "").strip().lower() not in ("1", "true", "yes"):
            return False
        if not self._embed_tried:
            self._embed_fn = _load_embed_fn()
            self._embed_tried = True
        return self._embed_fn is not None

    # ── write path ────────────────────────────────────────────────

    def add(self, doc_id: str, text: str) -> None:
        text = (text or "").strip()
        with self._lock:
            if not text:
                self.remove(doc_id)
                return
            self._docs[doc_id] = text
            self._dirty = True

    def remove(self, doc_id: str) -> None:
        with self._lock:
            self._docs.pop(doc_id, None)
            self._dirty = True

    def clear(self) -> None:
        with self._lock:
            self._docs.clear()
            self._dirty = True

    def __len__(self) -> int:
        with self._lock:
            return len(self._docs)

    # ── read path ─────────────────────────────────────────────────

    def search(self, query: str, limit: int = 5,
               min_score: float = 0.05) -> List[Tuple[str, float]]:
        """Return [(doc_id, score)] best-first. Score is cosine similarity."""
        query = (query or "").strip()
        if not query:
            return []
        if self._use_embeddings():
            hits = self._search_embeddings(query, limit, min_score)
            if hits is not None:
                return hits
        return self._search_tfidf(query, limit, min_score)

    def best_match(self, text: str,
                   min_score: float = 0.05) -> Optional[Tuple[str, float]]:
        hits = self.search(text, limit=1, min_score=min_score)
        return hits[0] if hits else None

    # ── embeddings engine ─────────────────────────────────────────

    def _search_embeddings(self, query: str, limit: int,
                           min_score: float) -> Optional[List[Tuple[str, float]]]:
        try:
            with self._lock:
                ids = list(self._docs.keys())
                texts = [self._docs[i] for i in ids]
            missing = [(i, t) for i, t in zip(ids, texts) if i not in self._emb]
            if missing:
                vecs = self._embed_fn([t for _, t in missing])
                for (i, _), v in zip(missing, vecs):
                    self._emb[i] = list(map(float, v))
            qv = list(map(float, self._embed_fn([query])[0]))
            scored = []
            for i in ids:
                dv = self._emb.get(i)
                if not dv:
                    continue
                score = _dense_cosine(qv, dv)
                if score >= min_score:
                    scored.append((i, round(score, 4)))
            scored.sort(key=lambda x: x[1], reverse=True)
            return scored[:limit]
        except Exception:
            # embedding path failed mid-flight — permanent fallback
            self._embed_fn = None
            self._emb.clear()
            return None

    # ── tf-idf engine ─────────────────────────────────────────────

    def _rebuild(self) -> None:
        self._df = Counter()
        raw: Dict[str, Counter] = {}
        for doc_id, text in self._docs.items():
            terms = Counter(_tokenize(text))
            if not terms:
                continue
            raw[doc_id] = terms
            for t in terms:
                self._df[t] += 1
        n = max(1, len(raw))

        def idf(t: str) -> float:
            return math.log(1.0 + n / (1.0 + self._df.get(t, 0)))

        self._vecs = {
            doc_id: {t: f * idf(t) for t, f in terms.items()}
            for doc_id, terms in raw.items()
        }
        self._dirty = False

    def _search_tfidf(self, query: str, limit: int,
                      min_score: float) -> List[Tuple[str, float]]:
        with self._lock:
            if self._dirty:
                self._rebuild()
            n = max(1, len(self._vecs))

            def idf(t: str) -> float:
                return math.log(1.0 + n / (1.0 + self._df.get(t, 0)))

            q_terms = Counter(_tokenize(query))
            q_vec = {t: f * idf(t) for t, f in q_terms.items()}
            scored = []
            for doc_id, d_vec in self._vecs.items():
                score = _cosine(q_vec, d_vec)
                if score >= min_score:
                    scored.append((doc_id, round(score, 4)))
            scored.sort(key=lambda x: x[1], reverse=True)
            return scored[:limit]


def _dense_cosine(a: List[float], b: List[float]) -> float:
    if not a or not b:
        return 0.0
    n = min(len(a), len(b))
    dot = sum(a[i] * b[i] for i in range(n))
    if dot <= 0:
        return 0.0
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(x * x for x in b))
    if na <= 0 or nb <= 0:
        return 0.0
    return dot / (na * nb)
