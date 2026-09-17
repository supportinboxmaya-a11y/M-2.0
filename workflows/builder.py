"""
Maya 2.0 - Workflow Builder
---------------------------
Define multi-step workflows as data (JSON) instead of code, then run
them. Complements the existing WorkflowEngine (which needs Python
callables) by letting users build workflows through the API/UI.

A workflow = ordered steps, each with:
    id          unique within the workflow
    name        human label
    action      "prompt" (run text through Maya) | "tool" (call a tool)
    input       prompt text or tool input; supports {{step_id.output}}
                and {{input.field}} placeholders
    tool        tool name (for action="tool")
    depends_on  list of step ids that must finish first
    condition   optional: {"when": "{{step.output}}", "op": "contains",
                "value": "yes"} — step runs only if it evaluates true;
                otherwise it's skipped

Execution:
- Steps run in dependency order; independent steps at the same level
  run in parallel.
- Each step's output is captured and available to later steps via
  {{step_id.output}} templating.
- Conditions are evaluated against already-computed outputs, enabling
  if/then branching without code.

Storage: SQLite (WAL). Definitions are validated on save (unique ids,
no missing/cyclic dependencies, known actions).
"""

import asyncio
import json
import re
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from typing import Callable, Dict, List, Optional

from config.settings import STORAGE_DIR

WF_DIR = STORAGE_DIR / "workflows_def"
WF_DIR.mkdir(parents=True, exist_ok=True)
WF_DB = str(WF_DIR / "workflows.db")

_TMPL = re.compile(r"\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}")
_VALID_ACTIONS = {"prompt", "tool"}
_OPS = {"contains", "equals", "not_equals", "not_empty", "gt", "lt"}


class WorkflowValidationError(Exception):
    pass


class WorkflowBuilder:
    """Store, validate, and run declarative workflows."""

    def __init__(self, db_path: str = WF_DB, prompt_fn: Optional[Callable] = None,
                 tool_fn: Optional[Callable] = None):
        self.db = db_path
        self._lock = threading.Lock()
        # prompt_fn(text)->str runs text through Maya; tool_fn(name, input)->str
        self.prompt_fn = prompt_fn
        self.tool_fn = tool_fn
        self._init_db()

    def _init_db(self):
        with self._conn() as c:
            c.execute("""CREATE TABLE IF NOT EXISTS workflows (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT DEFAULT '',
                steps TEXT NOT NULL,
                created_at REAL,
                updated_at REAL,
                runs INTEGER DEFAULT 0
            )""")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.db, check_same_thread=False, timeout=10)
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

    # ── validation ────────────────────────────────────────────────
    @staticmethod
    def validate_steps(steps: List[Dict]) -> None:
        if not steps or not isinstance(steps, list):
            raise WorkflowValidationError("workflow must have a non-empty steps list")
        ids = [s.get("id") for s in steps]
        if any(not i for i in ids):
            raise WorkflowValidationError("every step needs an id")
        if len(set(ids)) != len(ids):
            raise WorkflowValidationError("step ids must be unique")
        idset = set(ids)
        for s in steps:
            action = s.get("action", "prompt")
            if action not in _VALID_ACTIONS:
                raise WorkflowValidationError(
                    f"step '{s['id']}': unknown action '{action}'")
            if action == "tool" and not s.get("tool"):
                raise WorkflowValidationError(
                    f"step '{s['id']}': tool action needs a 'tool' name")
            for dep in s.get("depends_on", []):
                if dep not in idset:
                    raise WorkflowValidationError(
                        f"step '{s['id']}' depends on unknown step '{dep}'")
            cond = s.get("condition")
            if cond:
                op = cond.get("op")
                if op not in _OPS:
                    raise WorkflowValidationError(
                        f"step '{s['id']}': unknown condition op '{op}'")
        WorkflowBuilder._check_acyclic(steps)

    @staticmethod
    def _check_acyclic(steps: List[Dict]) -> None:
        graph = {s["id"]: list(s.get("depends_on", [])) for s in steps}
        state = {}   # 0=unvisited,1=visiting,2=done

        def dfs(n):
            state[n] = 1
            for dep in graph.get(n, []):
                if state.get(dep) == 1:
                    raise WorkflowValidationError(
                        f"dependency cycle detected at step '{n}'")
                if state.get(dep, 0) == 0:
                    dfs(dep)
            state[n] = 2

        for node in graph:
            if state.get(node, 0) == 0:
                dfs(node)

    # ── CRUD ──────────────────────────────────────────────────────
    def create(self, name: str, steps: List[Dict], description: str = "") -> Dict:
        if not name:
            raise WorkflowValidationError("workflow name is required")
        self.validate_steps(steps)
        wid = uuid.uuid4().hex[:12]
        now = time.time()
        with self._lock, self._conn() as c:
            c.execute("INSERT INTO workflows "
                      "(id, name, description, steps, created_at, updated_at, runs) "
                      "VALUES (?,?,?,?,?,?,0)",
                      (wid, name, description, json.dumps(steps), now, now))
        return self.get(wid)

    def update(self, wid: str, name: Optional[str] = None,
               steps: Optional[List[Dict]] = None,
               description: Optional[str] = None) -> Optional[Dict]:
        cur = self.get(wid)
        if not cur:
            return None
        if steps is not None:
            self.validate_steps(steps)
        with self._lock, self._conn() as c:
            c.execute("UPDATE workflows SET name=?, description=?, steps=?, "
                      "updated_at=? WHERE id=?",
                      (name if name is not None else cur["name"],
                       description if description is not None else cur["description"],
                       json.dumps(steps) if steps is not None
                       else json.dumps(cur["steps"]),
                       time.time(), wid))
        return self.get(wid)

    def delete(self, wid: str) -> bool:
        with self._lock, self._conn() as c:
            return c.execute("DELETE FROM workflows WHERE id=?", (wid,)).rowcount > 0

    def get(self, wid: str) -> Optional[Dict]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM workflows WHERE id=?", (wid,)).fetchone()
        return self._row(row) if row else None

    def list(self) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute("SELECT * FROM workflows ORDER BY updated_at DESC").fetchall()
        return [self._row(r) for r in rows]

    # ── execution ─────────────────────────────────────────────────
    async def run(self, wid: str, inputs: Optional[Dict] = None) -> Dict:
        wf = self.get(wid)
        if not wf:
            raise WorkflowValidationError("workflow not found")
        steps = {s["id"]: s for s in wf["steps"]}
        outputs: Dict[str, str] = {}
        skipped: set = set()
        status: Dict[str, str] = {}
        inputs = inputs or {}

        # topological levels for parallel execution
        done: set = set()
        remaining = set(steps.keys())
        order_log: List[Dict] = []

        while remaining:
            ready = [sid for sid in remaining
                     if all(d in done for d in steps[sid].get("depends_on", []))]
            if not ready:
                # remaining steps are blocked (deps skipped/failed) → skip them
                for sid in list(remaining):
                    status[sid] = "skipped"
                    skipped.add(sid)
                    done.add(sid)
                    remaining.discard(sid)
                break

            async def _exec(sid):
                step = steps[sid]
                # dependency skipped → skip this step too
                if any(d in skipped for d in step.get("depends_on", [])):
                    status[sid] = "skipped"
                    skipped.add(sid)
                    return
                # condition gate
                cond = step.get("condition")
                if cond and not self._eval_condition(cond, outputs, inputs):
                    status[sid] = "skipped"
                    skipped.add(sid)
                    return
                rendered = self._render(step.get("input", ""), outputs, inputs)
                try:
                    out = await self._run_action(step, rendered)
                    outputs[sid] = out
                    status[sid] = "done"
                except Exception as e:
                    status[sid] = "failed"
                    outputs[sid] = f"[error] {e}"
                    skipped.add(sid)   # dependents skip

            await asyncio.gather(*[_exec(sid) for sid in ready])
            for sid in ready:
                done.add(sid)
                remaining.discard(sid)
                order_log.append({"step": sid, "status": status.get(sid, "done")})

        with self._lock, self._conn() as c:
            c.execute("UPDATE workflows SET runs=runs+1 WHERE id=?", (wid,))

        overall = "completed"
        if any(v == "failed" for v in status.values()):
            overall = "failed"
        return {"workflow": wid, "status": overall, "steps": order_log,
                "outputs": outputs,
                "skipped": sorted(skipped & set(steps))}

    async def _run_action(self, step: Dict, rendered_input: str) -> str:
        action = step.get("action", "prompt")
        if action == "prompt":
            if self.prompt_fn is None:
                return f"[no prompt_fn] would run: {rendered_input}"
            res = self.prompt_fn(rendered_input)
            if asyncio.iscoroutine(res):
                res = await res
            return str(res)
        if action == "tool":
            if self.tool_fn is None:
                return f"[no tool_fn] would call {step.get('tool')}: {rendered_input}"
            res = self.tool_fn(step["tool"], rendered_input)
            if asyncio.iscoroutine(res):
                res = await res
            return str(res)
        return ""

    # ── templating + conditions ───────────────────────────────────
    @staticmethod
    def _render(template: str, outputs: Dict, inputs: Dict) -> str:
        def resolve(path: str) -> str:
            parts = path.split(".")
            if parts[0] == "input":
                cur = inputs
                for p in parts[1:]:
                    if isinstance(cur, dict) and p in cur:
                        cur = cur[p]
                    else:
                        return ""
                return str(cur)
            # {{step_id.output}} or {{step_id}}
            sid = parts[0]
            if sid in outputs:
                return str(outputs[sid])
            return ""
        return _TMPL.sub(lambda m: resolve(m.group(1)), template or "")

    def _eval_condition(self, cond: Dict, outputs: Dict, inputs: Dict) -> bool:
        left = self._render(cond.get("when", ""), outputs, inputs)
        op = cond.get("op")
        val = str(cond.get("value", ""))
        if op == "not_empty":
            return bool(left.strip())
        if op == "contains":
            return val.lower() in left.lower()
        if op == "equals":
            return left.strip() == val
        if op == "not_equals":
            return left.strip() != val
        if op in ("gt", "lt"):
            try:
                lf, rf = float(left), float(val)
                return lf > rf if op == "gt" else lf < rf
            except ValueError:
                return False
        return False

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _row(row) -> Dict:
        return {"id": row["id"], "name": row["name"],
                "description": row["description"],
                "steps": json.loads(row["steps"]),
                "created_at": row["created_at"], "updated_at": row["updated_at"],
                "runs": row["runs"]}
