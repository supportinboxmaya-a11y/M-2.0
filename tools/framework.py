"""Maya 3.0 — Phase 5 Tool Framework.

Wraps EXISTING tools (or any callable) with the five spec guarantees:
Permission · Logging · Timeout · Retry · Validation.
The original ToolRegistry stays untouched; this is an additive layer.
"""
import concurrent.futures
import time


class ToolPolicy:
    """Per-tool execution policy."""

    def __init__(self, category: str = "general", timeout_s: float = 30.0,
                 retries: int = 1, dangerous: bool = False,
                 validate_fn=None):
        self.category = category          # permission category (web/code/file/shell/…)
        self.timeout_s = timeout_s
        self.retries = max(1, retries)    # total attempts
        self.dangerous = dangerous        # needs explicit approval flag
        self.validate_fn = validate_fn    # callable(inputs) -> error str | None


class ManagedTool:
    def __init__(self, name: str, fn, policy: ToolPolicy | None = None,
                 description: str = "", logger=None, metrics=None):
        self.name = name
        self.fn = fn
        self.policy = policy or ToolPolicy()
        self.description = description
        self._log = logger or (lambda msg: print(f"[tool:{name}] {msg}"))
        self._metrics = metrics

    def execute(self, inputs: dict | None = None,
                caller_permissions: tuple = (), approved: bool = False) -> dict:
        """Run with the five guarantees. Never raises; returns a result dict."""
        inputs = inputs or {}
        t0 = time.time()

        # 1. Permission (never bypassed)
        if self.policy.category not in caller_permissions and "*" not in caller_permissions:
            return self._fail("permission denied "
                              f"(needs '{self.policy.category}')", t0, 0)
        if self.policy.dangerous and not approved:
            return self._fail("dangerous tool requires approved=True", t0, 0)

        # 2. Validation
        if self.policy.validate_fn:
            try:
                err = self.policy.validate_fn(inputs)
            except Exception as e:
                err = f"validator crashed: {e}"
            if err:
                return self._fail(f"validation failed: {err}", t0, 0)

        # 3–5. Retry loop with timeout and logging
        last_err = None
        for attempt in range(1, self.policy.retries + 1):
            try:
                with concurrent.futures.ThreadPoolExecutor(max_workers=1) as ex:
                    fut = ex.submit(self.fn, inputs)
                    output = fut.result(timeout=self.policy.timeout_s)
                elapsed = round(time.time() - t0, 3)
                self._log(f"ok in {elapsed}s (attempt {attempt})")
                if self._metrics:
                    self._metrics.incr(f"tool.{self.name}.ok")
                    self._metrics.observe(f"tool.{self.name}", elapsed)
                return {"ok": True, "output": output, "error": None,
                        "elapsed": elapsed, "attempts": attempt}
            except concurrent.futures.TimeoutError:
                last_err = f"timeout after {self.policy.timeout_s}s"
            except Exception as e:
                last_err = str(e)
            self._log(f"attempt {attempt} failed: {last_err}")
            if attempt < self.policy.retries:
                time.sleep(min(2.0, 0.2 * (2 ** (attempt - 1))))
        return self._fail(last_err or "unknown error", t0, self.policy.retries)

    def _fail(self, error: str, t0: float, attempts: int) -> dict:
        if self._metrics:
            self._metrics.incr(f"tool.{self.name}.fail")
        self._log(f"FAILED: {error}")
        return {"ok": False, "output": None, "error": error,
                "elapsed": round(time.time() - t0, 3), "attempts": attempts}


# Spec category taxonomy -> permission category used by agents
CATEGORY_MAP = {
    "development": "code", "git": "shell", "github": "web", "docker": "shell",
    "terminal": "shell", "filesystem": "file", "python": "code",
    "browser": "web", "database": "code", "cloud": "web", "vision": "media",
    "ocr": "media", "speech": "media", "image_generation": "media",
    "pdf": "file", "office": "file", "web": "web", "general": "code",
}


class ToolFramework:
    def __init__(self, logger=None, metrics=None):
        self._tools: dict[str, ManagedTool] = {}
        self._logger = logger
        self._metrics = metrics

    def register(self, name: str, fn, policy: ToolPolicy | None = None,
                 description: str = "") -> ManagedTool:
        mt = ManagedTool(name, fn, policy, description,
                         logger=self._logger, metrics=self._metrics)
        self._tools[name] = mt
        return mt

    def execute(self, name: str, inputs: dict | None = None,
                caller_permissions: tuple = (), approved: bool = False) -> dict:
        mt = self._tools.get(name)
        if mt is None:
            return {"ok": False, "output": None,
                    "error": f"unknown tool '{name}'", "elapsed": 0, "attempts": 0}
        return mt.execute(inputs, caller_permissions, approved)

    def list(self) -> list:
        return [{"name": t.name, "description": t.description,
                 "category": t.policy.category, "timeout_s": t.policy.timeout_s,
                 "retries": t.policy.retries, "dangerous": t.policy.dangerous}
                for t in self._tools.values()]

    def adopt_existing(self, registry, default_timeout: float = 60.0,
                       dangerous_categories: tuple = ("shell",)) -> int:
        """Wrap every tool in the existing ToolRegistry with managed policies."""
        count = 0
        for name in registry.tool_names():
            raw_cat = (registry._categories.get(name, "general") or "general").lower()
            cat = CATEGORY_MAP.get(raw_cat, raw_cat)
            desc = registry._descriptions.get(name, "")
            fn = registry._tools[name]
            self.register(name, fn, ToolPolicy(
                category=cat, timeout_s=default_timeout, retries=2,
                dangerous=cat in dangerous_categories), desc)
            count += 1
        return count
