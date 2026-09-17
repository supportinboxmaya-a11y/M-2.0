const API_BASE = window.location.origin;
const WS_BASE = API_BASE.replace(/^http/, 'ws');

let ws = null;
let mediaRecorder = null;
let audioChunks = [];
let isRecording = false;
let deferredPrompt = null;
let authToken = null;

const $ = (id) => document.getElementById(id);

function setStatus(state, text, detail = '') {
  const indicator = $('statusIndicator');
  indicator.className = 'status-indicator ' + state;
  $('statusText').textContent = text;
  $('statusDetail').textContent = detail;
}

function addTranscript(role, text) {
  const area = $('transcriptArea');
  if (area.classList.contains('empty')) {
    area.innerHTML = '';
    area.classList.remove('empty');
  }
  const div = document.createElement('div');
  div.className = 'transcript-item';
  div.innerHTML = `
    <div class="transcript-label">${role === 'user' ? 'You' : 'Maya'}</div>
    <div class="transcript-text ${role}">${text}</div>
  `;
  area.appendChild(div);
  area.scrollTop = area.scrollHeight;
}

function clearTranscript() {
  const area = $('transcriptArea');
  area.innerHTML = '<div style="text-align: center; color: var(--muted);">Conversation will appear here</div>';
  area.classList.add('empty');
}

async function getAuthToken() {
  if (authToken) return authToken;
  
  try {
    const resp = await fetch(`${API_BASE}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@maya.ai',
        password: 'change-this-password'
      })
    });
    if (!resp.ok) throw new Error('Login failed');
    const data = await resp.json();
    authToken = data.access_token;
    return authToken;
  } catch (e) {
    console.error('Auth failed:', e);
    setStatus('error', 'Auth failed', 'Check credentials');
    throw e;
  }
}

async function connect() {
  try {
    setStatus('connecting', 'Connecting...', 'Authenticating...');
    $('connectBtn').disabled = true;
    
    const token = await getAuthToken();
    const wsUrl = `${WS_BASE}/api/v1/voice/gateway?token=${token}`;
    
    ws = new WebSocket(wsUrl);
    
    ws.onopen = () => {
      console.log('WS connected');
      setStatus('idle', 'Connected', 'Ready - hold button to speak');
      $('connectBtn').disabled = true;
      $('disconnectBtn').disabled = false;
      $('pttButton').disabled = false;
      $('pttLabel').textContent = 'Hold to speak';
      $('pttHint').textContent = 'Hold to record, release to send';
      $('connectionStatus').textContent = 'WebSocket connected';
    };
    
    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        handleWSMessage(msg);
      } catch (e) {
        console.error('WS parse error:', e);
      }
    };
    
    ws.onerror = (err) => {
      console.error('WS error:', err);
      setStatus('error', 'Connection error', 'Check network');
    };
    
    ws.onclose = () => {
      console.log('WS closed');
      setStatus('idle', 'Disconnected', 'Tap connect to start');
      $('connectBtn').disabled = false;
      $('disconnectBtn').disabled = true;
      $('pttButton').disabled = true;
      $('pttLabel').textContent = 'Connect';
      $('pttHint').textContent = 'Hold to record';
      $('connectionStatus').textContent = 'WebSocket disconnected';
    };
    
  } catch (e) {
    setStatus('error', 'Failed to connect', e.message);
    $('connectBtn').disabled = false;
  }
}

function disconnect() {
  if (ws) {
    ws.close();
    ws = null;
  }
  if (mediaRecorder && mediaRecorder.state !== 'inactive') {
    mediaRecorder.stop();
  }
  isRecording = false;
}

function handleWSMessage(msg) {
  switch (msg.type) {
    case 'connected':
      console.log('Session:', msg.session_id);
      break;
    case 'transcript':
      addTranscript('user', msg.text);
      setStatus('thinking', 'Thinking...', 'Maya is processing');
      break;
    case 'thinking':
      setStatus('thinking', 'Thinking...', 'Maya is processing');
      break;
    case 'speaking':
      addTranscript('maya', msg.text);
      playAudio(msg.audio_base64);
      setStatus('speaking', 'Maya is speaking', 'Playing response');
      break;
    case 'turn_complete':
      setStatus('idle', 'Ready', 'Hold button to speak');
      break;
    case 'pong':
      console.log('Pong');
      break;
    case 'error':
      setStatus('error', 'Error', msg.message);
      break;
  }
}

async function startRecording() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        sampleRate: 16000,
        channelCount: 1,
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true
      }
    });
    
    mediaRecorder = new MediaRecorder(stream, {
      mimeType: 'audio/webm;codecs=opus'
    });
    
    audioChunks = [];
    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) audioChunks.push(e.data);
    };
    
    mediaRecorder.onstop = async () => {
      const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
      await sendAudio(audioBlob);
      stream.getTracks().forEach(t => t.stop());
    };
    
    mediaRecorder.start(100);
    isRecording = true;
    
  } catch (e) {
    console.error('Recording failed:', e);
    setStatus('error', 'Mic access denied', 'Allow microphone permission');
  }
}

async function stopRecording() {
  if (mediaRecorder && mediaRecorder.state === 'recording') {
    mediaRecorder.stop();
    isRecording = false;
  }
}

async function sendAudio(blob) {
  if (!ws || ws.readyState !== WebSocket.OPEN) return;
  
  const arrayBuffer = await blob.arrayBuffer();
  const uint8Array = new Uint8Array(arrayBuffer);
  
  ws.send(uint8Array);
  
  setTimeout(() => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'end' }));
    }
  }, 100);
}

function playAudio(base64) {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  
  const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  audioCtx.decodeAudioData(bytes.buffer, (buffer) => {
    const source = audioCtx.createBufferSource();
    source.buffer = buffer;
    source.connect(audioCtx.destination);
    source.start(0);
  });
}

const pttButton = $('pttButton');

pttButton.addEventListener('mousedown', (e) => {
  e.preventDefault();
  if (!isRecording && ws?.readyState === WebSocket.OPEN) {
    pttButton.classList.add('recording');
    $('pttIcon').textContent = '⏺️';
    $('pttLabel').textContent = 'Recording...';
    $('pttHint').textContent = 'Release to send';
    setStatus('listening', 'Listening...', 'Speak now');
    startRecording();
  }
});

pttButton.addEventListener('mouseup', (e) => {
  e.preventDefault();
  if (isRecording) {
    pttButton.classList.remove('recording');
    $('pttIcon').textContent = '🎤';
    $('pttLabel').textContent = 'Processing...';
    $('pttHint').textContent = 'Sending...';
    stopRecording();
  }
});

pttButton.addEventListener('mouseleave', (e) => {
  if (isRecording) {
    pttButton.classList.remove('recording');
    $('pttIcon').textContent = '🎤';
    $('pttLabel').textContent = 'Cancelled';
    $('pttHint').textContent = 'Hold to record';
    stopRecording();
    setStatus('idle', 'Ready', 'Hold button to speak');
  }
});

pttButton.addEventListener('touchstart', (e) => {
  e.preventDefault();
  if (!isRecording && ws?.readyState === WebSocket.OPEN) {
    pttButton.classList.add('recording');
    $('pttIcon').textContent = '⏺️';
    $('pttLabel').textContent = 'Recording...';
    $('pttHint').textContent = 'Release to send';
    setStatus('listening', 'Listening...', 'Speak now');
    startRecording();
  }
}, { passive: false });

pttButton.addEventListener('touchend', (e) => {
  e.preventDefault();
  if (isRecording) {
    pttButton.classList.remove('recording');
    $('pttIcon').textContent = '🎤';
    $('pttLabel').textContent = 'Processing...';
    $('pttHint').textContent = 'Sending...';
    stopRecording();
  }
}, { passive: false });

pttButton.addEventListener('touchcancel', (e) => {
  e.preventDefault();
  if (isRecording) {
    pttButton.classList.remove('recording');
    $('pttIcon').textContent = '🎤';
    $('pttLabel').textContent = 'Cancelled';
    $('pttHint').textContent = 'Hold to record';
    stopRecording();
    setStatus('idle', 'Ready', 'Hold button to speak');
  }
}, { passive: false });

window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  $('installBanner').classList.remove('hidden');
});

$('installBtn').addEventListener('click', async () => {
  if (deferredPrompt) {
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'accepted') {
      console.log('PWA installed');
    }
    deferredPrompt = null;
    $('installBanner').classList.add('hidden');
  }
});

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/voice/sw.js').then(reg => {
    console.log('SW registered:', reg.scope);
  }).catch(err => {
    console.log('SW registration failed:', err);
  });
}

if (window.matchMedia('(display-mode: standalone)').matches) {
  console.log('Running as PWA');
}