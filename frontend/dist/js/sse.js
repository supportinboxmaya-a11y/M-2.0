// Maya 2.0 ULTRA - SSE Manager for Chat Streaming
class SSEManager {
  constructor() {
    this.eventSource = null;
    this.listeners = new Map();
    this.currentChatId = null;
  }
  
  connect(endpoint, token, chatId = null) {
    this.disconnect();
    
    this.currentChatId = chatId;
    const url = `${endpoint}?token=${encodeURIComponent(token)}`;
    
    this.eventSource = new EventSource(url);
    
    this.eventSource.onopen = () => {
      console.log('[SSE] Connected');
      this.emit('open');
    };
    
    this.eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        this.handleMessage(data);
      } catch (error) {
        console.error('[SSE] Parse error:', error);
      }
    };
    
    this.eventSource.onerror = (error) => {
      console.error('[SSE] Error:', error);
      this.emit('error', error);
      
      if (this.eventSource.readyState === EventSource.CLOSED) {
        this.emit('close');
      }
    };
  }
  
  disconnect() {
    if (this.eventSource) {
      this.eventSource.close();
      this.eventSource = null;
    }
    this.currentChatId = null;
  }
  
  handleMessage(data) {
    const { type, ...payload } = data;
    
    switch (type) {
      case 'delta':
        this.emit('delta', payload.delta);
        break;
      case 'done':
        this.emit('done', payload);
        this.disconnect();
        break;
      case 'error':
        this.emit('error', new Error(payload.error));
        this.disconnect();
        break;
      default:
        this.emit('message', data);
    }
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
          console.error(`[SSE] Listener error (${type}):`, error);
        }
      }
    }
  }
  
  isConnected() {
    return this.eventSource && this.eventSource.readyState === EventSource.OPEN;
  }
}

export const sse = new SSEManager();