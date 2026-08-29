"""
Maya 2.0 ULTRA - Permission System API Routes
Phase 5 Safety Layer: Manual/Scoped Auto modes, Kill Switch, Scopes.
"""
import os
import json
from fastapi import APIRouter, HTTPException, Depends, Form, Body
from typing import Optional, List, Dict
from pydantic import BaseModel

from infrastructure.permissions import (
    get_permission_engine, PermissionEngine, PermissionMode, RiskLevel,
    ActionCategory, ActionRequest, PermissionScope, KillSwitch,
    DEFAULT_SAFE_SCOPES, DEFAULT_DANGEROUS_SCOPES
)
from api import get_current_user

logger = None  # Will be set on import

router = APIRouter(prefix="/api/v1/permissions", tags=["permissions"])


# ════════════════════════════════════════════════════════════════════════════
# MODELS
# ════════════════════════════════════════════════════════════════════════════

class ModeRequest(BaseModel):
    mode: str  # manual | scoped_auto | auto

class ScopeRequest(BaseModel):
    name: str
    description: str
    categories: List[str]
    max_risk_level: str = "low"
    requires_explicit_approval: bool = False

class ActionCheckRequest(BaseModel):
    action: str
    category: str
    risk_level: str = "low"
    tool_name: str = ""
    parameters: Dict = {}
    session_id: str = ""
    user_id: str = ""

class VoicePermissionRequest(BaseModel):
    transcript: str
    session_id: str = ""
    user_id: str = ""
    active_scopes: List[str] = []

class KillSwitchResetRequest(BaseModel):
    confirm: bool = True


# ════════════════════════════════════════════════════════════════════════════
# DEPENDENCY
# ════════════════════════════════════════════════════════════════════════════

def get_engine() -> PermissionEngine:
    return get_permission_engine()


# ════════════════════════════════════════════════════════════════════════════
# GLOBAL MODE
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/mode")
async def get_mode(engine: PermissionEngine = Depends(get_engine)):
    """Get current permission mode."""
    return {
        "mode": engine.mode.value,
        "available_modes": [m.value for m in PermissionMode],
        "description": {
            "manual": "Every action requires explicit human approval (DEFAULT)",
            "scoped_auto": "Safe actions in allowed scopes auto-approve",
            "auto": "All actions auto-approve (critical still needs approval)",
        }.get(engine.mode.value, "")
    }


@router.put("/mode")
async def set_mode(
    req: ModeRequest,
    engine: PermissionEngine = Depends(get_engine),
    user=Depends(get_current_user),
):
    """Set global permission mode."""
    try:
        new_mode = PermissionMode(req.mode.lower())
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid mode: {req.mode}")
    
    old_mode = engine.mode
    engine.mode = new_mode
    
    return {
        "success": True,
        "old_mode": old_mode.value,
        "new_mode": new_mode.value,
    }


# ════════════════════════════════════════════════════════════════════════════
# SCOPE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/scopes")
async def list_scopes(engine: PermissionEngine = Depends(get_engine)):
    """List all permission scopes."""
    return {"scopes": engine.list_scopes()}


@router.get("/scopes/{name}")
async def get_scope(name: str, engine: PermissionEngine = Depends(get_engine)):
    """Get a specific scope."""
    scope = engine.get_scope(name)
    if not scope:
        raise HTTPException(status_code=404, detail="Scope not found")
    return {
        "name": scope.name,
        "description": scope.description,
        "categories": [c.value for c in scope.allowed_categories],
        "max_risk_level": scope.max_risk_level.value,
        "requires_explicit_approval": scope.requires_explicit_approval,
    }


@router.post("/scopes")
async def create_scope(
    req: ScopeRequest,
    engine: PermissionEngine = Depends(get_engine),
    user=Depends(get_current_user),
):
    """Create a custom permission scope."""
    try:
        categories = [ActionCategory(c) for c in req.categories]
        max_risk = RiskLevel(req.max_risk_level)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid category or risk level: {e}")
    
    scope = engine.create_scope(
        name=req.name,
        description=req.description,
        categories=categories,
        max_risk=max_risk,
        requires_explicit=req.requires_explicit_approval,
    )
    
    return {"success": True, "scope": scope.name}


@router.delete("/scopes/{name}")
async def delete_scope(name: str, engine: PermissionEngine = Depends(get_engine),
                       user=Depends(get_current_user)):
    """Delete a custom scope."""
    try:
        engine.delete_scope(name)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return {"success": True, "deleted": name}


# ═════════════════════════════════════════════════════════════════════════════
# PERMISSION CHECKS
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/check")
async def check_permission(
    req: ActionCheckRequest,
    active_scopes: Optional[List[str]] = None,
    engine: PermissionEngine = Depends(get_engine),
):
    """Check if an action would be permitted."""
    try:
        category = ActionCategory(req.category)
        risk = RiskLevel(req.risk_level)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid category or risk level: {e}")
    
    request = ActionRequest(
        action=req.action,
        category=category,
        risk_level=risk,
        tool_name=req.tool_name,
        parameters=req.parameters,
        session_id=req.session_id,
        user_id=req.user_id,
    )
    
    decision = engine.check_permission(request, active_scopes)
    
    return {
        "action_id": decision.action_id,
        "approved": decision.approved,
        "mode": decision.mode.value,
        "reason": decision.reason,
        "auto_approved": decision.auto_approved,
        "decided_by": decision.decided_by,
        "scope_name": decision.scope_name,
    }


@router.post("/check/tool")
async def check_tool_permission(
    tool_name: str = Form(...),
    parameters: str = Form("{}"),
    session_id: str = Form(""),
    user_id: str = Form(""),
    active_scopes: Optional[str] = Form(None),  # JSON array
    engine: PermissionEngine = Depends(get_engine),
):
    """Check permission for tool invocation."""
    try:
        params = json.loads(parameters)
        scopes = json.loads(active_scopes) if active_scopes else None
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")
    
    decision = engine.check_tool_permission(tool_name, params, session_id, user_id, scopes)
    
    return {
        "approved": decision.approved,
        "reason": decision.reason,
        "auto_approved": decision.auto_approved,
        "scope_name": decision.scope_name,
    }


@router.post("/check/voice")
async def check_voice_permission(
    req: VoicePermissionRequest,
    engine: PermissionEngine = Depends(get_engine),
):
    """Check permission for a voice command."""
    decision = engine.check_voice_permission(
        transcript=req.transcript,
        session_id=req.session_id,
        user_id=req.user_id,
        active_scopes=req.active_scopes,
    )
    
    return {
        "approved": decision.approved,
        "reason": decision.reason,
        "auto_approved": decision.auto_approved,
        "scope_name": decision.scope_name,
        "category": decision.action_id,  # Will contain category info
    }


# ═════════════════════════════════════════════════════════════════════════════
# KILL SWITCH
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/kill-switch")
async def get_kill_switch_status(engine: PermissionEngine = Depends(get_engine)):
    """Get kill switch status."""
    return engine.kill_switch.get_status()


@router.post("/kill-switch/trigger")
async def trigger_kill_switch(
    reason: str = Form("Manual trigger"),
    engine: PermissionEngine = Depends(get_engine),
    user=Depends(get_current_user),
):
    """Activate the kill switch."""
    email = user.get("email", "unknown")
    engine.kill_switch.trigger(reason=reason, triggered_by=email)
    return {"success": True, "status": engine.kill_switch.get_status()}


@router.post("/kill-switch/reset")
async def reset_kill_switch(
    req: KillSwitchResetRequest,
    engine: PermissionEngine = Depends(get_engine),
    user=Depends(get_current_user),
):
    """Reset (deactivate) the kill switch."""
    if not req.confirm:
        raise HTTPException(status_code=400, detail="Must confirm reset")
    
    email = user.get("email", "unknown")
    success = engine.kill_switch.reset(reset_by=email)
    if not success:
        raise HTTPException(status_code=400, detail="Kill switch not active")
    
    return {"success": True, "status": engine.kill_switch.get_status()}


# ═════════════════════════════════════════════════════════════════════════════
# DECISION LOG
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/decisions")
async def get_decisions(
    limit: int = 100,
    engine: PermissionEngine = Depends(get_engine),
):
    """Get recent permission decisions."""
    return {"decisions": engine.get_recent_decisions(limit)}


# ═════════════════════════════════════════════════════════════════════════════
# CONSTANTS REFERENCE
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/constants")
async def get_constants():
    """Get permission system constants for frontend."""
    return {
        "modes": [m.value for m in PermissionMode],
        "risk_levels": [r.value for r in RiskLevel],
        "categories": [c.value for c in ActionCategory],
        "default_safe_scopes": [c.value for c in DEFAULT_SAFE_SCOPES],
        "default_dangerous_scopes": [c.value for c in DEFAULT_DANGEROUS_SCOPES],
        "builtin_scopes": ["read_only", "developer", "admin"],
    }


# ═════════════════════════════════════════════════════════════════════════════
# INTEGRATION WITH EXISTING APPROVAL ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/approval/mode")
async def get_approval_mode():
    """Get current approval mode (delegates to existing endpoint)."""
    from api import maya_instance
    if maya_instance:
        return {"mode": maya_instance.approval.mode}
    return {"mode": os.getenv("APPROVAL_MODE", "auto")}


@router.put("/approval/mode")
async def set_approval_mode(mode: str = Form(...)):
    """Set approval mode (delegates to existing endpoint)."""
    from api import maya_instance
    if not maya_instance:
        raise HTTPException(status_code=503, detail="Maya not initialized")
    maya_instance.approval.mode = mode
    return {"mode": mode}