// Maya 2.0 ULTRA - Skills View
// Procedural memory: learned skills, retrieval, composition, distillation.
export class SkillsView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.skills = [];
    this.selected = new Set();
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view skills-view';
      this.render();
      this.bindEvents();
    }
    this.app.viewContainer.appendChild(this.container);
    this.load();
  }

  hide() {
    if (this.container && this.container.parentNode) {
      this.container.parentNode.removeChild(this.container);
    }
  }

  destroy() {}

  render() {
    this.container.innerHTML = `
      <div class="view-header">
        <h2>Skills</h2>
        <div class="view-header-actions">
          <button class="btn btn-secondary btn-sm" id="composeBtn" title="Compose selected skills into a higher-order skill">Compose</button>
          <button class="btn btn-secondary btn-sm" id="distillBtn">Distill from episodes</button>
        </div>
      </div>
      <div id="skBody"><div class="loading-state"><div class="spinner"></div><p>Loading skills…</p></div></div>`;
  }

  bindEvents() {
    this.container.querySelector('#distillBtn').addEventListener('click', () => this.distill(''));
    this.container.querySelector('#composeBtn').addEventListener('click', () => this.compose());
  }

  flagNotice(err) {
    const msg = err?.message || String(err);
    if (err?.status === 503 || /COGNITION_ENABLED|not enabled/i.test(msg)) {
      return `<div class="empty-state fade-in"><div class="icon">🔒</div><div class="title">Cognition disabled</div><div class="desc">${this.escapeHtml(msg)}</div></div>`;
    }
    return `<div class="error-state"><div class="icon">⚠️</div><h3>Request failed</h3><p>${this.escapeHtml(msg)}</p></div>`;
  }

  async load() {
    const body = this.container.querySelector('#skBody');
    let stats = {};
    let replay = {};
    try {
      const [skillsRes, s1, s2] = await Promise.all([
        this.app.api.getSkillsProcedural(false, 200),
        this.app.api.getProceduralStats().catch(() => ({})),
        this.app.api.getReplayStats().catch(() => ({})),
      ]);
      this.skills = skillsRes.skills || [];
      stats = s1 || {};
      replay = s2 || {};
    } catch (err) { body.innerHTML = this.flagNotice(err); return; }

    body.innerHTML = `
      ${Object.keys(stats).length || Object.keys(replay).length ? `<div class="stat-grid stat-grid-4">
        ${stats.total_skills != null ? `<div class="stat-card"><div class="stat-value">${stats.total_skills}</div><div class="stat-label">Skills stored</div></div>` : ''}
        ${stats.retrieval_engine ? `<div class="stat-card"><div class="stat-value small-val">${this.escapeHtml(stats.retrieval_engine)}</div><div class="stat-label">Retrieval engine</div></div>` : ''}
        ${replay.total_replays != null ? `<div class="stat-card"><div class="stat-value">${replay.total_replays}</div><div class="stat-label">Replay batches</div></div>` : ''}
        ${replay.skills_generated != null ? `<div class="stat-card"><div class="stat-value">${replay.skills_generated}</div><div class="stat-label">Skills from replay</div></div>` : ''}
      </div>` : ''}

      <div class="panel">
        <h3>Find applicable skills</h3>
        <div class="search-bar">
          <input type="search" class="form-input" id="skillQuery" placeholder="Which skills apply to…?">
          <button class="btn btn-secondary btn-sm" id="skillSearchBtn">Search</button>
        </div>
        <div id="applicableResults" class="result-list"></div>
      </div>

      <div class="view-header" style="padding-top:var(--space-4)">
        <h3>Skill library (${this.skills.length})</h3>
        <span class="muted small">${this.selected.size} selected for composition</span>
      </div>
      <div class="result-list">
        ${this.skills.length ? this.skills.map(s => `
          <div class="result-item skill-row" data-id="${this.escapeHtml(s.id)}">
            <label class="skill-check"><input type="checkbox" data-sel="${this.escapeHtml(s.id)}"></label>
            <div class="skill-main">
              <div class="result-head">
                <strong>${this.escapeHtml(s.name || s.id)}</strong>
                ${s.verified ? '<span class="badge badge-success">verified</span>' : ''}
                <span class="muted small">conf ${Number(s.confidence ?? 0).toFixed(2)} · used ×${s.usage_count ?? 0}${s.success_rate != null ? ` · success ${Math.round(s.success_rate * 100)}%` : ''}</span>
              </div>
              ${s.description ? `<div class="muted">${this.escapeHtml(s.description)}</div>` : ''}
              ${(s.tags || []).length ? `<div>${s.tags.map(t => `<span class="badge badge-neutral">${this.escapeHtml(t)}</span>`).join(' ')}</div>` : ''}
            </div>
            <div class="row-actions">
              <button class="btn btn-secondary btn-sm" data-act="apply">Mark used ✓</button>
              <button class="btn btn-danger btn-sm" data-act="fail">Mark failed ✗</button>
            </div>
          </div>`).join('')
        : '<div class="empty-state"><div class="icon">🧠</div><div class="title">No skills yet</div><div class="desc">Skills are distilled automatically after repeated successful goals, or manually below.</div></div>'}
      </div>`;

    body.querySelectorAll('[data-sel]').forEach(cb => cb.addEventListener('change', () => {
      if (cb.checked) this.selected.add(cb.dataset.sel); else this.selected.delete(cb.dataset.sel);
    }));
    body.querySelectorAll('[data-act]').forEach(btn => btn.addEventListener('click', async () => {
      const sid = btn.closest('[data-id]').dataset.id;
      try {
        await this.app.api.recordSkillUse(sid, btn.dataset.act === 'apply');
        this.app.toast.success('Usage recorded — Maya learns from skill outcomes');
      } catch (err) { this.app.toast.error('Failed', err.message); }
    }));

    const doSearch = async () => {
      const q = body.querySelector('#skillQuery').value.trim();
      if (!q) return;
      const el = body.querySelector('#applicableResults');
      el.innerHTML = '<p class="muted small">Searching…</p>';
      try {
        const res = await this.app.api.getApplicableSkills(q);
        const items = res.skills || [];
        el.innerHTML = items.length ? items.map(s => `
          <div class="result-item">
            <div class="result-head"><strong>${this.escapeHtml(s.name || s.id)}</strong>
              <span class="muted small">conf ${Number(s.confidence ?? 0).toFixed(2)}</span></div>
            ${s.description ? `<div class="muted">${this.escapeHtml(s.description)}</div>` : ''}
            ${(s.steps || []).length ? `<ol class="plain-list mono-small">${s.steps.map(st => `<li>${this.escapeHtml(typeof st === 'string' ? st : JSON.stringify(st))}</li>`).join('')}</ol>` : ''}
          </div>`).join('') : '<p class="muted">No applicable skills — Maya will attempt fresh planning.</p>';
      } catch (err) { el.innerHTML = `<p class="muted">${this.escapeHtml(err.message)}</p>`; }
    };
    body.querySelector('#skillSearchBtn').addEventListener('click', doSearch);
    body.querySelector('#skillQuery').addEventListener('keydown', e => { if (e.key === 'Enter') doSearch(); });
  }

  async distill(goal) {
    try {
      const res = await this.app.api.distillSkills(goal);
      this.app.toast.success(`${res.skills_created} skill(s) distilled from experience`);
      this.load();
    } catch (err) { this.app.toast.error('Distillation failed', err.message); }
  }

  compose() {
    if (this.selected.size < 2) {
      this.app.toast.error('Select at least 2 skills to compose');
      return;
    }
    const ids = [...this.selected];
    const modal = new this.app.Modal({
      title: 'Compose higher-order skill',
      size: 'medium',
      onConfirm: async () => {
        const name = modal.element.querySelector('#csName').value.trim();
        if (!name) { this.app.toast.error('Name required'); return false; }
        try {
          await this.app.api.composeSkills(ids, name, modal.element.querySelector('#csDesc').value.trim());
          this.app.toast.success(`Composed skill "${name}"`);
          this.selected.clear();
          this.load();
          return true;
        } catch (err) { this.app.toast.error('Composition failed', err.message); return false; }
      },
    });
    modal.setContent(`
      <p class="muted small">Combining ${ids.length} skills into a reusable higher-order skill.</p>
      <div class="form-group"><label class="form-label" for="csName">New skill name *</label>
        <input class="form-input" id="csName" placeholder="e.g. deploy-static-site"></div>
      <div class="form-group"><label class="form-label" for="csDesc">Description</label>
        <textarea class="form-textarea" id="csDesc" rows="2"></textarea></div>`);
    modal.open();
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
