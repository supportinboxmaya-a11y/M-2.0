// Maya 2.0 ULTRA - WebSocket Manager
class WSManager {
  constructor() {
    this.ws = null;
    this.url = '';
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 10;
    this.reconnectDelay = 1000;
    this.listeners = new Map();
    this.isConnected = false;
    this.authToken = null;
    // Cloudflare tunnel for WebSocket (Vercel static doesn't proxy WS)
    this.wsBackend = 'wss://gzip-separately-competition-democratic.trycloudflare.com';
  }
  
  connect(token) {
    if (this.ws && (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)) {
      return;
    }
    
    this.authToken = token;
    this.url = `${this.wsBackend}/ws/agent?token=${encodeURIComponent(token)}`;
    
    this.ws = new WebSocket(this.url);
    
    this.ws.onopen = () => {
      console.log('[WS] Connected');
      this.isConnected = true;
      this.reconnectAttempts = 0;
      this.emit('open');
    };
    
    this.ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        this.handleMessage(data);
      } catch (error) {
        console.error('[WS] Parse error:', error);
      }
    };
    
    this.ws.onclose = () => {
      console.log('[WS] Disconnected');
      this.isConnected = false;
      this.emit('close');
      this.scheduleReconnect();
    };
    
    this.ws.onerror = (error) => {
      console.error('[WS] Error:', error);
      this.emit('error', error);
    };
  }
  
  disconnect() {
    if (this.ws) {
      this.ws.close(1000, 'Client disconnect');
      this.ws = null;
    }
    this.isConnected = false;
  }
  
  scheduleReconnect() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log('[WS] Max reconnect attempts reached');
      this.emit('maxReconnectReached');
      return;
    }
    
    const delay = this.reconnectDelay * Math.pow(1.5, this.reconnectAttempts);
    this.reconnectAttempts++;
    
    setTimeout(() => {
      if (this.authToken) {
        this.connect(this.authToken);
      }
    }, delay);
  }
  
  handleMessage(data) {
    const { type, ...payload } = data;
    this.emit(type, payload);
    this.emit('message', data);
  }
  
  send(data) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
      return true;
    }
    return false;
  }
  
  ping() {
    return this.send({ type: 'ping' });
  }
  
  on(type, listener) {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, new Set());
    }
    this.listeners.get(type).add(listener);
    return () => this.off(type, listener);
  }
  
  off(type, listener) {
    if (this.listeners.has(type)) {
      this.listeners.get(type).delete(listener);
    }
  }
  
  emit(type, data) {
    if (this.listeners.has(type)) {
      for (const listener of this.listeners.get(type)) {
        try {
          listener(data);
        } catch (error) {
          console.error(`[WS] Listener error (${type}):`, error);
        }
      }
    }
  }
  
  getConnectionState() {
    return this.isConnected ? 'connected' : 'disconnected';
  }
}

export const ws = new WSManager();