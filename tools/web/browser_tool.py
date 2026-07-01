"""
Maya 2.0 - Browser Automation Tool (Playwright)
------------------------------------------------
Real browser control: open pages, click, type, read text, screenshot.
Launches a single headless Chromium instance lazily (on first use) and
keeps it alive across calls so multi-step tasks stay fast.
"""
import os
from config.settings import WORKSPACE_DIR

try:
    from playwright.sync_api import sync_playwright
    _PLAYWRIGHT_AVAILABLE = True
except ImportError:
    _PLAYWRIGHT_AVAILABLE = False


class BrowserTool:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)
        self._playwright = None
        self._browser = None
        self._page = None

    def _ensure_page(self):
        if not _PLAYWRIGHT_AVAILABLE:
            raise RuntimeError(
                "Playwright is not installed. Add 'playwright' to requirements.txt "
                "and run 'playwright install --with-deps chromium' in the Dockerfile."
            )
        if self._page is not None:
            return self._page
        try:
            self._playwright = sync_playwright().start()
            self._browser = self._playwright.chromium.launch(
                headless=True,
                args=["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu"],
            )
            context = self._browser.new_context(
                user_agent=(
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
                ),
                viewport={"width": 1280, "height": 800},
            )
            self._page = context.new_page()
            self._page.set_default_timeout(15000)
            return self._page
        except Exception as e:
            self._page = None
            raise RuntimeError(f"Could not launch browser: {e}")

    def open(self, url: str = "", **kwargs) -> str:
        """Navigate to a URL."""
        if not url:
            return "Error: url required"
        if not url.startswith(("http://", "https://")):
            url = "https://" + url
        try:
            page = self._ensure_page()
            page.goto(url, wait_until="domcontentloaded")
            return f"Opened: {url}\nTitle: {page.title()}"
        except Exception as e:
            return f"Error opening {url}: {e}"

    def click(self, selector: str = "", text: str = "", **kwargs) -> str:
        """Click an element by CSS selector, or by visible text if no selector given."""
        try:
            page = self._ensure_page()
            if text and not selector:
                page.get_by_text(text, exact=False).first.click()
                return f"Clicked element with text: {text}"
            if not selector:
                return "Error: selector or text required"
            page.click(selector, timeout=10000)
            return f"Clicked: {selector}"
        except Exception as e:
            return f"Error clicking '{selector or text}': {e}"

    def type_text(self, selector: str = "", text: str = "", submit: bool = False, **kwargs) -> str:
        """Type text into an input identified by CSS selector."""
        if not selector:
            return "Error: selector required"
        try:
            page = self._ensure_page()
            page.fill(selector, text or "")
            if submit:
                page.press(selector, "Enter")
            return f"Typed into {selector}"
        except Exception as e:
            return f"Error typing into '{selector}': {e}"

    def get_text(self, selector: str = "", **kwargs) -> str:
        """Get visible text from the page or a specific element."""
        try:
            page = self._ensure_page()
            if selector:
                el = page.query_selector(selector)
                if not el:
                    return f"Error: element not found: {selector}"
                text = el.inner_text()
            else:
                text = page.inner_text("body")
            return text.strip()[:5000]
        except Exception as e:
            return f"Error getting text: {e}"

    def screenshot(self, filename: str = "screenshot.png", **kwargs) -> str:
        """Take a screenshot of the current page, saved into the workspace."""
        try:
            page = self._ensure_page()
            safe_name = os.path.basename(filename) or "screenshot.png"
            path = os.path.join(self.workspace, safe_name)
            page.screenshot(path=path, full_page=False)
            return f"Screenshot saved: {safe_name}"
        except Exception as e:
            return f"Error taking screenshot: {e}"

    def search_google(self, query: str = "", **kwargs) -> str:
        """Perform a real Google search through the browser and return top results."""
        if not query:
            return "Error: query required"
        try:
            page = self._ensure_page()
            page.goto(f"https://www.google.com/search?q={query}", wait_until="domcontentloaded")
            results = page.query_selector_all("div.g")
            out = []
            for r in results[:5]:
                text = (r.inner_text() or "").strip()
                if text:
                    out.append(text[:300])
            if not out:
                out.append(page.inner_text("body")[:1000])
            return "\n\n".join(out)
        except Exception as e:
            return f"Error searching Google: {e}"

    def close(self):
        """Shut down the browser cleanly (called on app shutdown)."""
        try:
            if self._browser:
                self._browser.close()
            if self._playwright:
                self._playwright.stop()
        except Exception:
            pass
        finally:
            self._page = None
            self._browser = None
            self._playwright = None
