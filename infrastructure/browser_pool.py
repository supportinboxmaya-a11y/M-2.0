"""
Maya 2.0 — Persistent Browser Pool (Phase 1)
=============================================
Managed pool of Playwright browser contexts with CDP sessions,
stealth plugins, and vision-guided interaction capabilities.
Optimized for Oracle ARM64 VPS deployment.
"""

import asyncio
import base64
import json
import os
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, AsyncGenerator
from playwright.async_api import (
    async_playwright, Browser, BrowserContext, Page, CDPSession,
    Playwright, ViewportSize
)

from config.settings import STORAGE_DIR, WORKSPACE_DIR


BROWSER_POOL_DIR = STORAGE_DIR / "browser_pool"
BROWSER_POOL_DIR.mkdir(parents=True, exist_ok=True)
SCREENSHOT_DIR = WORKSPACE_DIR / "browser_screenshots"
SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)


@dataclass
class BrowserContextInfo:
    """Metadata for a pooled browser context."""
    context_id: str
    context: BrowserContext
    page: Page
    cdp_session: Optional[CDPSession]
    created_at: float
    last_used: float
    in_use: bool = False
    viewport: ViewportSize = field(default_factory=lambda: {"width": 1920, "height": 1080})
    user_agent: str = ""
    metadata: Dict = field(default_factory=dict)


class BrowserPool:
    """
    Persistent pool of Playwright browser contexts.
    
    Features:
    - Pre-warmed contexts for instant task start
    - CDP sessions for vision-guided clicks
    - Stealth mode to avoid bot detection
    - Automatic cleanup and recycling
    - Screenshot/video recording
    - Mobile emulation support
    """
    
    def __init__(
        self,
        max_contexts: int = 5,
        headless: bool = True,
        stealth: bool = True,
        viewport: ViewportSize = None,
        user_agent: str = None,
        proxy: Dict = None,
        recordings_dir: str = None,
    ):
        self.max_contexts = max_contexts
        self.headless = headless
        self.stealth = stealth
        self.default_viewport = viewport or {"width": 1920, "height": 1080}
        self.default_user_agent = user_agent or (
            "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )
        self.proxy = proxy
        self.recordings_dir = recordings_dir or str(SCREENSHOT_DIR)
        
        self._playwright: Optional[Playwright] = None
        self._browser: Optional[Browser] = None
        self._contexts: Dict[str, BrowserContextInfo] = {}
        self._lock = asyncio.Lock()
        self._initialized = False
        self._cleanup_task: Optional[asyncio.Task] = None
        
        # Stealth script
        self._stealth_script = """
        () => {
            Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
            window.chrome = {runtime: {}};
            Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
            Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en']});
            const originalQuery = window.navigator.permissions.query;
            window.navigator.permissions.query = (parameters) => (
                parameters.name === 'notifications' ?
                    Promise.resolve({state: Notification.permission}) :
                    originalQuery(parameters)
            );
        }
        """

    async def initialize(self) -> None:
        """Initialize the browser pool."""
        if self._initialized:
            return
            
        self._playwright = await async_playwright().start()
        
        # Launch browser with ARM64-optimized flags
        launch_args = [
            "--no-sandbox",
            "--disable-setuid-sandbox",
            "--disable-dev-shm-usage",
            "--disable-gpu",
            "--disable-web-security",
            "--disable-features=IsolateOrigins,site-per-process",
            "--disable-site-isolation-trials",
            "--no-first-run",
            "--no-zygote",
            "--single-process",  # Better for ARM64 memory
            "--disable-background-timer-throttling",
            "--disable-backgrounding-occluded-windows",
            "--disable-renderer-backgrounding",
        ]
        
        if self.proxy:
            launch_args.append(f"--proxy-server={self.proxy.get('server')}")
        
        self._browser = await self._playwright.chromium.launch(
            headless=self.headless,
            args=launch_args,
        )
        
        # Pre-warm contexts
        await self._warm_pool()
        
        # Start cleanup task
        self._cleanup_task = asyncio.create_task(self._cleanup_loop())
        
        self._initialized = True
        print(f"✅ Browser pool initialized with {len(self._contexts)} contexts")

    async def _warm_pool(self, count: int = None) -> None:
        """Pre-create browser contexts."""
        count = count or self.max_contexts
        for _ in range(count):
            await self._create_context()

    async def _create_context(self, viewport: ViewportSize = None, 
                              user_agent: str = None, mobile: bool = False) -> BrowserContextInfo:
        """Create a new browser context with CDP session."""
        if not self._browser:
            raise RuntimeError("Browser not initialized")
        
        ctx_viewport = viewport or self.default_viewport
        ctx_user_agent = user_agent or self.default_user_agent
        
        context = await self._browser.new_context(
            viewport=ctx_viewport,
            user_agent=ctx_user_agent,
            device_scale_factor=1,
            is_mobile=mobile,
            has_touch=mobile,
            locale="en-US",
            timezone_id="UTC",
            permissions=["geolocation", "notifications"],
            record_video_dir=self.recordings_dir if self.recordings_dir else None,
        )
        
        # Apply stealth
        if self.stealth:
            await context.add_init_script(self._stealth_script)
        
        # Create page and CDP session
        page = await context.new_page()
        cdp_session = await context.new_cdp_session(page)
        
        # Enable CDP domains
        await cdp_session.send("Page.enable")
        await cdp_session.send("Runtime.enable")
        await cdp_session.send("DOM.enable")
        
        context_id = uuid.uuid4().hex[:12]
        info = BrowserContextInfo(
            context_id=context_id,
            context=context,
            page=page,
            cdp_session=cdp_session,
            created_at=time.time(),
            last_used=time.time(),
            viewport=ctx_viewport,
            user_agent=ctx_user_agent,
            metadata={"mobile": mobile},
        )
        
        self._contexts[context_id] = info
        return info

    @asynccontextmanager
    async def acquire(self, viewport: ViewportSize = None,
                      user_agent: str = None, mobile: bool = False,
                      timeout: float = 30.0) -> AsyncGenerator[BrowserContextInfo, None]:
        """Acquire a browser context from the pool."""
        if not self._initialized:
            await self.initialize()
        
        async with self._lock:
            # Find available context
            available = [
                ctx for ctx in self._contexts.values() 
                if not ctx.in_use and 
                (viewport is None or ctx.viewport == viewport) and
                (mobile == ctx.metadata.get("mobile", False))
            ]
            
            if available:
                info = available[0]
            elif len(self._contexts) < self.max_contexts:
                info = await self._create_context(viewport, user_agent, mobile)
            else:
                # Wait for a context to become available
                wait_start = time.time()
                while time.time() - wait_start < timeout:
                    await asyncio.sleep(0.5)
                    available = [
                        ctx for ctx in self._contexts.values() 
                        if not ctx.in_use
                    ]
                    if available:
                        info = available[0]
                        break
                else:
                    raise TimeoutError("No browser context available")
            
            info.in_use = True
            info.last_used = time.time()
        
        try:
            yield info
        finally:
            async with self._lock:
                info.in_use = False
                info.last_used = time.time()

    async def navigate(self, context_id: str, url: str, 
                       wait_until: str = "networkidle", timeout: float = 30000) -> Dict:
        """Navigate to URL in a context."""
        info = self._contexts.get(context_id)
        if not info:
            raise ValueError(f"Context not found: {context_id}")
        
        page = info.page
        try:
            response = await page.goto(url, wait_until=wait_until, timeout=timeout)
            return {
                "success": True,
                "url": page.url,
                "status": response.status if response else None,
                "title": await page.title(),
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def click(self, context_id: str, selector: str, 
                    force: bool = False, timeout: float = 5000) -> Dict:
        """Click an element."""
        info = self._contexts.get(context_id)
        if not info:
            raise ValueError(f"Context not found: {context_id}")
        
        try:
            await info.page.click(selector, force=force, timeout=timeout)
            return {"success": True}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def click_visually(self, context_id: str, description: str,
                             screenshot: bool = True) -> Dict:
        """Click an element by visual description using CDP + vision."""
        info = self._contexts.get(context_id)
        if not info:
            raise ValueError(f"Context not found: {context_id}")
        
        try:
            # Take screenshot for vision analysis
            if screenshot:
                screenshot_bytes = await info.page.screenshot()
                screenshot_b64 = base64.b64encode(screenshot_bytes).decode()
            else:
                screenshot_b64 = None
            
            # Get page text for context
            page_text = await info.page.evaluate("document.body.innerText")
            
            # Use CDP to find clickable elements
            clickable_elements = await info.cdp_session.send("DOM.querySelectorAll", {
                "selector": "a, button, input[type=button], input[type=submit], [role=button], [onclick]",
            })
            
            # This would integrate with a vision model to find the right element
            # For now, return the data for the vision tool to process
            return {
                "success": True,
                "screenshot": screenshot_b64,
                "page_text": page_text[:5000],
                "clickable_count": len(clickable_elements.get("nodeIds", [])),
                "description": description,
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def type_text(self, context_id: str, selector: str, text: str,
                        delay: int = 50) -> Dict:
        """Type text into an element."""
        info = self._contexts.get(context_id)
        if not info:
            raise ValueError(f"Context not found: {context_id}")
        
        try:
            await info.page.fill(selector, "", timeout=5000)
            await info.page.type(selector, text, delay=delay)
            return {"success": True}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def get_text(self, context_id: str, selector: str = "body") -> Dict:
        """Get text content from page or element."""
        info = self._contexts.get(context_id)
        if not info:
            raise ValueError(f"Context not found: {context_id}")
        
        try:
            text = await info.page.locator(selector).inner_text()
            return {"success": True, "text": text}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def screenshot(self, context_id: str, full_page: bool = True,
                         path: str = None) -> Dict:
        """Take a screenshot."""
        info = self._contexts.get(context_id)
        if not info:
            raise ValueError(f"Context not found: {context_id}")
        
        try:
            if path is None:
                path = str(SCREENSHOT_DIR / f"screenshot_{context_id}_{int(time.time())}.png")
            
            screenshot_bytes = await info.page.screenshot(
                path=path, full_page=full_page
            )
            screenshot_b64 = base64.b64encode(screenshot_bytes).decode()
            return {"success": True, "path": path, "base64": screenshot_b64}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def evaluate(self, context_id: str, script: str) -> Dict:
        """Evaluate JavaScript in the page context."""
        info = self._contexts.get(context_id)
        if not info:
            raise ValueError(f"Context not found: {context_id}")
        
        try:
            result = await info.page.evaluate(script)
            return {"success": True, "result": result}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def get_console_logs(self, context_id: str) -> List[Dict]:
        """Get browser console logs."""
        info = self._contexts.get(context_id)
        if not info:
            return []
        # Would need to set up console listener
        return []

    async def close_context(self, context_id: str) -> bool:
        """Close and remove a context."""
        async with self._lock:
            info = self._contexts.pop(context_id, None)
            if info:
                try:
                    await info.page.close()
                    await info.context.close()
                    return True
                except Exception:
                    pass
        return False

    async def recycle_context(self, context_id: str) -> BrowserContextInfo:
        """Recycle a context (close page, create new one)."""
        async with self._lock:
            info = self._contexts.get(context_id)
            if not info:
                raise ValueError(f"Context not found: {context_id}")
            
            await info.page.close()
            page = await info.context.new_page()
            cdp_session = await info.context.new_cdp_session(page)
            await cdp_session.send("Page.enable")
            await cdp_session.send("Runtime.enable")
            await cdp_session.send("DOM.enable")
            
            info.page = page
            info.cdp_session = cdp_session
            info.last_used = time.time()
            return info

    async def _cleanup_loop(self) -> None:
        """Periodic cleanup of idle contexts."""
        while True:
            await asyncio.sleep(300)  # Every 5 minutes
            try:
                async with self._lock:
                    now = time.time()
                    to_remove = []
                    for ctx_id, info in self._contexts.items():
                        if not info.in_use and now - info.last_used > 600:  # 10 min idle
                            if len(self._contexts) > 2:  # Keep minimum 2
                                to_remove.append(ctx_id)
                    
                    for ctx_id in to_remove:
                        info = self._contexts.pop(ctx_id)
                        try:
                            await info.page.close()
                            await info.context.close()
                        except Exception:
                            pass
            except Exception:
                pass

    async def get_status(self) -> Dict:
        """Get pool status."""
        async with self._lock:
            return {
                "total_contexts": len(self._contexts),
                "max_contexts": self.max_contexts,
                "in_use": sum(1 for c in self._contexts.values() if c.in_use),
                "available": sum(1 for c in self._contexts.values() if not c.in_use),
                "contexts": [
                    {
                        "context_id": c.context_id,
                        "in_use": c.in_use,
                        "viewport": c.viewport,
                        "mobile": c.metadata.get("mobile", False),
                        "created_at": c.created_at,
                        "last_used": c.last_used,
                    }
                    for c in self._contexts.values()
                ],
            }

    async def shutdown(self) -> None:
        """Shutdown the browser pool."""
        if self._cleanup_task:
            self._cleanup_task.cancel()
            try:
                await self._cleanup_task
            except asyncio.CancelledError:
                pass
        
        async with self._lock:
            for info in self._contexts.values():
                try:
                    await info.page.close()
                    await info.context.close()
                except Exception:
                    pass
            self._contexts.clear()
        
        if self._browser:
            await self._browser.close()
        if self._playwright:
            await self._playwright.stop()
        self._initialized = False


# Module singleton
_browser_pool: Optional[BrowserPool] = None


def get_browser_pool(**kwargs) -> BrowserPool:
    global _browser_pool
    if _browser_pool is None:
        _browser_pool = BrowserPool(**kwargs)
    return _browser_pool


async def init_browser_pool(**kwargs) -> BrowserPool:
    pool = get_browser_pool(**kwargs)
    await pool.initialize()
    return pool