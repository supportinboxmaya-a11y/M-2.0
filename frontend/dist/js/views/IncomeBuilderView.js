import { BaseView } from './BaseView.js';

export class IncomeBuilderView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Builder - Projects',
      apiEndpoint: 'getProjects',
      apiParams: { endpoint: '/api/v1/income/builder/projects' },
      showCreateButton: false,
      columns: [
        { key: 'title', label: 'Title' },
        { key: 'status', label: 'Status', render: (v) => `<span class="badge badge-${v === 'completed' ? 'success' : v === 'failed' ? 'error' : v === 'building' ? 'info' : 'warning'}">${v}</span>` },
        { key: 'current_step', label: 'Step', render: (v, row) => `${v} / ${row.total_steps}` },
        { key: 'deploy_url', label: 'Deploy URL', render: (v) => v ? `<a href="${v}" target="_blank">${v.slice(0, 40)}...</a>` : '—' },
        { key: 'created_at', label: 'Created', render: (v) => new Date(v * 1000).toLocaleDateString() }
      ],
      actions: [
        { key: 'view', label: 'View', icon: 'eye' },
        { key: 'retry', label: 'Retry', icon: 'refresh-cw', condition: (row) => row.status === 'failed' }
      ],
      emptyMessage: 'No build projects. Approve a plan first.'
    });
  }

  render() {
    super.render();
    this.container.querySelector('.view-header').innerHTML = `
      <h2>Builder - Projects</h2>
      <div style="display: flex; gap: var(--space-2); flex-wrap: wrap;">
        <button class="btn btn-secondary" id="statsBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="16"></line></svg> Stats</button>
        <select class="form-select" id="statusFilter" style="width: auto; min-width: 140px;">
          <option value="">All Statuses</option>
          <option value="building">Building</option>
          <option value="testing">Testing</option>
          <option value="completed">Completed</option>
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
      
      const response = await this.app.api.get(`/api/v1/income/builder/projects?${params}`);
      this.data = response.projects || [];
      this.renderTable();
    } catch (error) {
      console.error('Failed to load projects:', error);
      this.app.toast.error('Failed to load projects', error.message);
    }
  }

  async handleAction(action, row) {
    if (action === 'view') {
      this.showProjectDetail(row);
    } else if (action === 'retry') {
      this.retryProject(row.id);
    }
  }

  async showProjectDetail(row) {
    const modal = new this.app.Modal({
      title: row.title,
      size: 'large',
      onConfirm: () => true
    });
    
    let stepsHtml = '';
    if (row.steps && row.steps.length) {
      stepsHtml = `
        <div class="form-group"><label class="form-label">Build Steps</label>
          <div class="table-container">
            <table class="data-table">
              <thead><tr><th>Step</th><th>Type</th><th>Status</th><th>Started</th><th>Completed</th><th>Error</th></tr></thead>
              <tbody>
                ${row.steps.map(s => `
                  <tr>
                    <td>${s.step_type}</td>
                    <td>${s.description}</td>
                    <td><span class="badge badge-${s.status === 'completed' ? 'success' : s.status === 'failed' ? 'error' : s.status === 'running' ? 'info' : 'warning'}">${s.status}</span></td>
                    <td>${s.started_at ? new Date(s.started_at * 1000).toLocaleString() : '—'}</td>
                    <td>${s.completed_at ? new Date(s.completed_at * 1000).toLocaleString() : '—'}</td>
                    <td>${s.error || '—'}</td>
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
          <div class="stat-card"><div class="stat-value">${row.current_step} / ${row.total_steps}</div><div class="stat-label">Progress</div></div>
          <div class="stat-card"><div class="stat-value">${row.iteration || 1}</div><div class="stat-label">Iteration</div></div>
          <div class="stat-card"><div class="stat-value">${row.deploy_url ? 'Yes' : 'No'}</div><div class="stat-label">Deployed</div></div>
        </div>
        <div class="form-group"><label class="form-label">MVP Scope</label><div>${Array.isArray(row.mvp_scope) ? row.mvp_scope.map(s => `<div>• ${this.escapeHtml(s)}</div>`).join('') : this.escapeHtml(row.mvp_scope)}</div></div>
        <div class="form-group"><label class="form-label">Technical Approach</label><div class="form-textarea" readonly>${this.escapeHtml(row.technical_approach)}</div></div>
        <div class="form-group"><label class="form-label">Timeline</label><div>${Array.isArray(row.timeline) ? row.timeline.map(s => `<div>• ${this.escapeHtml(s)}</div>`).join('') : this.escapeHtml(row.timeline)}</div></div>
        ${row.deploy_url ? `<div class="form-group"><label class="form-label">Deploy URL</label><div><a href="${row.deploy_url}" target="_blank">${this.escapeHtml(row.deploy_url)}</a></div></div>` : ''}
        ${row.error ? `<div class="form-group"><label class="form-label">Error</label><div class="form-textarea error" readonly>${this.escapeHtml(row.error)}</div></div>` : ''}
        ${stepsHtml}
      </div>
    `);
    await modal.open();
  }

  async retryProject(projectId) {
    try {
      await this.app.api.post(`/api/v1/income/builder/projects/${projectId}/status`, { status: 'retry' });
      this.app.toast.success('Project retry initiated');
      this.loadData();
    } catch (error) {
      this.app.toast.error('Retry failed', error.message);
    }
  }

  async showStats() {
    try {
      const response = await this.app.api.get('/api/v1/income/builder/stats');
      
      const modal = new this.app.Modal({
        title: 'Builder Statistics',
        size: 'medium',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="stat-grid">
          <div class="stat-card"><div class="stat-value">${response.total_projects || 0}</div><div class="stat-label">Total Projects</div></div>
          <div class="stat-card"><div class="stat-value">${response.active_projects || 0}</div><div class="stat-label">Active</div></div>
          <div class="stat-card"><div class="stat-value">${response.total_steps || 0}</div><div class="stat-label">Total Steps</div></div>
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
