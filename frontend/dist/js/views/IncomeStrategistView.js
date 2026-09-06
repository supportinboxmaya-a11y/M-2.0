import { BaseView } from './BaseView.js';

export class IncomeStrategistView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Strategist - Plans',
      apiEndpoint: 'getPlans',
      apiParams: { endpoint: '/api/v1/income/strategist/plans' },
      showCreateButton: false,
      columns: [
        { key: 'title', label: 'Title' },
        { key: 'opportunity_id', label: 'Opportunity', render: (v) => v.slice(0, 8) + '...' },
        { key: 'status', label: 'Status', render: (v) => `<span class="badge badge-${v === 'approved' ? 'success' : v === 'rejected' ? 'error' : 'warning'}">${v}</span>` },
        { key: 'estimated_timeline_weeks', label: 'Timeline', render: (v) => v + ' weeks' },
        { key: 'created_at', label: 'Created', render: (v) => new Date(v * 1000).toLocaleDateString() }
      ],
      actions: [
        { key: 'view', label: 'View', icon: 'eye' },
        { key: 'approve', label: 'Approve', icon: 'check', condition: (row) => row.status === 'draft' },
        { key: 'reject', label: 'Reject', icon: 'x', condition: (row) => row.status === 'draft' }
      ],
      emptyMessage: 'No plans yet. Run a strategy review.'
    });
  }

  render() {
    super.render();
    this.container.querySelector('.view-header').innerHTML = `
      <h2>Strategist - Plans</h2>
      <div style="display: flex; gap: var(--space-2); flex-wrap: wrap;">
        <button class="btn btn-primary" id="runReviewBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg> Run Review</button>
        <button class="btn btn-secondary" id="rankedBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg> Ranked Opportunities</button>
        <select class="form-select" id="statusFilter" style="width: auto; min-width: 140px;">
          <option value="">All Statuses</option>
          <option value="draft">Draft</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
        </select>
      </div>
    `;
    this.bindFilterEvents();
  }

  bindFilterEvents() {
    this.container.querySelector('#runReviewBtn').addEventListener('click', () => this.runReview());
    this.container.querySelector('#rankedBtn').addEventListener('click', () => this.showRankedOpportunities());
    this.container.querySelector('#statusFilter').addEventListener('change', () => this.loadData());
  }

  async loadData() {
    const status = this.container.querySelector('#statusFilter').value;
    
    try {
      const params = new URLSearchParams();
      if (status) params.append('status', status);
      
      const response = await this.app.api.get(`/api/v1/income/strategist/plans?${params}`);
      this.data = response.plans || [];
      this.renderTable();
    } catch (error) {
      console.error('Failed to load plans:', error);
      this.app.toast.error('Failed to load plans', error.message);
    }
  }

  async runReview() {
    const btn = this.container.querySelector('#runReviewBtn');
    btn.disabled = true;
    btn.innerHTML = '<svg class="spinner" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" fill="none" stroke-dasharray="30 150" stroke-linecap="round"><animateTransform attributeName="transform" type="rotate" from="0 12 12" to="360 12 12" dur="1s" repeatCount="indefinite"/></svg> Reviewing...';
    
    try {
      const result = await this.app.api.post('/api/v1/income/strategist/review', {});
      this.app.toast.success('Strategy review complete');
      await this.loadData();
    } catch (error) {
      this.app.toast.error('Review failed', error.message);
    } finally {
      btn.disabled = false;
      btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg> Run Review';
    }
  }

  async showRankedOpportunities() {
    try {
      const response = await this.app.api.get('/api/v1/income/strategist/ranked-opportunities');
      const opps = response.opportunities || [];
      
      const modal = new this.app.Modal({
        title: 'Ranked Opportunities',
        size: 'large',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="table-container">
          <table class="data-table">
            <thead><tr><th>Title</th><th>Category</th><th>Score</th><th>Owner Pref Adj</th><th>Status</th></tr></thead>
            <tbody>
              ${opps.map(o => `
                <tr>
                  <td><strong>${this.escapeHtml(o.title)}</strong><br><small>${this.escapeHtml(o.description.slice(0, 80))}...</small></td>
                  <td>${this.escapeHtml(o.source_category)}</td>
                  <td>${o.total_score.toFixed(2)}</td>
                  <td>${o.owner_preference_adjustment ? o.owner_preference_adjustment.toFixed(2) : '0'}</td>
                  <td><span class="badge badge-${o.status === 'queued_for_strategist' ? 'success' : o.status === 'rejected' ? 'error' : 'warning'}">${o.status}</span></td>
                </tr>
              `).join('') || '<tr><td colspan="5" class="empty-state">No ranked opportunities</td></tr>'}
            </tbody>
          </table>
        </div>
      `);
      await modal.open();
    } catch (error) {
      this.app.toast.error('Failed to load ranked opportunities', error.message);
    }
  }

  async handleAction(action, row) {
    if (action === 'approve') {
      try {
        await this.app.api.post(`/api/v1/income/strategist/plans/${row.id}/approve`, {});
        this.app.toast.success('Plan approved');
        this.loadData();
      } catch (error) {
        this.app.toast.error('Failed to approve', error.message);
      }
    } else if (action === 'reject') {
      const reason = await this.app.Modal.prompt('Rejection reason:', 'Reject Plan');
      if (reason !== null) {
        try {
          await this.app.api.post(`/api/v1/income/strategist/plans/${row.id}/reject`, { reason });
          this.app.toast.success('Plan rejected');
          this.loadData();
        } catch (error) {
          this.app.toast.error('Failed to reject', error.message);
        }
      }
    } else if (action === 'view') {
      this.showPlanDetail(row);
    }
  }

  async showPlanDetail(row) {
    const modal = new this.app.Modal({
      title: row.title,
      size: 'large',
      onConfirm: () => true
    });
    
    modal.setContent(`
      <div style="max-height: 70vh; overflow-y: auto;">
        <div class="form-group"><label class="form-label">Executive Summary</label><div class="form-textarea" readonly>${this.escapeHtml(row.executive_summary)}</div></div>
        <div class="form-group"><label class="form-label">MVP Scope</label><div>${Array.isArray(row.mvp_scope) ? row.mvp_scope.map(s => `<div>• ${this.escapeHtml(s)}</div>`).join('') : this.escapeHtml(row.mvp_scope)}</div></div>
        <div class="form-group"><label class="form-label">Technical Approach</label><div class="form-textarea" readonly>${this.escapeHtml(row.technical_approach)}</div></div>
        <div class="form-group"><label class="form-label">Timeline</label><div>${Array.isArray(row.timeline) ? row.timeline.map(s => `<div>• ${this.escapeHtml(s)}</div>`).join('') : this.escapeHtml(row.timeline)}</div></div>
        <div class="form-group"><label class="form-label">Success Metrics</label><div>${Array.isArray(row.success_metrics) ? row.success_metrics.map(s => `<div>• ${this.escapeHtml(s)}</div>`).join('') : this.escapeHtml(row.success_metrics)}</div></div>
        <div class="form-group"><label class="form-label">Risks</label><div>${Array.isArray(row.risks) ? row.risks.map(s => `<div>• ${this.escapeHtml(s)}</div>`).join('') : this.escapeHtml(row.risks)}</div></div>
        <div class="form-group"><label class="form-label">Approval Checkpoints</label><div>${Array.isArray(row.approval_checkpoints) ? row.approval_checkpoints.map(s => `<div>• ${this.escapeHtml(s)}</div>`).join('') : this.escapeHtml(row.approval_checkpoints)}</div></div>
        <div class="stat-grid" style="margin: var(--space-4) 0;">
          <div class="stat-card"><div class="stat-value">${row.estimated_timeline_weeks}</div><div class="stat-label">Weeks</div></div>
        </div>
      </div>
    `);
    await modal.open();
  }
}
