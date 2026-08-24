"""
Maya 2.0 — Metacognitive Monitor (Phase 18)
============================================
Online monitoring of confidence, surprise, uncertainty.
Triggers recovery, replanning, and escalation.
"""

import json
import sqlite3
import threading
import time
import uuid
from collections import deque
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple

from config.settings import STORAGE_DIR


META_DIR = STORAGE_DIR / "metacognitive"
META_DIR.mkdir(parents=True, exist_ok=True)
META_DB = str(META_DIR / "metacognitive.db")


class MetacognitiveEventType(Enum):
    CONFIDENCE_DROP = "confidence_drop"
    SURPRISE = "surprise"
    STALL = "stall"
    RESOURCE_EXHAUSTION = "resource_exhaustion"
    GOAL_CONFLICT = "goal_conflict"
    SKILL_FAILURE = "skill_failure"
    UNCERTAINTY_SPIKE = "uncertainty_spike"
    RECOVERY_TRIGGERED = "recovery_triggered"
    REPLAN_TRIGGERED = "replan_triggered"
    ESCALATION = "escalation"


class RecoveryAction(Enum):
    RETRY = "retry"
    FALLBACK_SKILL = "fallback_skill"
    REPLAN = "replan"
    DECOMPOSE = "decompose"
    ESCALATE_HUMAN = "escalate_human"
    ABORT = "abort"
    GATHER_INFO = "gather_info"


@dataclass
class MetacognitiveEvent:
    """A metacognitive event."""
    id: str
    event_type: MetacognitiveEventType
    timestamp: float
    context: Dict  # Plan, step, goal, state
    confidence: float
    surprise: float
    uncertainty: float
    trigger_details: Dict
    action_taken: Optional[RecoveryAction] = None
    action_result: Optional[Dict] = None
    resolved: bool = False


@dataclass
class ConfidenceAssessment:
    """Assessment of confidence in current trajectory."""
    overall: float  # 0.0 to 1.0
    plan_confidence: float
    step_confidence: float
    skill_confidence: float
    resource_confidence: float
    factors: Dict[str, float]  # factor -> impact
    trend: str  # improving, stable, declining
    recommendation: str


@dataclass
class SurpriseEvent:
    """A surprise detection."""
    magnitude: float  # 0.0 to 1.0
    source: str  # step_result, environment, expectation_violation
    expected: Any
    actual: Any
    context: Dict
    timestamp: float


class ConfidenceMonitor:
    """Monitors confidence across multiple dimensions."""
    
    def __init__(self, kernel=None):
        self.kernel = kernel
        self.confidence_history: deque = deque(maxlen=100)
        self.step_confidences: Dict[str, deque] = {}  # step_id -> confidences
        self.plan_confidences: Dict[str, deque] = {}  # plan_id -> confidences
        
        # Thresholds
        self.low_confidence_threshold = 0.4
        self.confidence_drop_threshold = 0.2  # Drop per step
        self.min_samples_for_trend = 5
    
    def assess(self, context: Dict) -> ConfidenceAssessment:
        """Assess current confidence."""
        plan_id = context.get("plan_id")
        step_id = context.get("step_id")
        goal_id = context.get("goal_id")
        
        # Get relevant confidences
        plan_conf = self._get_plan_confidence(plan_id) if plan_id else 0.5
        step_conf = self._get_step_confidence(step_id) if step_id else 0.5
        skill_conf = self._get_skill_confidence(context) if context else 0.5
        resource_conf = self._get_resource_confidence(context)
        
        # Overall confidence (weighted)
        overall = (
            0.3 * plan_conf +
            0.3 * step_conf +
            0.2 * skill_conf +
            0.2 * resource_conf
        )
        
        # Track history
        self.confidence_history.append((time.time(), overall))
        if plan_id:
            self.plan_confidences.setdefault(plan_id, deque(maxlen=50)).append(overall)
        if step_id:
            self.step_confidences.setdefault(step_id, deque(maxlen=20)).append(overall)
        
        # Determine trend
        trend = self._compute_trend()
        
        # Identify factors
        factors = {
            "plan": plan_conf,
            "step": step_conf,
            "skill": skill_conf,
            "resource": resource_conf,
        }
        
        # Generate recommendation
        recommendation = self._generate_recommendation(overall, factors, trend)
        
        return ConfidenceAssessment(
            overall=overall,
            plan_confidence=plan_conf,
            step_confidence=step_conf,
            skill_confidence=skill_conf,
            resource_confidence=resource_conf,
            factors=factors,
            trend=trend,
            recommendation=recommendation,
        )
    
    def _get_plan_confidence(self, plan_id: str) -> float:
        if not plan_id or plan_id not in self.plan_confidences:
            return 0.5
        confs = self.plan_confidences[plan_id]
        if len(confs) < 2:
            return 0.5
        return sum(confs) / len(confs)
    
    def _get_step_confidence(self, step_id: str) -> float:
        if not step_id or step_id not in self.step_confidences:
            return 0.5
        confs = self.step_confidences[step_id]
        return sum(confs) / len(confs) if confs else 0.5
    
    def _get_skill_confidence(self, context: Dict) -> float:
        """Get confidence based on skill reliability."""
        skill_id = context.get("skill_id") or context.get("required_capability")
        if not skill_id or not self.kernel:
            return 0.5
        
        reg = getattr(self.kernel, 'capability_registry', None)
        if not reg:
            return 0.5
        
        cap = reg.get(skill_id)
        if not cap:
            return 0.5
        
        return cap.metadata.reliability_score
    
    def _get_resource_confidence(self, context: Dict) -> float:
        """Get confidence based on resource availability."""
        # Check budget, time, API limits
        budget_used = context.get("budget_used_pct", 0)
        time_elapsed = context.get("time_elapsed_pct", 0)
        
        budget_conf = 1.0 - budget_used
        time_conf = 1.0 - time_elapsed
        
        return max(0.0, min(1.0, (budget_conf + time_conf) / 2))
    
    def _compute_trend(self) -> str:
        if len(self.confidence_history) < self.min_samples_for_trend:
            return "unknown"
        
        recent = [c for _, c in list(self.confidence_history)[-self.min_samples_for_trend:]]
        older = [c for _, c in list(self.confidence_history)[-self.min_samples_for_trend*2:-self.min_samples_for_trend]]
        
        if not older:
            return "unknown"
        
        recent_avg = sum(recent) / len(recent)
        older_avg = sum(older) / len(older)
        diff = recent_avg - older_avg
        
        if diff > 0.05:
            return "improving"
        elif diff < -0.05:
            return "declining"
        return "stable"
    
    def _generate_recommendation(self, overall: float, factors: Dict, trend: str) -> str:
        if overall < self.low_confidence_threshold:
            worst = min(factors, key=factors.get)
            if worst == "skill":
                return "Consider fallback skill or skill synthesis"
            elif worst == "resource":
                return "Reduce scope or request more resources"
            elif worst == "plan":
                return "Replan with different approach"
            return "Investigate low confidence factors"
        
        if trend == "declining":
            return "Monitor closely, consider early replan"
        
        return "Continue current trajectory"
    
    def record_step_confidence(self, step_id: str, confidence: float) -> None:
        """Record confidence for a specific step."""
        self.step_confidences.setdefault(step_id, deque(maxlen=20)).append(confidence)
    
    def check_confidence_drop(self, context: Dict) -> bool:
        """Check if confidence dropped significantly."""
        step_id = context.get("step_id")
        if not step_id or step_id not in self.step_confidences:
            return False
        
        confs = self.step_confidences[step_id]
        if len(confs) < 2:
            return False
        
        return confs[-2] - confs[-1] > self.confidence_drop_threshold


class SurpriseDetector:
    """Detects surprises (expectation violations)."""
    
    def __init__(self, kernel=None, world_models=None):
        self.kernel = kernel
        self.world_models = world_models or {}
        self.surprise_history: deque = deque(maxlen=100)
        self.surprise_threshold = 0.5
    
    def detect(self, expected: Any, actual: Any, context: Dict) -> Optional[SurpriseEvent]:
        """Detect surprise between expected and actual outcome."""
        surprise = self._compute_surprise(expected, actual)
        
        if surprise >= self.surprise_threshold:
            event = SurpriseEvent(
                magnitude=surprise,
                source=context.get("source", "unknown"),
                expected=expected,
                actual=actual,
                context=context,
                timestamp=time.time(),
            )
            self.surprise_history.append(event)
            return event
        return None
    
    def _compute_surprise(self, expected: Any, actual: Any) -> float:
        """Compute surprise magnitude."""
        if expected is None or actual is None:
            return 0.0
        
        # Convert to comparable format
        exp_str = json.dumps(expected, sort_keys=True, default=str)
        act_str = json.dumps(actual, sort_keys=True, default=str)
        
        # Token overlap similarity
        exp_tokens = set(exp_str.lower().split())
        act_tokens = set(act_str.lower().split())
        
        if not exp_tokens or not act_tokens:
            return 0.0
        
        overlap = len(exp_tokens & act_tokens) / len(exp_tokens | act_tokens)
        return 1.0 - overlap
    
    def get_recent_surprises(self, limit: int = 10) -> List[SurpriseEvent]:
        return list(self.surprise_history)[-limit:]


class UncertaintyTracker:
    """Tracks uncertainty in beliefs and predictions."""
    
    def __init__(self, kernel=None):
        self.kernel = kernel
        self.uncertainty_log: deque = deque(maxlen=200)
        self.domain_uncertainty: Dict[str, float] = {}  # domain -> uncertainty
    
    def update_belief_uncertainty(self, belief_id: str, confidence: float, domain: str) -> None:
        """Update uncertainty for a belief."""
        uncertainty = 1.0 - confidence
        self.domain_uncertainty[domain] = max(
            self.domain_uncertainty.get(domain, 0.5),
            uncertainty
        )
        
        self.uncertainty_log.append({
            "timestamp": time.time(),
            "belief_id": belief_id,
            "confidence": confidence,
            "uncertainty": uncertainty,
            "domain": domain,
        })
    
    def get_domain_uncertainty(self, domain: str) -> float:
        return self.domain_uncertainty.get(domain, 0.5)
    
    def get_overall_uncertainty(self) -> float:
        if not self.domain_uncertainty:
            return 0.5
        return sum(self.domain_uncertainty.values()) / len(self.domain_uncertainty)
    
    def check_uncertainty_spike(self, domain: str, threshold: float = 0.3) -> bool:
        """Check if uncertainty spiked for a domain."""
        current = self.get_domain_uncertainty(domain)
        # Compare to recent average
        recent = [e["uncertainty"] for e in self.uncertainty_log 
                 if e["domain"] == domain][-10:]
        if not recent:
            return False
        avg = sum(recent) / len(recent)
        return current - avg > threshold


class MetacognitiveMonitor:
    """
    Main metacognitive monitor integrating confidence, surprise, and uncertainty.
    Triggers recovery actions when thresholds are exceeded.
    """
    
    def __init__(
        self,
        kernel=None,
        world_models=None,
        hierarchical_planner=None,
        capability_registry=None,
        approval_manager=None,
        intervention_handler=None,
    ):
        self.kernel = kernel
        self.world_models = world_models or {}
        self.planner = hierarchical_planner
        self.capability_registry = capability_registry
        self.approval = approval_manager
        self.intervention = intervention_handler
        
        self.confidence_monitor = ConfidenceMonitor(kernel)
        self.surprise_detector = SurpriseDetector(kernel, world_models)
        self.uncertainty_tracker = UncertaintyTracker(kernel)
        
        self._init_db()
        self._event_log: deque = deque(maxlen=500)
        self._recovery_handlers: Dict[RecoveryAction, Callable] = {}
        self._register_default_handlers()
        
        # Thresholds
        self.thresholds = {
            "low_confidence": 0.4,
            "surprise": 0.5,
            "uncertainty_spike": 0.3,
            "stall_time": 300,  # 5 minutes
            "max_retries": 3,
        }
        
        # Recovery state
        self.retry_counts: Dict[str, int] = {}
        self.active_recoveries: Dict[str, Dict] = {}
    
    def _init_db(self) -> None:
        with self._conn() as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS metacognitive_events (
                    id TEXT PRIMARY KEY,
                    event_type TEXT NOT NULL,
                    timestamp REAL,
                    context TEXT DEFAULT '{}',
                    confidence REAL,
                    surprise REAL,
                    uncertainty REAL,
                    trigger_details TEXT DEFAULT '{}',
                    action_taken TEXT,
                    action_result TEXT DEFAULT '{}',
                    resolved INTEGER DEFAULT 0
                )
            """)
            c.execute("CREATE INDEX IF NOT EXISTS idx_meta_time ON metacognitive_events(timestamp)")
            c.execute("CREATE INDEX IF NOT EXISTS idx_meta_type ON metacognitive_events(event_type)")
    
    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(META_DB, check_same_thread=False, timeout=30)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
    
    def _register_default_handlers(self) -> None:
        """Register default recovery action handlers."""
        self._recovery_handlers[RecoveryAction.RETRY] = self._handle_retry
        self._recovery_handlers[RecoveryAction.FALLBACK_SKILL] = self._handle_fallback_skill
        self._recovery_handlers[RecoveryAction.REPLAN] = self._handle_replan
        self._recovery_handlers[RecoveryAction.DECOMPOSE] = self._handle_decompose
        self._recovery_handlers[RecoveryAction.GATHER_INFO] = self._handle_gather_info
        self._recovery_handlers[RecoveryAction.ESCALATE_HUMAN] = self._handle_escalate_human
        self._recovery_handlers[RecoveryAction.ABORT] = self._handle_abort
    
    def monitor(self, context: Dict) -> List[MetacognitiveEvent]:
        """Run all monitors and return triggered events."""
        events = []
        
        # 1. Confidence monitoring
        confidence_assessment = self.confidence_monitor.assess(context)
        if confidence_assessment.overall < self.thresholds["low_confidence"]:
            events.append(self._create_event(
                MetacognitiveEventType.CONFIDENCE_DROP,
                context,
                confidence_assessment.overall,
                0.0,
                self.uncertainty_tracker.get_overall_uncertainty(),
                {"assessment": confidence_assessment.__dict__}
            ))
        
        if self.confidence_monitor.check_confidence_drop(context):
            events.append(self._create_event(
                MetacognitiveEventType.CONFIDENCE_DROP,
                context,
                confidence_assessment.overall,
                0.0,
                self.uncertainty_tracker.get_overall_uncertainty(),
                {"drop_detected": True}
            ))
        
        # 2. Surprise detection (called externally with actual results)
        
        # 3. Uncertainty tracking
        domain = context.get("domain", "general")
        if self.uncertainty_tracker.check_uncertainty_spike(domain, self.thresholds["uncertainty_spike"]):
            events.append(self._create_event(
                MetacognitiveEventType.UNCERTAINTY_SPIKE,
                context,
                confidence_assessment.overall,
                0.0,
                self.uncertainty_tracker.get_domain_uncertainty(domain),
                {"domain": domain}
            ))
        
        # 4. Stall detection
        if self._check_stall(context):
            events.append(self._create_event(
                MetacognitiveEventType.STALL,
                context,
                confidence_assessment.overall,
                0.0,
                self.uncertainty_tracker.get_overall_uncertainty(),
                {"stall_duration": context.get("stall_duration", 0)}
            ))
        
        # 5. Resource exhaustion
        if self._check_resource_exhaustion(context):
            events.append(self._create_event(
                MetacognitiveEventType.RESOURCE_EXHAUSTION,
                context,
                confidence_assessment.overall,
                0.0,
                self.uncertainty_tracker.get_overall_uncertainty(),
                {"resources": context.get("resources", {})}
            ))
        
        # Process events and trigger recoveries
        for event in events:
            self._process_event(event)
        
        return events
    
    def record_step_result(self, context: Dict, expected: Any, actual: Any, 
                           verified: bool) -> Optional[MetacognitiveEvent]:
        """Record a step result and check for surprises."""
        step_id = context.get("step_id", "unknown")
        
        # Update confidence
        step_conf = 1.0 if verified else 0.0
        self.confidence_monitor.record_step_confidence(step_id, step_conf)
        
        # Check for surprise
        surprise_event = self.surprise_detector.detect(expected, actual, context)
        if surprise_event:
            meta_event = self._create_event(
                MetacognitiveEventType.SURPRISE,
                context,
                step_conf,
                surprise_event.magnitude,
                self.uncertainty_tracker.get_overall_uncertainty(),
                {"surprise": surprise_event.__dict__}
            )
            self._process_event(meta_event)
            return meta_event
        
        return None
    
    def _check_stall(self, context: Dict) -> bool:
        """Check if execution has stalled."""
        plan_id = context.get("plan_id")
        if not plan_id or not self.planner:
            return False
        
        plan_status = self.planner.get_plan_status(plan_id)
        if not plan_status:
            return False
        
        last_checkpoint = context.get("last_checkpoint_time", 0)
        if last_checkpoint and time.time() - last_checkpoint > self.thresholds["stall_time"]:
            return True
        
        return False
    
    def _check_resource_exhaustion(self, context: Dict) -> bool:
        """Check if resources are exhausted."""
        budget_pct = context.get("budget_used_pct", 0)
        if budget_pct > 0.9:
            return True
        
        api_calls = context.get("api_calls_used", 0)
        api_limit = context.get("api_limit", 100)
        if api_calls >= api_limit * 0.9:
            return True
        
        return False
    
    def _create_event(self, event_type: MetacognitiveEventType, context: Dict,
                      confidence: float, surprise: float, uncertainty: float,
                      trigger_details: Dict) -> MetacognitiveEvent:
        event = MetacognitiveEvent(
            id=uuid.uuid4().hex[:12],
            event_type=event_type,
            timestamp=time.time(),
            context=context,
            confidence=confidence,
            surprise=surprise,
            uncertainty=uncertainty,
            trigger_details=trigger_details,
        )
        self._event_log.append(event)
        self._save_event(event)
        return event
    
    def _save_event(self, event: MetacognitiveEvent) -> None:
        with self._conn() as c:
            c.execute("""
                INSERT INTO metacognitive_events
                (id, event_type, timestamp, context, confidence, surprise, uncertainty,
                 trigger_details, action_taken, action_result, resolved)
                VALUES (?,?,?,?,?,?,?,?,?,?,?)
            """, (
                event.id, event.event_type.value, event.timestamp,
                json.dumps(event.context), event.confidence, event.surprise,
                event.uncertainty, json.dumps(event.trigger_details),
                event.action_taken.value if event.action_taken else None,
                json.dumps(event.action_result) if event.action_result else "{}",
                int(event.resolved)
            ))
    
    def _process_event(self, event: MetacognitiveEvent) -> None:
        """Process event and trigger appropriate recovery."""
        # Determine recovery action based on event type and context
        action = self._select_recovery_action(event)
        
        if action:
            event.action_taken = action
            handler = self._recovery_handlers.get(action)
            if handler:
                try:
                    result = handler(event)
                    event.action_result = result
                    event.resolved = result.get("success", False)
                    self._save_event(event)
                    
                    # Log recovery
                    self._log_recovery(event)
                except Exception as e:
                    event.action_result = {"error": str(e), "success": False}
                    self._save_event(event)
    
    def _select_recovery_action(self, event: MetacognitiveEvent) -> Optional[RecoveryAction]:
        """Select appropriate recovery action based on event."""
        context = event.context
        step_id = context.get("step_id")
        retry_count = self.retry_counts.get(step_id, 0)
        
        if event.event_type == MetacognitiveEventType.CONFIDENCE_DROP:
            if retry_count < self.thresholds["max_retries"]:
                return RecoveryAction.RETRY
            elif self.capability_registry:
                return RecoveryAction.FALLBACK_SKILL
            else:
                return RecoveryAction.REPLAN
        
        elif event.event_type == MetacognitiveEventType.SURPRISE:
            if surprise_event := event.trigger_details.get("surprise"):
                if surprise_event.get("magnitude", 0) > 0.7:
                    return RecoveryAction.REPLAN
            return RecoveryAction.GATHER_INFO
        
        elif event.event_type == MetacognitiveEventType.STALL:
            return RecoveryAction.REPLAN
        
        elif event.event_type == MetacognitiveEventType.RESOURCE_EXHAUSTION:
            return RecoveryAction.DECOMPOSE
        
        elif event.event_type == MetacognitiveEventType.UNCERTAINTY_SPIKE:
            return RecoveryAction.GATHER_INFO
        
        elif event.event_type == MetacognitiveEventType.SKILL_FAILURE:
            if retry_count < self.thresholds["max_retries"]:
                return RecoveryAction.RETRY
            return RecoveryAction.FALLBACK_SKILL
        
        return None
    
    # Recovery handlers
    
    def _handle_retry(self, event: MetacognitiveEvent) -> Dict:
        step_id = event.context.get("step_id")
        self.retry_counts[step_id] = self.retry_counts.get(step_id, 0) + 1
        
        return {
            "action": "retry",
            "step_id": step_id,
            "attempt": self.retry_counts[step_id],
            "success": True,  # Caller should actually retry
            "message": f"Retrying step {step_id} (attempt {self.retry_counts[step_id]})"
        }
    
    def _handle_fallback_skill(self, event: MetacognitiveEvent) -> Dict:
        step_id = event.context.get("step_id")
        required_cap = event.context.get("required_capability")
        
        if not required_cap or not self.capability_registry:
            return {"success": False, "error": "No capability registry or required capability"}
        
        # Find alternative skills
        alternatives = self.capability_registry.find_composable(required_cap, limit=3)
        verified_alts = [a for a in alternatives if a.metadata.verification_status.value == "verified"]
        
        if not verified_alts:
            return {"success": False, "error": "No verified fallback skills found"}
        
        # Select best alternative
        best = max(verified_alts, key=lambda s: s.metadata.reliability_score)
        
        return {
            "action": "fallback_skill",
            "original_skill": required_cap,
            "fallback_skill": best.id,
            "fallback_name": best.name,
            "reliability": best.metadata.reliability_score,
            "success": True,
            "message": f"Switching to fallback skill: {best.name}"
        }
    
    def _handle_replan(self, event: MetacognitiveEvent) -> Dict:
        plan_id = event.context.get("plan_id")
        if not plan_id or not self.planner:
            return {"success": False, "error": "No plan or planner"}
        
        try:
            # Trigger replan from current step
            current_step = event.context.get("current_step_index", 0)
            new_plan = self.planner.replan(plan_id, from_step=current_step, 
                                          reason=f"Metacognitive trigger: {event.event_type.value}")
            
            return {
                "action": "replan",
                "plan_id": plan_id,
                "new_plan_id": new_plan.id,
                "from_step": current_step,
                "success": True,
                "message": f"Replanned from step {current_step}"
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _handle_decompose(self, event: MetacognitiveEvent) -> Dict:
        goal_id = event.context.get("goal_id")
        if not goal_id or not self.kernel:
            return {"success": False, "error": "No goal or kernel"}
        
        try:
            # Decompose goal into subgoals
            subgoals = self.kernel.decompose_goal(goal_id, num_subgoals=3)
            
            return {
                "action": "decompose",
                "goal_id": goal_id,
                "subgoals_created": len(subgoals),
                "subgoal_ids": [g.id for g in subgoals],
                "success": True,
                "message": f"Decomposed goal into {len(subgoals)} subgoals"
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _handle_gather_info(self, event: MetacognitiveEvent) -> Dict:
        """Gather more information to reduce uncertainty."""
        domain = event.context.get("domain", "general")
        
        # Trigger research or observation
        return {
            "action": "gather_info",
            "domain": domain,
            "suggested_actions": [
                f"Observe {domain} environment",
                f"Search for {domain} documentation",
                f"Run diagnostic on {domain}"
            ],
            "success": True,
            "message": f"Initiating information gathering for {domain}"
        }
    
    def _handle_escalate_human(self, event: MetacognitiveEvent) -> Dict:
        """Escalate to human for decision."""
        if not self.approval:
            return {"success": False, "error": "No approval manager"}
        
        action_desc = f"Metacognitive escalation: {event.event_type.value}"
        reason = f"Automatic recovery failed for {event.context.get('plan_id', 'unknown')}"
        
        try:
            approved = self.approval.request_approval(
                action=action_desc,
                reason=reason,
                risk_level="high",
                task_id=event.context.get("plan_id"),
            )
            
            return {
                "action": "escalate_human",
                "approved": approved,
                "success": approved,
                "message": "Human approval requested" if approved else "Human denied escalation"
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _handle_abort(self, event: MetacognitiveEvent) -> Dict:
        """Abort current plan."""
        plan_id = event.context.get("plan_id")
        if plan_id and self.planner:
            plan = self.planner.active_plans.get(plan_id)
            if plan:
                plan.status = PlanStatus.FAILED
        
        return {
            "action": "abort",
            "plan_id": plan_id,
            "success": True,
            "message": f"Plan {plan_id} aborted due to metacognitive trigger"
        }
    
    def _log_recovery(self, event: MetacognitiveEvent) -> None:
        """Log recovery action."""
        if self.kernel:
            self.kernel._audit("recovery", 
                f"{event.action_taken.value} for {event.event_type.value}: {event.action_result}")
    
    def get_status(self) -> Dict:
        return {
            "confidence_history": list(self.confidence_monitor.confidence_history)[-20:],
            "recent_surprises": len(self.surprise_detector.surprise_history),
            "domain_uncertainties": self.uncertainty_tracker.domain_uncertainty,
            "active_recoveries": len(self.active_recoveries),
            "retry_counts": self.retry_counts,
            "recent_events": [
                {"type": e.event_type.value, "timestamp": e.timestamp, 
                 "action": e.action_taken.value if e.action_taken else None,
                 "resolved": e.resolved}
                for e in list(self._event_log)[-20:]
            ],
        }
    
    def get_events(self, event_type: MetacognitiveEventType = None, 
                   limit: int = 50) -> List[MetacognitiveEvent]:
        events = list(self._event_log)
        if event_type:
            events = [e for e in events if e.event_type == event_type]
        return events[-limit:]


# Module singleton
_metacognitive_monitor: Optional[MetacognitiveMonitor] = None


def get_metacognitive_monitor(kernel=None, world_models=None, **kwargs) -> MetacognitiveMonitor:
    global _metacognitive_monitor
    if _metacognitive_monitor is None and kernel:
        _metacognitive_monitor = MetacognitiveMonitor(kernel, world_models, **kwargs)
    return _metacognitive_monitor


def set_metacognitive_monitor(monitor: MetacognitiveMonitor) -> None:
    global _metacognitive_monitor
    _metacognitive_monitor = monitor