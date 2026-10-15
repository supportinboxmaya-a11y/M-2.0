"""
Maya 2.0 ULTRA — Multi-Modal Routes
====================================
Handles multi-modal processing endpoints (vision, audio, document).
"""
from fastapi import APIRouter, HTTPException, File, UploadFile, Form, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import base64
import jwt
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from infrastructure.multimodal import get_multimodal_processor
from config.settings import SECRET_KEY, JWT_ALGORITHM

router = APIRouter(prefix="/multimodal", tags=["multimodal"])

# Auth dependency - uses the same SECRET_KEY as api.py
security = HTTPBearer(auto_error=False)

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """Returns {'email', 'uid', 'role'} - same as api.py"""
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return {"email": payload.get("sub"), "uid": payload.get("uid", ""), "role": payload.get("role", "admin")}
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")


# ─── Request/Response Models ──────────────────────────────────────
class ImageProcessRequest(BaseModel):
    image: str  # base64 or data URL
    tasks: Optional[List[str]] = None  # ["caption", "classify", "embed", "detect"]
    labels: Optional[List[str]] = None  # for zero-shot classification


class AudioProcessRequest(BaseModel):
    audio: str  # base64 audio data
    task: str = "transcribe"  # "transcribe", "translate"


class DocumentProcessRequest(BaseModel):
    document: str  # base64 document data
    extract_tables: bool = False
    extract_figures: bool = False
    question: Optional[str] = None  # for QA


class MultimodalResponse(BaseModel):
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


# ─── Helper ───────────────────────────────────────────────────────
def _decode_base64(data: str) -> bytes:
    """Decode base64 string, handling data URLs."""
    if "," in data:
        data = data.split(",")[1]
    # Fix padding
    data = data.rstrip("=")
    pad_needed = (4 - len(data) % 4) % 4
    data = data + "=" * pad_needed
    return base64.b64decode(data, validate=False)


# ─── Endpoints ────────────────────────────────────────────────────
@router.post("/image", response_model=MultimodalResponse)
async def process_image(req: ImageProcessRequest, user=Depends(get_current_user)):
    """Process image with vision models (CLIP/SigLIP)."""
    try:
        processor = await get_multimodal_processor()
        image_bytes = _decode_base64(req.image)
        result = await processor.process_image(image_bytes, req.tasks, req.labels)
        return MultimodalResponse(success=True, data=result)
    except Exception as e:
        return MultimodalResponse(success=False, error=str(e))


@router.post("/audio", response_model=MultimodalResponse)
async def process_audio(req: AudioProcessRequest, user=Depends(get_current_user)):
    """Process audio with Whisper transcription."""
    try:
        processor = await get_multimodal_processor()
        audio_bytes = _decode_base64(req.audio)
        result = await processor.process_audio(audio_bytes)
        return MultimodalResponse(success=True, data=result)
    except Exception as e:
        return MultimodalResponse(success=False, error=str(e))


@router.post("/document", response_model=MultimodalResponse)
async def process_document(req: DocumentProcessRequest, user=Depends(get_current_user)):
    """Process document with LayoutLM/Donut."""
    try:
        processor = await get_multimodal_processor()
        doc_bytes = _decode_base64(req.document)
        result = await processor.process_document(
            doc_bytes,
            extract_tables=req.extract_tables,
            extract_figures=req.extract_figures,
            question=req.question,
        )
        return MultimodalResponse(success=True, data=result)
    except Exception as e:
        return MultimodalResponse(success=False, error=str(e))


# ─── Health Check ─────────────────────────────────────────────────
@router.get("/health")
async def health_check(user=Depends(get_current_user)):
    """Health check for multi-modal processor."""
    try:
        processor = await get_multimodal_processor()
        initialized = processor._initialized
        return {"status": "healthy" if initialized else "initializing", "initialized": initialized}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}


__all__ = ["router"]