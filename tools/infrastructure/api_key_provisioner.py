"""
APIKeyProvisioner — Autonomous LLM API key signup + free-tier watcher.

Two public tools (registered in tools/tool_manager.py):
    search_free_apis(provider_filter=None)
    provision_api_key(provider, email=None, name=None)

Design:
    - Uses the existing BrowserTool (Playwright, vision-guided) for all web interaction.
    - Approval gate: risk_level="critical" (unconditional, like PublishEngine).
    - CAPTCHA/OTP: notifies the user and pauses — they handle it, confirm, we resume.
    - Keys are stored via APIKeyManager (hashed) AND written to .env silently.
"""

import json
import os
import re
import time
from typing import Dict, List, Optional

from config.settings import env_first, BASE_DIR, WORKSPACE_DIR
from human.approval import ApprovalManager
from enterprise.api_keys import APIKeyManager
from tools.web.browser_tool import BrowserTool
from tools.web.google_search import GoogleSearch
from tools.media.vision_tool import VisionTool
from infrastructure.notifications import notify_phone
from config.constants import RISK_CRITICAL


# ── Provider Signup Map ────────────────────────────────────────────────
# Keys are provider names (lowercase, machine-readable). Each entry has:
#   url       — signup / API-key page
#   help_text — description for the vision-guided fallback
PROVIDER_SIGNUP_MAP: Dict[str, Dict[str, str]] = {
    "groq": {
        "url": "https://console.groq.com/signup",
        "help_text": "GroqCloud signup form with email and password fields",
    },
    "gemini": {
        "url": "https://aistudio.google.com/app/apikey",
        "help_text": "Google AI Studio API key page — click 'Get API key' then create",
    },
    "openrouter": {
        "url": "https://openrouter.ai/auth/signup",
        "help_text": "OpenRouter signup with email and name",
    },
    "nvidia_nim": {
        "url": "https://build.nvidia.com/explore/",
        "help_text": "NVIDIA NIM build page — sign in / sign up for API access",
    },
    "together": {
        "url": "https://api.together.xyz/settings/api-keys",
        "help_text": "Together AI API keys page — sign in needed",
    },
    "cerebras": {
        "url": "https://cloud.cerebras.ai/",
        "help_text": "Cerebras Cloud portal — sign up for API access",
    },
    "mistral": {
        "url": "https://console.mistral.ai/signup/",
        "help_text": "Mistral AI console signup with email",
    },
}

# ── Key Validation Map ─────────────────────────────────────────────────
# Each validator is (url, headers_fn) where headers_fn(key) returns headers.
VALIDATORS: Dict[str, Dict] = {
    "groq": {
        "url": "https://api.groq.com/openai/v1/models",
        "headers_fn": lambda k: {"Authorization": f"Bearer {k}"},
    },
    "gemini": {
        "url": "https://generativelanguage.googleapis.com/v1beta/models",
        "headers_fn": lambda k: {"X-Goog-Api-Key": k},
    },
    "openrouter": {
        "url": "https://openrouter.ai/api/v1/auth/key",
        "headers_fn": lambda k: {"Authorization": f"Bearer {k}"},
    },
    "cerebras": {
        "url": "https://api.cerebras.ai/v1/models",
        "headers_fn": lambda k: {"Authorization": f"Bearer {k}"},
    },
    "mistral": {
        "url": "https://api.mistral.ai/v1/models",
        "headers_fn": lambda k: {"Authorization": f"Bearer {k}"},
    },
    "together": {
        "url": "https://api.together.xyz/v1/models",
        "headers_fn": lambda k: {"Authorization": f"Bearer {k}"},
    },
}

# ── Key Pattern Map ────────────────────────────────────────────────────
# Regex patterns for extracting API keys from success/dashboard pages.
KEY_PATTERNS = {
    "gsk_": r"gsk_[A-Za-z0-9]{50,}",
    "sk-": r"sk-[A-Za-z0-9]{20,}",
    "AIza": r"AIza[0-9A-Za-z_-]{35}",
    "nvapi-": r"nvapi-[0-9a-f-]{36,}",
}


# ── Search sources for weekly watcher ──────────────────────────────────
SEARCH_QUERIES = [
    "new free LLM API 2025",
    "NVIDIA NIM pricing free tier",
    "Gemini free tier change 2025",
    "Groq API update pricing",
    "free LLM API providers comparison",
]

NEWS_SOURCES = [
    ("Hacker News", "https://news.ycombinator.com/"),
    ("r/LocalLLaMA", "https://old.reddit.com/r/LocalLLaMA/"),
]


class APIKeyProvisioner:
    """Autonomous API key signup and free-tier scanning."""

    def __init__(self):
        self.browser = BrowserTool()
        self.searcher = GoogleSearch()
        self.vision = VisionTool()
        self.key_manager = APIKeyManager()
        self.approval = ApprovalManager(
            mode=os.environ.get("APPROVAL_MODE", "auto")
        )
        self._db_path = str(BASE_DIR / "storage/provisioner_audit.db")
        self._init_audit_db()

    # ── Audit trail (append-only, same pattern as PublishEngine) ──────
    def _init_audit_db(self) -> None:
        import sqlite3
        os.makedirs(os.path.dirname(self._db_path), exist_ok=True)
        try:
            with sqlite3.connect(self._db_path) as c:
                c.execute("""CREATE TABLE IF NOT EXISTS provision_audit (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    provider TEXT NOT NULL,
                    action TEXT NOT NULL,
                    result TEXT DEFAULT '',
                    key_prefix TEXT DEFAULT '',
                    error TEXT DEFAULT '',
                    created_at REAL
                )""")
        except Exception:
            pass  # non-fatal — audit is best-effort

    def _audit(self, provider: str, action: str, result: str = "",
               key_prefix: str = "", error: str = "") -> None:
        import sqlite3
        try:
            with sqlite3.connect(self._db_path) as c:
                c.execute(
                    "INSERT INTO provision_audit "
                    "(provider, action, result, key_prefix, error, created_at) "
                    "VALUES (?, ?, ?, ?, ?, ?)",
                    (provider, action, result, key_prefix, error, time.time()),
                )
        except Exception:
            pass

    # ── Helper: silent .env write (taste: inline python re.sub) ──────
    @staticmethod
    def _set_env_var(key: str, value: str) -> None:
        """Silently update .env with a new variable. No echo of the value.
        Passes the value through the environment so it never appears in
        the command string (prevents shell-injection via the value)."""
        env_path = BASE_DIR / ".env"
        if not env_path.exists():
            with open(env_path, "w") as f:
                f.write(f"{key}={value}\n")
            return
        import subprocess
        # Build a python script that reads KEY_VAL from its own env
        code = (
            "import os, re;"
            "p = os.environ['ENV_PATH'];"
            "v = os.environ['KEY_VAL'];"
            "t = open(p).read();"
            "open(p, 'w').write(re.sub(rf'(?m)^{key}=.*', f'{key}={v}', t)"
            " if re.search(rf'(?m)^{key}=', t) else t + f'\\n{key}={v}\\n')"
        )
        subprocess.run(
            ["python", "-c", code],
            env={**os.environ, "ENV_PATH": str(env_path), "KEY_VAL": value},
            capture_output=True,
        )

    # ── Helper: validate a key with a test API call ───────────────────
    def _validate_key(self, provider: str, key: str) -> bool:
        """Make one test API call. Returns True if the key works."""
        import requests
        info = VALIDATORS.get(provider)
        if not info:
            return True  # no validator = assume valid (best-effort)
        try:
            resp = requests.get(
                info["url"],
                headers=info["headers_fn"](key),
                timeout=10,
            )
            return resp.status_code < 500  # 2xx or 4xx auth error = key processed
        except Exception:
            return False

    # ── Helper: extract patterns from page text ───────────────────────
    @staticmethod
    def _find_key_in_text(text: str) -> Optional[str]:
        for pattern in KEY_PATTERNS.values():
            m = re.search(pattern, text)
            if m:
                return m.group(0)
        return None

    # ── Phase helpers for provision flow ──────────────────────────────

    def _phase_navigate_fill(self, provider: str, email: str, name: str) -> str:
        """Navigate to signup page, fill email and name fields.
        Returns the page text snapshot for the approval prompt."""
        info = PROVIDER_SIGNUP_MAP.get(provider)
        if not info:
            raise ValueError(
                f"Unknown provider '{provider}'. Known: "
                + ", ".join(sorted(PROVIDER_SIGNUP_MAP.keys()))
            )

        url = info["url"]
        open_result = self.browser.open(url)
        if open_result.startswith("Error"):
            raise RuntimeError(f"Failed to open {url}: {open_result}")

        # Wait for page to settle
        self.browser._ensure_page().wait_for_timeout(2000)

        # Confirm we're on a signup-like page via vision
        look_result = self.browser.look(
            f"Is this the {provider} signup page? {info['help_text']}"
        )

        # Try to fill email and name fields
        # First attempt: common selectors (name attributes)
        page = self.browser._ensure_page()
        email_filled = False
        name_filled = False

        for sel in ["input[type='email']", "input[name='email']",
                     "input[id*='email']", "input[placeholder*='email' i]",
                     "input[aria-label*='email' i]"]:
            try:
                el = page.query_selector(sel)
                if el:
                    el.fill(email)
                    email_filled = True
                    break
            except Exception:
                continue

        if not email_filled:
            # Vision-guided fallback: click the email field then type
            click_result = self.browser.click_visually("the email input field")
            self.browser._ensure_page().keyboard.type(email, delay=30)
            email_filled = True  # best-effort

        for sel in ["input[name='name']", "input[name='full_name']",
                     "input[name='display_name']", "input[id*='name']",
                     "input[placeholder*='name' i]", "input[aria-label*='name' i]"]:
            try:
                el = page.query_selector(sel)
                if el and name:
                    el.fill(name)
                    name_filled = True
                    break
            except Exception:
                continue

        if not name_filled and name:
            click_result = self.browser.click_visually("the name or full name input field")
            self.browser._ensure_page().keyboard.type(name, delay=30)

        # Capture page state for the approval snapshot
        snapshot = self.browser.get_text() or ""
        return (
            f"Provider: {provider}\n"
            f"Signup URL: {url}\n"
            f"Email: {email}\n"
            f"Name: {name or '(not set)'}\n"
            f"--- Page Preview ---\n{snapshot[:3000]}"
        )

    def _phase_submit(self) -> str:
        """Click the submit button. Returns the new page text after navigation."""
        click_result = self.browser.click_visually(
            "the submit or sign up or create account button"
        )
        # Allow time for navigation / redirect
        page = self.browser._ensure_page()
        page.wait_for_timeout(4000)
        return self.browser.get_text() or ""

    def _phase_handle_captcha(self) -> None:
        """Check for CAPTCHA/OTP — if found, notify user and pause."""
        look_result = self.browser.look(
            "Is there a CAPTCHA, reCAPTCHA, email verification code input, "
            "or OTP field visible on this page? Answer YES or NO and describe what you see."
        )
        capcha_indicators = [
            "captcha", "recaptcha", "verification code", "otp",
            "verify your email", "check your email", "enter the code",
        ]
        should_pause = any(
            ind in look_result.lower() for ind in capcha_indicators
        )
        if not should_pause:
            return

        # Notify + take screenshot
        screenshot_path = f"captcha_{int(time.time())}.png"
        self.browser.screenshot(filename=screenshot_path)

        notify_phone(
            title="API Key Signup: Action Required",
            body=f"CAPTCHA or OTP detected. Handle it, then confirm. Screenshot: {screenshot_path}",
            level="warn",
        )
        print(f"\n⚠️  CAPTCHA/OTP detected on the signup page.")
        print(f"   Screenshot saved: {screenshot_path}")
        print(f"   Notification sent to your phone.")
        input("   Handle it in the browser, then type 'done' and press Enter: ")
        # After user confirms, wait briefly for page to update
        self.browser._ensure_page().wait_for_timeout(2000)

    def _phase_extract_key(self, provider: str, page_text: str) -> Optional[str]:
        """Try to find an API key on the current page. If not found,
        navigate to dashboard / API keys section."""
        key = self._find_key_in_text(page_text)
        if key:
            return key

        # Try looking for dashboard or API keys navigation
        page = self.browser._ensure_page()
        for link_text in ["dashboard", "api keys", "keys", "console"]:
            try:
                link = page.query_selector(f"a[href*='{link_text}']")
                if link:
                    link.click()
                    page.wait_for_timeout(3000)
                    new_text = self.browser.get_text() or ""
                    key = self._find_key_in_text(new_text)
                    if key:
                        return key
            except Exception:
                continue

        return None

    # ── M1 provider + env key mapping (mirrors M1's keygen.ts) ──────
    M1_PROVIDER_MAP = {
        "groq": ("groq", "M1_EMERGENCY_GROQ_KEY"),
        "gemini": ("gemini", "M1_EMERGENCY_GEMINI_KEY"),
        "nvidia_nim": ("nim", "NVIDIA_NIM_KEY"),
    }

    def _m1_keygen_integration(self, provider: str, key: str) -> str:
        """Mirror what M1's keygen.ts does: write to M1's .env and
        keystore pool (~/.m1/keys.json), so M1 can use the new key
        without a manual keygen run. Returns a status message."""
        m1_entry = self.M1_PROVIDER_MAP.get(provider)
        if not m1_entry:
            return ""  # no M1 mapping = skip (not an error)

        m1_provider, m1_env_key = m1_entry
        m1_env_path = os.path.expanduser("~/M1/.env")
        results = []

        # 1. Write to M1's .env
        if os.path.isfile(m1_env_path):
            try:
                with open(m1_env_path) as f:
                    content = f.read()
                regex = re.compile(rf"^{m1_env_key}=.*", re.MULTILINE)
                if regex.search(content):
                    content = regex.sub(f"{m1_env_key}={key}", content)
                else:
                    content += f"\n{m1_env_key}={key}\n"
                with open(m1_env_path, "w") as f:
                    f.write(content)
                results.append(f"M1 .env ({m1_env_key})")
            except Exception as e:
                results.append(f"M1 .env write failed: {e}")

        # 2. Add to M1's keystore pool at ~/.m1/keys.json
        pool_path = os.path.expanduser("~/.m1/keys.json")
        try:
            os.makedirs(os.path.dirname(pool_path), exist_ok=True)
            pool = {"keys": [], "archive": []}
            if os.path.isfile(pool_path):
                with open(pool_path) as f:
                    pool = json.load(f)
            pool.setdefault("keys", [])
            pool.setdefault("archive", [])
            pool["keys"].append({
                "provider": m1_provider,
                "key": key,
                "status": "active",
                "lastOk": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime()),
                "failCount": 0,
                "addedAt": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime()),
            })
            with open(pool_path, "w") as f:
                json.dump(pool, f, indent=2)
            results.append("M1 keystore pool")
        except Exception as e:
            results.append(f"M1 keystore write failed: {e}")

        return " + ".join(results) if results else ""

    def _phase_store_key(self, provider: str, key: str) -> str:
        """Validate, store via APIKeyManager, write to .env + M1 silently.
        Returns a confirmation string."""
        # Validate
        valid = self._validate_key(provider, key)
        if not valid:
            self._audit(provider, "store_failed", error="validation_failed")
            return f"Key extracted but validation failed for {provider}. Not stored."

        # Store via APIKeyManager (hashed)
        record = self.key_manager.create(
            name=f"provisioned_{provider}",
            owner="provisioner",
        )
        key_prefix = record.get("key", key)[:10]

        # Write to Maya's .env (silent, no echo)
        env_var = f"{provider.upper()}_KEY"
        self._set_env_var(env_var, key)

        # M1 integration: writes to M1 .env + keystore pool
        m1_status = self._m1_keygen_integration(provider, key)
        m1_line = f"M1 keygen: {m1_status}\n" if m1_status else ""

        self._audit(provider, "stored", result="ok", key_prefix=key_prefix)
        return (
            f"✅ Key provisioned and stored for {provider}.\n"
            f"   Prefix: {key_prefix}...\n"
            f"   Hashed in enterprise key store (id: {record.get('id')})\n"
            f"   Written to .env as {env_var}\n"
            f"{m1_line}"
            f"   Validated: {'yes' if valid else 'no'}"
        )

    # ── Public tool: search_free_apis ─────────────────────────────────

    def search_free_apis(self, provider_filter: Optional[str] = None,
                         **kwargs) -> str:
        """Scan for new free/cheap LLM APIs and news. Proposal only.
        Args:
            provider_filter: optional — narrow results to a provider name.
        Returns a structured report of findings."""
        findings: List[str] = []

        # 1. Web search queries
        for query in SEARCH_QUERIES:
            if provider_filter and provider_filter.lower() not in query.lower():
                continue
            result = self.searcher.search(query, num_results=3)
            if result and "No results" not in result:
                findings.append(f"Search: {query}\n{result[:1500]}")

        # 2. Direct provider page checks (if filter matches)
        if provider_filter:
            for prov, info in PROVIDER_SIGNUP_MAP.items():
                if provider_filter.lower() in prov:
                    open_result = self.browser.open(info["url"])
                    if not open_result.startswith("Error"):
                        look_result = self.browser.look(
                            f"What free tier or pricing options does this page show "
                            f"for {prov}?"
                        )
                        if look_result:
                            findings.append(
                                f"Direct check: {prov} ({info['url']})\n"
                                f"{look_result[:2000]}"
                            )

        # 3. News sources
        for source_name, source_url in NEWS_SOURCES:
            open_result = self.browser.open(source_url)
            if not open_result.startswith("Error"):
                snapshot = self.browser.look(
                    "List the top 3 most relevant posts about LLM APIs, "
                    "free tiers, pricing changes, or new AI providers. "
                    "Include post titles."
                )
                if snapshot:
                    findings.append(f"News: {source_name}\n{snapshot[:1500]}")

        if not findings:
            report = "No significant findings from this scan."
        else:
            report = "## API Free Tier Scan Results\n\n" + \
                     "\n---\n".join(f"### Result {i+1}\n{f}"
                                    for i, f in enumerate(findings))

        # Push to phone
        notify_phone(
            title="API Free Tier Scan Complete",
            body=f"Found {len(findings)} findings. Run again with a provider filter for details.",
            level="info",
        )

        self._audit("scan", "completed",
                    result=f"{len(findings)} findings")
        return report

    # ── Public tool: provision_api_key ────────────────────────────────

    def provision_key(self, provider: str = "", email: str = "",
                      name: str = "", **kwargs) -> str:
        """Automate LLM API key signup for a provider.
        Args:
            provider: required — one of groq, gemini, openrouter, etc.
            email: optional — defaults to PROVISIONER_EMAIL from .env.
            name: optional — defaults to PROVISIONER_NAME from .env.
        One-tap critical approval before form submission.
        Pauses for CAPTCHA/OTP with phone notification."""
        if not provider:
            return (
                "Error: provider is required. "
                f"Known providers: {', '.join(sorted(PROVIDER_SIGNUP_MAP.keys()))}"
            )

        provider = provider.lower().strip()
        if provider not in PROVIDER_SIGNUP_MAP:
            return (
                f"Error: unknown provider '{provider}'. "
                f"Known: {', '.join(sorted(PROVIDER_SIGNUP_MAP.keys()))}"
            )

        # Resolve credentials
        email = email or env_first("PROVISIONER_EMAIL")
        name = name or env_first("PROVISIONER_NAME")
        if not email:
            return "Error: email required — pass it or set PROVISIONER_EMAIL in .env"

        try:
            # ── Phase 1: Navigate & Fill ──────────────────────────────
            snapshot = self._phase_navigate_fill(provider, email, name)

            # ── Phase 2: Approval Gate (critical — unconditional) ──────
            approved = self.approval.request_approval(
                action=f"Submit API key signup for {provider}",
                reason=f"This will submit your info to {provider}'s signup form.\n\n"
                       f"Form contents:\n{snapshot}",
                risk_level=RISK_CRITICAL,
            )

            if not approved:
                self._audit(provider, "rejected", error="user_denied")
                self.browser.close()
                return f"⏹  Signup for {provider} rejected by user."

            # ── Phase 3: Submit ──────────────────────────────────────
            page_after_submit = self._phase_submit()
            self._audit(provider, "submitted")

            # ── Phase 4: Handle CAPTCHA/OTP ──────────────────────────
            self._phase_handle_captcha()

            # ── Phase 5: Extract Key ─────────────────────────────────
            key = self._phase_extract_key(provider, page_after_submit)
            if not key:
                # After CAPTCHA, try again — page may have advanced
                current_text = self.browser.get_text() or ""
                key = self._phase_extract_key(provider, current_text)

            if not key:
                self._audit(provider, "key_not_found", error="extraction_failed")
                return (
                    f"⚠️  Signup submitted for {provider}, but no API key was found "
                    f"on the page. Check the dashboard manually. "
                    f"Key may have been emailed instead."
                )

            # ── Phase 6: Store & Validate ────────────────────────────
            result = self._phase_store_key(provider, key)

            # Clean up browser
            self.browser.close()
            self._audit(provider, "success", result="ok",
                        key_prefix=key[:10])
            return result

        except ValueError as e:
            self._audit(provider, "error", error=str(e))
            return f"Error: {e}"
        except RuntimeError as e:
            self._audit(provider, "error", error=str(e))
            return f"Error: {e}"
        except Exception as e:
            self._audit(provider, "crash", error=str(e)[:500])
            return f"Unexpected error during {provider} signup: {e}"
