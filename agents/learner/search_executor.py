"""
Search and web scraping executor for Maya-Learner.
Uses ddgs (DuckDuckGo Search) library for reliable search results.
"""
import asyncio
import uuid
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime

from ddgs import DDGS
from tools.web.web_scraper import WebScraper
from agents.learner.config import LearnerConfig


@dataclass
class SearchResult:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    query: str = ""
    title: str = ""
    url: str = ""
    snippet: str = ""
    rank: int = 0
    timestamp: datetime = field(default_factory=datetime.utcnow)


@dataclass
class ScrapedContent:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    url: str = ""
    title: str = ""
    content: str = ""
    content_length: int = 0
    success: bool = True
    error: Optional[str] = None
    timestamp: datetime = field(default_factory=datetime.utcnow)


class SearchExecutor:
    """Handles web search and content scraping for learning tasks using ddgs."""

    def __init__(self, config: Optional[LearnerConfig] = None):
        self.config = config or LearnerConfig
        self.ddgs = DDGS()
        self.scraper = WebScraper()
        self._last_fetch: Dict[str, float] = {}

    async def search(self, query: str, max_results: Optional[int] = None) -> List[SearchResult]:
        """Execute a web search using ddgs and return structured results."""
        max_results = max_results or self.config.MAX_SEARCH_RESULTS
        results = []

        try:
            # Run ddgs search in executor to avoid blocking
            raw_results = await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: list(self.ddgs.text(query, max_results=max_results))
            )

            for i, r in enumerate(raw_results[:max_results]):
                results.append(SearchResult(
                    query=query,
                    title=r.get("title", ""),
                    url=r.get("href", r.get("url", "")),
                    snippet=r.get("body", r.get("snippet", "")),
                    rank=i + 1,
                ))
        except Exception as e:
            print(f"Search error for '{query}': {e}")

        return results

    async def scrape_url(self, url: str, max_length: Optional[int] = None) -> ScrapedContent:
        """Scrape a single URL with rate limiting."""
        max_length = max_length or self.config.MAX_SCRAPE_LENGTH

        await self._respect_crawl_delay(url)

        try:
            content = self.scraper.scrape(url)
            success = not content.startswith("Error") and not content.startswith("Access") and not content.startswith("Timeout")

            if content and len(content) > max_length:
                content = content[:max_length]

            return ScrapedContent(
                url=url,
                title="",
                content=content or "",
                content_length=len(content) if content else 0,
                success=success,
                error=None if success else content,
            )
        except Exception as e:
            return ScrapedContent(
                url=url,
                title="",
                content="",
                content_length=0,
                success=False,
                error=str(e),
            )

    async def _respect_crawl_delay(self, url: str) -> None:
        """Enforce per-domain crawl delay."""
        import time
        from urllib.parse import urlparse

        domain = urlparse(url).netloc
        now = time.time()
        last = self._last_fetch.get(domain, 0)
        elapsed = now - last

        if elapsed < self.config.CRAWL_DELAY:
            await asyncio.sleep(self.config.CRAWL_DELAY - elapsed)

        self._last_fetch[domain] = time.time()

    async def scrape_multiple(self, urls: List[str], max_length: Optional[int] = None) -> List[ScrapedContent]:
        """Scrape multiple URLs with crawl delay between each."""
        results = []
        for url in urls:
            result = await self.scrape_url(url, max_length)
            results.append(result)
        return results