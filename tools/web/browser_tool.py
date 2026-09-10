"""
Maya 2.0 - Browser Automation Tool (Playwright Async Native)
-------------------------------------------------------------
Real browser control using native async Playwright API.
Designed to work natively within FastAPI's async event loop.
"""
import os
import asyncio
from config.settings import WORKSPACE_DIR

try:
    from playwright.async_api import async_playwright
    _PLAYWRIGHT_AVAILABLE = True
except ImportError:
    _PLAYWRIGHT_AVAILABLE = False


class BrowserTool:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)
        self._playwright = None
        self._browser = None
        self._context = None
        self._page = None
        self._lock = asyncio.Lock()

    async def _ensure_page(self):
        """Ensure we have a valid page, creating browser/context if needed."""
        if not _PLAYWRIGHT_AVAILABLE:
            raise RuntimeError(
                "Playwright is not installed. Add 'playwright' to requirements.txt "
                "and run 'playwright install --with-deps chromium' in the Dockerfile."
            )
        async with self._lock:
            if self._page is not None:
                try:
                    # Check if page is still valid
                    await self._page.title()
                    return self._page
                except Exception:
                    self._page = None
            
            try:
                self._playwright = await async_playwright().start()
                self._browser = await self._playwright.chromium.launch(
                    headless=True,
                    args=["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu"],
                )
                self._context = await self._browser.new_context(
                    user_agent=(
                        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
                    ),
                    viewport={"width": 1280, "height": 800},
                )
                self._page = await self._context.new_page()
                self._page.set_default_timeout(15000)
                return self._page
            except Exception as e:
                self._page = None
                self._context = None
                self._browser = None
                self._playwright = None
                raise RuntimeError(f"Could not launch browser: {e}")

    async def open(self, url: str = "", **kwargs) -> str:
        """Navigate to a URL."""
        if not url:
            return "Error: url required"
        if not url.startswith(("http://", "https://")):
            url = "https://" + url
        try:
            page = await self._ensure_page()
            await page.goto(url, wait_until="domcontentloaded")
            title = await page.title()
            return f"Opened: {url}\nTitle: {title}"
        except Exception as e:
            return f"Error opening {url}: {e}"

    async def click(self, selector: str = "", text: str = "", **kwargs) -> str:
        """Click an element by CSS selector, or by visible text if no selector given."""
        try:
            page = await self._ensure_page()
            if text and not selector:
                await page.get_by_text(text, exact=False).first.click()
                return f"Clicked element with text: {text}"
            if not selector:
                return "Error: selector or text required"
            await page.click(selector, timeout=10000)
            return f"Clicked: {selector}"
        except Exception as e:
            return f"Error clicking '{selector or text}': {e}"

    async def click_visually(self, instruction: str = "", **kwargs) -> str:
        """Click by visual description using vision model."""
        if not instruction or not instruction.strip():
            return "Error: instruction required (describe what to click)"
        try:
            page = await self._ensure_page()
            png_bytes = await page.screenshot(full_page=False)
            viewport = page.viewport_size or {"width": 1280, "height": 800}
            import base64, re
            b64 = base64.b64encode(png_bytes).decode()
            from tools.media.vision_tool import VisionTool
            prompt = (
                f"This is a screenshot of a web page, {viewport['width']}x{viewport['height']} "
                f"pixels. Find this element: {instruction.strip()}. Reply with ONLY the pixel "
                "coordinates of the CENTER of that element, in the exact format 'x,y' "
                "(e.g. '412,88'). If you can't find it, reply 'not found'. No other text."
            )
            result = VisionTool().analyze(f"data:image/png;base64,{b64}", prompt)
            if not result.get("success"):
                return f"Error: vision lookup failed — {result.get('error')}"
            coords_text = (result.get("result") or "").strip()
            match = re.search(r"(\d+)\s*,\s*(\d+)", coords_text)
            if not match:
                return f"Could not locate '{instruction}' on the page (vision reply: {coords_text!r})"
            x, y = int(match.group(1)), int(match.group(2))
            await page.mouse.click(x, y)
            return f"Clicked at ({x}, {y}) — vision-located target: {instruction}"
        except Exception as e:
            return f"Error in visual click on '{instruction}': {e}"

    async def look(self, question: str = "What's on this page?", **kwargs) -> str:
        """Screenshot and ask vision model a question."""
        try:
            page = await self._ensure_page()
            png_bytes = await page.screenshot(full_page=False)
            import base64
            b64 = base64.b64encode(png_bytes).decode()
            from tools.media.vision_tool import VisionTool
            result = VisionTool().analyze(f"data:image/png;base64,{b64}", question)
            if not result.get("success"):
                return f"Error: vision lookup failed — {result.get('error')}"
            return result.get("result", "")
        except Exception as e:
            return f"Error looking at page: {e}"

    async def type_text(self, selector: str = "", text: str = "", submit: bool = False, **kwargs) -> str:
        """Type text into an input identified by CSS selector."""
        if not selector:
            return "Error: selector required"
        try:
            page = await self._ensure_page()
            await page.fill(selector, text or "")
            if submit:
                await page.press(selector, "Enter")
            return f"Typed into {selector}"
        except Exception as e:
            return f"Error typing into '{selector}': {e}"

    async def get_text(self, selector: str = "", **kwargs) -> str:
        """Get visible text from the page or a specific element."""
        try:
            page = await self._ensure_page()
            if selector:
                el = await page.query_selector(selector)
                if not el:
                    return f"Error: element not found: {selector}"
                text = await el.inner_text()
            else:
                text = await page.inner_text("body")
            return text.strip()[:5000]
        except Exception as e:
            return f"Error getting text: {e}"

    async def screenshot(self, filename: str = "screenshot.png", **kwargs) -> str:
        """Take a screenshot of the current page, saved into the workspace."""
        try:
            page = await self._ensure_page()
            safe_name = os.path.basename(filename) or "screenshot.png"
            path = os.path.join(self.workspace, safe_name)
            await page.screenshot(path=path, full_page=False)
            return f"Screenshot saved: {safe_name}"
        except Exception as e:
            return f"Error taking screenshot: {e}"

    async def search_google(self, query: str = "", **kwargs) -> str:
        """Perform a real Google search through the browser and return top results."""
        if not query:
            return "Error: query required"
        try:
            page = await self._ensure_page()
            await page.goto(f"https://www.google.com/search?q={query}", wait_until="domcontentloaded")
            results = await page.query_selector_all("div.g")
            out = []
            for r in results[:5]:
                text = (await r.inner_text() or "").strip()
                if text:
                    out.append(text[:300])
            if not out:
                out.append((await page.inner_text("body"))[:1000])
            return "\n\n".join(out)
        except Exception as e:
            return f"Error searching Google: {e}"

    async def close(self):
        """Shut down the browser cleanly."""
        try:
            if self._context:
                await self._context.close()
            if self._browser:
                await self._browser.close()
            if self._playwright:
                await self._playwright.stop()
        except Exception:
            pass
        finally:
            self._page = None
            self._context = None
            self._browser = None
            self._playwright = None
