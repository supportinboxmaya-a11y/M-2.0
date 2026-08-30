"""
Maya 2.0 ULTRA - Income Engine: Notification Service
====================================================
Unified notification system for approval requests, digests, and alerts.
Supports multiple channels: Email, Webhook, Telegram, Slack, Discord.
"""
import asyncio
import json
import os
import random
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set

import aiohttp
import sqlite3
from maya_logging.logger import get_logger

log = get_logger("notifications")

# ═════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

NOTIF_DB_DIR = Path("/home/ubuntu/M-2.0/storage/income_engine")
NOTIF_DB_DIR.mkdir(parents=True, exist_ok=True)
NOTIF_DB = str(NOTIF_DB_DIR / "notifications.db")

# Channel configurations from environment
NOTIFICATION_CHANNELS = {
    "email": {
        "enabled": os.environ.get("NOTIFY_EMAIL_ENABLED", "false").lower() == "true",
        "smtp_host": os.environ.get("SMTP_HOST", ""),
        "smtp_port": int(os.environ.get("SMTP_PORT", "587")),
        "smtp_user": os.environ.get("SMTP_USER", ""),
        "smtp_pass": os.environ.get("SMTP_PASS", ""),
        "from_email": os.environ.get("SMTP_FROM", ""),
        "to_emails": [e.strip() for e in os.environ.get("NOTIFY_EMAIL_TO", "").split(",") if e.strip()],
    },
    "webhook": {
        "enabled": os.environ.get("NOTIFY_WEBHOOK_ENABLED", "false").lower() == "true",
        "url": os.environ.get("NOTIFY_WEBHOOK_URL", ""),
        "secret": os.environ.get("NOTIFY_WEBHOOK_SECRET", ""),
    },
    "telegram": {
        "enabled": os.environ.get("NOTIFY_TELEGRAM_ENABLED", "false").lower() == "true",
        "bot_token": os.environ.get("TELEGRAM_BOT_TOKEN", ""),
        "chat_ids": [c.strip() for c in os.environ.get("TELEGRAM_CHAT_IDS", "").split(",") if c.strip()],
    },
    "slack": {
        "enabled": os.environ.get("NOTIFY_SLACK_ENABLED", "false").lower() == "true",
        "webhook_url": os.environ.get("SLACK_WEBHOOK_URL", ""),
    },
    "discord": {
        "enabled": os.environ.get("NOTIFY_DISCORD_ENABLED", "false").lower() == "true",
        "webhook_url": os.environ.get("DISCORD_WEBHOOK_URL", ""),
    },
}

# ═════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ═════════════════════════════════════════════════════════════════════════════

class NotificationType(Enum):
    APPROVAL_REQUEST = "approval_request"
    APPROVAL_RESPONSE = "approval_response"
    DAILY_DIGEST = "daily_digest"
    SCOUT_ALERT = "scout_alert"
    STRATEGIST_REVIEW = "strategist_review"
    BUILDER_STATUS = "builder_status"
    LAUNCH_READY = "launch_ready"
    ERROR_ALERT = "error_alert"
    SYSTEM_STATUS = "system_status"


class NotificationPriority(Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class Notification:
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    type: NotificationType = NotificationType.SYSTEM_STATUS
    priority: NotificationPriority = NotificationPriority.NORMAL
    title: str = ""
    message: str = ""
    channels: List[str] = field(default_factory=lambda: ["webhook"])  # Default channels
    metadata: Dict = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)
    sent_at: Optional[float] = None
    status: str = "pending"  # pending, sent, failed
    retry_count: int = 0
    error: str = ""


@dataclass
class ApprovalRequest:
    """Approval request that gets sent as notification."""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    action: str = ""
    reason: str = ""
    risk_level: str = "high"
    task_id: Optional[str] = None
    plan_id: Optional[str] = None
    opportunity_id: Optional[str] = None
    title: str = ""
    description: str = ""
    created_at: float = field(default_factory=time.time)
    expires_at: Optional[float] = None
    status: str = "pending"  # pending, approved, rejected, expired
    decided_at: Optional[float] = None
    decision: Optional[str] = None
    decided_by: Optional[str] = None
    notification_ids: List[str] = field(default_factory=list)


# ═════════════════════════════════════════════════════════════════════════════
# DATABASE
# ═════════════════════════════════════════════════════════════════════════════

def init_notification_db():
    """Initialize the notifications database."""
    with sqlite3.connect(NOTIF_DB) as conn:
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA busy_timeout=5000")
        conn.execute("""
            CREATE TABLE IF NOT EXISTS notifications (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                priority TEXT NOT NULL,
                title TEXT,
                message TEXT,
                channels TEXT DEFAULT '["webhook"]',
                metadata TEXT DEFAULT '{}',
                created_at REAL,
                sent_at REAL,
                status TEXT DEFAULT 'pending',
                retry_count INTEGER DEFAULT 0,
                error TEXT DEFAULT ''
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_notif_status ON notifications(status)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_notif_type ON notifications(type)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_notif_created ON notifications(created_at)")
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS approval_requests (
                id TEXT PRIMARY KEY,
                action TEXT NOT NULL,
                reason TEXT,
                risk_level TEXT DEFAULT 'high',
                task_id TEXT,
                plan_id TEXT,
                opportunity_id TEXT,
                title TEXT,
                description TEXT,
                created_at REAL,
                expires_at REAL,
                status TEXT DEFAULT 'pending',
                decided_at REAL,
                decision TEXT,
                decided_by TEXT,
                notification_ids TEXT DEFAULT '[]'
            )
        """)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS notification_deliveries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                notification_id TEXT NOT NULL,
                channel TEXT NOT NULL,
                success INTEGER NOT NULL,
                error TEXT DEFAULT '',
                sent_at REAL,
                FOREIGN KEY (notification_id) REFERENCES notifications(id)
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_approval_status ON approval_requests(status)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_approval_plan ON approval_requests(plan_id)")
        
        conn.execute("""
            CREATE TABLE IF NOT EXISTS notification_templates (
                name TEXT PRIMARY KEY,
                subject_template TEXT,
                body_template TEXT,
                channels TEXT DEFAULT '["webhook"]'
            )
        """)


@contextmanager
def get_notif_conn(max_retries: int = 5, base_delay: float = 0.1):
    """Get a database connection with retry logic for handling 'database is locked' errors.
    Uses exponential backoff with jitter."""
    for attempt in range(max_retries):
        try:
            conn = sqlite3.connect(NOTIF_DB)
            conn.row_factory = sqlite3.Row
            conn.execute("PRAGMA journal_mode=WAL")
            conn.execute("PRAGMA busy_timeout=5000")
            try:
                yield conn
                conn.commit()
            except Exception:
                conn.rollback()
                raise
            finally:
                conn.close()
            return
        except sqlite3.OperationalError as e:
            if "database is locked" in str(e).lower() and attempt < max_retries - 1:
                import random
                delay = base_delay * (2 ** attempt) + random.uniform(0, 0.1)
                log.warning(f"Database locked, retrying in {delay:.2f}s (attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                continue
            raise


# ═════════════════════════════════════════════════════════════════════════════
# CHANNEL SENDERS
# ══════════════════════════════════════════════════════════════════════════════

async def send_email(notification: Notification, config: Dict) -> bool:
    """Send notification via email."""
    if not config.get("enabled") or not config.get("to_emails"):
        return False
    
    try:
        import smtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        
        msg = MIMEMultipart()
        msg["From"] = config.get("from_email", "maya@localhost")
        msg["To"] = ", ".join(config["to_emails"])
        msg["Subject"] = f"[{notification.priority.value.upper()}] {notification.title}"
        
        body = f"""
{notification.message}

---
Priority: {notification.priority.value}
Type: {notification.type.value}
Time: {datetime.fromtimestamp(notification.created_at).isoformat()}
ID: {notification.id}

Maya Income Engine
        """
        msg.attach(MIMEText(body, "plain"))
        
        with smtplib.SMTP(config["smtp_host"], config["smtp_port"]) as server:
            server.starttls()
            server.login(config["smtp_user"], config["smtp_pass"])
            server.send_message(msg)
        
        return True
    except Exception as e:
        log.error(f"Email send failed: {e}")
        return False


async def send_webhook(notification: Notification, config: Dict) -> bool:
    """Send notification via webhook."""
    if not config.get("enabled") or not config.get("url"):
        return False
    
    try:
        payload = {
            "id": notification.id,
            "type": notification.type.value,
            "priority": notification.priority.value,
            "title": notification.title,
            "message": notification.message,
            "metadata": notification.metadata,
            "timestamp": notification.created_at,
        }
        
        headers = {"Content-Type": "application/json"}
        if config.get("secret"):
            import hmac
            import hashlib
            signature = hmac.new(
                config["secret"].encode(), 
                json.dumps(payload).encode(), 
                hashlib.sha256
            ).hexdigest()
            headers["X-Signature"] = signature
        
        async with aiohttp.ClientSession() as session:
            async with session.post(config["url"], json=payload, headers=headers, timeout=10) as resp:
                return resp.status < 400
    except Exception as e:
        log.error(f"Webhook send failed: {e}")
        return False


async def send_telegram(notification: Notification, config: Dict) -> bool:
    """Send notification via Telegram Bot."""
    if not config.get("enabled") or not config.get("bot_token") or not config.get("chat_ids"):
        return False
    
    try:
        priority_emoji = {
            NotificationPriority.LOW: "🔵",
            NotificationPriority.NORMAL: "🟢",
            NotificationPriority.HIGH: "🟠",
            NotificationPriority.CRITICAL: "🔴",
        }
        
        emoji = priority_emoji.get(notification.priority, "📢")
        text = f"{emoji} *{notification.title}*\n\n{notification.message}\n\n_Type: {notification.type.value}_\n_Priority: {notification.priority.value}_"
        
        url = f"https://api.telegram.org/bot{config['bot_token']}/sendMessage"
        
        # Check if this is an approval request with inline keyboard
        reply_markup = None
        if notification.type == NotificationType.APPROVAL_REQUEST:
            approval_id = notification.metadata.get("approval_id", "")
            if approval_id:
                reply_markup = {
                    "inline_keyboard": [
                        [
                            {"text": "✅ Approve", "callback_data": f"approve:{approval_id}"},
                            {"text": "❌ Reject", "callback_data": f"reject:{approval_id}"}
                        ]
                    ]
                }
        
        async with aiohttp.ClientSession() as session:
            for chat_id in config["chat_ids"]:
                payload = {
                    "chat_id": chat_id,
                    "text": text,
                    "parse_mode": "Markdown",
                    "disable_web_page_preview": True
                }
                if reply_markup:
                    payload["reply_markup"] = json.dumps(reply_markup)
                
                async with session.post(url, json=payload, timeout=10) as resp:
                    if resp.status >= 400:
                        log.warning(f"Telegram send failed for {chat_id}: {await resp.text()}")
                        return False
        return True
    except Exception as e:
        log.error(f"Telegram send failed: {e}")
        return False


async def send_slack(notification: Notification, config: Dict) -> bool:
    """Send notification via Slack webhook."""
    if not config.get("enabled") or not config.get("webhook_url"):
        return False
    
    try:
        color_map = {
            NotificationPriority.LOW: "#36a64f",
            NotificationPriority.NORMAL: "#36a64f",
            NotificationPriority.HIGH: "#ff9900",
            NotificationPriority.CRITICAL: "#ff0000",
        }
        
        payload = {
            "attachments": [{
                "color": color_map.get(notification.priority, "#36a64f"),
                "title": notification.title,
                "text": notification.message,
                "fields": [
                    {"title": "Type", "value": notification.type.value, "short": True},
                    {"title": "Priority", "value": notification.priority.value, "short": True},
                    {"title": "Time", "value": datetime.fromtimestamp(notification.created_at).isoformat(), "short": True},
                    {"title": "ID", "value": notification.id, "short": True},
                ],
                "footer": "Maya Income Engine",
                "ts": int(notification.created_at),
            }]
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(config["webhook_url"], json=payload, timeout=10) as resp:
                return resp.status < 400
    except Exception as e:
        log.error(f"Slack send failed: {e}")
        return False


async def send_discord(notification: Notification, config: Dict) -> bool:
    """Send notification via Discord webhook."""
    if not config.get("enabled") or not config.get("webhook_url"):
        return False
    
    try:
        color_map = {
            NotificationPriority.LOW: 0x36a64f,
            NotificationPriority.NORMAL: 0x36a64f,
            NotificationPriority.HIGH: 0xff9900,
            NotificationPriority.CRITICAL: 0xff0000,
        }
        
        payload = {
            "embeds": [{
                "title": notification.title,
                "description": notification.message,
                "color": color_map.get(notification.priority, 0x36a64f),
                "fields": [
                    {"name": "Type", "value": notification.type.value, "inline": True},
                    {"name": "Priority", "value": notification.priority.value, "inline": True},
                    {"name": "Time", "value": datetime.fromtimestamp(notification.created_at).isoformat(), "inline": True},
                    {"name": "ID", "value": notification.id, "inline": True},
                ],
                "footer": {"text": "Maya Income Engine"},
                "timestamp": datetime.fromtimestamp(notification.created_at).isoformat(),
            }]
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(config["webhook_url"], json=payload, timeout=10) as resp:
                return resp.status < 400
    except Exception as e:
        log.error(f"Discord send failed: {e}")
        return False


# ══════════════════════════════════════════════════════════════════════════════
# NOTIFICATION SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class NotificationService:
    """
    Unified notification service for the Income Engine.
    Handles approval requests, digests, alerts across multiple channels.
    """
    
    def __init__(self):
        self.config = NOTIFICATION_CHANNELS
        self._running = False
        self._task: Optional[asyncio.Task] = None
        self._pending_notifications: asyncio.Queue = asyncio.Queue()
        self._running = True
        self._task = asyncio.create_task(self._dispatch_loop())
        log.info("NotificationService started")
    
    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        log.info("NotificationService stopped")
    
    async def _dispatch_loop(self):
        """Main dispatch loop - processes notification queue."""
        while self._running:
            try:
                notification = await asyncio.wait_for(
                    self._pending_notifications.get(), timeout=1.0
                )
                await self._send_notification(notification)
            except asyncio.TimeoutError:
                continue
            except asyncio.CancelledError:
                break
            except Exception as e:
                log.error(f"Dispatch loop error: {e}")
    
    async def _send_notification(self, notification: Notification):
        """Send notification to all configured channels."""
        results = {}
        
        channel_senders = {
            "email": send_email,
            "webhook": send_webhook,
            "telegram": send_telegram,
            "slack": send_slack,
            "discord": send_discord,
        }
        
        for channel in notification.channels:
            if channel not in channel_senders:
                continue
            
            config = self.config.get(channel, {})
            if not config.get("enabled"):
                continue
            
            try:
                sender = channel_senders[channel]
                success = await sender(notification, config)
                results[channel] = success
                
                with get_notif_conn() as conn:
                    conn.execute("""
                        INSERT OR REPLACE INTO notification_deliveries 
                        (notification_id, channel, success, error, sent_at)
                        VALUES (?, ?, ?, ?, ?)
                    """, (notification.id, channel, int(success), 
                          "" if success else "Failed", time.time()))
            except Exception as e:
                log.error(f"Channel {channel} send error: {e}")
                results[channel] = False
        
        # Update notification status
        all_success = all(results.values()) if results else False
        with get_notif_conn() as conn:
            conn.execute("""
                UPDATE notifications SET status = ?, sent_at = ?, error = ?
                WHERE id = ?
            """, ("sent" if all_success else "failed", time.time(), 
                  "" if all_success else str(results), notification.id))
    
    async def send_notification(self, notification: Notification):
        """Queue a notification for sending."""
        # Store in DB first
        with get_notif_conn() as conn:
            conn.execute("""
                INSERT INTO notifications (id, type, priority, title, message, channels, metadata, created_at, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')
            """, (notification.id, notification.type.value, notification.priority.value,
                  notification.title, notification.message, json.dumps(notification.channels),
                  json.dumps(notification.metadata), notification.created_at))
        
        await self._pending_notifications.put(notification)
    
    async def send_approval_request(self, approval: ApprovalRequest) -> str:
        """Create and send an approval request notification."""
        # Store approval request
        with get_notif_conn() as conn:
            conn.execute("""
                INSERT INTO approval_requests (id, action, reason, risk_level, task_id, plan_id, 
                    opportunity_id, title, description, created_at, expires_at, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
            """, (approval.id, approval.action, approval.reason, approval.risk_level,
                  approval.task_id, approval.plan_id, approval.opportunity_id,
                  approval.title, approval.description, approval.created_at,
                  approval.expires_at))
        
        # Create notification
        priority_map = {
            "low": NotificationPriority.LOW,
            "medium": NotificationPriority.NORMAL,
            "high": NotificationPriority.HIGH,
            "critical": NotificationPriority.CRITICAL,
        }
        
        notification = Notification(
            type=NotificationType.APPROVAL_REQUEST,
            priority=priority_map.get(approval.risk_level, NotificationPriority.HIGH),
            title=f"Approval Required: {approval.title}",
            message=f"""
**Action:** {approval.action}
**Reason:** {approval.reason}
**Risk Level:** {approval.risk_level}
**Plan ID:** {approval.plan_id or 'N/A'}
**Opportunity ID:** {approval.opportunity_id or 'N/A'}

**Description:** {approval.description}

Please review and approve/reject via the Maya dashboard or reply to this notification.
            """.strip(),
            channels=["webhook", "telegram", "slack", "email"],
            metadata={
                "approval_id": approval.id,
                "plan_id": approval.plan_id,
                "opportunity_id": approval.opportunity_id,
                "risk_level": approval.risk_level,
            }
        )
        
        await self.send_notification(notification)
        
        # Update approval with notification IDs
        with get_notif_conn() as conn:
            conn.execute("""
                UPDATE approval_requests SET notification_ids = ? WHERE id = ?
            """, (json.dumps([notification.id]), approval.id))
        
        return approval.id
    
    async def send_daily_digest(self, strategist_result: Dict, scout_stats: Dict):
        """Send daily digest of Scout + Strategist activity."""
        notification = Notification(
            type=NotificationType.DAILY_DIGEST,
            priority=NotificationPriority.NORMAL,
            title="📊 Maya Income Engine - Daily Digest",
            message=f"""
**Scout Scan Results:**
- Signals found: {scout_stats.get('total_signals', 0)}
- Opportunities created: {scout_stats.get('opportunities_created', 0)}
- Sources scanned: {scout_stats.get('sources_scanned', 0)}

**Strategist Review:**
- Opportunities reviewed: {strategist_result.get('opportunities_reviewed', 0)}
- Top opportunity: {strategist_result.get('top_opportunity', 'None')}
- Plan created: {'Yes' if strategist_result.get('plan_created') else 'No'}
- Plan ID: {strategist_result.get('plan_id', 'N/A')}

Check the dashboard for details.
            """.strip(),
            channels=["webhook", "telegram", "slack", "email"],
            metadata={
                "scout_stats": scout_stats,
                "strategist_result": strategist_result,
            }
        )
        
        await self.send_notification(notification)
    
    async def send_approval_response(self, approval_id: str, approved: bool, decided_by: str, reason: str = ""):
        """Send notification about approval decision."""
        with get_notif_conn() as conn:
            row = conn.execute("SELECT * FROM approval_requests WHERE id = ?", (approval_id,)).fetchone()
            if not row:
                return
            
            approval = dict(row)
            decision = "APPROVED" if approved else "REJECTED"
            
            notification = Notification(
                type=NotificationType.APPROVAL_RESPONSE,
                priority=NotificationPriority.HIGH,
                title=f"Approval {decision}: {approval['title']}",
                message=f"""
**Decision:** {decided_by} {decision.lower()} the request.
**Reason:** {reason or 'No reason provided'}
**Action:** {approval['action']}
**Plan ID:** {approval['plan_id'] or 'N/A'}
**Opportunity ID:** {approval['opportunity_id'] or 'N/A'}
                """.strip(),
                channels=["webhook", "telegram", "slack", "email"],
                metadata={
                    "approval_id": approval_id,
                    "approved": approved,
                    "decided_by": decided_by,
                    "reason": reason,
                }
            )
            await self.send_notification(notification)
    
    async def send_builder_status(self, project_name: str, status: str, details: str = ""):
        """Send builder status update."""
        notification = Notification(
            type=NotificationType.BUILDER_STATUS,
            priority=NotificationPriority.NORMAL,
            title=f"Builder: {project_name} - {status}",
            message=details or f"Builder status changed to: {status}",
            channels=["webhook", "telegram"],
            metadata={"project": project_name, "status": status}
        )
        await self.send_notification(notification)
    
    async def send_launch_ready(self, project_name: str, plan_id: str):
        """Send launch-ready notification."""
        notification = Notification(
            type=NotificationType.LAUNCH_READY,
            priority=NotificationPriority.HIGH,
            title=f"🚀 Ready to Launch: {project_name}",
            message=f"""
Project **{project_name}** (plan {plan_id}) has been built and tested.
MVP is ready for launch approval.

Please review the launch package and approve to go live.
            """.strip(),
            channels=["webhook", "telegram", "slack", "email"],
            metadata={"project": project_name, "plan_id": plan_id}
        )
        await self.send_notification(notification)
    
    async def send_error_alert(self, component: str, error: str, context: str = ""):
        """Send critical error alert."""
        notification = Notification(
            type=NotificationType.ERROR_ALERT,
            priority=NotificationPriority.CRITICAL,
            title=f"🚨 Error in {component}",
            message=f"""
**Component:** {component}
**Error:** {error}
**Context:** {context}

This requires immediate attention.
            """.strip(),
            channels=["webhook", "telegram", "slack", "email"],
            metadata={"component": component, "error": error, "context": context}
        )
        await self.send_notification(notification)


# ══════════════════════════════════════════════════════════════════════════════
# MODULE SINGLETON
# ═════════════════════════════════════════════════════════════════════════════

_notification_service: Optional[NotificationService] = None


def get_notification_service() -> NotificationService:
    global _notification_service
    if _notification_service is None:
        _notification_service = NotificationService()
    return _notification_service


def reset_notification_service():
    global _notification_service
    if _notification_service:
        asyncio.create_task(_notification_service.stop())
    _notification_service = None


# Initialize database on import
init_notification_db()