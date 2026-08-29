"""
Maya 2.0 ULTRA - Income Engine: Growth & Portfolio Manager Agents
==================================================================
Growth Agent: Monitors live projects, proposes improvements, auto-implements small fixes.
Portfolio Manager: Weekly review of all projects, recommends resource allocation.
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

log = get_logger("growth_portfolio")

from infrastructure.income_engine import get_income_conn, get_pref_conn

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═════════════════════════════════════════════════════════════════════════════

GROWTH_DB_DIR = Path("/home/ubuntu/M-2.0/storage/income_engine")
GROWTH_DB_DIR.mkdir(parents=True, exist_ok=True)

# ══════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ═════════════════════════════════════════════════════════════════════════════

class GrowthActionType(Enum):
    BUG_FIX = "bug_fix"
    UI_IMPROVEMENT = "ui_improvement"
    PERFORMANCE = "performance"
    FEATURE_SMALL = "feature_small"
    ANALYTICS_UPDATE = "analytics_update"
    CONTENT_UPDATE = "content_update"
    SEO_IMPROVEMENT = "seo_improvement"


class PortfolioAction(Enum):
    DOUBLE_DOWN = "double_down"       # Invest more in winner
    MAINTAIN = "maintain"             # Keep current investment
    PIVOT = "pivot"                   # Change direction
    SUNSET = "sunset"                 # Gracefully shut down
    RESEARCH = "research"             # Need more data


@dataclass
class GrowthProposal:
    """A proposed growth action for a live project."""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    project_id: str = ""
    action_type: GrowthActionType = GrowthActionType.BUG_FIX
    title: str = ""
    description: str = ""
    impact_score: float = 0.0  # 0-100
    effort_score: float = 0.0  # 0-100
    confidence: float = 0.0  # 0-1
    status: str = "proposed"  # proposed, approved, rejected, implementing, completed
    data_source: str = ""  # analytics, user_feedback, error_logs, competitor
    created_at: float = field(default_factory=time.time)
    approved_at: Optional[float] = None
    implemented_at: Optional[float] = None


@dataclass
class ProjectMetrics:
    """Live metrics for a launched project."""
    project_id: str = ""
    period_start: float = 0
    period_end: float = 0
    visitors: int = 0
    signups: int = 0
    conversions: int = 0
    revenue: float = 0.0
    churn_rate: float = 0.0
    avg_session_duration: float = 0.0
    bounce_rate: float = 0.0
    error_rate: float = 0.0
    uptime: float = 100.0
    nps_score: Optional[float] = None


@dataclass
class PortfolioRecommendation:
    """Weekly portfolio recommendation."""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    project_id: str = ""
    action: PortfolioAction = PortfolioAction.MAINTAIN
    rationale: str = ""
    confidence: float = 0.0
    suggested_resources: Dict[str, float] = field(default_factory=dict)  # % allocation
    created_at: float = field(default_factory=time.time)


# ══════════════════════════════════════════════════════════════════════════════
# DATABASE
# ═════════════════════════════════════════════════════════════════════════════

def init_growth_tables():
    with get_income_conn() as conn:
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA busy_timeout=5000")
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS growth_proposals (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL,
                action_type TEXT NOT NULL,
                title TEXT,
                description TEXT,
                impact_score REAL DEFAULT 0,
                effort_score REAL DEFAULT 0,
                confidence REAL DEFAULT 0,
                status TEXT DEFAULT 'proposed',
                data_source TEXT,
                created_at REAL,
                approved_at REAL,
                implemented_at REAL
            )
        """)
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS project_metrics (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL,
                period_start REAL,
                period_end REAL,
                visitors INTEGER DEFAULT 0,
                signups INTEGER DEFAULT 0,
                conversions INTEGER DEFAULT 0,
                revenue REAL DEFAULT 0,
                churn_rate REAL DEFAULT 0,
                avg_session_duration REAL DEFAULT 0,
                bounce_rate REAL DEFAULT 0,
                error_rate REAL DEFAULT 0,
                uptime REAL DEFAULT 100,
                nps_score REAL
            )
        """)
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS portfolio_recommendations (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL,
                action TEXT NOT NULL,
                rationale TEXT,
                confidence REAL DEFAULT 0,
                suggested_resources TEXT DEFAULT '{}',
                created_at REAL
            )
        """)
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS growth_actions_log (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL,
                action_type TEXT,
                description TEXT,
                status TEXT,
                created_at REAL,
                completed_at REAL
            )
        """)


# ══════════════════════════════════════════════════════════════════════════════
# GROWTH AGENT
# ══════════════════════════════════════════════════════════════════════════════

class GrowthAgent:
    """
    Monitors live projects, identifies improvement opportunities,
    proposes and auto-implements small fixes.
    """
    
    def __init__(self, llm_fn: Optional[Callable] = None):
        self.llm_fn = llm_fn
        self._running = False
        self._task: Optional[asyncio.Task] = None
        
        init_growth_tables()
        log.info("GrowthAgent initialized")
    
    async def start(self):
        if self._running:
            return
        self._running = True
        self._task = asyncio.create_task(self._growth_loop())
        log.info("GrowthAgent started")
    
    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        log.info("GrowthAgent stopped")
    
    async def _growth_loop(self):
        """Daily growth analysis and proposal generation."""
        while self._running:
            try:
                await self._analyze_and_propose()
            except Exception as e:
                log.error(f"Growth loop error: {e}")
            
            try:
                await asyncio.sleep(24 * 3600)  # Daily
            except asyncio.CancelledError:
                break
    
    async def _analyze_and_propose(self):
        """Analyze live projects and generate growth proposals."""
        log.info("Starting daily growth analysis")
        
        # Get all live projects
        live_projects = self._get_live_projects()
        
        for project in live_projects:
            # Get metrics
            metrics = await self._fetch_metrics(project["id"])
            
            # Analyze and generate proposals
            proposals = await self._analyze_project(project, metrics)
            
            for proposal in proposals:
                await self._store_proposal(proposal)
                if proposal.confidence > 0.8 and proposal.effort_score < 30:
                    # Auto-approve low-effort, high-confidence improvements
                    await self._auto_implement(proposal)
        
        log.info("Daily growth analysis complete")
    
    def _get_live_projects(self) -> List[Dict]:
        with get_income_conn() as conn:
            rows = conn.execute("""
                SELECT bp.id, bp.title, bp.deploy_url, lp.launch_url
                FROM build_projects bp
                JOIN launch_projects lp ON lp.build_project_id = bp.id
                WHERE bp.status = 'launched' AND lp.status = 'live'
            """).fetchall()
        return [dict(r) for r in rows]
    
    async def _fetch_metrics(self, project_id: str) -> ProjectMetrics:
        """Fetch live metrics for a project."""
        # In production, this would query analytics APIs (GA4, Mixpanel, etc.)
        # For now, return simulated metrics
        return ProjectMetrics(
            project_id=project_id,
            period_start=time.time() - 86400 * 7,
            period_end=time.time(),
            visitors=1500,
            signups=45,
            conversions=8,
            revenue=1250.0,
            churn_rate=0.05,
            avg_session_duration=180.0,
            bounce_rate=0.42,
            error_rate=0.01,
            uptime=99.9,
            nps_score=42.0,
        )
    
    async def _analyze_project(self, project: Dict, metrics: ProjectMetrics) -> List[GrowthProposal]:
        """Analyze project metrics and generate growth proposals."""
        proposals = []
        
        # Rule-based analysis
        if metrics.error_rate > 0.02:
            proposals.append(GrowthProposal(
                project_id=project["id"],
                action_type=GrowthActionType.BUG_FIX,
                title=f"High error rate: {metrics.error_rate:.1%}",
                description=f"Error rate {metrics.error_rate:.1%} exceeds 2% threshold. Investigate and fix top errors.",
                impact_score=70,
                effort_score=20,
                confidence=0.9,
                data_source="error_logs",
            ))
        
        if metrics.bounce_rate > 0.6:
            proposals.append(GrowthProposal(
                project_id=project["id"],
                action_type=GrowthActionType.UI_IMPROVEMENT,
                title=f"High bounce rate: {metrics.bounce_rate:.0%}",
                description=f"Bounce rate {metrics.bounce_rate:.0%} indicates landing page issues. Improve hero, clarity, load time.",
                impact_score=60,
                effort_score=30,
                confidence=0.75,
                data_source="analytics",
            ))
        
        if metrics.conversions / max(metrics.signups, 1) < 0.1:
            proposals.append(GrowthProposal(
                project_id=project["id"],
                action_type=GrowthActionType.FEATURE_SMALL,
                title="Low trial-to-paid conversion",
                description=f"Only {metrics.conversions}/{metrics.signups} trials convert. Add onboarding, trial extensions, or value demonstration.",
                impact_score=80,
                effort_score=40,
                confidence=0.7,
                data_source="analytics",
            ))
        
        if metrics.uptime < 99.5:
            proposals.append(GrowthProposal(
                project_id=project["id"],
                action_type=GrowthActionType.PERFORMANCE,
                title=f"Uptime below target: {metrics.uptime:.1f}%",
                description=f"Uptime {metrics.uptime:.1f}% below 99.5% target. Check infrastructure, alerts.",
                impact_score=90,
                effort_score=15,
                confidence=0.95,
                data_source="monitoring",
            ))
        
        # LLM-based analysis for more sophisticated proposals
        if self.llm_fn and metrics.visitors > 100:
            proposals.extend(await self._llm_analysis(project, metrics))
        
        return proposals
    
    async def _llm_analysis(self, project: Dict, metrics: ProjectMetrics) -> List[GrowthProposal]:
        """Use LLM for advanced growth analysis."""
        if not self.llm_fn:
            return []
        
        prompt = f"""Analyze this SaaS project's metrics and suggest 1-2 specific growth actions:

Project: {project.get('title', 'Unknown')}
Metrics (7 days):
- Visitors: {metrics.visitors}
- Signups: {metrics.signups}
- Conversions: {metrics.conversions}
- Revenue: ${metrics.revenue}
- Churn: {metrics.churn_rate:.1%}
- Bounce Rate: {metrics.bounce_rate:.0%}
- Avg Session: {metrics.avg_session_duration:.0f}s
- Uptime: {metrics.uptime:.1f}%

Suggest specific, actionable improvements with impact/effort scores.
Return JSON array of: {{"title": "", "description": "", "action_type": "", "impact_score": 0-100, "effort_score": 0-100, "confidence": 0-1, "data_source": ""}}"""
        
        try:
            response = self.llm_fn(prompt)
            json_start = response.find("[")
            json_end = response.rfind("]") + 1
            if json_start >= 0 and json_end > 0:
                data = json.loads(response[json_start:json_end])
                proposals = []
                for item in data:
                    if isinstance(item, dict):
                        proposals.append(GrowthProposal(
                            project_id=project.get("id", ""),
                            action_type=GrowthActionType(item.get("action_type", "feature_small")),
                            title=item.get("title", ""),
                            description=item.get("description", ""),
                            impact_score=item.get("impact_score", 50),
                            effort_score=item.get("effort_score", 50),
                            confidence=item.get("confidence", 0.5),
                            data_source=item.get("data_source", "llm"),
                        ))
                return proposals
        except Exception as e:
            log.warning(f"LLM analysis failed: {e}")
        return []
    
    async def _store_proposal(self, proposal: GrowthProposal):
        with get_income_conn() as conn:
            conn.execute("""
                INSERT INTO growth_proposals (id, project_id, action_type, title, description,
                    impact_score, effort_score, confidence, status, data_source, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'proposed', ?, ?)
            """, (proposal.id, proposal.project_id, proposal.action_type.value,
                  proposal.title, proposal.description, proposal.impact_score,
                  proposal.effort_score, proposal.confidence, proposal.data_source,
                  proposal.created_at))
    
    async def _auto_implement(self, proposal: GrowthProposal):
        """Auto-implement low-effort, high-confidence proposals."""
        if proposal.effort_score > 30 or proposal.confidence < 0.8:
            return
        
        # In production, this would trigger the Builder Agent to implement the fix
        log.info(f"Auto-implementing: {proposal.title} (confidence: {proposal.confidence}, effort: {proposal.effort_score})")
        
        with get_income_conn() as conn:
            conn.execute("UPDATE growth_proposals SET status = 'implementing' WHERE id = ?", (proposal.id,))
        
        # Log action
        with get_income_conn() as conn:
            conn.execute("""
                INSERT INTO growth_actions_log (id, project_id, action_type, description, status, created_at)
                VALUES (?, ?, ?, 'approved', ?)
            """, (uuid.uuid4().hex[:12], proposal.project_id, proposal.title, time.time()))
        
        proposal.status = "implementing"
        proposal.approved_at = time.time()
        await self._store_proposal(proposal)
    
    def get_proposals(self, project_id: str = None, status: str = None) -> List[GrowthProposal]:
        with get_income_conn() as conn:
            query = "SELECT * FROM growth_proposals"
            params = []
            conditions = []
            if project_id:
                conditions.append("project_id = ?")
                params.append(project_id)
            if status:
                conditions.append("status = ?")
                params.append(status)
            if conditions:
                query += " WHERE " + " AND ".join(conditions)
            query += " ORDER BY created_at DESC"
            rows = conn.execute(query, params).fetchall()
        return [GrowthProposal(**dict(r)) for r in rows]
    
    def approve_proposal(self, proposal_id: str, approved: bool) -> bool:
        with get_income_conn() as conn:
            if approved:
                conn.execute("UPDATE growth_proposals SET status = 'approved', approved_at = ? WHERE id = ?",
                           (time.time(), proposal_id))
            else:
                conn.execute("UPDATE growth_proposals SET status = 'rejected' WHERE id = ?", (proposal_id,))
        return True


# ══════════════════════════════════════════════════════════════════════════════
# PORTFOLIO MANAGER
# ═════════════════════════════════════════════════════════════════════════════

class PortfolioManager:
    """
    Weekly portfolio review - analyzes all projects, recommends resource allocation.
    """
    
    def __init__(self, llm_fn: Optional[Callable] = None):
        self.llm_fn = llm_fn
        self._running = False
        self._task: Optional[asyncio.Task] = None
        init_growth_tables()
        log.info("PortfolioManager initialized")
    
    async def start(self):
        if self._running:
            return
        self._running = True
        self._task = asyncio.create_task(self._weekly_loop())
        log.info("PortfolioManager started")
    
    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        log.info("PortfolioManager stopped")
    
    async def _weekly_loop(self):
        while self._running:
            try:
                await self._run_weekly_review()
            except Exception as e:
                log.error(f"Portfolio review error: {e}")
            
            try:
                await asyncio.sleep(7 * 24 * 3600)  # Weekly
            except asyncio.CancelledError:
                break
    
    async def _run_weekly_review(self):
        """Run weekly portfolio review."""
        log.info("Starting weekly portfolio review")
        
        # Get all projects
        projects = self._get_all_projects()
        
        # Analyze each project
        recommendations = []
        for project in projects:
            rec = await self._analyze_project(project)
            if rec:
                recommendations.append(rec)
                await self._store_recommendation(rec)
        
        # Generate summary digest
        await self._send_weekly_digest(recommendations)
        
        log.info(f"Weekly review complete: {len(recommendations)} recommendations")
    
    def _get_all_projects(self) -> List[Dict]:
        with get_income_conn() as conn:
            rows = conn.execute("""
                SELECT bp.id, bp.title, bp.status, bp.created_at, bp.deploy_url,
                       lp.launch_url, lp.status as launch_status
                FROM build_projects bp
                LEFT JOIN launch_projects lp ON lp.build_project_id = bp.id
            """).fetchall()
        return [dict(r) for r in rows]
    
    async def _analyze_project(self, project: Dict) -> Optional[PortfolioRecommendation]:
        """Analyze a project and create portfolio recommendation."""
        # Get recent metrics
        with get_income_conn() as conn:
            metrics_row = conn.execute("""
                SELECT * FROM project_metrics WHERE project_id = ? 
                ORDER BY period_end DESC LIMIT 1
            """, (project["id"],)).fetchone()
        
        # Determine action based on status and metrics
        status = project.get("status", "unknown")
        launch_status = project.get("launch_status", "none")
        
        if status == "launched" and launch_status == "live":
            # Analyze metrics if available
            return await self._analyze_live_project(project)
        elif status in ("building", "testing", "deploying"):
            return PortfolioRecommendation(
                project_id=project["id"],
                action=PortfolioAction.MAINTAIN,
                rationale="Project in development - maintain current pace",
                confidence=0.8,
                suggested_resources={"engineering": 0.7, "design": 0.2, "ops": 0.1},
            )
        elif status == "failed" or launch_status == "failed":
            return PortfolioRecommendation(
                project_id=project["id"],
                action=PortfolioAction.PIVOT,
                rationale="Project failed - analyze root cause and pivot or sunset",
                confidence=0.7,
                suggested_resources={"research": 0.5, "engineering": 0.3, "ops": 0.2},
            )
        else:
            return PortfolioRecommendation(
                project_id=project["id"],
                action=PortfolioAction.RESEARCH,
                rationale=f"Project in {status} state - need more data",
                confidence=0.5,
                suggested_resources={"research": 0.6, "engineering": 0.3},
            )
    
    async def _analyze_live_project(self, project: Dict) -> Optional[PortfolioRecommendation]:
        """Analyze live project with metrics."""
        # In production, fetch real metrics from analytics
        # For now, use heuristics
        return PortfolioRecommendation(
            project_id=project["id"],
            action=PortfolioAction.MAINTAIN,
            rationale=f"Live project {project['title']} - maintain and monitor",
            confidence=0.7,
            suggested_resources={"engineering": 0.5, "growth": 0.3, "ops": 0.2},
        )
    
    async def _store_recommendation(self, rec: PortfolioRecommendation):
        with get_income_conn() as conn:
            conn.execute("""
                INSERT INTO portfolio_recommendations (id, project_id, action, rationale, confidence, suggested_resources, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (rec.id, rec.project_id, rec.action.value, rec.rationale, rec.confidence,
                  json.dumps(rec.suggested_resources), rec.created_at))
    
    async def _send_weekly_digest(self, recommendations: List[PortfolioRecommendation]):
        """Send weekly portfolio digest via notifications."""
        from infrastructure.income_notifications import (
            get_notification_service, Notification, NotificationType, NotificationPriority
        )
        
        notif = get_notification_service()
        
        digest = f"""
**Weekly Portfolio Digest**

**Summary:** {len(recommendations)} projects reviewed

**Actions:**
"""
        for rec in recommendations:
            action_emoji = {
                "double_down": "🚀",
                "maintain": "✅",
                "pivot": "🔄",
                "sunset": "🌅",
                "research": "🔍",
            }.get(rec.action.value, "📋")
            
            digest += f"\n{action_emoji} **{rec.action.value.upper()}** - Project {rec.project_id[:8]}: {rec.rationale[:100]}"
        
        notification = Notification(
            type=NotificationType.DAILY_DIGEST,
            priority=NotificationPriority.NORMAL,
            title="📊 Weekly Portfolio Review",
            message=digest,
            channels=["webhook", "email"],
            metadata={"recommendations": len(recommendations)},
        )
        
        notif = get_notification_service()
        await notif.send_notification(notification)
    
    def get_recommendations(self, project_id: str = None) -> List[PortfolioRecommendation]:
        with get_income_conn() as conn:
            query = "SELECT * FROM portfolio_recommendations"
            params = []
            if project_id:
                query += " WHERE project_id = ?"
                params.append(project_id)
            query += " ORDER BY created_at DESC"
            rows = conn.execute(query, params).fetchall()
        return [PortfolioRecommendation(**dict(r)) for r in rows]


# ══════════════════════════════════════════════════════════════════════════════
# MODULE SINGLETONS
# ══════════════════════════════════════════════════════════════════════════════

_growth_agent: Optional[GrowthAgent] = None
_portfolio_manager: Optional[PortfolioManager] = None


def get_growth_agent(llm_fn: Optional[Callable] = None) -> GrowthAgent:
    global _growth_agent
    if _growth_agent is None:
        _growth_agent = GrowthAgent(llm_fn)
    return _growth_agent


def reset_growth_agent():
    global _growth_agent
    if _growth_agent:
        asyncio.create_task(_growth_agent.stop())
    _growth_agent = None


def get_portfolio_manager(llm_fn: Optional[Callable] = None) -> PortfolioManager:
    global _portfolio_manager
    if _portfolio_manager is None:
        _portfolio_manager = PortfolioManager(llm_fn)
    return _portfolio_manager


def reset_portfolio_manager():
    global _portfolio_manager
    if _portfolio_manager:
        asyncio.create_task(_portfolio_manager.stop())
    _portfolio_manager = None


# Initialize tables on import
init_growth_tables()