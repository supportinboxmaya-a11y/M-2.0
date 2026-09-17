"""
Maya 2.0 — World Models (Phase 18)
===================================
Symbolic simulators for different environments to enable planning.
Each model implements: observe(), simulate(action), and optionally step().
"""

import json
import os
import subprocess
import time
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from infrastructure.remote_deploy import RemoteDeployer


@dataclass
class WorldState:
    """Represents a world state."""
    domain: str
    timestamp: float
    entities: Dict[str, Dict] = field(default_factory=dict)  # entity_id -> properties
    relations: List[Tuple[str, str, str]] = field(default_factory=list)  # (subject, predicate, object)
    metadata: Dict = field(default_factory=dict)


@dataclass
class Action:
    """An action in the world."""
    action_type: str
    parameters: Dict
    actor: str = "maya"
    timestamp: float = field(default_factory=time.time)


@dataclass
class SimulationResult:
    """Result of simulating an action."""
    success: bool
    predicted_state: Optional[WorldState] = None
    effects: List[Dict] = field(default_factory=list)  # State changes
    reward: float = 0.0
    error: str = ""
    confidence: float = 1.0


class WorldModel(ABC):
    """Base class for world models."""
    
    def __init__(self, domain: str):
        self.domain = domain
        self.current_state: Optional[WorldState] = None
        self.history: List[Tuple[Action, SimulationResult]] = []
    
    @abstractmethod
    def observe(self) -> List[Dict]:
        """Observe current environment, return list of observations."""
        pass
    
    @abstractmethod
    def simulate(self, action: Action) -> SimulationResult:
        """Simulate an action, return predicted outcome."""
        pass
    
    def step(self, action: Action) -> SimulationResult:
        """Execute action in reality (not simulation). Override for real execution."""
        result = self.simulate(action)
        if result.success and result.predicted_state:
            self.current_state = result.predicted_state
        self.history.append((action, result))
        return result
    
    def get_state(self) -> Optional[WorldState]:
        return self.current_state
    
    def reset(self) -> None:
        self.current_state = None
        self.history.clear()


class FileSystemWorldModel(WorldModel):
    """World model for local file system operations."""
    
    def __init__(self, root_path: str = "/"):
        super().__init__("filesystem")
        self.root_path = Path(root_path).resolve()
        self._cached_state: Optional[WorldState] = None
        self._cache_time = 0
        self._cache_ttl = 5.0  # seconds
    
    def observe(self) -> List[Dict]:
        """Observe file system state."""
        observations = []
        try:
            # Get directory tree (limited depth)
            for path in self.root_path.rglob("*"):
                if path.is_file():
                    rel = path.relative_to(self.root_path)
                    if len(rel.parts) <= 3:  # Limit depth
                        stat = path.stat()
                        observations.append({
                            "proposition": f"file_exists({rel})",
                            "confidence": 1.0,
                            "metadata": {
                                "size": stat.st_size,
                                "modified": stat.st_mtime,
                                "type": "file"
                            }
                        })
                elif path.is_dir():
                    rel = path.relative_to(self.root_path)
                    if len(rel.parts) <= 2:
                        observations.append({
                            "proposition": f"dir_exists({rel})",
                            "confidence": 1.0,
                            "metadata": {"type": "directory"}
                        })
        except Exception as e:
            observations.append({"proposition": f"observation_error: {e}", "confidence": 0.0})
        
        return observations
    
    def simulate(self, action: Action) -> SimulationResult:
        """Simulate file system action."""
        action_type = action.action_type
        params = action.parameters
        
        if action_type == "read_file":
            path = self.root_path / params.get("path", "")
            try:
                if path.exists() and path.is_file():
                    content = path.read_text()[:10000]
                    return SimulationResult(
                        success=True,
                        effects=[{"type": "read", "path": str(path), "content_preview": content[:200]}],
                        reward=0.1,
                        confidence=1.0
                    )
                else:
                    return SimulationResult(success=False, error="File not found", confidence=1.0)
            except Exception as e:
                return SimulationResult(success=False, error=str(e), confidence=0.5)
        
        elif action_type == "write_file":
            path = self.root_path / params.get("path", "")
            content = params.get("content", "")
            # Simulate: check if parent exists, permissions
            try:
                parent = path.parent
                if not parent.exists():
                    return SimulationResult(success=False, error="Parent directory does not exist", confidence=0.9)
                return SimulationResult(
                    success=True,
                    effects=[{"type": "write", "path": str(path), "size": len(content)}],
                    reward=0.2,
                    confidence=0.9
                )
            except Exception as e:
                return SimulationResult(success=False, error=str(e), confidence=0.5)
        
        elif action_type == "list_dir":
            path = self.root_path / params.get("path", ".")
            try:
                if path.exists() and path.is_dir():
                    items = [p.name for p in path.iterdir()]
                    return SimulationResult(
                        success=True,
                        effects=[{"type": "list", "path": str(path), "items": items[:100]}],
                        reward=0.1,
                        confidence=1.0
                    )
                else:
                    return SimulationResult(success=False, error="Not a directory", confidence=1.0)
            except Exception as e:
                return SimulationResult(success=False, error=str(e), confidence=0.5)
        
        elif action_type == "delete_file":
            path = self.root_path / params.get("path", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "delete", "path": str(path)}],
                reward=-0.5,  # Negative reward for destructive actions
                confidence=0.8
            )
        
        elif action_type == "run_command":
            # Simulate shell command
            cmd = params.get("command", "")
            # Conservative simulation - assume success for read-only, uncertain for writes
            read_only = any(cmd.startswith(p) for p in ["cat ", "ls ", "head ", "tail ", "grep ", "find ", "wc "])
            return SimulationResult(
                success=True,
                effects=[{"type": "command", "command": cmd, "read_only": read_only}],
                reward=0.0 if read_only else -0.2,
                confidence=0.7 if read_only else 0.3
            )
        
        return SimulationResult(success=False, error=f"Unknown action: {action_type}", confidence=0.0)


class CodebaseWorldModel(WorldModel):
    """World model for codebase understanding (using LSP-style queries)."""
    
    def __init__(self, project_root: str = "."):
        super().__init__("codebase")
        self.project_root = Path(project_root).resolve()
        self._symbol_cache: Dict[str, Dict] = {}
        self._last_index = 0
    
    def observe(self) -> List[Dict]:
        """Observe codebase structure."""
        observations = []
        try:
            # Find Python files
            for py_file in self.project_root.rglob("*.py"):
                if py_file.is_file() and "__pycache__" not in str(py_file):
                    rel = py_file.relative_to(self.project_root)
                    observations.append({
                        "proposition": f"python_module_exists({rel})",
                        "confidence": 1.0,
                        "metadata": {"type": "module", "path": str(rel)}
                    })
        except Exception as e:
            observations.append({"proposition": f"observation_error: {e}", "confidence": 0.0})
        return observations
    
    def simulate(self, action: Action) -> SimulationResult:
        action_type = action.action_type
        params = action.parameters
        
        if action_type == "find_symbol":
            symbol = params.get("symbol", "")
            # Simulate finding a symbol definition
            return SimulationResult(
                success=True,
                effects=[{"type": "symbol_search", "symbol": symbol, "locations": []}],
                reward=0.1,
                confidence=0.8
            )
        
        elif action_type == "get_references":
            symbol = params.get("symbol", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "references", "symbol": symbol, "refs": []}],
                reward=0.1,
                confidence=0.7
            )
        
        elif action_type == "run_tests":
            test_path = params.get("path", ".")
            return SimulationResult(
                success=True,
                effects=[{"type": "test_run", "path": test_path, "passed": 0, "failed": 0}],
                reward=0.5,
                confidence=0.6
            )
        
        elif action_type == "apply_edit":
            # Simulate code edit
            return SimulationResult(
                success=True,
                effects=[{"type": "edit", "file": params.get("file"), "changes": params.get("changes")}],
                reward=0.3,
                confidence=0.5
            )
        
        return SimulationResult(success=False, error=f"Unknown action: {action_type}", confidence=0.0)


class DockerWorldModel(WorldModel):
    """World model for Docker container operations."""
    
    def __init__(self, remote_deployer=None):
        super().__init__("docker")
        self.remote = remote_deployer
        self._container_cache: List[Dict] = []
        self._cache_time = 0
    
    def observe(self) -> List[Dict]:
        """Observe Docker state (containers, images, networks)."""
        observations = []
        if not self.remote or not self.remote.configured:
            return [{"proposition": "docker_not_configured", "confidence": 1.0}]
        
        try:
            # Get container list
            result = self.remote._ssh("docker ps -a --format '{{json .}}'")
            for line in result.strip().split('\n'):
                if line.strip():
                    try:
                        container = json.loads(line)
                        observations.append({
                            "proposition": f"container_exists({container.get('Names', '')})",
                            "confidence": 1.0,
                            "metadata": {
                                "id": container.get("ID", "")[:12],
                                "image": container.get("Image", ""),
                                "status": container.get("Status", ""),
                                "ports": container.get("Ports", ""),
                            }
                        })
                    except Exception:
                        pass
        except Exception as e:
            observations.append({"proposition": f"docker_observe_error: {e}", "confidence": 0.0})
        
        return observations
    
    def simulate(self, action: Action) -> SimulationResult:
        action_type = action.action_type
        params = action.parameters
        
        if action_type == "run_container":
            image = params.get("image", "")
            name = params.get("name", "")
            ports = params.get("ports", {})
            env = params.get("env", {})
            
            # Simulate: check if image exists locally or needs pull
            return SimulationResult(
                success=True,
                effects=[{
                    "type": "container_create",
                    "name": name,
                    "image": image,
                    "ports": ports,
                    "env_keys": list(env.keys()) if env else []
                }],
                reward=0.5,
                confidence=0.7
            )
        
        elif action_type == "stop_container":
            name = params.get("name", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "container_stop", "name": name}],
                reward=-0.3,
                confidence=0.8
            )
        
        elif action_type == "get_logs":
            name = params.get("name", "")
            lines = params.get("lines", 100)
            return SimulationResult(
                success=True,
                effects=[{"type": "logs", "name": name, "lines": lines}],
                reward=0.1,
                confidence=0.9
            )
        
        elif action_type == "build_image":
            dockerfile_dir = params.get("dockerfile_dir", "")
            tag = params.get("tag", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "build", "dir": dockerfile_dir, "tag": tag}],
                reward=0.3,
                confidence=0.6
            )
        
        return SimulationResult(success=False, error=f"Unknown action: {action_type}", confidence=0.0)


class BrowserWorldModel(WorldModel):
    """World model for browser automation (CDP/Playwright)."""
    
    def __init__(self):
        super().__init__("browser")
        self._page_state: Dict = {}
    
    def observe(self) -> List[Dict]:
        observations = []
        if self._page_state:
            observations.append({
                "proposition": f"page_loaded({self._page_state.get('url', 'unknown')})",
                "confidence": 0.9,
                "metadata": self._page_state
            })
        return observations
    
    def simulate(self, action: Action) -> SimulationResult:
        action_type = action.action_type
        params = action.parameters
        
        if action_type == "navigate":
            url = params.get("url", "")
            self._page_state = {"url": url, "title": "", "loaded": True}
            return SimulationResult(
                success=True,
                effects=[{"type": "navigate", "url": url}],
                reward=0.2,
                confidence=0.8
            )
        
        elif action_type == "click":
            selector = params.get("selector", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "click", "selector": selector}],
                reward=0.1,
                confidence=0.7
            )
        
        elif action_type == "extract":
            selector = params.get("selector", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "extract", "selector": selector, "data": []}],
                reward=0.2,
                confidence=0.7
            )
        
        elif action_type == "screenshot":
            return SimulationResult(
                success=True,
                effects=[{"type": "screenshot"}],
                reward=0.05,
                confidence=0.9
            )
        
        return SimulationResult(success=False, error=f"Unknown action: {action_type}", confidence=0.0)


class APIWorldModel(WorldModel):
    """World model for REST API interactions."""
    
    def __init__(self):
        super().__init__("api")
        self._endpoints: Dict[str, Dict] = {}  # path -> {methods, schema, auth}
        self._auth_state: Dict = {}
    
    def observe(self) -> List[Dict]:
        observations = []
        for path, info in self._endpoints.items():
            observations.append({
                "proposition": f"api_endpoint_exists({path})",
                "confidence": 0.8,
                "metadata": info
            })
        return observations
    
    def simulate(self, action: Action) -> SimulationResult:
        action_type = action.action_type
        params = action.parameters
        
        if action_type == "request":
            method = params.get("method", "GET")
            path = params.get("path", "")
            body = params.get("body")
            
            # Check if we know this endpoint
            known = path in self._endpoints
            return SimulationResult(
                success=True,
                effects=[{"type": "api_request", "method": method, "path": path, "known": known}],
                reward=0.1,
                confidence=0.8 if known else 0.4
            )
        
        elif action_type == "discover":
            # Simulate API discovery (OpenAPI spec fetch)
            url = params.get("url", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "discover", "url": url, "endpoints_found": 0}],
                reward=0.3,
                confidence=0.6
            )
        
        return SimulationResult(success=False, error=f"Unknown action: {action_type}", confidence=0.0)


class DatabaseWorldModel(WorldModel):
    """World model for database operations."""
    
    def __init__(self):
        super().__init__("database")
        self._schemas: Dict[str, Dict] = {}  # table -> schema
        self._connections: Dict[str, Any] = {}
    
    def observe(self) -> List[Dict]:
        observations = []
        for table, schema in self._schemas.items():
            observations.append({
                "proposition": f"table_exists({table})",
                "confidence": 1.0,
                "metadata": {"schema": schema}
            })
        return observations
    
    def simulate(self, action: Action) -> SimulationResult:
        action_type = action.action_type
        params = action.parameters
        
        if action_type == "query":
            sql = params.get("sql", "")
            # Simulate: check if tables referenced exist
            return SimulationResult(
                success=True,
                effects=[{"type": "query", "sql": sql[:200], "estimated_rows": 0}],
                reward=0.1,
                confidence=0.7
            )
        
        elif action_type == "execute":
            sql = params.get("sql", "")
            is_write = any(sql.strip().upper().startswith(w) for w in ["INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "ALTER"])
            return SimulationResult(
                success=True,
                effects=[{"type": "execute", "sql": sql[:200], "is_write": is_write}],
                reward=0.2 if not is_write else -0.3,
                confidence=0.6 if not is_write else 0.4
            )
        
        elif action_type == "inspect_schema":
            table = params.get("table", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "schema", "table": table, "columns": self._schemas.get(table, {})}],
                reward=0.1,
                confidence=0.9
            )
        
        return SimulationResult(success=False, error=f"Unknown action: {action_type}", confidence=0.0)


class ServerWorldModel(WorldModel):
    """World model for remote server operations (SSH)."""
    
    def __init__(self, remote_deployer=None):
        super().__init__("server")
        self.remote = remote_deployer
        self._system_info: Dict = {}
    
    def observe(self) -> List[Dict]:
        observations = []
        if not self.remote or not self.remote.configured:
            return [{"proposition": "server_not_configured", "confidence": 1.0}]
        
        try:
            # System info
            result = self.remote._ssh("uptime && free -h && df -h /")
            observations.append({
                "proposition": "server_healthy",
                "confidence": 0.9,
                "metadata": {"status_output": result[:500]}
            })
        except Exception as e:
            observations.append({"proposition": f"server_observe_error: {e}", "confidence": 0.0})
        
        return observations
    
    def simulate(self, action: Action) -> SimulationResult:
        action_type = action.action_type
        params = action.parameters
        
        if action_type == "run_command":
            cmd = params.get("command", "")
            # Conservative: read-only commands are predictable
            read_only = any(cmd.startswith(p) for p in [
                "cat ", "ls ", "df ", "free ", "uptime", "top -bn", "ps ", "netstat ",
                "ss ", "journalctl ", "systemctl status", "systemctl list-units",
                "docker ps", "docker info", "docker inspect", "docker logs", "docker stats"
            ])
            return SimulationResult(
                success=True,
                effects=[{"type": "ssh_command", "command": cmd, "read_only": read_only}],
                reward=0.0 if read_only else -0.2,
                confidence=0.8 if read_only else 0.3
            )
        
        elif action_type == "check_service":
            service = params.get("service", "")
            return SimulationResult(
                success=True,
                effects=[{"type": "service_check", "service": service, "status": "unknown"}],
                reward=0.1,
                confidence=0.7
            )
        
        return SimulationResult(success=False, error=f"Unknown action: {action_type}", confidence=0.0)


def create_world_models(remote_deployer=None) -> Dict[str, WorldModel]:
    """Factory function to create all world models."""
    return {
        "filesystem": FileSystemWorldModel("/home/ubuntu/M-2.0"),
        "codebase": CodebaseWorldModel("/home/ubuntu/M-2.0"),
        "docker": DockerWorldModel(remote_deployer),
        "browser": BrowserWorldModel(),
        "api": APIWorldModel(),
        "database": DatabaseWorldModel(),
        "server": ServerWorldModel(remote_deployer),
    }