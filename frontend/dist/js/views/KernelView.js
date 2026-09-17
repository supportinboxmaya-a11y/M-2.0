// Maya 2.0 ULTRA - Cognitive Kernel View (Phases 18/34–42)
// Read-only introspection + gated mutations through the ONE controller.
export class KernelView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.status = null;
    this.tab = 'overview';
    this.beliefs = [];
    this.pollTimer = null;
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view kernel-view';
      this.render();
      this.bindEvents();
    }
    this.app.viewContainer.appendChild(this.container);
    this.load();
    // Light polling so the state stays live while visible
    this.pollTimer = setInterval(() => { if (this.tab === 'overview') this.loadStatus(); }, 15000);
  }

  hide() {
    if (this.container && this.container.parentNode) {
      this.container.parentNode.removeChild(this.container);
    }
    if (this.pollTimer) { clearInterval(this.pollTimer); this.pollTimer = null; }
  }

  destroy() {}

  render() {
    this.container.innerHTML = `
      <div class="view-header">
        <h2>Cognitive Kernel</h2>
        <div class="view-header-actions">
          <span class="mode-pill" id="kvLoopPill" title="Unified loop controller state">…</span>
          <button class="icon-btn" id="kvRefresh" aria-label="Refresh" title="Refresh">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg>
          </button>
        </div>
      </div>
      <div class="subtabs" id="kvTabs">
        <button class="subtab active" data-tab="overview">Overview</button>
        <button class="subtab" data-tab="wm">Working Memory</button>
        <button class="subtab" data-tab="knowledge">Knowledge &amp; Beliefs</button>
        <button class="subtab" data-tab="simulate">World Simulation</button>
        <button class="subtab" data-tab="checkpoints">Checkpoints</button>
        <button class="subtab" data-tab="audit">Audit</button>
      </div>
      <div id="kvBody"><div class="loading-state"><div class="spinner"></div><p>Loading kernel state…</p></div></div>
    `;
  }

  bindEvents() {
    this.container.querySelector('#kvTabs').addEventListener('click', (e) => {
      const btn = e.target.closest('.subtab');
      if (!btn) return;
      this.tab = btn.dataset.tab;
      this.container.querySelectorAll('.subtab').forEach(t => t.classList.toggle('active', t === btn));
      this.load();
    });
    this.container.querySelector('#kvRefresh').addEventListener('click', () => this.load());
  }

  async load() {
    const body = this.container.querySelector('#kvBody');
    try {
      if (this.tab === 'overview') await this.loadStatus();
      else if (this.tab === 'wm') await this.renderWM();
      else if (this.tab === 'knowledge') await this.renderKnowledge();
      else if (this.tab === 'simulate') this.renderSimulate();
      else if (this.tab === 'checkpoints') await this.renderCheckpoints();
      else if (this.tab === 'audit') await this.renderAudit();
    } catch (err) {
      body.innerHTML = this.flagNotice(err);
    }
  }

  flagNotice(err) {
    const msg = err?.message || String(err);
    const is503 = err?.status === 503 || /503|requires|not enabled|not initialized/i.test(msg);
    if (is503) {
      return `<div class="empty-state fade-in">
        <div class="icon">🔒</div>
        <div class="title">Cognitive kernel disabled</div>
        <div class="desc">${this.escapeHtml(msg)}</div>
        <div class="desc">Set <code>COGNITION_ENABLED=true</code> in the backend environment to enable the unified cognitive loop.</div>
      </div>`;
    }
    return `<div class="error-state"><div class="icon">⚠️</div><h3>Request failed</h3><p>${this.escapeHtml(msg)}</p></div>`;
  }

  setLoopPill() {
    const pill = this.container.querySelector('#kvLoopPill');
    if (!pill || !this.status) return;
    const unified = this.status.controller?.unified_loop_enabled ?? false;
    const exec = this.status.controller?.has_executor ?? false;
    pill.textContent = unified && exec ? 'UNIFIED LOOP · EXECUTOR READY'
      : unified ? 'UNIFIED LOOP · NO EXECUTOR'
      : 'LEGACY PIPELINE';
    pill.classList.toggle('pill-ok', unified && exec);
    pill.classList.toggle('pill-warn', unified && !exec);
    pill.classList.toggle('pill-off', !unified);
  }

  async loadStatus() {
    const body = this.container.querySelector('#kvBody');
    try {
      this.status = await this.app.api.getKernelStatus();
    } catch (err) {
      body.innerHTML = this.flagNotice(err);
      return;
    }
    this.setLoopPill();
    const s = this.status;
    const meta = s.metacognitive || {};
    const threads = s.threads || {};
    const pct = (v) => v == null ? '—' : `${Math.round(v * 100)}%`;
    body.innerHTML = `
      <div class="stat-grid">
        <div class="stat-card"><div class="stat-value">${s.goals?.total ?? 0}</div><div class="stat-label">Goals total</div></div>
        <div class="stat-card"><div class="stat-value">${s.goals?.active ?? 0}</div><div class="stat-label">Active goals</div></div>
        <div class="stat-card"><div class="stat-value">${s.goals?.suspended ?? 0}</div><div class="stat-label">Suspended</div></div>
        <div class="stat-card"><div class="stat-value">${s.working_memory?.total_slots ?? '—'}</div><div class="stat-label">WM slots</div></div>
        <div class="stat-card"><div class="stat-value">${s.beliefs ?? '—'}</div><div class="stat-label">Beliefs</div></div>
        <div class="stat-card"><div class="stat-value">${pct(meta.overall_confidence)}</div><div class="stat-label">Confidence</div></div>
        <div class="stat-card"><div class="stat-value">${s.plans?.active ?? 0}</div><div class="stat-label">Active plans</div></div>
        <div class="stat-card"><div class="stat-value">${s.last_checkpoint ? new Date(s.last_checkpoint).toLocaleTimeString() : '—'}</div><div class="stat-label">Last checkpoint</div></div>
      </div>

      <div class="panel-grid">
        <div class="panel">
          <h3>Controller</h3>
          <dl class="kv-list">
            <div><dt>Instance</dt><dd><code>${this.escapeHtml(s.instance_id || '—')}</code></dd></div>
            <div><dt>Version</dt><dd>${this.escapeHtml(s.version || '—')}</dd></div>
            <div><dt>Uptime</dt><dd>${this.fmtUptime(s.uptime)}</dd></div>
            <div><dt>Unified loop</dt><dd>${s.controller?.unified_loop_enabled ? '✅ enabled' : '❌ disabled'}</dd></div>
            <div><dt>Executor</dt><dd>${s.controller?.has_executor ? '✅ registered (Maya pipeline)' : '⚠️ none — goals run propose-only'}</dd></div>
            <div><dt>Active plan</dt><dd><code>${this.escapeHtml(s.active_plan_id || '—')}</code></dd></div>
          </dl>
        </div>
        <div class="panel">
          <h3>Background processes</h3>
          ${Object.entries(threads).length ? Object.entries(threads).map(([n, on]) =>
            `<div class="thread-row"><span>${this.escapeHtml(n)}</span><span class="badge ${on ? 'badge-success' : 'badge-neutral'}">${on ? 'running' : 'stopped'}</span></div>`).join('')
            : '<p class="muted">No thread info.</p>'}
          <h3 style="margin-top:var(--space-4)">Metacognition</h3>
          <dl class="kv-list">
            <div><dt>Overall confidence</dt><dd>${pct(meta.overall_confidence)}</dd></div>
            <div><dt>Recent replans</dt><dd>${meta.recent_replans ?? 0}</dd></div>
            <div><dt>WM load</dt><dd>${meta.working_memory_load ?? '—'}</dd></div>
          </dl>
        </div>
      </div>`;
  }

  fmtUptime(sec) {
    if (sec == null) return '—';
    const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60);
    return h ? `${h}h ${m}m` : `${m}m`;
  }

  async renderWM() {
    const body = this.container.querySelector('#kvBody');
    let capacity = null;
    try { capacity = await this.app.api.getWorkingMemoryCapacity(); } catch {}
    body.innerHTML = `
      ${capacity ? `<div class="stat-grid stat-grid-3">
        <div class="stat-card"><div class="stat-value">${capacity.total_slots}</div><div class="stat-label">Slots in use</div></div>
        <div class="stat-card"><div class="stat-value">${Number(capacity.total_attention || 0).toFixed(1)}</div><div class="stat-label">Total attention</div></div>
        <div class="stat-card"><div class="stat-value">${Object.keys(capacity.by_type || {}).length}</div><div class="stat-label">Slot types</div></div>
      </div>` : ''}
      <div class="panel-grid">
        <div class="panel">
          <h3>Add to working memory</h3>
          <form class="form" id="wmAddForm">
            <div class="form-group"><label class="form-label" for="wmContent">Content</label>
              <textarea class="form-textarea" id="wmContent" rows="2" required placeholder="A fact, observation or hypothesis Maya should hold…"></textarea></div>
            <div class="form-row">
              <div class="form-group"><label class="form-label" for="wmType">Type</label>
                <select class="form-select" id="wmType">
                  <option value="fact">fact</option><option value="goal">goal</option><option value="plan">plan</option>
                  <option value="observation">observation</option><option value="hypothesis">hypothesis</option>
                </select></div>
              <div class="form-group"><label class="form-label" for="wmAttention">Attention (0–1)</label>
                <input type="number" class="form-input" id="wmAttention" value="1.0" min="0" max="1" step="0.1"></div>
            </div>
            <button class="btn btn-primary btn-sm" type="submit">Add slot</button>
          </form>
        </div>
        <div class="panel">
          <h3>Search working memory</h3>
          <div class="search-bar">
            <input type="search" class="form-input" id="wmQuery" placeholder="Search content…">
            <button class="btn btn-secondary btn-sm" id="wmSearchBtn">Search</button>
          </div>
          <div id="wmResults" class="result-list"><p class="muted">Type a query to inspect what Maya is currently attending to.</p></div>
        </div>
      </div>`;
    this.container.querySelector('#wmAddForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      try {
        await this.app.api.addWorkingMemory(
          this.container.querySelector('#wmContent').value.trim(),
          this.container.querySelector('#wmType').value,
          parseFloat(this.container.querySelector('#wmAttention').value) || 1.0,
        );
        this.app.toast.success('Added to working memory');
        this.renderWM();
      } catch (err) { this.app.toast.error('Failed', err.message); }
    });
    const doSearch = async () => {
      const q = this.container.querySelector('#wmQuery').value.trim();
      if (!q) return;
      try {
        const res = await this.app.api.searchWorkingMemory(q, 15);
        const items = res.results || [];
        const el = this.container.querySelector('#wmResults');
        el.innerHTML = items.length ? items.map(r => `
          <div class="result-item">
            <div class="result-head"><span class="badge badge-neutral">${this.escapeHtml(r.slot_type)}</span>
              <span class="muted small">attention ${Number(r.attention || 0).toFixed(2)} · accessed ×${r.access_count ?? 0}</span></div>
            <div>${this.escapeHtml(r.content)}</div>
          </div>`).join('') : '<p class="muted">No matching slots.</p>';
      } catch (err) { this.app.toast.error('Search failed', err.message); }
    };
    this.container.querySelector('#wmSearchBtn').addEventListener('click', doSearch);
    this.container.querySelector('#wmQuery').addEventListener('keydown', (e) => { if (e.key === 'Enter') doSearch(); });
  }

  async renderKnowledge() {
    const body = this.container.querySelector('#kvBody');
    let stats = {};
    try { stats = await this.app.api.getKnowledgeStats(); } catch {}
    body.innerHTML = `
      <div class="stat-grid stat-grid-3">
        <div class="stat-card"><div class="stat-value">${stats.total ?? '—'}</div><div class="stat-label">Beliefs</div></div>
        <div class="stat-card"><div class="stat-value">${stats.avg_confidence != null ? Number(stats.avg_confidence).toFixed(2) : '—'}</div><div class="stat-label">Avg confidence</div></div>
        <div class="stat-card"><div class="stat-value">${this.escapeHtml(stats.retrieval_engine || '—')}</div><div class="stat-label">Retrieval engine</div></div>
      </div>
      <div class="panel-grid">
        <div class="panel">
          <h3>Teach Maya (belief revision)</h3>
          <form class="form" id="learnForm">
            <div class="form-group"><label class="form-label" for="learnProp">Proposition</label>
              <textarea class="form-textarea" id="learnProp" rows="2" required placeholder="e.g. The deploy VPS runs Docker 29.1.3"></textarea></div>
            <div class="form-row">
              <div class="form-group"><label class="form-label" for="learnConf">Confidence (0–1)</label>
                <input type="number" class="form-input" id="learnConf" value="0.6" min="0" max="1" step="0.05"></div>
              <div class="form-group"><label class="form-label" for="learnSource">Source</label>
                <select class="form-select" id="learnSource">
                  <option>testimony</option><option>observation</option><option>inference</option><option>assumption</option>
                </select></div>
              <div class="form-group"><label class="form-label" for="learnDomain">Domain</label>
                <input class="form-input" id="learnDomain" value="general"></div>
            </div>
            <button class="btn btn-primary btn-sm" type="submit">Learn</button>
            <p class="muted small">Agreeing evidence strengthens an existing belief; conflicting evidence weakens it — no duplicates.</p>
          </form>
          <h3 style="margin-top:var(--space-4)">Query knowledge</h3>
          <div class="search-bar">
            <input type="search" class="form-input" id="kqInput" placeholder="What does Maya know about…?">
            <button class="btn btn-secondary btn-sm" id="kqBtn">Query</button>
          </div>
          <div id="kqResults" class="result-list"></div>
        </div>
        <div class="panel">
          <h3>Belief store</h3>
          <div class="form-row">
            <div class="form-group"><label class="form-label" for="bDomain">Domain filter</label>
              <input class="form-input" id="bDomain" placeholder="(all)"></div>
            <div class="form-group"><label class="form-label" for="bMinConf">Min confidence</label>
              <input type="number" class="form-input" id="bMinConf" value="0" min="0" max="1" step="0.05"></div>
            <div class="form-group" style="align-self:end"><button class="btn btn-secondary btn-sm" id="bLoadBtn">Load beliefs</button></div>
          </div>
          <div id="beliefList" class="result-list"><p class="muted">Load beliefs to browse Maya's current world model.</p></div>
        </div>
      </div>`;

    this.container.querySelector('#learnForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      try {
        const res = await this.app.api.learnKnowledge(this.container.querySelector('#learnProp').value.trim(), {
          confidence: parseFloat(this.container.querySelector('#learnConf').value) || 0.6,
          source: this.container.querySelector('#learnSource').value,
          domain: this.container.querySelector('#learnDomain').value.trim() || 'general',
        });
        this.app.toast.success(`Learned · confidence now ${Number(res.confidence).toFixed(2)}`);
      } catch (err) { this.app.toast.error('Learn failed', err.message); }
    });

    const doQuery = async () => {
      const q = this.container.querySelector('#kqInput').value.trim();
      if (!q) return;
      try {
        const res = await this.app.api.knowledgeQuery(q, null, 8);
        const el = this.container.querySelector('#kqResults');
        el.innerHTML = (res.results || []).length ? res.results.map(r => `
          <div class="result-item">
            <div class="result-head"><span class="badge badge-primary">${Number(r.score).toFixed(3)}</span>
              <span class="muted small">conf ${Number(r.confidence).toFixed(2)} · ${this.escapeHtml(r.domain)} · ${this.escapeHtml(r.source)}</span></div>
            <div>${this.escapeHtml(r.proposition)}</div>
          </div>`).join('') : '<p class="muted">No relevant knowledge found.</p>';
      } catch (err) { this.app.toast.error('Query failed', err.message); }
    };
    this.container.querySelector('#kqBtn').addEventListener('click', doQuery);
    this.container.querySelector('#kqInput').addEventListener('keydown', (e) => { if (e.key === 'Enter') doQuery(); });

    this.container.querySelector('#bLoadBtn').addEventListener('click', async () => {
      const domain = this.container.querySelector('#bDomain').value.trim() || null;
      const minConf = parseFloat(this.container.querySelector('#bMinConf').value) || 0;
      try {
        const res = await this.app.api.queryBeliefs(domain, minConf);
        const list = (res.beliefs || []).sort((a, b) => b.confidence - a.confidence).slice(0, 100);
        const el = this.container.querySelector('#beliefList');
        el.innerHTML = list.length ? list.map(b => `
          <div class="result-item">
            <div class="result-head"><span class="conf-dot" data-conf="${b.confidence}"></span>
              <span class="muted small">${Number(b.confidence).toFixed(2)} · ${this.escapeHtml(b.domain)} · ${this.escapeHtml(b.source)}</span></div>
            <div>${this.escapeHtml(b.proposition)}</div>
          </div>`).join('') : '<p class="muted">No beliefs match the filter.</p>';
      } catch (err) { this.app.toast.error('Failed to load beliefs', err.message); }
    });
  }

  renderSimulate() {
    const body = this.container.querySelector('#kvBody');
    body.innerHTML = `
      <div class="panel">
        <h3>Simulate an action against Maya's world models</h3>
        <p class="muted small">Runs the action through the domain world model (filesystem, codebase, docker, server…) — prediction only, zero side effects.</p>
        <form class="form" id="simForm">
          <div class="form-row">
            <div class="form-group"><label class="form-label" for="simDomain">Domain</label>
              <select class="form-select" id="simDomain">
                <option>general</option><option>filesystem</option><option>codebase</option><option>server</option>
                <option>docker</option><option>browser</option><option>api</option><option>database</option>
              </select></div>
            <div class="form-group"><label class="form-label" for="simAction">Action type</label>
              <input class="form-input" id="simAction" required placeholder="e.g. write_file / restart_container"></div>
          </div>
          <div class="form-group"><label class="form-label" for="simParams">Parameters (JSON)</label>
            <textarea class="form-textarea" id="simParams" rows="3" placeholder='{"path": "/tmp/x"}'></textarea></div>
          <button class="btn btn-secondary btn-sm" type="submit">Run simulation</button>
        </form>
        <div id="simResult" style="margin-top:var(--space-4)"></div>
      </div>`;
    this.container.querySelector('#simForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      let params = {};
      const raw = this.container.querySelector('#simParams').value.trim();
      if (raw) { try { params = JSON.parse(raw); } catch { this.app.toast.error('Invalid JSON parameters'); return; } }
      try {
        const r = await this.app.api.simulateAction(this.container.querySelector('#simAction').value.trim(), params, this.container.querySelector('#simDomain').value);
        this.container.querySelector('#simResult').innerHTML = `
          <div class="pipeline-status-card">
            <h4>Simulation ${r.success ? 'succeeded' : 'failed'}</h4>
            <dl class="kv-list">
              <div><dt>Reward</dt><dd>${r.reward ?? '—'}</dd></div>
              <div><dt>Confidence</dt><dd>${r.confidence != null ? Number(r.confidence).toFixed(2) : '—'}</dd></div>
              ${r.error ? `<div><dt>Error</dt><dd>${this.escapeHtml(r.error)}</dd></div>` : ''}
            </dl>
            ${r.effects && r.effects.length ? `<h4>Predicted effects</h4><ul class="plain-list">${r.effects.map(x => `<li><code>${this.escapeHtml(JSON.stringify(x))}</code></li>`).join('')}</ul>` : ''}
          </div>`;
      } catch (err) { this.app.toast.error('Simulation failed', err.message); }
    });
  }

  async renderCheckpoints() {
    const body = this.container.querySelector('#kvBody');
    let checkpoints = [];
    let failed = null;
    try {
      checkpoints = (await this.app.api.getKernelCheckpoints()).checkpoints || [];
    } catch (err) { failed = err; }
    if (failed && failed.status !== 200 && !Array.isArray(checkpoints)) {
      // fall through — still allow creating one
    }
    body.innerHTML = `
      <div class="view-header" style="padding-top:0">
        <h3>State checkpoints</h3>
        <button class="btn btn-primary btn-sm" id="cpCreateBtn">Create checkpoint</button>
      </div>
      <p class="muted small">Snapshots of goals, working memory, beliefs and plans. Restoring overwrites current kernel state — confirm before restoring.</p>
      <div class="table-container">
        <table class="data-table">
          <thead><tr><th>ID</th><th>When</th><th>Goals</th><th>WM slots</th><th>Beliefs</th><th>Plans</th><th></th></tr></thead>
          <tbody>
            ${checkpoints.length ? checkpoints.map(c => `
              <tr>
                <td><code>${this.escapeHtml(String(c.id).slice(-14))}</code></td>
                <td>${c.timestamp ? new Date(c.timestamp * (c.timestamp > 1e12 ? 1 : 1000)).toLocaleString() : '—'}</td>
                <td>${c.goals ?? Object.keys(c.goals || {}).length}</td>
                <td>${c.wm_slots ?? Object.keys(c.working_memory || {}).length}</td>
                <td>${c.beliefs ?? Object.keys(c.beliefs || {}).length}</td>
                <td>${c.plans ?? Object.keys(c.plans || {}).length}</td>
                <td><button class="btn btn-danger btn-sm" data-cp="${this.escapeHtml(c.id)}">Restore</button></td>
              </tr>`).join('')
            : '<tr><td colspan="7" class="muted">No checkpoints yet.</td></tr>'}
          </tbody>
        </table>
      </div>`;
    this.container.querySelector('#cpCreateBtn').addEventListener('click', async () => {
      try {
        const res = await this.app.api.createKernelCheckpoint();
        this.app.toast.success(`Checkpoint created: ${String(res.checkpoint_id).slice(-10)}`);
        this.renderCheckpoints();
      } catch (err) { this.app.toast.error('Checkpoint failed', err.message); }
    });
    body.querySelectorAll('[data-cp]').forEach(btn => btn.addEventListener('click', async () => {
      const ok = await this.app.confirm('Restoring will overwrite the current kernel state (goals, working memory, beliefs, plans). Continue?', 'Restore checkpoint');
      if (!ok) return;
      try {
        const res = await this.app.api.restoreKernelCheckpoint(btn.dataset.cp);
        if (res.restored) this.app.toast.success('Checkpoint restored');
        else this.app.toast.error('Restore failed');
      } catch (err) { this.app.toast.error('Restore failed', err.message); }
    }));
  }

  async renderAudit() {
    const body = this.container.querySelector('#kvBody');
    try {
      const audit = (await this.app.api.getKernelAudit()).audit || [];
      body.innerHTML = audit.length ? `
        <div class="result-list">
          ${audit.slice().reverse().map(a => `
            <div class="result-item">
              <div class="result-head">
                <span class="badge badge-neutral">${this.escapeHtml(a.event_type || a.event || '')}</span>
                <span class="muted small">${a.timestamp ? new Date(a.timestamp * 1000).toLocaleString() : ''}</span>
              </div>
              <div class="mono-small">${this.escapeHtml(typeof a.details === 'string' ? a.details : JSON.stringify(a.details || a))}</div>
            </div>`).join('')}
        </div>`
        : '<div class="empty-state"><div class="icon">📜</div><div class="title">No audit rows returned</div><div class="desc">The kernel writes an audit row for every cognition step; none available yet.</div></div>';
    } catch (err) { body.innerHTML = this.flagNotice(err); }
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
