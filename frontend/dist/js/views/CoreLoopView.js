// Maya 2.0 ULTRA - Core Loop View (Phase 19 Maya Cognitive Core)
// Identity, loop control, model selection, core checkpoints and audit.
export class CoreLoopView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view coreloop-view';
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
      <div class="subtabs" id="clTabs">
        <button class="subtab active" data-tab="status">Status</button>
        <button class="subtab" data-tab="models">Models</button>
        <button class="subtab" data-tab="checkpoints">Checkpoints</button>
        <button class="subtab" data-tab="audit">Audit</button>
      </div>
      <div id="clBody"><div class="loading-state"><div class="spinner"></div><p>Loading core…</p></div></div>`;
    this.tab = 'status';
  }

  bindEvents() {
    this.container.querySelector('#clTabs').addEventListener('click', (e) => {
      const btn = e.target.closest('.subtab');
      if (!btn) return;
      this.tab = btn.dataset.tab;
      this.container.querySelectorAll('.subtab').forEach(t => t.classList.toggle('active', t === btn));
      this.load();
    });
  }

  async load() {
    const body = this.container.querySelector('#clBody');
    try {
      if (this.tab === 'status') await this.loadStatus();
      else if (this.tab === 'models') await this.loadModels();
      else if (this.tab === 'checkpoints') await this.loadCheckpoints();
      else if (this.tab === 'audit') await this.loadAudit();
    } catch (err) { body.innerHTML = this.flagNotice(err); }
  }

  flagNotice(err) {
    const msg = err?.message || String(err);
    return `<div class="${/not initialized/i.test(msg) ? 'empty-state' : 'error-state'} fade-in">
      <div class="icon">${/not initialized/i.test(msg) ? '💤' : '⚠️'}</div>
      ${/not initialized/i.test(msg)
        ? `<div class="title">Core not initialized</div><div class="desc">${this.escapeHtml(msg)}</div>
           <button class="btn btn-primary btn-sm" id="initCoreBtn">Initialize core</button>`
        : `<h3>Request failed</h3><p>${this.escapeHtml(msg)}</p>`}
    </div>`;
  }

  async loadStatus() {
    const body = this.container.querySelector('#clBody');
    let status, identity;
    const errors = [];
    try { status = await this.app.api.getCoreStatus(); } catch (e) { errors.push(e.message); }
    try { identity = await this.app.api.getCoreIdentity(); } catch {}
    if (errors.length && !status) { body.innerHTML = this.flagNotice(new Error(errors[0])); }
    else {
      body.innerHTML = `
        ${identity ? `<div class="panel"><h3>Identity</h3><pre class="pre-wrap mono-small">${this.escapeHtml(JSON.stringify(identity, null, 2))}</pre></div>` : ''}
        ${status ? `<div class="panel" style="margin-top:var(--space-3)"><h3>Core status</h3>
          <pre class="pre-wrap mono-small">${this.escapeHtml(JSON.stringify(status, null, 2))}</pre></div>` : ''}
        <div class="panel propose-panel" style="margin-top:var(--space-3)">
          <h3>Cognitive loop control</h3>
          <p class="muted small">The continuous loop lets Maya pursue its mission autonomously. Start only after watching propose-only behaviour.</p>
          <div class="row-actions">
            <button class="btn btn-primary btn-sm" id="loopStartBtn">Start loop</button>
            <button class="btn btn-secondary btn-sm" id="loopPauseBtn">Pause</button>
            <button class="btn btn-secondary btn-sm" id="loopResumeBtn">Resume</button>
            <button class="btn btn-danger btn-sm" id="loopStopBtn">Stop</button>
            <button class="btn btn-danger btn-sm" id="shutdownBtn" title="Shutdown the cognitive core and persist state">Shutdown core</button>
          </div>
          <div id="loopOut" style="margin-top:var(--space-3)"></div>
        </div>`;
      const wire = (id, action, confirmMsg, danger) => {
        body.querySelector(id).addEventListener('click', async () => {
          if (confirmMsg) {
            const ok = await this.app.confirm(confirmMsg, 'Confirm');
            if (!ok) return;
          }
          try {
            const r = await this.app.api.coreLoopControl(action);
            body.querySelector('#loopOut').innerHTML =
              `<pre class="pre-wrap mono-small muted">${this.escapeHtml(JSON.stringify(r))}</pre>`;
            this.loadStatus._dirty = true;
          } catch (err) { this.app.toast.error(`${action} failed`, err.message); }
        });
      };
      wire('#loopStartBtn', 'start', 'Start the continuous cognitive loop? Maya will begin pursuing its mission between pauses.');
      wire('#loopPauseBtn', 'pause');
      wire('#loopResumeBtn', 'resume');
      wire('#loopStopBtn', 'stop', 'Stop the cognitive loop?');
      body.querySelector('#initCoreBtn')?.addEventListener('click', async () => {
        try {
          const r = await this.app.api.initializeCore();
          if (r.success) { this.app.toast.success('Core initialized'); this.load(); }
          else this.app.toast.error('Initialization failed');
        } catch (err) { this.app.toast.error('Init failed', err.message); }
      });
      body.querySelector('#shutdownBtn').addEventListener('click', async () => {
        const ok = await this.app.confirm('Shut down the cognitive core and persist all state?', 'Shutdown core');
        if (!ok) return;
        try { await this.app.api.shutdownCore(); this.app.toast.success('Core shut down'); }
        catch (err) { this.app.toast.error('Failed', err.message); }
      });
    }
  }

  async loadModels() {
    const body = this.container.querySelector('#clBody');
    let models;
    try { models = await this.app.api.getCoreModels(); } catch (err) { body.innerHTML = this.flagNotice(err); return; }
    const list = models.models || models.available || [];
    const active = models.active_model || models.active_model_id || '';
    body.innerHTML = `
      ${active ? `<div class="stat-grid stat-grid-3"><div class="stat-card"><div class="stat-value small-val">${this.escapeHtml(active)}</div><div class="stat-label">Active model</div></div></div>` : ''}
      <div class="panel">
        <h3>Model selection</h3>
        <p class="muted small">Models are capabilities Maya uses — switching changes which capability the kernel invokes, never who is in control.</p>
        ${list.length ? `
        <div class="result-list">${list.map(m => {
          const id = m.id || m.model_id || m.name;
          return `<div class="result-item">
            <div class="result-head"><strong>${this.escapeHtml(id)}</strong>
              ${id === active ? '<span class="badge badge-success">active</span>' : ''}
              ${m.provider ? `<span class="badge badge-neutral">${this.escapeHtml(m.provider)}</span>` : ''}</div>
            ${m.description ? `<div class="muted small">${this.escapeHtml(m.description)}</div>` : ''}
            ${id !== active ? `<button class="btn btn-secondary btn-sm" data-model="${this.escapeHtml(id)}">Switch to this model</button>` : ''}
          </div>`;
        }).join('')}</div>`
        : `<pre class="pre-wrap mono-small">${this.escapeHtml(JSON.stringify(models, null, 2))}</pre>`}
      </div>
      <div class="panel" style="margin-top:var(--space-3)">
        <h3>Direct invocation (debug)</h3>
        <form class="form" id="invokeForm">
          <div class="form-group"><label class="form-label" for="invPrompt">Prompt *</label>
            <textarea class="form-textarea" id="invPrompt" rows="2" required></textarea></div>
          <div class="form-row form-row-end">
            <input class="form-input" id="invModel" placeholder="model_id (optional)" style="max-width:240px">
            <select class="form-select" id="invTask" style="max-width:150px">
              <option>general</option><option>coding</option><option>research</option><option>fast</option><option>analysis</option><option>creative</option>
            </select>
            <button class="btn btn-secondary btn-sm" type="submit">Invoke</button>
          </div>
        </form>
        <div id="invokeOut" style="margin-top:var(--space-3)"></div>
      </div>`;
    body.querySelectorAll('[data-model]').forEach(btn => btn.addEventListener('click', async () => {
      try {
        const r = await this.app.api.switchCoreModel(btn.dataset.model);
        if (r.success) { this.app.toast.success(`Active model: ${r.active_model}`); this.load(); }
        else this.app.toast.error('Switch failed');
      } catch (err) { this.app.toast.error('Switch failed', err.message); }
    }));
    body.querySelector('#invokeForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      try {
        const r = await this.app.api.invokeCoreModel(
          body.querySelector('#invPrompt').value.trim(),
          body.querySelector('#invModel').value.trim() || null,
          body.querySelector('#invTask').value,
        );
        body.querySelector('#invokeOut').innerHTML =
          `<pre class="pre-wrap mono-small">${this.escapeHtml(typeof r === 'string' ? r : (r.text || r.result || JSON.stringify(r, null, 2)))}</pre>`;
      } catch (err) { this.app.toast.error('Invoke failed', err.message); }
    });
  }

  async loadCheckpoints() {
    const body = this.container.querySelector('#clBody');
    let cps;
    try { cps = (await this.app.api.getCoreCheckpoints()).checkpoints || []; } catch (err) { body.innerHTML = this.flagNotice(err); return; }
    body.innerHTML = `
      <div class="view-header">
        <h3>Unified checkpoints</h3>
        <button class="btn btn-primary btn-sm" id="cpNewBtn">Create checkpoint</button>
      </div>
      <p class="muted small">Atomic all-or-none snapshots of registered subsystems (memory, learning, task manager).</p>
      <div class="result-list">
        ${cps.length ? cps.map(c => `
          <div class="result-item">
            <div class="result-head"><code>${this.escapeHtml(c.id)}</code>
              <span class="badge ${c.status === 'completed' ? 'badge-success' : 'badge-neutral'}">${this.escapeHtml(c.status || '')}</span>
              <span class="muted small">${c.timestamp ? new Date(c.timestamp * 1000).toLocaleString() : ''}</span></div>
            <button class="btn btn-danger btn-sm" data-cpid="${this.escapeHtml(c.id)}">Restore</button>
          </div>`).join('')
        : '<p class="muted">No unified checkpoints yet.</p>'}
      </div>`;
    body.querySelector('#cpNewBtn').addEventListener('click', async () => {
      try {
        const r = await this.app.api.createCoreCheckpoint();
        this.app.toast.success(`Checkpoint ${r.checkpoint_id}`);
        this.load();
      } catch (err) { this.app.toast.error('Checkpoint failed', err.message); }
    });
    body.querySelectorAll('[data-cpid]').forEach(btn => btn.addEventListener('click', async () => {
      const ok = await this.app.confirm('Restore all subsystems from this checkpoint?', 'Restore checkpoint');
      if (!ok) return;
      try {
        const r = await this.app.api.restoreCoreCheckpoint(btn.dataset.cpid);
        if (r.success) this.app.toast.success('Restored'); else this.app.toast.error('Restore failed');
      } catch (err) { this.app.toast.error('Restore failed', err.message); }
    }));
  }

  async loadAudit() {
    const body = this.container.querySelector('#clBody');
    let audit;
    try { audit = (await this.app.api.getCoreAudit(80)).audit || []; } catch (err) { body.innerHTML = this.flagNotice(err); return; }
    body.innerHTML = audit.length ? `
      <div class="result-list">${audit.slice().reverse().map(a => `
        <div class="result-item">
          <div class="result-head"><span class="badge badge-neutral">${this.escapeHtml(a.event_type || a.event || a.action || '')}</span>
            <span class="muted small">${a.timestamp ? new Date(typeof a.timestamp === 'number' ? a.timestamp * (a.timestamp > 1e12 ? 1 : 1000) : Date.parse(a.timestamp)).toLocaleString() : ''}</span></div>
          <div class="mono-small muted pre-wrap">${this.escapeHtml(typeof a.details === 'string' ? a.details : JSON.stringify(a.details ?? a))}</div>
        </div>`).join('')}</div>`
      : '<div class="empty-state"><div class="icon">📜</div><div class="title">No core audit rows yet</div></div>';
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
