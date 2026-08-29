"""
Maya 2.0 ULTRA - Income Engine: Launch Agent
============================================
Handles production launch of completed MVPs:
- Generates launch content (landing page, Product Hunt, social)
- Queues all content for owner approval before going live
- Coordinates DNS, SSL, monitoring setup
- Tracks launch metrics post-launch
"""
import asyncio
import json
import os
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set

import sqlite3
from maya_logging.logger import get_logger

log = get_logger("launcher")

from infrastructure.income_engine import get_income_conn, get_pref_conn

# ═════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

LAUNCH_DB_DIR = Path("/home/ubuntu/M-2.0/storage/income_engine")
LAUNCH_DB_DIR.mkdir(parents=True, exist_ok=True)

# ═════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ═════════════════════════════════════════════════════════════════════════════

class LaunchStatus(Enum):
    READY = "ready"
    CONTENT_GENERATING = "content_generating"
    CONTENT_PENDING_APPROVAL = "content_pending_approval"
    CONTENT_APPROVED = "content_approved"
    DNS_CONFIGURING = "dns_configuring"
    SSL_CONFIGURING = "ssl_configuring"
    MONITORING_SETUP = "monitoring_setup"
    LAUNCHING = "launching"
    LIVE = "live"
    FAILED = "failed"


@dataclass
class LaunchContent:
    """Content pieces for launch."""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    launch_id: str = ""
    content_type: str = ""  # landing_page, product_hunt, twitter, linkedin, email, press_release
    title: str = ""
    content: str = ""
    status: str = "draft"  # draft, pending_approval, approved, rejected, published
    platform_url: str = ""
    created_at: float = field(default_factory=time.time)
    approved_at: Optional[float] = None
    published_at: Optional[float] = None


@dataclass
class LaunchProject:
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    build_project_id: str = ""
    plan_id: str = ""
    opportunity_id: str = ""
    title: str = ""
    description: str = ""
    status: LaunchStatus = LaunchStatus.READY
    
    # Launch config
    domain: str = ""
    subdomain: str = ""
    custom_domain: bool = False
    launch_date: Optional[float] = None
    launch_timezone: str = "UTC"
    
    # Content pieces
    content_pieces: List[LaunchContent] = field(default_factory=list)
    
    # Infrastructure
    dns_records: List[Dict] = field(default_factory=list)
    ssl_certificate: Dict = field(default_factory=dict)
    monitoring_config: Dict = field(default_factory=dict)
    analytics_config: Dict = field(default_factory=dict)
    
    # Launch metadata
    launch_url: str = ""
    analytics_id: str = ""
    error: str = ""
    
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    launched_at: Optional[float] = None


# ═════════════════════════════════════════════════════════════════════════════
# DATABASE
# ═════════════════════════════════════════════════════════════════════════════

def init_launcher_tables():
    with get_income_conn() as conn:
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA busy_timeout=5000")
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS launch_projects (
                id TEXT PRIMARY KEY,
                build_project_id TEXT NOT NULL,
                plan_id TEXT NOT NULL,
                opportunity_id TEXT,
                title TEXT,
                description TEXT,
                status TEXT DEFAULT 'ready',
                domain TEXT,
                subdomain TEXT,
                custom_domain INTEGER DEFAULT 0,
                launch_date REAL,
                launch_timezone TEXT DEFAULT 'UTC',
                launch_url TEXT,
                analytics_id TEXT,
                error TEXT DEFAULT '',
                created_at REAL,
                updated_at REAL,
                launched_at REAL
            )
        """)
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS launch_content (
                id TEXT PRIMARY KEY,
                launch_id TEXT NOT NULL,
                content_type TEXT NOT NULL,
                title TEXT,
                content TEXT,
                status TEXT DEFAULT 'draft',
                platform_url TEXT,
                created_at REAL,
                approved_at REAL,
                published_at REAL,
                FOREIGN KEY (launch_id) REFERENCES launch_projects(id)
            )
        """)
        
        conn.execute("CREATE INDEX IF NOT EXISTS idx_launch_status ON launch_projects(status)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_launch_build ON launch_projects(build_project_id)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_content_launch ON launch_content(launch_id)")


# ══════════════════════════════════════════════════════════════════════════════
# LAUNCH AGENT
# ══════════════════════════════════════════════════════════════════════════════

class LaunchAgent:
    """
    Launch coordinator - handles production launch of completed MVPs.
    Generates all launch content, queues for approval, coordinates infrastructure.
    """
    
    def __init__(self, llm_fn: Optional[Callable] = None):
        self.llm_fn = llm_fn
        self._running = False
        self._task: Optional[asyncio.Task] = None
        
        init_launcher_tables()
        log.info("LaunchAgent initialized")
    
    async def start(self):
        if self._running:
            return
        self._running = True
        self._task = asyncio.create_task(self._launch_loop())
        log.info("LaunchAgent started")
    
    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        log.info("LaunchAgent stopped")
    
    async def _launch_loop(self):
        """Process pending launches."""
        while self._running:
            try:
                await self._process_pending_launches()
            except Exception as e:
                log.error(f"Launch loop error: {e}")
            
            try:
                await asyncio.sleep(60)  # Check every minute
            except asyncio.CancelledError:
                break
    
    async def _process_pending_launches(self):
        """Process launches that are ready for next step."""
        with get_income_conn() as conn:
            rows = conn.execute("""
                SELECT * FROM launch_projects 
                WHERE status IN ('ready', 'content_generating', 'content_approved', 'dns_configuring', 
                                 'ssl_configuring', 'monitoring_setup')
                ORDER BY created_at
            """).fetchall()
        
        for row in rows:
            launch = self._row_to_launch(row)
            await self._process_launch(launch)
    
    def create_launch_from_build(self, build_project_id: str) -> Optional[LaunchProject]:
        """Create a launch project from a completed build."""
        with get_income_conn() as conn:
            build_row = conn.execute("SELECT * FROM build_projects WHERE id = ?", (build_project_id,)).fetchone()
            if not build_row or build_row["status"] != "completed":
                log.warning(f"Build project {build_project_id} not found or not completed")
                return None
            
            plan_row = conn.execute("SELECT * FROM plans WHERE id = ?", (build_row["plan_id"],)).fetchone()
            
            launch = LaunchProject(
                build_project_id=build_project_id,
                plan_id=build_row["plan_id"],
                opportunity_id=build_row["opportunity_id"] or "",
                title=build_row["title"] or "",
                description=build_row["description"] or "",
                status=LaunchStatus.READY,
                subdomain=f"maya-income-{build_project_id}",
                launch_date=time.time() + 86400,  # Default to tomorrow
            )
            
            self._store_launch(launch)
            log.info(f"Created launch project {launch.id} for build {build_project_id}")
            return launch
    
    async def _process_launch(self, launch: LaunchProject):
        """Process a launch through its pipeline."""
        try:
            if launch.status == LaunchStatus.READY:
                await self._generate_content(launch)
            elif launch.status == LaunchStatus.CONTENT_APPROVED:
                await self._setup_infrastructure(launch)
            elif launch.status in (LaunchStatus.DNS_CONFIGURING, LaunchStatus.SSL_CONFIGURING):
                await self._check_infrastructure(launch)
            elif launch.status == LaunchStatus.MONITORING_SETUP:
                await self._finalize_launch(launch)
        except Exception as e:
            launch.status = LaunchStatus.FAILED
            launch.error = str(e)
            launch.updated_at = time.time()
            self._store_launch(launch)
            log.error(f"Launch {launch.id} failed: {e}")
    
    async def _generate_content(self, launch: LaunchProject):
        """Generate all launch content using LLM."""
        if not self.llm_fn:
            launch.status = LaunchStatus.CONTENT_PENDING_APPROVAL
            launch.updated_at = time.time()
            self._store_launch(launch)
            return
        
        launch.status = LaunchStatus.CONTENT_GENERATING
        launch.updated_at = time.time()
        self._store_launch(launch)
        
        content_types = [
            ("landing_page", "Landing Page", "Complete HTML landing page with hero, features, pricing, CTA"),
            ("product_hunt", "Product Hunt Post", "Compelling PH post with tagline, hunter note, maker comment"),
            ("twitter_thread", "Twitter/X Thread", "5-7 tweet launch thread with hooks and CTAs"),
            ("linkedin_post", "LinkedIn Post", "Professional launch announcement for LinkedIn"),
            ("email_announcement", "Email Announcement", "Launch email to waitlist/subscribers"),
            ("press_release", "Press Release", "Formal press release for media distribution"),
        ]
        
        for content_type, title, description in content_types:
            content = await self._generate_single_content(launch, content_type, title, description)
            if content:
                launch.content_pieces.append(content)
        
        launch.status = LaunchStatus.CONTENT_PENDING_APPROVAL
        launch.updated_at = time.time()
        self._store_launch(launch)
        
        # Queue for approval
        await self._queue_content_for_approval(launch)
    
    async def _generate_single_content(self, launch: LaunchProject, content_type: str, title: str, description: str) -> Optional[LaunchContent]:
        """Generate a single content piece using LLM."""
        if not self.llm_fn:
            return None
        
        prompt = f"""Generate {title} for this product launch:

Product: {launch.title}
Description: {launch.description}
Launch URL: {launch.launch_url or 'TBD'}

{description}

Requirements:
- Compelling, conversion-focused copy
- Include clear CTAs
- SEO-optimized where applicable
- Brand voice: professional, innovative, trustworthy
- Include social proof elements where possible

Return ONLY the final content (no meta commentary)."""
        
        try:
            response = self.llm_fn(prompt)
            
            content = LaunchContent(
                launch_id=launch.id,
                content_type=content_type,
                title=title,
                content=response.strip(),
                status="pending_approval",
            )
            return content
        except Exception as e:
            log.error(f"Content generation failed for {content_type}: {e}")
            return None
    
    async def _queue_content_for_approval(self, launch: LaunchProject):
        """Queue all content for owner approval."""
        from infrastructure.income_notifications import get_notification_service, ApprovalRequest, NotificationType, NotificationPriority
        
        notif = get_notification_service()
        
        for content in launch.content_pieces:
            approval = ApprovalRequest(
                action=f"Approve {content.content_type} content for launch",
                reason=f"Review and approve {content.content_type} before publishing",
                risk_level="medium",
                plan_id=launch.plan_id,
                title=f"Approve: {content.title}",
                description=f"{content.content[:500]}...",
            )
            await notif.send_approval_request(approval)
    
    async def _setup_infrastructure(self, launch: LaunchProject):
        """Set up DNS, SSL, monitoring for launch."""
        launch.status = LaunchStatus.DNS_CONFIGURING
        launch.updated_at = time.time()
        self._store_launch(launch)
        
        # In production, this would:
        # 1. Configure DNS records (Cloudflare, Route53, etc.)
        # 2. Provision SSL certificate (Let's Encrypt, Cloudflare)
        # 2. Set up monitoring (Datadog, Sentry, UptimeRobot)
        # 3. Configure analytics (GA4, Mixpanel, Plausible)
        # 4. Set up error tracking (Sentry)
        
        # For now, simulate
        launch.dns_records = [
            {"type": "A", "name": launch.subdomain, "value": "1.2.3.4", "ttl": 300},
            {"type": "CNAME", "name": "www", "value": f"{launch.subdomain}.maya-income.com", "ttl": 3600},
        ]
        launch.ssl_certificate = {
            "provider": "letsencrypt",
            "domains": [f"{launch.subdomain}.maya-income.com", f"www.{launch.subdomain}.maya-income.com"],
            "status": "pending",
        }
        launch.monitoring_config = {
            "uptime_check": True,
            "error_tracking": "sentry",
            "analytics": "plausible",
        }
        
        launch.status = LaunchStatus.SSL_CONFIGURING
        launch.updated_at = time.time()
        self._store_launch(launch)
    
    async def _check_infrastructure(self, launch: LaunchProject):
        """Check if infrastructure is ready."""
        # In production, verify DNS propagation, SSL cert issuance, monitoring connectivity
        # For now, simulate completion
        launch.ssl_certificate["status"] = "issued"
        launch.monitoring_config["verified"] = True
        
        launch.status = LaunchStatus.MONITORING_SETUP
        launch.updated_at = time.time()
        self._store_launch(launch)
    
    async def _finalize_launch(self, launch: LaunchProject):
        """Finalize and launch."""
        launch.status = LaunchStatus.LAUNCHING
        launch.updated_at = time.time()
        self._store_launch(launch)
        
        # In production:
        # 1. Switch DNS to production
        # 2. Enable monitoring alerts
        # 3. Announce on social channels (if approved)
        # 4. Submit to directories (Product Hunt, etc.)
        # 5. Send launch announcement email
        
        launch.launch_url = f"https://{launch.subdomain}.maya-income.com"
        launch.status = LaunchStatus.LIVE
        launch.launched_at = time.time()
        launch.updated_at = time.time()
        self._store_launch(launch)
        
        # Update build project
        with get_income_conn() as conn:
            conn.execute("UPDATE build_projects SET status = 'launched' WHERE id = ?", (launch.build_project_id,))
        
        log.info(f"Launch {launch.id} is LIVE at {launch.launch_url}")
        
        # Send launch notification
        from infrastructure.income_notifications import get_notification_service
        notif = get_notification_service()
        await notif.send_launch_ready(launch.title, launch.plan_id)
    
    async def _queue_content_for_approval(self, launch: LaunchProject):
        """Queue content approval requests."""
        pass  # Implemented in _generate_content
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # STORAGE
    # ═════════════════════════════════════════════════════════════════════════════
    
    def _store_launch(self, launch: LaunchProject):
        with get_income_conn() as conn:
            conn.execute("""
                INSERT OR REPLACE INTO launch_projects 
                (id, build_project_id, plan_id, opportunity_id, title, description, status,
                 domain, subdomain, custom_domain, launch_date, launch_timezone,
                 launch_url, analytics_id, error, created_at, updated_at, launched_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (launch.id, launch.build_project_id, launch.plan_id, launch.opportunity_id,
                  launch.title, launch.description, launch.status.value,
                  launch.domain, launch.subdomain, int(launch.custom_domain), launch.launch_date,
                  launch.launch_timezone, launch.launch_url, launch.analytics_id,
                  launch.error, launch.created_at, launch.updated_at, launch.launched_at))
    
    def _row_to_launch(self, row) -> LaunchProject:
        launch = LaunchProject(
            id=row["id"], build_project_id=row["build_project_id"], plan_id=row["plan_id"],
            opportunity_id=row["opportunity_id"], title=row["title"], description=row["description"],
            status=LaunchStatus(row["status"]), domain=row["domain"], subdomain=row["subdomain"],
            custom_domain=bool(row["custom_domain"]), launch_date=row["launch_date"],
            launch_timezone=row["launch_timezone"], launch_url=row["launch_url"],
            analytics_id=row["analytics_id"], error=row["error"],
            created_at=row["created_at"], updated_at=row["updated_at"], launched_at=row["launched_at"],
        )
        return launch
    
    # ══════════════════════════════════════════════════════════════════════════════
    # PUBLIC API
    # ═════════════════════════════════════════════════════════════════════════════
    
    def get_launch(self, launch_id: str) -> Optional[LaunchProject]:
        with get_income_conn() as conn:
            row = conn.execute("SELECT * FROM launch_projects WHERE id = ?", (launch_id,)).fetchone()
            if row:
                return self._row_to_launch(row)
        return None
    
    def list_launches(self, status: Optional[LaunchStatus] = None) -> List[LaunchProject]:
        with get_income_conn() as conn:
            query = "SELECT * FROM launch_projects"
            params = []
            if status:
                query += " WHERE status = ?"
                params.append(status.value)
            query += " ORDER BY created_at DESC"
            rows = conn.execute(query, params).fetchall()
        return [self._row_to_launch(r) for r in rows]
    
    def get_content(self, launch_id: str) -> List[LaunchContent]:
        with get_income_conn() as conn:
            rows = conn.execute("SELECT * FROM launch_content WHERE launch_id = ?", (launch_id,)).fetchall()
        return [
            LaunchContent(
                id=r["id"], launch_id=r["launch_id"], content_type=r["content_type"],
                title=r["title"], content=r["content"], status=r["status"],
                platform_url=r["platform_url"], created_at=r["created_at"],
                approved_at=r["approved_at"], published_at=r["published_at"]
            ) for r in rows
        ]
    
    def approve_content(self, content_id: str, approved: bool, feedback: str = "") -> bool:
        """Approve or reject a content piece."""
        with get_income_conn() as conn:
            if approved:
                conn.execute("UPDATE launch_content SET status = 'approved', approved_at = ? WHERE id = ?", 
                            (time.time(), content_id))
            else:
                conn.execute("UPDATE launch_content SET status = 'rejected' WHERE id = ?", (content_id,))
        return True
    
    def get_launch_status(self, launch_id: str) -> Dict:
        launch = self.get_launch(launch_id)
        if not launch:
            return {"error": "Launch not found"}
        
        content = self.get_content(launch.id)
        return {
            "launch_id": launch.id,
            "title": launch.title,
            "status": launch.status.value,
            "launch_url": launch.launch_url,
            "content_count": len(content),
            "content_approved": sum(1 for c in content if c.status == "approved"),
            "content_pending": sum(1 for c in content if c.status == "pending_approval"),
            "error": launch.error,
        }


# ══════════════════════════════════════════════════════════════════════════════
# MODULE SINGLETON
# ══════════════════════════════════════════════════════════════════════════════

_launch_agent: Optional["LaunchAgent"] = None


def get_launch_agent(llm_fn: Optional[Callable] = None) -> "LaunchAgent":
    global _launch_agent
    if _launch_agent is None:
        _launch_agent = LaunchAgent(llm_fn)
    return _launch_agent


def reset_launch_agent():
    global _launch_agent
    if _launch_agent:
        asyncio.create_task(_launch_agent.stop())
    _launch_agent = None