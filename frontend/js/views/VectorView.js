// Maya 2.0 - Vector Store View
export class VectorView {
    constructor(app) {
        this.app = app;
        this.container = null;
        this.documents = [];
        this.currentPage = 1;
        this.pageSize = 20;
    }

    show() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.className = 'view vector-view';
        }
        this.container.innerHTML = this.render();
        this.app.viewContainer.appendChild(this.container);
        this.bindEvents();
        this.loadStats();
        this.search();
    }

    hide() {
        if (this.container?.parentNode) this.container.parentNode.removeChild(this.container);
    }

    render() {
        return `
            <div class="view-header">
                <h2><span class="icon">🔍</span> Vector Store</h2>
                <div class="view-actions">
                    <button class="btn btn-primary" id="addDocBtn">
                        <span>+</span> Add Document
                    </button>
                </div>
            </div>

            <div class="vector-layout">
                <div class="vector-search">
                    <div class="search-panel">
                        <h3>Semantic Search</h3>
                        <div class="search-form">
                            <div class="input-group">
                                <input type="text" id="searchQuery" placeholder="Enter search query..." />
                                <button class="btn btn-primary" id="searchBtn">Search</button>
                            </div>
                            <div class="search-options">
                                <label><input type="checkbox" id="hybridSearch" checked> Hybrid (BM25 + Dense)</label>
                                <label><input type="number" id="searchLimit" value="10" min="1" max="100" style="width: 80px;"> Results</label>
                            </div>
                        </div>
                    </div>

                    <div class="search-results" id="searchResults">
                        <div class="empty-state">Enter a query to search</div>
                    </div>
                </div>

                <div class="vector-documents">
                    <div class="panel">
                        <div class="panel-header">
                            <h3>Documents</h3>
                            <span class="badge" id="docCount">0 docs</span>
                        </div>
                        <div id="docList" class="doc-list">
                            <div class="loading">Loading...</div>
                        </div>
                        <div class="pagination" id="pagination"></div>
                    </div>

                    <div class="panel">
                        <h3>Store Stats</h3>
                        <div id="storeStats" class="stats-grid">
                            <div class="stat"><span class="stat-value" id="statCount">—</span><span class="stat-label">Documents</span></div>
                            <div class="stat"><span class="stat-value" id="statBackend">—</span><span class="stat-label">Backend</span></div>
                            <div class="stat"><span class="stat-value" id="statModel">—</span><span class="stat-label">Embedding Model</span></div>
                            <div class="stat"><span class="stat-value" id="statDim">—</span><span class="stat-label">Dimensions</span></div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Add Document Modal -->
            <div id="addDocModal" class="modal-overlay" style="display: none;">
                <div class="modal">
                    <div class="modal-header">
                        <h3>Add Document</h3>
                        <button class="modal-close" id="closeAddDocModal">✕</button>
                    </div>
                    <div class="modal-body">
                        <div class="form-group">
                            <label>Content</label>
                            <textarea id="docContent" rows="8" placeholder="Enter document content..."></textarea>
                        </div>
                        <div class="form-group">
                            <label>Metadata (JSON)</label>
                            <textarea id="docMetadata" rows="4" placeholder='{"type": "note", "tags": ["important"]}'></textarea>
                        </div>
                        <div class="form-group">
                            <label>Document ID (optional)</label>
                            <input type="text" id="docId" placeholder="Auto-generated if empty" />
                        </div>
                        <div class="modal-actions">
                            <button class="btn btn-secondary" id="cancelAddDoc">Cancel</button>
                            <button class="btn btn-primary" id="confirmAddDoc">Add Document</button>
                        </div>
                    </div>
                </div>
        `;
    }

    bindEvents() {
        // Search
        this.container.querySelector('#searchBtn').addEventListener('click', () => this.search());
        this.container.querySelector('#searchQuery').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.search();
        });

        // Add document
        this.container.querySelector('#addDocBtn').addEventListener('click', () => this.openAddModal());
        this.container.querySelector('#closeAddDocModal').addEventListener('click', () => this.closeAddModal());
        this.container.querySelector('#cancelAddDoc').addEventListener('click', () => this.closeAddModal());
        this.container.querySelector('#confirmAddDoc').addEventListener('click', () => this.addDocument());

        // Modal overlay click
        this.container.querySelector('#addDocModal').addEventListener('click', (e) => {
            if (e.target.id === 'addDocModal') this.closeAddModal();
        });
    }

    async loadStats() {
        try {
            const stats = await this.app.api.get('/api/v1/vector/stats');
            this.container.querySelector('#statCount').textContent = stats.count || 0;
            this.container.querySelector('#statBackend').textContent = stats.backend || 'chroma';
            this.container.querySelector('#statModel').textContent = stats.embedding_model || 'all-MiniLM-L6-v2';
            this.container.querySelector('#statDim').textContent = stats.embedding_dimension || 384;
            this.container.querySelector('#docCount').textContent = (stats.count || 0) + ' docs';
        } catch (e) {
            console.error('Failed to load stats:', e);
        }
    }

    async search() {
        const query = this.container.querySelector('#searchQuery').value.trim();
        if (!query) return;

        const hybrid = this.container.querySelector('#hybridSearch').checked;
        const limit = parseInt(this.container.querySelector('#searchLimit').value) || 10;

        const resultsEl = this.container.querySelector('#searchResults');
        resultsEl.innerHTML = '<div class="loading">Searching...</div>';

        try {
            const response = await this.app.api.post('/api/v1/vector/search', {
                query,
                limit,
                hybrid
            });

            const results = response.results || [];
            if (!results.length) {
                resultsEl.innerHTML = '<div class="empty-state">No results found</div>';
                return;
            }

            resultsEl.innerHTML = results.map((r, i) => `
                <div class="search-result">
                    <div class="result-header">
                        <span class="result-score">${(r.score * 100).toFixed(1)}%</span>
                        <span class="result-id">${r.id}</span>
                    </div>
                    <div class="result-content">${this.app.escapeHtml(r.content.substring(0, 300))}${r.content.length > 300 ? '...' : ''}</div>
                    <div class="result-meta">
                        ${Object.entries(r.metadata || {}).map(([k, v]) => `<span class="meta-tag">${k}: ${this.app.escapeHtml(String(v))}</span>`).join('')}
                    </div>
                </div>
            `).join('');
        } catch (e) {
            resultsEl.innerHTML = `<div class="error">Search failed: ${e.message}</div>`;
        }
    }

    async loadDocuments(page = 1) {
        this.currentPage = page;
        // Note: This would need a list endpoint, for now just show from search
    }

    openAddModal() {
        this.container.querySelector('#addDocModal').style.display = 'flex';
        this.container.querySelector('#docContent').focus();
    }

    closeAddModal() {
        this.container.querySelector('#addDocModal').style.display = 'none';
        this.container.querySelector('#docContent').value = '';
        this.container.querySelector('#docMetadata').value = '{}';
        this.container.querySelector('#docId').value = '';
    }

    async addDocument() {
        const content = this.container.querySelector('#docContent').value.trim();
        if (!content) return this.app.showToast('Enter document content', 'warning');

        let metadata = {};
        try {
            metadata = JSON.parse(this.container.querySelector('#docMetadata').value || '{}');
        } catch {
            return this.app.showToast('Invalid JSON metadata', 'error');
        }

        const docId = this.container.querySelector('#docId').value.trim() || null;

        try {
            const result = await this.app.api.post('/api/v1/vector/add', {
                content,
                metadata,
                doc_id: docId
            });

            if (result.success) {
                this.app.showToast('Document added', 'success');
                this.closeAddModal();
                this.loadStats();
            }
        } catch (e) {
            this.app.showToast('Failed to add: ' + e.message, 'error');
        }
    }
}