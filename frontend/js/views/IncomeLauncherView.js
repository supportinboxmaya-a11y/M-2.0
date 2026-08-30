import { BaseView } from './BaseView.js';

export class IncomeLauncherView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Launcher - Launches',
      apiEndpoint: 'getLaunches',
      apiParams: { endpoint: '/api/v1/income/launcher/launches' },
      showCreateButton: false,
      columns: [
        { key: 'title', label: 'Title' },
        { key: 'status', label: 'Status', render: (v) => `<span class="badge badge-${v === 'live' ? 'success' : v === 'failed' ? 'error' : v === 'launching' ? 'info' : 'warning'}">${v}</span>` },
        { key: 'subdomain', label: 'Subdomain', render: (v) => v ? `${v}.maya.app` : '—' },
        { key: 'launch_url', label: 'URL', render: (v) => v ? `<a href="${v}" target="_blank">${v.slice(0, 40)}...</a>` : '—' },
        { key: 'launched_at', label: 'Launched', render: (v) => v ? new Date(v * 1000).toLocaleDateString() : '—' }
      ],
      actions: [
        { key: 'view', label: 'View', icon: 'eye' },
        { key: 'retry', label: 'Retry', icon: 'refresh-cw', condition: (row) => row.status === 'failed' }
      ],
      emptyMessage: 'No launches. Complete a build project first.'
    });
  }

  render() {
    super.render();
    this.container.querySelector('.view-header').innerHTML = `
      <h2>Launcher - Launches</h2>
      <div style="display: flex; gap: var(--space-2); flex-wrap: wrap;">
        <button class="btn btn-secondary" id="statsBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="16"></line></svg> Stats</button>
        <select class="form-select" id="statusFilter" style="width: auto; min-width: 140px;">
          <option value="">All Statuses</option>
          <option value="draft">Draft</option>
          <option value="ready">Ready</option>
          <option value="launching">Launching</option>
          <option value="live">Live</option>
          <option value="failed">Failed</option>
        </select>
      </div>
    `;
    this.bindFilterEvents();
  }

  bindFilterEvents() {
    this.container.querySelector('#statsBtn').addEventListener('click', () => this.showStats());
    this.container.querySelector('#statusFilter').addEventListener('change', () => this.loadData());
  }

  async loadData() {
    const status = this.container.querySelector('#statusFilter').value;
    
    try {
      const params = new URLSearchParams();
      if (status) params.append('status', status);
      
      const response = await this.app.api.get(`/api/v1/income/launcher/launches?${params}`);
      this.data = response.launches || [];
      this.renderTable();
    } catch (error) {
      console.error('Failed to load launches:', error);
      this.app.toast.error('Failed to load launches', error.message);
    }
  }

  async handleAction(action, row) {
    if (action === 'view') {
      this.showLaunchDetail(row);
    } else if (action === 'retry') {
      this.retryLaunch(row.id);
    }
  }

  async showLaunchDetail(row) {
    const modal = new this.app.Modal({
      title: row.title,
      size: 'large',
      onConfirm: () => true
    });
    
    let contentHtml = '';
    if (row.content && row.content.length) {
      contentHtml = `
        <div class="form-group"><label class="form-label">Launch Content</label>
          <div class="table-container">
            <table class="data-table">
              <thead><tr><th>Type</th><th>Title</th><th>Status</th><th>Platform URL</th></tr></thead>
              <tbody>
                ${row.content.map(c => `
                  <tr>
                    <td>${c.content_type}</td>
                    <td>${this.escapeHtml(c.title)}</td>
                    <td><span class="badge badge-${c.status === 'approved' ? 'success' : c.status === 'rejected' ? 'error' : 'warning'}">${c.status}</span></td>
                    <td>${c.platform_url ? `<a href="${c.platform_url}" target="_blank">View</a>` : '—'}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>
      `;
    }
    
    const modal = new this.app.Modal({
      title: row.title,
      size: 'large',
      onConfirm: () => true
    });
    
    modal.setContent(`
      <div style="max-height: 70vh; overflow-y: auto;">
        <div class="stat-grid" style="margin-bottom: var(--space-4);">
          <div class="stat-card"><div class="stat-value">${row.subdomain || '—'}</div><div class="stat-label">Subdomain</div></div>
          <div class="stat-card"><div class="stat-value">${row.launch_url ? 'Yes' : 'No'}</div><div class="stat-label">Launch URL</div></div>
        </div>
        <div class="form-group"><label class="form-label">Description</label><div class="form-textarea" readonly>${this.escapeHtml(row.description)}</div></div>
        ${row.launch_url ? `<div class="form-group"><label class="form-label">Launch URL</label><div><a href="${row.launch_url}" target="_blank">${this.escapeHtml(row.launch_url)}</a></div></div>` : ''}
        ${row.domain ? `<div class="form-group"><label class="form-label">Custom Domain</label><div>${this.escapeHtml(row.domain)}</div></div>` : ''}
        ${row.launch_date ? `<div class="form-group"><label class="form-label">Scheduled Launch</label><div>${new Date(row.launch_date * 1000).toLocaleString()}</div></div>` : ''}
        ${contentHtml}
        ${row.error ? `<div class="form-group"><label class="form-label">Error</label><div class="form-textarea error" readonly>${this.escapeHtml(row.error)}</div></div>` : ''}
      </div>
    `);
    await modal.open();
  }

  async retryLaunch(launchId) {
    try {
      await this.app.api.post(`/api/v1/income/launcher/launches/${launchId}/retry`, {});
      this.app.toast.success('Launch retry initiated');
      this.loadData();
    } catch (error) {
      this.app.toast.error('Retry failed', error.message);
    }
  }

  async showStats() {
    try {
      const response = await this.app.api.get('/api/v1/income/launcher/stats');
      
      const modal = new this.app.Modal({
        title: 'Launcher Statistics',
        size: 'medium',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="stat-grid">
          <div class="stat-card"><div class="stat-value">${response.total_launches || 0}</div><div class="stat-label">Total Launches</div></div>
          <div class="stat-card"><div class="stat-value">${response.content_approved || 0}</div><div class="stat-label">Content Approved</div></div>
        </div>
        <div style="margin-top: var(--space-4);">
          <h4>By Status</h4>
          <div class="stat-grid">
            ${Object.entries(response.by_status || {}).map(([status, count]) => `
              <div class="stat-card"><div class="stat-value">${count}</div><div class="stat-label">${status}</div></div>
            `).join('')}
          </div>
        </div>
      `);
      await modal.open();
    } catch (error) {
      this.app.toast.error('Failed to load stats', error.message);
    }
  }
}
