"""
Maya 2.0 ULTRA — Dynamic Tool Creation Framework (Phase 1.1)
=============================================================
Self-evolution loop: Agent codes, tests, and dynamically imports missing tools at runtime.

Features:
- AST-based safety validation with comprehensive blocked patterns
- Sandbox execution for testing (gVisor/Firecracker/native)
- Dynamic tool loading with hot-reloading support
- Versioning and rollback capabilities
- Integration with capability registry and tool manager
"""

import ast
import asyncio
import hashlib
import importlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
from enum import Enum

from config.settings import STORAGE_DIR, WORKSPACE_DIR
from infrastructure.capability_registry import (
    Capability, CapabilityInterface, CapabilityMetadata, 
    CapabilityType, CapabilityStatus, get_capability_registry
)
from infrastructure.sandbox_executor import SandboxExecutor, SandboxConfig, ExecutionResult
from tools.system.tool_creator import scan_risk

# ─── Configuration ───────────────────────────────────────────────
DYNAMIC_TOOLS_DIR = STORAGE_DIR / "dynamic_tools"
DYNAMIC_TOOLS_DIR.mkdir(parents=True, exist_ok=True)
DYNAMIC_TOOLS_DB = str(DYNAMIC_TOOLS_DIR / "dynamic_tools.db")
DYNAMIC_TOOL_CODE_DIR = DYNAMIC_TOOLS_DIR / "code"
DYNAMIC_TOOL_CODE_DIR.mkdir(parents=True, exist_ok=True)
DYNAMIC_TOOL_TEST_DIR = DYNAMIC_TOOLS_DIR / "tests"
DYNAMIC_TOOL_TEST_DIR.mkdir(parents=True, exist_ok=True)

# ─── Enums ───────────────────────────────────────────────────────
class ToolCreationStatus(Enum):
    PENDING = "pending"
    VALIDATING = "validating"
    TESTING = "testing"
    REGISTERING = "registering"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class SafetyLevel(Enum):
    STRICT = "strict"      # Block all potentially dangerous operations
    MODERATE = "moderate"  # Allow common operations, block only critical ones
    PERMISSIVE = "permissive"  # Minimal blocking, rely on sandbox


# ─── Data Classes ────────────────────────────────────────────────
@dataclass
class DynamicToolSpec:
    """Specification for a dynamically created tool."""
    name: str
    description: str
    code: str
    entry_point: str = "execute"
    parameters: Dict = field(default_factory=dict)
    returns: Dict = field(default_factory=dict)
    category: str = "dynamic"
    tags: List[str] = field(default_factory=list)
    dependencies: List[str] = field(default_factory=list)
    version: str = "1.0.0"
    author: str = "maya_dynamic"
    safety_level: SafetyLevel = SafetyLevel.MODERATE
    test_cases: List[Dict] = field(default_factory=list)
    metadata: Dict = field(default_factory=dict)


@dataclass
class ToolValidationResult:
    """Result of tool validation."""
    valid: bool
    issues: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    ast_check: bool = True
    syntax_check: bool = True
    safety_check: bool = True
    import_check: bool = True


@dataclass
class ToolTestResult:
    """Result of tool testing in sandbox."""
    success: bool
    test_results: List[Dict] = field(default_factory=list)
    execution_time_ms: float = 0
    memory_used_mb: float = 0
    error: str = ""
    stdout: str = ""
    stderr: str = ""
    artifacts: List[str] = field(default_factory=list)


@dataclass
class DynamicToolRecord:
    """Record of a dynamically created tool."""
    id: str
    spec: DynamicToolSpec
    status: ToolCreationStatus = ToolCreationStatus.PENDING
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    validation_result: Optional[ToolValidationResult] = None
    test_result: Optional[ToolTestResult] = None
    capability_id: Optional[str] = None
    version_history: List[Dict] = field(default_factory=list)
    rollback_version: Optional[str] = None
    error: str = ""
    metadata: Dict = field(default_factory=dict)


# ─── Safety Scanner ──────────────────────────────────────────────
class EnhancedSafetyScanner:
    """Enhanced AST-based safety scanner for dynamic tool code."""
    
    # Extended blocked calls - more comprehensive
    BLOCKED_CALLS = {
        # System/OS operations
        "os.system", "os.popen", "os.execv", "os.execve", "os.execl", "os.execlp", "os.execle", "os.execvp", "os.execvpe",
        "os.remove", "os.unlink", "os.rmdir", "os.removedirs", "os.rename", "os.replace",
        "os.mkdir", "os.makedirs", "os.chmod", "os.chown", "os.chroot",
        "os.fork", "os.kill", "os.killpg", "os.nice", "os.setpgrp",
        # Subprocess
        "subprocess.run", "subprocess.Popen", "subprocess.call", "subprocess.check_call",
        "subprocess.check_output", "subprocess.getstatusoutput", "subprocess.getoutput",
        # Eval/Exec
        "eval", "exec", "compile", "__import__",
        # File operations
        "shutil.rmtree", "shutil.move", "shutil.copy", "shutil.copy2", "shutil.copytree",
        # Network
        "socket.socket", "socket.create_connection", "socket.getaddrinfo",
        "urllib.request.urlopen", "urllib.request.Request",
        "http.client.HTTPConnection", "http.client.HTTPSConnection",
        "requests.get", "requests.post", "requests.put", "requests.delete", "requests.request",
        # ctypes/ffi
        "ctypes.CDLL", "ctypes.LoadLibrary", "ctypes.windll", "ctypes.cdll",
        # Dynamic code
        "importlib.import_module", "importlib.util.spec_from_loader",
        # Pickle/marshal
        "pickle.loads", "pickle.load", "marshal.loads", "marshal.load",
        # Threading/async
        "threading.Thread", "multiprocessing.Process", "asyncio.run", "asyncio.create_task",
    }
    
    BLOCKED_MODULES = {
        "subprocess", "socket", "ctypes", "shutil", "pty", "ftplib", "telnetlib", 
        "smtplib", "http", "urllib", "requests", "pickle", "marshal", "threading",
        "multiprocessing", "asyncio", "importlib", "pkgutil", "runpy",
        "sys", "os", "builtins", "types", "inspect", "gc", "weakref",
    }
    
    BLOCKED_ATTRIBUTES = {
        "__globals__", "__locals__", "__code__", "__closure__", "__defaults__",
        "__dict__", "__class__", "__bases__", "__mro__", "__subclasses__",
    }
    
    ALLOWED_MODULES = {
        "json", "re", "math", "random", "datetime", "time", "uuid", "hashlib",
        "base64", "collections", "itertools", "functools", "operator", "statistics",
        "decimal", "fractions", "string", "textwrap", "html", "xml", "csv",
        "pathlib", "typing", "dataclasses", "enum", "pydantic", "numpy", "pandas",
    }

    def __init__(self, safety_level: SafetyLevel = SafetyLevel.MODERATE):
        self.safety_level = safety_level
        self._blocked_calls = self.BLOCKED_CALLS.copy()
        self._blocked_modules = self.BLOCKED_MODULES.copy()
        self._blocked_attributes = self.BLOCKED_ATTRIBUTES.copy()
        self._allowed_modules = self.ALLOWED_MODULES.copy()
        
        if safety_level == SafetyLevel.PERMISSIVE:
            # Remove some restrictions for permissive mode
            self._blocked_calls -= {"os.mkdir", "os.makedirs", "os.remove", "os.unlink"}
            self._blocked_modules -= {"os", "pathlib"}
        elif safety_level == SafetyLevel.STRICT:
            # Add more restrictions for strict mode
            self._blocked_calls.update({"open", "print", "input", "exit", "quit"})
            self._blocked_modules.update({"pathlib", "tempfile", "io"})

    def scan(self, code: str) -> ToolValidationResult:
        """Scan code for safety issues."""
        result = ToolValidationResult(valid=True)
        
        # Syntax check
        try:
            tree = ast.parse(code)
        except SyntaxError as e:
            result.valid = False
            result.syntax_check = False
            result.issues.append(f"Syntax error: {e}")
            return result
        
        # AST walk for safety checks
        for node in ast.walk(tree):
            # Check imports
            if isinstance(node, ast.Import):
                for alias in node.names:
                    top = alias.name.split(".")[0]
                    if top in self._blocked_modules:
                        result.valid = False
                        result.safety_check = False
                        result.issues.append(f"Blocked import: {alias.name}")
                    elif top not in self._allowed_modules and self.safety_level == SafetyLevel.STRICT:
                        result.warnings.append(f"Non-standard import: {alias.name}")
            
            elif isinstance(node, ast.ImportFrom):
                module = (node.module or "").split(".")[0]
                if module in self._blocked_modules:
                    result.valid = False
                    result.safety_check = False
                    result.issues.append(f"Blocked import from: {node.module}")
                elif module not in self._allowed_modules and self.safety_level == SafetyLevel.STRICT:
                    result.warnings.append(f"Non-standard import from: {node.module}")
            
            # Check function calls
            elif isinstance(node, ast.Call):
                call_name = self._get_call_name(node)
                if call_name and call_name in self._blocked_calls:
                    result.valid = False
                    result.safety_check = False
                    result.issues.append(f"Blocked function call: {call_name}")
            
            # Check attribute access
            elif isinstance(node, ast.Attribute):
                if node.attr in self._blocked_attributes:
                    result.valid = False
                    result.safety_check = False
                    result.issues.append(f"Blocked attribute access: {node.attr}")
            
            # Check for dangerous patterns
            if isinstance(node, ast.Lambda):
                result.warnings.append("Lambda functions detected - ensure they don't capture sensitive data")
            
            if isinstance(node, ast.Yield) or isinstance(node, ast.YieldFrom):
                result.warnings.append("Generator detected - ensure proper resource cleanup")
        
        # Additional heuristic checks
        self._heuristic_checks(code, tree, result)
        
        return result
    
    def _get_call_name(self, node: ast.Call) -> Optional[str]:
        """Extract the full name of a function call."""
        func = node.func
        if isinstance(func, ast.Name):
            return func.id
        elif isinstance(func, ast.Attribute):
            if isinstance(func.value, ast.Name):
                return f"{func.value.id}.{func.attr}"
            elif isinstance(func.value, ast.Attribute):
                if isinstance(func.value.value, ast.Name):
                    return f"{func.value.value.id}.{func.value.attr}.{func.attr}"
        return None
    
    def _heuristic_checks(self, code: str, tree: ast.AST, result: ToolValidationResult) -> None:
        """Additional heuristic safety checks."""
        # Check for obfuscation patterns
        if "eval(" in code and "compile(" in code:
            result.warnings.append("Possible code obfuscation: eval + compile combination")
        
        # Check for base64 encoded payloads
        import base64
        try:
            # Look for long base64 strings
            import re
            b64_matches = re.findall(r'[A-Za-z0-9+/]{100,}={0,2}', code)
            for match in b64_matches:
                try:
                    decoded = base64.b64decode(match).decode('utf-8', errors='ignore')
                    if any(kw in decoded.lower() for kw in ['import', 'exec', 'eval', 'system', 'subprocess']):
                        result.warnings.append("Suspicious base64 encoded content detected")
                        break
                except Exception:
                    pass
        except Exception:
            pass
        
        # Check for file operations on sensitive paths
        sensitive_paths = ["/etc/", "/root/", "/home/", "/var/", "/usr/bin", "/bin/", "/sbin/"]
        for path in sensitive_paths:
            if path in code:
                result.warnings.append(f"Reference to sensitive path: {path}")
        
        # Check for environment variable access
        if "os.environ" in code or "os.getenv" in code:
            result.warnings.append("Environment variable access detected")


# ─── Sandbox Test Runner ─────────────────────────────────────────
class DynamicToolTestRunner:
    """Runs dynamic tool code in sandbox for validation."""
    
    def __init__(self, sandbox_config: Optional[SandboxConfig] = None):
        self.sandbox = SandboxExecutor(sandbox_config or SandboxConfig(
            runtime="native",  # Use native for speed, can be overridden
            timeout_seconds=30,
            memory_limit_mb=512,
            network_enabled=False,
            filesystem_read_only=True,
        ))
    
    async def run_tests(
        self, 
        tool_spec: DynamicToolSpec, 
        test_cases: List[Dict] = None
    ) -> ToolTestResult:
        """Run tool code with test cases in sandbox."""
        start_time = time.time()
        test_cases = test_cases or tool_spec.test_cases
        
        # Create test harness
        test_code = self._create_test_harness(tool_spec, test_cases)
        
        # Execute in sandbox
        result = await self.sandbox.execute(
            code=test_code,
            language="python",
            config=self.sandbox.config
        )
        
        execution_time = (time.time() - start_time) * 1000
        
        # Parse test results
        test_results = []
        if result.success:
            try:
                # Look for test results in stdout
                stdout = result.stdout
                if "__TEST_RESULTS__" in stdout:
                    results_json = stdout.split("__TEST_RESULTS__")[1].split("__TEST_RESULTS_END__")[0].strip()
                    test_results = json.loads(results_json)
            except Exception:
                pass
        
        return ToolTestResult(
            success=result.success,
            test_results=test_results,
            execution_time_ms=execution_time,
            error=result.error,
            stdout=result.stdout,
            stderr=result.stderr,
            artifacts=result.artifacts,
        )
    
    def _create_test_harness(self, tool_spec: DynamicToolSpec, test_cases: List[Dict]) -> str:
        """Create a test harness for the tool."""
        harness = f'''
import json
import sys
import traceback

# Tool code
{tool_spec.code}

# Test runner
__test_results__ = []
test_cases = {json.dumps(test_cases)}

# Get the entry point function
entry_point = "{tool_spec.entry_point}"
if entry_point not in globals():
    print(f"Entry point '{{entry_point}}' not found")
    sys.exit(1)

func = globals()[entry_point]

for i, test_case in enumerate(test_cases):
    test_input = test_case.get("input", {{}})
    expected = test_case.get("expected", None)
    test_name = test_case.get("name", f"test_{{i}}")
    
    try:
        result = func(**test_input)
        passed = True
        error = None
        
        if expected is not None:
            if isinstance(expected, dict):
                # Deep comparison for dicts
                import json
                passed = json.dumps(result, sort_keys=True) == json.dumps(expected, sort_keys=True)
            else:
                passed = result == expected
        
        __test_results__.append({{
            "name": test_name,
            "passed": passed,
            "input": test_input,
            "expected": expected,
            "actual": result,
            "error": error
        }})
    except Exception as e:
        __test_results__.append({{
            "name": test_name,
            "passed": False,
            "input": test_input,
            "expected": expected,
            "actual": None,
            "error": str(e),
            "traceback": traceback.format_exc()
        }})

print("__TEST_RESULTS__")
print(json.dumps(__test_results__))
print("__TEST_RESULTS_END__")
'''
        return harness


# ─── Dynamic Tool Loader ─────────────────────────────────────────
class DynamicToolLoader:
    """Loads and manages dynamically created tools with hot-reloading."""
    
    def __init__(self, tool_manager=None):
        self.tool_manager = tool_manager
        self._loaded_modules: Dict[str, Any] = {}
        self._tool_functions: Dict[str, Callable] = {}
        self._tool_specs: Dict[str, DynamicToolSpec] = {}
        self._file_watchers: Dict[str, float] = {}  # path -> mtime
    
    def load_tool(self, tool_record: DynamicToolRecord) -> bool:
        """Load a dynamic tool from its record."""
        try:
            spec = tool_record.spec
            tool_id = tool_record.id
            
            # Write code to file
            code_file = DYNAMIC_TOOL_CODE_DIR / f"{tool_id}.py"
            code_file.write_text(spec.code)
            
            # Create module spec
            module_name = f"dynamic_tool_{tool_id}"
            spec_obj = importlib.util.spec_from_file_location(module_name, code_file)
            if spec_obj is None or spec_obj.loader is None:
                raise ImportError(f"Could not load module from {code_file}")
            
            module = importlib.util.module_from_spec(spec_obj)
            sys.modules[module_name] = module
            spec_obj.loader.exec_module(module)
            
            # Get the entry point function
            entry_point = spec.entry_point
            if not hasattr(module, entry_point):
                raise AttributeError(f"Entry point '{entry_point}' not found in module")
            
            func = getattr(module, entry_point)
            
            # Store references
            self._loaded_modules[tool_id] = module
            self._tool_functions[tool_id] = func
            self._tool_specs[tool_id] = spec
            self._file_watchers[str(code_file)] = code_file.stat().st_mtime
            
            # Register with tool manager if available
            if self.tool_manager:
                self._register_with_tool_manager(tool_id, func, spec)
            
            return True
            
        except Exception as e:
            print(f"Failed to load dynamic tool {tool_record.id}: {e}")
            return False
    
    def _register_with_tool_manager(self, tool_id: str, func: Callable, spec: DynamicToolSpec) -> None:
        """Register the tool with the tool manager's registry."""
        if self.tool_manager and hasattr(self.tool_manager, 'registry'):
            # Create a wrapper that handles the tool calling convention
            def tool_wrapper(**kwargs):
                return func(**kwargs)
            
            tool_wrapper.__name__ = spec.name
            tool_wrapper.__doc__ = spec.description
            
            self.tool_manager.registry.register(
                spec.name,
                tool_wrapper,
                spec.description,
                category=spec.category
            )
    
    def unload_tool(self, tool_id: str) -> bool:
        """Unload a dynamic tool."""
        try:
            # Remove from tool manager
            if self.tool_manager and hasattr(self.tool_manager, 'registry'):
                spec = self._tool_specs.get(tool_id)
                if spec:
                    self.tool_manager.registry.unregister(spec.name)
            
            # Remove module from sys.modules
            module_name = f"dynamic_tool_{tool_id}"
            if module_name in sys.modules:
                del sys.modules[module_name]
            
            # Clean up references
            self._loaded_modules.pop(tool_id, None)
            self._tool_functions.pop(tool_id, None)
            self._tool_specs.pop(tool_id, None)
            
            # Remove code file
            code_file = DYNAMIC_TOOL_CODE_DIR / f"{tool_id}.py"
            if code_file.exists():
                code_file.unlink()
            
            return True
        except Exception as e:
            print(f"Failed to unload dynamic tool {tool_id}: {e}")
            return False
    
    def reload_tool(self, tool_record: DynamicToolRecord) -> bool:
        """Hot-reload a dynamic tool."""
        tool_id = tool_record.id
        code_file = DYNAMIC_TOOL_CODE_DIR / f"{tool_id}.py"
        
        # Check if file was modified
        if code_file.exists():
            current_mtime = code_file.stat().st_mtime
            last_mtime = self._file_watchers.get(str(code_file), 0)
            if current_mtime <= last_mtime:
                return True  # No changes
        
        # Unload and reload
        self.unload_tool(tool_id)
        return self.load_tool(tool_record)
    
    def get_tool_function(self, tool_id: str) -> Optional[Callable]:
        """Get the loaded tool function."""
        return self._tool_functions.get(tool_id)
    
    def get_tool_spec(self, tool_id: str) -> Optional[DynamicToolSpec]:
        """Get the tool specification."""
        return self._tool_specs.get(tool_id)
    
    def list_loaded_tools(self) -> List[str]:
        """List all loaded tool IDs."""
        return list(self._tool_functions.keys())


# ─── Dynamic Tool Manager ────────────────────────────────────────
class DynamicToolManager:
    """
    Main manager for dynamic tool creation, validation, testing, and deployment.
    Implements the self-evolution loop: create → validate → test → register.
    """
    
    def __init__(
        self,
        tool_manager=None,
        capability_registry=None,
        llm_fn: Optional[Callable] = None,
        approval_manager=None,
        default_safety_level: SafetyLevel = SafetyLevel.MODERATE,
    ):
        self.tool_manager = tool_manager
        self.capability_registry = capability_registry or get_capability_registry()
        self.llm_fn = llm_fn
        self.approval_manager = approval_manager
        self.default_safety_level = default_safety_level
        
        self.scanner = EnhancedSafetyScanner(default_safety_level)
        self.test_runner = DynamicToolTestRunner()
        self.loader = DynamicToolLoader(tool_manager)
        
        self._records: Dict[str, DynamicToolRecord] = {}
        self._init_db()
        self._load_records()
    
    def _init_db(self) -> None:
        import sqlite3
        with sqlite3.connect(DYNAMIC_TOOLS_DB, check_same_thread=False) as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS dynamic_tools (
                    id TEXT PRIMARY KEY,
                    spec TEXT NOT NULL,
                    status TEXT NOT NULL,
                    created_at REAL,
                    updated_at REAL,
                    validation_result TEXT,
                    test_result TEXT,
                    capability_id TEXT,
                    version_history TEXT DEFAULT '[]',
                    rollback_version TEXT,
                    error TEXT DEFAULT '',
                    metadata TEXT DEFAULT '{}'
                )
            """)
            c.execute("CREATE INDEX IF NOT EXISTS idx_tool_status ON dynamic_tools(status)")
            c.execute("CREATE INDEX IF NOT EXISTS idx_tool_name ON dynamic_tools(spec)")
    
    def _load_records(self) -> None:
        import sqlite3
        with sqlite3.connect(DYNAMIC_TOOLS_DB, check_same_thread=False) as c:
            c.row_factory = sqlite3.Row
            rows = c.execute("SELECT * FROM dynamic_tools WHERE status != 'rolled_back'").fetchall()
            for row in rows:
                spec_dict = json.loads(row["spec"])
                spec = DynamicToolSpec(**spec_dict)
                
                validation = None
                if row["validation_result"]:
                    v_data = json.loads(row["validation_result"])
                    validation = ToolValidationResult(**v_data)
                
                test_result = None
                if row["test_result"]:
                    t_data = json.loads(row["test_result"])
                    test_result = ToolTestResult(**t_data)
                
                record = DynamicToolRecord(
                    id=row["id"],
                    spec=spec,
                    status=ToolCreationStatus(row["status"]),
                    created_at=row["created_at"],
                    updated_at=row["updated_at"],
                    validation_result=validation,
                    test_result=test_result,
                    capability_id=row["capability_id"],
                    version_history=json.loads(row["version_history"]),
                    rollback_version=row["rollback_version"],
                    error=row["error"],
                    metadata=json.loads(row["metadata"]),
                )
                self._records[record.id] = record
                
                # Load active tools
                if record.status == ToolCreationStatus.COMPLETED:
                    self.loader.load_tool(record)
    
    def _save_record(self, record: DynamicToolRecord) -> None:
        import sqlite3
        record.updated_at = time.time()
        with sqlite3.connect(DYNAMIC_TOOLS_DB, check_same_thread=False) as c:
            c.execute("""
                INSERT OR REPLACE INTO dynamic_tools
                (id, spec, status, created_at, updated_at,
                 validation_result, test_result, capability_id,
                 version_history, rollback_version, error, metadata)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
            """, (
                record.id,
                json.dumps(record.spec.__dict__),
                record.status.value,
                record.created_at,
                record.updated_at,
                json.dumps(record.validation_result.__dict__) if record.validation_result else None,
                json.dumps(record.test_result.__dict__) if record.test_result else None,
                record.capability_id,
                json.dumps(record.version_history),
                record.rollback_version,
                record.error,
                json.dumps(record.metadata),
            ))
    
    async def create_tool(
        self,
        name: str,
        description: str,
        code: str = "",
        requirements: str = "",
        entry_point: str = "execute",
        category: str = "dynamic",
        tags: List[str] = None,
        test_cases: List[Dict] = None,
        safety_level: SafetyLevel = None,
        auto_test: bool = True,
        auto_register: bool = True,
    ) -> DynamicToolRecord:
        """
        Create a new dynamic tool. If code is not provided, generate it using LLM.
        Returns the tool record with status.
        """
        tool_id = uuid.uuid4().hex[:12]
        
        # Generate code if not provided
        if not code and self.llm_fn:
            code = await self._generate_tool_code(name, description, requirements, entry_point)
        
        if not code:
            raise ValueError("Tool code is required (provide code or enable LLM generation)")
        
        # Create spec
        spec = DynamicToolSpec(
            name=name,
            description=description,
            code=code,
            entry_point=entry_point,
            category=category,
            tags=tags or [],
            test_cases=test_cases or [],
            safety_level=safety_level or self.default_safety_level,
        )
        
        # Create record
        record = DynamicToolRecord(
            id=tool_id,
            spec=spec,
            status=ToolCreationStatus.PENDING,
        )
        self._records[tool_id] = record
        self._save_record(record)
        
        # Run creation pipeline
        try:
            # Step 1: Validate
            record.status = ToolCreationStatus.VALIDATING
            self._save_record(record)
            validation_result = await self._validate_tool(record)
            record.validation_result = validation_result
            
            if not validation_result.valid:
                record.status = ToolCreationStatus.FAILED
                record.error = "; ".join(validation_result.issues)
                self._save_record(record)
                return record
            
            # Step 2: Test in sandbox
            if auto_test:
                record.status = ToolCreationStatus.TESTING
                self._save_record(record)
                test_result = await self.test_runner.run_tests(spec, test_cases)
                record.test_result = test_result
                
                if not test_result.success:
                    record.status = ToolCreationStatus.FAILED
                    record.error = f"Tests failed: {test_result.error}"
                    self._save_record(record)
                    return record
            
            # Step 3: Register (with approval if needed)
            if auto_register:
                record.status = ToolCreationStatus.REGISTERING
                self._save_record(record)
                await self._register_tool(record)
            
            record.status = ToolCreationStatus.COMPLETED
            record.error = ""
            self._save_record(record)
            
            # Load the tool
            self.loader.load_tool(record)
            
        except Exception as e:
            record.status = ToolCreationStatus.FAILED
            record.error = str(e)
            self._save_record(record)
        
        return record
    
    async def _generate_tool_code(
        self,
        name: str,
        description: str,
        requirements: str,
        entry_point: str,
    ) -> str:
        """Generate tool code using LLM."""
        prompt = f"""Create a Python tool function named '{entry_point}' that {description}.

Requirements: {requirements}

The tool should:
1. Be a single function named '{entry_point}' that takes keyword arguments
2. Return a JSON-serializable result
3. Include proper error handling
4. Include type hints
5. Have a comprehensive docstring
6. NOT use any blocked operations (subprocess, os.system, eval, exec, network calls, etc.)

Return ONLY the Python code for the tool function and any helper functions/classes it needs.
The code must define a function called '{entry_point}' and include a register_tools(registry) function
that registers the tool with the registry.

Example format:
```python
def execute(param1: str, param2: int = 10) -> dict:
    \"\"\"Tool description.\"\"\"
    # Implementation
    return {{"result": "success", "data": param1 * param2}}

def register_tools(registry):
    registry.register("tool_name", execute, "Tool description", category="dynamic")
```
"""
        response = await self.llm_fn(prompt)
        
        # Extract code from response
        code = response
        if "```python" in code:
            code = code.split("```python")[1].split("```")[0]
        elif "```" in code:
            code = code.split("```")[1].split("```")[0]
        
        return code.strip()
    
    async def _validate_tool(self, record: DynamicToolRecord) -> ToolValidationResult:
        """Validate tool code with safety scanner and syntax check."""
        spec = record.spec
        
        # Run enhanced safety scan
        result = self.scanner.scan(spec.code)
        
        # Also run the original scan_risk for compatibility
        original_issues = scan_risk(spec.code)
        if original_issues:
            result.valid = False
            result.safety_check = False
            result.issues.extend(original_issues)
        
        # Check for register_tools function
        if "def register_tools" not in spec.code:
            result.warnings.append("No register_tools function found - tool may not register properly")
        
        # Check entry point exists
        if f"def {spec.entry_point}" not in spec.code:
            result.valid = False
            result.issues.append(f"Entry point function '{spec.entry_point}' not found in code")
        
        return result
    
    async def _register_tool(self, record: DynamicToolRecord) -> None:
        """Register tool with capability registry and tool manager."""
        spec = record.spec
        
        # Check approval if needed
        if self.approval_manager and self.approval_manager.needs_approval(
            f"create_dynamic_tool:{spec.name}", risk_level="high"
        ):
            approved = self.approval_manager.request_approval(
                action=f"Create dynamic tool '{spec.name}'",
                reason=f"Auto-generated tool: {spec.description}",
                risk_level="high",
            )
            if not approved:
                raise PermissionError(f"Human approval denied for tool '{spec.name}'")
        
        # Register with capability registry
        interface = CapabilityInterface(
            name=spec.name,
            description=spec.description,
            input_schema={"type": "object", "properties": spec.parameters},
            output_schema={"type": "object", "properties": spec.returns},
            parameters=spec.parameters,
            returns=spec.returns,
        )
        
        metadata = CapabilityMetadata(
            capability_type=CapabilityType.TOOL,
            domain_tags=spec.tags,
            version=spec.version,
            author=spec.author,
            verification_status=CapabilityStatus.VERIFIED if record.test_result and record.test_result.success else CapabilityStatus.TESTING,
            provenance={
                "created_by": "dynamic_tool_framework",
                "tool_id": record.id,
                "generation_method": "llm" if self.llm_fn else "manual",
                "test_passed": record.test_result.success if record.test_result else False,
            },
            source_code_hash=hashlib.sha256(spec.code.encode()).hexdigest(),
            test_cases=spec.test_cases,
        )
        
        capability = Capability(
            id=record.id,
            name=spec.name,
            interface=interface,
            metadata=metadata,
            implementation=spec.code,
            entry_point=spec.entry_point,
            config={"category": spec.category, "tags": spec.tags},
        )
        
        capability_id = self.capability_registry.register(capability)
        record.capability_id = capability_id
        
        # Save version for rollback
        record.version_history.append({
            "version": spec.version,
            "code_hash": metadata.source_code_hash,
            "timestamp": time.time(),
            "capability_id": capability_id,
        })
        record.rollback_version = spec.version
    
    def get_tool(self, tool_id: str) -> Optional[DynamicToolRecord]:
        """Get a tool record by ID."""
        return self._records.get(tool_id)
    
    def get_tool_by_name(self, name: str) -> Optional[DynamicToolRecord]:
        """Get a tool record by name (latest version)."""
        for record in self._records.values():
            if record.spec.name == name and record.status == ToolCreationStatus.COMPLETED:
                return record
        return None
    
    def list_tools(self, status: Optional[ToolCreationStatus] = None) -> List[DynamicToolRecord]:
        """List all tools, optionally filtered by status."""
        tools = list(self._records.values())
        if status:
            tools = [t for t in tools if t.status == status]
        return sorted(tools, key=lambda x: x.created_at, reverse=True)
    
    async def update_tool(
        self,
        tool_id: str,
        code: str = None,
        version: str = None,
        test_cases: List[Dict] = None,
    ) -> DynamicToolRecord:
        """Update an existing dynamic tool (creates new version)."""
        record = self._records.get(tool_id)
        if not record:
            raise ValueError(f"Tool {tool_id} not found")
        
        # Save current version for rollback
        old_code = record.spec.code
        old_version = record.spec.version
        
        # Create new version
        new_version = version or self._increment_version(old_version)
        new_code = code or record.spec.code
        new_test_cases = test_cases or record.spec.test_cases
        
        # Create updated spec
        new_spec = DynamicToolSpec(
            name=record.spec.name,
            description=record.spec.description,
            code=new_code,
            entry_point=record.spec.entry_point,
            parameters=record.spec.parameters,
            returns=record.spec.returns,
            category=record.spec.category,
            tags=record.spec.tags,
            dependencies=record.spec.dependencies,
            version=new_version,
            author=record.spec.author,
            safety_level=record.spec.safety_level,
            test_cases=new_test_cases,
            metadata=record.spec.metadata,
        )
        
        # Create new record for new version
        new_id = uuid.uuid4().hex[:12]
        new_record = DynamicToolRecord(
            id=new_id,
            spec=new_spec,
            status=ToolCreationStatus.PENDING,
            metadata={"previous_version": tool_id, "previous_code_hash": hashlib.sha256(old_code.encode()).hexdigest()},
        )
        self._records[new_id] = new_record
        self._save_record(new_record)
        
        # Validate and test
        new_record.status = ToolCreationStatus.VALIDATING
        self._save_record(new_record)
        validation = await self._validate_tool(new_record)
        new_record.validation_result = validation
        
        if not validation.valid:
            new_record.status = ToolCreationStatus.FAILED
            new_record.error = "; ".join(validation.issues)
            self._save_record(new_record)
            return new_record
        
        new_record.status = ToolCreationStatus.TESTING
        self._save_record(new_record)
        test_result = await self.test_runner.run_tests(new_spec, new_test_cases)
        new_record.test_result = test_result
        
        if not test_result.success:
            new_record.status = ToolCreationStatus.FAILED
            new_record.error = f"Tests failed: {test_result.error}"
            self._save_record(new_record)
            return new_record
        
        # Register new version
        new_record.status = ToolCreationStatus.REGISTERING
        self._save_record(new_record)
        await self._register_tool(new_record)
        
        # Unload old version, load new
        self.loader.unload_tool(tool_id)
        self.loader.load_tool(new_record)
        
        new_record.status = ToolCreationStatus.COMPLETED
        self._save_record(new_record)
        
        # Mark old record as rolled back
        record.status = ToolCreationStatus.ROLLED_BACK
        record.rollback_version = new_version
        self._save_record(record)
        
        return new_record
    
    def rollback_tool(self, tool_id: str) -> bool:
        """Rollback a tool to its previous version."""
        record = self._records.get(tool_id)
        if not record or not record.rollback_version:
            return False
        
        # Find the previous version
        prev_record = None
        for r in self._records.values():
            if r.metadata.get("previous_version") == tool_id and r.spec.version == record.rollback_version:
                prev_record = r
                break
        
        if not prev_record:
            return False
        
        # Unload current, load previous
        self.loader.unload_tool(tool_id)
        self.loader.load_tool(prev_record)
        
        # Update status
        record.status = ToolCreationStatus.ROLLED_BACK
        prev_record.status = ToolCreationStatus.COMPLETED
        self._save_record(record)
        self._save_record(prev_record)
        
        return True
    
    def delete_tool(self, tool_id: str) -> bool:
        """Delete a dynamic tool completely."""
        record = self._records.get(tool_id)
        if not record:
            return False
        
        # Unload
        self.loader.unload_tool(tool_id)
        
        # Remove from capability registry
        if record.capability_id:
            self.capability_registry.unregister(record.capability_id)
        
        # Mark as failed
        record.status = ToolCreationStatus.FAILED
        record.error = "Deleted by user"
        self._save_record(record)
        
        return True
    
    def _increment_version(self, version: str) -> str:
        """Increment version string (semver-like)."""
        parts = version.split(".")
        if len(parts) >= 3:
            try:
                patch = int(parts[2]) + 1
                return f"{parts[0]}.{parts[1]}.{patch}"
            except ValueError:
                pass
        return version + ".1"
    
    def get_stats(self) -> Dict:
        """Get statistics about dynamic tools."""
        total = len(self._records)
        by_status = {}
        for status in ToolCreationStatus:
            by_status[status.value] = sum(1 for r in self._records.values() if r.status == status)
        
        loaded = len(self.loader.list_loaded_tools())
        
        return {
            "total_tools": total,
            "by_status": by_status,
            "loaded_tools": loaded,
            "capability_registry_size": len(self.capability_registry._capabilities) if self.capability_registry else 0,
        }


# ─── Integration Functions ───────────────────────────────────────
async def create_dynamic_tool_from_goal(
    goal: str,
    dynamic_tool_manager: DynamicToolManager,
    context: Dict = None,
) -> DynamicToolRecord:
    """
    High-level function to create a tool from a natural language goal.
    Uses LLM to analyze the goal and generate appropriate tool specification.
    """
    if not dynamic_tool_manager.llm_fn:
        raise ValueError("LLM function required for goal-based tool creation")
    
    # Analyze goal to extract tool specification
    analysis_prompt = f"""Analyze this goal and design a tool specification:

Goal: {goal}
Context: {json.dumps(context or {})}

Return a JSON object with:
{{
    "name": "tool_name_snake_case",
    "description": "What the tool does",
    "entry_point": "execute",
    "parameters": {{"param1": {{"type": "string", "description": "..."}}}},
    "returns": {{"type": "object", "properties": {{"result": {{"type": "string"}}}}}},
    "category": "dynamic",
    "tags": ["tag1", "tag2"],
    "test_cases": [
        {{"name": "basic_test", "input": {{"param1": "test"}}, "expected": {{"result": "expected_output"}}}}
    ],
    "requirements": "Detailed requirements for code generation"
}}
"""
    analysis = await dynamic_tool_manager.llm_fn(analysis_prompt)
    
    try:
        spec_dict = json.loads(analysis)
    except json.JSONDecodeError:
        # Try to extract JSON from response
        import re
        match = re.search(r'\{.*\}', analysis, re.DOTALL)
        if match:
            spec_dict = json.loads(match.group())
        else:
            raise ValueError("Could not parse tool specification from LLM response")
    
    # Create the tool
    return await dynamic_tool_manager.create_tool(
        name=spec_dict["name"],
        description=spec_dict["description"],
        entry_point=spec_dict.get("entry_point", "execute"),
        category=spec_dict.get("category", "dynamic"),
        tags=spec_dict.get("tags", []),
        test_cases=spec_dict.get("test_cases", []),
        requirements=spec_dict.get("requirements", ""),
    )


# ─── Export ──────────────────────────────────────────────────────
__all__ = [
    "DynamicToolManager",
    "DynamicToolLoader",
    "DynamicToolTestRunner",
    "EnhancedSafetyScanner",
    "DynamicToolSpec",
    "DynamicToolRecord",
    "ToolValidationResult",
    "ToolTestResult",
    "ToolCreationStatus",
    "SafetyLevel",
    "create_dynamic_tool_from_goal",
    "DYNAMIC_TOOLS_DIR",
    "DYNAMIC_TOOLS_DB",
]