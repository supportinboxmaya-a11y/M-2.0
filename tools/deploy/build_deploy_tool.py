"""
Maya 2.0 - Build & Deploy Tools
Provides APK build status, APK serving, code linting, log tailing, config updates, health checks, agent routing.
"""

import os
import subprocess
import json
import shutil
import socket
from pathlib import Path
from typing import Dict, List, Optional
from config.settings import WORKSPACE_DIR
from datetime import datetime


class BuildDeployTool:
    """Build and deployment management tools."""
    
    def __init__(self):
        self.workspace = Path(WORKSPACE_DIR)
        self.apk_dir = self.workspace / "apk"
        self.apk_dir.mkdir(exist_ok=True)
        
    def _apk_build_status(self, project_path: str = "") -> dict:
        """Check APK build status."""
        try:
            if project_path:
                proj = Path(project_path)
            else:
                # Find Android project
                proj = self.workspace
                for p in self.workspace.rglob("build.gradle*"):
                    proj = p.parent
                    break
            
            gradlew = proj / "gradlew"
            if not gradlew.exists():
                return {"success": False, "error": "No gradlew found in project"}
            
            # Check last build
            apk_outputs = list(proj.rglob("*.apk"))
            if apk_outputs:
                latest = max(apk_outputs, key=lambda p: p.stat().st_mtime)
                return {
                    "success": True,
                    "project": str(proj),
                    "last_build": datetime.fromtimestamp(latest.stat().st_mtime).isoformat(),
                    "apk_path": str(latest),
                    "apk_size_mb": round(latest.stat().st_size / (1024*1024), 2)
                }
            
            return {"success": True, "project": str(proj), "status": "No APK built yet"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _apk_serve(self, port: int = 8080, apk_path: str = "") -> dict:
        """Serve APK file via HTTP (for download)."""
        try:
            if not apk_path:
                apks = list(self.apk_dir.glob("*.apk"))
                if not apks:
                    return {"success": False, "error": "No APK found to serve"}
                apk_path = str(max(apks, key=lambda p: p.stat().st_mtime))
            
            # This would start a simple HTTP server - return info for now
            return {
                "success": True,
                "message": f"APK ready to serve: {apk_path}",
                "download_url": f"http://localhost:{port}/app-release.apk",
                "note": f"Use 'python -m http.server {port} -d {self.apk_dir}' to serve"
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _code_lint(self, path: str = "", fix: bool = False) -> dict:
        """Lint Python code using ruff/flake8."""
        try:
            target = Path(path) if path else self.workspace
            results = {}
            
            # Try ruff first
            try:
                cmd = ["ruff", "check", str(target)]
                if fix:
                    cmd.append("--fix")
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
                results["ruff"] = {
                    "exit_code": result.returncode,
                    "output": result.stdout,
                    "errors": result.stderr
                }
            except FileNotFoundError:
                results["ruff"] = {"error": "ruff not installed"}
            
            # Try flake8 as fallback
            try:
                cmd = ["flake8", str(target)]
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
                results["flake8"] = {
                    "exit_code": result.returncode,
                    "output": result.stdout,
                    "errors": result.stderr
                }
            except FileNotFoundError:
                results["flake8"] = {"error": "flake8 not installed"}
            
            return {"success": True, "results": results}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _log_tail(self, log_path: str = "", lines: int = 100, follow: bool = False) -> dict:
        """Tail log files."""
        try:
            if log_path:
                log_file = Path(log_path)
            else:
                # Default to maya-api logs
                log_file = Path("/var/log/maya-api.log")
                if not log_file.exists():
                    log_file = Path("/opt/maya/storage/logs/maya.log")
            
            if not log_file.exists():
                return {"success": False, "error": f"Log file not found: {log_file}"}
            
            if follow:
                return {"success": False, "error": "Follow mode not supported via tool. Use 'tail -f' directly."}
            
            result = subprocess.run(
                ["tail", "-n", str(lines), str(log_file)],
                capture_output=True, text=True, timeout=10
            )
            return {
                "success": True,
                "log_file": str(log_file),
                "lines": result.stdout
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _config_update(self, key: str, value: str, config_file: str = "") -> dict:
        """Update configuration in .env or config file."""
        try:
            if not config_file:
                config_file = str(self.workspace / ".env")
            
            config_path = Path(config_file)
            if not config_path.exists():
                return {"success": False, "error": f"Config file not found: {config_file}"}
            
            # Read current content
            lines = config_path.read_text().splitlines()
            
            # Update or add key
            updated = False
            for i, line in enumerate(lines):
                if line.strip().startswith(f"{key}="):
                    lines[i] = f"{key}={value}"
                    updated = True
                    break
            
            if not updated:
                lines.append(f"{key}={value}")
            
            # Write back
            config_path.write_text("\n".join(lines) + "\n")
            
            return {"success": True, "message": f"Updated {key} in {config_file}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _health_check_all(self) -> dict:
        """Comprehensive health check of all services."""
        try:
            checks = {}
            
            # Check services
            services = ["maya-api", "ollama", "maya-apk", "cloudflared-tunnel"]
            for svc in services:
                try:
                    result = subprocess.run(
                        ["systemctl", "is-active", svc],
                        capture_output=True, text=True, timeout=5
                    )
                    checks[svc] = {"active": result.stdout.strip() == "active", "status": result.stdout.strip()}
                except:
                    checks[svc] = {"active": False, "status": "error"}
            
            # Check ports
            ports = [8000, 8080, 11434, 3001]
            for port in ports:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(2)
                result = sock.connect_ex(("127.0.0.1", port))
                sock.close()
                checks[f"port_{port}"] = {"listening": result == 0}
            
            # Check disk space
            disk = shutil.disk_usage("/")
            checks["disk"] = {
                "free_gb": round(disk.free / (1024**3), 2),
                "percent_used": round(disk.used / disk.total * 100, 1)
            }
            
            # Check memory
            try:
                import psutil
                mem = psutil.virtual_memory()
                checks["memory"] = {
                    "available_gb": round(mem.available / (1024**3), 2),
                    "percent_used": mem.percent
                }
            except:
                checks["memory"] = {"error": "psutil not available"}
            
            # Overall health
            all_active = all(c.get("active", False) for k, c in checks.items() if k in services)
            checks["overall"] = "healthy" if all_active else "degraded"
            
            return {"success": True, "checks": checks}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _agent_router(self, task: str, preferred_agent: str = "") -> dict:
        """Route task to best agent (uses orchestrator logic)."""
        try:
            # Import orchestrator
            from agents.registry import AgentRegistry
            from agents.roster import build_default_agents
            
            registry = AgentRegistry()
            for a in build_default_agents():
                registry.register(a)
            
            if preferred_agent:
                agent = registry.get(preferred_agent)
                if agent:
                    return {"success": True, "agent": agent.name, "role": agent.role, "reason": "explicit"}
            
            # Route based on keywords
            agent = registry.route(task)
            if agent:
                return {"success": True, "agent": agent.name, "role": agent.role, "reason": "keyword_match"}
            
            return {"success": False, "error": "No suitable agent found"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    # Tool registry entry points (no recursion - call internal methods with _ prefix)
    def apk_build_status(self, project_path: str = "", **kwargs) -> str:
        result = self._apk_build_status(project_path)
        if result.get("success"):
            if "apk_path" in result:
                return f"Last build: {result['last_build']} - {result['apk_path']} ({result['apk_size_mb']} MB)"
            return f"Project: {result['project']} - {result['status']}"
        return f"Error: {result.get('error')}"

    def apk_serve(self, port: int = 8080, apk_path: str = "", **kwargs) -> str:
        result = self._apk_serve(port, apk_path)
        if result.get("success"):
            return f"APK: {result['download_url']}"
        return f"Error: {result.get('error')}"

    def code_lint(self, path: str = "", fix: bool = False, **kwargs) -> str:
        result = self._code_lint(path, fix)
        if result.get("success"):
            out = []
            for tool, res in result["results"].items():
                if "exit_code" in res:
                    out.append(f"{tool}: exit_code={res['exit_code']}")
                else:
                    out.append(f"{tool}: {res.get('error', 'unknown')}")
            return "\n".join(out)
        return f"Error: {result.get('error')}"

    def log_tail(self, log_path: str = "", lines: int = 100, follow: bool = False, **kwargs) -> str:
        result = self._log_tail(log_path, lines, follow)
        if result.get("success"):
            return result["lines"]
        return f"Error: {result.get('error')}"

    def config_update(self, key: str, value: str, config_file: str = "", **kwargs) -> str:
        result = self._config_update(key, value, config_file)
        if result.get("success"):
            return result["message"]
        return f"Error: {result.get('error')}"

    def health_check_all(self, **kwargs) -> str:
        result = self._health_check_all()
        if result.get("success"):
            import json
            return json.dumps(result["checks"], indent=2)
        return f"Error: {result.get('error')}"

    def agent_router(self, task: str, preferred_agent: str = "", **kwargs) -> str:
        result = self._agent_router(task, preferred_agent)
        if result.get("success"):
            return f"Routed to: {result['agent']} ({result['role']}) - {result['reason']}"
        return f"Error: {result.get('error')}"