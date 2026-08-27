// Maya 2.0 ULTRA - Agent Society View (Phase 18)
// Spawned agents, task tendering and the shared blackboard.
export class SocietyView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view society-view';
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
      <div class="subtabs" id="soTabs">
        <button class="subtab active" data-tab="agents">Agents</button>
        <button class="subtab" data-tab="tasks">Task Tenders</button>
        <button class="subtab" data-tab="blackboard">Blackboard</button>
      </div>
      <div id="soBody"><div class="loading-state"><div class="spinner"></div><p>Loading society…</p></div></div>`;
    this.tab = 'agents';
  }

  bindEvents() {
    this.container.querySelector('#soTabs').addEventListener('click', (e) => {
      const btn = e.target.closest('.subtab');
      if (!btn) return;
      this.tab = btn.dataset.tab;
      this.container.querySelectorAll('.subtab').forEach(t => t.classList.toggle('active', t === btn));
      this.load();
    });
  }

  flagNotice(err) {
    const msg = err?.message || String(err);
    if (err?.status === 503 || /COGNITION_ENABLED|not enabled/i.test(msg)) {
      return `<div class="empty-state fade-in"><div class="icon">🔒</div><div class="title">Cognition disabled</div><div class="desc">${this.escapeHtml(msg)}</div></div>`;
    }
    return `<div class="error-state"><div class="icon">⚠️</div><h3>Request failed</h3><p>${this.escapeHtml(msg)}</p></div>`;
  }

  async load() {
    const body = this.container.querySelector('#soBody');
    try {
      if (this.tab === 'agents') await this.loadAgents();
      else if (this.tab === 'tasks') await this.loadTasks();
      else if (this.tab === 'blackboard') await this.loadBlackboard();
    } catch (err) { body.innerHTML = this.flagNotice(err); }
  }

  async loadAgents() {
    const body = this.container.querySelector('#soBody');
    let status, agents;
    try {
      [status, agents] = await Promise.all([
        this.app.api.getSocietyStatus(),
        this.app.api.getSocietyAgents(),
      ]);
    } catch (err) { body.innerHTML = this.flagNotice(err); return; }
    const list = agents.agents || [];
    body.innerHTML = `
      ${status && Object.keys(status).length ? `<div class="panel"><h3>Society status</h3>
        <pre class="pre-wrap mono-small">${this.escapeHtml(JSON.stringify(status, null, 2))}</pre></div>` : ''}
      <div class="view-header" style="padding-top:var(--space-4)">
        <h3>Spawned agents (${list.length})</h3>
        <button class="btn btn-secondary btn-sm" id="spawnBtn">Spawn agent</button>
      </div>
      <div class="result-list">
        ${list.length ? list.map(a => `
          <div class="result-item">
            <div class="result-head">
              <strong>${this.escapeHtml(a.name || a.agent_id || a.id)}</strong>
              <span class="badge badge-neutral">${this.escapeHtml(a.role || '')}</span>
              ${a.status ? `<span class="badge ${a.status === 'idle' ? 'badge-success' : 'badge-primary'}">${this.escapeHtml(a.status)}</span>` : ''}
            </div>
            ${a.capabilities?.length ? `<div class="muted small">${a.capabilities.map(c => this.escapeHtml(c)).join(' · ')}</div>` : ''}
            ${(a.current_task || a.task_queue?.length) ? `<div class="muted small">task: ${this.escapeHtml(String(a.current_task || `${a.task_queue.length} queued`))}</div>` : ''}
          </div>`).join('')
        : '<div class="empty-state"><div class="icon">👥</div><div class="title">No spawned agents</div><div class="desc">Maya spawns specialized agents on demand; they coordinate via tenders and the blackboard.</div></div>'}
      </div>`;
    body.querySelector('#spawnBtn')?.addEventListener('click', () => {
      const modal = new this.app.Modal({
        title: 'Spawn agent',
        size: 'small',
        onConfirm: async () => {
          const role = modal.element.querySelector('#spRole').value.trim();
          if (!role) { this.app.toast.error('Role required'); return false; }
          try {
            await this.app.api.spawnSocietyAgent(role);
            this.app.toast.success(`Agent with role "${role}" spawned`);
            this.load();
            return true;
          } catch (err) { this.app.toast.error('Spawn failed', err.message); return false; }
        },
      });
      modal.setContent(`<div class="form-group"><label class="form-label" for="spRole">Role *</label>
        <input class="form-input" id="spRole" placeholder="e.g. researcher, coder, tester"></div>`);
      modal.open();
    });
  }

  async loadTasks() {
    const body = this.container.querySelector('#soBody');
    let agents;
    try { agents = (await this.app.api.getSocietyAgents()).agents || []; }
    catch (err) { body.innerHTML = this.flagNotice(err); return; }
    body.innerHTML = `
      <div class="panel propose-panel">
        <h3>Tender a task</h3>
        <p class="muted small">Publishes a task to eligible agent roles; agents bid with cost/duration/confidence and Maya awards the best bid.</p>
        <form class="form" id="tenderForm">
          <div class="form-group"><label class="form-label" for="tDesc">Task description *</label>
            <textarea class="form-textarea" id="tDesc" rows="2" required placeholder='{"description": "research X", "priority": "high"} or plain text'></textarea></div>
          <div class="form-row form-row-end">
            <input class="form-input" id="tRoles" placeholder="eligible roles (comma-sep, optional)" style="max-width:280px">
            <button class="btn btn-primary btn-sm" type="submit">Publish tender</button>
          </div>
        </form>
        <div id="tenderOut"></div>
      </div>
      <div class="panel">
        <h3>Assign directly to an agent</h3>
        ${agents.length ? `
          <form class="form form-inline" id="assignForm">
            <select class="form-select" id="aAgent" style="max-width:220px">
              ${agents.map(a => `<option value="${this.escapeHtml(a.agent_id || a.id)}">${this.escapeHtml(a.name || a.agent_id || a.id)}</option>`).join('')}
            </select>
            <input class="form-input" id="aTask" placeholder="task JSON" required style="flex:1">
            <button class="btn btn-secondary btn-sm" type="submit">Assign</button>
          </form>`
        : '<p class="muted">No agents available — spawn one first.</p>'}
      </div>`;
    body.querySelector('#tenderForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      let spec = body.querySelector('#tDesc').value.trim();
      try { spec = JSON.parse(spec); } catch { spec = { description: spec }; }
      const rolesRaw = body.querySelector('#tRoles').value.trim();
      try {
        const res = await this.app.api.tenderSocietyTask(spec, null, rolesRaw ? rolesRaw.split(',').map(r => r.trim()) : null);
        body.querySelector('#tenderOut').innerHTML =
          `<div class="pipeline-status-card is-proposal"><h4>Tender published</h4><p class="muted small">Task ID <code>${this.escapeHtml(res.task_id || '')}</code> — agents can now bid.</p>
           <button class="btn btn-primary btn-sm" id="awardNow">Award best bid now</button></div>`;
        body.querySelector('#awardNow')?.addEventListener('click', async () => {
          try {
            const w = await this.app.api.awardSocietyTask(res.task_id);
            this.app.toast.success(`Awarded to: ${w.awarded_to}`);
          } catch (err) { this.app.toast.error('Award failed', err.message); }
        });
      } catch (err) { this.app.toast.error('Tender failed', err.message); }
    });
    body.querySelector('#assignForm')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      let task;
      try { task = JSON.parse(body.querySelector('#aTask').value); }
      catch { this.app.toast.error('Task must be valid JSON'); return; }
      try {
        const r = await this.app.api.assignSocietyTask(body.querySelector('#aAgent').value, task);
        if (r.assigned) this.app.toast.success('Task assigned'); else this.app.toast.error('Assignment rejected');
      } catch (err) { this.app.toast.error('Assign failed', err.message); }
    });
  }

  async loadBlackboard() {
    const body = this.container.querySelector('#soBody');
    body.innerHTML = `
      <div class="panel-grid">
        <div class="panel">
          <h3>Write to blackboard</h3>
          <form class="form" id="bbForm">
            <div class="form-row">
              <div class="form-group"><label class="form-label" for="bbKey">Key *</label><input class="form-input" id="bbKey" required></div>
              <div class="form-group"><label class="form-label" for="bbTTL">TTL seconds</label><input type="number" class="form-input" id="bbTTL" value="3600"></div>
            </div>
            <div class="form-group"><label class="form-label" for="bbValue">Value *</label><textarea class="form-textarea" id="bbValue" rows="2"></textarea></div>
            <div class="form-group"><label class="form-label" for="bbTags">Tags (comma-sep)</label><input class="form-input" id="bbTags"></div>
            <button class="btn btn-primary btn-sm" type="submit">Share</button>
          </form>
        </div>
        <div class="panel">
          <h3>Query blackboard</h3>
          <div class="search-bar">
            <input class="form-input" id="bbPattern" placeholder="key pattern…">
            <button class="btn btn-secondary btn-sm" id="bbQueryBtn">Query</button>
          </div>
          <div id="bbResults" class="result-list"><p class="muted">Shared agent knowledge appears here.</p></div>
        </div>
      </div>`;
    body.querySelector('#bbForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      let value = body.querySelector('#bbValue').value;
      try { value = JSON.parse(value); } catch {}
      try {
        await this.app.api.writeBlackboard(
          this.app.auth.getUser()?.email || 'owner',
          body.querySelector('#bbKey').value.trim(), value,
          body.querySelector('#bbTags').value.split(',').map(t => t.trim()).filter(Boolean),
          parseInt(body.querySelector('#bbTTL').value) || 3600,
        );
        this.app.toast.success('Shared on blackboard');
      } catch (err) { this.app.toast.error('Write failed', err.message); }
    });
    body.querySelector('#bbQueryBtn').addEventListener('click', async () => {
      try {
        const res = await this.app.api.queryBlackboard({ pattern: body.querySelector('#bbPattern').value.trim() });
        const entries = res.entries || [];
        body.querySelector('#bbResults').innerHTML = entries.length ? entries.map(en => `
          <div class="result-item">
            <div class="result-head"><strong>${this.escapeHtml(en.key)}</strong>
              <span class="muted small">by ${this.escapeHtml(en.author || en.agent_id || '?')} · expires in ${Math.max(0, Math.round(((en.expires_at || 0) - Date.now() / 1000)))}s</span></div>
            <div class="pre-wrap mono-small">${this.escapeHtml(typeof en.value === 'string' ? en.value : JSON.stringify(en.value))}</div>
          </div>`).join('') : '<p class="muted">No matching entries.</p>';
      } catch (err) { this.app.toast.error('Query failed', err.message); }
    });
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
