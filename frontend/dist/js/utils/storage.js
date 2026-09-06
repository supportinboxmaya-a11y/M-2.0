// Maya 2.0 ULTRA - IndexedDB Storage Utilities

const DB_NAME = 'MayaOffline';
const DB_VERSION = 1;

const STORES = {
  offlineQueue: { keyPath: 'id', indexes: ['timestamp', 'type'] },
  drafts: { keyPath: 'id', indexes: ['view', 'timestamp'] },
  preferences: { keyPath: 'key' },
  cache: { keyPath: 'key', indexes: ['expires'] }
};

let dbPromise = null;

function getDB() {
  if (dbPromise) return dbPromise;
  
  dbPromise = new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      
      for (const [storeName, config] of Object.entries(STORES)) {
        if (!db.objectStoreNames.contains(storeName)) {
          const store = db.createObjectStore(storeName, { keyPath: config.keyPath });
          for (const indexName of config.indexes || []) {
            store.createIndex(indexName, indexName, { unique: false });
          }
        }
      }
    };
  });
  
  return dbPromise;
}

export async function addItem(storeName, item) {
  const db = await getDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(storeName, 'readwrite');
    const store = tx.objectStore(storeName);
    const request = store.add(item);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function putItem(storeName, item) {
  const db = await getDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(storeName, 'readwrite');
    const store = tx.objectStore(storeName);
    const request = store.put(item);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function getItem(storeName, key) {
  const db = await getDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(storeName, 'readonly');
    const store = tx.objectStore(storeName);
    const request = store.get(key);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function deleteItem(storeName, key) {
  const db = await getDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(storeName, 'readwrite');
    const store = tx.objectStore(storeName);
    const request = store.delete(key);
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

export async function getAllItems(storeName, indexName = null, query = null) {
  const db = await getDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(storeName, 'readonly');
    const store = tx.objectStore(storeName);
    const source = indexName ? store.index(indexName) : store;
    const request = query ? source.getAll(query) : source.getAll();
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function clearStore(storeName) {
  const db = await getDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(storeName, 'readwrite');
    const store = tx.objectStore(storeName);
    const request = store.clear();
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

// Offline queue specific helpers
export async function queueOfflineAction(action) {
  const item = {
    id: crypto.randomUUID(),
    ...action,
    timestamp: Date.now(),
    retries: 0
  };
  await addItem('offlineQueue', item);
  return item.id;
}

export async function getOfflineQueue() {
  return getAllItems('offlineQueue', 'timestamp');
}

export async function removeOfflineAction(id) {
  await deleteItem('offlineQueue', id);
}

export async function incrementRetry(id) {
  const item = await getItem('offlineQueue', id);
  if (item) {
    item.retries = (item.retries || 0) + 1;
    await putItem('offlineQueue', item);
  }
}

// Drafts
export async function saveDraft(view, data) {
  const key = `draft:${view}`;
  await putItem('drafts', {
    id: key,
    view,
    data,
    timestamp: Date.now()
  });
}

export async function getDraft(view) {
  const item = await getItem('drafts', `draft:${view}`);
  return item?.data || null;
}

export async function clearDraft(view) {
  await deleteItem('drafts', `draft:${view}`);
}

// Preferences
export async function setPreference(key, value) {
  await putItem('preferences', { key, value, updated: Date.now() });
}

export async function getPreference(key, defaultValue = null) {
  const item = await getItem('preferences', key);
  return item?.value ?? defaultValue;
}

export async function getAllPreferences() {
  const items = await getAllItems('preferences');
  const prefs = {};
  for (const item of items) {
    prefs[item.key] = item.value;
  }
  return prefs;
}

// Cache with TTL
export async function setCache(key, data, ttlMs = 5 * 60 * 1000) {
  await putItem('cache', {
    key,
    data,
    expires: Date.now() + ttlMs
  });
}

export async function getCache(key) {
  const item = await getItem('cache', key);
  if (!item) return null;
  if (item.expires < Date.now()) {
    await deleteItem('cache', key);
    return null;
  }
  return item.data;
}

export async function clearExpiredCache() {
  const db = await getDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction('cache', 'readwrite');
    const store = tx.objectStore('cache');
    const index = store.index('expires');
    const range = IDBKeyRange.upperBound(Date.now());
    const request = index.openCursor(range);
    
    request.onsuccess = (event) => {
      const cursor = event.target.result;
      if (cursor) {
        cursor.delete();
        cursor.continue();
      } else {
        resolve();
      }
    };
    request.onerror = () => reject(request.error);
  });
}

// Initialize
export async function initStorage() {
  await getDB();
  await clearExpiredCache();
}