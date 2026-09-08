// Maya 2.0 ULTRA - Code Execution View
export class CodeView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.currentLanguage = 'python';
    this.sessions = new Map();
    this.currentSessionId = null;
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view code-view';
      this.render();
      this.bindEvents();
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
        <h2>Code Execution</h2>
        <div class="view-header-actions">
          <button class="btn btn-secondary btn-sm" id="newCodeSessionBtn" title="New session">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            New Session
          </button>
        </div>
      </div>
      <div class="code-layout">
        <div class="code-editor-panel">
          <div class="code-toolbar">
            <select id="codeLanguage" class="form-select" aria-label="Language">
              <option value="python">Python</option>
              <option value="bash">Bash/Shell</option>
            </select>
            <span class="toolbar-divider"></span>
            <button class="btn btn-primary btn-sm" id="runCodeBtn" title="Run code (Ctrl+Enter)">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"></svg>
              Run
            </button>
            <button class="btn btn-secondary btn-sm" id="clearOutputBtn" title="Clear output">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path></svg>
              Clear
            </button>
          </div>
          <div class="code-editor-container">
            <textarea 
              class="code-editor" 
              id="codeEditor" 
              placeholder="Enter code here... (Ctrl+Enter to run)"
              spellcheck="false"
              data-language="python"
            ></textarea>
          </div>
        </div>
        <div class="code-output-panel">
          <div class="output-header">
            <h3>Output</h3>
            <span class="execution-status" id="executionStatus"></span>
          </div>
          <div class="output-content" id="codeOutput">
            <div class="output-placeholder">Output will appear here...</div>
          </div>
        </div>
    `;
  }

  bindEvents() {
    const editor = this.container.querySelector('#codeEditor');
    const languageSelect = this.container.querySelector('#codeLanguage');
    const runBtn = this.container.querySelector('#runCodeBtn');
    const clearBtn = this.container.querySelector('#clearOutputBtn');

    if (runBtn) {
      runBtn.addEventListener('click', () => this.runCode());
    }

    if (clearBtn) {
      clearBtn.addEventListener('click', () => this.clearOutput());
    }

    // Ctrl+Enter to run
    const editor = this.container.querySelector('#codeEditor');
    if (editor) {
      editor.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
          e.preventDefault();
          this.runCode();
        }
      });
    }

    if (this.container.querySelector('#newCodeSessionBtn')) {
      this.container.querySelector('#newCodeSessionBtn').addEventListener('click', () => this.newSession());
    }
  }

  async runCode() {
    const editor = this.container.querySelector('#codeEditor');
    const languageSelect = this.container.querySelector('#codeLanguage');
    const outputEl = this.container.querySelector('#codeOutput');
    const statusEl = this.container.querySelector('#executionStatus');

    const code = editor.value.trim();
    if (!code) return;

    const language = languageSelect.value;

    // Show running status
    this.setExecutionStatus('running', 'Running...');

    outputEl.innerHTML = '<div class="output-streaming">Running...</div>';

    try {
      const response = await this.app.api.request('/api/v1/tools/execute', {
        method: 'POST',
        body: JSON.stringify({
          name: 'code_runner',
          args: { code: editor.value, language: this.currentLanguage }
        })
      });

      if (response.success) {
        this.appendOutput('stdout', response.output);
      } else {
        this.appendOutput('stderr', response.error || 'Execution failed');
      }
    } catch (err) {
      this.appendOutput('error', err.message);
    } finally {
      this.setExecutionStatus('idle', 'Ready');
    }
  }

  appendOutput(type, text) {
    const outputEl = this.container.querySelector('#codeOutput');
    if (!outputEl) return;

    if (outputEl.querySelector('.output-placeholder')) {
      outputEl.innerHTML = '';
    }

    const line = document.createElement('div');
    line.className = `output-line output-${type}`;
    line.textContent = text;
    outputEl.appendChild(line);
    outputEl.scrollTop = outputEl.scrollHeight;
  }

  setExecutionStatus(state, text) {
    const statusEl = this.container.querySelector('#executionStatus');
    if (!statusEl) return;
    
    statusEl.textContent = text;
    statusEl.className = `execution-status status-${state}`;
  }

  clearOutput() {
    const outputEl = this.container.querySelector('#codeOutput');
    if (outputEl) {
      outputEl.innerHTML = '<div class="output-placeholder">Output will appear here...</div>';
    }
    this.setExecutionStatus('idle', 'Ready');
  }

  newSession() {
    const editor = this.container.querySelector('#codeEditor');
    if (editor) {
      editor.value = '';
      this.clearOutput();
    }
  }

  destroy() {}
}