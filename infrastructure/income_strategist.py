"""
Maya 2.0 ULTRA - Income Engine: Strategist Agent
Daily strategist - reviews Scout's findings, ranks opportunities, 
drafts one-page plans for top opportunities, queues for owner approval.
"""
import asyncio
import json
import os
import time
import uuid
from contextlib import contextmanager
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set
from dataclasses import dataclass, field

import sqlite3
from maya_logging.logger import get_logger

log = get_logger("strategist")

# Import from income_engine
from infrastructure.income_engine import (
    get_income_conn, get_pref_conn, init_income_db, init_owner_pref_db
)


# ════════════════════════════════════════════════════════════════════════════
# STRATEGIST AGENT
# ═════════════════════════════════════════════════════════════════════════════

class StrategistAgent:
    """
    Daily strategist - reviews Scout's findings, ranks opportunities, 
    drafts one-page plans for top opportunities, queues for owner approval.
    
    Runs daily (cron). Fully autonomous up to approval queue.
    """
    
    def __init__(self, llm_fn: Optional[Callable] = None):
        self.llm_fn = llm_fn
        self._running = False
        self._task: Optional[asyncio.Task] = None
        
        init_income_db()
        init_owner_pref_db()
        
        log.info("StrategistAgent initialized")
    
    async def start(self):
        if self._running:
            return
        self._running = True
        self._task = asyncio.create_task(self._daily_loop())
        log.info("StrategistAgent started")
    
    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        log.info("StrategistAgent stopped")
    
    async def _daily_loop(self):
        """Run daily strategy review."""
        while self._running:
            try:
                await self.run_daily_review()
            except Exception as e:
                log.error(f"Strategist daily review error: {e}")
            
            try:
                await asyncio.sleep(24 * 3600)  # 24 hours
            except asyncio.CancelledError:
                break
    
    async def run_daily_review(self) -> Dict:
        """Run one daily strategy review cycle."""
        review_id = uuid.uuid4().hex[:12]
        started_at = time.time()
        
        log.info(f"Starting daily strategy review {review_id}")
        
        # 1. Get scored opportunities from Scout
        opportunities = self._get_scored_opportunities()
        
        # 2. Get project performance data
        project_performance = self._get_project_performance()
        
        # 3. Get owner preferences
        owner_prefs = self._get_owner_preferences()
        
        # 4. Rank opportunities
        ranked = self._rank_opportunities(opportunities, project_performance, owner_prefs)
        
        # 5. Draft plan for top opportunity
        top_plan = None
        if ranked:
            top_plan = await self._draft_plan(ranked[0])
            if top_plan:
                await self._queue_for_approval(top_plan)
        
        completed_at = time.time()
        
        result = {
            "review_id": uuid.uuid4().hex[:12],
            "opportunities_reviewed": len(opportunities),
            "top_opportunity": ranked[0]["id"] if ranked else None,
            "plan_created": top_plan is not None,
            "plan_id": top_plan.get("id") if top_plan else None,
            "duration_seconds": time.time() - started_at,
        }
        
        log.info(f"Daily review {result['review_id']} complete: {len(opportunities)} opportunities, plan={'yes' if top_plan else 'no'}")
        return result
    
    def _get_scored_opportunities(self) -> List[Dict]:
        """Get all scored opportunities from Scout."""
        with get_income_conn() as conn:
            rows = conn.execute("""
                SELECT * FROM opportunities 
                WHERE status = 'scored' 
                ORDER BY total_score DESC
            """).fetchall()
        return [dict(r) for r in rows]
    
    def _get_project_performance(self) -> Dict:
        """Get performance data for existing projects."""
        # This would query the projects table in a full implementation
        return {}
    
    def _get_owner_preferences(self) -> Dict:
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
    
    def _rank_opportunities(self, opportunities: List[Dict], 
                           performance: Dict, prefs: Dict) -> List[Dict]:
        """Rank opportunities using composite scoring."""
        ranked = []
        for opp in opportunities:
            # Base score from Scout
            score = opp.get("total_score", 0)
            
            # Adjust for owner preferences
            category = opp.get("source_category", "").lower()
            if category in prefs:
                pref = prefs[category]
                if pref["preference"] == "avoid" and pref["confidence"] > 0.6:
                    score *= 0.3  # Heavily penalize avoided categories
                elif pref["preference"] == "prefer" and pref["confidence"] > 0.6:
                    score *= 1.2  # Boost preferred categories
            
            # Adjust for recency (newer opportunities get slight boost)
            created = opp.get("created_at", 0)
            age_days = (time.time() - created) / 86400
            if age_days < 7:
                score *= 1.1
            elif age_days > 30:
                score *= 0.9
            
            opp["adjusted_score"] = round(score, 2)
            ranked.append(opp)
        
        ranked.sort(key=lambda x: x["adjusted_score"], reverse=True)
        return ranked
    
    async def _draft_plan(self, opportunity: Dict) -> Optional[Dict]:
        """Draft a one-page execution plan for an opportunity."""
        if not self.llm_fn:
            return None
        
        prompt = f"""You are Maya's Income Strategist. Create a concise one-page execution plan for this opportunity.

OPPORTUNITY:
Title: {opportunity.get('title', '')}
Description: {opportunity.get('description', '')}
Problem: {opportunity.get('problem_statement', '')}
Target User: {opportunity.get('target_user', '')}
Solution: {opportunity.get('proposed_solution', '')}
Category: {opportunity.get('source_category', '')}
Target Market: {opportunity.get('target_market', '')}
Monetization: {opportunity.get('monetization_model', '')}
Score: {opportunity.get('total_score', 0)} (adjusted: {opportunity.get('adjusted_score', 0)})

CONSTRAINTS:
- Maya's existing stack: Python/FastAPI, web scraping, browser automation, code generation, deployment
- MVP must be buildable in 2-4 weeks
- Must use Maya's existing tools (web search, browser, code gen, deployment)
- Owner approval required before any building starts
- Going live requires separate approval

TASK: Create a ONE-PAGE execution plan with these sections:
1. EXECUTIVE SUMMARY (2-3 sentences)
2. MVP SCOPE (3-5 bullet points - what to build in v1)
3. TECHNICAL APPROACH (how to build with Maya's tools)
4. TIMELINE (week-by-week for 2-4 weeks)
5. SUCCESS METRICS (how to measure v1 success)
6. RISKS & MITIGATIONS (top 3 risks)
7. APPROVAL CHECKPOINTS (what needs owner approval and when)

Return ONLY a JSON object with these fields:
{{
  "id": "auto-generated",
  "opportunity_id": "...",
  "title": "...",
  "executive_summary": "...",
  "mvp_scope": ["...", "..."],
  "technical_approach": "...",
  "timeline": [{{"week": 1, "focus": "..."}}, ...],
  "success_metrics": ["...", "..."],
  "risks": [{{"risk": "...", "mitigation": "..."}}],
  "approval_checkpoints": [{{"stage": "...", "description": "..."}}],
  "estimated_timeline_weeks": 2-4,
  "created_at": timestamp
}}

Be concise. No fluff.
"""
        
        try:
            response = self.llm_fn(prompt)
            
            # Extract JSON
            json_start = response.find("{")
            json_end = response.rfind("}") + 1
            if json_start == -1 or json_end == 0:
                return None
            
            plan = json.loads(response[json_start:json_end])
            plan["id"] = plan.get("id", uuid.uuid4().hex[:12])
            plan["opportunity_id"] = opportunity.get("id", "")
            plan["created_at"] = time.time()
            
            # Store plan
            await self._store_plan(plan)
            
            log.info(f"Drafted plan {plan['id']} for opportunity {opportunity.get('id')}")
            return plan
            
        except Exception as e:
            log.warning(f"Failed to draft plan: {e}")
            return None
    
    async def _store_plan(self, plan: Dict):
        """Store a plan in the database."""
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
            conn.execute("""
                INSERT OR REPLACE INTO plans 
                (id, opportunity_id, title, executive_summary, mvp_scope, technical_approach,
                 timeline, success_metrics, risks, approval_checkpoints, estimated_timeline_weeks,
                 status, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'draft', ?)
            """, (plan["id"], plan["opportunity_id"], plan.get("title", ""),
                  plan.get("executive_summary", ""), json.dumps(plan.get("mvp_scope", [])),
                  plan.get("technical_approach", ""), json.dumps(plan.get("timeline", [])),
                  json.dumps(plan.get("success_metrics", [])), json.dumps(plan.get("risks", [])),
                  json.dumps(plan.get("approval_checkpoints", [])), 
                  plan.get("estimated_timeline_weeks", 4),
                  plan["created_at"]))
    
    async def _queue_for_approval(self, plan: Dict):
        """Queue plan for owner approval via notification."""
        # In a full implementation, this would send to Telegram/WhatsApp/Email
        # For now, we update the plan status
        with get_income_conn() as conn:
            conn.execute("""
                UPDATE plans SET status = 'pending_approval' WHERE id = ?
            """, (plan["id"],))
        
        log.info(f"Plan {plan['id']} queued for owner approval")
        
        # Also update the opportunity status
        with get_income_conn() as conn:
            conn.execute("""
                UPDATE opportunities SET status = 'queued_for_strategist' 
                WHERE id = (SELECT opportunity_id FROM plans WHERE id = ?)
            """, (plan["id"],))


# ═════════════════════════════════════════════════════════════════════════════
# STRATEGIST MODULE SINGLETON
# ═════════════════════════════════════════════════════════════════════════════

_strategist_agent: Optional["StrategistAgent"] = None


def get_strategist_agent(llm_fn: Optional[Callable] = None) -> "StrategistAgent":
    global _strategist_agent
    if _strategist_agent is None:
        _strategist_agent = StrategistAgent(llm_fn)
    return _strategist_agent


def reset_strategist_agent():
    global _strategist_agent
    if _strategist_agent:
        asyncio.create_task(_strategist_agent.stop())
    _strategist_agent = None