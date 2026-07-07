"""
Supabase-backed persistence for users, budgets, and chat history.

Uses the Supabase Python client with the SERVICE ROLE key (server-side only —
this key bypasses Row Level Security and must NEVER be sent to the frontend
or committed to git). The anon/public key is not used here at all.

Soft-fails to `enabled = False` if SUPABASE_URL / SUPABASE_SERVICE_KEY are not
set, or if the `supabase` package isn't installed. When disabled, api.py falls
back to the old single-admin-user behavior so nothing breaks for people who
haven't run the migration yet.
"""
import os
import uuid
from datetime import datetime, timezone
from typing import Optional

try:
    from supabase import create_client, Client
    _SUPABASE_SDK_AVAILABLE = True
except ImportError:
    _SUPABASE_SDK_AVAILABLE = False
    Client = None


class SupabaseStore:
    def __init__(self):
        self.client: Optional["Client"] = None
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_SERVICE_KEY")

        if not _SUPABASE_SDK_AVAILABLE:
            print("INFO: 'supabase' package not installed — multi-user features disabled. "
                  "Run: pip install supabase")
            return
        if not url or not key:
            print("INFO: SUPABASE_URL / SUPABASE_SERVICE_KEY not set — "
                  "multi-user features disabled, using single ADMIN_EMAIL login.")
            return
        try:
            self.client = create_client(url, key)
            print("✅ Supabase connected — multi-user mode active")
        except Exception as e:
            print(f"WARNING: Supabase client failed to init: {e}")

    @property
    def enabled(self) -> bool:
        return self.client is not None

    # ── Users ──────────────────────────────────────────────
    def get_user_by_email(self, email: str) -> Optional[dict]:
        if not self.enabled:
            return None
        res = self.client.table("users").select("*").eq("email", email).limit(1).execute()
        return res.data[0] if res.data else None

    def get_user_by_id(self, user_id: str) -> Optional[dict]:
        if not self.enabled:
            return None
        res = self.client.table("users").select("*").eq("id", user_id).limit(1).execute()
        return res.data[0] if res.data else None

    def create_user(self, email: str, password_hash: str, name: str = "",
                     role: str = "user", budget_usd: float = 5.0) -> dict:
        row = {
            "id": str(uuid.uuid4()),
            "email": email,
            "password_hash": password_hash,
            "name": name or email.split("@")[0],
            "role": role,
            "budget_usd": budget_usd,
            "budget_used_usd": 0,
            "banned": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        res = self.client.table("users").insert(row).execute()
        return res.data[0] if res.data else row

    def list_users(self, limit: int = 200) -> list:
        if not self.enabled:
            return []
        res = (self.client.table("users")
               .select("id,email,name,role,budget_usd,budget_used_usd,banned,created_at")
               .order("created_at", desc=True).limit(limit).execute())
        return res.data or []

    def set_banned(self, user_id: str, banned: bool) -> Optional[dict]:
        if not self.enabled:
            return None
        res = self.client.table("users").update({"banned": banned}).eq("id", user_id).execute()
        return res.data[0] if res.data else None

    def set_budget(self, user_id: str, budget_usd: float) -> Optional[dict]:
        if not self.enabled:
            return None
        res = self.client.table("users").update({"budget_usd": budget_usd}).eq("id", user_id).execute()
        return res.data[0] if res.data else None

    def add_budget_usage(self, user_id: str, amount_usd: float) -> Optional[dict]:
        if not self.enabled:
            return None
        user = self.get_user_by_id(user_id)
        if not user:
            return None
        new_used = float(user.get("budget_used_usd") or 0) + amount_usd
        res = self.client.table("users").update({"budget_used_usd": new_used}).eq("id", user_id).execute()
        return res.data[0] if res.data else None

    def over_budget(self, user_id: str) -> bool:
        """True if the user has used up their allotted budget."""
        user = self.get_user_by_id(user_id)
        if not user:
            return False
        return float(user.get("budget_used_usd") or 0) >= float(user.get("budget_usd") or 0)

    # ── Chat history (per user, per conversation thread) ────
    def add_chat_message(self, user_id: str, chat_id: str, role: str, content: str):
        if not self.enabled:
            return
        self.client.table("chat_messages").insert({
            "id": str(uuid.uuid4()), "user_id": user_id, "chat_id": chat_id,
            "role": role, "content": content,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }).execute()

    def get_chat_history(self, user_id: str, chat_id: str, limit: int = 20) -> list:
        if not self.enabled:
            return []
        res = (self.client.table("chat_messages").select("role,content,created_at")
               .eq("user_id", user_id).eq("chat_id", chat_id)
               .order("created_at", desc=False).limit(limit).execute())
        return res.data or []

    # ── LLM provider keys (set from the Admin Panel, survive restarts) ──
    def get_provider_keys(self) -> dict:
        if not self.enabled:
            return {}
        res = self.client.table("provider_keys").select("provider,api_key").execute()
        return {row["provider"]: row["api_key"] for row in (res.data or [])}

    def set_provider_key(self, provider: str, api_key: str) -> Optional[dict]:
        if not self.enabled:
            return None
        row = {"provider": provider, "api_key": api_key,
               "updated_at": datetime.now(timezone.utc).isoformat()}
        res = self.client.table("provider_keys").upsert(row, on_conflict="provider").execute()
        return res.data[0] if res.data else row


# Single shared instance, imported by api.py
supabase_store = SupabaseStore()
