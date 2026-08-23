// Maya 2.0 ULTRA - Memory View
export class MemoryView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.currentType = 'all';
    this.memories = [];
    this.searchQuery = '';
    this.page = 1;
    this.pageSize = 50;
    this.totalCount = 0;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view memory-view';
      this.render();
      this.bindEvents();
      this.loadMemories();
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
      <div class="memory-header">
        <div class="memory-tabs" id="memoryTabs">
          <button class="memory-tab active" data-type="all">All</button>
          <button class="memory-tab" data-type="short-term">Short-term</button>
          <button class="memory-tab" data-type="long-term">Long-term</button>
          <button class="memory-tab" data-type="episodic">Episodic</button>
          <button class="memory-tab" data-type="semantic">Semantic</button>
          <button class="memory-tab" data-type="vector">Vector</button>
          <button class="memory-tab" data-type="chat">Chat</button>
          <button class="memory-tab" data-type="fact">Facts</button>
        </div>
        <div class="memory-search">
          <svg class="memory-search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
          <input type="text" class="memory-search-input" id="memorySearch" placeholder="Search memories..." value="${this.searchQuery}">
        </div>
        <div class="memory-stats" id="memoryStats">
          <div class="memory-stat">
            <span class="memory-stat-value" id="statTotal">0</span>
            <span>Total</span>
          </div>
          <div class="memory-stat">
            <span class="memory-stat-value" id="statShortTerm">0</span>
            <span>Short-term</span>
          </div>
          <div class="memory-stat">
            <span class="memory-stat-value" id="statLongTerm">0</span>
            <span>Long-term</span>
          </div>
        </div>
      </div>
      
      <div class="memory-list" id="memoryList">
        <div class="loading-state">
          <div class="spinner"></div>
          <p>Loading memories...</p>
        </div>
      </div>
      
      <div class="memory-actions-bar" style="display: flex; gap: var(--space-2); justify-content: flex-end; margin-top: var(--space-3);">
        <button class="btn btn-primary" id="addMemoryBtn">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          Add Memory
        </button>
      </div>
    `;
  }
  
  bindEvents() {
    // Tabs
    this.container.querySelectorAll('.memory-tab').forEach(tab => {
      tab.addEventListener('click', () => this.setType(tab.dataset.type));
    });
    
    // Search
    const searchInput = this.container.querySelector('#memorySearch');
    searchInput.addEventListener('input', (e) => {
      this.searchQuery = e.target.value;
      this.debounceSearch();
    });
    searchInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') this.loadMemories();
    });
    
    // Add memory
    this.container.querySelector('#addMemoryBtn').addEventListener('click', () => this.openMemoryEditor());
    
    // Stats
    this.loadStats();
  }
  
  setType(type) {
    this.currentType = type;
    this.page = 1;
    this.container.querySelectorAll('.memory-tab').forEach(tab => {
      tab.classList.toggle('active', tab.dataset.type === type);
    });
    this.loadMemories();
  }
  
  debounceSearch() {
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      this.page = 1;
      this.loadMemories();
    }, 300);
  }
  
  async loadMemories() {
    const listEl = this.container.querySelector('#memoryList');
    listEl.innerHTML = `
      <div class="loading-state">
        <div class="spinner"></div>
        <p>Loading memories...</p>
      </div>
    `;
    
    try {
      const params = new URLSearchParams({
        limit: this.pageSize.toString()
      });
      if (this.currentType !== 'all') params.set('type', this.currentType);
      if (this.searchQuery) params.set('q', this.searchQuery);
      
      const memories = await this.app.api.getMemories(this.currentType !== 'all' ? this.currentType : null, this.pageSize);
      this.memories = memories;
      this.renderMemories();
    } catch (error) {
      this.renderError(error.message);
    }
  }
  
  async loadStats() {
    try {
      const stats = await this.app.api.getMemoryStats();
      this.container.querySelector('#statTotal').textContent = stats.total_memories || 0;
      this.container.querySelector('#statShortTerm').textContent = stats.short_term_items || 0;
      this.container.querySelector('#statLongTerm').textContent = stats.vector_count || 0;
    } catch (error) {
      console.error('Failed to load memory stats:', error);
    }
  }
  
  renderMemories() {
    const listEl = this.container.querySelector('#memoryList');
    
    if (this.memories.length === 0) {
      listEl.innerHTML = `
        <div class="empty-state">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2v14a2 2 0 0 0 2 2h12"></path><path d="M6 2h12"></path><path d="M16 2v14"></path></svg>
          <h3>No memories found</h3>
          <p>${this.searchQuery ? 'Try adjusting your search' : 'Memories will appear here as you interact with Maya'}</p>
        </div>
      `;
      return;
    }
    
    listEl.innerHTML = this.memories.map(memory => `
      <div class="memory-item" data-id="${memory.id}">
        <div class="memory-type-badge memory-type-${memory.type || 'general'}">${this.getTypeIcon(memory.type)}</div>
        <div class="memory-item-content">
          <div class="memory-item-text">${this.escapeHtml(this.truncate(memory.content, 200))}</div>
          <div class="memory-item-meta">
            <span>${memory.type || 'general'}</span>
            <span>${this.formatRelativeTime(memory.timestamp)}</span>
            ${memory.importance ? `<span>Importance: ${memory.importance}</span>` : ''}
          </div>
        </div>
        <div class="memory-item-actions">
          <button class="memory-action-btn" data-action="edit" title="Edit" aria-label="Edit memory">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
          </button>
          <button class="memory-action-btn" data-action="delete" title="Delete" aria-label="Delete memory">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
          </button>
        </div>
      </div>
    `).join('');
    
    // Bind action events
    listEl.querySelectorAll('.memory-action-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const item = btn.closest('.memory-item');
        const id = item.dataset.id;
        if (btn.dataset.action === 'edit') this.openMemoryEditor(id);
        else if (btn.dataset.action === 'delete') this.deleteMemory(id);
      });
    });
  }
  
  async openMemoryEditor(memoryId = null) {
    let memory = null;
    if (memoryId) {
      memory = this.memories.find(m => m.id === memoryId);
    }
    
    const modal = new this.app.Modal({
      title: memory ? 'Edit Memory' : 'Add Memory',
      size: 'medium',
      onConfirm: async () => {
        const content = modal.element.querySelector('#memoryContent').value.trim();
        const type = modal.element.querySelector('#memoryType').value;
        
        if (!content) {
          this.app.toast.error('Content is required');
          return false;
        }
        
        try {
          if (memoryId) {
            await this.app.api.updateMemory(memoryId, content);
            this.app.toast.success('Memory updated');
          } else {
            await this.app.api.addMemory(content, type);
            this.app.toast.success('Memory added');
          }
          this.loadMemories();
          return true;
        } catch (error) {
          this.app.toast.error('Failed to save memory', error.message);
          return false;
        }
      }
    });
    
    modal.setContent(`
      <div class="form-group">
        <label class="form-label" for="memoryContent">Content <span class="required">*</span></label>
        <textarea class="form-textarea" id="memoryContent" rows="6" placeholder="Enter memory content...">${memory ? this.escapeHtml(memory.content) : ''}</textarea>
      </div>
      <div class="form-group">
        <label class="form-label" for="memoryType">Type</label>
        <select class="form-select" id="memoryType">
          <option value="general" ${memory && memory.type === 'general' ? 'selected' : ''}>General</option>
          <option value="note" ${memory && memory.type === 'note' ? 'selected' : ''}>Note</option>
          <option value="chat" ${memory && memory.type === 'chat' ? 'selected' : ''}>Chat</option>
          <option value="fact" ${memory && memory.type === 'fact' ? 'selected' : ''}>Fact</option>
          <option value="task_episode" ${memory && memory.type === 'task_episode' ? 'selected' : ''}>Task Episode</option>
        </select>
      </div>
    `);
    
    await modal.open();
  }
  
  async deleteMemory(memoryId) {
    const confirmed = await this.app.confirmDelete('memory');
    if (!confirmed) return;
    
    try {
      await this.app.api.deleteMemory(memoryId);
      this.app.toast.success('Memory deleted');
      this.loadMemories();
    } catch (error) {
      this.app.toast.error('Failed to delete memory', error.message);
    }
  }
  
  renderError(message) {
    const listEl = this.container.querySelector('#memoryList');
    listEl.innerHTML = `
      <div class="error-state">
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
        <h3>Failed to load memories</h3>
        <p>${this.escapeHtml(message)}</p>
        <button class="btn btn-primary" onclick="this.loadMemories()">Retry</button>
      </div>
    `;
  }
  
  getTypeIcon(type) {
    const icons = {
      'short-term': '📝',
      'long-term': '💾',
      'episodic': '📖',
      'semantic': '🧠',
      'vector': '🔍',
      'chat': '💬',
      'fact': '📌',
      'general': '📄',
      'note': '📝',
      'task_episode': '⚙️'
    };
    return icons[type] || '📄';
  }
  
  formatRelativeTime(timestamp) {
    if (!timestamp) return 'Unknown';
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    const mins = Math.floor(diff / 60000);
    const hours = Math.floor(mins / 60);
    const days = Math.floor(hours / 24);
    
    if (mins < 1) return 'Just now';
    if (mins < 60) return `${mins}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
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
  
  destroy() {
    clearTimeout(this.searchTimeout);
  }
}