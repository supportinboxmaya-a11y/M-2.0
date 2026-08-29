"""
Maya 2.0 ULTRA - Voice API Routes
Local STT/TTS endpoints for voice control.
"""
import os
import base64
import tempfile
import asyncio
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form, WebSocket, WebSocketDisconnect, Request, Body
from fastapi.responses import StreamingResponse
from typing import Optional
import logging

from infrastructure.stt_service import get_stt_service, TranscriptionResult

logger = logging.getLogger("voice_routes")

router = APIRouter(prefix="/api/v1/voice", tags=["voice"])


# Import auth at module level to avoid circular import issues
from api import get_current_user


@router.post("/transcribe")
async def voice_transcribe(
    request: Request,
    file: Optional[UploadFile] = File(None),
    audio_base64: Optional[str] = Form(None),
    language: Optional[str] = Form(None),
    user: dict = Depends(get_current_user),  # Use proper auth dependency
):
    """
    Transcribe audio using local faster-whisper.

    Accepts either:
    - multipart/form-data with 'file' (audio file)
    - form-data with 'audio_base64' (base64 encoded audio, with or without data: URL prefix)
    - JSON body with 'audio_base64' field

    Optional: language (e.g., 'en', 'es', 'fr') to force language detection.
    """

    audio_bytes = None

    if file:
        audio_bytes = await file.read()
    elif audio_base64:
        if "," in audio_base64 and audio_base64.strip().startswith("data:"):
            audio_base64 = audio_base64.split(",", 1)[1]
        try:
            audio_bytes = base64.b64decode(audio_base64)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid base64: {e}")
    else:
        # Try to get from JSON body
        try:
            body = await request.json()
            audio_base64 = body.get("audio_base64") or body.get("audio")
            if audio_base64:
                if "," in audio_base64 and audio_base64.strip().startswith("data:"):
                    audio_base64 = audio_base64.split(",", 1)[1]
                try:
                    audio_bytes = base64.b64decode(audio_base64)
                except Exception as e:
                    raise HTTPException(status_code=400, detail=f"Invalid base64: {e}")
        except Exception:
            pass
        
        if audio_bytes is None:
            raise HTTPException(status_code=400, detail="No audio provided (file or audio_base64)")

    if len(audio_bytes) > 25 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Audio too large (25MB max)")

    stt = get_stt_service()

    if language:
        original_lang = stt.language
        stt.language = language
    else:
        original_lang = None

    try:
        result: TranscriptionResult = await stt.transcribe_bytes(audio_bytes)

        return {
            "transcript": result.text,
            "language": result.language,
            "language_probability": result.language_probability,
            "duration": result.duration,
            "segments": result.segments,
        }
    except Exception as e:
        logger.error(f"Transcription failed: {e}")
        raise HTTPException(status_code=500, detail=f"Transcription failed: {e}")
    finally:
        if original_lang is not None:
            stt.language = original_lang


@router.websocket("/transcribe/ws")
async def voice_transcribe_ws(
    websocket: WebSocket,
    token: Optional[str] = None,
):
    """
    WebSocket endpoint for streaming transcription.
    Client sends audio chunks, server returns partial transcripts.

    Protocol:
    - Client connects with ?token=JWT
    - Client sends binary audio frames (16-bit PCM, 16kHz mono)
    - Server sends JSON: {"type": "partial", "text": "..."} or {"type": "final", "text": "..."}
    - Client sends {"type": "end"} to finalize
    """
    await websocket.accept()

    if token:
        try:
            import jwt
            from api import SECRET_KEY
            jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        except Exception:
            await websocket.send_json({"type": "error", "message": "Invalid token"})
            await websocket.close()
            return

    stt = get_stt_service()
    buffer = bytearray()
    sample_rate = 16000
    chunk_count = 0

    try:
        while True:
            message = await websocket.receive()

            if "bytes" in message:
                chunk = message["bytes"]
                buffer.extend(chunk)
                chunk_count += 1

                if chunk_count % 10 == 0 and len(buffer) > sample_rate * 2 * 3:  # ~3 seconds
                    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                        import wave
                        with wave.open(tmp.name, 'wb') as wf:
                            wf.setnchannels(1)
                            wf.setsampwidth(2)
                            wf.setframerate(sample_rate)
                            wf.writeframes(buffer)
                        tmp_path = tmp.name

                    try:
                        loop = asyncio.get_event_loop()
                        result = await loop.run_in_executor(None, stt.transcribe_file, tmp_path)
                        if result.text.strip():
                            await websocket.send_json({
                                "type": "partial",
                                "text": result.text.strip(),
                            })
                        buffer = bytearray()
                        chunk_count = 0
                    except Exception as e:
                        logger.error(f"Streaming transcription error: {e}")
                    finally:
                        try:
                            os.unlink(tmp_path)
                        except:
                            pass

            elif "text" in message:
                import json
                try:
                    data = json.loads(message["text"])
                    if data.get("type") == "end":
                        if buffer:
                            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                                import wave
                                with wave.open(tmp.name, 'wb') as wf:
                                    wf.setnchannels(1)
                                    wf.setsampwidth(2)
                                    wf.setframerate(sample_rate)
                                    wf.writeframes(buffer)
                                tmp_path = tmp.name

                            try:
                                loop = asyncio.get_event_loop()
                                result = await loop.run_in_executor(None, stt.transcribe_file, tmp_path)
                                await websocket.send_json({
                                    "type": "final",
                                    "text": result.text.strip(),
                                    "language": result.language,
                                    "duration": result.duration,
                                })
                            finally:
                                try:
                                    os.unlink(tmp_path)
                                except:
                                    pass
                        break
                except json.JSONDecodeError:
                    pass

    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        try:
            await websocket.send_json({"type": "error", "message": str(e)})
        except:
            pass
    finally:
        try:
            await websocket.close()
        except:
            pass


@router.get("/models")
async def voice_models(user: dict = Depends(get_current_user)):
    """List available Whisper models."""

    return {
        "current": os.getenv("WHISPER_MODEL_SIZE", "small"),
        "available": ["tiny", "base", "small", "medium", "large-v3"],
        "device": os.getenv("WHISPER_DEVICE", "cpu"),
        "compute_type": os.getenv("WHISPER_COMPUTE_TYPE", "int8"),
    }


@router.post("/models")
async def voice_set_model(
    model_size: str = Form(...),
    user: dict = Depends(get_current_user),
):
    """Change the Whisper model (requires reload)."""

    if model_size not in ["tiny", "base", "small", "medium", "large-v3"]:
        raise HTTPException(status_code=400, detail="Invalid model size")

    from infrastructure.stt_service import reset_stt_service
    reset_stt_service()
    os.environ["WHISPER_MODEL_SIZE"] = model_size

    stt = get_stt_service()
    return {"status": "ok", "model": model_size}