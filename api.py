"""
Maya 2.0 ULTRA - FastAPI Server
Connects Maya core to the React frontend
"""
import os, uuid, asyncio, time
from datetime import datetime, timedelta
from typing import Optional, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
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

if SECRET_KEY == "maya-secret-key-2024":
    print("SECURITY WARNING: default SECRET_KEY in use — set a strong one in .env")
if ADMIN_PASSWORD == "maya2024":
    print("SECURITY WARNING: default ADMIN_PASSWORD in use — change it in .env")

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

class ChatRequest(BaseModel):
    message: str
    chat_id: Optional[str] = None  # groups messages into one conversation thread

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
    task_id = str(uuid.uuid4())
    task = {
        "id": task_id, "goal": req.goal, "status": "running",
        "steps": [], "current_phase": "starting", "created_at": datetime.utcnow().isoformat(),
        "provider_used": None, "cost_usd": 0, "tokens_used": 0
    }
    tasks_db[task_id] = task
    await broadcast({"type": "task_started", "task": task})
    await fire_webhooks("task.started", task)

    def on_progress(payload: dict):
        """Called from Maya's worker thread as it plans/executes/verifies —
        this is what makes 'what is Maya doing right now' actually visible
        instead of the UI only finding out after the whole task finishes."""
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

        if MAIN_EVENT_LOOP:
            try:
                asyncio.run_coroutine_threadsafe(
                    broadcast({"type": "task_progress", "task_id": task_id, "task": tasks_db[task_id]}),
                    MAIN_EVENT_LOOP,
                )
            except Exception:
                pass

    async def run_task():
        try:
            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: maya_instance.run(req.goal, task_id=task_id, progress_callback=on_progress)
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
        except Exception as e:
            tasks_db[task_id].update({"status": "failed", "error": str(e)})
        await broadcast({"type": "task_done", "task": tasks_db[task_id]})
        final = tasks_db[task_id]
        if supabase_store.enabled and user.get("uid") and final.get("cost_usd"):
            supabase_store.add_budget_usage(user["uid"], float(final["cost_usd"]))
        await fire_webhooks("task.done" if final.get("status") == "done" else "task.failed", final)

    asyncio.create_task(run_task())
    return task

CHAT_MESSAGE_FLAT_COST_USD = 0.01  # rough per-call estimate until real token costs are wired in

@app.post("/api/v1/agent/chat")
async def agent_chat(req: ChatRequest, user: dict = Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    check_budget(user)

    history = []
    use_supabase_history = supabase_store.enabled and user.get("uid") and req.chat_id
    if use_supabase_history:
        past = supabase_store.get_chat_history(user["uid"], req.chat_id, limit=20)
        history = [{"role": m["role"], "content": m["content"]} for m in past]

    response = await asyncio.get_event_loop().run_in_executor(
        None, lambda: maya_instance.chat(req.message, history=history)
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
# WEBSOCKET
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
    except WebSocketDisconnect:
        ws_clients.remove(ws) if ws in ws_clients else None

# ══════════════════════════════════════════════
# HEALTH
# ══════════════════════════════════════════════
@app.get("/")
async def root():
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
    from infrastructure import RateLimiter as _P1RateLimiter
    from infrastructure import install_exception_handler as _p1_install_exc

    _p1_install_exc(app, _p1_metrics)
    _p1_queue = _P1TaskQueue(workers=int(os.getenv("TASK_WORKERS", "2")))
    _p1_rl = _P1RateLimiter(rate=float(os.getenv("RATE_LIMIT_PER_MIN", "120")), per_seconds=60)

    @app.on_event("startup")
    async def _p1_start_queue():
        await _p1_queue.start()
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

    @app.get("/api/v1/queue/status")
    async def _p1_queue_status(user=Depends(get_current_user)):
        return _p1_queue.all_status()

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

    print("Phase 6 workflow engine active: plan, runs, cancel, checkpoints")
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
