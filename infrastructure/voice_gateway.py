"""
Maya 2.0 ULTRA - Enhanced Voice Gateway with VAD, Wake Word, and Tier 3 Integration
=====================================================================================
Enhancements:
1. Voice Activity Detection (VAD) - Silero VAD for precise utterance boundaries
2. Wake Word Detection - "Hey Maya" activation
3. Tier 3 Autonomous Agent Pipeline - Direct integration with Tier 3 for planning/execution
"""
import os
import json
import logging
import asyncio
import uuid
import wave
import tempfile
import struct
from typing import Optional, Dict, Any, List, Callable
from dataclasses import dataclass, field
from datetime import datetime
from collections import deque

from fastapi import WebSocket, WebSocketDisconnect, Depends, HTTPException
import jwt

from infrastructure.stt_service import get_stt_service, TranscriptionResult
from infrastructure.tts_service import get_tts_service, TTSResult, reset_tts_service
from infrastructure.extended_agent import get_extended_agent, ExtendedAgent, TaskType, TaskStatus
from infrastructure.tier3_autonomous import Tier3System, create_tier3_system

logger = logging.getLogger("voice_gateway")


# ════════════════════════════════════════════════════════════════════════════════
# VAD (Voice Activity Detection) - Silero VAD Integration
# ════════════════════════════════════════════════════════════════════════════════

class VADProcessor:
    """
    Voice Activity Detection using Silero VAD.
    Provides precise speech/non-speech boundaries for streaming audio.
    """
    
    def __init__(self, sample_rate: int = 16000, threshold: float = 0.5):
        self.sample_rate = sample_rate
        self.threshold = threshold
        self._model = None
        self._vad_loaded = False
        self._chunk_size = 512  # 512 samples = 32ms at 16kHz
        
    def _load_model(self):
        """Load Silero VAD model lazily."""
        if self._vad_loaded:
            return
        try:
            import torch
            logger.info("Loading Silero VAD model...")
            self._model, _ = torch.hub.load(
                repo_or_dir='snakers4/silero-vad',
                model='silero_vad',
                force_reload=False,
                trust_repo=True
            )
            self._vad_loaded = True
            logger.info("Silero VAD loaded successfully")
        except Exception as e:
            logger.warning(f"Silero VAD load failed, using energy-based fallback: {e}")
            self._model = None
            self._vad_loaded = True
    
    def is_speech(self, audio_chunk: bytes) -> bool:
        """Check if audio chunk contains speech."""
        self._load_model()
        
        if len(audio_chunk) < self._chunk_size * 2:
            return False
            
        # Convert to float32 tensor
        try:
            import numpy as np
            audio_np = np.frombuffer(audio_chunk[:self._chunk_size * 2], dtype=np.int16).astype(np.float32) / 32768.0
            
            if self._model is not None:
                # Use Silero VAD
                import torch
                tensor = torch.from_numpy(audio_np).unsqueeze(0)
                speech_prob = self._model(tensor, self.sample_rate).item()
                return speech_prob > self.threshold
            else:
                # Fallback: energy-based VAD
                energy = np.mean(audio_np ** 2)
                return energy > 0.001  # Threshold for speech energy
                
        except Exception as e:
            logger.debug(f"VAD error: {e}")
            return False
    
    def process_stream(self, audio_chunks: List[bytes]) -> List[Dict]:
        """
        Process a stream of audio chunks and return speech segments.
        Returns list of {"is_speech": bool, "chunk": bytes, "speech_prob": float}
        """
        self._load_model()
        results = []
        
        for chunk in audio_chunks:
            is_speech = self.is_speech(chunk)
            results.append({
                "is_speech": is_speech,
                "chunk": chunk,
                "timestamp": datetime.utcnow().isoformat()
            })
        
        return results


# ════════════════════════════════════════════════════════════════════════════════
# Wake Word Detector - "Hey Maya" Detection
# ════════════════════════════════════════════════════════════════════════════════

class WakeWordDetector:
    """
    Wake word detection using openWakeWord or simple keyword matching on STT output.
    Supports "Hey Maya" activation phrase.
    """
    
    def __init__(self, wake_words: List[str] = None, threshold: float = 0.7):
        self.wake_words = wake_words or ["hey maya", "hey mia", "okay maya", "hello maya"]
        self.threshold = threshold
        self._model = None
        self._loaded = False
        
    def _load_model(self):
        """Load openWakeWord model if available."""
        if self._loaded:
            return
        try:
            # Try to load openWakeWord for real-time wake word detection
            from openwakeword.model import Model
            self._model = Model(wakeword_models=["hey_jarvis"])  # Closest available
            self._loaded = True
            logger.info("Wake word model loaded (openWakeWord)")
        except Exception as e:
            logger.info(f"openWakeWord not available, using STT-based detection: {e}")
            self._model = None
            self._loaded = True
    
    def detect_in_stt(self, transcript: str) -> bool:
        """Detect wake word in STT transcript (fallback method)."""
        text = transcript.lower().strip()
        for wake in self.wake_words:
            if wake in text:
                logger.info(f"Wake word detected via STT: '{wake}' in '{transcript}'")
                return True
        return False
    
    def detect_in_audio(self, audio_chunk: bytes) -> bool:
        """Detect wake word directly from audio (if model available)."""
        self._load_model()
        if self._model is None:
            return False
        try:
            import numpy as np
            audio_np = np.frombuffer(audio_chunk, dtype=np.int16).astype(np.float32) / 32768.0
            prediction = self._model.predict(audio_np)
            # Check if any wake word exceeds threshold
            for key, prob in prediction.items():
                if prob > self.threshold:
                    logger.info(f"Wake word detected in audio: {key} ({prob:.2f})")
                    return True
        except Exception as e:
            logger.debug(f"Wake word audio detection error: {e}")
        return False


# ════════════════════════════════════════════════════════════════════════════════
# Audio Buffer with VAD-based Utterance Segmentation
# ════════════════════════════════════════════════════════════════════════════════

@dataclass
class AudioSegment:
    """Represents a segmented utterance from audio stream."""
    audio_data: bytes
    start_time: float
    end_time: float
    sample_rate: int
    is_speech: bool
    confidence: float = 1.0


class VADAudioBuffer:
    """
    Audio buffer with VAD-based utterance segmentation.
    Handles streaming audio and segments into speech/non-speech regions.
    """
    
    def __init__(self, sample_rate: int = 16000, vad_threshold: float = 0.5,
                 min_speech_duration: float = 0.5, max_silence_duration: float = 1.5):
        self.sample_rate = sample_rate
        self.vad = VADProcessor(sample_rate, vad_threshold)
        self.min_speech_duration = min_speech_duration  # seconds
        self.max_silence_duration = max_silence_duration  # seconds
        
        # Buffer state
        self._buffer = bytearray()
        self._speech_buffer = bytearray()
        self._in_speech = False
        self._silence_chunks = 0
        self._speech_chunks = 0
        self._chunk_duration = 0.032  # 512 samples at 16kHz = 32ms
        self._max_buffer_duration = 30.0  # Max buffer before forced flush
        self._total_duration = 0.0
        
    def add_chunk(self, chunk: bytes) -> List[AudioSegment]:
        """
        Add audio chunk and return any completed speech segments.
        """
        segments = []
        self._buffer.extend(chunk)
        self._total_duration += self._chunk_duration
        
        # Run VAD on chunk
        is_speech = self.vad.is_speech(chunk)
        
        if is_speech:
            self._speech_chunks += 1
            self._silence_chunks = 0
            self._speech_buffer.extend(chunk)
            
            if not self._in_speech and self._speech_chunks * self._chunk_duration >= self.min_speech_duration:
                self._in_speech = True
                logger.debug("Speech started")
                
        else:
            self._silence_chunks += 1
            
            if self._in_speech:
                self._speech_buffer.extend(chunk)  # Include trailing silence
                
                # Check if silence is long enough to end utterance
                silence_duration = self._silence_chunks * self._chunk_duration
                if silence_duration >= self.max_silence_duration:
                    # End of utterance
                    segments = self._flush_speech_buffer()
                    segments_returned = segments
                    self._in_speech = False
                    return segments_returned
        
        # Force flush if buffer too long
        if self._total_duration > self._max_buffer_duration:
            if self._in_speech:
                segments = self._flush_speech_buffer()
                return segments
            else:
                self._buffer = bytearray()
                self._total_duration = 0.0
        
        return []
    
    def _flush_speech_buffer(self) -> List[AudioSegment]:
        """Flush speech buffer and return as segment."""
        if len(self._speech_buffer) == 0:
            return []
            
        segment = AudioSegment(
            audio_data=bytes(self._speech_buffer),
            start_time=self._total_duration - (len(self._speech_buffer) / (self.sample_rate * 2)),
            end_time=self._total_duration,
            sample_rate=self.sample_rate,
            is_speech=True,
            confidence=1.0
        )
        
        self._speech_buffer = bytearray()
        self._speech_chunks = 0
        self._silence_chunks = 0
        return [segment]
    
    def flush_all(self) -> List[AudioSegment]:
        """Flush any remaining speech."""
        if self._in_speech and len(self._speech_buffer) > 0:
            return self._flush_speech_buffer()
        return []
    
    def reset(self):
        """Reset buffer state."""
        self._buffer = bytearray()
        self._speech_buffer = bytearray()
        self._in_speech = False
        self._silence_chunks = 0
        self._speech_chunks = 0
        self._total_duration = 0.0


# ════════════════════════════════════════════════════════════════════════════════
# Voice Session with VAD and Wake Word
# ════════════════════════════════════════════════════════════════════════════════

@dataclass
class VoiceSession:
    """Represents a voice conversation session."""
    session_id: str
    user_id: str
    created_at: datetime = field(default_factory=datetime.utcnow)
    last_activity: datetime = field(default_factory=datetime.utcnow)
    message_count: int = 0
    context: Dict[str, Any] = field(default_factory=dict)
    
    # VAD and wake word state
    vad_buffer: VADAudioBuffer = field(default_factory=lambda: VADAudioBuffer())
    wake_detector: WakeWordDetector = field(default_factory=WakeWordDetector)
    wake_word_active: bool = False  # Whether wake word has been detected
    listening_mode: bool = True  # True = waiting for wake word, False = active listening
    
    def reset_vad(self):
        """Reset VAD buffer for new utterance."""
        self.vad_buffer.reset()


# ════════════════════════════════════════════════════════════════════════════════
# Tier 3 Integration - Autonomous Execution Pipeline
# ════════════════════════════════════════════════════════════════════════════════

class Tier3VoiceExecutor:
    """
    Executes voice commands through Tier 3 Autonomous System.
    Integrates with Tier 3 for planning, execution, learning, and skill distillation.
    """
    
    def __init__(self):
        self.tier3: Optional[Tier3System] = None
        self._initialized = False
        
    def _ensure_initialized(self):
        """Lazy initialize Tier 3 system using Maya instance components."""
        if not self._initialized:
            try:
                from api.api import maya_instance
                if maya_instance:
                    # Extract components from Maya instance (same as auto_init_tier3)
                    tool_registry = None
                    if hasattr(maya_instance, 'tool_manager') and maya_instance.tool_manager:
                        tool_registry = maya_instance.tool_manager.get_registry()
                    
                    self.tier3 = Tier3System(
                        llm_fn=maya_instance.router.chat if hasattr(maya_instance, 'router') and hasattr(maya_instance.router, 'chat') else None,
                        tool_registry=tool_registry,
                        sandbox=maya_instance.executor if hasattr(maya_instance, 'executor') else None,
                        memory=maya_instance.memory if hasattr(maya_instance, 'memory') else None
                    )
                else:
                    raise RuntimeError("Maya instance not available")
            except Exception as e:
                logger.error(f"Failed to initialize Tier 3: {e}")
                raise
            self._initialized = True
            
    async def execute_voice_goal(self, session_id: str, transcript: str, 
                                  user_id: str, context: Dict = None) -> Dict:
        """
        Execute a voice command as a Tier 3 goal.
        Returns execution result with plan, steps, and outcome.
        """
        self._ensure_initialized()
        
        try:
            # Submit goal to Tier 3
            result = await self.tier3.execute_goal(
                goal=transcript,
                user_id=user_id,
                session_id=session_id,
                context=context or {},
                mode="voice"  # Voice-specific mode
            )
            
            return {
                "success": result.get("success", False),
                "result": result.get("result", ""),
                "error": result.get("error", ""),
                "plan": result.get("plan", []),
                "steps_completed": result.get("steps_completed", 0),
                "total_steps": result.get("total_steps", 0),
                "skills_used": result.get("skills_used", []),
                "learned": result.get("learned", False)
            }
            
        except Exception as e:
            logger.error(f"Tier 3 execution failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "result": ""
            }
    
    async def get_tier3_status(self) -> Dict:
        """Get Tier 3 system status."""
        self._ensure_initialized()
        return await self.tier3.get_status()


# ════════════════════════════════════════════════════════════════════════════════
# Main Voice Gateway with All Enhancements
# ════════════════════════════════════════════════════════════════════════════════

class VoiceGateway:
    """
    Enhanced Voice Gateway with VAD, Wake Word, and Tier 3 Integration.
    
    Flow:
    1. Phone connects via WebSocket with JWT token
    2. Phone sends audio chunks (binary, 16kHz 16-bit mono)
    3. Gateway buffers audio through VAD processor
    4. Wake word detector monitors for "Hey Maya"
    5. When wake word detected -> activate listening mode
    6. VAD segments utterances -> sends to STT when complete
    7. STT returns transcript -> Tier 3 executes goal
    8. Tier 3 returns result -> TTS synthesizes response
    9. Audio streamed back to phone
    """
    
    def __init__(self):
        self.sessions: Dict[str, VoiceSession] = {}
        self.active_connections: Dict[str, WebSocket] = {}
        self.stt = get_stt_service()
        self.tts = get_tts_service()
        self.tier3_executor = Tier3VoiceExecutor()
        self.extended_agent = get_extended_agent()
        
        # Audio settings
        self._sample_rate = 16000
        self._chunk_size = 512  # 32ms chunks
        
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
        logger.info(f"Created voice session {session_id} for user {session.user_id}")
        return session
    
    def get_session(self, session_id: str) -> Optional[VoiceSession]:
        """Get session by ID."""
        return self.sessions.get(session_id)
    
    def cleanup_session(self, session_id: str):
        """Clean up session resources."""
        self.sessions.pop(session_id, None)
        self.active_connections.pop(session_id, None)
        logger.info(f"Cleaned up voice session {session_id}")

    async def process_audio_stream(self, session_id: str, chunk: bytes) -> List[Dict]:
        """
        Process incoming audio chunk through VAD and wake word detection.
        Returns list of events to send to client.
        """
        events = []
        session = self.get_session(session_id)
        if not session:
            return [{"type": "error", "message": "Session not found"}]
        
        # Add chunk to VAD buffer
        segments = session.vad_buffer.add_chunk(chunk)
        
        # Check for wake word in audio (real-time)
        if session.listening_mode and not session.wake_word_active:
            if session.wake_detector.detect_in_audio(chunk):
                session.wake_word_active = True
                session.listening_mode = False
                events.append({
                    "type": "wake_word_detected",
                    "message": "Wake word detected! Listening...",
                    "session_id": session_id
                })
                # Play acknowledgment sound
                ack_audio = await self.tts.synthesize_bytes_async("Yes?")
                if ack_audio:
                    import base64
                    events.append({
                        "type": "acknowledgment",
                        "audio_base64": base64.b64encode(ack_audio).decode()
                    })
        
        # Process completed speech segments
        for segment in segments:
            if segment.is_speech and len(segment.audio_data) > 1600:  # At least 0.1s
                # Transcribe
                result = await self.stt.transcribe_bytes(segment.audio_data)
                
                if result.text.strip():
                    transcript = result.text.strip()
                    
                    # Check for wake word in transcript (fallback)
                    if session.listening_mode and not session.wake_word_active:
                        if session.wake_detector.detect_in_stt(transcript):
                            session.wake_word_active = True
                            session.listening_mode = False
                            events.append({
                                "type": "wake_word_detected",
                                "message": "Wake word detected! Listening...",
                                "session_id": session_id
                            })
                            continue  # Don't process as command yet
                    
                    if session.wake_word_active:
                        # Send transcript to client
                        events.append({
                            "type": "transcript",
                            "text": transcript,
                            "language": result.language,
                            "confidence": result.language_probability
                        })
                        
                        # Process through Tier 3
                        events.append({"type": "thinking"})
                        
                        tier3_result = await self.tier3_executor.execute_voice_goal(
                            session_id=session_id,
                            transcript=transcript,
                            user_id=session.user_id,
                            context=session.context
                        )
                        
                        if tier3_result.get("success"):
                            response_text = tier3_result.get("result", "")
                            
                            # Synthesize response
                            audio_bytes = await self.tts.synthesize_bytes_async(response_text)
                            
                            if audio_bytes:
                                import base64
                                events.append({
                                    "type": "speaking",
                                    "audio_base64": base64.b64encode(audio_bytes).decode(),
                                    "text": response_text,
                                    "plan": tier3_result.get("plan", []),
                                    "skills_used": tier3_result.get("skills_used", [])
                                })
                            
                            # Update session
                            session.message_count += 1
                            session.last_activity = datetime.utcnow()
                            session.wake_word_active = False  # Reset for next command
                            session.listening_mode = True
                            
                            events.append({"type": "turn_complete"})
                            
                            # Log turn
                            await self.log_turn(session_id, transcript, response_text, len(audio_bytes))
                        else:
                            # Error response
                            error_msg = tier3_result.get("error", "Unknown error")
                            logger.error(f"Tier 3 execution failed: {error_msg}")
                            error_audio = await self.tts.synthesize_bytes_async(f"Sorry, I encountered an error: {error_msg}")
                            if error_audio:
                                import base64
                                events.append({
                                    "type": "speaking",
                                    "audio_base64": base64.b64encode(error_audio).decode(),
                                    "text": f"Error: {error_msg}"
                                })
                            events.append({"type": "turn_complete"})
        
        return events

    async def send_to_maya_fallback(self, session_id: str, text: str) -> str:
        """Fallback to Extended Agent for voice command."""
        try:
            ext_agent = self.extended_agent
            result = await ext_agent.process_voice_command(
                session_id=session_id,
                transcript=text,
                user_id=self.get_session(session_id).user_id if self.get_session(session_id) else ""
            )
            return result.get("result", "Task completed")
        except Exception as e:
            logger.error(f"Extended agent fallback failed: {e}")
            return f"Error: {e}"

    async def synthesize_response(self, text: str) -> bytes:
        """Convert Maya's text response to audio."""
        try:
            return await self.tts.synthesize_bytes_async(text)
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


# ════════════════════════════════════════════════════════════════════════════════
# Module Singleton
# ════════════════════════════════════════════════════════════════════════════════

_voice_gateway: Optional[VoiceGateway] = None


def get_voice_gateway() -> VoiceGateway:
    """Get or create the global voice gateway instance."""
    global _voice_gateway
    if _voice_gateway is None:
        _voice_gateway = VoiceGateway()
    return _voice_gateway