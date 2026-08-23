// Maya 2.0 ULTRA - Tools View
export class ToolsView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.tools = [];
    this.currentCategory = 'all';
    this.searchQuery = '';
    this.testerOpen = false;
    this.selectedTool = null;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view tools-view';
      this.render();
      this.bindEvents();
      this.loadTools();
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
      <div class="tools-header">
        <h2>Tools</h2>
        <div class="tools-search">
          <svg class="tools-search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
          <input type="text" class="tools-search-input" id="toolsSearch" placeholder="Search tools..." value="${this.searchQuery}">
        </div>
        <div class="tools-category-filter" id="categoryFilter">
          <button class="category-filter-btn active" data-category="all">All</button>
        </div>
      </div>
      
      <div class="tools-grid" id="toolsGrid">
        <div class="loading-state">
          <div class="spinner"></div>
          <p>Loading tools...</p>
        </div>
      </div>
      
      <!-- Tool Tester Drawer -->
      <div class="tool-tester" id="toolTester" style="display: none;">
        <div class="tool-tester-header">
          <h3 class="tool-tester-title" id="testerTitle">Test Tool</h3>
          <button class="modal-close" id="closeTester" aria-label="Close tester">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
          </button>
        </div>
        <div class="tool-tester-body">
          <div class="tool-tester-description" id="testerDescription"></div>
          <form class="tool-tester-form" id="testerForm">
            <div class="form-group">
              <label class="form-label" for="testerInput">Input (JSON)</label>
              <textarea class="form-input tool-tester-input" id="testerInput" rows="8" placeholder='{"param": "value"}'></textarea>
            </div>
            <div class="form-group">
              <label class="form-label">Result</label>
              <pre class="tool-tester-result" id="testerResult"></pre>
            </div>
          </form>
        </div>
        <div class="tool-tester-footer">
          <button class="btn btn-secondary" id="clearTester">Clear</button>
          <button class="btn btn-primary" id="runTester">Run Tool</button>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    // Search
    const searchInput = this.container.querySelector('#toolsSearch');
    searchInput.addEventListener('input', (e) => {
      this.searchQuery = e.target.value;
      this.filterTools();
    });
    
    // Category filter (delegated)
    this.container.querySelector('#categoryFilter').addEventListener('click', (e) => {
      const btn = e.target.closest('.category-filter-btn');
      if (btn) this.setCategory(btn.dataset.category);
    });
    
    // Tester
    this.container.querySelector('#closeTester').addEventListener('click', () => this.closeTester());
    this.container.querySelector('#clearTester').addEventListener('click', () => this.clearTester());
    this.container.querySelector('#runTester').addEventListener('click', () => this.runTester());
    this.container.querySelector('#testerForm').addEventListener('submit', (e) => {
      e.preventDefault();
      this.runTester();
    });
  }
  
  async loadTools() {
    try {
      const response = await this.app.api.getTools();
      this.tools = response;
      this.renderCategories();
      this.renderTools();
    } catch (error) {
      this.renderError(error.message);
    }
  }
  
  renderCategories() {
    const categories = ['all', ...new Set(this.tools.map(t => t.category))];
    const filterEl = this.container.querySelector('#categoryFilter');
    
    filterEl.innerHTML = categories.map(cat => `
      <button class="category-filter-btn ${cat === this.currentCategory ? 'active' : ''}" data-category="${cat}">
        ${cat.charAt(0).toUpperCase() + cat.slice(1)}
      </button>
    `).join('');
  }
  
  renderTools() {
    const gridEl = this.container.querySelector('#toolsGrid');
    let filtered = this.tools;
    
    if (this.currentCategory !== 'all') {
      filtered = filtered.filter(t => t.category === this.currentCategory);
    }
    
    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase();
      filtered = filtered.filter(t => 
        t.name.toLowerCase().includes(query) ||
        t.description.toLowerCase().includes(query) ||
        t.category.toLowerCase().includes(query)
      );
    }
    
    if (filtered.length === 0) {
      gridEl.innerHTML = `
        <div class="empty-state">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path></svg>
          <h3>No tools found</h3>
          <p>Try adjusting your search or filter</p>
        </div>
      `;
      return;
    }
    
    gridEl.innerHTML = filtered.map(tool => `
      <div class="tool-card" data-name="${tool.name}">
        <div class="tool-card-header">
          <div class="tool-card-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path></svg>
          </div>
          <div class="tool-card-info">
            <div class="tool-card-name">${this.escapeHtml(tool.name)}</div>
            <span class="tool-card-category">${tool.category}</span>
          </div>
          <label class="form-switch tool-card-toggle">
            <input type="checkbox" class="form-switch-input" ${tool.enabled !== false ? 'checked' : ''} data-tool="${tool.name}">
            <span class="form-switch-slider"></span>
          </label>
        </div>
        <div class="tool-card-body">
          <p class="tool-card-description">${this.escapeHtml(tool.description || 'No description')}</p>
          <div class="tool-card-stats">
            <div class="tool-card-stat">
              <span class="tool-card-stat-value">${tool.call_count || 0}</span>
              <span>Calls</span>
            </div>
            <div class="tool-card-stat">
              <span class="tool-card-stat-value">${tool.success_rate || 0}%</span>
              <span>Success</span>
            </div>
            <div class="tool-card-stat">
              <span class="tool-card-stat-value">${tool.avg_duration_ms || 0}ms</span>
              <span>Avg</span>
            </div>
          </div>
        </div>
        <div class="tool-card-footer">
          <button class="btn btn-secondary btn-sm tool-test-btn" data-tool="${tool.name}">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"></polyline></svg>
            Test
          </button>
        </div>
      </div>
    `).join('');
    
    // Bind events
    gridEl.querySelectorAll('.tool-card-toggle input').forEach(input => {
      input.addEventListener('change', (e) => this.toggleTool(e.target.dataset.tool, e.target.checked));
    });
    
    gridEl.querySelectorAll('.tool-test-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.openTester(e.target.closest('[data-tool]').dataset.tool);
      });
    });
  }
  
  filterTools() {
    this.renderTools();
  }
  
  setCategory(category) {
    this.currentCategory = category;
    this.container.querySelectorAll('.category-filter-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.category === category);
    });
    this.renderTools();
  }
  
  async toggleTool(name, enabled) {
    try {
      await this.app.api.updateTool(name, enabled);
      this.app.toast.success(`Tool ${enabled ? 'enabled' : 'disabled'}`);
      this.loadTools();
    } catch (error) {
      this.app.toast.error('Failed to update tool', error.message);
      this.loadTools();
    }
  }
  
  openTester(toolName) {
    const tool = this.tools.find(t => t.name === toolName);
    if (!tool) return;
    
    this.selectedTool = tool;
    this.testerOpen = true;
    
    const tester = this.container.querySelector('#toolTester');
    const title = this.container.querySelector('#testerTitle');
    const desc = this.container.querySelector('#testerDescription');
    const input = this.container.querySelector('#testerInput');
    const result = this.container.querySelector('#testerResult');
    
    title.textContent = `Test: ${tool.name}`;
    desc.textContent = tool.description || 'No description available';
    input.value = '{}';
    result.textContent = '';
    
    tester.style.display = 'block';
    document.body.style.overflow = 'hidden';
    
    setTimeout(() => input.focus(), 100);
  }
  
  closeTester() {
    this.testerOpen = false;
    this.selectedTool = null;
    this.container.querySelector('#toolTester').style.display = 'none';
    document.body.style.overflow = '';
  }
  
  clearTester() {
    this.container.querySelector('#testerInput').value = '{}';
    this.container.querySelector('#testerResult').textContent = '';
  }
  
  async runTester() {
    const input = this.container.querySelector('#testerInput');
    const result = this.container.querySelector('#testerResult');
    const runBtn = this.container.querySelector('#runTester');
    
    let parsedInput;
    try {
      parsedInput = JSON.parse(input.value);
    } catch (e) {
      result.textContent = 'Invalid JSON: ' + e.message;
      result.className = 'tool-tester-result error';
      return;
    }
    
    runBtn.disabled = true;
    runBtn.textContent = 'Running...';
    result.textContent = 'Running...';
    result.className = 'tool-tester-result';
    
    try {
      const response = await this.app.api.runTool(this.selectedTool.name, parsedInput);
      result.textContent = JSON.stringify(response, null, 2);
      result.className = 'tool-tester-result';
    } catch (error) {
      result.textContent = 'Error: ' + error.message;
      result.className = 'tool-tester-result error';
    } finally {
      runBtn.disabled = false;
      runBtn.textContent = 'Run Tool';
    }
  }
  
  renderError(message) {
    const gridEl = this.container.querySelector('#toolsGrid');
    gridEl.innerHTML = `
      <div class="error-state">
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
        <h3>Failed to load tools</h3>
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