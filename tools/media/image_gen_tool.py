"""Maya 2.0 - Image Generation Tool (Optional Provider)"""
import os


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
            return "Image generated successfully (binary data returned by provider)."
        except Exception as e:
            return f"Image generation error: {e}"
