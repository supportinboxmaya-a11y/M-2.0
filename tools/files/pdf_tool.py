"""Maya 2.0 - PDF Tool (Sandboxed PDF Reader)"""
import os
from config.settings import WORKSPACE_DIR
from security.sandbox import Sandbox


class PDFTool:
    def __init__(self):
        self.workspace = str(WORKSPACE_DIR)
        self.sandbox = Sandbox()
        self.max_size = 20 * 1024 * 1024  # 20MB

    def run(self, path: str = "", max_pages: int = 30, **kwargs) -> str:
        if not path:
            return "Error: path required"

        try:
            safe_path = self.sandbox.safe_path(path)
        except PermissionError as e:
            return f"Error: {e}"

        if not os.path.exists(safe_path):
            return f"Error: File not found: {path}"

        if os.path.getsize(safe_path) > self.max_size:
            return "Error: File too large (max 20MB)"

        try:
            import PyPDF2
            with open(safe_path, "rb") as f:
                reader = PyPDF2.PdfReader(f)
                pages = reader.pages[:max_pages]
                text_parts = []
                for i, page in enumerate(pages, 1):
                    text = page.extract_text() or ""
                    if text.strip():
                        text_parts.append(f"--- Page {i} ---\n{text.strip()}")
                if not text_parts:
                    return "No extractable text found (PDF may be scanned/image-based)"
                result = "\n\n".join(text_parts)
                return result[:8000]
        except Exception as e:
            return f"Error reading PDF: {e}"
