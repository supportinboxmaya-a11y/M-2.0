/**
 * Maya 2.0 — Automation Workspace
 *
 * Ports from old: schedules (1247-1288), workflows (683-725),
 * webhooks (728-770), plugins (893-929)
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('automation', async function () {
    L().showLoading('Loading automation...');
    await Promise.all([
      MayaStore.loadSchedules(),
      MayaStore.loadWorkflows(),
      MayaStore.loadWebhooks(),
      MayaStore.loadPlugins(),
    ]);
    const schedules = MayaStore.get('schedules') || [];
    const workflows = MayaStore.get('workflows') || [];
    const defs = MayaStore.get('workflowDefs') || [];
    const webhooks = MayaStore.get('webhooks') || [];
    const hooks = MayaStore.get('hooks') || [];
    const plugins = MayaStore.get('plugins') || [];

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto;padding-bottom:var(--space-8)">`;
    html += `<h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);margin-bottom:var(--space-3)">⚡ Automation</h2>`;

    // ── Schedules ──
    html += `<div class="card"><div class="card-header"><h3>Schedules (${schedules.length})</h3><button class="btn btn-primary btn-sm" onclick="openNewSchedule()">+ New</button></div>`;
    if (schedules.length === 0) {
      html += `<div class="empty-state"><div class="icon">⏰</div><div class="title">No schedules</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Cron</th><th>Job</th><th>Last Run</th><th>Enabled</th></tr>`;
      schedules.forEach(function (s) {
        html += `<tr><td>${ESC(s.name)}</td><td class="text-mono text-xs">${s.cron}</td><td class="text-mono text-xs">${s.job}</td>
          <td class="text-xs">${s.last_run ? new Date(s.last_run).toLocaleString() : '—'}</td>
          <td><span class="tag ${s.enabled ? 'tag-success' : 'tag-disabled'}">${s.enabled ? 'On' : 'Off'}</span></td></tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    // ── Workflows ──
    html += `<div class="card"><div class="card-header"><h3>Workflows (${defs.length})</h3><button class="btn btn-primary btn-sm" onclick="openNewWorkflow()">+ New</button></div>`;
    if (defs.length === 0) {
      html += `<div class="empty-state"><div class="icon">🔄</div><div class="title">No workflow definitions</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Steps</th><th>Created</th><th></th></tr>`;
      defs.forEach(function (d) {
        html += `<tr><td>${ESC(d.name)}</td><td>${(d.steps || []).length}</td>
          <td class="text-xs">${d.created_at ? new Date(d.created_at).toLocaleString() : '—'}</td>
          <td><button class="btn btn-sm btn-ghost" onclick="MayaAPI.workflows.runDef('${d.id}').then(()=>L().toast('Workflow started','success'))">▶ Run</button></td></tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    // ── Workflow Runs ──
    if (workflows.length > 0) {
      html += `<div class="card"><div class="card-header"><h3>Recent Runs (${workflows.length})</h3></div>
        <div class="table-wrap"><table><tr><th>Goal</th><th>Status</th><th>Steps</th><th>Cost</th><th>Time</th></tr>`;
      workflows.forEach(function (t) {
        html += `<tr><td class="truncate text-sm" style="max-width:180px">${ESC(t.goal || '')}</td>
          <td><span class="tag tag-${t.status}">${t.status}</span></td>
          <td>${(t.steps || []).length}</td>
          <td class="text-xs">$${(t.cost_usd || 0).toFixed(4)}</td>
          <td class="text-xs">${t.created_at ? new Date(t.created_at).toLocaleTimeString() : '—'}</td></tr>`;
      });
      html += `</table></div></div>`;
    }

    // ── Webhooks ──
    html += `<div class="card"><div class="card-header"><h3>Webhooks (${webhooks.length + hooks.length})</h3><button class="btn btn-primary btn-sm" onclick="openNewWebhook()">+ New</button></div>`;
    if (webhooks.length > 0 || hooks.length > 0) {
      if (webhooks.length > 0) {
        html += `<div class="table-wrap mb-sm"><table><tr><th>Name</th><th>Job</th><th></th></tr>`;
        webhooks.forEach(function (w) {
          html += `<tr><td>${ESC(w.name)}</td><td class="text-mono text-xs">${w.job || '—'}</td>
            <td><button class="btn btn-sm btn-danger" onclick="MayaAPI.webhooks.delete('${w.id}').then(()=>MayaStore.loadWebhooks())">Delete</button></td></tr>`;
        });
        html += `</table></div>`;
      }
      if (hooks.length > 0) {
        html += `<div class="table-wrap"><table><tr><th>Name</th><th>Job</th><th>Signed</th><th>Fired</th></tr>`;
        hooks.forEach(function (h) {
          html += `<tr><td>${ESC(h.name)}</td><td class="text-mono text-xs">${h.job}</td><td>${h.signed ? '✅' : '❌'}</td><td>${h.fire_count || 0}</td></tr>`;
        });
        html += `</table></div>`;
      }
    } else {
      html += `<div class="empty-state"><div class="icon">🔗</div><div class="title">No webhooks configured</div></div>`;
    }
    html += `</div>`;

    // ── Plugins ──
    html += `<div class="card"><div class="card-header"><h3>Plugins (${plugins.length})</h3><button class="btn btn-primary btn-sm" onclick="openInstallPlugin()">+ Install</button></div>`;
    if (plugins.length === 0) {
      html += `<div class="empty-state"><div class="icon">🔌</div><div class="title">No plugins installed</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Enabled</th><th></th></tr>`;
      plugins.forEach(function (p) {
        html += `<tr><td>${ESC(p.name || p.id || '')}</td>
          <td><span class="tag ${p.enabled !== false ? 'tag-success' : 'tag-disabled'}">${p.enabled !== false ? 'Enabled' : 'Disabled'}</span></td>
          <td class="flex gap-sm">
            <button class="btn btn-sm btn-ghost" onclick="MayaAPI.plugins.update('${p.id}', ${!p.enabled}).then(()=>MayaStore.loadPlugins())">${p.enabled !== false ? 'Disable' : 'Enable'}</button>
            <button class="btn btn-sm btn-danger" onclick="MayaAPI.plugins.uninstall('${p.id}').then(()=>MayaStore.loadPlugins())">Uninstall</button>
          </td></tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    html += `</div>`;
    L().render(html);
    L().setTitle('Automation');

    window.openNewSchedule = function () {
      L().openModal(`<h2>New Schedule</h2>
        <div class="form-group"><label>Name</label><input class="input" id="schedName" placeholder="daily-brief"></div>
        <div class="form-group"><label>Cron</label><input class="input text-mono" id="schedCron" value="0 9 * * *"></div>
        <div class="form-group"><label>Job</label><input class="input text-mono" id="schedJob" value="agent_goal"></div>
        <div class="form-group"><label>Args (JSON)</label><input class="input text-mono" id="schedArgs" value='["Run daily brief"]'></div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="createSchedule()">Create</button></div>`);
    };
    window.createSchedule = function () {
      const name = document.getElementById('schedName').value.trim();
      if (!name) { L().toast('Name required', 'warning'); return; }
      let args = [];
      try { args = JSON.parse(document.getElementById('schedArgs').value || '[]'); } catch { args = []; }
      MayaAPI.schedules.create(name, document.getElementById('schedCron').value, document.getElementById('schedJob').value, args).then(function (res) {
        if (res.ok) { L().closeModal(); L().toast('Schedule created', 'success'); MayaStore.loadSchedules(); window.MayaRouter.navigate('automation'); }
        else { L().toast(res.error || 'Failed', 'error'); }
      });
    };

    window.openNewWorkflow = function () {
      L().openModal(`<h2>New Workflow</h2>
        <div class="form-group"><label>Name</label><input class="input" id="wfName" placeholder="My Workflow"></div>
        <div class="form-group"><label>Description</label><textarea class="textarea" id="wfDesc" rows="2"></textarea></div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="createWorkflow()">Create</button></div>`);
    };
    window.createWorkflow = function () {
      const name = document.getElementById('wfName').value.trim();
      if (!name) { L().toast('Name required', 'warning'); return; }
      MayaAPI.workflows.create(name, document.getElementById('wfDesc').value, [], []).then(function (res) {
        if (res.ok) { L().closeModal(); L().toast('Workflow created', 'success'); MayaStore.loadWorkflows(); window.MayaRouter.navigate('automation'); }
        else { L().toast(res.error || 'Failed', 'error'); }
      });
    };

    window.openNewWebhook = function () {
      L().openModal(`<h2>Create Webhook</h2>
        <div class="form-group"><label>Name</label><input class="input" id="whName" placeholder="pr-review"></div>
        <div class="form-group"><label>Job</label><input class="input text-mono" id="whJob" value="agent_goal"></div>
        <div class="form-group"><label>Template</label><textarea class="textarea text-mono" id="whTemplate" rows="2">Review PR: {{pull_request.title}}</textarea></div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="createWebhook()">Create</button></div>`);
    };
    window.createWebhook = function () {
      const name = document.getElementById('whName').value.trim();
      if (!name) { L().toast('Name required', 'warning'); return; }
      MayaAPI.webhooks.create(name, document.getElementById('whJob').value, document.getElementById('whTemplate').value, true).then(function (res) {
        if (res.ok) { L().closeModal(); L().toast('Webhook created', 'success'); MayaStore.loadWebhooks(); window.MayaRouter.navigate('automation'); }
        else { L().toast(res.error || 'Failed', 'error'); }
      });
    };

    window.openInstallPlugin = function () {
      L().openModal(`<h2>Install Plugin</h2>
        <div class="form-group"><label>Plugin ID</label><input class="input" id="pluginId" placeholder="plugin-name"></div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="installPlugin()">Install</button></div>`);
    };
    window.installPlugin = function () {
      const id = document.getElementById('pluginId').value.trim();
      if (!id) { L().toast('Plugin ID required', 'warning'); return; }
      MayaAPI.plugins.install(id).then(function (res) {
        if (res.ok) { L().closeModal(); L().toast('Plugin installed', 'success'); MayaStore.loadPlugins(); window.MayaRouter.navigate('automation'); }
        else { L().toast(res.error || 'Failed', 'error'); }
      });
    };
  });
})();
