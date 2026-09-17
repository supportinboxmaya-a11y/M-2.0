"""Maya 2.0 - Image Generation Tool (saves output to workspace)"""
import base64
import os
import time

from config.settings import WORKSPACE_DIR


class ImageGenTool:
    def __init__(self):
        self.stability_key = os.environ.get("STABILITY_KEY", "")

    def run(self, prompt: str = "", **kwargs) -> str:
        if not prompt:
            return "Error: prompt required"

        if not self.stability_key:
            return (
                "Image generation is not configured. "
                "Set STABILITY_KEY (or another image provider key) as an "
                "environment variable to enable this tool."
            )

        try:
            import requests
            r = requests.post(
                "https://api.stability.ai/v2beta/stable-image/generate/core",
                headers={
                    "authorization": f"Bearer {self.stability_key}",
                    "accept": "application/json",
                },
                files={"none": ""},
                data={"prompt": prompt, "output_format": "png"},
                timeout=60,
            )
            if r.status_code != 200:
                return f"Image generation failed: {r.status_code} {r.text[:200]}"
            payload = r.json()
            b64 = payload.get("image", "")
            if not b64:
                return f"Image generation failed: no image in response ({str(payload)[:200]})"
            out_dir = os.path.join(str(WORKSPACE_DIR), "images")
            os.makedirs(out_dir, exist_ok=True)
            path = os.path.join(out_dir, f"gen_{int(time.time() * 1000)}.png")
            with open(path, "wb") as f:
                f.write(base64.b64decode(b64))
            return f"Image generated and saved: {path}"
        except Exception as e:
            return f"Image generation error: {e}"
