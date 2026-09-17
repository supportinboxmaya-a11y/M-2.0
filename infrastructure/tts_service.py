"""
Maya 2.0 ULTRA - Text-to-Speech Service
Local Piper TTS synthesis service for voice control.
"""
import os
import logging
import tempfile
import asyncio
from pathlib import Path
from typing import Optional, AsyncGenerator
from dataclasses import dataclass

logger = logging.getLogger("tts_service")


@dataclass
class TTSResult:
    audio_path: str
    sample_rate: int
    duration: float
    text: str


class TTSService:
    """Piper TTS synthesis service."""

    def __init__(
        self,
        voice_model: str = "en_US-amy-medium",
        model_dir: Optional[str] = None,
        length_scale: float = 1.0,
        noise_scale: float = 0.667,
        noise_w: float = 0.8,
    ):
        """
        Initialize the TTS service.

        Args:
            voice_model: Voice model name (must exist in model_dir)
            model_dir: Directory containing .onnx and .onnx.json files
            length_scale: Speech speed (1.0 = normal, >1.0 = slower)
            noise_scale: Variation in speech (higher = more variation)
            noise_w: Phoneme duration variation
        """
        self.voice_model = voice_model
        self.model_dir = model_dir or os.getenv("PIPER_MODEL_DIR", "/home/ubuntu/M-2.0/models/piper")
        self.length_scale = length_scale
        self.noise_scale = noise_scale
        self.noise_w = noise_w
        self._voice = None
        self._voice_loaded = False

    def _load_voice(self):
        """Load the Piper voice model lazily."""
        if self._voice_loaded:
            return

        logger.info(f"Loading Piper voice: {self.voice_model} from {self.model_dir}")
        try:
            import piper

            model_path = Path(self.model_dir) / f"{self.voice_model}.onnx"
            config_path = Path(self.model_dir) / f"{self.voice_model}.onnx.json"

            if not model_path.exists():
                raise FileNotFoundError(f"Voice model not found: {model_path}")
            if not config_path.exists():
                raise FileNotFoundError(f"Voice config not found: {config_path}")

            self._voice = piper.PiperVoice.load(str(model_path))
            self._voice_loaded = True
            logger.info(f"TTS voice loaded: {self.voice_model} (sample_rate={self._voice.config.sample_rate})")
        except Exception as e:
            logger.error(f"Failed to load TTS voice: {e}")
            raise

    def synthesize(self, text: str) -> TTSResult:
        """
        Synthesize text to speech and save to a WAV file.

        Args:
            text: Text to synthesize

        Returns:
            TTSResult with audio file path and metadata
        """
        self._load_voice()

        import wave
        import io
        from piper.config import SynthesisConfig

        syn_config = SynthesisConfig(
            length_scale=self.length_scale,
            noise_scale=self.noise_scale,
            noise_w_scale=self.noise_w,
        )

        buffer = io.BytesIO()
        with wave.open(buffer, 'wb') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(self._voice.config.sample_rate)
            for chunk in self._voice.synthesize(text, syn_config=syn_config):
                if hasattr(chunk, 'audio_int16_bytes'):
                    wf.writeframes(chunk.audio_int16_bytes)

        # Save to temp file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            tmp.write(buffer.getvalue())
            tmp_path = tmp.name

        # Calculate duration
        num_frames = len(buffer.getvalue()) // 2  # 16-bit = 2 bytes per sample
        duration = num_frames / self._voice.config.sample_rate

        return TTSResult(
            audio_path=tmp_path,
            sample_rate=self._voice.config.sample_rate,
            duration=duration,
            text=text,
        )

    def synthesize_bytes(self, text: str) -> bytes:
        """
        Synthesize text to speech and return raw WAV bytes.

        Args:
            text: Text to synthesize

        Returns:
            Raw WAV audio bytes
        """
        self._load_voice()

        import wave
        import io
        from piper.config import SynthesisConfig

        syn_config = SynthesisConfig(
            length_scale=self.length_scale,
            noise_scale=self.noise_scale,
            noise_w_scale=self.noise_w,
        )

        buffer = io.BytesIO()
        with wave.open(buffer, 'wb') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(self._voice.config.sample_rate)
            for chunk in self._voice.synthesize(text, syn_config=syn_config):
                if hasattr(chunk, 'audio_int16_bytes'):
                    wf.writeframes(chunk.audio_int16_bytes)

        return buffer.getvalue()

    async def synthesize_async(self, text: str) -> TTSResult:
        """Async wrapper for synthesize."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self.synthesize, text)

    async def synthesize_bytes_async(self, text: str) -> bytes:
        """Async wrapper for synthesize_bytes."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self.synthesize_bytes, text)

    def get_available_voices(self) -> list:
        """List available voice models in the model directory."""
        voices = []
        model_dir = Path(self.model_dir)
        if model_dir.exists():
            for onnx_file in model_dir.glob("*.onnx"):
                name = onnx_file.stem
                config_file = model_dir / f"{name}.onnx.json"
                if config_file.exists():
                    voices.append(name)
        return voices


# Singleton instance
_tts_service: Optional[TTSService] = None


def get_tts_service() -> TTSService:
    """Get or create the global TTS service instance."""
    global _tts_service
    if _tts_service is None:
        voice_model = os.getenv("PIPER_VOICE_MODEL", "en_US-amy-medium")
        model_dir = os.getenv("PIPER_MODEL_DIR", "/home/ubuntu/M-2.0/models/piper")
        length_scale = float(os.getenv("PIPER_LENGTH_SCALE", "1.0"))
        noise_scale = float(os.getenv("PIPER_NOISE_SCALE", "0.667"))
        noise_w = float(os.getenv("PIPER_NOISE_W", "0.8"))
        _tts_service = TTSService(
            voice_model=voice_model,
            model_dir=model_dir,
            length_scale=length_scale,
            noise_scale=noise_scale,
            noise_w=noise_w,
        )
    return _tts_service


def reset_tts_service():
    """Reset the singleton (for testing or model change)."""
    global _tts_service
    _tts_service = None