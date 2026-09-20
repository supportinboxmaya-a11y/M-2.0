"""
Maya 2.0 - Silero VAD (Voice Activity Detection)
------------------------------------------------
Voice Activity Detection for hands-free interruption and real-time voice processing.
"""

import asyncio
import os
import time
import torch
import torch.nn as nn
from typing import Dict, Optional, AsyncGenerator, List
from collections import deque

from config.settings import WORKSPACE_DIR


class VADTool:
    """Silero VAD - Voice Activity Detection for real-time voice processing."""
    
    def __init__(self):
        self.model = None
        self.utils = None
        self.sample_rate = 16000
        self.window_size = 512  # 32ms at 16kHz
        self.threshold = 0.5
        self.min_speech_duration = 0.1  # 100ms minimum speech
        self.max_silence_duration = 0.5  # 500ms max silence before ending
        self._load_model()
        
    def _load_model(self):
        """Load Silero VAD model from torch hub or local cache."""
        try:
            # Load from torch hub (cached after first download)
            self.model, self.utils = torch.hub.load(
                repo_or_dir='snakers4/silero-vad',
                model='silero_vad',
                force_reload=False,
                trust_repo=True,
                verbose=False
            )
            print("Silero VAD model loaded successfully")
        except Exception as e:
            print(f"Failed to load Silero VAD: {e}")
            # Try loading from local cache
            try:
                model_path = os.path.join(torch.hub.get_dir(), 'snakers4_silero-vad_master', 'files', 'silero_vad.jit')
                if os.path.exists(model_path):
                    self.model = torch.jit.load(model_path)
                    print("Loaded Silero VAD from local cache")
                else:
                    raise
            except Exception as e2:
                print(f"Failed to load VAD from cache: {e2}")
    
    def is_speech(self, chunk: bytes, sample_rate: int = 16000) -> float:
        """Returns speech probability (0.0 to 1.0) for an audio chunk."""
        if self.model is None:
            return 0.0
            
        # Convert bytes to tensor
        chunk_tensor = torch.frombuffer(chunk, dtype=torch.int16).float() / 32768.0
        
        # Ensure correct shape for Silero VAD (512 samples = 32ms at 16kHz)
        if chunk_tensor.shape[-1] != 512:
            if chunk_tensor.shape[-1] < 512:
                chunk_tensor = torch.nn.functional.pad(chunk_tensor, (0, 512 - chunk_tensor.shape[-1]))
            else:
                chunk_tensor = chunk_tensor[:512]
        
        with torch.no_grad():
            speech_prob = self.model(chunk_tensor, sample_rate).item()
        return speech_prob
    
    async def process_stream(self, audio_chunks: AsyncGenerator[bytes, None], 
                            sample_rate: int = 16000) -> AsyncGenerator[Dict, None]:
        """
        Process streaming audio and yield voice activity events.
        Yields: {'is_speech': bool, 'probability': float, 'is_speech_start': bool, 'is_speech_end': bool}
        """
        speech_frames = 0
        silence_frames = 0
        is_speaking = False
        
        min_speech_frames = int(self.min_speech_duration * 16000 / 512)  # ~3 frames for 100ms
        max_silence_frames = int(self.max_silence_duration * 16000 / 512)  # ~31 frames for 500ms
        
        async for chunk in audio_chunks:
            if len(chunk) != 1024:  # 512 samples * 2 bytes = 1024 bytes for 16-bit
                continue
                
            speech_prob = self.is_speech(chunk)
            is_speech = speech_prob > self.threshold
            
            if is_speaking:
                if speech_prob > self.threshold:
                    speech_frames += 1
                    silence_frames = 0
                else:
                    silence_frames += 1
                    
                if silence_frames >= max_silence_frames:
                    # Speech ended
                    is_speaking = False
                    yield {
                        "type": "speech_end",
                        "duration_ms": speech_frames * 32,  # 32ms per frame
                        "final": True
                    }
            else:
                if speech_prob > self.threshold:
                    speech_frames += 1
                    silence_frames = 0
                    
                    if speech_frames >= min_speech_frames:
                        # Speech started
                        is_speaking = True
                        yield {
                            "type": "speech_start",
                            "timestamp": time.time(),
                            "probability": speech_prob
                        }
                else:
                    # Still silence
                    pass
                    
    def get_vad_iterator(self):
        """Returns a VAD iterator for streaming processing."""
        pass


class _NotConfigured(Exception):
    pass

# Required imports
import asyncio
import os
import time
import torch
import torch.nn as nn
from typing import Dict, Optional, AsyncGenerator
from config.settings import WORKSPACE_DIR
import time