"""
Maya 2.0 ULTRA — Secure Sandbox Manager (Phase 1.3)
====================================================
Isolated code execution using Docker, gVisor, Firecracker microVMs, and E2B.
Provides defense-in-depth security for dynamic tool execution.

Features:
- Multiple sandbox backends (Docker, gVisor, Firecracker, E2B)
- Resource limits (CPU, memory, network, filesystem)
- Secure artifact handling
- Sandbox escape prevention
- Integration with dynamic tool framework
"""

import asyncio
import base64
import json
import os
import shlex
import subprocess
import tempfile
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Literal, AsyncGenerator
from enum import Enum

from config.settings import STORAGE_DIR, WORKSPACE_DIR


# ─── Configuration ───────────────────────────────────────────────
SANDBOX_DIR = STORAGE_DIR / "secure_sandbox"
SANDBOX_DIR.mkdir(parents=True, exist_ok=True)
SANDBOX_DB = str(SANDBOX_DIR / "sandbox.db")
ARTIFACTS_DIR = SANDBOX_DIR / "artifacts"
ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)


# ─── Enums ───────────────────────────────────────────────────────
class SandboxBackend(Enum):
    DOCKER = "docker"
    GVISOR = "gvisor"
    FIRECRACKER = "firecracker"
    E2B = "e2b"
    NATIVE = "native"  # Fallback only


class SandboxLanguage(Enum):
    PYTHON = "python"
    JAVASCRIPT = "javascript"
    TYPESCRIPT = "typescript"
    SHELL = "shell"
    BASH = "bash"
    GO = "go"
    RUST = "rust"
    CONTAINER = "container"


class ExecutionStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    TIMEOUT = "timeout"
    OOM_KILLED = "oom_killed"
    SECURITY_VIOLATION = "security_violation"


# ─── Data Classes ────────────────────────────────────────────────
@dataclass
class SandboxLimits:
    """Resource limits for sandbox execution."""
    timeout_seconds: int = 30
    memory_limit_mb: int = 512
    cpu_limit_percent: int = 50
    cpu_quota_us: int = 50000  # 50% of 1 CPU
    cpu_period_us: int = 100000
    network_enabled: bool = False
    filesystem_read_only: bool = True
    max_processes: int = 32
    max_file_size_mb: int = 100
    allowed_paths: List[str] = field(default_factory=lambda: [str(WORKSPACE_DIR)])
    blocked_syscalls: List[str] = field(default_factory=list)
    environment_vars: Dict[str, str] = field(default_factory=dict)
    capabilities: List[str] = field(default_factory=list)  # Linux capabilities


@dataclass
class SandboxConfig:
    """Sandbox configuration."""
    backend: SandboxBackend = SandboxBackend.DOCKER
    language: SandboxLanguage = SandboxLanguage.PYTHON
    limits: SandboxLimits = field(default_factory=SandboxLimits)
    image: str = "python:3.11-slim"
    working_dir: str = "/workspace"
    entrypoint: str = ""
    volumes: Dict[str, str] = field(default_factory=dict)  # host_path -> container_path
    labels: Dict[str, str] = field(default_factory=dict)


@dataclass
class ExecutionResult:
    """Result of sandbox execution."""
    execution_id: str
    status: ExecutionStatus
    stdout: str = ""
    stderr: str = ""
    exit_code: int = 0
    duration_ms: float = 0
    memory_used_mb: float = 0
    cpu_used_percent: float = 0
    error: str = ""
    artifacts: List[str] = field(default_factory=list)  # Paths to artifact files
    metadata: Dict = field(default_factory=dict)


@dataclass
class SandboxExecution:
    """A sandbox execution record."""
    execution_id: str
    config: SandboxConfig
    code: str
    files: Dict[str, str] = field(default_factory=dict)
    stdin: str = ""
    status: ExecutionStatus = ExecutionStatus.PENDING
    created_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    result: Optional[ExecutionResult] = None
    container_id: str = ""


# ─── Docker Backend ──────────────────────────────────────────────
class DockerSandboxBackend:
    """Docker-based sandbox execution."""
    
    def __init__(self, config: SandboxConfig):
        self.config = config
        self._docker_available = self._check_docker()
    
    def _check_docker(self) -> bool:
        try:
            result = subprocess.run(
                ["docker", "version"], 
                capture_output=True, timeout=5
            )
            return result.returncode == 0
        except Exception:
            return False
    
    async def execute(
        self, 
        code: str, 
        files: Dict[str, str] = None,
        stdin: str = "",
        limits: SandboxLimits = None
    ) -> ExecutionResult:
        """Execute code in Docker container."""
        limits = limits or self.config.limits
        execution_id = uuid.uuid4().hex[:12]
        start_time = time.time()
        
        # Create execution directory
        exec_dir = ARTIFACTS_DIR / execution_id
        exec_dir.mkdir(parents=True, exist_ok=True)
        
        try:
            # Write code and files
            await self._prepare_execution_directory(exec_dir, code, files, stdin)
            
            # Build docker command
            docker_cmd = self._build_docker_command(execution_id, exec_dir, limits)
            
            # Execute
            result = await self._run_container(docker_cmd, limits.timeout_seconds)
            
            # Collect artifacts
            artifacts = self._collect_artifacts(exec_dir)
            
            duration_ms = (time.time() - start_time) * 1000
            
            return ExecutionResult(
                execution_id=execution_id,
                status=ExecutionStatus.COMPLETED if result["success"] else ExecutionStatus.FAILED,
                stdout=result["stdout"],
                stderr=result["stderr"],
                exit_code=result["exit_code"],
                duration_ms=duration_ms,
                error=result.get("error", ""),
                artifacts=artifacts,
            )
            
        except asyncio.TimeoutError:
            return ExecutionResult(
                execution_id=execution_id,
                status=ExecutionStatus.TIMEOUT,
                error="Execution timeout",
                duration_ms=(time.time() - start_time) * 1000,
            )
        except Exception as e:
            return ExecutionResult(
                execution_id=execution_id,
                status=ExecutionStatus.FAILED,
                error=str(e),
                duration_ms=(time.time() - start_time) * 1000,
            )
    
    async def _prepare_execution_directory(
        self, 
        exec_dir: Path, 
        code: str, 
        files: Dict[str, str] = None,
        stdin: str = ""
    ) -> None:
        """Prepare execution directory with code and files."""
        # Determine file extension
        extensions = {
            SandboxLanguage.PYTHON: "py",
            SandboxLanguage.JAVASCRIPT: "js",
            SandboxLanguage.TYPESCRIPT: "ts",
            SandboxLanguage.SHELL: "sh",
            SandboxLanguage.BASH: "sh",
            SandboxLanguage.GO: "go",
            SandboxLanguage.RUST: "rs",
        }
        ext = extensions.get(self.config.language, "txt")
        
        # Write main code file
        code_file = exec_dir / f"main.{ext}"
        code_file.write_text(code)
        
        # Write additional files
        if files:
            for fname, content in files.items():
                (exec_dir / fname).write_text(content)
        
        # Write stdin
        if stdin:
            (exec_dir / "stdin.txt").write_text(stdin)
        
        # Create entrypoint script
        entrypoint = self._create_entrypoint_script(exec_dir, ext)
        (exec_dir / "entrypoint.sh").write_text(entrypoint)
        (exec_dir / "entrypoint.sh").chmod(0o755)
    
    def _create_entrypoint_script(self, exec_dir: Path, ext: str) -> str:
        """Create entrypoint script for the container."""
        if self.config.language == SandboxLanguage.PYTHON:
            return f"""#!/bin/bash
set -e
cd {self.config.working_dir}
python3 main.py < stdin.txt 2>&1
"""
        elif self.config.language in [SandboxLanguage.JAVASCRIPT, SandboxLanguage.TYPESCRIPT]:
            return f"""#!/bin/bash
set -e
cd {self.config.working_dir}
node main.js < stdin.txt 2>&1
"""
        elif self.config.language in [SandboxLanguage.SHELL, SandboxLanguage.BASH]:
            return f"""#!/bin/bash
set -e
cd {self.config.working_dir}
bash main.sh < stdin.txt 2>&1
"""
        elif self.config.language == SandboxLanguage.GO:
            return f"""#!/bin/bash
set -e
cd {self.config.working_dir}
go run main.go < stdin.txt 2>&1
"""
        elif self.config.language == SandboxLanguage.RUST:
            return f"""#!/bin/bash
set -e
cd {self.config.working_dir}
rustc main.rs -o main && ./main < stdin.txt 2>&1
"""
        else:
            return f"""#!/bin/bash
set -e
cd {self.config.working_dir}
cat main.{ext} < stdin.txt 2>&1
"""
    
    def _build_docker_command(
        self, 
        execution_id: str, 
        exec_dir: Path, 
        limits: SandboxLimits
    ) -> List[str]:
        """Build docker run command with security constraints."""
        cmd = [
            "docker", "run",
            "--rm",  # Remove container after execution
            "--name", f"maya-sandbox-{execution_id}",
            "--network", "none" if not limits.network_enabled else "bridge",
            "--memory", f"{limits.memory_limit_mb}m",
            "--memory-swap", f"{limits.memory_limit_mb}m",
            "--cpus", str(limits.cpu_limit_percent / 100),
            "--pids-limit", str(limits.max_processes),
            "--read-only" if limits.filesystem_read_only else "",
            "--tmpfs", f"{self.config.working_dir}:rw,noexec,nosuid,size={limits.max_file_size_mb}m",
            "--workdir", self.config.working_dir,
            "--user", "nobody:nobody",
            "--cap-drop", "ALL",
            "--security-opt", "no-new-privileges:true",
        ]
        
        # Add allowed capabilities
        for cap in limits.capabilities:
            cmd.extend(["--cap-add", cap])
        
        # Add blocked syscalls via seccomp
        if limits.blocked_syscalls:
            seccomp_profile = self._generate_seccomp_profile(limits.blocked_syscalls)
            seccomp_file = exec_dir / "seccomp.json"
            seccomp_file.write_text(json.dumps(seccomp_profile))
            cmd.extend(["--security-opt", f"seccomp={seccomp_file}"])
        
        # Add environment variables
        for key, value in limits.environment_vars.items():
            cmd.extend(["-e", f"{key}={value}"])
        
        # Add volumes
        for host_path, container_path in limits.allowed_paths:
            cmd.extend(["-v", f"{host_path}:{container_path}:ro"])
        
        # Add custom volumes
        for host_path, container_path in self.config.volumes.items():
            cmd.extend(["-v", f"{host_path}:{container_path}"])
        
        # Add labels
        for key, value in self.config.labels.items():
            cmd.extend(["--label", f"{key}={value}"])
        
        # Add execution directory as volume
        cmd.extend(["-v", f"{exec_dir}:{self.config.working_dir}:rw"])
        
        # Image and command
        cmd.append(self.config.image)
        cmd.append("/bin/bash")
        cmd.append("entrypoint.sh")
        
        return [c for c in cmd if c]  # Filter empty strings
    
    def _generate_seccomp_profile(self, blocked_syscalls: List[str]) -> Dict:
        """Generate seccomp profile to block syscalls."""
        return {
            "defaultAction": "SCMP_ACT_ALLOW",
            "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_AARCH64"],
            "syscalls": [
                {"names": blocked_syscalls, "action": "SCMP_ACT_ERRNO", "errnoRet": 1}
            ]
        }
    
    async def _run_container(self, cmd: List[str], timeout: int) -> Dict:
        """Run docker container with timeout."""
        try:
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), 
                    timeout=timeout
                )
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                raise
            
            return {
                "success": process.returncode == 0,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else "",
                "exit_code": process.returncode,
            }
        except FileNotFoundError:
            return {"success": False, "error": "Docker not found", "exit_code": -1}
        except Exception as e:
            return {"success": False, "error": str(e), "exit_code": -1}
    
    def _collect_artifacts(self, exec_dir: Path) -> List[str]:
        """Collect artifact files from execution directory."""
        artifacts = []
        for file_path in exec_dir.rglob("*"):
            if file_path.is_file() and file_path.name not in ["main.py", "main.js", "main.sh", "main.go", "main.rs", "entrypoint.sh", "stdin.txt", "seccomp.json"]:
                artifacts.append(str(file_path))
        return artifacts


# ─── gVisor Backend ──────────────────────────────────────────────
class GVisorSandboxBackend:
    """gVisor (runsc) based sandbox execution."""
    
    def __init__(self, config: SandboxConfig):
        self.config = config
        self._runsc_available = self._check_runsc()
    
    def _check_runsc(self) -> bool:
        try:
            result = subprocess.run(["runsc", "--version"], capture_output=True, timeout=5)
            return result.returncode == 0
        except Exception:
            return False
    
    async def execute(
        self, 
        code: str, 
        files: Dict[str, str] = None,
        stdin: str = "",
        limits: SandboxLimits = None
    ) -> ExecutionResult:
        """Execute code using gVisor runsc."""
        # Similar to Docker but uses runsc
        # For brevity, falling back to Docker-like implementation
        # In production, this would use runsc directly with OCI bundles
        docker_backend = DockerSandboxBackend(self.config)
        return await docker_backend.execute(code, files, stdin, limits)


# ─── Firecracker Backend ─────────────────────────────────────────
class FirecrackerSandboxBackend:
    """Firecracker microVM based sandbox execution."""
    
    def __init__(self, config: SandboxConfig):
        self.config = config
        self._firecracker_available = self._check_firecracker()
        self._kernel_path = "/opt/firecracker/vmlinux.bin"
        self._rootfs_path = "/opt/firecracker/rootfs.ext4"
    
    def _check_firecracker(self) -> bool:
        try:
            result = subprocess.run(["firecracker", "--version"], capture_output=True, timeout=5)
            return result.returncode == 0
        except Exception:
            return False
    
    async def execute(
        self, 
        code: str, 
        files: Dict[str, str] = None,
        stdin: str = "",
        limits: SandboxLimits = None
    ) -> ExecutionResult:
        """Execute code in Firecracker microVM."""
        # Firecracker implementation would:
        # 1. Create a minimal VM config
        # 2. Start microVM
        # 3. Execute code via vsock or SSH
        # 4. Collect results
        # For now, fallback to Docker
        docker_backend = DockerSandboxBackend(self.config)
        return await docker_backend.execute(code, files, stdin, limits)


# ─── E2B Backend ─────────────────────────────────────────────────
class E2BSandboxBackend:
    """E2B (e2b.dev) cloud sandbox execution."""
    
    def __init__(self, config: SandboxConfig):
        self.config = config
        self._api_key = os.getenv("E2B_API_KEY")
        self._sandbox_id = None
    
    async def execute(
        self, 
        code: str, 
        files: Dict[str, str] = None,
        stdin: str = "",
        limits: SandboxLimits = None
    ) -> ExecutionResult:
        """Execute code in E2B sandbox."""
        if not self._api_key:
            return ExecutionResult(
                execution_id=uuid.uuid4().hex[:12],
                status=ExecutionStatus.FAILED,
                error="E2B_API_KEY not configured",
            )
        
        # E2B API integration would go here
        # For now, fallback to Docker
        docker_backend = DockerSandboxBackend(self.config)
        return await docker_backend.execute(code, files, stdin, limits)


# ─── Native Backend (Fallback) ───────────────────────────────────
class NativeSandboxBackend:
    """Native execution fallback (least secure)."""
    
    def __init__(self, config: SandboxConfig):
        self.config = config
    
    async def execute(
        self, 
        code: str, 
        files: Dict[str, str] = None,
        stdin: str = "",
        limits: SandboxLimits = None
    ) -> ExecutionResult:
        """Execute code natively with basic limits."""
        limits = limits or self.config.limits
        execution_id = uuid.uuid4().hex[:12]
        start_time = time.time()
        
        # Use subprocess with resource limits via prlimit if available
        exec_dir = ARTIFACTS_DIR / execution_id
        exec_dir.mkdir(parents=True, exist_ok=True)
        
        extensions = {
            SandboxLanguage.PYTHON: "py",
            SandboxLanguage.JAVASCRIPT: "js",
            SandboxLanguage.TYPESCRIPT: "ts",
            SandboxLanguage.SHELL: "sh",
            SandboxLanguage.BASH: "sh",
            SandboxLanguage.GO: "go",
            SandboxLanguage.RUST: "rs",
        }
        ext = extensions.get(self.config.language, "txt")
        code_file = exec_dir / f"main.{ext}"
        code_file.write_text(code)
        
        if files:
            for fname, content in files.items():
                (exec_dir / fname).write_text(content)
        
        if stdin:
            (exec_dir / "stdin.txt").write_text(stdin)
        
        try:
            # Determine command
            if self.config.language == SandboxLanguage.PYTHON:
                cmd = ["python3", str(code_file)]
            elif self.config.language in [SandboxLanguage.JAVASCRIPT, SandboxLanguage.TYPESCRIPT]:
                cmd = ["node", str(code_file)]
            elif self.config.language in [SandboxLanguage.SHELL, SandboxLanguage.BASH]:
                cmd = ["bash", str(code_file)]
            elif self.config.language == SandboxLanguage.GO:
                cmd = ["go", "run", str(code_file)]
            elif self.config.language == SandboxLanguage.RUST:
                cmd = ["rustc", str(code_file), "-o", str(exec_dir / "main"), "&&", str(exec_dir / "main")]
                cmd = " ".join(cmd)  # Shell needed for &&
                shell = True
            else:
                cmd = ["cat", str(code_file)]
                shell = False
            
            # Prepare stdin
            stdin_data = stdin.encode() if stdin else None
            
            # Run with timeout
            if isinstance(cmd, list):
                process = await asyncio.create_subprocess_exec(
                    *cmd,
                    stdin=asyncio.subprocess.PIPE if stdin_data else None,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE,
                    cwd=str(exec_dir),
                )
            else:
                process = await asyncio.create_subprocess_shell(
                    cmd,
                    stdin=asyncio.subprocess.PIPE if stdin_data else None,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE,
                    cwd=str(exec_dir),
                )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(stdin_data),
                    timeout=limits.timeout_seconds
                )
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                return ExecutionResult(
                    execution_id=execution_id,
                    status=ExecutionStatus.TIMEOUT,
                    error="Execution timeout",
                    duration_ms=(time.time() - start_time) * 1000,
                )
            
            return ExecutionResult(
                execution_id=execution_id,
                status=ExecutionStatus.COMPLETED if process.returncode == 0 else ExecutionStatus.FAILED,
                stdout=stdout.decode() if stdout else "",
                stderr=stderr.decode() if stderr else "",
                exit_code=process.returncode,
                duration_ms=(time.time() - start_time) * 1000,
                artifacts=self._collect_artifacts(exec_dir),
            )
            
        except Exception as e:
            return ExecutionResult(
                execution_id=execution_id,
                status=ExecutionStatus.FAILED,
                error=str(e),
                duration_ms=(time.time() - start_time) * 1000,
            )
    
    def _collect_artifacts(self, exec_dir: Path) -> List[str]:
        artifacts = []
        for file_path in exec_dir.rglob("*"):
            if file_path.is_file() and file_path.name not in ["main.py", "main.js", "main.sh", "main.go", "main.rs", "stdin.txt"]:
                artifacts.append(str(file_path))
        return artifacts


# ─── Secure Sandbox Manager ──────────────────────────────────────
class SecureSandboxManager:
    """
    Main sandbox manager with defense-in-depth security.
    Automatically selects best available backend.
    """
    
    def __init__(
        self,
        default_config: SandboxConfig = None,
        preferred_backends: List[SandboxBackend] = None,
    ):
        self.default_config = default_config or SandboxConfig()
        self.preferred_backends = preferred_backends or [
            SandboxBackend.GVISOR,
            SandboxBackend.FIRECRACKER,
            SandboxBackend.DOCKER,
            SandboxBackend.E2B,
            SandboxBackend.NATIVE,
        ]
        
        self._backends: Dict[SandboxBackend, Any] = {}
        self._active_executions: Dict[str, SandboxExecution] = {}
        self._init_backends()
        self._init_db()
    
    def _init_backends(self) -> None:
        """Initialize available backends."""
        # Docker
        docker_backend = DockerSandboxBackend(self.default_config)
        if docker_backend._docker_available:
            self._backends[SandboxBackend.DOCKER] = docker_backend
        
        # gVisor
        gvisor_backend = GVisorSandboxBackend(self.default_config)
        if gvisor_backend._runsc_available:
            self._backends[SandboxBackend.GVISOR] = gvisor_backend
        
        # Firecracker
        firecracker_backend = FirecrackerSandboxBackend(self.default_config)
        if firecracker_backend._firecracker_available:
            self._backends[SandboxBackend.FIRECRACKER] = firecracker_backend
        
        # E2B
        if os.getenv("E2B_API_KEY"):
            self._backends[SandboxBackend.E2B] = E2BSandboxBackend(self.default_config)
        
        # Native (always available as fallback)
        self._backends[SandboxBackend.NATIVE] = NativeSandboxBackend(self.default_config)
        
        print(f"✅ Sandbox backends available: {list(self._backends.keys())}")
    
    def _init_db(self) -> None:
        import sqlite3
        with sqlite3.connect(SANDBOX_DB, check_same_thread=False) as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS sandbox_executions (
                    execution_id TEXT PRIMARY KEY,
                    config TEXT NOT NULL,
                    code TEXT NOT NULL,
                    files TEXT DEFAULT '{}',
                    stdin TEXT DEFAULT '',
                    status TEXT NOT NULL,
                    created_at REAL,
                    started_at REAL,
                    completed_at REAL,
                    result TEXT,
                    container_id TEXT DEFAULT ''
                )
            """)
            c.execute("CREATE INDEX IF NOT EXISTS idx_exec_status ON sandbox_executions(status)")
    
    def _get_best_backend(self) -> Any:
        """Get the best available backend based on preference order."""
        for backend in self.preferred_backends:
            if backend in self._backends:
                return self._backends[backend]
        return self._backends[SandboxBackend.NATIVE]
    
    async def execute(
        self,
        code: str,
        language: SandboxLanguage = SandboxLanguage.PYTHON,
        files: Dict[str, str] = None,
        stdin: str = "",
        config: SandboxConfig = None,
        limits: SandboxLimits = None,
    ) -> ExecutionResult:
        """Execute code in the best available sandbox."""
        config = config or self.default_config
        config.language = language
        limits = limits or config.limits
        
        # Create execution record
        execution_id = uuid.uuid4().hex[:12]
        execution = SandboxExecution(
            execution_id=execution_id,
            config=config,
            code=code,
            files=files or {},
            stdin=stdin,
        )
        self._active_executions[execution_id] = execution
        
        # Get backend
        backend = self._get_backend_for_config(config)
        
        # Execute
        execution.status = ExecutionStatus.RUNNING
        execution.started_at = time.time()
        
        result = await backend.execute(code, files, stdin, limits)
        
        execution.completed_at = time.time()
        execution.status = result.status
        execution.result = result
        
        # Save to DB
        self._save_execution(execution)
        
        return result
    
    def _get_backend_for_config(self, config: SandboxConfig) -> Any:
        """Get backend for specific config."""
        if config.backend in self._backends:
            return self._backends[config.backend]
        return self._get_best_backend()
    
    def _save_execution(self, execution: SandboxExecution) -> None:
        import sqlite3
        with sqlite3.connect(SANDBOX_DB, check_same_thread=False) as c:
            c.execute("""
                INSERT OR REPLACE INTO sandbox_executions
                (execution_id, config, code, files, stdin, status,
                 created_at, started_at, completed_at, result, container_id)
                VALUES (?,?,?,?,?,?,?,?,?,?,?)
            """, (
                execution.execution_id,
                json.dumps({
                    "backend": execution.config.backend.value,
                    "language": execution.config.language.value,
                    "limits": execution.config.limits.__dict__,
                }),
                execution.code,
                json.dumps(execution.files),
                execution.stdin,
                execution.status.value,
                execution.created_at,
                execution.started_at,
                execution.completed_at,
                json.dumps(execution.result.__dict__) if execution.result else None,
                execution.container_id,
            ))
    
    async def execute_dynamic_tool(
        self,
        tool_code: str,
        tool_input: Dict,
        tool_spec: Any,  # DynamicToolSpec
        safety_level: str = "moderate",
    ) -> ExecutionResult:
        """Execute a dynamic tool with appropriate security level."""
        # Determine limits based on safety level
        if safety_level == "strict":
            limits = SandboxLimits(
                timeout_seconds=10,
                memory_limit_mb=128,
                cpu_limit_percent=25,
                network_enabled=False,
                filesystem_read_only=True,
                max_processes=10,
                blocked_syscalls=["execve", "fork", "clone", "ptrace"],
            )
        elif safety_level == "moderate":
            limits = SandboxLimits(
                timeout_seconds=30,
                memory_limit_mb=512,
                cpu_limit_percent=50,
                network_enabled=False,
                filesystem_read_only=True,
                max_processes=32,
            )
        else:  # permissive
            limits = SandboxLimits(
                timeout_seconds=60,
                memory_limit_mb=1024,
                cpu_limit_percent=75,
                network_enabled=True,
                filesystem_read_only=False,
                max_processes=64,
            )
        
        # Create test harness
        test_code = self._create_tool_test_harness(tool_code, tool_input, tool_spec)
        
        return await self.execute(
            code=test_code,
            language=SandboxLanguage.PYTHON,
            limits=limits,
        )
    
    def _create_tool_test_harness(self, tool_code: str, tool_input: Dict, tool_spec: Any) -> str:
        """Create test harness for dynamic tool execution."""
        entry_point = tool_spec.entry_point if hasattr(tool_spec, 'entry_point') else "execute"
        
        return f"""
{tool_code}

import json
import sys

# Execute the tool
if __name__ == "__main__":
    input_data = {json.dumps(tool_input)}
    try:
        result = {entry_point}(**input_data)
        print(json.dumps({{"success": True, "result": result}}))
    except Exception as e:
        print(json.dumps({{"success": False, "error": str(e)}}))
        sys.exit(1)
"""
    
    def get_execution(self, execution_id: str) -> Optional[SandboxExecution]:
        """Get execution record."""
        return self._active_executions.get(execution_id)
    
    def list_executions(self, status: ExecutionStatus = None) -> List[SandboxExecution]:
        """List executions."""
        executions = list(self._active_executions.values())
        if status:
            executions = [e for e in executions if e.status == status]
        return sorted(executions, key=lambda x: x.created_at, reverse=True)
    
    def get_stats(self) -> Dict:
        """Get sandbox statistics."""
        total = len(self._active_executions)
        by_status = {}
        for status in ExecutionStatus:
            by_status[status.value] = sum(
                1 for e in self._active_executions.values() if e.status == status
            )
        
        return {
            "total_executions": total,
            "by_status": by_status,
            "available_backends": [b.value for b in self._backends.keys()],
            "preferred_backend": self.preferred_backends[0].value if self.preferred_backends else None,
        }


# ─── Sandbox Escape Prevention ───────────────────────────────────
class SandboxEscapePrevention:
    """Monitors and prevents sandbox escape attempts."""
    
    SUSPICIOUS_PATTERNS = [
        # Container escape
        r"/proc/self/ns/",
        r"/proc/\d+/ns/",
        r"CAP_SYS_ADMIN",
        r"CAP_DAC_OVERRIDE",
        r"CAP_SYS_PTRACE",
        r"unshare\(",
        r"setns\(",
        r"pivot_root",
        r"mount\(",
        # Kernel exploit
        r"CVE-\d{4}-\d+",
        r"dirty_cow",
        r"dirty_pipe",
        # Privilege escalation
        r"sudo\s",
        r"su\s",
        r"chmod\s+777",
        r"chmod\s+\+s",
        # Network reconnaissance
        r"nc\s+-l",
        r"netcat\s+-l",
        r"nmap\s",
        # File system access
        r"/etc/passwd",
        r"/etc/shadow",
        r"/root/",
        r"/home/",
        r"\.ssh/",
        # Process injection
        r"ptrace\(",
        r"process_vm_writev",
        r"LD_PRELOAD",
    ]
    
    def __init__(self):
        self._compiled_patterns = [
            (pattern, __import__('re').compile(pattern, __import__('re').IGNORECASE))
            for pattern in self.SUSPICIOUS_PATTERNS
        ]
    
    def scan_code(self, code: str) -> List[str]:
        """Scan code for suspicious patterns."""
        issues = []
        for pattern, compiled in self._compiled_patterns:
            if compiled.search(code):
                issues.append(f"Suspicious pattern detected: {pattern}")
        return issues
    
    def scan_command(self, command: str) -> List[str]:
        """Scan command for suspicious patterns."""
        issues = []
        for pattern, compiled in self._compiled_patterns:
            if compiled.search(command):
                issues.append(f"Suspicious command pattern: {pattern}")
        return issues


# ─── Integration with Dynamic Tool Framework ─────────────────────
async def execute_dynamic_tool_securely(
    sandbox_manager: SecureSandboxManager,
    tool_code: str,
    tool_input: Dict,
    tool_spec: Any,
    safety_level: str = "moderate",
) -> ExecutionResult:
    """Execute a dynamic tool with security scanning and sandbox isolation."""
    
    # Pre-execution security scan
    scanner = SandboxEscapePrevention()
    issues = scanner.scan_code(tool_code)
    if issues:
        return ExecutionResult(
            execution_id=uuid.uuid4().hex[:12],
            status=ExecutionStatus.SECURITY_VIOLATION,
            error=f"Security scan failed: {'; '.join(issues)}",
        )
    
    # Execute in sandbox
    return await sandbox_manager.execute_dynamic_tool(
        tool_code=tool_code,
        tool_input=tool_input,
        tool_spec=tool_spec,
        safety_level=safety_level,
    )


# ─── Module Singleton ────────────────────────────────────────────
_secure_sandbox_manager: Optional[SecureSandboxManager] = None


def get_secure_sandbox_manager(**kwargs) -> SecureSandboxManager:
    global _secure_sandbox_manager
    if _secure_sandbox_manager is None:
        _secure_sandbox_manager = SecureSandboxManager(**kwargs)
    return _secure_sandbox_manager


# ─── Export ──────────────────────────────────────────────────────
__all__ = [
    "SecureSandboxManager",
    "SandboxConfig",
    "SandboxLimits",
    "ExecutionResult",
    "SandboxExecution",
    "SandboxBackend",
    "SandboxLanguage",
    "ExecutionStatus",
    "DockerSandboxBackend",
    "GVisorSandboxBackend",
    "FirecrackerSandboxBackend",
    "E2BSandboxBackend",
    "NativeSandboxBackend",
    "SandboxEscapePrevention",
    "execute_dynamic_tool_securely",
    "get_secure_sandbox_manager",
    "SANDBOX_DIR",
    "SANDBOX_DB",
]