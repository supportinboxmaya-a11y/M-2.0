/**
 * Maya 2.0 — Application Core
 *
 * Auth, initialization, WebSocket, and login screen only.
 * All workspace screens moved to js/screens/*.js
 */
(function () {
  'use strict';

  const App = {};
  window.MayaApp = App;

  const $ = (sel) => document.querySelector(sel);
  const L = () => window.MayaLayout;
  const R = () => window.MayaRouter;

  /* ── Init ── */

  // Fallback login renderer when MayaLayout is unavailable (JS load failure)
  function _renderFallback(msg) {
    var el = document.getElementById('workspaceContent');
    if (!el) el = document.getElementById('main');
    if (!el) return;
    el.innerHTML = '<div class="fade-in" style="display:flex;align-items:center;justify-content:center;min-height:80vh;flex-direction:column;gap:12px;padding:24px;color:var(--text-secondary)">' +
      '<div style="font-size:40px">🧠</div>' +
      '<h1 style="font-size:24px;color:var(--text-primary);margin:0">Maya 2.0</h1>' +
      (msg ? '<p>' + msg + '</p>' : '') +
      '<button onclick="location.reload()" style="padding:8px 24px;cursor:pointer;border:1px solid var(--border-primary);border-radius:8px;background:var(--accent-blue-bg, #1f6feb);color:#fff;font:inherit">Retry</button></div>';
  }

  async function init() {
    try {
      const token = MayaAPI && MayaAPI.getToken ? MayaAPI.getToken() : null;
      if (token) {
        var lay = L();
        if (lay && lay.showLoading) lay.showLoading('Connecting to Maya...');
        var result;
        var timeoutId;
        try {
          result = await Promise.race([
            MayaAPI.auth.me({ signal: AbortSignal.timeout ? AbortSignal.timeout(15000) : undefined }),
            new Promise(function (_, reject) {
              timeoutId = setTimeout(function () { reject(new Error('timeout')); }, 15000);
            }),
          ]);
          clearTimeout(timeoutId);
        } catch (e) {
          clearTimeout(timeoutId);
          MayaAPI.setToken(null);
          if (MayaStore && MayaStore._set) MayaStore._set('token', null);
          showLogin();
          return;
        }
        if (result && result.ok) {
          if (MayaStore && MayaStore._set) MayaStore._set('user', result.data);
          boot(result.data);
          return;
        }
      }
      showLogin();
    } catch (e) {
      console.error('Fatal init error:', e);
      _renderFallback('Connection failed. Tap to retry.');
    }
  }

  function boot(user) {
    try {
      var _lay = L();
      var _router = R();
      if (!_lay || !_router) { showLogin(); return; }
      // Set up layout
      _lay.init('chat');
      _lay.setUser(user);

      // Set up router with login guard
      _router.setBeforeNavigate(function (route) {
        const token = MayaAPI.getToken();
        if (!token) {
          showLogin();
          return false;
        }
      });

      // Start router
      _router.init();

      // Global listeners
      bindGlobalListeners();
    } catch (e) {
      console.error('Boot error:', e);
      _renderFallback('Could not initialize UI.');
    }
  }

  /* ── Login Screen ── */

  function showLogin() {
    var _lay = L();
    if (!_lay) { _renderFallback('Initializing...'); return; }
    _lay.render(`
    <div class="fade-in" style="display:flex;align-items:center;justify-content:center;min-height:100%;padding:24px">
      <div style="background:var(--bg-secondary);border:1px solid var(--border-primary);border-radius:var(--radius-xl);padding:40px;width:400px;max-width:100%">
        <h1 style="font-size:24px;margin-bottom:4px">🧠 Maya 2.0</h1>
        <p style="color:var(--text-secondary);margin-bottom:24px;font-size:13px">Autonomous AI Operating System</p>
        <div style="display:flex;margin-bottom:24px;border-bottom:1px solid var(--border-primary)">
          <button class="btn btn-ghost active" id="loginTab" style="flex:1;border-radius:0;border-bottom:2px solid var(--accent-blue);color:var(--text-primary)">Sign In</button>
          <button class="btn btn-ghost" id="registerTab" style="flex:1;border-radius:0">Register</button>
        </div>
        <form id="loginForm">
          <div class="form-group"><label>Email</label><input class="input" type="email" id="loginEmail" placeholder="admin@maya.ai" required autofocus></div>
          <div class="form-group"><label>Password</label><input class="input" type="password" id="loginPassword" placeholder="••••••••" required></div>
          <button type="submit" class="btn btn-primary btn-block">Sign In</button>
        </form>
        <form id="registerForm" style="display:none">
          <div class="form-group"><label>Name</label><input class="input" type="text" id="regName" placeholder="Your name"></div>
          <div class="form-group"><label>Email</label><input class="input" type="email" id="regEmail" placeholder="you@example.com" required></div>
          <div class="form-group"><label>Password</label><input class="input" type="password" id="regPassword" placeholder="••••••••" required></div>
          <button type="submit" class="btn btn-primary btn-block">Create Account</button>
        </form>
      </div>
    </div>`);

    document.getElementById('loginForm').addEventListener('submit', App._login);
    document.getElementById('registerForm').addEventListener('submit', App._register);
    document.getElementById('loginTab').addEventListener('click', function () {
      document.getElementById('loginTab').classList.add('active');
      document.getElementById('registerTab').classList.remove('active');
      document.getElementById('loginForm').style.display = '';
      document.getElementById('registerForm').style.display = 'none';
    });
    document.getElementById('registerTab').addEventListener('click', function () {
      document.getElementById('registerTab').classList.add('active');
      document.getElementById('loginTab').classList.remove('active');
      document.getElementById('registerForm').style.display = '';
      document.getElementById('loginForm').style.display = 'none';
    });
  }

  App._login = async function (e) {
    e.preventDefault();
    const btn = e.target.querySelector('button[type=submit]');
    btn.disabled = true; btn.textContent = 'Signing in...';
    const res = await MayaStore.auth.login(
      document.getElementById('loginEmail').value,
      document.getElementById('loginPassword').value
    );
    if (res.ok) {
      L().toast('Welcome back!', 'success');
      boot(res.data);
    } else {
      L().toast(res.error || 'Login failed', 'error');
      btn.disabled = false; btn.textContent = 'Sign In';
    }
  };

  App._register = async function (e) {
    e.preventDefault();
    const btn = e.target.querySelector('button[type=submit]');
    btn.disabled = true; btn.textContent = 'Creating...';
    const res = await MayaStore.auth.register(
      document.getElementById('regName').value,
      document.getElementById('regEmail').value,
      document.getElementById('regPassword').value
    );
    if (res.ok) {
      L().toast('Account created!', 'success');
      boot(res.data);
    } else {
      L().toast(res.error || 'Registration failed', 'error');
      btn.disabled = false; btn.textContent = 'Create Account';
    }
  };

  /* ── Global Event Bindings ── */

  function bindGlobalListeners() {
    // Auth: unauthorized redirect
    MayaAPI.onUnauthorized(function () {
      MayaStore.auth.logout();
      showLogin();
      L().toast('Session expired — please sign in again', 'warning');
    });

    // WebSocket for live task updates
    MayaAPI.subscribe(function (msg) {
      if (msg.type === 'task_progress') {
        const route = R().getCurrentRoute();
        if (route === 'agents') {
          // Refresh agent task list if on agents page
          const screen = window.MayaScreens && window.MayaScreens.agents;
          if (screen) screen();
        }
      }
      if (msg.type === 'task_done') {
        L().toast('Task completed: ' + ((msg.task && msg.task.goal) || '').slice(0, 50), 'success');
      }
    });
  }

  /* ── Boot ── */

  init();
})();
