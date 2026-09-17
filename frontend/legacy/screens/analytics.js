/**
 * Maya 2.0 — Analytics Workspace (Dashboard + Metrics + Logs)
 *
 * Ports from old app.js: Dashboard (229-268), Analytics (644-666),
 * Logs (1227-1244), LLM Stats (store.js), Learning Stats
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('analytics', async function () {
    L().showLoading('Loading analytics...');
    await Promise.all([
      MayaStore.analytics.loadAll(),
      MayaStore.loadMetrics(),
      MayaStore.loadDashboard(),
      MayaStore.loadLogs(),
    ]);
    const a = MayaStore.get('analytics') || {};
    const metrics = MayaStore.get('metrics');
    const logs = MayaStore.get('logs') || {};
    const s = MayaStore.getState();
    const status = s.agentStatus || {};

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto;padding-bottom:var(--space-8)">`;
    html += `<h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);margin-bottom:var(--space-3)">📊 Analytics</h2>`;

    // ── System Status Dashboard ──
    html += `<div class="card">
      <div class="card-header"><h3>System Status</h3></div>
      <div class="stat-grid mb-md">`;
    html += `<div class="stat-card"><div class="stat-value">${a.summary?.total_tasks || 0}</div><div class="stat-label">Total Tasks</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${a.summary?.success_rate || 0}%</div><div class="stat-label">Success Rate</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">$${(a.summary?.total_cost_usd || 0).toFixed(4)}</div><div class="stat-label">Cost</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${a.summary?.total_llm_calls || metrics?.llm_calls || 0}</div><div class="stat-label">LLM Calls</div></div>`;
    html += `</div>`;

    // Agent status detail
    html += `<div class="flex gap-md flex-wrap" style="font-size:var(--font-size-sm)">`;
    html += `<div><strong>Version:</strong> ${status.version || '—'}</div>`;
    html += `<div><strong>Providers:</strong> ${(status.providers || []).length || 0}</div>`;
    html += `<div><strong>Plugins:</strong> ${(status.plugins || []).length || 0}</div>`;
    html += `<div><strong>Budget:</strong> $${(a.summary?.budget_usd || 0).toFixed(2)}</div>`;
    html += `</div>`;
    if (a.summary?.budget_used_pct != null) {
      html += `<div class="progress-bar mt-sm"><div class="progress-fill" style="width:${Math.min(a.summary.budget_used_pct, 100)}%"></div></div>`;
      html += `<div class="text-xs">Budget used: ${a.summary.budget_used_pct.toFixed(1)}%</div>`;
    }
    html += `</div>`;

    // ── Quick Actions ──
    html += `<div class="card">
      <div class="card-header"><h3>Quick Actions</h3></div>
      <div class="quick-grid">
        <button class="quick-btn" onclick="window.MayaRouter.navigate('agents')"><span class="icon">🤖</span><span class="label">Run Agent</span></button>
        <button class="quick-btn" onclick="quickThink()"><span class="icon">🤔</span><span class="label">Quick Think</span></button>
        <button class="quick-btn" onclick="window.MayaRouter.navigate('chat')"><span class="icon">💬</span><span class="label">Chat</span></button>
        <button class="quick-btn" onclick="window.MayaRouter.navigate('agents')"><span class="icon">🧠</span><span class="label">Memory</span></button>
        <button class="quick-btn" onclick="window.MayaRouter.navigate('coding')"><span class="icon">🔧</span><span class="label">Tools</span></button>
        <button class="quick-btn" onclick="window.MayaRouter.navigate('business')"><span class="icon">📊</span><span class="label">Analytics</span></button>
      </div>
    </div>`;

    // ── Daily Activity ──
    const daily = a.daily || [];
    html += `<div class="card"><div class="card-header"><h3>Daily Activity</h3></div>`;
    if (daily.length > 0) {
      const maxTasks = Math.max(...daily.map(d => d.tasks || 0), 1);
      html += `<div style="display:flex;align-items:flex-end;gap:4px;padding:var(--space-2) 0;min-height:60px">`;
      daily.slice(-14).forEach(function (d) {
        const h = Math.max(4, ((d.tasks || 0) / maxTasks) * 40);
        html += `<div style="flex:1;text-align:center"><div style="background:var(--accent-blue);height:${h}px;border-radius:var(--radius-sm);margin:0 1px"></div><div class="text-xs" style="margin-top:2px">${(d.date || '').slice(5)}</div></div>`;
      });
      html += `</div>`;
    } else {
      html += `<div class="empty-state"><div class="title">No activity data yet</div></div>`;
    }
    html += `</div>`;

    // ── Top Providers ──
    const providers = a.providers || {};
    const provEntries = Object.entries(providers);
    html += `<div class="card"><div class="card-header"><h3>Provider Usage</h3></div>`;
    if (provEntries.length > 0) {
      const maxVal = Math.max(...provEntries.map(([, v]) => typeof v === 'number' ? v : (v.calls || v.requests || 0)), 1);
      provEntries.slice(0, 5).forEach(function ([k, v]) {
        const val = typeof v === 'number' ? v : (v.calls || v.requests || 0);
        html += `<div style="margin-bottom:var(--space-2)"><div style="display:flex;justify-content:space-between;font-size:var(--font-size-sm);margin-bottom:2px"><span>${ESC(k)}</span><span>${val}</span></div><div class="progress-bar"><div class="progress-fill" style="width:${(val/maxVal)*100}%"></div></div></div>`;
      });
      provEntries.slice(5).forEach(function ([k, v]) {
        const val = typeof v === 'number' ? v : (v.calls || v.requests || 0);
        html += `<div class="text-xs" style="padding:2px 0">${ESC(k)}: ${val}</div>`;
      });
    } else {
      html += `<div class="empty-state"><div class="title">No provider data</div></div>`;
    }
    html += `</div>`;

    // ── Recent Tasks ──
    html += `<div class="card"><div class="card-header"><h3>Recent Tasks</h3><button class="btn btn-sm btn-ghost" onclick="window.MayaRouter.navigate('agents')">View All</button></div>`;
    const tasks = s.tasks || [];
    if (tasks.length > 0) {
      html += `<div class="table-wrap"><table><tr><th>Goal</th><th>Status</th><th>Steps</th><th>Cost</th><th>Time</th></tr>`;
      tasks.slice(0, 5).forEach(function (t) {
        html += `<tr>
          <td class="truncate text-sm" style="max-width:180px">${ESC(t.goal || '')}</td>
          <td><span class="tag tag-${t.status}">${t.status}</span></td>
          <td>${(t.steps || []).length}</td>
          <td class="text-xs">$${(t.cost_usd || 0).toFixed(4)}</td>
          <td class="text-xs">${t.created_at ? new Date(t.created_at).toLocaleTimeString() : '—'}</td>
        </tr>`;
      });
      html += `</table></div>`;
    } else {
      html += `<div class="empty-state"><div class="title">No tasks yet</div></div>`;
    }
    html += `</div>`;

    // ── Logs ──
    html += `<div class="card"><div class="card-header"><h3>Logs</h3></div>
      <div class="flex gap-md">
        <button class="btn btn-sm" onclick="viewLogs('llm')">📜 LLM Calls (${(logs.llm || []).length})</button>
        <button class="btn btn-sm" onclick="viewLogs('tools')">📜 Tool Calls (${(logs.tools || []).length})</button>
      </div>`;
    if (metrics) {
      html += `<pre class="mt-sm">${ESC(JSON.stringify(metrics, null, 2))}</pre>`;
    }
    html += `</div>`;

    html += `</div>`;
    L().render(html);
    L().setTitle('Analytics');

    window.quickThink = function () {
      L().openModal(`<h2>🤔 Quick Think</h2>
        <div class="form-group"><label>Problem</label><textarea class="textarea" id="thinkInput" rows="4" placeholder="Ask Maya to think deeply..."></textarea></div>
        <div class="modal-actions">
          <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
          <button class="btn btn-primary" onclick="doThink()">Think</button>
        </div>
        <div id="thinkResult" class="mt-sm text-sm"></div>`);
    };
    window.doThink = async function () {
      const input = document.getElementById('thinkInput');
      const result = document.getElementById('thinkResult');
      result.innerHTML = '<span class="spinner"></span> Thinking...';
      const res = await MayaAPI.agent.think(input.value);
      result.innerHTML = res.ok ? `<pre>${ESC(res.data?.result || JSON.stringify(res.data))}</pre>` : `<span class="tag tag-error">${ESC(res.error)}</span>`;
    };
    window.viewLogs = function (type) {
      const logData = logs[type] || [];
      L().openModal(`<h2>${type.toUpperCase()} Logs</h2><pre>${logData.length ? ESC(JSON.stringify(logData.slice(-20), null, 2)) : 'No logs'}</pre><div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`);
    };
  });
})();
