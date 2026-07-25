/**
 * Maya 2.0 ULTRA — State Management
 *
 * Simple reactive store with subscriptions. Every UI toggle automatically
 * dispatches its backend sync action and handles loading/error states.
 */
(function () {
  const Store = {};
  window.MayaStore = Store;

  // ── Internal state ──
  const _state = {
    user:           null,
    token:          null,
    agentStatus:    null,
    tasks:          [],
    taskDetail:     null,
    tools:          [],
    toolsLog:       [],
    providers:      [],
    memories:       [],
    memoryStats:    null,
    analytics:      { summary: null, daily: [], providers: {}, tools: {} },
    workflows:      [],
    workflowDefs:   [],
    plugins:        [],
    webhooks:       [],
    hooks:          [],
    notifications:  { items: [], unread: 0 },
    approvals:      { mode: 'auto', items: [] },
    llmStats:       null,
    llmProviders:   [],
    llmStrategy:    null,
    learning:       { prompts: [], stats: null, experience: [] },
    prompts:        [],
    rag:            { stats: null, documents: [] },
    flags:          {},
    skills:         [],
    docs:           [],
    projects:       [],
    metrics:        null,
    hosting:        { apps: [], registry: [] },
    cognition:      { missions: [], objectives: [], status: null },
    instances:      [],
    schedules:      [],
    queue:          null,
    backups:        [],
    research:       { reports: [] },
    logs:           { llm: [], tools: [] },
    devices:        [],
    workspaces:     [],
    control:        { state: null },
    sync:           { types: [] },
    languages:      [],
    publish:        { history: [] },
    // Loading / error
    _loading:       {},
    _errors:        {},
  };

  const _subscribers = {};

  // ── Accessors ──
  Store.getState = () => ({ ..._state });
  Store.get = (key) => _state[key];

  // ── Subscribe to changes ──
  Store.subscribe = function (key, fn) {
    if (!_subscribers[key]) _subscribers[key] = [];
    _subscribers[key].push(fn);
    return () => { _subscribers[key] = _subscribers[key].filter(f => f !== fn); };
  };

  function _emit(key, value) {
    (_subscribers[key] || []).forEach(fn => fn(value));
  }

  // ── Update helpers ──
  function _set(key, value) {
    _state[key] = value;
    _emit(key, value);
  }

  function _loading(key, v) { _state._loading[key] = v; }
  function _error(key, e) { _state._errors[key] = e; }

  // ── Action wrapper: sets loading, calls API, handles error ──
  async function _action(key, apiCall) {
    _loading(key, true);
    _error(key, null);
    _emit('_loading', { ..._state._loading });
    try {
      const res = await apiCall();
      if (!res.ok) {
        _error(key, res.error);
        _emit('_errors', { ..._state._errors });
      }
      return res;
    } catch (e) {
      _error(key, e.message);
      _emit('_errors', { ..._state._errors });
      return { ok: false, data: null, error: e.message, status: 0 };
    } finally {
      _loading(key, false);
      _emit('_loading', { ..._state._loading });
    }
  }

  // ════════════════════════════════════════════
  //  AUTH ACTIONS
  // ════════════════════════════════════════════
  Store.auth = {
    login: async (email, password) => {
      const res = await _action('auth', () => MayaAPI.auth.login(email, password));
      if (res.ok) {
        MayaAPI.setToken(res.data.access_token);
        _set('token', res.data.access_token);
        _set('user', { email: res.data.email, role: res.data.role });
      }
      return res;
    },
    register: async (name, email, password) => {
      const res = await _action('auth', () => MayaAPI.auth.register(name, email, password));
      if (res.ok) {
        MayaAPI.setToken(res.data.access_token);
        _set('token', res.data.access_token);
        _set('user', { email: res.data.email, role: res.data.role });
      }
      return res;
    },
    logout: async () => {
      await MayaAPI.auth.logout();
      MayaAPI.setToken(null);
      _set('token', null);
      _set('user', null);
    },
    refresh: async () => {
      const res = await MayaAPI.auth.refresh();
      if (res.ok) { MayaAPI.setToken(res.data.access_token); _set('token', res.data.access_token); }
      return res;
    },
    me: async () => {
      const res = await _action('auth', () => MayaAPI.auth.me());
      if (res.ok) _set('user', res.data);
      return res;
    },
  };

  // ════════════════════════════════════════════
  //  AGENT ACTIONS
  // ════════════════════════════════════════════
  Store.agent = {
    status: async () => {
      const res = await _action('agentStatus', () => MayaAPI.agent.status());
      if (res.ok) _set('agentStatus', res.data);
      return res;
    },
    run: (goal, opts) => MayaAPI.agent.run(goal, opts),
    chat: (msg, opts) => MayaAPI.agent.chat(msg, opts),
    think: (problem, depth) => MayaAPI.agent.think(problem, depth),
  };

  // ════════════════════════════════════════════
  //  TASK ACTIONS
  // ════════════════════════════════════════════
  Store.tasks = {
    load: async (limit, status) => {
      const res = await _action('tasks', () => MayaAPI.tasks.list(limit, status));
      if (res.ok) _set('tasks', res.data);
      return res;
    },
    get: async (id) => {
      const res = await _action('taskDetail', () => MayaAPI.tasks.get(id));
      if (res.ok) _set('taskDetail', res.data);
      return res;
    },
    create: (goal, budget) => MayaAPI.tasks.create(goal, budget),
    delete: async (id) => {
      const res = await MayaAPI.tasks.delete(id);
      if (res.ok) Store.tasks.load();
      return res;
    },
    reflect: async (id, retry) => {
      const res = await MayaAPI.tasks.reflect(id, retry);
      if (res.ok) Store.tasks.get(id);
      return res;
    },
  };

  // ════════════════════════════════════════════
  //  TOOLS
  // ════════════════════════════════════════════
  Store.tools = {
    load: async () => {
      const res = await _action('tools', () => MayaAPI.tools.list());
      if (res.ok) _set('tools', res.data);
      return res;
    },
    run: (name, input) => MayaAPI.tools.run(name, input),
    toggle: async (name, enabled) => {
      await MayaAPI.tools.update(name, enabled);
      Store.tools.load();
    },
    logs: async (limit) => {
      const res = await _action('logs', () => MayaAPI.tools.logs(limit));
      if (res.ok) _set('toolsLog', res.data);
      return res;
    },
    logsV2: async (limit) => {
      const res = await _action('logs', () => MayaAPI.tools.logs(limit));
      if (res.ok) _set('logs', { ..._state.logs, tools: res.data });
      return res;
    },
  };

  // ════════════════════════════════════════════
  //  PROVIDERS
  // ════════════════════════════════════════════
  Store.providers = {
    load: async () => {
      const res = await _action('providers', () => MayaAPI.providers.list());
      if (res.ok) _set('providers', res.data);
      return res;
    },
    toggle: async (id, enabled) => {
      await MayaAPI.providers.update(id, enabled);
      Store.providers.load();
    },
    llmLoad: async () => {
      const res = await _action('llmProviders', () => MayaAPI.providers.llmProviders());
      if (res.ok) _set('llmProviders', res.data);
      return res;
    },
    llmToggle: async (provider) => {
      await MayaAPI.providers.toggle(provider);
      Store.providers.llmLoad();
    },
    setKey: async (provider, key) => {
      const res = await MayaAPI.providers.setKey(provider, key);
      Store.providers.llmLoad();
      return res;
    },
    llmStats: async () => {
      const res = await _action('llmStats', () => MayaAPI.providers.llmStats());
      if (res.ok) _set('llmStats', res.data);
      return res;
    },
    llmStrategy: async () => {
      const res = await _action('llmStrategy', () => MayaAPI.providers.llmStrategy());
      if (res.ok) _set('llmStrategy', res.data);
      return res;
    },
  };

  // ════════════════════════════════════════════
  //  MEMORY
  // ════════════════════════════════════════════
  Store.memory = {
    load: async (type, limit) => {
      const res = await _action('memories', () => MayaAPI.memory.list(type, limit));
      if (res.ok) _set('memories', res.data);
      return res;
    },
    search: async (q, limit) => {
      const res = await _action('memories', () => MayaAPI.memory.search(q, limit));
      if (res.ok) _set('memories', res.data);
      return res;
    },
    add: async (content, type) => {
      const res = await MayaAPI.memory.add(content, type);
      if (res.ok) Store.memory.load();
      return res;
    },
    delete: async (id) => {
      await MayaAPI.memory.delete(id);
      Store.memory.load();
    },
    stats: async () => {
      const res = await _action('memoryStats', () => MayaAPI.memory.stats());
      if (res.ok) _set('memoryStats', res.data);
      return res;
    },
  };

  // ════════════════════════════════════════════
  //  ANALYTICS
  // ════════════════════════════════════════════
  Store.analytics = {
    loadAll: async () => {
      const [sum, daily, prov, tools] = await Promise.all([
        MayaAPI.analytics.summary(),
        MayaAPI.analytics.daily(7),
        MayaAPI.analytics.providers(),
        MayaAPI.analytics.tools(),
      ]);
      _set('analytics', { summary: sum.data, daily: daily.data, providers: prov.data, tools: tools.data });
    },
  };

  // ════════════════════════════════════════════
  //  SCREEN-SPECIFIC LOADERS
  // ════════════════════════════════════════════
  Store.loadDashboard = async () => {
    await Promise.all([
      Store.agent.status(),
      Store.tasks.load(10),
      Store.analytics.loadAll(),
      Store.tools.logs(20),
    ]);
  };

  Store.loadTools = async () => { await Promise.all([Store.tools.load(), Store.tools.logs(50)]); };
  Store.loadMemory = async () => { await Promise.all([Store.memory.load(), Store.memory.stats()]); };
  Store.loadLLM = async () => {
    await Promise.all([
      Store.providers.llmLoad(), Store.providers.llmStats(),
      Store.providers.llmStrategy(),
    ]);
  };
  Store.loadWorkflows = async () => {
    const [wf, defs] = await Promise.all([
      _action('workflows', () => MayaAPI.workflows.list()),
      _action('workflowDefs', () => MayaAPI.workflows.defs()),
    ]);
    if (wf.ok) _set('workflows', wf.data);
    if (defs.ok) _set('workflowDefs', defs.data);
  };
  Store.loadPlugins = async () => {
    const res = await _action('plugins', () => MayaAPI.plugins.list());
    if (res.ok) _set('plugins', res.data);
  };
  Store.loadWebhooks = async () => {
    const [wh, hk] = await Promise.all([
      _action('webhooks', () => MayaAPI.webhooks.list()),
      _action('hooks', () => MayaAPI.webhooks.hooks()),
    ]);
    if (wh.ok) _set('webhooks', wh.data);
    if (hk.ok) _set('hooks', hk.data);
  };
  Store.loadNotifications = async () => {
    const [items, unread] = await Promise.all([
      _action('notifications', () => MayaAPI.notifications.list()),
      MayaAPI.notifications.unread(),
    ]);
    if (items.ok) _set('notifications', { items: items.data, unread: unread.ok ? unread.data?.count || 0 : 0 });
  };
  Store.loadApprovals = async () => {
    const [mode, items] = await Promise.all([
      MayaAPI.approvals.mode(),
      _action('approvals', () => MayaAPI.approvals.list()),
    ]);
    _set('approvals', { mode: mode.ok ? mode.data?.mode || 'auto' : 'auto', items: items.ok ? items.data : [] });
  };
  Store.loadLearning = async () => {
    const [prompts, stats, exp] = await Promise.all([
      _action('learning_prompts', () => MayaAPI.learning.prompts()),
      MayaAPI.learning.stats(),
      MayaAPI.learning.experience(),
    ]);
    _set('learning', {
      prompts: prompts.ok ? prompts.data : [],
      stats: stats.ok ? stats.data : null,
      experience: exp.ok ? exp.data : [],
    });
  };
  Store.loadPrompts = async () => {
    const res = await _action('prompts', () => MayaAPI.prompts.list());
    if (res.ok) _set('prompts', res.data);
  };
  Store.loadRAG = async () => {
    const [stats, docs] = await Promise.all([
      MayaAPI.rag.stats(),
      _action('rag_docs', () => MayaAPI.rag.documents()),
    ]);
    _set('rag', { stats: stats.ok ? stats.data : null, documents: docs.ok ? docs.data : [] });
  };
  Store.loadFlags = async () => {
    const res = await _action('flags', () => MayaAPI.flags.list());
    if (res.ok) _set('flags', res.data);
  };
  Store.loadHosting = async () => {
    const [apps, reg] = await Promise.all([
      _action('hosting_apps', () => MayaAPI.hosting.apps()),
      _action('hosting_registry', () => MayaAPI.hosting.registry()),
    ]);
    _set('hosting', {
      apps: apps.ok ? apps.data : [],
      registry: reg.ok ? (Array.isArray(reg.data) ? reg.data : reg.data?.apps || []) : [],
    });
  };
  Store.loadCognition = async () => {
    const [miss, objs, st] = await Promise.all([
      _action('cognition_missions', () => MayaAPI.cognition.missions()),
      _action('cognition_objectives', () => MayaAPI.cognition.objectives()),
      MayaAPI.cognition.status(),
    ]);
    _set('cognition', {
      missions: miss.ok ? miss.data : [],
      objectives: objs.ok ? objs.data : [],
      status: st.ok ? st.data : null,
    });
  };
  Store.loadInstances = async () => {
    const res = await _action('instances', () => MayaAPI.instances.list());
    if (res.ok) _set('instances', res.data);
  };
  Store.loadSchedules = async () => {
    const res = await _action('schedules', () => MayaAPI.schedules.list());
    if (res.ok) _set('schedules', res.data);
  };
  Store.loadQueue = async () => {
    const res = await _action('queue', () => MayaAPI.queue.status());
    if (res.ok) _set('queue', res.data);
  };
  Store.loadBackups = async () => {
    const res = await _action('backups', () => MayaAPI.backups.list());
    if (res.ok) _set('backups', res.data);
  };
  Store.loadResearch = async () => {
    const res = await _action('research', () => MayaAPI.research.reports());
    if (res.ok) _set('research', { reports: res.data });
  };
  Store.loadPublish = async () => {
    const res = await _action('publish', () => MayaAPI.publish.history());
    if (res.ok) _set('publish', Array.isArray(res.data) ? { history: res.data } : res.data);
  };
  Store.loadDevices = async () => {
    const res = await _action('devices', () => MayaAPI.device.list());
    if (res.ok) _set('devices', res.data);
  };
  Store.loadWorkspaces = async () => {
    const res = await _action('workspaces', () => MayaAPI.workspace.list());
    if (res.ok) _set('workspaces', res.data);
  };
  Store.loadLogs = async () => {
    const [llm, tools] = await Promise.all([
      MayaAPI.tools.logs(50),
      MayaAPI.tools.logs(50),
    ]);
    _set('logs', { llm: llm.data || [], tools: tools.data || [] });
  };
  Store.loadControlState = async () => {
    const res = await _action('control_state', () => MayaAPI.control.state());
    if (res.ok) _set('control', { state: res.data });
  };
  Store.loadSyncTypes = async () => {
    const res = await _action('sync_types', () => MayaAPI.sync.types());
    if (res.ok) _set('sync', { types: res.data });
  };
  Store.loadLogs = async () => {
    const [llm, tools] = await Promise.all([
      _action('logs', () => MayaAPI.logs.llm(50)),
      _action('logs', () => MayaAPI.logs.tools(50)),
    ]);
    _set('logs', {
      llm: llm.ok ? llm.data : [],
      tools: tools.ok ? tools.data : [],
    });
  };
  Store.loadMetrics = async () => {
    const res = await _action('metrics', () => MayaAPI.metrics.get());
    if (res.ok) _set('metrics', res.data);
  };
  Store.loadProjects = async () => {
    const res = await _action('projects', () => MayaAPI.projects.list());
    if (res.ok) _set('projects', res.data?.projects || []);
  };

  Store.loadLanguages = async () => {
    const res = await _action('languages', () => MayaAPI.translate.languages());
    if (res.ok) _set('languages', res.data);
  };
  Store.loadAdmin = {
    dashboard: async () => {
      const res = await _action('admin_dashboard', () => MayaAPI.admin.dashboard());
      if (res.ok) _set('adminDashboard', res.data);
    },
  };

  // ── Loading/error helpers ──
  Store.isLoading = (key) => !!_state._loading[key];
  Store.error = (key) => _state._errors[key];
  Store.clearError = (key) => { _error(key, null); _emit('_errors', { ..._state._errors }); };

  // Export internal _set for app.js init()
  Store._set = _set;
})();
