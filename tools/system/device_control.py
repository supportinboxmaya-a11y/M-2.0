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
"""


class DeviceControlTool:
    def __init__(self, bridge, approval=None):
        self.bridge = bridge          # infrastructure.device_bridge.DeviceBridge
        self.approval = approval      # human.approval.ApprovalManager, or None

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
        return (f"Queued command {cmd['id']} ({action}) for device {target}. "
                f"It runs once the local bridge script picks it up — call "
                f"device_result with command_id='{cmd['id']}' to check on it.")

    def device_result(self, command_id: str = "", **kwargs) -> str:
        """Check the status/result of a previously queued device command."""
        if not command_id:
            return "Error: command_id is required"
        cmd = self.bridge.get_command(command_id)
        if not cmd:
            return f"Error: no such command {command_id}"
        if cmd["status"] in ("pending", "sent"):
            return f"Still {cmd['status']} — the bridge hasn't reported a result yet."
        return f"Status: {cmd['status']}. Result: {cmd.get('result')}"
