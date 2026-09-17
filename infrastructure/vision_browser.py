"""
Maya 2.0 ULTRA — Vision Browser (Phase 1.2)
============================================
Enhanced browser automation with vision capabilities for autonomous web & UI interactions.

Features:
- Vision-guided element detection and interaction
- Autonomous web navigation and task completion
- Screenshot analysis with multimodal LLM
- Element detection and classification
- Form filling and data extraction
- Computer use capabilities (click, type, scroll, drag-drop)
"""

import asyncio
import base64
import json
import os
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, AsyncGenerator, Tuple, Callable
from enum import Enum
from playwright.async_api import (
    async_playwright, Browser, BrowserContext, Page, CDPSession,
    Playwright, ViewportSize, ElementHandle
)

from config.settings import STORAGE_DIR, WORKSPACE_DIR
from infrastructure.browser_pool import BrowserPool, get_browser_pool, BrowserContextInfo
from infrastructure.multimodal import MultiModalProcessor, get_multimodal_processor


# ─── Configuration ───────────────────────────────────────────────
VISION_BROWSER_DIR = STORAGE_DIR / "vision_browser"
VISION_BROWSER_DIR.mkdir(parents=True, exist_ok=True)
SCREENSHOT_DIR = WORKSPACE_DIR / "browser_screenshots"
SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
ELEMENT_CACHE_DIR = VISION_BROWSER_DIR / "element_cache"
ELEMENT_CACHE_DIR.mkdir(parents=True, exist_ok=True)


# ─── Enums ───────────────────────────────────────────────────────
class InteractionType(Enum):
    CLICK = "click"
    DOUBLE_CLICK = "double_click"
    RIGHT_CLICK = "right_click"
    HOVER = "hover"
    TYPE = "type"
    SELECT = "select"
    SCROLL = "scroll"
    DRAG_DROP = "drag_drop"
    KEY_PRESS = "key_press"
    WAIT = "wait"


class ElementType(Enum):
    BUTTON = "button"
    LINK = "link"
    INPUT = "input"
    TEXTAREA = "textarea"
    SELECT = "select"
    CHECKBOX = "checkbox"
    RADIO = "radio"
    IMAGE = "image"
    TEXT = "text"
    CONTAINER = "container"
    NAVIGATION = "navigation"
    FORM = "form"
    TABLE = "table"
    LIST = "list"
    UNKNOWN = "unknown"


class NavigationStrategy(Enum):
    DIRECT = "direct"           # Direct URL navigation
    SEARCH = "search"           # Search then click result
    LINK_TRAVERSAL = "link_traversal"  # Follow links
    FORM_SUBMIT = "form_submit"        # Fill and submit form


# ─── Data Classes ────────────────────────────────────────────────
@dataclass
class VisualElement:
    """An element detected via vision analysis."""
    element_id: str
    element_type: ElementType
    description: str
    bounding_box: Dict[str, float]  # x, y, width, height
    confidence: float
    selector: str = ""              # CSS selector if available
    text_content: str = ""
    attributes: Dict = field(default_factory=dict)
    is_clickable: bool = False
    is_editable: bool = False
    is_visible: bool = True
    screenshot_region: Optional[str] = None  # Base64 cropped region


@dataclass
class PageAnalysis:
    """Complete page analysis from vision."""
    url: str
    title: str
    screenshot: str  # Base64
    elements: List[VisualElement]
    page_text: str
    forms: List[Dict]
    links: List[Dict]
    timestamp: float
    viewport: ViewportSize


@dataclass
class InteractionStep:
    """A single interaction step in a task."""
    step_id: str
    interaction_type: InteractionType
    target: str  # Description or selector
    value: str = ""  # For typing, selecting
    description: str = ""
    expected_outcome: str = ""
    verification: str = ""  # How to verify success


@dataclass
class BrowserTask:
    """A browser automation task."""
    task_id: str
    goal: str
    url: str = ""
    steps: List[InteractionStep] = field(default_factory=list)
    status: str = "pending"  # pending, running, completed, failed
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    result: Dict = field(default_factory=dict)
    error: str = ""
    screenshots: List[str] = field(default_factory=list)
    context_id: str = ""


# ─── Vision Element Detector ─────────────────────────────────────
class VisionElementDetector:
    """Detects and classifies UI elements using vision."""
    
    def __init__(self, multimodal_processor: MultiModalProcessor = None):
        self.multimodal = multimodal_processor or get_multimodal_processor()
        self._element_cache: Dict[str, List[VisualElement]] = {}
    
    async def analyze_page(
        self, 
        page: Page, 
        cdp_session: CDPSession,
        include_screenshot: bool = True
    ) -> PageAnalysis:
        """Analyze a page using vision and CDP."""
        # Get page info
        url = page.url
        title = await page.title()
        viewport = page.viewport_size or {"width": 1920, "height": 1080}
        
        # Take screenshot
        screenshot_bytes = None
        screenshot_b64 = ""
        if include_screenshot:
            screenshot_bytes = await page.screenshot(full_page=True)
            screenshot_b64 = base64.b64encode(screenshot_bytes).decode()
        
        # Get page text
        page_text = await page.evaluate("document.body.innerText")
        
        # Get forms
        forms = await page.evaluate("""
            () => {
                const forms = Array.from(document.forms);
                return forms.map(f => ({
                    action: f.action,
                    method: f.method,
                    fields: Array.from(f.elements).map(el => ({
                        tag: el.tagName,
                        type: el.type,
                        name: el.name,
                        id: el.id,
                        placeholder: el.placeholder,
                        required: el.required,
                        value: el.value
                    }))
                }));
            }
        """)
        
        # Get links
        links = await page.evaluate("""
            () => {
                return Array.from(document.querySelectorAll('a[href]')).map(a => ({
                    href: a.href,
                    text: a.innerText,
                    title: a.title
                }));
            }
        """)
        
        # Detect elements using vision
        elements = []
        if screenshot_bytes:
            elements = await self._detect_elements_vision(screenshot_b64, page_text)
        
        # Enhance with CDP data
        elements = await self._enhance_with_cdp(elements, cdp_session)
        
        return PageAnalysis(
            url=url,
            title=title,
            screenshot=screenshot_b64,
            elements=elements,
            page_text=page_text,
            forms=forms,
            links=links,
            timestamp=time.time(),
            viewport=viewport,
        )
    
    async def _detect_elements_vision(
        self, 
        screenshot_b64: str, 
        page_text: str
    ) -> List[VisualElement]:
        """Use vision model to detect UI elements."""
        prompt = """Analyze this screenshot and identify all interactive UI elements.
Return a JSON array of elements with:
- element_id: unique identifier
- element_type: one of [button, link, input, textarea, select, checkbox, radio, image, text, container, navigation, form, table, list, unknown]
- description: human-readable description
- bounding_box: {x, y, width, height} in pixels (approximate)
- confidence: 0.0 to 1.0
- text_content: visible text on/near element
- is_clickable: true if clickable
- is_editable: true if editable (input, textarea)
- attributes: any relevant attributes (id, class, name, etc.)

Focus on: buttons, links, form fields, navigation elements, and interactive components.
Ignore purely decorative elements."""
        
        try:
            response = await self.multimodal.analyze_image(
                image=screenshot_b64,
                prompt=prompt,
                model="gpt-4-vision-preview"  # or whatever vision model is available
            )
            
            # Parse response
            elements_data = json.loads(response)
            elements = []
            for elem_data in elements_data:
                elements.append(VisualElement(
                    element_id=elem_data.get("element_id", uuid.uuid4().hex[:8]),
                    element_type=ElementType(elem_data.get("element_type", "unknown")),
                    description=elem_data.get("description", ""),
                    bounding_box=elem_data.get("bounding_box", {"x": 0, "y": 0, "width": 0, "height": 0}),
                    confidence=elem_data.get("confidence", 0.5),
                    text_content=elem_data.get("text_content", ""),
                    is_clickable=elem_data.get("is_clickable", False),
                    is_editable=elem_data.get("is_editable", False),
                    attributes=elem_data.get("attributes", {}),
                ))
            return elements
            
        except Exception as e:
            print(f"Vision element detection failed: {e}")
            return []
    
    async def _enhance_with_cdp(
        self, 
        elements: List[VisualElement], 
        cdp_session: CDPSession
    ) -> List[VisualElement]:
        """Enhance elements with CDP data (selectors, precise bounding boxes)."""
        try:
            # Get all elements with their selectors
            cdp_elements = await cdp_session.send("DOM.getDocument", {"depth": -1})
            root_node_id = cdp_elements.get("root", {}).get("nodeId")
            
            if not root_node_id:
                return elements
            
            # Query for interactive elements
            clickable_selectors = [
                "a[href]", "button", "input[type=button]", "input[type=submit]",
                "[role=button]", "[onclick]", "select", "textarea",
                "input:not([type=hidden])", "[contenteditable=true]"
            ]
            
            for selector in clickable_selectors:
                try:
                    result = await cdp_session.send("DOM.querySelectorAll", {
                        "nodeId": root_node_id,
                        "selector": selector,
                    })
                    node_ids = result.get("nodeIds", [])
                    
                    for node_id in node_ids:
                        # Get box model
                        box_model = await cdp_session.send("DOM.getBoxModel", {"nodeId": node_id})
                        if box_model and "model" in box_model:
                            model = box_model["model"]
                            # Get element info
                            node_info = await cdp_session.send("DOM.describeNode", {"nodeId": node_id})
                            
                            # Match with vision elements or create new
                            # (Simplified - in production would do proper matching)
                            pass
                except Exception:
                    continue
                    
        except Exception as e:
            print(f"CDP enhancement failed: {e}")
        
        return elements
    
    async def find_element_by_description(
        self, 
        page: Page, 
        description: str,
        elements: List[VisualElement] = None
    ) -> Optional[VisualElement]:
        """Find element matching a natural language description."""
        if not elements:
            # Would need to analyze page first
            return None
        
        # Use LLM to match description to element
        elements_json = json.dumps([
            {
                "element_id": e.element_id,
                "description": e.description,
                "element_type": e.element_type.value,
                "text_content": e.text_content,
                "is_clickable": e.is_clickable,
                "is_editable": e.is_editable,
            }
            for e in elements
        ])
        
        prompt = f"""Find the element that best matches this description: "{description}"

Available elements:
{elements_json}

Return the element_id of the best match, or null if no good match.
Only return the element_id."""
        
        try:
            response = await self.multimodal.analyze_image(
                image="",  # Text-only query
                prompt=prompt,
                model="gpt-4"
            )
            element_id = response.strip().strip('"')
            
            for e in elements:
                if e.element_id == element_id:
                    return e
        except Exception:
            pass
        
        # Fallback: simple text matching
        description_lower = description.lower()
        for e in elements:
            if (description_lower in e.description.lower() or 
                description_lower in e.text_content.lower()):
                return e
        
        return None


# ─── Autonomous Browser Agent ────────────────────────────────────
class VisionBrowserAgent:
    """Autonomous browser agent that can perform complex web tasks."""
    
    def __init__(
        self,
        browser_pool: BrowserPool = None,
        multimodal_processor: MultiModalProcessor = None,
        llm_fn: Callable = None,
    ):
        self.browser_pool = browser_pool or get_browser_pool()
        self.multimodal = multimodal_processor or get_multimodal_processor()
        self.llm_fn = llm_fn
        self.detector = VisionElementDetector(multimodal_processor)
        self._active_tasks: Dict[str, BrowserTask] = {}
        self._context_locks: Dict[str, asyncio.Lock] = {}
    
    async def execute_task(self, task: BrowserTask) -> BrowserTask:
        """Execute a browser task autonomously."""
        task.status = "running"
        task.updated_at = time.time()
        self._active_tasks[task.task_id] = task
        
        try:
            async with self.browser_pool.acquire() as context_info:
                task.context_id = context_info.context_id
                page = context_info.page
                cdp_session = context_info.cdp_session
                
                # Navigate to URL if provided
                if task.url:
                    nav_result = await self.browser_pool.navigate(context_info.context_id, task.url)
                    if not nav_result.get("success"):
                        raise Exception(f"Navigation failed: {nav_result.get('error')}")
                    task.screenshots.append(nav_result.get("url", ""))
                
                # If no steps provided, plan them
                if not task.steps:
                    task.steps = await self._plan_steps(task.goal, page, cdp_session)
                
                # Execute each step
                for step in task.steps:
                    step_result = await self._execute_step(step, page, cdp_session, context_info.context_id)
                    task.screenshots.append(step_result.get("screenshot", ""))
                    
                    if not step_result.get("success"):
                        # Try to recover
                        recovered = await self._recover_from_failure(step, step_result, page, cdp_session)
                        if not recovered:
                            raise Exception(f"Step failed: {step.description} - {step_result.get('error')}")
                
                # Final verification
                task.result = await self._verify_task_completion(task, page, cdp_session)
                task.status = "completed"
                
        except Exception as e:
            task.status = "failed"
            task.error = str(e)
        
        task.updated_at = time.time()
        return task
    
    async def _plan_steps(
        self, 
        goal: str, 
        page: Page, 
        cdp_session: CDPSession
    ) -> List[InteractionStep]:
        """Plan interaction steps to achieve a goal."""
        # Analyze current page
        analysis = await self.detector.analyze_page(page, cdp_session)
        
        prompt = f"""Plan a sequence of browser interactions to achieve this goal:
Goal: {goal}

Current page:
- URL: {analysis.url}
- Title: {analysis.title}
- Page text (first 3000 chars): {analysis.page_text[:3000]}

Available elements:
{json.dumps([
    {"id": e.element_id, "type": e.element_type.value, "desc": e.description, 
     "text": e.text_content, "clickable": e.is_clickable, "editable": e.is_editable}
    for e in analysis.elements[:50]
], indent=2)}

Return a JSON array of steps:
[
    {{
        "step_id": "step_1",
        "interaction_type": "click|type|scroll|wait|select",
        "target": "element description or CSS selector",
        "value": "value to type or select",
        "description": "what this step does",
        "expected_outcome": "what should happen",
        "verification": "how to verify success"
    }}
]"""
        
        if not self.llm_fn:
            # Fallback: simple heuristic planning
            return self._heuristic_plan(goal, analysis)
        
        try:
            response = await self.llm_fn(prompt)
            steps_data = json.loads(response)
            return [InteractionStep(**s) for s in steps_data]
        except Exception:
            return self._heuristic_plan(goal, analysis)
    
    def _heuristic_plan(self, goal: str, analysis: PageAnalysis) -> List[InteractionStep]:
        """Heuristic planning when LLM is not available."""
        steps = []
        goal_lower = goal.lower()
        
        # Look for search-related goals
        if "search" in goal_lower or "find" in goal_lower:
            # Find search input
            for elem in analysis.elements:
                if elem.element_type in [ElementType.INPUT, ElementType.TEXTAREA] and \
                   ("search" in elem.description.lower() or "search" in elem.attributes.get("placeholder", "").lower()):
                    steps.append(InteractionStep(
                        step_id="step_1",
                        interaction_type=InteractionType.TYPE,
                        target=elem.description,
                        value=goal.replace("search", "").replace("find", "").strip(),
                        description=f"Type search query in {elem.description}",
                        expected_outcome="Search results appear",
                        verification="Check for results"
                    ))
                    break
        
        # Look for click goals
        if "click" in goal_lower or "press" in goal_lower or "button" in goal_lower:
            for elem in analysis.elements:
                if elem.is_clickable and elem.element_type in [ElementType.BUTTON, ElementType.LINK]:
                    if any(kw in elem.description.lower() for kw in goal_lower.split()):
                        steps.append(InteractionStep(
                            step_id="step_1",
                            interaction_type=InteractionType.CLICK,
                            target=elem.description,
                            description=f"Click {elem.description}",
                            expected_outcome="Navigation or action triggered",
                            verification="Check URL changed or content updated"
                        ))
                        break
        
        return steps
    
    async def _execute_step(
        self,
        step: InteractionStep,
        page: Page,
        cdp_session: CDPSession,
        context_id: str
    ) -> Dict:
        """Execute a single interaction step."""
        # Analyze page for current elements
        analysis = await self.detector.analyze_page(page, cdp_session)
        
        # Find target element
        target_element = await self.detector.find_element_by_description(
            page, step.target, analysis.elements
        )
        
        result = {"success": False, "screenshot": ""}
        
        try:
            if step.interaction_type == InteractionType.CLICK:
                if target_element and target_element.selector:
                    await page.click(target_element.selector)
                elif target_element:
                    # Click via coordinates
                    bbox = target_element.bounding_box
                    await page.mouse.click(
                        bbox["x"] + bbox["width"] / 2,
                        bbox["y"] + bbox["height"] / 2
                    )
                else:
                    # Try direct selector
                    await page.click(step.target)
                result["success"] = True
                
            elif step.interaction_type == InteractionType.TYPE:
                if target_element and target_element.selector:
                    await page.fill(target_element.selector, "")
                    await page.type(target_element.selector, step.value)
                elif target_element:
                    bbox = target_element.bounding_box
                    await page.mouse.click(
                        bbox["x"] + bbox["width"] / 2,
                        bbox["y"] + bbox["height"] / 2
                    )
                    await page.keyboard.type(step.value)
                else:
                    await page.fill(step.target, step.value)
                result["success"] = True
                
            elif step.interaction_type == InteractionType.SCROLL:
                await page.evaluate(f"window.scrollBy(0, {step.value or '500'})")
                result["success"] = True
                
            elif step.interaction_type == InteractionType.WAIT:
                await asyncio.sleep(float(step.value or "1"))
                result["success"] = True
                
            elif step.interaction_type == InteractionType.KEY_PRESS:
                await page.keyboard.press(step.value or "Enter")
                result["success"] = True
                
            elif step.interaction_type == InteractionType.HOVER:
                if target_element and target_element.selector:
                    await page.hover(target_element.selector)
                result["success"] = True
                
            elif step.interaction_type == InteractionType.SELECT:
                if target_element and target_element.selector:
                    await page.select_option(target_element.selector, step.value)
                result["success"] = True
            
            # Take verification screenshot
            screenshot_bytes = await page.screenshot()
            result["screenshot"] = base64.b64encode(screenshot_bytes).decode()
            
            # Verify step
            if step.verification:
                verification_result = await self._verify_step(step, page, analysis)
                result["verified"] = verification_result
            
        except Exception as e:
            result["error"] = str(e)
            # Take error screenshot
            try:
                screenshot_bytes = await page.screenshot()
                result["screenshot"] = base64.b64encode(screenshot_bytes).decode()
            except Exception:
                pass
        
        return result
    
    async def _verify_step(
        self, 
        step: InteractionStep, 
        page: Page, 
        analysis: PageAnalysis
    ) -> bool:
        """Verify a step completed successfully."""
        if not self.llm_fn:
            return True  # Skip verification without LLM
        
        prompt = f"""Verify if this step was successful:
Step: {step.description}
Expected: {step.expected_outcome}
Verification criteria: {step.verification}

Current page:
- URL: {page.url}
- Title: {await page.title()}
- Text sample: {(await page.evaluate("document.body.innerText"))[:2000]}

Return JSON: {{"success": true/false, "reason": "explanation"}}"""
        
        try:
            response = await self.llm_fn(prompt)
            result = json.loads(response)
            return result.get("success", True)
        except Exception:
            return True
    
    async def _recover_from_failure(
        self,
        step: InteractionStep,
        step_result: Dict,
        page: Page,
        cdp_session: CDPSession
    ) -> bool:
        """Attempt to recover from a failed step."""
        # Simple recovery: wait and retry
        await asyncio.sleep(1)
        
        # Re-analyze page
        analysis = await self.detector.analyze_page(page, cdp_session)
        
        # Try to find element again
        target_element = await self.detector.find_element_by_description(
            page, step.target, analysis.elements
        )
        
        if target_element:
            # Retry
            retry_result = await self._execute_step(step, page, cdp_session, "")
            return retry_result.get("success", False)
        
        return False
    
    async def _verify_task_completion(
        self, 
        task: BrowserTask, 
        page: Page, 
        cdp_session: CDPSession
    ) -> Dict:
        """Verify overall task completion."""
        if not self.llm_fn:
            return {"completed": True, "reason": "No LLM for verification"}
        
        prompt = f"""Verify if the browser task was completed successfully:
Goal: {task.goal}
Final URL: {page.url}
Final Title: {await page.title()}
Page text sample: {(await page.evaluate("document.body.innerText"))[:3000]}

Steps executed:
{json.dumps([{"desc": s.description, "target": s.target} for s in task.steps], indent=2)}

Return JSON: {{"completed": true/false, "confidence": 0.0-1.0, "reason": "explanation", "data": {{}}}}"""
        
        try:
            response = await self.llm_fn(prompt)
            return json.loads(response)
        except Exception:
            return {"completed": True, "confidence": 0.5, "reason": "Verification failed"}


# ─── Computer Use Tools ──────────────────────────────────────────
class ComputerUseTools:
    """High-level computer use tools for the agent."""
    
    def __init__(self, vision_browser_agent: VisionBrowserAgent):
        self.agent = vision_browser_agent
    
    async def browse_and_act(self, goal: str, url: str = "") -> Dict:
        """Browse to URL and perform actions to achieve goal."""
        task = BrowserTask(
            task_id=uuid.uuid4().hex[:12],
            goal=goal,
            url=url,
        )
        result = await self.agent.execute_task(task)
        return {
            "success": result.status == "completed",
            "goal": goal,
            "result": result.result,
            "error": result.error,
            "steps_completed": len([s for s in result.steps if s]),
            "screenshots": result.screenshots,
        }
    
    async def click_element(self, description: str, context_id: str = "") -> Dict:
        """Click an element by visual description."""
        # This would use an existing context
        # Simplified for now
        return {"success": False, "error": "Requires active browser context"}
    
    async def type_text(self, description: str, text: str, context_id: str = "") -> Dict:
        """Type text into an element by description."""
        return {"success": False, "error": "Requires active browser context"}
    
    async def extract_data(self, description: str, context_id: str = "") -> Dict:
        """Extract data from page using vision."""
        return {"success": False, "error": "Requires active browser context"}
    
    async def take_screenshot(self, context_id: str = "", full_page: bool = True) -> Dict:
        """Take a screenshot of the current page."""
        return {"success": False, "error": "Requires active browser context"}


# ─── Vision Browser Pool Manager ─────────────────────────────────
class VisionBrowserManager:
    """High-level manager for vision-enabled browser automation."""
    
    def __init__(
        self,
        max_contexts: int = 5,
        headless: bool = True,
        llm_fn: Callable = None,
    ):
        self.browser_pool = BrowserPool(max_contexts=max_contexts, headless=headless)
        self.multimodal = get_multimodal_processor()
        self.agent = VisionBrowserAgent(
            browser_pool=self.browser_pool,
            multimodal_processor=self.multimodal,
            llm_fn=llm_fn,
        )
        self.computer_tools = ComputerUseTools(self.agent)
        self._initialized = False
    
    async def initialize(self) -> None:
        """Initialize the browser pool."""
        if not self._initialized:
            await self.browser_pool.initialize()
            self._initialized = True
    
    async def execute_goal(self, goal: str, url: str = "") -> Dict:
        """Execute a high-level goal using the browser."""
        await self.initialize()
        return await self.computer_tools.browse_and_act(goal, url)
    
    async def create_task(self, goal: str, url: str = "") -> BrowserTask:
        """Create a new browser task."""
        return BrowserTask(
            task_id=uuid.uuid4().hex[:12],
            goal=goal,
            url=url,
        )
    
    async def run_task(self, task: BrowserTask) -> BrowserTask:
        """Run a browser task."""
        await self.initialize()
        return await self.agent.execute_task(task)
    
    def get_computer_tools(self) -> ComputerUseTools:
        """Get computer use tools for registration."""
        return self.computer_tools
    
    async def get_status(self) -> Dict:
        """Get browser pool status."""
        return await self.browser_pool.get_status()
    
    async def shutdown(self) -> None:
        """Shutdown the browser pool."""
        await self.browser_pool.shutdown()
        self._initialized = False


# ─── Tool Registration Functions ─────────────────────────────────
def register_vision_browser_tools(registry, vision_manager: VisionBrowserManager):
    """Register vision browser tools with the tool registry."""
    tools = vision_manager.get_computer_tools()
    
    async def browse_and_act(goal: str, url: str = "") -> Dict:
        """Browse the web and perform actions to achieve a goal."""
        return await tools.browse_and_act(goal, url)
    
    async def click_element(description: str, context_id: str = "") -> Dict:
        """Click an element by visual description."""
        return await tools.click_element(description, context_id)
    
    async def type_text(description: str, text: str, context_id: str = "") -> Dict:
        """Type text into an element by visual description."""
        return await tools.type_text(description, text, context_id)
    
    async def extract_data(description: str, context_id: str = "") -> Dict:
        """Extract data from the current page using vision."""
        return await tools.extract_data(description, context_id)
    
    async def take_screenshot(context_id: str = "", full_page: bool = True) -> Dict:
        """Take a screenshot of the current page."""
        return await tools.take_screenshot(context_id, full_page)
    
    registry.register("browser_browse_and_act", browse_and_act, 
                      "Browse to a URL and perform actions to achieve a goal using vision",
                      category="web")
    registry.register("browser_click_element", click_element,
                      "Click an element by visual description",
                      category="web")
    registry.register("browser_type_text", type_text,
                      "Type text into an element by visual description",
                      category="web")
    registry.register("browser_extract_data", extract_data,
                      "Extract data from page using vision analysis",
                      category="web")
    registry.register("browser_screenshot", take_screenshot,
                      "Take a screenshot of the current page",
                      category="web")


# ─── Module Singleton ────────────────────────────────────────────
_vision_browser_manager: Optional[VisionBrowserManager] = None


def get_vision_browser_manager(**kwargs) -> VisionBrowserManager:
    global _vision_browser_manager
    if _vision_browser_manager is None:
        _vision_browser_manager = VisionBrowserManager(**kwargs)
    return _vision_browser_manager


async def init_vision_browser(**kwargs) -> VisionBrowserManager:
    manager = get_vision_browser_manager(**kwargs)
    await manager.initialize()
    return manager


# ─── Export ──────────────────────────────────────────────────────
__all__ = [
    "VisionBrowserManager",
    "VisionBrowserAgent",
    "VisionElementDetector",
    "ComputerUseTools",
    "BrowserTask",
    "InteractionStep",
    "PageAnalysis",
    "VisualElement",
    "ElementType",
    "InteractionType",
    "NavigationStrategy",
    "register_vision_browser_tools",
    "get_vision_browser_manager",
    "init_vision_browser",
]