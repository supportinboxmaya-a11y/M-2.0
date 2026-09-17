/**
 * Maya 2.0 — Coding Workspace
 *
 * Ports from old: agent.run (310-350), tools (527-588),
 * hosting (842-890), publish (1440-1482), controls (1485-1520)
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('coding', async function () {
    L().showLoading('Loading workspace...');
    await MayaStore.loadTools();
    await MayaStore.loadHosting();
    const tools = MayaStore.get('tools') || [];
    const logs = MayaStore.get('toolsLog') || [];
    const hosting = MayaStore.get('hosting') || {};
    const apps = hosting.apps || [];
    const registry = hosting.registry || [];
    const publish = MayaStore.get('publish') || {};
    const pubHistory = publish.history || [];

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto;padding-bottom:var(--space-8)">`;
    html += `<h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);margin-bottom:var(--space-3)">💻 Coding</h2>`;

    // ── Tool Runner ──
    html += `<div class="card"><div class="card-header"><h3>Tool Runner</h3></div>
      <div class="form-row">
        <div style="flex:1"><select class="select" id="toolSelect" style="width:100%"><option value="">— Select tool —</option>${tools.map(t => `<option value="${t.name}">${ESC(t.name)}</option>`).join('')}</select></div>
        <div style="flex:2"><input class="input" type="text" id="toolInput" placeholder='Input JSON params'></div>
        <div><button class="btn btn-primary" onclick="runTool()">▶ Execute</button></div>
      </div>
      <div id="toolResult" class="mt-sm text-sm"></div>
    </div>`;

    // ── All Tools ──
    html += `<div class="card"><div class="card-header"><h3>All Tools (${tools.length})</h3></div>`;
    if (tools.length === 0) {
      html += `<div class="empty-state"><div class="icon">🔧</div><div class="title">No tools available</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Category</th><th>Description</th><th>Calls</th><th>Success</th></tr>`;
      tools.forEach(function (t) {
        html += `<tr><td class="text-mono">${ESC(t.name)}</td>
          <td><span class="tag tag-info">${t.category || 'general'}</span></td>
          <td class="text-xs">${ESC((t.description || '').slice(0, 80))}</td>
          <td>${t.call_count || t.calls || 0}</td>
          <td>${t.success_rate || 0}%</td></tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    // ── Tool Logs ──
    if (logs.length > 0) {
      html += `<div class="card"><div class="card-header"><h3>Recent Tool Logs</h3></div>
        <div class="table-wrap"><table><tr><th>Tool</th><th>Calls</th><th>Success</th><th>Failures</th><th>Avg Time</th></tr>`;
      logs.slice(0, 20).forEach(function (l) {
        html += `<tr><td class="text-mono">${ESC(l.tool)}</td><td>${l.calls || 0}</td><td>${l.successes || 0}</td><td>${l.failures || 0}</td><td>${(l.avg_time || 0).toFixed(3)}s</td></tr>`;
      });
      html += `</table></div></div>`;
    }

    // ── Hosting ──
    html += `<div class="card"><div class="card-header"><h3>Deployed Apps (${apps.length})</h3><button class="btn btn-primary btn-sm" onclick="openDeploy()">+ Deploy</button></div>`;
    if (apps.length === 0) {
      html += `<div class="empty-state"><div class="icon">☁️</div><div class="title">No apps deployed</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th></th></tr>`;
      apps.forEach(function (a) {
        const name = a.name || a;
        html += `<tr><td>${ESC(name)}</td><td class="flex gap-sm">
          <button class="btn btn-sm btn-ghost" onclick="MayaAPI.hosting.startApp('${name}').then(()=>L().toast('Started','success'))">▶ Start</button>
          <button class="btn btn-sm btn-ghost" onclick="MayaAPI.hosting.stopApp('${name}').then(()=>L().toast('Stopped','success'))">⏹ Stop</button>
          <button class="btn btn-sm btn-danger" onclick="MayaAPI.hosting.deleteApp('${name}').then(()=>window.MayaRouter.navigate('coding'))">Delete</button>
        </td></tr>`;
      });
      html += `</table></div>`;
    }
    if (registry.length > 0) {
      html += `<div class="mt-sm"><div class="text-xs" style="color:var(--text-secondary);margin-bottom:4px">Registry (${registry.length})</div><div class="table-wrap"><table><tr><th>Name</th><th>Image</th><th>Status</th></tr>`;
      registry.forEach(function (r) {
        html += `<tr><td>${ESC(r.name)}</td><td class="text-mono text-xs">${ESC(r.image || '—')}</td><td><span class="tag ${r.active ? 'tag-success' : 'tag-disabled'}">${r.active ? 'Active' : 'Inactive'}</span></td></tr>`;
      });
      html += `</table></div></div>`;
    }
    html += `</div>`;

    // ── Publish ──
    html += `<div class="card"><div class="card-header"><h3>Publish</h3><button class="btn btn-primary btn-sm" onclick="openPublish()">+ New</button></div>`;
    if (pubHistory.length === 0) {
      html += `<div class="empty-state"><div class="icon">🚀</div><div class="title">No publish history</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Site</th><th>Action</th><th>Date</th></tr>`;
      pubHistory.forEach(function (h) {
        html += `<tr><td>${ESC(h.site_name)}</td><td><span class="tag ${h.action === 'published' ? 'tag-success' : h.action === 'failed' ? 'tag-error' : 'tag-info'}">${h.action}</span></td><td class="text-xs">${h.created_at ? new Date(h.created_at).toLocaleString() : ''}</td></tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    html += `</div>`;
    L().render(html);
    L().setTitle('Coding');

    window.runTool = function () {
      const name = document.getElementById('toolSelect').value;
      const input = document.getElementById('toolInput').value;
      if (!name) { L().toast('Select a tool', 'warning'); return; }
      let parsed = {};
      try { if (input.trim()) parsed = JSON.parse(input); } catch { L().toast('Invalid JSON', 'error'); return; }
      const result = document.getElementById('toolResult');
      result.innerHTML = '<span class="spinner"></span> Running...';
      MayaAPI.tools.run(name, parsed).then(function (res) {
        result.innerHTML = res.ok ? `<pre>${ESC(JSON.stringify(res.data, null, 2))}</pre>` : `<span class="tag tag-error">${ESC(res.error)}</span>`;
      });
    };

    window.openDeploy = function () {
      L().openModal(`<h2>Deploy App</h2>
        <div class="form-group"><label>App Name</label><input class="input" id="deployName" placeholder="my-app"></div>
        <div class="form-group"><label>Source (git URL or directory)</label><input class="input" id="deploySource" placeholder="https://github.com/user/repo"></div>
        <div class="modal-actions">
          <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
          <button class="btn btn-primary" onclick="doDeploy()">Deploy</button>
        </div>`);
    };
    window.doDeploy = async function () {
      const name = document.getElementById('deployName').value.trim();
      if (!name) { L().toast('Name required', 'warning'); return; }
      const res = await MayaAPI.hosting.deploy(document.getElementById('deploySource').value, name);
      if (res.ok) { L().closeModal(); L().toast('Deploy started', 'success'); MayaStore.loadHosting(); window.MayaRouter.navigate('coding'); }
      else { L().toast(res.error || 'Failed', 'error'); }
    };

    window.openPublish = function () {
      L().openModal(`<h2>Publish Site</h2>
        <div class="form-group"><label>Site Name</label><input class="input" id="pubName" placeholder="my-site"></div>
        <div class="form-group"><label>Description</label><input class="input" id="pubDesc"></div>
        <div class="form-group"><label>Files (JSON)</label><textarea class="textarea text-mono" id="pubFiles" rows="5">{"index.html": "..."}</textarea></div>
        <div class="modal-actions">
          <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
          <button class="btn btn-primary" onclick="doPublish()">Propose</button>
        </div>
        <div id="pubResult" class="mt-sm text-sm"></div>`);
    };
    window.doPublish = async function () {
      const name = document.getElementById('pubName').value.trim();
      if (!name) { L().toast('Name required', 'warning'); return; }
      let files = {};
      try { files = JSON.parse(document.getElementById('pubFiles').value || '{}'); } catch { L().toast('Invalid JSON', 'error'); return; }
      document.getElementById('pubResult').innerHTML = '<span class="spinner"></span>';
      const res = await MayaAPI.publish.create(name, files, document.getElementById('pubDesc').value);
      document.getElementById('pubResult').innerHTML = res.ok ? '<span class="tag tag-success">Proposed!</span>' : '<span class="tag tag-error">' + ESC(res.error) + '</span>';
      if (res.ok) setTimeout(function () { L().closeModal(); window.MayaRouter.navigate('coding'); }, 1000);
    };
  });
})();
