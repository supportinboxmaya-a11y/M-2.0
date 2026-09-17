/**
 * Maya 2.0 — Agents Workspace
 *
 * Ports from old: agent.run (310-350), tasks (427-461), memory (466-522),
 * cognition (790-839), instances (1331-1366), learning (store.js)
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('agents', async function () {
    L().showLoading('Loading agents...');
    await Promise.all([
      MayaStore.agent.status(),
      MayaStore.tasks.load(50),
      MayaStore.loadMemory(),
      MayaStore.loadCognition(),
      MayaStore.loadInstances(),
    ]);
    const status = MayaStore.get('agentStatus') || {};
    const tasks = MayaStore.get('tasks') || [];
    const memories = MayaStore.get('memories') || [];
    const memStats = MayaStore.get('memoryStats') || {};
    const cognition = MayaStore.get('cognition') || {};
    const cogStatus = cognition.status || {};
    const missions = cognition.missions || [];
    const objectives = cognition.objectives || [];
    const instances = MayaStore.get('instances') || [];

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto;padding-bottom:var(--space-8)">`;
    html += `<div style="display:flex;align-items:center;gap:var(--space-2);margin-bottom:var(--space-3);flex-wrap:wrap">
      <h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);flex:1">🤖 Agents</h2>
    </div>`;

    // ── Agent Status ──
    const isRunning = status.busy || status.running;
    html += `<div class="card">
      <div class="card-header"><h3>Agent Status</h3></div>
      <div class="stat-grid mb-md">`;
    html += `<div class="stat-card"><div class="stat-value" style="font-size:16px">${isRunning ? '🟢 Running' : '⚪ Idle'}</div><div class="stat-label">Status</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${(status.tools || []).length}</div><div class="stat-label">Tools</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${(status.providers || []).length}</div><div class="stat-label">Providers</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${cogStatus.enabled ? '✅' : '❌'}</div><div class="stat-label">Cognition</div></div>`;
    html += `</div>`;
    if (status.version) html += `<div class="text-xs">Version: ${status.version}</div>`;
    html += `</div>`;

    // ── Run Agent ──
    html += `<div class="card">
      <div class="card-header"><h3>Run Agent</h3></div>
      <div class="form-group"><label>Goal</label><textarea class="textarea" id="agentGoal" rows="2" placeholder="e.g. Search the web for latest AI news and summarize..."></textarea></div>
      <div class="form-row">
        <div><label class="text-xs" style="color:var(--text-secondary);display:block;margin-bottom:2px">Budget ($)</label><input class="input" type="number" id="agentBudget" value="1.0" step="0.1" min="0" style="min-width:80px"></div>
        <div style="flex:1"><label class="text-xs" style="color:var(--text-secondary);display:block;margin-bottom:2px">Instance</label><select class="select" id="agentInstance"><option value="">— None —</option>${instances.map(i => `<option value="${i.id}">${ESC(i.name)}</option>`).join('')}</select></div>
      </div>
      <button class="btn btn-primary btn-block" onclick="runAgent()">🚀 Execute Goal</button>
      <div id="agentResult" class="mt-sm text-sm" style="display:none"></div>
    </div>`;

    // ── Tasks ──
    html += `<div class="card"><div class="card-header"><h3>Tasks</h3>
      <div class="flex gap-sm">
        <select class="select" id="taskFilter" style="font-size:var(--font-size-xs);min-width:100px" onchange="filterTasks()">
          <option value="">All</option><option value="running">Running</option><option value="done">Done</option><option value="failed">Failed</option><option value="pending">Pending</option>
        </select>
        <button class="btn btn-sm btn-ghost" onclick="refreshTasks()">🔄</button>
      </div>
    </div>`;
    if (tasks.length === 0) {
      html += `<div class="empty-state"><div class="icon">📋</div><div class="title">No tasks yet</div><div class="desc">Create a task above to get started</div></div>`;
    } else {
      html += `<div id="taskTableWrap"><div class="table-wrap"><table><tr><th>Goal</th><th>Status</th><th>Steps</th><th>Cost</th><th>Time</th></tr>`;
      tasks.forEach(function (t) {
        html += `<tr><td class="truncate text-sm" style="max-width:180px">${ESC(t.goal || '')}</td>
          <td><span class="tag tag-${t.status}">${t.status}</span></td>
          <td>${(t.steps || []).length}</td>
          <td class="text-xs">$${(t.cost_usd || 0).toFixed(4)}</td>
          <td class="text-xs">${t.created_at ? new Date(t.created_at).toLocaleTimeString() : '—'}</td>
        </tr>`;
      });
      html += `</table></div></div>`;
    }
    html += `</div>`;

    // ── Memory ──
    html += `<div class="card"><div class="card-header"><h3>Memory</h3><span class="tag tag-info">${memStats.total || memories.length} total</span></div>
      <div class="form-row mb-sm">
        <div style="flex:3"><input class="input" id="memInput" placeholder="Add a memory..."></div>
        <div style="flex:1"><select class="select" id="memType"><option value="general">General</option><option value="fact">Fact</option><option value="preference">Preference</option><option value="lesson">Lesson</option></select></div>
        <div><button class="btn btn-primary btn-sm" onclick="addMemory()">Save</button></div>
      </div>
      <div class="flex mb-sm"><input class="input" id="memSearch" placeholder="Search memories..." style="flex:1" onkeydown="if(event.key==='Enter')searchMemory()"><button class="btn btn-sm" onclick="searchMemory()">🔍</button></div>`;
    if (memories.length === 0) {
      html += `<div class="empty-state"><div class="icon">🧠</div><div class="title">No memories stored</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Content</th><th>Type</th><th></th></tr>`;
      memories.forEach(function (m) {
        const content = typeof m === 'string' ? m : (m.content || JSON.stringify(m));
        html += `<tr><td class="text-sm">${ESC(content.slice(0, 100))}</td><td><span class="tag tag-info">${m.type || 'general'}</span></td>
          <td><button class="btn btn-sm btn-danger" onclick="MayaAPI.memory.delete('${m.id || ''}').then(()=>window.MayaRouter.navigate('agents'))">🗑</button></td></tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    // ── Instances ──
    html += `<div class="card"><div class="card-header"><h3>Instances (${instances.length})</h3><button class="btn btn-primary btn-sm" onclick="openNewInstance()">+ New</button></div>`;
    if (instances.length === 0) {
      html += `<div class="empty-state"><div class="icon">📦</div><div class="title">No instances</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Persona</th><th>Provider</th><th></th></tr>`;
      instances.forEach(function (i) {
        html += `<tr><td>${ESC(i.name)}</td><td class="text-xs">${ESC((i.persona || '').slice(0, 60))}</td><td>${i.provider || 'default'}</td>
          <td><button class="btn btn-sm btn-danger" onclick="MayaAPI.instances.delete('${i.id}').then(()=>window.MayaRouter.navigate('agents'))">Delete</button></td></tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    // ── Cognition: Missions ──
    html += `<div class="card"><div class="card-header"><h3>Cognition</h3>
      <div class="flex gap-sm">
        <button class="btn btn-sm" onclick="openNewMission()">+ Mission</button>
        <button class="btn btn-sm" onclick="runCycle()">🔄 Cycle</button>
      </div>
    </div>`;
    html += `<div class="stat-grid mb-sm">`;
    html += `<div class="stat-card"><div class="stat-value">${missions.length}</div><div class="stat-label">Missions</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${objectives.length}</div><div class="stat-label">Objectives</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${cogStatus.enabled ? '✅' : '❌'}</div><div class="stat-label">Enabled</div></div>`;
    html += `</div>`;
    if (missions.length > 0) {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Status</th><th>Self-gen</th><th></th></tr>`;
      missions.forEach(function (m) {
        html += `<tr><td>${ESC(m.name)}</td><td><span class="tag ${m.active ? 'tag-success' : 'tag-disabled'}">${m.active ? 'Active' : 'Inactive'}</span></td><td>${m.self_gen ? '✅' : '❌'}</td>
          <td class="flex gap-sm">
            <button class="btn btn-sm btn-ghost" onclick="MayaAPI.cognition.generateObjectives('${m.id}').then(()=>L().toast('Generated','success'))">Generate</button>
            <button class="btn btn-sm btn-danger" onclick="MayaAPI.cognition.deleteMission('${m.id}').then(()=>window.MayaRouter.navigate('agents'))">Delete</button>
          </td></tr>`;
      });
      html += `</table></div>`;
    }
    if (cogStatus.mode) {
      html += `<div class="mt-sm"><button class="btn btn-sm" onclick="L().openModal('<pre>'+ESC(JSON.stringify(cogStatus,null,2))+'</pre>')">📊 Status</button></div>`;
    }
    html += `</div>`;

    html += `</div>`;
    L().render(html);
    L().setTitle('Agents');

    window.runAgent = async function () {
      const goal = document.getElementById('agentGoal').value;
      const budget = parseFloat(document.getElementById('agentBudget').value) || 1;
      const instanceId = document.getElementById('agentInstance').value;
      if (!goal.trim()) { L().toast('Enter a goal', 'warning'); return; }
      const result = document.getElementById('agentResult');
      result.style.display = ''; result.innerHTML = '<span class="spinner"></span> Starting task...';
      const res = await MayaAPI.agent.run(goal, { budget, instanceId });
      if (res.ok) {
        result.innerHTML = `<span class="tag tag-running">Task started: ${ESC(res.data?.id || '')}</span>`;
        L().toast('Task started!', 'success');
        MayaStore.tasks.load(50);
      } else {
        result.innerHTML = `<span class="tag tag-error">${ESC(res.error)}</span>`;
        L().toast(res.error || 'Failed', 'error');
      }
    };

    window.filterTasks = async function () {
      const filter = document.getElementById('taskFilter').value;
      await MayaStore.tasks.load(50, filter || undefined);
      const t = MayaStore.get('tasks') || [];
      const wrap = document.getElementById('taskTableWrap');
      if (wrap) {
        wrap.innerHTML = t.length ? `<div class="table-wrap"><table><tr><th>Goal</th><th>Status</th><th>Steps</th><th>Cost</th><th>Time</th></tr>${t.map(function(t){return '<tr><td class="truncate text-sm">'+ESC(t.goal||'')+'</td><td><span class="tag tag-'+t.status+'">'+t.status+'</span></td><td>'+(t.steps||[]).length+'</td><td class="text-xs">$'+(t.cost_usd||0).toFixed(4)+'</td><td class="text-xs">'+(t.created_at?new Date(t.created_at).toLocaleTimeString():'—')+'</td></tr>'}).join('\n')}</table></div>` : '<div class="empty-state"><div class="title">No tasks</div></div>';
      }
    };
    window.refreshTasks = function () { window.MayaRouter.navigate('agents'); };

    window.addMemory = async function () {
      const input = document.getElementById('memInput');
      const type = document.getElementById('memType').value;
      if (!input.value.trim()) return;
      await MayaStore.memory.add(input.value, type);
      input.value = '';
      L().toast('Memory saved', 'success');
      window.MayaRouter.navigate('agents');
    };
    window.searchMemory = async function () {
      const q = document.getElementById('memSearch').value.trim();
      if (!q) { window.MayaRouter.navigate('agents'); return; }
      await MayaStore.memory.search(q);
      window.MayaRouter.navigate('agents');
    };

    window.openNewInstance = function () {
      L().openModal(`<h2>New Instance</h2>
        <div class="form-group"><label>Name</label><input class="input" id="instName" placeholder="My Assistant"></div>
        <div class="form-group"><label>Persona</label><textarea class="textarea" id="instPersona" rows="2" placeholder="You are a helpful assistant..."></textarea></div>
        <div class="form-group"><label>Provider (optional)</label><input class="input" id="instProvider" placeholder="groq"></div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="doCreateInstance()">Create</button></div>`);
    };
    window.doCreateInstance = async function () {
      const name = document.getElementById('instName').value.trim();
      if (!name) { L().toast('Name required', 'warning'); return; }
      const res = await MayaAPI.instances.create(name, document.getElementById('instPersona').value, document.getElementById('instProvider').value);
      if (res.ok) { L().closeModal(); L().toast('Instance created', 'success'); window.MayaRouter.navigate('agents'); }
      else { L().toast(res.error || 'Failed', 'error'); }
    };

    window.openNewMission = function () {
      L().openModal(`<h2>New Mission</h2>
        <div class="form-group"><label>Name</label><input class="input" id="cogName" placeholder="Monitor VPS health"></div>
        <div class="form-group"><label>Directive</label><textarea class="textarea" id="cogDirective" rows="3" placeholder="What should this mission accomplish?"></textarea></div>
        <div class="form-group"><label><input type="checkbox" id="cogSelfGen" checked> Auto-generate objectives</label></div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="doCreateMission()">Create</button></div>`);
    };
    window.doCreateMission = async function () {
      const name = document.getElementById('cogName').value.trim();
      if (!name) { L().toast('Name required', 'warning'); return; }
      await MayaAPI.cognition.createMission(name, document.getElementById('cogDirective').value, document.getElementById('cogSelfGen').checked);
      L().closeModal(); L().toast('Mission created', 'success');
      window.MayaRouter.navigate('agents');
    };
    window.runCycle = async function () {
      const res = await MayaAPI.cognition.cycle();
      if (res.ok) { L().toast('Cycle triggered', 'success'); window.MayaRouter.navigate('agents'); }
      else { L().toast(res.error || 'Failed', 'error'); }
    };
  });
})();
