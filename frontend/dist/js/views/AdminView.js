// Maya 2.0 ULTRA - Admin View
export class AdminView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.currentTab = 'overview';
  }
  
  show() {
    if (!auth.isAdmin()) {
      this.app.toast.error('Access denied', 'Admin privileges required');
      window.location.hash = '#chat';
      return;
    }
    
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view admin-view';
      this.render();
      this.bindEvents();
      this.loadData();
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
      <div class="admin-header">
        <h2>Admin Panel</h2>
      </div>
      
      <div class="admin-tabs" id="adminTabs">
        <button class="admin-tab active" data-tab="overview">Overview</button>
        <button class="admin-tab" data-tab="users">Users</button>
        <button class="admin-tab" data-tab="orgs">Organizations</button>
        <button class="admin-tab" data-tab="apikeys">API Keys</button>
        <button class="admin-tab" data-tab="audit">Audit Log</button>
        <button class="admin-tab" data-tab="usage">Usage</button>
      </div>
      
      <div class="admin-tab-panel active" id="panelOverview">
        <div class="admin-dashboard-grid" id="adminDashboard">
          <div class="loading-state"><div class="spinner"></div><p>Loading dashboard...</p></div>
        </div>
      </div>
      
      <div class="admin-tab-panel" id="panelUsers" style="display: none;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4);">
          <h3>Users</h3>
        </div>
        <div class="users-table-container">
          <table class="table" id="usersTable">
            <thead>
              <tr>
                <th>Email</th>
                <th>Name</th>
                <th>Role</th>
                <th>Budget</th>
                <th>Used</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody id="usersTableBody">
              <tr><td colspan="7" style="text-align: center;"><div class="loading-state"><div class="spinner"></div></div></td></tr>
            </tbody>
          </table>
        </div>
      </div>
      
      <div class="admin-tab-panel" id="panelOrgs" style="display: none;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4);">
          <h3>Organizations</h3>
          <button class="btn btn-primary" id="createOrgBtn">Create Org</button>
        </div>
        <div class="orgs-list" id="orgsList">
          <div class="loading-state"><div class="spinner"></div><p>Loading organizations...</p></div>
        </div>
      </div>
      
      <div class="admin-tab-panel" id="panelApikeys" style="display: none;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4);">
          <h3>API Keys</h3>
          <button class="btn btn-primary" id="createApiKeyBtn">Create Key</button>
        </div>
        <div class="api-keys-list" id="apiKeysList">
          <div class="loading-state"><div class="spinner"></div><p>Loading API keys...</p></div>
        </div>
      </div>
      
      <div class="admin-tab-panel" id="panelAudit" style="display: none;">
        <div class="audit-filters">
          <div class="audit-filter-group">
            <label class="audit-filter-label">Actor</label>
            <input type="text" class="form-input" id="auditActor" placeholder="Filter by actor">
          </div>
          <div class="audit-filter-group">
            <label class="audit-filter-label">Action</label>
            <input type="text" class="form-input" id="auditAction" placeholder="Filter by action">
          </div>
          <div class="audit-filter-group">
            <label class="audit-filter-label">Limit</label>
            <input type="number" class="form-input" id="auditLimit" value="100" min="1" max="1000">
          </div>
        </div>
        <div class="audit-table-container">
          <table class="table" id="auditTable">
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>Actor</th>
                <th>Action</th>
                <th>Target</th>
                <th>Details</th>
              </tr>
            </thead>
            <tbody id="auditTableBody">
              <tr><td colspan="5" style="text-align: center;"><div class="loading-state"><div class="spinner"></div></div></td></tr>
            </tbody>
          </table>
        </div>
      </div>
      
      <div class="admin-tab-panel" id="panelUsage" style="display: none;">
        <div class="usage-stats" id="usageStats">
          <div class="loading-state"><div class="spinner"></div></div>
        </div>
        <div class="usage-charts" id="usageCharts">
          <div class="usage-chart-card">
            <h4 class="usage-chart-title">Requests Over Time</h4>
            <div class="usage-chart" id="requestsChart"></div>
          </div>
          <div class="usage-chart-card">
            <h4 class="usage-chart-title">Cost by Provider</h4>
            <div class="usage-chart" id="costChart"></div>
          </div>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    this.container.querySelectorAll('.admin-tab').forEach(tab => {
      tab.addEventListener('click', () => this.setTab(tab.dataset.tab));
    });
    
    this.container.querySelector('#createOrgBtn').addEventListener('click', () => this.openCreateOrgModal());
    this.container.querySelector('#createApiKeyBtn').addEventListener('click', () => this.openCreateApiKeyModal());
    
    this.container.querySelector('#auditActor').addEventListener('input', this.debounce(() => this.loadAudit(), 300));
    this.container.querySelector('#auditAction').addEventListener('input', this.debounce(() => this.loadAudit(), 300));
    this.container.querySelector('#auditLimit').addEventListener('change', () => this.loadAudit());
  }
  
  debounce(fn, delay) {
    let timeoutId;
    return (...args) => {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => fn(...args), delay);
    };
  }
  
  setTab(tab) {
    this.currentTab = tab;
    this.container.querySelectorAll('.admin-tab').forEach(t => {
      t.classList.toggle('active', t.dataset.tab === tab);
    });
    this.container.querySelectorAll('.admin-tab-panel').forEach(p => {
      p.style.display = p.id === `panel${tab.charAt(0).toUpperCase() + tab.slice(1)}` ? 'block' : 'none';
    });
    
    if (tab === 'overview') this.loadDashboard();
    else if (tab === 'users') this.loadUsers();
    else if (tab === 'orgs') this.loadOrgs();
    else if (tab === 'apikeys') this.loadApiKeys();
    else if (tab === 'audit') this.loadAudit();
    else if (tab === 'usage') this.loadUsage();
  }
  
  async loadData() {
    await Promise.all([
      this.loadDashboard(),
      this.loadUsers(),
      this.loadOrgs(),
      this.loadApiKeys()
    ]);
  }
  
  async loadDashboard() {
    try {
      const dashboard = await this.app.api.getAdminDashboard();
      this.renderDashboard(dashboard);
    } catch (error) {
      console.error('Failed to load dashboard:', error);
    }
  }
  
  renderDashboard(dashboard) {
    const el = this.container.querySelector('#adminDashboard');
    if (!dashboard) {
      el.innerHTML = '<div class="empty-state"><h3>No dashboard data</h3></div>';
      return;
    }
    
    el.innerHTML = `
      <div class="dashboard-card">
        <h4 class="dashboard-card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg> Users</h4>
        <div class="dashboard-metric">
          <div class="dashboard-metric-value">${dashboard.total_users || 0}</div>
          <div class="dashboard-metric-label">Total Users</div>
        </div>
      </div>
      <div class="dashboard-card">
        <h4 class="dashboard-card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg> Organizations</h4>
        <div class="dashboard-metric">
          <div class="dashboard-metric-value">${dashboard.total_orgs || 0}</div>
          <div class="dashboard-metric-label">Total Organizations</div>
        </div>
      </div>
      <div class="dashboard-card">
        <h4 class="dashboard-card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"></path><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3"></path></svg> API Keys</h4>
        <div class="dashboard-metric">
          <div class="dashboard-metric-value">${dashboard.total_keys || 0}</div>
          <div class="dashboard-metric-label">Active Keys</div>
        </div>
      </div>
      <div class="dashboard-card">
        <h4 class="dashboard-card-title"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg> Audit Events (24h)</h4>
        <div class="dashboard-metric">
          <div class="dashboard-metric-value">${dashboard.audit_events_24h || 0}</div>
          <div class="dashboard-metric-label">Recent Events</div>
        </div>
      </div>
    `;
  }
  
  async loadUsers() {
    try {
      const response = await this.app.api.getAdminUsers();
      this.renderUsers(response.users || []);
    } catch (error) {
      console.error('Failed to load users:', error);
    }
  }
  
  renderUsers(users) {
    const tbody = this.container.querySelector('#usersTableBody');
    
    if (!users.length) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: var(--text-tertiary);">No users found</td></tr>';
      return;
    }
    
    tbody.innerHTML = users.map(user => `
      <tr>
        <td>${this.escapeHtml(user.email)}</td>
        <td>${this.escapeHtml(user.name || '—')}</td>
        <td><span class="user-role user-role-${user.role}">${user.role}</span></td>
        <td>${user.budget_usd ? '$' + user.budget_usd.toFixed(2) : '—'}</td>
        <td class="${user.budget_used_usd && user.budget_usd && user.budget_used_usd > user.budget_usd * 0.8 ? 'warning' : ''}">${user.budget_used_usd ? '$' + user.budget_used_usd.toFixed(2) : '$0.00'}</td>
        <td>${user.banned ? '<span class="user-banned">Banned</span>' : '<span style="color: var(--success);">Active</span>'}</td>
        <td>
          <div class="user-actions">
            <button class="btn btn-sm btn-secondary" data-action="ban" data-id="${user.id}" data-banned="${user.banned}">
              ${user.banned ? 'Unban' : 'Ban'}
            </button>
            <button class="btn btn-sm btn-secondary" data-action="budget" data-id="${user.id}">Budget</button>
          </div>
        </td>
      </tr>
    `).join('');
    
    // Bind actions
    this.container.querySelectorAll('#usersTableBody [data-action="ban"]').forEach(btn => {
      btn.addEventListener('click', () => this.toggleUserBan(btn.dataset.id, btn.dataset.banned === 'true'));
    });
    this.container.querySelectorAll('#usersTableBody [data-action="budget"]').forEach(btn => {
      btn.addEventListener('click', () => this.openBudgetModal(btn.dataset.id));
    });
  }
  
  async loadOrgs() {
    try {
      const response = await this.app.api.getAdminOrgs();
      this.renderOrgs(response.orgs || []);
    } catch (error) {
      console.error('Failed to load orgs:', error);
    }
  }
  
  renderOrgs(orgs) {
    const el = this.container.querySelector('#orgsList');
    
    if (!orgs.length) {
      el.innerHTML = '<div class="empty-state"><h3>No organizations</h3><p>Create your first organization</p></div>';
      return;
    }
    
    el.innerHTML = orgs.map(org => `
      <div class="org-card">
        <div class="org-card-header">
          <div class="org-name">${this.escapeHtml(org.name)}</div>
          <span class="org-id">${org.id}</span>
        </div>
        <div class="org-card-body">
          <div class="org-members">
            ${(org.members || []).slice(0, 5).map(member => `
              <div class="org-member">
                <div class="org-member-info">
                  <span class="org-member-email">${member.email}</span>
                  <span class="org-member-role org-member-role-${member.role}">${member.role}</span>
                </div>
              </div>
            `).join('')}
            ${org.members && org.members.length > 5 ? `<div class="org-member" style="color: var(--text-tertiary);">+${org.members.length - 5} more</div>` : ''}
          </div>
          <div class="org-teams">
            ${(org.teams || []).map(team => `
              <div class="org-team">
                <span class="org-team-name">${team.name}</span>
                <span>${team.member_count || 0} members</span>
              </div>
            `).join('')}
          </div>
        </div>
      </div>
    `).join('');
  }
  
  async loadApiKeys() {
    try {
      const response = await this.app.api.getApiKeys();
      this.renderApiKeys(response.keys || []);
    } catch (error) {
      console.error('Failed to load API keys:', error);
    }
  }
  
  renderApiKeys(keys) {
    const el = this.container.querySelector('#apiKeysList');
    
    if (!keys.length) {
      el.innerHTML = '<div class="empty-state"><h3>No API keys</h3><p>Create your first API key</p></div>';
      return;
    }
    
    el.innerHTML = keys.map(key => `
      <div class="api-key-card">
        <div class="api-key-header">
          <div class="api-key-name">${this.escapeHtml(key.name)}</div>
          <div class="api-key-meta">
            <span>Created: ${new Date(key.created_at).toLocaleDateString()}</span>
            <span>Last used: ${key.last_used ? new Date(key.last_used).toLocaleDateString() : 'Never'}</span>
          </div>
        </div>
        <div class="api-key-value">${key.key_preview || '••••••••'}</div>
        <button class="btn btn-danger btn-sm" data-action="revoke" data-id="${key.id}">Revoke</button>
      </div>
    `).join('');
    
    this.container.querySelectorAll('#apiKeysList [data-action="revoke"]').forEach(btn => {
      btn.addEventListener('click', () => this.revokeApiKey(btn.dataset.id));
    });
  }
  
  async loadAudit() {
    try {
      const actor = this.container.querySelector('#auditActor').value;
      const action = this.container.querySelector('#auditAction').value;
      const limit = parseInt(this.container.querySelector('#auditLimit').value) || 100;
      
      const response = await this.app.api.getAuditLog(actor, action, limit);
      this.renderAudit(response.events || []);
    } catch (error) {
      console.error('Failed to load audit:', error);
    }
  }
  
  renderAudit(events) {
    const tbody = this.container.querySelector('#auditTableBody');
    
    if (!events.length) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; color: var(--text-tertiary);">No audit events found</td></tr>';
      return;
    }
    
    tbody.innerHTML = events.map(event => `
      <tr>
        <td>${new Date(event.timestamp).toLocaleString()}</td>
        <td>${this.escapeHtml(event.actor)}</td>
        <td><span class="audit-action">${event.action}</span></td>
        <td>${this.escapeHtml(event.target || '—')}</td>
        <td style="font-family: var(--font-mono); font-size: var(--text-xs); max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${this.escapeHtml(JSON.stringify(event.metadata || {}))}</td>
      </tr>
    `).join('');
  }
  
  async loadUsage() {
    try {
      const usage = await this.app.api.getUsage();
      this.renderUsage(usage);
    } catch (error) {
      console.error('Failed to load usage:', error);
    }
  }
  
  renderUsage(usage) {
    const statsEl = this.container.querySelector('#usageStats');
    const chartsEl = this.container.querySelector('#usageCharts');
    
    if (!usage) {
      statsEl.innerHTML = '<div class="empty-state"><h3>No usage data</h3></div>';
      return;
    }
    
    statsEl.innerHTML = `
      <div class="usage-stat-card">
        <div class="usage-stat-value">${usage.total_requests || 0}</div>
        <div class="usage-stat-label">Total Requests</div>
      </div>
      <div class="usage-stat-card">
        <div class="usage-stat-value">$${(usage.total_cost_usd || 0).toFixed(4)}</div>
        <div class="usage-stat-label">Total Cost</div>
      </div>
      <div class="usage-stat-card">
        <div class="usage-stat-value">${usage.total_tokens || 0}</div>
        <div class="usage-stat-label">Total Tokens</div>
      </div>
      <div class="usage-stat-card">
        <div class="usage-stat-value">${usage.active_users || 0}</div>
        <div class="usage-stat-label">Active Users</div>
      </div>
    `;
    
    // Render charts
    this.renderUsageCharts(usage);
  }
  
  renderUsageCharts(usage) {
    // Simple bar chart for requests over time
    const requestsChart = this.container.querySelector('#requestsChart');
    if (requestsChart && usage.daily_requests) {
      new this.app.Chart(requestsChart, {
        type: 'bar',
        data: usage.daily_requests.map(d => d.requests),
        labels: usage.daily_requests.map(d => d.date),
        height: 200
      });
    }
    
    // Cost by provider pie chart
    const costChart = this.container.querySelector('#costChart');
    if (costChart && usage.cost_by_provider) {
      new this.app.Chart(costChart, {
        type: 'pie',
        data: Object.values(usage.cost_by_provider),
        labels: Object.keys(usage.cost_by_provider),
        height: 200
      });
    }
  }
  
  async openCreateOrgModal() {
    const modal = new this.app.Modal({
      title: 'Create Organization',
      size: 'medium',
      onConfirm: async () => {
        const name = modal.element.querySelector('#orgName').value.trim();
        if (!name) { this.app.toast.error('Name is required'); return false; }
        
        try {
          await this.app.api.createAdminOrg(name);
          this.app.toast.success('Organization created');
          this.loadOrgs();
          return true;
        } catch (error) {
          this.app.toast.error('Failed to create org', error.message);
          return false;
        }
      }
    });
    
    modal.setContent(`
      <div class="form-group">
        <label class="form-label" for="orgName">Organization Name <span class="required">*</span></label>
        <input type="text" class="form-input" id="orgName" placeholder="My Organization" required>
      </div>
    `);
    await modal.open();
  }
  
  async openCreateApiKeyModal() {
    const modal = new this.app.Modal({
      title: 'Create API Key',
      size: 'medium',
      onConfirm: async () => {
        const name = modal.element.querySelector('#keyName').value.trim();
        if (!name) { this.app.toast.error('Name is required'); return false; }
        
        try {
          const key = await this.app.api.createApiKey(name);
          this.app.toast.success('API key created');
          this.app.toast.info('Save this key: ' + key.key);
          this.loadApiKeys();
          return true;
        } catch (error) {
          this.app.toast.error('Failed to create key', error.message);
          return false;
        }
      }
    });
    
    modal.setContent(`
      <div class="form-group">
        <label class="form-label" for="keyName">Key Name <span class="required">*</span></label>
        <input type="text" class="form-input" id="keyName" placeholder="Production Key" required>
      </div>
    `);
    await modal.open();
  }
  
  async revokeApiKey(keyId) {
    const confirmed = await this.app.confirmDelete('API key');
    if (!confirmed) return;
    
    try {
      await this.app.api.revokeApiKey(keyId);
      this.app.toast.success('API key revoked');
      this.loadApiKeys();
    } catch (error) {
      this.app.toast.error('Failed to revoke key', error.message);
    }
  }
  
  async toggleUserBan(userId, currentlyBanned) {
    try {
      await this.app.api.banUser(userId, !currentlyBanned);
      this.app.toast.success(`User ${currentlyBanned ? 'unbanned' : 'banned'}`);
      this.loadUsers();
    } catch (error) {
      this.app.toast.error('Failed to update user', error.message);
    }
  }
  
  async openBudgetModal(userId) {
    const modal = new this.app.Modal({
      title: 'Set User Budget',
      size: 'small',
      onConfirm: async () => {
        const budget = parseFloat(modal.element.querySelector('#userBudget').value);
        if (isNaN(budget) || budget < 0) { this.app.toast.error('Valid budget required'); return false; }
        
        try {
          await this.app.api.setUserBudget(userId, budget);
          this.app.toast.success('Budget updated');
          this.loadUsers();
          return true;
        } catch (error) {
          this.app.toast.error('Failed to set budget', error.message);
          return false;
        }
      }
    });
    
    modal.setContent(`
      <div class="form-group">
        <label class="form-label" for="userBudget">Budget (USD)</label>
        <input type="number" class="form-input" id="userBudget" step="0.01" min="0" placeholder="5.00">
      </div>
    `);
    await modal.open();
  }
  
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  
  destroy() {}
}