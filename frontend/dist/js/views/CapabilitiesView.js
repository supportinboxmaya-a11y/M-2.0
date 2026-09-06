// Maya 2.0 ULTRA - Capability Registry View (Phase 18)
export class CapabilitiesView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.caps = [];
    this.stats = {};
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view caps-view';
      this.render();
      this.bindEvents();
    }
    this.app.viewContainer.appendChild(this.container);
    this.load();
  }

  hide() {
    if (this.container && this.container.parentNode) this.container.parentNode.removeChild(this.container);
  }

  destroy() {}

  render() {
    this.container.innerHTML = `
      <div class="view-header">
        <h2>Capability Registry</h2>
        <button class="icon-btn" id="capRefresh" aria-label="Refresh" title="Refresh">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg>
        </button>
      </div>
      <div class="search-bar panel">
        <input type="search" class="form-input" id="capSearch" placeholder="Search capabilities by name or description…">
        <select class="form-select" id="capTypeFilter" style="max-width:180px">
          <option value="">All types</option>
          <option value="tool">tool</option>
          <option value="skill">skill</option>
          <option value="model">model</option>
          <option value="agent">agent</option>
          <option value="workflow">workflow</option>
          <option value="mcp_tool">mcp_tool</option>
        </select>
      </div>
      <div id="capBody"><div class="loading-state"><div class="spinner"></div><p>Loading capabilities…</p></div></div>`;
  }

  bindEvents() {
    this.container.querySelector('#capRefresh').addEventListener('click', () => this.load());
    let t;
    this.container.querySelector('#capSearch').addEventListener('input', (e) => {
      clearTimeout(t);
      t = setTimeout(() => this.search(e.target.value.trim()), 300);
    });
    this.container.querySelector('#capTypeFilter').addEventListener('change', () => this.load());
  }

  flagNotice(err) {
    const msg = err?.message || String(err);
    if (err?.status === 503 || /COGNITION_ENABLED|not enabled/i.test(msg)) {
      return `<div class="empty-state fade-in"><div class="icon">🔒</div><div class="title">Cognition disabled</div><div class="desc">${this.escapeHtml(msg)}</div></div>`;
    }
    return `<div class="error-state"><div class="icon">⚠️</div><h3>Request failed</h3><p>${this.escapeHtml(msg)}</p></div>`;
  }

  async load() {
    const body = this.container.querySelector('#capBody');
    const type = this.container.querySelector('#capTypeFilter').value || null;
    try {
      const [res, stats] = await Promise.all([
        this.app.api.getCapabilities({ type, limit: 200 }),
        this.app.api.getCapabilityStats().catch(() => ({})),
      ]);
      this.caps = res.capabilities || [];
      this.stats = stats || {};
    } catch (err) { body.innerHTML = this.flagNotice(err); return; }
    const s = this.stats;
    body.innerHTML = `
      ${s.total != null ? `<div class="stat-grid stat-grid-3">
        <div class="stat-card"><div class="stat-value">${s.total}</div><div class="stat-label">Registered capabilities</div></div>
        <div class="stat-card"><div class="stat-value">${s.by_type ? Object.keys(s.by_type).length : '—'}</div><div class="stat-label">Types</div></div>
        <div class="stat-card"><div class="stat-value">${s.verified ?? '—'}</div><div class="stat-label">Verified</div></div>
      </div>` : ''}
      <div class="result-list">
        ${this.caps.length ? this.caps.map(c => `
          <div class="result-item cap-row" data-id="${this.escapeHtml(c.id)}">
            <div class="result-head">
              <strong>${this.escapeHtml(c.name || c.id)}</strong>
              <span class="badge badge-neutral">${this.escapeHtml(c.type)}</span>
              ${c.verified ? '<span class="badge badge-success">verified</span>' : ''}
              ${c.status ? `<span class="muted small">${this.escapeHtml(c.status)}</span>` : ''}
            </div>
            ${c.description ? `<div class="muted">${this.escapeHtml(c.description)}</div>` : ''}
            ${(c.tags || []).length ? `<div>${c.tags.map(t => `<span class="badge badge-neutral">${this.escapeHtml(t)}</span>`).join(' ')}</div>` : ''}
            <div class="row-actions"><button class="btn btn-secondary btn-sm" data-act="detail">Details & relations</button></div>
          </div>`).join('')
        : '<div class="empty-state"><div class="icon">🧩</div><div class="title">No capabilities registered</div><div class="desc">Tools, skills, agents and MCP tools register here as the kernel discovers them.</div></div>'}
      </div>`;
    body.querySelectorAll('[data-act="detail"]').forEach(btn => btn.addEventListener('click', () => {
      const cap = this.caps.find(c => c.id === btn.closest('[data-id]').dataset.id);
      if (cap) this.showDetail(cap);
    }));
  }

  async search(q) {
    const body = this.container.querySelector('#capBody');
    if (!q) { this.load(); return; }
    try {
      const res = await this.app.api.searchCapabilities(q, 30);
      this.caps = res.capabilities || [];
      const listEl = body.querySelector('.result-list');
      if (listEl) {
        listEl.innerHTML = this.caps.length ? this.caps.map(c => `
          <div class="result-item"><div class="result-head"><strong>${this.escapeHtml(c.name || c.id)}</strong>
          <span class="badge badge-neutral">${this.escapeHtml(c.type)}</span></div>
          ${c.description ? `<div class="muted">${this.escapeHtml(c.description)}</div>` : ''}</div>`).join('')
          : '<p class="muted">No matching capabilities.</p>';
      } else { this.load(); }
    } catch (err) { this.app.toast.error('Search failed', err.message); }
  }

  async showDetail(cap) {
    let relations = {}, composable = [];
    try {
      [relations, composable] = await Promise.all([
        this.app.api.getCapabilityRelations(cap.id).catch(() => ({})),
        this.app.api.getComposableCapabilities(cap.id).catch(() => ({ capabilities: [] })),
      ]);
    } catch {}
    const modal = new this.app.Modal({ title: cap.name || cap.id, size: 'large', confirmText: 'Close', onConfirm: async () => true });
    modal.setContent(`
      <dl class="kv-list">
        <div><dt>ID</dt><dd><code>${this.escapeHtml(cap.id)}</code></dd></div>
        <div><dt>Type</dt><dd>${this.escapeHtml(cap.type)}</dd></div>
        <div><dt>Status</dt><dd>${this.escapeHtml(cap.status || '—')}</dd></div>
        <div><dt>Verified</dt><dd>${cap.verified ? '✅' : 'not yet'}</dd></div>
      </dl>
      ${cap.description ? `<p>${this.escapeHtml(cap.description)}</p>` : ''}
      ${cap.schema ? `<h4>Schema</h4><pre class="pre-wrap mono-small">${this.escapeHtml(JSON.stringify(cap.schema, null, 2))}</pre>` : ''}
      <h4>Relations</h4>
      <div class="result-list">
        ${(relations.outgoing || relations.relations || []).length
          ? (relations.outgoing || relations.relations).map(r => `<div class="result-item"><span class="badge badge-neutral">${this.escapeHtml(r.relation_type || r.type)}</span> → <code>${this.escapeHtml(r.target_id || r.target)}</code></div>`).join('')
          : '<p class="muted">No outgoing relations.</p>'}
      </div>
      <h4>Composable with</h4>
      ${(composable.capabilities || []).length
        ? composable.capabilities.map(c => `<div class="muted small">${this.escapeHtml(c.name || c.id)} (${this.escapeHtml(c.type)})</div>`).join('')
        : '<p class="muted">None found.</p>'}
      <div class="row-actions" style="margin-top:var(--space-3)">
        <button class="btn btn-secondary btn-sm" id="verifyCapBtn">Run verification</button>
      </div>
      <div id="verifyOut" style="margin-top:var(--space-2)"></div>`);
    setTimeout(() => {
      modal.element?.querySelector('#verifyCapBtn')?.addEventListener('click', async () => {
        try {
          const r = await this.app.api.verifyCapability(cap.id);
          modal.element.querySelector('#verifyOut').innerHTML =
            `<div class="pipeline-status-card"><h4>Verification result</h4><pre class="pre-wrap mono-small">${this.escapeHtml(JSON.stringify(r, null, 2))}</pre></div>`;
        } catch (err) { this.app.toast.error('Verification failed', err.message); }
      });
    }, 50);
    modal.open();
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
