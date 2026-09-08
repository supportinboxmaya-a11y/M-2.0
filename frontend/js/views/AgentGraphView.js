// Maya 2.0 - Agent Graph View
export class AgentGraphView {
    constructor(app) {
        this.app = app;
        this.container = null;
        this.graphs = [];
        this.currentGraph = null;
        this.executionEvents = [];
    }

    show() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.className = 'view agent-graph-view';
        }
        this.container.innerHTML = this.render();
        this.app.viewContainer.appendChild(this.container);
        this.bindEvents();
        this.loadGraphs();
    }

    hide() {
        if (this.container?.parentNode) this.container.parentNode.removeChild(this.container);
    }

    render() {
        return `
            <div class="view-header">
                <h2><span class="icon">🕸️</span> Agent Graphs</h2>
                <div class="view-actions">
                    <button class="btn btn-primary" id="createGraphBtn">
                        <span>+</span> Create Graph
                    </button>
                </div>
            </div>

            <div class="graph-layout">
                <div class="graph-sidebar">
                    <div class="panel">
                        <h3>Available Graphs</h3>
                        <div id="graphList" class="graph-list">
                            <div class="loading">Loading graphs...</div>
                        </div>
                    </div>

                    <div class="panel">
                        <h3>Templates</h3>
                        <div class="template-buttons">
                            <button class="btn btn-secondary btn-sm template-btn" data-template="research">
                                📚 Research & Write
                            </button>
                            <button class="btn btn-secondary btn-sm template-btn" data-template="code">
                                💻 Code Pipeline
                            </button>
                            <button class="btn btn-secondary btn-sm template-btn" data-template="autonomous">
                                🤖 Autonomous Research
                            </button>
                        </div>
                    </div>
                </div>

                <div class="graph-main">
                    <div id="graphDetail" class="graph-detail">
                        <div class="detail-placeholder">
                            <div class="icon">🕸️</div>
                            <p>Select a graph or create a new one</p>
                        </div>
                    </div>

                    <div id="graphExecution" class="graph-execution" style="display: none;">
                        <div class="execution-header">
                            <h3>Execution: <span id="execGraphName"></span></h3>
                            <div class="execution-controls">
                                <button class="btn btn-danger btn-sm" id="stopExecution">Stop</button>
                            </div>
                        </div>
                        <div class="execution-log" id="executionLog">
                            <div class="empty-state">Waiting for execution...</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Create Graph Modal -->
            <div id="createGraphModal" class="modal-overlay" style="display: none;">
                <div class="modal modal-lg">
                    <div class="modal-header">
                        <h3>Create Agent Graph</h3>
                        <button class="modal-close" id="closeCreateGraph">✕</button>
                    </div>
                    <div class="modal-body">
                        <div class="form-group">
                            <label>Graph Name</label>
                            <input type="text" id="graphName" placeholder="My Research Graph" />
                        </div>
                        <div class="form-group">
                            <label>Description</label>
                            <textarea id="graphDescription" rows="3" placeholder="What does this graph do?"></textarea>
                        </div>
                        <div class="form-group">
                            <label>Template</label>
                            <select id="graphTemplate" class="select">
                                <option value="custom">Custom (Builder)</option>
                                <option value="research">Research & Write</option>
                                <option value="code">Code Generation Pipeline</option>
                                <option value="autonomous">Autonomous Research</option>
                            </select>
                        </div>
                        <div class="modal-actions">
                            <button class="btn btn-secondary" id="cancelCreateGraph">Cancel</button>
                            <button class="btn btn-primary" id="confirmCreateGraph">Create Graph</button>
                        </div>
                    </div>
                </div>
            `;
    }

    bindEvents() {
        // Create graph
        this.container.querySelector('#createGraphBtn').addEventListener('click', () => this.openCreateModal());
        this.container.querySelector('#closeCreateGraph').addEventListener('click', () => this.closeCreateModal());
        this.container.querySelector('#cancelCreateGraph').addEventListener('click', () => this.closeCreateModal());
        this.container.querySelector('#confirmCreateGraph').addEventListener('click', () => this.createGraph());

        // Templates
        this.container.querySelectorAll('.template-btn').forEach(btn => {
            btn.addEventListener('click', () => this.createFromTemplate(btn.dataset.template));
        });

        // Modal overlay
        this.container.querySelector('#createGraphModal').addEventListener('click', (e) => {
            if (e.target.id === 'createGraphModal') this.closeCreateModal();
        });
    }

    async loadGraphs() {
        try {
            const response = await this.app.api.get('/api/v1/agent-graph/list');
            this.graphs = response.graphs || [];
            this.renderGraphList();
        } catch (e) {
            console.error('Failed to load graphs:', e);
            this.container.querySelector('#graphList').innerHTML = '<div class="error">Failed to load graphs</div>';
        }
    }

    renderGraphList() {
        const list = this.container.querySelector('#graphList');
        if (!this.graphs.length) {
            list.innerHTML = '<div class="empty-state">No graphs yet. Create one!</div>';
            return;
        }

        list.innerHTML = this.graphs.map(g => `
            <div class="graph-item ${g.graph_id === this.currentGraph?.graph_id ? 'active' : ''}" 
                 data-graph-id="${g.graph_id}">
                <div class="graph-info">
                    <span class="graph-name">${this.app.escapeHtml(g.name)}</span>
                    <span class="graph-id">${g.graph_id}</span>
                </div>
                <div class="graph-desc">${this.app.escapeHtml(g.description || 'No description')}</div>
            </div>
        `).join('');

        list.querySelectorAll('.graph-item').forEach(item => {
            item.addEventListener('click', () => this.selectGraph(item.dataset.graphId));
        });
    }

    async selectGraph(graphId) {
        this.currentGraph = this.graphs.find(g => g.graph_id === graphId);
        this.renderGraphDetail();
        this.container.querySelectorAll('.graph-item').forEach(el => {
            el.classList.toggle('active', el.dataset.graphId === graphId);
        });
    }

    renderGraphDetail() {
        if (!this.currentGraph) return;

        const detail = this.container.querySelector('#graphDetail');
        detail.innerHTML = `
            <div class="graph-detail-header">
                <h3>${this.app.escapeHtml(this.currentGraph.name)}</h3>
                <span class="badge">${this.currentGraph.graph_id}</span>
            </div>
            <p class="graph-desc">${this.app.escapeHtml(this.currentGraph.description || 'No description')}</p>
            
            <div class="graph-stats">
                <div class="stat"><span class="stat-value">${this.currentGraph.nodes?.length || 0}</span><span class="stat-label">Nodes</span></div>
                <div class="stat"><span class="stat-value">${this.currentGraph.edges?.length || 0}</span><span class="stat-label">Edges</span></div>
            </div>

            <div class="graph-nodes">
                <h4>Nodes</h4>
                <div class="node-list">
                    ${(this.currentGraph.nodes || []).map(n => `
                        <div class="node-item">
                            <span class="node-role">${this.getRoleIcon(n.agent_role)} ${n.name}</span>
                            <span class="node-tools">${(n.tools || []).join(', ') || 'No tools'}</span>
                        </div>
                    `).join('')}
                </div>
            </div>

            <div class="graph-actions">
                <button class="btn btn-primary" id="runGraphBtn">
                    <span>▶</span> Run Graph
                </button>
                <button class="btn btn-secondary" id="editGraphBtn">Edit</button>
                <button class="btn btn-danger" id="deleteGraphBtn">Delete</button>
            </div>
        `;

        // Bind detail actions
        detail.querySelector('#runGraphBtn').addEventListener('click', () => this.runGraph());
        detail.querySelector('#editGraphBtn').addEventListener('click', () => this.editGraph());
        detail.querySelector('#deleteGraphBtn').addEventListener('click', () => this.deleteGraph());
    }

    getRoleIcon(role) {
        const icons = {
            researcher: '🔬',
            coder: '💻',
            planner: '📋',
            executor: '⚡',
            critic: '🔍',
            aggregator: '📊',
            human: '👤',
        };
        return icons[role] || '🤖';
    }

    async runGraph() {
        if (!this.currentGraph) return;

        const input = prompt('Enter input data (JSON) or press Enter for empty:', '{}');
        let inputData = {};
        try {
            inputData = input ? JSON.parse(input) : {};
        } catch {
            return this.app.showToast('Invalid JSON', 'error');
        }

        this.showExecutionPanel();
        this.executionEvents = [];

        try {
            const response = await this.app.api.post('/api/v1/agent-graph/run', {
                graph_id: this.currentGraph.graph_id,
                input_data: inputData
            });

            this.executionEvents = response.events || [];
            this.renderExecutionLog();
            this.app.showToast('Graph execution complete', 'success');
        } catch (e) {
            this.app.showToast('Execution failed: ' + e.message, 'error');
        }
    }

    showExecutionPanel() {
        this.container.querySelector('#graphDetail').style.display = 'none';
        this.container.querySelector('#graphExecution').style.display = 'block';
        this.container.querySelector('#execGraphName').textContent = this.currentGraph.name;
    }

    renderExecutionLog() {
        const log = this.container.querySelector('#executionLog');
        if (!this.executionEvents.length) {
            log.innerHTML = '<div class="empty-state">No events</div>';
            return;
        }

        log.innerHTML = this.executionEvents.map(e => `
            <div class="exec-event ${e.type}">
                <span class="event-time">[${new Date().toLocaleTimeString()}]</span>
                <span class="event-type">${e.type}</span>
                <span class="event-detail">
                    ${e.node_id ? `Node: ${e.node_id}` : ''}
                    ${e.output ? `Output: ${JSON.stringify(e.output).substring(0, 100)}` : ''}
                    ${e.error ? `Error: ${e.error}` : ''}
                </span>
            </div>
        `).join('');
        log.scrollTop = log.scrollHeight;
    }

    openCreateModal() {
        this.container.querySelector('#createGraphModal').style.display = 'flex';
    }

    closeCreateModal() {
        this.container.querySelector('#createGraphModal').style.display = 'none';
    }

    async createGraph() {
        const name = this.container.querySelector('#graphName').value.trim();
        const description = this.container.querySelector('#graphDescription').value.trim();
        const template = this.container.querySelector('#graphTemplate').value;

        if (!name) return this.app.showToast('Enter graph name', 'warning');

        try {
            let graph;
            if (template !== 'custom') {
                // Use template
                const response = await this.app.api.post('/api/v1/agent-graph/create', {
                    name,
                    description,
                    template
                });
                graph = response;
            } else {
                // Would open builder - for now use template
                this.app.showToast('Custom builder coming soon. Using research template.', 'info');
                const response = await this.app.api.post('/api/v1/agent-graph/create', {
                    name,
                    description,
                    template: 'research'
                });
                graph = response;
            }

            this.app.showToast('Graph created', 'success');
            this.closeCreateModal();
            this.loadGraphs();
        } catch (e) {
            this.app.showToast('Failed to create: ' + e.message, 'error');
        }
    }

    async createFromTemplate(template) {
        const name = prompt(`Name for ${template} graph:`, `${template} graph`);
        if (!name) return;

        try {
            await this.app.api.post('/api/v1/agent-graph/create', {
                name,
                description: `Created from ${template} template`,
                template
            });
            this.app.showToast('Graph created from template', 'success');
            this.loadGraphs();
        } catch (e) {
            this.app.showToast('Failed: ' + e.message, 'error');
        }
    }

    async editGraph() {
        this.app.showToast('Graph editor coming soon', 'info');
    }

    async deleteGraph() {
        if (!confirm('Delete this graph?')) return;
        try {
            await this.app.api.delete(`/api/v1/agent-graph/${this.currentGraph.graph_id}`);
            this.app.showToast('Graph deleted', 'success');
            this.currentGraph = null;
            this.container.querySelector('#graphDetail').innerHTML = '<div class="detail-placeholder"><p>Select a graph</p></div>';
            this.loadGraphs();
        } catch (e) {
            this.app.showToast('Failed to delete: ' + e.message, 'error');
        }
    }
}