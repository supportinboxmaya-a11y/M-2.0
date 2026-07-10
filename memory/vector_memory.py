"""
Maya 2.0 - Vector Memory (Persistent)
-------------------------------------
Semantic similarity search over memories.

Primary engine : ChromaDB PersistentClient — vectors survive restarts
                 (the old implementation used the in-memory Client, so
                 every deploy silently wiped all vector memory).
Fallback engine: pure-Python TF-IDF cosine similarity rebuilt from
                 LongTermMemory, so semantic search still works with
                 zero optional dependencies (the old fallback was a
                 plain substring match).

Also new: update / delete / prune, so vectors stay in sync when
memories are edited, deleted, compressed, or expired — previously
deleted memories kept appearing in vector search results forever
("ghost results").

search() results keep the old {"content": ...} shape for backward
compatibility and additionally carry id, metadata, score, engine.
"""

import math
import re
import threading
from collections import Counter
from typing import Dict, List, Optional, Set

from config.settings import STORAGE_DIR

VECTOR_DIR = STORAGE_DIR / "vectors"

_TOKEN = re.compile(r"[A-Za-z0-9_\u0980-\u09FF]+")   # latin + bangla


def _tokenize(text: str) -> List[str]:
    return [t.lower() for t in _TOKEN.findall(text or "")]


def _clean_metadata(metadata: Optional[Dict]) -> Dict:
    """Chroma only accepts str/int/float/bool metadata values."""
    out = {}
    for k, v in (metadata or {}).items():
        if isinstance(v, (str, int, float, bool)):
            out[k] = v
        elif v is not None:
            out[k] = str(v)
    return out


class VectorMemory:
    """Persistent vector search with a TF-IDF fallback, kept in sync
    with the long-term store via update/delete/prune."""

    def __init__(self, fallback_store=None, collection: str = "maya_memory"):
        self._store = fallback_store       # LongTermMemory (for fallback)
        self._lock = threading.Lock()
        self.collection = None
        self._dirty = True                 # fallback cache invalidation
        self._df: Counter = Counter()
        self._vecs: Dict[str, Counter] = {}
        self._meta: Dict[str, Dict] = {}
        self._local: Dict[str, Dict] = {}  # used when no fallback_store
        self._init()

    def _init(self):
        try:
            import chromadb
            VECTOR_DIR.mkdir(parents=True, exist_ok=True)
            client = chromadb.PersistentClient(path=str(VECTOR_DIR))
            self.collection = client.get_or_create_collection("maya_memory")
        except Exception:
            self.collection = None

    @property
    def engine(self) -> str:
        return "chroma" if self.collection is not None else "tfidf"

    # ── write path ────────────────────────────────────────────────
    def add(self, content: str, doc_id: str = None, metadata: Dict = None) -> str:
        import uuid
        doc_id = doc_id or str(uuid.uuid4())[:8]
        content = (content or "").strip()
        if not content:
            return doc_id
        if self.collection is not None:
            try:
                self.collection.upsert(documents=[content], ids=[doc_id],
                                       metadatas=[_clean_metadata(metadata)])
            except Exception:
                pass
        else:
            with self._lock:
                self._local[doc_id] = {"content": content,
                                       "metadata": metadata or {}}
                self._dirty = True
        return doc_id

    def update(self, doc_id: str, content: str, metadata: Dict = None):
        """Re-embed an edited memory so search reflects the new content."""
        if not doc_id:
            return
        self.add(content, doc_id=doc_id, metadata=metadata)

    def delete(self, doc_id: str):
        if not doc_id:
            return
        if self.collection is not None:
            try:
                self.collection.delete(ids=[doc_id])
            except Exception:
                pass
        else:
            with self._lock:
                self._local.pop(doc_id, None)
                self._dirty = True

    def prune(self, valid_ids: Set[str]) -> int:
        """Remove every vector whose id is no longer in the long-term
        store (after cleanup/compression). Returns how many were removed."""
        valid = set(valid_ids or [])
        removed = 0
        if self.collection is not None:
            try:
                got = self.collection.get()
                stale = [i for i in (got.get("ids") or []) if i not in valid]
                if stale:
                    self.collection.delete(ids=stale)
                    removed = len(stale)
            except Exception:
                pass
        else:
            with self._lock:
                stale = [i for i in self._local if i not in valid]
                for i in stale:
                    self._local.pop(i, None)
                removed = len(stale)
                if removed:
                    self._dirty = True
        return removed

    def count(self) -> int:
        if self.collection is not None:
            try:
                return int(self.collection.count())
            except Exception:
                return 0
        with self._lock:
            if self._store is not None:
                if self._dirty:
                    self._rebuild()
                return len(self._vecs)
            return len(self._local)

    # ── read path ─────────────────────────────────────────────────
    def search(self, query: str, limit: int = 5) -> List[Dict]:
        query = (query or "").strip()
        if not query:
            return []
        if self.collection is not None:
            return self._search_chroma(query, limit)
        return self._search_tfidf(query, limit)

    def _search_chroma(self, query: str, limit: int) -> List[Dict]:
        try:
            res = self.collection.query(query_texts=[query], n_results=limit)
        except Exception:
            return []
        ids = (res.get("ids") or [[]])[0]
        docs = (res.get("documents") or [[]])[0]
        metas = (res.get("metadatas") or [[]])[0]
        dists = (res.get("distances") or [[]])[0]
        hits = []
        for i, doc_id in enumerate(ids):
            dist = dists[i] if i < len(dists) else 1.0
            hits.append({"id": doc_id,
                         "content": docs[i] if i < len(docs) else "",
                         "metadata": metas[i] if i < len(metas) else {},
                         "score": round(1.0 / (1.0 + float(dist)), 4),
                         "engine": "chroma"})
        return hits

    # ── tf-idf fallback engine ────────────────────────────────────
    def invalidate(self):
        """Mark the fallback cache stale (long-term store changed)."""
        with self._lock:
            self._dirty = True

    def _rows(self) -> List[Dict]:
        if self._store is not None:
            try:
                return self._store.get_all(limit=100000)
            except Exception:
                return []
        return [{"id": k, "content": v["content"], "metadata": v["metadata"]}
                for k, v in self._local.items()]

    def _rebuild(self):
        self._df, self._vecs, self._meta = Counter(), {}, {}
        for m in self._rows():
            terms = Counter(_tokenize(m.get("content", "")))
            if not terms:
                continue
            mid = m.get("id", "")
            self._vecs[mid] = terms
            self._meta[mid] = m
            for t in terms:
                self._df[t] += 1
        self._dirty = False

    def _search_tfidf(self, query: str, limit: int) -> List[Dict]:
        with self._lock:
            if self._dirty:
                self._rebuild()
            q_terms = Counter(_tokenize(query))
            if not q_terms or not self._vecs:
                return []
            n_docs = max(1, len(self._vecs))

            def idf(t):
                return math.log(1.0 + n_docs / (1.0 + self._df.get(t, 0)))

            q_vec = {t: f * idf(t) for t, f in q_terms.items()}
            q_norm = math.sqrt(sum(v * v for v in q_vec.values())) or 1.0

            scored = []
            for mid, terms in self._vecs.items():
                dot = sum(q_vec[t] * terms.get(t, 0) * idf(t) for t in q_vec)
                if dot <= 0:
                    continue
                d_norm = math.sqrt(sum((f * idf(t)) ** 2
                                       for t, f in terms.items())) or 1.0
                scored.append((dot / (q_norm * d_norm), mid))
            scored.sort(reverse=True)

            hits = []
            for score, mid in scored[:limit]:
                m = self._meta[mid]
                hits.append({"id": mid, "content": m.get("content", ""),
                             "metadata": m.get("metadata", {}),
                             "score": round(score, 4), "engine": "tfidf"})
            return hits
