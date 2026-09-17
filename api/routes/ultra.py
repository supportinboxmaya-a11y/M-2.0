"""
Maya 2.0 ULTRA — API Routes for Ultra Capabilities
====================================================
REST endpoints for the 4 core ultra capabilities:
1. Dynamic Tool Creation (Self-Evolution Loop)
2. Vision & Computer Use (Browser Automation)
3. Isolated Sandbox Security
4. Multi-Agent Swarm Framework
"""

from fastapi import APIRouter, HTTPException, Depends, Body
from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Any
import uuid
import json

from infrastructure.ultra_integration import (
    MayaUltra, UltraTask, UltraMode, TaskComplexity,
    get_ultra_instance, init_ultra, create_ultra_api_routes
)
from infrastructure.dynamic_tool_framework import (
    DynamicToolSpec, ToolCreationStatus, SafetyLevel
)
from infrastructure.vision_browser import (
    BrowserTask, InteractionStep, InteractionType
)
from infrastructure.secure_sandbox import (
    SandboxConfig, SandboxLimits, SandboxLanguage, ExecutionStatus
)
from infrastructure.swarm import (
    SwarmTask, AgentRole, TaskPriority, TaskStatus
)

# Get the main app's maya_instance to access ultra
async def get_ultra():
    """Get the ultra instance from the main app."""
    from api import maya_instance
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    
    # Initialize ultra if not already
    if not hasattr(maya_instance, '_ultra'):
        maya_instance._ultra = get_ultra_instance(llm_fn=maya_instance.router.llm_fn)
        await maya_instance._ultra.initialize()
        await maya_instance._ultra.start()
    
    return maya_instance._ultra


router = APIRouter(prefix="/api/v1/ultra", tags=["ultra"])


# ─── Request/Response Models ─────────────────────────────────────
class UltraTaskRequest(BaseModel):
    goal: str = Field(..., description="The goal to achieve")
    mode: str = Field("assistive", description="Operation mode: assistive, autonomous, swarm, learning")
    complexity: str = Field("moderate", description="Task complexity: simple, moderate, complex, swarm")
    context: Dict = Field(default_factory=dict, description="Additional context for the task")


class UltraTaskResponse(BaseModel):
    task_id: str
    goal: str
    mode: str
    complexity: str
    status: str
    result: Dict
    error: str
    created_at: float
    updated_at: float


class ToolCreationRequest(BaseModel):
    goal: str = Field(..., description="Natural language goal for the tool")
    requirements: str = Field("", description="Detailed requirements")
    name: Optional[str] = Field(None, description="Tool name (auto-generated if not provided)")
    category: str = Field("dynamic", description="Tool category")
    test_cases: List[Dict] = Field(default_factory=list, description="Test cases for validation")


class ToolCreationResponse(BaseModel):
    tool_id: str
    name: str
    status: str
    validation_result: Optional[Dict]
    test_result: Optional[Dict]
    capability_id: Optional[str]
    error: str


class BrowserActionRequest(BaseModel):
    goal: str = Field(..., description="Goal to achieve through browser automation")
    url: str = Field("", description="Starting URL (optional)")


class BrowserActionResponse(BaseModel):
    success: bool
    goal: str
    result: Dict
    error: str
    steps_completed: int
    screenshots: List[str]


class SandboxExecutionRequest(BaseModel):
    code: str = Field(..., description="Code to execute")
    language: str = Field("python", description="Language: python, javascript, shell, etc.")
    timeout_seconds: int = Field(30, description="Execution timeout")
    memory_limit_mb: int = Field(512, description="Memory limit in MB")
    network_enabled: bool = Field(False, description="Allow network access")
    files: Dict[str, str] = Field(default_factory=dict, description="Additional files")


class SandboxExecutionResponse(BaseModel):
    execution_id: str
    success: bool
    stdout: str
    stderr: str
    exit_code: int
    duration_ms: float
    artifacts: List[str]
    error: str


class SwarmExecutionRequest(BaseModel):
    goal: str = Field(..., description="Goal for the swarm to achieve")
    context: Dict = Field(default_factory=dict, description="Additional context")
    num_architects: int = Field(1, description="Number of architect agents")
    num_coders: int = Field(2, description="Number of coder agents")
    num_testers: int = Field(1, description="Number of tester agents")
    num_reviewers: int = Field(1, description="Number of reviewer agents")


class SwarmExecutionResponse(BaseModel):
    goal: str
    completed: bool
    task_results: Dict
    summary: str


class UltraStatusResponse(BaseModel):
    capabilities: Dict
    stats: Dict
    active_tasks: List[Dict]


# ─── Ultra Task Endpoints ────────────────────────────────────────
@router.post("/task", response_model=UltraTaskResponse)
async def create_ultra_task(
    req: UltraTaskRequest,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Create and execute an ultra task."""
    task = UltraTask(
        task_id=uuid.uuid4().hex[:12],
        goal=req.goal,
        mode=UltraMode(req.mode),
        complexity=TaskComplexity(req.complexity),
        context=req.context,
    )
    result = await ultra.execute_task(task)
    return UltraTaskResponse(**result.__dict__)


@router.get("/task/{task_id}", response_model=UltraTaskResponse)
async def get_ultra_task(
    task_id: str,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get status of an ultra task."""
    for task in ultra.get_active_tasks():
        if task.task_id == task_id:
            return UltraTaskResponse(**task.__dict__)
    raise HTTPException(status_code=404, detail="Task not found")


@router.get("/tasks", response_model=List[UltraTaskResponse])
async def list_ultra_tasks(
    ultra: MayaUltra = Depends(get_ultra),
):
    """List all active ultra tasks."""
    return [UltraTaskResponse(**t.__dict__) for t in ultra.get_active_tasks()]


# ─── Dynamic Tool Creation Endpoints ─────────────────────────────
@router.post("/tool/create", response_model=ToolCreationResponse)
async def create_dynamic_tool(
    req: ToolCreationRequest,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Create a dynamic tool from a natural language goal."""
    if not ultra.enable_dynamic_tools:
        raise HTTPException(status_code=503, detail="Dynamic tools not enabled")
    
    tool = await ultra.create_tool(req.goal, req.requirements)
    
    return ToolCreationResponse(
        tool_id=tool.id,
        name=tool.spec.name,
        status=tool.status.value,
        validation_result=tool.validation_result.__dict__ if tool.validation_result else None,
        test_result=tool.test_result.__dict__ if tool.test_result else None,
        capability_id=tool.capability_id,
        error=tool.error,
    )


@router.get("/tool/{tool_id}")
async def get_dynamic_tool(
    tool_id: str,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get a dynamic tool by ID."""
    if not ultra._dynamic_tools:
        raise HTTPException(status_code=503, detail="Dynamic tools not enabled")
    
    tool = ultra._dynamic_tools.get_tool(tool_id)
    if not tool:
        raise HTTPException(status_code=404, detail="Tool not found")
    return tool.__dict__


@router.get("/tools")
async def list_dynamic_tools(
    status: Optional[str] = None,
    ultra: MayaUltra = Depends(get_ultra),
):
    """List all dynamic tools."""
    if not ultra._dynamic_tools:
        raise HTTPException(status_code=503, detail="Dynamic tools not enabled")
    
    tool_status = ToolCreationStatus(status) if status else None
    tools = ultra._dynamic_tools.list_tools(tool_status)
    return [t.__dict__ for t in tools]


@router.post("/tool/{tool_id}/update")
async def update_dynamic_tool(
    tool_id: str,
    code: Optional[str] = Body(None),
    version: Optional[str] = Body(None),
    test_cases: Optional[List[Dict]] = Body(None),
    ultra: MayaUltra = Depends(get_ultra),
):
    """Update a dynamic tool (creates new version)."""
    if not ultra._dynamic_tools:
        raise HTTPException(status_code=503, detail="Dynamic tools not enabled")
    
    tool = await ultra._dynamic_tools.update_tool(tool_id, code, version, test_cases)
    return tool.__dict__


@router.post("/tool/{tool_id}/rollback")
async def rollback_dynamic_tool(
    tool_id: str,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Rollback a dynamic tool to previous version."""
    if not ultra._dynamic_tools:
        raise HTTPException(status_code=503, detail="Dynamic tools not enabled")
    
    success = ultra._dynamic_tools.rollback_tool(tool_id)
    return {"success": success}


@router.delete("/tool/{tool_id}")
async def delete_dynamic_tool(
    tool_id: str,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Delete a dynamic tool."""
    if not ultra._dynamic_tools:
        raise HTTPException(status_code=503, detail="Dynamic tools not enabled")
    
    success = ultra._dynamic_tools.delete_tool(tool_id)
    return {"success": success}


# ─── Vision Browser Endpoints ────────────────────────────────────
@router.post("/browser/act", response_model=BrowserActionResponse)
async def browser_autonomous_action(
    req: BrowserActionRequest,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Execute autonomous browser action to achieve a goal."""
    if not ultra.enable_vision_browser:
        raise HTTPException(status_code=503, detail="Vision browser not enabled")
    
    result = await ultra.browse_and_act(req.goal, req.url)
    return BrowserActionResponse(**result)


@router.post("/browser/task")
async def create_browser_task(
    goal: str = Body(...),
    url: str = Body(""),
    ultra: MayaUltra = Depends(get_ultra),
):
    """Create a browser task for manual execution."""
    if not ultra._vision_browser:
        raise HTTPException(status_code=503, detail="Vision browser not enabled")
    
    task = await ultra._vision_browser.create_task(goal, url)
    return task.__dict__


@router.post("/browser/task/{task_id}/run")
async def run_browser_task(
    task_id: str,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Run a browser task."""
    # This would need task storage - simplified for now
    raise HTTPException(status_code=501, detail="Task persistence not implemented")


@router.get("/browser/status")
async def browser_pool_status(
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get browser pool status."""
    if not ultra._vision_browser:
        raise HTTPException(status_code=503, detail="Vision browser not enabled")
    
    return await ultra._vision_browser.get_status()


# ─── Secure Sandbox Endpoints ────────────────────────────────────
@router.post("/sandbox/execute", response_model=SandboxExecutionResponse)
async def sandbox_execute(
    req: SandboxExecutionRequest,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Execute code in secure sandbox."""
    if not ultra.enable_secure_sandbox:
        raise HTTPException(status_code=503, detail="Secure sandbox not enabled")
    
    limits = SandboxLimits(
        timeout_seconds=req.timeout_seconds,
        memory_limit_mb=req.memory_limit_mb,
        network_enabled=req.network_enabled,
    )
    
    result = await ultra.execute_code(req.code, req.language, limits.__dict__)
    
    return SandboxExecutionResponse(
        execution_id=uuid.uuid4().hex[:12],
        success=result["success"],
        stdout=result["stdout"],
        stderr=result["stderr"],
        exit_code=result["exit_code"],
        duration_ms=result["duration_ms"],
        artifacts=result["artifacts"],
        error=result.get("error", ""),
    )


@router.get("/sandbox/stats")
async def sandbox_stats(
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get sandbox statistics."""
    if not ultra._secure_sandbox:
        raise HTTPException(status_code=503, detail="Secure sandbox not enabled")
    
    return ultra._secure_sandbox.get_stats()


@router.get("/sandbox/backends")
async def sandbox_backends(
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get available sandbox backends."""
    if not ultra._secure_sandbox:
        raise HTTPException(status_code=503, detail="Secure sandbox not enabled")
    
    return {
        "available": [b.value for b in ultra._secure_sandbox._backends.keys()],
        "preferred": ultra._secure_sandbox.preferred_backends[0].value if ultra._secure_sandbox.preferred_backends else None,
    }


# ─── Multi-Agent Swarm Endpoints ────────────────────────────────
@router.post("/swarm/execute", response_model=SwarmExecutionResponse)
async def swarm_execute(
    req: SwarmExecutionRequest,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Execute a goal using the multi-agent swarm."""
    if not ultra.enable_swarm:
        raise HTTPException(status_code=503, detail="Swarm not enabled")
    
    # Reconfigure swarm if needed
    if (req.num_architects != len(ultra._swarm.architects) or
        req.num_coders != len(ultra._swarm.coders) or
        req.num_testers != len(ultra._swarm.testers) or
        req.num_reviewers != len(ultra._swarm.reviewers)):
        # Would need to recreate swarm - simplified
        pass
    
    result = await ultra.run_swarm(req.goal, req.context)
    return SwarmExecutionResponse(**result)


@router.get("/swarm/status")
async def swarm_status(
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get swarm status."""
    if not ultra._swarm:
        raise HTTPException(status_code=503, detail="Swarm not enabled")
    
    return ultra._swarm.get_status()


@router.get("/swarm/queue/stats")
async def swarm_queue_stats(
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get task queue statistics."""
    if not ultra._swarm:
        raise HTTPException(status_code=503, detail="Swarm not enabled")
    
    return await ultra._swarm.task_queue.get_queue_stats()


@router.post("/swarm/task")
async def create_swarm_task(
    role: str = Body(...),
    title: str = Body(...),
    description: str = Body(...),
    payload: Dict = Body(default_factory=dict),
    priority: str = Body("normal"),
    dependencies: List[str] = Body(default_factory=list),
    ultra: MayaUltra = Depends(get_ultra),
):
    """Create a task for the swarm."""
    if not ultra._swarm:
        raise HTTPException(status_code=503, detail="Swarm not enabled")
    
    task = SwarmTask(
        task_id=uuid.uuid4().hex[:12],
        role=AgentRole(role),
        title=title,
        description=description,
        payload=payload,
        priority=TaskPriority[priority.upper()],
        dependencies=dependencies,
    )
    
    await ultra._swarm.task_queue.enqueue_task(task)
    return task.__dict__


@router.get("/swarm/task/{task_id}")
async def get_swarm_task(
    task_id: str,
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get a swarm task by ID."""
    if not ultra._swarm:
        raise HTTPException(status_code=503, detail="Swarm not enabled")
    
    task = await ultra._swarm.task_queue.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task.__dict__


# ─── System Status Endpoints ─────────────────────────────────────
@router.get("/status", response_model=UltraStatusResponse)
async def ultra_status(
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get overall ultra system status."""
    caps = ultra.get_capabilities()
    
    # Get detailed capability status
    details = {
        "dynamic_tools": {
            "enabled": caps.dynamic_tools,
            "tools_count": len(ultra._dynamic_tools.list_tools()) if ultra._dynamic_tools else 0,
        },
        "vision_browser": {
            "enabled": caps.vision_browser,
            "pool_status": await ultra._vision_browser.get_status() if ultra._vision_browser else {},
        },
        "secure_sandbox": {
            "enabled": caps.secure_sandbox,
            "stats": ultra._secure_sandbox.get_stats() if ultra._secure_sandbox else {},
        },
        "swarm": {
            "enabled": caps.swarm,
            "status": ultra._swarm.get_status() if ultra._swarm else {},
        },
    }
    
    return UltraStatusResponse(
        capabilities=details,
        stats=ultra.get_stats(),
        active_tasks=[t.__dict__ for t in ultra.get_active_tasks()],
    )


@router.get("/capabilities")
async def ultra_capabilities(
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get detailed capability status."""
    caps = ultra.get_capabilities()
    return caps.__dict__


@router.post("/mode")
async def set_ultra_mode(
    mode: str = Body(..., embed=True),
    ultra: MayaUltra = Depends(get_ultra),
):
    """Set the ultra system mode."""
    try:
        ultra.mode = UltraMode(mode)
        return {"mode": ultra.mode.value, "success": True}
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid mode: {mode}")


@router.get("/mode")
async def get_ultra_mode(
    ultra: MayaUltra = Depends(get_ultra),
):
    """Get the current ultra system mode."""
    return {"mode": ultra.mode.value}


# ─── Health Check ────────────────────────────────────────────────
@router.get("/health")
async def ultra_health():
    """Health check for ultra capabilities."""
    ultra = await get_ultra()
    caps = ultra.get_capabilities()
    
    return {
        "status": "healthy" if caps.all_ready else "degraded",
        "capabilities": caps.__dict__,
        "running": ultra._running,
    }


# ─── Export ──────────────────────────────────────────────────────
__all__ = ["router"]