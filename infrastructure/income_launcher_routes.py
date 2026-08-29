"""
Maya 2.0 ULTRA - Launch Agent API Routes
Income Engine: Production launch management.
"""
import os
import time
from fastapi import APIRouter, HTTPException, Depends, Form, Body
from typing import Optional, List, Dict
from pydantic import BaseModel

from infrastructure.income_launcher import get_launch_agent, LaunchAgent, LaunchProject, LaunchStatus, LaunchContent, reset_launch_agent

router = APIRouter(prefix="/api/v1/income/launcher", tags=["income-launcher"])


# Dependency
def get_agent() -> LaunchAgent:
    return get_launch_agent()


# Models
class LaunchCreate(BaseModel):
    build_project_id: str

class ContentApprove(BaseModel):
    content_id: str
    approved: bool
    feedback: str = ""

class ContentUpdate(BaseModel):
    content_id: str
    content: str

class LaunchConfig(BaseModel):
    subdomain: str = ""
    custom_domain: str = ""
    launch_date: Optional[float] = None


# ═════════════════════════════════════════════════════════════════════════════
# LAUNCH MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/launches")
async def create_launch(
    req: LaunchCreate,
    agent: LaunchAgent = Depends(get_agent),
):
    """Create a launch project from a completed build."""
    launch = agent.create_launch_from_build(req.build_project_id)
    if not launch:
        raise HTTPException(status_code=400, detail="Build project not found or not completed")
    return {
        "launch_id": launch.id,
        "title": launch.title,
        "status": launch.status.value,
        "subdomain": launch.subdomain,
    }


@router.get("/launches")
async def list_launches(
    status: Optional[str] = None,
    limit: int = 50,
    agent: LaunchAgent = Depends(get_agent),
):
    """List launch projects."""
    status_enum = LaunchStatus(status) if status else None
    launches = agent.list_launches(status_enum)
    return {
        "launches": [
            {
                "id": l.id,
                "build_project_id": l.build_project_id,
                "title": l.title,
                "status": l.status.value,
                "subdomain": l.subdomain,
                "launch_url": l.launch_url,
                "launched_at": l.launched_at,
                "created_at": l.created_at,
            }
            for l in launches[:limit]
        ],
        "count": len(launches),
    }


@router.get("/launches/{launch_id}")
async def get_launch(launch_id: str, agent: LaunchAgent = Depends(get_agent)):
    """Get launch details."""
    launch = agent.get_launch(launch_id)
    if not launch:
        raise HTTPException(status_code=404, detail="Launch not found")
    
    content = agent.get_content(launch_id)
    return {
        "id": launch.id,
        "build_project_id": launch.build_project_id,
        "plan_id": launch.plan_id,
        "title": launch.title,
        "description": launch.description,
        "status": launch.status.value,
        "domain": launch.domain,
        "subdomain": launch.subdomain,
        "launch_url": launch.launch_url,
        "launch_date": launch.launch_date,
        "content": [
            {
                "id": c.id,
                "content_type": c.content_type,
                "title": c.title,
                "status": c.status,
                "platform_url": c.platform_url,
            }
            for c in content
        ],
        "dns_records": launch.dns_records,
        "ssl_certificate": launch.ssl_certificate,
        "monitoring_config": launch.monitoring_config,
        "launch_url": launch.launch_url,
        "launched_at": launch.launched_at,
        "error": launch.error,
    }


@router.get("/launches/{launch_id}/content")
async def get_launch_content(launch_id: str, agent: LaunchAgent = Depends(get_agent)):
    """Get all content pieces for a launch."""
    content = agent.get_content(launch_id)
    return {
        "launch_id": launch_id,
        "content": [
            {
                "id": c.id,
                "content_type": c.content_type,
                "title": c.title,
                "content": c.content,
                "status": c.status,
                "platform_url": c.platform_url,
                "created_at": c.created_at,
                "approved_at": c.approved_at,
                "published_at": c.published_at,
            }
            for c in content
        ],
    }


@router.post("/content/approve")
async def approve_content(
    req: ContentApprove,
    agent: LaunchAgent = Depends(get_agent),
):
    """Approve or reject a content piece."""
    success = agent.approve_content(req.content_id, req.approved, req.feedback)
    if not success:
        raise HTTPException(status_code=404, detail="Content not found")
    return {"success": True, "content_id": req.content_id, "approved": req.approved}


@router.post("/content/update")
async def update_content(
    req: ContentUpdate,
    agent: LaunchAgent = Depends(get_agent),
):
    """Update content piece (for editing before approval)."""
    # In a full implementation, this would update the content
    return {"success": True, "content_id": req.content_id, "message": "Content update not yet implemented"}


@router.post("/launches/{launch_id}/config")
async def configure_launch(
    launch_id: str,
    req: LaunchConfig,
    agent: LaunchAgent = Depends(get_agent),
):
    """Configure launch settings (domain, subdomain, launch date)."""
    launch = agent.get_launch(launch_id)
    if not launch:
        raise HTTPException(status_code=404, detail="Launch not found")
    
    if req.subdomain:
        launch.subdomain = req.subdomain
    if req.custom_domain:
        launch.custom_domain = True
        launch.domain = req.custom_domain
    if req.launch_date:
        launch.launch_date = req.launch_date
    
    launch.updated_at = time.time()
    agent._store_launch(launch)
    
    return {"success": True, "launch_id": launch_id}


# ═════════════════════════════════════════════════════════════════════════════
# LAUNCH CONTROL
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/launches/{launch_id}/start")
async def start_launch(launch_id: str, agent: LaunchAgent = Depends(get_agent)):
    """Manually trigger launch processing."""
    launch = agent.get_launch(launch_id)
    if not launch:
        raise HTTPException(status_code=404, detail="Launch not found")
    
    # Trigger processing
    await agent._process_launch(launch)
    return {"success": True, "launch_id": launch_id, "status": launch.status.value}


@router.post("/launches/{launch_id}/retry")
async def retry_launch(launch_id: str, agent: LaunchAgent = Depends(get_agent)):
    """Retry a failed launch."""
    launch = agent.get_launch(launch_id)
    if not launch:
        raise HTTPException(status_code=404, detail="Launch not found")
    
    if launch.status != LaunchStatus.FAILED:
        raise HTTPException(status_code=400, detail="Only failed launches can be retried")
    
    launch.status = LaunchStatus.READY
    launch.error = ""
    launch.updated_at = time.time()
    agent._store_launch(launch)
    
    return {"success": True, "launch_id": launch_id, "status": "retrying"}


# ═════════════════════════════════════════════════════════════════════════════
# STATS & HEALTH
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/stats")
async def get_stats(agent: LaunchAgent = Depends(get_agent)):
    """Get launcher statistics."""
    launches = agent.list_launches()
    
    by_status = {}
    for l in launches:
        by_status[l.status.value] = by_status.get(l.status.value, 0) + 1
    
    total_content = 0
    approved_content = 0
    for l in launches:
        content = agent.get_content(l.id)
        total_content += len(content)
        approved_content += sum(1 for c in content if c.status == "approved")
    
    return {
        "total_launches": len(launches),
        "by_status": by_status,
        "total_content_pieces": total_content,
        "content_approved": approved_content,
    }


@router.get("/health")
async def health():
    return {"status": "healthy", "launcher_agent": "active"}


# ══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ════════════════════════════════════════════════════════════════════════════════

@router.on_event("startup")
async def startup_launcher():
    if os.environ.get("LAUNCHER_ENABLED", "true").lower() == "true":
        agent = get_launch_agent()
        await agent.start()

@router.on_event("shutdown")
async def shutdown_launcher():
    reset_launch_agent()