// Maya 2.0 ULTRA - Metacognition View
// Confidence/surprise events + episodic memory + experience replay.
export class MetacognitionView {
  constructor(app) {
    this.app = app;
    this.container = null;
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view metacog-view';
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
      <div class="subtabs" id="mcTabs">
        <button class="subtab active" data-tab="monitor">Monitor</button>
        <button class="subtab" data-tab="events">Events</button>
        <button class="subtab" data-tab="episodic">Episodic Memory</button>
        <button class="subtab" data-tab="replay">Experience Replay</button>
      </div>
      <div id="mcBody"><div class="loading-state"><div class="spinner"></div><p>Loading…</p></div></div>`;
  }

  bindEvents() {
    this.container.querySelector('#mcTabs').addEventListener('click', (e) => {
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
    const body = this.container.querySelector('#mcBody');
    try {
      if (this.tab === 'monitor') await this.loadMonitor();
      else if (this.tab === 'events') await this.loadEvents();
      else if (this.tab === 'episodic') await this.loadEpisodic();
      else if (this.tab === 'replay') await this.loadReplay();
    } catch (err) { body.innerHTML = this.flagNotice(err); }
  }

  async loadMonitor() {
    const body = this.container.querySelector('#mcBody');
    let status;
    try { status = await this.app.api.getMetacognitiveStatus(); } catch (err) { body.innerHTML = this.flagNotice(err); return; }
    body.innerHTML = `
      <div class="panel">
        <h3>Metacognitive monitor status</h3>
        <pre class="pre-wrap mono-small">${this.escapeHtml(JSON.stringify(status, null, 2))}</pre>
      </div>
      <div class="panel" style="margin-top:var(--space-3)">
        <h3>Run a monitor pass</h3>
        <p class="muted small">Evaluates current cognitive context for confidence drops, surprises, stalls and uncertainty spikes; recovery handlers may fire.</p>
        <form class="form" id="monForm">
          <div class="form-group"><label class="form-label" for="monCtx">Context (JSON, optional)</label>
            <textarea class="form-textarea" id="monCtx" rows="2" placeholder='{"goal_id": "..."}'></textarea></div>
          <button class="btn btn-secondary btn-sm" type="submit">Monitor now</button>
        </form>
        <div id="monOut" style="margin-top:var(--space-3)"></div>
      </div>`;
    body.querySelector('#monForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      let ctx = {};
      const raw = body.querySelector('#monCtx').value.trim();
      if (raw) { try { ctx = JSON.parse(raw); } catch { this.app.toast.error('Invalid JSON'); return; } }
      try {
        const res = await this.app.api.runMetacognitiveMonitor(ctx);
        body.querySelector('#monOut').innerHTML = (res.events || []).length
          ? `<h4>${res.events.length} event(s)</h4><div class="result-list">${res.events.map(ev =>
              `<div class="result-item"><div class="result-head"><span class="badge badge-warning">${this.escapeHtml(ev.event_type)}</span>
               <span class="muted small">action: ${this.escapeHtml(ev.action_taken || '—')}</span></div></div>`).join('')}</div>`
          : '<p class="muted">No metacognitive events — everything nominal.</p>';
      } catch (err) { this.app.toast.error('Monitor failed', err.message); }
    });
  }

  async loadEvents() {
    const body = this.container.querySelector('#mcBody');
    const types = ['', 'confidence_drop', 'surprise', 'stall', 'resource_exhaustion', 'goal_conflict', 'skill_failure', 'uncertainty_spike', 'recovery_triggered', 'replan_triggered', 'escalation'];
    body.innerHTML = `
      <div class="view-header">
        <select class="form-select" id="evtType" style="width:auto;min-width:180px">
          ${types.map(t => `<option value="${t}">${t || 'All types'}</option>`).join('')}
        </select>
      </div>
      <div id="evtList"><div class="loading-state"><div class="spinner"></div><p>Loading events…</p></div></div>`;
    const loadList = async () => {
      const type = body.querySelector('#evtType').value || null;
      try {
        const res = await this.app.api.getMetacognitiveEvents(type, 60);
        const events = res.events || [];
        body.querySelector('#evtList').innerHTML = events.length ? `
          <div class="result-list">${events.map(ev => `
            <div class="result-item">
              <div class="result-head">
                <span class="badge ${ev.resolved ? 'badge-success' : 'badge-warning'}">${this.escapeHtml(ev.event_type)}</span>
                <span class="muted small">${ev.timestamp ? new Date(ev.timestamp).toLocaleString() : ''}</span>
              </div>
              ${ev.trigger_details ? `<div class="mono-small muted">${this.escapeHtml(typeof ev.trigger_details === 'string' ? ev.trigger_details : JSON.stringify(ev.trigger_details))}</div>` : ''}
              ${ev.action_taken ? `<div class="small">Action: <strong>${this.escapeHtml(ev.action_taken)}</strong>${ev.action_result ? ` — ${this.escapeHtml(String(ev.action_result))}` : ''}</div>` : ''}
            </div>`).join('')}</div>`
          : '<div class="empty-state"><div class="icon">🧭</div><div class="title">No metacognitive events</div><div class="desc">Confidence drops, surprises and recovery triggers appear here as Maya works.</div></div>';
      } catch (err) { body.querySelector('#evtList').innerHTML = this.flagNotice(err); }
    };
    body.querySelector('#evtType').addEventListener('change', loadList);
    loadList();
  }

  async loadEpisodic() {
    const body = this.container.querySelector('#mcBody');
    let stats;
    try { stats = await this.app.api.getEpisodeStats().catch(() => ({})); } catch {}
    body.innerHTML = `
      ${stats && stats.total_episodes != null ? `<div class="stat-grid stat-grid-3">
        <div class="stat-card"><div class="stat-value">${stats.total_episodes}</div><div class="stat-label">Episodes stored</div></div>
        ${stats.success_rate != null ? `<div class="stat-card"><div class="stat-value">${Math.round(stats.success_rate * 100)}%</div><div class="stat-label">Success rate</div></div>` : ''}
        ${stats.successful != null ? `<div class="stat-card"><div class="stat-value">${stats.successful}</div><div class="stat-label">Successful episodes</div></div>` : ''}
      </div>` : ''}
      <div class="search-bar panel">
        <input type="search" class="form-input" id="epQuery" placeholder="Find similar past experiences…">
        <button class="btn btn-secondary btn-sm" id="epSearchBtn">Search</button>
      </div>
      <div id="epList"><div class="loading-state"><div class="spinner"></div><p>Loading recent episodes…</p></div></div>`;
    const renderEpisodes = (eps) => eps.length ? `
      <div class="result-list">${eps.map(ep => `
        <div class="result-item">
          <div class="result-head">
            <span class="badge ${ep.outcome === 'success' || ep.success ? 'badge-success' : 'badge-error'}">${this.escapeHtml(String(ep.outcome ?? (ep.success ? 'success' : 'failure')))}</span>
            <span class="muted small">${ep.timestamp ? new Date(ep.timestamp).toLocaleString() : ''}</span>
          </div>
          <div><strong>Goal:</strong> ${this.escapeHtml(ep.goal || '')}</div>
          ${(ep.steps || []).length ? `<details><summary class="muted small">${ep.steps.length} steps</summary>
            <ol class="plain-list mono-small">${ep.steps.map(s => `<li>${this.escapeHtml(typeof s === 'string' ? s : JSON.stringify(s))}</li>`).join('')}</ol></details>` : ''}
          ${ep.result ? `<div class="pre-wrap mono-small muted">${this.escapeHtml(String(ep.result).slice(0, 400))}</div>` : ''}
        </div>`).join('')}</div>`
      : '<div class="empty-state"><div class="icon">📽️</div><div class="title">No episodes</div><div class="desc">Completed goals are recorded as episodic memories for future grounding.</div></div>';
    try {
      const res = await this.app.api.getEpisodes(30);
      body.querySelector('#epList').innerHTML = renderEpisodes(res.episodes || []);
    } catch (err) { body.querySelector('#epList').innerHTML = this.flagNotice(err); }
    const doSearch = async () => {
      const q = body.querySelector('#epQuery').value.trim();
      if (!q) return;
      try {
        const res = await this.app.api.searchEpisodes(q, 10);
        body.querySelector('#epList').innerHTML = renderEpisodes(res.episodes || []);
      } catch (err) { this.app.toast.error('Search failed', err.message); }
    };
    body.querySelector('#epSearchBtn').addEventListener('click', doSearch);
    body.querySelector('#epQuery').addEventListener('keydown', e => { if (e.key === 'Enter') doSearch(); });
  }

  async loadReplay() {
    const body = this.container.querySelector('#mcBody');
    let stats = {};
    try { stats = await this.app.api.getReplayStats().catch(() => ({})); } catch {}
    body.innerHTML = `
      <div class="panel">
        <h3>Experience replay</h3>
        <p class="muted small">Replays batches of past episodes through the kernel to strengthen skills and beliefs — the same mechanism the consolidation loop runs automatically.</p>
        <button class="btn btn-secondary btn-sm" id="replayBtn">Replay batch</button>
        <div id="replayOut" style="margin-top:var(--space-3)"></div>
        ${Object.keys(stats).length ? `<pre class="pre-wrap mono-small" style="margin-top:var(--space-3)">${this.escapeHtml(JSON.stringify(stats, null, 2))}</pre>` : ''}
      </div>`;
    body.querySelector('#replayBtn').addEventListener('click', async () => {
      try {
        const r = await this.app.api.replayExperience(32);
        body.querySelector('#replayOut').innerHTML =
          `<div class="pipeline-status-card"><h4>Replay complete</h4><pre class="pre-wrap mono-small">${this.escapeHtml(JSON.stringify(r, null, 2))}</pre></div>`;
      } catch (err) { this.app.toast.error('Replay failed', err.message); }
    });
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
