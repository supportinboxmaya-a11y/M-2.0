
import os, base64

class MediaTool:
    def get_image_info(self, path):
        try:
            from PIL import Image
            with Image.open(path) as img:
                return {"success": True, "result": f"{img.format} {img.width}x{img.height} {img.mode}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def run(self, action="info", path="", **kwargs):
        if not path:
            return "Error: path required"
        if action == "info":
            r = self.get_image_info(path)
        else:
            r = {"success": False, "error": f"Unknown action: {action}"}
        return str(r.get("result", r.get("error", "Done")))
