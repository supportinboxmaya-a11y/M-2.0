import { BaseView } from './BaseView.js';

export class IncomeGrowthView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Growth - Proposals',
      apiEndpoint: 'getProposals',
      apiParams: { endpoint: '/api/v1/income/growth/proposals' },
      showCreateButton: false,
      columns: [
        { key: 'title', label: 'Title' },
        { key: 'project_id', label: 'Project', render: (v) => v.slice(0, 8) + '...' },
        { key: 'action_type', label: 'Action', render: (v) => v.replace(/_/g, ' ') },
        { key: 'impact_score', label: 'Impact', render: (v) => v.toFixed(1) },
        { key: 'effort_score', label: 'Effort', render: (v) => v.toFixed(1) },
        { key: 'confidence', label: 'Confidence', render: (v) => (v * 100).toFixed(0) + '%' },
        { key: 'status', label: 'Status', render: (v) => `<span class="badge badge-${v === 'approved' ? 'success' : v === 'rejected' ? 'error' : 'warning'}">${v}</span>` },
        { key: 'created_at', label: 'Created', render: (v) => new Date(v * 1000).toLocaleDateString() }
      ],
      actions: [
        { key: 'view', label: 'View', icon: 'eye' },
        { key: 'approve', label: 'Approve', icon: 'check', condition: (row) => row.status === 'pending' },
        { key: 'reject', label: 'Reject', icon: 'x', condition: (row) => row.status === 'pending' }
      ],
      emptyMessage: 'No growth proposals. Update project metrics first.'
    });
  }

  render() {
    super.render();
    this.container.querySelector('.view-header').innerHTML = `
      <h2>Growth - Proposals</h2>
      <div style="display: flex; gap: var(--space-2); flex-wrap: wrap;">
        <button class="btn btn-secondary" id="metricsBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="16"></line></svg> Update Metrics</button>
        <button class="btn btn-secondary" id="actionsBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7"></path></svg> Actions Log</button>
        <select class="form-select" id="statusFilter" style="width: auto; min-width: 140px;">
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
          <option value="implemented">Implemented</option>
        </select>
      </div>
    `;
    this.bindFilterEvents();
  }

  bindFilterEvents() {
    this.container.querySelector('#metricsBtn').addEventListener('click', () => this.openMetricsModal());
    this.container.querySelector('#actionsBtn').addEventListener('click', () => this.showActionsLog());
    this.container.querySelector('#statusFilter').addEventListener('change', () => this.loadData());
  }

  async loadData() {
    const status = this.container.querySelector('#statusFilter').value;
    
    try {
      const params = new URLSearchParams();
      if (status) params.append('status', status);
      
      const response = await this.app.api.get(`/api/v1/income/growth/proposals?${params}`);
      this.data = response.proposals || [];
      this.renderTable();
    } catch (error) {
      console.error('Failed to load proposals:', error);
      this.app.toast.error('Failed to load proposals', error.message);
    }
  }

  async handleAction(action, row) {
    if (action === 'approve') {
      try {
        await this.app.api.post(`/api/v1/income/growth/proposals/${row.id}/decide`, { proposal_id: row.id, approved: true });
        this.app.toast.success('Proposal approved');
        this.loadData();
      } catch (error) {
        this.app.toast.error('Failed to approve', error.message);
      }
    } else if (action === 'reject') {
      try {
        await this.app.api.post(`/api/v1/income/growth/proposals/${row.id}/decide`, { proposal_id: row.id, approved: false });
        this.app.toast.success('Proposal rejected');
        this.loadData();
      } catch (error) {
        this.app.toast.error('Failed to reject', error.message);
      }
    } else if (action === 'view') {
      this.showProposalDetail(row);
    }
  }

  async showProposalDetail(row) {
    const modal = new this.app.Modal({
      title: row.title,
      size: 'large',
      onConfirm: () => true
    });
    
    modal.setContent(`
      <div style="max-height: 70vh; overflow-y: auto;">
        <div class="stat-grid" style="margin-bottom: var(--space-4);">
          <div class="stat-card"><div class="stat-value">${row.impact_score.toFixed(1)}</div><div class="stat-label">Impact Score</div></div>
          <div class="stat-card"><div class="stat-value">${row.effort_score.toFixed(1)}</div><div class="stat-label">Effort Score</div></div>
          <div class="stat-card"><div class="stat-value">${(row.confidence * 100).toFixed(0)}%</div><div class="stat-label">Confidence</div></div>
        </div>
        <div class="form-group"><label class="form-label">Description</label><div class="form-textarea" readonly>${this.escapeHtml(row.description)}</div></div>
        <div class="form-group"><label class="form-label">Data Source</label><div>${this.escapeHtml(row.data_source)}</div></div>
        ${row.status !== 'pending' ? `<div class="form-group"><label class="form-label">Decision</label><div><span class="badge badge-${row.status === 'approved' ? 'success' : 'error'}">${row.status}</span> at ${row.decided_at ? new Date(row.decided_at * 1000).toLocaleString() : '—'}</div></div>` : ''}
      </div>
    `);
    await modal.open();
  }

  async openMetricsModal() {
    // Get list of projects first
    try {
      const projectsResponse = await this.app.api.get('/api/v1/income/builder/projects');
      const projects = projectsResponse.projects || [];
      
      const modal = new this.app.Modal({
        title: 'Update Project Metrics',
        size: 'medium',
        onConfirm: async (modal) => {
          const form = modal.element.querySelector('form');
          const data = {
            project_id: form.querySelector('[name="project_id"]').value,
            visitors: parseInt(form.querySelector('[name="visitors"]').value) || 0,
            signups: parseInt(form.querySelector('[name="signups"]').value) || 0,
            conversions: parseInt(form.querySelector('[name="conversions"]').value) || 0,
            revenue: parseFloat(form.querySelector('[name="revenue"]').value) || 0,
            churn_rate: parseFloat(form.querySelector('[name="churn_rate"]').value) || 0,
            avg_session_duration: parseFloat(form.querySelector('[name="avg_session_duration"]').value) || 0,
            bounce_rate: parseFloat(form.querySelector('[name="bounce_rate"]').value) || 0,
            error_rate: parseFloat(form.querySelector('[name="error_rate"]').value) || 0,
            uptime: parseFloat(form.querySelector('[name="uptime"]').value) || 100
          };
          
          try {
            await this.app.api.post('/api/v1/income/growth/metrics', data);
            this.app.toast.success('Metrics updated');
            modal.close(true);
          } catch (error) {
            this.app.toast.error('Failed to update metrics', error.message);
            return false;
          }
          return true;
        }
      });
      
      modal.setContent(`
        <form>
          <div class="form-group"><label class="form-label">Project</label>
            <select class="form-select" name="project_id" required>
              <option value="">Select project...</option>
              ${projects.map(p => `<option value="${p.id}">${p.title}</option>`).join('')}
            </select>
          </div>
          <div class="form-group"><label class="form-label">Visitors</label><input type="number" class="form-input" name="visitors" min="0" value="0"></div>
          <div class="form-group"><label class="form-label">Signups</label><input type="number" class="form-input" name="signups" min="0" value="0"></div>
          <div class="form-group"><label class="form-label">Conversions</label><input type="number" class="form-input" name="conversions" min="0" value="0"></div>
          <div class="form-group"><label class="form-label">Revenue ($)</label><input type="number" class="form-input" name="revenue" min="0" step="0.01" value="0"></div>
          <div class="form-group"><label class="form-label">Churn Rate (%)</label><input type="number" class="form-input" name="churn_rate" min="0" max="100" step="0.1" value="0"></div>
          <div class="form-group"><label class="form-label">Avg Session Duration (sec)</label><input type="number" class="form-input" name="avg_session_duration" min="0" value="0"></div>
          <div class="form-group"><label class="form-label">Bounce Rate (%)</label><input type="number" class="form-input" name="bounce_rate" min="0" max="100" step="0.1" value="0"></div>
          <div class="form-group"><label class="form-label">Error Rate (%)</label><input type="number" class="form-input" name="error_rate" min="0" max="100" step="0.1" value="0"></div>
          <div class="form-group"><label class="form-label">Uptime (%)</label><input type="number" class="form-input" name="uptime" min="0" max="100" step="0.1" value="100"></div>
        </form>
      `);
      await modal.open();
    } catch (error) {
      this.app.toast.error('Failed to load projects', error.message);
    }
  }

  async showActionsLog() {
    try {
      const response = await this.app.api.get('/api/v1/income/growth/actions/log');
      const actions = response.actions || [];
      
      const modal = new this.app.Modal({
        title: 'Growth Actions Log',
        size: 'large',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="table-container">
          <table class="data-table">
            <thead><tr><th>Project</th><th>Action</th><th>Proposal</th><th>Approved</th><th>Created</th></tr></thead>
            <tbody>
              ${actions.map(a => `
                <tr>
                  <td>${a.project_id.slice(0, 8)}...</td>
                  <td>${a.action_type}</td>
                  <td>${a.proposal_id ? a.proposal_id.slice(0, 8) + '...' : '—'}</td>
                  <td><span class="badge badge-${a.approved ? 'success' : 'error'}">${a.approved ? 'Yes' : 'No'}</span></td>
                  <td>${new Date(a.created_at * 1000).toLocaleString()}</td>
                </tr>
              `).join('') || '<tr><td colspan="5" class="empty-state">No actions logged</td></tr>'}
            </tbody>
          </table>
        </div>
      `);
      await modal.open();
    } catch (error) {
      this.app.toast.error('Failed to load actions log', error.message);
    }
  }
}
