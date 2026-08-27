// Maya 2.0 ULTRA - RAG View
import { BaseView } from '../BaseView.js';

export class RAGView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'RAG / Knowledge Base',
      apiEndpoint: 'getRAGDocuments',
      showCreateButton: true,
      columns: [
        { key: 'title', label: 'Title', render: (v) => v ? v.slice(0, 50) : 'Untitled' },
        { key: 'doc_type', label: 'Type' },
        { key: 'chunks', label: 'Chunks' },
        { key: 'created_at', label: 'Created', render: (v) => v ? new Date(v).toLocaleDateString() : '—' }
      ],
      actions: [
        { key: 'search', label: 'Search', icon: 'search' },
        { key: 'delete', label: 'Delete', icon: 'trash' }
      ],
      emptyMessage: 'No documents in knowledge base'
    });
  }
  
  async openCreateModal() {
    const modal = new this.app.Modal({
      title: 'Ingest Document',
      size: 'large',
      onConfirm: async () => {
        return true;
      }
    });
    
    modal.setContent(`
      <div class="form-group">
        <label class="form-label">Ingest Method</label>
        <select class="form-select" id="ingestMethod">
          <option value="text">Paste Text</option>
          <option value="file">Upload File</option>
          <option value="workspace">Workspace Path</option>
        </select>
      </div>
      <div id="ingestFields"></div>
    `);
    
    await modal.open();
  }
  
  handleAction(key, row) {
    if (key === 'search') this.openSearch(row);
    else if (key === 'delete') this.deleteDocument(row.id);
  }
  
  openSearch(doc) {
    // Open search modal for this document
  }
  
  async deleteDocument(docId) {
    const confirmed = await this.app.confirmDelete('document');
    if (!confirmed) return;
    
    try {
      await this.app.api.deleteRAGDocument(docId);
      this.app.toast.success('Document deleted');
      this.loadData();
    } catch (error) {
      this.app.toast.error('Failed to delete', error.message);
    }
  }
}

export class WorkflowsView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Workflows',
      apiEndpoint: 'getWorkflows',
      showCreateButton: true,
      columns: [
        { key: 'name', label: 'Name' },
        { key: 'description', label: 'Description', render: (v) => v ? v.slice(0, 50) : '—' },
        { key: 'run_count', label: 'Runs' },
        { key: 'last_run', label: 'Last Run', render: (v) => v ? new Date(v).toLocaleString() : 'Never' }
      ],
      actions: [
        { key: 'run', label: 'Run', icon: 'play' },
        { key: 'edit', label: 'Edit', icon: 'edit' },
        { key: 'delete', label: 'Delete', icon: 'trash' }
      ],
      emptyMessage: 'No workflows yet'
    });
  }
}

export class LearningView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view learning-view';
      this.render();
      this.bindEvents();
      this.loadStats();
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
      <div class="view-header"><h2>Learning</h2></div>
      <div class="learning-tabs">
        <button class="learning-tab active" data-tab="feedback">Feedback</button>
        <button class="learning-tab" data-tab="experience">Experience</button>
        <button class="learning-tab" data-tab="compression">Compression</button>
        <button class="learning-tab" data-tab="prompts">Prompt Optimization</button>
      </div>
      <div class="learning-tab-panel active" id="panelFeedback">
        <h3>Submit Feedback</h3>
        <form class="form" id="feedbackForm">
          <div class="form-group"><label class="form-label">Goal</label><textarea class="form-textarea" rows="3" required></textarea></div>
          <div class="form-group"><label class="form-label">Output</label><textarea class="form-textarea" rows="3" required></textarea></div>
          <div class="form-group"><label class="form-label">Rating (1-5)</label><input type="number" class="form-input" min="1" max="5" required></div>
          <div class="form-group"><label class="form-label">Comment</label><textarea class="form-textarea" rows="2"></textarea></div>
          <button type="submit" class="btn btn-primary">Submit</button>
        </form>
        <hr style="margin: var(--space-5) 0;">
        <h3>Feedback Stats</h3>
        <div id="feedbackStats">Loading...</div>
      </div>
      <div class="learning-tab-panel" id="panelExperience" style="display: none;">
        <h3>Experience Replay</h3>
        <div id="experienceList">Loading...</div>
      </div>
      <div class="learning-tab-panel" id="panelCompression" style="display: none;">
        <h3>Memory Compression</h3>
        <form class="form" id="compressionForm">
          <div class="form-group"><label class="form-label">Memory Type</label><select class="form-select"><option value="chat">Chat</option><option value="general">General</option><option value="note">Note</option></select></div>
          <label class="form-switch"><input type="checkbox" class="form-switch-input" checked><span class="form-switch-slider"></span><span class="form-switch-label">Dry Run</span></label>
          <button type="submit" class="btn btn-primary">Run Compression</button>
        </form>
        <div id="compressionResult"></div>
      </div>
      <div class="learning-tab-panel" id="panelPrompts" style="display: none;">
        <h3>Prompt Optimization</h3>
        <div id="promptOptStats">Loading...</div>
        <h4 style="margin-top:var(--space-4)">Backend Optimizer Report</h4>
        <div id="optimizedPrompts">Loading...</div>
      </div>
    `;
    
    this.bindTabEvents();
  }

  bindEvents() {
    this.container.querySelector('#feedbackForm')?.addEventListener('submit', (e) => this.submitFeedback(e));
    this.container.querySelector('#compressionForm')?.addEventListener('submit', (e) => this.runCompression(e));
  }

  bindTabEvents() {
    this.container.querySelectorAll('.learning-tab').forEach(tab => {
      tab.addEventListener('click', () => this.setTab(tab.dataset.tab));
    });
  }
  
  setTab(tab) {
    this.container.querySelectorAll('.learning-tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tab));
    this.container.querySelectorAll('.learning-tab-panel').forEach(p => p.style.display = p.id === `panel${tab.charAt(0).toUpperCase() + tab.slice(1)}` ? 'block' : 'none');
  }
  
  async loadStats() {
    try {
      const stats = await this.app.api.getLearningStats();
      this.renderStats(stats);
    } catch (error) {
      console.error('Failed to load learning stats:', error);
    }
  }
  
  renderStats(stats) {
    const el = this.container.querySelector('#feedbackStats');
    el.innerHTML = `
      <div class="stat-grid">
      <div class="stat-card"><div class="stat-value">${stats.feedback?.total || 0}</div><div class="stat-label">Total Feedback</div></div>
      <div class="stat-card"><div class="stat-value">${stats.feedback?.avg_rating || 0}</div><div class="stat-label">Avg Rating</div></div>
      <div class="stat-card"><div class="stat-value">${stats.lessons?.length || 0}</div><div class="stat-label">Lessons Learned</div></div>
      </div>
    `;
    
    this.renderExperience(stats.experience);
    this.renderPromptOpt(stats.prompts);
    this.loadOptimizedPrompts();
  }

  async loadOptimizedPrompts() {
    const el = this.container.querySelector('#optimizedPrompts');
    if (!el) return;
    try {
      const res = await this.app.api.getLearningPrompts();
      const report = res?.report || {};
      const core = res?.core || res || {};
      const coreRows = Object.entries(core).filter(([, v]) => typeof v !== 'object');
      el.innerHTML = `
        ${coreRows.length ? `<div class="stat-grid">${coreRows.map(([k, v]) =>
          `<div class="stat-card"><div class="stat-value small-val">${this.escapeHtml(String(v))}</div><div class="stat-label">${this.escapeHtml(k)}</div></div>`).join('')}</div>` : ''}
        <pre class="tool-tester-result" style="max-height:320px;overflow:auto">${this.escapeHtml(JSON.stringify(report, null, 2))}</pre>`;
    } catch (err) {
      el.innerHTML = `<div class="empty-state"><div class="desc">Optimizer report unavailable: ${this.escapeHtml(err.message)}</div></div>`;
    }
  }
  
  renderExperience(experience) {
    const el = this.container.querySelector('#experienceList');
    if (!experience || !experience.history?.length) {
      el.innerHTML = '<div class="empty-state"><h3>No experience data</h3></div>';
      return;
    }
    
    el.innerHTML = experience.history.slice(0, 10).map(exp => `
      <div class="experience-item" style="padding: var(--space-3); border-bottom: 1px solid var(--border);">
        <div style="font-weight: 500;">${this.app.escapeHtml(exp.goal)}</div>
        <div style="font-size: var(--text-sm); color: var(--text-tertiary);">Status: ${exp.status} | Confidence: ${exp.confidence}</div>
      </div>
    `).join('');
  }
  
  renderPromptOpt(prompts) {
    const el = this.container.querySelector('#promptOptStats');
    if (!prompts) {
      el.innerHTML = '<div class="empty-state"><h3>No prompt optimization data</h3></div>';
      return;
    }
    
    el.innerHTML = `
      <div class="stat-grid">
      <div class="stat-card"><div class="stat-value">${prompts.total_optimizations || 0}</div><div class="stat-label">Total Optimizations</div></div>
      <div class="stat-card"><div class="stat-value">${prompts.avg_improvement || 0}%</div><div class="stat-label">Avg Improvement</div></div>
      </div>
    `;
  }
  
  async submitFeedback(e) {
    e.preventDefault();
    const form = e.target;
    const data = {
      goal: form.querySelector('textarea').value,
      output: form.querySelectorAll('textarea')[1].value,
      rating: parseInt(form.querySelector('input[type="number"]').value),
      comment: form.querySelectorAll('textarea')[2].value
    };
    
    try {
      await this.app.api.submitFeedback(data.goal, data.output, data.rating, data.comment);
      this.app.toast.success('Feedback submitted');
      form.reset();
      this.loadStats();
    } catch (error) {
      this.app.toast.error('Failed to submit feedback', error.message);
    }
  }
  
  async runCompression(e) {
    e.preventDefault();
    const form = e.target;
    const memoryType = form.querySelector('select').value;
    const dryRun = form.querySelector('input[type="checkbox"]').checked;
    
    try {
      const result = await this.app.api.compressMemory(dryRun, memoryType);
      const resultEl = this.container.querySelector('#compressionResult');
      resultEl.innerHTML = `
        <div class="pipeline-status-card">
          <h4>Compression Result</h4>
          <div class="pipeline-status-details">
            <div class="pipeline-detail-item"><div class="pipeline-detail-label">Compressed</div><div class="pipeline-detail-value">${result.compressed}</div></div>
            <div class="pipeline-detail-item"><div class="pipeline-detail-label">Kept</div><div class="pipeline-detail-value">${result.kept}</div></div>
            <div class="pipeline-detail-item"><div class="pipeline-detail-label">Summary</div><div class="pipeline-detail-value">${result.summary_preview}</div></div>
          </div>
        </div>
      `;
    } catch (error) {
      this.app.toast.error('Compression failed', error.message);
    }
  }
}

export class PromptsView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view prompts-view';
      this.render();
      this.bindEvents();
      this.loadPrompts();
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
      <div class="view-header">
        <h2>Prompt Library</h2>
        <button class="btn btn-primary" id="createPromptBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg> Create Prompt</button>
      </div>
      <div class="prompts-layout">
        <nav class="prompts-sidebar">
          <div class="prompts-search">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            <input type="text" class="form-input" id="promptSearch" placeholder="Search prompts...">
          </div>
          <ul class="prompts-categories" id="promptsCategories">
            <li><button class="category-btn active" data-category="">All</button></li>
          </ul>
        </nav>
        <div class="prompts-content">
          <div class="prompts-grid" id="promptsGrid">
            <div class="loading-state"><div class="spinner"></div></div>
          </div>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    this.container.querySelector('#createPromptBtn').addEventListener('click', () => this.openCreateModal());
    this.container.querySelector('#promptSearch').addEventListener('input', (e) => this.filterPrompts(e.target.value));
  }
  
  async loadPrompts() {
    try {
      const response = await this.app.api.getPrompts();
      this.prompts = response.prompts || [];
      this.categories = response.categories || [];
      this.renderCategories();
      this.renderPrompts();
    } catch (error) {
      console.error('Failed to load prompts:', error);
    }
  }
  
  renderCategories() {
    const el = this.container.querySelector('#promptsCategories');
    el.innerHTML = `
      <li><button class="category-btn active" data-category="">All</button></li>
      ${this.categories.map(c => `<li><button class="category-btn" data-category="${c}">${c}</button></li>`).join('')}
    `;
    
    el.querySelectorAll('.category-btn').forEach(btn => {
      btn.addEventListener('click', () => this.setCategory(btn.dataset.category));
    });
  }
  
  setCategory(category) {
    this.currentCategory = category;
    this.container.querySelectorAll('.category-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.category === category);
    });
    this.renderPrompts();
  }
  
  filterPrompts(query) {
    this.searchQuery = query;
    this.renderPrompts();
  }
  
  renderPrompts() {
    const el = this.container.querySelector('#promptsGrid');
    let filtered = this.prompts;
    
    if (this.currentCategory) filtered = filtered.filter(p => p.category === this.currentCategory);
    if (this.searchQuery) {
      const q = this.searchQuery.toLowerCase();
      filtered = filtered.filter(p => p.name.toLowerCase().includes(q) || p.body.toLowerCase().includes(q));
    }
    
    if (filtered.length === 0) {
      el.innerHTML = '<div class="empty-state"><h3>No prompts found</h3></div>';
      return;
    }
    
    el.innerHTML = filtered.map(prompt => `
      <div class="prompt-card" style="border: 1px solid var(--border); border-radius: var(--radius); padding: var(--space-4);">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: var(--space-2);">
          <h4 style="margin: 0;">${this.escapeHtml(prompt.name)}</h4>
          <span class="badge badge-primary">${prompt.category}</span>
        </div>
        <p style="color: var(--text-secondary); font-size: var(--text-sm); margin-bottom: var(--space-3);">${this.escapeHtml(this.truncate(prompt.body, 150))}</p>
        <div style="display: flex; gap: var(--space-2); flex-wrap: wrap; margin-bottom: var(--space-3);">
          ${(prompt.tags || []).map(t => `<span class="badge badge-neutral">${t}</span>`).join('')}
        </div>
        <div style="display: flex; gap: var(--space-2);">
          <button class="btn btn-secondary btn-sm" data-action="render" data-id="${prompt.id}">Test Run</button>
          <button class="btn btn-secondary btn-sm" data-action="edit" data-id="${prompt.id}">Edit</button>
          <button class="btn btn-secondary btn-sm" data-action="history" data-id="${prompt.id}">History</button>
          <button class="btn btn-danger btn-sm" data-action="delete" data-id="${prompt.id}">Delete</button>
        </div>
      </div>
    `).join('');
    
    el.querySelectorAll('[data-action="render"]').forEach(btn => btn.addEventListener('click', () => this.renderPrompt(btn.dataset.id)));
    el.querySelectorAll('[data-action="edit"]').forEach(btn => btn.addEventListener('click', () => this.openEditModal(btn.dataset.id)));
    el.querySelectorAll('[data-action="history"]').forEach(btn => btn.addEventListener('click', () => this.openHistory(btn.dataset.id)));
    el.querySelectorAll('[data-action="delete"]').forEach(btn => btn.addEventListener('click', () => this.deletePrompt(btn.dataset.id)));
  }
  
  async openCreateModal() {
    const modal = new this.app.Modal({
      title: 'Create Prompt',
      size: 'large',
      onConfirm: async () => {
        // Implementation
        return true;
      }
    });
    
    modal.setContent(`
      <div class="form-group"><label class="form-label">Name</label><input type="text" class="form-input" required placeholder="Prompt Name"></div>
      <div class="form-group"><label class="form-label">Body</label><textarea class="form-textarea" rows="6" required placeholder="Prompt body with {{variables}}"></textarea></div>
      <div class="form-group"><label class="form-label">Category</label><input type="text" class="form-input" value="general"></div>
      <div class="form-group"><label class="form-label">Description</label><textarea class="form-textarea" rows="2"></textarea></div>
    `);
    
    await modal.open();
  }
  
  truncate(str, length) {
    if (!str || str.length <= length) return str || '';
    return str.slice(0, length - 3) + '...';
  }
  
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  
  destroy() {}
}

export class WebhooksView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Webhooks',
      apiEndpoint: 'getWebhooks',
      showCreateButton: true,
      columns: [
        { key: 'name', label: 'Name' },
        { key: 'url', label: 'URL', render: (v) => v.slice(0, 50) + '...' },
        { key: 'events', label: 'Events', render: (v) => (v || []).join(', ') },
        { key: 'active', label: 'Status', render: (v) => v ? '<span class="badge badge-success">Active</span>' : '<span class="badge badge-neutral">Inactive</span>' }
      ],
      actions: [
        { key: 'edit', label: 'Edit', icon: 'edit' },
        { key: 'delete', label: 'Delete', icon: 'trash' }
      ],
      emptyMessage: 'No webhooks configured'
    });
  }
}

export class TranslateView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.languages = [];
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view translate-view';
      this.render();
      this.bindEvents();
      this.loadLanguages();
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
      <div class="view-header"><h2>Translate</h2></div>
      <div class="translate-form">
        <div class="form-group">
          <label class="form-label">Text to Translate</label>
          <textarea class="form-textarea" id="translateText" rows="6" placeholder="Enter text..."></textarea>
        </div>
        <div class="form-group">
          <div style="display: flex; gap: var(--space-4);">
            <div class="form-group" style="flex: 1;">
              <label class="form-label">Source Language</label>
              <select class="form-select" id="translateSource"><option value="">Auto-detect</option></select>
            </div>
            <div class="form-group" style="flex: 1;">
              <label class="form-label">Target Language</label>
              <select class="form-select" id="translateTarget" required></select>
            </div>
          </div>
        </div>
        <div style="display: flex; gap: var(--space-3);">
          <button class="btn btn-primary" id="translateBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg> Translate</button>
          <label class="form-switch"><input type="checkbox" class="form-switch-input" id="translateSpeak"><span class="form-switch-slider"></span><span class="form-switch-label">Speak Result</span></label>
        </div>
        <div class="form-group">
          <label class="form-label">Translation</label>
          <textarea class="form-textarea" id="translateResult" rows="6" readonly placeholder="Translation will appear here..."></textarea>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    this.container.querySelector('#translateBtn').addEventListener('click', () => this.translate());
    this.container.querySelector('#translateSource').addEventListener('change', () => this.detectLanguage());
  }
  
  async loadLanguages() {
    try {
      const response = await this.app.api.getLanguages();
      this.languages = response.languages || [];
      this.populateLanguageSelects();
    } catch (error) {
      console.error('Failed to load languages:', error);
    }
  }
  
  populateLanguageSelects() {
    const source = this.container.querySelector('#translateSource');
    const target = this.container.querySelector('#translateTarget');
    
    const options = this.languages.map(l => `<option value="${l.code}">${l.name} (${l.code})</option>`).join('');
    source.innerHTML = '<option value="">Auto-detect</option>' + options;
    target.innerHTML = options;
  }
  
  async translate() {
    const text = this.container.querySelector('#translateText').value.trim();
    const target = this.container.querySelector('#translateTarget').value;
    const source = this.container.querySelector('#translateSource').value || null;
    const speak = this.container.querySelector('#translateSpeak').checked;
    
    if (!text || !target) {
      this.app.toast.error('Text and target language required');
      return;
    }
    
    try {
      const result = await this.app.api.translate(text, target, source, speak);
      this.container.querySelector('#translateResult').value = result.translation || result.translatedText || JSON.stringify(result);
      
      if (result.audio) {
        const audio = new Audio('data:audio/mp3;base64,' + result.audio);
        audio.play();
      }
    } catch (error) {
      this.app.toast.error('Translation failed', error.message);
    }
  }
  
  async detectLanguage() {
    const text = this.container.querySelector('#translateText').value.trim();
    if (!text) return;
    
    try {
      const result = await this.app.api.detectLanguage(text);
      this.container.querySelector('#translateSource').value = result.code;
    } catch (error) {
      console.error('Language detection failed:', error);
    }
  }
}

export class AnalyticsView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Analytics',
      showCreateButton: false,
      columns: [],
      actions: [],
      emptyMessage: 'No analytics data'
    });
  }
  
  render() {
    this.container.innerHTML = `
      <div class="view-header"><h2>Analytics</h2></div>
      <div class="analytics-tabs">
        <button class="analytics-tab active" data-tab="summary">Summary</button>
        <button class="analytics-tab" data-tab="daily">Daily</button>
        <button class="analytics-tab" data-tab="providers">Providers</button>
        <button class="analytics-tab" data-tab="tools">Tools</button>
      </div>
      <div class="analytics-tab-panel active" id="panelSummary">
        <div class="analytics-grid" id="summaryGrid">Loading...</div>
      </div>
      <div class="analytics-tab-panel" id="panelDaily" style="display: none;">
        <div class="chart-container" id="dailyChart"></div>
      </div>
      <div class="analytics-tab-panel" id="panelProviders" style="display: none;">
        <div class="chart-container" id="providersChart"></div>
      </div>
      <div class="analytics-tab-panel" id="panelTools" style="display: none;">
        <div class="chart-container" id="toolsChart"></div>
      </div>
    `;
    this.bindTabEvents();
    this.loadAnalytics();
  }
  
  bindTabEvents() {
    this.container.querySelectorAll('.analytics-tab').forEach(tab => {
      tab.addEventListener('click', () => this.setTab(tab.dataset.tab));
    });
  }
  
  setTab(tab) {
    this.container.querySelectorAll('.analytics-tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tab));
    this.container.querySelectorAll('.analytics-tab-panel').forEach(p => p.style.display = p.id === `panel${tab.charAt(0).toUpperCase() + tab.slice(1)}` ? 'block' : 'none');
    
    if (tab === 'daily') this.renderDailyChart();
    else if (tab === 'providers') this.renderProvidersChart();
    else if (tab === 'tools') this.renderToolsChart();
  }
  
  async loadAnalytics() {
    try {
      const [summary, daily, providers, tools] = await Promise.all([
        this.app.api.getAnalyticsSummary(),
        this.app.api.getAnalyticsDaily(),
        this.app.api.getAnalyticsProviders(),
        this.app.api.getAnalyticsTools()
      ]);
      
      this.renderSummary(summary);
      this.dailyData = daily;
      this.providersData = providers;
      this.toolsData = tools;
      
      this.renderDailyChart();
      this.renderProvidersChart();
      this.renderToolsChart();
    } catch (error) {
      console.error('Failed to load analytics:', error);
    }
  }
  
  renderSummary(summary) {
    const el = this.container.querySelector('#summaryGrid');
    el.innerHTML = `
      <div class="stat-grid">
      <div class="stat-card"><div class="stat-value">${summary.total_tasks || 0}</div><div class="stat-label">Total Tasks</div></div>
      <div class="stat-card"><div class="stat-value">${summary.success_rate || 0}%</div><div class="stat-label">Success Rate</div></div>
      <div class="stat-card"><div class="stat-value">$${(summary.total_cost_usd || 0).toFixed(4)}</div><div class="stat-label">Total Cost</div></div>
      <div class="stat-card"><div class="stat-value">${summary.budget_used_pct || 0}%</div><div class="stat-label">Budget Used</div></div>
      </div>
    `;
  }
  
  renderDailyChart() {
    const el = this.container.querySelector('#dailyChart');
    if (!this.dailyData) return;
    
    new this.app.Chart(el, {
      type: 'bar',
      data: this.dailyData.map(d => d.tasks),
      labels: this.dailyData.map(d => d.date),
      height: 300
    });
  }
  
  renderProvidersChart() {
    const el = this.container.querySelector('#providersChart');
    if (!this.providersData) return;
    
    new this.app.Chart(el, {
      type: 'pie',
      data: Object.values(this.providersData).map(p => p.cost),
      labels: Object.keys(this.providersData),
      height: 300
    });
  }
  
  renderToolsChart() {
    const el = this.container.querySelector('#toolsChart');
    if (!this.toolsData) return;
    
    new this.app.Chart(el, {
      type: 'bar',
      data: Object.values(this.toolsData).map(t => t.calls),
      labels: Object.keys(this.toolsData),
      height: 300
    });
  }
}

export class LogsView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view logs-view';
      this.render();
      this.bindTabEvents();
      this.loadLogs();
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
      <div class="view-header"><h2>Logs</h2></div>
      <div class="logs-tabs">
        <button class="logs-tab active" data-tab="llm">LLM Logs</button>
        <button class="logs-tab" data-tab="tools">Tool Logs</button>
      </div>
      <div class="logs-tab-panel active" id="panelLLM">
        <div class="table-container" id="llmLogsTable"></div>
      </div>
      <div class="logs-tab-panel" id="panelTools" style="display: none;">
        <div class="table-container" id="toolsLogsTable"></div>
      </div>
    `;
    this.bindTabEvents();
  }

  bindTabEvents() {
    this.container.querySelectorAll('.logs-tab').forEach(tab => {
      tab.addEventListener('click', () => this.setTab(tab.dataset.tab));
    });
  }
  
  setTab(tab) {
    this.container.querySelectorAll('.logs-tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tab));
    this.container.querySelectorAll('.logs-tab-panel').forEach(p => p.style.display = p.id === `panel${tab.charAt(0).toUpperCase() + tab.slice(1)}` ? 'block' : 'none');
  }
  
  async loadLogs() {
    try {
      const [llmLogs, toolLogs] = await Promise.all([
        this.app.api.getLLMLogs(100),
        this.app.api.getToolLogs(100)
      ]);
      
      this.renderLLMLogs(llmLogs);
      this.renderToolLogs(toolLogs);
    } catch (error) {
      console.error('Failed to load logs:', error);
    }
  }
  
  renderLLMLogs(logs) {
    const el = this.container.querySelector('#llmLogsTable');
    if (!logs.length) {
      el.innerHTML = '<div class="empty-state"><h3>No LLM logs</h3></div>';
      return;
    }
    
    new this.app.DataTable(el, {
      columns: [
        { key: 'provider', label: 'Provider' },
        { key: 'model', label: 'Model' },
        { key: 'input_chars', label: 'Input' },
        { key: 'output_chars', label: 'Output' },
        { key: 'response_time', label: 'Time (s)', render: (v) => v?.toFixed(2) || '—' },
        { key: 'success', label: 'Status', render: (v) => v ? '<span class="badge badge-success">OK</span>' : '<span class="badge badge-error">Failed</span>' },
        { key: 'error', label: 'Error', render: (v) => v ? v.slice(0, 50) : '—' },
        { key: 'timestamp', label: 'Time', render: (v) => v ? new Date(v).toLocaleString() : '—' }
      ],
      data: logs,
      sortable: true,
      filterable: true,
      pagination: true,
      pageSize: 20
    });
  }
  
  renderToolLogs(logs) {
    const el = this.container.querySelector('#toolsLogsTable');
    if (!logs.length) {
      el.innerHTML = '<div class="empty-state"><h3>No tool logs</h3></div>';
      return;
    }
    
    new this.app.DataTable(el, {
      columns: [
        { key: 'tool', label: 'Tool' },
        { key: 'calls', label: 'Calls' },
        { key: 'successes', label: 'Success' },
        { key: 'failures', label: 'Failures' },
        { key: 'avg_time', label: 'Avg Time (s)', render: (v) => v?.toFixed(3) || '—' },
        { key: 'last_error', label: 'Last Error', render: (v) => v ? v.slice(0, 50) : '—' }
      ],
      data: logs,
      sortable: true,
      filterable: true,
      pagination: true,
      pageSize: 20
    });
  }
}

export class DocsView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.docs = [];
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view docs-view';
      this.render();
      this.bindEvents();
      this.loadDocs();
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
      <div class="view-header"><h2>Documentation</h2></div>
      <div class="docs-layout">
        <nav class="docs-sidebar">
          <ul class="docs-list" id="docsList">
            <li class="loading-state"><div class="spinner"></div><p>Loading...</p></li>
          </ul>
        </nav>
        <div class="docs-content">
          <div class="docs-viewer" id="docsViewer">
            <div class="empty-state"><h3>Select a document</h3><p>Choose a document from the sidebar</p></div>
          </div>
        </div>
      </div>
    `;
  }
  
  bindEvents() {}
  
  async loadDocs() {
    try {
      const response = await this.app.api.getDocs();
      this.docs = response.docs || [];
      this.renderDocList();
    } catch (error) {
      console.error('Failed to load docs:', error);
    }
  }
  
  renderDocList() {
    const el = this.container.querySelector('#docsList');
    el.innerHTML = this.docs.map(doc => `
      <li><a href="#" class="doc-link" data-doc="${doc}">${doc}</a></li>
    `).join('');
    
    el.querySelectorAll('.doc-link').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        this.loadDoc(link.dataset.doc);
      });
    });
  }
  
  async loadDoc(name) {
    const viewer = this.container.querySelector('#docsViewer');
    viewer.innerHTML = '<div class="loading-state"><div class="spinner"></div></div>';
    
    try {
      const response = await this.app.api.getDoc(name);
      this.app.MarkdownRenderer.renderToElement(response.content, viewer);
    } catch (error) {
      viewer.innerHTML = `<div class="error-state"><h3>Failed to load</h3><p>${error.message}</p></div>`;
    }
  }
}

export class AgentsView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Agents',
      apiEndpoint: 'getAgents',
      showCreateButton: false,
      columns: [
        { key: 'name', label: 'Name' },
        { key: 'role', label: 'Role' },
        { key: 'skills', label: 'Skills', render: (v) => (v || []).join(', ') },
        { key: 'permissions', label: 'Permissions', render: (v) => (v || []).join(', ') }
      ],
      actions: [],
      emptyMessage: 'No agents registered'
    });
  }
}

export class InstancesView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Instances',
      apiEndpoint: 'getInstances',
      showCreateButton: true,
      columns: [
        { key: 'name', label: 'Name' },
        { key: 'persona', label: 'Persona', render: (v) => v?.slice(0, 50) || '—' },
        { key: 'budget_usd', label: 'Budget', render: (v) => v ? '$' + v : '—' },
        { key: 'owner', label: 'Owner' }
      ],
      actions: [
        { key: 'delete', label: 'Delete', icon: 'trash' }
      ],
      emptyMessage: 'No instances yet'
    });
  }
}

export class DevicesView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view devices-view';
      this.render();
      this.bindEvents();
      this.loadDevices();
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
      <div class="view-header">
        <h2>Devices</h2>
        <button class="btn btn-primary" id="pairDeviceBtn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg> Pair Device</button>
      </div>
      <div class="devices-list" id="devicesList">
        <div class="loading-state"><div class="spinner"></div><p>Loading devices...</p></div>
      </div>
    `;
  }
  
  bindEvents() {
    this.container.querySelector('#pairDeviceBtn').addEventListener('click', () => this.openPairingModal());
  }
  
  async loadDevices() {
    try {
      const response = await this.app.api.listDevices();
      this.renderDevices(response.devices || []);
    } catch (error) {
      console.error('Failed to load devices:', error);
    }
  }
  
  renderDevices(devices) {
    const el = this.container.querySelector('#devicesList');
    
    if (!devices.length) {
      el.innerHTML = '<div class="empty-state"><h3>No devices paired</h3><p>Pair a device to get started</p></div>';
      return;
    }
    
    el.innerHTML = devices.map(device => `
      <div class="device-card" style="border: 1px solid var(--border); border-radius: var(--radius); padding: var(--space-4); margin-bottom: var(--space-3);">
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div>
            <h4 style="margin-bottom: var(--space-1);">${this.escapeHtml(device.name)}</h4>
            <div style="font-size: var(--text-sm); color: var(--text-tertiary);">ID: ${device.id}</div>
            <div style="font-size: var(--text-sm); color: var(--text-tertiary);">Paired: ${new Date(device.paired_at).toLocaleString()}</div>
          </div>
          <div style="display: flex; gap: var(--space-2);">
            <button class="btn btn-secondary btn-sm" data-action="history" data-id="${device.id}">History</button>
            <button class="btn btn-secondary btn-sm" data-action="command" data-id="${device.id}">Send Command</button>
            <button class="btn btn-danger btn-sm" data-action="revoke" data-id="${device.id}">Revoke</button>
          </div>
        </div>
      `).join('');
      
      this.container.querySelectorAll('[data-action="history"]').forEach(btn => {
        btn.addEventListener('click', () => this.openHistory(btn.dataset.id));
      });
      this.container.querySelectorAll('[data-action="command"]').forEach(btn => {
        btn.addEventListener('click', () => this.openCommandModal(btn.dataset.id));
      });
      this.container.querySelectorAll('[data-action="revoke"]').forEach(btn => {
        btn.addEventListener('click', () => this.revokeDevice(btn.dataset.id));
      });
  }
  
  async openPairingModal() {
    const modal = new this.app.Modal({
      title: 'Pair New Device',
      size: 'medium',
      onConfirm: async () => {
        return true;
      }
    });
    
    modal.setContent(`
      <div class="form-group">
        <label class="form-label">Device Name</label>
        <input type="text" class="form-input" placeholder="My Phone" required>
      </div>
    `);
    
    await modal.open();
    
    try {
      const result = await this.app.api.startDevicePairing(modal.element.querySelector('input').value || 'My Device');
      modal.setContent(`
        <div class="pairing-code" style="text-align: center; padding: var(--space-6);">
          <h3 style="margin-bottom: var(--space-4);">Enter this code on your device:</h3>
          <div style="font-size: 3rem; font-weight: 700; letter-spacing: 0.5em; color: var(--accent); font-family: var(--font-mono);">${result.code}</div>
          <p style="margin-top: var(--space-4); color: var(--text-secondary);">Expires: ${new Date(result.expires_at).toLocaleString()}</p>
          <p style="color: var(--text-tertiary); font-size: var(--text-sm);">Waiting for device to complete pairing...</p>
        </div>
      `);
      
      const checkPairing = setInterval(async () => {
        try {
          const devices = await this.app.api.listDevices();
          if (devices.some(d => d.name === modal.element.querySelector('input')?.value)) {
            clearInterval(checkPairing);
            this.app.toast.success('Device paired successfully');
            modal.close(true);
            this.loadDevices();
          }
        } catch {}
      }, 2000);
      
      modal.element.addEventListener('modal:close', () => clearInterval(checkPairing));
    } catch (error) {
      this.app.toast.error('Failed to start pairing', error.message);
    }
  }
  
  async openHistory(deviceId) {}
  async openCommandModal(deviceId) {}
  
  async revokeDevice(deviceId) {
    const confirmed = await this.app.confirmDelete('device');
    if (!confirmed) return;
    
    try {
      await this.app.api.revokeDevice(deviceId);
      this.app.toast.success('Device revoked');
      this.loadDevices();
    } catch (error) {
      this.app.toast.error('Failed to revoke device', error.message);
    }
  }
}

export class WorkspaceView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.tab = 'memory';
    this.workspaces = [];
    this.workspace = 'default';
    this.memories = [];
    this.files = [];
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view workspace-view';
      this.render();
      this.bindEvents();
      this.init();
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
      <div class="view-header">
        <h2>Workspace</h2>
        <div class="view-header-actions">
          <select class="form-select" id="wsSelect" aria-label="Workspace" style="max-width:200px"></select>
          <button class="icon-btn" id="wsRefresh" aria-label="Refresh" title="Refresh">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg>
          </button>
        </div>
      </div>
      <div class="learning-tabs" role="tablist">
        <button class="learning-tab active" data-tab="memory">Memory</button>
        <button class="learning-tab" data-tab="files">Files</button>
        <button class="learning-tab" data-tab="stats">Stats</button>
      </div>
      <div id="wsBody"><div class="loading-state"><div class="spinner"></div><p>Loading…</p></div></div>
      <div id="wsModalHost"></div>
    `;
  }

  bindEvents() {
    this.container.querySelectorAll('.learning-tab').forEach(t =>
      t.addEventListener('click', () => { this.tab = t.dataset.tab; this.setTab(); this.loadTab(); }));
    this.container.querySelector('#wsRefresh').addEventListener('click', () => this.loadTab());
    this.container.querySelector('#wsSelect').addEventListener('change', (e) => {
      this.workspace = e.target.value || 'default';
      this.loadTab();
    });
  }

  setTab() {
    this.container.querySelectorAll('.learning-tab').forEach(t =>
      t.classList.toggle('active', t.dataset.tab === this.tab));
  }

  async init() {
    try {
      const res = await this.app.api.listWorkspaces();
      this.workspaces = res?.workspaces || [];
    } catch { this.workspaces = []; }
    const sel = this.container.querySelector('#wsSelect');
    sel.innerHTML = (this.workspaces.length
      ? this.workspaces.map(w =>
          `<option value="${this.escapeHtml(w.scope || w.id || w.name)}">${this.escapeHtml(w.name || w.scope || w.id)}</option>`)
      : '<option value="default">default</option>').join('');
    const scopes = this.workspaces.map(w => w.scope || w.id || w.name);
    if (!scopes.includes(this.workspace)) this.workspace = scopes[0] || 'default';
    sel.value = this.workspace;
    await this.loadTab();
  }

  async loadTab() {
    const body = this.container.querySelector('#wsBody');
    body.innerHTML = '<div class="loading-state"><div class="spinner"></div><p>Loading…</p></div>';
    try {
      if (this.tab === 'memory') await this.loadMemory(body);
      else if (this.tab === 'files') await this.loadFiles(body);
      else await this.loadStats(body);
    } catch (err) {
      body.innerHTML = `<div class="error-state"><div class="icon">⚠️</div><h3>Failed to load</h3><p>${this.escapeHtml(err.message)}</p></div>`;
    }
  }

  async loadMemory(body) {
    const res = await this.app.api.getWorkspaceMemory(this.workspace, '', 50);
    this.memories = res?.results || [];
    body.innerHTML = `
      <form class="form" id="wsMemForm" style="display:flex;gap:var(--space-2);flex-wrap:wrap;margin-bottom:var(--space-4)">
        <input type="text" class="form-input" id="wsMemInput" placeholder="Add memory to ${this.escapeHtml(this.workspace)}…" required style="flex:1;min-width:180px">
        <button type="submit" class="btn btn-primary">Add</button>
      </form>
      ${this.memories.length ? `
      <div class="table-container"><table class="data-table">
        <thead><tr><th>Content</th><th>Type</th><th>Author</th><th></th></tr></thead>
        <tbody>${this.memories.map(m => `
          <tr>
            <td>${this.escapeHtml(m.content)}</td>
            <td>${this.escapeHtml(m.type || 'general')}</td>
            <td>${this.escapeHtml(m.author || m.metadata?.author || '—')}</td>
            <td class="row-actions"><button class="task-action-btn" data-del="${this.escapeHtml(m.id)}">Delete</button></td>
          </tr>`).join('')}
        </tbody>
      </table></div>` : `<div class="empty-state"><div class="icon">🗂</div><div class="title">No memories</div><div class="desc">Nothing stored in this workspace yet.</div></div>`}
    `;
    body.querySelector('#wsMemForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const input = body.querySelector('#wsMemInput');
      try {
        await this.app.api.addWorkspaceMemory(this.workspace, input.value.trim());
        this.app.toast.success('Memory added');
        this.loadTab();
      } catch (err) { this.app.toast.error('Add failed', err.message); }
    });
    body.querySelectorAll('[data-del]').forEach(btn => btn.addEventListener('click', async () => {
      if (!await this.app.confirmDelete('workspace memory')) return;
      try {
        await this.app.api.deleteWorkspaceMemory(btn.dataset.del, this.workspace);
        this.app.toast.success('Deleted');
        this.loadTab();
      } catch (err) { this.app.toast.error('Delete failed', err.message); }
    }));
  }

  async loadFiles(body) {
    const res = await this.app.api.listWorkspaceFiles();
    this.files = Array.isArray(res) ? res : (res?.files || []);
    if (!this.files.length) {
      body.innerHTML = `<div class="empty-state"><div class="icon">📁</div><div class="title">No files</div><div class="desc">The workspace directory is empty.</div></div>`;
      return;
    }
    body.innerHTML = `
      <div class="table-container"><table class="data-table">
        <thead><tr><th>Name</th><th>Size</th><th>Modified</th></tr></thead>
        <tbody>${this.files.map(f => `
          <tr>
            <td>${this.escapeHtml(f.name)}</td>
            <td>${f.size != null ? this.app.formatBytes(f.size) : '—'}</td>
            <td>${f.modified ? new Date(f.modified * 1000).toLocaleString() : '—'}</td>
          </tr>`).join('')}
        </tbody>
      </table></div>`;
  }

  async loadStats(body) {
    const s = await this.app.api.getWorkspaceStats(this.workspace);
    const rows = Object.entries(s || {}).filter(([, v]) => typeof v !== 'object');
    body.innerHTML = `
      <div class="stat-grid">
        ${rows.map(([k, v]) => `
          <div class="stat-card"><div class="stat-value">${this.escapeHtml(String(v))}</div><div class="stat-label">${this.escapeHtml(k.replace(/_/g, ' '))}</div></div>`).join('')}
      </div>`;
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}

export class BackupsView extends BaseView {
  constructor(app) {
    super(app, {
      title: 'Backups',
      apiEndpoint: 'listBackups',
      showCreateButton: true,
      columns: [
        { key: 'name', label: 'Name' },
        { key: 'created_at', label: 'Created', render: (v) => v ? new Date(v).toLocaleString() : '—' },
        { key: 'tasks', label: 'Tasks' },
        { key: 'memories', label: 'Memories' }
      ],
      actions: [
        { key: 'restore', label: 'Restore', icon: 'rotate-ccw' },
        { key: 'delete', label: 'Delete', icon: 'trash' }
      ],
      emptyMessage: 'No backups yet'
    });
  }
}

export class SecurityView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view security-view';
      this.render();
      this.loadStatus();
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
      <div class="view-header"><h2>Security</h2></div>
      <div class="security-status" id="securityStatus">
        <div class="loading-state"><div class="spinner"></div><p>Loading security status...</p></div>
      </div>
    `;
  }
  
  async loadStatus() {
    try {
      const status = await this.app.api.getSecurityStatus();
      this.renderStatus(status);
    } catch (error) {
      console.error('Failed to load security status:', error);
    }
  }
  
  renderStatus(status) {
    const el = this.container.querySelector('#securityStatus');
    el.innerHTML = `
      <div class="security-grid">
        <div class="security-card">
          <h4>Sandbox</h4>
          <div class="status-badge ${status.sandbox ? 'success' : 'error'}">${status.sandbox ? 'Enabled' : 'Disabled'}</div>
        </div>
        <div class="security-card">
          <h4>Risk Level</h4>
          <div class="status-badge ${status.risk_level === 'low' ? 'success' : status.risk_level === 'medium' ? 'warning' : 'error'}">${status.risk_level}</div>
        </div>
        <div class="security-card">
          <h4>Blocked Tools</h4>
          <div>${(status.blocked_tools || []).join(', ') || 'None'}</div>
        </div>
        <div class="security-card">
          <h4>Audit Log</h4>
          <div>${(status.audit_log || []).length} entries</div>
        </div>
      </div>
    `;
  }
}

export class ApprovalsView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.approvals = [];
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view approvals-view';
      this.render();
      this.bindEvents();
      this.loadApprovals();
      
      this.app.ws?.on?.('approval_requested', () => this.loadApprovals());
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
      <div class="view-header">
        <h2>Approvals</h2>
        <select class="form-select" id="approvalFilter" style="width: auto; min-width: 150px;">
          <option value="">All</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
        </select>
      </div>
      <div class="approvals-list" id="approvalsList">
        <div class="loading-state"><div class="spinner"></div><p>Loading approvals...</p></div>
      </div>
    `;
  }
  
  bindEvents() {
    this.container.querySelector('#approvalFilter').addEventListener('change', () => this.loadApprovals());
  }
  
  async loadApprovals() {
    const status = this.container.querySelector('#approvalFilter').value;
    
    try {
      const response = await this.app.api.getApprovals(status);
      this.approvals = response.approvals || [];
      this.renderApprovals();
    } catch (error) {
      console.error('Failed to load approvals:', error);
    }
  }
  
  renderApprovals() {
    const el = this.container.querySelector('#approvalsList');
    
    if (!this.approvals.length) {
      el.innerHTML = '<div class="empty-state"><h3>No approvals</h3><p>No pending approval requests</p></div>';
      return;
    }
    
    el.innerHTML = this.approvals.map(approval => `
      <div class="approval-card" style="border: 1px solid var(--border); border-radius: var(--radius); padding: var(--space-4); margin-bottom: var(--space-3);">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: var(--space-3);">
          <div>
            <h4 style="margin-bottom: var(--space-1);">${this.escapeHtml(approval.action)}</h4>
            <div style="font-size: var(--text-sm); color: var(--text-tertiary);">${new Date(approval.created_at).toLocaleString()}</div>
          </div>
          <span class="badge badge-${this.getStatusBadge(approval.status)}">${approval.status}</span>
        </div>
        ${approval.reason ? `<div style="color: var(--text-secondary); margin-bottom: var(--space-3);">${this.escapeHtml(approval.reason)}</div>` : ''}
        <div style="font-size: var(--text-xs); color: var(--text-tertiary); margin-bottom: var(--space-3);">Risk: ${approval.risk_level}</div>
        ${approval.status === 'pending' ? `
          <div style="display: flex; gap: var(--space-2);">
            <button class="btn btn-primary" data-action="approve" data-id="${approval.id}">Approve</button>
            <button class="btn btn-danger" data-action="reject" data-id="${approval.id}">Reject</button>
          </div>
        ` : ''}
      </div>
    `).join('');
    
    el.querySelectorAll('[data-action="approve"]').forEach(btn => {
      btn.addEventListener('click', () => this.decideApproval(btn.dataset.id, 'approve'));
    });
    el.querySelectorAll('[data-action="reject"]').forEach(btn => {
      btn.addEventListener('click', () => this.decideApproval(btn.dataset.id, 'reject'));
    });
  }
  
  async decideApproval(id, decision) {
    try {
      await this.app.api.decideApproval(id, decision);
      this.app.toast.success(`Approval ${decision}`);
      this.loadApprovals();
    } catch (error) {
      this.app.toast.error('Failed to decide', error.message);
    }
  }
  
  getStatusBadge(status) {
    const badges = {
      'pending': 'warning',
      'approved': 'success',
      'rejected': 'error'
    };
    return badges[status] || 'neutral';
  }
  
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  
  destroy() {}
}