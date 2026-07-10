"""
Maya 2.0 - RAG Knowledge Index (Thread-safe)
--------------------------------------------
Persistent document + chunk store backed by SQLite, following the same
connection-pooling pattern as memory/long_term.py.

Keyword search uses SQLite FTS5 with BM25 ranking (built into the
standard library's SQLite on all supported platforms). When FTS5 is
unavailable the index transparently falls back to LIKE matching so the
system keeps working everywhere.

Deduplication: identical content (by SHA-256) is never indexed twice —
re-ingesting a document replaces its previous version and bumps the
version counter.
"""

import hashlib
import json
import sqlite3
import threading
import uuid
from contextlib import contextmanager
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR

RAG_DIR = STORAGE_DIR / "rag"
RAG_DIR.mkdir(parents=True, exist_ok=True)
RAG_DB_FILE = str(RAG_DIR / "knowledge.db")


class KnowledgeIndex:
    """Thread-safe SQLite knowledge base with FTS5 keyword search."""

    def __init__(self, db_path: str = RAG_DB_FILE):
        self.db = db_path
        self._lock = threading.Lock()
        self._fts_enabled = False
        self._init_db()

    # ── schema ────────────────────────────────────────────────────
    def _init_db(self):
        with self._get_conn() as conn:
            conn.execute("""CREATE TABLE IF NOT EXISTS documents (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                doc_type TEXT DEFAULT 'text',
                source TEXT DEFAULT 'inline',
                content_hash TEXT NOT NULL,
                char_count INTEGER DEFAULT 0,
                chunk_count INTEGER DEFAULT 0,
                version INTEGER DEFAULT 1,
                metadata TEXT DEFAULT '{}',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )""")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_doc_hash "
                         "ON documents(content_hash)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_doc_source "
                         "ON documents(source)")
            conn.execute("""CREATE TABLE IF NOT EXISTS chunks (
                id TEXT PRIMARY KEY,
                doc_id TEXT NOT NULL,
                seq INTEGER NOT NULL,
                content TEXT NOT NULL,
                section TEXT DEFAULT '',
                start_offset INTEGER DEFAULT 0,
                end_offset INTEGER DEFAULT 0,
                FOREIGN KEY (doc_id) REFERENCES documents(id)
            )""")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_chunk_doc "
                         "ON chunks(doc_id)")
            try:
                conn.execute("""CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts
                    USING fts5(content, section,
                               content='chunks', content_rowid='rowid')""")
                self._fts_enabled = True
            except sqlite3.OperationalError:
                self._fts_enabled = False   # LIKE fallback below

    @contextmanager
    def _get_conn(self):
        conn = sqlite3.connect(self.db, check_same_thread=False, timeout=10)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    # ── write path ────────────────────────────────────────────────
    def add_document(self, title: str, chunks: List[Dict], doc_type: str = "text",
                     source: str = "inline", char_count: int = 0,
                     metadata: Optional[Dict] = None) -> Dict:
        """Index a chunked document. Dedupes by content hash; re-ingesting
        the same source replaces the old version and bumps `version`."""
        content_hash = hashlib.sha256(
            "\n".join(c["content"] for c in chunks).encode("utf-8", "replace")
        ).hexdigest()
        with self._lock, self._get_conn() as conn:
            dup = conn.execute("SELECT id, version FROM documents "
                               "WHERE content_hash = ?", (content_hash,)).fetchone()
            if dup:
                return {"doc_id": dup["id"], "deduplicated": True,
                        "version": dup["version"], "chunks": 0}

            prev = conn.execute("SELECT id, version FROM documents "
                                "WHERE source = ? AND source != 'inline'",
                                (source,)).fetchone()
            version = 1
            if prev:                            # replace older version
                version = int(prev["version"]) + 1
                self._delete_doc_rows(conn, prev["id"])

            doc_id = str(uuid.uuid4())[:12]
            conn.execute(
                "INSERT INTO documents (id, title, doc_type, source, content_hash,"
                " char_count, chunk_count, version, metadata)"
                " VALUES (?,?,?,?,?,?,?,?,?)",
                (doc_id, title, doc_type, source, content_hash, char_count,
                 len(chunks), version, json.dumps(metadata or {})))
            for i, c in enumerate(chunks):
                rowid = conn.execute(
                    "INSERT INTO chunks (id, doc_id, seq, content, section,"
                    " start_offset, end_offset) VALUES (?,?,?,?,?,?,?)",
                    (f"{doc_id}:{i}", doc_id, i, c["content"],
                     c.get("section", ""), c.get("start", 0), c.get("end", 0))
                ).lastrowid
                if self._fts_enabled:
                    conn.execute("INSERT INTO chunks_fts (rowid, content, section)"
                                 " VALUES (?,?,?)",
                                 (rowid, c["content"], c.get("section", "")))
            return {"doc_id": doc_id, "deduplicated": False,
                    "version": version, "chunks": len(chunks)}

    def delete_document(self, doc_id: str) -> bool:
        with self._lock, self._get_conn() as conn:
            row = conn.execute("SELECT id FROM documents WHERE id = ?",
                               (doc_id,)).fetchone()
            if not row:
                return False
            self._delete_doc_rows(conn, doc_id)
            return True

    def _delete_doc_rows(self, conn, doc_id: str):
        if self._fts_enabled:
            conn.execute("""DELETE FROM chunks_fts WHERE rowid IN
                (SELECT rowid FROM chunks WHERE doc_id = ?)""", (doc_id,))
        conn.execute("DELETE FROM chunks WHERE doc_id = ?", (doc_id,))
        conn.execute("DELETE FROM documents WHERE id = ?", (doc_id,))

    # ── read path ─────────────────────────────────────────────────
    def keyword_search(self, query: str, limit: int = 10) -> List[Dict]:
        """BM25-ranked keyword search over all chunks."""
        query = (query or "").strip()
        if not query:
            return []
        with self._get_conn() as conn:
            if self._fts_enabled:
                fts_q = " OR ".join(
                    '"' + t.replace('"', "") + '"'
                    for t in query.split() if t.strip()) or '""'
                try:
                    rows = conn.execute(
                        """SELECT c.id, c.doc_id, c.seq, c.content, c.section,
                                  c.start_offset, c.end_offset,
                                  bm25(chunks_fts) AS rank
                           FROM chunks_fts
                           JOIN chunks c ON c.rowid = chunks_fts.rowid
                           WHERE chunks_fts MATCH ?
                           ORDER BY rank LIMIT ?""", (fts_q, limit)).fetchall()
                    return [self._row_to_hit(r, -float(r["rank"])) for r in rows]
                except sqlite3.OperationalError:
                    pass                        # fall through to LIKE
            like = f"%{query}%"
            rows = conn.execute(
                """SELECT id, doc_id, seq, content, section,
                          start_offset, end_offset, 1.0 AS rank
                   FROM chunks WHERE content LIKE ? LIMIT ?""",
                (like, limit)).fetchall()
            return [self._row_to_hit(r, 1.0) for r in rows]

    def all_chunks(self, limit: int = 50000) -> List[Dict]:
        with self._get_conn() as conn:
            rows = conn.execute(
                "SELECT id, doc_id, seq, content, section, start_offset,"
                " end_offset FROM chunks LIMIT ?", (limit,)).fetchall()
            return [dict(r) for r in rows]

    def get_document(self, doc_id: str) -> Optional[Dict]:
        with self._get_conn() as conn:
            row = conn.execute("SELECT * FROM documents WHERE id = ?",
                               (doc_id,)).fetchone()
            return dict(row) if row else None

    def list_documents(self, limit: int = 200) -> List[Dict]:
        with self._get_conn() as conn:
            rows = conn.execute(
                "SELECT id, title, doc_type, source, chunk_count, char_count,"
                " version, created_at, updated_at FROM documents"
                " ORDER BY updated_at DESC LIMIT ?", (limit,)).fetchall()
            return [dict(r) for r in rows]

    def stats(self) -> Dict:
        with self._get_conn() as conn:
            docs = conn.execute("SELECT COUNT(*) AS n, COALESCE(SUM(char_count),0)"
                                " AS chars FROM documents").fetchone()
            chunks = conn.execute("SELECT COUNT(*) AS n FROM chunks").fetchone()
            by_type = conn.execute("SELECT doc_type, COUNT(*) AS n FROM documents"
                                   " GROUP BY doc_type").fetchall()
            return {"documents": docs["n"], "chunks": chunks["n"],
                    "total_chars": docs["chars"],
                    "by_type": {r["doc_type"]: r["n"] for r in by_type},
                    "fts5": self._fts_enabled}

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _row_to_hit(row, score: float) -> Dict:
        return {"chunk_id": row["id"], "doc_id": row["doc_id"],
                "seq": row["seq"], "content": row["content"],
                "section": row["section"], "start": row["start_offset"],
                "end": row["end_offset"], "score": round(float(score), 4),
                "engine": "keyword"}
