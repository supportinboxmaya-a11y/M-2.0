"""
Maya 2.0 ULTRA - Extended Agent API Routes
Phase 5 capabilities: proactive tasks, autonomous planning, interruption handling, extended tools.
"""
import os
import json
from fastapi import APIRouter, HTTPException, Depends, Form, WebSocket, WebSocketDisconnect
from typing import Optional, List, Dict
import logging

from infrastructure.extended_agent import (
    get_extended_agent, ExtendedAgent, ExtendedTask, TaskStatus, TaskType,
    ProactiveTaskScheduler, AutonomousPlanner, InterruptionHandler,
    PersistentMemory, reset_extended_agent,
    EXTENDED_AGENT_ENABLED, PROACTIVE_TASKS_ENABLED, INTERRUPTION_ENABLED
)

logger = logging.getLogger("extended_agent_routes")

router = APIRouter(prefix="/api/v1/extended", tags=["extended-agent"])


# Dependency to get extended agent
def get_agent() -> ExtendedAgent:
    return get_extended_agent()


# ═════════════════════════════════════════════════════════════════════════════
# STATUS & HEALTH
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/status")
async def extended_status(agent: ExtendedAgent = Depends(get_agent)):
    """Get extended agent status."""
    return agent.get_status()


@router.get("/health")
async def extended_health():
    """Health check for extended agent."""
    return {"status": "healthy", "extended_agent": EXTENDED_AGENT_ENABLED}


# ════════════════════════════════════════════════════════════════════════════
# TASK MANAGEMENT (Multi-step autonomous planning)
# ════════════════════════════════════════════════════════════════════════════

@router.post("/tasks")
async def create_task(
    goal: str = Form(...),
    task_type: str = Form("user_request"),
    session_id: str = Form(""),
    user_id: str = Form(""),
    agent: ExtendedAgent = Depends(get_agent),
):
    """Create a new autonomous task with auto-generated plan."""
    try:
        ttype = TaskType(task_type)
    except ValueError:
        ttype = TaskType.USER_REQUEST
    
    task = agent.autonomous_planner.create_task(
        goal=goal,
        task_type=ttype,
        session_id=session_id,
        user_id=user_id,
    )
    
    return {
        "task_id": task.id,
        "goal": task.goal,
        "status": task.status.value,
        "total_steps": task.total_steps,
        "plan": task.plan,
    }


@router.get("/tasks/{task_id}")
async def get_task_status(task_id: str, agent: ExtendedAgent = Depends(get_agent)):
    """Get task status and progress."""
    status = agent.get_task_status(task_id)
    if not status:
        raise HTTPException(status_code=404, detail="Task not found")
    return status


@router.post("/tasks/{task_id}/interrupt")
async def interrupt_task(task_id: str, reason: str = Form("User interruption"),
                         agent: ExtendedAgent = Depends(get_agent)):
    """Interrupt a running task."""
    task_status = agent.get_task_status(task_id)
    if not task_status:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task_status["status"] != "running":
        raise HTTPException(status_code=400, detail=f"Task not running (status: {task_status['status']})")
    
    agent.autonomous_planner.interrupt_task(task_id, reason)
    return {"success": True, "task_id": task_id, "interrupted": True}


@router.post("/tasks/{task_id}/cancel")
async def cancel_task(task_id: str, agent: ExtendedAgent = Depends(get_agent)):
    """Cancel a task."""
    task_status = agent.get_task_status(task_id)
    if not task_status:
        raise HTTPException(status_code=404, detail="Task not found")
    
    agent.autonomous_planner.cancel_task(task_id)
    return {"success": True, "task_id": task_id, "cancelled": True}


@router.get("/tasks")
async def list_tasks(
    status: Optional[str] = None,
    session_id: Optional[str] = None,
    agent: ExtendedAgent = Depends(get_agent),
):
    """List tasks (filter by status/session)."""
    tasks = []
    for task in agent.autonomous_planner.active_tasks.values():
        if status and task.status.value != status:
            continue
        if session_id and task.session_id != session_id:
            continue
        tasks.append({
            "id": task.id, "goal": task.goal, "status": task.status.value,
            "current_step": task.current_step, "total_steps": task.total_steps,
            "task_type": task.task_type.value, "session_id": task.session_id,
            "created_at": task.created_at,
        })
    return {"tasks": tasks, "count": len(tasks)}


# ════════════════════════════════════════════════════════════════════════════
# PROACTIVE TASKS (Scheduled background jobs)
# ════════════════════════════════════════════════════════════════════════════

@router.get("/proactive/jobs")
async def list_proactive_jobs(agent: ExtendedAgent = Depends(get_agent)):
    """List all proactive jobs."""
    return {"jobs": agent.list_proactive_jobs()}


@router.post("/proactive/jobs")
async def create_proactive_job(
    name: str = Form(...),
    description: str = Form(...),
    cron: str = Form(...),
    notify_on_failure: bool = Form(True),
    notify_on_success: bool = Form(False),
    agent: ExtendedAgent = Depends(get_agent),
):
    """Create a new proactive background job."""
    job_id = agent.add_proactive_job(name, description, cron)
    return {"job_id": job_id, "name": name, "cron": cron}


@router.delete("/proactive/jobs/{job_id}")
async def delete_proactive_job(job_id: str, agent: ExtendedAgent = Depends(get_agent)):
    """Delete a proactive job."""
    success = agent.proactive_scheduler.remove_job(job_id)
    if not success:
        raise HTTPException(status_code=404, detail="Job not found")
    return {"success": True, "job_id": job_id}


@router.post("/proactive/jobs/{job_id}/run")
async def run_proactive_job_now(job_id: str, agent: ExtendedAgent = Depends(get_agent)):
    """Manually trigger a proactive job."""
    job = agent.proactive_scheduler.jobs.get(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    result = await agent.proactive_scheduler.run_job(job)
    return {"job_id": job_id, **result}


# ════════════════════════════════════════════════════════════════════════════
# PERSISTENT MEMORY (Cross-session)
# ════════════════════════════════════════════════════════════════════════════

@router.post("/memory/preferences")
async def set_preference(
    user_id: str = Form(...),
    key: str = Form(...),
    value: str = Form(...),
    agent: ExtendedAgent = Depends(get_agent),
):
    """Store a user preference."""
    agent.remember_user_preference(user_id, key, value)
    return {"success": True, "user_id": user_id, "key": key, "value": value}


@router.get("/memory/preferences/{user_id}/{key}")
async def get_preference(user_id: str, key: str, agent: ExtendedAgent = Depends(get_agent)):
    """Get a user preference."""
    value = agent.get_user_preference(user_id, key)
    if value is None:
        raise HTTPException(status_code=404, detail="Preference not found")
    return {"user_id": user_id, "key": key, "value": value}


@router.get("/memory/preferences/{user_id}")
async def list_preferences(user_id: str, agent: ExtendedAgent = Depends(get_agent)):
    """List all preferences for a user."""
    facts = agent.persistent_memory.get_facts(user_id)
    prefs = [f for f in facts if f.get("metadata", {}).get("key")]
    return {"user_id": user_id, "preferences": prefs}


@router.post("/memory/facts")
async def remember_fact(
    user_id: str = Form(...),
    fact: str = Form(...),
    topic: str = Form("general"),
    agent: ExtendedAgent = Depends(get_agent),
):
    """Store a learned fact."""
    agent.persistent_memory.remember_fact(user_id, fact, topic)
    return {"success": True, "user_id": user_id, "topic": topic}


@router.get("/memory/facts/{user_id}")
async def list_facts(user_id: str, topic: Optional[str] = None, 
                     agent: ExtendedAgent = Depends(get_agent)):
    """List learned facts for a user."""
    facts = agent.persistent_memory.get_facts(user_id, topic)
    return {"user_id": user_id, "facts": facts}


@router.post("/memory/projects")
async def save_project_state(
    project_id: str = Form(...),
    state: str = Form(...),  # JSON string
    agent: ExtendedAgent = Depends(get_agent),
):
    """Save project state."""
    try:
        state_dict = json.loads(state)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")
    
    agent.save_project_state(project_id, state_dict)
    return {"success": True, "project_id": project_id}


@router.get("/memory/projects/{project_id}")
async def load_project_state(project_id: str, agent: ExtendedAgent = Depends(get_agent)):
    """Load project state."""
    state = agent.load_project_state(project_id)
    if state is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return {"project_id": project_id, "state": state}


@router.get("/memory/context")
async def get_relevant_context(
    query: str,
    user_id: Optional[str] = None,
    limit: int = 10,
    agent: ExtendedAgent = Depends(get_agent),
):
    """Get relevant cross-session context for a query."""
    context = agent.persistent_memory.get_relevant_context(query, user_id, limit)
    return {"query": query, "context": context}


# ════════════════════════════════════════════════════════════════════════════
# INTERRUPTION HANDLING
# ════════════════════════════════════════════════════════════════════════════

@router.get("/interruptions")
async def list_interruptions(
    session_id: Optional[str] = None,
    limit: int = 20,
    agent: ExtendedAgent = Depends(get_agent),
):
    """List interruption events."""
    events = agent.interruption_handler.get_interruption_history(session_id, limit)
    return {"interruptions": events, "count": len(events)}


@router.post("/interrupt")
async def trigger_interrupt(
    session_id: str = Form(...),
    reason: str = Form("Manual interrupt"),
    agent: ExtendedAgent = Depends(get_agent),
):
    """Manually trigger an interruption for a session."""
    success = agent.interrupt_current_task(session_id, reason)
    if not success:
        raise HTTPException(status_code=404, detail="No running task for session")
    return {"success": True, "session_id": session_id, "interrupted": True}


# ════════════════════════════════════════════════════════════════════════════
# VOICE COMMAND PROCESSING (with full extended capabilities)
# ════════════════════════════════════════════════════════════════════════════

@router.post("/voice/command")
async def process_voice_command(
    transcript: str = Form(...),
    session_id: str = Form(""),
    user_id: str = Form(""),
    agent: ExtendedAgent = Depends(get_agent),
):
    """
    Process a voice command with full extended capabilities:
    - Cross-session context
    - Autonomous planning
    - Interruption handling
    - Persistent memory storage
    """
    result = await agent.process_voice_command(session_id, transcript, user_id)
    return result


# ════════════════════════════════════════════════════════════════════════════
# EXTENDED TOOLS (Calendar, search, file management, system)
# ════════════════════════════════════════════════════════════════════════════

@router.get("/tools/extended")
async def list_extended_tools(agent: ExtendedAgent = Depends(get_agent)):
    """List all available extended tools."""
    from api import maya_instance
    if not maya_instance:
        return {"tools": [], "count": 0}
    tool_registry = maya_instance.tool_manager.get_registry()
    all_tools = tool_registry.list_tools()
    extended = [t for t in all_tools if t["category"] in 
               ("calendar", "files", "system", "research", "communication")]
    return {"tools": extended, "count": len(extended)}


# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

@router.get("/config")
async def get_config():
    """Get extended agent configuration."""
    return {
        "extended_agent_enabled": EXTENDED_AGENT_ENABLED,
        "proactive_tasks_enabled": PROACTIVE_TASKS_ENABLED,
        "interruption_enabled": INTERRUPTION_ENABLED,
    }


@router.post("/config")
async def update_config(
    extended_agent_enabled: Optional[bool] = Form(None),
    proactive_tasks_enabled: Optional[bool] = Form(None),
    interruption_enabled: Optional[bool] = Form(None),
    agent: ExtendedAgent = Depends(get_agent),
):
    """Update extended agent configuration (runtime only)."""
    global EXTENDED_AGENT_ENABLED, PROACTIVE_TASKS_ENABLED, INTERRUPTION_ENABLED
    
    if extended_agent_enabled is not None:
        EXTENDED_AGENT_ENABLED = extended_agent_enabled
    if proactive_tasks_enabled is not None:
        PROACTIVE_TASKS_ENABLED = proactive_tasks_enabled
        if proactive_tasks_enabled:
            agent.proactive_scheduler.start()
        else:
            agent.proactive_scheduler.stop()
    if interruption_enabled is not None:
        INTERRUPTION_ENABLED = interruption_enabled
    
    return get_config()


# ════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ════════════════════════════════════════════════════════════════════════════

# Register extended agent startup/shutdown
@router.on_event("startup")
async def startup_extended():
    if EXTENDED_AGENT_ENABLED:
        agent = get_extended_agent()
        await agent.start()

@router.on_event("shutdown")
async def shutdown_extended():
    agent = get_extended_agent()
    await agent.stop()