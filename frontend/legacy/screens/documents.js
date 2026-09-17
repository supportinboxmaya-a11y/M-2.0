/**
 * Maya 2.0 — Documents Workspace
 *
 * Ports from old: RAG (970-1005), prompts (932-966),
 * translate (1148-1180), docs (store.js docs)
 */
(function () {
  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  MayaRouter.registerScreen('documents', async function () {
    L().showLoading('Loading documents...');
    await Promise.all([
      MayaStore.loadRAG(),
      MayaStore.loadPrompts(),
      MayaStore.loadLanguages(),
    ]);
    const rag = MayaStore.get('rag') || {};
    const docs = rag.documents || [];
    const prompts = MayaStore.get('prompts') || [];
    const langs = MayaStore.get('languages') || [];

    let html = `<div style="max-width:var(--content-max-width);margin:0 auto;padding-bottom:var(--space-8)">`;
    html += `<h2 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);margin-bottom:var(--space-3)">📄 Documents</h2>`;

    // ── Knowledge Base (RAG) ──
    html += `<div class="card"><div class="card-header"><h3>Knowledge Base</h3></div>`;
    html += `<div class="stat-grid mb-sm">`;
    html += `<div class="stat-card"><div class="stat-value">${rag.stats?.document_count || rag.stats?.total_documents || docs.length}</div><div class="stat-label">Documents</div></div>`;
    html += `<div class="stat-card"><div class="stat-value">${rag.stats?.chunk_count || 0}</div><div class="stat-label">Chunks</div></div>`;
    html += `</div>`;
    html += `<div class="flex mb-sm"><input class="input" id="ragSearch" placeholder="Search knowledge base..." style="flex:1" onkeydown="if(event.key==='Enter')searchRag()"><button class="btn btn-sm" onclick="searchRag()">🔍</button></div>
      <div id="ragResults" class="text-sm mb-sm"></div>`;
    if (docs.length > 0) {
      html += `<div class="table-wrap"><table><tr><th>Source</th><th>Version</th><th></th></tr>`;
      docs.forEach(function (d) {
        html += `<tr><td class="text-sm">${ESC(d.source || d.id || '')}</td><td>${d.version || 1}</td>
          <td><button class="btn btn-sm btn-danger" onclick="MayaAPI.rag.deleteDoc('${d.id}').then(()=>window.MayaRouter.navigate('documents'))">Delete</button></td></tr>`;
      });
      html += `</table></div>`;
    } else {
      html += `<div class="empty-state"><div class="icon">📚</div><div class="title">No documents ingested</div></div>`;
    }
    html += `</div>`;

    // ── Prompt Library ──
    html += `<div class="card"><div class="card-header"><h3>Prompt Library (${prompts.length})</h3><button class="btn btn-primary btn-sm" onclick="openNewPrompt()">+ New</button></div>`;
    if (prompts.length === 0) {
      html += `<div class="empty-state"><div class="icon">📝</div><div class="title">No saved prompts</div></div>`;
    } else {
      html += `<div class="table-wrap"><table><tr><th>Name</th><th>Category</th><th>Body</th></tr>`;
      prompts.forEach(function (p) {
        html += `<tr><td>${ESC(p.name)}</td><td><span class="tag tag-info">${p.category || 'general'}</span></td>
          <td class="text-sm truncate" style="max-width:200px">${ESC((p.body || '').slice(0, 80))}</td></tr>`;
      });
      html += `</table></div>`;
    }
    html += `</div>`;

    // ── Translate ──
    html += `<div class="card"><div class="card-header"><h3>Translate</h3></div>
      <div class="form-row">
        <div class="form-group"><label>Source</label><select class="select" id="transSource"><option value="">Auto-detect</option>${(Array.isArray(langs) ? langs : []).map(l => `<option value="${l.code || l}">${l.name || l}</option>`).join('')}</select></div>
        <div class="form-group"><label>Target</label><select class="select" id="transTarget">${(Array.isArray(langs) ? langs : []).map(l => `<option value="${l.code || l}">${l.name || l}</option>`).join('')}</select></div>
      </div>
      <div class="form-group"><textarea class="textarea" id="transText" rows="2" placeholder="Text to translate..."></textarea></div>
      <button class="btn btn-primary" onclick="doTranslate()">🌐 Translate</button>
      <div id="transResult" class="mt-sm text-sm"></div>
    </div>`;

    html += `</div>`;
    L().render(html);
    L().setTitle('Documents');

    window.searchRag = async function () {
      const q = document.getElementById('ragSearch').value.trim();
      if (!q) return;
      const res = await MayaAPI.rag.search(q);
      document.getElementById('ragResults').innerHTML = res.ok ? `<pre>${ESC(JSON.stringify(res.data, null, 2))}</pre>` : `<span class="tag tag-error">${ESC(res.error)}</span>`;
    };

    window.openNewPrompt = function () {
      L().openModal(`<h2>New Prompt</h2>
        <div class="form-group"><label>Name</label><input class="input" id="promptName"></div>
        <div class="form-group"><label>Category</label><input class="input" id="promptCategory" value="general"></div>
        <div class="form-group"><label>Body (use {{variable}})</label><textarea class="textarea" id="promptBody" rows="5"></textarea></div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="createPrompt()">Save</button></div>`);
    };
    window.createPrompt = async function () {
      const name = document.getElementById('promptName').value.trim();
      if (!name) { L().toast('Name required', 'warning'); return; }
      await MayaAPI.prompts.create(name, document.getElementById('promptBody').value, document.getElementById('promptCategory').value, []);
      L().closeModal(); L().toast('Prompt saved', 'success');
      window.MayaRouter.navigate('documents');
    };

    window.doTranslate = async function () {
      const text = document.getElementById('transText').value.trim();
      if (!text) { L().toast('Enter text', 'warning'); return; }
      const target = document.getElementById('transTarget').value;
      const source = document.getElementById('transSource').value || undefined;
      const res = await MayaAPI.translate.translate(text, target, source);
      document.getElementById('transResult').innerHTML = res.ok ? `<pre>${ESC(res.data?.translation || res.data?.text || JSON.stringify(res.data))}</pre>` : `<span class="tag tag-error">${ESC(res.error)}</span>`;
    };
  });
})();
