// Maya 2.0 ULTRA - Research & Publish View
// Phase 32 research/market engine (analysis-only) +
// Phase 21 guarded static-site publish (critical approval gate).
export class ResearchView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view research-view';
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
      <div class="subtabs" id="rvTabs">
        <button class="subtab active" data-tab="research">Research Reports</button>
        <button class="subtab" data-tab="publish">Publish History</button>
      </div>
      <div id="rvBody"><div class="loading-state"><div class="spinner"></div><p>Loading…</p></div></div>`;
    this.tab = 'research';
  }

  bindEvents() {
    this.container.querySelector('#rvTabs').addEventListener('click', (e) => {
      const btn = e.target.closest('.subtab');
      if (!btn) return;
      this.tab = btn.dataset.tab;
      this.container.querySelectorAll('.subtab').forEach(t => t.classList.toggle('active', t === btn));
      this.load();
    });
  }

  flagNotice(err, hint) {
    const msg = err?.message || String(err);
    if (err?.status === 503 || /not enabled|ENABLED=true/i.test(msg)) {
      return `<div class="empty-state fade-in"><div class="icon">🔒</div>
        <div class="title">Feature disabled</div><div class="desc">${this.escapeHtml(msg)}</div>
        ${hint ? `<div class="desc">${hint}</div>` : ''}</div>`;
    }
    return `<div class="error-state"><div class="icon">⚠️</div><h3>Request failed</h3><p>${this.escapeHtml(msg)}</p></div>`;
  }

  async load() {
    const body = this.container.querySelector('#rvBody');
    try {
      if (this.tab === 'research') await this.loadResearch();
      else await this.loadPublish();
    } catch (err) { body.innerHTML = this.flagNotice(err); }
  }

  /* ── Research (Phase 32) ─────────────────────────────────────── */
  async loadResearch() {
    const body = this.container.querySelector('#rvBody');
    let reports;
    try { reports = (await this.app.api.getResearchReports()).reports || []; }
    catch (err) {
      body.innerHTML = this.flagNotice(err,
        'Set <code>RESEARCH_ENGINE_ENABLED=true</code> in the backend environment to enable the research engine.');
      return;
    }
    body.innerHTML = `
      <div class="panel propose-panel">
        <h3>Analyze a topic</h3>
        <p class="muted small">Fetches public pages → chunks → LLM summary → local report. Read-only web access, zero external writes.</p>
        <form class="form" id="resForm">
          <div class="form-row">
            <div class="form-group" style="flex:1"><label class="form-label" for="resTopic">Topic *</label>
              <input class="form-input" id="resTopic" required placeholder="e.g. free VPS providers comparison"></div>
            <div class="form-group"><label class="form-label" for="resMax">Max sources</label>
              <input type="number" class="form-input" id="resMax" value="5" min="1" max="20"></div>
          </div>
          <div class="form-group"><label class="form-label" for="resUrls">URLs (optional, one per line)</label>
            <textarea class="form-textarea" id="resUrls" rows="2" placeholder="https://…"></textarea></div>
          <button class="btn btn-primary btn-sm" type="submit">Run analysis</button>
        </form>
        <div id="resOut"></div>
      </div>
      <div class="view-header" style="padding-top:var(--space-4)"><h3>Saved reports (${reports.length})</h3></div>
      <div class="result-list">
        ${reports.length ? reports.map(r => `
          <div class="result-item" data-id="${this.escapeHtml(r.id)}">
            <div class="result-head"><strong>${this.escapeHtml(r.topic)}</strong>
              <span class="muted small">${r.source_count ?? '?'} sources · ${r.created_at ? new Date(r.created_at * (r.created_at > 1e12 ? 1 : 1000)).toLocaleString() : ''}</span></div>
            ${r.summary_short ? `<div class="muted">${this.escapeHtml(String(r.summary_short).slice(0, 200))}</div>` : ''}
            <div class="row-actions"><button class="btn btn-secondary btn-sm" data-ract="open">Open full report</button></div>
          </div>`).join('')
        : '<div class="empty-state"><div class="icon">🔬</div><div class="title">No reports yet</div><div class="desc">Run an analysis above — results are stored locally.</div></div>'}
      </div>`;
    body.querySelector('#resForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const urls = body.querySelector('#resUrls').value.split('\n').map(u => u.trim()).filter(Boolean);
      const out = body.querySelector('#resOut');
      out.innerHTML = '<div class="loading-state"><div class="spinner"></div><p>Maya is researching… (can take a minute)</p></div>';
      try {
        const r = await this.app.api.analyzeResearch({
          topic: body.querySelector('#resTopic').value.trim(),
          urls: urls.length ? urls : undefined,
          max_sources: parseInt(body.querySelector('#resMax').value) || 5,
        });
        if (r.ok === false) throw new Error(r.error || 'Analysis failed');
        out.innerHTML = `<div class="pipeline-status-card"><h4>✅ Report saved</h4>
          <p class="muted small">${r.source_count ?? '—'} sources${r.errors?.length ? ` · ${r.errors.length} fetch errors` : ''}</p></div>`;
        setTimeout(() => this.load(), 800);
      } catch (err) { out.innerHTML = `<div class="error-state"><h3>Failed</h3><p>${this.escapeHtml(err.message)}</p></div>`; }
    });
    body.querySelectorAll('[data-ract="open"]').forEach(btn => btn.addEventListener('click', () => {
      const id = btn.closest('[data-id]').dataset.id;
      this.openReport(id);
    }));
  }

  async openReport(id) {
    let rep;
    try { rep = await this.app.api.getResearchReport(id); }
    catch (err) { this.app.toast.error('Failed to load report', err.message); return; }
    const modal = new this.app.Modal({ title: rep.topic || 'Report', size: 'large', confirmText: 'Close', onConfirm: async () => true });
    modal.setContent(`
      ${rep.urls?.length ? `<p class="muted small">${rep.urls.map(u => `<a href="${this.escapeHtml(u)}" target="_blank" rel="noopener">${this.escapeHtml(u)}</a>`).join('<br>')}</p>` : ''}
      <div class="pre-wrap mono-small" style="max-height:60vh;overflow-y:auto">${this.escapeHtml(rep.summary_long || rep.summary_short || JSON.stringify(rep, null, 2))}</div>`);
    modal.open();
  }

  /* ── Publish (Phase 21) ──────────────────────────────────────── */
  async loadPublish() {
    const body = this.container.querySelector('#rvBody');
    let history;
    try { history = (await this.app.api.getPublishHistory()).history || []; }
    catch (err) { body.innerHTML = this.flagNotice(err); return; }
    body.innerHTML = `
      <div class="panel propose-panel">
        <h3>Publish a static site</h3>
        <p class="muted small">Proposals freeze the exact file contents. Publishing requires the owner's critical-risk approval — Maya can never publish on its own here.</p>
        <form class="form" id="pubForm">
          <div class="form-row">
            <div class="form-group"><label class="form-label" for="pubName">Site name *</label>
              <input class="form-input" id="pubName" required placeholder="my-site"></div>
            <div class="form-group"><label class="form-label" for="pubDesc">Description</label>
              <input class="form-input" id="pubDesc" placeholder="what is being published"></div>
          </div>
          <div class="form-group"><label class="form-label" for="pubFiles">Files (JSON: {"index.html": "&lt;h1&gt;…"}) *</label>
            <textarea class="form-textarea" id="pubFiles" rows="4" required placeholder='{"index.html": "<html>…</html>"}'></textarea></div>
          <button class="btn btn-primary btn-sm" type="submit">Submit proposal</button>
        </form>
        <div id="pubOut"></div>
      </div>
      <div class="view-header" style="padding-top:var(--space-4)"><h3>Publish audit trail (${history.length})</h3></div>
      <div class="result-list">
        ${history.length ? history.map(h => `
          <div class="result-item" data-id="${this.escapeHtml(h.id)}">
            <div class="result-head"><strong>${this.escapeHtml(h.site_name)}</strong>
              <span class="badge badge-${{ published: 'success', proposed: 'warning', rejected: 'neutral', failed: 'error' }[h.action] || 'neutral'}">${this.escapeHtml(h.action)}</span>
              <span class="muted small">${h.created_at ? new Date(h.created_at * (h.created_at > 1e12 ? 1 : 1000)).toLocaleString() : ''}</span></div>
            ${h.description ? `<div class="muted small">${this.escapeHtml(h.description)}</div>` : ''}
            ${h.result_url ? `<div class="small"><a href="${this.escapeHtml(h.result_url)}" target="_blank" rel="noopener">${this.escapeHtml(h.result_url)}</a></div>` : ''}
            <div class="row-actions"><button class="btn btn-secondary btn-sm" data-pact="open">View frozen proposal</button></div>
          </div>`).join('')
        : '<div class="empty-state"><div class="icon">🚀</div><div class="title">No publish proposals yet</div></div>'}
      </div>`;
    body.querySelector('#pubForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      let files;
      try { files = JSON.parse(body.querySelector('#pubFiles').value); }
      catch { this.app.toast.error('Files must be valid JSON'); return; }
      try {
        const r = await this.app.api.publishSite({
          site_name: body.querySelector('#pubName').value.trim(),
          files,
          description: body.querySelector('#pubDesc').value.trim(),
        });
        this.app.toast.success(`Proposal ${r.proposal_id || ''} created — awaiting critical-risk approval`);
        this.load();
      } catch (err) { this.app.toast.error('Proposal failed', err.message); }
    });
    body.querySelectorAll('[data-pact="open"]').forEach(btn => btn.addEventListener('click', () => {
      const id = btn.closest('[data-id]').dataset.id;
      this.openProposal(id);
    }));
  }

  async openProposal(id) {
    let p;
    try { p = await this.app.api.getPublishProposal(id); }
    catch (err) { this.app.toast.error('Failed to load', err.message); return; }
    const modal = new this.app.Modal({ title: `Proposal ${p.id}`, size: 'large', confirmText: 'Close', onConfirm: async () => true });
    modal.setContent(`
      <dl class="kv-list">
        <div><dt>Site</dt><dd>${this.escapeHtml(p.site_name)}</dd></div>
        <div><dt>Action</dt><dd>${this.escapeHtml(p.action)}</dd></div>
        ${p.approver ? `<div><dt>Approver</dt><dd>${this.escapeHtml(p.approver)}</dd></div>` : ''}
        ${p.result_url ? `<div><dt>URL</dt><dd><a href="${this.escapeHtml(p.result_url)}" target="_blank" rel="noopener">${this.escapeHtml(p.result_url)}</a></dd></div>` : ''}
      </dl>
      <h4>Frozen file contents (verbatim)</h4>
      <pre class="pre-wrap mono-small" style="max-height:55vh;overflow-y:auto">${this.escapeHtml(
        Object.entries(p.files || {}).map(([name, content]) => `─── ${name} ───\n${content}`).join('\n\n') || '(none)'
      )}</pre>`);
    modal.open();
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
