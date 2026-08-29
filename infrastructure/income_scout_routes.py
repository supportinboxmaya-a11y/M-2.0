"""
Maya 2.0 ULTRA - Scout Agent API Routes
Income Engine: Opportunity scanning endpoints.
"""
import os
import json
from fastapi import APIRouter, HTTPException, Depends, Form, Body
from typing import Optional, List, Dict
from pydantic import BaseModel

from infrastructure.income_engine import (
    get_scout_agent, ScoutAgent, Opportunity, OpportunityStatus,
    reset_scout_agent, init_income_db, init_owner_pref_db,
    get_income_conn, get_pref_conn
)

router = APIRouter(prefix="/api/v1/income/scout", tags=["income-scout"])


# Dependency
def get_agent() -> ScoutAgent:
    return get_scout_agent()


# Models
class ScanRequest(BaseModel):
    source: Optional[str] = None  # Specific source to scan, or all


class OpportunityResponse(BaseModel):
    id: str
    title: str
    description: str
    problem_statement: str
    target_user: str
    proposed_solution: str
    market_signal_score: float
    build_complexity_score: float
    competition_score: float
    monetization_score: float
    total_score: float
    status: str
    source_category: str
    target_market: str
    estimated_market_size: str
    monetization_model: str
    created_at: float
    updated_at: float
    analyzed_at: Optional[float]
    rejected_reason: str
    owner_rejected: bool
    owner_feedback: str


class DecisionRequest(BaseModel):
    opportunity_id: str
    approved: bool
    feedback: str = ""


# ════════════════════════════════════════════════════════════════════════════
# SCAN CONTROL
# ════════════════════════════════════════════════════════════════════════════

@router.post("/scan")
async def trigger_scan(
    req: ScanRequest = Body(default=None),
    agent: ScoutAgent = Depends(get_agent),
):
    """Trigger a manual scan cycle."""
    result = await agent.run_scan_cycle()
    return result


@router.get("/scan/history")
async def scan_history(
    limit: int = 20,
    agent: ScoutAgent = Depends(get_agent),
):
    """Get recent scan history."""
    with get_income_conn() as conn:
        rows = conn.execute("""
            SELECT * FROM scout_runs ORDER BY started_at DESC LIMIT ?
        """, (limit,)).fetchall()
    return {"runs": [dict(r) for r in rows]}


@router.get("/signals")
async def get_recent_signals(
    source: Optional[str] = None,
    signal_type: Optional[str] = None,
    limit: int = 50,
    agent: ScoutAgent = Depends(get_agent),
):
    """Get recent raw signals."""
    with get_income_conn() as conn:
        query = "SELECT * FROM raw_signals"
        params = []
        conditions = []
        
        if source:
            conditions.append("source = ?")
            params.append(source)
        if signal_type:
            conditions.append("signal_type = ?")
            params.append(signal_type)
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)
        
        rows = conn.execute(query, params).fetchall()
    return {"signals": [dict(r) for r in rows]}


# ═════════════════════════════════════════════════════════════════════════════
# OPPORTUNITIES
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/opportunities")
async def list_opportunities(
    status: Optional[str] = None,
    category: Optional[str] = None,
    min_score: float = 0,
    limit: int = 50,
    agent: ScoutAgent = Depends(get_agent),
):
    """List scored opportunities."""
    with get_income_conn() as conn:
        query = "SELECT * FROM opportunities WHERE total_score >= ?"
        params = [min_score]
        
        if status:
            query += " AND status = ?"
            params.append(status)
        if category:
            query += " AND source_category = ?"
            params.append(category)
        
        query += " ORDER BY total_score DESC LIMIT ?"
        params.append(limit)
        
        rows = conn.execute(query, params).fetchall()
    return {"opportunities": [dict(r) for r in rows], "count": len(rows)}


@router.get("/opportunities/{opp_id}")
async def get_opportunity(opp_id: str, agent: ScoutAgent = Depends(get_agent)):
    """Get a single opportunity by ID."""
    with get_income_conn() as conn:
        row = conn.execute("SELECT * FROM opportunities WHERE id = ?", (opp_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    return dict(row)


@router.post("/opportunities/{opp_id}/decision")
async def record_decision(
    opp_id: str,
    req: DecisionRequest,
    agent: ScoutAgent = Depends(get_agent),
):
    """Record owner's decision on an opportunity (for preference learning)."""
    agent.record_owner_decision(req.opportunity_id, req.approved, req.feedback)
    
    with get_income_conn() as conn:
        if req.approved:
            conn.execute("UPDATE opportunities SET status = ? WHERE id = ?", 
                        ("queued_for_strategist", req.opportunity_id))
        else:
            conn.execute("UPDATE opportunities SET status = ?, rejected_reason = ? WHERE id = ?", 
                        ("rejected", req.feedback or "Rejected by owner", req.opportunity_id))
    
    return {"success": True, "opportunity_id": req.opportunity_id, "approved": req.approved}


@router.delete("/opportunities/{opp_id}")
async def reject_opportunity(opp_id: str, agent: ScoutAgent = Depends(get_agent)):
    """Explicitly reject an opportunity."""
    with get_income_conn() as conn:
        conn.execute("UPDATE opportunities SET status = 'rejected', owner_rejected = 1 WHERE id = ?", 
                    (opp_id,))
    return {"success": True, "opportunity_id": opp_id}


# ═════════════════════════════════════════════════════════════════════════════
# OWNER PREFERENCES
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/preferences")
async def get_preferences(agent: ScoutAgent = Depends(get_agent)):
    """Get learned owner preferences."""
    prefs = agent._get_owner_preferences()
    return {"preferences": prefs}


@router.post("/preferences")
async def set_preference(
    category: str = Form(...),
    preference: str = Form(...),  # prefer, avoid, neutral
    confidence: float = Form(0.7),
    notes: str = Form(""),
    agent: ScoutAgent = Depends(get_agent),
):
    """Manually set an owner preference."""
    from infrastructure.income_engine import get_pref_conn
    import uuid
    import time
    
    with get_pref_conn() as conn:
        conn.execute("""
            INSERT OR REPLACE INTO owner_preferences 
            (id, category, preference, confidence, evidence_count, last_updated, notes)
            VALUES (?, ?, ?, ?, 
                COALESCE((SELECT evidence_count FROM owner_preferences WHERE category = ?), 0) + 1,
                ?, ?)
        """, (uuid.uuid4().hex[:12], category, preference, confidence, category, 
              time.time(), notes))
    return {"success": True, "category": category, "preference": preference}


@router.delete("/preferences/{category}")
async def delete_preference(category: str):
    """Delete an owner preference."""
    from infrastructure.income_engine import get_pref_conn
    with get_pref_conn() as conn:
        conn.execute("DELETE FROM owner_preferences WHERE category = ?", (category,))
    return {"success": True, "category": category}


# ═════════════════════════════════════════════════════════════════════════════
# STATS & HEALTH
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/stats")
async def get_stats():
    """Get Scout Agent statistics."""
    with get_income_conn() as conn:
        total_opps = conn.execute("SELECT COUNT(*) FROM opportunities").fetchone()[0]
        by_status = conn.execute("""
            SELECT status, COUNT(*) as count FROM opportunities GROUP BY status
        """).fetchall()
        by_category = conn.execute("""
            SELECT source_category, COUNT(*) as count FROM opportunities GROUP BY source_category
        """).fetchall()
        total_signals = conn.execute("SELECT COUNT(*) FROM raw_signals").fetchone()[0]
        recent_runs = conn.execute("""
            SELECT * FROM scout_runs ORDER BY started_at DESC LIMIT 5
        """).fetchall()
    
    return {
        "total_opportunities": total_opps,
        "total_signals": total_signals,
        "by_status": [dict(r) for r in by_status],
        "by_category": [dict(r) for r in by_category],
        "recent_runs": [dict(r) for r in recent_runs],
    }


@router.get("/health")
async def health():
    return {"status": "healthy", "scout_agent": "active"}


# ═════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ═════════════════════════════════════════════════════════════════════════════

@router.on_event("startup")
async def startup_scout():
    if os.environ.get("SCOUT_ENABLED", "true").lower() == "true":
        agent = get_scout_agent()
        await agent.start()

@router.on_event("shutdown")
async def shutdown_scout():
    reset_scout_agent()