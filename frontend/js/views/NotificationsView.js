import { BaseView } from './BaseView.js';

export class NotificationsView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Notifications',
      apiEndpoint: 'getNotifications',
      apiParams: { endpoint: '/api/v1/income/notifications/stats' },
      showCreateButton: false,
      columns: [
        { key: 'type', label: 'Type', render: (v) => v },
        { key: 'priority', label: 'Priority', render: (v) => `<span class="badge badge-${v === 'critical' ? 'error' : v === 'high' ? 'warning' : 'info'}">${v}</span>` },
        { key: 'title', label: 'Title' },
        { key: 'status', label: 'Status', render: (v) => `<span class="badge badge-${v === 'sent' ? 'success' : v === 'failed' ? 'error' : 'warning'}">${v}</span>` },
        { key: 'created_at', label: 'Created', render: (v) => new Date(v * 1000).toLocaleString() }
      ],
      actions: [
        { key: 'view', label: 'View', icon: 'eye' }
      ],
      emptyMessage: 'No notifications sent yet.'
    });
  }

  render() {
    super.render();
    this.container.querySelector('.view-header').innerHTML = `
      <h2>Notifications</h2>
      <div style="display: flex; gap: var(--space-2); flex-wrap: wrap;">
        <button class="btn btn-secondary" id="statsBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="16"></line></svg> Stats</button>
        <button class="btn btn-secondary" id="channelsBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg> Channels</button>
        <button class="btn btn-secondary" id="templatesBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg> Templates</button>
        <select class="form-select" id="typeFilter" style="width: auto; min-width: 160px;">
          <option value="">All Types</option>
          <option value="approval_request">Approval Request</option>
          <option value="builder_status">Builder Status</option>
          <option value="launch_ready">Launch Ready</option>
          <option value="error_alert">Error Alert</option>
          <option value="daily_digest">Daily Digest</option>
        </select>
      </div>
    `;
    this.bindFilterEvents();
  }

  bindFilterEvents() {
    this.container.querySelector('#statsBtn').addEventListener('click', () => this.showStats());
    this.container.querySelector('#channelsBtn').addEventListener('click', () => this.showChannels());
    this.container.querySelector('#templatesBtn').addEventListener('click', () => this.showTemplates());
    this.container.querySelector('#typeFilter').addEventListener('change', () => this.loadData());
  }

  async loadData() {
    const type = this.container.querySelector('#typeFilter').value;
    
    try {
      const params = new URLSearchParams();
      if (type) params.append('type', type);
      
      // The notifications API uses a different endpoint structure
      const response = await this.app.api.get(`/api/v1/income/notifications/stats`);
      // The stats endpoint returns stats, not list. We need a different endpoint.
      // Let's try the generic list endpoint
      const listResponse = await this.app.api.get(`/api/v1/income/notifications/notifications`);
      this.data = listResponse.notifications || [];
      this.renderTable();
    } catch (error) {
      console.error('Failed to load notifications:', error);
      // Fallback to empty table
      this.data = [];
      this.renderTable();
    }
  }

  async showStats() {
    try {
      const response = await this.app.api.get('/api/v1/income/notifications/stats');
      
      const modal = new this.app.Modal({
        title: 'Notification Statistics',
        size: 'medium',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="stat-grid">
          <div class="stat-card"><div class="stat-value">${response.total_notifications || 0}</div><div class="stat-label">Total Sent</div></div>
        </div>
        <div style="margin-top: var(--space-4);">
          <h4>By Status</h4>
          <div class="stat-grid">
            ${(response.by_status || []).map(r => `
              <div class="stat-card"><div class="stat-value">${r.count}</div><div class="stat-label">${r.status}</div></div>
            `).join('')}
          </div>
        </div>
        <div style="margin-top: var(--space-4);">
          <h4>By Type</h4>
          <div class="stat-grid">
            ${(response.by_type || []).map(r => `
              <div class="stat-card"><div class="stat-value">${r.count}</div><div class="stat-label">${r.type}</div></div>
            `).join('')}
          </div>
        </div>
        <div style="margin-top: var(--space-4);">
          <h4>By Priority</h4>
          <div class="stat-grid">
            ${(response.by_priority || []).map(r => `
              <div class="stat-card"><div class="stat-value">${r.count}</div><div class="stat-label">${r.priority}</div></div>
            `).join('')}
          </div>
        </div>
        <div style="margin-top: var(--space-4);">
          <h4>Recent Notifications</h4>
          <div class="table-container">
            <table class="data-table">
              <thead><tr><th>Title</th><th>Type</th><th>Priority</th><th>Status</th><th>Created</th></tr></thead>
              <tbody>
                ${(response.recent || []).map(n => `
                  <tr>
                    <td>${this.escapeHtml(n.title)}</td>
                    <td>${n.type}</td>
                    <td><span class="badge badge-${n.priority === 'critical' ? 'error' : n.priority === 'high' ? 'warning' : 'info'}">${n.priority}</span></td>
                    <td><span class="badge badge-${n.status === 'sent' ? 'success' : n.status === 'failed' ? 'error' : 'warning'}">${n.status}</span></td>
                    <td>${new Date(n.created_at * 1000).toLocaleString()}</td>
                  </tr>
                `).join('') || '<tr><td colspan="5" class="empty-state">No recent notifications</td></tr>'}
              </tbody>
            </table>
          </div>
        </div>
      `);
      await modal.open();
    } catch (error) {
      this.app.toast.error('Failed to load stats', error.message);
    }
  }

  async showChannels() {
    try {
      const response = await this.app.api.get('/api/v1/income/notifications/channels');
      
      const modal = new this.app.Modal({
        title: 'Notification Channels',
        size: 'medium',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="channels-grid">
          ${Object.entries(response.channels || {}).map(([name, cfg]) => `
            <div class="channel-card" style="border: 1px solid var(--border); border-radius: var(--radius); padding: var(--space-4);">
              <h4>${name}</h4>
              <div class="status-badge ${cfg.enabled ? 'success' : 'error'}">${cfg.enabled ? 'Enabled' : 'Disabled'}</div>
              <div style="margin-top: var(--space-2); font-size: var(--text-sm); color: var(--text-tertiary);">
                Configured: ${cfg.configured ? 'Yes' : 'No'}
              </div>
            </div>
          `).join('')}
        </div>
      `);
      await modal.open();
    } catch (error) {
      this.app.toast.error('Failed to load channels', error.message);
    }
  }

  async showTemplates() {
    try {
      const response = await this.app.api.get('/api/v1/income/notifications/templates');
      
      const modal = new this.app.Modal({
        title: 'Notification Templates',
        size: 'large',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="view-header">
          <h2>Templates</h2>
          <button class="btn btn-primary" id="createTemplateBtn">Create Template</button>
        </div>
        <div class="table-container">
          <table class="data-table">
            <thead><tr><th>Name</th><th>Subject</th><th>Channels</th></tr></thead>
            <tbody>
              ${(response.templates || []).map(t => `
                <tr>
                  <td><strong>${this.escapeHtml(t.name)}</strong></td>
                  <td>${this.escapeHtml(t.subject_template.slice(0, 60))}...</td>
                  <td>${(t.channels || []).join(', ')}</td>
                </tr>
              `).join('') || '<tr><td colspan="3" class="empty-state">No templates</td></tr>'}
            </tbody>
          </table>
        </div>
      `);
      await modal.open();
    } catch (error) {
      this.app.toast.error('Failed to load templates', error.message);
    }
  }
}
