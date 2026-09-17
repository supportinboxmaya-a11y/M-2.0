/**
 * Maya 2.0 — Business Workspace
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('business', async function () {
    L().showLoading('Loading business...');
    await Promise.all([
      MayaStore.loadProjects(),
      MayaStore.analytics.loadAll(),
    ]);
    const projects = MayaStore.get('projects') || [];
    const analytics = MayaStore.get('analytics') || {};
    const summary = analytics.summary || {};

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto">`;

    html += `<div style="display:flex;align-items:center;gap:var(--space-2);margin-bottom:var(--space-3);flex-wrap:wrap">
      <h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);flex:1">💼 Business</h2>
      <button class="btn btn-primary btn-sm" onclick="openNewProject()">+ New Project</button>
    </div>`;

    // Stats
    html += `<div class="stat-grid mb-md">`;
    html += `<div class="stat-card"><div class="stat-value">${summary.total_tasks || 0}</div><div class="stat-label">Total Tasks</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${summary.success_rate || 0}%</div><div class="stat-label">Success Rate</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">$${(summary.total_cost_usd || 0).toFixed(2)}</div><div class="stat-label">Cost</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${projects.length}</div><div class="stat-label">Projects</div></div>`;
    html += `</div>`;

    // Projects
    html += `<div class="card"><div class="card-header"><h3>Projects (${projects.length})</h3></div>`;
    if (projects.length === 0) {
      html += `<div class="empty-state"><div class="icon">💼</div><div class="title">No projects yet</div><div class="desc">Create your first project to track goals and progress</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Status</th><th>Progress</th><th></th></tr>`;
      projects.forEach(function (p) {
        const goal = p.goal || p.kwargs?.goal || '';
        html += `<tr>
          <td><strong>${ESC(p.name || '')}</strong><div class="text-xs">${ESC(goal.slice(0, 60))}</div></td>
          <td><span class="tag ${p.enabled ? 'tag-success' : 'tag-disabled'}">${p.enabled ? 'Running' : 'Paused'}</span></td>
          <td><div class="progress-bar" style="width:80px"><div class="progress-fill" style="width:${p.progress || 0}%"></div></div></td>
          <td class="flex gap-sm">
            <button class="action-btn" title="Progress" onclick="MayaAPI.projects.progress('${p.id}').then(r=>L().openModal('<pre>'+ESC(JSON.stringify(r.data,null,2))+'</pre>'))">📊</button>
            <button class="action-btn" title="Delete" onclick="MayaAPI.projects.delete('${p.id}').then(()=>window.MayaRouter.navigate('business'))">🗑</button>
          </td>
        </tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    html += `</div>`;
    L().render(html);
    L().setTitle('Business');

    window.openNewProject = function () {
      L().openModal(`<h2>🎯 New Standing Goal</h2>
        <p class="text-sm" style="margin-bottom:var(--space-3);color:var(--text-secondary)">Maya will work toward this goal autonomously on a schedule.</p>
        <div class="form-group"><label>Name</label><input class="input" id="projName" placeholder="Weekly brief"></div>
        <div class="form-group"><label>Goal</label><textarea class="textarea" id="projGoal" rows="3" placeholder="e.g. Summarize the top AI news every week..."></textarea></div>
        <div class="form-group"><label>Cron (optional)</label><input class="input text-mono" id="projCron" value="@hourly" placeholder="0 9 * * 1"></div>
        <div class="modal-actions">
          <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
          <button class="btn btn-primary" onclick="createProject()">Start</button>
        </div>
        <div id="projResult" class="mt-sm text-sm"></div>`);
    };
    window.createProject = function () {
      const name = document.getElementById('projName').value.trim();
      const goal = document.getElementById('projGoal').value.trim();
      if (!name || !goal) { L().toast('Name and goal required', 'warning'); return; }
      document.getElementById('projResult').innerHTML = '<span class="spinner"></span>';
      MayaAPI.projects.create(name, goal, document.getElementById('projCron').value || '@hourly').then(function (res) {
        if (res.ok) {
          document.getElementById('projResult').innerHTML = '<span class="tag tag-success">Project created</span>';
          setTimeout(function () { L().closeModal(); MayaStore.loadProjects(); window.MayaRouter.navigate('business'); }, 1000);
        } else {
          document.getElementById('projResult').innerHTML = '<span class="tag tag-error">' + ESC(res.error) + '</span>';
        }
      });
    };
  });
})();
