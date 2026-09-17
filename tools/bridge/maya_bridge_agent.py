#!/usr/bin/env python3
"""
Maya Bridge Agent — run this on YOUR OWN computer, NOT on the server.

Lets Maya (running in the cloud) queue GUI actions (mouse, keyboard,
screenshot) that THIS script executes locally, on THIS machine, after
you explicitly pair it below. Nothing happens on your computer unless
you run this script and pair it with a code from the Maya web app.

Requirements (install locally — this is not part of the server's
requirements.txt and never runs on Render):
    pip install requests pyautogui pillow

Usage:
    1. In the Maya web app: Settings > Device Bridge > "Generate
       pairing code". Note the 8-character code and the backend URL
       shown there.
    2. Run: python maya_bridge_agent.py
    3. Paste the backend URL and pairing code when prompted.
    4. Leave this running. Ctrl+C to stop — a stopped bridge can't
       execute anything, so that's also your kill switch.

Safety:
    - Every command this script runs already passed Maya's own
      approval flow on the server (human/approval.py) before being
      queued — but a paired device still grants real control of THIS
      computer's mouse and keyboard, so only pair machines you're
      genuinely comfortable with Maya interacting with.
    - pyautogui's built-in fail-safe is on: slam the mouse into any
      screen corner to immediately abort whatever it's doing.
    - Every action is printed to this terminal as it happens.
    - Revoke a pairing any time from Settings > Device Bridge, or just
      stop this script.
"""
import sys
import time

try:
    import requests
except ImportError:
    print("Missing dependency. Run: pip install requests pyautogui pillow")
    sys.exit(1)


def main():
    backend_url = input("Backend URL (e.g. http://130.210.46.182:8000/api/v1): ").strip().rstrip("/")
    code = input("Pairing code from Settings > Device Bridge: ").strip().upper()

    try:
        resp = requests.post(f"{backend_url}/device/pair/complete", json={"code": code}, timeout=15)
    except requests.RequestException as e:
        print(f"Could not reach backend: {e}")
        sys.exit(1)
    if resp.status_code != 200:
        print(f"Pairing failed: {resp.status_code} {resp.text}")
        sys.exit(1)
    creds = resp.json()
    device_id, secret = creds["device_id"], creds["secret"]
    print(f"Paired. device_id={device_id}")
    print("Leave this running. Ctrl+C to stop.\n")

    try:
        import pyautogui
        pyautogui.FAILSAFE = True  # slam mouse into a screen corner to abort
    except ImportError:
        pyautogui = None
        print("WARNING: pyautogui isn't installed — commands will be reported as failed.")
        print("Run: pip install pyautogui pillow\n")

    while True:
        try:
            resp = requests.get(
                f"{backend_url}/device/{device_id}/commands",
                params={"secret": secret}, timeout=15,
            )
            commands = resp.json().get("commands", []) if resp.status_code == 200 else []
            for cmd in commands:
                result = execute(cmd, pyautogui)
                print(f"[{cmd['action']}] -> {result}")
                requests.post(
                    f"{backend_url}/device/commands/{cmd['id']}/result",
                    json={"device_id": device_id, "secret": secret, "result": result},
                    timeout=15,
                )
        except requests.RequestException as e:
            print(f"(connection issue, retrying) {e}")
        except KeyboardInterrupt:
            print("\nStopped. No further commands will run.")
            break
        time.sleep(2)


def execute(cmd: dict, pyautogui) -> dict:
    if pyautogui is None:
        return {"ok": False, "error": "pyautogui not installed on this machine"}
    action = cmd.get("action", "")
    p = cmd.get("params", {}) or {}
    try:
        if action == "move_mouse":
            pyautogui.moveTo(int(p["x"]), int(p["y"]), duration=0.2)
            return {"ok": True}
        if action == "click":
            if "x" in p and "y" in p:
                pyautogui.click(int(p["x"]), int(p["y"]))
            else:
                pyautogui.click()
            return {"ok": True}
        if action == "type_text":
            pyautogui.write(str(p.get("text", "")), interval=0.02)
            return {"ok": True}
        if action == "press_key":
            pyautogui.press(str(p.get("key", "")))
            return {"ok": True}
        if action == "screenshot":
            import base64
            import io
            img = pyautogui.screenshot()
            buf = io.BytesIO()
            img.save(buf, format="PNG")
            b64 = base64.b64encode(buf.getvalue()).decode()
            return {"ok": True, "image_base64": b64}
        return {"ok": False, "error": f"unknown action: {action}"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


if __name__ == "__main__":
    main()
