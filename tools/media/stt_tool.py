"""
Maya 2.0 - Speech-to-Text Tool
-------------------------------
Converts speech to text using faster-whisper (local) or OpenAI Whisper API.
"""

import base64
import os
import tempfile
from typing import Dict, Optional


class STTTool:
    """Speech -> Text using faster-whisper (local) or OpenAI Whisper API."""

    def transcribe(
        self,
        audio_data: Optional[bytes] = None,
        audio_base64: Optional[str] = None,
        audio_path: Optional[str] = None,
        language: Optional[str] = None,
        model: str = "base",
        language_detection: bool = True,
        vad_filter: bool = False
    ) -> Dict:
        """
        Transcribe audio to text.
        
        Args:
            audio_data: Raw audio bytes
            audio_base64: Base64 encoded audio
            audio_path: Path to audio file in workspace
            language: Language code (e.g., 'en', 'es', 'fr') or None for auto-detect
            model: Whisper model size (tiny, base, small, medium, large, large-v2, large-v3)
            language_detection: Whether to auto-detect language
            vad_filter: Whether to use Voice Activity Detection filter
            
        Returns:
            Dict with transcription result
        """
        # Load audio from various sources
        audio_file = self._load_audio(audio_data, audio_base64, audio_path)
        if not audio_file:
            return {"success": False, "error": "No audio provided. Provide audio_data, audio_base64, or audio_path."}

        try:
            # Use faster-whisper for local inference (fast, no API key needed)
            return self._transcribe_local(audio_file, language, model, language_detection, vad_filter)
        except Exception as e:
            # Fallback to OpenAI Whisper API if available
            return self._transcribe_openai(audio_file, language)

    def _load_audio(self, audio_data: Optional[bytes], audio_base64: Optional[str], audio_path: Optional[str]) -> Optional[str]:
        """Load audio from various sources and return path to temp file."""
        if audio_path:
            # Handle workspace path
            if not os.path.isabs(audio_path):
                full_path = os.path.join(str(WORKSPACE_DIR), audio_path)
            else:
                full_path = audio_path
            if os.path.exists(full_path):
                return full_path
            return None
        
        # Create temp file from audio data
        if audio_base64:
            audio_data = base64.b64decode(audio_base64)
        
        if audio_data:
            # Create temp file with appropriate extension
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                f.write(audio_data)
                return f.name
        
        return None

    def _transcribe_local(self, audio_file: str, language: Optional[str], model: str, language_detection: bool, vad_filter: bool = False) -> Dict:
        """Use faster-whisper for local transcription."""
        try:
            from faster_whisper import WhisperModel
        except ImportError:
            return {"success": False, "error": "faster-whisper not installed. Install with: pip install faster-whisper"}

        try:
            # Load model (downloads on first use)
            model_size = model if model in ["tiny", "base", "small", "medium", "large", "large-v2", "large-v3"] else "base"
            model_obj = WhisperModel(model_size, device="cpu", compute_type="int8")
            
            # Transcribe
            segments, info = model_obj.transcribe(
                audio_file,
                language=language if not language_detection else None,
                vad_filter=vad_filter,
                vad_parameters=dict(min_silence_duration_ms=500)
            )
            
            # Collect segments
            text_parts = []
            segments_info = []
            for segment in segments:
                text_parts.append(segment.text)
                segments_info.append({
                    "start": segment.start,
                    "end": segment.end,
                    "text": segment.text
                })
            
            # Handle case where no segments are detected
            if not text_parts:
                return {
                    "success": True,
                    "text": "",
                    "language": info.language,
                    "language_probability": info.language_probability,
                    "segments": [],
                    "duration": info.duration,
                    "note": "No speech detected in audio"
                }
            
            full_text = " ".join(text_parts).strip()
            
            return {
                "success": True,
                "text": full_text,
                "language": info.language,
                "language_probability": info.language_probability,
                "segments": segments_info,
                "duration": info.duration
            }
        except Exception as e:
            return {"success": False, "error": f"Local transcription failed: {str(e)}"}

    def _transcribe_openai(self, audio_file: str, language: Optional[str]) -> Dict:
        """Fallback to OpenAI Whisper API."""
        key = os.environ.get("OPENAI_KEY") or os.environ.get("OPENAI_API_KEY")
        if not key:
            return {"success": False, "error": "No OpenAI API key configured for fallback"}
        
        try:
            from openai import OpenAI
            client = OpenAI(api_key=key)
            
            with open(audio_file, "rb") as f:
                transcript = client.audio.transcriptions.create(
                    model="whisper-1",
                    file=f,
                    language=language,
                    response_format="verbose_json"
                )
            
            return {
                "success": True,
                "text": transcript.text,
                "language": transcript.language,
                "duration": transcript.duration
            }
        except Exception as e:
            return {"success": False, "error": f"OpenAI transcription failed: {str(e)}"}

    # Tool-registry entry point
    def run(self, audio_base64: str = "", audio_path: str = "", language: str = "", model: str = "base", vad_filter: bool = False, **kwargs) -> str:
        """Tool registry entry point.
        
        Args:
            audio_base64: Base64 encoded audio data
            audio_path: Path to audio file in workspace
            language: Language code (optional, auto-detect if empty)
            model: Whisper model size (tiny, base, small, medium, large, large-v2, large-v3)
            vad_filter: Enable Voice Activity Detection filter
        """
        result = self.transcribe(
            audio_base64=audio_base64,
            audio_path=audio_path,
            language=language if language else None,
            model=model,
            vad_filter=vad_filter
        )
        
        if result.get("success"):
            return f"Transcription: {result['text']}"
        return f"Error: {result.get('error')}"


class _NotConfigured(Exception):
    """Provider key absent -- silently try the next provider."""
    pass

# Add required imports at top
import base64
import os
import tempfile
from typing import Dict, Optional
from config.settings import env_first, WORKSPACE_DIR