"""
Maya 2.0 - RAG Chunker
----------------------
Splits documents into retrieval-sized chunks.

Strategies:
- markdown : split on headings, keep heading as chunk context
- code     : split on top-level def/class boundaries (language-agnostic heuristic)
- text     : paragraph packing with sliding overlap

Every chunk records its character offsets so source attribution can
point back to the exact location in the original document.
"""

import re
from typing import List, Dict

DEFAULT_CHUNK_SIZE = 900     # characters
DEFAULT_OVERLAP = 150        # characters carried between adjacent chunks
_MD_HEADING = re.compile(r"^(#{1,6})\s+(.+)$", re.MULTILINE)
_CODE_BOUNDARY = re.compile(
    r"^(?:def |class |function |func |public |private |protected |const |export )",
    re.MULTILINE,
)


class Chunker:
    """Turns raw text into a list of chunk dicts."""

    def __init__(self, chunk_size: int = DEFAULT_CHUNK_SIZE,
                 overlap: int = DEFAULT_OVERLAP):
        self.chunk_size = max(200, int(chunk_size))
        self.overlap = max(0, min(int(overlap), self.chunk_size // 2))

    # ── public API ────────────────────────────────────────────────
    def chunk(self, text: str, doc_type: str = "text") -> List[Dict]:
        """Return [{content, start, end, section}] for the given text."""
        text = (text or "").strip()
        if not text:
            return []
        if doc_type == "markdown":
            return self._chunk_markdown(text)
        if doc_type == "code":
            return self._chunk_code(text)
        return self._chunk_text(text)

    # ── strategies ────────────────────────────────────────────────
    def _chunk_text(self, text: str, base_offset: int = 0,
                    section: str = "") -> List[Dict]:
        """Paragraph packing with overlap between adjacent chunks."""
        paragraphs, pos = [], 0
        for para in re.split(r"\n\s*\n", text):
            start = text.find(para, pos)
            if start < 0:
                start = pos
            paragraphs.append((para.strip(), start))
            pos = start + len(para)

        chunks, buf, buf_start = [], "", 0
        for para, start in paragraphs:
            if not para:
                continue
            if not buf:
                buf, buf_start = para, start
            elif len(buf) + len(para) + 2 <= self.chunk_size:
                buf += "\n\n" + para
            else:
                chunks.append(self._make(buf, buf_start, base_offset, section))
                tail = buf[-self.overlap:] if self.overlap else ""
                buf = (tail + "\n\n" + para) if tail else para
                buf_start = start - len(tail)
            # single paragraph longer than chunk_size → hard split
            while len(buf) > self.chunk_size * 1.5:
                head, buf = buf[:self.chunk_size], buf[self.chunk_size - self.overlap:]
                chunks.append(self._make(head, buf_start, base_offset, section))
                buf_start += self.chunk_size - self.overlap
        if buf:
            chunks.append(self._make(buf, buf_start, base_offset, section))
        return chunks

    def _chunk_markdown(self, text: str) -> List[Dict]:
        """Split on headings; each section is chunked with its heading kept."""
        matches = list(_MD_HEADING.finditer(text))
        if not matches:
            return self._chunk_text(text)
        chunks: List[Dict] = []
        preamble = text[:matches[0].start()].strip()
        if preamble:
            chunks.extend(self._chunk_text(preamble, 0, ""))
        for i, m in enumerate(matches):
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            body = text[m.end():end].strip()
            title = m.group(2).strip()
            if body:
                for c in self._chunk_text(body, m.end(), title):
                    c["content"] = f"{title}\n{c['content']}"
                    chunks.append(c)
            else:
                chunks.append(self._make(title, m.start(), 0, title))
        return chunks

    def _chunk_code(self, text: str) -> List[Dict]:
        """Split at function/class boundaries, pack small units together."""
        boundaries = [m.start() for m in _CODE_BOUNDARY.finditer(text)] or [0]
        if boundaries[0] != 0:
            boundaries.insert(0, 0)
        units = []
        for i, b in enumerate(boundaries):
            e = boundaries[i + 1] if i + 1 < len(boundaries) else len(text)
            unit = text[b:e]
            if unit.strip():
                units.append((unit, b))

        chunks, buf, buf_start = [], "", 0
        for unit, start in units:
            if not buf:
                buf, buf_start = unit, start
            elif len(buf) + len(unit) <= self.chunk_size:
                buf += unit
            else:
                chunks.append(self._make(buf.rstrip(), buf_start, 0, "code"))
                buf, buf_start = unit, start
            while len(buf) > self.chunk_size * 2:      # giant unit → hard split
                head, buf = buf[:self.chunk_size], buf[self.chunk_size:]
                chunks.append(self._make(head, buf_start, 0, "code"))
                buf_start += self.chunk_size
        if buf.strip():
            chunks.append(self._make(buf.rstrip(), buf_start, 0, "code"))
        return chunks

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _make(content: str, start: int, base: int, section: str) -> Dict:
        s = base + max(0, start)
        return {"content": content, "start": s, "end": s + len(content),
                "section": section or ""}
