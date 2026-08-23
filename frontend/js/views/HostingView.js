// Maya 2.0 ULTRA - Hosting View
export class HostingView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.currentTab = 'local';
    this.apps = [];
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view hosting-view';
      this.render();
      this.bindEvents();
      this.loadApps();
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
      <div class="hosting-header">
        <h2>Hosting</h2>
      </div>
      
      <div class="hosting-tabs" id="hostingTabs">
        <button class="hosting-tab active" data-tab="local">Local Apps</button>
        <button class="hosting-tab" data-tab="remote">Remote VPS</button>
        <button class="hosting-tab" data-tab="registry">Registry</button>
        <button class="hosting-tab" data-tab="pipeline">Deploy Pipeline</button>
      </div>
      
      <div class="hosting-tab-panel active" id="panelLocal">
        <div class="apps-grid" id="localAppsGrid">
          <div class="loading-state"><div class="spinner"></div><p>Loading apps...</p></div>
        </div>
        <div style="margin-top: var(--space-4);">
          <button class="btn btn-primary" id="deployLocalApp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            Deploy App
          </button>
        </div>
      </div>
      
      <div class="hosting-tab-panel" id="panelRemote" style="display: none;">
        <div class="remote-deploy-form" id="remoteDeployForm">
          <h3>Deploy to Remote VPS</h3>
          <div class="form-group">
            <label class="form-label" for="remoteAppName">App Name</label>
            <input type="text" class="form-input" id="remoteAppName" placeholder="my-app">
          </div>
          <div class="form-group">
            <label class="form-label" for="remoteImage">Docker Image</label>
            <input type="text" class="form-input" id="remoteImage" placeholder="nginx:latest">
          </div>
          <div class="form-group">
            <label class="form-label" for="remoteDockerfile">Dockerfile Directory (optional)</label>
            <input type="text" class="form-input" id="remoteDockerfile" placeholder="./my-app">
          </div>
          <div class="form-group">
            <label class="form-label" for="remotePorts">Ports (JSON: {"80": "8080"})</label>
            <input type="text" class="form-input" id="remotePorts" placeholder='{"80": "80"}'>
          </div>
          <button class="btn btn-primary" id="deployRemoteBtn">Deploy to VPS</button>
        </div>
      </div>
      
      <div class="hosting-tab-panel" id="panelRegistry" style="display: none;">
        <div class="apps-grid" id="registryAppsGrid">
          <div class="loading-state"><div class="spinner"></div><p>Loading registry...</p></div>
        </div>
        <div style="margin-top: var(--space-4);">
          <button class="btn btn-primary" id="registerAppBtn">Register App</button>
        </div>
      </div>
      
      <div class="hosting-tab-panel" id="panelPipeline" style="display: none;">
        <div class="pipeline-wizard" id="pipelineWizard">
          <div class="pipeline-progress">
            <div class="pipeline-step-indicator">
              <div class="pipeline-step-circle active" data-step="1">1</div>
              <div class="pipeline-step-line"></div>
              <div class="pipeline-step-circle" data-step="2">2</div>
              <div class="pipeline-step-line"></div>
              <div class="pipeline-step-circle" data-step="3">3</div>
            </div>
            <div class="pipeline-step-label">Plan</div>
            <div class="pipeline-step-label">Confirm</div>
            <div class="pipeline-step-label">Execute</div>
          </div>
          
          <div class="pipeline-step active" id="stepPlan">
            <form class="pipeline-form" id="pipelinePlanForm">
              <div class="pipeline-form-row">
                <div class="form-group">
                  <label class="form-label" for="pipeAppName">App Name</label>
                  <input type="text" class="form-input" id="pipeAppName" required placeholder="my-app">
                </div>
                <div class="form-group">
                  <label class="form-label" for="pipeSourceDir">Source Directory</label>
                  <input type="text" class="form-input" id="pipeSourceDir" required placeholder="./my-app">
                </div>
              </div>
              <div class="pipeline-form-row">
                <div class="form-group">
                  <label class="form-label" for="pipePorts">Ports (JSON)</label>
                  <input type="text" class="form-input" id="pipePorts" placeholder='{"80": "80"}'>
                </div>
                <div class="form-group">
                  <label class="form-label" for="pipeEnv">Environment (JSON)</label>
                  <input type="text" class="form-input" id="pipeEnv" placeholder='{"NODE_ENV": "production"}'>
                </div>
              </div>
              <button type="submit" class="btn btn-primary">Next: Review Plan</button>
            </form>
          </div>
          
          <div class="pipeline-step" id="stepConfirm" style="display: none;">
            <div class="pipeline-plan" id="pipelinePlan"></div>
            <div class="modal-footer" style="margin-top: var(--space-5);">
              <button type="button" class="btn btn-secondary" id="pipelineBack">Back</button>
              <button type="button" class="btn btn-primary" id="pipelineExecute">Execute Deployment</button>
            </div>
          </div>
          
          <div class="pipeline-step" id="stepExecute" style="display: none;">
            <div class="loading-state" style="text-align: center;">
              <div class="spinner"></div>
              <p>Deploying...</p>
            </div>
          </div>
        </div>
        
        <div class="pipeline-status" id="pipelineStatus" style="margin-top: var(--space-5); display: none;"></div>
      </div>
    `;
  }
  
  bindEvents() {
    // Tabs
    this.container.querySelectorAll('.hosting-tab').forEach(tab => {
      tab.addEventListener('click', () => this.setTab(tab.dataset.tab));
    });
    
    // Deploy local
    this.container.querySelector('#deployLocalApp').addEventListener('click', () => this.openDeployModal());
    
    // Remote deploy
    this.container.querySelector('#deployRemoteBtn').addEventListener('click', () => this.deployRemote());
    
    // Pipeline
    this.container.querySelector('#pipelinePlanForm').addEventListener('submit', (e) => this.handlePlanSubmit(e));
    this.container.querySelector('#pipelineBack').addEventListener('click', () => this.showPipelineStep('plan'));
    this.container.querySelector('#pipelineExecute').addEventListener('click', () => this.executePipeline());
  }
  
  setTab(tab) {
    this.currentTab = tab;
    this.container.querySelectorAll('.hosting-tab').forEach(t => {
      t.classList.toggle('active', t.dataset.tab === tab);
    });
    this.container.querySelectorAll('.hosting-tab-panel').forEach(p => {
      p.style.display = p.id === `panel${tab.charAt(0).toUpperCase() + tab.slice(1)}` ? 'block' : 'none';
    });
    
    if (tab === 'remote') this.loadRemoteApps();
    else if (tab === 'registry') this.loadRegistry();
    else if (tab === 'pipeline') this.loadPipelineStatus();
  }
  
  async loadApps() {
    try {
      const response = await this.app.api.getHostedApps();
      this.apps = response.apps || [];
      this.renderApps();
    } catch (error) {
      this.renderError('localAppsGrid', error.message);
    }
  }
  
  async loadRemoteApps() {
    // Load remote apps if needed
  }
  
  async loadRegistry() {
    try {
      const response = await this.app.api.getRegistryApps();
      this.renderRegistry(response.apps || []);
    } catch (error) {
      this.renderError('registryAppsGrid', error.message);
    }
  }
  
  async loadPipelineStatus() {
    try {
      const status = await this.app.api.getPipelineStatus();
      this.renderPipelineStatus(status);
    } catch (error) {
      // Pipeline might be disabled
    }
  }
  
  renderApps() {
    const gridEl = this.container.querySelector('#localAppsGrid');
    
    if (this.apps.length === 0) {
      gridEl.innerHTML = `
        <div class="empty-state" style="grid-column: 1 / -1;">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect><rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect><line x1="6" y1="6" x2="6.01" y2="6"></line><line x1="6" y1="18" x2="6.01" y2="18"></line></svg>
          <h3>No apps deployed</h3>
          <p>Deploy your first app to get started</p>
        </div>
      `;
      return;
    }
    
    gridEl.innerHTML = this.apps.map(app => `
      <div class="app-card">
        <div class="app-card-header">
          <div class="app-card-info">
            <div class="app-card-name">
              ${this.escapeHtml(app.name)}
              <span class="app-card-kind">${app.kind}</span>
            </div>
            <div class="app-card-status">
              <span class="status-indicator status-${app.alive ? 'running' : 'stopped'}"></span>
              <span>${app.alive ? 'Running' : 'Stopped'}</span>
            </div>
          </div>
        </div>
        <div class="app-card-body">
          <div class="app-card-fields">
            <div class="app-field">
              <span class="app-field-label">Port</span>
              <span class="app-field-value">${app.port}</span>
            </div>
            <div class="app-field">
              <span class="app-field-label">PID</span>
              <span class="app-field-value">${app.pid || '—'}</span>
            </div>
            <div class="app-field">
              <span class="app-field-label">URL</span>
              <span class="app-field-value"><a href="http://localhost:${app.port}" target="_blank">http://localhost:${app.port}</a></span>
            </div>
          </div>
        </div>
        <div class="app-card-footer">
          ${app.alive ? `
            <button class="btn btn-secondary btn-sm app-action-btn" data-action="stop" data-name="${app.name}">Stop</button>
            <button class="btn btn-secondary btn-sm app-action-btn" data-action="restart" data-name="${app.name}">Restart</button>
          ` : `
            <button class="btn btn-primary btn-sm app-action-btn" data-action="start" data-name="${app.name}">Start</button>
          `}
          <button class="btn btn-secondary btn-sm app-action-btn" data-action="logs" data-name="${app.name}">Logs</button>
          <button class="btn btn-danger btn-sm app-action-btn" data-action="remove" data-name="${app.name}">Remove</button>
        </div>
      </div>
    `).join('');
    
    // Bind action events
    gridEl.querySelectorAll('.app-action-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const action = btn.dataset.action;
        const name = btn.dataset.name;
        this.handleAppAction(action, name);
      });
    });
  }
  
  renderRegistry(apps) {
    const gridEl = this.container.querySelector('#registryAppsGrid');
    
    if (!apps.length) {
      gridEl.innerHTML = `
        <div class="empty-state" style="grid-column: 1 / -1;">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"></polyline><rect x="1" y="3" width="22" height="5"></rect><line x1="10" y1="12" x2="14" y2="12"></line></svg>
          <h3>Registry empty</h3>
          <p>Register apps to track them</p>
        </div>
      `;
      return;
    }
    
    gridEl.innerHTML = apps.map(app => `
      <div class="app-card">
        <div class="app-card-header">
          <div class="app-card-info">
            <div class="app-card-name">${this.escapeHtml(app.name)}</div>
          </div>
        </div>
        <div class="app-card-body">
          <div class="app-card-fields">
            <div class="app-field">
              <span class="app-field-label">Container</span>
              <span class="app-field-value">${app.container_id?.slice(0, 12) || '—'}</span>
            </div>
            <div class="app-field">
              <span class="app-field-label">Image</span>
              <span class="app-field-value">${app.image || '—'}</span>
            </div>
            <div class="app-field">
              <span class="app-field-label">Host</span>
              <span class="app-field-value">${app.host || '—'}</span>
            </div>
            <div class="app-field">
              <span class="app-field-label">Monitor</span>
              <span class="app-field-value">${app.monitor ? 'Enabled' : 'Disabled'}</span>
            </div>
          </div>
        </div>
        <div class="app-card-footer">
          <button class="btn btn-secondary btn-sm" data-action="health" data-name="${app.name}">Health</button>
          <button class="btn btn-secondary btn-sm" data-action="restart" data-name="${app.name}">Restart</button>
          <button class="btn btn-secondary btn-sm" data-action="logs" data-name="${app.name}">Logs</button>
          <button class="btn btn-danger btn-sm" data-action="unregister" data-name="${app.name}">Unregister</button>
        </div>
      </div>
    `).join('');
  }
  
  renderPipelineStatus(status) {
    const el = this.container.querySelector('#pipelineStatus');
    if (!status || !status.last_execution) {
      el.style.display = 'none';
      return;
    }
    
    el.style.display = 'block';
    const exec = status.last_execution;
    el.innerHTML = `
      <div class="pipeline-status-card">
        <div class="pipeline-status-header">
          <h3 class="pipeline-status-title">Last Deployment</h3>
          <span class="pipeline-status-badge pipeline-status-${exec.status}">${exec.status}</span>
        </div>
        <div class="pipeline-status-details">
          <div class="pipeline-detail-item">
            <div class="pipeline-detail-label">App</div>
            <div class="pipeline-detail-value">${exec.app_name}</div>
          </div>
          <div class="pipeline-detail-item">
            <div class="pipeline-detail-label">Started</div>
            <div class="pipeline-detail-value">${new Date(exec.started_at).toLocaleString()}</div>
          </div>
          <div class="pipeline-detail-item">
            <div class="pipeline-detail-label">Duration</div>
            <div class="pipeline-detail-value">${exec.duration_ms}ms</div>
          </div>
          <div class="pipeline-detail-item">
            <div class="pipeline-detail-label">Steps</div>
            <div class="pipeline-detail-value">${exec.steps_completed}/${exec.total_steps}</div>
          </div>
        </div>
      </div>
    `;
  }
  
  showPipelineStep(step) {
    this.container.querySelectorAll('.pipeline-step').forEach(s => s.style.display = 'none');
    this.container.querySelector(`#step${step.charAt(0).toUpperCase() + step.slice(1)}`).style.display = 'block';
    this.container.querySelectorAll('.pipeline-step-circle').forEach((c, i) => {
      const steps = ['plan', 'confirm', 'execute'];
      c.classList.toggle('active', steps[i] === step);
    });
  }
  
  async handlePlanSubmit(e) {
    e.preventDefault();
    const form = e.target;
    const data = {
      app_name: form.querySelector('#pipeAppName').value,
      source_dir: form.querySelector('#pipeSourceDir').value,
      ports: JSON.parse(form.querySelector('#pipePorts').value || '{}'),
      env: JSON.parse(form.querySelector('#pipeEnv').value || '{}')
    };
    
    try {
      const plan = await this.app.api.planPipeline(data);
      this.showPipelinePlan(plan);
      this.showPipelineStep('confirm');
    } catch (error) {
      this.app.toast.error('Planning failed', error.message);
    }
  }
  
  showPipelinePlan(plan) {
    const el = this.container.querySelector('#pipelinePlan');
    el.innerHTML = `
      <div class="pipeline-plan-steps">
        ${plan.steps.map((step, i) => `
          <div class="pipeline-plan-step">
            <div class="pipeline-plan-step-number">${i + 1}</div>
            <div class="pipeline-plan-step-content">
              <div class="pipeline-plan-step-title">${step.name}</div>
              <div class="pipeline-plan-step-desc">${step.description}</div>
            </div>
          </div>
        `).join('')}
      </div>
    `;
  }
  
  async executePipeline() {
    this.showPipelineStep('execute');
    
    const form = this.container.querySelector('#pipelinePlanForm');
    const data = {
      app_name: form.querySelector('#pipeAppName').value,
      source_dir: form.querySelector('#pipeSourceDir').value,
      ports: JSON.parse(form.querySelector('#pipePorts').value || '{}'),
      env: JSON.parse(form.querySelector('#pipeEnv').value || '{}'),
      confirm: true
    };
    
    try {
      const result = await this.app.api.executePipeline(data);
      this.app.toast.success('Deployment completed');
      this.loadPipelineStatus();
      this.showPipelineStep('plan');
      form.reset();
    } catch (error) {
      this.app.toast.error('Deployment failed', error.message);
      this.showPipelineStep('confirm');
    }
  }
  
  async handleAppAction(action, name) {
    try {
      let result;
      switch (action) {
        case 'start': result = await this.app.api.startApp(name); break;
        case 'stop': result = await this.app.api.stopApp(name); break;
        case 'restart': result = await this.app.api.restartApp(name); break;
        case 'logs': this.openLogs(name); return;
        case 'remove': 
          const confirmed = await this.app.confirmDelete('app');
          if (confirmed) result = await this.app.api.removeApp(name);
          else return;
          break;
        case 'health': result = await this.app.api.healthCheckApp(name); break;
        case 'unregister': 
          const confirmed2 = await this.app.confirmDelete('app registration');
          if (confirmed2) result = await this.app.api.unregisterApp(name);
          else return;
          break;
      }
      
      if (result?.ok) {
        this.app.toast.success(`${action} successful`);
        this.loadApps();
      }
    } catch (error) {
      this.app.toast.error(`${action} failed`, error.message);
    }
  }
  
  openLogs(name) {
    // Open logs modal
  }
  
  async openDeployModal() {
    const modal = new this.app.Modal({
      title: 'Deploy Local App',
      size: 'large',
      onConfirm: async () => {
        // Implementation
        return true;
      }
    });
    
    modal.setContent(`
      <div class="form-group">
        <label class="form-label">Name</label>
        <input type="text" class="form-input" required placeholder="my-app">
      </div>
      <div class="form-group">
        <label class="form-label">Kind</label>
        <select class="form-select">
          <option value="python-asgi">Python ASGI</option>
          <option value="python">Python Script</option>
          <option value="node">Node.js</option>
          <option value="static">Static Files</option>
          <option value="command">Custom Command</option>
        </select>
      </div>
      <!-- More fields -->
    `);
    
    await modal.open();
  }
  
  async deployRemote() {
    const appName = this.container.querySelector('#remoteAppName').value;
    const image = this.container.querySelector('#remoteImage').value;
    const dockerfileDir = this.container.querySelector('#remoteDockerfile').value;
    const ports = JSON.parse(this.container.querySelector('#remotePorts').value || '{}');
    
    if (!appName || !image) {
      this.app.toast.error('App name and image are required');
      return;
    }
    
    try {
      const result = await this.app.api.remoteDeploy({ app: appName, image, dockerfile_dir: dockerfileDir, ports });
      this.app.toast.success('Remote deploy started');
    } catch (error) {
      this.app.toast.error('Remote deploy failed', error.message);
    }
  }
  
  renderError(containerId, message) {
    const el = this.container.querySelector(`#${containerId}`);
    el.innerHTML = `
      <div class="error-state" style="grid-column: 1 / -1;">
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
        <h3>Failed to load</h3>
        <p>${this.escapeHtml(message)}</p>
      </div>
    `;
  }
  
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  
  destroy() {}
}