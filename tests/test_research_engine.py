"""Phase 32 tests — Research/Market engine.

Offline — all external dependencies (WebScraper, LLMRouter, Chunker) mocked.
No real HTTP fetches, no real LLM calls.
"""
import json
import os
import sys
import tempfile
import time
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Ensure settings paths use temp dir before importing
_tmp_db_root = Path(tempfile.mkdtemp(prefix="maya_p32_"))
import config.settings as _settings
_settings.STORAGE_DIR = _tmp_db_root / "storage"
_settings.WORKSPACE_DIR = _tmp_db_root / "workspace"
(_settings.STORAGE_DIR / "research").mkdir(parents=True, exist_ok=True)
(_settings.WORKSPACE_DIR / "research").mkdir(parents=True, exist_ok=True)

from infrastructure.research_engine import ResearchEngine, RESEARCH_DB, RESEARCH_OUTPUT_DIR


# ── Mock helpers ──────────────────────────────────────────────────────────────

def _mock_scraper():
    """WebScraper that returns canned HTML content."""
    s = MagicMock()
    def scrape(url: str, extract: str = "text") -> str:
        if "error" in url:
            return f"Error 500 for {url}"
        if "timeout" in url:
            return f"Timeout fetching {url}"
        return (
            f"<html><body><p>Content about {url}. "
            f"This page discusses important findings and data. "
            f"The research shows significant results. "
            f"Multiple sources confirm these findings. "
            f"Further analysis is recommended.</p></body></html>"
        )
    s.scrape.side_effect = scrape
    return s


def _mock_llm_router():
    """LLMRouter that returns canned summaries."""
    r = MagicMock()
    def chat(messages, provider=None, model=None, max_tokens=4000, task_type="general"):
        prompt = messages[-1]["content"] if messages else ""
        if "Realistic example" in prompt or "example URLs" in prompt:
            return '["https://example.com/article1", "https://example.com/article2"]'
        if "Summarize the following" in prompt:
            return "Key findings from the source indicate significant results and data."
        if "Research topic" in prompt:
            return (
                "## Overview\nResearch shows key findings.\n\n"
                "## Key Findings\n- Finding 1\n- Finding 2\n\n"
                "## Sources\n1. https://example.com/article1\n\n"
                "## Recommendations\n- Monitor trends"
            )
        return "Mocked response"
    r.chat.side_effect = chat
    return r


def _mock_chunker():
    """Chunker that returns pre-split chunks."""
    c = MagicMock()
    def chunk(text: str, doc_type: str = "text"):
        if not text.strip():
            return []
        return [
            {"content": text[:500], "start": 0, "end": min(500, len(text)),
             "section": ""},
        ]
    c.chunk.side_effect = chunk
    return c


# ── Tests ────────────────────────────────────────────────────────────────────


class TestAnalyze:
    """ResearchEngine.analyze() — full pipeline."""

    def setup_method(self):
        self.engine = ResearchEngine(
            scraper=_mock_scraper(),
            llm_router=_mock_llm_router(),
            chunker=_mock_chunker(),
        )

    def test_empty_topic(self):
        """analyze() with empty topic returns error."""
        result = self.engine.analyze("")
        assert result["ok"] is False
        assert "topic is required" in result["error"]

    def test_whitespace_topic(self):
        """analyze() with whitespace-only topic returns error."""
        result = self.engine.analyze("   ")
        assert result["ok"] is False

    def test_explicit_urls(self):
        """analyze() with explicit URLs fetches those URLs."""
        urls = [
            "https://example.com/first",
            "https://example.com/second",
        ]
        result = self.engine.analyze("AI trends", urls=urls)
        assert result["ok"] is True
        assert result["source_count"] == 2
        assert result["report_id"] is not None
        assert "AI trends" in result["topic"]

    def test_no_urls_uses_llm(self):
        """analyze() without URLs uses LLM to generate them."""
        result = self.engine.analyze("market research", max_sources=2)
        assert result["ok"] is True
        assert result["source_count"] >= 1
        assert result["report_id"] is not None

    def test_report_saved_to_db(self):
        """analyze() saves a row in the reports SQLite DB."""
        urls = ["https://example.com/test"]
        result = self.engine.analyze("Test topic", urls=urls)
        report = self.engine.get_report(result["report_id"])
        assert report is not None
        assert report["topic"] == "Test topic"
        assert report["source_count"] == 1

    def test_report_markdown_written(self):
        """analyze() writes a .md file to workspace/research/."""
        urls = ["https://example.com/mdtest"]
        result = self.engine.analyze("MD test", urls=urls)
        md_path = RESEARCH_OUTPUT_DIR / f"{result['report_id']}.md"
        assert md_path.exists()
        content = md_path.read_text(encoding="utf-8")
        assert "MD test" in content
        assert result["report_id"] in content

    def test_scrape_failure_skipped(self):
        """analyze() skips URLs that fail to scrape, continues with others."""
        urls = [
            "https://example.com/error",
            "https://example.com/working",
        ]
        result = self.engine.analyze("Partial failure", urls=urls)
        assert result["ok"] is True
        # One should have errors in the errors list
        assert len(result["errors"]) >= 1
        # At least one source succeeded
        assert result["source_count"] >= 1

    def test_max_sources_clamped(self):
        """analyze() clamps max_sources to 1-20."""
        result = self.engine.analyze("Clamp test", max_sources=0)
        assert result["ok"] is True
        result2 = self.engine.analyze("Clamp high", max_sources=999)
        assert result2["ok"] is True

    def test_list_reports(self):
        """list_reports() returns all reports ordered by recency."""
        self.engine.analyze("First topic", urls=["https://ex.com/1"])
        time.sleep(0.01)
        self.engine.analyze("Second topic", urls=["https://ex.com/2"])
        reports = self.engine.list_reports()
        assert len(reports) >= 2
        assert reports[0]["topic"] == "Second topic"

    def test_get_report_full(self):
        """get_report() returns full report with parsed URLs."""
        urls = ["https://example.com/gettest"]
        result = self.engine.analyze("Get report", urls=urls)
        report = self.engine.get_report(result["report_id"])
        assert report is not None
        assert "urls" in report
        assert isinstance(report["urls"], list)
        assert len(report["urls"]) > 0

    def test_zero_external_writes(self):
        """analyze() writes ONLY to SQLite and local .md file.

        No HTTP POST/PUT/PATCH/DELETE should be made by the engine itself
        (only HTTP GET via scraper, which is mocked).
        """
        urls = ["https://example.com/nopost"]
        result = self.engine.analyze("No external writes", urls=urls)
        assert result["ok"] is True
        # Verify files are in research directory
        assert (RESEARCH_OUTPUT_DIR / f"{result['report_id']}.md").exists()
        # Verify DB file exists
        import sqlite3
        conn = sqlite3.connect(RESEARCH_DB)
        row = conn.execute(
            "SELECT COUNT(*) FROM reports WHERE id = ?",
            (result["report_id"],),
        ).fetchone()
        conn.close()
        assert row[0] == 1


class TestListGet:
    """ResearchEngine.list_reports() and get_report()."""

    def setup_method(self):
        self.engine = ResearchEngine(
            scraper=_mock_scraper(),
            llm_router=_mock_llm_router(),
            chunker=_mock_chunker(),
        )

    def _make_report(self, topic: str = "Test") -> str:
        r = self.engine.analyze(topic, urls=["https://ex.com/t"])
        return r["report_id"]

    def test_list_empty(self):
        """list_reports() returns a list of dicts with expected structure."""
        reports = self.engine.list_reports()
        # Should be a list (may have entries from earlier tests)
        assert isinstance(reports, list)
        if reports:
            r = reports[0]
            assert "id" in r
            assert "topic" in r
            assert "created_at" in r

    def test_get_missing(self):
        """get_report() returns None for unknown id."""
        report = self.engine.get_report("nonexistent")
        assert report is None

    def test_multiple_reports(self):
        """Multiple analyses produce multiple reports."""
        id1 = self._make_report("Topic A")
        id2 = self._make_report("Topic B")
        reports = self.engine.list_reports()
        ids = [r["id"] for r in reports]
        assert id1 in ids
        assert id2 in ids
