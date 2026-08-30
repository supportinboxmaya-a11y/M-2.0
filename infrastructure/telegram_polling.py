#!/usr/bin/env python3
"""
Maya 2.0 ULTRA - Telegram Polling Service
==========================================
Polls Telegram Bot API for callback queries (approval button clicks).
Runs as a standalone service, no webhook or tunnel needed.
Uses polling mode (getUpdates) - no webhook/tunnel needed.
"""

import asyncio
import json
import os
import sys
import time
import signal
from typing import Dict, List, Optional
from contextlib import asynccontextmanager

import aiohttp
import sqlite3

# Ensure unbuffered output so logs appear immediately
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from infrastructure.income_notifications import (
    get_notif_conn, get_notification_service, NotificationType, NotificationPriority
)

# ─── CONFIG ──────────────────────────────────────────────────────────────────
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID", "")
POLL_INTERVAL = int(os.environ.get("TELEGRAM_POLL_INTERVAL", "3"))  # seconds
BOT_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

# ─── DB HELPERS ──────────────────────────────────────────────────────────────
def get_notif_conn():
    conn = sqlite3.connect("/home/ubuntu/M-2.0/storage/income_engine/notifications.db")
    conn.row_factory = sqlite3.Row
    return conn


# ─── POLLING SERVICE ────────────────────────────────────────────────────────
class TelegramPollingService:
    def __init__(self):
        self.running = False
        self.task: Optional[asyncio.Task] = None
        self.last_update_id = 0
        self.session: Optional[aiohttp.ClientSession] = None
        self._log("Service initialized")

    def _log(self, msg: str):
        """Log with flush=True for immediate output."""
        print(f"[TelegramPolling] {msg}", flush=True)

    async def start(self):
        if self.running:
            return
        self.running = True
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=30)
        )
        self._log("Service initialized")

        # Get the latest update_id to start polling from the latest
        await self._get_latest_update_id()
        
        self.task = asyncio.create_task(self._poll_loop())
        self._log("Started polling")

    async def stop(self):
        self._log("Stop requested")
        self.running = False
        if self.task:
            self.task.cancel()
            try:
                await asyncio.wait_for(self.task, timeout=5.0)
            except (asyncio.CancelledError, asyncio.TimeoutError):
                pass
        if self.session:
            await self.session.close()
        self._log("Stopped")

    async def _get_latest_update_id(self):
        """Get the latest update_id to start polling from the latest."""
        try:
            async with self.session.get(
                f"{BOT_API_URL}/getUpdates", 
                params={"limit": 1, "offset": -1},
                timeout=aiohttp.ClientTimeout(total=10)
            ) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    if data.get("ok") and data.get("result"):
                        self.last_update_id = data["result"][0]["update_id"] + 1
                        self._log(f"Starting from update_id: {self.last_update_id}")
        except Exception as e:
            self._log(f"Error getting latest update_id: {e}")

    async def _poll_loop(self):
        """Main polling loop - calls getUpdates periodically."""
        self._log(f"Entering poll loop, running={self.running}")
        while self.running:
            self._log(f"Poll loop iteration, running={self.running}, last_update_id={self.last_update_id}")
            try:
                await self._poll_once()
            except Exception as e:
                self._log(f"Poll error: {e}")
                import traceback
                traceback.print_exc()
            
            try:
                await asyncio.sleep(POLL_INTERVAL)
            except asyncio.CancelledError:
                break

    async def _poll_once(self):
        """Single poll - fetch updates and process callbacks."""
        try:
            params = {
                "offset": self.last_update_id,
                "limit": 100,
                "timeout": 5,  # Short polling timeout for faster shutdown
                "allowed_updates": ["callback_query"]
            }
            
            async with self.session.get(
                f"{BOT_API_URL}/getUpdates", 
                params=params, 
                timeout=aiohttp.ClientTimeout(total=8)
            ) as resp:
                if resp.status != 200:
                    self._log(f"getUpdates failed: {resp.status}")
                    return
                
                data = await resp.json()
                if not data.get("ok"):
                    self._log(f"API error: {data}")
                    return
                
                updates = data.get("result", [])
                for update in updates:
                    self.last_update_id = update["update_id"] + 1
                    await self._process_update(update)
                    
        except asyncio.CancelledError:
            raise
        except Exception as e:
            self._log(f"Poll exception: {e}")
            import traceback
            traceback.print_exc()

    async def _process_update(self, update: dict):
        """Process a single update - check for callback queries."""
        self._log(f"Received update: {update.get('update_id')}")
        
        callback_query = update.get("callback_query")
        if not callback_query:
            return
        
        data = callback_query.get("data", "")
        user_id = callback_query.get("from", {}).get("id")
        callback_query_id = callback_query.get("id")
        
        self._log(f"Callback query received: data={data}, user_id={user_id}, callback_query_id={callback_query_id}")
        
        if not data.startswith(("approve:", "reject:")):
            self._log(f"Callback data doesn't match approve/reject pattern: {data}")
            return
        
        action, approval_id = data.split(":", 1)
        approved = action == "approve"
        
        chat_id = callback_query.get("message", {}).get("chat", {}).get("id")
        message_id = callback_query.get("message", {}).get("message_id")
        
        self._log(f"Processing callback: {action} for approval {approval_id} by user {user_id}")
        
        # Process the approval decision
        await self._process_approval(approval_id, approved, str(user_id))
        
        # Answer callback query to show confirmation to user
        await self._answer_callback_query(callback_query_id, approved, chat_id, message_id)
        self._log(f"Callback processing complete for {approval_id}")

    async def _process_approval(self, approval_id: str, approved: bool, user_id: str):
        """Process approval decision in database."""
        self._log(f"_process_approval called: approval_id={approval_id}, approved={approved}, user_id={user_id}")
        
        # First, update the database - commit the transaction before sending notifications
        with get_notif_conn() as conn:
            row = conn.execute("SELECT * FROM approval_requests WHERE id = ?", (approval_id,)).fetchone()
            if not row:
                self._log(f"Approval {approval_id} not found")
                return
            
            if row["status"] != "pending":
                self._log(f"Approval {approval_id} already {row['status']}")
                return
            
            decision = "approved" if approved else "rejected"
            decision_text = "APPROVED" if approved else "REJECTED"
            
            conn.execute("""
                UPDATE approval_requests 
                SET status = ?, decided_at = ?, decision = ?, decided_by = ?
                WHERE id = ?
            """, (decision, time.time(), decision, user_id, approval_id))
            
            self._log(f"Approval {approval_id} marked as {decision}")
        
        # Send response notification via notification service (outside DB transaction)
        try:
            notif_service = get_notification_service()
            await notif_service.send_approval_response(approval_id, approved, user_id, "Decided via Telegram")
            self._log(f"send_approval_response completed for {approval_id}")
        except Exception as e:
            self._log(f"Warning: Failed to send approval response notification for {approval_id}: {e}")
            import traceback
            traceback.print_exc()

    async def _answer_callback_query(self, callback_query_id: str, approved: bool, chat_id: int, message_id: int):
        """Answer the callback query and update the original message with confirmation."""
        if not self.session:
            self._log("_answer_callback_query: no session")
            return
        
        text = "✅ Approved" if approved else "❌ Rejected"
        self._log(f"Answering callback query {callback_query_id} with approved={approved}")
        try:
            # First answer the callback query (shows popup)
            async with self.session.post(
                f"{BOT_API_URL}/answerCallbackQuery",
                json={
                    "callback_query_id": callback_query_id,
                    "text": f"{'✅' if approved else '❌'} {'Approved' if approved else 'Rejected'}",
                    "show_alert": True
                }
            ) as resp:
                if resp.status >= 400:
                    self._log(f"Failed to answer callback: {await resp.text()}")
                else:
                    self._log("Callback query answered successfully")
            
            # Also edit the original message to show confirmation
            try:
                confirmation_text = f"{'✅ Approved' if approved else '❌ Rejected'} — Your decision has been recorded."
                async with self.session.post(
                    f"{BOT_API_URL}/editMessageText",
                    json={
                        "chat_id": chat_id,
                        "message_id": message_id,
                        "text": confirmation_text,
                        "parse_mode": "Markdown"
                    }
                ) as resp:
                    if resp.status >= 400:
                        self._log(f"Failed to edit message: {await resp.text()}")
                    else:
                        self._log("Original message updated with confirmation")
            except Exception as e:
                self._log(f"Failed to edit message (may not have edit permissions): {e}")
                
        except Exception as e:
            self._log(f"Failed to answer callback: {e}")
            import traceback
            traceback.print_exc()


# ─── SERVICE MANAGEMENT ─────────────────────────────────────────────────────
_polling_service: Optional["TelegramPollingService"] = None


def get_polling_service() -> TelegramPollingService:
    global _polling_service
    if _polling_service is None:
        _polling_service = TelegramPollingService()
    return _polling_service


async def start_polling():
    """Start the Telegram polling service."""
    service = get_polling_service()
    await service.start()
    return service


async def stop_polling():
    """Stop the Telegram polling service."""
    global _polling_service
    if _polling_service:
        await _polling_service.stop()
        _polling_service = None


# ─── MAIN ENTRY POINT ───────────────────────────────────────────────────────
async def main():
    """Run the polling service."""
    print("[TelegramPolling] Starting service...", flush=True)
    
    service = await start_polling()
    
    # Handle shutdown signals
    loop = asyncio.get_event_loop()
    shutdown_event = asyncio.Event()
    
    def signal_handler():
        print("[TelegramPolling] Shutdown signal received", flush=True)
        shutdown_event.set()
    
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, signal_handler)
    
    # Keep running until shutdown requested
    try:
        await shutdown_event.wait()
        print("[TelegramPolling] Shutdown event received, stopping...", flush=True)
    except asyncio.CancelledError:
        pass
    finally:
        print("[TelegramPolling] Cleaning up...", flush=True)
        await stop_polling()
        print("[TelegramPolling] Service stopped", flush=True)


if __name__ == "__main__":
    # Force unbuffered output
    os.environ["PYTHONUNBUFFERED"] = "1"
    asyncio.run(main())