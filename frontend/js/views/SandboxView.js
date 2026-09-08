// Maya 2.0 - Sandbox Executor View
export class SandboxView {
    constructor(app) {
        this.app = app;
        this.container = null;
        this.history = [];
        this.currentLanguage = 'python';
    }

    show() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.className = 'view sandbox-view';
        }
        this.container.innerHTML = this.render();
        this.app.viewContainer.appendChild(this.container);
        this.bindEvents();
        this.loadStatus();
    }

    hide() {
        if (this.container?.parentNode) this.container.parentNode.removeChild(this.container);
    }

    render() {
        return `
            <div class="view-header">
                <h2><span class="icon">🔒</span> Sandbox Executor</h2>
                <div class="view-actions">
                    <span class="badge" id="sandboxStatus">Checking...</span>
                </div>
            </div>

            <div class="sandbox-layout">
                <div class="sandbox-editor">
                    <div class="editor-toolbar">
                        <select id="languageSelect" class="select">
                            <option value="python">🐍 Python</option>
                            <option value="javascript">📜 JavaScript</option>
                            <option value="typescript">📘 TypeScript</option>
                            <option value="shell">🖥️ Shell</option>
                            <option value="go">🐹 Go</option>
                            <option value="rust">🦀 Rust</option>
                        </select>
                        <div class="toolbar-spacer"></div>
                        <button class="btn btn-secondary btn-sm" id="clearEditor">Clear</button>
                        <button class="btn btn-secondary btn-sm" id="loadExample">Example</button>
                        <button class="btn btn-primary" id="executeBtn">
                            <span class="btn-icon">▶</span> Execute
                        </button>
                    </div>
                    <textarea id="codeEditor" class="code-editor" spellcheck="false" 
                        placeholder="Enter code to execute in secure sandbox..."></textarea>
                </div>

                <div class="sandbox-output">
                    <div class="output-tabs">
                        <button class="tab-btn active" data-tab="stdout">📤 Stdout</button>
                        <button class="tab-btn" data-tab="stderr">⚠ Stderr</button>
                        <button class="tab-btn" data-tab="result">📋 Result</button>
                        <button class="tab-btn" data-tab="artifacts">📦 Artifacts</button>
                    </div>
                    <div class="tab-panels">
                        <div class="tab-panel active" id="stdoutPanel">
                            <pre id="stdoutOutput" class="output-content">No output yet</pre>
                        </div>
                        <div class="tab-panel" id="stderrPanel">
                            <pre id="stderrOutput" class="output-content">No errors</pre>
                        </div>
                        <div class="tab-panel" id="resultPanel">
                            <pre id="resultOutput" class="output-content">No result</pre>
                        </div>
                        <div class="tab-panel" id="artifactsPanel">
                            <div id="artifactsList" class="artifacts-list">No artifacts</div>
                        </div>
                    </div>

                    <div class="execution-meta" id="executionMeta" style="display: none;">
                        <span id="execTime">Time: —</span>
                        <span id="execStatus">Status: —</span>
                        <span id="exitCode">Exit: —</span>
                    </div>
                </div>
            </div>

            <div class="sandbox-history">
                <h3>Execution History</h3>
                <div id="historyList" class="history-list">
                    <div class="empty-state">No executions yet</div>
                </div>
            </div>
        `;
    }

    bindEvents() {
        // Language change
        this.container.querySelector('#languageSelect').addEventListener('change', (e) => {
            this.currentLanguage = e.target.value;
        });

        // Execute
        this.container.querySelector('#executeBtn').addEventListener('click', () => this.execute());

        // Clear
        this.container.querySelector('#clearEditor').addEventListener('click', () => {
            this.container.querySelector('#codeEditor').value = '';
        });

        // Load example
        this.container.querySelector('#loadExample').addEventListener('click', () => this.loadExample());

        // Tab switching
        this.container.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => this.switchTab(btn.dataset.tab));
        });
    }

    async loadStatus() {
        try {
            const response = await this.app.api.get('/api/v1/sandbox/status');
            const status = this.container.querySelector('#sandboxStatus');
            status.textContent = `${response.runtime} • ${response.config.memory_limit_mb}MB • ${response.config.timeout_seconds}s`;
            status.className = 'badge ' + (response.runtime === 'gvisor' ? 'success' : 'warning');
        } catch (e) {
            this.container.querySelector('#sandboxStatus').textContent = 'Unavailable';
            this.container.querySelector('#sandboxStatus').className = 'badge danger';
        }
    }

    async execute() {
        const code = this.container.querySelector('#codeEditor').value.trim();
        if (!code) return this.app.showToast('Enter code to execute', 'warning');

        const btn = this.container.querySelector('#executeBtn');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Executing...';

        try {
            const result = await this.app.api.post('/api/v1/sandbox/execute', {
                code,
                language: this.currentLanguage
            });

            this.showResult(result);
            this.addToHistory(code, result);
            this.app.showToast(
                result.success ? 'Execution successful' : 'Execution failed', 
                result.success ? 'success' : 'error'
            );
        } catch (e) {
            this.app.showToast('Execution error: ' + e.message, 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = '<span class="btn-icon">▶</span> Execute';
        }
    }

    showResult(result) {
        // Update meta
        this.container.querySelector('#execTime').textContent = `Time: ${this.app.formatDuration(result.duration_ms)}`;
        this.container.querySelector('#execStatus').textContent = `Status: ${result.success ? 'Success' : 'Failed'}`;
        this.container.querySelector('#exitCode').textContent = `Exit: ${result.exit_code}`;
        this.container.querySelector('#executionMeta').style.display = 'flex';

        // Update panels
        this.container.querySelector('#stdoutOutput').textContent = result.stdout || '(empty)';
        this.container.querySelector('#stderrOutput').textContent = result.stderr || '(empty)';
        this.container.querySelector('#resultOutput').textContent = JSON.stringify({
            success: result.success,
            exit_code: result.exit_code,
            duration_ms: result.duration_ms,
            artifacts: result.artifacts
        }, null, 2);

        // Artifacts
        const artifactsList = this.container.querySelector('#artifactsList');
        if (result.artifacts && result.artifacts.length) {
            artifactsList.innerHTML = result.artifacts.map(a => `
                <div class="artifact-item">
                    <span class="artifact-name">${this.app.escapeHtml(a)}</span>
                    <button class="btn btn-ghost btn-sm" onclick="window.open('/api/v1/workspace/files/${encodeURIComponent(a.split('/').pop())}')">Open</button>
                </div>
            `).join('');
        } else {
            artifactsList.innerHTML = '<div class="empty-state">No artifacts generated</div>';
        }

        // Switch to appropriate tab
        this.switchTab(result.success ? 'stdout' : 'stderr');
    }

    switchTab(tabName) {
        this.container.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tabName);
        });
        this.container.querySelectorAll('.tab-panel').forEach(panel => {
            panel.classList.toggle('active', panel.id === tabName + 'Panel');
        });
    }

    addToHistory(code, result) {
        this.history.unshift({
            code: code.substring(0, 100),
            language: this.currentLanguage,
            success: result.success,
            time: Date.now(),
            duration: result.duration_ms
        });
        this.history = this.history.slice(0, 20);
        this.renderHistory();
    }

    renderHistory() {
        const list = this.container.querySelector('#historyList');
        if (!this.history.length) {
            list.innerHTML = '<div class="empty-state">No executions yet</div>';
            return;
        }

        list.innerHTML = this.history.map((h, i) => `
            <div class="history-item">
                <div class="history-main">
                    <span class="history-lang">${this.getLangIcon(h.language)}</span>
                    <span class="history-code">${this.app.escapeHtml(h.code)}</span>
                    <span class="history-status ${h.success ? 'success' : 'danger'}">
                        ${h.success ? '✓' : '✗'}
                    </span>
                </div>
                <div class="history-meta">
                    ${this.app.formatDuration(h.duration)} • ${new Date(h.time).toLocaleTimeString()}
                </div>
            </div>
        `).join('');
    }

    getLangIcon(lang) {
        const icons = { python: '🐍', javascript: '📜', typescript: '📘', shell: '🖥️', go: '🐹', rust: '🦀' };
        return icons[lang] || '📄';
    }

    loadExample() {
        const examples = {
            python: `import json
import requests

# Fetch data from API
response = requests.get('https://api.github.com/users/octocat')
data = response.json()

# Process and output
result = {
    'name': data.get('name'),
    'repos': data.get('public_repos'),
    'followers': data.get('followers')
}
print(json.dumps(result, indent=2))`,
            javascript: `// Fetch and process data
const response = await fetch('https://api.github.com/users/octocat');
const data = await response.json();

const result = {
    name: data.name,
    repos: data.public_repos,
    followers: data.followers
};

console.log(JSON.stringify(result, null, 2));`,
            shell: `#!/bin/bash
# System info
echo "=== System Info ==="
uname -a
echo ""
echo "=== Disk Usage ==="
df -h /
echo ""
echo "=== Memory ==="
free -h`,
        };
        this.container.querySelector('#codeEditor').value = examples[this.currentLanguage] || examples.python;
    }
}