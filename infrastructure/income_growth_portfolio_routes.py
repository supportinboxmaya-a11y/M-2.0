"""
Maya 2.0 ULTRA - Growth & Portfolio Manager API Routes
Income Engine: Growth proposals, portfolio recommendations, metrics.
"""
import os
import time
import json
from fastapi import APIRouter, HTTPException, Depends, Form, Body
from typing import Optional, List, Dict
from pydantic import BaseModel

from infrastructure.income_growth_portfolio import (
    get_growth_agent, GrowthAgent, GrowthProposal, GrowthActionType,
    get_portfolio_manager, PortfolioManager, PortfolioRecommendation, PortfolioAction,
    reset_growth_agent, reset_portfolio_manager, ProjectMetrics,
    init_growth_tables
)

router = APIRouter(prefix="/api/v1/income/growth", tags=["income-growth"])


# Dependency
def get_growth() -> GrowthAgent:
    return get_growth_agent()

def get_portfolio() -> PortfolioManager:
    return get_portfolio_manager()


# Models
class ProposalAction(BaseModel):
    proposal_id: str
    approved: bool

class MetricsUpdate(BaseModel):
    project_id: str
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


# ═════════════════════════════════════════════════════════════════════════════
# GROWTH PROPOSALS
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/proposals")
async def list_proposals(
    project_id: Optional[str] = None,
    status: Optional[str] = None,
    limit: int = 50,
    agent: GrowthAgent = Depends(get_growth),
):
    """List growth proposals."""
    proposals = agent.get_proposals(project_id, status)
    return {
        "proposals": [
            {
                "id": p.id,
                "project_id": p.project_id,
                "action_type": p.action_type.value,
                "title": p.title,
                "description": p.description,
                "impact_score": p.impact_score,
                "effort_score": p.effort_score,
                "confidence": p.confidence,
                "status": p.status,
                "data_source": p.data_source,
                "created_at": p.created_at,
                "approved_at": p.approved_at,
                "implemented_at": p.implemented_at,
            }
            for p in proposals[:limit]
        ],
        "count": len(proposals),
    }


@router.get("/proposals/{proposal_id}")
async def get_proposal(proposal_id: str, agent: GrowthAgent = Depends(get_growth)):
    """Get a single proposal."""
    proposals = agent.get_proposals()
    proposal = next((p for p in proposals if p.id == proposal_id), None)
    if not proposal:
        raise HTTPException(status_code=404, detail="Proposal not found")
    return {
        "id": proposal.id,
        "project_id": proposal.project_id,
        "action_type": proposal.action_type.value,
        "title": proposal.title,
        "description": proposal.description,
        "impact_score": proposal.impact_score,
        "effort_score": proposal.effort_score,
        "confidence": proposal.confidence,
        "status": proposal.status,
        "data_source": proposal.data_source,
        "created_at": proposal.created_at,
        "approved_at": proposal.approved_at,
        "implemented_at": proposal.implemented_at,
    }


@router.post("/proposals/{proposal_id}/decide")
async def decide_proposal(
    proposal_id: str,
    req: ProposalAction,
    agent: GrowthAgent = Depends(get_growth),
):
    """Approve or reject a growth proposal."""
    success = agent.approve_proposal(proposal_id, req.approved)
    if not success:
        raise HTTPException(status_code=404, detail="Proposal not found")
    return {"success": True, "proposal_id": proposal_id, "approved": req.approved}


# ══════════════════════════════════════════════════════════════════════════════
# METRICS
# ══════════════════════════════════════════════════════════════════════════════

@router.post("/metrics")
async def update_metrics(
    req: MetricsUpdate,
    agent: GrowthAgent = Depends(get_growth),
):
    """Update project metrics (from analytics webhook or manual)."""
    from infrastructure.income_engine import get_income_conn
    with get_income_conn() as conn:
        conn.execute("""
            INSERT OR REPLACE INTO project_metrics 
            (id, project_id, period_start, period_end, visitors, signups, conversions,
             revenue, churn_rate, avg_session_duration, bounce_rate, error_rate, uptime, nps_score)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (uuid.uuid4().hex[:12], req.project_id, time.time() - 86400 * 7, time.time(),
              req.visitors, req.signups, req.conversions, req.revenue, req.churn_rate,
              req.avg_session_duration, req.bounce_rate, req.error_rate, req.uptime, req.nps_score))
    return {"success": True, "project_id": req.project_id}


@router.get("/metrics/{project_id}")
async def get_metrics(
    project_id: str,
    limit: int = 30,
    agent: GrowthAgent = Depends(get_growth),
):
    """Get historical metrics for a project."""
    from infrastructure.income_engine import get_income_conn
    with get_income_conn() as conn:
        rows = conn.execute("""
            SELECT * FROM project_metrics WHERE project_id = ? 
            ORDER BY period_end DESC LIMIT ?
        """, (project_id, limit)).fetchall()
    return {"metrics": [dict(r) for r in rows]}


# ══════════════════════════════════════════════════════════════════════════════
# PORTFOLIO RECOMMENDATIONS
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/portfolio/recommendations")
async def get_recommendations(
    project_id: Optional[str] = None,
    limit: int = 50,
    agent: PortfolioManager = Depends(get_portfolio),
):
    """Get portfolio recommendations."""
    recs = agent.get_recommendations(project_id)
    return {
        "recommendations": [
            {
                "id": r.id,
                "project_id": r.project_id,
                "action": r.action.value,
                "rationale": r.rationale,
                "confidence": r.confidence,
                "suggested_resources": r.suggested_resources,
                "created_at": r.created_at,
            }
            for r in recs[:limit]
        ],
        "count": len(recs),
    }


@router.post("/portfolio/review")
async def trigger_portfolio_review(
    agent: PortfolioManager = Depends(get_portfolio),
):
    """Trigger a manual portfolio review."""
    await agent._run_weekly_review()
    return {"success": True, "message": "Weekly review triggered"}


@router.get("/portfolio/summary")
async def get_portfolio_summary(
    agent: PortfolioManager = Depends(get_portfolio),
):
    """Get portfolio summary."""
    projects = agent._get_all_projects()
    
    by_status = {}
    for p in projects:
        status = p.get("status", "unknown")
        by_status[status] = by_status.get(status, 0) + 1
    
    return {
        "total_projects": len(projects),
        "by_status": by_status,
        "live_projects": len([p for p in projects if p.get("launch_status") == "live"]),
        "building_projects": len([p for p in projects if p.get("status") in ("building", "testing")]),
        "failed_projects": len([p for p in projects if p.get("status") == "failed"]),
    }


# ══════════════════════════════════════════════════════════════════════════════
# GROWTH ACTIONS LOG
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/actions/log")
async def get_actions_log(
    project_id: Optional[str] = None,
    limit: int = 100,
    agent: GrowthAgent = Depends(get_growth),
):
    """Get growth actions log."""
    from infrastructure.income_engine import get_income_conn
    with get_income_conn() as conn:
        query = "SELECT * FROM growth_actions_log"
        params = []
        if project_id:
            query += " WHERE project_id = ?"
            params.append(project_id)
        query += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)
        rows = conn.execute(query, params).fetchall()
    return {"actions": [dict(r) for r in rows], "count": len(rows)}


# ══════════════════════════════════════════════════════════════════════════════
# HEALTH
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/health")
async def health():
    return {"status": "healthy", "growth_agent": "active", "portfolio_manager": "active"}


# ═════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════

@router.on_event("startup")
async def startup_growth():
    if os.environ.get("GROWTH_ENABLED", "true").lower() == "true":
        agent = get_growth_agent()
        await agent.start()
    
    if os.environ.get("PORTFOLIO_ENABLED", "true").lower() == "true":
        agent = get_portfolio_manager()
        await agent.start()

@router.on_event("shutdown")
async def shutdown_growth():
    reset_growth_agent()
    reset_portfolio_manager()