"""
Maya 2.0 - Device Control Tool
--------------------------------
Lets Maya reach onto a person's OWN paired computer for things a
headless browser can't do — click a native desktop app, take a full
screen screenshot, type into any window. This tool only ever queues a
command in infrastructure/device_bridge.py; the actual mouse/keyboard/
screen action happens in a separate local script the person runs
themselves (tools/bridge/maya_bridge_agent.py), never in this process.

Every command goes through the same human-approval gate as create_tool
(risk_level="critical" — this is more consequential than writing a
sandboxed tool, since it can touch anything on a real desktop), unless
approval_mode is explicitly "skip".

In headless/VPS mode, provides mock responses for testing.
"""

import os
import platform
import uuid
from typing import Optional, Dict, Any


class MockDeviceBridge:
    """Mock device bridge for headless/VPS environments."""
    
    def __init__(self):
        self.devices = [{
            "id": "mock-device-1",
            "name": "Mock Device (Headless Mode)",
            "status": "connected",
            "capabilities": ["move_mouse", "click", "type_text", "press_key", "screenshot"]
        }]
        self.commands = {}
    
    def list_devices(self) -> list:
        return self.devices
    
    def enqueue(self, device_id: str, action: str, params: dict) -> dict:
        cmd_id = f"cmd_{uuid.uuid4().hex[:8]}"
        self.commands[cmd_id] = {
            "id": cmd_id,
            "device_id": device_id,
            "action": action,
            "params": params,
            "status": "completed",
            "result": f"Mock execution of {action} with params: {params}",
            "timestamp": "2024-01-01T00:00:00Z"
        }
        return self.commands[cmd_id]
    
    def get_command(self, command_id: str) -> Optional[dict]:
        return self.commands.get(command_id)


class MockApprovalManager:
    """Mock approval manager for headless/VPS environments."""
    
    def needs_approval(self, action: str, risk_level: str = "medium") -> bool:
        return False  # Auto-approve in mock mode
    
    def request_approval(self, action: str, reason: str, risk_level: str = "medium") -> bool:
        return True  # Always approve in mock mode


class DeviceControlTool:
    def __init__(self, bridge=None, approval=None):
        # Detect headless/VPS environment
        self.is_headless = self._detect_headless()
        
        if self.is_headless or bridge is None:
            self.bridge = MockDeviceBridge()
            self.approval = MockApprovalManager()
            self.mock_mode = True
        else:
            self.bridge = bridge          # infrastructure.device_bridge.DeviceBridge
            self.approval = approval      # human.approval.ApprovalManager, or None
            self.mock_mode = False
    
    def _detect_headless(self) -> bool:
        """Detect if running in headless/VPS environment."""
        if not os.environ.get("DISPLAY") and platform.system() == "Linux":
            return True
        if os.environ.get("SSH_CONNECTION") or os.environ.get("SSH_CLIENT"):
            return True
        if os.path.exists("/.dockerenv"):
            return True
        return False

    def _pick_device(self, device_id: str = "") -> str:
        if device_id:
            return device_id
        devices = self.bridge.list_devices()
        return devices[0]["id"] if len(devices) == 1 else ""

    def control(self, action: str = "", device_id: str = "", reason: str = "", **params) -> str:
        """Queue a GUI action on a paired device. action: one of
        'move_mouse', 'click', 'type_text', 'press_key', 'screenshot'.
        Extra kwargs (x, y, text, key, ...) are passed through as the
        command's params. Returns a command id — use device_result(id)
        to check whether it ran and what happened, since this doesn't
        happen synchronously (a real desktop, not this server, runs it)."""
        if not action:
            return "Error: action is required (move_mouse, click, type_text, press_key, screenshot)"
        
        devices = self.bridge.list_devices()
        if not devices:
            if self.mock_mode:
                # In mock mode, create a mock device
                return self._mock_control(action, params)
            return ("Error: no device is paired. Ask the person to open Settings > "
                     "Device Bridge, generate a pairing code, and run the bridge "
                     "script on their computer first.")
        target = self._pick_device(device_id)
        if not target:
            names = ", ".join(f"{d['id']} ({d['name']})" for d in devices)
            return f"Error: multiple devices paired, specify device_id. Options: {names}"

        if self.approval is not None and self.approval.needs_approval(
            f"device_control:{action}", risk_level="critical"
        ):
            approved = self.approval.request_approval(
                action=f"Control paired device: {action} {params}",
                reason=reason or "(Maya did not give a reason)",
                risk_level="critical",
            )
            if not approved:
                return f"Not sent — human approval denied for device action '{action}'"

        cmd = self.bridge.enqueue(target, action, params)
        if not cmd:
            return f"Error: device {target} not found (was it unpaired?)"
        
        result = (f"Queued command {cmd['id']} ({action}) for device {target}. "
                f"It runs once the local bridge script picks it up — call "
                f"device_result with command_id='{cmd['id']}' to check on it.")
        if self.mock_mode:
            result += " [MOCK MODE]"
        return result
    
    def _mock_control(self, action: str, params: dict) -> str:
        """Mock control for headless mode."""
        cmd_id = f"mock_cmd_{uuid.uuid4().hex[:8]}"
        return (f"[MOCK] Queued command {cmd_id} ({action}) for mock device. "
                f"Params: {params}. Use device_result with command_id='{cmd_id}' to check.")

    def device_result(self, command_id: str = "", **kwargs) -> str:
        """Check the status/result of a previously queued device command."""
        if not command_id:
            return "Error: command_id is required"
        cmd = self.bridge.get_command(command_id)
        if not cmd:
            return f"Error: no such command {command_id}"
        if cmd["status"] in ("pending", "sent"):
            return f"Still {cmd['status']} — the bridge hasn't reported a result yet."
        result = f"Status: {cmd['status']}. Result: {cmd.get('result')}"
        if self.mock_mode:
            result += " [MOCK MODE]"
        return result


# For backward compatibility - provide a factory function
def create_device_control_tool(bridge=None, approval=None) -> DeviceControlTool:
    """Factory to create DeviceControlTool with appropriate bridge/approval."""
    return DeviceControlTool(bridge, approval)