"""
Maya 2.0 - RAG Vector Search
----------------------------
Semantic search over indexed chunks.

Primary engine : ChromaDB PersistentClient (if `chromadb` installed) —
                 real embeddings, persisted under storage/rag/chroma.
Fallback engine: pure-Python TF-IDF cosine similarity built lazily from
                 the KnowledgeIndex, so semantic-ish search still works
                 with zero extra dependencies.

Both engines share the same add/remove/search interface, and both are
kept in sync by the RAGRetriever facade.
"""

import math
import re
import threading
from collections import Counter
from typing import Dict, List, Optional

from .index import RAG_DIR

_TOKEN = re.compile(r"[A-Za-z0-9_\u0980-\u09FF]+")   # latin + bangla


def _tokenize(text: str) -> List[str]:
    return [t.lower() for t in _TOKEN.findall(text or "")]


class VectorIndex:
    """Chroma-backed vector search with a TF-IDF cosine fallback."""

    def __init__(self, knowledge_index=None, collection: str = "maya_rag"):
        self._ki = knowledge_index
        self._lock = threading.Lock()
        self._collection = None
        self._dirty = True          # fallback cache invalidation flag
        self._df: Counter = Counter()
        self._vecs: Dict[str, Dict] = {}
        self._meta: Dict[str, Dict] = {}
        try:
            import chromadb
            client = chromadb.PersistentClient(path=str(RAG_DIR / "chroma"))
            self._collection = client.get_or_create_collection(collection)
        except Exception:
            self._collection = None

    @property
    def engine(self) -> str:
        return "chroma" if self._collection is not None else "tfidf"

    # ── write path ────────────────────────────────────────────────
    def add_chunks(self, chunks: List[Dict]):
        """chunks: [{chunk_id, doc_id, content, section, seq, start, end}]"""
        if not chunks:
            return
        if self._collection is not None:
            self._collection.add(
                ids=[c["chunk_id"] for c in chunks],
                documents=[c["content"] for c in chunks],
                metadatas=[{"doc_id": c["doc_id"], "seq": c.get("seq", 0),
                            "section": c.get("section", ""),
                            "start": c.get("start", 0), "end": c.get("end", 0)}
                           for c in chunks])
        else:
            with self._lock:
                self._dirty = True

    def remove_document(self, doc_id: str):
        if self._collection is not None:
            try:
                self._collection.delete(where={"doc_id": doc_id})
            except Exception:
                pass
        else:
            with self._lock:
                self._dirty = True

    # ── read path ─────────────────────────────────────────────────
    def search(self, query: str, limit: int = 10) -> List[Dict]:
        query = (query or "").strip()
        if not query:
            return []
        if self._collection is not None:
            return self._search_chroma(query, limit)
        return self._search_tfidf(query, limit)

    # ── chroma engine ─────────────────────────────────────────────
    def _search_chroma(self, query: str, limit: int) -> List[Dict]:
        try:
            res = self._collection.query(query_texts=[query], n_results=limit)
        except Exception:
            return []
        hits = []
        ids = (res.get("ids") or [[]])[0]
        docs = (res.get("documents") or [[]])[0]
        metas = (res.get("metadatas") or [[]])[0]
        dists = (res.get("distances") or [[]])[0]
        for i, cid in enumerate(ids):
            meta = metas[i] if i < len(metas) else {}
            dist = dists[i] if i < len(dists) else 1.0
            hits.append({"chunk_id": cid, "doc_id": meta.get("doc_id", ""),
                         "seq": meta.get("seq", 0),
                         "content": docs[i] if i < len(docs) else "",
                         "section": meta.get("section", ""),
                         "start": meta.get("start", 0),
                         "end": meta.get("end", 0),
                         "score": round(1.0 / (1.0 + float(dist)), 4),
                         "engine": "vector"})
        return hits

    # ── tf-idf fallback engine ────────────────────────────────────
    def _rebuild(self):
        """Rebuild the TF-IDF cache from the KnowledgeIndex."""
        self._df, self._vecs, self._meta = Counter(), {}, {}
        if self._ki is None:
            self._dirty = False
            return
        for c in self._ki.all_chunks():
            terms = Counter(_tokenize(c["content"]))
            if not terms:
                continue
            cid = c["id"]
            self._vecs[cid] = terms
            self._meta[cid] = c
            for t in terms:
                self._df[t] += 1
        self._dirty = False

    def _search_tfidf(self, query: str, limit: int) -> List[Dict]:
        with self._lock:
            if self._dirty:
                self._rebuild()
            n_docs = max(1, len(self._vecs))
            q_terms = Counter(_tokenize(query))
            if not q_terms or not self._vecs:
                return []

            def idf(t):
                return math.log(1.0 + n_docs / (1.0 + self._df.get(t, 0)))

            q_vec = {t: f * idf(t) for t, f in q_terms.items()}
            q_norm = math.sqrt(sum(v * v for v in q_vec.values())) or 1.0

            scored = []
            for cid, terms in self._vecs.items():
                dot = sum(q_vec[t] * terms.get(t, 0) * idf(t) for t in q_vec)
                if dot <= 0:
                    continue
                d_norm = math.sqrt(sum((f * idf(t)) ** 2
                                       for t, f in terms.items())) or 1.0
                scored.append((dot / (q_norm * d_norm), cid))
            scored.sort(reverse=True)

            hits = []
            for score, cid in scored[:limit]:
                m = self._meta[cid]
                hits.append({"chunk_id": cid, "doc_id": m["doc_id"],
                             "seq": m["seq"], "content": m["content"],
                             "section": m["section"], "start": m["start_offset"],
                             "end": m["end_offset"],
                             "score": round(score, 4), "engine": "vector"})
            return hits
