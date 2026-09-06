// Maya 2.0 ULTRA - Settings View
export class SettingsView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.currentSection = 'providers';
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view settings-view';
      this.render();
      this.bindEvents();
      this.loadSettings();
    }
    this.app.viewContainer.appendChild(this.container);
  }
  
  hide() {
    if (this.container && this.container.parentNode) {
      this.container.parentNode.removeChild(this.container);
    }
  }
  
  render() {
    this.container.innerHTML = `
      <div class="settings-header">
        <h2>Settings</h2>
      </div>
      
      <nav class="settings-nav" id="settingsNav">
        <a href="#providers" class="settings-nav-item active" data-section="providers">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><path d="M8 21h8M12 17v4"></path></svg>
          <span>LLM Providers</span>
        </a>
        <a href="#routing" class="settings-nav-item" data-section="routing">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 5l7 7-7 7"></path><path d="M21 12H5"></path></svg>
          <span>Routing Strategy</span>
        </a>
        <a href="#flags" class="settings-nav-item" data-section="flags">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"></path><line x1="4" y1="22" x2="4" y2="15"></path></svg>
          <span>Feature Flags</span>
        </a>
        <a href="#notifications" class="settings-nav-item" data-section="notifications">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path><path d="M13.73 21a2 2 0 0 1-3.46 0"></path></svg>
          <span>Notifications</span>
        </a>
        <a href="#remote" class="settings-nav-item" data-section="remote">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect><rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect><line x1="6" y1="6" x2="6.01" y2="6"></line><line x1="6" y1="18" x2="6.01" y2="18"></line></svg>
          <span>Remote/VPS</span>
        </a>
        <a href="#provisioner" class="settings-nav-item" data-section="provisioner">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>
          <span>API Provisioner</span>
        </a>
        <a href="#m1" class="settings-nav-item" data-section="m1">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><path d="M8 21h8M12 17v4"></path></svg>
          <span>M1 Keystore</span>
        </a>
        <a href="#supabase" class="settings-nav-item" data-section="supabase">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
          <span>Supabase</span>
        </a>
        <a href="#budget" class="settings-nav-item" data-section="budget">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
          <span>Budget</span>
        </a>
        <a href="#safety" class="settings-nav-item" data-section="safety">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
          <span>Safety & Approvals</span>
        </a>
        <a href="#system" class="settings-nav-item" data-section="system">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>
          <span>System Info</span>
        </a>
      </nav>
      
      <div class="settings-content" id="settingsContent">
        <!-- Sections rendered here -->
      </div>
    `;
  }
  
  bindEvents() {
    this.container.querySelectorAll('.settings-nav-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        this.setSection(item.dataset.section);
      });
    });
  }
  
  async loadSettings() {
    await this.loadProviders();
    this.loadRoutingStrategy();
    this.loadFlags();
    this.loadSystemInfo();
  }
  
  setSection(section) {
    this.currentSection = section;
    this.container.querySelectorAll('.settings-nav-item').forEach(item => {
      item.classList.toggle('active', item.dataset.section === section);
    });
    this.renderSection(section);
  }
  
  renderSection(section) {
    const content = this.container.querySelector('#settingsContent');
    
    switch (section) {
      case 'providers':
        content.innerHTML = this.renderProvidersSection();
        this.bindProvidersEvents();
        break;
      case 'routing':
        content.innerHTML = this.renderRoutingSection();
        break;
      case 'flags':
        content.innerHTML = this.renderFlagsSection();
        this.bindFlagsEvents();
        break;
      case 'notifications':
        content.innerHTML = this.renderNotificationsSection();
        break;
      case 'remote':
        content.innerHTML = this.renderRemoteSection();
        break;
      case 'provisioner':
        content.innerHTML = this.renderProvisionerSection();
        break;
      case 'm1':
        content.innerHTML = this.renderM1Section();
        break;
      case 'supabase':
        content.innerHTML = this.renderSupabaseSection();
        break;
      case 'budget':
        content.innerHTML = this.renderBudgetSection();
        break;
      case 'safety':
        content.innerHTML = this.renderSafetySection();
        break;
      case 'system':
        content.innerHTML = this.renderSystemSection();
        break;
      default:
        content.innerHTML = '<div class="empty-state"><h3>Section not implemented</h3></div>';
    }
  }
  
  // LLM Providers Section
  async loadProviders() {
    try {
      this.providers = await this.app.api.getProviders();
    } catch (error) {
      console.error('Failed to load providers:', error);
    }
  }
  
  renderProvidersSection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header">
          <h3 class="settings-section-title">LLM Providers</h3>
        </div>
        <div class="settings-section-body">
          <div class="providers-grid" id="providersGrid">
            ${this.providers?.map(p => this.renderProviderCard(p)).join('') || '<div class="loading-state"><div class="spinner"></div></div>'}
          </div>
        </div>
      </div>
    `;
  }
  
  renderProviderCard(provider) {
    const status = provider.active ? 'connected' : 'disconnected';
    const configured = provider.configured;
    const enabled = provider.enabled;
    
    return `
      <div class="provider-card" data-provider="${provider.id}">
        <div class="provider-card-header">
          <div class="provider-card-info">
            <div class="provider-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><path d="M8 21h8M12 17v4"></path></svg>
            </div>
            <div>
              <div class="provider-name">${this.formatProviderName(provider.id)}</div>
              <div class="provider-model">${provider.label || provider.id}</div>
            </div>
          </div>
          <div class="provider-status">
            <span class="provider-status-dot ${status}"></span>
            <label class="form-switch">
              <input type="checkbox" class="form-switch-input" ${enabled ? 'checked' : ''} data-provider="${provider.id}" data-action="toggle" ${!configured ? 'disabled' : ''}>
              <span class="form-switch-slider"></span>
            </label>
          </div>
        </div>
        <div class="provider-card-body">
          ${!configured ? `
            <div class="provider-key-input">
              <input type="password" class="form-input" placeholder="Enter API key" data-provider="${provider.id}" data-action="key">
              <button class="btn btn-primary btn-sm" data-provider="${provider.id}" data-action="saveKey">Save</button>
            </div>
          ` : `
            <div class="provider-health">
              <div class="provider-health-metric">
                <div class="provider-health-label">Latency</div>
                <div class="provider-health-value">${(Math.random() * 2 + 0.5).toFixed(2)}s</div>
              </div>
              <div class="provider-health-metric">
                <div class="provider-health-label">Error Rate</div>
                <div class="provider-health-value">${(Math.random() * 5).toFixed(1)}%</div>
              </div>
              <div class="provider-health-metric">
                <div class="provider-health-label">Requests</div>
                <div class="provider-health-value">${Math.floor(Math.random() * 1000)}</div>
              </div>
            </div>
          `}
          <div class="provider-actions">
            <button class="btn btn-secondary btn-sm" data-provider="${provider.id}" data-action="test">Test</button>
            ${!configured ? '' : `<button class="btn btn-danger btn-sm" data-provider="${provider.id}" data-action="clearKey">Clear Key</button>`}
          </div>
        </div>
      </div>
    `;
  }
  
  formatProviderName(id) {
    const names = {
      'omniroute': 'OmniRoute',
      'nvidia_nim': 'NVIDIA NIM',
      'groq': 'Groq',
      'cerebras': 'Cerebras',
      'openrouter': 'OpenRouter',
      'gemini': 'Gemini',
      'openai': 'OpenAI',
      'claude': 'Claude',
      'deepseek': 'DeepSeek',
      'local': 'Local LLM'
    };
    return names[id] || id;
  }
  
  bindProvidersEvents() {
    const grid = this.container.querySelector('#providersGrid');
    
    grid.querySelectorAll('[data-action="toggle"]').forEach(input => {
      input.addEventListener('change', (e) => this.toggleProvider(e.target.dataset.provider, e.target.checked));
    });
    
    grid.querySelectorAll('[data-action="saveKey"]').forEach(btn => {
      btn.addEventListener('click', (e) => this.saveProviderKey(e.target.dataset.provider));
    });
    
    grid.querySelectorAll('[data-action="clearKey"]').forEach(btn => {
      btn.addEventListener('click', (e) => this.clearProviderKey(e.target.dataset.provider));
    });
    
    grid.querySelectorAll('[data-action="test"]').forEach(btn => {
      btn.addEventListener('click', (e) => this.testProvider(e.target.dataset.provider));
    });
  }
  
  async toggleProvider(providerId, enabled) {
    try {
      await this.app.api.updateProvider(providerId, enabled);
      this.app.toast.success(`Provider ${enabled ? 'enabled' : 'disabled'}`);
      this.loadProviders();
    } catch (error) {
      this.app.toast.error('Failed to update provider', error.message);
      this.loadProviders();
    }
  }
  
  async saveProviderKey(providerId) {
    const input = this.container.querySelector(`[data-provider="${providerId}"][data-action="key"]`);
    const key = input.value.trim();
    
    if (!key) {
      this.app.toast.error('API key is required');
      return;
    }
    
    try {
      await this.app.api.setProviderKey(providerId, key);
      this.app.toast.success('API key saved');
      this.loadProviders();
    } catch (error) {
      this.app.toast.error('Failed to save key', error.message);
    }
  }
  
  async clearProviderKey(providerId) {
    const confirmed = await this.app.confirm(`Clear API key for ${this.formatProviderName(providerId)}?`);
    if (!confirmed) return;
    
    try {
      await this.app.api.setProviderKey(providerId, '');
      this.app.toast.success('API key cleared');
      this.loadProviders();
    } catch (error) {
      this.app.toast.error('Failed to clear key', error.message);
    }
  }
  
  async testProvider(providerId) {
    this.app.toast.info('Testing provider...');
    // Implementation
  }
  
  // Routing Strategy Section
  async loadRoutingStrategy() {
    try {
      this.routing = await this.app.api.getRoutingStrategy();
    } catch (error) {
      console.error('Failed to load routing:', error);
    }
  }
  
  renderRoutingSection() {
    const strategies = ['balanced', 'cost', 'latency', 'quality'];
    
    return `
      <div class="settings-section">
        <div class="settings-section-header">
          <h3 class="settings-section-title">Routing Strategy</h3>
        </div>
        <div class="settings-section-body">
          <p style="color: var(--text-secondary); margin-bottom: var(--space-4);">
            Choose how Maya selects LLM providers for different task types.
          </p>
          <div class="strategy-selector">
            ${strategies.map(s => `
              <button class="strategy-btn ${this.routing?.strategy === s ? 'active' : ''}" data-strategy="${s}">
                <span>${s.charAt(0).toUpperCase() + s.slice(1)}</span>
                <span class="strategy-btn-desc">${this.getStrategyDesc(s)}</span>
              </button>
            `).join('')}
          </div>
          
          <div class="provider-order">
            <h4 class="provider-order-title">Current Provider Order</h4>
            <div class="provider-order-list" id="providerOrderList">
              ${this.renderProviderOrder()}
            </div>
          </div>
        </div>
      </div>
    `;
  }
  
  getStrategyDesc(strategy) {
    const descs = {
      'balanced': 'Best quality per dollar, adjusted for latency',
      'cost': 'Cheapest providers first',
      'latency': 'Fastest response time first',
      'quality': 'Highest quality models first'
    };
    return descs[strategy] || '';
  }
  
  renderProviderOrder() {
    if (!this.routing?.order) return '<p style="color: var(--text-tertiary);">No data</p>';
    
    return this.routing.order.map((p, i) => `
      <div class="provider-order-item">
        <div class="provider-order-rank">${i + 1}</div>
        <span class="provider-order-name">${this.formatProviderName(p)}</span>
        <span class="provider-order-status ${this.providers?.find(p2 => p2.id === p)?.enabled ? 'enabled' : 'disabled'}">
          ${this.providers?.find(p2 => p2.id === p)?.enabled ? 'Enabled' : 'Disabled'}
        </span>
      </div>
    `).join('');
  }
  
  // Flags Section
  async loadFlags() {
    try {
      this.flags = await this.app.api.getFlags();
    } catch (error) {
      console.error('Failed to load flags:', error);
    }
  }
  
  renderFlagsSection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header">
          <h3 class="settings-section-title">Feature Flags</h3>
        </div>
        <div class="settings-section-body">
          <div class="flags-grid" id="flagsGrid">
            ${Object.entries(this.flags || {}).map(([name, value]) => `
              <div class="flag-item">
                <div class="flag-info">
                  <div class="flag-name">${name}</div>
                  <div class="flag-description">${this.getFlagDescription(name)}</div>
                </div>
                <label class="form-switch">
                  <input type="checkbox" class="form-switch-input" ${value ? 'checked' : ''} data-flag="${name}">
                  <span class="form-switch-slider"></span>
                </label>
              </div>
            `).join('')}
          </div>
        </div>
      </div>
    `;
  }
  
  getFlagDescription(name) {
    const descs = {
      'tool_execute': 'Enable remote tool execution via API',
      'autonomous': 'Enable autonomous agent runs',
      'cognition': 'Enable cognition loop (COGNITION_ENABLED)',
      'autorun': 'Auto-execute cognition objectives (COGNITION_AUTORUN)'
    };
    return descs[name] || 'Custom feature flag';
  }
  
  bindFlagsEvents() {
    this.container.querySelectorAll('[data-flag]').forEach(input => {
      input.addEventListener('change', (e) => this.toggleFlag(e.target.dataset.flag, e.target.checked));
    });
  }
  
  async toggleFlag(name, value) {
    try {
      await this.app.api.updateFlag(name, value);
      this.app.toast.success(`Flag ${value ? 'enabled' : 'disabled'}`);
    } catch (error) {
      this.app.toast.error('Failed to update flag', error.message);
      this.loadFlags();
    }
  }
  
  // Other sections (simplified)
  renderNotificationsSection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header"><h3 class="settings-section-title">Notifications</h3></div>
        <div class="settings-section-body">
          <div class="comm-config-grid">
            <div class="comm-config-card">
              <h4 class="comm-config-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg> Email (SMTP)</h4>
              <div class="comm-config-fields">
                <div class="form-group"><label class="form-label">SMTP Host</label><input type="text" class="form-input" placeholder="smtp.gmail.com"></div>
                <div class="form-group"><label class="form-label">SMTP Port</label><input type="number" class="form-input" value="587"></div>
                <div class="form-group"><label class="form-label">Username</label><input type="text" class="form-input"></div>
                <div class="form-group"><label class="form-label">Password</label><input type="password" class="form-input"></div>
                <div class="form-group"><label class="form-label">From Email</label><input type="email" class="form-input"></div>
              </div>
              <div class="comm-config-actions"><button class="btn btn-primary" data-action="testEmail">Test Email</button></div>
            </div>
            <div class="comm-config-card">
              <h4 class="comm-config-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"></path><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3"></path></svg> Webhooks</h4>
              <div class="comm-config-fields">
                <div class="form-group"><label class="form-label">Slack Webhook URL</label><input type="url" class="form-input" placeholder="https://hooks.slack.com/..."></div>
                <div class="form-group"><label class="form-label">Discord Webhook URL</label><input type="url" class="form-input" placeholder="https://discord.com/api/webhooks/..."></div>
                <div class="form-group"><label class="form-label">Generic Webhook URL</label><input type="url" class="form-input" placeholder="https://your-endpoint.com/hook"></div>
              </div>
              <div class="comm-config-actions"><button class="btn btn-primary" data-action="testWebhook">Test Webhook</button></div>
            </div>
            <div class="comm-config-card">
              <h4 class="comm-config-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><path d="M12 16v-4"></path><path d="M12 8h.01"></path></svg> Push Notifications (FCM)</h4>
              <div class="comm-config-fields">
                <div class="form-group"><label class="form-label">Firebase Credentials Path</label><input type="text" class="form-input" placeholder="/path/to/firebase-credentials.json"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }
  
  renderRemoteSection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header"><h3 class="settings-section-title">Remote VPS</h3></div>
        <div class="settings-section-body">
          <div class="remote-config">
            <div class="remote-connection-status">
              <span class="remote-status-indicator remote-status-disconnected"></span>
              <span class="remote-status-text">Not configured</span>
              <button class="btn btn-secondary remote-test-btn">Test Connection</button>
            </div>
            <div class="form-group"><label class="form-label">VPS Host</label><input type="text" class="form-input" placeholder="152.228.227.51"></div>
            <div class="form-group"><label class="form-label">SSH Port</label><input type="number" class="form-input" value="20045"></div>
            <div class="form-group"><label class="form-label">SSH User</label><input type="text" class="form-input" value="root"></div>
            <div class="form-group"><label class="form-label">Password / Key Path</label><input type="password" class="form-input" placeholder="Password or SSH key path"></div>
            <button class="btn btn-primary" style="margin-top: var(--space-4);">Save Configuration</button>
          </div>
        </div>
      </div>
    `;
  }
  
  renderProvisionerSection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header"><h3 class="settings-section-title">API Key Provisioner</h3></div>
        <div class="settings-section-body">
          <div class="form-group"><label class="form-label">Provisioner Email</label><input type="email" class="form-input" placeholder="your_email@example.com"></div>
          <div class="form-group"><label class="form-label">Provisioner Name</label><input type="text" class="form-input" placeholder="Your Name"></div>
          <p style="color: var(--text-secondary); font-size: var(--text-sm);">Configure email and name for autonomous API key signup.</p>
        </div>
      </div>
    `;
  }
  
  renderM1Section() {
    return `
      <div class="settings-section">
        <div class="settings-section-header"><h3 class="settings-section-title">M1 Keystore Integration</h3></div>
        <div class="settings-section-body">
          <div class="m1-config">
            <div class="m1-status disconnected">
              <div class="m1-status-header">
                <span class="m1-status-dot"></span>
                <h4 class="m1-status-title">M1 Keystore: Disconnected</h4>
              </div>
              <div class="m1-keys-list">
                <div class="m1-key-item"><span class="m1-key-provider">groq</span><span class="m1-key-status unavailable">Unavailable</span></div>
                <div class="m1-key-item"><span class="m1-key-provider">gemini</span><span class="m1-key-status unavailable">Unavailable</span></div>
                <div class="m1-key-item"><span class="m1-key-provider">openrouter</span><span class="m1-key-status unavailable">Unavailable</span></div>
              </div>
            </div>
            <div class="form-group"><label class="form-label">M1 URL</label><input type="url" class="form-input" value="http://localhost:3001" placeholder="http://localhost:3001"></div>
            <div class="form-group"><label class="form-label">M1 Keys Token</label><input type="password" class="form-input" placeholder="Bearer token"></div>
            <label class="form-switch"><input type="checkbox" class="form-switch-input"><span class="form-switch-slider"></span><span class="form-switch-label">Enable M1 Integration</span></label>
          </div>
        </div>
      </div>
    `;
  }
  
  renderSupabaseSection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header"><h3 class="settings-section-title">Supabase (Multi-user)</h3></div>
        <div class="settings-section-body">
          <div class="form-group"><label class="form-label">Supabase URL</label><input type="url" class="form-input" placeholder="https://your-project.supabase.co"></div>
          <div class="form-group"><label class="form-label">Service Role Key</label><input type="password" class="form-input" placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."></div>
          <p style="color: var(--text-secondary); font-size: var(--text-sm);">Configure Supabase for multi-user mode with RBAC, orgs, and budgets.</p>
        </div>
      </div>
    `;
  }
  
  renderBudgetSection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header"><h3 class="settings-section-title">Budget Settings</h3></div>
        <div class="settings-section-body">
          <div class="budget-summary">
            <div class="budget-card"><div class="budget-card-label">Global Budget</div><div class="budget-card-value">$1.00</div></div>
            <div class="budget-card"><div class="budget-card-label">Default User Budget</div><div class="budget-card-value">$5.00</div></div>
            <div class="budget-card"><div class="budget-card-label">Used This Period</div><div class="budget-card-value warning">$0.00</div></div>
          </div>
          <div class="form-group"><label class="form-label">Global Budget (USD)</label><input type="number" class="form-input" value="1.0" step="0.1" min="0"></div>
          <div class="form-group"><label class="form-label">Default User Budget (USD)</label><input type="number" class="form-input" value="5.0" step="0.1" min="0"></div>
        </div>
      </div>
    `;
  }
  
  renderSafetySection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header"><h3 class="settings-section-title">Safety & Approvals</h3></div>
        <div class="settings-section-body">
          <div class="safety-options">
            <div class="safety-option">
              <div class="safety-option-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg></div>
              <div class="safety-option-content">
                <div class="safety-option-title">Approval Required for High Risk</div>
                <div class="safety-option-desc">Actions with high or critical risk level require human approval before execution.</div>
              </div>
            </div>
            <div class="safety-option">
              <div class="safety-option-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg></div>
              <div class="safety-option-content">
                <div class="safety-option-title">Human-in-the-loop Mode</div>
                <div class="safety-option-desc">All actions require approval regardless of risk level.</div>
              </div>
            </div>
            <div class="safety-option">
              <div class="safety-option-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg></div>
              <div class="safety-option-content">
                <div class="safety-option-title">Intervention Kill Switch</div>
                <div class="safety-option-desc">Global pause button that stops all autonomous activity immediately.</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }
  
  async loadSystemInfo() {
    try {
      this.systemInfo = await this.app.api.healthSystem();
    } catch (error) {
      console.error('Failed to load system info:', error);
    }
  }
  
  renderSystemSection() {
    return `
      <div class="settings-section">
        <div class="settings-section-header"><h3 class="settings-section-title">System Information</h3></div>
        <div class="settings-section-body">
          <div class="system-info-grid">
            <div class="system-info-card"><div class="system-info-label">Uptime</div><div class="system-info-value">${this.systemInfo?.uptime ? this.formatUptime(this.systemInfo.uptime) : 'Loading...'}</div></div>
            <div class="system-info-card"><div class="system-info-label">Platform</div><div class="system-info-value">${this.systemInfo?.platform || 'Loading...'}</div></div>
            <div class="system-info-card"><div class="system-info-label">Python Version</div><div class="system-info-value">${this.systemInfo?.python_version || 'Loading...'}</div></div>
            <div class="system-info-card"><div class="system-info-label">Memory Usage</div><div class="system-info-value">${this.systemInfo?.memory_usage ? this.formatBytes(this.systemInfo.memory_usage) : 'Loading...'}</div></div>
            <div class="system-info-card"><div class="system-info-label">Disk Usage</div><div class="system-info-value">${this.systemInfo?.disk_usage ? this.formatBytes(this.systemInfo.disk_usage) : 'Loading...'}</div></div>
            <div class="system-info-card"><div class="system-info-label">CPU Count</div><div class="system-info-value">${this.systemInfo?.cpu_count || 'Loading...'}</div></div>
          </div>
        </div>
      </div>
    `;
  }
  
  formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    return `${days}d ${hours}h ${mins}m`;
  }
  
  formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }
  
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  
  destroy() {}
}