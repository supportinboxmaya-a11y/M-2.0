/**
 * Maya 2.0 ULTRA — API Client Layer
 *
 * Complete, typed mapping of every backend endpoint. Features:
 *   - Auto auth-token injection
 *   - 401 → redirect to login
 *   - 429/503 exponential-backoff retry (up to 3 attempts)
 *   - Unified error shape: { ok, data, error, status }
 */
(function () {
  const BASE = (window.__MAYA_API_BASE__ || '').replace(/\/+$/, '') || '/api/v1';
  const MAX_RETRIES = 3;
  let _token = localStorage.getItem('maya_token') || null;
  let _onUnauthorized = null;  // callback set by app init

  /* ── Token management ──────────────────── */
  window.MayaAPI = window.MayaAPI || {};
  const Api = window.MayaAPI;

  Api.setToken = function (t) {
    _token = t;
    if (t) localStorage.setItem('maya_token', t);
    else localStorage.removeItem('maya_token');
  };
  Api.getToken = () => _token;
  Api.onUnauthorized = function (fn) { _onUnauthorized = fn; };

  /* ── Core request (retry + error mapping) ─ */
  async function _req(method, path, body, opts = {}) {
    const url = BASE + path;
    const headers = { 'Content-Type': 'application/json' };
    if (_token) headers['Authorization'] = 'Bearer ' + _token;
    if (opts.headers) Object.assign(headers, opts.headers);

    let lastErr = null;
    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      try {
        const init = { method, headers };
        if (body && method !== 'GET') init.body = JSON.stringify(body);
        if (opts.signal) init.signal = opts.signal;

        const res = await fetch(url, init);
        const text = await res.text();
        let data;
        try { data = JSON.parse(text); } catch { data = text; }

        if (res.status === 401 && _onUnauthorized) {
          _onUnauthorized(data);
          return { ok: false, data: null, error: 'Unauthorized', status: 401 };
        }

        if (res.status === 429 || res.status >= 500) {
          if (attempt < MAX_RETRIES - 1) {
            const delay = Math.min(1000 * Math.pow(2, attempt), 8000);
            await new Promise(r => setTimeout(r, delay));
            continue;
          }
          return { ok: false, data, error: data?.detail || data?.error || res.statusText, status: res.status };
        }

        if (!res.ok) {
          return { ok: false, data, error: data?.detail || data?.error || res.statusText, status: res.status };
        }

        return { ok: true, data, error: null, status: res.status };
      } catch (e) {
        lastErr = e;
        if (e.name === 'AbortError') return { ok: false, data: null, error: 'aborted', status: 0 };
        if (attempt < MAX_RETRIES - 1) {
          await new Promise(r => setTimeout(r, 1000 * Math.pow(2, attempt)));
        }
      }
    }
    return { ok: false, data: null, error: lastErr?.message || 'Network error', status: 0 };
  }

  /* ── Convenience methods ──────────────── */
  function _get(p, o) { return _req('GET', p, null, o); }
  function _post(p, b, o) { return _req('POST', p, b, o); }
  function _put(p, b, o) { return _req('PUT', p, b, o); }
  function _del(p, o) { return _req('DELETE', p, null, o); }
  function _patch(p, b, o) { return _req('PATCH', p, b, o); }

  /* ════════════════════════════════════════════
     AUTH
  ════════════════════════════════════════════ */
  Api.auth = {
    login:     (email, password)     => _post('/auth/login', { email, password }),
    register:  (name, email, password) => _post('/auth/register', { name, email, password }),
    logout:    ()                    => _post('/auth/logout'),
    refresh:   ()                    => _post('/auth/refresh'),
    me:        ()                    => _get('/users/me'),
  };

  /* ════════════════════════════════════════════
     AGENT
  ════════════════════════════════════════════ */
  Api.agent = {
    status: ()       => _get('/agent/status'),
    run:    (goal, opts = {}) =>
      _post('/agent/run', { goal, budget_usd: opts.budget, instance_id: opts.instanceId }),
    chat:   (message, opts = {}) =>
      _post('/agent/chat', { message, chat_id: opts.chatId, instance_id: opts.instanceId }),
    think:  (problem, depth = 'normal') =>
      _post('/agent/think', { problem, depth }),
    chatStream: (message, opts = {}) => {
      // Returns EventSource-compatible response info
      const params = new URLSearchParams({ message, chat_id: opts.chatId || '', instance_id: opts.instanceId || '' });
      return BASE + '/agent/chat/stream?' + params.toString();
    },
  };

  /* ════════════════════════════════════════════
     TASKS
  ════════════════════════════════════════════ */
  Api.tasks = {
    list:    (limit, status) => _get('/tasks' + _q({ limit, status })),
    get:     (id)            => _get('/tasks/' + id),
    create:  (goal, budget)  => _post('/tasks', { goal, budget_usd: budget }),
    delete:  (id)            => _del('/tasks/' + id),
    reflect: (id, retry)     => _post('/tasks/' + id + '/reflect', { retry }),
  };

  /* ════════════════════════════════════════════
     LOGS
  ════════════════════════════════════════════ */
  Api.logs = {
    llm:   (limit) => _get('/logs/llm' + _q({ limit })),
    tools: (limit) => _get('/logs/tools' + _q({ limit })),
  };

  /* ════════════════════════════════════════════
     METRICS
  ════════════════════════════════════════════ */
  Api.metrics = {
    get: () => _get('/metrics'),
  };

  /* ════════════════════════════════════════════
     PROJECTS (Standing Goals)
  ════════════════════════════════════════════ */
  Api.projects = {
    list:     ()                   => _get('/projects'),
    create:   (name, goal, cron)   => _post('/projects', { name, goal, cron }),
    progress: (scheduleId)         => _get('/projects/' + scheduleId + '/progress'),
    delete:   (scheduleId)         => _del('/projects/' + scheduleId),
  };

  /* ════════════════════════════════════════════
     MEMORY
  ════════════════════════════════════════════ */
  Api.memory = {
    list:   (type, limit) => _get('/memory' + _q({ type, limit })),
    search: (q, limit)    => _get('/memory/search' + _q({ q, limit })),
    add:    (content, type = 'general') => _post('/memory', { content, type }),
    delete: (id)          => _del('/memory/' + id),
    stats:  ()            => _get('/memory/stats'),
    rank:   ()            => _get('/memory/rank'),
    cleanup:()            => _post('/memory/cleanup'),
    summary:()            => _get('/memory/summary'),
  };

  /* ════════════════════════════════════════════
     TOOLS
  ════════════════════════════════════════════ */
  Api.tools = {
    list:      ()              => _get('/tools'),
    run:       (name, input)   => _post('/tools/' + name + '/run', { input }),
    update:    (name, enabled) => _put('/tools/' + name, { enabled }),
    logs:      (limit)         => _get('/tools/logs' + _q({ limit })),
    framework: ()              => _get('/tools/framework'),
    execute:   (tool, input, perms) => _post('/tools/execute', { tool, input, caller_permissions: perms }),
  };

  /* ════════════════════════════════════════════
     PROVIDERS
  ════════════════════════════════════════════ */
  Api.providers = {
    list:          ()        => _get('/providers'),
    update:        (id, enabled) => _put('/providers/' + id, { enabled }),
    llmProviders:  ()        => _get('/llm/providers'),
    toggle:        (provider)=> _post('/llm/providers/' + provider + '/toggle'),
    setKey:        (provider, key) => _put('/llm/providers/' + provider + '/key', { api_key: key }),
    llmStats:      ()        => _get('/llm/stats'),
    llmStrategy:   ()        => _get('/llm/strategy'),
  };

  /* ════════════════════════════════════════════
     ANALYTICS
  ════════════════════════════════════════════ */
  Api.analytics = {
    summary:  ()        => _get('/analytics/summary'),
    daily:    (days)    => _get('/analytics/daily' + _q({ days })),
    providers:()        => _get('/analytics/providers'),
    tools:    ()        => _get('/analytics/tools'),
  };

  /* ════════════════════════════════════════════
     AUTONOMOUS
  ════════════════════════════════════════════ */
  Api.autonomous = {
    run: (goal, approveDangerous) => _post('/autonomous/run', { goal, approve_dangerous: approveDangerous }),
  };

  /* ════════════════════════════════════════════
     WORKFLOWS
  ════════════════════════════════════════════ */
  Api.workflows = {
    list:    ()                       => _get('/workflows'),
    create:  (name, desc, nodes, edges)=> _post('/workflows', { name, description: desc, nodes, edges }),
    update:  (id, name, desc)         => _put('/workflows/' + id, { name, description: desc }),
    delete:  (id)                     => _del('/workflows/' + id),
    run:     (id)                     => _post('/workflows/' + id + '/run'),
    plans:   (goal)                   => _post('/workflows/plan', { goal }),
    runs:    ()                       => _get('/workflows/runs'),
    getRun:  (id)                     => _get('/workflows/runs/' + id),
    cancelRun: (id)                   => _post('/workflows/runs/' + id + '/cancel'),
    executeRun: (id, execFn)          => _post('/workflows/runs/' + id + '/execute'),

    // Declarative workflow definitions
    defs:    ()                       => _get('/workflows/defs'),
    getDef:  (wid)                    => _get('/workflows/defs/' + wid),
    createDef: (def)                  => _post('/workflows/defs', def),
    updateDef: (wid, def)             => _put('/workflows/defs/' + wid, def),
    deleteDef: (wid)                  => _del('/workflows/defs/' + wid),
    runDef:  (wid)                    => _post('/workflows/defs/' + wid + '/run'),
  };

  /* ════════════════════════════════════════════
     PLUGINS
  ════════════════════════════════════════════ */
  Api.plugins = {
    list:       ()              => _get('/plugins'),
    update:     (id, enabled)   => _put('/plugins/' + id, { enabled }),
    install:    (id)            => _post('/plugins/' + id + '/install'),
    uninstall:  (id)            => _del('/plugins/' + id),
    installCode:(name, code)    => _post('/plugins/install-code', { name, code }),
    getTools:   (id)            => _get('/plugins/' + id + '/tools'),
  };

  /* ════════════════════════════════════════════
     VISION / VOICE
  ════════════════════════════════════════════ */
  Api.vision = {
    analyze: (image, prompt) => _post('/vision/analyze', { image, prompt }),
    ocr:     (image)         => _post('/vision/ocr', { image }),
  };

  Api.voice = {
    transcribe: (audioBase64, format) => _post('/voice/transcribe', { audio: audioBase64, format }),
    speak:      (text, voice)         => _post('/voice/speak', { text, voice }),
  };

  /* ════════════════════════════════════════════
     DEVICE BRIDGE
  ════════════════════════════════════════════ */
  Api.device = {
    pairStart:    (name)          => _post('/device/pair/start', { name }),
    pairComplete: (code)          => _post('/device/pair/complete', { code }),
    list:         ()              => _get('/device/list'),
    delete:       (id)            => _del('/device/' + id),
    history:      (id)            => _get('/device/' + id + '/history'),
    send:         (action, params)=> _post('/device/command', { action, params }),
    commands:     (id)            => _get('/device/' + id + '/commands'),
    commandResult:(cmdId, result) => _post('/device/commands/' + cmdId + '/result', { result }),
  };

  /* ════════════════════════════════════════════
     WORKSPACE
  ════════════════════════════════════════════ */
  Api.workspace = {
    files:   ()                 => _get('/workspace/files'),
    getFile: (filename)         => _get('/workspace/files/' + filename),
    list:    ()                 => _get('/workspaces'),
    memory:  (workspace)        => _get('/workspace/memory' + _q({ workspace })),
    addMemory: (workspace, content, type) =>
      _post('/workspace/memory', { workspace, content, memory_type: type }),
    deleteMemory: (mid, workspace) =>
      _del('/workspace/memory/' + mid + _q({ workspace })),
    stats:   (workspace)        => _get('/workspace/stats' + _q({ workspace })),
  };

  /* ════════════════════════════════════════════
     APPROVALS
  ════════════════════════════════════════════ */
  Api.approvals = {
    mode:     ()              => _get('/approval/mode'),
    setMode:  (mode)          => _put('/approval/mode', { mode }),
    request:  (action, reason, risk, taskId) =>
      _post('/approvals/request', { action, reason, risk_level: risk, task_id: taskId }),
    list:     ()              => _get('/approvals'),
    decide:   (aid, decision) => _post('/approvals/' + aid + '/' + decision),
  };

  /* ════════════════════════════════════════════
     WEBHOOKS
  ════════════════════════════════════════════ */
  Api.webhooks = {
    list:    ()                => _get('/webhooks'),
    create:  (name, job, template, signed) =>
      _post('/webhooks', { name, job, template, signed }),
    update:  (id, wh)          => _put('/webhooks/' + id, wh),
    delete:  (id)              => _del('/webhooks/' + id),

    // Inbound trigger hooks
    hooks:    ()               => _get('/hooks'),
    createHook: (name, job, template, signed) =>
      _post('/hooks', { name, job, template, signed }),
    deleteHook: (tid)          => _del('/hooks/' + tid),
    setHookEnabled: (tid, enabled) => _post('/hooks/' + tid + '/enabled', { enabled }),
  };

  /* ════════════════════════════════════════════
     NOTIFICATIONS
  ════════════════════════════════════════════ */
  Api.notifications = {
    list:     ()              => _get('/notifications'),
    unread:   ()              => _get('/notifications/unread'),
    markRead: (id)            => _post('/notifications/' + id + '/read'),
    markAllRead: ()           => _post('/notifications/read-all'),
    send:     (event, title, body, channels, recipient) =>
      _post('/notifications/send', { event, title, body, channels, recipient }),
    registerDevice: (token, platform, recipient) =>
      _post('/notifications/register-device', { token, platform, recipient }),
  };

  /* ════════════════════════════════════════════
     LEARNING
  ════════════════════════════════════════════ */
  Api.learning = {
    prompts:    ()             => _get('/learning/prompts'),
    feedback:   (taskId, rating, comment) =>
      _post('/learning/feedback', { task_id: taskId, rating, comment }),
    stats:      ()             => _get('/learning/stats'),
    experience: ()             => _get('/learning/experience'),
    compress:   ()             => _post('/learning/compress'),
  };

  /* ════════════════════════════════════════════
     PROMPT LIBRARY
  ════════════════════════════════════════════ */
  Api.prompts = {
    list:    ()                 => _get('/prompts'),
    get:     (pid)              => _get('/prompts/' + pid),
    create:  (name, body, category, tags) =>
      _post('/prompts', { name, body, category, tags }),
    update:  (pid, data)        => _put('/prompts/' + pid, data),
    delete:  (pid)              => _del('/prompts/' + pid),
    history: (pid)              => _get('/prompts/' + pid + '/history'),
    render:  (pid, values)      => _post('/prompts/' + pid + '/render', { values }),
  };

  /* ════════════════════════════════════════════
     RAG
  ════════════════════════════════════════════ */
  Api.rag = {
    stats:      ()                => _get('/rag/stats'),
    documents:  ()                => _get('/rag/documents'),
    deleteDoc:  (docId)           => _del('/rag/documents/' + docId),
    ingest:     (content, source) => _post('/rag/ingest', { content, source }),
    search:     (q, limit)        => _get('/rag/search' + _q({ q, limit })),
    context:    (q)               => _get('/rag/context' + _q({ q })),
  };

  /* ════════════════════════════════════════════
     ADMIN
  ════════════════════════════════════════════ */
  Api.admin = {
    users:       ()                  => _get('/admin/users'),
    banUser:     (uid, banned)       => _put('/admin/users/' + uid + '/ban', { banned }),
    setBudget:   (uid, budgetUsd)    => _put('/admin/users/' + uid + '/budget', { budget_usd: budgetUsd }),
    roles:       ()                  => _get('/admin/roles'),
    orgs:        ()                  => _get('/admin/orgs'),
    createOrg:   (name)              => _post('/admin/orgs', { name }),
    deleteOrg:   (orgId)             => _del('/admin/orgs/' + orgId),
    removeMember:(orgId, email)      => _del('/admin/orgs/' + orgId + '/members/' + email),
    createTeam:  (orgId, name)       => _post('/admin/orgs/' + orgId + '/teams', { name }),
    listTeams:   (orgId)             => _get('/admin/orgs/' + orgId + '/teams'),
    addMember:   (orgId, email, role)=> _post('/admin/orgs/' + orgId + '/members', { email, role }),
    listMembers: (orgId)             => _get('/admin/orgs/' + orgId + '/members'),
    apiKeys:     ()                  => _get('/admin/apikeys'),
    createApiKey:(name)              => _post('/admin/apikeys', { name }),
    deleteApiKey:(keyId)             => _del('/admin/apikeys/' + keyId),
    audit:       ()                  => _get('/admin/audit'),
    usage:       ()                  => _get('/admin/usage'),
    dashboard:   ()                  => _get('/admin/dashboard'),
  };

  /* ════════════════════════════════════════════
     BRAIN / AGENTS
  ════════════════════════════════════════════ */
  Api.brain = {
    analyze: (goal)          => _get('/brain/analyze' + _q({ goal })),
    graph:   (steps)         => _post('/brain/graph', { steps }),
  };
  Api.agents = {
    list:        ()           => _get('/agents'),
    orchestrate: (goal)       => _post('/agents/orchestrate', { goal }),
    messages:    ()           => _get('/agents/messages'),
  };

  /* ════════════════════════════════════════════
     HOSTING / DEPLOY
  ════════════════════════════════════════════ */
  Api.hosting = {
    apps:       ()                => _get('/hosting/apps'),
    deploy:     (source, name)    => _post('/hosting/deploy', { source, name }),
    getApp:     (name)            => _get('/hosting/apps/' + name),
    startApp:   (name)            => _post('/hosting/apps/' + name + '/start'),
    stopApp:    (name)            => _post('/hosting/apps/' + name + '/stop'),
    restartApp: (name)            => _post('/hosting/apps/' + name + '/restart'),
    tunnelApp:  (name)            => _post('/hosting/apps/' + name + '/tunnel'),
    appLogs:    (name)            => _get('/hosting/apps/' + name + '/logs'),
    deleteApp:  (name)            => _del('/hosting/apps/' + name),
    registry:   ()                => _get('/hosting/registry'),
    registerApp:(name, image, port)=> _post('/hosting/registry', { name, image, internal_port: port }),
    getRegistry:(name)            => _get('/hosting/registry/' + name),
    deleteRegistry:(name)         => _del('/hosting/registry/' + name),
    setMonitor: (name, enabled)   => _patch('/hosting/registry/' + name + '/monitor', { enabled }),
    checkHealth:(name)            => _post('/hosting/registry/' + name + '/health'),
    checkAll:   ()                => _post('/hosting/registry/check-all'),
    restartRegistry:(name)        => _post('/hosting/registry/' + name + '/restart'),
    registryLogs:(name)           => _get('/hosting/registry/' + name + '/logs'),
    remoteDeploy: (source, name, env) =>
      _post('/hosting/remote/deploy', { source, name, env }),
    remoteAction: (app, action)   => _post('/hosting/remote/' + app + '/' + action),

    deployPipeline: {
      plan:    (source, name) => _post('/deploy/pipeline/plan', { source, name }),
      execute: (source, name, confirm) => _post('/deploy/pipeline/execute', { source, name, confirm }),
      status:  ()             => _get('/deploy/pipeline/status'),
    },
  };

  /* ════════════════════════════════════════════
     COGNITION
  ════════════════════════════════════════════ */
  Api.cognition = {
    missions:       ()                     => _get('/cognitive/missions'),
    createMission:  (name, directive, selfGen) =>
      _post('/cognitive/missions', { name, directive, self_gen: selfGen }),
    updateMission:  (mid, data)            => _patch('/cognitive/missions/' + mid, data),
    deleteMission:  (mid)                  => _del('/cognitive/missions/' + mid),
    generateObjectives: (mid)              => _post('/cognitive/missions/' + mid + '/generate'),
    objectives:     ()                     => _get('/cognitive/objectives'),
    createObjective:(mid, title, desc, priority) =>
      _post('/cognitive/objectives', { mission_id: mid, title, description: desc, priority }),
    cycle:          ()                     => _post('/cognitive/cycle'),
    executeObjective:(oid)                 => _post('/cognitive/execute-objective', { objective_id: oid }),
    pause:          ()                     => _post('/cognitive/pause'),
    resume:         ()                     => _post('/cognitive/resume'),
    status:         ()                     => _get('/cognitive/status'),
    analyze:        (mid)                  => _post('/cognitive/missions/' + mid + '/analyze'),
    reports:        (mid)                  => _get('/cognitive/missions/' + mid + '/reports'),
    getReport:      (mid, rid)             => _get('/cognitive/missions/' + mid + '/reports/' + rid),
  };

  /* ════════════════════════════════════════════
     PUBLISH
  ════════════════════════════════════════════ */
  Api.publish = {
    create:  (siteName, files, desc) => _post('/publish', { site_name: siteName, files, description: desc }),
    history: ()                      => _get('/publish/history'),
    get:     (proposalId)            => _get('/publish/history/' + proposalId),
  };

  /* ════════════════════════════════════════════
     RESEARCH
  ════════════════════════════════════════════ */
  Api.research = {
    analyze: (urls, goal)     => _post('/research/analyze', { urls, goal }),
    reports: ()               => _get('/research/reports'),
    getReport: (reportId)     => _get('/research/reports/' + reportId),
  };

  /* ════════════════════════════════════════════
     SECURITY / FLAGS / SKILLS
  ════════════════════════════════════════════ */
  Api.security = {
    status: ()  => _get('/security/status'),
  };
  Api.flags = {
    list:   ()  => _get('/flags'),
    update: (flags) => _put('/flags', { flags }),
  };
  Api.skills = {
    list:   ()  => _get('/skills'),
  };
  Api.docs = {
    list:   ()  => _get('/docs'),
    get:    (name) => _get('/docs/' + name),
  };

  /* ════════════════════════════════════════════
     INSTANCES
  ════════════════════════════════════════════ */
  Api.instances = {
    create: (name, persona, provider) =>
      _post('/instances', { name, persona, provider }),
    list:   ()        => _get('/instances'),
    get:    (iid)     => _get('/instances/' + iid),
    delete: (iid)     => _del('/instances/' + iid),
  };

  /* ════════════════════════════════════════════
     CONTROL
  ════════════════════════════════════════════ */
  Api.control = {
    sendCommand: (action, params) => _post('/control/command', { action, params }),
    state:       ()               => _get('/control/state'),
  };

  /* ════════════════════════════════════════════
     SYNC / TRANSLATE
  ════════════════════════════════════════════ */
  Api.sync = {
    types:  ()                 => _get('/sync/types'),
    push:   (ops)              => _post('/sync/push', { operations: ops }),
    status: (opId)             => _get('/sync/status/' + opId),
    recent: ()                 => _get('/sync/recent'),
  };
  Api.translate = {
    languages: ()                 => _get('/translate/languages'),
    translate: (text, target, source, speak) =>
      _post('/translate', { text, target_language: target, source_language: source, speak }),
    detect:    (text)             => _post('/translate/detect', { text }),
  };

  /* ════════════════════════════════════════════
     HEALTH
  ════════════════════════════════════════════ */
  Api.health = {
    live:  ()  => _get('/health/live'),
    ready: ()  => _get('/health/ready'),
    all:   ()  => _get('/health'),
    system:()  => _get('/health/system'),
  };

  /* ════════════════════════════════════════════
     QUEUE / SCHEDULES
  ════════════════════════════════════════════ */
  Api.queue = {
    status:   ()              => _get('/queue/status'),
    stats:    ()              => _get('/queue/stats'),
    task:     (taskId)        => _get('/queue/task/' + taskId),
    submit:   (job, args)     => _post('/queue/submit', { job, args }),
    cancel:   (taskId)        => _post('/queue/cancel/' + taskId),
  };
  Api.schedules = {
    list:      ()               => _get('/schedules'),
    create:    (name, cron, job, args) =>
      _post('/schedules', { name, cron, job, args }),
    delete:    (sid)            => _del('/schedules/' + sid),
    setEnabled:(sid, enabled)   => _post('/schedules/' + sid + '/enabled', { enabled }),
  };

  /* ════════════════════════════════════════════
     BACKUPS
  ════════════════════════════════════════════ */
  Api.backups = {
    list:   ()              => _get('/backup/list'),
    create: (note)          => _post('/backup/create', { note }),
    restore:(backupId)      => _post('/backup/restore/' + backupId),
    delete: (backupId)      => _del('/backup/' + backupId),
  };

  /* ── Helper: query string builder ─────── */
  function _q(params) {
    const p = {};
    for (const k in params) {
      if (params[k] !== undefined && params[k] !== null && params[k] !== '') {
        p[k] = params[k];
      }
    }
    const s = new URLSearchParams(p).toString();
    return s ? '?' + s : '';
  }

  /* ── WebSocket subscription ───────────── */
  Api.subscribe = function (onMessage) {
    const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = location.host;
    const ws = new WebSocket(proto + '//' + host + '/ws');
    ws.onmessage = (e) => {
      try { onMessage(JSON.parse(e.data)); } catch { /* ignore */ }
    };
    ws.onclose = () => setTimeout(() => Api.subscribe(onMessage), 3000);
    return () => ws.close();
  };

  /* ── Upload helper (multipart) ────────── */
  Api.uploadFile = async function (url, file, fieldName = 'file') {
    const formData = new FormData();
    formData.append(fieldName, file);
    const headers = {};
    if (_token) headers['Authorization'] = 'Bearer ' + _token;
    try {
      const res = await fetch(BASE + url, { method: 'POST', headers, body: formData });
      const data = await res.json();
      return { ok: res.ok, data, error: data?.error || null, status: res.status };
    } catch (e) {
      return { ok: false, data: null, error: e.message, status: 0 };
    }
  };
})();
