"""
Maya 2.0 ULTRA - Income Engine
================================
24/7 autonomous income-generation system with multi-agent loop:

1. SCOUT AGENT - Continuous opportunity scanning (this module)
2. STRATEGIST AGENT - Daily ranking & plan drafting
3. BUILDER AGENT - Autonomous MVP building
4. LAUNCH AGENT - Launch preparation & approval
5. GROWTH AGENT - Daily monitoring & improvements
6. PORTFOLIO MANAGER - Weekly portfolio review

This module: SCOUT AGENT - Pure research, fully autonomous
"""
import asyncio
import json
import os
import re
import sqlite3
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set
from urllib.parse import urljoin, urlparse

import httpx
from maya_logging.logger import get_logger

log = get_logger("income_engine")

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

INCOME_DB_DIR = Path("/home/ubuntu/M-2.0/storage/income_engine")
INCOME_DB_DIR.mkdir(parents=True, exist_ok=True)
INCOME_DB = str(INCOME_DB_DIR / "income_engine.db")

SCOUT_SCAN_INTERVAL_HOURS = int(os.environ.get("SCOUT_SCAN_INTERVAL_HOURS", "4"))
SCOUT_MAX_RESULTS_PER_SOURCE = int(os.environ.get("SCOUT_MAX_RESULTS_PER_SOURCE", "50"))

# Source configurations
SCOUT_SOURCES = {
    "reddit": {
        "enabled": True,
        "subreddits": [
            "saas", "entrepreneur", "startups", "sideproject", "indiehackers",
            "microsaas", "bootstrapped", "saasmetrics", "nocode", "webdev"
        ],
        "keywords": [
            "pain point", "frustrated", "annoying", "wish there was", "need a tool",
            "looking for", "recommend", "alternative to", "expensive", "overpriced",
            "manual process", "tedious", "time consuming", "waste of time",
            "feature request", "missing feature", "bug", "broken", "doesn't work"
        ]
    },
    "hackernews": {
        "enabled": True,
        "types": ["show", "ask", "new"],
        "keywords": ["launch", "built", "made", "created", "looking for", "need", "pain"]
    },
    "indiehackers": {
        "enabled": True,
        "categories": ["products", "ideas", "validation", "marketing", "growth"],
        "keywords": ["problem", "pain", "struggle", "frustrated", "need", "want", "wish"]
    },
    "google_trends": {
        "enabled": False,  # Requires API setup
        "categories": ["software", "saas", "tool", "app", "platform"]
    },
    "app_store": {
        "enabled": True,
        "categories": ["productivity", "business", "utilities", "developer_tools"],
        "keywords": ["missing", "bug", "crash", "slow", "expensive", "subscription"]
    },
    "g2_capterra": {
        "enabled": False,  # Requires scraping setup
        "categories": ["saas", "software", "tool"]
    }
}

# Owner preference learning
OWNER_PREF_DB = str(INCOME_DB_DIR / "owner_preferences.db")

# ════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ════════════════════════════════════════════════════════════════════════════

class OpportunityStatus(Enum):
    NEW = "new"
    ANALYZING = "analyzing"
    SCORED = "scored"
    REJECTED = "rejected"
    QUEUED_FOR_STRATEGIST = "queued_for_strategist"
    APPROVED = "approved"
    BUILDING = "building"
    LAUNCHED = "launched"


class SignalType(Enum):
    COMPLAINT = "complaint"
    FEATURE_REQUEST = "feature_request"
    PRICING_COMPLAINT = "pricing_complaint"
    MISSING_FEATURE = "missing_feature"
    BUG_REPORT = "bug_report"
    WORKAROUND_SHARED = "workaround_shared"
    ALTERNATIVE_SEEKING = "alternative_seeking"
    PAIN_POINT = "pain_point"


@dataclass
class RawSignal:
    """Raw signal from a source before analysis."""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    source: str = ""  # reddit, hn, indiehackers, etc.
    source_id: str = ""  # Original post/comment ID
    url: str = ""
    title: str = ""
    content: str = ""
    author: str = ""
    timestamp: float = field(default_factory=time.time)
    metadata: Dict = field(default_factory=dict)  # upvotes, comments, subreddit, etc.
    raw_signal_type: Optional[SignalType] = None
    keywords_matched: List[str] = field(default_factory=list)


@dataclass
class Opportunity:
    """Analyzed and scored business opportunity."""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    title: str = ""
    description: str = ""
    problem_statement: str = ""
    target_user: str = ""
    proposed_solution: str = ""
    
    # Scoring (0-100)
    market_signal_score: float = 0.0      # How strong is the demand signal
    build_complexity_score: float = 0.0   # How hard to build (lower = easier)
    competition_score: float = 0.0        # Competition level (lower = less competition)
    monetization_score: float = 0.0       # Clarity of monetization path
    total_score: float = 0.0              # Weighted composite
    
    # Metadata
    status: OpportunityStatus = OpportunityStatus.NEW
    source_signals: List[str] = field(default_factory=list)  # RawSignal IDs
    source_category: str = ""              # saas, tool, platform, etc.
    target_market: str = ""                # b2b, b2c, developers, etc.
    estimated_market_size: str = ""        # rough estimate
    monetization_model: str = ""           # subscription, usage, freemium, etc.
    
    # Tracking
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    analyzed_at: Optional[float] = None
    rejected_reason: str = ""
    
    # Owner preference
    owner_rejected: bool = False
    owner_feedback: str = ""


@dataclass
class OwnerPreference:
    """Learned owner preferences from past decisions."""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    category: str = ""           # e.g., "crypto", "ai", "b2b_saas", "consumer"
    preference: str = "neutral"  # "prefer", "avoid", "neutral"
    confidence: float = 0.5      # 0-1
    evidence_count: int = 0
    last_updated: float = field(default_factory=time.time)
    notes: str = ""


# ════════════════════════════════════════════════════════════════════════════
# DATABASE
# ════════════════════════════════════════════════════════════════════════════

def init_income_db():
    """Initialize the income engine database."""
    with sqlite3.connect(INCOME_DB) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS raw_signals (
                id TEXT PRIMARY KEY,
                source TEXT NOT NULL,
                source_id TEXT NOT NULL,
                url TEXT,
                title TEXT,
                content TEXT,
                author TEXT,
                timestamp REAL,
                metadata TEXT DEFAULT '{}',
                signal_type TEXT,
                keywords_matched TEXT DEFAULT '[]',
                UNIQUE(source, source_id)
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_signals_source ON raw_signals(source)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_signals_time ON raw_signals(timestamp)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_signals_type ON raw_signals(signal_type)")
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS opportunities (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                problem_statement TEXT,
                target_user TEXT,
                proposed_solution TEXT,
                market_signal_score REAL DEFAULT 0,
                build_complexity_score REAL DEFAULT 0,
                competition_score REAL DEFAULT 0,
                monetization_score REAL DEFAULT 0,
                total_score REAL DEFAULT 0,
                status TEXT DEFAULT 'new',
                source_signals TEXT DEFAULT '[]',
                source_category TEXT,
                target_market TEXT,
                estimated_market_size TEXT,
                monetization_model TEXT,
                created_at REAL,
                updated_at REAL,
                analyzed_at REAL,
                rejected_reason TEXT DEFAULT '',
                owner_rejected INTEGER DEFAULT 0,
                owner_feedback TEXT DEFAULT ''
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_opp_status ON opportunities(status)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_opp_score ON opportunities(total_score)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_opp_category ON opportunities(source_category)")
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS scout_runs (
                id TEXT PRIMARY KEY,
                started_at REAL,
                completed_at REAL,
                sources_scanned INTEGER,
                signals_found INTEGER,
                opportunities_created INTEGER,
                errors TEXT DEFAULT '[]'
            )
        """)


def init_owner_pref_db():
    """Initialize owner preferences database."""
    with sqlite3.connect(OWNER_PREF_DB) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS owner_preferences (
                id TEXT PRIMARY KEY,
                category TEXT NOT NULL UNIQUE,
                preference TEXT DEFAULT 'neutral',
                confidence REAL DEFAULT 0.5,
                evidence_count INTEGER DEFAULT 0,
                last_updated REAL,
                notes TEXT DEFAULT ''
            )
        """)


@contextmanager
def get_income_conn():
    conn = sqlite3.connect(INCOME_DB)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


@contextmanager
def get_pref_conn():
    conn = sqlite3.connect(OWNER_PREF_DB)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════════════════
# SCOUT AGENT
# ═════════════════════════════════════════════════════════════════════════════

class ScoutAgent:
    """
    Autonomous opportunity scout.
    Scans multiple sources continuously for pain points and opportunities.
    """
    
    def __init__(self, llm_fn: Optional[Callable] = None):
        self.llm_fn = llm_fn
        self._running = False
        self._task: Optional[asyncio.Task] = None
        
        # Initialize databases
        init_income_db()
        init_owner_pref_db()
        
        # HTTP client for web requests
        self.http_client = httpx.AsyncClient(
            timeout=30.0,
            headers={"User-Agent": "Mozilla/5.0 (Maya Income Scout)"}
        )
        
        log.info("ScoutAgent initialized")
    
    async def start(self):
        """Start the continuous scanning loop."""
        if self._running:
            return
        self._running = True
        self._task = asyncio.create_task(self._scan_loop())
        log.info("ScoutAgent started")
    
    async def stop(self):
        """Stop the scanning loop."""
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        await self.http_client.aclose()
        log.info("ScoutAgent stopped")
    
    async def _scan_loop(self):
        """Main scanning loop - runs every SCOUT_SCAN_INTERVAL_HOURS."""
        while self._running:
            try:
                await self.run_scan_cycle()
            except Exception as e:
                log.error(f"Scout scan cycle error: {e}")
            
            # Sleep until next cycle
            try:
                await asyncio.sleep(SCOUT_SCAN_INTERVAL_HOURS * 3600)
            except asyncio.CancelledError:
                break
    
    async def run_scan_cycle(self) -> Dict:
        """Run one complete scan cycle across all enabled sources."""
        run_id = uuid.uuid4().hex[:12]
        started_at = time.time()
        
        log.info(f"Starting scout scan cycle {run_id}")
        
        total_signals = 0
        total_opportunities = 0
        errors = []
        sources_scanned = 0
        
        # Scan each enabled source
        for source_name, config in SCOUT_SOURCES.items():
            if not config.get("enabled", False):
                continue
            
            try:
                if source_name == "reddit":
                    signals = await self._scan_reddit(config)
                elif source_name == "hackernews":
                    signals = await self._scan_hackernews(config)
                elif source_name == "indiehackers":
                    signals = await self._scan_indiehackers(config)
                elif source_name == "app_store":
                    signals = await self._scan_app_store(config)
                else:
                    signals = []
                
                # Process signals
                for signal in signals:
                    await self._store_signal(signal)
                    total_signals += 1
                
                # Analyze signals into opportunities
                new_opps = await self._analyze_signals(signals)
                total_opportunities += len(new_opps)
                sources_scanned += 1
                
            except Exception as e:
                error_msg = f"{source_name}: {str(e)}"
                errors.append(error_msg)
                log.error(f"Scout error scanning {source_name}: {e}")
        
        completed_at = time.time()
        
        # Record run
        with get_income_conn() as conn:
            conn.execute("""
                INSERT INTO scout_runs (id, started_at, completed_at, sources_scanned, 
                    signals_found, opportunities_created, errors)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (run_id, started_at, completed_at, sources_scanned, total_signals, 
                  total_opportunities, json.dumps(errors)))
        
        result = {
            "run_id": run_id,
            "duration_seconds": completed_at - started_at,
            "sources_scanned": sources_scanned,
            "signals_found": total_signals,
            "opportunities_created": total_opportunities,
            "errors": errors
        }
        
        log.info(f"Scout scan {run_id} complete: {total_signals} signals, {total_opportunities} opportunities")
        return result
    
    # ════════════════════════════════════════════════════════════════════════════
    # SOURCE SCANNERS
    # ════════════════════════════════════════════════════════════════════════════
    
    async def _scan_reddit(self, config: Dict) -> List[RawSignal]:
        """Scan Reddit for pain points and opportunities."""
        signals = []
        
        for subreddit in config.get("subreddits", []):
            try:
                # Use Reddit's public JSON API (no auth needed for public posts)
                url = f"https://www.reddit.com/r/{subreddit}/hot.json?limit=100"
                resp = await self.http_client.get(url)
                
                if resp.status_code != 200:
                    continue
                
                data = resp.json()
                posts = data.get("data", {}).get("children", [])
                
                for post in posts:
                    p = post.get("data", {})
                    
                    # Skip non-text posts, stickied, etc.
                    if p.get("is_self") is False and not p.get("url", "").endswith((".png", ".jpg", ".gif", ".mp4")):
                        continue
                    
                    title = p.get("title", "")
                    content = p.get("selftext", "")
                    full_text = f"{title} {content}".lower()
                    
                    # Check for keywords
                    matched_keywords = [kw for kw in config.get("keywords", []) if kw.lower() in full_text]
                    if not matched_keywords:
                        continue
                    
                    # Determine signal type
                    signal_type = self._classify_signal(full_text)
                    
                    signal = RawSignal(
                        source="reddit",
                        source_id=p.get("id", ""),
                        url=f"https://reddit.com{p.get('permalink', '')}",
                        title=title,
                        content=content[:2000],  # Truncate
                        author=p.get("author", ""),
                        timestamp=p.get("created_utc", time.time()),
                        metadata={
                            "subreddit": subreddit,
                            "score": p.get("score", 0),
                            "num_comments": p.get("num_comments", 0),
                            "upvote_ratio": p.get("upvote_ratio", 0)
                        },
                        raw_signal_type=signal_type,
                        keywords_matched=matched_keywords
                    )
                    signals.append(signal)
                    
            except Exception as e:
                log.warning(f"Error scanning r/{subreddit}: {e}")
        
        return signals
    
    async def _scan_hackernews(self, config: Dict) -> List[RawSignal]:
        """Scan HackerNews Show HN, Ask HN, and new posts."""
        signals = []
        
        try:
            # Get top stories
            resp = await self.http_client.get("https://hacker-news.firebaseio.com/v0/topstories.json")
            story_ids = resp.json()[:200]
            
            for story_id in story_ids[:50]:  # Limit to avoid rate limits
                try:
                    item_resp = await self.http_client.get(f"https://hacker-news.firebaseio.com/v0/item/{story_id}.json")
                    item = item_resp.json()
                    
                    if not item or item.get("type") != "story":
                        continue
                    
                    title = item.get("title", "")
                    text = item.get("text", "")
                    full_text = f"{title} {text}".lower()
                    
                    matched_keywords = [kw for kw in config.get("keywords", []) if kw.lower() in full_text]
                    if not matched_keywords:
                        continue
                    
                    signal_type = self._classify_signal(full_text)
                    
                    signal = RawSignal(
                        source="hackernews",
                        source_id=str(item.get("id", "")),
                        url=item.get("url", f"https://news.ycombinator.com/item?id={item.get('id')}"),
                        title=title,
                        content=text[:2000],
                        author=item.get("by", ""),
                        timestamp=item.get("time", time.time()),
                        metadata={
                            "score": item.get("score", 0),
                            "descendants": item.get("descendants", 0),
                            "type": item.get("type")
                        },
                        raw_signal_type=signal_type,
                        keywords_matched=matched_keywords
                    )
                    signals.append(signal)
                    
                except Exception:
                    continue
                    
        except Exception as e:
            log.warning(f"Error scanning HackerNews: {e}")
        
        return signals
    
    async def _scan_indiehackers(self, config: Dict) -> List[RawSignal]:
        """Scan IndieHackers for pain points and product discussions."""
        signals = []
        
        try:
            # IndieHackers has a public API
            for category in config.get("categories", []):
                url = f"https://api.indiehackers.com/posts?category={category}&limit=50"
                resp = await self.http_client.get(url)
                
                if resp.status_code != 200:
                    continue
                
                data = resp.json()
                posts = data.get("posts", [])
                
                for post in posts:
                    title = post.get("title", "")
                    content = post.get("content", "")
                    full_text = f"{title} {content}".lower()
                    
                    matched_keywords = [kw for kw in config.get("keywords", []) if kw.lower() in full_text]
                    if not matched_keywords:
                        continue
                    
                    signal_type = self._classify_signal(full_text)
                    
                    signal = RawSignal(
                        source="indiehackers",
                        source_id=str(post.get("id", "")),
                        url=post.get("url", ""),
                        title=title,
                        content=content[:2000],
                        author=post.get("username", ""),
                        timestamp=post.get("created_at", time.time()),
                        metadata={
                            "category": category,
                            "upvotes": post.get("upvotes", 0),
                            "comments": post.get("comments_count", 0)
                        },
                        raw_signal_type=signal_type,
                        keywords_matched=matched_keywords
                    )
                    signals.append(signal)
                    
        except Exception as e:
            log.warning(f"Error scanning IndieHackers: {e}")
        
        return signals
    
    async def _scan_app_store(self, config: Dict) -> List[RawSignal]:
        """Scan app store reviews for pain points."""
        # This would use iTunes/App Store APIs
        # For now, placeholder - requires API setup
        return []
    
    def _classify_signal(self, text: str) -> SignalType:
        """Classify the type of signal from text content."""
        text_lower = text.lower()
        
        if any(w in text_lower for w in ["bug", "broken", "crash", "error", "doesn't work", "not working"]):
            return SignalType.BUG_REPORT
        elif any(w in text_lower for w in ["price", "expensive", "overpriced", "cost", "subscription", "pricing"]):
            return SignalType.PRICING_COMPLAINT
        elif any(w in text_lower for w in ["feature request", "wish", "need", "missing", "add", "support for"]):
            return SignalType.FEATURE_REQUEST
        elif any(w in text_lower for w in ["workaround", "hack", "manual", "tedious", "time consuming"]):
            return SignalType.WORKAROUND_SHARED
        elif any(w in text_lower for w in ["alternative", "recommend", "better than", "switch from"]):
            return SignalType.ALTERNATIVE_SEEKING
        elif any(w in text_lower for w in ["frustrated", "annoying", "pain", "hate", "sucks", "terrible"]):
            return SignalType.PAIN_POINT
        elif any(w in text_lower for w in ["complain", "issue", "problem", "wrong"]):
            return SignalType.COMPLAINT
        else:
            return SignalType.PAIN_POINT
    
    # ════════════════════════════════════════════════════════════════════════════
    # SIGNAL PROCESSING
    # ════════════════════════════════════════════════════════════════════════════
    
    async def _store_signal(self, signal: RawSignal):
        """Store a raw signal in the database."""
        with get_income_conn() as conn:
            conn.execute("""
                INSERT OR IGNORE INTO raw_signals 
                (id, source, source_id, url, title, content, author, timestamp, 
                 metadata, signal_type, keywords_matched)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (signal.id, signal.source, signal.source_id, signal.url,
                  signal.title, signal.content, signal.author, signal.timestamp,
                  json.dumps(signal.metadata), 
                  signal.raw_signal_type.value if signal.raw_signal_type else None,
                  json.dumps(signal.keywords_matched)))
    
    async def _analyze_signals(self, signals: List[RawSignal]) -> List[Opportunity]:
        """Analyze raw signals and extract scored opportunities."""
        if not signals or not self.llm_fn:
            return []
        
        # Group signals by theme/topic
        signal_groups = self._group_signals(signals)
        
        opportunities = []
        for group in signal_groups:
            if len(group) < 2:  # Need at least 2 signals for a pattern
                continue
            
            opportunity = await self._create_opportunity_from_group(group)
            if opportunity:
                opportunities.append(opportunity)
        
        return opportunities
    
    def _group_signals(self, signals: List[RawSignal]) -> List[List[RawSignal]]:
        """Group signals by similarity (simple keyword overlap)."""
        groups = []
        used = set()
        
        for signal in signals:
            if signal.id in used:
                continue
            
            group = [signal]
            used.add(signal.id)
            
            signal_keywords = set(signal.keywords_matched)
            signal_words = set(re.findall(r'\b\w+\b', signal.content.lower()))
            
            for other in signals:
                if other.id in used:
                    continue
                
                # Check keyword overlap
                other_keywords = set(other.keywords_matched)
                overlap = len(signal_keywords & other_keywords)
                
                # Check word overlap in content
                other_words = set(re.findall(r'\b\w+\b', other.content.lower()))
                word_overlap = len(signal_words & other_words) / max(len(signal_words), 1)
                
                if overlap >= 1 or word_overlap > 0.3:
                    group.append(other)
                    used.add(other.id)
            
            if len(group) >= 2:
                groups.append(group)
        
        return groups
    
    async def _create_opportunity_from_group(self, signals: List[RawSignal]) -> Optional[Opportunity]:
        """Use LLM to create a scored opportunity from a signal group."""
        if not self.llm_fn or len(signals) < 2:
            return None
        
        # Prepare context for LLM
        context = "\n\n".join([
            f"Source: {s.source}\nTitle: {s.title}\nContent: {s.content[:500]}\n"
            f"Signal Type: {s.raw_signal_type.value if s.raw_signal_type else 'unknown'}\n"
            f"Keywords: {', '.join(s.keywords_matched)}\n"
            f"Metadata: {json.dumps(s.metadata)}"
            for s in signals[:5]  # Limit to 5 signals
        ])
        
        # Get owner preferences to avoid rejected categories
        prefs = self._get_owner_preferences()
        pref_context = ""
        avoid_categories = [cat for cat, pref in prefs.items() if pref["preference"] == "avoid" and pref["confidence"] > 0.6]
        if avoid_categories:
            pref_context = f"\nIMPORTANT: Owner has previously rejected these categories: {', '.join(avoid_categories)}. Deprioritize or reject similar opportunities."
        
        prompt = f"""You are Maya's Income Scout. Analyze these user signals and identify a viable business opportunity.

SIGNALS (from Reddit, HN, IndieHackers, etc.):
{context}
{pref_context}

TASK: If these signals indicate a REAL, BUILDABLE business opportunity, create an opportunity profile.
If this is just noise, vague complaints, or already saturated market, return "REJECT".

For a valid opportunity, return ONLY a JSON object:
{{
  "title": "Brief title (max 80 chars)",
  "description": "2-3 sentence summary of the opportunity",
  "problem_statement": "Clear problem statement",
  "target_user": "Who has this problem (specific persona)",
  "proposed_solution": "What to build (high-level)",
  "source_category": "saas|tool|platform|plugin|extension|api|marketplace|other",
  "target_market": "b2b|b2c|developers|designers|marketers|other",
  "estimated_market_size": "small|medium|large|unknown",
  "monetization_model": "subscription|usage|freemium|one-time|marketplace|ads|other",
  "market_signal_score": 0-100,
  "build_complexity_score": 0-100,
  "competition_score": 0-100,
  "monetization_score": 0-100,
  "rejected_reason": ""
}}

SCORING GUIDE:
- market_signal_score: How many people complain? How urgent? (high = many people, urgent pain)
- build_complexity_score: How hard to build MVP? (low = simple, high = complex AI/integrations)
- competition_score: How crowded? (low = few competitors, high = saturated)
- monetization_score: Clear path to revenue? (high = obvious, low = unclear)

Total score = market_signal*0.35 + (100-build_complexity)*0.25 + (100-competition)*0.2 + monetization*0.2

Return "REJECT" if: already saturated, too vague, not a real problem, owner would reject, or total_score < 40.
"""
        
        try:
            response = self.llm_fn(prompt)
            
            if "REJECT" in response.upper():
                return None
            
            # Extract JSON
            json_start = response.find("{")
            json_end = response.rfind("}") + 1
            if json_start == -1 or json_end == 0:
                return None
            
            data = json.loads(response[json_start:json_end])
            
            # Calculate total score
            weights = {"market_signal": 0.35, "build_complexity": 0.25, "competition": 0.2, "monetization": 0.2}
            total = (
                data.get("market_signal_score", 0) * weights["market_signal"] +
                (100 - data.get("build_complexity_score", 50)) * weights["build_complexity"] +
                (100 - data.get("competition_score", 50)) * weights["competition"] +
                data.get("monetization_score", 0) * weights["monetization"]
            )
            
            if total < 40:
                return None
            
            # Check owner preferences
            category = data.get("source_category", "").lower()
            prefs = self._get_owner_preferences()
            for cat, pref in prefs.items():
                if cat.lower() in category and pref["preference"] == "avoid" and pref["confidence"] > 0.6:
                    return None
            
            opportunity = Opportunity(
                title=data.get("title", "")[:200],
                description=data.get("description", "")[:500],
                problem_statement=data.get("problem_statement", "")[:500],
                target_user=data.get("target_user", "")[:200],
                proposed_solution=data.get("proposed_solution", "")[:500],
                market_signal_score=data.get("market_signal_score", 0),
                build_complexity_score=data.get("build_complexity_score", 0),
                competition_score=data.get("competition_score", 0),
                monetization_score=data.get("monetization_score", 0),
                total_score=round(total, 2),
                source_category=data.get("source_category", "other"),
                target_market=data.get("target_market", "unknown"),
                estimated_market_size=data.get("estimated_market_size", "unknown"),
                monetization_model=data.get("monetization_model", "subscription"),
                status=OpportunityStatus.SCORED,
                source_signals=[s.id for s in signals],
                analyzed_at=time.time()
            )
            
            # Store opportunity
            await self._store_opportunity(opportunity)
            
            log.info(f"Created opportunity: {opportunity.title} (score: {opportunity.total_score})")
            return opportunity
            
        except Exception as e:
            log.warning(f"Failed to create opportunity: {e}")
            return None
    
    async def _store_opportunity(self, opp: Opportunity):
        """Store an opportunity in the database."""
        with get_income_conn() as conn:
            conn.execute("""
                INSERT OR REPLACE INTO opportunities 
                (id, title, description, problem_statement, target_user, proposed_solution,
                 market_signal_score, build_complexity_score, competition_score, monetization_score,
                 total_score, status, source_signals, source_category, target_market,
                 estimated_market_size, monetization_model, created_at, updated_at, analyzed_at,
                 rejected_reason, owner_rejected, owner_feedback)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (opp.id, opp.title, opp.description, opp.problem_statement, opp.target_user,
                  opp.proposed_solution, opp.market_signal_score, opp.build_complexity_score,
                  opp.competition_score, opp.monetization_score, opp.total_score,
                  opp.status.value, json.dumps(opp.source_signals), opp.source_category,
                  opp.target_market, opp.estimated_market_size, opp.monetization_model,
                  opp.created_at, opp.updated_at, opp.analyzed_at, opp.rejected_reason,
                  int(opp.owner_rejected), opp.owner_feedback))
    
    def _get_owner_preferences(self) -> Dict:
        """Load owner preferences from database."""
        prefs = {}
        with get_pref_conn() as conn:
            rows = conn.execute("SELECT * FROM owner_preferences").fetchall()
            for row in rows:
                prefs[row["category"]] = {
                    "preference": row["preference"],
                    "confidence": row["confidence"],
                    "evidence_count": row["evidence_count"]
                }
        return prefs
    
    # ═════════════════════════════════════════════════════════════════════════════
    # OWNER PREFERENCE LEARNING
    # ════════════════════════════════════════════════════════════════════════════
    
    def record_owner_decision(self, opportunity_id: str, approved: bool, feedback: str = ""):
        """Record owner's decision on an opportunity to learn preferences."""
        with get_income_conn() as conn:
            # Get opportunity category
            row = conn.execute("SELECT source_category FROM opportunities WHERE id = ?", 
                              (opportunity_id,)).fetchone()
            if not row:
                return
            category = row["source_category"]
        
        with get_pref_conn() as conn:
            # Get existing preference
            row = conn.execute("SELECT * FROM owner_preferences WHERE category = ?", 
                              (category,)).fetchone()
            
            if row:
                # Update existing
                evidence = row["evidence_count"] + 1
                if approved:
                    # Shift toward "prefer"
                    new_pref = "prefer" if evidence >= 2 else "neutral"
                else:
                    # Shift toward "avoid"
                    new_pref = "avoid" if evidence >= 2 else "neutral"
                
                confidence = min(0.9, 0.5 + evidence * 0.1)
                
                conn.execute("""
                    UPDATE owner_preferences 
                    SET preference = ?, confidence = ?, evidence_count = ?, last_updated = ?, notes = ?
                    WHERE category = ?
                """, (new_pref, confidence, evidence, time.time(), 
                      f"Owner {'approved' if approved else 'rejected'} opportunity", category))
            else:
                # Create new preference
                new_pref = "prefer" if approved else "avoid"
                confidence = 0.6
                
                conn.execute("""
                    INSERT INTO owner_preferences (id, category, preference, confidence, evidence_count, last_updated, notes)
                    VALUES (?, ?, ?, ?, 1, ?, ?)
                """, (uuid.uuid4().hex[:12], category, new_pref, confidence, time.time(),
                      f"Owner {'approved' if approved else 'rejected'} opportunity"))


# ════════════════════════════════════════════════════════════════════════════
# MODULE SINGLETON
# ════════════════════════════════════════════════════════════════════════════

_scout_agent: Optional[ScoutAgent] = None


def get_scout_agent(llm_fn: Optional[Callable] = None) -> ScoutAgent:
    global _scout_agent
    if _scout_agent is None:
        _scout_agent = ScoutAgent(llm_fn)
    return _scout_agent


def reset_scout_agent():
    global _scout_agent
    if _scout_agent:
        asyncio.create_task(_scout_agent.stop())
    _scout_agent = None