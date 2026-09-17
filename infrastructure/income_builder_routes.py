"""
Maya 2.0 ULTRA - Builder Agent API Routes
Income Engine: Autonomous MVP building from approved plans.
"""
import os
import time
from fastapi import APIRouter, HTTPException, Depends, Form, Body
from typing import Optional, List, Dict
from pydantic import BaseModel

from infrastructure.income_builder import get_builder_agent, BuilderAgent, BuildProject, BuildStatus, BuildStep, BuildStepType, reset_builder_agent

router = APIRouter(prefix="/api/v1/income/builder", tags=["income-builder"])


# Dependency
def get_agent() -> BuilderAgent:
    return get_builder_agent()


# Models
class ProjectCreate(BaseModel):
    plan_id: str

class StepExecute(BaseModel):
    project_id: str
    step_id: str

class ProjectStatusUpdate(BaseModel):
    status: str  # retry, cancel, pause


# ═════════════════════════════════════════════════════════════════════════════
# PROJECT MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/projects")
async def create_project(
    req: ProjectCreate,
    agent: BuilderAgent = Depends(get_agent),
):
    """Create a build project from an approved plan."""
    project = agent.create_project_from_plan(req.plan_id)
    if not project:
        raise HTTPException(status_code=400, detail="Plan not found or not approved")
    return {
        "project_id": project.id,
        "title": project.title,
        "status": project.status.value,
        "steps": len(project.steps),
        "repo_path": project.repo_path,
    }


@router.get("/projects")
async def list_projects(
    status: Optional[str] = None,
    limit: int = 50,
    agent: BuilderAgent = Depends(get_agent),
):
    """List build projects."""
    status_enum = BuildStatus(status) if status else None
    projects = agent.list_projects(status_enum)
    return {
        "projects": [
            {
                "id": p.id,
                "plan_id": p.plan_id,
                "title": p.title,
                "status": p.status.value,
                "current_step": p.current_step,
                "total_steps": len(p.steps),
                "iteration": p.current_iteration,
                "repo_path": p.repo_path,
                "deploy_url": p.deploy_url,
                "created_at": p.created_at,
                "updated_at": p.updated_at,
            }
            for p in projects[:limit]
        ],
        "count": len(projects),
    }


@router.get("/projects/{project_id}")
async def get_project(project_id: str, agent: BuilderAgent = Depends(get_agent)):
    """Get project details."""
    project = agent.get_project(project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    return {
        "id": project.id,
        "plan_id": project.plan_id,
        "opportunity_id": project.opportunity_id,
        "title": project.title,
        "description": project.description,
        "status": project.status.value,
        "repo_path": project.repo_path,
        "repo_url": project.repo_url,
        "deploy_url": project.deploy_url,
        "mvp_scope": project.mvp_scope,
        "technical_approach": project.technical_approach,
        "timeline": project.timeline,
        "success_metrics": project.success_metrics,
        "current_iteration": project.current_iteration,
        "max_iterations": project.max_iterations,
        "current_step": project.current_step,
        "total_steps": len(project.steps),
        "test_results": project.test_results,
        "deploy_info": project.deploy_info,
        "error": project.error,
        "steps": [
            {
                "id": s.id,
                "step_type": s.step_type.value,
                "description": s.description,
                "status": s.status,
                "started_at": s.started_at,
                "completed_at": s.completed_at,
                "error": s.error,
            }
            for s in project.steps
        ],
        "created_at": project.created_at,
        "updated_at": project.updated_at,
        "started_at": project.started_at,
        "completed_at": project.completed_at,
    }


@router.post("/projects/{project_id}/status")
async def update_project_status(
    project_id: str,
    req: ProjectStatusUpdate,
    agent: BuilderAgent = Depends(get_agent),
):
    """Update project status (retry, cancel, pause)."""
    project = agent.get_project(project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    if req.status == "retry" and project.status == BuildStatus.FAILED:
        project.status = BuildStatus.BUILDING
        project.error = ""
        project.updated_at = time.time()
        # Reset failed steps
        for step in project.steps:
            if step.status == "failed":
                step.status = "pending"
                step.error = ""
        from infrastructure.income_engine import get_income_conn
        with get_income_conn() as conn:
            conn.execute("UPDATE build_projects SET status = ?, error = ?, updated_at = ? WHERE id = ?",
                        (BuildStatus.BUILDING.value, "", time.time(), project_id))
        return {"success": True, "project_id": project_id, "status": "retrying"}
    
    elif req.status == "cancel":
        project.status = BuildStatus.FAILED
        project.error = "Cancelled by user"
        from infrastructure.income_engine import get_income_conn
        with get_income_conn() as conn:
            conn.execute("UPDATE build_projects SET status = ?, error = ?, updated_at = ? WHERE id = ?",
                        (BuildStatus.FAILED.value, "Cancelled by user", time.time(), project_id))
        return {"success": True, "project_id": project_id, "status": "cancelled"}
    
    raise HTTPException(status_code=400, detail=f"Invalid status transition: {req.status}")


# ═════════════════════════════════════════════════════════════════════════════
# BUILD STEPS
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/projects/{project_id}/steps")
async def get_project_steps(project_id: str, agent: BuilderAgent = Depends(get_agent)):
    """Get all steps for a project."""
    project = agent.get_project(project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    return {
        "project_id": project_id,
        "current_step": project.current_step,
        "total_steps": len(project.steps),
        "steps": [
            {
                "id": s.id,
                "step_type": s.step_type.value,
                "description": s.description,
                "status": s.status,
                "input_data": s.input_data,
                "output_data": s.output_data,
                "error": s.error,
                "started_at": s.started_at,
                "completed_at": s.completed_at,
                "iteration": s.iteration,
            }
            for s in project.steps
        ],
    }


@router.post("/projects/{project_id}/steps/{step_id}/execute")
async def execute_step(
    project_id: str,
    step_id: str,
    agent: BuilderAgent = Depends(get_agent),
):
    """Manually trigger step execution (for debugging)."""
    project = agent.get_project(project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    step = next((s for s in project.steps if s.id == step_id), None)
    if not step:
        raise HTTPException(status_code=404, detail="Step not found")
    
    if step.status != "pending":
        raise HTTPException(status_code=400, detail=f"Step status is {step.status}, not pending")
    
    await agent._execute_step(project, step)
    
    return {"success": True, "step_id": step_id, "status": step.status}


# ═════════════════════════════════════════════════════════════════════════════
# AUTOMATED BUILD (from approved plan)
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/build-from-plan")
async def build_from_plan(
    plan_id: str = Form(...),
    agent: BuilderAgent = Depends(get_agent),
):
    """Create project from approved plan and start building."""
    project = agent.create_project_from_plan(plan_id)
    if not project:
        raise HTTPException(status_code=400, detail="Plan not found or not approved")
    
    # Start building (async)
    return {
        "project_id": project.id,
        "title": project.title,
        "status": project.status.value,
        "message": "Build project created. Building will start automatically.",
    }


# ═════════════════════════════════════════════════════════════════════════════
# STATS
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/stats")
async def get_stats(agent: BuilderAgent = Depends(get_agent)):
    """Get builder statistics."""
    projects = agent.list_projects()
    
    by_status = {}
    for p in projects:
        by_status[p.status.value] = by_status.get(p.status.value, 0) + 1
    
    return {
        "total_projects": len(projects),
        "by_status": by_status,
        "active_projects": len(agent.active_projects),
        "total_steps": sum(len(p.steps) for p in projects),
    }


@router.get("/health")
async def health():
    return {"status": "healthy", "builder_agent": "active"}


# ═════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ═════════════════════════════════════════════════════════════════════════════

@router.on_event("startup")
async def startup_builder():
    if os.environ.get("BUILDER_ENABLED", "true").lower() == "true":
        agent = get_builder_agent()
        await agent.start()

@router.on_event("shutdown")
async def shutdown_builder():
    reset_builder_agent()