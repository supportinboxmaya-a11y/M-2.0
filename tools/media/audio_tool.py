"""
Maya 2.0 - Audio Recording & Playback Tool
--------------------------------------------
Handles audio recording, playback, and streaming.
Supports headless/VPS mode with mock fallbacks.
"""

import base64
import os
import tempfile
import uuid
import platform
from typing import Dict, Optional

from config.settings import WORKSPACE_DIR


class AudioTool:
    """Audio recording, playback, and streaming tool."""
    
    def __init__(self):
        self.recordings_dir = os.path.join(str(WORKSPACE_DIR), "audio", "recordings")
        self.playback_dir = os.path.join(str(WORKSPACE_DIR), "audio", "playback")
        os.makedirs(self.recordings_dir, exist_ok=True)
        os.makedirs(self.playback_dir, exist_ok=True)
        
        # Detect headless/VPS environment
        self.is_headless = self._detect_headless()
        self._pyaudio_available = self._check_pyaudio()
    
    def _detect_headless(self) -> bool:
        """Detect if running in headless/VPS environment."""
        # Check common headless indicators
        if not os.environ.get("DISPLAY") and platform.system() == "Linux":
            return True
        if os.environ.get("SSH_CONNECTION") or os.environ.get("SSH_CLIENT"):
            return True
        # Check if running in container
        if os.path.exists("/.dockerenv"):
            return True
        return False
    
    def _check_pyaudio(self) -> bool:
        """Check if PyAudio is available and working."""
        try:
            import pyaudio
            p = pyaudio.PyAudio()
            # Try to get default input device
            try:
                p.get_default_input_device_info()
                p.terminate()
                return True
            except:
                p.terminate()
                return False
        except:
            return False
    
    def record_audio(
        self,
        duration_seconds: float = 5.0,
        sample_rate: int = 16000,
        channels: int = 1,
        fmt: str = "wav"
    ) -> Dict:
        """Record audio from default microphone (requires PyAudio).
        
        In headless/VPS mode, returns a mock recording for testing.
        """
        if self.is_headless or not self._pyaudio_available:
            return self._mock_record(duration_seconds, sample_rate, channels, fmt)
        
        try:
            import pyaudio
        except ImportError:
            return {"success": False, "error": "pyaudio not installed. Install with: pip install pyaudio"}
        
        try:
            audio = pyaudio.PyAudio()
            stream = audio.open(
                format=pyaudio.paInt16,
                channels=channels,
                rate=sample_rate,
                input=True,
                frames_per_buffer=1024
            )
            
            frames = []
            num_frames = int(sample_rate / 1024 * duration_seconds)
            
            for _ in range(num_frames):
                data = stream.read(1024)
                frames.append(data)
            
            stream.stop_stream()
            stream.close()
            audio.terminate()
            
            # Save to file
            filename = f"recording_{uuid.uuid4().hex[:8]}.wav"
            filepath = os.path.join(self.recordings_dir, filename)
            
            import wave
            with wave.open(filepath, 'wb') as wf:
                wf.setnchannels(channels)
                wf.setsampwidth(2)  # 16-bit
                wf.setframerate(sample_rate)
                wf.writeframes(b''.join(frames))
            
            # Return base64 encoded audio
            with open(filepath, 'rb') as f:
                audio_b64 = base64.b64encode(f.read()).decode()
            
            return {
                "success": True,
                "path": filepath,
                "audio_base64": audio_b64,
                "duration_seconds": duration_seconds,
                "sample_rate": sample_rate,
                "format": "wav"
            }
        except Exception as e:
            return {"success": False, "error": f"Recording failed: {str(e)}"}
    
    def _mock_record(self, duration_seconds: float, sample_rate: int, channels: int, fmt: str) -> Dict:
        """Generate mock audio recording for headless environments."""
        import wave
        import struct
        
        filename = f"mock_recording_{uuid.uuid4().hex[:8]}.wav"
        filepath = os.path.join(self.recordings_dir, filename)
        
        # Generate silent WAV file
        num_frames = int(sample_rate * duration_seconds)
        with wave.open(filepath, 'wb') as wf:
            wf.setnchannels(channels)
            wf.setsampwidth(2)
            wf.setframerate(sample_rate)
            # Write silence
            for _ in range(num_frames):
                wf.writeframes(struct.pack('<h', 0))
        
        with open(filepath, 'rb') as f:
            audio_b64 = base64.b64encode(f.read()).decode()
        
        return {
            "success": True,
            "path": filepath,
            "audio_base64": audio_b64,
            "duration_seconds": duration_seconds,
            "sample_rate": sample_rate,
            "format": "wav",
            "mock": True,
            "note": "Generated mock recording (headless/VPS mode)"
        }

    def save_audio_base64(self, audio_base64: str, filename: str = "") -> Dict:
        """Save base64 encoded audio to file."""
        try:
            audio_data = base64.b64decode(audio_base64)
            if not filename:
                filename = f"upload_{uuid.uuid4().hex[:8]}.wav"
            filepath = os.path.join(self.playback_dir, filename)
            
            with open(filepath, 'wb') as f:
                f.write(audio_data)
            
            return {
                "success": True,
                "path": filepath,
                "filename": filename
            }
        except Exception as e:
            return {"success": False, "error": f"Failed to save audio: {str(e)}"}

    def play_audio(self, audio_base64: str, fmt: str = "wav") -> Dict:
        """Play audio from base64 (requires local audio output).
        
        In headless/VPS mode, saves the file instead of playing.
        """
        if self.is_headless or not self._pyaudio_available:
            return self._mock_play(audio_base64)
        
        try:
            import pyaudio
            audio_data = base64.b64decode(audio_base64)
            
            # Save temporarily
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                f.write(audio_data)
                temp_path = f.name
            
            # Play using pyaudio
            import wave
            wf = wave.open(temp_path, 'rb')
            
            p = pyaudio.PyAudio()
            stream = p.open(
                format=p.get_format_from_width(wf.getsampwidth()),
                channels=wf.getnchannels(),
                rate=wf.getframerate(),
                output=True
            )
            
            data = wf.readframes(1024)
            while data:
                stream.write(data)
                data = wf.readframes(1024)
            
            stream.stop_stream()
            stream.close()
            p.terminate()
            
            os.unlink(temp_path)
            
            return {"success": True, "message": "Audio playback completed"}
        except Exception as e:
            return {"success": False, "error": f"Playback failed: {str(e)}"}
    
    def _mock_play(self, audio_base64: str) -> Dict:
        """Mock playback - save file instead of playing."""
        try:
            audio_data = base64.b64decode(audio_base64)
            filename = f"playback_{uuid.uuid4().hex[:8]}.wav"
            filepath = os.path.join(self.playback_dir, filename)
            
            with open(filepath, 'wb') as f:
                f.write(audio_data)
            
            return {
                "success": True, 
                "message": f"Audio saved for playback (headless mode): {filepath}",
                "saved_path": filepath,
                "mock": True
            }
        except Exception as e:
            return {"success": False, "error": f"Mock playback failed: {str(e)}"}

    # Tool registry entry points
    def record(self, duration_seconds: float = 5.0, sample_rate: int = 16000, **kwargs) -> str:
        """Record audio from microphone."""
        result = self.record_audio(duration_seconds, **kwargs)
        if result.get("success"):
            msg = f"Recording saved: {result['path']} (base64: {result.get('audio_base64', '')[:50]}...)"
            if result.get("mock"):
                msg += " [MOCK - headless mode]"
            return msg
        return f"Error: {result.get('error')}"

    def play(self, audio_base64: str, fmt: str = "wav") -> str:
        """Play audio from base64."""
        result = self.play_audio(audio_base64)
        if result.get("success"):
            msg = result.get("message", "Audio playback completed")
            if result.get("mock"):
                msg += " [MOCK - headless mode]"
            return msg
        return f"Error: {result.get('error')}"

    def save(self, audio_base64: str, filename: str = "") -> str:
        result = self.save_audio_base64(audio_base64, filename if filename else None)
        if result.get("success"):
            return f"Audio saved: {result['path']}"
        return f"Error: {result.get('error')}"


# Required imports
import base64
import os
import tempfile
import uuid
import platform
from typing import Dict, Optional
from config.settings import WORKSPACE_DIR
import base64
import struct