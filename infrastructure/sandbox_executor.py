"""
Maya 2.0 — Sandbox Executor (Phase 1)
======================================
Secure code execution using gVisor (runsc) or Firecracker.
Supports Python, JavaScript, Shell, and containerized workloads.
Optimized for Oracle ARM64 VPS.
"""

import asyncio
import json
import os
import shlex
import subprocess
import tempfile
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Literal

from config.settings import STORAGE_DIR, WORKSPACE_DIR


SANDBOX_DIR = STORAGE_DIR / "sandbox"
SANDBOX_DIR.mkdir(parents=True, exist_ok=True)


@dataclass
class ExecutionResult:
    """Result of sandbox execution."""
    success: bool
    stdout: str = ""
    stderr: str = ""
    exit_code: int = 0
    duration_ms: float = 0
    error: str = ""
    artifacts: List[str] = field(default_factory=list)  # Files created


@dataclass
class SandboxConfig:
    """Sandbox configuration."""
    runtime: Literal["gvisor", "firecracker", "native"] = "gvisor"
    language: Literal["python", "javascript", "shell", "container"] = "python"
    timeout_seconds: int = 30
    memory_limit_mb: int = 512
    cpu_limit_percent: int = 50
    network_enabled: bool = False
    filesystem_read_only: bool = True
    allowed_paths: List[str] = field(default_factory=lambda: [str(WORKSPACE_DIR)])
    environment_vars: Dict[str, str] = field(default_factory=dict)
    capabilities: List[str] = field(default_factory=list)  # gVisor capabilities


class SandboxExecutor:
    """
    Secure code execution sandbox.
    
    Supports multiple backends:
    - gVisor (runsc): Best balance of security/compatibility
    - Firecracker: Maximum isolation, higher overhead
    - Native: Fastest, minimal isolation (dev only)
    """
    
    def __init__(self, config: SandboxConfig = None):
        self.config = config or SandboxConfig()
        self._detect_runtime()
        self._prepare_environment()
    
    def _detect_runtime(self) -> None:
        """Detect available sandbox runtime."""
        # Check for gVisor (runsc)
        try:
            result = subprocess.run(
                ["runsc", "--version"], 
                capture_output=True, timeout=5
            )
            if result.returncode == 0:
                self.config.runtime = "gvisor"
                self._runsc_version = result.stdout.decode().strip()
                return
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass
        
        # Check for Firecracker
        try:
            result = subprocess.run(
                ["firecracker", "--version"], 
                capture_output=True, timeout=5
            )
            if result.returncode == 0:
                self.config.runtime = "firecracker"
                return
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass
        
        # Fallback to native
        self.config.runtime = "native"
        print("⚠️  No sandbox runtime found (runsc/firecracker), using native execution")
    
    def _prepare_environment(self) -> None:
        """Prepare sandbox environment."""
        # Create workspace mount point
        self.workspace_mount = str(WORKSPACE_DIR)
        self.sandbox_workspace = "/workspace"
        
        # Prepare gVisor bundle dir if needed
        if self.config.runtime == "gvisor":
            self.bundle_dir = SANDBOX_DIR / "bundles"
            self.bundle_dir.mkdir(exist_ok=True)
    
    async def execute(
        self,
        code: str,
        language: str = None,
        files: Dict[str, str] = None,
        stdin: str = "",
        config: SandboxConfig = None,
    ) -> ExecutionResult:
        """Execute code in sandbox."""
        config = config or self.config
        language = language or config.language
        start_time = time.time()
        
        # Create temp directory for this execution
        exec_id = uuid.uuid4().hex[:12]
        exec_dir = SANDBOX_DIR / "exec" / exec_id
        exec_dir.mkdir(parents=True, exist_ok=True)
        
        # Write code file
        code_file = self._get_code_file(exec_dir, language, code)
        
        # Write additional files
        if files:
            for fname, content in files.items():
                (exec_dir / fname).write_text(content)
        
        # Write stdin
        if stdin:
            (exec_dir / "stdin.txt").write_text(stdin)
        
        try:
            if config.runtime == "gvisor":
                result = await self._execute_gvisor(exec_dir, code_file, language, config, stdin)
            elif config.runtime == "firecracker":
                result = await self._execute_firecracker(exec_dir, code_file, language, config, stdin)
            else:
                result = await self._execute_native(exec_dir, code_file, language, config, stdin)
        except Exception as e:
            result = ExecutionResult(
                success=False,
                error=f"Sandbox execution failed: {e}",
                duration_ms=(time.time() - start_time) * 1000,
            )
        
        # Collect artifacts
        result.artifacts = self._collect_artifacts(exec_dir)
        result.duration_ms = (time.time() - start_time) * 1000
        
        # Cleanup (keep artifacts for a bit)
        # asyncio.create_task(self._delayed_cleanup(exec_dir))
        
        return result
    
    def _get_code_file(self, exec_dir: Path, language: str, code: str) -> Path:
        """Get the appropriate code file for the language."""
        extensions = {
            "python": "main.py",
            "javascript": "main.js",
            "typescript": "main.ts",
            "shell": "main.sh",
            "bash": "main.sh",
            "go": "main.go",
            "rust": "main.rs",
        }
        ext = extensions.get(language, "main.txt")
        code_file = exec_dir / ext
        code_file.write_text(code)
        return code_file
    
    async def _execute_gvisor(
        self, exec_dir: Path, code_file: Path, 
        language: str, config: SandboxConfig, stdin: str
    ) -> ExecutionResult:
        """Execute using gVisor runsc."""
        # Create gVisor bundle
        bundle_dir = exec_dir / "bundle"
        bundle_dir.mkdir(exist_ok=True)
        
        # Create config.json for runsc
        runsc_config = {
            "ociVersion": "1.0.2",
            "process": {
                "terminal": False,
                "user": "nobody",
                "args": self._get_run_args(language, code_file.name),
                "env": [
                    f"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                    f"HOME=/tmp",
                    f"PYTHONPATH=/workspace",
                ] + [f"{k}={v}" for k, v in config.environment_vars.items()],
                "cwd": self.sandbox_workspace,
                "capabilities": {
                    "bounding": config.capabilities or [],
                    "effective": config.capabilities or [],
                    "inheritable": config.capabilities or [],
                    "permitted": config.capabilities or [],
                    "ambient": [],
                },
                "rlimits": [
                    {"type": "RLIMIT_CPU", "hard": config.timeout_seconds, "soft": config.timeout_seconds},
                    {"type": "RLIMIT_AS", "hard": config.memory_limit_mb * 1024 * 1024, 
                     "soft": config.memory_limit_mb * 1024 * 1024},
                    {"type": "RLIMIT_FSIZE", "hard": 100 * 1024 * 1024, "soft": 100 * 1024 * 1024},
                ],
            },
            "root": {
                "path": "rootfs",
                "readonly": config.filesystem_read_only,
            },
            "mounts": [
                {
                    "destination": self.sandbox_workspace,
                    "type": "bind",
                    "source": self.workspace_mount,
                    "options": ["rbind", "ro" if config.filesystem_read_only else "rw"],
                },
                {
                    "destination": "/tmp",
                    "type": "tmpfs",
                    "source": "tmpfs",
                    "options": ["nosuid", "noexec", "nodev", "size=100M"],
                },
            ],
            "linux": {
                "namespaces": [
                    {"type": "pid"},
                    {"type": "network"} if not config.network_enabled else {"type": "network", "path": ""},
                    {"type": "ipc"},
                    {"type": "uts"},
                    {"type": "mount"},
                ],
                "seccomp": {
                    "defaultAction": "SCMP_ACT_ERRNO",
                    "architectures": ["SCMP_ARCH_AARCH64", "SCMP_ARCH_X86_64"],
                    "syscalls": self._get_allowed_syscalls(language),
                },
            },
        }
        
        (bundle_dir / "config.json").write_text(json.dumps(runsc_config))
        
        # Create minimal rootfs or use existing
        rootfs = bundle_dir / "rootfs"
        if not rootfs.exists():
            # Use a minimal rootfs or bind mount host
            rootfs.mkdir(parents=True)
            # Bind mount essential dirs
            for d in ["bin", "lib", "lib64", "usr", "etc"]:
                (rootfs / d).mkdir(exist_ok=True)
        
        # Run with runsc
        cmd = [
            "runsc", "--rootless", "run",
            "--bundle", str(bundle_dir),
            f"maya-sandbox-{exec_dir.name}",
        ]
        
        return await self._run_command(cmd, config.timeout_seconds, stdin, exec_dir)
    
    async def _execute_firecracker(
        self, exec_dir: Path, code_file: Path,
        language: str, config: SandboxConfig, stdin: str
    ) -> ExecutionResult:
        """Execute using Firecracker microVM.
        
        Firecracker requires:
        - Kernel image (vmlinux)
        - Rootfs (ext4 image)
        - Network config (tap device)
        - Jailer for isolation
        
        This implementation requires pre-built Firecracker artifacts:
        - vmlinux kernel image
        - Rootfs ext4 image
        - Firecracker binary and jailer
        
        If artifacts are not available, falls back to gVisor.
        """
        # Check if Firecracker artifacts are available
        firecracker_root = Path(os.environ.get("FIRECRACKER_ROOT", "/opt/firecracker"))
        kernel_path = firecracker_root / "vmlinux"
        rootfs_path = firecracker_root / "rootfs.ext4"
        firecracker_bin = firecracker_root / "firecracker"
        jailer_bin = firecracker_root / "jailer"
        
        artifacts_exist = all(p.exists() for p in [kernel_path, rootfs_path, firecracker_bin, jailer_bin])
        
        if not artifacts_exist:
            log.warning("Firecracker artifacts not found, falling back to gVisor")
            if self._has_runsc():
                self.config.runtime = "gvisor"
                return await self._execute_gvisor(exec_dir, code_file, language, config, stdin)
            raise RuntimeError("Firecracker artifacts not found and gVisor not available")

        # Generate unique VM ID
        vm_id = f"maya-vm-{uuid.uuid4().hex[:8]}"
        tap_name = f"tap-{uuid.uuid4().hex[:8]}"
        
        # Create tap device for networking
        tap_created = False
        try:
            # Create tap device (requires root/CAP_NET_ADMIN)
            subprocess.run(
                ["sudo", "ip", "tuntap", "add", "dev", tap_name, "mode", "tap", "user", "maya"],
                check=True, capture_output=True
            )
            subprocess.run(["sudo", "ip", "link", "set", tap_name, "up"], check=True)
            tap_created = True
            
            # Configure jailer
            jailer_cmd = [
                str(jailer_bin), "--id", vm_id,
                "--exec-file", str(firecracker_bin),
                "--kernel", str(kernel_path),
                "--root-drive", str(rootfs_path),
                "--netdev", f"tap:{tap_name}",
                "--no-daemonize",
            ]
            
            # Build firecracker config
            import json
            config_json = {
                "boot-source": {"kernel_image_path": str(kernel_path)},
                "drives": [{"drive_id": "rootfs", "path_on_host": str(rootfs_path), "is_root_device": True, "is_read_only": False}],
                "network-interfaces": [{"iface_id": "eth0", "host_dev_name": tap_name}],
                "machine-config": {"vcpu_count": 1, "mem_size_mib": config.memory_limit_mb},
            }
            
            config_file = exec_dir / "firecracker-config.json"
            with open(config_file, "w") as f:
                json.dump(config_json, f)
            
            # Add config file to jailer args
            jailer_cmd.extend(["--config-file", str(config_file)])
            
            # Run jailer (which starts firecracker)
            process = await asyncio.create_subprocess_exec(
                *jailer_cmd,
                stdin=asyncio.subprocess.PIPE if stdin else None,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(stdin.encode() if stdin else None),
                    timeout=config.timeout_seconds
                )
                return ExecutionResult(
                    success=process.returncode == 0,
                    stdout=stdout.decode() if stdout else "",
                    stderr=stderr.decode() if stderr else "",
                    exit_code=process.returncode or 0,
                    duration_ms=0,
                )
            except asyncio.TimeoutError:
                process.kill()
                return ExecutionResult(success=False, stdout="", stderr="Timeout", exit_code=-1, duration_ms=config.timeout_seconds * 1000)
            finally:
                # Cleanup tap device
                if tap_created:
                    try:
                        subprocess.run(["sudo", "ip", "link", "delete", tap_name], capture_output=True)
                    except Exception:
                        pass
        except Exception as e:
            log.warning(f"Firecracker execution failed, falling back to gVisor: {e}")
            if self._has_runsc():
                self.config.runtime = "gvisor"
                return await self._execute_gvisor(exec_dir, code_file, language, config, stdin)
            raise RuntimeError(f"Firecracker execution failed: {e}")
    
    async def _execute_native(
        self, exec_dir: Path, code_file: Path,
        language: str, config: SandboxConfig, stdin: str
    ) -> ExecutionResult:
        """Execute natively (no sandbox) - DEV ONLY."""
        cmd = self._get_native_cmd(language, code_file)
        return await self._run_command(cmd, config.timeout_seconds, stdin, exec_dir)
    
    def _get_run_args(self, language: str, filename: str) -> List[str]:
        """Get command args for the language."""
        commands = {
            "python": ["python3", filename],
            "javascript": ["node", filename],
            "typescript": ["npx", "ts-node", filename],
            "shell": ["bash", filename],
            "bash": ["bash", filename],
            "go": ["go", "run", filename],
            "rust": ["rustc", filename, "-o", "main", "&&", "./main"],
        }
        return commands.get(language, ["cat", filename])
    
    def _get_native_cmd(self, language: str, code_file: Path) -> List[str]:
        """Get native command for language."""
        return self._get_run_args(language, code_file.name)
    
    def _get_allowed_syscalls(self, language: str) -> List[Dict]:
        """Get allowed syscalls for the language."""
        # Base syscalls needed for most operations
        base_syscalls = [
            "read", "write", "open", "close", "stat", "fstat", "lstat",
            "poll", "lseek", "mmap", "mprotect", "munmap", "brk",
            "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
            "ioctl", "pread64", "pwrite64", "readv", "writev",
            "access", "pipe", "select", "sched_yield", "mremap",
            "msync", "mincore", "madvise", "shmget", "shmat", "shmctl",
            "dup", "dup2", "pause", "nanosleep", "getitimer", "alarm",
            "setitimer", "getpid", "sendfile", "socket", "connect",
            "accept", "sendto", "recvfrom", "sendmsg", "recvmsg",
            "shutdown", "bind", "listen", "getsockname", "getpeername",
            "socketpair", "setsockopt", "getsockopt", "clone", "fork",
            "vfork", "execve", "exit", "wait4", "kill", "uname",
            "semget", "semop", "semctl", "shmdt", "msgget", "msgsnd",
            "msgrcv", "msgctl", "fcntl", "flock", "fsync", "fdatasync",
            "truncate", "ftruncate", "getdents", "getcwd", "chdir",
            "fchdir", "rename", "mkdir", "rmdir", "creat", "link",
            "unlink", "symlink", "readlink", "chmod", "fchmod",
            "chown", "fchown", "lchown", "umask", "gettimeofday",
            "getrlimit", "getrusage", "sysinfo", "times", "ptrace",
            "getuid", "syslog", "getgid", "setuid", "setgid", "geteuid",
            "getegid", "setpgid", "getppid", "getpgrp", "setsid",
            "setreuid", "setregid", "getgroups", "setgroups", "setresuid",
            "getresuid", "setresgid", "getresgid", "getpgid", "setfsuid",
            "setfsgid", "getsid", "capget", "capset", "rt_sigpending",
            "rt_sigtimedwait", "rt_sigqueueinfo", "rt_sigsuspend",
            "sigaltstack", "utime", "mknod", "uselib", "personality",
            "ustat", "statfs", "fstatfs", "sysfs", "getpriority",
            "setpriority", "sched_setparam", "sched_getparam",
            "sched_setscheduler", "sched_getscheduler", "sched_get_priority_max",
            "sched_get_priority_min", "sched_rr_get_interval", "mlock",
            "munlock", "mlockall", "munlockall", "vhangup", "modify_ldt",
            "pivot_root", "_sysctl", "prctl", "arch_prctl", "adjtimex",
            "setrlimit", "chroot", "sync", "acct", "settimeofday",
            "mount", "umount2", "swapon", "swapoff", "reboot", "sethostname",
            "setdomainname", "iopl", "ioperm", "create_module", "init_module",
            "delete_module", "get_kernel_syms", "query_module", "quotactl",
            "nfsservctl", "getpmsg", "putpmsg", "afs_syscall", "tuxcall",
            "security", "gettid", "readahead", "setxattr", "lsetxattr",
            "fsetxattr", "getxattr", "lgetxattr", "fgetxattr", "listxattr",
            "llistxattr", "flistxattr", "removexattr", "lremovexattr",
            "fremovexattr", "tkill", "time", "futex", "sched_setaffinity",
            "sched_getaffinity", "set_thread_area", "io_setup", "io_destroy",
            "io_getevents", "io_submit", "io_cancel", "get_thread_area",
            "lookup_dcookie", "epoll_create", "epoll_ctl_old", "epoll_wait_old",
            "remap_file_pages", "getdents64", "set_tid_address", "restart_syscall",
            "semtimedop", "fadvise64", "timer_create", "timer_settime",
            "timer_gettime", "timer_getoverrun", "timer_delete", "clock_settime",
            "clock_gettime", "clock_getres", "clock_nanosleep", "exit_group",
            "epoll_wait", "epoll_ctl", "tgkill", "utimes", "vserver", "mbind",
            "set_mempolicy", "get_mempolicy", "mq_open", "mq_unlink", "mq_timedsend",
            "mq_timedreceive", "mq_notify", "mq_getsetattr", "kexec_load",
            "waitid", "add_key", "request_key", "keyctl", "ioprio_set", "ioprio_get",
            "inotify_init", "inotify_add_watch", "inotify_rm_watch", "migrate_pages",
            "openat", "mkdirat", "mknodat", "fchownat", "futimesat", "newfstatat",
            "unlinkat", "renameat", "linkat", "symlinkat", "readlinkat", "fchmodat",
            "faccessat", "pselect6", "ppoll", "unshare", "set_robust_list", "get_robust_list",
            "splice", "tee", "sync_file_range", "vmsplice", "move_pages", "utimensat",
            "epoll_pwait", "signalfd", "timerfd_create", "eventfd", "fallocate",
            "timerfd_settime", "timerfd_gettime", "accept4", "signalfd4", "eventfd2",
            "epoll_create1", "dup3", "pipe2", "inotify_init1", "preadv", "pwritev",
            "rt_tgsigqueueinfo", "perf_event_open", "recvmmsg", "fanotify_init",
            "fanotify_mark", "prlimit64", "name_to_handle_at", "open_by_handle_at",
            "clock_adjtime", "syncfs", "sendmmsg", "setns", "getcpu", "process_vm_readv",
            "process_vm_writev", "kcmp", "finit_module", "sched_setattr", "sched_getattr",
            "renameat2", "seccomp", "getrandom", "memfd_create", "kexec_file_load",
            "bpf", "execveat", "userfaultfd", "membarrier", "mlock2", "copy_file_range",
            "preadv2", "pwritev2", "pkey_mknod", "pkey_mkostemp", "pkey_mkostemp",
            "statx", "io_pgetevents", "rseq", "clock_gettime64", "clock_settime64",
            "clock_adjtime64", "clock_getres64", "clock_nanosleep64", "timer_gettime64",
            "timer_settime64", "timerfd_gettime64", "timerfd_settime64",
            "utimensat_time64", "pselect6_time64", "ppoll_time64",
            "io_pgetevents_time64", "recvmmsg_time64", "mq_timedsend_time64",
            "mq_timedreceive_time64", "futex_time64", "sched_rr_get_interval_time64",
        ]
        
        # Language-specific additions
        if language == "python":
            # Python needs these for imports, threading, etc.
            pass
        
        return [{"names": base_syscalls, "action": "SCMP_ACT_ALLOW"}]
    
    def _has_runsc(self) -> bool:
        try:
            subprocess.run(["runsc", "--version"], capture_output=True, timeout=2)
            return True
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False
    
    async def _run_command(
        self, cmd: List[str], timeout: int, stdin: str, exec_dir: Path
    ) -> ExecutionResult:
        """Run a command with timeout."""
        try:
            proc = await asyncio.create_subprocess_exec(
                *cmd,
                cwd=str(exec_dir),
                stdin=asyncio.subprocess.PIPE if stdin else None,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=os.environ.copy(),
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    proc.communicate(stdin.encode() if stdin else None),
                    timeout=timeout,
                )
                exit_code = proc.returncode or 0
            except asyncio.TimeoutError:
                proc.kill()
                await proc.wait()
                return ExecutionResult(
                    success=False,
                    stdout="",
                    stderr=f"Execution timed out after {timeout}s",
                    exit_code=-1,
                    error="Timeout",
                )
            
            return ExecutionResult(
                success=exit_code == 0,
                stdout=stdout.decode("utf-8", errors="replace"),
                stderr=stderr.decode("utf-8", errors="replace"),
                exit_code=exit_code,
            )
        except Exception as e:
            return ExecutionResult(
                success=False,
                error=str(e),
            )
    
    def _collect_artifacts(self, exec_dir: Path) -> List[str]:
        """Collect files created during execution."""
        artifacts = []
        for f in exec_dir.rglob("*"):
            if f.is_file() and f.name not in ["stdin.txt", "main.py", "main.js", "main.sh"]:
                try:
                    rel = f.relative_to(exec_dir)
                    # Copy to workspace for persistence
                    dest = WORKSPACE_DIR / f"sandbox_{exec_dir.name}_{rel}"
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_bytes(f.read_bytes())
                    artifacts.append(str(dest))
                except Exception:
                    pass
        return artifacts
    
    async def _delayed_cleanup(self, exec_dir: Path, delay: int = 3600) -> None:
        """Clean up execution directory after delay."""
        await asyncio.sleep(delay)
        try:
            import shutil
            shutil.rmtree(exec_dir, ignore_errors=True)
        except Exception:
            pass
    
    async def execute_container(
        self,
        image: str,
        command: List[str] = None,
        volumes: Dict[str, str] = None,
        environment: Dict[str, str] = None,
        working_dir: str = "/workspace",
        config: SandboxConfig = None,
    ) -> ExecutionResult:
        """Execute a Docker container in sandbox."""
        config = config or self.config
        
        if config.runtime == "gvisor":
            # Use runsc with docker image
            cmd = [
                "runsc", "--rootless", "run",
                "--image", image,
            ]
            if command:
                cmd.extend(command)
            # Would need more setup for full container support
            return ExecutionResult(
                success=False,
                error="Container execution not fully implemented for gVisor",
            )
        
        # Native Docker (less secure but functional)
        docker_cmd = ["docker", "run", "--rm"]
        
        # Resource limits
        docker_cmd.extend([
            f"--memory={config.memory_limit_mb}m",
            f"--cpus={config.cpu_limit_percent / 100}",
            "--network=none" if not config.network_enabled else "bridge",
            "--read-only" if config.filesystem_read_only else "",
        ])
        
        # Volumes
        if volumes:
            for host, container in volumes.items():
                docker_cmd.extend(["-v", f"{host}:{container}"])
        else:
            docker_cmd.extend(["-v", f"{self.workspace_mount}:{working_dir}"])
        
        # Environment
        if environment:
            for k, v in environment.items():
                docker_cmd.extend(["-e", f"{k}={v}"])
        
        docker_cmd.extend(["-w", working_dir, image])
        if command:
            docker_cmd.extend(command)
        
        # Filter empty strings
        docker_cmd = [c for c in docker_cmd if c]
        
        return await self._run_command(docker_cmd, config.timeout_seconds, "", Path("."))
    
    def get_status(self) -> Dict:
        """Get sandbox status."""
        return {
            "runtime": self.config.runtime,
            "runsc_version": getattr(self, "_runsc_version", None),
            "config": {
                "timeout_seconds": self.config.timeout_seconds,
                "memory_limit_mb": self.config.memory_limit_mb,
                "cpu_limit_percent": self.config.cpu_limit_percent,
                "network_enabled": self.config.network_enabled,
                "filesystem_read_only": self.config.filesystem_read_only,
            },
        }


# Module singleton
_sandbox_executor: Optional[SandboxExecutor] = None


def get_sandbox_executor(config: SandboxConfig = None) -> SandboxExecutor:
    global _sandbox_executor
    if _sandbox_executor is None:
        _sandbox_executor = SandboxExecutor(config)
    return _sandbox_executor