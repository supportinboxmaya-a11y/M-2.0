// Maya 2.0 - System Status View
export class SystemStatusView {
    constructor(app) {
        this.app = app;
        this.container = null;
        this.pollInterval = null;
        this.statusData = {};
    }

    show() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.className = 'view system-status-view';
        }
        this.container.innerHTML = this.render();
        this.app.viewContainer.appendChild(this.container);
        this.bindEvents();
        this.loadStatus();
        this.startPolling();
    }

    hide() {
        if (this.container?.parentNode) this.container.parentNode.removeChild(this.container);
        this.stopPolling();
    }

    render() {
        return `
            <div class="view-header">
                <h2><span class="icon">⚙️</span> System Status</h2>
                <div class="view-actions">
                    <button class="btn btn-secondary" id="refreshStatus">🔄 Refresh</button>
                    <button class="btn btn-primary" id="runHealthCheck">🏥 Health Check</button>
                </div>
            </div>

            <div class="status-grid">
                <!-- Core System -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>🖥️ Core System</h3>
                        <span class="status-indicator" id="coreStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="coreDetails">
                        <div class="detail-row"><span>Version</span><span id="sysVersion">—</span></div>
                        <div class="detail-row"><span>Uptime</span><span id="sysUptime">—</span></div>
                        <div class="detail-row"><span>Providers</span><span id="sysProviders">—</span></div>
                        <div class="detail-row"><span>Tools</span><span id="sysTools">—</span></div>
                        <div class="detail-row"><span>Budget</span><span id="sysBudget">—</span></div>
                    </div>
                </div>

                <!-- Browser Pool -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>🌐 Browser Pool</h3>
                        <span class="status-indicator" id="browserStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="browserDetails">
                        <div class="detail-row"><span>Contexts</span><span id="browserContexts">—</span></div>
                        <div class="detail-row"><span>In Use</span><span id="browserInUse">—</span></div>
                        <div class="detail-row"><span>Max</span><span id="browserMax">—</span></div>
                    </div>
                </div>

                <!-- Sandbox -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>🔒 Sandbox</h3>
                        <span class="status-indicator" id="sandboxStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="sandboxDetails">
                        <div class="detail-row"><span>Runtime</span><span id="sandboxRuntime">—</span></div>
                        <div class="detail-row"><span>Memory</span><span id="sandboxMemory">—</span></div>
                        <div class="detail-row"><span>Timeout</span><span id="sandboxTimeout">—</span></div>
                    </div>
                </div>

                <!-- Vector Store -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>🔍 Vector Store</h3>
                        <span class="status-indicator" id="vectorStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="vectorDetails">
                        <div class="detail-row"><span>Documents</span><span id="vectorCount">—</span></div>
                        <div class="detail-row"><span>Backend</span><span id="vectorBackend">—</span></div>
                        <div class="detail-row"><span>Model</span><span id="vectorModel">—</span></div>
                        <div class="detail-row"><span>Dimensions</span><span id="vectorDim">—</span></div>
                    </div>
                </div>

                <!-- Multi-Modal -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>🎨 Multi-Modal</h3>
                        <span class="status-indicator" id="mmStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="mmDetails">
                        <div class="detail-row"><span>Vision</span><span id="mmVision">—</span></div>
                        <div class="detail-row"><span>Audio</span><span id="mmAudio">—</span></div>
                        <div class="detail-row"><span>Document</span><span id="mmDoc">—</span></div>
                    </div>
                </div>

                <!-- Enhanced Memory -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>🧠 Enhanced Memory</h3>
                        <span class="status-indicator" id="memStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="memDetails">
                        <div class="detail-row"><span>Hippocampus</span><span id="memHc">—</span></div>
                        <div class="detail-row"><span>Semantic</span><span id="memSc">—</span></div>
                        <div class="detail-row"><span>WM v2</span><span id="memWm">—</span></div>
                    </div>
                </div>

                <!-- Agent Graphs -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>🕸️ Agent Graphs</h3>
                        <span class="status-indicator" id="graphStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="graphDetails">
                        <div class="detail-row"><span>Graphs</span><span id="graphCount">—</span></div>
                        <div class="detail-row"><span>Running</span><span id="graphRunning">—</span></div>
                    </div>
                </div>

                <!-- Cognitive Kernel -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>🧠 Cognitive Kernel</h3>
                        <span class="status-indicator" id="kernelStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="kernelDetails">
                        <div class="detail-row"><span>Goals</span><span id="kernelGoals">—</span></div>
                        <div class="detail-row"><span>Beliefs</span><span id="kernelBeliefs">—</span></div>
                        <div class="detail-row"><span>WM Slots</span><span id="kernelWm">—</span></div>
                        <div class="detail-row"><span>Unified Loop</span><span id="kernelUnified">—</span></div>
                    </div>
                </div>

                <!-- Agent Society -->
                <div class="status-card">
                    <div class="card-header">
                        <h3>👥 Agent Society</h3>
                        <span class="status-indicator" id="societyStatus">Checking...</span>
                    </div>
                    <div class="status-details" id="societyDetails">
                        <div class="detail-row"><span>Agents</span><span id="societyAgents">—</span></div>
                        <div class="detail-row"><span>Active</span><span id="societyActive">—</span></div>
                        <div class="detail-row"><span>Tenders</span><span id="societyTenders">—</span></div>
                    </div>
                </div>
            </div>

            <div class="status-section">
                <h3>📊 Resource Usage</h3>
                <div class="resource-bars">
                    <div class="resource-bar">
                        <div class="resource-label">CPU</div>
                        <div class="bar-container"><div class="bar-fill" id="cpuBar" style="width: 0%"></div></div>
                        <span class="resource-value" id="cpuValue">—</span>
                    </div>
                    <div class="resource-bar">
                        <div class="resource-label">Memory</div>
                        <div class="bar-container"><div class="bar-fill" id="memBar" style="width: 0%"></div></div>
                        <span class="resource-value" id="memValue">—</span>
                    </div>
                    <div class="resource-bar">
                        <div class="resource-label">Disk</div>
                        <div class="bar-container"><div class="bar-fill" id="diskBar" style="width: 0%"></div></div>
                        <span class="resource-value" id="diskValue">—</span>
                    </div>
                    <div class="resource-bar">
                        <div class="resource-label">GPU</div>
                        <div class="bar-container"><div class="bar-fill" id="gpuBar" style="width: 0%"></div></div>
                        <span class="resource-value" id="gpuValue">N/A (ARM64)</span>
                    </div>
                </div>
            </div>

            <div class="status-section">
                <h3>🔧 Quick Actions</h3>
                <div class="quick-actions">
                    <button class="btn btn-secondary" id="createCheckpoint">💾 Create Checkpoint</button>
                    <button class="btn btn-secondary" id="listCheckpoints">📋 List Checkpoints</button>
                    <button class="btn btn-secondary" id="clearCache">🗑️ Clear Cache</button>
                    <button class="btn btn-danger" id="restartMaya">🔄 Restart Maya</button>
                </div>
            </div>

            <div class="status-section">
                <h3>📋 Recent Audit Log</h3>
                <div id="auditLog" class="audit-log">
                    <div class="loading">Loading...</div>
                </div>
            </div>
        `;
    }

    bindEvents() {
        this.container.querySelector('#refreshStatus').addEventListener('click', () => this.loadStatus());
        this.container.querySelector('#runHealthCheck').addEventListener('click', () => this.runHealthCheck());
        this.container.querySelector('#createCheckpoint').addEventListener('click', () => this.createCheckpoint());
        this.container.querySelector('#listCheckpoints').addEventListener('click', () => this.listCheckpoints());
        this.container.querySelector('#clearCache').addEventListener('click', () => this.clearCache());
        this.container.querySelector('#restartMaya').addEventListener('click', () => this.restartMaya());
    }

    async loadStatus() {
        try {
            const [core, enhanced] = await Promise.all([
                this.app.api.get('/api/v1/agent/status'),
                this.app.api.get('/api/v1/enhanced/status').catch(() => ({}))
            ]);

            this.statusData = { ...core, ...enhanced };
            this.updateUI();
        } catch (e) {
            console.error('Status load failed:', e);
        }
    }

    updateUI() {
        const d = this.statusData;

        // Core
        this.setStatus('coreStatus', d.providers?.length ? 'online' : 'offline');
        this.setText('sysVersion', d.version || '2.0.0');
        this.setText('sysUptime', this.formatUptime(process.uptime ? process.uptime() * 1000 : Date.now()));
        this.setText('sysProviders', d.providers?.join(', ') || 'None');
        this.setText('sysTools', d.tools?.length || 0);
        this.setText('sysBudget', `$${d.cost?.budget_usd?.toFixed(2) || 0} / $${d.cost?.budget_usd?.toFixed(2) || 0}`);

        // Enhanced status
        if (d.browser_pool) this.updateBrowser(d.browser_pool);
        if (d.sandbox_executor) this.updateSandbox(d.sandbox_executor);
        if (d.vector_store) this.updateVector(d.vector_store);
        if (d.multimodal) this.updateMultimodal(d.multimodal);
        if (d.hippocampus) this.updateMemory(d.hippocampus, d.semantic_consolidation, d.working_memory_v2);
        if (d.agent_graphs) this.updateGraphs(d.agent_graphs);
        if (d.cognitive_kernel) this.updateKernel(d.cognitive_kernel);
        if (d.agent_society) this.updateSociety(d.agent_society);

        // Resources (would need a separate endpoint)
        this.updateResources();
    }

    setStatus(id, status) {
        const el = this.container.querySelector(`#${id}`);
        if (!el) return;
        el.textContent = status.charAt(0).toUpperCase() + status.slice(1);
        el.className = 'status-indicator ' + (status === 'online' || status === 'enabled' || status === 'Ready' ? 'online' : 
            status === 'offline' || status === 'disabled' ? 'offline' : 'warning');
    }

    setText(id, text) {
        const el = this.container.querySelector(`#${id}`);
        if (el) el.textContent = text;
    }

    updateBrowser(b) {
        this.setStatus('browserStatus', b.enabled ? 'online' : 'offline');
        this.setText('browserContexts', `${b.in_use || 0} / ${b.total_contexts || 0}`);
        this.setText('browserInUse', b.in_use || 0);
        this.setText('browserMax', b.max_contexts || 5);
    }

    updateSandbox(s) {
        this.setStatus('sandboxStatus', s.runtime !== 'native' ? 'online' : 'warning');
        this.setText('sandboxRuntime', s.runtime);
        this.setText('sandboxMemory', `${s.config?.memory_limit_mb || 512}MB`);
        this.setText('sandboxTimeout', `${s.config?.timeout_seconds || 30}s`);
    }

    updateVector(v) {
        this.setStatus('vectorStatus', v.enabled ? 'online' : 'offline');
        this.setText('vectorCount', v.count || 0);
        this.setText('vectorBackend', v.backend || 'chroma');
        this.setText('vectorModel', v.embedding_model || 'all-MiniLM-L6-v2');
        this.setText('vectorDim', v.embedding_dimension || 384);
    }

    updateMultimodal(m) {
        this.setStatus('mmStatus', m.enabled ? 'online' : 'offline');
        this.setText('mmVision', m.vision ? 'Ready' : 'Not loaded');
        this.setText('mmAudio', m.audio ? 'Ready' : 'Not loaded');
        this.setText('mmDoc', m.document ? 'Ready' : 'Not loaded');
    }

    updateMemory(hc, sc, wm) {
        this.setStatus('memStatus', hc?.enabled ? 'online' : 'offline');
        this.setText('memHc', `${hc?.traces || 0} traces, ${hc?.schemas || 0} schemas`);
        this.setText('memSc', `${sc?.beliefs || 0} beliefs, ${sc?.causal_links || 0} links`);
        this.setText('memWm', `${wm?.chunks || 0} chunks, ${wm?.items || 0} items`);
    }

    updateGraphs(g) {
        this.setStatus('graphStatus', g.enabled ? 'online' : 'offline');
        this.setText('graphCount', g.count || 0);
        this.setText('graphRunning', g.running || 0);
    }

    updateKernel(k) {
        this.setStatus('kernelStatus', k.enabled ? 'online' : 'offline');
        this.setText('kernelGoals', k.goals_active || 0);
        this.setText('kernelBeliefs', k.beliefs || 0);
        this.setText('kernelWm', k.wm_slots || 0);
        this.setText('kernelUnified', k.unified_loop ? 'Enabled' : 'Disabled');
    }

    updateSociety(s) {
        this.setStatus('societyStatus', s.enabled ? 'online' : 'offline');
        this.setText('societyAgents', s.total_agents || 0);
        this.setText('societyActive', Object.values(s.by_status || {}).reduce((a, b) => a + (b === 'busy' ? 1 : 0), 0));
        this.setText('societyTenders', s.active_tenders || 0);
    }

    updateResources() {
        // These would come from a system metrics endpoint
        // For now, show placeholders
        this.setResourceBar('cpuBar', 'cpuValue', 0, '—');
        this.setResourceBar('memBar', 'memValue', 0, '—');
        this.setResourceBar('diskBar', 'diskValue', 0, '—');
    }

    setResourceBar(barId, valueId, percent, text) {
        const bar = this.container.querySelector(`#${barId}`);
        const val = this.container.querySelector(`#${valueId}`);
        if (bar) bar.style.width = `${percent}%`;
        if (val) val.textContent = text;
    }

    async runHealthCheck() {
        const btn = this.container.querySelector('#runHealthCheck');
        btn.disabled = true;
        btn.textContent = '🏥 Checking...';

        try {
            // Run health checks on all systems
            const results = await this.app.api.post('/api/v1/system/health', {});
            this.app.showToast('Health check complete', 'success');
            console.log('Health check:', results);
        } catch (e) {
            this.app.showToast('Health check failed: ' + e.message, 'error');
        } finally {
            btn.disabled = false;
            btn.textContent = '🏥 Health Check';
        }
    }

    async createCheckpoint() {
        try {
            const result = await this.app.api.post('/api/v1/checkpoints', { metadata: { manual: true } });
            this.app.showToast('Checkpoint created: ' + result.checkpoint_id, 'success');
        } catch (e) {
            this.app.showToast('Failed: ' + e.message, 'error');
        }
    }

    async listCheckpoints() {
        try {
            const result = await this.app.api.get('/api/v1/checkpoints');
            const checkpoints = result.checkpoints || [];
            if (!checkpoints.length) {
                this.app.showToast('No checkpoints found', 'info');
                return;
            }
            // Show in modal
            this.app.showModal({
                title: 'Checkpoints',
                content: checkpoints.map(c => `
                    <div class="checkpoint-item">
                        <strong>${c.id}</strong> - ${new Date(c.timestamp * 1000).toLocaleString()}
                        <span class="badge ${c.status}">${c.status}</span>
                    </div>
                `).join(''),
                size: 'lg'
            });
        } catch (e) {
            this.app.showToast('Failed: ' + e.message, 'error');
        }
    }

    async clearCache() {
        if (!confirm('Clear all caches?')) return;
        try {
            await this.app.api.post('/api/v1/system/clear-cache', {});
            this.app.showToast('Cache cleared', 'success');
        } catch (e) {
            this.app.showToast('Failed: ' + e.message, 'error');
        }
    }

    async restartMaya() {
        if (!confirm('Restart Maya? This will interrupt any running tasks.')) return;
        try {
            await this.app.api.post('/api/v1/system/restart', {});
            this.app.showToast('Restart initiated', 'success');
            setTimeout(() => window.location.reload(), 5000);
        } catch (e) {
            this.app.showToast('Failed: ' + e.message, 'error');
        }
    }

    startPolling() {
        this.loadStatus();
        this.pollInterval = setInterval(() => this.loadStatus(), 15000);
    }

    stopPolling() {
        if (this.pollInterval) clearInterval(this.pollInterval);
    }

    formatUptime(ms) {
        const sec = Math.floor(ms / 1000);
        const d = Math.floor(sec / 86400);
        const h = Math.floor((sec % 86400) / 3600);
        const m = Math.floor((sec % 3600) / 60);
        return `${d}d ${h}h ${m}m`;
    }
}