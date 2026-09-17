import { BaseView } from './BaseView.js';

export class IncomePortfolioView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Portfolio',
      apiEndpoint: 'getRecommendations',
      apiParams: { endpoint: '/api/v1/income/growth/portfolio/recommendations' },
      showCreateButton: false,
      columns: [
        { key: 'project_id', label: 'Project', render: (v) => v.slice(0, 8) + '...' },
        { key: 'action', label: 'Action', render: (v) => v.replace(/_/g, ' ') },
        { key: 'confidence', label: 'Confidence', render: (v) => (v * 100).toFixed(0) + '%' },
        { key: 'rationale', label: 'Rationale', render: (v) => v.slice(0, 60) + '...' },
        { key: 'suggested_resources', label: 'Resources', render: (v) => (v || []).join(', ') },
        { key: 'created_at', label: 'Created', render: (v) => new Date(v * 1000).toLocaleDateString() }
      ],
      actions: [
        { key: 'view', label: 'View', icon: 'eye' }
      ],
      emptyMessage: 'No portfolio recommendations. Run a portfolio review.'
    });
  }

  render() {
    super.render();
    this.container.querySelector('.view-header').innerHTML = `
      <h2>Portfolio Manager</h2>
      <div style="display: flex; gap: var(--space-2); flex-wrap: wrap;">
        <button class="btn btn-primary" id="reviewBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg> Run Review</button>
        <button class="btn btn-secondary" id="summaryBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="16"></line></svg> Summary</button>
      </div>
    `;
    this.bindFilterEvents();
  }

  bindFilterEvents() {
    this.container.querySelector('#reviewBtn').addEventListener('click', () => this.runReview());
    this.container.querySelector('#summaryBtn').addEventListener('click', () => this.showSummary());
  }

  async loadData() {
    try {
      const response = await this.app.api.get('/api/v1/income/growth/portfolio/recommendations');
      this.data = response.recommendations || [];
      this.renderTable();
    } catch (error) {
      console.error('Failed to load recommendations:', error);
      this.app.toast.error('Failed to load recommendations', error.message);
    }
  }

  async runReview() {
    const btn = this.container.querySelector('#reviewBtn');
    btn.disabled = true;
    btn.innerHTML = '<svg class="spinner" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" fill="none" stroke-dasharray="30 150" stroke-linecap="round"><animateTransform attributeName="transform" type="rotate" from="0 12 12" to="360 12 12" dur="1s" repeatCount="indefinite"/></svg> Reviewing...';
    
    try {
      await this.app.api.post('/api/v1/income/growth/portfolio/review', {});
      this.app.toast.success('Portfolio review complete');
      await this.loadData();
    } catch (error) {
      this.app.toast.error('Review failed', error.message);
    } finally {
      btn.disabled = false;
      btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg> Run Review';
    }
  }

  async showSummary() {
    try {
      const response = await this.app.api.get('/api/v1/income/growth/portfolio/summary');
      
      const modal = new this.app.Modal({
        title: 'Portfolio Summary',
        size: 'medium',
        onConfirm: () => true
      });
      
      modal.setContent(`
        <div class="stat-grid">
          <div class="stat-card"><div class="stat-value">${response.total_projects || 0}</div><div class="stat-label">Total Projects</div></div>
          <div class="stat-card"><div class="stat-value">${response.live_projects || 0}</div><div class="stat-label">Live</div></div>
          <div class="stat-card"><div class="stat-value">${response.building_projects || 0}</div><div class="stat-label">Building</div></div>
          <div class="stat-card"><div class="stat-value">${response.failed_projects || 0}</div><div class="stat-label">Failed</div></div>
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
      this.app.toast.error('Failed to load summary', error.message);
    }
  }
}
