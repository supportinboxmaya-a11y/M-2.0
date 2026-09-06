// Maya 2.0 ULTRA - Self-Model View (Phases 39 + 42)
export class SelfModelView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.proposals = [];
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view selfmodel-view';
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
      <div class="subtabs" id="smTabs">
        <button class="subtab active" data-tab="profile">Profile</button>
        <button class="subtab" data-tab="assess">Assess a goal</button>
        <button class="subtab" data-tab="improve">Self-Improvement</button>
      </div>
      <div id="smBody"><div class="loading-state"><div class="spinner"></div><p>Loading self-model…</p></div></div>`;
    this.tab = 'profile';
  }

  bindEvents() {
    this.container.querySelector('#smTabs').addEventListener('click', (e) => {
      const btn = e.target.closest('.subtab');
      if (!btn) return;
      this.tab = btn.dataset.tab;
      this.container.querySelectorAll('.subtab').forEach(t => t.classList.toggle('active', t === btn));
      this.load();
    });
  }

  async load() {
    const body = this.container.querySelector('#smBody');
    if (this.tab === 'profile') await this.loadProfile();
    else if (this.tab === 'assess') this.renderAssess();
    else if (this.tab === 'improve') await this.loadImprove();
  }

  async loadProfile() {
    const body = this.container.querySelector('#smBody');
    let profile;
    try {
      profile = await this.app.api.getSelfProfile();
    } catch (err) {
      body.innerHTML = `<div class="error-state"><div class="icon">⚠️</div><h3>Failed to load</h3><p>${this.escapeHtml(err.message)}</p></div>`;
      return;
    }
    const byType = profile.by_task_type || {};
    body.innerHTML = `
      <div class="stat-grid stat-grid-3">
        <div class="stat-card"><div class="stat-value">${profile.total_outcomes ?? 0}</div><div class="stat-label">Recorded outcomes</div></div>
        <div class="stat-card"><div class="stat-value">${profile.overall_success_rate != null ? Math.round(profile.overall_success_rate * 100) + '%' : '—'}</div><div class="stat-label">Overall success rate</div></div>
        <div class="stat-card"><div class="stat-value">${Object.keys(byType).length}</div><div class="stat-label">Task types tracked</div></div>
      </div>

      ${Object.keys(byType).length ? `
      <div class="table-container panel">
        <h3>Track record by task type</h3>
        <table class="data-table">
          <thead><tr><th>Task type</th><th>Attempts</th><th>Success</th><th>Avg duration</th><th>Avg quality</th></tr></thead>
          <tbody>${Object.entries(byType).map(([type, s]) => `
            <tr>
              <td><strong>${this.escapeHtml(type)}</strong></td>
              <td>${s.attempts ?? '—'}</td>
              <td>${s.success_rate != null ? `<span class="badge ${s.success_rate >= 0.8 ? 'badge-success' : s.success_rate >= 0.5 ? 'badge-warning' : 'badge-error'}">${Math.round(s.success_rate * 100)}%</span>` : '—'}</td>
              <td>${s.avg_duration != null ? Number(s.avg_duration).toFixed(1) + 's' : '—'}</td>
              <td>${s.avg_quality != null ? Number(s.avg_quality).toFixed(1) : '—'}</td>
            </tr>`).join('')}
          </tbody>
        </table>
      </div>` : '<div class="empty-state"><div class="icon">🪞</div><div class="title">No outcomes recorded yet</div><div class="desc">Every unified-loop goal updates Maya\u2019s track record.</div></div>'}

      <div class="panel-grid">
        <div class="panel"><h3>Strengths</h3>
          ${(profile.strengths || []).length ? profile.strengths.map(s => `<div class="thread-row"><span>${this.escapeHtml(s.task_type)}</span><span class="badge badge-success">${Math.round((s.success_rate || 0) * 100)}% · ${s.attempts} attempts</span></div>`).join('') : '<p class="muted">Not enough data yet (min 2 attempts at ≥80% success).</p>'}
        </div>
        <div class="panel"><h3>Weaknesses</h3>
          ${(profile.weaknesses || []).length ? profile.weaknesses.map(s => `<div class="thread-row"><span>${this.escapeHtml(s.task_type)}</span><span class="badge badge-error">${Math.round((s.success_rate || 0) * 100)}% · ${s.attempts} attempts</span></div>`).join('') : '<p class="muted">No known weaknesses.</p>'}
        </div>
      </div>

      <div class="panel">
        <h3>Traits</h3>
        <form class="form form-inline" id="traitForm">
          <input class="form-input" id="traitKey" placeholder="key" required style="max-width:180px">
          <input class="form-input" id="traitValue" placeholder='value ("curious")' required>
          <button class="btn btn-secondary btn-sm" type="submit">Set trait</button>
        </form>
        <div class="result-list" style="margin-top:var(--space-2)">
          ${Object.entries(profile.traits || {}).map(([k, v]) => `
            <div class="result-item"><div class="result-head"><strong>${this.escapeHtml(k)}</strong></div><div>${this.escapeHtml(typeof v === 'string' ? v : JSON.stringify(v))}</div></div>`).join('') || '<p class="muted">No traits set.</p>'}
        </div>
      </div>`;
    body.querySelector('#traitForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      let value = body.querySelector('#traitValue').value;
      try { value = JSON.parse(value); } catch {}
      try {
        await this.app.api.setSelfTrait(body.querySelector('#traitKey').value.trim(), value);
        this.app.toast.success('Trait recorded');
        this.load();
      } catch (err) { this.app.toast.error('Failed', err.message); }
    });
  }

  renderAssess() {
    const body = this.container.querySelector('#smBody');
    body.innerHTML = `
      <div class="panel">
        <h3>Pre-planning self-check</h3>
        <p class="muted small">Ask Maya how confident it is about a hypothetical goal — the same check planning consults before committing.</p>
        <div class="search-bar">
          <input type="search" class="form-input" id="assessQ" placeholder="e.g. deploy a static site to the VPS">
          <button class="btn btn-secondary btn-sm" id="assessBtn">Assess</button>
        </div>
        <div id="assessOut" style="margin-top:var(--space-4)"></div>
      </div>`;
    const run = async () => {
      const q = body.querySelector('#assessQ').value.trim();
      if (!q) return;
      try {
        const r = await this.app.api.assessSelf(q);
        body.querySelector('#assessOut').innerHTML = `
          <div class="pipeline-status-card">
            <dl class="kv-list">
              <div><dt>Task type</dt><dd><strong>${this.escapeHtml(r.task_type)}</strong></dd></div>
              <div><dt>Prior experience</dt><dd>${r.experience ? `${r.experience.attempts} attempts · ${Math.round((r.experience.success_rate || 0) * 100)}% success` : 'none'}</dd></div>
              <div><dt>Novel task?</dt><dd>${r.novel ? 'Yes — first attempt' : 'No'}</dd></div>
              <div><dt>Known weakness?</dt><dd>${r.known_weakness ? '⚠️ Yes' : 'No'}</dd></div>
            </dl>
            <h4>Recommendation</h4><p>${this.escapeHtml(r.recommendation)}</p>
          </div>`;
      } catch (err) { this.app.toast.error('Assess failed', err.message); }
    };
    body.querySelector('#assessBtn').addEventListener('click', run);
    body.querySelector('#assessQ').addEventListener('keydown', e => { if (e.key === 'Enter') run(); });
  }

  async loadImprove() {
    const body = this.container.querySelector('#smBody');
    let status, gaps, proposals;
    try {
      [status, proposals] = await Promise.all([
        this.app.api.getSelfImproveStatus(),
        this.app.api.getImprovementProposals().catch(() => ({ proposals: [] })),
      ]);
      gaps = status.enabled !== false ? await this.app.api.getSelfImproveGaps().catch(() => ({ gaps: [] })) : { gaps: [] };
    } catch (err) {
      body.innerHTML = `<div class="error-state"><div class="icon">⚠️</div><h3>Failed to load</h3><p>${this.escapeHtml(err.message)}</p></div>`;
      return;
    }
    if (status.enabled === false) {
      body.innerHTML = `<div class="empty-state fade-in"><div class="icon">🔒</div>
        <div class="title">Self-improvement disabled</div>
        <div class="desc">Phase 42 ships OFF by default (Safety Rule 3). Set <code>SELF_IMPROVE_ENABLED=true</code> in the backend to enable gap analysis and propose→approve→execute flows.</div></div>`;
      return;
    }
    this.proposals = proposals.proposals || [];
    const pending = this.proposals.filter(p => p.status === 'proposed');
    body.innerHTML = `
      <div class="stat-grid stat-grid-4">
        <div class="stat-card"><div class="stat-value">${status.gaps_detected ?? gaps.gaps.length}</div><div class="stat-label">Gaps detected</div></div>
        <div class="stat-card"><div class="stat-value">${pending.length}</div><div class="stat-label">Pending proposals</div></div>
        <div class="stat-card"><div class="stat-value">${status.episodes_buffered ?? 0}</div><div class="stat-label">Episodes buffered</div></div>
        <div class="stat-card"><div class="stat-value">${status.skills_distilled_live ?? 0}</div><div class="stat-label">Skills auto-distilled</div></div>
      </div>

      <div class="panel propose-panel">
        <h3>Capability gaps</h3>
        ${gaps.gaps.length ? `<div class="result-list">${gaps.gaps.map(g => `
          <div class="result-item">
            <div class="result-head"><strong>${this.escapeHtml(g.task_type)}</strong>
              <span class="badge ${g.success_rate < 0.3 ? 'badge-error' : 'badge-warning'}">${Math.round(g.success_rate * 100)}% over ${g.attempts} attempts</span></div>
            <div class="muted small">priority ${Number(g.priority).toFixed(1)} · suggested: <code>${this.escapeHtml(g.suggested_action)}</code>
              ${g.covered_by_skills?.length ? ` · covered by skills: ${this.escapeHtml(g.covered_by_skills.join(', '))}` : ''}</div>
            <button class="btn btn-secondary btn-sm" data-propose='${this.escapeHtml(JSON.stringify({ task_type: g.task_type }))}' style="margin-top:var(--space-2)">Draft proposal</button>
          </div>`).join('')}</div>`
        : '<p class="muted">No capability gaps detected — or not enough outcome data yet.</p>'}
      </div>

      <div class="view-header" style="padding-top:var(--space-4)"><h3>Proposals (${this.proposals.length})</h3></div>
      <div class="result-list">
        ${this.proposals.length ? this.proposals.map(p => `
          <div class="result-item">
            <div class="result-head">
              <span class="badge badge-${{ proposed: 'warning', approved: 'primary', executed: 'success', rejected: 'neutral', failed: 'error' }[p.status] || 'neutral'}">${this.escapeHtml(p.status)}</span>
              <span class="badge badge-neutral">${this.escapeHtml(p.type)}</span>
              <span class="muted small">${this.escapeHtml(p.task_type)} · ${new Date((p.created_at || 0) * 1000).toLocaleString()}</span>
            </div>
            <div><code class="mono-small">${this.escapeHtml(p.id)}</code></div>
            ${p.spec ? `<div class="pre-wrap mono-small">${this.escapeHtml(typeof p.spec === 'string' ? p.spec.slice(0, 600) : JSON.stringify(p.spec, null, 2).slice(0, 600))}</div>` : ''}
            ${p.status === 'proposed' ? `<div class="row-actions">
                <button class="btn btn-primary btn-sm" data-pact="approve" data-pid="${this.escapeHtml(p.id)}">Approve</button>
                <button class="btn btn-danger btn-sm" data-pact="reject" data-pid="${this.escapeHtml(p.id)}">Reject</button>
              </div>` : ''}
            ${p.status === 'approved' ? `<div class="row-actions">
                <button class="btn btn-primary btn-sm" data-pact="execute" data-pid="${this.escapeHtml(p.id)}">Execute (AST scan + approval gate apply)</button>
              </div>` : ''}
            ${p.execution_result ? `<div class="pre-wrap mono-small muted">${this.escapeHtml(JSON.stringify(p.execution_result).slice(0, 300))}</div>` : ''}
          </div>`).join('')
        : '<p class="muted">No improvement proposals yet — draft one from a gap above.</p>'}
      </div>
      <div id="proposeOut"></div>`;

    body.querySelectorAll('[data-propose]').forEach(btn => btn.addEventListener('click', async () => {
      try {
        const gap = JSON.parse(btn.dataset.propose.replace(/&quot;/g, '"'));
        await this.app.api.proposeImprovement(gap);
        this.app.toast.success('Proposal drafted (propose-only — nothing executes without your approval)');
        this.load();
      } catch (err) { this.app.toast.error('Proposal failed', err.message); }
    }));
    body.querySelectorAll('[data-pact]').forEach(btn => btn.addEventListener('click', async () => {
      const pid = btn.dataset.pid;
      try {
        if (btn.dataset.pact === 'approve') {
          await this.app.api.decideProposal(pid, true);
          this.app.toast.success('Approved — now execute explicitly when ready');
        } else if (btn.dataset.pact === 'reject') {
          await this.app.api.decideProposal(pid, false);
          this.app.toast.info?.('Rejected');
        } else if (btn.dataset.pact === 'execute') {
          const ok = await this.app.confirm(
            'Executes an owner-approved improvement. Tool code passes the AST safety scan and approval gate before loading. Continue?',
            'Execute proposal',
          );
          if (!ok) return;
          const res = await this.app.api.executeProposal(pid);
          this.app.toast.success(`Executed: ${typeof res === 'object' ? JSON.stringify(res).slice(0, 120) : res}`);
        }
        this.load();
      } catch (err) { this.app.toast.error('Action failed', err.message); }
    }));
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
