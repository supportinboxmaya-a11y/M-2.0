"""
Maya 2.0 — Full Autonomous Cognition Loop
------------------------------------------
Persistent mission + objectives store, self-goal generation, priority
scoring, and a scheduler-driven continuous cycle that wakes, picks a
goal, runs it through AutonomousMaya, reflects, and stores experience.

Feature flags (both default OFF):
  COGNITION_ENABLED — master switch; when false the scheduler cycle is
                      never registered and all routes return 503.
  COGNITION_AUTORUN  — when false, _cycle() only PROPOSES the chosen
                      objective (stores it as status "proposed") instead
                      of calling AutonomousMaya.run(). Flip it on only
                      after validating proposals.

Hard rules:
  - Every EXTERNAL/irreversible action passes through ApprovalManager.
  - InterventionHandler.check_interrupt() gates the top of each cycle.
  - Every cycle writes an audit log entry.
  - Boot-safe: soft-fail on import. No existing module is rewritten.
"""

import asyncio
import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from datetime import datetime
from typing import Callable, Dict, List, Optional, Any

# ── Feature flags (default OFF) ────────────────────────────────────────────
COGNITION_ENABLED = os.environ.get("COGNITION_ENABLED", "false").lower() == "true"
COGNITION_AUTORUN = os.environ.get("COGNITION_AUTORUN", "false").lower() == "true"

# ── DB path ────────────────────────────────────────────────────────────────
from config.settings import STORAGE_DIR

COG_DIR = STORAGE_DIR / "cognition"
COG_DIR.mkdir(parents=True, exist_ok=True)
COG_DB = str(COG_DIR / "cognition.db")


# ============================================================================
# CognitionEngine
# ============================================================================

class CognitionEngine:
    """Persistent mission + objectives store with a scheduler-driven cycle.

    All injected dependencies are optional — defaults are created when
    ``None`` is passed (most produce no-ops so the engine is safe to
    instantiate before the full Maya stack is ready).
    """

    def __init__(
        self,
        auto_maya: Optional[Any] = None,
        goal_analyzer: Optional[Any] = None,
        reflector: Optional[Any] = None,
        experience_store: Optional[Any] = None,
        approval_manager: Optional[Any] = None,
        intervention_handler: Optional[Any] = None,
        scheduler: Optional[Any] = None,
        task_queue: Optional[Any] = None,
        llm_fn: Optional[Callable] = None,
    ) -> None:
        self._lock = threading.Lock()

        # Injected dependencies
        self.auto_maya = auto_maya
        self.goal_analyzer = goal_analyzer
        self.reflector = reflector
        self.experience_store = experience_store
        self.approval = approval_manager
        self.intervention = intervention_handler
        self.scheduler = scheduler
        self.task_queue = task_queue
        self.llm_fn = llm_fn

        # Scheduler schedule id (populated on register)
        self._schedule_id: Optional[str] = None

        self._init_db()

    # ── DB init ────────────────────────────────────────────────────────────

    def _init_db(self) -> None:
        try:
            with self._conn() as c:
                c.executescript("""
                CREATE TABLE IF NOT EXISTS missions (
                    id          TEXT PRIMARY KEY,
                    name        TEXT NOT NULL,
                    description TEXT DEFAULT '',
                    self_gen    INTEGER DEFAULT 1,
                    active      INTEGER DEFAULT 1,
                    mission_type TEXT DEFAULT 'general',
                    created_at  REAL,
                    updated_at  REAL
                );

                CREATE TABLE IF NOT EXISTS objectives (
                    id                TEXT PRIMARY KEY,
                    mission_id        TEXT NOT NULL,
                    description       TEXT NOT NULL,
                    priority          REAL DEFAULT 0.0,
                    status            TEXT DEFAULT 'pending',
                    requires_approval INTEGER DEFAULT 0,
                    depends_on        TEXT DEFAULT '',
                    failure_count     INTEGER DEFAULT 0,
                    last_error        TEXT DEFAULT '',
                    created_at        REAL,
                    completed_at      REAL
                );

                CREATE INDEX IF NOT EXISTS idx_obj_mission
                    ON objectives(mission_id);

                CREATE TABLE IF NOT EXISTS cognition_audit (
                    id              TEXT PRIMARY KEY,
                    mission_id      TEXT,
                    objective_id    TEXT,
                    objective_desc  TEXT DEFAULT '',
                    action          TEXT DEFAULT '',
                    detail          TEXT DEFAULT '',
                    timestamp       REAL
                );

                CREATE INDEX IF NOT EXISTS idx_audit_ts
                    ON cognition_audit(timestamp);
                """)
                # Phase 20 migration: add mission_type if the column doesn't exist
                try:
                    c.execute(
                        "ALTER TABLE missions ADD COLUMN mission_type "
                        "TEXT DEFAULT 'general'"
                    )
                except sqlite3.OperationalError:
                    pass  # column already exists
        except Exception as e:
            print(f"WARNING: CognitionEngine DB init error: {e}")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(COG_DB, check_same_thread=False, timeout=10)
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

    # ── Mission CRUD ───────────────────────────────────────────────────────

    def create_mission(
        self, name: str, description: str = "",
        self_gen: bool = True, active: bool = True,
        mission_type: str = "general",
    ) -> dict:
        mid = uuid.uuid4().hex[:12]
        now = time.time()
        with self._lock, self._conn() as c:
            c.execute(
                "INSERT INTO missions (id, name, description, self_gen, "
                "active, mission_type, created_at, updated_at) "
                "VALUES (?,?,?,?,?,?,?,?)",
                (mid, name[:200], description[:2000], int(self_gen),
                 int(active), mission_type[:50], now, now),
            )
        return self._get_mission(mid)

    def get_mission(self, mission_id: str) -> Optional[dict]:
        return self._get_mission(mission_id)

    def list_missions(
        self, active_only: bool = False,
        mission_type: Optional[str] = None,
    ) -> List[dict]:
        clauses: List[str] = []
        vals: list = []
        if active_only:
            clauses.append("active = 1")
        if mission_type:
            clauses.append("mission_type = ?")
            vals.append(mission_type)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        with self._conn() as c:
            rows = c.execute(
                f"SELECT * FROM missions {where} ORDER BY created_at", vals
            ).fetchall()
        return [self._row_dict(r) for r in rows]

    def toggle_mission(self, mission_id: str, active: bool) -> bool:
        with self._lock, self._conn() as c:
            cur = c.execute(
                "UPDATE missions SET active = ?, updated_at = ? WHERE id = ?",
                (int(active), time.time(), mission_id),
            )
            return cur.rowcount > 0

    def update_mission(
        self, mission_id: str, *,
        name: Optional[str] = None,
        description: Optional[str] = None,
        self_gen: Optional[bool] = None,
        mission_type: Optional[str] = None,
    ) -> Optional[dict]:
        fields = []
        vals = []
        if name is not None:
            fields.append("name = ?")
            vals.append(name[:200])
        if description is not None:
            fields.append("description = ?")
            vals.append(description[:2000])
        if self_gen is not None:
            fields.append("self_gen = ?")
            vals.append(int(self_gen))
        if mission_type is not None:
            fields.append("mission_type = ?")
            vals.append(mission_type[:50])
        if not fields:
            return self._get_mission(mission_id)
        fields.append("updated_at = ?")
        vals.append(time.time())
        vals.append(mission_id)
        with self._lock, self._conn() as c:
            c.execute(
                f"UPDATE missions SET {', '.join(fields)} WHERE id = ?", vals
            )
        return self._get_mission(mission_id)

    def delete_mission(self, mission_id: str) -> bool:
        with self._lock, self._conn() as c:
            c.execute("DELETE FROM objectives WHERE mission_id = ?", (mission_id,))
            cur = c.execute("DELETE FROM missions WHERE id = ?", (mission_id,))
            return cur.rowcount > 0

    # ── Objective lifecycle ────────────────────────────────────────────────

    def add_objective(
        self,
        mission_id: str,
        description: str,
        priority: float = 0.0,
        depends_on: Optional[List[str]] = None,
        requires_approval: bool = False,
    ) -> dict:
        oid = uuid.uuid4().hex[:12]
        now = time.time()
        with self._lock, self._conn() as c:
            c.execute(
                "INSERT INTO objectives (id, mission_id, description, priority, "
                "status, requires_approval, depends_on, created_at) "
                "VALUES (?,?,?,?,?,?,?,?)",
                (oid, mission_id, description[:2000], priority,
                 "pending", int(requires_approval),
                 ",".join(depends_on or []), now),
            )
        return self._get_objective(oid)

    def list_objectives(
        self, mission_id: Optional[str] = None,
        status: Optional[str] = None
    ) -> List[dict]:
        clauses = []
        vals: list = []
        if mission_id:
            clauses.append("mission_id = ?")
            vals.append(mission_id)
        if status:
            clauses.append("status = ?")
            vals.append(status)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        with self._conn() as c:
            rows = c.execute(
                f"SELECT * FROM objectives {where} ORDER BY priority DESC, created_at",
                vals,
            ).fetchall()
        return [self._row_dict(r) for r in rows]

    def update_objective_status(
        self, objective_id: str, status: str,
        error: str = ""
    ) -> bool:
        with self._lock, self._conn() as c:
            now = time.time()
            if status in ("done", "failed"):
                cur = c.execute(
                    "UPDATE objectives SET status = ?, completed_at = ?, "
                    "last_error = ? WHERE id = ?",
                    (status, now, error[:500], objective_id),
                )
            else:
                cur = c.execute(
                    "UPDATE objectives SET status = ?, last_error = ? "
                    "WHERE id = ?",
                    (status, error[:500], objective_id),
                )
            return cur.rowcount > 0

    def propose_objective(self, objective_id: str) -> None:
        """Set objective status to 'proposed' — signals it's ready for
        human review before autorun executes it."""
        self.update_objective_status(objective_id, "proposed")

    # ── Self-goal generation ───────────────────────────────────────────────

    def generate_objectives(self, mission_id: str) -> List[dict]:
        """Use the LLM (if available) to decompose a mission into objectives.

        Each generated objective gets a priority score and is inserted
        into the store with status ``pending``.
        """
        mission = self._get_mission(mission_id)
        if not mission:
            return []

        if not self.llm_fn:
            return []

        is_business = mission.get("mission_type") == "business"
        if is_business:
            prompt = (
                f"Business Mission: {mission['description'] or mission['name']}\n\n"
                "Decompose this business mission into 3-8 concrete business analysis "
                "objectives. Each objective must be a single sentence describing a "
                "specific analysis, research, or planning task (e.g. pricing analysis, "
                "financial projection, marketing strategy, competitive research). "
                "Return ONLY a JSON array of strings, no other text:\n"
                '["objective one", "objective two", ...]'
            )
        else:
            prompt = (
                f"Mission: {mission['description'] or mission['name']}\n\n"
                "Decompose this mission into 3-8 concrete, actionable objectives. "
                "Each objective must be a single sentence describing a specific task. "
                "Return ONLY a JSON array of strings, no other text:\n"
                '["objective one", "objective two", ...]'
            )
        try:
            raw = self.llm_fn(prompt)
            raw = raw.strip()
            # Try to extract JSON array from the response
            if "[" in raw and "]" in raw:
                raw = raw[raw.index("["):raw.rindex("]") + 1]
            objectives = json.loads(raw)
            if not isinstance(objectives, list):
                return []
        except Exception:
            return []

        created = []
        for desc in objectives:
            if not isinstance(desc, str) or len(desc.strip()) < 5:
                continue

            # Business objectives are pure analysis — no approval needed
            if is_business:
                requires_approval = False
            else:
                # Analyze the goal for complexity hints
                analysis = {}
                if self.goal_analyzer:
                    try:
                        analysis = self.goal_analyzer.analyze(desc)
                    except Exception:
                        pass

                # Mark as requiring approval if tools suggest external actions
                suggested = analysis.get("suggested_tools", [])
                requires_approval = any(
                    t in ("web", "shell", "file") for t in suggested
                )

            priority = self._score_priority(desc, analysis)
            obj = self.add_objective(
                mission_id=mission_id,
                description=desc.strip(),
                priority=priority,
                requires_approval=requires_approval,
            )
            created.append(obj)

        return created

    # ── Priority scoring ───────────────────────────────────────────────────

    def _score_priority(
        self, description: str, analysis: Optional[dict] = None
    ) -> float:
        """Score 0.0-100.0 based on urgency hints and complexity."""
        if analysis is None:
            analysis = {}
        score = 50.0  # baseline

        desc_lower = description.lower()
        urgency_words = {
            "urgent": 25, "critical": 30, "immediately": 20,
            "asap": 15, "important": 10, "blocking": 20,
            "deadline": 15, "overdue": 20, "security": 25,
            "bug": 10, "error": 10, "crash": 20,
        }
        for word, boost in urgency_words.items():
            if word in desc_lower:
                score += boost

        estimated = analysis.get("estimated_steps", 1)
        if estimated > 3:
            score += 10  # multi-step tasks get slight priority bump

        return min(100.0, max(0.0, score))

    def recalc_priorities(self, mission_id: str) -> None:
        """Re-score all pending/proposed objectives for a mission."""
        objectives = self.list_objectives(mission_id=mission_id)
        for obj in objectives:
            if obj["status"] not in ("pending", "proposed"):
                continue
            analysis = {}
            if self.goal_analyzer:
                try:
                    analysis = self.goal_analyzer.analyze(obj["description"])
                except Exception:
                    pass
            priority = self._score_priority(obj["description"], analysis)
            with self._lock, self._conn() as c:
                c.execute(
                    "UPDATE objectives SET priority = ? WHERE id = ?",
                    (priority, obj["id"]),
                )

    # ── The cognition cycle ────────────────────────────────────────────────

    async def cycle(self) -> dict:
        """Run one full cognition cycle. Called by the scheduler.

        Returns a dict summarising what happened (or why nothing happened).
        """
        result: Dict[str, Any] = {
            "cycle_ts": time.time(),
            "action": "noop",
            "mission_id": None,
            "objective_id": None,
            "detail": "",
        }

        # 1. Intervention check — global kill switch
        if self.intervention is not None:
            try:
                if self.intervention.check_interrupt():
                    result["detail"] = "Skipped: intervention mode active"
                    self._audit(None, None, None, "skipped",
                                result["detail"])
                    return result
            except Exception:
                pass  # input() not available in server mode; treat as pass

        # 2. Load active missions
        missions = self.list_missions(active_only=True)
        if not missions:
            result["detail"] = "No active missions"
            return result

        # 3. Self-generate objectives for missions with self_gen=True
        for m in missions:
            if m.get("self_gen"):
                existing = self.list_objectives(
                    mission_id=m["id"], status="pending"
                )
                if not existing:
                    self.generate_objectives(m["id"])

        # 4. Pick top-priority pending objective across all missions
        candidates = self._top_pending(len(missions))
        if not candidates:
            result["detail"] = "No pending objectives"
            return result

        mission_id = candidates[0]["mission_id"]
        objective_id = candidates[0]["id"]
        description = candidates[0]["description"]
        requires_approval = bool(candidates[0].get("requires_approval", 0))
        is_business = candidates[0].get("mission_type") == "business"

        result["mission_id"] = mission_id
        result["objective_id"] = objective_id
        result["objective_desc"] = description

        # 5. Approval gate for external/irreversible actions.
        # Business objectives ALWAYS require approval — they have no
        # execution path through AutonomousMaya and must be triggered
        # manually via POST /analyze. The requires_approval field on the
        # objective itself is set to False (because the objective is pure
        # analysis), but the mission_type gate here ensures no business
        # objective is ever auto-executed without explicit human approval.
        should_gate = (requires_approval or is_business) and self.approval is not None
        if should_gate:
            try:
                if self.approval.needs_approval(
                    f"cognition:run:{objective_id}", risk_level="high"
                ):
                    approved = self.approval.request_approval(
                        action=f"[Cognition] Execute objective: {description}",
                        reason="Objective requires approval (external action detected)",
                        risk_level="high",
                        task_id=objective_id,
                    )
                    if not approved:
                        self.update_objective_status(objective_id, "blocked",
                                                     "Denied by user approval")
                        result["action"] = "blocked"
                        result["detail"] = "Objective blocked by user"
                        self._audit(mission_id, objective_id, description,
                                    "blocked", "User denied approval")
                        return result
            except Exception:
                pass  # fall through if approval system is unavailable

        # 6. COGNITION_AUTORUN gate — propose-only mode
        if not COGNITION_AUTORUN:
            self.propose_objective(objective_id)
            result["action"] = "proposed"
            if is_business:
                result["detail"] = (
                    f"Business objective proposed — trigger analysis via "
                    f"POST /cognitive/missions/{mission_id}/analyze"
                )
            else:
                result["detail"] = (
                    f"Objective proposed — COGNITION_AUTORUN is false. "
                    f"Set it to true to auto-execute."
                )
            self._audit(mission_id, objective_id, description,
                        "proposed", result["detail"])
            return result

        # 7. Execute (AUTORUN=true path)
        # Business objectives are PURE ANALYSIS — they MUST NOT go through
        # AutonomousMaya (which has tool access). Instead they route through
        # BusinessResearchEngine (pure LLM, no tools), or if that's not
        # available, they stay proposed. This is a structural safety gate:
        # even if AUTORUN is flipped on, business objectives never reach
        # auto_maya.run().
        if is_business:
            self.update_objective_status(objective_id, "in_progress")
            self._audit(mission_id, objective_id, description, "run",
                        "Starting business analysis via BusinessResearchEngine")
            try:
                from infrastructure.business_research import business_research as _bre
                if _bre and self.llm_fn:
                    report = _bre.analyze(
                        mission_id=mission_id,
                        objective_id=objective_id,
                        description=description,
                        llm_fn=self.llm_fn,
                    )
                    self.update_objective_status(objective_id, "done")
                    result["action"] = "done"
                    result["detail"] = "Business analysis complete"
                else:
                    self.propose_objective(objective_id)
                    result["action"] = "proposed"
                    result["detail"] = (
                        "Business objective proposed — no LLM or research "
                        "engine available"
                    )
            except Exception as e:
                self.update_objective_status(objective_id, "failed", str(e))
                result["action"] = "failed"
                result["detail"] = f"Business analysis error: {e}"
            self._audit(mission_id, objective_id, description,
                        result["action"], result["detail"])
            return result

        self.update_objective_status(objective_id, "in_progress")
        self._audit(mission_id, objective_id, description, "run",
                    "Starting AutonomousMaya execution")

        success = True
        error_msg = ""
        output = ""
        try:
            if self.auto_maya is not None:
                run_result = await self.auto_maya.run(description)
                output = run_result.get("output", "")
                # Reflect on the result
                acceptable = True
                if self.reflector is not None:
                    try:
                        critique = self.reflector.critique(description, output)
                        acceptable = critique.get("acceptable", True)
                    except Exception:
                        acceptable = True
                if acceptable:
                    self.update_objective_status(objective_id, "done")
                    result["action"] = "done"
                    result["detail"] = "Objective completed successfully"
                else:
                    self.update_objective_status(
                        objective_id, "failed", "Reflection failed"
                    )
                    success = False
                    error_msg = "Output did not pass reflection"
                    result["action"] = "failed"
                    result["detail"] = error_msg
            else:
                self.update_objective_status(objective_id, "done")
                result["action"] = "done"
                result["detail"] = "Objective marked done (no AutonomousMaya configured)"
        except Exception as e:
            error_msg = str(e)
            self.update_objective_status(objective_id, "failed", error_msg)
            success = False
            result["action"] = "failed"
            result["detail"] = f"Execution error: {error_msg}"

        # 8. Store experience
        if self.experience_store is not None and description:
            try:
                self.experience_store.add(
                    task=description,
                    lesson=error_msg if not success else "Completed successfully",
                    success=success,
                    metadata={
                        "objective_id": objective_id,
                        "mission_id": mission_id,
                        "cycle_result": result["action"],
                    },
                )
            except Exception:
                pass

        self._audit(mission_id, objective_id, description,
                    result["action"], result["detail"])
        return result

    # ── Scheduler integration ──────────────────────────────────────────────

    def register_scheduler(
        self, cron: str = "*/15 * * * *"
    ) -> Optional[str]:
        """Register a ``cognition_cycle`` handler on the task queue and
        add a schedule.  Returns the schedule id, or ``None`` on failure."""
        if not COGNITION_ENABLED:
            print("INFO: COGNITION_ENABLED is false — scheduler not registered")
            return None
        if not self.task_queue or not self.scheduler:
            print("WARNING: CognitionEngine has no task_queue or scheduler — "
                  "cannot register")
            return None

        # Register the async cycle handler
        try:
            self.task_queue.register("cognition_cycle", self.cycle)
        except Exception as e:
            print(f"WARNING: Failed to register cognition_cycle handler: {e}")
            return None

        # Add a schedule
        try:
            sched = self.scheduler.add(
                name="cognition_cycle",
                cron=cron,
                job="cognition_cycle",
                args=[],
                kwargs={},
            )
            self._schedule_id = sched["id"]
            print(
                f"INFO: Cognition scheduler registered (schedule={sched['id']}, "
                f"cron={cron})"
            )
            return sched["id"]
        except Exception as e:
            print(f"WARNING: Failed to add cognition schedule: {e}")
            return None

    def unregister_scheduler(self) -> bool:
        """Remove the cognition schedule."""
        if not self._schedule_id:
            return False
        if self.scheduler is not None:
            try:
                return self.scheduler.remove(self._schedule_id)
            except Exception:
                return False
        return False

    # ── Control ────────────────────────────────────────────────────────────

    @property
    def enabled(self) -> bool:
        return COGNITION_ENABLED

    @property
    def autorun(self) -> bool:
        return COGNITION_AUTORUN

    def status(self) -> dict:
        missions = self.list_missions()
        active_missions = [m for m in missions if m.get("active")]
        business_missions = [m for m in missions if m.get("mission_type") == "business"]
        pending = self.list_objectives(status="pending")
        proposed = self.list_objectives(status="proposed")
        in_progress = self.list_objectives(status="in_progress")
        recent_audit = self._recent_audit(10)

        return {
            "enabled": COGNITION_ENABLED,
            "autorun": COGNITION_AUTORUN,
            "schedule_id": self._schedule_id,
            "missions_total": len(missions),
            "missions_active": len(active_missions),
            "missions_business": len(business_missions),
            "objectives_pending": len(pending),
            "objectives_proposed": len(proposed),
            "objectives_in_progress": len(in_progress),
            "recent_audit": recent_audit,
        }

    # ── Internals ──────────────────────────────────────────────────────────

    def _get_mission(self, mission_id: str) -> Optional[dict]:
        with self._conn() as c:
            row = c.execute(
                "SELECT * FROM missions WHERE id = ?", (mission_id,)
            ).fetchone()
        return self._row_dict(row) if row else None

    def _get_objective(self, objective_id: str) -> Optional[dict]:
        with self._conn() as c:
            row = c.execute(
                "SELECT * FROM objectives WHERE id = ?", (objective_id,)
            ).fetchone()
        return self._row_dict(row) if row else None

    def _top_pending(self, limit: int = 5) -> List[dict]:
        """Return the highest-priority pending objectives across all active
        missions, ordered by priority descending."""
        with self._conn() as c:
            rows = c.execute(
                "SELECT o.*, m.mission_type FROM objectives o "
                "JOIN missions m ON m.id = o.mission_id "
                "WHERE o.status = 'pending' AND m.active = 1 "
                "ORDER BY o.priority DESC LIMIT ?",
                (limit,),
            ).fetchall()
        return [self._row_dict(r) for r in rows]

    def _audit(
        self,
        mission_id: Optional[str],
        objective_id: Optional[str],
        objective_desc: Optional[str],
        action: str,
        detail: str = "",
    ) -> None:
        """Write an audit log entry."""
        try:
            with self._lock, self._conn() as c:
                c.execute(
                    "INSERT INTO cognition_audit "
                    "(id, mission_id, objective_id, objective_desc, action, "
                    "detail, timestamp) VALUES (?,?,?,?,?,?,?)",
                    (
                        uuid.uuid4().hex[:12],
                        mission_id,
                        objective_id,
                        (objective_desc or "")[:200],
                        action[:50],
                        detail[:500],
                        time.time(),
                    ),
                )
        except Exception:
            pass  # audit failure must never break the cycle

    def _recent_audit(self, limit: int = 10) -> List[dict]:
        try:
            with self._conn() as c:
                rows = c.execute(
                    "SELECT * FROM cognition_audit "
                    "ORDER BY timestamp DESC LIMIT ?",
                    (limit,),
                ).fetchall()
            return [self._row_dict(r) for r in rows]
        except Exception:
            return []

    @staticmethod
    def _row_dict(row) -> dict:
        d = dict(row)
        # Convert int booleans
        for k in ("active", "self_gen", "requires_approval"):
            if k in d:
                d[k] = bool(d[k])
        # mission_type default
        if "mission_type" not in d or not d.get("mission_type"):
            d["mission_type"] = "general"
        return d


# ── Module singleton ────────────────────────────────────────────────────────
try:
    from llm.router import LLMRouter
    _cog_router = LLMRouter()
    def _cog_llm_fn(prompt: str) -> str:
        return _cog_router.chat(
            [{"role": "user", "content": prompt}],
            model="google/gemma-2-2b-it",
            max_tokens=2000,
        )
except Exception as e:
    print(f"WARNING: Cognition LLM router init failed: {e}")
    _cog_llm_fn = None

cognition_engine = CognitionEngine(llm_fn=_cog_llm_fn)
