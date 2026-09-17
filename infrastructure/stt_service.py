"""
Maya 2.0 ULTRA - Speech-to-Text Service
Local faster-whisper transcription service for voice control.
"""
import os
import logging
import tempfile
import asyncio
from pathlib import Path
from typing import Optional, AsyncGenerator
from dataclasses import dataclass

logger = logging.getLogger("stt_service")


@dataclass
class TranscriptionResult:
    text: str
    language: str
    language_probability: float
    duration: float
    segments: list


class STTService:
    """CPU-optimized faster-whisper transcription service."""

    def __init__(
        self,
        model_size: str = "small",
        device: str = "cpu",
        compute_type: str = "int8",
        download_root: Optional[str] = None,
        language: Optional[str] = None,
    ):
        """
        Initialize the STT service.

        Args:
            model_size: Whisper model size (tiny, base, small, medium, large-v3)
            device: Device to run on (cpu, cuda)
            compute_type: Compute type for CPU (int8, int8_float16, float32)
            download_root: Directory to cache models
            language: Force language (None for auto-detect)
        """
        self.model_size = model_size
        self.device = device
        self.compute_type = compute_type
        self.download_root = download_root or os.getenv("WHISPER_MODEL_DIR", "/home/ubuntu/M-2.0/models/whisper")
        self.language = language
        self._model = None
        self._model_loaded = False

    def _load_model(self):
        """Load the faster-whisper model lazily."""
        if self._model_loaded:
            return

        logger.info(f"Loading faster-whisper model: {self.model_size} on {self.device} ({self.compute_type})")
        try:
            from faster_whisper import WhisperModel

            Path(self.download_root).mkdir(parents=True, exist_ok=True)

            self._model = WhisperModel(
                self.model_size,
                device=self.device,
                compute_type=self.compute_type,
                download_root=self.download_root,
            )
            self._model_loaded = True
            logger.info("STT model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load STT model: {e}")
            raise

    def transcribe_file(self, audio_path: str) -> TranscriptionResult:
        """
        Transcribe an audio file.

        Args:
            audio_path: Path to audio file (wav, mp3, etc.)

        Returns:
            TranscriptionResult with text and metadata
        """
        self._load_model()

        try:
            segments, info = self._model.transcribe(
                audio_path,
                language=self.language,
                beam_size=5,
                vad_filter=True,
                vad_parameters=dict(min_silence_duration_ms=500),
            )

            segment_list = []
            full_text = []
            for segment in segments:
                segment_list.append({
                    "start": segment.start,
                    "end": segment.end,
                    "text": segment.text,
                    "avg_logprob": segment.avg_logprob,
                })
                full_text.append(segment.text)

            return TranscriptionResult(
                text=" ".join(full_text).strip(),
                language=info.language,
                language_probability=info.language_probability,
                duration=info.duration,
                segments=segment_list,
            )
        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            raise

    async def transcribe_bytes(self, audio_bytes: bytes, suffix: str = ".wav") -> TranscriptionResult:
        """
        Transcribe audio from bytes (for HTTP upload).

        Args:
            audio_bytes: Raw audio data
            suffix: File extension hint

        Returns:
            TranscriptionResult
        """
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name

        try:
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(None, self.transcribe_file, tmp_path)
            return result
        finally:
            try:
                os.unlink(tmp_path)
            except:
                pass

    async def transcribe_streaming(
        self,
        audio_chunks: AsyncGenerator[bytes, None],
        sample_rate: int = 16000,
    ) -> AsyncGenerator[str, None]:
        """
        Transcribe streaming audio chunks (partial results).
        Note: faster-whisper doesn't natively support streaming.
        This is a placeholder for future VAD-based chunking.

        Args:
            audio_chunks: Async generator of audio bytes
            sample_rate: Audio sample rate

        Yields:
            Partial transcript strings
        """
        self._load_model()

        buffer = bytearray()
        chunk_duration = 0
        max_buffer_duration = 30  # seconds

        async for chunk in audio_chunks:
            buffer.extend(chunk)
            chunk_duration += len(chunk) / (sample_rate * 2)  # assuming 16-bit PCM

            if chunk_duration >= 5.0:  # Process every ~5 seconds
                with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                    import wave
                    with wave.open(tmp.name, 'wb') as wf:
                        wf.setnchannels(1)
                        wf.setsampwidth(2)
                        wf.setframerate(sample_rate)
                        wf.writeframes(buffer)
                    tmp_path = tmp.name

                try:
                    result = self.transcribe_file(tmp_path)
                    if result.text.strip():
                        yield result.text.strip()
                    buffer = bytearray()
                    chunk_duration = 0
                finally:
                    try:
                        os.unlink(tmp_path)
                    except:
                        pass


# Singleton instance
_stt_service: Optional[STTService] = None


def get_stt_service() -> STTService:
    """Get or create the global STT service instance."""
    global _stt_service
    if _stt_service is None:
        model_size = os.getenv("WHISPER_MODEL_SIZE", "small")
        device = os.getenv("WHISPER_DEVICE", "cpu")
        compute_type = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
        language = os.getenv("WHISPER_LANGUAGE")
        _stt_service = STTService(
            model_size=model_size,
            device=device,
            compute_type=compute_type,
            language=language,
        )
    return _stt_service


def reset_stt_service():
    """Reset the singleton (for testing)."""
    global _stt_service
    _stt_service = None