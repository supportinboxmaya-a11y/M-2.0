/**
 * Maya 2.0 ULTRA — Hardware Integration
 *
 * Camera (MediaDevices), Voice (MediaRecorder), Clipboard.
 * Zero-failure policy: every capability degrades gracefully.
 */
(function () {
  const H = {};
  window.MayaHardware = H;

  /* ════════════════════════════════════════════
     CAMERA
  ════════════════════════════════════════════ */
  H.camera = {
    _stream: null,
    _active: false,

    // Check if camera is available (doesn't request permission)
    available: function () {
      return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
    },

    // Start the camera stream
    start: async function (opts = {}) {
      if (this._active && this._stream) return { ok: true, stream: this._stream };
      if (!this.available()) return { ok: false, error: 'Camera not available on this device' };

      try {
        this._stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: opts.facing || 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
          audio: false,
        });
        this._active = true;
        return { ok: true, stream: this._stream };
      } catch (e) {
        const msg = e.name === 'NotAllowedError' ? 'Camera permission denied'
          : e.name === 'NotFoundError' ? 'No camera found'
          : `Camera error: ${e.message}`;
        this._active = false;
        return { ok: false, error: msg, name: e.name };
      }
    },

    // Stop the camera stream
    stop: function () {
      if (this._stream) {
        this._stream.getTracks().forEach(t => t.stop());
        this._stream = null;
      }
      this._active = false;
    },

    // Capture a single frame as a Blob
    captureFrame: async function () {
      if (!this._active || !this._stream) return { ok: false, error: 'Camera not active' };
      try {
        const video = document.createElement('video');
        video.srcObject = this._stream;
        video.play();
        await new Promise(r => { video.onloadedmetadata = r; });

        const canvas = document.createElement('canvas');
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        canvas.getContext('2d').drawImage(video, 0, 0);

        return new Promise(resolve => {
          canvas.toBlob(blob => {
            video.pause(); video.srcObject = null;
            resolve(blob ? { ok: true, blob, dataUrl: URL.createObjectURL(blob) }
              : { ok: false, error: 'Failed to encode image' });
          }, 'image/jpeg', 0.85);
        });
      } catch (e) {
        return { ok: false, error: `Capture failed: ${e.message}` };
      }
    },

    // Capture and auto-upload to backend
    captureAndUpload: async function (prompt) {
      const frame = await this.captureFrame();
      if (!frame.ok) return frame;
      const reader = new FileReader();
      return new Promise(resolve => {
        reader.onloadend = async () => {
          const b64 = reader.result.split(',')[1];
          const result = await MayaAPI.vision.analyze(b64, prompt || 'Analyze this image');
          resolve(result);
        };
        reader.readAsDataURL(frame.blob);
      });
    },
  };

  /* ════════════════════════════════════════════
     VOICE / AUDIO RECORDING
  ════════════════════════════════════════════ */
  H.voice = {
    _mediaRecorder: null,
    _stream: null,
    _chunks: [],
    _state: 'idle',   // idle | recording | paused | processing

    available: function () {
      return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia && window.MediaRecorder);
    },

    // Request mic permission and start recording
    startRecording: async function (opts = {}) {
      if (this._state === 'recording') return { ok: true, state: this._state };
      if (!this.available()) return { ok: false, error: 'Voice recording not available' };

      try {
        this._stream = await navigator.mediaDevices.getUserMedia({
          audio: { sampleRate: opts.sampleRate || 16000, channelCount: 1, echoCancellation: true },
        });
        this._chunks = [];
        const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
          ? 'audio/webm;codecs=opus' : 'audio/webm';

        this._mediaRecorder = new MediaRecorder(this._stream, { mimeType });
        this._mediaRecorder.ondataavailable = (e) => { if (e.data.size > 0) this._chunks.push(e.data); };
        this._mediaRecorder.start(250);
        this._state = 'recording';
        return { ok: true, state: 'recording' };
      } catch (e) {
        const msg = e.name === 'NotAllowedError' ? 'Microphone permission denied'
          : `Microphone error: ${e.message}`;
        this._state = 'idle';
        return { ok: false, error: msg };
      }
    },

    // Pause recording
    pauseRecording: function () {
      if (this._mediaRecorder && this._mediaRecorder.state === 'recording') {
        this._mediaRecorder.pause();
        this._state = 'paused';
        return { ok: true, state: 'paused' };
      }
      return { ok: false, error: 'Not recording' };
    },

    // Resume recording
    resumeRecording: function () {
      if (this._mediaRecorder && this._mediaRecorder.state === 'paused') {
        this._mediaRecorder.resume();
        this._state = 'recording';
        return { ok: true, state: 'recording' };
      }
      return { ok: false, error: 'Not paused' };
    },

    // Stop recording and return audio blob
    stopRecording: function () {
      return new Promise((resolve) => {
        if (!this._mediaRecorder || this._mediaRecorder.state === 'inactive') {
          this._cleanup();
          resolve({ ok: false, error: 'Not recording' });
          return;
        }
        this._mediaRecorder.onstop = () => {
          const blob = new Blob(this._chunks, { type: this._mediaRecorder.mimeType });
          this._cleanup();
          resolve({ ok: true, blob, dataUrl: URL.createObjectURL(blob) });
        };
        this._mediaRecorder.stop();
      });
    },

    // Full pipeline: record → transcribe → return text
    recordAndTranscribe: async function (opts = {}) {
      const start = await this.startRecording(opts);
      if (!start.ok) return start;

      // Record for specified duration, or wait for manual stop
      if (opts.duration) {
        await new Promise(r => setTimeout(r, opts.duration));
        const stop = await this.stopRecording();
        if (!stop.ok) return stop;
        return await this._transcribe(stop.blob);
      }

      // Manual mode: return recorder control handles
      return { ok: true, recorder: this };
    },

    _transcribe: async function (blob) {
      try {
        const reader = new FileReader();
        return new Promise(resolve => {
          reader.onloadend = async () => {
            const b64 = reader.result.split(',')[1];
            const result = await MayaAPI.voice.transcribe(b64, blob.type);
            resolve(result);
          };
          reader.readAsDataURL(blob);
        });
      } catch (e) {
        return { ok: false, error: `Transcription failed: ${e.message}` };
      }
    },

    // Abort recording without saving
    cancelRecording: function () {
      this._cleanup();
      this._state = 'idle';
      return { ok: true, state: 'idle' };
    },

    _cleanup: function () {
      this._chunks = [];
      if (this._stream) { this._stream.getTracks().forEach(t => t.stop()); this._stream = null; }
      this._mediaRecorder = null;
      this._state = 'idle';
    },
  };

  /* ════════════════════════════════════════════
     CLIPBOARD
  ════════════════════════════════════════════ */
  H.clipboard = {
    // Copy text (modern API with fallback)
    copy: async function (text) {
      // Modern async clipboard API
      if (navigator.clipboard && navigator.clipboard.writeText) {
        try {
          await navigator.clipboard.writeText(text);
          return { ok: true };
        } catch (e) {
          // Permission denied or clipboard blocked — fall through
        }
      }

      // Fallback: legacy execCommand
      try {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        ta.style.left = '-9999px';
        document.body.appendChild(ta);
        ta.select();
        const success = document.execCommand('copy');
        document.body.removeChild(ta);
        if (success) return { ok: true };
        return { ok: false, error: 'Clipboard copy failed' };
      } catch (e) {
        return { ok: false, error: `Clipboard error: ${e.message}` };
      }
    },

    // Read text from clipboard
    paste: async function () {
      if (navigator.clipboard && navigator.clipboard.readText) {
        try {
          const text = await navigator.clipboard.readText();
          return { ok: true, text };
        } catch (e) {
          return { ok: false, error: `Clipboard read denied: ${e.message}` };
        }
      }
      return { ok: false, error: 'Clipboard paste not supported' };
    },
  };
})();
