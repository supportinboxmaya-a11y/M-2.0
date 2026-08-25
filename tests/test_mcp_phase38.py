"""Phase 38 tests — MCP client (Maya as MCP host).

Exercises the full JSON-RPC handshake against a real subprocess MCP server
(a tiny echo server speaking newline-delimited JSON-RPC), plus tool
registration into Maya's ToolRegistry, filtering, and HTTP transport.
"""
import json
import os
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

for _name in ("loguru", "dotenv"):
    if _name not in sys.modules:
        try:
            __import__(_name)
        except ImportError:
            import types as _t
            sys.modules[_name] = _t.SimpleNamespace()
            if _name == "loguru":
                class _L:
                    def __getattr__(self, item):
                        return lambda *a, **k: None
                sys.modules[_name].logger = _L()

from infrastructure.mcp_client import (  # noqa: E402
    StdioMCPConnection, HttpMCPConnection, MCPManager, MCPError, extract_text,
)

ECHO_SERVER = r'''
import json, sys
while True:
    line = sys.stdin.readline()
    if not line:
        break
    line = line.strip()
    if not line:
        continue
    try:
        msg = json.loads(line)
    except json.JSONDecodeError:
        continue
    method = msg.get("method", "")
    if "id" not in msg:
        continue  # notification: ignore
    rid = msg["id"]
    if method == "initialize":
        result = {"protocolVersion": "2024-11-05",
                  "capabilities": {"tools": {}},
                  "serverInfo": {"name": "echo", "version": "0.1"}}
    elif method == "tools/list":
        result = {"tools": [
            {"name": "echo", "description": "Echo back the input text",
             "inputSchema": {"type": "object",
                             "properties": {"text": {"type": "string"}}}},
            {"name": "danger", "description": "Dangerous op",
             "inputSchema": {"type": "object"}},
        ]}
    elif method == "tools/call":
        name = msg.get("params", {}).get("name")
        args = msg.get("params", {}).get("arguments", {})
        if name == "echo":
            result = {"content": [{"type": "text",
                                   "text": f"echo: {args.get('text', '')}"}]}
        else:
            result = {"content": [{"type": "text", "text": "boom"}]}
    else:
        msg["error"] = {"code": -32601, "message": "method not found"}
        print(json.dumps({"jsonrpc": "2.0", "id": rid,
                          "error": msg["error"]}), flush=True)
        continue
    print(json.dumps({"jsonrpc": "2.0", "id": rid, "result": result}),
          flush=True)
'''


def _make_server_script() -> str:
    d = Path(tempfile.mkdtemp(prefix="p38_"))
    p = d / "echo_mcp_server.py"
    p.write_text(ECHO_SERVER)
    return str(p)


def _conn() -> StdioMCPConnection:
    return StdioMCPConnection([sys.executable, _make_server_script()])


def test_stdio_handshake_list_and_call():
    c = _conn()
    try:
        init = c.initialize()
        assert init["serverInfo"]["name"] == "echo"
        tools = c.list_tools()
        assert {t["name"] for t in tools} >= {"echo", "danger"}
        res = c.call_tool("echo", {"text": "hello maya"})
        assert extract_text(res) == "echo: hello maya"
    finally:
        c.close()


def test_manager_registers_into_tool_registry_with_deny():
    from tools.registry import ToolRegistry
    mgr = MCPManager()
    reg = ToolRegistry()
    n = mgr.connect_server({
        "name": "echo.srv",          # dots must sanitize to underscores
        "command": [sys.executable, _make_server_script()],
        "tools_deny": ["danger"],
    }, registry=reg)
    assert n == 1                    # danger denied
    names = reg.names_in_category("mcp")
    assert names == ["mcp_echo_srv_echo"]
    # call through the registry like any other tool
    out = reg.run("mcp_echo_srv_echo", {"text": "via registry"})
    assert out == "echo: via registry"
    # description tagged with origin
    assert "[mcp:echo.srv]" in reg._descriptions["mcp_echo_srv_echo"]
    st = mgr.status()
    assert st["total_registered"] == 1
    mgr.disconnect_all()
    assert mgr.status()["total_registered"] == 0


def test_registry_unregister_retracts_mcp_tools():
    from tools.registry import ToolRegistry
    mgr = MCPManager()
    reg = ToolRegistry()
    mgr.connect_server({"name": "s2",
                        "command": [sys.executable, _make_server_script()]},
                       registry=reg)
    assert len(reg.names_in_category("mcp")) == 2   # echo + danger
    for n in list(reg._tools):
        if n.startswith("mcp_"):
            reg.unregister(n)
    assert reg.names_in_category("mcp") == []


def test_unknown_server_call_raises_clean():
    mgr = MCPManager()
    try:
        mgr.call_tool("nope", "anything", {})
        assert False, "should have raised"
    except MCPError as e:
        assert "unknown MCP server" in str(e)


def test_http_transport_against_stub():
    """HTTP transport via a local stub server thread."""
    import threading
    from http.server import BaseHTTPRequestHandler, HTTPServer

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self):
            length = int(self.headers.get("Content-Length", 0))
            msg = json.loads(self.rfile.read(length) or b"{}")
            method = msg.get("method", "")
            body = None
            if method == "initialize":
                body = {"jsonrpc": "2.0", "id": msg["id"], "result": {
                    "serverInfo": {"name": "http-echo"}}}
            elif method == "tools/list":
                body = {"jsonrpc": "2.0", "id": msg["id"], "result": {
                    "tools": [{"name": "ping", "description": "pong",
                               "inputSchema": {}}]}}
            elif method == "tools/call":
                body = {"jsonrpc": "2.0", "id": msg["id"], "result": {
                    "content": [{"type": "text", "text": "pong"}]}}
            elif "id" in msg:
                body = {"jsonrpc": "2.0", "id": msg["id"],
                        "result": {}}
            if body is not None:
                data = json.dumps(body).encode()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)

        def log_message(self, *a):
            pass

    srv = HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    port = srv.server_address[1]
    try:
        conn = HttpMCPConnection(f"http://127.0.0.1:{port}/mcp")
        assert conn.initialize()["serverInfo"]["name"] == "http-echo"
        assert any(t["name"] == "ping" for t in conn.list_tools())
        assert extract_text(conn.call_tool("ping", {})) == "pong"
        conn.close()
    finally:
        srv.shutdown()
