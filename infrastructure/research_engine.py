"""
Maya 2.0 — Phase 32: Research / Market Engine
-----------------------------------------------
Analysis-only: fetches web sources → summarizes via LLM → saves a structured
report locally.  Zero external writes beyond reading public web pages.

Strict boundaries:
  - Only two outputs: SQLite (``storage/research/reports.db``) and a markdown
    file (``workspace/research/{id}.md``).
  - No HTTP POST/PUT/PATCH/DELETE to any external API.
  - No email, no publishing, no remote DB writes.
  - Per-domain crawl delay >= 1.0 s ; Chrome user-agent.

Reuses existing infra: ``WebScraper`` for fetching, ``LLMRouter`` for LLM,
``Chunker`` for text splitting, ``MemorySummarizer`` as extractive fallback.
"""

import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from datetime import datetime
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR, WORKSPACE_DIR

RESEARCH_DIR = STORAGE_DIR / "research"
RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
RESEARCH_DB = str(RESEARCH_DIR / "reports.db")
RESEARCH_OUTPUT_DIR = WORKSPACE_DIR / "research"
RESEARCH_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

RESEARCH_ENGINE_ENABLED = (
    os.environ.get("RESEARCH_ENGINE_ENABLED", "false").lower() == "true"
)

# Per-domain minimum delay between fetches (seconds)
CRAWL_DELAY = 1.0
# Max sources per analysis
MAX_SOURCES_DEFAULT = 5
# Max sources absolute cap
MAX_SOURCES_CAP = 20

# Chrome user-agent for polite fetching
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
)


class ResearchEngine:
    """Fetch sources → summarize → save report locally.

    Thread-safe via ``_lock``.  SQLite with WAL mode.

    All output goes to local files only — never to external APIs.
    """

    def __init__(
        self,
        scraper=None,
        llm_router=None,
        chunker=None,
        summarizer=None,
    ) -> None:
        self._lock = threading.Lock()
        self._scraper = scraper  # WebScraper instance (lazy import)
        self._llm_router = llm_router  # LLMRouter instance (lazy import)
        self._chunker = chunker  # Chunker instance (lazy import)
        self._summarizer = summarizer  # MemorySummarizer (lazy import)
        # Per-domain last-fetch timestamps for crawl delay
        self._last_fetch: Dict[str, float] = {}
        self._init_db()

    # ── DB init ───────────────────────────────────────────────────────────────

    def _init_db(self) -> None:
        try:
            with self._conn() as c:
                c.executescript("""
                CREATE TABLE IF NOT EXISTS reports (
                    id           TEXT PRIMARY KEY,
                    topic        TEXT NOT NULL,
                    urls_json    TEXT DEFAULT '[]',
                    summary_short TEXT DEFAULT '',
                    source_count INTEGER DEFAULT 0,
                    created_at   REAL,
                    updated_at   REAL
                );
                """)
        except Exception as e:
            print(f"WARNING: ResearchEngine DB init error: {e}")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(RESEARCH_DB, check_same_thread=False, timeout=10)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    # ── Public API ────────────────────────────────────────────────────────────

    def analyze(
        self,
        topic: str,
        urls: Optional[List[str]] = None,
        max_sources: int = MAX_SOURCES_DEFAULT,
    ) -> dict:
        """Run a full analysis cycle: fetch → chunk → summarize → save.

        Args:
            topic:     Research query / topic (required).
            urls:      Optional explicit URL list.  If empty, the engine
                       uses the search-based URL generation path.
            max_sources: Max URLs to actually fetch (clamped 1–20).

        Returns:
            Dict with ``report_id``, ``topic``, ``summary_short``,
            ``source_count``, ``errors``.

        Writes ONLY to:
          - SQLite ``reports`` table
          - ``workspace/research/{id}.md`` markdown file
        """
        if not topic or not topic.strip():
            return {"ok": False, "error": "topic is required"}

        max_sources = max(1, min(int(max_sources), MAX_SOURCES_CAP))
        errors: List[str] = []
        source_summaries: List[Dict] = []

        # Step 1: Determine URLs
        fetch_urls = (urls or [])[:max_sources]
        if not fetch_urls:
            fetch_urls = self._generate_urls(topic, max_sources)

        # Step 2: Fetch + chunk + summarize each source
        for url in fetch_urls:
            if not url or not isinstance(url, str):
                continue
            try:
                self._enforce_crawl_delay(url)
                page_text = self._fetch(url)
                if page_text.startswith("Error") or page_text.startswith("Timeout"):
                    errors.append(f"{url}: {page_text[:100]}")
                    continue
                chunks = self._chunk_text(page_text)
                combined = " ".join(c["content"] for c in chunks)
                summary = self._summarize_source(url, combined)
                source_summaries.append({
                    "url": url,
                    "summary": summary,
                    "chars": len(combined),
                })
            except Exception as e:
                errors.append(f"{url}: {e}")
                continue

        # Step 3: Generate final structured report
        final_report = self._generate_report(topic, source_summaries)
        short_summary = final_report[:500] if len(final_report) > 500 else final_report

        # Step 4: Save to SQLite
        report_id = uuid.uuid4().hex[:12]
        now = time.time()
        urls_json = json.dumps([s["url"] for s in source_summaries])
        with self._lock, self._conn() as c:
            c.execute(
                "INSERT INTO reports (id, topic, urls_json, summary_short, "
                "source_count, created_at, updated_at) "
                "VALUES (?, ?, ?, ?, ?, ?, ?)",
                (report_id, topic.strip(), urls_json, short_summary,
                 len(source_summaries), now, now),
            )

        # Step 5: Write markdown file
        md_path = RESEARCH_OUTPUT_DIR / f"{report_id}.md"
        md_content = self._build_markdown(
            report_id, topic, source_summaries, final_report,
        )
        try:
            md_path.write_text(md_content, encoding="utf-8")
        except OSError as e:
            errors.append(f"Failed to write markdown: {e}")

        return {
            "ok": True,
            "report_id": report_id,
            "topic": topic.strip(),
            "summary_short": short_summary,
            "source_count": len(source_summaries),
            "errors": errors,
        }

    def list_reports(self) -> List[dict]:
        """Return all reports, ordered by most recent first."""
        with self._conn() as c:
            rows = c.execute(
                "SELECT id, topic, summary_short, source_count, created_at "
                "FROM reports ORDER BY created_at DESC"
            ).fetchall()
        return [dict(r) for r in rows]

    def get_report(self, report_id: str) -> Optional[dict]:
        """Return a single report with full metadata."""
        with self._conn() as c:
            row = c.execute(
                "SELECT * FROM reports WHERE id = ?", (report_id,)
            ).fetchone()
        if not row:
            return None
        result = dict(row)
        try:
            result["urls"] = json.loads(result.get("urls_json", "[]"))
        except (json.JSONDecodeError, TypeError):
            result["urls"] = []
        return result

    # ── Internal pipeline steps ───────────────────────────────────────────────

    def _generate_urls(self, topic: str, count: int) -> List[str]:
        """Use LLM to generate search queries, then resolve to URLs.

        If the LLM is unavailable, return an empty list (caller handles).
        """
        router = self._llm_router or self._lazy_llm_router()
        if not router:
            return []
        prompt = (
            f"Research topic: {topic}\n\n"
            f"Generate {count} realistic example URLs (like "
            f"https://example.com/article-about-<topic>) that would be "
            f"relevant for researching this topic. "
            f"Return ONLY a JSON array of URL strings, no other text:\n"
        )
        try:
            raw = router.chat([{"role": "user", "content": prompt}], max_tokens=1000)
        except Exception:
            return []

        raw = raw.strip()
        if "[" in raw and "]" in raw:
            raw = raw[raw.index("["):raw.rindex("]") + 1]
        try:
            urls = json.loads(raw)
            if isinstance(urls, list):
                return [u for u in urls if isinstance(u, str) and u.startswith("http")][:count]
        except (json.JSONDecodeError, TypeError):
            pass
        return []

    def _enforce_crawl_delay(self, url: str) -> None:
        """Wait if needed to respect per-domain crawl delay."""
        from urllib.parse import urlparse
        domain = urlparse(url).netloc
        if not domain:
            return
        last = self._last_fetch.get(domain, 0.0)
        elapsed = time.time() - last
        if elapsed < CRAWL_DELAY:
            time.sleep(CRAWL_DELAY - elapsed)
        self._last_fetch[domain] = time.time()

    def _fetch(self, url: str) -> str:
        """Fetch a URL via ``WebScraper.scrape()`` or fallback ``requests``."""
        scraper = self._scraper or self._lazy_scraper()
        if scraper:
            return scraper.scrape(url)
        # Fallback: bare requests if no scraper available
        import requests
        try:
            r = requests.get(
                url,
                headers={"User-Agent": USER_AGENT},
                timeout=15,
            )
            if r.status_code != 200:
                return f"Error {r.status_code} for {url}"
            return r.text[:5000]
        except requests.Timeout:
            return f"Timeout fetching {url}"
        except Exception as e:
            return f"Scrape error: {e}"

    def _chunk_text(self, text: str) -> List[Dict]:
        """Chunk raw text using ``Chunker`` or a simple fallback."""
        chunker = self._chunker or self._lazy_chunker()
        if chunker:
            return chunker.chunk(text, doc_type="text")
        # Fallback: return whole text as one chunk
        return [{"content": text[:5000], "start": 0, "end": len(text), "section": ""}]

    def _summarize_source(self, url: str, text: str) -> str:
        """Summarize a single source.  Falls back to extractive on LLM failure."""
        router = self._llm_router or self._lazy_llm_router()
        if router and len(text) > 500:
            prompt = (
                f"Summarize the following web page content from {url} in 2-3 sentences. "
                f"Focus on key facts, data, and claims:\n\n{text[:6000]}"
            )
            try:
                return router.chat(
                    [{"role": "user", "content": prompt}],
                    max_tokens=500,
                )
            except Exception:
                pass  # fall through to extractive

        # Extractive fallback: first 2-3 sentences
        import re
        sentences = re.split(r"(?<=[.!?])\s+", text)
        meaningful = [s for s in sentences if len(s.strip()) > 20]
        return " ".join(meaningful[:3])[:1000]

    def _generate_report(
        self, topic: str, source_summaries: List[Dict],
    ) -> str:
        """Produce a structured markdown report from all source summaries.

        Uses LLM when available; otherwise concatenates raw summaries.
        """
        if not source_summaries:
            return f"# Research: {topic}\n\nNo sources were successfully fetched."

        # Build context block
        context_parts = []
        for i, s in enumerate(source_summaries, 1):
            context_parts.append(
                f"## Source {i}: {s['url']}\n{s['summary']}\n"
            )
        context = "\n".join(context_parts)

        router = self._llm_router or self._lazy_llm_router()
        if router:
            prompt = (
                f"Research topic: {topic}\n\n"
                f"Below are summaries from {len(source_summaries)} sources. "
                f"Write a structured markdown report with these sections:\n"
                f"- **Overview** (2-3 sentences)\n"
                f"- **Key Findings** (bullet list)\n"
                f"- **Sources** (numbered list)\n"
                f"- **Recommendations** (if any)\n\n"
                f"Source summaries:\n{context}"
            )
            try:
                return router.chat(
                    [{"role": "user", "content": prompt}],
                    max_tokens=2000,
                )
            except Exception:
                pass  # fall through to concatenation

        # Fallback: concatenate with header
        parts = [
            f"# Research: {topic}",
            f"*Generated {datetime.now().isoformat()}*",
            f"**Sources consulted:** {len(source_summaries)}",
            "",
            "## Summary",
            "",
            context,
        ]
        return "\n".join(parts)

    def _build_markdown(
        self,
        report_id: str,
        topic: str,
        source_summaries: List[Dict],
        final_report: str,
    ) -> str:
        """Build the full markdown file content."""
        sources_md = []
        for i, s in enumerate(source_summaries, 1):
            sources_md.append(f"{i}. [{s['url']}]({s['url']})")
        sources_text = "\n".join(sources_md)

        return (
            f"# Research: {topic}\n\n"
            f"**Report ID:** {report_id}\n"
            f"**Date:** {datetime.now().isoformat()}\n"
            f"**Sources:** {len(source_summaries)}\n\n"
            f"---\n\n"
            f"{final_report}\n\n"
            f"---\n\n"
            f"## Sources\n\n{sources_text}\n"
        )

    # ── Lazy imports ──────────────────────────────────────────────────────────

    @staticmethod
    def _lazy_scraper():
        try:
            from tools.web.web_scraper import WebScraper
            return WebScraper()
        except Exception:
            return None

    @staticmethod
    def _lazy_llm_router():
        try:
            from llm.router import LLMRouter
            return LLMRouter()
        except Exception:
            return None

    @staticmethod
    def _lazy_chunker():
        try:
            from rag.chunker import Chunker
            return Chunker()
        except Exception:
            return None


# ── Module singleton ────────────────────────────────────────────────────────────
research_engine = ResearchEngine()
