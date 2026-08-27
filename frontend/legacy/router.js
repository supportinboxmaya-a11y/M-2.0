/**
 * Maya 2.0 — SPA Router
 *
 * Hash-based routing with lazy screen loading.
 * Routes: #chat, #research, #business, #coding, #documents, #files,
 *         #automation, #agents, #analytics, #admin
 */
(function () {
  'use strict';

  const Router = {};
  window.MayaRouter = Router;

  // Route registry: maps route id → screen file path
  // Screens are loaded lazily when first navigated to.
  const ROUTES = {
    chat:       { file: 'js/screens/chat.js',        label: 'Chat' },
    research:   { file: 'js/screens/research.js',    label: 'Research' },
    business:   { file: 'js/screens/business.js',    label: 'Business' },
    coding:     { file: 'js/screens/coding.js',      label: 'Coding' },
    documents:  { file: 'js/screens/documents.js',   label: 'Documents' },
    files:      { file: 'js/screens/files.js',       label: 'Files' },
    automation: { file: 'js/screens/automation.js',  label: 'Automation' },
    agents:     { file: 'js/screens/agents.js',      label: 'Agents' },
    analytics:  { file: 'js/screens/analytics.js',   label: 'Analytics' },
    admin:      { file: 'js/screens/admin.js',       label: 'Admin' },
  };

  // Screen cache: once a screen module is loaded, its render function is stored here
  const _loaded = {};

  let _currentRoute = null;
  let _beforeNavigate = null; // hook for login guard

  /* ── Configuration ── */

  Router.setBeforeNavigate = function (fn) {
    _beforeNavigate = fn;
  };

  /* ── Navigation ── */

  Router.navigate = function (routeId, params) {
    if (!ROUTES[routeId]) {
      console.warn('Unknown route:', routeId, '→ redirecting to chat');
      routeId = 'chat';
    }

    // Run before-navigate hook (e.g. login check)
    if (_beforeNavigate) {
      const canProceed = _beforeNavigate(routeId);
      if (canProceed === false) return;
    }

    _currentRoute = routeId;
    location.hash = routeId;

    // Update nav highlights
    if (window.MayaLayout) {
      window.MayaLayout.setActive(routeId);
    }

    // Load and render screen
    _loadAndRender(routeId, params);
  };

  Router.getCurrentRoute = function () {
    return _currentRoute;
  };

  /* ── Lazy loading ── */

  function _loadAndRender(routeId, params) {
    const route = ROUTES[routeId];
    const L = window.MayaLayout;

    if (!L) {
      console.error('MayaLayout not initialized');
      return;
    }

    // Already loaded: just call render
    if (_loaded[routeId]) {
      L.setTitle(route.label);
      _loaded[routeId](params);
      return;
    }

    // Show loading
    L.showLoading('Loading ' + route.label + '...');

    // Lazy-load the screen JS file via dynamic script injection
    const script = document.createElement('script');
    script.src = route.file;
    script.onload = function () {
      L.setTitle(route.label);
      // The screen module registers itself in window.MayaScreens
      const screen = window.MayaScreens && window.MayaScreens[routeId];
      if (screen) {
        _loaded[routeId] = screen;
        screen(params);
      } else {
        // Fallback: screen didn't register — use basic screen
        L.render(`<div class="empty-state fade-in"><div class="icon">🧩</div><div class="title">${route.label}</div><div class="desc">Workspace not yet implemented</div></div>`);
        _loaded[routeId] = function () {
          L.render(`<div class="empty-state fade-in"><div class="icon">🧩</div><div class="title">${route.label}</div><div class="desc">Workspace not yet implemented</div></div>`);
        };
      }
    };
    script.onerror = function () {
      L.render(`<div class="empty-state fade-in"><div class="icon">⚠️</div><div class="title">Failed to load ${route.label}</div><div class="desc">The screen file could not be loaded. Check the console for details.</div></div>`);
    };
    document.body.appendChild(script);
  }

  /* ── Init from hash ── */

  Router.init = function () {
    const hash = location.hash.replace('#', '') || 'chat';
    Router.navigate(hash);

    // Listen for hash changes
    window.addEventListener('hashchange', function () {
      const h = location.hash.replace('#', '') || 'chat';
      if (h !== _currentRoute) {
        Router.navigate(h);
      }
    });
  };

  /* ── Screen registration ── */

  // Screens call this to register themselves
  window.MayaScreens = window.MayaScreens || {};

  Router.registerScreen = function (routeId, renderFn) {
    window.MayaScreens[routeId] = renderFn;
  };

})();
