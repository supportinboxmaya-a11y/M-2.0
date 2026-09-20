"""
Maya 2.0 - Camera Tool
----------------------
Handles camera capture and streaming using OpenCV.
"""

import base64
import os
import tempfile
import uuid
from typing import Dict, Optional

from config.settings import WORKSPACE_DIR


class CameraTool:
    """Camera capture and streaming tool."""
    
    def __init__(self):
        self.captures_dir = os.path.join(str(WORKSPACE_DIR), "camera", "captures")
        self.stream_dir = os.path.join(str(WORKSPACE_DIR), "camera", "stream")
        os.makedirs(self.captures_dir, exist_ok=True)
        os.makedirs(self.stream_dir, exist_ok=True)
        
    def capture_image(
        self,
        camera_index: int = 0,
        width: int = 1920,
        height: int = 1080,
        fmt: str = "jpg",
        quality: int = 90
    ) -> Dict:
        """Capture a single image from camera."""
        try:
            import cv2
        except ImportError:
            return {"success": False, "error": "opencv-python not installed. Install with: pip install opencv-python-headless"}
        
        try:
            cap = cv2.VideoCapture(camera_index)
            if not cap.isOpened():
                return {"success": False, "error": f"Cannot open camera at index {camera_index}"}
            
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
            
            ret, frame = cap.read()
            cap.release()
            
            if not ret:
                return {"success": False, "error": "Failed to capture frame"}
            
            # Encode to specified format
            if fmt.lower() == "jpg":
                encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), quality]
                ext = "jpg"
            else:
                encode_param = [int(cv2.IMWRITE_PNG_COMPRESSION), 3]
                ext = "png"
            
            ret, buffer = cv2.imencode(f".{ext}", frame, encode_param)
            if not ret:
                return {"success": False, "error": "Failed to encode image"}
            
            # Save to file
            filename = f"capture_{uuid.uuid4().hex[:8]}.{ext}"
            filepath = os.path.join(self.captures_dir, filename)
            
            with open(filepath, 'wb') as f:
                f.write(buffer)
            
            # Return base64 encoded image
            img_b64 = base64.b64encode(buffer).decode()
            
            return {
                "success": True,
                "path": filepath,
                "image_base64": img_b64,
                "format": ext,
                "width": width,
                "height": height
            }
        except Exception as e:
            return {"success": False, "error": f"Capture failed: {str(e)}"}

    def start_stream(
        self,
        camera_index: int = 0,
        width: int = 640,
        height: int = 480,
        fps: int = 30
    ) -> Dict:
        """Start a camera stream (returns stream info for WebSocket)."""
        try:
            import cv2
        except ImportError:
            return {"success": False, "error": "opencv-python not installed"}
        
        # This would typically start a background thread/process for streaming
        # For now, return stream info for WebSocket handling
        return {
            "success": True,
            "stream_id": str(uuid.uuid4()),
            "camera_index": camera_index,
            "width": width,
            "height": height,
            "fps": fps,
            "stream_url": f"/ws/camera/stream/{{stream_id}}",
            "message": "Camera stream endpoint ready. Connect to WebSocket for streaming."
        }

    def capture_frame(self, stream_id: str = "", camera_index: int = 0) -> Dict:
        """Capture a single frame from an active stream or camera."""
        try:
            import cv2
        except ImportError:
            return {"success": False, "error": "opencv-python not installed"}
        
        try:
            cap = cv2.VideoCapture(camera_index)
            if not cap.isOpened():
                return {"success": False, "error": f"Cannot open camera at index {camera_index}"}
            
            ret, frame = cap.read()
            cap.release()
            
            if not ret:
                return {"success": False, "error": "Failed to capture frame"}
            
            # Encode as JPEG
            ret, buffer = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), 85])
            if not ret:
                return {"success": False, "error": "Failed to encode frame"}
            
            img_b64 = base64.b64encode(buffer).decode()
            
            return {
                "success": True,
                "frame_base64": img_b64,
                "format": "jpg",
                "timestamp": __import__('time').time()
            }
        except Exception as e:
            return {"success": False, "error": f"Frame capture failed: {str(e)}"}

    def process_frame(
        self,
        image: str = "",
        image_base64: str = "",
        image_path: str = "",
        prompt: str = "Analyze this image and describe what you see in detail.",
        vision_provider: str = "auto"
    ) -> Dict:
        """
        Process an incoming image frame with AI vision analysis.
        Accepts base64 encoded image or file path.
        """
        try:
            # Load image from base64 or path
            if image_base64 or image:
                import base64
                image_data = base64.b64decode(image_base64 or image)
                image_path = self._save_temp_image(image_data)
            elif image_path:
                if not os.path.isabs(image_path):
                    image_path = os.path.join(str(WORKSPACE_DIR), image_path)
                if not os.path.exists(image_path):
                    return {"success": False, "error": f"Image not found: {image_path}"}
            else:
                return {"success": False, "error": "No image provided. Provide image, image_base64, or image_path."}

            # Use vision tool to analyze
            try:
                from tools.media.vision_tool import VisionTool
                vision = VisionTool()
                result = vision.run(action="analyze", image=image_path, prompt=prompt)
                return {"success": True, "analysis": result}
            except Exception as e:
                return {"success": False, "error": f"Vision analysis failed: {str(e)}"}

        except Exception as e:
            return {"success": False, "error": f"Processing failed: {str(e)}"}

    def _save_temp_image(self, image_data: bytes) -> str:
        """Save image data to temp file and return path."""
        import tempfile
        import uuid
        temp_dir = os.path.join(str(WORKSPACE_DIR), "camera", "temp")
        os.makedirs(temp_dir, exist_ok=True)
        filename = f"frame_{uuid.uuid4().hex[:8]}.jpg"
        filepath = os.path.join(temp_dir, filename)
        with open(filepath, 'wb') as f:
            f.write(image_data)
        return filepath

    def capture(self, camera_index: int = 0, width: int = 1920, height: int = 1080, fmt: str = "jpg", quality: int = 90, **kwargs) -> str:
        result = self.capture_image(camera_index, width, height, fmt, quality)
        if result.get("success"):
            return f"Image captured: {result['path']} (base64: {result.get('image_base64', '')[:50]}...)"
        return f"Error: {result.get('error')}"

    def stream(self, camera_index: int = 0, width: int = 640, height: int = 480, fps: int = 30, **kwargs) -> str:
        result = self.start_stream(camera_index, width, height, fps)
        if result.get("success"):
            return f"Stream started: {result['stream_id']} at {result['stream_url']}"
        return f"Error: {result.get('error')}"

    def frame(self, stream_id: str = "", camera_index: int = 0, **kwargs) -> str:
        result = self.capture_frame(stream_id, camera_index)
        if result.get("success"):
            return f"Frame captured (base64: {result.get('frame_base64', '')[:50]}...)"
        return f"Error: {result.get('error')}"


# Required imports
import base64
import os
import tempfile
import uuid
from typing import Dict, Optional

from config.settings import WORKSPACE_DIR
import base64