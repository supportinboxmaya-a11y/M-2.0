// Maya 2.0 ULTRA - API Client
class ApiClient {
  constructor() {
    this.baseUrl = '';
    this.token = null;
    this.defaultHeaders = {
      'Content-Type': 'application/json'
    };
  }
  
  setToken(token) {
    this.token = token;
  }
  
  clearToken() {
    this.token = null;
  }
  
  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}${endpoint}`;
    const headers = { ...this.defaultHeaders };
    
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    
    if (options.headers) {
      Object.assign(headers, options.headers);
    }
    
    const config = {
      method: options.method || 'GET',
      headers,
      credentials: 'include'
    };
    
    if (options.body && !(options.body instanceof FormData)) {
      config.body = JSON.stringify(options.body);
    } else if (options.body instanceof FormData) {
      config.body = options.body;
      delete headers['Content-Type'];
    }
    
    try {
      const response = await fetch(url, config);
      
      if (response.status === 401) {
        // Token expired, try refresh
        const refreshed = await this.refreshToken();
        if (refreshed) {
          // Retry with new token
          headers['Authorization'] = `Bearer ${this.token}`;
          return fetch(url, { ...config, headers });
        } else {
          // Redirect to login
          window.dispatchEvent(new CustomEvent('auth:expired'));
          throw new Error('Authentication expired');
        }
      }
      
      if (!response.ok) {
        let errorData;
        try {
          errorData = await response.json();
        } catch {
          errorData = { detail: response.statusText };
        }
        throw new ApiError(response.status, errorData.detail || errorData.error || 'Request failed', errorData);
      }
      
      if (response.status === 204) return null;
      
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        return response.json();
      }
      
      return response.text();
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError(0, 'Network error', { originalError: error.message });
    }
  }
  
  async refreshToken() {
    try {
      const response = await fetch(`${this.baseUrl}/api/v1/auth/refresh`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/json'
        },
        credentials: 'include'
      });
      
      if (response.ok) {
        const data = await response.json();
        this.token = data.access_token;
        localStorage.setItem('maya_token', this.token);
        return true;
      }
    } catch {
      // Ignore
    }
    return false;
  }
  
  // Convenience methods
  get(endpoint) { return this.request(endpoint); }
  post(endpoint, body) { return this.request(endpoint, { method: 'POST', body }); }
  put(endpoint, body) { return this.request(endpoint, { method: 'PUT', body }); }
  patch(endpoint, body) { return this.request(endpoint, { method: 'PATCH', body }); }
  delete(endpoint) { return this.request(endpoint, { method: 'DELETE' }); }
  
  // Auth
  login(email, password) {
    return this.post('/api/v1/auth/login', { email, password });
  }
  
  register(name, email, password) {
    return this.post('/api/v1/auth/register', { name, email, password });
  }
  
  logout() {
    return this.post('/api/v1/auth/logout');
  }
  
  getMe() {
    return this.get('/api/v1/users/me');
  }
  
  // Agent
  getAgentStatus() {
    return this.get('/api/v1/agent/status');
  }
  
  runAgent(goal, budgetUsd = 1.0, instanceId = null) {
    return this.post('/api/v1/agent/run', { goal, budget_usd: budgetUsd, instance_id: instanceId });
  }
  
  chat(message, chatId = null, instanceId = null) {
    return this.post('/api/v1/agent/chat', { message, chat_id: chatId, instance_id: instanceId });
  }
  
  chatStream(message, chatId = null, instanceId = null) {
    return this.post('/api/v1/agent/chat/stream', { message, chat_id: chatId, instance_id: instanceId });
  }
  
  think(problem, depth = 'normal') {
    return this.post('/api/v1/agent/think', { problem, depth });
  }
  
  // Tasks
  getTasks(limit = 50, status = null) {
    const params = new URLSearchParams({ limit: limit.toString() });
    if (status) params.set('status', status);
    return this.get(`/api/v1/tasks?${params}`);
  }
  
  getTask(taskId) {
    return this.get(`/api/v1/tasks/${taskId}`);
  }
  
  createTask(goal, budgetUsd = 1.0, instanceId = null) {
    return this.post('/api/v1/tasks', { goal, budget_usd: budgetUsd, instance_id: instanceId });
  }
  
  deleteTask(taskId) {
    return this.delete(`/api/v1/tasks/${taskId}`);
  }
  
  reflectTask(taskId, retry = false) {
    return this.post(`/api/v1/tasks/${taskId}/reflect`, { retry });
  }
  
  // Memory
  getMemories(type = null, limit = 50) {
    const params = new URLSearchParams({ limit: limit.toString() });
    if (type) params.set('type', type);
    return this.get(`/api/v1/memory?${params}`);
  }
  
  searchMemory(query, limit = 10) {
    return this.get(`/api/v1/memory/search?q=${encodeURIComponent(query)}&limit=${limit}`);
  }
  
  addMemory(content, type = 'general') {
    return this.post('/api/v1/memory', { content, type });
  }
  
  deleteMemory(memoryId) {
    return this.delete(`/api/v1/memory/${memoryId}`);
  }
  
  getMemoryStats() {
    return this.get('/api/v1/memory/stats');
  }
  
  rankMemory(query, limit = 5) {
    return this.get(`/api/v1/memory/rank?q=${encodeURIComponent(query)}&limit=${limit}`);
  }
  
  cleanupMemory(dryRun = true) {
    return this.post('/api/v1/memory/cleanup', { dry_run: dryRun });
  }
  
  summarizeMemory(query = '', limit = 20) {
    return this.get(`/api/v1/memory/summary?q=${encodeURIComponent(query)}&limit=${limit}`);
  }
  
  // Tools
  getTools() {
    return this.get('/api/v1/tools');
  }
  
  runTool(toolName, input) {
    return this.post(`/api/v1/tools/${toolName}/run`, { input });
  }
  
  updateTool(toolName, enabled) {
    return this.put(`/api/v1/tools/${toolName}`, { enabled });
  }
  
  getToolLogs(limit = 50) {
    return this.get(`/api/v1/tools/logs?limit=${limit}`);
  }
  
  // LLM Providers
  getProviders() {
    return this.get('/api/v1/providers');
  }
  
  updateProvider(providerId, enabled) {
    return this.put(`/api/v1/providers/${providerId}`, { enabled });
  }
  
  setProviderKey(provider, apiKey) {
    return this.put(`/api/v1/llm/providers/${provider}/key`, { api_key: apiKey });
  }
  
  getProviderStats() {
    return this.get('/api/v1/llm/stats');
  }
  
  getRoutingStrategy(strategy = 'balanced') {
    return this.get(`/api/v1/llm/strategy?strategy=${strategy}`);
  }
  
  // Workflows
  getWorkflows() {
    return this.get('/api/v1/workflows');
  }
  
  createWorkflow(name, description, nodes = [], edges = []) {
    return this.post('/api/v1/workflows', { name, description, nodes, edges });
  }
  
  updateWorkflow(wfId, data) {
    return this.put(`/api/v1/workflows/${wfId}`, data);
  }
  
  deleteWorkflow(wfId) {
    return this.delete(`/api/v1/workflows/${wfId}`);
  }
  
  runWorkflow(wfId) {
    return this.post(`/api/v1/workflows/${wfId}/run`);
  }
  
  // Phase 6 Workflow Engine
  planWorkflow(goal) {
    return this.post('/api/v1/workflows/plan', { goal });
  }
  
  getWorkflowRuns() {
    return this.get('/api/v1/workflows/runs');
  }
  
  getWorkflowRun(runId) {
    return this.get(`/api/v1/workflows/runs/${runId}`);
  }
  
  cancelWorkflowRun(runId) {
    return this.post(`/api/v1/workflows/runs/${runId}/cancel`);
  }
  
  executeWorkflowRun(runId) {
    return this.post(`/api/v1/workflows/runs/${runId}/execute`);
  }
  
  // Phase 3 Workflow Builder
  getWorkflowDefs() {
    return this.get('/api/v1/workflows/defs');
  }
  
  getWorkflowDef(wid) {
    return this.get(`/api/v1/workflows/defs/${wid}`);
  }
  
  createWorkflowDef(name, steps, description = '') {
    return this.post('/api/v1/workflows/defs', { name, steps, description });
  }
  
  updateWorkflowDef(wid, data) {
    return this.put(`/api/v1/workflows/defs/${wid}`, data);
  }
  
  deleteWorkflowDef(wid) {
    return this.delete(`/api/v1/workflows/defs/${wid}`);
  }
  
  runWorkflowDef(wid, inputs = {}) {
    return this.post(`/api/v1/workflows/defs/${wid}/run`, { inputs });
  }
  
  // Brain
  analyzeGoal(goal) {
    return this.get(`/api/v1/brain/analyze?goal=${encodeURIComponent(goal)}`);
  }
  
  buildGraph(steps) {
    return this.post('/api/v1/brain/graph', { steps });
  }
  
  // Agents
  getAgents() {
    return this.get('/api/v1/agents');
  }
  
  orchestrateAgents(goal) {
    return this.post('/api/v1/agents/orchestrate', { goal });
  }
  
  getAgentMessages(limit = 50) {
    return this.get(`/api/v1/agents/messages?limit=${limit}`);
  }
  
  // RAG
  getRAGStats() {
    return this.get('/api/v1/rag/stats');
  }
  
  getRAGDocuments(limit = 200) {
    return this.get(`/api/v1/rag/documents?limit=${limit}`);
  }
  
  deleteRAGDocument(docId) {
    return this.delete(`/api/v1/rag/documents/${docId}`);
  }
  
  ingestRAG(data) {
    return this.post('/api/v1/rag/ingest', data);
  }
  
  searchRAG(query, limit = 5, mode = 'hybrid') {
    return this.get(`/api/v1/rag/search?q=${encodeURIComponent(query)}&limit=${limit}&mode=${mode}`);
  }
  
  getRAGContext(query, limit = 5, maxChars = 6000) {
    return this.get(`/api/v1/rag/context?q=${encodeURIComponent(query)}&limit=${limit}&max_chars=${maxChars}`);
  }
  
  // Vision/Voice
  analyzeVision(image, prompt = 'Describe this image in detail.') {
    return this.post('/api/v1/vision/analyze', { image, prompt });
  }
  
  ocrImage(image) {
    return this.post('/api/v1/vision/ocr', { image });
  }
  
  transcribeVoice(audio) {
    return this.post('/api/v1/voice/transcribe', { audio });
  }
  
  speakText(text, voice = 'alloy') {
    return this.post('/api/v1/voice/speak', { text, voice });
  }
  
  // Device Bridge
  startDevicePairing(name = 'My computer') {
    return this.post('/api/v1/device/pair/start', { name });
  }
  
  completeDevicePairing(code) {
    return this.post('/api/v1/device/pair/complete', { code });
  }
  
  listDevices() {
    return this.get('/api/v1/device/list');
  }
  
  revokeDevice(deviceId) {
    return this.delete(`/api/v1/device/${deviceId}`);
  }
  
  getDeviceHistory(deviceId) {
    return this.get(`/api/v1/device/${deviceId}/history`);
  }
  
  enqueueDeviceCommand(deviceId, action, params = {}) {
    return this.post('/api/v1/device/command', { device_id: deviceId, action, params });
  }
  
  // Workspace Files
  listWorkspaceFiles() {
    return this.get('/api/v1/workspace/files');
  }
  
  getWorkspaceFile(filename) {
    return this.get(`/api/v1/workspace/files/${filename}`);
  }
  
  // Backups
  listBackups() {
    return this.get('/api/v1/backup/list');
  }
  
  createBackup() {
    return this.post('/api/v1/backup/create');
  }
  
  restoreBackup(backupId) {
    return this.post(`/api/v1/backup/restore/${backupId}`);
  }
  
  deleteBackup(backupId) {
    return this.delete(`/api/v1/backup/${backupId}`);
  }
  
  // Security
  getSecurityStatus() {
    return this.get('/api/v1/security/status');
  }
  
  // Feature Flags
  getFlags() {
    return this.get('/api/v1/flags');
  }
  
  updateFlag(name, value) {
    return this.put('/api/v1/flags', { name, value });
  }
  
  // Approvals
  getApprovalMode() {
    return this.get('/api/v1/approval/mode');
  }
  
  setApprovalMode(mode) {
    return this.put('/api/v1/approval/mode', { mode });
  }
  
  createApproval(action, reason = '', riskLevel = 'low') {
    return this.post('/api/v1/approvals/request', { action, reason, risk_level: riskLevel });
  }
  
  getApprovals(status = '') {
    return this.get(`/api/v1/approvals?status=${status}`);
  }
  
  decideApproval(aid, decision) {
    return this.post(`/api/v1/approvals/${aid}/${decision}`);
  }
  
  // Learning
  submitFeedback(goal, output, rating, comment = '') {
    return this.post('/api/v1/learning/feedback', { goal, output, rating, comment });
  }
  
  getLearningStats() {
    return this.get('/api/v1/learning/stats');
  }
  
  getExperience(goal = '', limit = 5) {
    const params = new URLSearchParams({ limit: limit.toString() });
    if (goal) params.set('goal', goal);
    return this.get(`/api/v1/learning/experience?${params}`);
  }
  
  compressMemory(dryRun = true, memoryType = 'chat') {
    return this.post('/api/v1/learning/compress', { dry_run: dryRun, memory_type: memoryType });
  }
  
  // Plugins
  getPlugins() {
    return this.get('/api/v1/plugins');
  }
  
  updatePlugin(pluginId, enabled) {
    return this.put(`/api/v1/plugins/${pluginId}`, { enabled });
  }
  
  installPlugin(pluginId) {
    return this.post(`/api/v1/plugins/${pluginId}/install`);
  }
  
  deletePlugin(pluginId) {
    return this.delete(`/api/v1/plugins/${pluginId}`);
  }
  
  installPluginCode(name, code) {
    return this.post('/api/v1/plugins/install-code', { name, code });
  }
  
  getPluginTools(pluginId) {
    return this.get(`/api/v1/plugins/${pluginId}/tools`);
  }
  
  // Prompts
  getPrompts(category = '', query = '', limit = 100) {
    const params = new URLSearchParams({ limit: limit.toString() });
    if (category) params.set('category', category);
    if (query) params.set('q', query);
    return this.get(`/api/v1/prompts?${params}`);
  }
  
  getPrompt(pid) {
    return this.get(`/api/v1/prompts/${pid}`);
  }
  
  createPrompt(data) {
    return this.post('/api/v1/prompts', data);
  }
  
  updatePrompt(pid, data) {
    return this.put(`/api/v1/prompts/${pid}`, data);
  }
  
  deletePrompt(pid) {
    return this.delete(`/api/v1/prompts/${pid}`);
  }
  
  getPromptHistory(pid) {
    return this.get(`/api/v1/prompts/${pid}/history`);
  }
  
  renderPrompt(pid, values, run = false) {
    return this.post(`/api/v1/prompts/${pid}/render`, { values, run });
  }
  
  // Inbound Webhooks
  getWebhookTriggers() {
    return this.get('/api/v1/hooks');
  }
  
  createWebhookTrigger(data) {
    return this.post('/api/v1/hooks', data);
  }
  
  deleteWebhookTrigger(tid) {
    return this.delete(`/api/v1/hooks/${tid}`);
  }
  
  updateWebhookTrigger(tid, enabled) {
    return this.post(`/api/v1/hooks/${tid}/enabled`, { enabled });
  }
  
  // Outbound Webhooks
  getWebhooks() {
    return this.get('/api/v1/webhooks');
  }
  
  createWebhook(data) {
    return this.post('/api/v1/webhooks', data);
  }
  
  updateWebhook(whId, data) {
    return this.put(`/api/v1/webhooks/${whId}`, data);
  }
  
  deleteWebhook(whId) {
    return this.delete(`/api/v1/webhooks/${whId}`);
  }
  
  // Notifications
  getNotifications(unreadOnly = false, limit = 50) {
    return this.get(`/api/v1/notifications?unread_only=${unreadOnly}&limit=${limit}`);
  }
  
  getUnreadCount() {
    return this.get('/api/v1/notifications/unread');
  }
  
  markNotificationRead(nid) {
    return this.post(`/api/v1/notifications/${nid}/read`);
  }
  
  markAllNotificationsRead() {
    return this.post('/api/v1/notifications/read-all');
  }
  
  sendNotification(data) {
    return this.post('/api/v1/notifications/send', data);
  }
  
  registerDevice(token, platform) {
    return this.post('/api/v1/notifications/register-device', { token, platform });
  }
  
  // Offline Sync
  getSyncTypes() {
    return this.get('/api/v1/sync/types');
  }
  
  pushSync(actions) {
    return this.post('/api/v1/sync/push', { actions });
  }
  
  getSyncStatus(opId) {
    return this.get(`/api/v1/sync/status/${opId}`);
  }
  
  getRecentSync(limit = 50) {
    return this.get(`/api/v1/sync/recent?limit=${limit}`);
  }
  
  // Translation
  getLanguages() {
    return this.get('/api/v1/translate/languages');
  }
  
  translate(text, target, source = null, speak = false) {
    return this.post('/api/v1/translate', { text, target, source, speak });
  }
  
  detectLanguage(text) {
    return this.post('/api/v1/translate/detect', { text });
  }
  
  // Phone Control
  sendControlCommand(text, instanceId = null) {
    return this.post('/api/v1/control/command', { text, instance_id: instanceId });
  }
  
  getControlState() {
    return this.get('/api/v1/control/state');
  }
  
  // Instances
  getInstances() {
    return this.get('/api/v1/instances');
  }
  
  createInstance(data) {
    return this.post('/api/v1/instances', data);
  }
  
  getInstance(iid) {
    return this.get(`/api/v1/instances/${iid}`);
  }
  
  deleteInstance(iid) {
    return this.delete(`/api/v1/instances/${iid}`);
  }
  
  // Local Hosting
  getHostedApps() {
    return this.get('/api/v1/hosting/apps');
  }
  
  deployApp(data) {
    return this.post('/api/v1/hosting/deploy', data);
  }
  
  getAppStatus(name) {
    return this.get(`/api/v1/hosting/apps/${name}`);
  }
  
  startApp(name) {
    return this.post(`/api/v1/hosting/apps/${name}/start`);
  }
  
  stopApp(name) {
    return this.post(`/api/v1/hosting/apps/${name}/stop`);
  }
  
  restartApp(name) {
    return this.post(`/api/v1/hosting/apps/${name}/restart`);
  }
  
  tunnelApp(name) {
    return this.post(`/api/v1/hosting/apps/${name}/tunnel`);
  }
  
  getAppLogs(name, lines = 100) {
    return this.get(`/api/v1/hosting/apps/${name}/logs?lines=${lines}`);
  }
  
  removeApp(name) {
    return this.delete(`/api/v1/hosting/apps/${name}`);
  }
  
  // Remote VPS Deploy
  remoteDeploy(data) {
    return this.post('/api/v1/hosting/remote/deploy', data);
  }
  
  remoteAppAction(app, action) {
    return this.post(`/api/v1/hosting/remote/${app}/${action}`);
  }
  
  // App Registry
  getRegistryApps() {
    return this.get('/api/v1/hosting/registry');
  }
  
  registerApp(data) {
    return this.post('/api/v1/hosting/registry', data);
  }
  
  getRegistryApp(name) {
    return this.get(`/api/v1/hosting/registry/${name}`);
  }
  
  unregisterApp(name) {
    return this.delete(`/api/v1/hosting/registry/${name}`);
  }
  
  toggleAppMonitor(name, enabled) {
    return this.patch(`/api/v1/hosting/registry/${name}/monitor`, { enabled });
  }
  
  healthCheckApp(name) {
    return this.post(`/api/v1/hosting/registry/${name}/health`);
  }
  
  checkAllApps() {
    return this.post('/api/v1/hosting/registry/check-all');
  }
  
  restartRegistryApp(name) {
    return this.post(`/api/v1/hosting/registry/${name}/restart`);
  }
  
  getRegistryAppLogs(name, lines = 100) {
    return this.get(`/api/v1/hosting/registry/${name}/logs?lines=${lines}`);
  }
  
  // Deploy Pipeline
  planPipeline(data) {
    return this.post('/api/v1/deploy/pipeline/plan', data);
  }
  
  executePipeline(data) {
    return this.post('/api/v1/deploy/pipeline/execute', data);
  }
  
  getPipelineStatus() {
    return this.get('/api/v1/deploy/pipeline/status');
  }
  
  // Research Engine
  analyzeResearch(data) {
    return this.post('/api/v1/research/analyze', data);
  }
  
  getResearchReports() {
    return this.get('/api/v1/research/reports');
  }
  
  getResearchReport(reportId) {
    return this.get(`/api/v1/research/reports/${reportId}`);
  }
  
  // Cognition
  getMissions(activeOnly = false, missionType = null) {
    const params = new URLSearchParams({ active_only: activeOnly.toString() });
    if (missionType) params.set('mission_type', missionType);
    return this.get(`/api/v1/cognitive/missions?${params}`);
  }
  
  createMission(data) {
    return this.post('/api/v1/cognitive/missions', data);
  }
  
  updateMission(missionId, data) {
    return this.patch(`/api/v1/cognitive/missions/${missionId}`, data);
  }
  
  deleteMission(missionId) {
    return this.delete(`/api/v1/cognitive/missions/${missionId}`);
  }
  
  generateObjectives(missionId) {
    return this.post(`/api/v1/cognitive/missions/${missionId}/generate`);
  }
  
  getObjectives(missionId = null, status = null) {
    const params = new URLSearchParams();
    if (missionId) params.set('mission_id', missionId);
    if (status) params.set('status', status);
    return this.get(`/api/v1/cognitive/objectives?${params}`);
  }
  
  addObjective(data) {
    return this.post('/api/v1/cognitive/objectives', data);
  }
  
  triggerCognitionCycle() {
    return this.post('/api/v1/cognitive/cycle');
  }
  
  executeObjective(objectiveId) {
    return this.post('/api/v1/cognitive/execute-objective', { objective_id: objectiveId });
  }
  
  pauseCognition() {
    return this.post('/api/v1/cognitive/pause');
  }
  
  resumeCognition() {
    return this.post('/api/v1/cognitive/resume');
  }
  
  getCognitionStatus() {
    return this.get('/api/v1/cognitive/status');
  }
  
  // Business Analysis
  analyzeBusinessObjective(missionId, objectiveId = null) {
    return this.post(`/api/v1/cognitive/missions/${missionId}/analyze`, { objective_id: objectiveId });
  }
  
  getBusinessReports(missionId) {
    return this.get(`/api/v1/cognitive/missions/${missionId}/reports`);
  }
  
  getBusinessReport(missionId, reportId) {
    return this.get(`/api/v1/cognitive/missions/${missionId}/reports/${reportId}`);
  }
  
  // Guarded Publish
  publishSite(data) {
    return this.post('/api/v1/publish', data);
  }
  
  getPublishHistory() {
    return this.get('/api/v1/publish/history');
  }
  
  getPublishProposal(proposalId) {
    return this.get(`/api/v1/publish/history/${proposalId}`);
  }
  
  // Analytics
  getAnalyticsSummary() {
    return this.get('/api/v1/analytics/summary');
  }
  
  getAnalyticsDaily(days = 7) {
    return this.get(`/api/v1/analytics/daily?days=${days}`);
  }
  
  getAnalyticsProviders() {
    return this.get('/api/v1/analytics/providers');
  }
  
  getAnalyticsTools() {
    return this.get('/api/v1/analytics/tools');
  }
  
  // Logs
  getLLMLogs(limit = 50) {
    return this.get(`/api/v1/logs/llm?limit=${limit}`);
  }
  
  getToolLogs(limit = 50) {
    return this.get(`/api/v1/logs/tools?limit=${limit}`);
  }
  
  // Admin
  getAdminRoles() {
    return this.get('/api/v1/admin/roles');
  }
  
  getAdminOrgs() {
    return this.get('/api/v1/admin/orgs');
  }
  
  createAdminOrg(name) {
    return this.post('/api/v1/admin/orgs', { name });
  }
  
  deleteAdminOrg(orgId) {
    return this.delete(`/api/v1/admin/orgs/${orgId}`);
  }
  
  removeOrgMember(orgId, email) {
    return this.delete(`/api/v1/admin/orgs/${orgId}/members/${email}`);
  }
  
  createOrgTeam(orgId, name) {
    return this.post(`/api/v1/admin/orgs/${orgId}/teams`, { name });
  }
  
  getOrgTeams(orgId) {
    return this.get(`/api/v1/admin/orgs/${orgId}/teams`);
  }
  
  addOrgMember(orgId, data) {
    return this.post(`/api/v1/admin/orgs/${orgId}/members`, data);
  }
  
  getOrgMembers(orgId) {
    return this.get(`/api/v1/admin/orgs/${orgId}/members`);
  }
  
  createApiKey(name) {
    return this.post('/api/v1/admin/apikeys', { name });
  }
  
  getApiKeys() {
    return this.get('/api/v1/admin/apikeys');
  }
  
  revokeApiKey(keyId) {
    return this.delete(`/api/v1/admin/apikeys/${keyId}`);
  }
  
  getAuditLog(actor = null, action = null, limit = 100) {
    const params = new URLSearchParams({ limit: limit.toString() });
    if (actor) params.set('actor', actor);
    if (action) params.set('action', action);
    return this.get(`/api/v1/admin/audit?${params}`);
  }
  
  getUsage(sinceTs = 0) {
    return this.get(`/api/v1/admin/usage?since_ts=${sinceTs}`);
  }
  
  getAdminDashboard() {
    return this.get('/api/v1/admin/dashboard');
  }
  
  getAdminUsers() {
    return this.get('/api/v1/admin/users');
  }
  
  banUser(userId, banned) {
    return this.put(`/api/v1/admin/users/${userId}/ban`, { banned });
  }
  
  setUserBudget(userId, budgetUsd) {
    return this.put(`/api/v1/admin/users/${userId}/budget`, { budget_usd: budgetUsd });
  }
  
  // Health
  health() {
    return this.get('/health');
  }
  
  healthLive() {
    return this.get('/health/live');
  }
  
  healthReady() {
    return this.get('/health/ready');
  }
  
  healthSystem() {
    return this.get('/health/system');
  }
  
  // Metrics
  getMetrics() {
    return this.get('/api/v1/metrics');
  }
  
  // Queue
  getQueueStatus() {
    return this.get('/api/v1/queue/status');
  }
  
  getQueueStats() {
    return this.get('/api/v1/queue/stats');
  }
  
  getQueueTask(taskId) {
    return this.get(`/api/v1/queue/task/${taskId}`);
  }
  
  submitQueueJob(job, args = [], kwargs = {}) {
    return this.post('/api/v1/queue/submit', { job, args, kwargs });
  }
  
  cancelQueueTask(taskId) {
    return this.post(`/api/v1/queue/cancel/${taskId}`);
  }
  
  // Schedules
  getSchedules() {
    return this.get('/api/v1/schedules');
  }
  
  createSchedule(data) {
    return this.post('/api/v1/schedules', data);
  }
  
  deleteSchedule(sid) {
    return this.delete(`/api/v1/schedules/${sid}`);
  }
  
  setScheduleEnabled(sid, enabled) {
    return this.post(`/api/v1/schedules/${sid}/enabled`, { enabled });
  }
  
  // Projects
  createProject(data) {
    return this.post('/api/v1/projects', data);
  }
  
  getProjects() {
    return this.get('/api/v1/projects');
  }
  
  getProjectProgress(scheduleId) {
    return this.get(`/api/v1/projects/${scheduleId}/progress`);
  }
  
  deleteProject(scheduleId) {
    return this.delete(`/api/v1/projects/${scheduleId}`);
  }
  
  // Docs
  getDocs() {
    return this.get('/api/v1/docs');
  }
  
  getDoc(name) {
    return this.get(`/api/v1/docs/${name}`);
  }
  
  // Skills
  getSkills() {
    return this.get('/api/v1/skills');
  }
}

class ApiError extends Error {
  constructor(status, message, data = {}) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

export const api = new ApiClient();
export { ApiError };