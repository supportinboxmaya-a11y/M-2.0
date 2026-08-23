// Maya 2.0 ULTRA - Offline Sync Manager
import { 
  queueOfflineAction, 
  getOfflineQueue, 
  removeOfflineAction,
  incrementRetry,
  initStorage 
} from './utils/storage.js';
import { api } from './api.js';
import { auth } from './auth.js';

class SyncManager {
  constructor() {
    this.isOnline = navigator.onLine;
    this.syncInProgress = false;
    this.listeners = new Set();
    this.maxRetries = 3;
    
    window.addEventListener('online', () => this.handleOnline());
    window.addEventListener('offline', () => this.handleOffline());
  }
  
  async init() {
    await initStorage();
    this.isOnline = navigator.onLine;
    
    if (this.isOnline && auth.isAuthenticated()) {
      await this.processQueue();
    }
  }
  
  handleOnline() {
    this.isOnline = true;
    this.emit('online');
    
    if (auth.isAuthenticated()) {
      this.processQueue();
    }
  }
  
  handleOffline() {
    this.isOnline = false;
    this.emit('offline');
  }
  
  async queueAction(type, payload, options = {}) {
    const action = {
      type,
      payload,
      options,
      clientTs: Date.now()
    };
    
    const id = await queueOfflineAction(action);
    this.emit('queued', { id, action });
    
    if (this.isOnline && auth.isAuthenticated()) {
      this.processQueue();
    }
    
    return id;
  }
  
  async processQueue() {
    if (this.syncInProgress || !this.isOnline || !auth.isAuthenticated()) {
      return;
    }
    
    this.syncInProgress = true;
    this.emit('syncStart');
    
    try {
      const queue = await getOfflineQueue();
      
      if (queue.length === 0) {
        this.emit('syncComplete', { processed: 0 });
        return;
      }
      
      // Process in batches
      const batchSize = 10;
      let processed = 0;
      let failed = 0;
      
      for (let i = 0; i < queue.length; i += batchSize) {
        const batch = queue.slice(i, i + batchSize);
        
        try {
          const response = await api.pushSync(batch.map(item => ({
            op_id: item.id,
            type: item.type,
            payload: item.payload,
            client_ts: item.clientTs
          })));
          
          // Remove successful actions
          for (const result of response.results || []) {
            if (result.success) {
              await removeOfflineAction(result.op_id);
              processed++;
            } else {
              await incrementRetry(result.op_id);
              failed++;
            }
          }
        } catch (error) {
          console.error('[Sync] Batch failed:', error);
          
          // Increment retry for all in batch
          for (const item of batch) {
            await incrementRetry(item.id);
          }
          failed += batch.length;
        }
      }
      
      this.emit('syncComplete', { processed, failed, remaining: queue.length - processed });
      
      // Check if more items need processing
      const remaining = await getOfflineQueue();
      if (remaining.length > 0) {
        // Process again after a short delay
        setTimeout(() => this.processQueue(), 1000);
      }
    } finally {
      this.syncInProgress = false;
    }
  }
  
  async forceSync() {
    if (!this.isOnline) {
      throw new Error('Cannot sync while offline');
    }
    await this.processQueue();
  }
  
  getQueueLength() {
    return getOfflineQueue().then(queue => queue.length);
  }
  
  isSyncing() {
    return this.syncInProgress;
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
    for (const listener of this.listeners) {
      try {
        listener(type, data);
      } catch (error) {
        console.error(`[Sync] Listener error (${type}):`, error);
      }
    }
  }
  
  // Convenience methods for common actions
  async addMemoryOffline(content, type = 'general', metadata = {}) {
    return this.queueAction('add_memory', { content, type, metadata });
  }
  
  async createPromptOffline(name, body, category = 'general') {
    return this.queueAction('create_prompt', { name, body, category });
  }
  
  async enqueueGoalOffline(goal) {
    return this.queueAction('enqueue_goal', { goal });
  }
}

export const sync = new SyncManager();

// Register sync on service worker registration
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.ready.then((registration) => {
    // Register periodic sync if supported
    if ('periodicSync' in registration) {
      registration.periodicSync.register('maya-periodic-sync', {
        minInterval: 24 * 60 * 60 * 1000 // 24 hours
      }).catch(() => {
        // Periodic sync not supported
      });
    }
  });
}