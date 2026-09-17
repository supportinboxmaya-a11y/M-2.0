"""
Maya 2.0 ULTRA - Strategist Agent API Routes
Income Engine: Daily strategy review, opportunity ranking, plan drafting.
"""
import os
import json
from fastapi import APIRouter, HTTPException, Depends, Form, Body
from typing import Optional, List, Dict
from pydantic import BaseModel

from infrastructure.income_strategist import get_strategist_agent, StrategistAgent, reset_strategist_agent

router = APIRouter(prefix="/api/v1/income/strategist", tags=["income-strategist"])


# Dependency
def get_agent() -> StrategistAgent:
    return get_strategist_agent()


# ═════════════════════════════════════════════════════════════════════════════
# DAILY REVIEW
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/review")
async def trigger_review(agent: StrategistAgent = Depends(get_agent)):
    """Trigger a manual daily strategy review."""
    result = await agent.run_daily_review()
    return result


@router.get("/review/history")
async def review_history(
    limit: int = 20,
    agent: StrategistAgent = Depends(get_agent),
):
    """Get recent review history."""
    # This would query a reviews table in a full implementation
    return {"reviews": [], "message": "Review history not yet implemented"}


# ═════════════════════════════════════════════════════════════════════════════
# PLANS
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/plans")
async def list_plans(
    status: Optional[str] = None,
    limit: int = 20,
    agent: StrategistAgent = Depends(get_agent),
):
    """List all plans."""
    from infrastructure.income_engine import get_income_conn
    with get_income_conn() as conn:
        # Ensure table exists
        conn.execute("""
            CREATE TABLE IF NOT EXISTS plans (
                id TEXT PRIMARY KEY,
                opportunity_id TEXT NOT NULL,
                title TEXT,
                executive_summary TEXT,
                mvp_scope TEXT DEFAULT '[]',
                technical_approach TEXT,
                timeline TEXT DEFAULT '[]',
                success_metrics TEXT DEFAULT '[]',
                risks TEXT DEFAULT '[]',
                approval_checkpoints TEXT DEFAULT '[]',
                estimated_timeline_weeks INTEGER,
                status TEXT DEFAULT 'draft',
                created_at REAL,
                approved_at REAL,
                approved_by TEXT
            )
        """)
        query = "SELECT * FROM plans"
        params = []
        if status:
            query += " WHERE status = ?"
            params.append(status)
        query += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)
        rows = conn.execute(query, params).fetchall()
    return {"plans": [dict(r) for r in rows], "count": len(rows)}


@router.get("/plans/{plan_id}")
async def get_plan(plan_id: str, agent: StrategistAgent = Depends(get_agent)):
    """Get a single plan by ID."""
    from infrastructure.income_engine import get_income_conn
    with get_income_conn() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS plans (
                id TEXT PRIMARY KEY,
                opportunity_id TEXT NOT NULL,
                title TEXT,
                executive_summary TEXT,
                mvp_scope TEXT DEFAULT '[]',
                technical_approach TEXT,
                timeline TEXT DEFAULT '[]',
                success_metrics TEXT DEFAULT '[]',
                risks TEXT DEFAULT '[]',
                approval_checkpoints TEXT DEFAULT '[]',
                estimated_timeline_weeks INTEGER,
                status TEXT DEFAULT 'draft',
                created_at REAL,
                approved_at REAL,
                approved_by TEXT
            )
        """)
        row = conn.execute("SELECT * FROM plans WHERE id = ?", (plan_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Plan not found")
    return dict(row)


@router.post("/plans/{plan_id}/approve")
async def approve_plan(plan_id: str, agent: StrategistAgent = Depends(get_agent)):
    """Approve a plan for building."""
    from infrastructure.income_engine import get_income_conn
    with get_income_conn() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS plans (
                id TEXT PRIMARY KEY,
                opportunity_id TEXT NOT NULL,
                title TEXT,
                executive_summary TEXT,
                mvp_scope TEXT DEFAULT '[]',
                technical_approach TEXT,
                timeline TEXT DEFAULT '[]',
                success_metrics TEXT DEFAULT '[]',
                risks TEXT DEFAULT '[]',
                approval_checkpoints TEXT DEFAULT '[]',
                estimated_timeline_weeks INTEGER,
                status TEXT DEFAULT 'draft',
                created_at REAL,
                approved_at REAL,
                approved_by TEXT
            )
        """)
        conn.execute("UPDATE plans SET status = 'approved', approved_at = ? WHERE id = ?", 
                    (time.time(), plan_id))
        # Also update opportunity status
        conn.execute("""
            UPDATE opportunities SET status = 'approved' 
            WHERE id = (SELECT opportunity_id FROM plans WHERE id = ?)
        """, (plan_id,))
    return {"success": True, "plan_id": plan_id, "status": "approved"}


@router.post("/plans/{plan_id}/reject")
async def reject_plan(
    plan_id: str,
    reason: str = Form(""),
    agent: StrategistAgent = Depends(get_agent),
):
    """Reject a plan."""
    from infrastructure.income_engine import get_income_conn
    with get_income_conn() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS plans (
                id TEXT PRIMARY KEY,
                opportunity_id TEXT NOT NULL,
                title TEXT,
                executive_summary TEXT,
                mvp_scope TEXT DEFAULT '[]',
                technical_approach TEXT,
                timeline TEXT DEFAULT '[]',
                success_metrics TEXT DEFAULT '[]',
                risks TEXT DEFAULT '[]',
                approval_checkpoints TEXT DEFAULT '[]',
                estimated_timeline_weeks INTEGER,
                status TEXT DEFAULT 'draft',
                created_at REAL,
                approved_at REAL,
                approved_by TEXT
            )
        """)
        conn.execute("UPDATE plans SET status = 'rejected' WHERE id = ?", (plan_id,))
        conn.execute("""
            UPDATE opportunities SET status = 'rejected', rejected_reason = ? 
            WHERE id = (SELECT opportunity_id FROM plans WHERE id = ?)
        """, (reason or "Rejected by owner", plan_id))
    return {"success": True, "plan_id": plan_id, "status": "rejected"}


# ═════════════════════════════════════════════════════════════════════════════
# RANKED OPPORTUNITIES
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/ranked-opportunities")
async def get_ranked_opportunities(
    limit: int = 20,
    agent: StrategistAgent = Depends(get_agent),
):
    """Get Strategist-ranked opportunities (with owner preference adjustments)."""
    opportunities = agent._get_scored_opportunities()
    prefs = agent._get_owner_preferences()
    ranked = agent._rank_opportunities(opportunities, {}, agent._get_owner_preferences())
    return {"opportunities": ranked[:limit], "count": len(ranked)}


# ═════════════════════════════════════════════════════════════════════════════
# CONFIG
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/config")
async def get_config():
    return {
        "strategist_enabled": os.environ.get("STRATEGIST_ENABLED", "true").lower() == "true",
    }


# ═════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ══════════════════════════════════════════════════════════════════════════════

@router.on_event("startup")
async def startup_strategist():
    if os.environ.get("STRATEGIST_ENABLED", "true").lower() == "true":
        agent = get_strategist_agent()
        await agent.start()

@router.on_event("shutdown")
async def shutdown_strategist():
    reset_strategist_agent()