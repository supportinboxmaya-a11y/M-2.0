// Maya 2.0 ULTRA - Goals View
// The persistent goal lifecycle through CognitiveKernel.process_goal —
// propose-only by default; execution is an explicit, confirmed choice.
export class GoalsView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.goals = [];
    this.incomplete = [];
    this.statusFilter = '';
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view goals-view';
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
        <h2>Goals</h2>
        <button class="btn btn-primary" id="gvNewGoalBtn">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          New Goal
        </button>
      </div>

      <div class="panel propose-panel">
        <h3>Give Maya a goal</h3>
        <p class="muted small">Runs through <code>kernel.process_goal</code> — grounding → planning → (optionally) gated execution → learning.
        <strong>Propose-only</strong> creates the goal + plan without touching the world.</p>
        <form class="form" id="processForm">
          <div class="form-group">
            <textarea class="form-textarea" id="pgDescription" rows="2" required placeholder="Describe what Maya should pursue…"></textarea>
          </div>
          <div class="form-row form-row-end">
            <label class="form-switch" title="Execute requires confirmation and runs Maya's full gated pipeline">
              <input type="checkbox" class="form-switch-input" id="pgExecute">
              <span class="form-switch-slider"></span>
              <span class="form-switch-label">Execute (not just propose)</span>
            </label>
            <select class="form-select pg-priority" id="pgPriority" aria-label="Priority">
              <option value="25">Low priority</option>
              <option value="50" selected>Normal priority</option>
              <option value="75">High priority</option>
              <option value="100">Critical</option>
            </select>
            <button class="btn btn-primary btn-sm" type="submit" id="pgSubmit">Send to Maya</button>
          </div>
        </form>
        <div id="pgResult"></div>
      </div>

      <div id="gvIncompleteWrap"></div>

      <div class="view-header" style="padding-top:var(--space-4)">
        <h3>All active &amp; suspended goals</h3>
        <select class="form-select" id="gvStatusFilter" style="width:auto;min-width:140px">
          <option value="">All statuses</option>
          <option value="active">active</option>
          <option value="suspended">suspended</option>
          <option value="completed">completed</option>
          <option value="blocked">blocked</option>
          <option value="abandoned">abandoned</option>
        </select>
      </div>
      <div id="gvGoalsList"><div class="loading-state"><div class="spinner"></div><p>Loading goals…</p></div></div>
    `;
  }

  bindEvents() {
    this.container.querySelector('#gvNewGoalBtn').addEventListener('click', () => this.openCreateModal());
    this.container.querySelector('#gvStatusFilter').addEventListener('change', (e) => {
      this.statusFilter = e.target.value;
      this.loadGoals();
    });
    this.container.querySelector('#processForm').addEventListener('submit', (e) => this.processGoal(e));
  }

  async load() {
    await Promise.all([this.loadGoals(), this.loadIncomplete()]);
  }

  statusBadge(status) {
    const cls = { active: 'badge-primary', completed: 'badge-success', blocked: 'badge-error', suspended: 'badge-warning', abandoned: 'badge-neutral' }[status] || 'badge-neutral';
    return `<span class="badge ${cls}">${this.escapeHtml(status)}</span>`;
  }

  async loadGoals() {
    const el = this.container.querySelector('#gvGoalsList');
    try {
      const res = await this.app.api.getKernelGoals(this.statusFilter || null);
      this.goals = res.goals || [];
      if (!this.goals.length) {
        el.innerHTML = `<div class="empty-state"><div class="icon">🎯</div><div class="title">No goals</div><div class="desc">Give Maya a goal above — it persists across restarts.</div></div>`;
        return;
      }
      el.innerHTML = `<div class="result-list">${this.goals.map(g => `
        <div class="result-item goal-row" data-id="${this.escapeHtml(g.id)}">
          <div class="result-head">
            ${this.statusBadge(g.status)}
            <span class="muted small">priority ${g.priority ?? '—'} · progress ${Math.round((g.progress || 0) * 100)}% · ${g.created_at ? new Date(g.created_at * 1000).toLocaleString() : ''}</span>
          </div>
          <div class="goal-desc">${this.escapeHtml(g.description)}</div>
          <div class="progress-track"><div class="progress-fill" style="width:${Math.round((g.progress || 0) * 100)}%"></div></div>
          <div class="row-actions">
            <button class="btn btn-secondary btn-sm" data-act="detail">Details</button>
            ${(g.status === 'suspended' || g.status === 'blocked' || g.status === 'active') ? `
              <button class="btn btn-secondary btn-sm" data-act="plan">Plan</button>` : ''}
            ${g.status !== 'completed' && g.status !== 'abandoned' ? `
              <button class="btn btn-danger btn-sm" data-act="abandon">Abandon</button>` : ''}
          </div>
        </div>`).join('')}</div>`;

      el.querySelectorAll('.goal-row').forEach(row => {
        row.querySelectorAll('[data-act]').forEach(btn => btn.addEventListener('click', () => {
          const goal = this.goals.find(g => g.id === row.dataset.id);
          if (!goal) return;
          if (btn.dataset.act === 'detail') this.showDetail(goal);
          else if (btn.dataset.act === 'plan') this.createPlan(goal);
          else if (btn.dataset.act === 'abandon') this.abandon(goal);
        }));
      });
    } catch (err) {
      el.innerHTML = this.flagNotice(err);
    }
  }

  flagNotice(err) {
    const msg = err?.message || String(err);
    if (err?.status === 503 || /COGNITION_ENABLED|not enabled/i.test(msg)) {
      return `<div class="empty-state fade-in"><div class="icon">🔒</div>
        <div class="title">Cognition disabled</div><div class="desc">${this.escapeHtml(msg)}</div></div>`;
    }
    return `<div class="error-state"><div class="icon">⚠️</div><h3>Request failed</h3><p>${this.escapeHtml(msg)}</p></div>`;
  }

  async loadIncomplete() {
    const wrap = this.container.querySelector('#gvIncompleteWrap');
    let goals = [];
    let scan = null;
    try {
      goals = (await this.app.api.getIncompleteGoals()).goals || [];
      try { scan = (await this.app.api.resumeIncompleteGoals({ plan_proposals: true, max_goals: 10 })).results || []; } catch {}
    } catch { wrap.innerHTML = ''; return; }
    if (!goals.length) { wrap.innerHTML = ''; return; }
    const scanMap = {};
    (scan || []).forEach(r => { scanMap[r.goal_id] = r; });
    wrap.innerHTML = `
      <div class="panel incomplete-panel">
        <h3>Incomplete goals (${goals.length})</h3>
        <p class="muted small">These survived restarts. Resume propose-only for a fresh plan, or execute previously-active goals through the gated pipeline.</p>
        <div class="incomplete-actions">
          <button class="btn btn-secondary btn-sm" id="scanBtn">Scan backlog</button>
          <button class="btn btn-primary btn-sm" id="resumeExecBtn" title="Re-executes only previously-ACTIVE goals; SUSPENDED/BLOCKED stay propose-only">Resume active (execute)</button>
        </div>
        <div class="result-list" style="margin-top:var(--space-3)">
          ${goals.map(g => {
            const sc = scanMap[g.id];
            return `<div class="result-item" data-id="${this.escapeHtml(g.id)}">
              <div class="result-head">${this.statusBadge(g.status)}
                <span class="muted small">updated ${g.updated_at ? new Date(g.updated_at * 1000).toLocaleString() : ''}</span></div>
              <div>${this.escapeHtml(g.description)}</div>
              ${sc && sc.mode !== 'scan_only' ? `<div class="muted small resume-hint">Suggested: ${sc.auto_executed ? 'auto-executed' : this.escapeHtml(sc.mode || 'propose_only')}${sc.plan_id ? ` · plan <code>${this.escapeHtml(sc.plan_id)}</code>` : ''}</div>` : ''}
              <div class="row-actions">
                <button class="btn btn-secondary btn-sm" data-ract="propose">Resume (propose)</button>
                ${g.prior_status === 'active' || g.status === 'active' ? `<button class="btn btn-primary btn-sm" data-ract="execute">Resume (execute)</button>` : ''}
              </div>
            </div>`;
          }).join('')}
        </div>
        <div id="resumeResult"></div>
      </div>`;

    wrap.querySelector('#scanBtn').addEventListener('click', () => this.loadIncomplete());
    wrap.querySelector('#resumeExecBtn').addEventListener('click', async () => {
      const ok = await this.app.confirm(
        'This re-executes previously-ACTIVE goals through Maya\u2019s gated pipeline (risk checks + approval gates still apply). Continue?',
        'Execute resumed goals',
      );
      if (!ok) return;
      try {
        const res = await this.app.api.resumeIncompleteGoals({ execute: true, max_goals: 5 });
        this.renderResumeResult(res.results);
        this.load();
      } catch (err) { this.app.toast.error('Batch resume failed', err.message); }
    });
    wrap.querySelectorAll('[data-ract]').forEach(btn => btn.addEventListener('click', async () => {
      const gid = btn.closest('[data-id]').dataset.id;
      const exec = btn.dataset.ract === 'execute';
      if (exec) {
        const ok = await this.app.confirm('Execute this goal through the unified loop now?', 'Execute goal');
        if (!ok) return;
      }
      try {
        const res = await this.app.api.resumeGoal(gid, exec);
        this.showProcessResult({ ...res, _resumed: true }, wrap.querySelector('#resumeResult'));
        this.load();
      } catch (err) { this.app.toast.error('Resume failed', err.message); }
    }));
  }

  renderResumeResult(results) {
    const el = this.container.querySelector('#resumeResult');
    if (!el || !Array.isArray(results)) return;
    el.innerHTML = `<div class="pipeline-status-card"><h4>Batch resume result</h4>
      ${results.map(r => `<div class="muted small"><code>${this.escapeHtml(r.goal_id)}</code> — ${r.mode || (r.executed ? 'executed' : 'proposed')} ${r.success === true ? '✅' : r.success === false ? '❌' : ''}</div>`).join('')}
    </div>`;
  }

  async processGoal(e) {
    e.preventDefault();
    const desc = this.container.querySelector('#pgDescription').value.trim();
    if (!desc) return;
    const execute = this.container.querySelector('#pgExecute').checked;
    const priority = parseFloat(this.container.querySelector('#pgPriority').value) || 50;
    if (execute) {
      const ok = await this.app.confirm(
        'Maya will run this goal end-to-end through its pipeline: planning, tool use, verification and recovery. Risky steps still require approval.',
        'Execute goal',
      );
      if (!ok) return;
    }
    const btn = this.container.querySelector('#pgSubmit');
    btn.disabled = true;
    btn.textContent = execute ? 'Executing…' : 'Planning…';
    const resultEl = this.container.querySelector('#pgResult');
    resultEl.innerHTML = '<div class="loading-state"><div class="spinner"></div><p>Maya is thinking…</p></div>';
    try {
      const res = await this.app.api.processGoal(desc, { priority, execute });
      this.showProcessResult(res, resultEl);
      this.container.querySelector('#pgDescription').value = '';
      this.load();
    } catch (err) {
      resultEl.innerHTML = `<div class="error-state"><div class="icon">⚠️</div><h3>Failed</h3><p>${this.escapeHtml(err.message)}</p></div>`;
    } finally {
      btn.disabled = false;
      btn.textContent = 'Send to Maya';
    }
  }

  showProcessResult(res, el) {
    if (!el) el = this.container.querySelector('#pgResult');
    const mode = res.mode || (res.executed ? 'executed' : 'processed');
    const outcome = res.outcome || {};
    el.innerHTML = `
      <div class="pipeline-status-card ${res.mode === 'propose_only' || res.mode === 'no_executor' ? 'is-proposal' : ''}">
        <h4>${res.mode === 'propose_only' || res.mode === 'no_executor'
          ? 'Proposal ready — no world changes made'
          : res.success ? '✅ Goal completed' : '❌ Goal did not complete'} <span class="badge badge-neutral">${this.escapeHtml(mode)}</span></h4>
        <dl class="kv-list">
          <div><dt>Goal ID</dt><dd><code>${this.escapeHtml(res.goal_id || '')}</code></dd></div>
          ${res.plan_id ? `<div><dt>Plan ID</dt><dd><code>${this.escapeHtml(res.plan_id)}</code></dd></div>` : ''}
          ${res.duration != null ? `<div><dt>Duration</dt><dd>${Number(res.duration).toFixed(1)}s</dd></div>` : ''}
          ${outcome.task_id ? `<div><dt>Task ID</dt><dd><code>${this.escapeHtml(outcome.task_id)}</code></dd></div>` : ''}
          ${outcome.quality_score != null ? `<div><dt>Quality</dt><dd>${Number(outcome.quality_score).toFixed(1)}/10</dd></div>` : ''}
        </dl>
        ${Array.isArray(res.plan_steps) && res.plan_steps.length ? `
          <h4>Proposed plan</h4>
          <ol class="plain-list plan-steps">${res.plan_steps.map(s =>
            `<li><strong>${this.escapeHtml(s.title || s.description || s.action || 'Step')}</strong>${s.tool ? ` <span class="badge badge-neutral">${this.escapeHtml(s.tool)}</span>` : ''}${s.expected_outcome ? `<div class="muted small">${this.escapeHtml(s.expected_outcome)}</div>` : ''}</li>`).join('')}
          </ol>` : ''}
        ${outcome.result ? `<h4>Result</h4><div class="pre-wrap mono-small">${this.escapeHtml(outcome.result)}</div>` : ''}
        ${outcome.error ? `<h4>Error</h4><div class="pre-wrap mono-small" style="color:var(--error)">${this.escapeHtml(outcome.error)}</div>` : ''}
      </div>`;
  }

  openCreateModal() {
    const modal = new this.app.Modal({
      title: 'Create goal (without executing)',
      size: 'medium',
      onConfirm: async () => {
        const description = modal.element.querySelector('#ngDesc').value.trim();
        if (!description) { this.app.toast.error('Description required'); return false; }
        try {
          await this.app.api.createGoal({
            description,
            priority: parseFloat(modal.element.querySelector('#ngPriority').value) || 50,
            success_criteria: (modal.element.querySelector('#ngCriteria').value || '')
              .split('\n').map(s => s.trim()).filter(Boolean),
          });
          this.app.toast.success('Goal created');
          this.load();
          return true;
        } catch (err) { this.app.toast.error('Failed', err.message); return false; }
      },
    });
    modal.setContent(`
      <div class="form-group"><label class="form-label" for="ngDesc">Description *</label>
        <textarea class="form-textarea" id="ngDesc" rows="3"></textarea></div>
      <div class="form-group"><label class="form-label" for="ngPriority">Priority</label>
        <input type="number" class="form-input" id="ngPriority" value="50" min="0" max="100"></div>
      <div class="form-group"><label class="form-label" for="ngCriteria">Success criteria (one per line)</label>
        <textarea class="form-textarea" id="ngCriteria" rows="3"></textarea></div>`);
    modal.open();
  }

  async showDetail(goal) {
    let children = [];
    try { children = (await this.app.api.getKernelGoals()).goals?.filter(g => g.parent_id === goal.id) || []; } catch {}
    const modal = new this.app.Modal({ title: `Goal ${goal.id}`, size: 'large', showCancel: true, confirmText: 'Close', onConfirm: async () => true });
    modal.setContent(`
      <div class="kv-list">
        <div><dt>Status</dt><dd>${this.statusBadge(goal.status)}</dd></div>
        <div><dt>Priority</dt><dd>${goal.priority ?? '—'}</dd></div>
        <div><dt>Progress</dt><dd>${Math.round((goal.progress || 0) * 100)}%</dd></div>
        <div><dt>Created</dt><dd>${goal.created_at ? new Date(goal.created_at * 1000).toLocaleString() : '—'}</dd></div>
        <div><dt>Assigned agent</dt><dd>${this.escapeHtml(goal.assigned_agent || '—')}</dd></div>
        <div><dt>Required capabilities</dt><dd>${(goal.required_capabilities || []).map(c => `<span class="badge badge-neutral">${this.escapeHtml(c)}</span>`).join(' ') || '—'}</dd></div>
      </div>
      <h4>Description</h4><p>${this.escapeHtml(goal.description)}</p>
      ${goal.success_criteria?.length ? `<h4>Success criteria</h4><ul class="plain-list">${goal.success_criteria.map(c => `<li>${this.escapeHtml(c)}</li>`).join('')}</ul>` : ''}
      ${children.length ? `<h4>Sub-goals (${children.length})</h4>${children.map(c => `<div class="muted small">${this.statusBadge(c.status)} ${this.escapeHtml(c.description)}</div>`).join('')}` : ''}
      <div class="row-actions" style="margin-top:var(--space-4)">
        <button class="btn btn-secondary btn-sm" id="decompBtn">Decompose into sub-goals</button>
      </div>
      <div id="decompOut" style="margin-top:var(--space-3)"></div>`);
    setTimeout(() => {
      modal.element?.querySelector('#decompBtn')?.addEventListener('click', async () => {
        try {
          const res = await this.app.api.decomposeGoal(goal.id, 5);
          modal.element.querySelector('#decompOut').innerHTML =
            `<h4>Sub-goals created</h4><ul class="plain-list">${(res.subgoals || []).map(s => `<li>${this.escapeHtml(s.description)}</li>`).join('')}</ul>`;
          this.load();
        } catch (err) { this.app.toast.error('Decompose failed', err.message); }
      });
    }, 50);
    modal.open();
  }

  async createPlan(goal) {
    let res;
    try {
      res = await this.app.api.createPlan(goal.id);
    } catch (err) { this.app.toast.error('Plan failed', err.message); return; }
    const planId = res.plan_id;
    const modal = this.app.showModal({ title: `Plan for "${this.escapeHtml(goal.description.slice(0, 40))}…"` });
    const render = (plan) => {
      modal.setContent(`
        <p style="color:var(--text-tertiary);font-size:var(--text-sm)">plan <code>${this.escapeHtml(planId)}</code></p>
        <div class="stat-grid">
          <div class="stat-card"><div class="stat-value small-val">${this.escapeHtml(String(plan.status || 'unknown'))}</div><div class="stat-label">Status</div></div>
          <div class="stat-card"><div class="stat-value">${plan.steps_completed ?? 0}/${plan.steps_total ?? res.steps ?? '?'}</div><div class="stat-label">Steps completed</div></div>
          <div class="stat-card"><div class="stat-value">${plan.steps_failed ?? 0}</div><div class="stat-label">Failed</div></div>
        </div>
        <div style="display:flex;gap:var(--space-2);flex-wrap:wrap;margin-top:var(--space-4)">
          <button class="btn btn-secondary btn-sm" id="planRefresh">Refresh</button>
          <button class="btn btn-secondary btn-sm" id="planReplan">Replan</button>
          <button class="btn btn-primary btn-sm" id="planExecute">Execute</button>
        </div>
        <div id="planOut" style="margin-top:var(--space-3)"></div>`);
      modal.element.querySelector('#planRefresh').addEventListener('click', refresh);
      modal.element.querySelector('#planReplan').addEventListener('click', async () => {
        try {
          const r = await this.app.api.replanPlan(planId, null, 'operator requested');
          modal.element.querySelector('#planOut').textContent = `Replanned: ${r.steps} steps`;
          refresh();
        } catch (err) { this.app.toast.error('Replan failed', err.message); }
      });
      modal.element.querySelector('#planExecute').addEventListener('click', async () => {
        try {
          const out = modal.element.querySelector('#planOut');
          out.textContent = 'Executing…';
          const r = await this.app.api.executePlan(planId);
          out.textContent = r.success
            ? `Executed successfully (${(r.results || []).length} step results)`
            : `Failed at step ${r.failed_step || '?'}${r.error ? ': ' + r.error : ''}`;
          refresh();
        } catch (err) { this.app.toast.error('Execute failed', err.message); }
      });
    };
    const refresh = async () => {
      try {
        render(await this.app.api.getPlanStatus(planId));
      } catch (err) {
        modal.setContent(`<div class="error-state" style="padding:var(--space-4)"><h3>Status unavailable</h3><p>${this.escapeHtml(err.message)}</p></div>`);
      }
    };
    await refresh();
  }

  async abandon(goal) {
    const ok = await this.app.confirm(`Mark goal "${goal.description.slice(0, 60)}…" as abandoned?`, 'Abandon goal');
    if (!ok) return;
    try {
      await this.app.api.updateGoal(goal.id, { status: 'abandoned' });
      this.app.toast.success('Goal abandoned');
      this.load();
    } catch (err) { this.app.toast.error('Failed', err.message); }
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
