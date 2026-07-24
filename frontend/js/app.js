/**
 * Maya 2.0 ULTRA — Application Logic
 *
 * SPA router, screen rendering, event bindings, error boundaries,
 * hardware integration, and full feature-to-backend wiring.
 */
(function () {
  'use strict';

  /* ════════════════════════════════════════════
     APP STATE & INIT
  ════════════════════════════════════════════ */
  const App = {};
  window.MayaApp = App;
  const $ = (sel, ctx) => (ctx || document).querySelector(sel);
  const $$ = (sel, ctx) => Array.from((ctx || document).querySelectorAll(sel));

  // ── SPA Routes ──
  const ROUTES = {
    'dashboard':    { label: 'Dashboard',     icon: '📊', screen: 'screenDashboard' },
    'agent':        { label: 'Agent',          icon: '🤖', screen: 'screenAgent' },
    'tasks':        { label: 'Tasks',          icon: '📋', screen: 'screenTasks' },
    'chat':         { label: 'Chat',            icon: '💬', screen: 'screenChat' },
    'memory':       { label: 'Memory',         icon: '🧠', screen: 'screenMemory' },
    'tools':        { label: 'Tools',          icon: '🔧', screen: 'screenTools' },
    'providers':    { label: 'LLM Providers',  icon: '⚡', screen: 'screenLLM' },
    'analytics':    { label: 'Analytics',      icon: '📈', screen: 'screenAnalytics' },
    'workflows':    { label: 'Workflows',      icon: '🔄', screen: 'screenWorkflows' },
    'webhooks':     { label: 'Webhooks',       icon: '🔗', screen: 'screenWebhooks' },
    'notifications':{ label: 'Notifications',  icon: '🔔', screen: 'screenNotifications' },
    'cognition':    { label: 'Cognition',      icon: '🧬', screen: 'screenCognition' },
    'hosting':      { label: 'Hosting',        icon: '☁️', screen: 'screenHosting' },
    'plugins':      { label: 'Plugins',        icon: '🔌', screen: 'screenPlugins' },
    'prompts':      { label: 'Prompts',        icon: '📝', screen: 'screenPrompts' },
    'rag':          { label: 'Knowledge Base', icon: '📚', screen: 'screenRAG' },
    'vision':       { label: 'Vision',         icon: '👁️', screen: 'screenVision' },
    'voice':        { label: 'Voice',          icon: '🎤', screen: 'screenVoice' },
    'translate':    { label: 'Translate',      icon: '🌐', screen: 'screenTranslate' },
    'schedules':    { label: 'Schedules',      icon: '⏰', screen: 'screenSchedules' },
    'projects':     { label: 'Projects',       icon: '🎯', screen: 'screenProjects' },
    'logs':         { label: 'Logs',           icon: '📜', screen: 'screenLogs' },
    'devices':      { label: 'Device Bridge',  icon: '🖥️', screen: 'screenDevices' },
    'instances':    { label: 'Instances',      icon: '📦', screen: 'screenInstances' },
    'backups':      { label: 'Backups',        icon: '💾', screen: 'screenBackups' },
    'research':     { label: 'Research',       icon: '🔬', screen: 'screenResearch' },
    'publish':      { label: 'Publish',        icon: '🚀', screen: 'screenPublish' },
    'controls':     { label: 'Controls',       icon: '🎮', screen: 'screenControls' },
    'admin':        { label: 'Admin',          icon: '⚙️', screen: 'screenAdmin' },
  };

  // ── Toast system ──
  function toast(msg, type = 'info', duration = 4000) {
    const el = document.createElement('div');
    el.className = 'toast toast-' + type;
    el.textContent = msg;
    document.getElementById('toasts').appendChild(el);
    setTimeout(() => { el.style.opacity = '0'; setTimeout(() => el.remove(), 300); }, duration);
  }
  App.toast = toast;

  // ── Modal system ──
  function openModal(html) {
    document.getElementById('modalContent').innerHTML = html;
    document.getElementById('modalOverlay').classList.add('active');
  }
  function closeModal() { document.getElementById('modalOverlay').classList.remove('active'); }
  App.openModal = openModal; App.closeModal = closeModal;
  document.getElementById('modalOverlay').addEventListener('click', function (e) {
    if (e.target === this) closeModal();
  });

  // ── Error boundary ──
  function safeRender(fn, fallback) {
    try { return fn(); } catch (e) {
      console.error('Render error:', e);
      return fallback || `<div class="empty">⚠️ Something went wrong rendering this section.</div>`;
    }
  }

  // ── Loading indicator ──
  function loadingSpinner(msg) { return `<div class="empty"><span class="spinner"></span> ${msg || 'Loading...'}</div>`; }

  // ── Router ──
  let currentRoute = 'dashboard';
  function navigateTo(route) {
    if (!ROUTES[route]) route = 'dashboard';
    currentRoute = route;
    // Update nav
    $$('.sidebar-nav a').forEach(a => a.classList.toggle('active', a.dataset.route === route));
    // Render screen
    const main = document.getElementById('main');
    try { ROUTES[route].screen(); } catch (e) {
      console.error('Route error:', e);
      main.innerHTML = `<div class="empty"><h3>⚠️ Error loading ${route}</h3><p>${e.message}</p>
        <button onclick="MayaApp.navigate('dashboard')" class="primary mt-md">Go to Dashboard</button></div>`;
    }
    window.scrollTo(0, 0);
  }
  App.navigate = navigateTo;

  // ── Sidebar builder ──
  function buildSidebar() {
    const nav = document.getElementById('nav');
    nav.innerHTML = Object.keys(ROUTES).map(key => {
      const r = ROUTES[key];
      return `<a href="#" data-route="${key}" onclick="MayaApp.navigate('${key}')">
        <span class="icon">${r.icon}</span><span>${r.label}</span></a>`;
    }).join('\n');
  }

  // ── Init auth check ──
  async function init() {
    const token = MayaAPI.getToken();
    if (token) {
      const res = await MayaAPI.auth.me();
      if (res.ok) {
        MayaStore._set('user', res.data);
        buildSidebar();
        navigateTo(getRouteFromHash() || 'dashboard');
        document.getElementById('sidebarUser').textContent = res.data?.email || 'Logged in';
        bindGlobalListeners();
        return;
      }
    }
    showLogin();
  }

  function getRouteFromHash() {
    const hash = location.hash.replace('#', '');
    return ROUTES[hash] ? hash : null;
  }
  window.addEventListener('hashchange', () => {
    const r = getRouteFromHash();
    if (r) navigateTo(r);
  });

  /* ════════════════════════════════════════════
     LOGIN SCREEN
  ════════════════════════════════════════════ */
  function showLogin() {
    document.getElementById('main').innerHTML = `
    <div class="login-page">
    <div class="login-box">
    <h1>🧠 Maya 2.0 ULTRA</h1>
    <p>Sign in to your autonomous AI agent</p>
    <div class="login-tabs">
      <button class="active" data-tab="login" onclick="document.querySelector('.login-box .login-tabs .active').classList.remove('active');this.classList.add('active');document.getElementById('loginForm').style.display='';document.getElementById('registerForm').style.display='none'">Sign In</button>
      <button data-tab="register" onclick="document.querySelector('.login-box .login-tabs .active').classList.remove('active');this.classList.add('active');document.getElementById('loginForm').style.display='none';document.getElementById('registerForm').style.display=''">Register</button>
    </div>
    <form id="loginForm" onsubmit="return MayaApp._login(event)">
      <div class="form-group"><label>Email</label><input type="email" id="loginEmail" placeholder="admin@maya.ai" required autofocus></div>
      <div class="form-group"><label>Password</label><input type="password" id="loginPassword" placeholder="••••••••" required></div>
      <button type="submit" class="primary" style="width:100%;margin-top:8px">Sign In</button>
    </form>
    <form id="registerForm" style="display:none" onsubmit="return MayaApp._register(event)">
      <div class="form-group"><label>Name</label><input type="text" id="regName" placeholder="Your name"></div>
      <div class="form-group"><label>Email</label><input type="email" id="regEmail" placeholder="you@example.com" required></div>
      <div class="form-group"><label>Password</label><input type="password" id="regPassword" placeholder="••••••••" required></div>
      <button type="submit" class="primary" style="width:100%;margin-top:8px">Create Account</button>
    </form>
    </div></div>`;
    document.getElementById('sidebar').style.display = 'none';
  }

  App._login = async function (e) {
    e.preventDefault();
    const btn = e.target.querySelector('button[type=submit]');
    btn.disabled = true; btn.textContent = 'Signing in...';
    const res = await MayaStore.auth.login($('#loginEmail').value, $('#loginPassword').value);
    if (res.ok) {
      toast('Welcome back!', 'success');
      document.getElementById('sidebar').style.display = '';
      buildSidebar();
      navigateTo('dashboard');
      document.getElementById('sidebarUser').textContent = res.data.email;
      bindGlobalListeners();
    } else {
      toast(res.error || 'Login failed', 'error');
      btn.disabled = false; btn.textContent = 'Sign In';
    }
  };

  App._register = async function (e) {
    e.preventDefault();
    const btn = e.target.querySelector('button[type=submit]');
    btn.disabled = true; btn.textContent = 'Creating...';
    const res = await MayaStore.auth.register($('#regName').value, $('#regEmail').value, $('#regPassword').value);
    if (res.ok) {
      toast('Account created!', 'success');
      document.getElementById('sidebar').style.display = '';
      buildSidebar();
      navigateTo('dashboard');
      document.getElementById('sidebarUser').textContent = res.data.email;
      bindGlobalListeners();
    } else {
      toast(res.error || 'Registration failed', 'error');
      btn.disabled = false; btn.textContent = 'Create Account';
    }
  };

  /* ════════════════════════════════════════════
     GLOBAL EVENT BINDINGS
  ════════════════════════════════════════════ */
  function bindGlobalListeners() {
    // Auth: unauthorized redirect
    MayaAPI.onUnauthorized(() => {
      MayaStore.auth.logout();
      showLogin();
      toast('Session expired — please sign in again', 'warning');
    });
    // WebSocket for live task updates
    MayaAPI.subscribe((msg) => {
      if (msg.type === 'task_progress' && currentRoute === 'tasks') {
        MayaStore.tasks.load(50);
      }
      if (msg.type === 'task_done') {
        toast('Task completed: ' + (msg.task?.goal || '').slice(0, 50), 'success');
        if (currentRoute === 'tasks' || currentRoute === 'dashboard') {
          MayaStore.tasks.load(10);
          MayaStore.loadDashboard();
        }
      }
    });
  }

  /* ════════════════════════════════════════════
     SCREEN: DASHBOARD
  ════════════════════════════════════════════ */
  ROUTES.dashboard.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">📊 Dashboard</h2>${loadingSpinner('Loading dashboard...')}`;
    await MayaStore.loadDashboard();
    const s = MayaStore.getState();
    const a = s.analytics.summary || {};
    const status = s.agentStatus || {};
    main.innerHTML = safeRender(() => `
    <div class="card-grid">
    <div class="card stat"><div class="stat-value">${a.total_tasks || 0}</div><div class="stat-label">Total Tasks</div></div>
    <div class="card stat"><div class="stat-value">${a.success_rate || 0}%</div><div class="stat-label">Success Rate</div></div>
    <div class="card stat"><div class="stat-value">$${(a.total_cost_usd || 0).toFixed(4)}</div><div class="stat-label">Total Cost</div></div>
    <div class="card stat"><div class="stat-value">${(status.tools || []).length || 0}</div><div class="stat-label">Tools</div></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Maya Status</h3></div>
      <div class="form-row">
      <div><strong>Version:</strong> ${status.version || '—'}</div>
      <div><strong>Providers:</strong> ${(status.providers || []).length || 0}</div>
      <div><strong>Plugins:</strong> ${(status.plugins || []).length || 0}</div>
      <div><strong>Budget:</strong> $${(a.budget_usd || 0).toFixed(2)}</div>
      </div>
      <div class="progress-bar mt-sm"><div class="progress-fill" style="width:${Math.min(a.budget_used_pct || 0, 100)}%"></div></div>
      <div class="text-sm">Budget used: ${(a.budget_used_pct || 0).toFixed(1)}%</div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Recent Tasks</h3><button onclick="MayaApp.navigate('tasks')">View All</button></div>
      ${renderTaskTable(s.tasks.slice(0, 5))}
    </div>
    <div class="card">
      <div class="card-header"><h3>Quick Actions</h3></div>
      <div class="flex">
      <button onclick="MayaApp.navigate('agent')" class="primary">🤖 Run Agent</button>
      <button onclick="MayaApp.navigate('chat')">💬 Chat</button>
      <button onclick="MayaApp.navigate('memory')">🧠 Memory</button>
      <button onclick="MayaApp.navigate('tools')">🔧 Tools</button>
      <button onclick="MayaApp._quickThink()">🤔 Quick Think</button>
      </div>
    </div>`, `<div class="empty">⚠️ Dashboard error</div>`);
  };

  App._quickThink = async function () {
    openModal(`<h2>🤔 Quick Think</h2>
    <div class="form-group"><label>Problem</label><textarea id="thinkInput" rows="4" placeholder="Ask Maya to think deeply..."></textarea></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doThink()">Think</button>
    </div>
    <div id="thinkResult" class="mt-sm text-sm"></div>`);
  };
  App._doThink = async function () {
    const input = $('#thinkInput'); const result = $('#thinkResult');
    result.innerHTML = '<span class="spinner"></span> Thinking...';
    const res = await MayaAPI.agent.think(input.value);
    result.innerHTML = res.ok ? `<pre>${res.data?.result || res.data}</pre>` : `Error: ${res.error}`;
  };

  /* ── Shared helpers ── */
  function renderTaskTable(tasks) {
    if (!tasks || !tasks.length) return '<div class="empty">No tasks yet</div>';
    return `<div class="table-wrap"><table>
    <tr><th>Goal</th><th>Status</th><th>Steps</th><th>Cost</th><th>Time</th></tr>
    ${tasks.map(t => `<tr class="pointer" onclick="MayaApp.navigate('tasks')">
    <td class="truncate">${esc(t.goal || '')}</td>
    <td><span class="tag tag-${t.status}">${t.status}</span></td>
    <td>${(t.steps || []).length}</td>
    <td>$${(t.cost_usd || 0).toFixed(4)}</td>
    <td class="text-sm">${t.created_at ? new Date(t.created_at).toLocaleTimeString() : '—'}</td>
    </tr>`).join('\n')}
    </table></div>`;
  }

  function esc(s) {
    const d = document.createElement('div');
    d.textContent = s || '';
    return d.innerHTML;
  }

  /* ════════════════════════════════════════════
     SCREEN: AGENT RUN
  ════════════════════════════════════════════ */
  ROUTES.agent.screen = function () {
    const main = document.getElementById('main');
    main.innerHTML = `
    <h2 style="margin-bottom:16px">🤖 Run Agent</h2>
    <div class="card">
    <div class="form-group"><label>Goal</label><textarea id="agentGoal" rows="3" placeholder="e.g. Search the web for latest AI news and summarize..."></textarea></div>
    <div class="form-row">
      <div class="form-group"><label>Budget ($)</label><input type="number" id="agentBudget" value="1.0" step="0.1" min="0"></div>
      <div class="form-group"><label>Instance (optional)</label>
        <select id="agentInstance"><option value="">— None —</option></select></div>
    </div>
    <button onclick="MayaApp._runAgent()" class="primary" style="width:100%">🚀 Execute Goal</button>
    <div id="agentResult" class="mt-md" style="display:none"></div>
    </div>`;
    // Load instances for the dropdown
    MayaStore.loadInstances();
    setTimeout(() => {
      const inst = MayaStore.get('instances') || [];
      const sel = document.getElementById('agentInstance');
      sel.innerHTML = '<option value="">— None —</option>' + inst.map(i =>
        `<option value="${i.id}">${esc(i.name)}</option>`).join('');
    }, 500);
  };

  App._runAgent = async function () {
    const goal = $('#agentGoal').value; const budget = parseFloat($('#agentBudget').value) || 1;
    const instanceId = $('#agentInstance').value;
    if (!goal.trim()) { toast('Enter a goal', 'warning'); return; }
    const result = document.getElementById('agentResult');
    result.style.display = ''; result.innerHTML = '<span class="spinner"></span> Starting task...';
    const res = await MayaAPI.agent.run(goal, { budget, instanceId });
    if (res.ok) {
      result.innerHTML = `<div class="tag tag-running">Task started: ${res.data?.id}</div>
      <div class="mt-sm">Task is running in the background. <a href="#" onclick="MayaApp.navigate('tasks')">View progress →</a></div>`;
      toast('Task started!', 'success');
      MayaStore.tasks.load(50);
    } else {
      result.innerHTML = `<div class="tag tag-error">Error: ${esc(res.error)}</div>`;
      toast(res.error || 'Failed to start task', 'error');
    }
  };

  /* ════════════════════════════════════════════
     SCREEN: CHAT
  ════════════════════════════════════════════ */
  ROUTES.chat.screen = function () {
    const main = document.getElementById('main');
    main.innerHTML = `
    <h2 style="margin-bottom:16px">💬 Chat with Maya</h2>
    <div class="card" style="display:flex;flex-direction:column;min-height:60vh">
    <div id="chatMessages" style="flex:1;overflow-y:auto;margin-bottom:12px;padding:8px"></div>
    <div class="flex" style="border-top:1px solid var(--border);padding-top:12px">
      <textarea id="chatInput" rows="2" style="flex:1;min-height:44px" placeholder="Type your message..." onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();MayaApp._sendChat()}"></textarea>
      <button onclick="MayaApp._sendChat()" class="primary" style="height:44px">Send</button>
      <button onclick="MayaApp._voiceChat()" style="height:44px" title="Voice input">🎤</button>
    </div>
    </div>`;
    App._chatHistory = [];
  };

  App._sendChat = async function () {
    const input = $('#chatInput');
    const msg = input.value.trim();
    if (!msg) return;
    input.value = '';
    addChatMessage('user', msg);
    addChatMessage('assistant', '<span class="spinner"></span> Thinking...');
    const res = await MayaAPI.agent.chat(msg);
    const msgs = document.querySelectorAll('#chatMessages > div');
    if (msgs.length) msgs[msgs.length - 1].remove();
    addChatMessage('assistant', res.ok ? (res.data?.reply || JSON.stringify(res.data)) : (res.error || 'Error'));
  };

  function addChatMessage(role, content) {
    const container = document.getElementById('chatMessages');
    const div = document.createElement('div');
    div.style.cssText = `margin-bottom:8px;padding:10px 14px;border-radius:8px;max-width:85%;
      ${role === 'user' ? 'background:var(--accent2);align-self:flex-end;margin-left:auto;' : 'background:var(--bg3);'}`;
    div.innerHTML = `<div class="text-sm" style="margin-bottom:4px;color:var(--text2)">${role === 'user' ? 'You' : 'Maya'}</div>
      <div>${content}</div>`;
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
  }

  App._voiceChat = async function () {
    const res = await MayaHardware.voice.startRecording();
    if (!res.ok) { toast(res.error, 'error'); return; }
    toast('Recording... tap again to stop', 'info');
    // Simple: record 5 seconds
    setTimeout(async () => {
      const stop = await MayaHardware.voice.stopRecording();
      if (!stop.ok) { toast(stop.error, 'error'); return; }
      addChatMessage('user', '🎤 [Voice input]');
      addChatMessage('assistant', '<span class="spinner"></span> Transcribing...');
      const reader = new FileReader();
      reader.onloadend = async function () {
        const b64 = reader.result.split(',')[1];
        const trans = await MayaAPI.voice.transcribe(b64, stop.blob.type);
        const msgs = document.querySelectorAll('#chatMessages > div');
        if (msgs.length) msgs[msgs.length - 1].remove();
        if (trans.ok) {
          addChatMessage('user', '🎤 ' + (trans.data?.text || trans.data?.transcript || ''));
          addChatMessage('assistant', '<span class="spinner"></span> Thinking...');
          const reply = await MayaAPI.agent.chat(trans.data?.text || trans.data?.transcript || '');
          if (msgs.length) msgs[msgs.length - 1]?.remove();
          addChatMessage('assistant', reply.ok ? (reply.data?.reply || '') : (reply.error || 'Error'));
        } else {
          toast('Transcription failed', 'error');
        }
      };
      reader.readAsDataURL(stop.blob);
    }, 5000);
  };

  /* ════════════════════════════════════════════
     SCREEN: TASKS
  ════════════════════════════════════════════ */
  ROUTES.tasks.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">📋 Tasks</h2>${loadingSpinner('Loading tasks...')}`;
    await MayaStore.tasks.load(100);
    const tasks = MayaStore.get('tasks') || [];
    const detail = MayaStore.get('taskDetail');
    main.innerHTML = safeRender(() => `
    <div class="flex-between mb-md">
      <div class="flex">
        <button class="primary" onclick="MayaApp.navigate('agent')">+ New Task</button>
        <button onclick="MayaApp._refreshTasks()">🔄 Refresh</button>
      </div>
      <div class="flex">
        <select id="taskFilter" onchange="MayaApp._refreshTasks()">
          <option value="">All Status</option>
          <option value="running">Running</option>
          <option value="done">Done</option>
          <option value="failed">Failed</option>
          <option value="pending">Pending</option>
        </select>
      </div>
    </div>
    <div class="card">
      ${renderTaskTable(tasks)}
    </div>
    ${detail ? `<div class="card"><div class="card-header"><h3>Task Detail</h3><button onclick="MayaStore._set('taskDetail',null);MayaApp._refreshTasks()">Close</button></div>
    <pre>${esc(JSON.stringify(detail, null, 2))}</pre></div>` : ''}
    `, `<div class="empty">⚠️ Error loading tasks</div>`);
  };

  App._refreshTasks = async function () {
    const filter = document.getElementById('taskFilter')?.value;
    await MayaStore.tasks.load(100, filter || undefined);
    ROUTES.tasks.screen();
  };

  /* ════════════════════════════════════════════
     SCREEN: MEMORY
  ════════════════════════════════════════════ */
  ROUTES.memory.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">🧠 Memory</h2>${loadingSpinner('Loading...')}`;
    await MayaStore.loadMemory();
    const mem = MayaStore.get('memories') || [];
    const stats = MayaStore.get('memoryStats') || {};
    main.innerHTML = safeRender(() => `
    <div class="card-grid mb-md">
      <div class="card stat"><div class="stat-value">${stats.total || mem.length}</div><div class="stat-label">Total Memories</div></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Add Memory</h3></div>
      <div class="form-row">
        <div style="flex:3"><input type="text" id="memInput" placeholder="Enter memory content..."></div>
        <div style="flex:1">
          <select id="memType"><option value="general">General</option><option value="fact">Fact</option><option value="preference">Preference</option><option value="lesson">Lesson</option></select>
        </div>
        <div><button onclick="MayaApp._addMemory()" class="primary">Save</button></div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Search</h3></div>
      <div class="flex">
        <input type="text" id="memSearch" placeholder="Search memories..." style="flex:1" onkeydown="if(event.key==='Enter')MayaApp._searchMemory()">
        <button onclick="MayaApp._searchMemory()">🔍 Search</button>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><h3>All Memories (${mem.length})</h3></div>
      ${mem.length ? `<div class="table-wrap"><table>
      <tr><th>Content</th><th>Type</th><th>Actions</th></tr>
      ${mem.map(m => `<tr>
        <td>${esc(typeof m === 'string' ? m : m.content || JSON.stringify(m))}</td>
        <td><span class="tag tag-env">${m.type || 'general'}</span></td>
        <td><button class="danger" onclick="MayaAPI.memory.delete('${m.id || ''}').then(()=>MayaApp.navigate('memory'))">Delete</button></td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No memories stored yet</div>'}
    </div>`, `<div class="empty">⚠️ Error loading memory</div>`);
  };

  App._addMemory = async function () {
    const input = document.getElementById('memInput');
    const type = document.getElementById('memType').value;
    if (!input.value.trim()) return;
    await MayaStore.memory.add(input.value, type);
    input.value = '';
    toast('Memory saved', 'success');
    MayaStore.loadMemory();
    ROUTES.memory.screen();
  };

  App._searchMemory = async function () {
    const q = document.getElementById('memSearch').value.trim();
    if (!q) { MayaStore.loadMemory(); ROUTES.memory.screen(); return; }
    await MayaStore.memory.search(q);
    ROUTES.memory.screen();
  };

  /* ════════════════════════════════════════════
     SCREEN: TOOLS
  ════════════════════════════════════════════ */
  ROUTES.tools.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">🔧 Tools</h2>${loadingSpinner('Loading...')}`;
    await MayaStore.loadTools();
    const tools = MayaStore.get('tools') || [];
    const logs = MayaStore.get('toolsLog') || [];
    main.innerHTML = safeRender(() => `
    <div class="card">
      <div class="card-header"><h3>Run a Tool</h3></div>
      <div class="form-row">
        <div style="flex:1">
          <select id="toolSelect"><option value="">— Select tool —</option>
          ${tools.map(t => `<option value="${t.name}">${t.name}</option>`).join('')}
          </select>
        </div>
        <div style="flex:2"><input type="text" id="toolInput" placeholder='Input JSON (e.g. {"query":"hello"})'></div>
        <div><button onclick="MayaApp._runTool()" class="primary">Run</button></div>
      </div>
      <div id="toolResult" class="mt-sm text-sm"></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>All Tools (${tools.length})</h3></div>
      <div class="table-wrap"><table>
      <tr><th>Name</th><th>Category</th><th>Description</th><th>Calls</th><th>Success</th></tr>
      ${tools.map(t => `<tr>
        <td class="text-mono">${esc(t.name)}</td>
        <td><span class="tag tag-env">${t.category || 'general'}</span></td>
        <td class="text-sm">${esc((t.description || '').slice(0, 80))}</td>
        <td>${t.call_count || t.calls || 0}</td>
        <td>${t.success_rate || 0}%</td>
      </tr>`).join('\n')}
      </table></div>
    </div>
    ${logs.length ? `<div class="card">
    <div class="card-header"><h3>Recent Tool Logs</h3></div>
    <div class="table-wrap"><table>
    <tr><th>Tool</th><th>Calls</th><th>Success</th><th>Failures</th><th>Avg Time</th></tr>
    ${logs.slice(0, 20).map(l => `<tr>
      <td class="text-mono">${esc(l.tool)}</td>
      <td>${l.calls || 0}</td>
      <td>${l.successes || 0}</td>
      <td>${l.failures || 0}</td>
      <td>${(l.avg_time || 0).toFixed(3)}s</td>
    </tr>`).join('\n')}
    </table></div></div>` : ''}
    `, `<div class="empty">⚠️ Error loading tools</div>`);
  };

  App._runTool = async function () {
    const name = document.getElementById('toolSelect').value;
    const input = document.getElementById('toolInput').value;
    if (!name) { toast('Select a tool', 'warning'); return; }
    let parsed = {};
    try { if (input.trim()) parsed = JSON.parse(input); } catch { toast('Invalid JSON input', 'error'); return; }
    const result = document.getElementById('toolResult');
    result.innerHTML = '<span class="spinner"></span> Running...';
    const res = await MayaAPI.tools.run(name, parsed);
    result.innerHTML = res.ok ? `<pre>${esc(JSON.stringify(res.data, null, 2))}</pre>` : `Error: ${esc(res.error)}`;
  };

  /* ════════════════════════════════════════════
     SCREEN: LLM PROVIDERS
  ════════════════════════════════════════════ */
  ROUTES.providers.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">⚡ LLM Providers</h2>${loadingSpinner('Loading...')}`;
    await MayaStore.loadLLM();
    const provs = MayaStore.get('llmProviders') || [];
    const stats = MayaStore.get('llmStats') || {};
    const strategy = MayaStore.get('llmStrategy') || {};
    main.innerHTML = safeRender(() => `
    <div class="card">
      <div class="card-header"><h3>Strategy</h3></div>
      <pre>${esc(JSON.stringify(strategy, null, 2))}</pre>
    </div>
    <div class="card">
      <div class="card-header"><h3>Providers</h3></div>
      <div class="table-wrap"><table>
      <tr><th>Provider</th><th>Status</th><th>Actions</th></tr>
      ${(Array.isArray(provs) ? provs : Object.entries(provs).map(([k, v]) => ({name: k, ...v}))).map(p =>
        `<tr>
        <td><strong>${esc(p.name || p.id || '')}</strong></td>
        <td><span class="tag ${p.enabled ? 'tag-success' : 'tag-disabled'}">${p.enabled ? 'Enabled' : 'Disabled'}</span></td>
        <td class="flex">
          <button onclick="MayaAPI.providers.toggle('${p.name || p.id}', ${!p.enabled}).then(()=>MayaStore.providers.llmLoad())">${p.enabled ? 'Disable' : 'Enable'}</button>
          <button onclick="MayaApp._setProviderKey('${p.name || p.id}')">🔑 Set Key</button>
        </td>
        </tr>`).join('\n')}
      </table></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Usage Stats</h3></div>
      <pre>${esc(JSON.stringify(stats, null, 2))}</pre>
    </div>`, `<div class="empty">⚠️ Error loading providers</div>`);
  };

  App._setProviderKey = function (provider) {
    openModal(`<h2>🔑 Set API Key: ${esc(provider)}</h2>
    <div class="form-group"><label>API Key</label><input type="password" id="providerKey" placeholder="Enter key..."></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doSetKey('${provider}')">Save</button>
    </div>`);
  };
  App._doSetKey = async function (provider) {
    const key = document.getElementById('providerKey').value;
    if (!key) { toast('Enter a key', 'warning'); return; }
    await MayaAPI.providers.setKey(provider, key);
    closeModal();
    toast('Key saved for ' + provider, 'success');
    await MayaStore.loadLLM();
    ROUTES.providers.screen();
  };

  /* ════════════════════════════════════════════
     SCREEN: ANALYTICS
  ════════════════════════════════════════════ */
  ROUTES.analytics.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">📈 Analytics</h2>${loadingSpinner('Loading...')}`;
    await MayaStore.analytics.loadAll();
    const a = MayaStore.get('analytics') || {};
    main.innerHTML = safeRender(() => `
    <div class="card-grid mb-md">
      <div class="card stat"><div class="stat-value">${a.summary?.total_tasks || 0}</div><div class="stat-label">Total Tasks</div></div>
      <div class="card stat"><div class="stat-value">${a.summary?.success_rate || 0}%</div><div class="stat-label">Success Rate</div></div>
      <div class="card stat"><div class="stat-value">$${(a.summary?.total_cost_usd || 0).toFixed(4)}</div><div class="stat-label">Cost</div></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Daily Activity</h3></div>
      ${(a.daily || []).length ? `<div class="table-wrap"><table>
      <tr><th>Date</th><th>Tasks</th></tr>
      ${a.daily.map(d => `<tr><td>${d.date}</td><td>${d.tasks}</td></tr>`).join('\n')}
      </table></div>` : '<div class="empty">No daily data</div>'}
    </div>
    <div class="card">
      <div class="card-header"><h3>Provider Usage</h3></div>
      <pre>${esc(JSON.stringify(a.providers || {}, null, 2))}</pre>
    </div>`, `<div class="empty">⚠️ Error loading analytics</div>`);
  };

  /* ════════════════════════════════════════════
     REMAINING SCREENS — compact pattern
  ════════════════════════════════════════════ */

  // Generic screen factory for list-heavy screens
  function makeListScreen(title, icon, loadFn, renderFn) {
    return async function () {
      const main = document.getElementById('main');
      main.innerHTML = `<h2 style="margin-bottom:16px">${icon} ${title}</h2>${loadingSpinner()}`;
      if (loadFn) await loadFn();
      main.innerHTML = safeRender(() => renderFn(), `<div class="empty">⚠️ Error loading ${title}</div>`);
    };
  }

  // Workflows
  ROUTES.workflows.screen = makeListScreen('Workflows', '🔄', () => MayaStore.loadWorkflows(), () => {
    const wf = MayaStore.get('workflows') || [];
    const defs = MayaStore.get('workflowDefs') || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._createWorkflow()">+ New Workflow</button>
    </div>
    <div class="card">
      <div class="card-header"><h3>Workflow Definitions (${defs.length})</h3></div>
      ${defs.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Steps</th><th>Created</th><th>Actions</th></tr>
      ${defs.map(d => `<tr>
        <td>${esc(d.name)}</td>
        <td>${(d.steps || []).length}</td>
        <td class="text-sm">${d.created_at ? new Date(d.created_at).toLocaleString() : '—'}</td>
        <td class="flex">
          <button onclick="MayaAPI.workflows.runDef('${d.id}').then(()=>toast('Workflow started','success'))">▶️ Run</button>
        </td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No workflow definitions</div>'}
    </div>
    <div class="card">
      <div class="card-header"><h3>Recent Workflow Runs (${wf.length})</h3></div>
      ${renderTaskTable(wf)}
    </div>`;
  });

  App._createWorkflow = function () {
    openModal(`<h2>New Workflow</h2>
    <div class="form-group"><label>Name</label><input id="wfName" placeholder="My Workflow"></div>
    <div class="form-group"><label>Description</label><textarea id="wfDesc" rows="2"></textarea></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doCreateWorkflow()">Create</button>
    </div>`);
  };
  App._doCreateWorkflow = async function () {
    const name = document.getElementById('wfName').value.trim();
    if (!name) { toast('Name required', 'warning'); return; }
    await MayaAPI.workflows.create(name, document.getElementById('wfDesc').value, [], []);
    closeModal(); toast('Workflow created', 'success');
    ROUTES.workflows.screen();
  };

  // Webhooks
  ROUTES.webhooks.screen = makeListScreen('Webhooks', '🔗', () => MayaStore.loadWebhooks(), () => {
    const wh = MayaStore.get('webhooks') || [];
    const hooks = MayaStore.get('hooks') || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._createWebhook()">+ New Webhook</button>
    </div>
    <div class="card">
      <div class="card-header"><h3>Outbound Webhooks</h3></div>
      ${wh.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Job</th><th>Actions</th></tr>
      ${wh.map(w => `<tr><td>${esc(w.name)}</td><td class="text-mono">${w.job || '—'}</td>
        <td class="flex"><button class="danger" onclick="MayaAPI.webhooks.delete('${w.id}').then(()=>MayaStore.loadWebhooks())">Delete</button></td></tr>`).join('\n')}
      </table></div>` : '<div class="empty">No webhooks configured</div>'}
    </div>
    <div class="card">
      <div class="card-header"><h3>Inbound Triggers (${hooks.length})</h3></div>
      ${hooks.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Job</th><th>Signed</th><th>Fired</th></tr>
      ${hooks.map(h => `<tr><td>${esc(h.name)}</td><td class="text-mono">${h.job}</td>
        <td>${h.signed ? '✅' : '❌'}</td><td>${h.fire_count || 0}</td></tr>`).join('\n')}
      </table></div>` : '<div class="empty">No triggers</div>'}
    </div>`;
  });

  App._createWebhook = function () {
    openModal(`<h2>Create Webhook</h2>
    <div class="form-group"><label>Name</label><input id="whName" placeholder="pr-review"></div>
    <div class="form-group"><label>Job</label><input id="whJob" value="agent_goal" class="text-mono"></div>
    <div class="form-group"><label>Template</label><textarea id="whTemplate" rows="2" class="text-mono">Review PR: {{pull_request.title}}</textarea></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doCreateWebhook()">Create</button>
    </div>`);
  };
  App._doCreateWebhook = async function () {
    const name = document.getElementById('whName').value.trim();
    if (!name) { toast('Name required', 'warning'); return; }
    await MayaAPI.webhooks.create(name, document.getElementById('whJob').value, document.getElementById('whTemplate').value, true);
    closeModal(); toast('Webhook created! Secret shown once.', 'success');
    MayaStore.loadWebhooks();
    ROUTES.webhooks.screen();
  };

  // Notifications
  ROUTES.notifications.screen = makeListScreen('Notifications', '🔔', () => MayaStore.loadNotifications(), () => {
    const n = MayaStore.get('notifications') || {};
    return `
    <div class="flex-between mb-md">
      <span class="tag tag-running">${n.unread || 0} unread</span>
      <button onclick="MayaAPI.notifications.markAllRead().then(()=>MayaStore.loadNotifications())">Mark All Read</button>
    </div>
    <div class="card">
      ${(n.items || []).length ? (n.items || []).map(item => `<div style="padding:10px;border-bottom:1px solid var(--border);${item.read ? '' : 'background:var(--bg3)'}">
      <div class="flex-between"><strong>${esc(item.title)}</strong><span class="text-sm">${item.created_at ? new Date(item.created_at).toLocaleString() : ''}</span></div>
      <div class="text-sm">${esc(item.body || '')}</div>
      ${!item.read ? `<button onclick="MayaAPI.notifications.markRead('${item.id}').then(()=>MayaStore.loadNotifications())" class="mt-sm">Mark Read</button>` : ''}
      </div>`).join('') : '<div class="empty">No notifications</div>'}
    </div>`;
  });

  // Cognition
  ROUTES.cognition.screen = makeListScreen('Cognition', '🧬', () => MayaStore.loadCognition(), () => {
    const c = MayaStore.get('cognition') || {};
    const st = c.status || {};
    return `
    <div class="card-grid mb-md">
      <div class="card stat"><div class="stat-value">${(c.missions || []).length}</div><div class="stat-label">Missions</div></div>
      <div class="card stat"><div class="stat-value">${(c.objectives || []).length}</div><div class="stat-label">Objectives</div></div>
      <div class="card stat"><div class="stat-value">${st.enabled ? '✅' : '❌'}</div><div class="stat-label">Enabled</div></div>
    </div>
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._createMission()">+ New Mission</button>
      <button onclick="MayaAPI.cognition.cycle().then(()=>toast('Cycle triggered','success'))">🔄 Run Cycle</button>
      <button onclick="MayaAPI.cognition.status().then(()=>MayaStore.loadCognition())">📊 Status</button>
    </div>
    <div class="card">
      <div class="card-header"><h3>Missions</h3></div>
      ${(c.missions || []).length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Status</th><th>Self-gen</th><th>Actions</th></tr>
      ${c.missions.map(m => `<tr>
        <td>${esc(m.name)}</td>
        <td><span class="tag ${m.active ? 'tag-success' : 'tag-disabled'}">${m.active ? 'Active' : 'Inactive'}</span></td>
        <td>${m.self_gen ? '✅' : '❌'}</td>
        <td class="flex">
          <button onclick="MayaAPI.cognition.generateObjectives('${m.id}').then(()=>toast('Generated','success'))">Generate</button>
          <button onclick="MayaAPI.cognition.deleteMission('${m.id}').then(()=>MayaStore.loadCognition())" class="danger">Delete</button>
        </td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No missions</div>'}
    </div>
    ${st.mode ? `<div class="card"><div class="card-header"><h3>Status</h3></div><pre>${esc(JSON.stringify(st, null, 2))}</pre></div>` : ''}`;
  });

  App._createMission = function () {
    openModal(`<h2>New Mission</h2>
    <div class="form-group"><label>Name</label><input id="cogName" placeholder="Monitor VPS health"></div>
    <div class="form-group"><label>Directive</label><textarea id="cogDirective" rows="3" placeholder="What should this mission accomplish?"></textarea></div>
    <div class="form-group"><label><input type="checkbox" id="cogSelfGen" checked> Auto-generate objectives</label></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doCreateMission()">Create</button>
    </div>`);
  };
  App._doCreateMission = async function () {
    const name = document.getElementById('cogName').value.trim();
    if (!name) { toast('Name required', 'warning'); return; }
    await MayaAPI.cognition.createMission(name, document.getElementById('cogDirective').value, document.getElementById('cogSelfGen').checked);
    closeModal(); toast('Mission created', 'success');
    MayaStore.loadCognition();
    ROUTES.cognition.screen();
  };

  // Hosting
  ROUTES.hosting.screen = makeListScreen('Hosting', '☁️', () => MayaStore.loadHosting(), () => {
    const h = MayaStore.get('hosting') || {};
    return `
    <div class="card">
      <div class="card-header"><h3>Deployed Apps (${(h.apps || []).length})</h3>
        <button onclick="MayaApp._deployApp()" class="primary">+ Deploy</button>
      </div>
      ${(h.apps || []).length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Actions</th></tr>
      ${h.apps.map(a => `<tr>
        <td>${esc(a.name || a)}</td>
        <td class="flex">
          <button onclick="MayaAPI.hosting.startApp('${a.name || a}').then(()=>toast('Started','success'))">▶️ Start</button>
          <button onclick="MayaAPI.hosting.stopApp('${a.name || a}').then(()=>toast('Stopped','success'))">⏹ Stop</button>
          <button onclick="MayaAPI.hosting.deleteApp('${a.name || a}').then(()=>MayaStore.loadHosting())" class="danger">Delete</button>
        </td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No apps deployed</div>'}
    </div>
    <div class="card">
      <div class="card-header"><h3>App Registry (${(h.registry || []).length})</h3></div>
      ${(h.registry || []).length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Image</th><th>Status</th></tr>
      ${h.registry.map(r => `<tr>
        <td>${esc(r.name)}</td>
        <td class="text-mono">${esc(r.image || '—')}</td>
        <td><span class="tag ${r.active ? 'tag-success' : 'tag-disabled'}">${r.active ? 'Active' : 'Inactive'}</span></td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No registry entries</div>'}
    </div>`;
  });

  App._deployApp = function () {
    openModal(`<h2>Deploy App</h2>
    <div class="form-group"><label>App Name</label><input id="deployName" placeholder="my-app"></div>
    <div class="form-group"><label>Source (git URL or directory)</label><input id="deploySource" placeholder="https://github.com/user/repo"></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doDeploy()">Deploy</button>
    </div>`);
  };
  App._doDeploy = async function () {
    const name = document.getElementById('deployName').value.trim();
    if (!name) { toast('Name required', 'warning'); return; }
    await MayaAPI.hosting.deploy(document.getElementById('deploySource').value, name);
    closeModal(); toast('Deploy started', 'success');
    MayaStore.loadHosting();
    ROUTES.hosting.screen();
  };

  // Plugins
  ROUTES.plugins.screen = makeListScreen('Plugins', '🔌', () => MayaStore.loadPlugins(), () => {
    const plugins = MayaStore.get('plugins') || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._installPlugin()">+ Install Plugin</button>
    </div>
    <div class="card">
      ${plugins.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Enabled</th><th>Actions</th></tr>
      ${plugins.map(p => `<tr>
        <td>${esc(p.name || p.id || '')}</td>
        <td><span class="tag ${p.enabled !== false ? 'tag-success' : 'tag-disabled'}">${p.enabled !== false ? 'Enabled' : 'Disabled'}</span></td>
        <td class="flex">
          <button onclick="MayaAPI.plugins.update('${p.id}', ${!p.enabled}).then(()=>MayaStore.loadPlugins())">${p.enabled !== false ? 'Disable' : 'Enable'}</button>
          <button class="danger" onclick="MayaAPI.plugins.uninstall('${p.id}').then(()=>MayaStore.loadPlugins())">Uninstall</button>
        </td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No plugins installed</div>'}
    </div>`;
  });

  App._installPlugin = function () {
    openModal(`<h2>Install Plugin</h2>
    <div class="form-group"><label>Plugin ID</label><input id="pluginId" placeholder="plugin-name"></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doInstallPlugin()">Install</button>
    </div>`);
  };
  App._doInstallPlugin = async function () {
    const id = document.getElementById('pluginId').value.trim();
    if (!id) { toast('Plugin ID required', 'warning'); return; }
    await MayaAPI.plugins.install(id);
    closeModal(); toast('Plugin installed', 'success');
    MayaStore.loadPlugins();
    ROUTES.plugins.screen();
  };

  // Prompts
  ROUTES.prompts.screen = makeListScreen('Prompt Library', '📝', () => MayaStore.loadPrompts(), () => {
    const prompts = MayaStore.get('prompts') || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._createPrompt()">+ New Prompt</button>
    </div>
    <div class="card">
      ${prompts.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Category</th><th>Body</th></tr>
      ${prompts.map(p => `<tr>
        <td>${esc(p.name)}</td>
        <td><span class="tag tag-env">${p.category || 'general'}</span></td>
        <td class="text-sm truncate">${esc((p.body || '').slice(0, 80))}</td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No prompts saved</div>'}
    </div>`;
  });

  App._createPrompt = function () {
    openModal(`<h2>New Prompt</h2>
    <div class="form-group"><label>Name</label><input id="promptName"></div>
    <div class="form-group"><label>Category</label><input id="promptCategory" value="general"></div>
    <div class="form-group"><label>Body (use {{variable}} for placeholders)</label><textarea id="promptBody" rows="5"></textarea></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doCreatePrompt()">Save</button>
    </div>`);
  };
  App._doCreatePrompt = async function () {
    const name = document.getElementById('promptName').value.trim();
    if (!name) { toast('Name required', 'warning'); return; }
    await MayaAPI.prompts.create(name, document.getElementById('promptBody').value, document.getElementById('promptCategory').value, []);
    closeModal(); toast('Prompt saved', 'success');
    MayaStore.loadPrompts();
    ROUTES.prompts.screen();
  };

  // RAG
  ROUTES.rag.screen = makeListScreen('Knowledge Base', '📚', () => MayaStore.loadRAG(), () => {
    const r = MayaStore.get('rag') || {};
    return `
    <div class="card-grid mb-md">
      <div class="card stat"><div class="stat-value">${r.stats?.document_count || r.stats?.total_documents || 0}</div><div class="stat-label">Documents</div></div>
      <div class="card stat"><div class="stat-value">${r.stats?.chunk_count || 0}</div><div class="stat-label">Chunks</div></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Search Knowledge Base</h3></div>
      <div class="flex">
        <input type="text" id="ragSearch" placeholder="Search..." style="flex:1" onkeydown="if(event.key==='Enter')MayaApp._searchRag()">
        <button onclick="MayaApp._searchRag()">🔍 Search</button>
      </div>
      <div id="ragResults" class="mt-sm"></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Documents (${(r.documents || []).length})</h3></div>
      ${(r.documents || []).length ? `<div class="table-wrap"><table>
      <tr><th>Source</th><th>Versions</th><th>Actions</th></tr>
      ${r.documents.map(d => `<tr>
        <td class="text-sm">${esc(d.source || d.id || '')}</td>
        <td>${d.version || 1}</td>
        <td><button class="danger" onclick="MayaAPI.rag.deleteDoc('${d.id}').then(()=>MayaStore.loadRAG())">Delete</button></td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No documents ingested</div>'}
    </div>`;
  });

  App._searchRag = async function () {
    const q = document.getElementById('ragSearch').value.trim();
    if (!q) return;
    const res = await MayaAPI.rag.search(q);
    document.getElementById('ragResults').innerHTML = res.ok
      ? `<pre>${esc(JSON.stringify(res.data, null, 2))}</pre>`
      : `<div class="tag tag-error">${esc(res.error)}</div>`;
  };

  // Vision
  ROUTES.vision.screen = function () {
    document.getElementById('main').innerHTML = `
    <h2 style="margin-bottom:16px">👁️ Vision Analysis</h2>
    <div class="card">
      <div class="card-header"><h3>Capture & Analyze</h3></div>
      <div class="flex mb-md" id="visionControls">
        <button onclick="MayaApp._startCamera('vision')" class="primary">📷 Open Camera</button>
        <button onclick="MayaApp._uploadVision()">📁 Upload Image</button>
      </div>
      <video id="visionVideo" style="display:none;max-width:100%;border-radius:var(--radius);margin-bottom:8px" autoplay playsinline></video>
      <canvas id="visionCanvas" style="display:none"></canvas>
      <img id="visionPreview" style="display:none;max-width:100%;border-radius:var(--radius);margin-bottom:8px">
      <div class="form-group">
        <label>Prompt</label>
        <input type="text" id="visionPrompt" value="Describe this image in detail.">
      </div>
      <button onclick="MayaApp._analyzeVision()" class="primary">🔍 Analyze</button>
      <div id="visionResult" class="mt-sm"></div>
    </div>`;
  };

  App._visionStream = null;
  App._visionB64 = null;
  App._startCamera = async function (prefix) {
    const res = await MayaHardware.camera.start({ facing: 'environment' });
    if (!res.ok) { toast(res.error, 'error'); return; }
    App._visionStream = res.stream;
    const video = document.getElementById(prefix + 'Video');
    video.srcObject = res.stream; video.style.display = '';
    video.play();
    document.getElementById(prefix + 'Controls')?.querySelectorAll('button')[0]?.replaceWith(
      `<button onclick="MayaApp._captureVision('${prefix}')" class="danger">📸 Capture</button>`);
  };

  App._captureVision = async function (prefix) {
    const video = document.getElementById(prefix + 'Video');
    const canvas = document.getElementById(prefix + 'Canvas');
    canvas.width = video.videoWidth; canvas.height = video.videoHeight;
    canvas.getContext('2d').drawImage(video, 0, 0);
    App._visionB64 = canvas.toDataURL('image/jpeg', 0.85);
    document.getElementById(prefix + 'Preview').src = App._visionB64;
    document.getElementById(prefix + 'Preview').style.display = '';
    video.style.display = 'none';
    MayaHardware.camera.stop();
    toast('Photo captured', 'success');
  };

  App._uploadVision = function () {
    const input = document.createElement('input');
    input.type = 'file'; input.accept = 'image/*';
    input.onchange = function (e) {
      const file = e.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onloadend = function () {
        App._visionB64 = reader.result;
        document.getElementById('visionPreview').src = reader.result;
        document.getElementById('visionPreview').style.display = '';
      };
      reader.readAsDataURL(file);
      toast('Image loaded', 'success');
    };
    input.click();
  };

  App._analyzeVision = async function () {
    if (!App._visionB64) { toast('Capture or upload an image first', 'warning'); return; }
    const prompt = document.getElementById('visionPrompt').value;
    const result = document.getElementById('visionResult');
    result.innerHTML = '<span class="spinner"></span> Analyzing...';
    const b64 = App._visionB64.split(',')[1];
    const res = await MayaAPI.vision.analyze(b64, prompt);
    result.innerHTML = res.ok ? `<pre>${esc(res.data?.result || JSON.stringify(res.data))}</pre>`
      : `<div class="tag tag-error">${esc(res.error)}</div>`;
  };

  // Voice
  ROUTES.voice.screen = function () {
    document.getElementById('main').innerHTML = `
    <h2 style="margin-bottom:16px">🎤 Voice</h2>
    <div class="card">
      <div class="card-header"><h3>Record & Transcribe</h3></div>
      <div class="flex mb-md" id="voiceControls">
        <button onclick="MayaApp._startVoice()" class="primary">🎤 Start Recording</button>
        <button onclick="MayaApp._stopVoice()" class="danger" style="display:none">⏹ Stop</button>
      </div>
      <div id="voiceStatus" class="text-sm mb-sm">Click "Start Recording" to begin</div>
      <div id="voiceResult"></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Text to Speech</h3></div>
      <div class="form-group"><textarea id="ttsText" rows="3" placeholder="Text to speak..."></textarea></div>
      <div class="flex">
        <button onclick="MayaApp._speak()" class="primary">🔊 Speak</button>
        <select id="ttsVoice"><option value="alloy">Alloy</option><option value="echo">Echo</option><option value="shimmer">Shimmer</option></select>
      </div>
      <div id="ttsResult" class="mt-sm"></div>
    </div>`;
  };

  App._startVoice = async function () {
    const res = await MayaHardware.voice.startRecording();
    if (!res.ok) { toast(res.error, 'error'); return; }
    document.getElementById('voiceStatus').textContent = '🔴 Recording...';
    document.querySelector('#voiceControls button:first-child').style.display = 'none';
    document.querySelector('#voiceControls button:last-child').style.display = '';
  };

  App._stopVoice = async function () {
    const res = await MayaHardware.voice.stopRecording();
    if (!res.ok) { toast(res.error, 'error'); return; }
    document.getElementById('voiceStatus').textContent = '⏳ Transcribing...';
    document.querySelector('#voiceControls button:first-child').style.display = '';
    document.querySelector('#voiceControls button:last-child').style.display = 'none';

    const reader = new FileReader();
    reader.onloadend = async function () {
      const b64 = reader.result.split(',')[1];
      const trans = await MayaAPI.voice.transcribe(b64, res.blob.type);
      document.getElementById('voiceResult').innerHTML = trans.ok
        ? `<pre>${esc(trans.data?.text || trans.data?.transcript || JSON.stringify(trans.data))}</pre>`
        : `<div class="tag tag-error">${esc(trans.error)}</div>`;
      document.getElementById('voiceStatus').textContent = trans.ok ? '✅ Done' : '❌ Failed';
    };
    reader.readAsDataURL(res.blob);
  };

  App._speak = async function () {
    const text = document.getElementById('ttsText').value.trim();
    if (!text) { toast('Enter text to speak', 'warning'); return; }
    const voice = document.getElementById('ttsVoice').value;
    const result = document.getElementById('ttsResult');
    result.innerHTML = '<span class="spinner"></span> Generating...';
    const res = await MayaAPI.voice.speak(text, voice);
    result.innerHTML = res.ok
      ? `<pre>${esc(JSON.stringify(res.data, null, 2))}</pre>`
      : `<div class="tag tag-error">${esc(res.error)}</div>`;
  };

  // Translate
  ROUTES.translate.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">🌐 Translate</h2>${loadingSpinner()}`;
    await MayaStore.loadLanguages();
    const langs = MayaStore.get('languages') || [];
    main.innerHTML = safeRender(() => `
    <div class="card">
      <div class="form-row">
        <div class="form-group"><label>Source Language</label>
          <select id="transSource"><option value="">Auto-detect</option>
          ${(Array.isArray(langs) ? langs : []).map(l => `<option value="${l.code || l}">${l.name || l}</option>`).join('')}
          </select></div>
        <div class="form-group"><label>Target Language</label>
          <select id="transTarget">
          ${(Array.isArray(langs) ? langs : []).map(l => `<option value="${l.code || l}">${l.name || l}</option>`).join('')}
          </select></div>
      </div>
      <div class="form-group"><label>Text</label><textarea id="transText" rows="4" placeholder="Text to translate..."></textarea></div>
      <button onclick="MayaApp._translate()" class="primary">🌐 Translate</button>
      <div id="transResult" class="mt-sm"></div>
    </div>`, `<div class="empty">⚠️ Translation not available</div>`);
  };

  App._translate = async function () {
    const text = document.getElementById('transText').value.trim();
    if (!text) { toast('Enter text', 'warning'); return; }
    const target = document.getElementById('transTarget').value;
    const source = document.getElementById('transSource').value || undefined;
    const res = await MayaAPI.translate.translate(text, target, source);
    document.getElementById('transResult').innerHTML = res.ok
      ? `<pre>${esc(res.data?.translation || res.data?.text || JSON.stringify(res.data))}</pre>`
      : `<div class="tag tag-error">${esc(res.error)}</div>`;
  };

  // Projects (Standing Goals)
  ROUTES.projects.screen = makeListScreen('Projects', '🎯', () => MayaStore.loadProjects(), () => {
    const projects = MayaStore.get('projects') || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._createProject()">+ New Project</button>
    </div>
    <div class="card">
      ${projects.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Goal</th><th>Status</th><th>Actions</th></tr>
      ${projects.map(p => `<tr>
        <td>${esc(p.name || '')}</td>
        <td class="text-sm truncate">${esc((p.goal || p.kwargs?.goal || '').slice(0, 60))}</td>
        <td><span class="tag ${p.enabled ? 'tag-success' : 'tag-disabled'}">${p.enabled ? 'Running' : 'Paused'}</span></td>
        <td class="flex">
          <button onclick="MayaAPI.projects.progress('${p.id}').then(r=>MayaApp.openModal('<pre>'+MayaApp.esc(JSON.stringify(r.data,null,2))+'</pre>'))">Progress</button>
          <button class="danger" onclick="MayaAPI.projects.delete('${p.id}').then(()=>{MayaStore.loadProjects();MayaApp.navigate('projects')})">Stop</button>
        </td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No standing goals. Create a project for Maya to work toward autonomously.</div>'}
    </div>`;
  });
  App._createProject = function () {
    openModal(`<h2>🎯 New Standing Goal</h2>
    <p class="mb-md text-sm">Maya will work toward this goal autonomously on a schedule.</p>
    <div class="form-group"><label>Name</label><input id="projName" placeholder="Weekly brief"></div>
    <div class="form-group"><label>Goal</label><textarea id="projGoal" rows="3" placeholder="e.g. Summarize the top AI news every week..."></textarea></div>
    <div class="form-group"><label>Cron (optional, default hourly)</label><input id="projCron" value="@hourly" class="text-mono" placeholder="0 9 * * 1"></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doCreateProject()">Start</button>
    </div>
    <div id="projResult" class="mt-sm text-sm"></div>`);
  };
  App._doCreateProject = async function () {
    const name = document.getElementById('projName').value.trim();
    const goal = document.getElementById('projGoal').value.trim();
    if (!name || !goal) { toast('Name and goal required', 'warning'); return; }
    document.getElementById('projResult').innerHTML = '<span class="spinner"></span>';
    await MayaAPI.projects.create(name, goal, document.getElementById('projCron').value || '@hourly');
    document.getElementById('projResult').innerHTML = '<span class="tag tag-success">Project created</span>';
    setTimeout(() => { closeModal(); MayaStore.loadProjects(); ROUTES.projects.screen(); }, 1000);
  };

  // Logs
  ROUTES.logs.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">📜 Logs</h2>${loadingSpinner('Loading logs...')}`;
    await Promise.all([MayaStore.loadLogs(), MayaStore.loadMetrics()]);
    const logs = MayaStore.get('logs') || {};
    const metrics = MayaStore.get('metrics');
    main.innerHTML = safeRender(() => `
    <div class="card">
      <div class="card-header"><h3>LLM Calls (${(logs.llm || []).length})</h3></div>
      ${(logs.llm || []).length ? `<pre>${esc(JSON.stringify(logs.llm.slice(-10), null, 2))}</pre>` : '<div class="empty">No LLM logs yet</div>'}
    </div>
    <div class="card">
      <div class="card-header"><h3>Tool Calls (${(logs.tools || []).length})</h3></div>
      ${(logs.tools || []).length ? `<pre>${esc(JSON.stringify(logs.tools.slice(-10), null, 2))}</pre>` : '<div class="empty">No tool logs yet</div>'}
    </div>
    ${metrics ? `<div class="card"><div class="card-header"><h3>Server Metrics</h3></div><pre>${esc(JSON.stringify(metrics, null, 2))}</pre></div>` : ''}
    <div class="flex"><button onclick="MayaApp.navigate('logs')">🔄 Refresh</button></div>`, `<div class="empty">⚠️ Error loading logs</div>`);
  };

  // Schedules
  ROUTES.schedules.screen = makeListScreen('Schedules', '⏰', () => MayaStore.loadSchedules(), () => {
    const scheds = MayaStore.get('schedules') || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._createSchedule()">+ New Schedule</button>
    </div>
    <div class="card">
      ${scheds.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Cron</th><th>Job</th><th>Enabled</th><th>Last Run</th></tr>
      ${scheds.map(s => `<tr>
        <td>${esc(s.name)}</td>
        <td class="text-mono">${s.cron}</td>
        <td class="text-mono">${s.job}</td>
        <td><span class="tag ${s.enabled ? 'tag-success' : 'tag-disabled'}">${s.enabled ? 'Yes' : 'No'}</span></td>
        <td class="text-sm">${s.last_run ? new Date(s.last_run).toLocaleString() : '—'}</td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No schedules</div>'}
    </div>`;
  });

  App._createSchedule = function () {
    openModal(`<h2>New Schedule</h2>
    <div class="form-group"><label>Name</label><input id="schedName" placeholder="daily-brief"></div>
    <div class="form-group"><label>Cron Expression</label><input id="schedCron" value="0 9 * * *" class="text-mono"></div>
    <div class="form-group"><label>Job</label><input id="schedJob" value="agent_goal" class="text-mono"></div>
    <div class="form-group"><label>Arguments (JSON array)</label><input id="schedArgs" value='["Run daily brief"]' class="text-mono"></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doCreateSchedule()">Create</button>
    </div>`);
  };
  App._doCreateSchedule = async function () {
    const name = document.getElementById('schedName').value.trim();
    if (!name) { toast('Name required', 'warning'); return; }
    let args = [];
    try { args = JSON.parse(document.getElementById('schedArgs').value || '[]'); } catch { args = []; }
    await MayaAPI.schedules.create(name, document.getElementById('schedCron').value,
      document.getElementById('schedJob').value, args);
    closeModal(); toast('Schedule created', 'success');
    MayaStore.loadSchedules();
    ROUTES.schedules.screen();
  };

  // Devices
  ROUTES.devices.screen = makeListScreen('Device Bridge', '🖥️', () => MayaStore.loadDevices(), () => {
    const devs = MayaStore.get('devices') || [];
    return `
    <div class="card">
      <div class="card-header"><h3>Paired Devices</h3>
        <button onclick="MayaApp._pairDevice()" class="primary">+ Pair Device</button>
      </div>
      ${devs.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>ID</th><th>Paired</th><th>Actions</th></tr>
      ${devs.map(d => `<tr>
        <td>${esc(d.name || '')}</td>
        <td class="text-mono text-sm">${d.id || d.device_id || ''}</td>
        <td class="text-sm">${d.paired_at ? new Date(d.paired_at).toLocaleString() : ''}</td>
        <td><button class="danger" onclick="MayaAPI.device.delete('${d.id}').then(()=>MayaStore.loadDevices())">Revoke</button></td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No devices paired</div>'}
    </div>`;
  });

  App._pairDevice = async function () {
    openModal(`<h2>Pair Device</h2>
    <div class="form-group"><label>Device Name</label><input id="devName" placeholder="My Laptop"></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doPairDevice()">Generate Code</button>
    </div>
    <div id="pairResult" class="mt-sm"></div>`);
  };
  App._doPairDevice = async function () {
    const name = document.getElementById('devName').value.trim();
    const result = document.getElementById('pairResult');
    result.innerHTML = '<span class="spinner"></span>';
    const res = await MayaAPI.device.pairStart(name);
    result.innerHTML = res.ok
      ? `<div class="tag tag-success">Pairing code: <strong>${res.data?.pairing_code || ''}</strong></div>
         <div class="text-sm mt-sm">Enter this code in the Maya Bridge Agent on your device.</div>`
      : `<div class="tag tag-error">${esc(res.error)}</div>`;
  };

  // Instances
  ROUTES.instances.screen = makeListScreen('Instances', '📦', () => MayaStore.loadInstances(), () => {
    const insts = MayaStore.get('instances') || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._createInstance()">+ New Instance</button>
    </div>
    <div class="card">
      ${insts.length ? `<div class="table-wrap"><table>
      <tr><th>Name</th><th>Persona</th><th>Provider</th><th>Actions</th></tr>
      ${insts.map(i => `<tr>
        <td>${esc(i.name)}</td>
        <td class="text-sm">${esc((i.persona || '').slice(0, 80))}</td>
        <td>${i.provider || 'default'}</td>
        <td><button class="danger" onclick="MayaAPI.instances.delete('${i.id}').then(()=>MayaStore.loadInstances())">Delete</button></td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No instances</div>'}
    </div>`;
  });

  App._createInstance = function () {
    openModal(`<h2>New Instance</h2>
    <div class="form-group"><label>Name</label><input id="instName" placeholder="My Assistant"></div>
    <div class="form-group"><label>Persona</label><textarea id="instPersona" rows="2" placeholder="You are a helpful assistant..."></textarea></div>
    <div class="form-group"><label>Provider (optional)</label><input id="instProvider" placeholder="groq"></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doCreateInstance()">Create</button>
    </div>`);
  };
  App._doCreateInstance = async function () {
    const name = document.getElementById('instName').value.trim();
    if (!name) { toast('Name required', 'warning'); return; }
    await MayaAPI.instances.create(name, document.getElementById('instPersona').value, document.getElementById('instProvider').value);
    closeModal(); toast('Instance created', 'success');
    MayaStore.loadInstances();
    ROUTES.instances.screen();
  };

  // Backups
  ROUTES.backups.screen = makeListScreen('Backups', '💾', () => MayaStore.loadBackups(), () => {
    const backups = MayaStore.get('backups') || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._createBackup()">+ Create Backup</button>
    </div>
    <div class="card">
      ${backups.length ? `<div class="table-wrap"><table>
      <tr><th>ID</th><th>Created</th><th>Actions</th></tr>
      ${backups.map(b => `<tr>
        <td class="text-mono text-sm">${b.id || ''}</td>
        <td class="text-sm">${b.created_at ? new Date(b.created_at).toLocaleString() : b.created || ''}</td>
        <td class="flex">
          <button onclick="MayaAPI.backups.restore('${b.id}').then(()=>toast('Restored','success'))">♻️ Restore</button>
          <button class="danger" onclick="MayaAPI.backups.delete('${b.id}').then(()=>MayaStore.loadBackups())">Delete</button>
        </td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No backups</div>'}
    </div>`;
  });

  App._createBackup = async function () {
    await MayaAPI.backups.create('Manual backup via UI');
    toast('Backup created', 'success');
    MayaStore.loadBackups();
    ROUTES.backups.screen();
  };

  // Research
  ROUTES.research.screen = makeListScreen('Research', '🔬', () => MayaStore.loadResearch(), () => {
    const r = MayaStore.get('research') || {};
    const reports = r.reports || [];
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._doResearch()">+ New Research</button>
    </div>
    <div class="card">
      ${reports.length ? `<div class="table-wrap"><table>
      <tr><th>Report</th><th>Date</th><th>Actions</th></tr>
      ${reports.map(rp => `<tr>
        <td>${esc(rp.title || rp.name || rp.id || '')}</td>
        <td class="text-sm">${rp.created_at ? new Date(rp.created_at).toLocaleString() : ''}</td>
        <td><button onclick="MayaAPI.research.getReport('${rp.id}').then(r=>MayaApp.openModal('<pre>'+MayaApp.esc(JSON.stringify(r.data,null,2))+'</pre>'))">View</button></td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No research reports</div>'}
    </div>`;
  });

  App._doResearch = async function () {
    openModal(`<h2>New Research</h2>
    <div class="form-group"><label>URLs (one per line)</label><textarea id="researchUrls" rows="4" placeholder="https://example.com/article"></textarea></div>
    <div class="form-group"><label>Analysis Goal</label><input id="researchGoal" placeholder="Summarize the key findings"></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doRunResearch()">Analyze</button>
    </div>
    <div id="researchResult" class="mt-sm text-sm"></div>`);
  };
  App._doRunResearch = async function () {
    const urls = document.getElementById('researchUrls').value.split('\n').map(s => s.trim()).filter(Boolean);
    const goal = document.getElementById('researchGoal').value.trim();
    document.getElementById('researchResult').innerHTML = '<span class="spinner"></span> Analyzing...';
    const res = await MayaAPI.research.analyze(urls, goal);
    document.getElementById('researchResult').innerHTML = res.ok
      ? `<div class="tag tag-success">Report created</div>`
      : `<div class="tag tag-error">${esc(res.error)}</div>`;
    if (res.ok) { setTimeout(() => closeModal(), 1000); MayaStore.loadResearch(); }
  };

  // Publish
  ROUTES.publish.screen = makeListScreen('Publish', '🚀', () => MayaStore.loadPublish(), () => {
    const p = MayaStore.get('publish') || {};
    const history = p.history || (Array.isArray(p) ? p : []);
    return `
    <div class="flex-between mb-md">
      <button class="primary" onclick="MayaApp._doPublish()">+ New Publish</button>
    </div>
    <div class="card">
      ${history.length ? `<div class="table-wrap"><table>
      <tr><th>Site</th><th>Action</th><th>Date</th></tr>
      ${history.map(h => `<tr>
        <td>${esc(h.site_name)}</td>
        <td><span class="tag tag-${h.action === 'published' ? 'success' : h.action === 'failed' ? 'error' : 'env'}">${h.action}</span></td>
        <td class="text-sm">${h.created_at ? new Date(h.created_at).toLocaleString() : ''}</td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">No publish history</div>'}
    </div>`;
  });

  App._doPublish = async function () {
    openModal(`<h2>Publish Site</h2>
    <div class="form-group"><label>Site Name</label><input id="pubName" placeholder="my-site"></div>
    <div class="form-group"><label>Description</label><input id="pubDesc"></div>
    <div class="form-group"><label>Files (JSON: {"index.html": "..."})</label><textarea id="pubFiles" rows="5" class="text-mono"></textarea></div>
    <div class="modal-actions">
      <button onclick="MayaApp.closeModal()">Cancel</button>
      <button class="primary" onclick="MayaApp._doRunPublish()">Propose</button>
    </div>
    <div id="publishResult" class="mt-sm text-sm"></div>`);
  };
  App._doRunPublish = async function () {
    const name = document.getElementById('pubName').value.trim();
    if (!name) { toast('Name required', 'warning'); return; }
    let files = {};
    try { files = JSON.parse(document.getElementById('pubFiles').value || '{}'); } catch {
      toast('Invalid JSON', 'error'); return;
    }
    document.getElementById('publishResult').innerHTML = '<span class="spinner"></span> Proposing...';
    const res = await MayaAPI.publish.create(name, files, document.getElementById('pubDesc').value);
    document.getElementById('publishResult').innerHTML = res.ok
      ? `<div class="tag tag-success">Proposed! Check approvals to approve.</div>`
      : `<div class="tag tag-error">${esc(res.error)}</div>`;
  };

  // Controls
  ROUTES.controls.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">🎮 Control Center</h2>${loadingSpinner()}`;
    await Promise.all([MayaStore.loadControlState(), MayaStore.loadQueue()]);
    const ctrl = MayaStore.get('control') || {};
    const queue = MayaStore.get('queue') || {};
    main.innerHTML = safeRender(() => `
    <div class="card">
      <div class="card-header"><h3>Send Command</h3></div>
      <div class="form-row">
        <div class="form-group"><label>Action</label>
          <select id="ctrlAction"><option value="notify">Notify</option><option value="pause">Pause</option><option value="resume">Resume</option></select></div>
        <div class="form-group"><label>Parameters (JSON)</label><input id="ctrlParams" value='{"message":"Hello"}' class="text-mono"></div>
      </div>
      <button onclick="MayaApp._sendControl()" class="primary">Send</button>
      <div id="ctrlResult" class="mt-sm text-sm"></div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Control State</h3></div>
      <pre>${esc(JSON.stringify(ctrl.state || {}, null, 2))}</pre>
    </div>
    <div class="card">
      <div class="card-header"><h3>Queue Status</h3></div>
      <pre>${esc(JSON.stringify(queue, null, 2))}</pre>
    </div>`, `<div class="empty">⚠️ Controls error</div>`);
  };

  App._sendControl = async function () {
    const action = document.getElementById('ctrlAction').value;
    let params = {};
    try { params = JSON.parse(document.getElementById('ctrlParams').value || '{}'); } catch { params = {}; }
    const res = await MayaAPI.control.sendCommand(action, params);
    document.getElementById('ctrlResult').innerHTML = res.ok
      ? `<div class="tag tag-success">Command sent</div>`
      : `<div class="tag tag-error">${esc(res.error)}</div>`;
  };

  // Admin
  ROUTES.admin.screen = async function () {
    const main = document.getElementById('main');
    main.innerHTML = `<h2 style="margin-bottom:16px">⚙️ Admin Panel</h2>${loadingSpinner()}`;
    const [usersRes, flagsRes, auditRes] = await Promise.all([
      MayaAPI.admin.users(),
      MayaAPI.flags.list(),
      MayaAPI.admin.audit(),
    ]);
    const users = usersRes.ok ? usersRes.data : [];
    const flags = flagsRes.ok ? flagsRes.data : {};
    const audit = auditRes.ok ? auditRes.data : [];
    main.innerHTML = safeRender(() => `
    <div class="card">
      <div class="card-header"><h3>Users (${Array.isArray(users) ? users.length : 0})</h3></div>
      ${Array.isArray(users) && users.length ? `<div class="table-wrap"><table>
      <tr><th>Email</th><th>Role</th><th>Budget</th><th>Banned</th><th>Actions</th></tr>
      ${users.map(u => `<tr>
        <td>${esc(u.email)}</td>
        <td>${u.role}</td>
        <td>$${u.budget_usd || 0}</td>
        <td>${u.banned ? '🚫' : '✅'}</td>
        <td class="flex">
          <button onclick="MayaAPI.admin.banUser('${u.id}', ${!u.banned}).then(()=>MayaApp.navigate('admin'))">${u.banned ? 'Unban' : 'Ban'}</button>
        </td>
      </tr>`).join('\n')}
      </table></div>` : '<div class="empty">User management requires Supabase</div>'}
    </div>
    <div class="card">
      <div class="card-header"><h3>Feature Flags</h3></div>
      <pre>${esc(JSON.stringify(flags, null, 2))}</pre>
      <div class="flex mt-sm">
        <button onclick="MayaAPI.flags.update({RESEARCH_ENGINE_ENABLED:true}).then(()=>toast('Flags updated','success'))">Enable Research</button>
        <button onclick="MayaAPI.flags.update({COGNITION_ENABLED:true}).then(()=>toast('Flags updated','success'))">Enable Cognition</button>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><h3>Audit Log</h3></div>
      ${Array.isArray(audit) && audit.length ? `<pre>${esc(JSON.stringify(audit.slice(0, 20), null, 2))}</pre>`
        : '<div class="empty">No audit entries</div>'}
    </div>`, `<div class="empty">⚠️ Admin error</div>`);
  };

  /* ════════════════════════════════════════════
     BOOT
  ════════════════════════════════════════════ */
  init();
})();
