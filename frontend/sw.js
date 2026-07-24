/**
 * Maya 2.0 ULTRA — Service Worker
 *
 * Provides offline fallback and PWA installability.
 * Cache-first for static assets, network-first for API calls.
 */
const CACHE = 'maya-v1';
const STATIC = [
  '/',
  '/index.html',
  '/manifest.json',
  '/js/api.js',
  '/js/store.js',
  '/js/hardware.js',
  '/js/app.js',
  '/assets/icons/icon.svg',
  '/assets/icons/icon-192.png',
  '/assets/icons/icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(STATIC))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // API calls: network-first with timeout fallback to cache
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      fetch(event.request)
        .then((res) => {
          const clone = res.clone();
          caches.open(CACHE).then((cache) => cache.put(event.request, clone));
          return res;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // Static assets: cache-first
  event.respondWith(
    caches.match(event.request)
      .then((hit) => hit || fetch(event.request))
      .catch(() => new Response('Offline', { status: 503 }))
  );
});
