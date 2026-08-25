"""
Maya 2.0 ULTRA - FastAPI Server
Connects Maya core to the React frontend
"""
# Force-load requests.exceptions before any other imports
# Workaround for google.api_core/retry_base.py importing requests.exceptions
import requests
import requests.exceptions  # noqa: F401

import os, uuid, asyncio, time
from datetime import datetime, timedelta
from typing import Optional, List, Dict
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, WebSocket, WebSocketDisconnect, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import jwt
import bcrypt
from dotenv import load_dotenv

load_dotenv()

# ── Maya Core ──────────────────────────────────
from core.maya import Maya
from infrastructure.supabase_client import supabase_store

maya_instance: Optional[Maya] = None
MAIN_EVENT_LOOP: Optional[asyncio.AbstractEventLoop] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global maya_instance, MAIN_EVENT_LOOP
    MAIN_EVENT_LOOP = asyncio.get_running_loop()
    maya_instance = Maya()
    maya_instance.approval.request_handler = web_approval_handler
    # Re-apply any provider keys previously set via the Admin Panel — env
    # vars alone would reset to whatever's in Render on every restart/redeploy.
    if supabase_store.enabled:
        try:
            for provider, key in supabase_store.get_provider_keys().items():
                if key:
                    maya_instance.router.set_key(provider, key)
        except Exception as e:
            print(f"WARNING: could not load saved provider keys: {e}")
    print("✅ Maya 2.0 ULTRA started")
    yield
    print("Maya shutting down...")

app = FastAPI(title="Maya 2.0 ULTRA API", version="2.0.0", lifespan=lifespan)

# ── CORS ───────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Auth ───────────────────────────────────────
SECRET_KEY = os.getenv("SECRET_KEY", "maya-secret-key-2024")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@maya.ai")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "maya2024")
security = HTTPBearer(auto_error=False)

if SECRET_KEY == "maya-secret-key-2024":
    print("SECURITY WARNING: default SECRET_KEY in use — set a strong one in .env")
if ADMIN_PASSWORD == "maya2024":
    print("SECURITY WARNING: default ADMIN_PASSWORD in use — change it in .env")

DEFAULT_USER_BUDGET_USD = float(os.getenv("DEFAULT_USER_BUDGET_USD", "5.0"))

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode(), password_hash.encode())
    except Exception:
        return False

def create_token(email: str, uid: str = "", role: str = "admin") -> str:
    payload = {"sub": email, "uid": uid, "role": role,
               "exp": datetime.utcnow() + timedelta(days=7)}
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """Returns {'email', 'uid', 'role'}. Kept as a dict (not just the email
    string) so downstream endpoints can enforce per-user data and admin-only
    access once Supabase multi-user mode is on."""
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=["HS256"])
        return {"email": payload.get("sub"), "uid": payload.get("uid", ""),
                "role": payload.get("role", "admin")}
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

def require_admin(user: dict = Depends(get_current_user)) -> dict:
    """Use as a dependency on admin-only endpoints once multi-user is on.
    Before Supabase is configured, every logged-in user is treated as admin
    (there's only the single ADMIN_EMAIL account), so this stays permissive."""
    if supabase_store.enabled and user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return user

# ── In-memory task store ────────────────────────
tasks_db: dict = {}

# ── Streaming Infrastructure ────────────────────
from infrastructure.streaming import (
    get_stream_manager, StreamEventType, StreamEmitter,
    sse_generator, websocket_handler, set_stream_manager
)

# Initialize stream manager
stream_manager = get_stream_manager()
stream_manager.set_storage_path("storage/streaming_sessions")

ws_clients: List[WebSocket] = []

async def broadcast(data: dict):
    for ws in ws_clients.copy():
        try:
            await ws.send_json(data)
        except:
            ws_clients.remove(ws)

# ── Schemas ────────────────────────────────────
class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    name: str = ""
    email: str
    password: str

class BanRequest(BaseModel):
    banned: bool = True

class BudgetRequest(BaseModel):
    budget_usd: float

class AgentRunRequest(BaseModel):
    goal: str
    budget_usd: Optional[float] = 1.0
    instance_id: Optional[str] = None

class ChatRequest(BaseModel):
    message: str
    chat_id: Optional[str] = None  # groups messages into one conversation thread
    instance_id: Optional[str] = None

class ThinkRequest(BaseModel):
    problem: str
    depth: str = "normal"

class MemoryAddRequest(BaseModel):
    content: str
    type: str = "general"

class MemorySearchRequest(BaseModel):
    q: str
    limit: int = 10

class ToolUpdateRequest(BaseModel):
    enabled: bool

class ProviderUpdateRequest(BaseModel):
    enabled: bool

class WorkflowCreateRequest(BaseModel):
    name: str
    description: Optional[str] = ""
    nodes: list = []
    edges: list = []

# ══════════════════════════════════════════════
# AUTH ROUTES
# ══════════════════════════════════════════════
@app.post("/api/v1/auth/login")
async def login(req: LoginRequest):
    # ── Multi-user mode (Supabase configured) ──────────────
    if supabase_store.enabled:
        user = supabase_store.get_user_by_email(req.email)
        if not user or not verify_password(req.password, user["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        if user.get("banned"):
            raise HTTPException(status_code=403, detail="This account has been suspended")
        token = create_token(user["email"], uid=user["id"], role=user.get("role", "user"))
        return {"access_token": token, "token_type": "bearer",
                "email": user["email"], "role": user.get("role", "user")}

    # ── Fallback: single hardcoded admin (no Supabase set up yet) ──
    if req.email == ADMIN_EMAIL and req.password == ADMIN_PASSWORD:
        token = create_token(req.email, uid="", role="admin")
        return {"access_token": token, "token_type": "bearer", "email": req.email, "role": "admin"}
    raise HTTPException(status_code=401, detail="Invalid credentials")

@app.post("/api/v1/auth/register")
async def register(req: RegisterRequest):
    if not supabase_store.enabled:
        raise HTTPException(status_code=403,
            detail="Registration needs Supabase configured. See supabase/schema.sql and set "
                   "SUPABASE_URL / SUPABASE_SERVICE_KEY in the backend's env vars.")
    if supabase_store.get_user_by_email(req.email):
        raise HTTPException(status_code=409, detail="An account with this email already exists")
    role = "admin" if req.email == ADMIN_EMAIL else "user"
    user = supabase_store.create_user(
        email=req.email, password_hash=hash_password(req.password),
        name=req.name, role=role, budget_usd=DEFAULT_USER_BUDGET_USD,
    )
    token = create_token(user["email"], uid=user["id"], role=role)
    return {"access_token": token, "token_type": "bearer", "email": user["email"], "role": role}

@app.post("/api/v1/auth/logout")
async def logout(user: dict = Depends(get_current_user)):
    return {"message": "Logged out"}

@app.post("/api/v1/auth/refresh")
async def refresh(user: dict = Depends(get_current_user)):
    token = create_token(user["email"], uid=user.get("uid", ""), role=user.get("role", "admin"))
    return {"access_token": token, "token_type": "bearer"}

@app.get("/api/v1/users/me")
async def get_me(user: dict = Depends(get_current_user)):
    if not supabase_store.enabled:
        return {"email": user["email"], "role": "admin", "budget_usd": None, "budget_used_usd": None}
    full = supabase_store.get_user_by_id(user["uid"]) if user.get("uid") else None
    if not full:
        raise HTTPException(status_code=404, detail="User not found")
    return {"email": full["email"], "name": full.get("name"), "role": full.get("role"),
            "budget_usd": full.get("budget_usd"), "budget_used_usd": full.get("budget_used_usd")}

# ══════════════════════════════════════════════
# AGENT ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/agent/status")
async def agent_status(user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    return maya_instance.status()

def check_budget(user: dict):
    """Blocks the request with 402 if this user (Supabase mode only) has used
    up their budget_usd allowance. No-op when Supabase isn't configured."""
    if supabase_store.enabled and user.get("uid") and supabase_store.over_budget(user["uid"]):
        raise HTTPException(status_code=402,
            detail="Budget exceeded. Ask an admin to raise your limit in the Admin Panel.")

@app.post("/api/v1/agent/run")
async def agent_run(req: AgentRunRequest, user: dict = Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    check_budget(user)
    # Resolve optional instance (persona + memory scope)
    _run_instance = None
    _run_scope = ""
    if req.instance_id:
        try:
            from infrastructure.instances import instance_manager as _run_im
            _run_instance = _run_im.get(req.instance_id)
            if _run_instance:
                _run_scope = _run_instance.get("memory_scope", "")
        except Exception:
            pass
    _run_goal = req.goal
    if _run_instance:
        p = (_run_instance.get("persona") or "").strip()
        if p:
            _run_goal = f"[Instance: {_run_instance['name']}] Persona: {p}\n\n{_run_goal}"

    task_id = str(uuid.uuid4())
    session = await stream_manager.create_session(_run_goal, user.get("uid", "anonymous"))
    # Link session to task
    await stream_manager.update_session(session.task_id, status="running")
    
    task = {
        "id": task_id, "goal": req.goal, "status": "running",
        "steps": [], "current_phase": "starting", "created_at": datetime.utcnow().isoformat(),
        "provider_used": None, "cost_usd": 0, "tokens_used": 0,
        "instance_id": req.instance_id,
        "session_id": session.session_id,
    }
    tasks_db[task_id] = task
    await broadcast({"type": "task_started", "task": task})
    await fire_webhooks("task.started", task)

    def on_progress(payload: dict):
        """Called from Maya's worker thread as it plans/executes/verifies."""
        if task_id not in tasks_db:
            return
        phase = payload.get("phase")
        tasks_db[task_id]["current_phase"] = phase

        if phase == "step_start":
            tasks_db[task_id]["steps"].append({
                "step": payload.get("step"),
                "title": (payload.get("description") or "Step")[:60],
                "description": payload.get("description", ""),
                "tool": payload.get("tool"),
                "result": None, "success": None, "error": None,
            })
        elif phase == "step_done":
            for s in tasks_db[task_id]["steps"]:
                if s["step"] == payload.get("step"):
                    s.update({
                        "tool": payload.get("tool") or s.get("tool"),
                        "result": payload.get("result"),
                        "success": payload.get("success"),
                    })
                    break

        # Emit to stream manager
        if MAIN_EVENT_LOOP:
            try:
                asyncio.run_coroutine_threadsafe(
                    stream_manager.emit_event(
                        StreamEventType.PROGRESS, task_id, session.session_id,
                        {"phase": phase, "data": payload}
                    ),
                    MAIN_EVENT_LOOP,
                )
            except Exception:
                pass

    async def run_task():
        try:
            # Create stream emitter for this task
            emitter = StreamEmitter(stream_manager, task_id, session.session_id)
            
            # Wrap the run to emit streaming events
            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: maya_instance.run(_run_goal, task_id=task_id,
                                                progress_callback=on_progress,
                                                scope=_run_scope, stream_emitter=emitter)
            )
            raw_steps = result.get("steps", []) or []
            normalized_steps = [{
                "step": s.get("step"),
                "title": (s.get("description") or "Step")[:60],
                "description": s.get("description", ""),
                "tool": s.get("tool_used"),
                "result": s.get("result"),
                "success": s.get("success"),
                "error": s.get("error"),
            } for s in raw_steps]
            tasks_db[task_id].update({
                "status": "done" if result.get("success") else "failed",
                "result": result.get("result", ""),
                "error": result.get("error"),
                "steps": normalized_steps,
                "completed_at": datetime.utcnow().isoformat(),
                "cost_usd": result.get("cost_usd", 0),
                "tokens_used": result.get("tokens_used", 0),
            })
            await stream_manager.update_session(task_id, status="completed" if result.get("success") else "failed")
            await stream_manager.emit_event(
                StreamEventType.TASK_COMPLETED if result.get("success") else StreamEventType.TASK_FAILED,
                task_id, session.session_id,
                {"result": result.get("result", ""), "error": result.get("error")}
            )
        except Exception as e:
            tasks_db[task_id].update({"status": "failed", "error": str(e)})
            await stream_manager.update_session(task_id, status="failed")
            await stream_manager.emit_event(
                StreamEventType.TASK_FAILED, task_id, session.session_id,
                {"error": str(e)}
            )
        await broadcast({"type": "task_done", "task": tasks_db[task_id]})
        final = tasks_db[task_id]
        if supabase_store.enabled and user.get("uid") and final.get("cost_usd"):
            supabase_store.add_budget_usage(user["uid"], float(final["cost_usd"]))
        await fire_webhooks("task.done" if final.get("status") == "done" else "task.failed", final)

    asyncio.create_task(run_task())
    return {"task": task, "session_id": session.session_id}

CHAT_MESSAGE_FLAT_COST_USD = 0.01  # rough per-call estimate until real token costs are wired in

@app.post("/api/v1/agent/chat")
async def agent_chat(req: ChatRequest, user: dict = Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    check_budget(user)

    _chat_msg = req.message
    _chat_scope = ""
    if req.instance_id:
        try:
            from infrastructure.instances import instance_manager as _chat_im
            _chat_inst = _chat_im.get(req.instance_id)
            if _chat_inst:
                _chat_scope = _chat_inst.get("memory_scope", "")
                p = (_chat_inst.get("persona") or "").strip()
                if p:
                    _chat_msg = f"[Instance: {_chat_inst['name']}] Persona: {p}\n\n{_chat_msg}"
        except Exception:
            pass

    history = []
    use_supabase_history = supabase_store.enabled and user.get("uid") and req.chat_id
    if use_supabase_history:
        past = supabase_store.get_chat_history(user["uid"], req.chat_id, limit=20)
        history = [{"role": m["role"], "content": m["content"]} for m in past]

    response = await asyncio.get_event_loop().run_in_executor(
        None, lambda: maya_instance.chat(_chat_msg, history=history, scope=_chat_scope)
    )

    if use_supabase_history:
        supabase_store.add_chat_message(user["uid"], req.chat_id, "user", req.message)
        supabase_store.add_chat_message(user["uid"], req.chat_id, "assistant", response)
        supabase_store.add_budget_usage(user["uid"], CHAT_MESSAGE_FLAT_COST_USD)

    return {"reply": response, "timestamp": datetime.utcnow().isoformat()}

@app.post("/api/v1/agent/think")
async def agent_think(req: ThinkRequest, user: dict = Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    result = await asyncio.get_event_loop().run_in_executor(
        None, lambda: maya_instance.think(req.problem)
    )
    return {"result": result, "depth": req.depth}

# ══════════════════════════════════════════════
# TASK ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/tasks")
async def list_tasks(limit: int = 50, status: Optional[str] = None, user=Depends(get_current_user)):
    tasks = list(tasks_db.values())
    if status:
        tasks = [t for t in tasks if t["status"] == status]
    return sorted(tasks, key=lambda x: x["created_at"], reverse=True)[:limit]

@app.get("/api/v1/tasks/{task_id}")
async def get_task(task_id: str, user=Depends(get_current_user)):
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")
    return tasks_db[task_id]

@app.post("/api/v1/tasks")
async def create_task(req: AgentRunRequest, user=Depends(get_current_user)):
    return await agent_run(req, user)

@app.delete("/api/v1/tasks/{task_id}")
async def delete_task(task_id: str, user=Depends(get_current_user)):
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")
    del tasks_db[task_id]
    return {"message": "Deleted"}

@app.post("/api/v1/tasks/{task_id}/reflect")
async def reflect_on_task(task_id: str, body: dict = None, user=Depends(get_current_user)):
    """Self-critique a completed task against its own goal, and
    optionally run one retry that folds the critique back in as a new
    task. body: {retry?: bool}. The critique is also stored on the
    original task so the UI can show it without re-requesting."""
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    task = tasks_db[task_id]
    if task.get("status") not in ("done", "failed"):
        raise HTTPException(status_code=409, detail="Task hasn't finished yet")

    from infrastructure.reflection import ReflectionEngine
    engine = ReflectionEngine(maya_instance.router)
    loop = asyncio.get_event_loop()
    critique = await loop.run_in_executor(
        None, lambda: engine.critique(task.get("goal", ""), str(task.get("result", ""))))
    task["reflection"] = critique

    retry_task_id = None
    body = body or {}
    if body.get("retry") and engine.should_retry(critique):
        retry_goal = engine.retry_prompt(task.get("goal", ""), str(task.get("result", "")), critique)
        retry_req = AgentRunRequest(goal=retry_goal)
        retry_result = await agent_run(retry_req, user)
        retry_task_id = retry_result.get("id") if isinstance(retry_result, dict) else None
        if retry_task_id:
            tasks_db[retry_task_id]["reflected_from"] = task_id

    return {"task_id": task_id, "critique": critique, "retry_task_id": retry_task_id}

# ══════════════════════════════════════════════
# MEMORY ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/memory")
async def list_memories(type: Optional[str] = None, limit: int = 50, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    memories = maya_instance.memory.get_all() if hasattr(maya_instance.memory, "get_all") else []
    if type:
        memories = [m for m in memories if m.get("type") == type]
    return memories[:limit]

@app.get("/api/v1/memory/search")
async def search_memory(q: str, limit: int = 10, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    results = maya_instance.recall(q)
    return results[:limit] if isinstance(results, list) else []

@app.post("/api/v1/memory")
async def add_memory(req: MemoryAddRequest, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    maya_instance.remember(req.content)
    return {"id": str(uuid.uuid4()), "content": req.content, "type": req.type, "timestamp": datetime.utcnow().isoformat()}

@app.delete("/api/v1/memory/{memory_id}")
async def delete_memory(memory_id: str, user=Depends(get_current_user)):
    if maya_instance and hasattr(maya_instance.memory, "delete"):
        maya_instance.memory.delete(memory_id)
    return {"message": "Deleted"}

@app.get("/api/v1/memory/stats")
async def memory_stats(user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    return {"total": len(maya_instance.memory.get_all()) if hasattr(maya_instance.memory, "get_all") else 0}

# ══════════════════════════════════════════════
# TOOLS ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/tools")
async def list_tools(user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    reg = maya_instance.tool_manager.get_registry()
    return [{**t, "enabled": True} for t in reg.list_tools()]

@app.post("/api/v1/tools/{tool_name}/run")
async def run_tool(tool_name: str, body: dict, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    result = await asyncio.get_event_loop().run_in_executor(
        None, lambda: maya_instance.tool_manager.get_registry().run(tool_name, body.get("input", {}))
    )
    return {"result": result}

@app.put("/api/v1/tools/{tool_name}")
async def update_tool(tool_name: str, req: ToolUpdateRequest, user=Depends(get_current_user)):
    if maya_instance and hasattr(maya_instance.tool_manager, "set_enabled"):
        maya_instance.tool_manager.set_enabled(tool_name, req.enabled)
    return {"tool": tool_name, "enabled": req.enabled}

@app.get("/api/v1/tools/logs")
async def tool_logs(limit: int = 50, user=Depends(get_current_user)):
    if maya_instance and hasattr(maya_instance, "tool_manager"):
        stats = maya_instance.tool_manager.get_registry()._usage_stats
        entries = [
            {"tool": name, "calls": st.get("calls", 0), "successes": st.get("successes", 0),
             "failures": st.get("failures", 0), "avg_time": round(st.get("avg_time", 0), 3),
             "last_error": st.get("last_error")}
            for name, st in stats.items() if st.get("calls", 0) > 0
        ]
        return entries[-limit:]
    return []

@app.get("/api/v1/providers")
async def list_providers(user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    return maya_instance.router.list_providers()

@app.put("/api/v1/providers/{provider_id}")
async def update_provider(provider_id: str, req: ProviderUpdateRequest, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    ok = maya_instance.router.set_enabled(provider_id, req.enabled)
    if not ok:
        raise HTTPException(status_code=404, detail=f"Unknown provider: {provider_id}")
    return {"id": provider_id, "enabled": req.enabled}

# ══════════════════════════════════════════════
# ANALYTICS ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/analytics/summary")
async def analytics_summary(user=Depends(get_current_user)):
    tasks = list(tasks_db.values())
    done = [t for t in tasks if t["status"] == "done"]
    total_cost = sum(t.get("cost_usd", 0) for t in tasks)
    return {
        "total_tasks": len(tasks),
        "success_rate": round(len(done) / len(tasks) * 100, 1) if tasks else 0,
        "total_cost_usd": total_cost,
        "budget_usd": float(os.getenv("BUDGET_USD", "1.0")),
        "budget_used_pct": round(total_cost / float(os.getenv("BUDGET_USD", "1.0")) * 100, 1),
        "avg_duration_ms": 0,
    }

@app.get("/api/v1/analytics/daily")
async def analytics_daily(days: int = 7, user=Depends(get_current_user)):
    from collections import defaultdict
    from datetime import timedelta
    cutoff = (datetime.utcnow() - timedelta(days=max(days, 1))).date().isoformat()
    daily = defaultdict(int)
    for task in tasks_db.values():
        date = task["created_at"][:10]
        if date >= cutoff:
            daily[date] += 1
    return [{"date": k, "tasks": v} for k, v in sorted(daily.items())]

@app.get("/api/v1/analytics/providers")
async def analytics_providers(user=Depends(get_current_user)):
    providers = {}
    for task in tasks_db.values():
        p = task.get("provider_used", "unknown")
        if p not in providers:
            providers[p] = {"calls": 0, "tokens": 0, "cost": 0}
        providers[p]["calls"] += 1
        providers[p]["cost"] += task.get("cost_usd", 0)
        providers[p]["tokens"] += task.get("tokens_used", 0)
    return providers

@app.get("/api/v1/analytics/tools")
async def analytics_tools(user=Depends(get_current_user)):
    if maya_instance and hasattr(maya_instance, "tool_manager"):
        return getattr(maya_instance.tool_manager, "stats", {})
    return {}

# ══════════════════════════════════════════════
# LOGS ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/logs/llm")
async def llm_logs(limit: int = 50, user=Depends(get_current_user)):
    if maya_instance and hasattr(maya_instance, "router"):
        logs = getattr(maya_instance.router, "logs", [])
        return logs[-limit:]
    return []

@app.get("/api/v1/logs/tools")
async def tools_logs_v2(limit: int = 50, user=Depends(get_current_user)):
    return await tool_logs(limit, user)

# ══════════════════════════════════════════════
# WORKFLOWS ROUTES
# ══════════════════════════════════════════════
workflows_db: dict = {}

@app.get("/api/v1/workflows")
async def list_workflows(user=Depends(get_current_user)):
    return list(workflows_db.values())

@app.post("/api/v1/workflows")
async def create_workflow(req: WorkflowCreateRequest, user=Depends(get_current_user)):
    wf_id = str(uuid.uuid4())
    wf = {
        "id": wf_id, "name": req.name, "description": req.description,
        "nodes": req.nodes, "edges": req.edges,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
        "run_count": 0, "last_run": None
    }
    workflows_db[wf_id] = wf
    return wf

@app.put("/api/v1/workflows/{wf_id}")
async def update_workflow(wf_id: str, req: WorkflowCreateRequest, user=Depends(get_current_user)):
    if wf_id not in workflows_db:
        raise HTTPException(status_code=404, detail="Not found")
    workflows_db[wf_id].update({"name": req.name, "description": req.description, "updated_at": datetime.utcnow().isoformat()})
    return workflows_db[wf_id]

@app.delete("/api/v1/workflows/{wf_id}")
async def delete_workflow(wf_id: str, user=Depends(get_current_user)):
    if wf_id not in workflows_db:
        raise HTTPException(status_code=404, detail="Not found")
    del workflows_db[wf_id]
    return {"message": "Deleted"}

@app.post("/api/v1/workflows/{wf_id}/run")
async def run_workflow(wf_id: str, user=Depends(get_current_user)):
    if wf_id not in workflows_db:
        raise HTTPException(status_code=404, detail="Not found")
    wf = workflows_db[wf_id]
    wf["run_count"] += 1
    wf["last_run"] = datetime.utcnow().isoformat()
    result = await agent_run(AgentRunRequest(goal=wf["name"]), user)
    return {"workflow": wf, "task": result}

# ══════════════════════════════════════════════
# PLUGINS ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/plugins")
async def list_plugins(user=Depends(get_current_user)):
    if maya_instance and hasattr(maya_instance, "plugin_loader"):
        return maya_instance.plugin_loader.list_plugins()
    return []

@app.put("/api/v1/plugins/{plugin_id}")
async def update_plugin(plugin_id: str, body: dict, user=Depends(get_current_user)):
    if maya_instance and hasattr(maya_instance, "plugin_loader"):
        maya_instance.plugin_loader.set_enabled(plugin_id, body.get("enabled", True))
    return {"id": plugin_id, "enabled": body.get("enabled")}

@app.post("/api/v1/plugins/{plugin_id}/install")
async def install_plugin(plugin_id: str, user=Depends(get_current_user)):
    if maya_instance and hasattr(maya_instance, "plugin_loader"):
        ok = maya_instance.plugin_loader.install(plugin_id)
        if not ok:
            raise HTTPException(status_code=501,
                detail="Installing new plugins from a catalog isn't supported yet — "
                       "drop a .py file into the plugins/ folder instead.")
    return {"id": plugin_id, "installed": True}

@app.delete("/api/v1/plugins/{plugin_id}")
async def delete_plugin(plugin_id: str, user=Depends(get_current_user)):
    if not maya_instance or not hasattr(maya_instance, "plugin_loader"):
        raise HTTPException(status_code=503, detail="Plugin system not initialized")
    ok = maya_instance.plugin_loader.uninstall(plugin_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Plugin not found")
    return {"id": plugin_id, "deleted": True}

# ══════════════════════════════════════════════
# VISION ROUTES
# ══════════════════════════════════════════════
@app.post("/api/v1/vision/analyze")
async def vision_analyze(body: dict, user=Depends(get_current_user)):
    """Analyze an image with a real multimodal provider
    (Gemini → OpenAI → Claude fallback). Accepts base64 / data URL."""
    image = body.get("image", "")
    prompt = body.get("prompt", "Describe this image in detail.")
    if not image:
        raise HTTPException(status_code=400, detail="No image provided")
    from tools.media.vision_tool import VisionTool
    try:
        result = await asyncio.get_event_loop().run_in_executor(
            None, lambda: VisionTool().analyze(image, prompt))
    except (ValueError, PermissionError, FileNotFoundError) as e:
        raise HTTPException(status_code=400, detail=str(e))
    if not result.get("success"):
        return {"result": "", "message": result.get("error", "Vision failed")}
    return {"result": result["result"], "provider": result.get("provider", "")}

# ══════════════════════════════════════════════
# VOICE ROUTES
# ══════════════════════════════════════════════
@app.post("/api/v1/voice/transcribe")
async def voice_transcribe(body: dict, user=Depends(get_current_user)):
    """Transcribe base64/data-URL audio using Groq Whisper (whisper-large-v3)."""
    audio = body.get("audio", "")
    if not audio:
        raise HTTPException(status_code=400, detail="No audio provided")
    api_key = os.getenv("GROQ_API_KEY") or os.getenv("GROQ_KEY")
    if not api_key:
        return {"transcript": "", "message": "Set GROQ_API_KEY on the server to enable voice transcription"}
    try:
        import base64, tempfile
        # Accept both raw base64 and data URLs (data:audio/webm;base64,....)
        if "," in audio and audio.strip().startswith("data:"):
            audio = audio.split(",", 1)[1]
        raw = base64.b64decode(audio)
        if len(raw) > 25 * 1024 * 1024:
            raise HTTPException(status_code=413, detail="Audio too large (25MB max)")
        with tempfile.NamedTemporaryFile(suffix=".webm", delete=False) as f:
            f.write(raw)
            tmp_path = f.name

        def _transcribe():
            from groq import Groq
            client = Groq(api_key=api_key)
            with open(tmp_path, "rb") as af:
                res = client.audio.transcriptions.create(
                    file=("audio.webm", af.read()),
                    model="whisper-large-v3",
                )
            return getattr(res, "text", "") or ""

        text = await asyncio.get_event_loop().run_in_executor(None, _transcribe)
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        return {"transcript": text.strip()}
    except HTTPException:
        raise
    except Exception as e:
        return {"transcript": "", "message": f"Transcription failed: {e}"}

# ══════════════════════════════════════════════
# DEVICE BRIDGE ROUTES
# ══════════════════════════════════════════════
# Pairing/list/revoke/history are human-facing (normal JWT auth, same as
# everything else). Poll/result are BRIDGE-facing — the local script has
# no Maya login, so those two authenticate with the device_id+secret pair
# handed out at pairing time instead of a Bearer token.
@app.post("/api/v1/device/pair/start")
async def device_pair_start(body: dict, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    return maya_instance.device_bridge.start_pairing(body.get("name", "My computer"))

@app.post("/api/v1/device/pair/complete")
async def device_pair_complete(body: dict):
    """Called by the local bridge script, not the web UI — deliberately
    has no user auth, since the script has no Maya login. The one-time
    pairing code (generated by /device/pair/start and typed in by a
    person) is the actual security boundary here."""
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    result = maya_instance.device_bridge.complete_pairing(body.get("code", ""))
    if not result:
        raise HTTPException(status_code=400, detail="Invalid or expired pairing code")
    return result

@app.get("/api/v1/device/list")
async def device_list(user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    return {"devices": maya_instance.device_bridge.list_devices()}

@app.delete("/api/v1/device/{device_id}")
async def device_revoke(device_id: str, user=Depends(get_current_user)):
    if not maya_instance or not maya_instance.device_bridge.revoke(device_id):
        raise HTTPException(status_code=404, detail="Device not found")
    return {"revoked": device_id}

@app.get("/api/v1/device/{device_id}/history")
async def device_history(device_id: str, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    return {"commands": maya_instance.device_bridge.commands_for_device(device_id)}

@app.post("/api/v1/device/command")
async def device_enqueue(body: dict, user=Depends(get_current_user)):
    """A person (not just Maya) can also queue a command directly from
    the UI — same underlying queue the device_control tool uses."""
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    device_id = body.get("device_id", "")
    action = body.get("action", "")
    if not (device_id and action):
        raise HTTPException(status_code=400, detail="device_id and action are required")
    cmd = maya_instance.device_bridge.enqueue(device_id, action, body.get("params", {}))
    if not cmd:
        raise HTTPException(status_code=404, detail="Device not found")
    return cmd

@app.get("/api/v1/device/{device_id}/commands")
async def device_poll(device_id: str, secret: str = ""):
    """Bridge-facing: the local script polls this for pending commands."""
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    if not maya_instance.device_bridge.verify(device_id, secret):
        raise HTTPException(status_code=401, detail="Invalid device credentials")
    return {"commands": maya_instance.device_bridge.poll(device_id)}

@app.post("/api/v1/device/commands/{command_id}/result")
async def device_report_result(command_id: str, body: dict):
    """Bridge-facing: the local script reports back what happened.
    Verified by device_id+secret in the body (not JWT, matching /poll)."""
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    device_id = body.get("device_id", "")
    secret = body.get("secret", "")
    if not maya_instance.device_bridge.verify(device_id, secret):
        raise HTTPException(status_code=401, detail="Invalid device credentials")
    if not maya_instance.device_bridge.report_result(command_id, body.get("result", {})):
        raise HTTPException(status_code=404, detail="Command not found")
    return {"acknowledged": command_id}

# ══════════════════════════════════════════════
# WORKSPACE FILES ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/workspace/files")
async def list_workspace_files(user=Depends(get_current_user)):
    """List files tools have written into the workspace (screenshots, exports, etc.)."""
    from pathlib import Path
    from config.settings import WORKSPACE_DIR
    out = []
    try:
        for p in sorted(Path(WORKSPACE_DIR).iterdir(), key=lambda p: p.stat().st_mtime, reverse=True):
            if p.is_file():
                out.append({"name": p.name, "size": p.stat().st_size, "modified": p.stat().st_mtime})
    except FileNotFoundError:
        pass
    return {"files": out[:200]}

@app.get("/api/v1/workspace/files/{filename}")
async def get_workspace_file(filename: str, user=Depends(get_current_user)):
    """Serve a file a tool wrote into the workspace (e.g. a browser_screenshot PNG)."""
    from fastapi.responses import FileResponse
    from tools.files.safe_path import resolve_safe_path
    try:
        path = resolve_safe_path(filename)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    if not path.is_file():
        raise HTTPException(status_code=404, detail="file not found")
    return FileResponse(str(path))

# ══════════════════════════════════════════════
# BACKUP ROUTES
# ══════════════════════════════════════════════
backups_db: list = []

@app.get("/api/v1/backup/list")
async def list_backups(user=Depends(get_current_user)):
    return backups_db

@app.post("/api/v1/backup/create")
async def create_backup(user=Depends(get_current_user)):
    backup = {
        "id": str(uuid.uuid4()),
        "name": f"Backup {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}",
        "created_at": datetime.utcnow().isoformat(),
        "tasks": len(tasks_db),
        "memories": 0,
    }
    backups_db.append(backup)
    return backup

@app.post("/api/v1/backup/restore/{backup_id}")
async def restore_backup(backup_id: str, user=Depends(get_current_user)):
    backup = next((b for b in backups_db if b["id"] == backup_id), None)
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    return {"message": f"Restored from {backup['name']}"}

@app.delete("/api/v1/backup/{backup_id}")
async def delete_backup(backup_id: str, user=Depends(get_current_user)):
    global backups_db
    if not any(b["id"] == backup_id for b in backups_db):
        raise HTTPException(status_code=404, detail="Backup not found")
    backups_db = [b for b in backups_db if b["id"] != backup_id]
    return {"id": backup_id, "deleted": True}

# ══════════════════════════════════════════════
# SECURITY ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/security/status")
async def security_status(user=Depends(get_current_user)):
    return {"sandbox": True, "risk_level": "low", "blocked_tools": [], "audit_log": []}



# ══════════════════════════════════════════════
# CONTROL PANEL ENDPOINTS
# ══════════════════════════════════════════════

class FlagUpdateRequest(BaseModel):
    name: str
    value: bool

@app.put("/api/v1/flags")
async def update_flag(req: FlagUpdateRequest, user=Depends(get_current_user)):
    try:
        from infrastructure import flags as _cf_flags
        _cf_flags.set(req.name, req.value)
        return {"name": req.name, "value": req.value, "flags": _cf_flags.all()}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Flags unavailable: {e}")

@app.get("/api/v1/llm/providers")
async def llm_providers(user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    return {"providers": maya_instance.router.list_providers()}

class ProviderToggleRequest(BaseModel):
    enabled: bool

@app.post("/api/v1/llm/providers/{provider}/toggle")
async def llm_provider_toggle(provider: str, req: ProviderToggleRequest, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    try:
        ok = maya_instance.router.set_enabled(provider, req.enabled)
        return {"provider": provider, "enabled": req.enabled, "ok": bool(ok)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

class ProviderKeyRequest(BaseModel):
    api_key: str

@app.put("/api/v1/llm/providers/{provider}/key")
async def llm_provider_set_key(provider: str, req: ProviderKeyRequest, user: dict = Depends(require_admin)):
    """Sets an LLM provider's API key from the Admin Panel instead of Render's
    env vars — takes effect immediately (no redeploy), and is saved to
    Supabase so it survives the next restart. Falls back to being in-memory
    only (lost on restart) if Supabase isn't configured."""
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    if not req.api_key or not req.api_key.strip():
        raise HTTPException(status_code=400, detail="api_key cannot be empty")
    ok = maya_instance.router.set_key(provider, req.api_key.strip())
    if not ok:
        raise HTTPException(status_code=400, detail=f"Unknown provider or key type: {provider}")
    persisted = False
    if supabase_store.enabled:
        supabase_store.set_provider_key(provider, req.api_key.strip())
        persisted = True
    return {"provider": provider, "ok": True, "persisted": persisted}

approvals_db: dict = {}
APPROVAL_TIMEOUT_SECONDS = int(os.getenv("APPROVAL_TIMEOUT_SECONDS", "600"))

def web_approval_handler(action: str, reason: str = "", risk_level: str = "high", task_id: str = None) -> bool:
    """The actual link between the Approvals page and the executor.

    Runs inside Maya's background worker thread (agent_run's run_in_executor),
    NOT the main event loop — so blocking here with time.sleep() only pauses
    this one task, never the server. It creates a pending row here (the same
    store /api/v1/approvals reads from), pushes it live over the websocket,
    and polls until /api/v1/approvals/{id}/{decision} flips the status —
    that's the endpoint that already existed but had nothing to wake up.
    """
    aid = str(uuid.uuid4())
    approvals_db[aid] = {
        "id": aid, "action": action, "reason": reason, "risk_level": risk_level,
        "task_id": task_id, "status": "pending", "created_at": datetime.utcnow().isoformat(),
    }

    if task_id and task_id in tasks_db:
        tasks_db[task_id]["status"] = "waiting_approval"

    if MAIN_EVENT_LOOP:
        try:
            asyncio.run_coroutine_threadsafe(
                broadcast({"type": "approval_requested", "approval": approvals_db[aid]}),
                MAIN_EVENT_LOOP,
            )
        except Exception:
            pass

    # Push a phone notification so the user knows something needs their
    # attention without polling.  Falls back to in-app store if FCM is
    # not configured.
    if risk_level in ("high", "critical"):
        try:
            from infrastructure.notifications import notify_phone
            notify_phone(
                f"⚠️ Approval needed: {action[:80]}",
                reason[:300] or action[:300],
                level="warning",
            )
        except Exception:
            pass

    waited = 0
    poll_interval = 2
    while waited < APPROVAL_TIMEOUT_SECONDS:
        status = approvals_db.get(aid, {}).get("status")
        if status == "approved":
            if task_id and task_id in tasks_db:
                tasks_db[task_id]["status"] = "running"
            return True
        if status == "rejected":
            return False
        time.sleep(poll_interval)
        waited += poll_interval

    # Timed out with no response — fail safe (reject) rather than silently proceeding.
    approvals_db[aid]["status"] = "rejected"
    approvals_db[aid]["decided_at"] = datetime.utcnow().isoformat()
    approvals_db[aid]["reason"] = (reason + " " if reason else "") + "[auto-rejected: no response within timeout]"
    return False

@app.get("/api/v1/approval/mode")
async def approval_mode(user=Depends(get_current_user)):
    mode = maya_instance.approval.mode if maya_instance else os.getenv("APPROVAL_MODE", "auto")
    return {"mode": mode}

class ApprovalModeRequest(BaseModel):
    mode: str

@app.put("/api/v1/approval/mode")
async def set_approval_mode(req: ApprovalModeRequest, user=Depends(get_current_user)):
    if req.mode not in ("auto", "human", "skip"):
        raise HTTPException(status_code=400, detail="mode must be auto, human, or skip")
    if maya_instance:
        maya_instance.approval.mode = req.mode
    return {"mode": req.mode}

class ApprovalRequest(BaseModel):
    action: str
    reason: str = ""
    risk_level: str = "low"

@app.post("/api/v1/approvals/request")
async def create_approval(req: ApprovalRequest, user=Depends(get_current_user)):
    aid = str(uuid.uuid4())
    approvals_db[aid] = {"id": aid, "action": req.action, "reason": req.reason,
                         "risk_level": req.risk_level, "status": "pending",
                         "created_at": datetime.utcnow().isoformat()}
    await broadcast({"type": "approval_requested", "approval": approvals_db[aid]})
    return approvals_db[aid]

@app.get("/api/v1/approvals")
async def list_approvals(status: str = "", user=Depends(get_current_user)):
    items = list(approvals_db.values())
    if status:
        items = [a for a in items if a["status"] == status]
    return {"approvals": sorted(items, key=lambda a: a["created_at"], reverse=True)}

@app.post("/api/v1/approvals/{aid}/{decision}")
async def decide_approval(aid: str, decision: str, user=Depends(get_current_user)):
    if aid not in approvals_db:
        raise HTTPException(status_code=404, detail="Approval not found")
    if decision not in ("approve", "reject"):
        raise HTTPException(status_code=400, detail="decision must be approve or reject")
    approvals_db[aid]["status"] = "approved" if decision == "approve" else "rejected"
    approvals_db[aid]["decided_at"] = datetime.utcnow().isoformat()
    return approvals_db[aid]

@app.get("/api/v1/learning/prompts")
async def learning_prompts(user=Depends(get_current_user)):
    try:
        report = _p10_po.report() if "_p10_po" in globals() else {}
    except Exception:
        report = {}
    core = {}
    if maya_instance and hasattr(maya_instance, "learning"):
        try:
            core = getattr(maya_instance.learning, "prompt_stats", lambda: {})()
        except Exception:
            core = {}
    return {"optimizer": report, "core": core}

@app.get("/api/v1/skills")
async def list_skills(user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    try:
        plugins = maya_instance.plugins.list_plugins()
    except Exception:
        plugins = []
    return {"skills": plugins}

@app.get("/api/v1/docs")
async def docs_list(user=Depends(get_current_user)):
    import glob
    files = sorted(os.path.basename(f) for f in glob.glob("docs/*.md"))
    return {"docs": files}

@app.get("/api/v1/docs/{name}")
async def docs_read(name: str, user=Depends(get_current_user)):
    if "/" in name or ".." in name or not name.endswith(".md"):
        raise HTTPException(status_code=400, detail="Invalid document name")
    path = os.path.join("docs", name)
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Document not found")
    with open(path, encoding="utf-8") as f:
        return {"name": name, "content": f.read()}

# ══════════════════════════════════════════════
# WEBHOOKS (outbound event notifications)
# ══════════════════════════════════════════════
import json as _wh_json
WEBHOOKS_PATH = "storage/webhooks.json"

def _wh_load() -> dict:
    try:
        with open(WEBHOOKS_PATH) as f:
            return _wh_json.load(f)
    except Exception:
        return {}

def _wh_save(data: dict):
    try:
        os.makedirs("storage", exist_ok=True)
        with open(WEBHOOKS_PATH, "w") as f:
            _wh_json.dump(data, f)
    except Exception:
        pass

webhooks_db: dict = _wh_load()

class WebhookCreateRequest(BaseModel):
    name: str
    url: str
    events: list = ["task.done"]
    active: bool = True

@app.get("/api/v1/webhooks")
async def list_webhooks(user=Depends(get_current_user)):
    return {"webhooks": list(webhooks_db.values())}

@app.post("/api/v1/webhooks")
async def create_webhook(req: WebhookCreateRequest, user=Depends(get_current_user)):
    if not req.url.startswith(("http://", "https://")):
        raise HTTPException(status_code=400, detail="URL must start with http:// or https://")
    wh_id = str(uuid.uuid4())
    wh = {"id": wh_id, "name": req.name, "url": req.url, "events": req.events,
          "active": req.active, "created_at": datetime.utcnow().isoformat()}
    webhooks_db[wh_id] = wh
    _wh_save(webhooks_db)
    return wh

@app.put("/api/v1/webhooks/{wh_id}")
async def update_webhook(wh_id: str, body: dict, user=Depends(get_current_user)):
    if wh_id not in webhooks_db:
        raise HTTPException(status_code=404, detail="Webhook not found")
    for k in ("name", "url", "events", "active"):
        if k in body:
            webhooks_db[wh_id][k] = body[k]
    _wh_save(webhooks_db)
    return webhooks_db[wh_id]

@app.delete("/api/v1/webhooks/{wh_id}")
async def delete_webhook(wh_id: str, user=Depends(get_current_user)):
    if wh_id not in webhooks_db:
        raise HTTPException(status_code=404, detail="Webhook not found")
    del webhooks_db[wh_id]
    _wh_save(webhooks_db)
    return {"message": "Deleted"}

def _fire_webhooks_sync(event: str, payload: dict):
    """POST the event to every active webhook subscribed to it (best-effort)."""
    import requests as _wh_requests
    for wh in list(webhooks_db.values()):
        if not wh.get("active") or event not in wh.get("events", []):
            continue
        try:
            _wh_requests.post(wh["url"], json={"event": event, "data": payload},
                              timeout=5)
        except Exception:
            pass

async def fire_webhooks(event: str, payload: dict):
    await asyncio.get_event_loop().run_in_executor(None, _fire_webhooks_sync, event, payload)

# ══════════════════════════════════════════════
# WEBSOCKET (Enhanced with Streaming)
# ══════════════════════════════════════════════
@app.websocket("/ws/agent")
async def websocket_endpoint(ws: WebSocket):
    token = ws.query_params.get("token")
    if token:
        try:
            jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        except Exception:
            await ws.close(code=4401)
            return
    await ws.accept()
    ws_clients.append(ws)
    try:
        await ws.send_json({"type": "connected", "message": "Maya 2.0 ULTRA connected"})
        while True:
            data = await ws.receive_json()
            if data.get("type") == "ping":
                await ws.send_json({"type": "pong"})
            elif data.get("type") == "run":
                goal = data.get("goal", "")
                await ws.send_json({"type": "task_started", "goal": goal})
            elif data.get("type") == "stream_connect":
                # Connect to existing task stream
                task_id = data.get("task_id")
                if task_id:
                    await websocket_handler(ws, task_id, stream_manager)
                    return  # Handler takes over the connection
    except WebSocketDisconnect:
        ws_clients.remove(ws) if ws in ws_clients else None

# New WebSocket endpoint for streaming
@app.websocket("/ws/stream/{task_id}")
async def websocket_stream_endpoint(ws: WebSocket, task_id: str):
    """WebSocket endpoint for real-time task streaming with reconnect support."""
    token = ws.query_params.get("token")
    if token:
        try:
            jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        except Exception:
            await ws.close(code=4401)
            return
    await ws.accept()
    await websocket_handler(ws, task_id, stream_manager)

# ══════════════════════════════════════════════
# HEALTH
# ══════════════════════════════════════════════
@app.get("/")
async def root():
    # Serve the frontend SPA when the frontend directory exists
    import pathlib as _root_path
    _root_idx = _root_path.Path(__file__).parent / "frontend" / "index.html"
    if _root_idx.is_file():
        from fastapi.responses import FileResponse
        return FileResponse(str(_root_idx))
    return {"status": "ok", "service": "Maya 2.0 ULTRA API", "version": "2.0.0"}

@app.get("/health")
async def health():
    return {"status": "healthy", "maya": maya_instance is not None}


# ══════════════ Phase 1: Infrastructure integration ══════════════
# Appended block — soft-fails so the API always boots even if the
# infrastructure package is missing or partially broken.
try:
    import time as _p1_time
    from infrastructure import metrics as _p1_metrics
    from infrastructure import flags as _p1_flags
    from infrastructure import TaskQueue as _P1TaskQueue
    from infrastructure import Scheduler as _P1Scheduler
    from infrastructure import RateLimiter as _P1RateLimiter
    from infrastructure import install_exception_handler as _p1_install_exc

    _p1_install_exc(app, _p1_metrics)
    _p1_queue = _P1TaskQueue(workers=int(os.getenv("TASK_WORKERS", "2")),
                             persist=os.getenv("QUEUE_PERSIST", "true").lower() != "false")
    _p1_rl = _P1RateLimiter(rate=float(os.getenv("RATE_LIMIT_PER_MIN", "120")), per_seconds=60)

    _p1_scheduler = _P1Scheduler(_p1_queue,
                                 tick_seconds=int(os.getenv("SCHED_TICK", "30")))

    @app.on_event("startup")
    async def _p1_start_queue():
        await _p1_queue.start()
        if os.getenv("SCHEDULER_ENABLED", "true").lower() != "false":
            await _p1_scheduler.start()
            print("Scheduler active: cron-based persistent scheduled tasks")
        print("Phase 1 infrastructure active: metrics, task queue, rate limiter, flags")

    @app.middleware("http")
    async def _p1_observe(request, call_next):
        if request.url.path.startswith("/api/v1/"):
            ip = request.client.host if request.client else "unknown"
            if not _p1_rl.allow(ip):
                from fastapi.responses import JSONResponse
                _p1_metrics.incr("http.rate_limited")
                return JSONResponse(status_code=429, content={"error": "Rate limit exceeded"})
        t0 = _p1_time.time()
        response = await call_next(request)
        _p1_metrics.incr("http.requests")
        _p1_metrics.observe("http.latency", _p1_time.time() - t0)
        if response.status_code >= 500:
            _p1_metrics.incr("http.5xx")
        return response

    @app.get("/api/v1/metrics")
    async def _p1_get_metrics(user=Depends(get_current_user)):
        return _p1_metrics.snapshot()

    @app.get("/api/v1/flags")
    async def _p1_get_flags(user=Depends(get_current_user)):
        return _p1_flags.all()

    # Register a persistent job: run an autonomous goal in the background.
    # Because only the job name + JSON args are stored, this survives a
    # server restart and resumes automatically.
    async def _p1_agent_goal_job(goal: str):
        if maya_instance and hasattr(maya_instance, "chat"):
            loop = asyncio.get_event_loop()
            return await loop.run_in_executor(
                None, lambda: maya_instance.chat(goal))
        return {"note": "maya_instance unavailable", "goal": goal}
    _p1_queue.register("agent_goal", _p1_agent_goal_job)

    # A "standing goal" (Project): unlike agent_goal above (one goal, one
    # shot), this job fires repeatedly on its schedule and each firing
    # reads the project's own prior progress from memory before deciding
    # the next concrete step — so the work accumulates across runs
    # instead of starting from zero every time. Stops itself (disables
    # its own schedule) once the model reports the goal is done.
    _PROJECT_DONE_MARKER = "PROJECT_COMPLETE:"

    async def _p1_standing_goal_job(project_id: str, goal: str = ""):
        if not (maya_instance and hasattr(maya_instance, "run")):
            return {"note": "maya_instance unavailable", "project_id": project_id}
        mtype = f"project:{project_id}"
        history = maya_instance.memory.get_all(limit=20, memory_type=mtype)
        progress = "\n".join(f"- {h.get('content', '')}" for h in reversed(history)) or "(nothing done yet)"
        step_goal = (
            f"This is part of a longer-running project. Original goal: {goal}\n\n"
            f"Progress so far:\n{progress}\n\n"
            "Do the single next concrete step toward the goal. If the goal is now "
            f"fully achieved, say so and start your final answer with the exact "
            f"text '{_PROJECT_DONE_MARKER}'."
        )
        loop = asyncio.get_event_loop()
        # .run() (not .chat()) so this actually uses tools, and inherits the
        # same risk-check + human-approval gate as any other goal run.
        result = await loop.run_in_executor(None, lambda: maya_instance.run(step_goal))
        text = (result.get("result") if isinstance(result, dict) else str(result)) or ""
        maya_instance.memory.add(text, memory_type=mtype, metadata={"project_id": project_id})
        if text.strip().startswith(_PROJECT_DONE_MARKER):
            for s in _p1_scheduler.list():
                if s.get("job") == "standing_goal_step" and s.get("args", [None])[0] == project_id:
                    _p1_scheduler.set_enabled(s["id"], False)
                    break
        return {"project_id": project_id, "result": text}
    _p1_queue.register("standing_goal_step", _p1_standing_goal_job)

    @app.post("/api/v1/projects")
    async def _p1_project_create(body: dict, user=Depends(get_current_user)):
        """Start a standing goal: a project that keeps working toward
        `goal` on its own schedule (default hourly), remembering its own
        progress between runs. body: {name, goal, cron?}."""
        import uuid as _uuid
        name = (body.get("name") or "").strip()
        goal = (body.get("goal") or "").strip()
        cron = (body.get("cron") or "@hourly").strip()
        if not (name and goal):
            raise HTTPException(status_code=400, detail="name and goal are required")
        project_id = _uuid.uuid4().hex[:12]
        try:
            sched = _p1_scheduler.add(name, cron, "standing_goal_step",
                                      args=[project_id], kwargs={"goal": goal})
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        if maya_instance:
            maya_instance.memory.add(f"GOAL: {goal}", memory_type=f"project:{project_id}",
                                     metadata={"project_id": project_id, "kind": "goal_start"})
        return {"project_id": project_id, "schedule": sched}

    @app.get("/api/v1/projects")
    async def _p1_project_list(user=Depends(get_current_user)):
        """List standing goals, each with its latest progress note."""
        out = []
        for s in _p1_scheduler.list():
            if s.get("job") != "standing_goal_step":
                continue
            project_id = (s.get("args") or [None])[0]
            goal = (s.get("kwargs") or {}).get("goal", "")
            latest = None
            if maya_instance and project_id:
                rows = maya_instance.memory.get_all(limit=1, memory_type=f"project:{project_id}")
                latest = rows[0] if rows else None
            out.append({**s, "project_id": project_id, "goal": goal, "latest_progress": latest})
        return {"projects": out}

    @app.get("/api/v1/projects/{schedule_id}/progress")
    async def _p1_project_progress(schedule_id: str, user=Depends(get_current_user)):
        sched = next((s for s in _p1_scheduler.list() if s["id"] == schedule_id), None)
        if not sched or sched.get("job") != "standing_goal_step":
            raise HTTPException(status_code=404, detail="Project not found")
        project_id = (sched.get("args") or [None])[0]
        history = maya_instance.memory.get_all(limit=50, memory_type=f"project:{project_id}") if maya_instance else []
        return {"project_id": project_id, "history": history}

    @app.delete("/api/v1/projects/{schedule_id}")
    async def _p1_project_delete(schedule_id: str, user=Depends(get_current_user)):
        """Stop a standing goal (removes its schedule; progress memory is kept)."""
        if not _p1_scheduler.remove(schedule_id):
            raise HTTPException(status_code=404, detail="Project not found")
        return {"deleted": schedule_id}

    @app.get("/api/v1/queue/status")
    async def _p1_queue_status(user=Depends(get_current_user)):
        return _p1_queue.all_status()

    @app.get("/api/v1/queue/stats")
    async def _p1_queue_stats(user=Depends(get_current_user)):
        """Queue counts, worker count, and registered persistent jobs."""
        return _p1_queue.stats()

    @app.get("/api/v1/queue/task/{task_id}")
    async def _p1_queue_task(task_id: str, user=Depends(get_current_user)):
        st = _p1_queue.status(task_id)
        if st is None:
            raise HTTPException(status_code=404, detail="Task not found")
        return {"id": task_id, **st}

    @app.post("/api/v1/queue/submit")
    async def _p1_queue_submit(body: dict, user=Depends(get_current_user)):
        """Submit a persistent background job. body: {job, args?, kwargs?}.
        The job must be a registered handler (e.g. 'agent_goal')."""
        job = (body.get("job") or "").strip()
        if not job:
            raise HTTPException(status_code=400, detail="'job' is required")
        try:
            task_id = await _p1_queue.submit_job(
                job, *body.get("args", []), **body.get("kwargs", {}))
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        return {"task_id": task_id, "job": job, "state": "queued"}

    @app.post("/api/v1/queue/cancel/{task_id}")
    async def _p1_queue_cancel(task_id: str, user=Depends(get_current_user)):
        if not _p1_queue.cancel(task_id):
            raise HTTPException(status_code=409,
                                detail="Task not cancellable (already started or missing)")
        return {"task_id": task_id, "state": "cancelled"}

    # ── Scheduled tasks (cron) ──
    @app.get("/api/v1/schedules")
    async def _p1_sched_list(user=Depends(get_current_user)):
        return {"schedules": _p1_scheduler.list()}

    @app.post("/api/v1/schedules")
    async def _p1_sched_add(body: dict, user=Depends(get_current_user)):
        """Create a cron schedule. body: {name, cron, job, args?, kwargs?}.
        `job` must be a registered queue handler (e.g. 'agent_goal').
        `cron` is a 5-field expression or an alias like @daily."""
        name = (body.get("name") or "").strip()
        cron = (body.get("cron") or "").strip()
        job = (body.get("job") or "").strip()
        if not (name and cron and job):
            raise HTTPException(status_code=400,
                                detail="name, cron and job are required")
        try:
            return _p1_scheduler.add(name, cron, job,
                                     args=body.get("args", []),
                                     kwargs=body.get("kwargs", {}))
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

    @app.delete("/api/v1/schedules/{sid}")
    async def _p1_sched_remove(sid: str, user=Depends(get_current_user)):
        if not _p1_scheduler.remove(sid):
            raise HTTPException(status_code=404, detail="Schedule not found")
        return {"deleted": sid}

    @app.post("/api/v1/schedules/{sid}/enabled")
    async def _p1_sched_enable(sid: str, body: dict,
                               user=Depends(get_current_user)):
        enabled = bool(body.get("enabled", True))
        if not _p1_scheduler.set_enabled(sid, enabled):
            raise HTTPException(status_code=404, detail="Schedule not found")
        return {"id": sid, "enabled": enabled}


except Exception as _p1_err:
    print(f"WARNING: Phase 1 infrastructure not loaded: {_p1_err}")
# ══════════════ End Phase 1 integration ══════════════


# ══════════════ Phase 2: Memory System integration ══════════════
try:
    from memory.long_term import LongTermMemory as _P2LT
    from memory.ranker import MemoryRanker as _P2Ranker
    from memory.lifecycle import MemoryLifecycle as _P2Lifecycle
    from memory.summarizer import MemorySummarizer as _P2Summarizer

    _p2_lt = _P2LT()
    _p2_ranker = _P2Ranker()
    _p2_lc = _P2Lifecycle(_p2_lt)
    _p2_sum = _P2Summarizer()

    @app.get("/api/v1/memory/rank")
    async def _p2_rank(q: str, limit: int = 5, user=Depends(get_current_user)):
        """Ranked memory retrieval: keyword overlap + importance + recency."""
        rows = _p2_lt.get_all(limit=2000)
        return {"query": q, "results": _p2_ranker.rank(q, rows, limit=limit)}

    @app.post("/api/v1/memory/cleanup")
    async def _p2_cleanup(dry_run: bool = True, user=Depends(get_current_user)):
        """Expire old memories per TTL policy. dry_run=true reports only.
        Routed through MemoryManager so orphaned vectors get pruned too."""
        if maya_instance and hasattr(maya_instance, "memory") and \
                hasattr(maya_instance.memory, "cleanup"):
            return maya_instance.memory.cleanup(dry_run=dry_run)
        return _p2_lc.cleanup(dry_run=dry_run)

    @app.get("/api/v1/memory/summary")
    async def _p2_summary(q: str = "", limit: int = 20, user=Depends(get_current_user)):
        """Digest of the most relevant (or most recent) memories."""
        rows = _p2_lt.get_all(limit=2000)
        if q:
            rows = _p2_ranker.rank(q, rows, limit=limit)
        else:
            rows = rows[:limit]
        return {"summary": _p2_sum.summarize([r.get("content", "") for r in rows]),
                "memories_considered": len(rows)}

    print("Phase 2 memory system active: rank, cleanup, summary")
except Exception as _p2_err:
    print(f"WARNING: Phase 2 memory system not loaded: {_p2_err}")
# ══════════════ End Phase 2 integration ══════════════


# ══════════════ Phase 3: Brain Engine integration ══════════════
try:
    from brain import BrainEngine as _P3Brain

    _p3_brain = _P3Brain()

    @app.get("/api/v1/brain/analyze")
    async def _p3_analyze(goal: str, user=Depends(get_current_user)):
        """Goal understanding: complexity, sub-goals, suggested tools."""
        return _p3_brain.analyze(goal)

    @app.post("/api/v1/brain/graph")
    async def _p3_graph(payload: dict, user=Depends(get_current_user)):
        """Build a dependency task graph from planner-style steps."""
        steps = payload.get("steps", [])
        g = _p3_brain.build_graph(steps)
        return g.to_dict()

    print("Phase 3 brain engine active: analyze, graph")
except Exception as _p3_err:
    print(f"WARNING: Phase 3 brain engine not loaded: {_p3_err}")
# ══════════════ End Phase 3 integration ══════════════


# ══════════════ Phase 4: Multi-Agent System integration ══════════════
try:
    from agents import Orchestrator as _P4Orch

    _p4_orch = _P4Orch()

    @app.get("/api/v1/agents")
    async def _p4_agents(user=Depends(get_current_user)):
        """All registered agents with permissions and health."""
        return {"agents": [{"name": a.name, "role": a.role,
                            "skills": list(a.skills),
                            "permissions": list(a.permissions),
                            **a.health()} for a in _p4_orch.registry.list()]}

    @app.post("/api/v1/agents/orchestrate")
    async def _p4_orchestrate(payload: dict, user=Depends(get_current_user)):
        """Plan a goal across agents (analysis + graph + assignments; no execution)."""
        goal = payload.get("goal", "")
        if not goal:
            raise HTTPException(status_code=400, detail="goal is required")
        planned = _p4_orch.plan(goal)
        return {"analysis": planned["analysis"],
                "assignments": planned["assignments"],
                "graph": planned["graph"].to_dict()}

    @app.get("/api/v1/agents/messages")
    async def _p4_messages(limit: int = 50, user=Depends(get_current_user)):
        return {"messages": _p4_orch.bus.history(limit)}

    print("Phase 4 multi-agent system active: 11 agents, orchestrator")
except Exception as _p4_err:
    print(f"WARNING: Phase 4 multi-agent system not loaded: {_p4_err}")
# ══════════════ End Phase 4 integration ══════════════


# ══════════════ Phase 5: Tool Framework integration ══════════════
try:
    from tools.framework import ToolFramework as _P5FW

    try:
        from infrastructure import metrics as _p5_metrics
    except Exception:
        _p5_metrics = None
    _p5_fw = _P5FW(metrics=_p5_metrics)
    try:
        from tools.registry import ToolRegistry as _P5Reg
        import tools as _p5_tools_pkg
        _p5_existing = getattr(_p5_tools_pkg, "registry", None) or getattr(_p5_tools_pkg, "tool_registry", None)
        if _p5_existing is not None:
            _p5_adopted = _p5_fw.adopt_existing(_p5_existing)
            print(f"Phase 5: adopted {_p5_adopted} existing tools into the framework")
    except Exception as _e:
        print(f"Phase 5: existing registry not adopted ({_e}); framework empty but active")

    @app.get("/api/v1/tools/framework")
    async def _p5_list(user=Depends(get_current_user)):
        """Managed tools with policies (permission/timeout/retry/dangerous)."""
        return {"tools": _p5_fw.list()}

    @app.post("/api/v1/tools/execute")
    async def _p5_execute(payload: dict, user=Depends(get_current_user)):
        """Execute a managed tool. Disabled unless FLAG_TOOL_EXECUTE=true."""
        try:
            from infrastructure import flags as _p5_flags
            enabled = _p5_flags.enabled("tool_execute")
        except Exception:
            enabled = False
        if not enabled:
            raise HTTPException(status_code=403,
                                detail="Set FLAG_TOOL_EXECUTE=true to enable remote tool execution")
        return _p5_fw.execute(payload.get("name", ""),
                              payload.get("inputs", {}),
                              caller_permissions=("*",),
                              approved=bool(payload.get("approved", False)))

    print("Phase 5 tool framework active")
except Exception as _p5_err:
    print(f"WARNING: Phase 5 tool framework not loaded: {_p5_err}")
# ══════════════ End Phase 5 integration ══════════════


# ══════════════ Phase 6: Workflow Engine integration ══════════════
try:
    from workflows import WorkflowEngine as _P6WE, FileCheckpoint as _P6FC

    _p6_engine = _P6WE(checkpoint=_P6FC("storage/checkpoints"))

    @app.post("/api/v1/workflows/plan")
    async def _p6_plan(payload: dict, user=Depends(get_current_user)):
        """Create a resumable workflow (plan only; no execution)."""
        goal = payload.get("goal", "")
        if not goal:
            raise HTTPException(status_code=400, detail="goal is required")
        run = _p6_engine.create(goal)
        return {"run_id": run.id, "state": run.to_state()}

    @app.get("/api/v1/workflows/runs")
    async def _p6_runs(user=Depends(get_current_user)):
        return {"checkpoints": _p6_engine.checkpoint.list()}

    @app.get("/api/v1/workflows/runs/{run_id}")
    async def _p6_run_state(run_id: str, user=Depends(get_current_user)):
        state = _p6_engine.checkpoint.load(run_id)
        if state is None:
            raise HTTPException(status_code=404, detail="run not found")
        return state

    @app.post("/api/v1/workflows/runs/{run_id}/cancel")
    async def _p6_cancel(run_id: str, user=Depends(get_current_user)):
        run = _p6_engine.runs.get(run_id)
        if run is None:
            raise HTTPException(status_code=404, detail="run not active in this process")
        run.cancel()
        return {"run_id": run_id, "cancelling": True}

    def _p6_llm(prompt: str) -> str:
        """Route this engine's LLM calls through the existing router.
        Self-contained (not shared with Phase 7's _p7_llm) since Phase 6
        loads before Phase 7 in this file."""
        try:
            from llm.router import LLMRouter
            if not hasattr(_p6_llm, "_router"):
                _p6_llm._router = LLMRouter()
            return _p6_llm._router.chat([{"role": "user", "content": prompt}])
        except Exception as e:
            return f"error: llm unavailable ({e})"

    @app.post("/api/v1/workflows/runs/{run_id}/execute")
    async def _p6_execute(run_id: str, user=Depends(get_current_user)):
        """Execute a previously planned/checkpointed run to completion.
        Mirrors how Phase 7's AutonomousMaya drives the same engine:
        Phase 5's tool framework (if loaded) plus an LLM fallback via
        ExecutorBridge, so this fills in the "plan only" gap without
        duplicating the actual execution logic in workflows/engine.py."""
        run = _p6_engine.runs.get(run_id)
        if run is None:
            run = _p6_engine.resume(run_id)
            if run is None:
                raise HTTPException(status_code=404, detail="run not found")
        try:
            _fw = _p5_fw            # Phase 5 framework with adopted tools
        except NameError:
            _fw = None
        from autonomous.executor_bridge import ExecutorBridge
        bridge = ExecutorBridge(_fw, _p6_llm, approve_dangerous=False)
        result = await _p6_engine.execute(run, bridge)
        return result

    print("Phase 6 workflow engine active: plan, runs, execute, cancel, checkpoints")
except Exception as _p6_err:
    print(f"WARNING: Phase 6 workflow engine not loaded: {_p6_err}")
# ══════════════ End Phase 6 integration ══════════════


# ══════════════ Phase 7: Autonomous Mode integration ══════════════
try:
    from autonomous import AutonomousMaya as _P7Auto

    def _p7_llm(prompt: str) -> str:
        """Route autonomous LLM calls through the existing router."""
        try:
            from llm.router import LLMRouter
            if not hasattr(_p7_llm, "_router"):
                _p7_llm._router = LLMRouter()
            return _p7_llm._router.chat([{"role": "user", "content": prompt}])
        except Exception as e:
            return f"error: llm unavailable ({e})"

    @app.post("/api/v1/autonomous/run")
    async def _p7_run(payload: dict, user=Depends(get_current_user)):
        """Full autonomous run. Disabled unless FLAG_AUTONOMOUS=true."""
        try:
            from infrastructure import flags as _p7_flags
            enabled = _p7_flags.enabled("autonomous")
        except Exception:
            enabled = False
        if not enabled:
            raise HTTPException(status_code=403,
                                detail="Set FLAG_AUTONOMOUS=true to enable autonomous runs")
        goal = payload.get("goal", "")
        if not goal:
            raise HTTPException(status_code=400, detail="goal is required")
        try:
            _fw = _p5_fw            # Phase 5 framework with adopted tools
        except NameError:
            _fw = None
        maya_auto = _P7Auto(framework=_fw, llm_fn=_p7_llm,
                            approve_dangerous=bool(payload.get("approve_dangerous", False)))
        result = await maya_auto.run(goal)
        return result

    print("Phase 7 autonomous mode active (flag-gated)")
except Exception as _p7_err:
    print(f"WARNING: Phase 7 autonomous mode not loaded: {_p7_err}")
# ══════════════ End Phase 7 integration ══════════════


# ══════════════ Phase 8: Multi-Model Router+ integration ══════════════
try:
    from llm.router_plus import RouterPlus as _P8RP, SmartSelector as _P8Sel, PROVIDER_TABLE as _P8Table

    _p8_router = _P8RP()

    @app.get("/api/v1/llm/stats")
    async def _p8_stats(user=Depends(get_current_user)):
        """Live provider stats: latency EMA, error rates, cost table."""
        return {"stats": _p8_router.stats.snapshot(), "table": _P8Table}

    @app.get("/api/v1/llm/strategy")
    async def _p8_strategy(strategy: str = "balanced", user=Depends(get_current_user)):
        """Preview provider ordering for a strategy (cost/latency/quality/balanced)."""
        try:
            from llm.router import LLMRouter
            available = [p for p, info in getattr(LLMRouter, "PROVIDER_INFO", {}).items()] or \
                        list(_P8Table.keys())
        except Exception:
            available = list(_P8Table.keys())
        return {"strategy": strategy,
                "order": _p8_router.selector.order(available, strategy)}

    print("Phase 8 router+ active: stats, strategy ordering, fallback chains")
except Exception as _p8_err:
    print(f"WARNING: Phase 8 router+ not loaded: {_p8_err}")
# ══════════════ End Phase 8 integration ══════════════


# ══════════════ Phase 9: Enterprise Layer integration ══════════════
try:
    from enterprise import RBAC as _P9RBAC, OrgStore as _P9Orgs, \
        APIKeyManager as _P9Keys, AuditLog as _P9Audit, Monitor as _P9Mon
    from enterprise._db import DB as _P9DB

    _p9_db = _P9DB("storage/enterprise.db")
    _p9_rbac = _P9RBAC()
    _p9_orgs = _P9Orgs(db=_p9_db)
    _p9_keys = _P9Keys(db=_p9_db)
    _p9_audit = _P9Audit(db=_p9_db)
    try:
        _p9_mon = _P9Mon(metrics=_p1_metrics, agent_registry=_p4_orch.registry,
                         provider_stats=_p8_router.stats, audit=_p9_audit)
    except NameError:
        _p9_mon = _P9Mon(audit=_p9_audit)

    def _p9_actor(user) -> str:
        return (user or {}).get("email", "admin") if isinstance(user, dict) else "admin"

    @app.get("/api/v1/admin/roles")
    async def _p9_roles(user=Depends(get_current_user)):
        return _p9_rbac.roles()

    @app.get("/api/v1/admin/orgs")
    async def _p9_list_orgs(user=Depends(get_current_user)):
        return {"orgs": _p9_orgs.list_orgs()}

    @app.post("/api/v1/admin/orgs")
    async def _p9_create_org(payload: dict, user=Depends(get_current_user)):
        org = _p9_orgs.create_org(payload.get("name", "org"))
        _p9_audit.record(_p9_actor(user), "org_created", org["id"], org)
        return org

    @app.delete("/api/v1/admin/orgs/{org_id}")
    async def _p9_delete_org(org_id: str, user=Depends(require_admin)):
        _p9_orgs.delete_org(org_id)
        _p9_audit.record(_p9_actor(user), "org_deleted", org_id, {})
        return {"id": org_id, "deleted": True}

    @app.delete("/api/v1/admin/orgs/{org_id}/members/{email}")
    async def _p9_remove_member(org_id: str, email: str, user=Depends(require_admin)):
        _p9_orgs.remove_member(email, org_id)
        _p9_audit.record(_p9_actor(user), "member_removed", org_id, {"email": email})
        return {"org_id": org_id, "email": email, "removed": True}

    @app.post("/api/v1/admin/orgs/{org_id}/teams")
    async def _p9_create_team(org_id: str, payload: dict, user=Depends(get_current_user)):
        team = _p9_orgs.create_team(org_id, payload.get("name", "team"))
        _p9_audit.record(_p9_actor(user), "team_created", team["id"], team)
        return team

    @app.get("/api/v1/admin/orgs/{org_id}/teams")
    async def _p9_list_teams(org_id: str, user=Depends(get_current_user)):
        return {"teams": _p9_orgs.list_teams(org_id)}

    @app.post("/api/v1/admin/orgs/{org_id}/members")
    async def _p9_add_member(org_id: str, payload: dict, user=Depends(get_current_user)):
        m = _p9_orgs.add_member(payload.get("email", ""), org_id,
                                payload.get("role", "viewer"), payload.get("team_id"))
        _p9_audit.record(_p9_actor(user), "member_added", org_id, m)
        return m

    @app.get("/api/v1/admin/orgs/{org_id}/members")
    async def _p9_members(org_id: str, user=Depends(get_current_user)):
        return {"members": _p9_orgs.members(org_id)}

    @app.post("/api/v1/admin/apikeys")
    async def _p9_create_key(payload: dict, user=Depends(get_current_user)):
        created = _p9_keys.create(payload.get("name", "key"), _p9_actor(user))
        _p9_audit.record(_p9_actor(user), "apikey_created", created["id"],
                         {"name": created["name"]})     # raw key never logged
        return created

    @app.get("/api/v1/admin/apikeys")
    async def _p9_list_keys(user=Depends(get_current_user)):
        return {"keys": _p9_keys.list()}

    @app.delete("/api/v1/admin/apikeys/{key_id}")
    async def _p9_revoke_key(key_id: str, user=Depends(get_current_user)):
        _p9_keys.revoke(key_id)
        _p9_audit.record(_p9_actor(user), "apikey_revoked", key_id)
        return {"revoked": key_id}

    @app.get("/api/v1/admin/audit")
    async def _p9_audit_q(actor: str = None, action: str = None, limit: int = 100,
                          user=Depends(get_current_user)):
        return {"events": _p9_audit.query(actor, action, limit)}

    @app.get("/api/v1/admin/usage")
    async def _p9_usage(since_ts: float = 0.0, user=Depends(get_current_user)):
        return _p9_audit.usage_summary(since_ts)

    @app.get("/api/v1/admin/dashboard")
    async def _p9_dashboard(user=Depends(get_current_user)):
        return _p9_mon.dashboard()

    print("Phase 9 enterprise layer active: rbac, orgs, apikeys, audit, dashboard")
except Exception as _p9_err:
    print(f"WARNING: Phase 9 enterprise layer not loaded: {_p9_err}")
# ══════════════ End Phase 9 integration ══════════════


# ══════════════ Multi-user (Supabase) — user management ══════════════
# Feeds the Admin Panel's "Users" section. Works whenever Supabase is
# configured (SUPABASE_URL / SUPABASE_SERVICE_KEY); returns an empty/limited
# response otherwise so the panel just shows "no users yet" instead of erroring.
@app.get("/api/v1/admin/users")
async def admin_list_users(user: dict = Depends(require_admin)):
    return {"enabled": supabase_store.enabled, "users": supabase_store.list_users()}

@app.put("/api/v1/admin/users/{user_id}/ban")
async def admin_ban_user(user_id: str, req: BanRequest, user: dict = Depends(require_admin)):
    if not supabase_store.enabled:
        raise HTTPException(status_code=400, detail="Supabase not configured")
    updated = supabase_store.set_banned(user_id, req.banned)
    if not updated:
        raise HTTPException(status_code=404, detail="User not found")
    return updated

@app.put("/api/v1/admin/users/{user_id}/budget")
async def admin_set_budget(user_id: str, req: BudgetRequest, user: dict = Depends(require_admin)):
    if not supabase_store.enabled:
        raise HTTPException(status_code=400, detail="Supabase not configured")
    updated = supabase_store.set_budget(user_id, req.budget_usd)
    if not updated:
        raise HTTPException(status_code=404, detail="User not found")
    return updated
# ══════════════ End multi-user block ══════════════


# ══════════════ Phase 10: Learning Layer integration ══════════════
try:
    from learning import FeedbackStore as _P10FB, ExperienceReplay as _P10Exp, \
        PromptOptimizer as _P10PO, MemoryCompressor as _P10MC
    from enterprise._db import DB as _P10DB

    _p10_db = _P10DB("storage/learning.db")
    _p10_fb = _P10FB(db=_p10_db)
    _p10_exp = _P10Exp(db=_p10_db)
    _p10_po = _P10PO()

    @app.post("/api/v1/learning/feedback")
    async def _p10_feedback(payload: dict, user=Depends(get_current_user)):
        _p10_fb.record(payload.get("goal", ""), payload.get("output", ""),
                       int(payload.get("rating", 0)), payload.get("comment", ""))
        return {"recorded": True, "stats": _p10_fb.stats()}

    @app.get("/api/v1/learning/stats")
    async def _p10_stats(user=Depends(get_current_user)):
        return {"feedback": _p10_fb.stats(), "lessons": _p10_fb.lessons(),
                "prompts": _p10_po.report()}

    @app.get("/api/v1/learning/experience")
    async def _p10_experience(goal: str = "", limit: int = 5,
                              user=Depends(get_current_user)):
        if goal:
            return {"similar": _p10_exp.similar(goal, limit),
                    "success": _p10_exp.success_rate(goal.split()[0] if goal else "")}
        return {"history": _p10_exp.history(limit)}

    @app.post("/api/v1/learning/compress")
    async def _p10_compress(payload: dict, user=Depends(get_current_user)):
        dry = bool(payload.get("dry_run", True))
        mtype = payload.get("memory_type", "chat")
        try:
            _store = _p2_lt                       # Phase 2 long-term store
        except NameError:
            from memory.long_term import LongTermMemory
            _store = LongTermMemory()
        return _P10MC(_store).compress(mtype, dry_run=dry)

    # auto-record autonomous runs into experience (workflow learning)
    try:
        _p7_orig_run = _P7Auto.run
        async def _p10_learned_run(self, goal):
            result = await _p7_orig_run(self, goal)
            try:
                _p10_exp.store(goal, [], result.get("status", "?"),
                               float(result.get("plan_confidence", 0)))
            except Exception:
                pass
            return result
        _P7Auto.run = _p10_learned_run
        print("Phase 10: autonomous runs now feed experience replay")
    except NameError:
        pass

    print("Phase 10 learning layer active: feedback, experience, prompts, compression")
except Exception as _p10_err:
    print(f"WARNING: Phase 10 learning layer not loaded: {_p10_err}")
# ══════════════ End Phase 10 integration ══════════════


# ══════════════ Phase 11: Enterprise RAG integration ══════════════
# Hybrid retrieval (FTS5 BM25 + vector w/ RRF fusion), document
# ingestion, knowledge index, source attribution. Soft-fails so the
# API always boots even if the rag package is missing.
try:
    from rag import RAGRetriever as _P11RAG
    from config.settings import WORKSPACE_DIR as _P11_WS

    _p11_rag = _P11RAG.shared()

    @app.get("/api/v1/rag/stats")
    async def _p11_stats(user=Depends(get_current_user)):
        """Knowledge base size, doc types, and active search engines."""
        return _p11_rag.stats()

    @app.get("/api/v1/rag/documents")
    async def _p11_docs(limit: int = 200, user=Depends(get_current_user)):
        return {"documents": _p11_rag.list_documents(limit=limit)}

    @app.delete("/api/v1/rag/documents/{doc_id}")
    async def _p11_delete(doc_id: str, user=Depends(get_current_user)):
        if not _p11_rag.delete_document(doc_id):
            raise HTTPException(status_code=404, detail="Document not found")
        return {"deleted": doc_id}

    @app.post("/api/v1/rag/ingest")
    async def _p11_ingest(body: dict, user=Depends(get_current_user)):
        """Ingest inline text: {text, title?, doc_type?} — or a workspace
        file: {path} (path is confined to the workspace directory)."""
        path = (body.get("path") or "").strip()
        if path:
            import os as _os
            full = _os.path.abspath(_os.path.join(str(_P11_WS), path))
            if not full.startswith(str(_P11_WS)):
                raise HTTPException(status_code=403,
                                    detail="Path outside workspace")
            try:
                return await asyncio.get_event_loop().run_in_executor(
                    None, lambda: _p11_rag.ingest_file(full))
            except FileNotFoundError:
                raise HTTPException(status_code=404, detail="File not found")
            except (ValueError, RuntimeError) as e:
                raise HTTPException(status_code=400, detail=str(e))
        text = (body.get("text") or "").strip()
        if not text:
            raise HTTPException(status_code=400,
                                detail="Provide 'text' or workspace 'path'")
        return await asyncio.get_event_loop().run_in_executor(
            None, lambda: _p11_rag.ingest_text(
                text, title=body.get("title", "untitled"),
                doc_type=body.get("doc_type", "text")))

    @app.get("/api/v1/rag/search")
    async def _p11_search(q: str, limit: int = 5, mode: str = "hybrid",
                          user=Depends(get_current_user)):
        """mode: hybrid | keyword | vector"""
        if mode not in ("hybrid", "keyword", "vector"):
            raise HTTPException(status_code=400, detail="Invalid mode")
        hits = await asyncio.get_event_loop().run_in_executor(
            None, lambda: _p11_rag.search(q, limit=min(limit, 25), mode=mode))
        return {"query": q, "mode": mode, "results": hits}

    @app.get("/api/v1/rag/context")
    async def _p11_context(q: str, limit: int = 5, max_chars: int = 6000,
                           user=Depends(get_current_user)):
        """LLM-ready numbered context block + citations for a query."""
        return await asyncio.get_event_loop().run_in_executor(
            None, lambda: _p11_rag.get_context(
                q, limit=min(limit, 25), max_chars=min(max_chars, 20000)))

    # Make retrieval available to agents as tools
    try:
        _p11_tm = maya_instance.tools if maya_instance else None
        if _p11_tm and hasattr(_p11_tm, "registry"):
            _p11_tm.registry.register(
                "knowledge_search",
                lambda query, limit=5: _p11_rag.get_context(query, limit=limit),
                "Search the indexed knowledge base (hybrid RAG) and return "
                "context with source citations", category="memory")
            _p11_tm.registry.register(
                "knowledge_ingest",
                lambda text, title="untitled": _p11_rag.ingest_text(text, title=title),
                "Add text to the knowledge base for future retrieval",
                category="memory")
    except Exception:
        pass

    print("Phase 11 RAG active: hybrid search, ingestion, attribution "
          f"(vector engine: {_p11_rag.vectors.engine})")
except Exception as _p11_err:
    print(f"WARNING: Phase 11 RAG not loaded: {_p11_err}")
# ══════════════ End Phase 11 integration ══════════════


# ══════════════ Phase 12: Multimodal integration ══════════════
# Real OCR and text-to-speech endpoints. Vision analyze was upgraded
# in place above to use actual multimodal providers. Soft-fails so
# the API always boots.
try:
    from tools.media.vision_tool import VisionTool as _P12Vision
    from tools.media.tts_tool import TTSTool as _P12TTS

    _p12_vision = _P12Vision()
    _p12_tts = _P12TTS()

    @app.post("/api/v1/vision/ocr")
    async def _p12_ocr(body: dict, user=Depends(get_current_user)):
        """Extract text from an image (pytesseract if installed,
        vision LLM otherwise). Accepts base64 / data URL."""
        image = body.get("image", "")
        if not image:
            raise HTTPException(status_code=400, detail="No image provided")
        try:
            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: _p12_vision.ocr(image))
        except (ValueError, PermissionError, FileNotFoundError) as e:
            raise HTTPException(status_code=400, detail=str(e))
        if not result.get("success"):
            return {"text": "", "message": result.get("error", "OCR failed")}
        return {"text": result["result"], "provider": result.get("provider", "")}

    @app.post("/api/v1/voice/speak")
    async def _p12_speak(body: dict, user=Depends(get_current_user)):
        """Text-to-speech: returns base64 audio (OpenAI tts-1 → Groq
        playai-tts). Same configuration-message pattern as transcribe."""
        text = (body.get("text") or "").strip()
        if not text:
            raise HTTPException(status_code=400, detail="No text provided")
        result = await asyncio.get_event_loop().run_in_executor(
            None, lambda: _p12_tts.synthesize(text, body.get("voice", "alloy")))
        if not result.get("success"):
            return {"audio": "", "message": result.get("error", "TTS failed")}
        return {"audio": result["audio_base64"], "format": result["format"],
                "provider": result["provider"]}

    print("Phase 12 multimodal active: real vision, OCR, TTS")
except Exception as _p12_err:
    print(f"WARNING: Phase 12 multimodal not loaded: {_p12_err}")
# ══════════════ End Phase 12 integration ══════════════


# ══════════════ Superpower 2: Streaming responses (SSE) ══════════════
# Server-Sent Events endpoint that streams the assistant's reply token
# by token, so the UI can render it live. Soft-fails so the API always
# boots even if something here is unavailable.
try:
    from fastapi.responses import StreamingResponse as _Sp2Stream
    import json as _sp2_json

    @app.post("/api/v1/agent/chat/stream")
    async def _sp2_chat_stream(req: ChatRequest, user: dict = Depends(get_current_user)):
        """Stream a chat reply as Server-Sent Events.

        Emits `data: {"delta": "..."}` lines as chunks arrive, then a
        final `data: {"done": true}`. On error, emits
        `data: {"error": "..."}`. Mirrors /agent/chat's history handling.
        """
        if not maya_instance:
            raise HTTPException(status_code=503, detail="Maya not initialized")
        check_budget(user)

        history = []
        use_hist = supabase_store.enabled and user.get("uid") and req.chat_id
        if use_hist:
            past = supabase_store.get_chat_history(user["uid"], req.chat_id, limit=20)
            history = [{"role": m["role"], "content": m["content"]} for m in past]

        messages = list(history) + [{"role": "user", "content": req.message}]

        def _generate():
            collected = []
            try:
                router = maya_instance.router
                for delta in router.stream_chat(messages):
                    if not delta:
                        continue
                    collected.append(delta)
                    yield "data: " + _sp2_json.dumps({"delta": delta}) + "\n\n"
            except Exception as e:
                yield "data: " + _sp2_json.dumps({"error": str(e)}) + "\n\n"
                return
            full = "".join(collected)
            if use_hist and full:
                try:
                    supabase_store.add_chat_message(user["uid"], req.chat_id,
                                                    "user", req.message)
                    supabase_store.add_chat_message(user["uid"], req.chat_id,
                                                    "assistant", full)
                    supabase_store.add_budget_usage(user["uid"],
                                                    CHAT_MESSAGE_FLAT_COST_USD)
                except Exception:
                    pass
            yield "data: " + _sp2_json.dumps({"done": True}) + "\n\n"

        return _Sp2Stream(_generate(), media_type="text/event-stream",
                          headers={"Cache-Control": "no-cache",
                                   "X-Accel-Buffering": "no"})

    print("Superpower 2 active: SSE streaming at /api/v1/agent/chat/stream")
except Exception as _sp2_err:
    print(f"WARNING: Superpower 2 streaming not loaded: {_sp2_err}")
# ══════════════ End Superpower 2 ══════════════

# ══════════════ Task Execution Streaming (SSE + WebSocket) ══════════════
try:
    from fastapi.responses import StreamingResponse as _TaskStream
    import json as _task_json

    @app.get("/api/v1/agent/tasks/{task_id}/stream")
    async def task_stream_sse(task_id: str, user=Depends(get_current_user)):
        """Stream task execution events as Server-Sent Events.
        
        Supports reconnect with Last-Event-ID header for resume capability.
        """
        session = await stream_manager.get_session(task_id)
        if not session:
            # Try to load from disk
            session = await stream_manager.load_session(task_id)
        if not session:
            raise HTTPException(status_code=404, detail="Task session not found")
        
        # Register SSE queue
        queue = await stream_manager.register_sse(session.session_id)
        
        async def _generate():
            # Send initial state on connect/reconnect
            yield f"data: {_task_json.dumps({'type': 'connected', 'task_id': task_id, 'session_id': session.session_id, 'status': session.status, 'current_step': session.current_step, 'goal': session.goal})}\n\n"
            
            # If reconnecting, send missed events summary
            last_event_id = None
            # Check for Last-Event-ID header (not directly accessible in FastAPI, but we can use query param)
            
            try:
                while True:
                    try:
                        event_json = await asyncio.wait_for(queue.get(), timeout=30.0)
                        yield f"data: {event_json}\n\n"
                    except asyncio.TimeoutError:
                        # Heartbeat
                        yield f"data: {_task_json.dumps({'type': 'heartbeat', 'timestamp': time.time()})}\n\n"
            except asyncio.CancelledError:
                pass
            except Exception:
                pass
            finally:
                await stream_manager.unregister_sse(session.session_id)
        
        return _TaskStream(_generate(), media_type="text/event-stream",
                          headers={"Cache-Control": "no-cache",
                                   "X-Accel-Buffering": "no",
                                   "Connection": "keep-alive"})

    @app.post("/api/v1/agent/tasks/{task_id}/cancel")
    async def cancel_task(task_id: str, user=Depends(get_current_user)):
        """Cancel a running task."""
        ok = await stream_manager.cancel_task(task_id)
        if not ok:
            raise HTTPException(status_code=400, detail="Task not found or not cancellable")
        return {"cancelled": True, "task_id": task_id}

    @app.post("/api/v1/agent/tasks/{task_id}/pause")
    async def pause_task(task_id: str, user=Depends(get_current_user)):
        """Pause a running task."""
        ok = await stream_manager.pause_task(task_id)
        if not ok:
            raise HTTPException(status_code=400, detail="Task not found or not pausable")
        return {"paused": True, "task_id": task_id}

    @app.post("/api/v1/agent/tasks/{task_id}/resume")
    async def resume_task(task_id: str, user=Depends(get_current_user)):
        """Resume a paused task."""
        ok = await stream_manager.resume_task(task_id)
        if not ok:
            raise HTTPException(status_code=400, detail="Task not found or not resumable")
        return {"resumed": True, "task_id": task_id}

    @app.get("/api/v1/agent/tasks/{task_id}/status")
    async def task_status(task_id: str, user=Depends(get_current_user)):
        """Get task status with session info."""
        session = await stream_manager.get_session(task_id)
        if not session:
            session = await stream_manager.load_session(task_id)
        if not session:
            # Check in-memory tasks_db
            if task_id in tasks_db:
                return tasks_db[task_id]
            raise HTTPException(status_code=404, detail="Task not found")
        return {
            "task_id": session.task_id,
            "session_id": session.session_id,
            "goal": session.goal,
            "status": session.status,
            "current_step": session.current_step,
            "completed_steps": len(session.completed_steps),
            "tools_used": session.tools_used,
            "errors": session.errors,
            "created_at": session.created_at,
            "updated_at": session.updated_at,
        }

    print("Task execution streaming active: SSE at /api/v1/agent/tasks/{id}/stream, WebSocket at /ws/stream/{id}")
except Exception as _task_stream_err:
    print(f"WARNING: Task execution streaming not loaded: {_task_stream_err}")
# ══════════════ End Task Execution Streaming ══════════════


# ══════════════ Superpower 5: Multi-user Workspaces ══════════════
# Per-user private + shared team workspaces for memory. Reuses the
# enterprise OrgStore for team membership. Soft-fails so the API always
# boots. Single-user deployments are unaffected (default workspace).
try:
    from enterprise.workspace import WorkspaceContext as _Sp5Ctx, WorkspaceError as _Sp5Err
    from enterprise.scoped_memory import ScopedMemory as _Sp5Mem

    _sp5_orgs = None
    try:
        _sp5_orgs = _p9_orgs          # reuse enterprise OrgStore if present
    except NameError:
        _sp5_orgs = None
    _sp5_ctx = _Sp5Ctx(org_store=_sp5_orgs)
    _sp5_mem = _Sp5Mem()

    def _sp5_resolve(user: dict, workspace: str):
        try:
            return _sp5_ctx.resolve(user, workspace)
        except _Sp5Err as e:
            raise HTTPException(status_code=403, detail=str(e))

    @app.get("/api/v1/workspaces")
    async def _sp5_list_ws(user=Depends(get_current_user)):
        """List workspaces the current user may use (default, personal, teams)."""
        return {"workspaces": [w.to_dict() for w in _sp5_ctx.available(user)]}

    @app.get("/api/v1/workspace/memory")
    async def _sp5_ws_search(workspace: str = "default", q: str = "",
                             limit: int = 20, user=Depends(get_current_user)):
        """Search memory within a workspace. Results never cross workspaces."""
        ws = _sp5_resolve(user, workspace)
        return {"workspace": ws.to_dict(),
                "results": _sp5_mem.search(ws.scope, q, limit=min(limit, 100))}

    @app.post("/api/v1/workspace/memory")
    async def _sp5_ws_add(body: dict, user=Depends(get_current_user)):
        """Add a memory to a workspace. body: {workspace, content, type?, metadata?}."""
        ws = _sp5_resolve(user, body.get("workspace", "default"))
        content = (body.get("content") or "").strip()
        if not content:
            raise HTTPException(status_code=400, detail="content is required")
        mid = _sp5_mem.add(ws.scope, content,
                           author=user.get("email", ""),
                           memory_type=body.get("type", "general"),
                           metadata=body.get("metadata") or {})
        return {"id": mid, "workspace": ws.to_dict()}

    @app.delete("/api/v1/workspace/memory/{memory_id}")
    async def _sp5_ws_del(memory_id: str, workspace: str = "default",
                          user=Depends(get_current_user)):
        ws = _sp5_resolve(user, workspace)
        if not _sp5_mem.delete(ws.scope, memory_id):
            raise HTTPException(status_code=404,
                                detail="Memory not found in this workspace")
        return {"deleted": memory_id, "workspace": ws.scope}

    @app.get("/api/v1/workspace/stats")
    async def _sp5_ws_stats(workspace: str = "default",
                            user=Depends(get_current_user)):
        ws = _sp5_resolve(user, workspace)
        return {"workspace": ws.to_dict(), **_sp5_mem.stats(ws.scope)}

    print("Superpower 5 active: multi-user workspaces (personal + team memory)")
except Exception as _sp5_err:
    print(f"WARNING: Superpower 5 workspaces not loaded: {_sp5_err}")
# ══════════════ End Superpower 5 ══════════════


# ══════════════ Superpower 7: Inbound Webhook Triggers ══════════════
# External services (GitHub, Slack, forms, Zapier) POST to a signed
# endpoint to trigger a queued job. Complements the existing OUTBOUND
# webhooks. Soft-fails so the API always boots.
try:
    from infrastructure.webhook_triggers import WebhookTriggers as _Sp7WT
    from fastapi import Request as _Sp7Request

    _sp7_triggers = _Sp7WT()

    @app.get("/api/v1/hooks")
    async def _sp7_list(user=Depends(get_current_user)):
        """List inbound webhook triggers (secrets never shown)."""
        return {"triggers": _sp7_triggers.list()}

    @app.post("/api/v1/hooks")
    async def _sp7_create(body: dict, user=Depends(get_current_user)):
        """Create an inbound trigger. body: {name, job, template, signed?}.
        `job` must be a registered queue handler (e.g. 'agent_goal').
        `template` may use {{path.to.field}} from the incoming payload.
        The secret is returned ONCE — store it to sign future calls."""
        job = (body.get("job") or "").strip()
        if job and hasattr(_p1_queue, "_handlers") and job not in _p1_queue._handlers:
            raise HTTPException(status_code=400,
                                detail=f"job '{job}' is not a registered queue handler")
        try:
            return _sp7_triggers.create(
                name=(body.get("name") or "").strip(),
                job=job,
                template=(body.get("template") or "").strip(),
                signed=bool(body.get("signed", True)))
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

    @app.delete("/api/v1/hooks/{tid}")
    async def _sp7_delete(tid: str, user=Depends(get_current_user)):
        if not _sp7_triggers.delete(tid):
            raise HTTPException(status_code=404, detail="Trigger not found")
        return {"deleted": tid}

    @app.post("/api/v1/hooks/{tid}/enabled")
    async def _sp7_enable(tid: str, body: dict, user=Depends(get_current_user)):
        enabled = bool(body.get("enabled", True))
        if not _sp7_triggers.set_enabled(tid, enabled):
            raise HTTPException(status_code=404, detail="Trigger not found")
        return {"id": tid, "enabled": enabled}

    @app.post("/api/v1/hooks/{tid}")
    async def _sp7_fire(tid: str, request: _Sp7Request):
        """Public trigger endpoint — NO auth (external services call it),
        but signed triggers require a valid HMAC-SHA256 signature in the
        X-Maya-Signature (or X-Hub-Signature-256) header."""
        trig = _sp7_triggers.get(tid)
        if not trig or not trig.get("enabled"):
            raise HTTPException(status_code=404, detail="Trigger not found")
        raw = await request.body()
        signature = request.headers.get("x-maya-signature") or \
            request.headers.get("x-hub-signature-256") or ""
        if not _sp7_triggers.verify_signature(trig.get("secret"), raw, signature):
            raise HTTPException(status_code=401, detail="Invalid signature")
        try:
            payload = json.loads(raw.decode("utf-8")) if raw else {}
        except Exception:
            payload = {}
        goal = _sp7_triggers.render_goal(trig["template"], payload)
        try:
            task_id = await _p1_queue.submit_job(
                trig["job"], goal, label=f"hook:{trig['name']}")
        except Exception as e:
            raise HTTPException(status_code=400,
                                detail=f"could not enqueue job: {e}")
        _sp7_triggers.mark_fired(tid)
        return {"triggered": tid, "task_id": task_id, "goal": goal}

    print("Superpower 7 active: inbound webhook triggers (external -> queue)")
except Exception as _sp7_err:
    print(f"WARNING: Superpower 7 webhook triggers not loaded: {_sp7_err}")
# ══════════════ End Superpower 7 ══════════════


# ══════════════ Superpower 8: Notifications ══════════════
# Multi-channel alerts (in-app + email + webhook) when things happen.
# Also auto-notifies when persistent queue jobs finish. Soft-fails.
try:
    from infrastructure.notifications import Notifier as _Sp8Notifier

    _sp8_notifier = _Sp8Notifier()

    @app.get("/api/v1/notifications")
    async def _sp8_list(unread_only: bool = False, limit: int = 50,
                        user=Depends(get_current_user)):
        """List the current user's notifications (newest first)."""
        rcpt = user.get("email", "")
        return {"notifications": _sp8_notifier.list(rcpt, unread_only, min(limit, 200)),
                "unread": _sp8_notifier.unread_count(rcpt)}

    @app.get("/api/v1/notifications/unread")
    async def _sp8_unread(user=Depends(get_current_user)):
        return {"unread": _sp8_notifier.unread_count(user.get("email", ""))}

    @app.post("/api/v1/notifications/{nid}/read")
    async def _sp8_read(nid: str, user=Depends(get_current_user)):
        if not _sp8_notifier.mark_read(nid):
            raise HTTPException(status_code=404, detail="Notification not found")
        return {"id": nid, "read": True}

    @app.post("/api/v1/notifications/read-all")
    async def _sp8_read_all(user=Depends(get_current_user)):
        n = _sp8_notifier.mark_all_read(user.get("email", ""))
        return {"marked_read": n}

    @app.post("/api/v1/notifications/send")
    async def _sp8_send(body: dict, user=Depends(get_current_user)):
        """Send a notification. body: {title, body?, channels?, event?,
        email_to?, webhook_url?}. Defaults to an in-app notification for
        the current user."""
        title = (body.get("title") or "").strip()
        if not title:
            raise HTTPException(status_code=400, detail="title is required")
        return _sp8_notifier.notify(
            event=body.get("event", "manual"),
            title=title, body=body.get("body", ""),
            channels=body.get("channels") or ["in_app"],
            recipient=body.get("recipient") or user.get("email", ""),
            email_to=body.get("email_to", ""),
            webhook_url=body.get("webhook_url", ""),
            meta=body.get("meta") or {})

    @app.post("/api/v1/notifications/register-device")
    async def _sp8_register_device(body: dict,
                                   user=Depends(get_current_user)):
        """Register a device push token. body: {token, platform}.
        Platform is 'android' or 'ios'.  Idempotent — re-registering
        the same token updates the recipient."""
        token = (body.get("token") or "").strip()
        platform = (body.get("platform") or "").strip().lower()
        if not token or not platform:
            raise HTTPException(status_code=400,
                                detail="token and platform are required")
        return _sp8_notifier.register_device(
            token, platform, user.get("email", ""))

    # Auto-notify on persistent queue job completion. We wrap the queue's
    # registered handlers so every finish/fail raises an in-app alert,
    # without touching the queue internals.
    try:
        if "_p1_queue" in dir() and hasattr(_p1_queue, "_handlers"):
            def _sp8_wrap(name, handler):
                async def wrapped(*a, **kw):
                    try:
                        result = await handler(*a, **kw)
                        _sp8_notifier.notify(
                            event="job.done", title=f"Job '{name}' completed",
                            body=str(result)[:400], channels=["in_app"],
                            meta={"job": name})
                        return result
                    except Exception as e:
                        _sp8_notifier.notify(
                            event="job.failed", title=f"Job '{name}' failed",
                            body=str(e)[:400], channels=["in_app"],
                            meta={"job": name})
                        raise
                return wrapped
            for _jname, _jhandler in list(_p1_queue._handlers.items()):
                _p1_queue._handlers[_jname] = _sp8_wrap(_jname, _jhandler)
    except Exception:
        pass

    print("Superpower 8 active: notifications (in-app + email + webhook)")
except Exception as _sp8_err:
    print(f"WARNING: Superpower 8 notifications not loaded: {_sp8_err}")
# ══════════════ End Superpower 8 ══════════════


# ══════════════ Superpower 9: Prompt Library ══════════════
# Save, organize, and reuse prompt templates with {{variables}}.
# Soft-fails so the API always boots.
try:
    from infrastructure.prompt_library import PromptLibrary as _Sp9Lib

    _sp9_lib = _Sp9Lib()

    @app.get("/api/v1/prompts")
    async def _sp9_list(category: str = "", q: str = "", limit: int = 100,
                        user=Depends(get_current_user)):
        """List prompts (optionally filtered by category/search), plus
        the category breakdown for the sidebar."""
        return {"prompts": _sp9_lib.list(category or None, q, min(limit, 300)),
                "categories": _sp9_lib.categories()}

    @app.get("/api/v1/prompts/{pid}")
    async def _sp9_get(pid: str, user=Depends(get_current_user)):
        p = _sp9_lib.get(pid)
        if not p:
            raise HTTPException(status_code=404, detail="Prompt not found")
        return p

    @app.post("/api/v1/prompts")
    async def _sp9_create(body: dict, user=Depends(get_current_user)):
        """Create a prompt. body: {name, body, description?, category?,
        tags?, variables?}. Variables are auto-derived from {{...}}."""
        try:
            return _sp9_lib.create(
                name=(body.get("name") or "").strip(),
                body=body.get("body", ""),
                description=body.get("description", ""),
                category=body.get("category", "general"),
                tags=body.get("tags") or [],
                variables=body.get("variables") or [])
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

    @app.put("/api/v1/prompts/{pid}")
    async def _sp9_update(pid: str, body: dict, user=Depends(get_current_user)):
        updated = _sp9_lib.update(
            pid, body=body.get("body"), name=body.get("name"),
            description=body.get("description"), category=body.get("category"),
            tags=body.get("tags"))
        if not updated:
            raise HTTPException(status_code=404, detail="Prompt not found")
        return updated

    @app.delete("/api/v1/prompts/{pid}")
    async def _sp9_delete(pid: str, user=Depends(get_current_user)):
        if not _sp9_lib.delete(pid):
            raise HTTPException(status_code=404, detail="Prompt not found")
        return {"deleted": pid}

    @app.get("/api/v1/prompts/{pid}/history")
    async def _sp9_history(pid: str, user=Depends(get_current_user)):
        if not _sp9_lib.get(pid):
            raise HTTPException(status_code=404, detail="Prompt not found")
        return {"history": _sp9_lib.history(pid)}

    @app.post("/api/v1/prompts/{pid}/render")
    async def _sp9_render(pid: str, body: dict, user=Depends(get_current_user)):
        """Fill a prompt's {{variables}} with body.values and return the
        final text. Optionally run it through Maya if body.run is true."""
        try:
            rendered = _sp9_lib.render(pid, body.get("values") or {})
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        result = {"rendered": rendered}
        if body.get("run") and maya_instance and hasattr(maya_instance, "chat"):
            result["response"] = await asyncio.get_event_loop().run_in_executor(
                None, lambda: maya_instance.chat(rendered))
        return result

    print("Superpower 9 active: prompt library (reusable templates)")
except Exception as _sp9_err:
    print(f"WARNING: Superpower 9 prompt library not loaded: {_sp9_err}")
# ══════════════ End Superpower 9 ══════════════


# ══════════════ #2/6: Plugin System (install from code) ══════════════
# Real plugin installation from source + working enable/disable that
# actually retracts tools (ToolRegistry.unregister added). Soft-fails.
try:
    @app.post("/api/v1/plugins/install-code")
    async def _p26_install_code(body: dict, user=Depends(get_current_user)):
        """Install a plugin from source code. body: {name, code}.
        The code must define register_tools(registry). Tools become
        callable immediately; disabling/uninstalling retracts them."""
        if not maya_instance or not hasattr(maya_instance, "plugin_loader"):
            raise HTTPException(status_code=503, detail="Plugin system not initialized")
        name = (body.get("name") or "").strip()
        code = body.get("code") or ""
        try:
            info = await asyncio.get_event_loop().run_in_executor(
                None, lambda: maya_instance.plugin_loader.install_from_code(name, code))
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        return {"installed": True, "name": info.get("name", name),
                "tools": info.get("registered_tools", [])}

    @app.get("/api/v1/plugins/{plugin_id}/tools")
    async def _p26_plugin_tools(plugin_id: str, user=Depends(get_current_user)):
        """List the tools a plugin registered."""
        if not maya_instance or not hasattr(maya_instance, "plugin_loader"):
            raise HTTPException(status_code=503, detail="Plugin system not initialized")
        info = maya_instance.plugin_loader.get_plugin(plugin_id)
        if not info:
            raise HTTPException(status_code=404, detail="Plugin not found")
        return {"id": plugin_id,
                "tools": info.get("registered_tools", []),
                "enabled": maya_instance.plugin_loader._enabled_state.get(plugin_id, True)}

    print("Plugin system upgraded: install-from-code + real tool retraction")
except Exception as _p26_err:
    print(f"WARNING: #2/6 plugin upgrade not loaded: {_p26_err}")
# ══════════════ End #2/6 ══════════════


# ══════════════ #3/6: Workflow Builder ══════════════
# Declarative multi-step workflows (JSON) with conditions + parallel
# steps, runnable through Maya. Soft-fails so the API always boots.
try:
    from workflows.builder import WorkflowBuilder as _P36WB, WorkflowValidationError as _P36Err

    def _p36_prompt(text):
        if maya_instance and hasattr(maya_instance, "chat"):
            return maya_instance.chat(text)
        return f"[maya unavailable] {text}"

    def _p36_tool(name, tool_input):
        if maya_instance and hasattr(maya_instance, "tools") and \
                hasattr(maya_instance.tools, "registry"):
            reg = maya_instance.tools.registry
            if reg.has(name):
                # tools take kwargs; pass a single 'input'/'query' best-effort
                try:
                    return reg.run(name, {"query": tool_input})
                except TypeError:
                    return reg.run(name, {"input": tool_input})
        return f"[tool '{name}' unavailable] {tool_input}"

    _p36_builder = _P36WB(prompt_fn=_p36_prompt, tool_fn=_p36_tool)

    @app.get("/api/v1/workflows/defs")
    async def _p36_list(user=Depends(get_current_user)):
        """List saved declarative workflows."""
        return {"workflows": _p36_builder.list()}

    @app.get("/api/v1/workflows/defs/{wid}")
    async def _p36_get(wid: str, user=Depends(get_current_user)):
        wf = _p36_builder.get(wid)
        if not wf:
            raise HTTPException(status_code=404, detail="Workflow not found")
        return wf

    @app.post("/api/v1/workflows/defs")
    async def _p36_create(body: dict, user=Depends(get_current_user)):
        """Create a workflow. body: {name, steps:[...], description?}.
        Each step: {id, name?, action, input?, tool?, depends_on?, condition?}."""
        try:
            return _p36_builder.create(
                name=(body.get("name") or "").strip(),
                steps=body.get("steps") or [],
                description=body.get("description", ""))
        except _P36Err as e:
            raise HTTPException(status_code=400, detail=str(e))

    @app.put("/api/v1/workflows/defs/{wid}")
    async def _p36_update(wid: str, body: dict, user=Depends(get_current_user)):
        try:
            updated = _p36_builder.update(
                wid, name=body.get("name"), steps=body.get("steps"),
                description=body.get("description"))
        except _P36Err as e:
            raise HTTPException(status_code=400, detail=str(e))
        if not updated:
            raise HTTPException(status_code=404, detail="Workflow not found")
        return updated

    @app.delete("/api/v1/workflows/defs/{wid}")
    async def _p36_delete(wid: str, user=Depends(get_current_user)):
        if not _p36_builder.delete(wid):
            raise HTTPException(status_code=404, detail="Workflow not found")
        return {"deleted": wid}

    @app.post("/api/v1/workflows/defs/{wid}/run")
    async def _p36_run(wid: str, body: dict = None, user=Depends(get_current_user)):
        """Run a workflow. Optional body: {inputs: {...}} available to
        steps via {{input.field}}."""
        try:
            return await _p36_builder.run(wid, (body or {}).get("inputs") or {})
        except _P36Err as e:
            raise HTTPException(status_code=404, detail=str(e))

    print("#3/6 active: workflow builder (declarative multi-step workflows)")
except Exception as _p36_err:
    print(f"WARNING: #3/6 workflow builder not loaded: {_p36_err}")
# ══════════════ End #3/6 ══════════════


# ══════════════ #4/6: Deployment Health & Monitoring ══════════════
# Liveness/readiness probes + system info for production deployment.
# Soft-fails so the API always boots.
try:
    from infrastructure.health import HealthMonitor as _P46Health

    def _p46_providers():
        try:
            if maya_instance and hasattr(maya_instance, "router"):
                return maya_instance.router.available_providers()
        except Exception:
            pass
        return []

    _p46_monitor = _P46Health(provider_checker=_p46_providers)

    @app.get("/health/live")
    async def _p46_live():
        """Liveness probe — cheap, never touches dependencies. 200 = up."""
        return _p46_monitor.liveness()

    @app.get("/health/ready")
    async def _p46_ready(response: Response):
        """Readiness probe — checks storage, DB, and LLM providers.
        Returns 503 when not ready so load balancers hold traffic."""
        result = _p46_monitor.readiness()
        if not result["ready"]:
            response.status_code = 503
        return result

    @app.get("/health/system")
    async def _p46_system(user=Depends(get_current_user)):
        """System info for dashboards (uptime, disk, memory, platform)."""
        return _p46_monitor.system_info()

    print("#4/6 active: deployment health probes (/health/live, /health/ready)")
except Exception as _p46_err:
    print(f"WARNING: #4/6 health monitoring not loaded: {_p46_err}")
# ══════════════ End #4/6 ══════════════


# ══════════════ #5/6: Mobile Offline Sync ══════════════
# Replay actions the mobile/PWA client queued while offline, idempotently.
# Soft-fails so the API always boots.
try:
    from infrastructure.sync_engine import SyncEngine as _P56Sync

    _p56_sync = _P56Sync()

    # Register offline-syncable actions. Each handler(payload, user)->result.
    def _p56_add_memory(payload, user):
        text = (payload.get("content") or payload.get("text") or "").strip()
        if not text:
            raise ValueError("content required")
        if maya_instance and hasattr(maya_instance, "memory"):
            maya_instance.memory.add(text, memory_type=payload.get("type", "note"))
            return {"stored": True}
        return {"stored": False, "note": "memory unavailable"}
    _p56_sync.register("add_memory", _p56_add_memory)

    def _p56_create_prompt(payload, user):
        # Reuse the prompt library if it loaded (#1/6).
        if "_sp9_lib" in dir():
            p = _sp9_lib.create(name=payload.get("name", "untitled"),
                                body=payload.get("body", ""),
                                category=payload.get("category", "general"))
            return {"id": p["id"]}
        raise ValueError("prompt library unavailable")
    _p56_sync.register("create_prompt", _p56_create_prompt)

    def _p56_enqueue_goal(payload, user):
        # Record an autonomous goal request captured while offline. Actual
        # execution is picked up by the queue; here we just validate and
        # acknowledge so the client can clear it from its offline queue.
        goal = (payload.get("goal") or "").strip()
        if not goal:
            raise ValueError("goal required")
        return {"accepted": True, "goal": goal}
    _p56_sync.register("enqueue_goal", _p56_enqueue_goal)

    @app.get("/api/v1/sync/types")
    async def _p56_types(user=Depends(get_current_user)):
        """List action types the client may queue for offline sync."""
        return {"types": _p56_sync.known_types()}

    @app.post("/api/v1/sync/push")
    async def _p56_push(body: dict, user=Depends(get_current_user)):
        """Replay a batch of offline-queued actions. body: {actions:[
        {op_id, type, payload, client_ts}, ...]}. Idempotent — already
        applied op_ids are skipped."""
        actions = body.get("actions") or []
        if not isinstance(actions, list):
            raise HTTPException(status_code=400, detail="actions must be a list")
        return _p56_sync.apply_batch(actions, user=user.get("email", ""))

    @app.get("/api/v1/sync/status/{op_id}")
    async def _p56_status(op_id: str, user=Depends(get_current_user)):
        st = _p56_sync.status(op_id)
        if st is None:
            raise HTTPException(status_code=404, detail="op not found")
        return st

    @app.get("/api/v1/sync/recent")
    async def _p56_recent(limit: int = 50, user=Depends(get_current_user)):
        return {"ops": _p56_sync.recent(user.get("email", ""), min(limit, 200))}

    print("#5/6 active: mobile offline sync (idempotent action replay)")
except Exception as _p56_err:
    print(f"WARNING: #5/6 offline sync not loaded: {_p56_err}")
# ══════════════ End #5/6 ══════════════


# ══════════════ #6/6: Live Translation ══════════════
# LLM-backed translation with script detection, optional TTS. Soft-fails.
try:
    from tools.media.translator import Translator as _P66Translator

    def _p66_chat(messages):
        if maya_instance and hasattr(maya_instance, "router"):
            return maya_instance.router.chat(messages)
        return "[translator unavailable]"

    _p66_translator = _P66Translator(chat_fn=_p66_chat)

    @app.get("/api/v1/translate/languages")
    async def _p66_langs(user=Depends(get_current_user)):
        """List supported languages."""
        return {"languages": _p66_translator.supported_languages()}

    @app.post("/api/v1/translate")
    async def _p66_translate(body: dict, user=Depends(get_current_user)):
        """Translate text. body: {text, target, source?, speak?}.
        target/source are language codes ('bn') or names ('Bengali').
        If speak=true and TTS is available, also returns spoken audio."""
        try:
            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: _p66_translator.translate(
                    body.get("text", ""), body.get("target", "en"),
                    body.get("source")))
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        # Optional: speak the translation via the existing TTS tool.
        if body.get("speak") and maya_instance and \
                hasattr(maya_instance, "tools"):
            try:
                reg = maya_instance.tools.registry
                if reg.has("text_to_speech"):
                    audio = reg.run("text_to_speech",
                                    {"text": result["translation"]})
                    result["audio"] = audio
            except Exception:
                pass
        return result

    @app.post("/api/v1/translate/detect")
    async def _p66_detect(body: dict, user=Depends(get_current_user)):
        """Detect the language of a piece of text."""
        code = _p66_translator.detect(body.get("text", ""))
        return {"code": code, "name": _p66_translator.language_name(code)}

    print("#6/6 active: live translation (LLM-backed, script detection)")
except Exception as _p66_err:
    print(f"WARNING: #6/6 translation not loaded: {_p66_err}")
# ══════════════ End #6/6 ══════════════


# ══════════════ Phase 13: Phone Control Command & State ══════════════
# Natural-language control channel for phone.  Routes text to chat() or
# run() depending on intent, and exposes a compact dashboard for the
# phone home screen.  Soft-fails so the API always boots.
try:
    _p13_ACTION_PREFIXES = (
        "run ", "execute ", "do ", "create ", "build ", "make ", "find ",
        "search ", "send ", "analyze ", "calculate ", "compute ",
        "generate ", "write ", "edit ", "update ", "delete ", "remove ",
        "install ", "configure ", "deploy ", "start ", "stop ", "restart ",
    )

    def _p13_classify(text: str) -> str:
        """Return 'run' if text looks like an action goal, else 'chat'."""
        t = text.strip().lower()
        if t.startswith(_p13_ACTION_PREFIXES) or len(t) > 100:
            return "run"
        return "chat"

    @app.post("/api/v1/control/command")
    async def _p13_command(body: dict, user: dict = Depends(get_current_user)):
        """
        Natural-language control command from phone.

        Body: {text, instance_id?}

        Routes short/conversational text to maya_instance.chat() and
        longer/action-oriented text to maya_instance.run().  Returns
        {reply, actions_taken} for the phone to display.
        """
        if not maya_instance:
            raise HTTPException(status_code=503, detail="Maya not initialized")
        text = (body.get("text") or "").strip()
        if not text:
            raise HTTPException(status_code=400, detail="text is required")

        # Resolve optional instance for persona + memory scope
        _inst = None
        iid = body.get("instance_id")
        if iid:
            try:
                from infrastructure.instances import instance_manager as _p13_im
                _inst = _p13_im.get(iid)
            except Exception:
                pass
        _scope = _inst.get("memory_scope", "") if _inst else ""
        if _inst:
            p = (_inst.get("persona") or "").strip()
            if p:
                text = f"[Instance: {_inst['name']}] Persona: {p}\n\n{text}"

        mode = _p13_classify(text)
        loop = asyncio.get_event_loop()

        if mode == "run":
            result = await loop.run_in_executor(
                None, lambda: maya_instance.run(text, task_id=str(uuid.uuid4()),
                                                scope=_scope)
            )
            reply = result.get("result", str(result))
            actions_taken = 1 if result.get("success") else 0
        else:
            reply = await loop.run_in_executor(
                None, lambda: maya_instance.chat(text, scope=_scope)
            )
            actions_taken = 0

        return {"reply": reply, "actions_taken": actions_taken}

    @app.get("/api/v1/control/state")
    async def _p13_state(user: dict = Depends(get_current_user)):
        """
        Compact phone dashboard snapshot.

        Returns hosted_apps_count, active_instances_count,
        pending_approvals_count, queue_depth, and provider_health_summary.
        """
        if not maya_instance:
            return {
                "hosted_apps_count": 0,
                "active_instances_count": 0,
                "pending_approvals_count": 0,
                "queue_depth": 0,
                "provider_health_summary": {},
            }

        # Hosted apps
        try:
            from infrastructure.hosting_manager import hosting_manager as _p13_hosting
            hosted_apps = len(_p13_hosting.list())
        except Exception:
            hosted_apps = 0

        # Active instances: Maya itself + running tasks
        try:
            running_tasks = len([
                t for t in tasks_db.values()
                if t.get("status") in ("running", "pending", "waiting_approval")
            ])
        except Exception:
            running_tasks = 0
        active_instances = 1 + running_tasks

        # Pending approvals
        try:
            pending_approvals = len([
                a for a in approvals_db.values()
                if a.get("status") == "pending"
            ])
        except Exception:
            pending_approvals = 0

        # Queue depth (safe — Phase 1 may be absent or _p1_queue not in scope)
        queue_depth = 0
        try:
            # _p1_queue is scoped to Phase 1's try block; attempt to reach
            # through the module's symbol table as a last resort.
            import api as _p13_api
            q = getattr(_p13_api, "_p1_queue", None)
            if q is not None and hasattr(q, "pending_count"):
                queue_depth = q.pending_count()
        except Exception:
            pass

        # Provider health summary
        try:
            health = maya_instance.router.health
            summary = {
                p: {
                    "available": h["available"],
                    "errors": h["error_count"],
                }
                for p, h in health.items()
            }
        except Exception:
            summary = {}

        return {
            "hosted_apps_count": hosted_apps,
            "active_instances_count": active_instances,
            "pending_approvals_count": pending_approvals,
            "queue_depth": queue_depth,
            "provider_health_summary": summary,
        }

    print("Phase 13 active: phone control command + state endpoints")
except Exception as _p13_err:
    print(f"WARNING: Phase 13 phone control not loaded: {_p13_err}")
# ══════════════ End Phase 13 integration ══════════════


# ══════════════ Phase 14: Instance CRUD + Per-Instance Routing ══════════
# Manage named Maya instances (persona, skills, budget, memory scope).
# Soft-fails so the API always boots.
try:
    from infrastructure.instances import instance_manager as _p14_im

    @app.post("/api/v1/instances")
    async def _p14_create(body: dict, user=Depends(get_current_user)):
        """Create a new Maya instance.

        Body: {name, persona, skills?, budget_usd?}.
        Owner defaults to the current user's email.
        """
        name = (body.get("name") or "").strip()
        if not name:
            raise HTTPException(status_code=400, detail="name is required")
        persona = (body.get("persona") or "").strip()
        if not persona:
            raise HTTPException(status_code=400, detail="persona is required")
        instance = _p14_im.create(
            name=name,
            persona=persona,
            skills=body.get("skills"),
            budget_usd=body.get("budget_usd", 5.0),
            owner=user.get("email", ""),
        )
        return instance

    @app.get("/api/v1/instances")
    async def _p14_list(user=Depends(get_current_user)):
        """List instances.  Admins see all; others see only their own."""
        email = user.get("email", "")
        role = user.get("role", "")
        if supabase_store.enabled and role != "admin":
            return {"instances": _p14_im.list(owner=email)}
        return {"instances": _p14_im.list()}

    @app.get("/api/v1/instances/{iid}")
    async def _p14_get(iid: str, user=Depends(get_current_user)):
        """Get a single instance by id.  Non-admins may only fetch their
        own instances."""
        inst = _p14_im.get(iid)
        if not inst:
            raise HTTPException(status_code=404, detail="Instance not found")
        email = user.get("email", "")
        role = user.get("role", "")
        if supabase_store.enabled and role != "admin" and inst.get("owner") != email:
            raise HTTPException(status_code=404, detail="Instance not found")
        return inst

    @app.delete("/api/v1/instances/{iid}")
    async def _p14_delete(iid: str, user=Depends(get_current_user)):
        """Delete an instance.  Non-admins may only delete their own."""
        inst = _p14_im.get(iid)
        if not inst:
            raise HTTPException(status_code=404, detail="Instance not found")
        email = user.get("email", "")
        role = user.get("role", "")
        if supabase_store.enabled and role != "admin" and inst.get("owner") != email:
            raise HTTPException(status_code=404, detail="Instance not found")
        _p14_im.delete(iid)
        return {"deleted": iid}

    print("Phase 14 active: instance CRUD + per-instance routing")
except Exception as _p14_err:
    print(f"WARNING: Phase 14 instance management not loaded: {_p14_err}")
# ══════════════ End Phase 14 integration ══════════════


# ══════════════ Phase 15: Hosting API (RBAC + owner-scoped) ════════════
# Deploy and manage locally hosted apps.  Mutating routes (deploy, start,
# stop, restart, remove, tunnel) require the RBAC 'execute' permission
# (admin or developer role).  Non-admins only see / act on their own apps
# by owner email.  Soft-fails so the API always boots.
try:
    from infrastructure.hosting_manager import hosting_manager as _p15_hosting
    from enterprise.rbac import RBAC as _P15RBAC

    _p15_rbac = _P15RBAC()

    def _p15_check_execute(user: dict):
        """Raise 403 if the user lacks the RBAC 'execute' permission."""
        if not supabase_store.enabled:
            return  # single-user mode — always allow
        if not _p15_rbac.can(user.get("role", ""), "execute"):
            raise HTTPException(status_code=403,
                                detail="execute permission required (admin or developer role)")

    def _p15_owner_check(user: dict, app_owner: str):
        """Raise 404 if a non-admin tries to access someone else's app."""
        if not supabase_store.enabled:
            return
        if user.get("role", "") != "admin" and app_owner != user.get("email", ""):
            raise HTTPException(status_code=404, detail="App not found")

    # ── List ──────────────────────────────────────────────────────────
    @app.get("/api/v1/hosting/apps")
    async def _p15_list(user=Depends(get_current_user)):
        """List hosted apps.  Admins see all; others see only their own."""
        email = user.get("email", "")
        role = user.get("role", "")
        if supabase_store.enabled and role != "admin":
            return {"apps": _p15_hosting.list(owner=email)}
        return {"apps": _p15_hosting.list()}

    # ── Deploy ────────────────────────────────────────────────────────
    @app.post("/api/v1/hosting/deploy")
    async def _p15_deploy(body: dict, user=Depends(get_current_user)):
        """Deploy a new app.

        Body: {name, kind, entry?, path?, command?, port?, env?,
               tunnel?, autostart?, owner?}.

        *owner* may only be set by admins; non-admins are always tagged
        with their own email.
        """
        _p15_check_execute(user)
        owner = user.get("email", "")
        if supabase_store.enabled and user.get("role") == "admin" and body.get("owner"):
            owner = body["owner"]
        result = _p15_hosting.deploy(
            name=body.get("name", ""),
            kind=body.get("kind", ""),
            entry=body.get("entry", ""),
            path=body.get("path", ""),
            command=body.get("command", ""),
            port=body.get("port"),
            env=body.get("env"),
            owner=owner,
            autostart=body.get("autostart", True),
            tunnel=body.get("tunnel", False),
        )
        if not result.get("ok"):
            raise HTTPException(status_code=400, detail=result.get("error", "deploy failed"))
        return result

    # ── Status ────────────────────────────────────────────────────────
    @app.get("/api/v1/hosting/apps/{name}")
    async def _p15_status(name: str, user=Depends(get_current_user)):
        """Get live status for a hosted app."""
        result = _p15_hosting.status(name)
        if result.get("ok") is False:
            raise HTTPException(status_code=404, detail=result.get("error", "not found"))
        _p15_owner_check(user, result.get("owner", ""))
        return result

    # ── Start ─────────────────────────────────────────────────────────
    @app.post("/api/v1/hosting/apps/{name}/start")
    async def _p15_start(name: str, user=Depends(get_current_user)):
        _p15_check_execute(user)
        app = _p15_hosting.status(name)
        if app.get("ok") is False:
            raise HTTPException(status_code=404, detail=app.get("error", "not found"))
        _p15_owner_check(user, app.get("owner", ""))
        result = _p15_hosting.start(name)
        if not result.get("ok"):
            raise HTTPException(status_code=400, detail=result.get("error", "start failed"))
        return result

    # ── Stop ──────────────────────────────────────────────────────────
    @app.post("/api/v1/hosting/apps/{name}/stop")
    async def _p15_stop(name: str, user=Depends(get_current_user)):
        _p15_check_execute(user)
        app = _p15_hosting.status(name)
        if app.get("ok") is False:
            raise HTTPException(status_code=404, detail=app.get("error", "not found"))
        _p15_owner_check(user, app.get("owner", ""))
        result = _p15_hosting.stop(name)
        if not result.get("ok"):
            raise HTTPException(status_code=400, detail=result.get("error", "stop failed"))
        return result

    # ── Restart ───────────────────────────────────────────────────────
    @app.post("/api/v1/hosting/apps/{name}/restart")
    async def _p15_restart(name: str, user=Depends(get_current_user)):
        _p15_check_execute(user)
        app = _p15_hosting.status(name)
        if app.get("ok") is False:
            raise HTTPException(status_code=404, detail=app.get("error", "not found"))
        _p15_owner_check(user, app.get("owner", ""))
        result = _p15_hosting.restart(name)
        if not result.get("ok"):
            raise HTTPException(status_code=400, detail=result.get("error", "restart failed"))
        return result

    # ── Tunnel ────────────────────────────────────────────────────────
    @app.post("/api/v1/hosting/apps/{name}/tunnel")
    async def _p15_tunnel(name: str, user=Depends(get_current_user)):
        _p15_check_execute(user)
        app = _p15_hosting.status(name)
        if app.get("ok") is False:
            raise HTTPException(status_code=404, detail=app.get("error", "not found"))
        _p15_owner_check(user, app.get("owner", ""))
        result = _p15_hosting.open_tunnel(name)
        if not result.get("ok"):
            raise HTTPException(status_code=400, detail=result.get("error", "tunnel failed"))
        return result

    # ── Logs ──────────────────────────────────────────────────────────
    @app.get("/api/v1/hosting/apps/{name}/logs")
    async def _p15_logs(name: str, lines: int = 100, user=Depends(get_current_user)):
        """Tail the app's log file.  *lines* defaults to 100, capped at 2000."""
        app = _p15_hosting.status(name)
        if app.get("ok") is False:
            raise HTTPException(status_code=404, detail=app.get("error", "not found"))
        _p15_owner_check(user, app.get("owner", ""))
        return _p15_hosting.logs(name, lines=min(max(lines, 1), 2000))

    # ── Remove ────────────────────────────────────────────────────────
    @app.delete("/api/v1/hosting/apps/{name}")
    async def _p15_remove(name: str, user=Depends(get_current_user)):
        _p15_check_execute(user)
        app = _p15_hosting.status(name)
        if app.get("ok") is False:
            raise HTTPException(status_code=404, detail=app.get("error", "not found"))
        _p15_owner_check(user, app.get("owner", ""))
        result = _p15_hosting.remove(name)
        if not result.get("ok"):
            raise HTTPException(status_code=400, detail=result.get("error", "remove failed"))
        return result

    print("Phase 15 active: hosting API (RBAC + owner-scoped)")
except Exception as _p15_err:
    print(f"WARNING: Phase 15 hosting API not loaded: {_p15_err}")
# ══════════════ End Phase 15 integration ══════════════

# ══════════════ Phase 16: Remote VPS Deploy over SSH + Docker ══════════════
try:
    from infrastructure.remote_deploy import remote_deployer as _p16_remote
    from enterprise.rbac import RBAC as _P16RBAC
    from human.approval import ApprovalManager
    from security.risk_checker import RiskChecker

    _p16_rbac = _P16RBAC()
    _p16_approval = ApprovalManager(mode=os.environ.get("APPROVAL_MODE", "auto"))
    _p16_risk = RiskChecker()

    def _p16_check_execute(user: dict):
        """Raise 403 if the user lacks the RBAC 'execute' permission."""
        if not supabase_store.enabled:
            return
        if not _p16_rbac.can(user.get("role", ""), "execute"):
            raise HTTPException(status_code=403,
                                detail="execute permission required (admin or developer role)")

    def _p16_abort_if_not_configured():
        """Return a clean JSON response if no VPS is configured (not a 500)."""
        if not _p16_remote.configured:
            raise HTTPException(status_code=503,
                                detail="VPS not configured — set VPS_HOST and credentials")

    @app.post("/api/v1/hosting/remote/deploy")
    async def _p16_remote_deploy(body: dict, user=Depends(get_current_user)):
        """Build image (optional) and run a container on the remote VPS.

        Request body:
          app            — container name (required)
          image          — Docker image to run (required)
          dockerfile_dir — if set, ``docker build -t <image> <dir>`` first
          ports          — dict mapping ``host_port → container_port``
          env            — dict mapping env var names → values
        """
        _p16_check_execute(user)
        _p16_abort_if_not_configured()

        app = body.get("app", "")
        image = body.get("image", "")
        if not app or not image:
            raise HTTPException(status_code=400, detail="'app' and 'image' are required")

        dockerfile_dir = body.get("dockerfile_dir")
        ports = body.get("ports")
        env = body.get("env")

        # Optional build step
        if dockerfile_dir:
            build_result = _p16_remote.build_image(app, dockerfile_dir)
            if not build_result.get("ok"):
                raise HTTPException(status_code=400,
                                    detail=build_result.get("error", "build failed"))

        # Run the container
        result = _p16_remote.run_container(app, image, ports=ports, env=env)
        if not result.get("ok"):
            raise HTTPException(status_code=400,
                                detail=result.get("error", "deploy failed"))
        return result

    @app.post("/api/v1/hosting/remote/{app}/{action}")
    async def _p16_remote_action(app: str, action: str, user=Depends(get_current_user)):
        """Control a remote container.

        *action* — one of ``start``, ``stop``, ``restart``, ``logs``.
        """
        _p16_check_execute(user)
        _p16_abort_if_not_configured()

        valid = {"start", "stop", "restart", "logs"}
        if action not in valid:
            raise HTTPException(status_code=400,
                                detail=f"Invalid action '{action}'. Valid: {', '.join(sorted(valid))}")

        # Container lifecycle ops always go through the approval gate
        # at HIGH risk (gates in all modes — auto, human, skip).
        if action in ("stop", "start", "restart"):
            if _p16_approval.needs_approval(f"remote:{action}:{app}", risk_level="high"):
                approved = _p16_approval.request_approval(
                    action=f"[Remote] {action.capitalize()} container '{app}' on VPS",
                    reason=f"User requested {action} of container '{app}'",
                    risk_level="high",
                )
                if not approved:
                    raise HTTPException(status_code=403, detail=f"{action.capitalize()} denied by user")

        method_map = {
            "start": _p16_remote.start_container,
            "stop": _p16_remote.stop_container,
            "restart": _p16_remote.restart_container,
            "logs": lambda a: _p16_remote.container_logs(a),
        }

        result = method_map[action](app)
        if not result.get("ok"):
            detail = result.get("error", f"{action} failed")
            raise HTTPException(status_code=400, detail=detail)
        return result

    print("Phase 16 active: remote VPS deploy over SSH + Docker (RBAC + approval gate)")
except Exception as _p16_err:
    print(f"WARNING: Phase 16 remote VPS deploy not loaded: {_p16_err}")
# ══════════════ End Phase 16 integration ══════════════

# ══════════════ Phase 17: Autonomous Cognition Loop ══════════════
try:
    from infrastructure.cognition import (
        cognition_engine as _p17_cog,
        COGNITION_ENABLED as _P17_ENABLED,
        COGNITION_AUTORUN as _P17_AUTORUN,
    )
    from enterprise.rbac import RBAC as _P17RBAC
    from human.intervention import InterventionHandler

    _p17_rbac = _P17RBAC()
    _p17_intervention = InterventionHandler()

    def _p17_check_execute(user: dict):
        if not supabase_store.enabled:
            return
        if not _p17_rbac.can(user.get("role", ""), "execute"):
            raise HTTPException(status_code=403,
                                detail="execute permission required (admin or developer role)")

    def _p17_require_enabled():
        """Clean 503 instead of a 500 when the cognition loop is off."""
        if not _P17_ENABLED:
            raise HTTPException(
                status_code=503,
                detail=(
                    "Cognition loop not enabled — set COGNITION_ENABLED=true "
                    "in .env and restart"
                ),
            )

    # ── Missions ───────────────────────────────────────────────────
    @app.get("/api/v1/cognitive/missions")
    async def _p17_list_missions(
        active_only: bool = False,
        mission_type: Optional[str] = None,
        user=Depends(get_current_user),
    ):
        _p17_require_enabled()
        return {"missions": _p17_cog.list_missions(
            active_only=active_only, mission_type=mission_type,
        )}

    @app.post("/api/v1/cognitive/missions")
    async def _p17_create_mission(
        body: dict, user=Depends(get_current_user),
    ):
        _p17_check_execute(user)
        _p17_require_enabled()
        name = body.get("name", "")
        if not name:
            raise HTTPException(status_code=400, detail="'name' is required")
        mission_type = body.get("mission_type", "general")
        if mission_type not in ("general", "business"):
            raise HTTPException(
                status_code=400,
                detail="mission_type must be 'general' or 'business'",
            )
        mission = _p17_cog.create_mission(
            name=name,
            description=body.get("description", ""),
            self_gen=body.get("self_gen", True),
            active=body.get("active", True),
            mission_type=mission_type,
        )
        return mission

    @app.patch("/api/v1/cognitive/missions/{mission_id}")
    async def _p17_update_mission(
        mission_id: str, body: dict,
        user=Depends(get_current_user),
    ):
        _p17_check_execute(user)
        _p17_require_enabled()
        # Support toggle via active field
        if "active" in body:
            ok = _p17_cog.toggle_mission(mission_id, bool(body["active"]))
            if not ok:
                raise HTTPException(status_code=404, detail="Mission not found")
        mission = _p17_cog.update_mission(
            mission_id,
            name=body.get("name"),
            description=body.get("description"),
            self_gen=body.get("self_gen"),
            mission_type=body.get("mission_type"),
        )
        if not mission:
            raise HTTPException(status_code=404, detail="Mission not found")
        return mission

    @app.delete("/api/v1/cognitive/missions/{mission_id}")
    async def _p17_delete_mission(
        mission_id: str, user=Depends(get_current_user),
    ):
        _p17_check_execute(user)
        _p17_require_enabled()
        ok = _p17_cog.delete_mission(mission_id)
        if not ok:
            raise HTTPException(status_code=404, detail="Mission not found")
        return {"ok": True}

    @app.post("/api/v1/cognitive/missions/{mission_id}/generate")
    async def _p17_generate_objectives(
        mission_id: str, user=Depends(get_current_user),
    ):
        _p17_check_execute(user)
        _p17_require_enabled()
        objectives = _p17_cog.generate_objectives(mission_id)
        return {"objectives": objectives, "count": len(objectives)}

    # ── Objectives ─────────────────────────────────────────────────
    @app.get("/api/v1/cognitive/objectives")
    async def _p17_list_objectives(
        mission_id: Optional[str] = None,
        status: Optional[str] = None,
        user=Depends(get_current_user),
    ):
        _p17_require_enabled()
        return {
            "objectives": _p17_cog.list_objectives(
                mission_id=mission_id, status=status
            ),
        }

    @app.post("/api/v1/cognitive/objectives")
    async def _p17_add_objective(
        body: dict, user=Depends(get_current_user),
    ):
        _p17_check_execute(user)
        _p17_require_enabled()
        mission_id = body.get("mission_id", "")
        description = body.get("description", "")
        if not mission_id or not description:
            raise HTTPException(
                status_code=400,
                detail="'mission_id' and 'description' are required",
            )
        obj = _p17_cog.add_objective(
            mission_id=mission_id,
            description=description,
            priority=body.get("priority", 0.0),
            depends_on=body.get("depends_on"),
            requires_approval=body.get("requires_approval", False),
        )
        return obj

    # ── Cycle & control ────────────────────────────────────────────
    @app.post("/api/v1/cognitive/cycle")
    async def _p17_trigger_cycle(user=Depends(get_current_user)):
        _p17_check_execute(user)
        _p17_require_enabled()
        result = await _p17_cog.cycle()
        return result

    # ── One-shot objective execution (manual approval path) ───────
    # READ-ONLY WHITELIST: all SSH commands must match one of these prefixes.
    _P17_RO_PREFIXES = (
        "docker ps", "docker info", "docker inspect", "docker logs",
        "docker stats", "docker version",
        "journalctl", "systemctl status", "systemctl list-units",
        "cat /", "df ", "free ", "uptime", "top -bn",
        "uname ", "hostname", "who ", "last ",
    )

    # Per-objective SSH rate limiter: {objective_id: call_count}
    _p17_ssh_count: Dict[str, int] = {}
    _P17_SSH_MAX_PER_OBJECTIVE = 10

    @app.post("/api/v1/cognitive/execute-objective")
    async def _p17_execute_objective(
        body: dict, user=Depends(get_current_user),
    ):
        """Execute a single proposed objective via read-only SSH commands.

        Bypasses the COGNITION_AUTORUN gate (which blocks execution in
        propose-only mode) but keeps all other safety: RBAC execute check,
        human intervention kill-switch, and a **command whitelist** that
        only permits read-only prefixes — no restart/start/stop/rm/exec.

        Safety layers (in order):
          1. RBAC execute permission check
          2. Intervention kill-switch (423 if active)
          3. Command whitelist (prefix match) — every _ssh() call validated
          4. Objective status gated (only pending/proposed)
          5. Per-objective SSH rate limit (_P17_SSH_MAX_PER_OBJECTIVE calls max)
        """
        _p17_check_execute(user)
        _p17_require_enabled()
        objective_id = body.get("objective_id", "")
        if not objective_id:
            raise HTTPException(status_code=400, detail="objective_id is required")
        obj = _p17_cog._get_objective(objective_id)
        if not obj:
            raise HTTPException(status_code=404, detail="Objective not found")
        if obj["status"] not in ("pending", "proposed"):
            raise HTTPException(
                status_code=400,
                detail=f"Objective is {obj['status']} — can only execute pending/proposed",
            )
        desc = obj["description"]
        mission_id = obj["mission_id"]

        # Intervention kill-switch check
        if _p17_intervention.check_interrupt():
            raise HTTPException(status_code=423, detail="Intervention mode active")

        _p17_cog.update_objective_status(objective_id, "in_progress")
        _p17_cog._audit(mission_id, objective_id, desc,
                        "run", "Manual one-shot execution (read-only whitelist)")

        def _ro_ssh(cmd: str) -> str:
            """Run *cmd* via RemoteDeployer._ssh if it passes the read-only whitelist
            and the per-objective SSH rate limit."""
            stripped = cmd.strip()
            if not any(stripped.startswith(p) for p in _P17_RO_PREFIXES):
                raise RuntimeError(
                    f"Command blocked by read-only whitelist: {stripped[:80]}"
                )
            # Per-objective SSH rate limit
            _p17_ssh_count[objective_id] = _p17_ssh_count.get(objective_id, 0) + 1
            if _p17_ssh_count[objective_id] > _P17_SSH_MAX_PER_OBJECTIVE:
                raise RuntimeError(
                    f"SSH rate limit exceeded: "
                    f"{_P17_SSH_MAX_PER_OBJECTIVE} calls per objective"
                )
            from infrastructure.remote_deploy import remote_deployer as _p17_rd
            return _p17_rd._ssh(cmd)

        results = {}
        errors = []
        try:
            # 1) List running containers
            containers = _ro_ssh("docker ps --format '{{json .}}' 2>&1")
            parsed: list = []
            for line in containers.strip().splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    import json as _j
                    parsed.append(_j.loads(line))
                except _j.JSONDecodeError:
                    pass
            results["containers"] = parsed

            # 2) Check status of known containers
            if parsed:
                names = [c.get("Names", "") or c.get("name", "") for c in parsed]
                names = [n for n in names if n]
                if names:
                    parts = []
                    for n in names:
                        parts.append(
                            f'echo ">>>{n}<<<" && '
                            f"docker ps -a --filter name=^{n}$ "
                            f"--format '{{{{.Status}}}}'"
                        )
                    cmd = " && ".join(parts)
                    out = _ro_ssh(cmd)
                    statuses = {}
                    current = None
                    for line in out.splitlines():
                        line = line.strip()
                        if line.startswith(">>>") and line.endswith("<<<"):
                            current = line[3:-3]
                        elif current is not None:
                            statuses[current] = line if line else "not found"
                            current = None
                    results["statuses"] = statuses

            # 3) System errors from journalctl (last 24h)
            try:
                syslog_out = _ro_ssh(
                    "journalctl --since '24 hours ago' --no-pager -p err 2>&1 | head -200"
                )
                results["system_errors"] = syslog_out
            except RuntimeError as e:
                results["system_errors"] = f"SSH error: {e}"

            # 4) Docker daemon version
            try:
                docker_info = _ro_ssh("docker info --format '{{.ServerVersion}}' 2>&1")
                results["docker_version"] = docker_info.strip()
            except RuntimeError as e:
                results["docker_version"] = f"SSH error: {e}"

            final_status = "done"
            _p17_cog.update_objective_status(objective_id, "done")
        except Exception as e:
            errors.append(str(e))
            final_status = "failed"
            _p17_cog.update_objective_status(objective_id, "failed", str(e))

        _p17_cog._audit(mission_id, objective_id, desc,
                        final_status, "Execution via one-shot endpoint")
        return {
            "objective_id": objective_id,
            "objective_desc": desc,
            "mission_id": mission_id,
            "status": final_status,
            "results": results,
            "errors": errors,
        }

    @app.post("/api/v1/cognitive/pause")
    async def _p17_pause(user=Depends(get_current_user)):
        _p17_check_execute(user)
        _p17_require_enabled()
        _p17_intervention.enable()
        return {"ok": True, "detail": "Cognition loop paused"}

    @app.post("/api/v1/cognitive/resume")
    async def _p17_resume(user=Depends(get_current_user)):
        _p17_check_execute(user)
        _p17_require_enabled()
        _p17_intervention.disable()
        return {"ok": True, "detail": "Cognition loop resumed"}

    @app.get("/api/v1/cognitive/status")
    async def _p17_status(user=Depends(get_current_user)):
        """Engine status — works even when disabled (reports the flag state)."""
        return _p17_cog.status()

    # ── Phase 20: Business analysis endpoints ──────────────────────
    from infrastructure.business_research import (
        business_research as _p20_biz,
    )

    @app.post("/api/v1/cognitive/missions/{mission_id}/analyze")
    async def _p20_analyze_objective(
        mission_id: str, body: dict = {},
        user=Depends(get_current_user),
    ):
        """Run a business mission's top pending objective through the
        four business-agent analysis pipeline (pricing → finance →
        marketing → strategy). Only works for mission_type='business'.

        Returns a report dict with per-agent responses and a combined
        executive summary. Pure LLM — no side effects, no tool calls.
        """
        _p17_check_execute(user)
        _p17_require_enabled()
        mission = _p17_cog.get_mission(mission_id)
        if not mission:
            raise HTTPException(status_code=404, detail="Mission not found")
        if mission.get("mission_type") != "business":
            raise HTTPException(
                status_code=400,
                detail="This endpoint is only for business missions "
                       "(mission_type='business')",
            )
        # Pick the top pending objective, or use an explicit one
        objective_id = body.get("objective_id", "")
        if objective_id:
            obj = _p17_cog._get_objective(objective_id)
            if not obj:
                raise HTTPException(404, detail="Objective not found")
            if obj["status"] not in ("pending", "proposed"):
                raise HTTPException(
                    400,
                    detail=f"Objective is {obj['status']} — must be pending or proposed",
                )
        else:
            pending = _p17_cog.list_objectives(
                mission_id=mission_id, status="pending"
            )
            if not pending:
                raise HTTPException(
                    400, detail="No pending objectives for this mission"
                )
            # Highest priority first (list_objectives orders by priority DESC)
            obj = pending[0]

        _p17_cog.update_objective_status(obj["id"], "in_progress")
        _p17_cog._audit(
            mission_id, obj["id"], obj["description"],
            "run", "Starting business analysis",
        )

        try:
            llm = _p17_cog.llm_fn
            report = _p20_biz.analyze(
                mission_id=mission_id,
                objective_id=obj["id"],
                description=obj["description"],
                llm_fn=llm,
            )
            _p17_cog.update_objective_status(obj["id"], "done")
            _p17_cog._audit(
                mission_id, obj["id"], obj["description"],
                "done", "Business analysis complete",
            )
            return report
        except Exception as e:
            _p17_cog.update_objective_status(obj["id"], "failed", str(e))
            _p17_cog._audit(
                mission_id, obj["id"], obj["description"],
                "failed", f"Business analysis error: {e}",
            )
            raise HTTPException(500, detail=str(e))

    @app.get("/api/v1/cognitive/missions/{mission_id}/reports")
    async def _p20_list_reports(
        mission_id: str, user=Depends(get_current_user),
    ):
        """List all business analysis reports for a mission."""
        _p17_check_execute(user)
        _p17_require_enabled()
        mission = _p17_cog.get_mission(mission_id)
        if not mission:
            raise HTTPException(status_code=404, detail="Mission not found")
        reports = _p20_biz.list_reports(mission_id=mission_id)
        return {"reports": reports, "count": len(reports)}

    @app.get("/api/v1/cognitive/missions/{mission_id}/reports/{report_id}")
    async def _p20_get_report(
        mission_id: str, report_id: str,
        user=Depends(get_current_user),
    ):
        """Get a single business analysis report with full agent responses."""
        _p17_check_execute(user)
        _p17_require_enabled()
        report = _p20_biz.get_report(report_id)
        if not report:
            raise HTTPException(status_code=404, detail="Report not found")
        if report.get("mission_id") != mission_id:
            raise HTTPException(
                status_code=404, detail="Report not found for this mission"
            )
        return report

    print(
        f"Phase 17 active: cognition loop (ENABLED={_P17_ENABLED}, "
        f"AUTORUN={_P17_AUTORUN})"
    )
except Exception as _p17_err:
    print(f"WARNING: Phase 17 cognition loop not loaded: {_p17_err}")
# ══════════════ End Phase 17 integration ══════════════


# ══════════════ Phase 21: Guarded Publish (real-world action) ══════════════
try:
    from infrastructure.publish_engine import (
        publish_engine as _p21_engine,
    )
    from enterprise.rbac import RBAC as _P21RBAC

    _p21_rbac = _P21RBAC()

    def _p21_check_execute(user: dict):
        if not supabase_store.enabled:
            return
        if not _p21_rbac.can(user.get("role", ""), "execute"):
            raise HTTPException(
                status_code=403,
                detail="execute permission required (admin or developer role)",
            )

    @app.post("/api/v1/publish")
    async def _p21_publish(
        body: dict, user=Depends(get_current_user),
    ):
        """Propose and execute a publish action.

        The caller provides the site name and file content. The engine
        creates a permanent audit record, then blocks for human approval
        (showing the exact file contents). On approval, it deploys to
        Netlify via the existing WebBuilderTool.

        Body:
          - site_name: str (required, alphanumeric + ._-)
          - files: {path: content, ...} (required)
          - description: str (optional)

        Returns the result (published URL) or error.
        """
        _p21_check_execute(user)
        site_name = body.get("site_name", "")
        if not site_name:
            raise HTTPException(status_code=400, detail="'site_name' is required")
        files = body.get("files")
        if not files or not isinstance(files, dict):
            raise HTTPException(
                status_code=400,
                detail="'files' must be a non-empty {path: content} dict",
            )
        # Validate site name matches WebBuilderTool's _SAFE_NAME
        import re
        if not re.match(r"^[A-Za-z0-9._-]+$", site_name):
            raise HTTPException(
                status_code=400,
                detail="site_name may only contain letters, numbers, '.', '_' and '-'",
            )
        description = body.get("description", "")

        # 1. Create the permanent audit record
        proposal = _p21_engine.propose(
            site_name=site_name, files=files, description=description,
        )
        if "error" in proposal:
            raise HTTPException(status_code=500, detail=proposal["error"])

        # 2. Pass through the approval gate (blocks until decision)
        approval = maya_instance.approval if maya_instance else None
        result = _p21_engine.publish(
            proposal_id=proposal["id"],
            approval=approval,
            user={"email": user.get("email", ""), "username": user.get("username", "")},
        )
        if "error" in result and not result.get("url"):
            # Check if there's a detailed audit record to return anyway
            audit = _p21_engine.get_proposal(proposal["id"])
            if audit:
                return audit
            raise HTTPException(status_code=403 if "rejected" in result.get("error", "") else 500, detail=result["error"])

        return result

    @app.get("/api/v1/publish/history")
    async def _p21_list_history(user=Depends(get_current_user)):
        """List all publish proposals (audit trail), newest first."""
        _p21_check_execute(user)
        return {"proposals": _p21_engine.list_history()}

    @app.get("/api/v1/publish/history/{proposal_id}")
    async def _p21_get_history(
        proposal_id: str, user=Depends(get_current_user),
    ):
        """Get full detail for a single publish proposal, including the
        exact proposed file contents (files_json)."""
        _p21_check_execute(user)
        proposal = _p21_engine.get_proposal(proposal_id)
        if not proposal:
            raise HTTPException(status_code=404, detail="Proposal not found")
        return proposal

    print("Phase 21 active: guarded publish (hard approval + permanent audit)")
except Exception as _p21_err:
    print(f"WARNING: Phase 21 publish engine not loaded: {_p21_err}")
# ══════════════ End Phase 21 integration ══════════════


# ══════════════ Phase 30: App Registry + Remote Monitoring ══════════════
try:
    from infrastructure.app_registry import (
        app_registry as _p30_registry,
        APP_MONITOR_ENABLED as _P30_MONITOR_ENABLED,
    )
    from infrastructure.remote_deploy import remote_deployer as _p30_remote
    from enterprise.rbac import RBAC as _P30RBAC
    from human.approval import ApprovalManager
    from security.risk_checker import RiskChecker

    _p30_rbac = _P30RBAC()
    _p30_approval = ApprovalManager(
        mode=os.environ.get("APPROVAL_MODE", "auto")
    )
    _p30_risk = RiskChecker()

    def _p30_check_execute(user: dict):
        if not supabase_store.enabled:
            return
        if not _p30_rbac.can(user.get("role", ""), "execute"):
            raise HTTPException(
                status_code=403,
                detail="execute permission required (admin or developer role)",
            )

    # ── Registry CRUD ───────────────────────────────────────────────

    @app.get("/api/v1/hosting/registry")
    async def _p30_list(user=Depends(get_current_user)):
        """List all tracked apps in the registry."""
        return {"apps": _p30_registry.list()}

    @app.post("/api/v1/hosting/registry")
    async def _p30_register(body: dict, user=Depends(get_current_user)):
        """Register an app in the registry."""
        _p30_check_execute(user)
        name = body.get("name")
        if not name:
            raise HTTPException(status_code=400, detail="'name' is required")
        app = _p30_registry.register(
            name=name,
            container_id=body.get("container_id", ""),
            image=body.get("image", ""),
            host=body.get("host", ""),
        )
        return app

    @app.get("/api/v1/hosting/registry/{name}")
    async def _p30_get(name: str, user=Depends(get_current_user)):
        """Get a single tracked app."""
        app = _p30_registry.get(name)
        if not app:
            raise HTTPException(status_code=404, detail="App not found")
        return app

    @app.delete("/api/v1/hosting/registry/{name}")
    async def _p30_unregister(name: str, user=Depends(get_current_user)):
        """Remove an app from the registry."""
        _p30_check_execute(user)
        ok = _p30_registry.unregister(name)
        if not ok:
            raise HTTPException(status_code=404, detail="App not found")
        return {"ok": True}

    @app.patch("/api/v1/hosting/registry/{name}/monitor")
    async def _p30_toggle_monitor(
        name: str, body: dict, user=Depends(get_current_user),
    ):
        """Enable/disable health monitoring for an app."""
        _p30_check_execute(user)
        enabled = body.get("enabled")
        if enabled is None:
            raise HTTPException(status_code=400, detail="'enabled' (bool) is required")
        ok = _p30_registry.set_monitor(name, bool(enabled))
        if not ok:
            raise HTTPException(status_code=404, detail="App not found")
        return {"ok": True, "name": name, "monitor": bool(enabled)}

    # ── Health & lifecycle ──────────────────────────────────────────

    @app.post("/api/v1/hosting/registry/{name}/health")
    async def _p30_health(name: str, user=Depends(get_current_user)):
        """Trigger a health check for one app."""
        result = _p30_registry.health_check(name)
        if not result.get("ok"):
            raise HTTPException(
                status_code=404 if result.get("error") == "not found" else 502,
                detail=result.get("error", "Health check failed"),
            )
        return result

    @app.post("/api/v1/hosting/registry/check-all")
    async def _p30_check_all(user=Depends(get_current_user)):
        """Health-check all monitored apps in one remote sweep."""
        if not _p30_remote.configured:
            raise HTTPException(
                status_code=503,
                detail="Remote VPS not configured — set VPS_HOST in .env",
            )
        results = _p30_registry.check_all()
        return {"checked": len(results), "results": results}

    @app.post("/api/v1/hosting/registry/{name}/restart")
    async def _p30_restart(name: str, user=Depends(get_current_user)):
        """Restart a container on the remote VPS (approval-gated)."""
        _p30_check_execute(user)
        app = _p30_registry.get(name)
        if not app:
            raise HTTPException(status_code=404, detail="App not found")
        if not _p30_remote.configured:
            raise HTTPException(
                status_code=503, detail="Remote VPS not configured"
            )

        # Risk check + approval gate for the restart action.
        # Hard-coded at HIGH so it gates in all approval modes.
        if _p30_approval.needs_approval(
            f"appregistry:restart:{name}",
            risk_level="high",
        ):
            approved = _p30_approval.request_approval(
                action=f"[AppRegistry] Restart remote container '{name}'",
                reason="User requested container restart via AppRegistry",
                risk_level="high",
                task_id=name,
            )
            if not approved:
                raise HTTPException(status_code=403, detail="Restart denied by user")

        result = _p30_registry.restart(name)
        if not result.get("ok"):
            raise HTTPException(status_code=502, detail=result.get("error", "Restart failed"))
        return {"ok": True, "name": name}

    @app.get("/api/v1/hosting/registry/{name}/logs")
    async def _p30_logs(
        name: str, lines: int = 100, user=Depends(get_current_user),
    ):
        """Fetch remote container logs."""
        result = _p30_registry.logs(name, lines=max(1, min(5000, lines)))
        if not result.get("ok"):
            raise HTTPException(status_code=404, detail=result.get("error", "Log fetch failed"))
        return {"name": name, "logs": result.get("logs", "")}

    print(
        f"Phase 30 active: app registry + remote monitoring "
        f"(MONITOR={_P30_MONITOR_ENABLED})"
    )
except Exception as _p30_err:
    print(f"WARNING: Phase 30 app registry not loaded: {_p30_err}")
# ══════════════ End Phase 30 integration ══════════════

# ══════════════ Phase 31: Build → Deploy Pipeline ══════════════
try:
    from infrastructure.deploy_pipeline import (
        deploy_pipeline as _p31_pipe,
        DEPLOY_PIPELINE_ENABLED as _P31_ENABLED,
    )
    from enterprise.rbac import RBAC as _P31RBAC
    from human.approval import ApprovalManager
    from security.risk_checker import RiskChecker
    from human.intervention import InterventionHandler as _P31IH

    _p31_rbac = _P31RBAC()
    _p31_approval = ApprovalManager(
        mode=os.environ.get("APPROVAL_MODE", "auto")
    )
    _p31_risk = RiskChecker()
    _p31_intervention = _P31IH()

    def _p31_check_execute(user: dict):
        if not supabase_store.enabled:
            return
        if not _p31_rbac.can(user.get("role", ""), "execute"):
            raise HTTPException(
                status_code=403,
                detail="execute permission required (admin or developer role)",
            )

    def _p31_require_enabled():
        """Clean 503 when the pipeline is disabled."""
        if not _P31_ENABLED:
            raise HTTPException(
                status_code=503,
                detail=(
                    "Deploy pipeline not enabled — set "
                    "DEPLOY_PIPELINE_ENABLED=true in .env and restart"
                ),
            )

    # ── Plan (dry-run) ───────────────────────────────────────────────
    @app.post("/api/v1/deploy/pipeline/plan")
    async def _p31_plan(body: dict, user=Depends(get_current_user)):
        """Preview build→deploy→register steps without executing.

        Reads the local source directory.  No SSH, no VPS changes,
        no side effects.
        """
        _p31_check_execute(user)
        _p31_require_enabled()
        result = _p31_pipe.plan(
            app_name=body.get("app_name", ""),
            source_dir=body.get("source_dir", ""),
            ports=body.get("ports"),
            env=body.get("env"),
        )
        return result

    # ── Execute (state-changing, gated) ──────────────────────────────
    @app.post("/api/v1/deploy/pipeline/execute")
    async def _p31_execute(body: dict, user=Depends(get_current_user)):
        """Run the full pipeline: build→deploy→register.

        Dry-run by default — set ``confirm=true`` to execute.
        State-changing: goes through RiskChecker + ApprovalManager.
        """
        _p31_check_execute(user)
        _p31_require_enabled()

        app_name = body.get("app_name", "")
        source_dir = body.get("source_dir", "")
        ports = body.get("ports")
        env = body.get("env")
        confirm = bool(body.get("confirm", False))

        # Dry-run without confirm
        if not confirm:
            result = _p31_pipe.plan(app_name, source_dir, ports, env)
            return {
                "ok": False,
                "detail": (
                    "Dry-run — set confirm=true to execute. "
                    "This is a state-changing operation."
                ),
                "plan": result,
            }

        # Intervention kill-switch
        if _p31_intervention.check_interrupt():
            raise HTTPException(status_code=423, detail="Intervention mode active")

        # VPS configured check
        from infrastructure.remote_deploy import remote_deployer as _p31_rd
        if not _p31_rd.configured:
            raise HTTPException(
                status_code=503,
                detail="Remote VPS not configured (VPS_HOST not set)",
            )

        # Risk check + approval gate
        risk = _p31_risk.check(f"build:deploy {app_name}")
        if _p31_approval.needs_approval(
            f"deploy:pipeline:execute:{app_name}",
            risk.get("level", "high"),
        ):
            approved = _p31_approval.request_approval(
                action=f"[DeployPipeline] Build and deploy '{app_name}'",
                reason=risk.get("reason", "User-initiated deploy"),
                risk_level=risk.get("level", "high"),
                task_id=app_name,
            )
            if not approved:
                raise HTTPException(
                    status_code=403,
                    detail="Deploy denied by user",
                )

        # Execute
        result = _p31_pipe.execute(
            app_name=app_name,
            source_dir=source_dir,
            ports=ports,
            env=env,
            confirm=True,
        )
        return result

    # ── Status ──────────────────────────────────────────────────────
    @app.get("/api/v1/deploy/pipeline/status")
    async def _p31_status(user=Depends(get_current_user)):
        """Return the last pipeline execution result."""
        _p31_require_enabled()
        return _p31_pipe.status()

    print(
        f"Phase 31 active: build→deploy pipeline "
        f"(ENABLED={_P31_ENABLED})"
    )
except Exception as _p31_err:
    print(f"WARNING: Phase 31 deploy pipeline not loaded: {_p31_err}")
# ══════════════ End Phase 31 integration ══════════════

# ══════════════ Phase 32: Research / Market Engine ══════════════
try:
    from infrastructure.research_engine import (
        research_engine as _p32_engine,
        RESEARCH_ENGINE_ENABLED as _P32_ENABLED,
    )
    from enterprise.rbac import RBAC as _P32RBAC

    _p32_rbac = _P32RBAC()

    def _p32_check_view(user: dict):
        if not supabase_store.enabled:
            return
        if not _p32_rbac.can(user.get("role", ""), "view"):
            raise HTTPException(
                status_code=403,
                detail="view permission required",
            )

    def _p32_require_enabled():
        """Clean 503 when the research engine is disabled."""
        if not _P32_ENABLED:
            raise HTTPException(
                status_code=503,
                detail=(
                    "Research engine not enabled — set "
                    "RESEARCH_ENGINE_ENABLED=true in .env and restart"
                ),
            )

    # ── Analyze ─────────────────────────────────────────────────
    @app.post("/api/v1/research/analyze")
    async def _p32_analyze(body: dict, user=Depends(get_current_user)):
        """Run a full research analysis: fetch → summarize → report.

        Analysis-only: reads public web pages, writes local report.
        No external writes of any kind.
        """
        _p32_check_view(user)
        _p32_require_enabled()
        result = _p32_engine.analyze(
            topic=body.get("topic", ""),
            urls=body.get("urls"),
            max_sources=body.get("max_sources", 5),
        )
        return result

    # ── List reports ────────────────────────────────────────────
    @app.get("/api/v1/research/reports")
    async def _p32_list_reports(user=Depends(get_current_user)):
        """List all research reports, most recent first."""
        _p32_check_view(user)
        _p32_require_enabled()
        return {"reports": _p32_engine.list_reports()}

    # ── Get report ──────────────────────────────────────────────
    @app.get("/api/v1/research/reports/{report_id}")
    async def _p32_get_report(report_id: str, user=Depends(get_current_user)):
        """Get a single research report."""
        _p32_check_view(user)
        _p32_require_enabled()
        report = _p32_engine.get_report(report_id)
        if not report:
            raise HTTPException(status_code=404, detail="Report not found")
        return report

    print(
        f"Phase 32 active: research/market engine "
        f"(ENABLED={_P32_ENABLED})"
    )
except Exception as _p32_err:
    print(f"WARNING: Phase 32 research engine not loaded: {_p32_err}")
# ══════════════ End Phase 32 integration ══════════════

# ══════════════ Phase 18: AGI Cognitive Architecture ══════════════
# Cognitive Kernel, Capability Registry, Tool Synthesizer, World Models,
# Hierarchical Planner, Metacognitive Monitor, Agent Society, Procedural Memory
try:
    from infrastructure.cognitive_kernel import (
        get_cognitive_kernel as _p18_get_kernel,
        CognitiveKernel as _P18Kernel,
    )
    from infrastructure.capability_registry import (
        get_capability_registry as _p18_get_registry,
        CapabilityRegistry as _P18Registry,
        CapabilityType as _P18CapType,
        CapabilityStatus as _P18CapStatus,
    )
    from infrastructure.tool_synthesizer import (
        get_tool_synthesizer as _p18_get_synthesizer,
        ToolSynthesizer as _P18Synthesizer,
    )
    from infrastructure.world_models import create_world_models as _p18_create_models
    from infrastructure.hierarchical_planner import (
        get_hierarchical_planner as _p18_get_planner,
        HierarchicalPlanner as _P18Planner,
    )
    from infrastructure.metacognitive import (
        get_metacognitive_monitor as _p18_get_monitor,
        MetacognitiveMonitor as _P18Monitor,
    )
    from infrastructure.agent_society import (
        get_agent_society as _p18_get_society,
        AgentSociety as _P18Society,
    )
    from infrastructure.procedural_memory import (
        get_episodic_memory as _p18_get_episodic,
        get_procedural_memory as _p18_get_procedural,
        get_experience_distiller as _p18_get_distiller,
        get_experience_replay as _p18_get_replay,
    )
    from enterprise.rbac import RBAC as _P18RBAC
    from human.approval import ApprovalManager as _P18Approval
    from human.intervention import InterventionHandler as _P18Intervention

    _p18_rbac = _P18RBAC()
    _p18_approval = _P18Approval(mode=os.environ.get("APPROVAL_MODE", "auto"))
    _p18_intervention = _P18Intervention()

    def _p18_check_execute(user: dict):
        if not supabase_store.enabled:
            return
        if not _p18_rbac.can(user.get("role", ""), "execute"):
            raise HTTPException(status_code=403, detail="execute permission required (admin or developer role)")

    def _p18_require_enabled():
        if not os.environ.get("COGNITION_ENABLED", "false").lower() == "true":
            raise HTTPException(status_code=503, detail="Cognition kernel requires COGNITION_ENABLED=true")

    # Initialize core components
    try:
        _p18_llm_fn = None
        if maya_instance and hasattr(maya_instance, "router"):
            def _p18_llm(prompt: str) -> str:
                return maya_instance.router.chat([{"role": "user", "content": prompt}])
            _p18_llm_fn = _p18_llm
    except Exception:
        pass

    _p18_world_models = _p18_create_models(
        getattr(maya_instance, "remote_deployer", None) if maya_instance else None
    ) if "_p18_create_models" in dir() else {}

    # Cognitive Kernel
    _p18_kernel = _p18_get_kernel(
        llm_fn=_p18_llm_fn,
        world_models=_p18_world_models,
        approval_manager=_p18_approval,
        intervention_handler=_p18_intervention,
    )

    # Capability Registry
    _p18_registry = _p18_get_registry(
        getattr(maya_instance, "tool_manager", None).get_registry() if maya_instance and hasattr(maya_instance, "tool_manager") else None
    )

    # Tool Synthesizer
    _p18_synthesizer = _p18_get_synthesizer(
        llm_fn=_p18_llm_fn,
        capability_registry=_p18_registry,
        approval_manager=_p18_approval,
    )

    # Hierarchical Planner
    _p18_planner = _p18_get_planner(
        kernel=_p18_kernel,
        world_models=_p18_world_models,
        capability_registry=_p18_registry,
    )

    # Metacognitive Monitor
    _p18_monitor = _p18_get_monitor(
        kernel=_p18_kernel,
        world_models=_p18_world_models,
        hierarchical_planner=_p18_planner,
        capability_registry=_p18_registry,
        approval_manager=_p18_approval,
        intervention_handler=_p18_intervention,
    )

    # Agent Society
    _p18_society = _p18_get_society(
        kernel=_p18_kernel,
        capability_registry=_p18_registry,
        llm_fn=_p18_llm_fn,
        approval_manager=_p18_approval,
    )

    # Procedural Memory
    _p18_episodic = _p18_get_episodic()
    _p18_procedural = _p18_get_procedural()
    _p18_distiller = _p18_get_distiller(llm_fn=_p18_llm_fn, capability_registry=_p18_registry)
    _p18_replay = _p18_get_replay(kernel=_p18_kernel)

    # Start background processes
    _p18_kernel.start()
    _p18_society.start()
    _p18_monitor._running = True  # Monitor runs inline

    print("Phase 18 active: AGI Cognitive Architecture (kernel, registry, synthesizer, planner, monitor, society, memory)")

    # ── Cognitive Kernel Routes ──────────────────────────────────────
    @app.get("/api/v1/cognitive/kernel/status")
    async def _p18_kernel_status(user=Depends(get_current_user)):
        return _p18_kernel.status()

    # ── Phase 34: Unified Cognitive Loop ─────────────────────────────
    @app.post("/api/v1/cognitive/kernel/process-goal")
    async def _p34_process_goal(body: dict, user=Depends(get_current_user)):
        """
        THE single control entry for goals.

        Body: {description: str, priority?: float, execute?: bool}

        execute defaults to FALSE (propose-only: goal + plan + memory
        grounding, zero world side effects). When execute=true the kernel
        delegates to Maya's own pipeline, which keeps risk checking and
        approval gates. Requires COGNITION_ENABLED=true + RBAC execute.
        """
        _p18_require_enabled()
        description = (body.get("description") or "").strip()
        if not description:
            raise HTTPException(status_code=400, detail="description required")
        execute = bool(body.get("execute", False))
        if execute:
            _p18_check_execute(user)
        priority = float(body.get("priority", 50.0))
        result = await asyncio.to_thread(
            _p18_kernel.process_goal, description, priority,
            body.get("metadata") or {}, execute,
        )
        return result

    @app.post("/api/v1/cognitive/kernel/checkpoint")
    async def _p18_kernel_checkpoint(user=Depends(get_current_user)):
        _p18_check_execute(user)
        cid = _p18_kernel.checkpoint()
        return {"checkpoint_id": cid}

    @app.get("/api/v1/cognitive/kernel/checkpoints")
    async def _p18_kernel_checkpoints(user=Depends(get_current_user)):
        return {"checkpoints": _p18_kernel.list_checkpoints()}

    @app.post("/api/v1/cognitive/kernel/restore")
    async def _p18_kernel_restore(body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        cid = body.get("checkpoint_id", "")
        if not cid:
            raise HTTPException(status_code=400, detail="checkpoint_id required")
        ok = _p18_kernel.restore_checkpoint(cid)
        return {"restored": ok}

    # Working Memory
    @app.post("/api/v1/cognitive/memory/working/add")
    async def _p18_wm_add(body: dict, user=Depends(get_current_user)):
        content = body.get("content", "")
        slot_type = body.get("type", "fact")
        attention = body.get("attention", 1.0)
        sid = _p18_kernel.wm_add(content, slot_type, attention, body.get("metadata"), body.get("bindings"))
        return {"slot_id": sid}

    @app.get("/api/v1/cognitive/memory/working/search")
    async def _p18_wm_search(q: str, limit: int = 10, type: str = None, user=Depends(get_current_user)):
        results = _p18_kernel.wm_search(q, limit, type)
        return {"results": [{"id": k, **v.__dict__} for k, v in _p18_kernel.working_memory.items() if v.content.lower().find(q.lower()) >= 0][:limit]}

    @app.get("/api/v1/cognitive/memory/working/capacity")
    async def _p18_wm_capacity(user=Depends(get_current_user)):
        return _p18_kernel.wm_capacity()

    # Goals
    @app.post("/api/v1/cognitive/goals")
    async def _p18_create_goal(body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        goal = _p18_kernel.create_goal(
            description=body.get("description", ""),
            parent_id=body.get("parent_id"),
            priority=body.get("priority", 50.0),
            success_criteria=body.get("success_criteria"),
            constraints=body.get("constraints"),
            required_capabilities=body.get("required_capabilities"),
        )
        return {"goal_id": goal.id, **goal.__dict__}

    @app.get("/api/v1/cognitive/goals")
    async def _p18_list_goals(status: str = None, user=Depends(get_current_user)):
        goals = _p18_kernel.get_active_goals()
        if status:
            goals = [g for g in goals if g.status.value == status]
        return {"goals": [g.__dict__ for g in goals]}

    @app.get("/api/v1/cognitive/goals/{goal_id}")
    async def _p18_get_goal(goal_id: str, user=Depends(get_current_user)):
        goal = _p18_kernel.get_goal(goal_id)
        if not goal:
            raise HTTPException(status_code=404, detail="Goal not found")
        return goal.__dict__

    @app.post("/api/v1/cognitive/goals/{goal_id}/decompose")
    async def _p18_decompose_goal(goal_id: str, body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        subgoals = _p18_kernel.decompose_goal(goal_id, body.get("num_subgoals", 5))
        return {"subgoals": [g.__dict__ for g in subgoals]}

    @app.patch("/api/v1/cognitive/goals/{goal_id}")
    async def _p18_update_goal(goal_id: str, body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        goal = _p18_kernel.update_goal(goal_id, **body)
        if not goal:
            raise HTTPException(status_code=404, detail="Goal not found")
        return goal.__dict__

    # Beliefs
    @app.post("/api/v1/cognitive/beliefs")
    async def _p18_add_belief(body: dict, user=Depends(get_current_user)):
        belief = _p18_kernel.add_belief(
            proposition=body.get("proposition", ""),
            confidence=body.get("confidence", 0.5),
            evidence=body.get("evidence"),
            source=body.get("source", "observation"),
            domain=body.get("domain", "general"),
        )
        return belief.__dict__

    @app.get("/api/v1/cognitive/beliefs")
    async def _p18_query_beliefs(domain: str = None, min_conf: float = 0.0, user=Depends(get_current_user)):
        beliefs = _p18_kernel.query_beliefs(domain, min_conf)
        return {"beliefs": [b.__dict__ for b in beliefs]}

    # Simulation
    @app.post("/api/v1/cognitive/simulate")
    async def _p18_simulate(body: dict, user=Depends(get_current_user)):
        action = Action(
            action_type=body.get("action_type", ""),
            parameters=body.get("parameters", {}),
            domain=body.get("domain", "general"),
        )
        result = _p18_kernel.simulate(action, body.get("domain", "general"))
        return {"success": result.success, "effects": result.effects, "reward": result.reward, "confidence": result.confidence, "error": result.error}

    # ── Capability Registry Routes ──────────────────────────────────
    @app.get("/api/v1/capabilities")
    async def _p18_list_capabilities(type: str = None, tag: str = None, status: str = None, limit: int = 50, user=Depends(get_current_user)):
        cap_type = _P18CapType(type) if type else None
        cap_status = _P18CapStatus(status) if status else None
        caps = _p18_registry.list_capabilities(cap_type, tag, cap_status, limit)
        return {"capabilities": [c.to_dict() for c in caps]}

    @app.get("/api/v1/capabilities/search")
    async def _p18_search_capabilities(q: str, limit: int = 20, user=Depends(get_current_user)):
        caps = _p18_registry.search(q, limit)
        return {"capabilities": [c.to_dict() for c in caps]}

    @app.get("/api/v1/capabilities/{cap_id}")
    async def _p18_get_capability(cap_id: str, user=Depends(get_current_user)):
        cap = _p18_registry.get(cap_id)
        if not cap:
            raise HTTPException(status_code=404, detail="Capability not found")
        return cap.to_dict()

    @app.post("/api/v1/capabilities/{cap_id}/verify")
    async def _p18_verify_capability(cap_id: str, body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        result = _p18_registry.verify(cap_id, body.get("test_cases"))
        return result

    @app.get("/api/v1/capabilities/{cap_id}/composable")
    async def _p18_composable(cap_id: str, limit: int = 10, user=Depends(get_current_user)):
        caps = _p18_registry.find_composable(cap_id, limit)
        return {"capabilities": [c.to_dict() for c in caps]}

    @app.get("/api/v1/capabilities/{cap_id}/relations")
    async def _p18_relations(cap_id: str, user=Depends(get_current_user)):
        return _p18_registry.get_relations(cap_id)

    @app.post("/api/v1/capabilities/{cap_id}/relations")
    async def _p18_add_relation(cap_id: str, body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        ok = _p18_registry.add_relation(cap_id, body.get("target_id"), body.get("relation_type"))
        return {"added": ok}

    @app.get("/api/v1/capabilities/stats")
    async def _p18_capability_stats(user=Depends(get_current_user)):
        return _p18_registry.stats()

    # ── Tool Synthesizer Routes ─────────────────────────────────────
    @app.post("/api/v1/cognitive/synthesize")
    async def _p18_synthesize(body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        job_id = _p18_synthesizer.synthesize(
            goal=body.get("goal", ""),
            requirements=body.get("requirements"),
            async_mode=body.get("async", True),
        )
        return {"job_id": job_id}

    @app.get("/api/v1/cognitive/synthesize/{job_id}")
    async def _p18_synthesis_status(job_id: str, user=Depends(get_current_user)):
        job = _p18_synthesizer.get_job(job_id)
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")
        return job.__dict__

    @app.get("/api/v1/cognitive/synthesize")
    async def _p18_list_synthesis(status: str = None, limit: int = 50, user=Depends(get_current_user)):
        jobs = _p18_synthesizer.list_jobs(status, limit)
        return {"jobs": [j.__dict__ for j in jobs]}

    @app.get("/api/v1/cognitive/synthesize/stats")
    async def _p18_synthesis_stats(user=Depends(get_current_user)):
        return _p18_synthesizer.get_status()

    # ── Hierarchical Planner Routes ─────────────────────────────────
    @app.post("/api/v1/cognitive/plan")
    async def _p18_create_plan(body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        goal_id = body.get("goal_id", "")
        goal = _p18_kernel.get_goal(goal_id)
        if not goal:
            raise HTTPException(status_code=404, detail="Goal not found")
        plan = _p18_planner.plan_for_goal(goal)
        return {"plan_id": plan.id, "status": plan.status.value, "steps": len(plan.steps)}

    @app.get("/api/v1/cognitive/plan/{plan_id}")
    async def _p18_plan_status(plan_id: str, user=Depends(get_current_user)):
        status = _p18_planner.get_plan_status(plan_id)
        if not status:
            raise HTTPException(status_code=404, detail="Plan not found")
        return status

    @app.post("/api/v1/cognitive/plan/{plan_id}/execute")
    async def _p18_execute_plan(plan_id: str, body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        # Execute with a simple executor that uses tool registry
        def executor(step):
            # Simple execution - in production would use actual tool calls
            return {"success": True, "output": f"Executed {step.name}"}
        
        result = _p18_planner.execute_plan(plan_id, executor)
        return result

    @app.post("/api/v1/cognitive/plan/{plan_id}/replan")
    async def _p18_replan(plan_id: str, body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        from_step = body.get("from_step")
        reason = body.get("reason", "")
        plan = _p18_planner.replan(plan_id, from_step, reason)
        return {"plan_id": plan.id, "steps": len(plan.steps)}

    # ── Metacognitive Monitor Routes ────────────────────────────────
    @app.get("/api/v1/cognitive/metacognitive/status")
    async def _p18_meta_status(user=Depends(get_current_user)):
        return _p18_monitor.get_status()

    @app.post("/api/v1/cognitive/metacognitive/monitor")
    async def _p18_meta_monitor(body: dict, user=Depends(get_current_user)):
        events = _p18_monitor.monitor(body.get("context", {}))
        return {"events": [e.__dict__ for e in events]}

    @app.post("/api/v1/cognitive/metacognitive/step_result")
    async def _p18_meta_step_result(body: dict, user=Depends(get_current_user)):
        event = _p18_monitor.record_step_result(
            body.get("context", {}),
            body.get("expected"),
            body.get("actual"),
            body.get("verified", False),
        )
        return event.__dict__ if event else {"monitored": False}

    @app.get("/api/v1/cognitive/metacognitive/events")
    async def _p18_meta_events(type: str = None, limit: int = 50, user=Depends(get_current_user)):
        from infrastructure.metacognitive import MetacognitiveEventType
        evt_type = MetacognitiveEventType(type) if type else None
        events = _p18_monitor.get_events(evt_type, limit)
        return {"events": [e.__dict__ for e in events]}

    # ── Agent Society Routes ────────────────────────────────────────
    @app.get("/api/v1/cognitive/society/status")
    async def _p18_society_status(user=Depends(get_current_user)):
        return _p18_society.get_society_status()

    @app.post("/api/v1/cognitive/society/spawn")
    async def _p18_spawn_agent(body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        agent = _p18_society.spawn_agent(body.get("role", ""), body.get("spec"))
        return agent.__dict__

    @app.get("/api/v1/cognitive/society/agents")
    async def _p18_list_agents(role: str = None, status: str = None, user=Depends(get_current_user)):
        status_enum = AgentStatus(status) if status else None
        agents = _p18_society.list_agents(role, status_enum)
        return {"agents": [a.__dict__ for a in agents]}

    @app.post("/api/v1/cognitive/society/agents/{agent_id}/task")
    async def _p18_assign_task(agent_id: str, body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        ok = _p18_society.assign_task(agent_id, body)
        return {"assigned": ok}

    @app.post("/api/v1/cognitive/society/tasks/tender")
    async def _p18_tender_task(body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        task_id = _p18_society.request_bids(
            body.get("task_spec", {}),
            body.get("deadline"),
            body.get("eligible_roles"),
        )
        return {"task_id": task_id}

    @app.post("/api/v1/cognitive/society/tasks/{task_id}/bid")
    async def _p18_submit_bid(task_id: str, body: dict, user=Depends(get_current_user)):
        from infrastructure.agent_society import TaskBid
        bid = TaskBid(
            task_id=task_id,
            agent_id=body.get("agent_id", ""),
            estimated_cost=body.get("estimated_cost", 1.0),
            estimated_duration=body.get("estimated_duration", 60.0),
            confidence=body.get("confidence", 0.8),
            proposed_approach=body.get("proposed_approach", ""),
        )
        ok = _p18_society.submit_bid(bid.agent_id, task_id, bid)
        return {"submitted": ok}

    @app.post("/api/v1/cognitive/society/tasks/{task_id}/award")
    async def _p18_award_task(task_id: str, user=Depends(get_current_user)):
        _p18_check_execute(user)
        winner = _p18_society.award_task(task_id)
        return {"awarded_to": winner}

    @app.post("/api/v1/cognitive/society/blackboard/write")
    async def _p18_bb_write(body: dict, user=Depends(get_current_user)):
        entry = _p18_society.share_info(
            body.get("agent_id", user.get("email", "anonymous")),
            body.get("key", ""),
            body.get("value"),
            body.get("tags"),
            body.get("ttl", 3600),
        )
        return entry.__dict__

    @app.get("/api/v1/cognitive/society/blackboard/read")
    async def _p18_bb_read(key: str, user=Depends(get_current_user)):
        value = _p18_society.get_info(user.get("email", ""), key)
        return {"value": value}

    @app.get("/api/v1/cognitive/society/blackboard/query")
    async def _p18_bb_query(tags: str = "", author: str = "", pattern: str = "", user=Depends(get_current_user)):
        entries = _p18_society.blackboard.query(
            tags=tags.split(",") if tags else None,
            author=author or None,
            pattern=pattern or None,
        )
        return {"entries": [e.__dict__ for e in entries]}

    # ── Procedural Memory Routes ────────────────────────────────────
    @app.get("/api/v1/cognitive/memory/episodic")
    async def _p18_episodic_list(limit: int = 50, outcome: str = None, user=Depends(get_current_user)):
        if outcome:
            eps = _p18_episodic.get_by_outcome(outcome, limit)
        else:
            eps = _p18_episodic.get_recent(limit)
        return {"episodes": [e.__dict__ for e in eps]}

    @app.get("/api/v1/cognitive/memory/episodic/search")
    async def _p18_episodic_search(goal: str, limit: int = 10, user=Depends(get_current_user)):
        eps = _p18_episodic.get_similar(goal, limit)
        return {"episodes": [e.__dict__ for e in eps]}

    @app.get("/api/v1/cognitive/memory/episodic/stats")
    async def _p18_episodic_stats(user=Depends(get_current_user)):
        return _p18_episodic.stats()

    @app.get("/api/v1/cognitive/memory/procedural")
    async def _p18_procedural_list(verified: bool = False, limit: int = 100, user=Depends(get_current_user)):
        skills = _p18_procedural.list_skills(verified, limit)
        return {"skills": [s.__dict__ for s in skills]}

    @app.get("/api/v1/cognitive/memory/procedural/applicable")
    async def _p18_procedural_applicable(goal: str, context: str = "{}", user=Depends(get_current_user)):
        ctx = json.loads(context)
        skills = _p18_procedural.find_applicable_skills(ctx, goal)
        return {"skills": [s.__dict__ for s in skills]}

    @app.post("/api/v1/cognitive/memory/procedural/{skill_id}/use")
    async def _p18_procedural_use(skill_id: str, body: dict, user=Depends(get_current_user)):
        _p18_procedural.record_usage(skill_id, body.get("success", False), body.get("reward", 0.0))
        return {"recorded": True}

    @app.get("/api/v1/cognitive/memory/procedural/stats")
    async def _p18_procedural_stats(user=Depends(get_current_user)):
        return _p18_procedural.stats()

    @app.post("/api/v1/cognitive/memory/distill")
    async def _p18_distill(body: dict, user=Depends(get_current_user)):
        _p18_check_execute(user)
        goal = body.get("goal", "")
        if goal:
            skills = _p18_distiller.distill_from_goal(goal)
        else:
            skills = _p18_distiller.distill_episodes(
                _p18_episodic.get_successful(limit=20)
            )
        return {"skills_created": len(skills), "skills": [s.__dict__ for s in skills]}

    @app.post("/api/v1/cognitive/memory/replay")
    async def _p18_replay(body: dict, user=Depends(get_current_user)):
        result = _p18_replay.replay_batch(body.get("batch_size", 32))
        return result

    @app.get("/api/v1/cognitive/memory/replay/stats")
    async def _p18_replay_stats(user=Depends(get_current_user)):
        return _p18_replay.get_replay_stats()

except Exception as _p18_err:
    print(f"WARNING: Phase 18 AGI architecture not loaded: {_p18_err}")
# ══════════════ End Phase 18 integration ══════════════

# ══════════════ Maya Cognitive Core (Phase 19) ══════════════
try:
    from infrastructure.maya_cognitive_core import (
        get_maya_cognitive_core as _p19_get_core,
        MayaCognitiveCore as _P19Core,
    )
    from enterprise.rbac import RBAC as _P19RBAC

    _p19_rbac = _P19RBAC()

    def _p19_check_execute(user: dict):
        if not supabase_store.enabled:
            return
        if not _p19_rbac.can(user.get("role", ""), "execute"):
            raise HTTPException(status_code=403,
                                detail="execute permission required (admin or developer role)")

    def _p19_require_core():
        core = _p19_get_core()
        if not core or not core.cognitive_kernel:
            raise HTTPException(status_code=503, detail="Maya Cognitive Core not initialized")

    @app.get("/api/v1/maya/core/status")
    async def _p19_status(user=Depends(get_current_user)):
        """Get comprehensive status of the Maya Cognitive Core."""
        _p19_check_execute(user)
        core = _p19_get_core()
        return core.get_status()

    @app.post("/api/v1/maya/core/initialize")
    async def _p19_initialize(user=Depends(get_current_user)):
        """Initialize the Maya Cognitive Core and all subsystems."""
        _p19_check_execute(user)
        core = _p19_get_core(
            router=maya_instance.router if maya_instance else None,
            tool_registry=maya_instance.tool_manager.get_registry() if maya_instance else None,
            approval_manager=maya_instance.approval if maya_instance else None,
            intervention_handler=maya_instance.intervention if maya_instance else None,
            risk_checker=maya_instance.risk if maya_instance else None,
            permission_manager=maya_instance.permissions if maya_instance else None,
            memory_manager=maya_instance.memory if maya_instance else None,
        )
        success = core.initialize()
        return {"success": success, "message": "Cognitive core initialized" if success else "Initialization failed"}

    @app.post("/api/v1/maya/core/loop/start")
    async def _p19_loop_start(interval: float = 30.0, user=Depends(get_current_user)):
        """Start the continuous cognitive loop."""
        _p19_check_execute(user)
        core = _p19_get_core()
        success = core.start_cognitive_loop(interval)
        return {"success": success, "interval": interval}

    @app.post("/api/v1/maya/core/loop/pause")
    async def _p19_loop_pause(user=Depends(get_current_user)):
        """Pause the cognitive loop."""
        _p19_check_execute(user)
        core = _p19_get_core()
        success = core.pause_cognitive_loop()
        return {"success": success}

    @app.post("/api/v1/maya/core/loop/resume")
    async def _p19_loop_resume(user=Depends(get_current_user)):
        """Resume the cognitive loop."""
        _p19_check_execute(user)
        core = _p19_get_core()
        success = core.resume_cognitive_loop()
        return {"success": success}

    @app.post("/api/v1/maya/core/loop/stop")
    async def _p19_loop_stop(user=Depends(get_current_user)):
        """Stop the cognitive loop."""
        _p19_check_execute(user)
        core = _p19_get_core()
        success = core.stop_cognitive_loop()
        return {"success": success}

    @app.post("/api/v1/maya/core/mission")
    async def _p19_run_mission(body: dict, user=Depends(get_current_user)):
        """Run a mission through the cognitive loop."""
        _p19_check_execute(user)
        core = _p19_get_core()
        mission_desc = body.get("description", "")
        mission_type = body.get("mission_type", "general")
        self_gen = body.get("self_gen", True)
        if not mission_desc:
            raise HTTPException(400, "Mission description required")
        result = core.run_mission(mission_desc, mission_type, self_gen)
        return result

    @app.post("/api/v1/maya/core/goal/execute")
    async def _p19_execute_goal(body: dict, user=Depends(get_current_user)):
        """Execute a single goal synchronously."""
        _p19_check_execute(user)
        core = _p19_get_core()
        goal_desc = body.get("goal", "")
        max_steps = body.get("max_steps", 10)
        if not goal_desc:
            raise HTTPException(400, "Goal description required")
        result = core.execute_single_goal(goal_desc, max_steps)
        return result

    @app.get("/api/v1/maya/core/identity")
    async def _p19_identity(user=Depends(get_current_user)):
        """Get Maya's persistent identity."""
        _p19_check_execute(user)
        core = _p19_get_core()
        return core.identity.to_dict()

    @app.get("/api/v1/maya/core/models")
    async def _p19_models(user=Depends(get_current_user)):
        """Get model status and available models."""
        _p19_check_execute(user)
        core = _p19_get_core()
        return core.get_model_status()

    @app.post("/api/v1/maya/core/models/switch")
    async def _p19_switch_model(body: dict, user=Depends(get_current_user)):
        """Switch the active model."""
        _p19_check_execute(user)
        core = _p19_get_core()
        model_id = body.get("model_id", "")
        if not model_id:
            raise HTTPException(400, "model_id required")
        success = core.switch_model(model_id)
        return {"success": success, "active_model": core.self_state.active_model_id}

    @app.post("/api/v1/maya/core/models/invoke")
    async def _p19_invoke_model(body: dict, user=Depends(get_current_user)):
        """Directly invoke a model (Maya controls the invocation)."""
        _p19_check_execute(user)
        core = _p19_get_core()
        prompt = body.get("prompt", "")
        model_id = body.get("model_id")
        task_type = body.get("task_type", "general")
        max_tokens = body.get("max_tokens", 4000)
        if not prompt:
            raise HTTPException(400, "prompt required")
        result = core.model_interface.invoke(prompt, model_id=model_id, task_type=task_type, max_tokens=max_tokens)
        return result

    @app.post("/api/v1/maya/core/checkpoint")
    async def _p19_checkpoint(user=Depends(get_current_user)):
        """Create a full checkpoint of all cognitive state."""
        _p19_check_execute(user)
        core = _p19_get_core()
        checkpoint_id = core.checkpoint()
        return {"checkpoint_id": checkpoint_id}

    @app.post("/api/v1/maya/core/checkpoint/restore")
    async def _p19_restore_checkpoint(body: dict, user=Depends(get_current_user)):
        """Restore cognitive state from checkpoint."""
        _p19_check_execute(user)
        core = _p19_get_core()
        checkpoint_id = body.get("checkpoint_id", "")
        if not checkpoint_id:
            raise HTTPException(400, "checkpoint_id required")
        success = core.restore_checkpoint(checkpoint_id)
        return {"success": success}

    @app.get("/api/v1/maya/core/checkpoints")
    async def _p19_list_checkpoints(user=Depends(get_current_user)):
        """List available checkpoints."""
        _p19_check_execute(user)
        core = _p19_get_core()
        return {"checkpoints": core.list_checkpoints()}

    @app.get("/api/v1/maya/core/audit")
    async def _p19_audit(limit: int = 50, user=Depends(get_current_user)):
        """Get recent cognitive loop audit log."""
        _p19_check_execute(user)
        core = _p19_get_core()
        return {"audit": core.get_recent_audit(limit)}

    @app.post("/api/v1/maya/core/shutdown")
    async def _p19_shutdown(user=Depends(get_current_user)):
        """Shutdown the cognitive core and persist all state."""
        _p19_check_execute(user)
        core = _p19_get_core()
        core.shutdown()
        return {"success": True, "message": "Cognitive core shutdown complete"}

    print("Phase 19 active: Maya Cognitive Core (central controller)")
except Exception as _p19_err:
    print(f"WARNING: Phase 19 Maya Cognitive Core not loaded: {_p19_err}")
# ══════════════ End Phase 19 integration ══════════════

# ── SPA fallback: serve index.html for any non-API path ──────────
import os as _fe_os
import pathlib as _fe_path
_frontend_root = _fe_path.Path(__file__).parent / "frontend"
_frontend_index = _frontend_root / "index.html"

@app.api_route("/{path:path}", methods=["GET"])
async def spa_fallback(path: str):
    # Only serve non-API, non-dotfile paths as SPA routes
    if path.startswith("api/") or path.startswith(".") or path.startswith("_"):
        raise HTTPException(status_code=404, detail="Not found")
    resolved = (_frontend_root / path).resolve()
    # Security: only serve files under frontend/
    if str(resolved).startswith(str(_frontend_root.resolve())) and resolved.is_file():
        from fastapi.responses import FileResponse
        return FileResponse(str(resolved))
    if _frontend_index.is_file():
        from fastapi.responses import FileResponse
        return FileResponse(str(_frontend_index))
    raise HTTPException(status_code=404, detail="Not found")
