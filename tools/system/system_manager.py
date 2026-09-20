"""
Maya 2.0 - System Management Tools
Provides service management, system stats, port management, and process control.
"""

import subprocess
import shutil
import os
import socket
from typing import Dict, List, Optional
from config.settings import WORKSPACE_DIR
from pathlib import Path


try:
    import psutil
    _HAS_PSUTIL = True
except ImportError:
    _HAS_PSUTIL = False


class SystemManagerTool:
    """System and process management for VPS operations."""
    
    def __init__(self):
        self.workspace = Path(WORKSPACE_DIR)
        
    def _check_service_status(self, service_name: str) -> dict:
        """Check systemd service status."""
        try:
            result = subprocess.run(
                ["systemctl", "is-active", service_name],
                capture_output=True, text=True, timeout=10
            )
            is_active = result.stdout.strip() == "active"
            
            # Get more details
            result2 = subprocess.run(
                ["systemctl", "status", service_name, "--no-pager"],
                capture_output=True, text=True, timeout=10
            )
            
            return {
                "success": True,
                "service": service_name,
                "active": is_active,
                "status": result.stdout.strip(),
                "details": result2.stdout[:2000]
            }
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "Timeout checking service"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _restart_service(self, service_name: str) -> dict:
        """Restart a systemd service (requires sudo)."""
        try:
            # Check if we can use sudo
            result = subprocess.run(
                ["sudo", "systemctl", "restart", service_name],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0:
                # Verify it's running
                status = self._check_service_status(service_name)
                return {"success": True, "message": f"Service {service_name} restarted", "status": status}
            else:
                return {"success": False, "error": result.stderr or "Failed to restart service"}
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "Timeout restarting service"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _system_stats(self) -> dict:
        """Get comprehensive system statistics."""
        try:
            stats = {}
            
            # CPU
            stats["cpu_percent"] = psutil.cpu_percent(interval=0.5) if _HAS_PSUTIL else "N/A"
            stats["cpu_count"] = psutil.cpu_count() if _HAS_PSUTIL else "N/A"
            
            # Memory
            if _HAS_PSUTIL:
                mem = psutil.virtual_memory()
                stats["memory"] = {
                    "total_gb": round(mem.total / (1024**3), 2),
                    "available_gb": round(mem.available / (1024**3), 2),
                    "used_gb": round(mem.used / (1024**3), 2),
                    "percent": mem.percent
                }
                
                swap = psutil.swap_memory()
                stats["swap"] = {
                    "total_gb": round(swap.total / (1024**3), 2),
                    "used_gb": round(swap.used / (1024**3), 2),
                    "percent": swap.percent
                }
            else:
                stats["memory"] = "psutil not available"
                stats["swap"] = "psutil not available"
            
            # Disk
            disk = shutil.disk_usage("/")
            stats["disk"] = {
                "total_gb": round(disk.total / (1024**3), 2),
                "used_gb": round(disk.used / (1024**3), 2),
                "free_gb": round(disk.free / (1024**3), 2),
                "percent": round(disk.used / disk.total * 100, 1)
            }
            
            # Workspace disk
            ws_disk = shutil.disk_usage(str(self.workspace))
            stats["workspace_disk"] = {
                "total_gb": round(ws_disk.total / (1024**3), 2),
                "used_gb": round(ws_disk.used / (1024**3), 2),
                "free_gb": round(ws_disk.free / (1024**3), 2),
                "percent": round(ws_disk.used / ws_disk.total * 100, 1)
            }
            
            # Load average
            if hasattr(os, 'getloadavg'):
                stats["load_avg"] = os.getloadavg()
            
            # Network interfaces
            if _HAS_PSUTIL:
                net = psutil.net_io_counters()
                stats["network"] = {
                    "bytes_sent": net.bytes_sent,
                    "bytes_recv": net.bytes_recv
                }
            
            return {"success": True, "stats": stats}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _manage_ports(self, action: str = "list", port: int = None, protocol: str = "tcp") -> dict:
        """Manage firewall ports (list, open, close)."""
        try:
            if action == "list":
                result = subprocess.run(
                    ["sudo", "iptables", "-L", "INPUT", "-v", "-n"],
                    capture_output=True, text=True, timeout=10
                )
                return {"success": True, "output": result.stdout}
            
            elif action == "open" and port:
                # Check if rule exists first
                check = subprocess.run(
                    ["sudo", "iptables", "-C", "INPUT", "-p", protocol, "--dport", str(port), "-j", "ACCEPT"],
                    capture_output=True
                )
                if check.returncode == 0:
                    return {"success": True, "message": f"Port {port}/{protocol} already open"}
                
                result = subprocess.run(
                    ["sudo", "iptables", "-A", "INPUT", "-p", protocol, "--dport", str(port), "-j", "ACCEPT"],
                    capture_output=True, text=True, timeout=10
                )
                if result.returncode == 0:
                    # Save rules
                    subprocess.run(["sudo", "netfilter-persistent", "save"], capture_output=True)
                    return {"success": True, "message": f"Port {port}/{protocol} opened and saved"}
                return {"success": False, "error": result.stderr}
            
            elif action == "close" and port:
                result = subprocess.run(
                    ["sudo", "iptables", "-D", "INPUT", "-p", protocol, "--dport", str(port), "-j", "ACCEPT"],
                    capture_output=True, text=True, timeout=10
                )
                if result.returncode == 0:
                    subprocess.run(["sudo", "netfilter-persistent", "save"], capture_output=True)
                    return {"success": True, "message": f"Port {port}/{protocol} closed and saved"}
                return {"success": False, "error": result.stderr}
            
            return {"success": False, "error": "Invalid action. Use: list, open, close"}
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "Timeout managing ports"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _kill_process(self, pid: int, force: bool = False) -> dict:
        """Kill a process by PID."""
        if not _HAS_PSUTIL:
            return {"success": False, "error": "psutil not installed"}
        
        try:
            proc = psutil.Process(pid)
            if force:
                proc.kill()
            else:
                proc.terminate()
            proc.wait(timeout=5)
            return {"success": True, "message": f"Process {pid} terminated"}
        except psutil.NoSuchProcess:
            return {"success": False, "error": f"No such process: {pid}"}
        except psutil.AccessDenied:
            return {"success": False, "error": f"Permission denied killing process {pid}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _check_port(self, port: int, host: str = "0.0.0.0") -> dict:
        """Check if a port is listening."""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            result = sock.connect_ex((host, port))
            sock.close()
            return {
                "success": True,
                "port": port,
                "host": host,
                "listening": result == 0
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    # Tool registry entry points (no recursion - call internal methods with _ prefix)
    def check_service_status(self, service_name: str, **kwargs) -> str:
        result = self._check_service_status(service_name)
        if result.get("success"):
            return f"Service {service_name}: {'ACTIVE' if result['active'] else 'INACTIVE'} ({result['status']})"
        return f"Error: {result.get('error')}"

    def restart_service(self, service_name: str, **kwargs) -> str:
        result = self._restart_service(service_name)
        if result.get("success"):
            return f"Service {service_name} restarted successfully"
        return f"Error: {result.get('error')}"

    def system_stats(self, **kwargs) -> str:
        result = self._system_stats()
        if result.get("success"):
            import json
            return json.dumps(result["stats"], indent=2)
        return f"Error: {result.get('error')}"

    def manage_ports(self, action: str = "list", port: int = None, protocol: str = "tcp", **kwargs) -> str:
        result = self._manage_ports(action, port, protocol)
        if result.get("success"):
            return result.get("message", result.get("output", "Done"))
        return f"Error: {result.get('error')}"

    def kill_process(self, pid: int, force: bool = False, **kwargs) -> str:
        result = self._kill_process(pid, force)
        if result.get("success"):
            return result["message"]
        return f"Error: {result.get('error')}"

    def check_port(self, port: int, host: str = "0.0.0.0", **kwargs) -> str:
        result = self._check_port(port, host)
        if result.get("success"):
            return f"Port {port} on {host}: {'LISTENING' if result['listening'] else 'NOT LISTENING'}"
        return f"Error: {result.get('error')}"