"""
Maya 2.0 ULTRA - Permission & Approval System (Phase 5 Safety Layer)
=====================================================================
Provides a comprehensive permission framework for extended agent capabilities:

1. MANUAL MODE (default) - Every action requires explicit human approval
2. SCOPED AUTO MODE - Pre-approved safe actions run automatically within defined scopes
3. KILL-SWITCH - Global emergency stop for all autonomous operations

Integrates with existing ApprovalManager and InterventionHandler.
"""
import os
import json
import time
import uuid
import threading
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
from pathlib import Path

from config.settings import STORAGE_DIR
from human.approval import ApprovalManager, APPROVAL_AUTO, APPROVAL_HUMAN
from human.intervention import InterventionHandler
from maya_logging.logger import get_logger

log = get_logger("permissions")

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

PERM_DIR = STORAGE_DIR / "permissions"
PERM_DIR.mkdir(parents=True, exist_ok=True)
PERM_DB = str(PERM_DIR / "permissions.db")

# Default mode: MANUAL (every action needs approval)
DEFAULT_PERMISSION_MODE = os.environ.get("PERMISSION_MODE", "manual")  # manual | scoped_auto | auto
KILL_SWITCH_ENABLED = os.environ.get("KILL_SWITCH_ENABLED", "true").lower() == "true"

# ════════════════════════════════════════════════════════════════════════════
# PERMISSION MODES & SCOPES
# ════════════════════════════════════════════════════════════════════════════

class PermissionMode(Enum):
    """Global permission modes."""
    MANUAL = "manual"           # Every action requires approval (DEFAULT)
    SCOPED_AUTO = "scoped_auto" # Safe actions in allowed scopes auto-approve
    AUTO = "auto"               # All actions auto-approve (dangerous - dev only)


class RiskLevel(Enum):
    """Risk levels for actions."""
    LOW = "low"           # Read-only, no side effects
    MEDIUM = "medium"     # May modify local state
    HIGH = "high"         # External actions, deployments, deletions
    CRITICAL = "critical" # Irreversible, financial, account changes


class ActionCategory(Enum):
    """Categories of actions for scoping."""
    READ = "read"                    # File/memory reading
    SEARCH = "search"                # Web search, knowledge lookup
    CALCULATE = "calculate"          # Math, code execution (sandboxed)
    FILE_READ = "file_read"          # Reading files
    FILE_WRITE = "file_write"        # Writing/modifying files
    SHELL = "shell"                  # Shell commands
    DEPLOY = "deploy"                # Deployments, publishes
    EXTERNAL_API = "external_api"    # Third-party API calls
    FINANCIAL = "financial"          # Payments, billing
    ACCOUNT = "account"              # Account management
    SYSTEM = "system"                # System administration
    VOICE = "voice"                  # Voice interactions


# Pre-defined safe scopes (auto-approved in SCOPED_AUTO mode)
DEFAULT_SAFE_SCOPES: Set[ActionCategory] = {
    ActionCategory.READ,
    ActionCategory.SEARCH,
    ActionCategory.CALCULATE,
    ActionCategory.FILE_READ,
}

DEFAULT_DANGEROUS_SCOPES: Set[ActionCategory] = {
    ActionCategory.FILE_WRITE,
    ActionCategory.SHELL,
    ActionCategory.DEPLOY,
    ActionCategory.EXTERNAL_API,
    ActionCategory.FINANCIAL,
    ActionCategory.ACCOUNT,
    ActionCategory.SYSTEM,
}


# ════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ════════════════════════════════════════════════════════════════════════════

@dataclass
class PermissionScope:
    """A named scope defining allowed action categories."""
    name: str
    description: str
    allowed_categories: Set[ActionCategory] = field(default_factory=set)
    max_risk_level: RiskLevel = RiskLevel.LOW
    requires_explicit_approval: bool = False  # Even in scoped_auto, require approval
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)


@dataclass
class ActionRequest:
    """Request to perform an action requiring permission."""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    action: str = ""                    # Human-readable action description
    category: ActionCategory = ActionCategory.READ
    risk_level: RiskLevel = RiskLevel.LOW
    tool_name: str = ""                 # Tool being invoked (if any)
    parameters: Dict = field(default_factory=dict)
    session_id: str = ""                # Voice/session context
    user_id: str = ""                   # User context
    metadata: Dict = field(default_factory=dict)
    timestamp: float = field(default_factory=time.time)


@dataclass
class PermissionDecision:
    """Result of a permission check."""
    action_id: str
    approved: bool
    mode: PermissionMode
    reason: str = ""
    auto_approved: bool = False
    decided_at: float = field(default_factory=time.time)
    decided_by: str = "system"  # "system", "human", "kill_switch"
    scope_name: str = ""


# ════════════════════════════════════════════════════════════════════════════
# KILL SWITCH
# ════════════════════════════════════════════════════════════════════════════

class KillSwitch:
    """
    Global emergency stop for all autonomous operations.
    - Can be triggered via API, voice command, or hardware button
    - Blocks ALL autonomous actions immediately
    - Requires explicit human reset to re-enable
    - Logs all trigger events
    """
    
    def __init__(self):
        self._enabled = False
        self._triggered_at: Optional[float] = None
        self._triggered_by: str = ""
        self._trigger_reason: str = ""
        self._lock = threading.Lock()
        self._callbacks: List[Callable[[], None]] = []
        
        # Load persisted state
        self._load_state()
    
    @property
    def is_active(self) -> bool:
        return self._enabled
    
    def trigger(self, reason: str = "Manual kill switch", triggered_by: str = "user"):
        """Activate the kill switch."""
        with self._lock:
            if self._enabled:
                return  # Already active
            self._enabled = True
            self._triggered_at = time.time()
            self._triggered_by = triggered_by
            self._trigger_reason = reason
            self._save_state()
            log.critical(f"KILL SWITCH ACTIVATED: {reason} (by {triggered_by})")
            
            # Notify callbacks
            for cb in self._callbacks:
                try:
                    cb()
                except Exception as e:
                    log.error(f"Kill switch callback error: {e}")
    
    def reset(self, reset_by: str = "user") -> bool:
        """Reset (deactivate) the kill switch. Requires explicit human action."""
        with self._lock:
            if not self._enabled:
                return False
            self._enabled = False
            self._triggered_at = None
            self._triggered_by = ""
            self._trigger_reason = ""
            self._save_state()
            log.critical(f"KILL SWITCH RESET by {reset_by}")
            return True
    
    def register_callback(self, callback: Callable[[], None]):
        """Register a callback to be notified when kill switch activates."""
        self._callbacks.append(callback)
    
    def get_status(self) -> Dict:
        """Get current kill switch status."""
        return {
            "active": self._enabled,
            "triggered_at": self._triggered_at,
            "triggered_by": self._triggered_by,
            "trigger_reason": self._trigger_reason,
        }
    
    def _save_state(self):
        """Persist kill switch state."""
        try:
            with sqlite3.connect(PERM_DB) as conn:
                conn.execute("""
                    CREATE TABLE IF NOT EXISTS kill_switch (
                        id INTEGER PRIMARY KEY CHECK (id = 1),
                        enabled INTEGER NOT NULL,
                        triggered_at REAL,
                        triggered_by TEXT,
                        trigger_reason TEXT,
                        updated_at REAL
                    )
                """)
                conn.execute("""
                    INSERT OR REPLACE INTO kill_switch (id, enabled, triggered_at, triggered_by, trigger_reason, updated_at)
                    VALUES (1, ?, ?, ?, ?, ?)
                """, (int(self._enabled), self._triggered_at or 0, self._triggered_by, self._trigger_reason, time.time()))
        except Exception as e:
            log.error(f"Failed to save kill switch state: {e}")
    
    def _load_state(self):
        """Load persisted kill switch state."""
        try:
            with sqlite3.connect(PERM_DB) as conn:
                row = conn.execute("SELECT * FROM kill_switch WHERE id = 1").fetchone()
                if row and row[1]:  # enabled
                    self._enabled = True
                    self._triggered_at = row[2]
                    self._triggered_by = row[3]
                    self._trigger_reason = row[4]
                    log.warning(f"Kill switch was active on startup (triggered by {self._triggered_by})")
        except Exception:
            pass


# ════════════════════════════════════════════════════════════════════════════
# PERMISSION ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class PermissionEngine:
    """
    Core permission evaluation engine.
    Evaluates action requests against current mode, scopes, and kill switch.
    """
    
    def __init__(self, approval_manager: ApprovalManager, intervention: InterventionHandler):
        self.approval = approval_manager
        self.intervention = intervention
        self.kill_switch = KillSwitch()
        
        # Current mode
        self._mode = PermissionMode(os.environ.get("PERMISSION_MODE", "manual"))
        
        # Scopes registry
        self._scopes: Dict[str, PermissionScope] = {}
        self._init_default_scopes()
        self._load_scopes()
        
        # Auto-approval cache (for performance)
        self._auto_cache: Dict[str, bool] = {}
        self._cache_lock = threading.Lock()
        
        # Decision log
        self._decisions: List[PermissionDecision] = []
        self._decisions_lock = threading.Lock()
        
        # Register kill switch callback
        self.kill_switch.register_callback(self._on_kill_switch)
        
        log.info(f"PermissionEngine initialized in {self._mode.value} mode")
    
    @property
    def mode(self) -> PermissionMode:
        return self._mode
    
    @mode.setter
    def mode(self, value: PermissionMode):
        old = self._mode
        self._mode = value
        # Clear cache on mode change
        with self._cache_lock:
            self._auto_cache.clear()
        log.info(f"Permission mode changed: {old.value} -> {value.value}")
    
    def _init_default_scopes(self):
        """Initialize built-in scopes."""
        # Safe scope - read-only operations
        self._scopes["read_only"] = PermissionScope(
            name="read_only",
            description="Read-only operations: search, read files, calculations",
            allowed_categories={ActionCategory.READ, ActionCategory.SEARCH, 
                               ActionCategory.CALCULATE, ActionCategory.FILE_READ},
            max_risk_level=RiskLevel.LOW,
        )
        
        # Developer scope - file operations + code
        self._scopes["developer"] = PermissionScope(
            name="developer",
            description="Development operations: file read/write, code execution, shell",
            allowed_categories={ActionCategory.READ, ActionCategory.SEARCH, 
                               ActionCategory.CALCULATE, ActionCategory.FILE_READ,
                               ActionCategory.FILE_WRITE, ActionCategory.SHELL},
            max_risk_level=RiskLevel.MEDIUM,
        )
        
        # Admin scope - everything (still requires approval for critical)
        self._scopes["admin"] = PermissionScope(
            name="admin",
            description="Full access (critical actions still require approval)",
            allowed_categories=set(ActionCategory),
            max_risk_level=RiskLevel.CRITICAL,
            requires_explicit_approval=True,
        )
    
    def _load_scopes(self):
        """Load custom scopes from DB."""
        try:
            with sqlite3.connect(PERM_DB) as conn:
                conn.execute("""
                    CREATE TABLE IF NOT EXISTS permission_scopes (
                        name TEXT PRIMARY KEY,
                        description TEXT,
                        categories TEXT NOT NULL,  -- JSON array
                        max_risk_level TEXT,
                        requires_explicit_approval INTEGER DEFAULT 0,
                        created_at REAL,
                        updated_at REAL
                    )
                """)
                rows = conn.execute("SELECT * FROM permission_scopes").fetchall()
                for row in rows:
                    scope = PermissionScope(
                        name=row[0],
                        description=row[1],
                        allowed_categories=set(json.loads(row[2])),
                        max_risk_level=RiskLevel(row[3]),
                        requires_explicit_approval=bool(row[4]),
                        created_at=row[5],
                        updated_at=row[6],
                    )
                    self._scopes[scope.name] = scope
        except Exception as e:
            log.warning(f"Failed to load scopes: {e}")
    
    def _save_scope(self, scope: PermissionScope):
        """Persist a scope."""
        try:
            with sqlite3.connect(PERM_DB) as conn:
                conn.execute("""
                    INSERT OR REPLACE INTO permission_scopes 
                    (name, description, categories, max_risk_level, requires_explicit_approval, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (scope.name, scope.description, json.dumps([c.value for c in scope.allowed_categories]),
                      scope.max_risk_level.value, int(scope.requires_explicit_approval),
                      scope.created_at, scope.updated_at))
        except Exception as e:
            log.error(f"Failed to save scope: {e}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # CORE PERMISSION EVALUATION
    # ════════════════════════════════════════════════════════════════════════════
    
    def check_permission(self, request: ActionRequest, 
                         active_scopes: List[str] = None) -> PermissionDecision:
        """
        Evaluate if an action is permitted.
        
        Flow:
        1. Check kill switch (blocks everything if active)
        2. Check intervention handler (global pause)
        3. Check mode:
           - MANUAL: Always require approval
           - SCOPED_AUTO: Check if action fits in active scopes
           - AUTO: Allow everything (with critical still needing approval)
        4. If approval needed, delegate to ApprovalManager
        """
        # 1. Kill switch - absolute override
        if self.kill_switch.is_active:
            return PermissionDecision(
                action_id=request.id,
                approved=False,
                mode=self._mode,
                reason=f"KILL SWITCH ACTIVE: {self.kill_switch.get_status()['trigger_reason']}",
                decided_by="kill_switch",
            )
        
        # 2. Intervention handler - global pause
        if self.intervention.check_interrupt():
            return PermissionDecision(
                action_id=request.id,
                approved=False,
                mode=self._mode,
                reason="Intervention mode active - operation paused",
                decided_by="intervention",
            )
        
        # 3. Mode-based evaluation
        if self._mode == PermissionMode.MANUAL:
            return self._require_approval(request, "Manual mode: all actions require approval")
        
        elif self._mode == PermissionMode.AUTO:
            # Even in auto, critical actions need approval
            if request.risk_level in (RiskLevel.HIGH, RiskLevel.CRITICAL):
                return self._require_approval(request, "Critical action requires approval even in auto mode")
            return PermissionDecision(
                action_id=request.id, approved=True, mode=self._mode,
                reason="Auto mode: action permitted", auto_approved=True
            )
        
        elif self._mode == PermissionMode.SCOPED_AUTO:
            return self._evaluate_scoped(request, active_scopes or ["read_only"])
        
        return PermissionDecision(
            action_id=request.id, approved=False, mode=self._mode,
            reason=f"Unknown mode: {self._mode}"
        )
    
    def _evaluate_scoped(self, request: ActionRequest, 
                         active_scopes: List[str]) -> PermissionDecision:
        """Evaluate action against active scopes."""
        # Check each active scope
        for scope_name in active_scopes:
            scope = self._scopes.get(scope_name)
            if not scope:
                continue
            
            # Check if category is allowed in this scope
            if request.category in scope.allowed_categories:
                # Check risk level
                risk_order = [RiskLevel.LOW, RiskLevel.MEDIUM, RiskLevel.HIGH, RiskLevel.CRITICAL]
                if risk_order.index(request.risk_level) <= risk_order.index(scope.max_risk_level):
                    # Within scope limits
                    if scope.requires_explicit_approval:
                        return self._require_approval(request, f"Scope '{scope_name}' requires explicit approval")
                    
                    # Auto-approved within scope
                    return PermissionDecision(
                        action_id=request.id, approved=True, mode=self._mode,
                        reason=f"Auto-approved in scope '{scope_name}'",
                        auto_approved=True, scope_name=scope_name
                    )
        
        # Not covered by any active scope
        return self._require_approval(request, f"Action not covered by active scopes: {active_scopes}")
    
    def _require_approval(self, request: ActionRequest, reason: str) -> PermissionDecision:
        """Delegate to ApprovalManager for human approval."""
        approved = self.approval.request_approval(
            action=request.action,
            reason=reason,
            risk_level=request.risk_level.value,
            task_id=request.id,
        )
        
        return PermissionDecision(
            action_id=request.id,
            approved=approved,
            mode=self._mode,
            reason=reason if approved else f"Denied: {reason}",
            decided_by="human",
        )
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SCOPE MANAGEMENT
    # ════════════════════════════════════════════════════════════════════════════
    
    def create_scope(self, name: str, description: str, 
                     categories: List[ActionCategory],
                     max_risk: RiskLevel = RiskLevel.LOW,
                     requires_explicit: bool = False) -> PermissionScope:
        """Create a custom permission scope."""
        scope = PermissionScope(
            name=name,
            description=description,
            allowed_categories=set(categories),
            max_risk_level=max_risk,
            requires_explicit_approval=requires_explicit,
        )
        self._scopes[name] = scope
        self._save_scope(scope)
        log.info(f"Created permission scope: {name}")
        return scope
    
    def delete_scope(self, name: str) -> bool:
        """Delete a custom scope (not built-in)."""
        if name in ("read_only", "developer", "admin"):
            raise ValueError("Cannot delete built-in scope")
        if name in self._scopes:
            del self._scopes[name]
            with sqlite3.connect(PERM_DB) as conn:
                conn.execute("DELETE FROM permission_scopes WHERE name = ?", (name,))
            return True
        return False
    
    def get_scope(self, name: str) -> Optional[PermissionScope]:
        return self._scopes.get(name)
    
    def list_scopes(self) -> List[Dict]:
        return [{
            "name": s.name, "description": s.description,
            "categories": [c.value for c in s.allowed_categories],
            "max_risk_level": s.max_risk_level.value,
            "requires_explicit_approval": s.requires_explicit_approval,
        } for s in self._scopes.values()]
    
    # ═══════════════════════════════════════════════════════════════════════════
    # DECISION LOG
    # ═══════════════════════════════════════════════════════════════════════════
    
    def _log_decision(self, decision: PermissionDecision):
        with self._decisions_lock:
            self._decisions.append(decision)
            # Keep last 10000
            if len(self._decisions) > 10000:
                self._decisions = self._decisions[-10000:]
    
    def get_recent_decisions(self, limit: int = 100) -> List[Dict]:
        with self._decisions_lock:
            return [{
                "action_id": d.action_id, "approved": d.approved,
                "mode": d.mode.value, "reason": d.reason,
                "auto_approved": d.auto_approved, "decided_by": d.decided_by,
                "scope_name": d.scope_name, "decided_at": d.decided_at,
            } for d in self._decisions[-limit:]]
    
    # ═══════════════════════════════════════════════════════════════════════════
    # KILL SWITCH HANDLING
    # ════════════════════════════════════════════════════════════════════════════
    
    def _on_kill_switch(self):
        """Called when kill switch activates - clear caches, stop operations."""
        with self._cache_lock:
            self._auto_cache.clear()
        log.critical("PermissionEngine: Kill switch activated - all auto-approvals revoked")
    
    # ════════════════════════════════════════════════════════════════════════════
    # CONVENIENCE METHODS
    # ════════════════════════════════════════════════════════════════════════════
    
    def check_tool_permission(self, tool_name: str, parameters: Dict, 
                              session_id: str = "", user_id: str = "",
                              active_scopes: List[str] = None) -> PermissionDecision:
        """Quick permission check for tool invocation."""
        # Map tool to category/risk
        category_map = {
            "web_search": ActionCategory.SEARCH, "web_scrape": ActionCategory.SEARCH,
            "read_file": ActionCategory.FILE_READ, "write_file": ActionCategory.FILE_WRITE,
            "run_shell": ActionCategory.SHELL, "run_code": ActionCategory.CALCULATE,
            "web_deploy": ActionCategory.DEPLOY, "web_build": ActionCategory.FILE_WRITE,
            "calendar_create_event": ActionCategory.EXTERNAL_API,
            "file_find": ActionCategory.FILE_READ, "file_grep": ActionCategory.FILE_READ,
            "system_status": ActionCategory.READ, "process_list": ActionCategory.READ,
        }
        
        risk_map = {
            ActionCategory.READ: RiskLevel.LOW,
            ActionCategory.SEARCH: RiskLevel.LOW,
            ActionCategory.CALCULATE: RiskLevel.LOW,
            ActionCategory.FILE_READ: RiskLevel.LOW,
            ActionCategory.FILE_WRITE: RiskLevel.MEDIUM,
            ActionCategory.SHELL: RiskLevel.HIGH,
            ActionCategory.DEPLOY: RiskLevel.HIGH,
            ActionCategory.EXTERNAL_API: RiskLevel.MEDIUM,
            ActionCategory.FINANCIAL: RiskLevel.CRITICAL,
            ActionCategory.ACCOUNT: RiskLevel.CRITICAL,
            ActionCategory.SYSTEM: RiskLevel.HIGH,
            ActionCategory.VOICE: RiskLevel.LOW,
        }
        
        category = category_map.get(tool_name, ActionCategory.SYSTEM)
        risk = risk_map.get(category, RiskLevel.HIGH)
        
        request = ActionRequest(
            action=f"Invoke tool: {tool_name}",
            category=category,
            risk_level=risk,
            tool_name=tool_name,
            parameters=parameters,
            session_id=session_id,
            user_id=user_id,
        )
        
        return self.check_permission(request, active_scopes)
    
    def check_voice_permission(self, transcript: str, session_id: str, user_id: str,
                               active_scopes: List[str] = None) -> PermissionDecision:
        """Permission check for voice commands."""
        # Heuristic: classify intent from transcript
        transcript_lower = transcript.lower()
        
        if any(w in transcript_lower for w in ["search", "find", "look up", "what is", "who is"]):
            category = ActionCategory.SEARCH
        elif any(w in transcript_lower for w in ["calculate", "compute", "math", "+", "-", "*", "/"]):
            category = ActionCategory.CALCULATE
        elif any(w in transcript_lower for w in ["read", "show", "display", "cat", "view"]):
            category = ActionCategory.FILE_READ
        elif any(w in transcript_lower for w in ["write", "create", "save", "edit", "modify", "delete"]):
            category = ActionCategory.FILE_WRITE
        elif any(w in transcript_lower for w in ["deploy", "publish", "push"]):
            category = ActionCategory.DEPLOY
        elif any(w in transcript_lower for w in ["pay", "charge", "bill", "money"]):
            category = ActionCategory.FINANCIAL
        else:
            category = ActionCategory.READ  # Default safe
        
        risk_map = {
            ActionCategory.SEARCH: RiskLevel.LOW,
            ActionCategory.CALCULATE: RiskLevel.LOW,
            ActionCategory.FILE_READ: RiskLevel.LOW,
            ActionCategory.FILE_WRITE: RiskLevel.MEDIUM,
            ActionCategory.DEPLOY: RiskLevel.HIGH,
            ActionCategory.FINANCIAL: RiskLevel.CRITICAL,
        }
        
        request = ActionRequest(
            action=f"Voice command: {transcript[:100]}",
            category=category,
            risk_level=risk_map.get(category, RiskLevel.MEDIUM),
            session_id=session_id,
            user_id=user_id,
            metadata={"transcript": transcript},
        )
        
        return self.check_permission(request, active_scopes)


# ════════════════════════════════════════════════════════════════════════════
# MODULE SINGLETON
# ════════════════════════════════════════════════════════════════════════════

_permission_engine: Optional[PermissionEngine] = None


def get_permission_engine(approval_manager: ApprovalManager = None,
                          intervention: InterventionHandler = None) -> PermissionEngine:
    """Get or create the global PermissionEngine instance."""
    global _permission_engine
    if _permission_engine is None:
        if approval_manager is None or intervention is None:
            # Try to get from Maya instance
            try:
                from api import maya_instance
                if maya_instance:
                    approval_manager = maya_instance.approval
                    intervention = maya_instance.intervention
            except Exception:
                pass
        
        if approval_manager is None:
            approval_manager = ApprovalManager(mode=APPROVAL_HUMAN)
        if intervention is None:
            intervention = InterventionHandler()
        
        _permission_engine = PermissionEngine(approval_manager, intervention)
    return _permission_engine


def reset_permission_engine():
    global _permission_engine
    _permission_engine = None


# Import sqlite3 for scope persistence
import sqlite3