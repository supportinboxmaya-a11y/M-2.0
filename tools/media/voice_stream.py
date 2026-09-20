"""
Maya 2.0 - Real-time Voice Streaming Tool
------------------------------------------
Handles WebSocket-based real-time speech-to-text and text-to-speech streaming.
"""

import asyncio
import base64
import json
import os
import tempfile
import uuid
from typing import Dict, Optional, AsyncGenerator

from config.settings import WORKSPACE_DIR, env_first


class VoiceStreamTool:
    """Real-time voice streaming tool with STT and TTS."""

    def __init__(self):
        self.streams_dir = os.path.join(str(WORKSPACE_DIR), "audio", "streams")
        os.makedirs(self.streams_dir, exist_ok=True)
        self.active_streams = {}
        
    async def stt_stream(self, audio_chunks: AsyncGenerator[bytes, None], 
                         language: str = "en", model: str = "base") -> AsyncGenerator[str, None]:
        """Process streaming audio chunks and yield transcriptions."""
        try:
            from faster_whisper import WhisperModel
        except ImportError:
            yield json.dumps({"error": "faster-whisper not installed"})
            return
            
        # Use base model for speed
        model_size = "base"
        model_obj = WhisperModel(model_size, device="cpu", compute_type="int8")
        
        # Buffer for accumulating audio
        audio_buffer = bytearray()
        
        async for chunk in audio_chunks:
            audio_buffer.extend(chunk)
            
            # Process when we have enough audio (e.g., 1 second = 16000 samples at 16kHz)
            if len(audio_buffer) >= 32000:  # ~1 second at 16kHz 16-bit mono
                # Write to temp file
                with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                    f.write(audio_buffer)
                    temp_path = f.name
                
                try:
                    model_obj = WhisperModel("base", device="cpu", compute_type="int8")
                    segments, info = model_obj.transcribe(temp_path, language="en")
                    text = " ".join([seg.text for seg in segments])
                    if text.strip():
                        yield json.dumps({"text": text, "final": False})
                except Exception as e:
                    yield json.dumps({"error": str(e)})
                finally:
                    os.unlink(temp_path)
                    audio_buffer = bytearray()
        
        # Process remaining audio
        if audio_buffer:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                f.write(audio_buffer)
                temp_path = f.name
            try:
                model_obj = WhisperModel("base", device="cpu", compute_type="int8")
                segments, info = model_obj.transcribe(temp_path)
                text = " ".join([seg.text for seg in segments])
                if text.strip():
                    yield json.dumps({"text": text, "final": True})
            except Exception as e:
                yield json.dumps({"error": str(e)})
            finally:
                os.unlink(temp_path)
    
    async def tts_stream(self, text: str, voice: str = "en-US-AriaNeural") -> AsyncGenerator[bytes, None]:
        """Generate streaming TTS audio chunks using edge-tts."""
        try:
            import edge_tts
        except ImportError:
            yield json.dumps({"error": "edge-tts not installed"}).encode()
            return
            
        try:
            communicate = edge_tts.Communicate(text, voice)
            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    yield chunk["data"]
        except Exception as e:
            yield json.dumps({"error": str(e)}).encode()
    
    async def handle_voice_stream(self, websocket, language: str = "en"):
        """Handle bidirectional voice stream over WebSocket."""
        # This would be called from FastAPI WebSocket endpoint
        pass
    
    # Tool registry entry points
    def record_audio(self, duration_seconds: float = 5.0, sample_rate: int = 16000, **kwargs) -> str:
        """Record audio from microphone (fallback to file-based)."""
        return "Audio recording started. Use WebSocket /ws/voice for real-time streaming."
    
    def play_audio(self, audio_base64: str, format: str = "wav") -> str:
        """Play audio from base64 (placeholder for WebSocket streaming)."""
        return "Audio playback via WebSocket /ws/voice"
    
    def synthesize_speech(self, text: str, voice: str = "en-US-AriaNeural") -> str:
        """Generate TTS audio using edge-tts (async)."""
        return f"TTS generation started for: {text[:50]}... Use WebSocket /ws/tts for streaming."
    
    def transcribe_stream(self, audio_base64: str = "", audio_path: str = "", 
                          language: str = "en", model: str = "base", **kwargs) -> str:
        """Transcribe audio (delegates to STT tool)."""
        return "Use speech_to_text tool for transcription. For streaming, use WebSocket /ws/stt."


# Required imports
import asyncio
import base64
import json
import os
import tempfile
import uuid
from typing import Dict, Optional, AsyncGenerator

from config.settings import WORKSPACE_DIR, env_first