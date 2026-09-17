// Maya 2.0 - Browser Pool View
export class BrowserView {
    constructor(app) {
        this.app = app;
        this.container = null;
        this.contexts = [];
        this.currentContextId = null;
        this.pollInterval = null;
    }

    show() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.className = 'view browser-view';
        }
        this.container.innerHTML = this.render();
        this.app.viewContainer.appendChild(this.container);
        this.bindEvents();
        this.loadContexts();
        this.startPolling();
    }

    hide() {
        if (this.container?.parentNode) this.container.parentNode.removeChild(this.container);
        this.stopPolling();
    }

    render() {
        return `
            <div class="view-header">
                <h2><span class="icon">🌐</span> Browser Pool</h2>
                <div class="view-actions">
                    <button class="btn btn-primary" id="acquireContext">
                        <span>+</span> Acquire Context
                    </button>
                </div>
            </div>

            <div class="browser-layout">
                <div class="browser-sidebar">
                    <div class="panel">
                        <h3>Active Contexts</h3>
                        <div id="contextList" class="context-list">
                            <div class="loading">Loading contexts...</div>
                        </div>
                    </div>

                    <div class="panel">
                        <h3>Actions</h3>
                        <div class="action-buttons">
                            <button class="btn btn-secondary btn-sm" id="newContext" disabled>
                                <span>+</span> New Context
                            </button>
                            <button class="btn btn-secondary btn-sm" id="recycleContext" disabled>
                                ♻ Recycle
                            </button>
                            <button class="btn btn-danger btn-sm" id="closeContext" disabled>
                                ✕ Close
                            </button>
                        </div>
                    </div>
                </div>

                <div class="browser-main">
                    <div class="browser-toolbar">
                        <div class="url-bar">
                            <input type="text" id="urlInput" placeholder="Enter URL..." />
                            <button class="btn btn-primary" id="navigateBtn">Go</button>
                        </div>
                        <div class="toolbar-actions">
                            <button class="btn btn-secondary btn-sm" id="screenshotBtn" disabled>📸 Screenshot</button>
                            <button class="btn btn-secondary btn-sm" id="clickModeBtn" disabled>👆 Click Mode</button>
                            <button class="btn btn-secondary btn-sm" id="inspectBtn" disabled>🔍 Inspect</button>
                        </div>
                    </div>

                    <div class="browser-viewport" id="browserViewport">
                        <div class="viewport-placeholder">
                            <div class="icon">🌐</div>
                            <p>Select or acquire a browser context to begin</p>
                        </div>
                    </div>

                    <div class="browser-console" id="browserConsole" style="display: none;">
                        <div class="console-header">
                            <h4>Console Output</h4>
                            <button class="btn btn-ghost btn-sm" id="clearConsole">Clear</button>
                        </div>
                        <pre id="consoleOutput"></pre>
                    </div>
                </div>
            </div>
        `;
    }

    bindEvents() {
        // Acquire context
        this.container.querySelector('#acquireContext').addEventListener('click', () => this.acquireContext());
        
        // New context
        this.container.querySelector('#newContext').addEventListener('click', () => this.createNewContext());
        
        // Recycle
        this.container.querySelector('#recycleContext').addEventListener('click', () => this.recycleContext());
        
        // Close
        this.container.querySelector('#closeContext').addEventListener('click', () => this.closeContext());
        
        // Navigate
        const urlInput = this.container.querySelector('#urlInput');
        this.container.querySelector('#navigateBtn').addEventListener('click', () => this.navigate(urlInput.value));
        urlInput.addEventListener('keypress', (e) => e.key === 'Enter' && this.navigate(urlInput.value));
        
        // Screenshot
        this.container.querySelector('#screenshotBtn').addEventListener('click', () => this.takeScreenshot());
        
        // Console
        this.container.querySelector('#clearConsole').addEventListener('click', () => {
            this.container.querySelector('#consoleOutput').textContent = '';
        });
    }

    async loadContexts() {
        try {
            const response = await this.app.api.get('/api/v1/browser/status');
            this.contexts = response.contexts || [];
            this.renderContextList();
        } catch (e) {
            console.error('Failed to load contexts:', e);
            this.container.querySelector('#contextList').innerHTML = 
                '<div class="error">Failed to load contexts</div>';
        }
    }

    renderContextList() {
        const list = this.container.querySelector('#contextList');
        if (!this.contexts.length) {
            list.innerHTML = '<div class="empty-state">No active contexts</div>';
            return;
        }

        list.innerHTML = this.contexts.map(ctx => `
            <div class="context-item ${ctx.context_id === this.currentContextId ? 'active' : ''}" 
                 data-context-id="${ctx.context_id}">
                <div class="context-info">
                    <span class="context-id">${ctx.context_id}</span>
                    <span class="context-status ${ctx.in_use ? 'busy' : 'idle'}">
                        ${ctx.in_use ? '● Busy' : '● Idle'}
                    </span>
                </div>
                <div class="context-meta">
                    ${ctx.viewport.width}x${ctx.viewport.height} ${ctx.mobile ? '📱' : '💻'}
                </div>
            </div>
        `).join('');

        // Add click handlers
        list.querySelectorAll('.context-item').forEach(item => {
            item.addEventListener('click', () => this.selectContext(item.dataset.contextId));
        });
    }

    async selectContext(contextId) {
        this.currentContextId = contextId;
        this.updateContextButtons(true);
        this.container.querySelectorAll('.context-item').forEach(el => {
            el.classList.toggle('active', el.dataset.contextId === contextId);
        });
        this.log(`Selected context: ${contextId}`);
    }

    async acquireContext() {
        try {
            this.log('Acquiring browser context...');
            const response = await this.app.api.post('/api/v1/browser/acquire', {});
            this.contexts.push(response);
            this.renderContextList();
            this.selectContext(response.context_id);
            this.app.showToast('Browser context acquired', 'success');
        } catch (e) {
            this.app.showToast('Failed to acquire context: ' + e.message, 'error');
        }
    }

    async createNewContext() {
        if (!this.currentContextId) return;
        try {
            this.log('Creating new context...');
            const response = await this.app.api.post('/api/v1/browser/context', {
                context_id: this.currentContextId
            });
            this.app.showToast('New context created', 'success');
            this.loadContexts();
        } catch (e) {
            this.app.showToast('Failed to create context: ' + e.message, 'error');
        }
    }

    async recycleContext() {
        if (!this.currentContextId) return;
        try {
            this.log('Recycling context...');
            await this.app.api.post('/api/v1/browser/recycle', {
                context_id: this.currentContextId
            });
            this.app.showToast('Context recycled', 'success');
        } catch (e) {
            this.app.showToast('Failed to recycle: ' + e.message, 'error');
        }
    }

    async closeContext() {
        if (!this.currentContextId) return;
        if (!confirm('Close this browser context?')) return;
        
        try {
            await this.app.api.delete(`/api/v1/browser/context/${this.currentContextId}`);
            this.contexts = this.contexts.filter(c => c.context_id !== this.currentContextId);
            this.currentContextId = null;
            this.updateContextButtons(false);
            this.renderContextList();
            this.app.showToast('Context closed', 'success');
        } catch (e) {
            this.app.showToast('Failed to close: ' + e.message, 'error');
        }
    }

    async navigate(url) {
        if (!this.currentContextId) return;
        if (!url.startsWith('http')) url = 'https://' + url;
        
        this.log(`Navigating to ${url}...`);
        try {
            const result = await this.app.api.post('/api/v1/browser/navigate', {
                context_id: this.currentContextId,
                url
            });
            if (result.success) {
                this.app.showToast('Navigation complete', 'success');
                this.updateViewport(result);
            } else {
                this.app.showToast('Navigation failed: ' + result.error, 'error');
            }
        } catch (e) {
            this.app.showToast('Navigation error: ' + e.message, 'error');
        }
    }

    async takeScreenshot() {
        if (!this.currentContextId) return;
        try {
            const result = await this.app.api.post('/api/v1/browser/screenshot', {
                context_id: this.currentContextId,
                full_page: true
            });
            if (result.success && result.base64) {
                this.showScreenshot(result.base64);
                this.app.showToast('Screenshot captured', 'success');
            }
        } catch (e) {
            this.app.showToast('Screenshot failed: ' + e.message, 'error');
        }
    }

    showScreenshot(base64) {
        const viewport = this.container.querySelector('#browserViewport');
        viewport.innerHTML = `
            <img src="data:image/png;base64,${base64}" 
                 class="browser-screenshot" 
                 alt="Browser screenshot" />
        `;
    }

    updateViewport(data) {
        const viewport = this.container.querySelector('#browserViewport');
        viewport.innerHTML = `
            <div class="viewport-info">
                <h4>${this.app.escapeHtml(data.title || 'Untitled')}</h4>
                <span class="url">${this.app.escapeHtml(data.url)}</span>
            </div>
            <div class="viewport-placeholder">
                <p>Page loaded. Use screenshot to view content.</p>
            </div>
        `;
    }

    updateContextButtons(enabled) {
        ['newContext', 'recycleContext', 'closeContext', 'screenshotBtn', 'clickModeBtn', 'inspectBtn']
            .forEach(id => {
                const btn = this.container.querySelector(`#${id}`);
                if (btn) btn.disabled = !enabled;
            });
    }

    log(message) {
        const output = this.container.querySelector('#consoleOutput');
        const time = new Date().toLocaleTimeString();
        output.textContent += `[${time}] ${message}\n`;
        output.scrollTop = output.scrollHeight;
        this.container.querySelector('#browserConsole').style.display = 'block';
    }

    startPolling() {
        this.pollInterval = setInterval(() => this.loadContexts(), 10000);
    }

    stopPolling() {
        if (this.pollInterval) clearInterval(this.pollInterval);
    }

    destroy() {
        this.stopPolling();
    }
}