"""
Maya 2.0 ULTRA - Voice API Routes
Local STT/TTS endpoints for voice control + Voice Gateway WebSocket.
"""
import os
import base64
import tempfile
import asyncio
import json
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form, WebSocket, WebSocketDisconnect, Request, Body
from fastapi.responses import StreamingResponse, FileResponse
from typing import Optional
import logging

from infrastructure.stt_service import get_stt_service, TranscriptionResult
from infrastructure.tts_service import get_tts_service, TTSResult, reset_tts_service
from infrastructure.voice_gateway import get_voice_gateway, VoiceGateway

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


# ═══════════════════════════════════════════════════════════
# TTS ENDPOINTS
# ═══════════════════════════════════════════════════════════

@router.post("/synthesize")
async def voice_synthesize(
    text: str = Form(...),
    voice: Optional[str] = Form(None),
    length_scale: Optional[float] = Form(None),
    noise_scale: Optional[float] = Form(None),
    noise_w: Optional[float] = Form(None),
    user: dict = Depends(get_current_user),
):
    """
    Synthesize text to speech using Piper TTS.

    Args:
        text: Text to synthesize (required)
        voice: Voice model to use (optional, overrides default)
        length_scale: Speech speed multiplier (optional)
        noise_scale: Variation scale (optional)
        noise_w: Phoneme duration variation (optional)

    Returns:
        Audio file (WAV) as streaming response
    """
    tts = get_tts_service()

    # Temporarily override voice settings if provided
    original_voice = tts.voice_model
    original_length = tts.length_scale
    original_noise = tts.noise_scale
    original_noise_w = tts.noise_w

    if voice:
        tts.voice_model = voice
        tts._voice_loaded = False  # Force reload
    if length_scale is not None:
        tts.length_scale = length_scale
    if noise_scale is not None:
        tts.noise_scale = noise_scale
    if noise_w is not None:
        tts.noise_w = noise_w

    try:
        audio_bytes = await tts.synthesize_bytes_async(text)

        from fastapi.responses import Response
        return Response(
            content=audio_bytes,
            media_type="audio/wav",
            headers={
                "Content-Disposition": f'inline; filename="speech.wav"',
                "X-Sample-Rate": str(tts._voice.config.sample_rate if tts._voice else 22050),
            },
        )
    except Exception as e:
        logger.error(f"TTS synthesis failed: {e}")
        raise HTTPException(status_code=500, detail=f"Synthesis failed: {e}")
    finally:
        # Restore original settings
        tts.voice_model = original_voice
        tts.length_scale = original_length
        tts.noise_scale = original_noise
        tts.noise_w = original_noise_w
        if voice:
            tts._voice_loaded = False


@router.post("/synthesize/json")
async def voice_synthesize_json(
    request: Request,
    user: dict = Depends(get_current_user),
):
    """
    Synthesize text to speech (JSON body).

    Body:
        text: Text to synthesize (required)
        voice: Voice model (optional)
        length_scale: Speech speed (optional)
        noise_scale: Variation (optional)
        noise_w: Phoneme variation (optional)

    Returns:
        JSON with base64 encoded audio
    """
    import base64

    body = await request.json()
    text = body.get("text")
    if not text:
        raise HTTPException(status_code=400, detail="Missing 'text' field")

    voice = body.get("voice")
    length_scale = body.get("length_scale")
    noise_scale = body.get("noise_scale")
    noise_w = body.get("noise_w")

    tts = get_tts_service()

    original_voice = tts.voice_model
    original_length = tts.length_scale
    original_noise = tts.noise_scale
    original_noise_w = tts.noise_w

    if voice:
        tts.voice_model = voice
        tts._voice_loaded = False
    if length_scale is not None:
        tts.length_scale = length_scale
    if noise_scale is not None:
        tts.noise_scale = noise_scale
    if noise_w is not None:
        tts.noise_w = noise_w

    try:
        audio_bytes = await tts.synthesize_bytes_async(text)
        audio_b64 = base64.b64encode(audio_bytes).decode()

        return {
            "audio_base64": audio_b64,
            "format": "wav",
            "sample_rate": tts._voice.config.sample_rate if tts._voice else 22050,
            "text": text,
        }
    except Exception as e:
        logger.error(f"TTS synthesis failed: {e}")
        raise HTTPException(status_code=500, detail=f"Synthesis failed: {e}")
    finally:
        tts.voice_model = original_voice
        tts.length_scale = original_length
        tts.noise_scale = original_noise
        tts.noise_w = original_noise_w
        if voice:
            tts._voice_loaded = False


@router.get("/voices")
async def voice_list(user: dict = Depends(get_current_user)):
    """List available Piper voice models."""
    tts = get_tts_service()
    voices = tts.get_available_voices()

    return {
        "current": tts.voice_model,
        "available": voices,
        "model_dir": tts.model_dir,
    }


@router.post("/voices")
async def voice_set_voice(
    voice: str = Form(...),
    user: dict = Depends(get_current_user),
):
    """Change the Piper voice model (requires reload)."""
    tts = get_tts_service()

    if voice not in tts.get_available_voices():
        raise HTTPException(status_code=400, detail=f"Voice '{voice}' not found. Available: {tts.get_available_voices()}")

    reset_tts_service()
    os.environ["PIPER_VOICE_MODEL"] = voice

    tts = get_tts_service()
    return {"status": "ok", "voice": voice}


# ═══════════════════════════════════════════════════════════
# VOICE GATEWAY WEBSOCKET (Phone Client <-> Maya)
# ═══════════════════════════════════════════════════════════

@router.websocket("/gateway")
async def voice_gateway_ws(
    websocket: WebSocket,
    token: Optional[str] = None,
):
    """
    Voice Gateway WebSocket endpoint.
    
    Protocol:
    - Client connects with ?token=JWT
    - Server sends: {"type": "connected", "session_id": "..."}
    - Client sends binary audio chunks (16-bit PCM, 16kHz mono)
    - Server sends: {"type": "listening"} when buffering
    - Server sends: {"type": "transcript", "text": "..."} when STT completes
    - Server sends: {"type": "thinking"} while Maya processes
    - Server sends: {"type": "speaking", "audio_base64": "..."} with TTS audio
    - Server sends: {"type": "turn_complete"} when done
    - Client can send JSON: {"type": "ping"} -> {"type": "pong"}
    - Client can send JSON: {"type": "end"} to close session
    """
    await websocket.accept()
    
    if not token:
        await websocket.send_json({"type": "error", "message": "Missing token parameter"})
        await websocket.close()
        return
    
    gateway = get_voice_gateway()
    
    # Authenticate
    user = await gateway.authenticate(token)
    if not user:
        await websocket.send_json({"type": "error", "message": "Invalid token"})
        await websocket.close()
        return
    
    # Create session
    session = gateway.create_session(user)
    session_id = session.session_id
    
    # Register connection
    gateway.active_connections[session_id] = websocket
    
    try:
        await websocket.send_json({
            "type": "connected",
            "session_id": session_id,
            "message": "Voice gateway ready. Send audio chunks (16kHz 16-bit mono)."
        })
        
        while True:
            message = await websocket.receive()
            
            if "bytes" in message:
                # Binary audio chunk from phone
                chunk = message["bytes"]
                
                # Process audio chunk (buffers and transcribes when ready)
                transcript = await gateway.process_audio_chunk(session_id, chunk)
                
                if transcript:
                    # Got transcript - send to Maya
                    await websocket.send_json({
                        "type": "transcript",
                        "text": transcript,
                    })
                    
                    await websocket.send_json({"type": "thinking"})
                    
                    # Send to Maya's agent core
                    maya_response = await gateway.send_to_maya(session_id, transcript)
                    
                    # Synthesize response
                    audio_bytes = await gateway.synthesize_response(maya_response)
                    
                    if audio_bytes:
                        audio_b64 = base64.b64encode(audio_bytes).decode()
                        await websocket.send_json({
                            "type": "speaking",
                            "audio_base64": audio_b64,
                            "text": maya_response,
                        })
                    
                    # Log the turn
                    await gateway.log_turn(session_id, transcript, maya_response, len(audio_bytes))
                    
                    await websocket.send_json({"type": "turn_complete"})
                    
            elif "text" in message:
                # JSON control messages
                try:
                    data = json.loads(message["text"])
                    msg_type = data.get("type")
                    
                    if msg_type == "ping":
                        await websocket.send_json({"type": "pong"})
                    elif msg_type == "end":
                        break
                    elif msg_type == "text":
                        # Direct text input (bypass STT)
                        text = data.get("text", "")
                        if text:
                            await websocket.send_json({"type": "thinking"})
                            maya_response = await gateway.send_to_maya(session_id, text)
                            audio_bytes = await gateway.synthesize_response(maya_response)
                            if audio_bytes:
                                audio_b64 = base64.b64encode(audio_bytes).decode()
                                await websocket.send_json({
                                    "type": "speaking",
                                    "audio_base64": audio_b64,
                                    "text": maya_response,
                                })
                            await gateway.log_turn(session_id, text, maya_response, len(audio_bytes))
                            await websocket.send_json({"type": "turn_complete"})
                            
                except json.JSONDecodeError:
                    pass
                    
    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.error(f"Voice gateway error: {e}")
        try:
            await websocket.send_json({"type": "error", "message": str(e)})
        except:
            pass
    finally:
        # Cleanup
        gateway.cleanup_session(session_id)
        gateway.active_connections.pop(session_id, None)
        try:
            await websocket.close()
        except:
            pass


@router.get("/gateway/sessions")
async def voice_gateway_sessions(user: dict = Depends(get_current_user)):
    """List active voice gateway sessions."""
    gateway = get_voice_gateway()
    sessions = []
    for session_id, session in gateway.sessions.items():
        sessions.append({
            "session_id": session_id,
            "user_id": session.user_id,
            "created_at": session.created_at.isoformat(),
            "last_activity": session.last_activity.isoformat(),
            "message_count": session.message_count,
        })
    return {"sessions": sessions, "count": len(sessions)}