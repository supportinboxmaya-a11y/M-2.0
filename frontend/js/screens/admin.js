/**
 * Maya 2.0 — Admin Workspace
 *
 * Ports from old: admin (1522-1563), providers/llm (590-641),
 * backups (1370-1396), devices (1291-1328), controls (1485-1520),
 * flags, queue, health, sync, publish (old), notifications (773-787)
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('admin', async function () {
    L().showLoading('Loading admin...');
    const [usersRes, flagsRes, healthRes, devsRes, backupsRes, queueRes, ctrlRes, notifRes] = await Promise.all([
      MayaAPI.admin.users().catch(() => ({ ok: false })),
      MayaAPI.flags.list().catch(() => ({ ok: false })),
      MayaAPI.health.all().catch(() => ({ ok: false })),
      MayaStore.loadDevices ? MayaStore.loadDevices() : MayaAPI.device.list().catch(() => ({ ok: false })),
      MayaStore.loadBackups().catch(() => {}),
      MayaAPI.queue.status().catch(() => ({ ok: false })),
      MayaStore.loadControlState().catch(() => {}),
      MayaStore.loadNotifications().catch(() => {}),
    ]);
    // LLM providers
    await MayaStore.loadLLM().catch(() => {});
    const provs = MayaStore.get('llmProviders') || [];
    const llmStats = MayaStore.get('llmStats') || {};
    const llmStrategy = MayaStore.get('llmStrategy') || {};
    const users = usersRes.ok ? (Array.isArray(usersRes.data) ? usersRes.data : []) : [];
    const flags = flagsRes.ok ? flagsRes.data : {};
    const health = healthRes.ok ? healthRes.data : {};
    const devices = MayaStore.get('devices') || [];
    const backups = MayaStore.get('backups') || [];
    const queue = queueRes.ok ? queueRes.data : {};
    const control = MayaStore.get('control') || {};
    const notifs = MayaStore.get('notifications') || {};

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto;padding-bottom:var(--space-8)">`;
    html += `<h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);margin-bottom:var(--space-3)">⚙️ Admin</h2>`;

    // ── Overview ──
    html += `<div class="stat-grid mb-md">`;
    html += `<div class="stat-card"><div class="stat-value">${Array.isArray(users) ? users.length : 0}</div><div class="stat-label">Users</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${health.status || '—'}</div><div class="stat-label">System</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${notifs.unread || 0}</div><div class="stat-label">Unread</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${backups.length}</div><div class="stat-label">Backups</div></div>`;
    html += `</div>`;

    // ── Quick Actions ──
    html += `<div class="quick-grid mb-md">`;
    html += `<button class="quick-btn" onclick="openUserMgmt()"><span class="icon">👥</span><span class="label">Users</span></button>`;
    html += `<button class="quick-btn" onclick="openProviderMgmt()"><span class="icon">⚡</span><span class="label">Providers</span></button>`;
    html += `<button class="quick-btn" onclick="openFlags()"><span class="icon">🚩</span><span class="label">Flags</span></button>`;
    html += `<button class="quick-btn" onclick="openDevices()"><span class="icon">🖥️</span><span class="label">Devices</span></button>`;
    html += `<button class="quick-btn" onclick="openBackups()"><span class="icon">💾</span><span class="label">Backups</span></button>`;
    html += `<button class="quick-btn" onclick="openControls()"><span class="icon">🎮</span><span class="label">Controls</span></button>`;
    html += `<button class="quick-btn" onclick="openNotifs()"><span class="icon">🔔</span><span class="label">Notif.</span></button>`;
    html += `<button class="quick-btn" onclick="viewAudit()"><span class="icon">📜</span><span class="label">Audit</span></button>`;
    html += `</div>`;

    // ── Users ──
    html += `<div class="card" id="adminUsers"><div class="card-header"><h3>Users (${Array.isArray(users) ? users.length : 0})</h3></div>`;
    if (Array.isArray(users) && users.length > 0) {
      html += `<div class="table-wrap"><table><tr><th>Email</th><th>Role</th><th>Budget</th><th>Status</th><th></th></tr>`;
      users.forEach(function (u) {
        html += `<tr><td>${ESC(u.email)}</td><td>${u.role || '—'}</td><td>$${u.budget_usd || 0}</td>
          <td>${u.banned ? '<span class="tag tag-error">Banned</span>' : '<span class="tag tag-success">Active</span>'}</td>
          <td><button class="btn btn-sm ${u.banned ? 'btn-ghost' : 'btn-danger'}" onclick="MayaAPI.admin.banUser('${u.id}', ${!u.banned}).then(()=>window.MayaRouter.navigate('admin'))">${u.banned ? 'Unban' : 'Ban'}</button></td></tr>`;
      });
      html += `</table></div>`;
    } else {
      html += `<div class="empty-state"><div class="icon">👥</div><div class="title">User management requires Supabase</div></div>`;
    }
    html += `</div>`;

    // ── Feature Flags ──
    html += `<div class="card"><div class="card-header"><h3>Feature Flags</h3></div>`;
    const flagEntries = Object.entries(flags);
    if (flagEntries.length > 0) {
      flagEntries.forEach(function ([k, v]) {
        html += `<div class="flex-between" style="padding:var(--space-1) 0;border-bottom:1px solid var(--border-secondary)"><span class="text-mono text-sm">${ESC(k)}</span><span class="tag ${v ? 'tag-success' : 'tag-disabled'}">${v ? 'On' : 'Off'}</span></div>`;
      });
    } else {
      html += `<div class="empty-state"><div class="title">No flags</div></div>`;
    }
    html += `</div>`;

    // ── LLM Providers (inline) ──
    html += `<div class="card"><div class="card-header"><h3>LLM Providers</h3></div>`;
    const provItems = Array.isArray(provs) ? provs : Object.entries(provs).map(([k, v]) => ({ name: k, ...v }));
    if (provItems.length > 0) {
      html += `<div class="table-wrap"><table><tr><th>Provider</th><th>Status</th><th></th></tr>`;
      provItems.forEach(function (p) {
        const pname = p.name || p.id || '';
        html += `<tr><td><strong>${ESC(pname)}</strong></td>
          <td><span class="tag ${p.enabled ? 'tag-success' : 'tag-disabled'}">${p.enabled ? 'Enabled' : 'Disabled'}</span></td>
          <td class="flex gap-sm">
            <button class="btn btn-sm btn-ghost" onclick="MayaAPI.providers.toggle('${pname}', ${!p.enabled}).then(()=>MayaStore.providers.llmLoad())">${p.enabled ? 'Disable' : 'Enable'}</button>
            <button class="btn btn-sm" onclick="setKey('${pname}')">🔑 Key</button>
          </td></tr>`;
      });
      html += `</table></div>`;
    } else {
      html += `<div class="empty-state"><div class="title">No providers</div></div>`;
    }
    if (Object.keys(llmStrategy).length) {
      html += `<button class="btn btn-sm mt-sm" onclick="L().openModal('<pre>'+ESC(JSON.stringify(llmStrategy,null,2))+'</pre>')">📊 Strategy</button>`;
    }
    html += `</div>`;

    // ── Health ──
    html += `<div class="card"><div class="card-header"><h3>System Health</h3></div>
      <pre class="text-xs">${ESC(JSON.stringify(health, null, 2))}</pre></div>`;

    html += `</div>`;
    L().render(html);
    L().setTitle('Admin');

    // ── Modal popup functions ──
    window.openUserMgmt = function () {
      L().openModal(`<h2>Users</h2><pre>${users.length ? ESC(users.map(u => u.email + ' (' + (u.role || 'user') + ')').join('\n')) : 'No users'}</pre><div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`);
    };
    window.openProviderMgmt = function () {
      L().openModal(`<h2>Providers</h2><pre>${ESC(JSON.stringify(provItems, null, 2))}</pre><div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`);
    };
    window.setKey = function (provider) {
      L().openModal(`<h2>Set Key: ${ESC(provider)}</h2>
        <div class="form-group"><label>API Key</label><input class="input" type="password" id="providerKey" placeholder="Enter key..."></div>
        <div class="modal-actions">
          <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
          <button class="btn btn-primary" onclick="doSetKey('${provider}')">Save</button>
        </div>`);
    };
    window.doSetKey = async function (provider) {
      const key = document.getElementById('providerKey').value;
      if (!key) { L().toast('Enter a key', 'warning'); return; }
      await MayaAPI.providers.setKey(provider, key);
      L().closeModal(); L().toast('Key saved', 'success');
      window.MayaRouter.navigate('admin');
    };
    window.openFlags = function () {
      L().openModal(`<h2>Feature Flags</h2><pre>${ESC(JSON.stringify(flags, null, 2))}</pre><div class="flex mt-sm"><button class="btn btn-sm" onclick="MayaAPI.flags.update({RESEARCH_ENGINE_ENABLED:true}).then(()=>{L().toast('Flags updated','success');L().closeModal()})">Enable Research</button><button class="btn btn-sm" onclick="MayaAPI.flags.update({COGNITION_ENABLED:true}).then(()=>{L().toast('Flags updated','success');L().closeModal()})">Enable Cognition</button></div></div>`);
    };
    window.openDevices = function () {
      let dhtml = `<h2>Paired Devices (${devices.length})</h2>`;
      if (devices.length > 0) {
        dhtml += `<div class="table-wrap"><table><tr><th>Name</th><th>ID</th><th>Paired</th><th></th></tr>`;
        devices.forEach(function (d) {
          dhtml += `<tr><td>${ESC(d.name || '')}</td><td class="text-xs text-mono">${d.id || d.device_id || ''}</td><td class="text-xs">${d.paired_at ? new Date(d.paired_at).toLocaleString() : ''}</td><td><button class="btn btn-sm btn-danger" onclick="MayaAPI.device.delete('${d.id}').then(()=>L().toast('Revoked','success'))">Revoke</button></td></tr>`;
        });
        dhtml += `</table></div>`;
      } else {
        dhtml += `<div class="empty-state"><div class="title">No devices</div></div>`;
      }
      dhtml += `<div class="modal-actions"><button class="btn btn-primary" onclick="pairDevice()">+ Pair Device</button><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`;
      L().openModal(dhtml);
    };
    window.pairDevice = function () {
      L().openModal(`<h2>Pair Device</h2><div class="form-group"><label>Device Name</label><input class="input" id="devName" placeholder="My Laptop"></div><div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="doPair()">Generate Code</button></div><div id="pairResult" class="mt-sm text-sm"></div>`);
    };
    window.doPair = async function () {
      const name = document.getElementById('devName').value.trim();
      const result = document.getElementById('pairResult');
      result.innerHTML = '<span class="spinner"></span>';
      const res = await MayaAPI.device.pairStart(name);
      result.innerHTML = res.ok ? '<span class="tag tag-success">Code: ' + ESC(res.data?.pairing_code || '') + '</span>' : '<span class="tag tag-error">' + ESC(res.error) + '</span>';
    };
    window.openBackups = function () {
      let bhtml = `<h2>Backups (${backups.length})</h2>`;
      if (backups.length > 0) {
        bhtml += `<div class="table-wrap"><table><tr><th>ID</th><th>Created</th><th></th></tr>`;
        backups.forEach(function (b) {
          bhtml += `<tr><td class="text-xs text-mono">${b.id || ''}</td><td class="text-xs">${b.created_at ? new Date(b.created_at).toLocaleString() : b.created || ''}</td><td class="flex gap-sm"><button class="btn btn-sm" onclick="MayaAPI.backups.restore('${b.id}').then(()=>L().toast('Restored','success'))">♻️</button><button class="btn btn-sm btn-danger" onclick="MayaAPI.backups.delete('${b.id}').then(()=>L().toast('Deleted','success'))">🗑</button></td></tr>`;
        });
        bhtml += `</table></div>`;
      } else {
        bhtml += `<div class="empty-state"><div class="title">No backups</div></div>`;
      }
      bhtml += `<div class="modal-actions"><button class="btn btn-primary" onclick="MayaAPI.backups.create('Manual').then(()=>{L().toast('Backup created','success');L().closeModal()})">+ Create</button><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`;
      L().openModal(bhtml);
    };
    window.openControls = function () {
      L().openModal(`<h2>Control Center</h2>
        <div class="form-row"><div class="form-group"><label>Action</label><select class="select" id="ctrlAction"><option value="notify">Notify</option><option value="pause">Pause</option><option value="resume">Resume</option></select></div>
        <div class="form-group"><label>Params (JSON)</label><input class="input text-mono" id="ctrlParams" value='{"message":"Hello"}'></div></div>
        <button class="btn btn-primary" onclick="sendControl()">Send</button>
        <div id="ctrlResult" class="mt-sm text-sm"></div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`);
    };
    window.sendControl = async function () {
      const action = document.getElementById('ctrlAction').value;
      let params = {};
      try { params = JSON.parse(document.getElementById('ctrlParams').value || '{}'); } catch {}
      const res = await MayaAPI.control.sendCommand(action, params);
      document.getElementById('ctrlResult').innerHTML = res.ok ? '<span class="tag tag-success">Sent</span>' : '<span class="tag tag-error">' + ESC(res.error) + '</span>';
    };
    window.openNotifs = function () {
      const items = notifs.items || [];
      let nhtml = `<h2>Notifications</h2><div class="flex-between mb-sm"><span class="tag tag-running">${notifs.unread || 0} unread</span><button class="btn btn-sm" onclick="MayaAPI.notifications.markAllRead().then(()=>L().toast('All read','success'))">Mark All Read</button></div>`;
      if (items.length > 0) {
        items.forEach(function (item) {
          nhtml += `<div style="padding:8px;border-bottom:1px solid var(--border-secondary);${item.read ? '' : 'background:var(--bg-tertiary)'}">
            <div class="flex-between"><strong class="text-sm">${ESC(item.title)}</strong><span class="text-xs">${item.created_at ? new Date(item.created_at).toLocaleString() : ''}</span></div>
            <div class="text-xs">${ESC(item.body || '')}</div>
            ${!item.read ? `<button class="btn btn-sm btn-ghost mt-sm" onclick="MayaAPI.notifications.markRead('${item.id}').then(()=>{L().toast('Marked read','success');L().closeModal()})">Mark Read</button>` : ''}
          </div>`;
        });
      } else {
        nhtml += `<div class="empty-state"><div class="title">No notifications</div></div>`;
      }
      nhtml += `<div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`;
      L().openModal(nhtml);
    };
    window.viewAudit = async function () {
      const res = await MayaAPI.admin.audit();
      L().openModal(`<h2>Audit Log</h2><pre>${res.ok ? ESC(JSON.stringify(res.data, null, 2).slice(0, 3000)) : 'No audit data'}</pre><div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`);
    };
  });
})();
