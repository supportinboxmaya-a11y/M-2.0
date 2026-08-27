// Maya 2.0 ULTRA - Service Worker
const CACHE_NAME = 'maya-v2';
const OFFLINE_CACHE = 'maya-offline-v1';
const API_CACHE = 'maya-api-v1';

const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/css/variables.css',
  '/css/reset.css',
  '/css/layout.css',
  '/css/components.css',
  '/css/chat.css',
  '/css/memory.css',
  '/css/tools.css',
  '/css/tasks.css',
  '/css/hosting.css',
  '/css/cognition.css',
  '/css/settings.css',
  '/css/admin.css',
  '/css/cognitive.css',
  '/css/mobile.css',
  '/js/app.js',
  '/js/api.js',
  '/js/auth.js',
  '/js/BaseView.js',
  '/js/ws.js',
  '/js/sse.js',
  '/js/sync.js',
  '/js/components/Sidebar.js',
  '/js/components/Header.js',
  '/js/components/Modal.js',
  '/js/components/Toast.js',
  '/js/components/ConfirmDialog.js',
  '/js/components/DataTable.js',
  '/js/components/Form.js',
  '/js/components/MarkdownRenderer.js',
  '/js/components/Chart.js',
  '/js/views/ChatView.js',
  '/js/views/LoginView.js',
  '/js/views/MemoryView.js',
  '/js/views/ToolsView.js',
  '/js/views/TasksView.js',
  '/js/views/GenericViews.js',
  '/js/views/KernelView.js',
  '/js/views/GoalsView.js',
  '/js/views/SkillsView.js',
  '/js/views/SelfModelView.js',
  '/js/views/CapabilitiesView.js',
  '/js/views/MetacognitionView.js',
  '/js/views/SocietyView.js',
  '/js/views/MCPView.js',
  '/js/views/CoreLoopView.js',
  '/js/views/ResearchView.js',
  '/js/views/RAGView.js',
  '/js/views/WorkflowsView.js',
  '/js/views/HostingView.js',
  '/js/views/CognitionView.js',
  '/js/views/SettingsView.js',
  '/js/views/AdminView.js',
  '/js/views/LearningView.js',
  '/js/views/PromptsView.js',
  '/js/views/WebhooksView.js',
  '/js/views/TranslateView.js',
  '/js/views/AnalyticsView.js',
  '/js/views/LogsView.js',
  '/js/views/DocsView.js',
  '/js/views/AgentsView.js',
  '/js/views/InstancesView.js',
  '/js/views/DevicesView.js',
  '/js/views/WorkspaceView.js',
  '/js/views/BackupsView.js',
  '/js/views/SecurityView.js',
  '/js/views/ApprovalsView.js',
  '/js/utils/date.js',
  '/js/utils/format.js',
  '/js/utils/validation.js',
  '/js/utils/storage.js'
];

// Install - cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate - clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((key) => ![CACHE_NAME, OFFLINE_CACHE, API_CACHE].includes(key))
          .map((key) => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

// Fetch - network first for API, cache first for static
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip chrome-extension, data: URLs
  if (!url.protocol.startsWith('http')) {
    return;
  }
  
  // API requests - network first with offline fallback
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(networkFirstApi(request));
    return;
  }
  
  // Static assets - cache first
  event.respondWith(cacheFirst(request));
});

// Network first for API
async function networkFirstApi(request) {
  const cache = await caches.open(API_CACHE);
  
  try {
    const response = await fetch(request);
    
    // Cache successful GET responses
    if (response.ok) {
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    // Try cache
    const cached = await cache.match(request);
    if (cached) {
      // Add offline indicator header
      const offlineResponse = cached.clone();
      offlineResponse.headers.set('X-Maya-Offline', 'true');
      return offlineResponse;
    }
    
    // Return offline response
    return new Response(JSON.stringify({
      error: 'Offline',
      message: 'This request requires network connectivity'
    }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Cache first for static assets
async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  
  if (cached) {
    // Update cache in background
    fetch(request).then((response) => {
      if (response.ok) {
        cache.put(request, response);
      }
    }).catch(() => {});
    
    return cached;
  }
  
  try {
    const response = await fetch(request);
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    // Return offline page for navigation requests
    if (request.mode === 'navigate') {
      const offlinePage = await cache.match('/index.html');
      return offlinePage || new Response('Offline', { status: 503 });
    }
    throw error;
  }
}

// Background sync for offline actions
self.addEventListener('sync', (event) => {
  if (event.tag === 'maya-sync') {
    event.waitUntil(syncOfflineActions());
  }
});

async function syncOfflineActions() {
  const db = await openOfflineDB();
  const tx = db.transaction('offlineQueue', 'readwrite');
  const store = tx.objectStore('offlineQueue');
  const actions = await getAll(store);
  
  for (const action of actions) {
    try {
      const response = await fetch('/api/v1/sync/push', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${action.token}`
        },
        body: JSON.stringify({ actions: [action] })
      });
      
      if (response.ok) {
        await deleteItem(store, action.id);
      }
    } catch (error) {
      console.log('Sync failed for action:', action.id, error);
    }
  }
}

// IndexedDB helpers for offline queue
function openOfflineDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('MayaOffline', 1);
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains('offlineQueue')) {
        db.createObjectStore('offlineQueue', { keyPath: 'id' });
      }
    };
  });
}

function getAll(store) {
  return new Promise((resolve, reject) => {
    const request = store.getAll();
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function deleteItem(store, id) {
  return new Promise((resolve, reject) => {
    const request = store.delete(id);
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

// Push notifications
self.addEventListener('push', (event) => {
  if (!event.data) return;
  
  const data = event.data.json();
  const options = {
    body: data.body || data.message || 'New notification from Maya',
    icon: '/icons/icon-192.png',
    badge: '/icons/badge-72.png',
    vibrate: [100, 50, 100],
    data: data.meta || {},
    actions: [
      { action: 'view', title: 'View' },
      { action: 'dismiss', title: 'Dismiss' }
    ],
    requireInteraction: data.level === 'warning' || data.level === 'critical'
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'Maya 2.0', options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  if (event.action === 'view') {
    event.waitUntil(
      clients.matchAll({ type: 'window' })
        .then((clientList) => {
          for (const client of clientList) {
            if (client.url.includes('/') && 'focus' in client) {
              return client.focus();
            }
          }
          return clients.openWindow('/');
        })
    );
  }
});

// Periodic sync (if supported)
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'maya-periodic-sync') {
    event.waitUntil(syncOfflineActions());
  }
});