/**
 * Maya 2.0 — Files Workspace
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('files', async function () {
    L().showLoading('Loading files...');
    const res = await MayaAPI.workspace.files();
    const files = res.ok ? (Array.isArray(res.data) ? res.data : (res.data?.files || res.data?.items || [])) : [];

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto">`;
    html += `<div style="display:flex;align-items:center;gap:var(--space-2);margin-bottom:var(--space-3);flex-wrap:wrap">
      <h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);flex:1">📁 Files</h2>
      <button class="btn btn-primary btn-sm" onclick="L().toast('Upload file','info')">↑ Upload</button>
    </div>`;

    html += `<input class="input" type="text" placeholder="Search files..." style="margin-bottom:var(--space-3)">`;

    html += `<div class="card"><div class="card-header"><h3>Workspace Files (${files.length})</h3></div>`;
    if (files.length === 0) {
      html += `<div class="empty-state"><div class="icon">📁</div><div class="title">No files in workspace</div><div class="desc">Upload files or create them from the Coding workspace</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Size</th><th>Type</th><th></th></tr>`;
      files.forEach(function (f) {
        const name = f.name || f.filename || f.path || f;
        const size = f.size || 0;
        const ext = (typeof name === 'string' ? name.split('.').pop() : '').toUpperCase();
        html += `<tr>
          <td class="text-mono">${ESC(typeof name === 'string' ? name : JSON.stringify(name))}</td>
          <td class="text-xs">${size > 1024 ? (size / 1024).toFixed(1) + ' KB' : size + ' B'}</td>
          <td><span class="tag tag-info">${ext || 'FILE'}</span></td>
          <td class="flex gap-sm">
            <button class="action-btn" title="Copy">📋</button>
            <button class="action-btn" title="Download">📤</button>
            <button class="action-btn" title="Delete">🗑</button>
          </td>
        </tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div></div>`;

    L().render(html);
    L().setTitle('Files');
  });
})();
