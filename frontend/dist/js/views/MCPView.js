// Maya 2.0 ULTRA - MCP Host View (Phase 38)
export class MCPView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.status = null;
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view mcp-view';
      this.render();
      this.bindEvents();
    }
    this.app.viewContainer.appendChild(this.container);
    this.load();
  }

  hide() {
    if (this.container && this.container.parentNode) this.container.parentNode.removeChild(this.container);
  }

  destroy() {}

  render() {
    this.container.innerHTML = `
      <div class="view-header">
        <h2>MCP Servers</h2>
        <span class="mode-pill" id="mcpPill">…</span>
      </div>
      <div id="mcpBody"><div class="loading-state"><div class="spinner"></div><p>Loading MCP status…</p></div></div>`;
  }

  bindEvents() {}

  async load() {
    const body = this.container.querySelector('#mcpBody');
    let status;
    try { status = await this.app.api.getMCPStatus(); }
    catch (err) {
      body.innerHTML = `<div class="error-state"><div class="icon">⚠️</div><h3>Failed to load</h3><p>${this.escapeHtml(err.message)}</p></div>`;
      return;
    }
    this.status = status;
    const pill = this.container.querySelector('#mcpPill');
    pill.textContent = status.enabled ? 'MCP ENABLED' : 'MCP DISABLED';
    pill.classList.toggle('pill-ok', !!status.enabled);
    pill.classList.toggle('pill-off', !status.enabled);

    const servers = status.servers || {};
    body.innerHTML = !status.enabled ? `
      <div class="empty-state fade-in">
        <div class="icon">🔌</div>
        <div class="title">MCP host disabled</div>
        <div class="desc">Set <code>MCP_ENABLED=true</code> plus <code>MCP_SERVERS=[{...}]</code> in the backend environment. When enabled, connected server tools register as ordinary registry capabilities the planner can use.</div>
      </div>` : `
      <div class="stat-grid stat-grid-3">
        <div class="stat-card"><div class="stat-value">${Object.keys(servers).length}</div><div class="stat-label">Connected servers</div></div>
        <div class="stat-card"><div class="stat-value">${status.total_registered ?? 0}</div><div class="stat-label">Registered tools</div></div>
        <div class="stat-card"><div class="stat-value">${Object.values(servers).filter(s => s.alive).length}</div><div class="stat-label">Alive</div></div>
      </div>

      <div class="panel propose-panel">
        <h3>Connect a server</h3>
        <p class="muted small">stdio (<code>command</code>) or Streamable HTTP (<code>url</code>). Tools register as <code>mcp_&lt;server&gt;_&lt;tool&gt;</code>.</p>
        <form class="form" id="connectForm">
          <div class="form-row">
            <div class="form-group"><label class="form-label" for="mcName">Name *</label><input class="form-input" id="mcName" required placeholder="filesystem"></div>
            <div class="form-group"><label class="form-label" for="mcUrl">URL (HTTP transport)</label><input class="form-input" id="mcUrl" placeholder="http://localhost:9000/mcp"></div>
          </div>
          <div class="form-group"><label class="form-label" for="mcCmd">Command (stdio transport, JSON array)</label>
            <input class="form-input" id="mcCmd" placeholder='["npx","-y","@modelcontextprotocol/server-filesystem","/tmp"]'></div>
          <button class="btn btn-primary btn-sm" type="submit">Connect &amp; register tools</button>
        </form>
      </div>

      ${Object.keys(servers).length ? `
      <div class="result-list" style="margin-top:var(--space-4)">
        ${Object.entries(servers).map(([name, s]) => `
          <div class="result-item">
            <div class="result-head"><strong>${this.escapeHtml(name)}</strong>
              <span class="badge ${s.alive ? 'badge-success' : 'badge-error'}">${s.alive ? 'alive' : 'down'}</span>
              <span class="muted small">${s.registered_tools ?? 0} tools registered</span></div>
          </div>`).join('')}
      </div>
      <div class="row-actions" style="margin-top:var(--space-3)">
        <button class="btn btn-danger btn-sm" id="disconnectBtn">Disconnect all</button>
      </div>`
      : '<p class="muted" style="margin-top:var(--space-4)">No servers connected yet.</p>'}
      <div id="callOut"></div>`;

    body.querySelector('#connectForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = body.querySelector('#mcName').value.trim();
      const url = body.querySelector('#mcUrl').value.trim();
      const cmdRaw = body.querySelector('#mcCmd').value.trim();
      if (!name || (!url && !cmdRaw)) { this.app.toast.error('Name + URL or command required'); return; }
      const config = { name };
      if (url) config.url = url;
      else { try { config.command = JSON.parse(cmdRaw); } catch { this.app.toast.error('Command must be a JSON array'); return; } }
      try {
        const res = await this.app.api.connectMCPServer(config);
        this.app.toast.success(`Connected — ${res.tools_registered} tools registered`);
        this.load();
      } catch (err) { this.app.toast.error('Connect failed', err.message); }
    });
    body.querySelector('#disconnectBtn')?.addEventListener('click', async () => {
      const ok = await this.app.confirm('Disconnect all MCP servers and retract their registered tools?', 'Disconnect');
      if (!ok) return;
      try {
        const res = await this.app.api.disconnectMCPServers();
        this.app.toast.success(`Disconnected (${res.tools_removed} tools removed)`);
        this.load();
      } catch (err) { this.app.toast.error('Failed', err.message); }
    });
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
