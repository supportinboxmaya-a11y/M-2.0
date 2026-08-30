import { BaseView } from './BaseView.js';

export class IncomeScoutView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Scout - Opportunities',
      apiEndpoint: 'getOpportunities',
      apiParams: { endpoint: '/api/v1/income/scout/opportunities' },
      showCreateButton: false,
      columns: [
        { key: 'title', label: 'Title', render: (v, row) => `<strong>${v}</strong><br><small class="text-secondary">${row.source_category}</small>` },
        { key: 'total_score', label: 'Score', render: (v) => v.toFixed(2) },
        { key: 'market_signal_score', label: 'Market', render: (v) => v.toFixed(2) },
        { key: 'build_complexity_score', label: 'Complexity', render: (v) => v.toFixed(2) },
        { key: 'status', label: 'Status', render: (v) => `<span class="badge badge-${v === 'queued_for_strategist' ? 'success' : v === 'rejected' ? 'error' : 'warning'}">${v}</span>` },
        { key: 'created_at', label: 'Created', render: (v) => new Date(v * 1000).toLocaleDateString() }
      ],
      actions: [
        { key: 'view', label: 'View', icon: 'eye' },
        { key: 'approve', label: 'Approve', icon: 'check', condition: (row) => row.status === 'discovered' || row.status === 'analyzed' },
        { key: 'reject', label: 'Reject', icon: 'x', condition: (row) => row.status !== 'rejected' }
      ],
      emptyMessage: 'No opportunities yet. Run a scan.'
    });
  }

  render() {
    super.render();
    this.container.querySelector('.view-header').innerHTML = `
      <h2>Scout - Opportunities</h2>
      <div style="display: flex; gap: var(--space-2); flex-wrap: wrap;">
        <button class="btn btn-primary" id="runScanBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg> Run Scan</button>
        <button class="btn btn-secondary" id="scanHistoryBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg> Scan History</button>
        <select class="form-select" id="statusFilter" style="width: auto; min-width: 140px;">
          <option value="">All Statuses</option>
          <option value="discovered">Discovered</option>
          <option value="analyzed">Analyzed</option>
          <option value="queued_for_strategist">Queued for Strategist</option>
          <option value="rejected">Rejected</option>
        </select>
        <select class="form-select" id="categoryFilter" style="width: auto; min-width: 160px;">
          <option value="">All Categories</option>
        </select>
      </div>
    `;
    this.bindFilterEvents();
  }

  bindFilterEvents() {
    this.container.querySelector('#runScanBtn').addEventListener('click', () => this.runScan());
    this.container.querySelector('#scanHistoryBtn').addEventListener('click', () => this.showScanHistory());
    this.container.querySelector('#statusFilter').addEventListener('change', () => this.loadData());
    this.container.querySelector('#categoryFilter').addEventListener('change', () => this.loadData());
  }

  async loadData() {
    const status = this.container.querySelector('#statusFilter').value;
    const category = this.container.querySelector('#categoryFilter').value;
    
    try {
      const params = new URLSearchParams();
      if (status) params.append('status', status);
      if (category) params.append('category', category);
      
      const response = await this.app.api.get(`/api/v1/income/scout/opportunities?${params}`);
      this.data = response.opportunities || [];
      this.updateCategoryFilter(this.data);
      this.renderTable();
    } catch (error) {
      console.error('Failed to load opportunities:', error);
      this.app.toast.error('Failed to load opportunities', error.message);
    }
  }

  updateCategoryFilter(opportunities) {
    const categories = [...new Set(opportunities.map(o => o.source_category))].sort();
    const select = this.container.querySelector('#categoryFilter');
    select.innerHTML = '<option value="">All Categories</option>' + 
      categories.map(c => `<option value="${c}">${c}</option>`).join('');
  }

  async runScan() {
    const btn = this.container.querySelector('#runScanBtn');
    btn.disabled = true;
    btn.innerHTML = '<svg class="spinner" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" fill="none" stroke-dasharray="30 150" stroke-linecap="round"><animateTransform attributeName="transform" type="rotate" from="0 12 12" to="360 12 12" dur="1s" repeatCount="indefinite"/></svg> Scanning...';
    
    try {
      const result = await this.app.api.post('/api/v1/income/scout/scan', {});
      this.app.toast.success(`Scan complete: ${result.signals_found} signals, ${result.opportunities_created} opportunities`);
      await this.loadData();
    } catch (error) {
      this.app.toast.error('Scan failed', error.message);
    } finally {
      btn.disabled = false;
      btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg> Run Scan';
    }
  }

  async showScanHistory() {
    try {
      const response = await this.app.api.get('/api/v1/income/scout/scan/history');
      const runs = response.runs || [];
      
      const modal = new this.app.Modal({
        title: 'Scan History',
        size: 'large',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="table-container">
          <table class="data-table">
            <thead><tr><th>Started</th><th>Signals</th><th>Opportunities</th><th>Duration</th><th>Status</th></tr></thead>
            <tbody>
              ${runs.map(r => `
                <tr>
                  <td>${new Date(r.started_at * 1000).toLocaleString()}</td>
                  <td>${r.signals_found}</td>
                  <td>${r.opportunities_created}</td>
                  <td>${r.duration_seconds?.toFixed(1) || '—'}s</td>
                  <td><span class="badge badge-${r.status === 'completed' ? 'success' : 'warning'}">${r.status}</span></td>
                </tr>
              `).join('') || '<tr><td colspan="5" class="empty-state">No scan history</td></tr>'}
            </tbody>
          </table>
        </div>
      `);
      await modal.open();
    } catch (error) {
      this.app.toast.error('Failed to load scan history', error.message);
    }
  }

  async handleAction(action, row) {
    if (action === 'approve') {
      await this.decideOpportunity(row.id, true);
    } else if (action === 'reject') {
      const reason = await this.app.Modal.prompt('Rejection reason:', 'Reject Opportunity');
      if (reason !== null) {
        await this.decideOpportunity(row.id, false, reason);
      }
    } else if (action === 'view') {
      this.showOpportunityDetail(row);
    }
  }

  async decideOpportunity(id, approved, feedback = '') {
    try {
      await this.app.api.post(`/api/v1/income/scout/opportunities/${id}/decision`, {
        opportunity_id: id,
        approved,
        feedback
      });
      this.app.toast.success(`Opportunity ${approved ? 'approved' : 'rejected'}`);
      this.loadData();
    } catch (error) {
      this.app.toast.error('Failed to decide', error.message);
    }
  }

  async showOpportunityDetail(row) {
    const modal = new this.app.Modal({
      title: row.title,
      size: 'large',
      onConfirm: () => true
    });
    
    modal.setContent(`
      <div style="max-height: 70vh; overflow-y: auto;">
        <div class="form-group"><label class="form-label">Description</label><div class="form-textarea" readonly>${this.escapeHtml(row.description)}</div></div>
        <div class="form-group"><label class="form-label">Problem Statement</label><div class="form-textarea" readonly>${this.escapeHtml(row.problem_statement)}</div></div>
        <div class="form-group"><label class="form-label">Target User</label><div class="form-textarea" readonly>${this.escapeHtml(row.target_user)}</div></div>
        <div class="form-group"><label class="form-label">Proposed Solution</label><div class="form-textarea" readonly>${this.escapeHtml(row.proposed_solution)}</div></div>
        <div class="stat-grid" style="margin: var(--space-4) 0;">
          <div class="stat-card"><div class="stat-value">${row.total_score.toFixed(2)}</div><div class="stat-label">Total Score</div></div>
          <div class="stat-card"><div class="stat-value">${row.market_signal_score.toFixed(2)}</div><div class="stat-label">Market Signal</div></div>
          <div class="stat-card"><div class="stat-value">${row.build_complexity_score.toFixed(2)}</div><div class="stat-label">Complexity</div></div>
          <div class="stat-card"><div class="stat-value">${row.competition_score.toFixed(2)}</div><div class="stat-label">Competition</div></div>
          <div class="stat-card"><div class="stat-value">${row.monetization_score.toFixed(2)}</div><div class="stat-label">Monetization</div></div>
        </div>
        <div class="form-group"><label class="form-label">Market</label><div>${this.escapeHtml(row.target_market)}</div></div>
        <div class="form-group"><label class="form-label">Est. Market Size</label><div>${this.escapeHtml(row.estimated_market_size)}</div></div>
        <div class="form-group"><label class="form-label">Monetization Model</label><div>${this.escapeHtml(row.monetization_model)}</div></div>
        ${row.owner_feedback ? `<div class="form-group"><label class="form-label">Owner Feedback</label><div class="form-textarea" readonly>${this.escapeHtml(row.owner_feedback)}</div></div>` : ''}
      </div>
    `);
    await modal.open();
  }
}
