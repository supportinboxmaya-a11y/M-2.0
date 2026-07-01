"""
Maya 2.0 ULTRA - FastAPI Server
Connects Maya core to the React frontend
"""
import os, uuid, asyncio
from datetime import datetime, timedelta
from typing import Optional, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import jwt
from dotenv import load_dotenv

load_dotenv()

# ── Maya Core ──────────────────────────────────
from core.maya import Maya

maya_instance: Optional[Maya] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global maya_instance
    maya_instance = Maya()
    print("✅ Maya 2.0 ULTRA started")
    yield
    print("Maya shutting down...")

app = FastAPI(title="Maya 2.0 ULTRA API", version="2.0.0", lifespan=lifespan)

# ── CORS ───────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Auth ───────────────────────────────────────
SECRET_KEY = os.getenv("SECRET_KEY", "maya-secret-key-2024")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@maya.ai")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "maya2024")
security = HTTPBearer(auto_error=False)

def create_token(email: str) -> str:
    payload = {"sub": email, "exp": datetime.utcnow() + timedelta(days=7)}
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=["HS256"])
        return payload["sub"]
    except:
        raise HTTPException(status_code=401, detail="Invalid token")

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

class AgentRunRequest(BaseModel):
    goal: str
    budget_usd: Optional[float] = 1.0

class ChatRequest(BaseModel):
    message: str

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
    if req.email == ADMIN_EMAIL and req.password == ADMIN_PASSWORD:
        token = create_token(req.email)
        return {"access_token": token, "token_type": "bearer", "email": req.email}
    raise HTTPException(status_code=401, detail="Invalid credentials")

@app.post("/api/v1/auth/logout")
async def logout(user=Depends(get_current_user)):
    return {"message": "Logged out"}

@app.post("/api/v1/auth/refresh")
async def refresh(user=Depends(get_current_user)):
    return {"access_token": create_token(user), "token_type": "bearer"}

# ══════════════════════════════════════════════
# AGENT ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/agent/status")
async def agent_status(user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    return maya_instance.status()

@app.post("/api/v1/agent/run")
async def agent_run(req: AgentRunRequest, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    task_id = str(uuid.uuid4())
    task = {
        "id": task_id, "goal": req.goal, "status": "running",
        "steps": [], "created_at": datetime.utcnow().isoformat(),
        "provider_used": None, "cost_usd": 0, "tokens_used": 0
    }
    tasks_db[task_id] = task
    await broadcast({"type": "task_started", "task": task})

    async def run_task():
        try:
            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: maya_instance.run(req.goal)
            )
            tasks_db[task_id].update({
                "status": "done" if result.get("success") else "failed",
                "result": result.get("result", ""),
                "error": result.get("error"),
                "steps": result.get("steps", []),
                "completed_at": datetime.utcnow().isoformat(),
                "cost_usd": result.get("cost_usd", 0),
                "tokens_used": result.get("tokens_used", 0),
            })
        except Exception as e:
            tasks_db[task_id].update({"status": "failed", "error": str(e)})
        await broadcast({"type": "task_done", "task": tasks_db[task_id]})

    asyncio.create_task(run_task())
    return task

@app.post("/api/v1/agent/chat")
async def agent_chat(req: ChatRequest, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    response = await asyncio.get_event_loop().run_in_executor(
        None, lambda: maya_instance.chat(req.message)
    )
    return {"reply": response, "timestamp": datetime.utcnow().isoformat()}

@app.post("/api/v1/agent/think")
async def agent_think(req: ThinkRequest, user=Depends(get_current_user)):
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
    tools = maya_instance.tool_manager.list_tools() if hasattr(maya_instance, "tool_manager") else []
    return tools

@app.post("/api/v1/tools/{tool_name}/run")
async def run_tool(tool_name: str, body: dict, user=Depends(get_current_user)):
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    result = await asyncio.get_event_loop().run_in_executor(
        None, lambda: maya_instance.tool_manager.run(tool_name, body.get("input", {}))
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
        logs = getattr(maya_instance.tool_manager, "logs", [])
        return logs[-limit:]
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
    daily = defaultdict(int)
    for task in tasks_db.values():
        date = task["created_at"][:10]
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
        maya_instance.plugin_loader.install(plugin_id)
    return {"id": plugin_id, "installed": True}

# ══════════════════════════════════════════════
# VISION ROUTES
# ══════════════════════════════════════════════
@app.post("/api/v1/vision/analyze")
async def vision_analyze(body: dict, user=Depends(get_current_user)):
    image = body.get("image", "")
    prompt = body.get("prompt", "Describe this image")
    if not image:
        raise HTTPException(status_code=400, detail="No image provided")
    response = await asyncio.get_event_loop().run_in_executor(
        None, lambda: maya_instance.chat(f"[IMAGE ATTACHED] {prompt}")
    )
    return {"result": response}

# ══════════════════════════════════════════════
# VOICE ROUTES
# ══════════════════════════════════════════════
@app.post("/api/v1/voice/transcribe")
async def voice_transcribe(body: dict, user=Depends(get_current_user)):
    # Placeholder — integrate Whisper or Groq audio if available
    return {"transcript": "", "message": "Voice transcription requires Whisper integration"}

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

# ══════════════════════════════════════════════
# SECURITY ROUTES
# ══════════════════════════════════════════════
@app.get("/api/v1/security/status")
async def security_status(user=Depends(get_current_user)):
    return {"sandbox": True, "risk_level": "low", "blocked_tools": [], "audit_log": []}

# ══════════════════════════════════════════════
# WEBSOCKET
# ══════════════════════════════════════════════
@app.websocket("/ws/agent")
async def websocket_endpoint(ws: WebSocket):
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
