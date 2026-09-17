"""
Maya 2.0 - Device Bridge
-------------------------
Lets a person pair their own desktop with Maya so the agent can queue
GUI actions (move mouse, click, type, screenshot) for a small LOCAL
script (see tools/bridge/maya_bridge_agent.py — distributed separately,
run BY THE PERSON on their own machine, never on this server) to poll
for and execute on that actual computer.

This is off by default and stays off until a person explicitly runs
the bridge script on their own computer with a pairing code generated
here. Nothing in this module — or anywhere else in this codebase — can
control a device that hasn't been paired.

Safety model:
  - Pairing requires a one-time code generated here (10 minute expiry)
    and entered into the local script — nothing can pair itself.
  - Commands just sit queued with no effect unless a live bridge is
    polling for that specific device.
  - Revoking a device immediately stops it from receiving further
    commands or authenticating.
  - This module holds no execution logic — it only tracks pairing,
    commands, and results. The actual mouse/keyboard/screen control
    happens exclusively in the separate local script.
  - State is in-memory (consistent with tasks_db and other in-process
    state elsewhere in api.py) — a server restart clears pairings, so
    devices need to be re-paired. That's a deliberate simplicity
    trade-off, not an oversight.
"""
import time
import uuid
from typing import Dict, List, Optional

PAIRING_CODE_TTL_SECONDS = 600


class DeviceBridge:
    def __init__(self):
        self._devices: Dict[str, dict] = {}
        self._pending_codes: Dict[str, dict] = {}
        self._commands: Dict[str, dict] = {}

    # ── pairing ──────────────────────────────────────────────
    def start_pairing(self, name: str) -> dict:
        code = uuid.uuid4().hex[:8].upper()
        self._pending_codes[code] = {"name": name or "My computer", "created_at": time.time()}
        return {"pairing_code": code, "name": self._pending_codes[code]["name"]}

    def complete_pairing(self, code: str) -> Optional[dict]:
        """Called by the local bridge script with the code a person typed
        in. Returns {device_id, secret} once, or None if the code is
        wrong or expired."""
        entry = self._pending_codes.pop((code or "").strip().upper(), None)
        if not entry or (time.time() - entry["created_at"]) > PAIRING_CODE_TTL_SECONDS:
            return None
        device_id = uuid.uuid4().hex[:12]
        secret = uuid.uuid4().hex
        self._devices[device_id] = {
            "id": device_id, "name": entry["name"], "secret": secret,
            "paired_at": time.time(), "last_seen": None,
        }
        return {"device_id": device_id, "secret": secret}

    def verify(self, device_id: str, secret: str) -> bool:
        d = self._devices.get(device_id)
        return bool(d and secret and d["secret"] == secret)

    def list_devices(self) -> List[dict]:
        return [{k: v for k, v in d.items() if k != "secret"} for d in self._devices.values()]

    def revoke(self, device_id: str) -> bool:
        return self._devices.pop(device_id, None) is not None

    # ── commands ─────────────────────────────────────────────
    def enqueue(self, device_id: str, action: str, params: dict) -> Optional[dict]:
        if device_id not in self._devices:
            return None
        cmd_id = uuid.uuid4().hex[:12]
        cmd = {
            "id": cmd_id, "device_id": device_id, "action": action,
            "params": params or {}, "status": "pending", "result": None,
            "created_at": time.time(),
        }
        self._commands[cmd_id] = cmd
        return cmd

    def poll(self, device_id: str) -> List[dict]:
        """The bridge script calls this — returns pending commands for
        this device and marks them 'sent' so they aren't handed out
        twice on the next poll."""
        if device_id in self._devices:
            self._devices[device_id]["last_seen"] = time.time()
        out = []
        for cmd in self._commands.values():
            if cmd["device_id"] == device_id and cmd["status"] == "pending":
                cmd["status"] = "sent"
                out.append(cmd)
        return out

    def report_result(self, command_id: str, result: dict) -> bool:
        cmd = self._commands.get(command_id)
        if not cmd:
            return False
        cmd["status"] = "done"
        cmd["result"] = result
        return True

    def get_command(self, command_id: str) -> Optional[dict]:
        return self._commands.get(command_id)

    def commands_for_device(self, device_id: str, limit: int = 50) -> List[dict]:
        cmds = [c for c in self._commands.values() if c["device_id"] == device_id]
        return sorted(cmds, key=lambda c: c["created_at"], reverse=True)[:limit]
