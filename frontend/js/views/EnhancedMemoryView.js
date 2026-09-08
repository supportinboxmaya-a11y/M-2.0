// Maya 2.0 - Enhanced Memory View
export class EnhancedMemoryView {
    constructor(app) {
        this.app = app;
        this.container = null;
        this.currentTab = 'hippocampus';
    }

    show() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.className = 'view enhanced-memory-view';
        }
        this.container.innerHTML = this.render();
        this.app.viewContainer.appendChild(this.container);
        this.bindEvents();
        this.loadAll();
    }

    hide() {
        if (this.container?.parentNode) this.container.parentNode.removeChild(this.container);
    }

    render() {
        return `
            <div class="view-header">
                <h2><span class="icon">🧠</span> Enhanced Memory Systems</h2>
                <div class="view-actions">
                    <button class="btn btn-secondary" id="consolidateBtn">
                        <span>🔄</span> Consolidate Now
                    </button>
                </div>
            </div>

            <div class="mm-tabs">
                <button class="tab-btn active" data-tab="hippocampus">🧠 Hippocampus</button>
                <button class="tab-btn" data-tab="semantic">🔗 Semantic Consolidation</button>
                <button class="tab-btn" data-tab="wm">💾 Working Memory v2</button>
            </div>

            <div class="tab-panels">
                <!-- Hippocampus Tab -->
                <div class="tab-panel active" id="hippocampusPanel">
                    <div class="memory-stats">
                        <div class="stat-card">
                            <span class="stat-value" id="hcTraces">—</span>
                            <span class="stat-label">Memory Traces</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="hcSchemas">—</span>
                            <span class="stat-label">Schemas</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="hcReplay">—</span>
                            <span class="stat-label">Replay Buffer</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="hcCycle">—</span>
                            <span class="stat-label">Consolidation Cycle</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="hcRipples">—</span>
                            <span class="stat-label">Ripple Events</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="hcStrength">—</span>
                            <span class="stat-label">Avg Strength</span>
                        </div>
                    </div>

                    <div class="panel">
                        <div class="panel-header">
                            <h3>Schemas</h3>
                            <button class="btn btn-secondary btn-sm" id="querySchemaBtn">Query Schema</button>
                        </div>
                        <div id="schemaQuery" class="query-form" style="display: none;">
                            <input type="text" id="schemaQueryInput" placeholder="Enter query..." />
                            <button class="btn btn-primary" id="runSchemaQuery">Query</button>
                        </div>
                        <div id="schemaList" class="schema-list">
                            <div class="loading">Loading schemas...</div>
                        </div>
                    </div>

                    <div class="panel">
                        <h3>Recent Ripple Events</h3>
                        <div id="rippleEvents" class="ripple-list">
                            <div class="empty-state">No ripple events</div>
                        </div>
                    </div>
                </div>

                <!-- Semantic Consolidation Tab -->
                <div class="tab-panel" id="semanticPanel">
                    <div class="memory-stats">
                        <div class="stat-card">
                            <span class="stat-value" id="scBeliefs">—</span>
                            <span class="stat-label">Beliefs</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="scLinks">—</span>
                            <span class="stat-label">Causal Links</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="scEvidence">—</span>
                            <span class="stat-label">Evidence Items</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="scConfidence">—</span>
                            <span class="stat-label">Avg Confidence</span>
                        </div>
                    </div>

                    <div class="panel">
                        <h3>Causal Query</h3>
                        <div class="query-form">
                            <div class="query-row">
                                <input type="text" id="causeInput" placeholder="Cause (optional)" />
                                <span class="arrow">→</span>
                                <input type="text" id="effectInput" placeholder="Effect (optional)" />
                            </div>
                            <button class="btn btn-primary" id="runCausalQuery">Query</button>
                        </div>
                        <div id="causalResults" class="causal-results"></div>
                    </div>

                    <div class="panel">
                        <h3>Intervention (do-calculus)</h3>
                        <div class="query-form">
                            <input type="text" id="interventionVar" placeholder="Variable" style="width: 150px;" />
                            <input type="number" id="interventionValue" placeholder="Value" step="0.1" style="width: 100px;" />
                            <input type="text" id="interventionEffect" placeholder="Effect to measure" />
                            <button class="btn btn-primary" id="runIntervention">Run Intervention</button>
                        </div>
                        <div id="interventionResults" class="intervention-results"></div>
                    </div>

                    <div class="panel">
                        <h3>Conflict Detection</h3>
                        <button class="btn btn-secondary" id="detectConflicts">Detect Conflicts</button>
                        <div id="conflictResults" class="conflict-results"></div>
                    </div>
                </div>

                <!-- Working Memory v2 Tab -->
                <div class="tab-panel" id="wmPanel">
                    <div class="memory-stats">
                        <div class="stat-card">
                            <span class="stat-value" id="wmChunks">—</span>
                            <span class="stat-label">Chunks</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="wmItems">—</span>
                            <span class="stat-label">Items</span>
                        </div>
                        <div class="stat-card">
                            <span class="stat-value" id="wmCapacity">—</span>
                            <span class="stat-label">Capacity</span>
                        </div>
                    </div>

                    <div class="wm-controls">
                        <div class="panel">
                            <h3>Add Item</h3>
                            <div class="form-group">
                                <textarea id="wmContent" rows="3" placeholder="Content to remember..."></textarea>
                            </div>
                            <div class="form-row">
                                <input type="text" id="wmChunkId" placeholder="Chunk ID (optional)" />
                                <input type="number" id="wmAttention" placeholder="Attention (0-1)" step="0.1" min="0" max="1" value="1" style="width: 150px;" />
                            </div>
                            <button class="btn btn-primary" id="addWmItem">Add to WM</button>
                        </div>

                        <div class="panel">
                            <h3>Retrieve</h3>
                            <div class="form-row">
                                <input type="text" id="wmQuery" placeholder="Search query..." style="flex: 1;" />
                                <input type="number" id="wmLimit" placeholder="Limit" value="5" min="1" max="20" style="width: 100px;" />
                            </div>
                            <button class="btn btn-primary" id="retrieveWm">Retrieve</button>
                        </div>

                        <button class="btn btn-secondary" id="decayWm">Apply Decay</button>
                    </div>

                    <div class="panel">
                        <h3>WM Contents</h3>
                        <div id="wmChunksList" class="wm-chunks">
                            <div class="loading">Loading...</div>
                        </div>
                        <div id="wmResults" class="wm-results" style="display: none;">
                            <h4>Retrieval Results</h4>
                            <div id="wmResultsList"></div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    bindEvents() {
        // Tab switching
        this.container.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => this.switchTab(btn.dataset.tab));
        });

        // Hippocampus
        this.container.querySelector('#consolidateBtn').addEventListener('click', () => this.consolidate());
        this.container.querySelector('#querySchemaBtn').addEventListener('click', () => {
            this.container.querySelector('#schemaQuery').style.display = 'block';
        });
        this.container.querySelector('#runSchemaQuery').addEventListener('click', () => this.querySchema());

        // Semantic
        this.container.querySelector('#runCausalQuery').addEventListener('click', () => this.causalQuery());
        this.container.querySelector('#runIntervention').addEventListener('click', () => this.intervention());
        this.container.querySelector('#detectConflicts').addEventListener('click', () => this.detectConflicts());

        // WM
        this.container.querySelector('#addWmItem').addEventListener('click', () => this.addWmItem());
        this.container.querySelector('#retrieveWm').addEventListener('click', () => this.retrieveWm());
        this.container.querySelector('#decayWm').addEventListener('click', () => this.decayWm());
    }

    switchTab(tab) {
        this.currentTab = tab;
        this.container.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tab);
        });
        this.container.querySelectorAll('.tab-panel').forEach(panel => {
            panel.classList.toggle('active', panel.id === tab + 'Panel');
        });
    }

    async loadAll() {
        await Promise.all([
            this.loadHippocampusStats(),
            this.loadSchemas(),
            this.loadRipples(),
            this.loadSemanticStats(),
            this.loadWmStats(),
            this.loadWmChunks(),
        ]);
    }

    async loadHippocampusStats() {
        try {
            const stats = await this.app.api.get('/api/v1/hippocampus/stats');
            this.container.querySelector('#hcTraces').textContent = stats.traces || 0;
            this.container.querySelector('#hcSchemas').textContent = stats.schemas || 0;
            this.container.querySelector('#hcReplay').textContent = stats.replay_buffer || 0;
            this.container.querySelector('#hcCycle').textContent = stats.consolidation_cycle || 0;
            this.container.querySelector('#hcRipples').textContent = stats.ripple_events || 0;
            this.container.querySelector('#hcStrength').textContent = (stats.avg_trace_strength * 100).toFixed(1) + '%';
        } catch (e) {
            console.error('Hippocampus stats failed:', e);
        }
    }

    async loadSchemas() {
        try {
            const schemas = await this.app.api.get('/api/v1/hippocampus/schemas');
            const list = this.container.querySelector('#schemaList');
            if (!schemas.length) {
                list.innerHTML = '<div class="empty-state">No schemas extracted yet</div>';
                return;
            }
            list.innerHTML = schemas.map(s => `
                <div class="schema-item">
                    <div class="schema-header">
                        <span class="schema-name">${this.app.escapeHtml(s.name)}</span>
                        <span class="schema-confidence">${(s.confidence * 100).toFixed(0)}%</span>
                    </div>
                    <div class="schema-pattern">${this.app.escapeHtml(JSON.stringify(s.pattern))}</div>
                    <div class="schema-meta">${s.instances.length} instances • ${s.applications} applications</div>
                </div>
            `).join('');
        } catch (e) {
            this.container.querySelector('#schemaList').innerHTML = '<div class="error">Failed to load</div>';
        }
    }

    async loadRipples() {
        try {
            const stats = await this.app.api.get('/api/v1/hippocampus/stats');
            // Would need a separate endpoint for ripple events
            this.container.querySelector('#rippleEvents').innerHTML = '<div class="empty-state">Ripple events log not available via API</div>';
        } catch (e) {
            this.container.querySelector('#rippleEvents').innerHTML = '<div class="error">Failed to load</div>';
        }
    }

    async querySchema() {
        const query = this.container.querySelector('#schemaQueryInput').value.trim();
        if (!query) return this.app.showToast('Enter query', 'warning');

        try {
            const schemas = await this.app.api.post('/api/v1/hippocampus/schema/query', { query, limit: 3 });
            const list = this.container.querySelector('#schemaList');
            if (!schemas.schemas.length) {
                list.innerHTML = '<div class="empty-state">No matching schemas</div>';
                return;
            }
            list.innerHTML = schemas.schemas.map(s => `
                <div class="schema-item result">
                    <div class="schema-header">
                        <span class="schema-name">${this.app.escapeHtml(s.name)}</span>
                        <span class="schema-confidence">${(s.confidence * 100).toFixed(0)}%</span>
                    </div>
                    <div class="schema-pattern">${this.app.escapeHtml(JSON.stringify(s.pattern))}</div>
                    <button class="btn btn-secondary btn-sm" onclick="app.currentView.applySchema('${s.id}')">Apply</button>
                </div>
            `).join('');
        } catch (e) {
            this.app.showToast('Query failed: ' + e.message, 'error');
        }
    }

    async applySchema(schemaId) {
        const context = prompt('Enter context (JSON):', '{}');
        let ctx = {};
        try { ctx = JSON.parse(context); } catch { return this.app.showToast('Invalid JSON', 'error'); }

        try {
            const result = await this.app.api.post('/api/v1/hippocampus/schema/apply', { schema_id: schemaId, context: ctx });
            this.app.showToast('Schema applied', 'success');
            console.log('Schema application result:', result);
        } catch (e) {
            this.app.showToast('Failed: ' + e.message, 'error');
        }
    }

    async loadSemanticStats() {
        try {
            const stats = await this.app.api.get('/api/v1/semantic-consolidation/stats');
            this.container.querySelector('#scBeliefs').textContent = stats.beliefs || 0;
            this.container.querySelector('#scLinks').textContent = stats.causal_links || 0;
            this.container.querySelector('#scEvidence').textContent = stats.evidence_items || 0;
            this.container.querySelector('#scConfidence').textContent = (stats.avg_confidence * 100).toFixed(1) + '%';
        } catch (e) {
            console.error('Semantic stats failed:', e);
        }
    }

    async causalQuery() {
        const cause = this.container.querySelector('#causeInput').value.trim();
        const effect = this.container.querySelector('#effectInput').value.trim();

        try {
            const result = await this.app.api.post('/api/v1/semantic-consolidation/causal', { cause, effect });
            this.renderCausalResult(result);
        } catch (e) {
            this.app.showToast('Query failed: ' + e.message, 'error');
        }
    }

    async intervention() {
        const variable = this.container.querySelector('#interventionVar').value.trim();
        const value = parseFloat(this.container.querySelector('#interventionValue').value);
        const effect = this.container.querySelector('#interventionEffect').value.trim();

        if (!variable || isNaN(value) || !effect) {
            return this.app.showToast('Fill all fields', 'warning');
        }

        try {
            const result = await this.app.api.post('/api/v1/semantic-consolidation/causal', {
                intervention: { variable, value },
                effect
            });
            this.renderInterventionResult(result);
        } catch (e) {
            this.app.showToast('Intervention failed: ' + e.message, 'error');
        }
    }

    async detectConflicts() {
        try {
            const result = await this.app.api.post('/api/v1/semantic-consolidation/detect-conflicts', {});
            const el = this.container.querySelector('#conflictResults');
            if (!result.conflicts?.length) {
                el.innerHTML = '<div class="empty-state">No conflicts detected</div>';
                return;
            }
            el.innerHTML = result.conflicts.map(c => `
                <div class="conflict-item">
                    <div class="conflict-beliefs">
                        <span>${this.app.escapeHtml(c.prop_1)}</span> (${c.conf_1})
                        vs
                        <span>${this.app.escapeHtml(c.prop_2)}</span> (${c.conf_2})
                    </div>
                </div>
            `).join('');
        } catch (e) {
            this.app.showToast('Detection failed: ' + e.message, 'error');
        }
    }

    renderCausalResult(result) {
        const el = this.container.querySelector('#causalResults');
        if (result.direct) {
            el.innerHTML = `
                <div class="result-card success">
                    <h5>Direct Causal Link Found</h5>
                    <p>Strength: ${(result.causal_strength * 100).toFixed(1)}%</p>
                </div>
            `;
        } else if (result.paths?.length) {
            el.innerHTML = `
                <div class="result-card">
                    <h5>Indirect Paths Found</h5>
                    <ul>${result.paths.map(p => `<li>${p.join(' → ')}</li>`).join('')}</ul>
                </div>
            `;
        } else {
            el.innerHTML = '<div class="result-card warning"><h5>No Causal Link</h5><p>No path found between cause and effect</p></div>';
        }
    }

    renderInterventionResult(result) {
        const el = this.container.querySelector('#interventionResults');
        el.innerHTML = `
            <div class="result-card">
                <h5>Intervention Result</h5>
                <p>Variable: ${result.intervention}</p>
                <pre>${JSON.stringify(result, null, 2)}</pre>
            </div>
        `;
    }

    async loadWmStats() {
        try {
            const state = await this.app.api.get('/api/v1/working-memory/state');
            this.container.querySelector('#wmChunks').textContent = state.chunks || 0;
            this.container.querySelector('#wmItems').textContent = state.items || 0;
            this.container.querySelector('#wmCapacity').textContent = state.capacity || 7;
            this.renderWmChunks(state.chunks_detail || {});
        } catch (e) {
            console.error('WM stats failed:', e);
        }
    }

    async loadWmChunks() {
        // Loaded via stats
    }

    renderWmChunks(chunks) {
        const el = this.container.querySelector('#wmChunksList');
        if (!Object.keys(chunks).length) {
            el.innerHTML = '<div class="empty-state">Working memory is empty</div>';
            return;
        }
        el.innerHTML = Object.entries(chunks).map(([cid, c]) => `
            <div class="chunk-item">
                <span class="chunk-id">${cid}</span>
                <span class="chunk-count">${c.item_count} items</span>
                <span class="chunk-strength">${(c.strength * 100).toFixed(0)}%</span>
            </div>
        `).join('');
    }

    async addWmItem() {
        const content = this.container.querySelector('#wmContent').value.trim();
        if (!content) return this.app.showToast('Enter content', 'warning');
        
        const chunkId = this.container.querySelector('#wmChunkId').value.trim() || null;
        const attention = parseFloat(this.container.querySelector('#wmAttention').value) || 1;

        try {
            await this.app.api.post('/api/v1/working-memory/add', { content, chunk_id: chunkId, attention });
            this.app.showToast('Added to working memory', 'success');
            this.container.querySelector('#wmContent').value = '';
            this.loadWmStats();
        } catch (e) {
            this.app.showToast('Failed: ' + e.message, 'error');
        }
    }

    async retrieveWm() {
        const query = this.container.querySelector('#wmQuery').value.trim();
        if (!query) return this.app.showToast('Enter query', 'warning');
        
        const limit = parseInt(this.container.querySelector('#wmLimit').value) || 5;

        try {
            const result = await this.app.api.post('/api/v1/working-memory/retrieve', { query, limit });
            this.showWmResults(result.results || []);
        } catch (e) {
            this.app.showToast('Retrieve failed: ' + e.message, 'error');
        }
    }

    showWmResults(results) {
        const el = this.container.querySelector('#wmResults');
        const list = this.container.querySelector('#wmResultsList');
        
        if (!results.length) {
            list.innerHTML = '<div class="empty-state">No matches</div>';
            el.style.display = 'block';
            return;
        }

        list.innerHTML = results.map(r => `
            <div class="wm-result">
                <span class="wm-score">${(r.score * 100).toFixed(1)}%</span>
                <span class="wm-content">${this.app.escapeHtml(r.content)}</span>
                <span class="wm-chunk">${r.chunk_id}</span>
            </div>
        `).join('');
        el.style.display = 'block';
    }

    async decayWm() {
        try {
            await this.app.api.post('/api/v1/working-memory/decay', {});
            this.app.showToast('Decay applied', 'success');
            this.loadWmStats();
        } catch (e) {
            this.app.showToast('Failed: ' + e.message, 'error');
        }
    }

    async consolidate() {
        try {
            this.app.showToast('Starting consolidation...', 'info');
            const result = await this.app.api.post('/api/v1/hippocampus/consolidate', {});
            this.app.showToast('Consolidation complete', 'success');
            this.loadHippocampusStats();
            this.loadSchemas();
        } catch (e) {
            this.app.showToast('Consolidation failed: ' + e.message, 'error');
        }
    }
}