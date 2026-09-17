"""
Maya 2.0 - RAG Hybrid Search + Source Attribution
-------------------------------------------------
HybridSearch fuses keyword (BM25/FTS5) and vector results using
Reciprocal Rank Fusion (RRF) — robust because it needs no score
normalization between engines.

SourceAttributor turns raw hits into user-facing citations and builds
the final context block handed to the LLM, with numbered [n] markers
so answers can point at their sources.
"""

from typing import Dict, List, Optional

RRF_K = 60   # standard RRF damping constant


class HybridSearch:
    """Fuses keyword and vector hit lists into one ranked list."""

    def __init__(self, knowledge_index, vector_index):
        self.ki = knowledge_index
        self.vi = vector_index

    def search(self, query: str, limit: int = 5, mode: str = "hybrid") -> List[Dict]:
        """mode: 'hybrid' | 'keyword' | 'vector'"""
        fetch = max(limit * 3, 10)
        if mode == "keyword":
            return self.ki.keyword_search(query, limit=limit)
        if mode == "vector":
            return self.vi.search(query, limit=limit)

        kw = self.ki.keyword_search(query, limit=fetch)
        vec = self.vi.search(query, limit=fetch)
        return self._rrf([kw, vec], limit)

    @staticmethod
    def _rrf(result_lists: List[List[Dict]], limit: int) -> List[Dict]:
        fused: Dict[str, Dict] = {}
        scores: Dict[str, float] = {}
        engines: Dict[str, set] = {}
        for hits in result_lists:
            for rank, hit in enumerate(hits):
                cid = hit["chunk_id"]
                scores[cid] = scores.get(cid, 0.0) + 1.0 / (RRF_K + rank + 1)
                engines.setdefault(cid, set()).add(hit.get("engine", "?"))
                if cid not in fused:
                    fused[cid] = hit
        ranked = sorted(fused.values(),
                        key=lambda h: scores[h["chunk_id"]], reverse=True)
        out = []
        for h in ranked[:limit]:
            h = dict(h)
            h["score"] = round(scores[h["chunk_id"]], 4)
            h["engine"] = "+".join(sorted(engines[h["chunk_id"]]))
            out.append(h)
        return out


class SourceAttributor:
    """Builds citations and an LLM-ready context block from hits."""

    def __init__(self, knowledge_index):
        self.ki = knowledge_index
        self._doc_cache: Dict[str, Dict] = {}

    def _doc(self, doc_id: str) -> Dict:
        if doc_id not in self._doc_cache:
            self._doc_cache[doc_id] = self.ki.get_document(doc_id) or {}
        return self._doc_cache[doc_id]

    def attribute(self, hits: List[Dict]) -> List[Dict]:
        """Attach document title/source/type to each hit."""
        out = []
        for i, h in enumerate(hits):
            doc = self._doc(h["doc_id"])
            out.append({
                "ref": i + 1,
                "chunk_id": h["chunk_id"],
                "doc_id": h["doc_id"],
                "title": doc.get("title", "unknown"),
                "source": doc.get("source", "unknown"),
                "doc_type": doc.get("doc_type", "text"),
                "section": h.get("section", ""),
                "offsets": [h.get("start", 0), h.get("end", 0)],
                "score": h.get("score", 0.0),
                "engine": h.get("engine", ""),
                "content": h.get("content", ""),
            })
        return out

    @staticmethod
    def build_context(cited: List[Dict], max_chars: int = 6000) -> str:
        """Numbered context block for prompting, truncated to max_chars."""
        parts, used = [], 0
        for c in cited:
            head = f"[{c['ref']}] {c['title']}"
            if c["section"]:
                head += f" — {c['section']}"
            block = f"{head}\n{c['content']}\n"
            if used + len(block) > max_chars:
                remain = max_chars - used - len(head) - 2
                if remain > 100:
                    block = f"{head}\n{c['content'][:remain]}…\n"
                else:
                    break
            parts.append(block)
            used += len(block)
        return "\n".join(parts)

    @staticmethod
    def format_citations(cited: List[Dict]) -> List[Dict]:
        """Public citation objects (no chunk content) for API responses."""
        return [{k: c[k] for k in
                 ("ref", "title", "source", "doc_type", "section",
                  "offsets", "score", "engine")}
                for c in cited]
