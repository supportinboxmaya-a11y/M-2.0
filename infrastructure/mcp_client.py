"""Phase 38 — MCP (Model Context Protocol) client support.

Maya acts as an MCP HOST: external MCP servers become ordinary tools in
Maya's ToolRegistry. They are capabilities Maya uses — never controllers.
No third-party SDK required: implements JSON-RPC 2.0 over stdio
(newline-delimited) or Streamable HTTP directly.

Server configuration (env):
    MCP_ENABLED=false            # master switch, ships OFF
    MCP_SERVERS=[{"name":"files","command":["npx","-y","@modelcontextprotocol/server-filesystem","/tmp"],
                  "tools_deny":["remove_file"]},
                 {"name":"web","url":"https://example.com/mcp"}]

Every registered tool is prefixed mcp_<server>_ and its description is
tagged [mcp:<server>] so planners can see the origin.
"""
import json
import os
import re
import subprocess
import threading
import uuid
from typing import Any, Callable, Dict, List, Optional

from maya_logging.logger import get_logger

log = get_logger("mcp")

MCP_PROTOCOL_VERSION = "2024-11-05"


class MCPError(Exception):
    pass


# ── Transports ────────────────────────────────────────────────────────────

class StdioMCPConnection:
    """JSON-RPC 2.0 over stdio (newline-delimited), as an MCP host."""

    def __init__(self, command: List[str], env: Dict = None, cwd: str = None):
        self.command = command
        self.env = {**os.environ, **(env or {})}
        self.cwd = cwd
        self.proc: Optional[subprocess.Popen] = None
        self._req_id = 0
        self._lock = threading.Lock()

    def start(self) -> None:
        if self.proc and self.proc.poll() is None:
            return
        try:
            self.proc = subprocess.Popen(
                self.command,
                stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True, bufsize=1, env=self.env, cwd=self.cwd,
            )
        except OSError as e:
            raise MCPError(f"cannot spawn MCP server {self.command}: {e}")

    def _request(self, method: str, params: Dict = None) -> Any:
        if not self.proc or self.proc.poll() is not None:
            raise MCPError("MCP server not running")
        with self._lock:
            self._req_id += 1
            rid = self._req_id
            msg: Dict[str, Any] = {"jsonrpc": "2.0", "id": rid, "method": method}
            if params is not None:
                msg["params"] = params
            try:
                self.proc.stdin.write(json.dumps(msg) + "\n")
                self.proc.stdin.flush()
            except (BrokenPipeError, ValueError) as e:
                raise MCPError(f"MCP server write failed: {e}")
            while True:
                line = self.proc.stdout.readline()
                if not line:
                    raise MCPError("MCP server closed the connection")
                line = line.strip()
                if not line:
                    continue
                try:
                    resp = json.loads(line)
                except json.JSONDecodeError:
                    continue  # skip non-protocol noise
                if resp.get("id") != rid:
                    continue  # notification / other request
                if "error" in resp:
                    raise MCPError(f"MCP error: {resp['error']}")
                return resp.get("result", {})

    def _notify(self, method: str, params: Dict = None) -> None:
        msg: Dict[str, Any] = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            msg["params"] = params
        self.proc.stdin.write(json.dumps(msg) + "\n")
        self.proc.stdin.flush()

    def initialize(self) -> Dict:
        self.start()
        result = self._request("initialize", {
            "protocolVersion": MCP_PROTOCOL_VERSION,
            "capabilities": {},
            "clientInfo": {"name": "maya", "version": "2.0"},
        })
        try:
            self._notify("notifications/initialized")
        except Exception:
            pass
        return result

    def list_tools(self) -> List[Dict]:
        return self._request("tools/list", {}).get("tools", [])

    def call_tool(self, name: str, arguments: Dict) -> Any:
        return self._request("tools/call",
                             {"name": name, "arguments": arguments})

    def close(self) -> None:
        if self.proc and self.proc.poll() is None:
            try:
                self.proc.terminate()
                self.proc.wait(timeout=5)
            except Exception:
                try:
                    self.proc.kill()
                except Exception:
                    pass
        self.proc = None


class HttpMCPConnection:
    """Streamable HTTP transport (POST JSON-RPC to a single URL)."""

    def __init__(self, url: str, headers: Dict = None, timeout: float = 30.0):
        self.url = url
        self.headers = {"Content-Type": "application/json",
                        "Accept": "application/json, text/event-stream",
                        **(headers or {})}
        self.timeout = timeout
        self._req_id = 0
        import requests
        self._requests = requests

    def start(self) -> None:
        pass  # stateless

    def _post(self, payload: Dict) -> Optional[Dict]:
        resp = self._requests.post(self.url, json=payload,
                                   headers=self.headers,
                                   timeout=self.timeout)
        resp.raise_for_status()
        body = resp.text.strip()
        if not body:
            return None  # 202 Accepted notification-only response
        ctype = resp.headers.get("Content-Type", "")
        if "text/event-stream" in ctype:
            # parse SSE data lines, last JSON wins
            result = None
            for line in body.splitlines():
                if line.startswith("data:"):
                    chunk = line[5:].strip()
                    try:
                        result = json.loads(chunk)
                    except json.JSONDecodeError:
                        continue
            return result
        try:
            return json.loads(body)
        except json.JSONDecodeError as e:
            raise MCPError(f"invalid MCP HTTP response: {e}")

    def initialize(self) -> Dict:
        self._req_id += 1
        resp = self._post({
            "jsonrpc": "2.0", "id": self._req_id, "method": "initialize",
            "params": {
                "protocolVersion": MCP_PROTOCOL_VERSION,
                "capabilities": {},
                "clientInfo": {"name": "maya", "version": "2.0"},
            },
        })
        # initialized notification (fire-and-forget)
        try:
            self._post({"jsonrpc": "2.0",
                        "method": "notifications/initialized"})
        except Exception:
            pass
        return (resp or {}).get("result", {})

    def list_tools(self) -> List[Dict]:
        self._req_id += 1
        resp = self._post({"jsonrpc": "2.0", "id": self._req_id,
                           "method": "tools/list", "params": {}})
        if resp and "error" in resp:
            raise MCPError(f"MCP error: {resp['error']}")
        return ((resp or {}).get("result") or {}).get("tools", [])

    def call_tool(self, name: str, arguments: Dict) -> Any:
        self._req_id += 1
        resp = self._post({"jsonrpc": "2.0", "id": self._req_id,
                           "method": "tools/call",
                           "params": {"name": name, "arguments": arguments}})
        if resp and "error" in resp:
            raise MCPError(f"MCP error: {resp['error']}")
        return (resp or {}).get("result", {})

    def close(self) -> None:
        pass


# ── Manager ───────────────────────────────────────────────────────────────

def _sanitize(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_]", "_", name)[:40]


def extract_text(result: Any) -> str:
    """Flatten a tools/call result into planner-friendly text."""
    if isinstance(result, str):
        return result
    content = (result or {}).get("content") if isinstance(result, dict) else None
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(str(item.get("text", "")))
            elif isinstance(item, dict) and "text" in item:
                parts.append(str(item["text"]))
        return "\n".join(parts)
    return json.dumps(result, ensure_ascii=False)


class MCPManager:
    """Owns MCP server connections; registers their tools as Maya tools."""

    def __init__(self):
        self.connections: Dict[str, Any] = {}
        self.registered: Dict[str, List[str]] = {}
        self._lock = threading.Lock()

    def _make_connection(self, cfg: Dict):
        if cfg.get("command"):
            return StdioMCPConnection(cfg["command"], env=cfg.get("env"),
                                      cwd=cfg.get("cwd"))
        if cfg.get("url"):
            return HttpMCPConnection(cfg["url"], headers=cfg.get("headers"),
                                     timeout=float(cfg.get("timeout", 30)))
        raise MCPError("server config needs 'command' or 'url'")

    def _filter_tools(self, tools: List[Dict], cfg: Dict) -> List[Dict]:
        allow = set(cfg.get("tools_allow") or [])
        deny = set(cfg.get("tools_deny") or [])
        out = []
        for t in tools:
            n = t.get("name", "")
            if deny and n in deny:
                continue
            if allow and n not in allow:
                continue
            out.append(t)
        return out

    def connect_server(self, cfg: Dict, registry=None) -> int:
        """Connect one server and register its tools. Returns tool count."""
        name = _sanitize(cfg.get("name") or f"srv_{uuid.uuid4().hex[:6]}")
        conn = self._make_connection(cfg)
        conn.initialize()
        tools = self._filter_tools(conn.list_tools(), cfg)

        registered = []
        with self._lock:
            old = self.connections.pop(name, None)
            if old is not None:
                old.close()
            self.connections[name] = conn

        if registry is not None:
            for t in tools:
                tool_name = f"mcp_{name}_{_sanitize(t.get('name', ''))}"
                schema = t.get("inputSchema") or {}
                description = (
                    f"[mcp:{cfg.get('name', name)}] "
                    f"{t.get('description') or t.get('name', '')}"
                )

                def make_fn(server=name, tool=t.get("name")):
                    def _call(**kwargs):
                        res = self.call_tool(server, tool, kwargs)
                        return extract_text(res)
                    return _call

                registry.register(tool_name, make_fn(), description,
                                  category="mcp", schema=schema)
                registered.append(tool_name)

        with self._lock:
            self.registered[name] = registered
        log.info(f"MCP server '{name}' connected: "
                 f"{len(tools)} tools ({len(registered)} registered)")
        return len(registered)

    def connect_all_and_register(self, registry) -> int:
        """Connect every configured server. Never raises; returns total."""
        total = 0
        for cfg in self._load_config():
            try:
                total += self.connect_server(cfg, registry=registry)
            except Exception as e:
                log.warning(f"MCP server '{cfg.get('name', '?')}' failed: {e}")
        return total

    @staticmethod
    def _load_config() -> List[Dict]:
        raw = os.getenv("MCP_SERVERS", "").strip()
        if not raw:
            path = os.getenv("MCP_SERVERS_FILE", "").strip()
            if path and os.path.exists(path):
                try:
                    raw = open(path).read().strip()
                except Exception:
                    return []
        if not raw:
            return []
        try:
            cfg = json.loads(raw)
            return cfg if isinstance(cfg, list) else []
        except json.JSONDecodeError:
            log.warning("MCP_SERVERS is not valid JSON — ignored")
            return []

    def call_tool(self, server: str, tool: str, arguments: Dict) -> Any:
        conn = self.connections.get(server)
        if conn is None:
            raise MCPError(f"unknown MCP server '{server}'")
        return conn.call_tool(tool, arguments)

    def disconnect_all(self) -> None:
        with self._lock:
            conns = list(self.connections.values())
            self.connections.clear()
            self.registered.clear()
        for c in conns:
            try:
                c.close()
            except Exception:
                pass

    def status(self) -> Dict:
        with self._lock:
            return {
                "servers": {
                    name: {
                        "alive": getattr(c, "proc", None) is None
                        or c.proc.poll() is None,
                        "registered_tools": len(self.registered.get(name, [])),
                    }
                    for name, c in self.connections.items()
                },
                "total_registered": sum(
                    len(v) for v in self.registered.values()),
            }


_mcp_manager: Optional[MCPManager] = None


def get_mcp_manager() -> MCPManager:
    global _mcp_manager
    if _mcp_manager is None:
        _mcp_manager = MCPManager()
    return _mcp_manager
