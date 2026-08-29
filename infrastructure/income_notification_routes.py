"""
Maya 2.0 ULTRA - Income Engine Notification Routes
Approval requests, digests, and multi-channel notifications.
"""
import os
import time
import json
from fastapi import APIRouter, HTTPException, Depends, Form, Body
from typing import Optional, List, Dict
from pydantic import BaseModel

from infrastructure.income_notifications import (
    get_notification_service, NotificationService, NotificationService,
    Notification, NotificationType, NotificationPriority, ApprovalRequest,
    reset_notification_service
)

router = APIRouter(prefix="/api/v1/income/notifications", tags=["income-notifications"])


# Dependency
def get_service() -> NotificationService:
    return get_notification_service()


# Models
class NotificationCreate(BaseModel):
    type: str
    priority: str = "normal"
    title: str
    message: str
    channels: List[str] = ["webhook"]
    metadata: Dict = {}

class ApprovalRequestCreate(BaseModel):
    action: str
    reason: str = ""
    risk_level: str = "high"
    task_id: str = ""
    plan_id: str = ""
    opportunity_id: str = ""
    title: str = ""
    description: str = ""
    expires_in_hours: int = 24

class ApprovalDecision(BaseModel):
    approval_id: str
    approved: bool
    decided_by: str = ""
    reason: str = ""

class DigestRequest(BaseModel):
    strategist_result: Dict = {}
    scout_stats: Dict = {}


# ═════════════════════════════════════════════════════════════════════════════
# NOTIFICATION SENDING
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/send")
async def send_notification(
    req: NotificationCreate,
    service: NotificationService = Depends(get_service),
):
    """Send a custom notification."""
    try:
        ntype = NotificationType(req.type)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid type: {req.type}")
    
    try:
        nprio = NotificationPriority(req.priority)
    except ValueError:
        nprio = NotificationPriority.NORMAL
    
    notification = Notification(
        type=ntype,
        priority=nprio,
        title=req.title,
        message=req.message,
        channels=req.channels,
        metadata=req.metadata,
    )
    
    await service.send_notification(notification)
    return {"success": True, "notification_id": notification.id}


# ═════════════════════════════════════════════════════════════════════════════
# APPROVAL REQUESTS
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/approvals/request")
async def create_approval_request(
    req: ApprovalRequestCreate,
    service: NotificationService = Depends(get_service),
):
    """Create an approval request and notify owner."""
    approval = ApprovalRequest(
        action=req.action,
        reason=req.reason,
        risk_level=req.risk_level,
        task_id=req.task_id,
        plan_id=req.plan_id,
        opportunity_id=req.opportunity_id,
        title=req.title,
        description=req.description,
        expires_at=time.time() + req.expires_in_hours * 3600 if req.expires_in_hours else None,
    )
    
    approval_id = await service.send_approval_request(approval)
    return {"success": True, "approval_id": approval_id}


@router.get("/approvals")
async def list_approvals(
    status: Optional[str] = None,
    limit: int = 50,
    service: NotificationService = Depends(get_service),
):
    """List approval requests."""
    from infrastructure.income_notifications import get_notif_conn
    with get_notif_conn() as conn:
        query = "SELECT * FROM approval_requests"
        params = []
        if status:
            query += " WHERE status = ?"
            params.append(status)
        query += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)
        rows = conn.execute(query, params).fetchall()
    return {"approvals": [dict(r) for r in rows], "count": len(rows)}


@router.get("/approvals/{approval_id}")
async def get_approval(approval_id: str, service: NotificationService = Depends(get_service)):
    """Get a single approval request."""
    from infrastructure.income_notifications import get_notif_conn
    with get_notif_conn() as conn:
        row = conn.execute("SELECT * FROM approval_requests WHERE id = ?", (approval_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Approval not found")
    return dict(row)


@router.post("/approvals/{approval_id}/decide")
async def decide_approval(
    approval_id: str,
    req: ApprovalDecision,
    service: NotificationService = Depends(get_service),
):
    """Decide on an approval request."""
    from infrastructure.income_notifications import get_notif_conn
    with get_notif_conn() as conn:
        row = conn.execute("SELECT * FROM approval_requests WHERE id = ?", (approval_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Approval not found")
        
        if row["status"] != "pending":
            raise HTTPException(status_code=400, detail=f"Already {row['status']}")
        
        decision = "approved" if req.approved else "rejected"
        decided_at = time.time()
        
        conn.execute("""
            UPDATE approval_requests 
            SET status = ?, decided_at = ?, decision = ?, decided_by = ?
            WHERE id = ?
        """, (decision, decided_at, decision, req.decided_by, approval_id))
        
        # Note: Notification sending skipped to avoid DB lock issues
        # In production, use a separate notification queue/worker
        
        return {"success": True, "approval_id": approval_id, "decision": decision}


# ═════════════════════════════════════════════════════════════════════════════
# DIGESTS & ALERTS
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/digest/daily")
async def send_daily_digest(
    req: DigestRequest,
    service: NotificationService = Depends(get_service),
):
    """Send daily digest notification."""
    from infrastructure.income_notifications import get_notification_service
    service = get_notification_service()
    await service.send_daily_digest(req.strategist_result, req.scout_stats)
    return {"success": True, "message": "Daily digest sent"}


@router.post("/alerts/builder")
async def send_builder_alert(
    project_name: str = Form(...),
    status: str = Form(...),
    details: str = Form(""),
    service: NotificationService = Depends(get_service),
):
    """Send builder status alert."""
    await service.send_builder_status(project_name, status, details)
    return {"success": True}


@router.post("/alerts/launch-ready")
async def send_launch_ready(
    project_name: str = Form(...),
    plan_id: str = Form(...),
    service: NotificationService = Depends(get_service),
):
    """Send launch-ready notification."""
    await service.send_launch_ready(project_name, plan_id)
    return {"success": True}


@router.post("/alerts/error")
async def send_error_alert(
    component: str = Form(...),
    error: str = Form(...),
    context: str = Form(""),
    service: NotificationService = Depends(get_service),
):
    """Send critical error alert."""
    await service.send_error_alert(component, error, context)
    return {"success": True}


# ══════════════════════════════════════════════════════════════════════════════
# TEMPLATES
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/templates")
async def list_templates(service: NotificationService = Depends(get_service)):
    """List notification templates."""
    from infrastructure.income_notifications import get_notif_conn
    with get_notif_conn() as conn:
        rows = conn.execute("SELECT * FROM notification_templates").fetchall()
    return {"templates": [dict(r) for r in rows]}


@router.post("/templates")
async def create_template(
    name: str = Form(...),
    subject_template: str = Form(...),
    body_template: str = Form(...),
    channels: str = Form('["webhook"]'),
    service: NotificationService = Depends(get_service),
):
    """Create a notification template."""
    from infrastructure.income_notifications import get_notif_conn
    try:
        channels_list = json.loads(channels)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid channels JSON")
    
    from infrastructure.income_notifications import get_notif_conn
    with get_notif_conn() as conn:
        conn.execute("""
            INSERT OR REPLACE INTO notification_templates (name, subject_template, body_template, channels)
            VALUES (?, ?, ?, ?)
        """, (name, subject_template, body_template, json.dumps(channels_list)))
    return {"success": True, "name": name}


@router.delete("/templates/{name}")
async def delete_template(name: str, service: NotificationService = Depends(get_service)):
    """Delete a notification template."""
    from infrastructure.income_notifications import get_notif_conn
    with get_notif_conn() as conn:
        conn.execute("DELETE FROM notification_templates WHERE name = ?", (name,))
    return {"success": True, "name": name}


# ══════════════════════════════════════════════════════════════════════════════
# STATUS & HEALTH
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/channels")
async def get_channels(service: NotificationService = Depends(get_service)):
    """Get configured notification channels."""
    from infrastructure.income_notifications import NOTIFICATION_CHANNELS
    return {
        "channels": {
            name: {"enabled": cfg.get("enabled"), "configured": bool(cfg.get("url") or cfg.get("bot_token") or cfg.get("webhook_url"))}
            for name, cfg in NOTIFICATION_CHANNELS.items()
        }
    }


@router.get("/stats")
async def get_stats(service: NotificationService = Depends(get_service)):
    """Get notification statistics."""
    from infrastructure.income_notifications import get_notif_conn
    with get_notif_conn() as conn:
        total = conn.execute("SELECT COUNT(*) FROM notifications").fetchone()[0]
        by_status = conn.execute("SELECT status, COUNT(*) as count FROM notifications GROUP BY status").fetchall()
        by_type = conn.execute("SELECT type, COUNT(*) as count FROM notifications GROUP BY type").fetchall()
        by_priority = conn.execute("SELECT priority, COUNT(*) as count FROM notifications GROUP BY priority").fetchall()
        recent = conn.execute("SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10").fetchall()
    
    return {
        "total_notifications": total,
        "by_status": [dict(r) for r in by_status],
        "by_type": [dict(r) for r in by_type],
        "by_priority": [dict(r) for r in by_priority],
        "recent": [dict(r) for r in recent],
    }


@router.get("/health")
async def health():
    return {"status": "healthy", "notification_service": "active"}


# ══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ══════════════════════════════════════════════════════════════════════════════

@router.on_event("startup")
async def startup_notifications():
    if os.environ.get("NOTIFICATIONS_ENABLED", "true").lower() == "true":
        get_notification_service()

@router.on_event("shutdown")
async def shutdown_notifications():
    reset_notification_service()