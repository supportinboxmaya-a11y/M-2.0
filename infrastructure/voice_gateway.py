"""
Maya 2.0 ULTRA - Voice Gateway
WebSocket server that connects phone client -> STT -> Maya Agent -> TTS -> phone client.
"""
import os
import json
import logging
import asyncio
import uuid
from typing import Optional, Dict, Any
from dataclasses import dataclass, field
from datetime import datetime

from fastapi import WebSocket, WebSocketDisconnect, Depends, HTTPException
import jwt

from infrastructure.stt_service import get_stt_service, TranscriptionResult
from infrastructure.tts_service import get_tts_service, TTSResult

logger = logging.getLogger("voice_gateway")


@dataclass
class VoiceSession:
    """Represents a voice conversation session."""
    session_id: str
    user_id: str
    created_at: datetime = field(default_factory=datetime.utcnow)
    last_activity: datetime = field(default_factory=datetime.utcnow)
    message_count: int = 0
    context: Dict[str, Any] = field(default_factory=dict)


class VoiceGateway:
    """
    Voice Gateway - connects phone client to Maya's agent core via STT/TTS.
    
    Flow:
    1. Phone connects via WebSocket with JWT token
    2. Phone sends audio chunks (binary)
    3. Gateway buffers audio, sends to STT when utterance complete
    4. STT returns transcript
    5. Gateway sends transcript to Maya's agent core (reuse existing chat endpoint)
    6. Maya returns text response
    7. Gateway sends text to TTS
    8. TTS returns audio
    9. Gateway streams audio back to phone
    """
    
    def __init__(self):
        self.sessions: Dict[str, VoiceSession] = {}
        self.active_connections: Dict[str, WebSocket] = {}
        self.stt = get_stt_service()
        self.tts = get_tts_service()
        self._audio_buffers: Dict[str, bytearray] = {}
        self._sample_rate = 16000  # Expected from phone client
        self._chunk_timeout = 3.0  # seconds of silence before processing
        
    async def authenticate(self, token: str) -> Optional[dict]:
        """Validate JWT token and return user info."""
        try:
            from api import SECRET_KEY
            payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            return {"email": payload.get("sub"), "uid": payload.get("uid", ""), "role": payload.get("role", "admin")}
        except Exception as e:
            logger.warning(f"Auth failed: {e}")
            return None
    
    def create_session(self, user: dict) -> VoiceSession:
        """Create a new voice session."""
        session_id = str(uuid.uuid4())[:8]
        session = VoiceSession(
            session_id=session_id,
            user_id=user.get("uid") or user.get("email", "unknown"),
        )
        self.sessions[session_id] = session
        self._audio_buffers[session_id] = bytearray()
        logger.info(f"Created voice session {session_id} for user {session.user_id}")
        return session
    
    def get_session(self, session_id: str) -> Optional[VoiceSession]:
        """Get session by ID."""
        return self.sessions.get(session_id)
    
    def cleanup_session(self, session_id: str):
        """Clean up session resources."""
        self.sessions.pop(session_id, None)
        self._audio_buffers.pop(session_id, None)
        logger.info(f"Cleaned up voice session {session_id}")
    
    async def process_audio_chunk(self, session_id: str, chunk: bytes) -> Optional[str]:
        """
        Buffer audio chunk and return transcript if utterance complete.
        Returns transcript text if ready, None if still buffering.
        """
        buffer = self._audio_buffers.get(session_id, bytearray())
        buffer.extend(chunk)
        self._audio_buffers[session_id] = buffer
        
        # Simple VAD: process if we have enough audio (~2 seconds at 16kHz 16-bit mono)
        min_bytes = self._sample_rate * 2 * 2  # 2 seconds
        if len(buffer) >= min_bytes:
            # Save buffer to temp file and transcribe
            import tempfile
            import wave
            
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                with wave.open(tmp.name, 'wb') as wf:
                    wf.setnchannels(1)
                    wf.setsampwidth(2)
                    wf.setframerate(self._sample_rate)
                    wf.writeframes(buffer)
                tmp_path = tmp.name
            
            try:
                loop = asyncio.get_event_loop()
                result: TranscriptionResult = await loop.run_in_executor(
                    None, self.stt.transcribe_file, tmp_path
                )
                
                # Clear buffer after processing
                self._audio_buffers[session_id] = bytearray()
                
                if result.text.strip():
                    return result.text.strip()
                    
            except Exception as e:
                logger.error(f"STT error: {e}")
            finally:
                try:
                    os.unlink(tmp_path)
                except:
                    pass
        
        return None
    
    async def send_to_maya(self, session_id: str, text: str) -> str:
        """
        Send transcribed text to Maya's agent core and get response.
        Reuses the existing chat endpoint logic.
        """
        session = self.get_session(session_id)
        if not session:
            return "Session not found"
        
        try:
            from api import maya_instance
            
            # Use Maya's existing chat pipeline
            if maya_instance:
                # Maya.chat(message, history=None, scope="")
                # Use session_id as scope for conversation memory
                response = maya_instance.chat(
                    message=text,
                    history=session.context.get("history"),
                    scope=f"voice_{session_id}",
                )
                return str(response)
            else:
                return "Maya not initialized"
                
        except Exception as e:
            logger.error(f"Maya chat error: {e}")
            return f"Error: {str(e)}"
    
    async def synthesize_response(self, text: str) -> bytes:
        """Convert Maya's text response to audio."""
        try:
            audio_bytes = await self.tts.synthesize_bytes_async(text)
            return audio_bytes
        except Exception as e:
            logger.error(f"TTS error: {e}")
            return b""
    
    async def log_turn(self, session_id: str, transcript: str, maya_response: str, audio_size: int):
        """Log each conversation turn for debugging."""
        session = self.get_session(session_id)
        if session:
            session.message_count += 1
            session.last_activity = datetime.utcnow()
            
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "session_id": session_id,
            "user_id": session.user_id if session else "unknown",
            "turn": session.message_count if session else 0,
            "input_transcript": transcript,
            "maya_response": maya_response[:200] + "..." if len(maya_response) > 200 else maya_response,
            "output_audio_bytes": audio_size,
        }
        logger.info(f"VOICE_TURN: {json.dumps(log_entry)}")


# Global gateway instance
_voice_gateway: Optional[VoiceGateway] = None


def get_voice_gateway() -> VoiceGateway:
    """Get or create the global voice gateway instance."""
    global _voice_gateway
    if _voice_gateway is None:
        _voice_gateway = VoiceGateway()
    return _voice_gateway