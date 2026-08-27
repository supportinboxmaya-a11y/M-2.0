/**
 * Maya 2.0 — Research Workspace
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('research', async function () {
    L().showLoading('Loading research...');
    await MayaStore.loadResearch();
    const r = MayaStore.get('research') || {};
    const reports = r.reports || [];

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto">`;

    // Header
    html += `<div style="display:flex;align-items:center;gap:var(--space-2);margin-bottom:var(--space-3);flex-wrap:wrap">
      <h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);flex:1">🔬 Research</h2>
      <button class="btn btn-primary btn-sm" onclick="openNewResearch()">+ New Research</button>
    </div>`;

    // Search
    html += `<div style="margin-bottom:var(--space-3)"><input class="input" type="text" placeholder="Search reports..." onkeydown="if(event.key==='Enter')L().toast('Search: '+this.value,'info')"></div>`;

    // Report list
    html += `<div class="card"><div class="card-header"><h3>Recent Reports (${reports.length})</h3></div>`;
    if (reports.length === 0) {
      html += `<div class="empty-state"><div class="icon">🔬</div><div class="title">No research reports yet</div><div class="desc">Click "+ New Research" to start your first analysis</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Report</th><th>Sources</th><th>Date</th><th></th></tr>`;
      reports.forEach(function (rp) {
        html += `<tr>
          <td>${ESC(rp.title || rp.name || rp.id || 'Unnamed')}</td>
          <td>${rp.source_count || rp.sources || '—'}</td>
          <td class="text-xs">${rp.created_at ? new Date(rp.created_at).toLocaleDateString() : '—'}</td>
          <td class="flex gap-sm">
            <button class="btn btn-sm btn-ghost" onclick="MayaAPI.research.getReport('${rp.id}').then(r=>L().openModal('<pre>'+ESC(JSON.stringify(r.data,null,2))+'</pre>'))">View</button>
            <button class="action-btn" title="Copy">📋</button>
            <button class="action-btn" title="Delete">🗑</button>
          </td>
        </tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div></div>`;

    // New Research modal
    window.openNewResearch = function () {
      L().openModal(`<h2>New Research</h2>
        <div class="form-group"><label>URLs (one per line)</label><textarea class="textarea" id="researchUrls" rows="4" placeholder="https://example.com/article"></textarea></div>
        <div class="form-group"><label>Analysis Goal</label><input class="input" id="researchGoal" placeholder="Summarize key findings"></div>
        <div class="modal-actions">
          <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
          <button class="btn btn-primary" onclick="runResearch()">Analyze</button>
        </div>
        <div id="researchResult" class="mt-sm text-sm"></div>`);
    };
    window.runResearch = function () {
      const urls = document.getElementById('researchUrls').value.split('\n').map(s => s.trim()).filter(Boolean);
      const goal = document.getElementById('researchGoal').value.trim();
      document.getElementById('researchResult').innerHTML = '<span class="spinner"></span> Analyzing...';
      MayaAPI.research.analyze(urls, goal).then(function (res) {
        if (res.ok) {
          document.getElementById('researchResult').innerHTML = '<span class="tag tag-success">Report created</span>';
          setTimeout(function () { L().closeModal(); window.MayaRouter.navigate('research'); }, 1000);
        } else {
          document.getElementById('researchResult').innerHTML = '<span class="tag tag-error">' + ESC(res.error) + '</span>';
        }
      });
    };

    L().render(html);
    L().setTitle('Research');
  });
})();
