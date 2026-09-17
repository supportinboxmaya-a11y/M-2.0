"""
Maya 2.0 — Business Research Engine (Phase 20)

Pure-LLM business analysis on top of the cognition loop. Takes a business
objective and runs it through four specialist agents (pricing, finance,
marketing, strategy) via llm_fn. Results are stored as reports — no side
effects, no tool execution, no SSH/docker/payment/publish paths.

Output is always plans / proposals only.
"""

import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from typing import Callable, Dict, List, Optional, Any

from config.settings import STORAGE_DIR

BUSINESS_DIR = STORAGE_DIR / "business"
BUSINESS_DIR.mkdir(parents=True, exist_ok=True)
BUSINESS_DB = str(BUSINESS_DIR / "business_reports.db")


# Agent prompts — these are what each specialist agent sees.
# Pure LLM reasoning, zero tool permissions.
_AGENT_PROMPTS: Dict[str, str] = {
    "pricing": (
        "You are Maya's Pricing Agent. You recommend pricing models, "
        "subscription tiers, licensing structures, and revenue strategies. "
        "Your output must be a concrete, detailed proposal with rationale. "
        "Analyze the business objective below and produce your recommendation."
    ),
    "finance": (
        "You are Maya's Finance Agent. You provide financial analysis, "
        "budget forecasts, cashflow projections, cost estimates, and "
        "profitability assessments. Base your recommendations on the "
        "objective description below. Include numbers where possible."
    ),
    "marketing": (
        "You are Maya's Marketing Agent. You design campaign strategies, "
        "content plans, SEO approaches, social media tactics, and growth "
        "recommendations. Your output must be a concrete, actionable proposal."
    ),
    "strategy": (
        "You are Maya's Strategy Agent. You formulate strategic roadmaps, "
        "competitive analyses (SWOT), positioning recommendations, and "
        "long-term plans. Base your analysis on the objective below and "
        "produce a clear strategic proposal."
    ),
}


class BusinessResearchEngine:
    """Pure-LLM business analysis engine.

    Takes a business objective, runs it through four specialist agents
    (pricing → finance → marketing → strategy) via ``llm_fn``, bundles
    the results into a report, and stores it in the business_reports DB.
    Zero side effects — only reads the description and calls ``llm_fn``.
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._init_db()

    # ── DB init ────────────────────────────────────────────────────────────

    def _init_db(self) -> None:
        try:
            with self._conn() as c:
                c.executescript("""
                CREATE TABLE IF NOT EXISTS business_reports (
                    id              TEXT PRIMARY KEY,
                    mission_id      TEXT NOT NULL,
                    objective_id    TEXT NOT NULL,
                    objective_desc  TEXT NOT NULL,
                    agent_responses TEXT NOT NULL,
                    combined_summary TEXT DEFAULT '',
                    created_at      REAL
                );

                CREATE INDEX IF NOT EXISTS idx_biz_report_mission
                    ON business_reports(mission_id);

                CREATE INDEX IF NOT EXISTS idx_biz_report_obj
                    ON business_reports(objective_id);
                """)
        except Exception as e:
            print(f"WARNING: BusinessResearchEngine DB init error: {e}")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(BUSINESS_DB, check_same_thread=False, timeout=10)
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

    # ── Analysis ──────────────────────────────────────────────────────────

    def analyze(
        self,
        mission_id: str,
        objective_id: str,
        description: str,
        llm_fn: Optional[Callable[[str], str]] = None,
    ) -> Dict[str, Any]:
        """Run *description* through all four business agents.

        Returns a report dict with per-agent responses and a combined summary.
        If ``llm_fn`` is ``None``, returns an error report instead.
        """
        if not llm_fn:
            return {"error": "No LLM function available — cannot analyze"}

        agent_responses: Dict[str, str] = {}

        # Run each agent in order: pricing → finance → marketing → strategy
        agents_to_run = ["pricing", "finance", "marketing", "strategy"]
        for name in agents_to_run:
            prompt = _AGENT_PROMPTS.get(name, "")
            if not prompt:
                continue
            full_prompt = (
                f"{prompt}\n\n"
                f"--- Business Objective ---\n"
                f"{description}\n\n"
                f"--- Your Recommendation ---\n"
            )
            try:
                response = llm_fn(full_prompt)
                agent_responses[name] = response.strip()
            except Exception as e:
                agent_responses[name] = f"[Analysis error: {e}]"

        # Generate a combined executive summary
        combined = self._build_summary(description, agent_responses, llm_fn)

        report = {
            "id": uuid.uuid4().hex[:12],
            "mission_id": mission_id,
            "objective_id": objective_id,
            "objective_desc": description,
            "agent_responses": agent_responses,
            "combined_summary": combined,
            "created_at": time.time(),
        }

        self._save_report(report)
        return report

    # ── Summary generation ────────────────────────────────────────────────

    def _build_summary(
        self,
        description: str,
        agent_responses: Dict[str, str],
        llm_fn: Callable[[str], str],
    ) -> str:
        """Ask the LLM to condense all four agent responses into a single
        executive summary."""
        parts = []
        for name, resp in agent_responses.items():
            parts.append(f"=== {name.capitalize()} ===\n{resp}\n")
        prompt = (
            f"You are Maya's Business Strategy Summarizer. Your job is to "
            f"condense the following four specialist analyses into a single "
            f"concise executive summary (3-5 paragraphs) highlighting key "
            f"recommendations, trade-offs, and actionable next steps.\n\n"
            f"--- Original Objective ---\n{description}\n\n"
            f"--- Specialist Analyses ---\n"
            f"{''.join(parts)}\n\n"
            f"--- Executive Summary ---\n"
        )
        try:
            return llm_fn(prompt).strip()
        except Exception:
            return "Summary generation failed."

    # ── Persistence ───────────────────────────────────────────────────────

    def _save_report(self, report: Dict[str, Any]) -> None:
        try:
            with self._lock, self._conn() as c:
                c.execute(
                    "INSERT INTO business_reports "
                    "(id, mission_id, objective_id, objective_desc, "
                    "agent_responses, combined_summary, created_at) "
                    "VALUES (?,?,?,?,?,?,?)",
                    (
                        report["id"],
                        report["mission_id"],
                        report["objective_id"],
                        report["objective_desc"][:2000],
                        json.dumps(report["agent_responses"]),
                        report["combined_summary"][:5000],
                        report["created_at"],
                    ),
                )
        except Exception as e:
            print(f"WARNING: Failed to save business report: {e}")

    # ── Query ─────────────────────────────────────────────────────────────

    def list_reports(
        self, mission_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """List all reports, newest first. Optionally filter by mission."""
        clauses: List[str] = []
        vals: list = []
        if mission_id:
            clauses.append("mission_id = ?")
            vals.append(mission_id)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        try:
            with self._conn() as c:
                rows = c.execute(
                    f"SELECT id, mission_id, objective_id, objective_desc, "
                    f"combined_summary, created_at "
                    f"FROM business_reports {where} "
                    f"ORDER BY created_at DESC",
                    vals,
                ).fetchall()
            return [dict(r) for r in rows]
        except Exception:
            return []

    def get_report(self, report_id: str) -> Optional[Dict[str, Any]]:
        """Get a single report with full agent responses."""
        try:
            with self._conn() as c:
                row = c.execute(
                    "SELECT * FROM business_reports WHERE id = ?",
                    (report_id,),
                ).fetchone()
            if not row:
                return None
            d = dict(row)
            # Deserialize JSON agent_responses
            if isinstance(d.get("agent_responses"), str):
                try:
                    d["agent_responses"] = json.loads(d["agent_responses"])
                except (json.JSONDecodeError, TypeError):
                    pass
            return d
        except Exception:
            return None


# ── Module singleton ────────────────────────────────────────────────────────
business_research = BusinessResearchEngine()
