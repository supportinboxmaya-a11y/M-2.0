// Maya 2.0 ULTRA - Base View
// Shared list/table view with loading / error / empty states.
export class BaseView {
  constructor(app, options = {}) {
    this.app = app;
    this.options = Object.assign({
      title: 'View',
      apiEndpoint: null,
      dataKey: null,
      showCreateButton: false,
      createLabel: 'Create',
      columns: [],
      actions: [],
      emptyMessage: 'Nothing here yet',
      searchable: true,
    }, options);
    this.container = null;
    this.data = [];
    this.loading = false;
    this.error = null;
    this.searchQuery = '';
  }

  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view base-view';
      this.render();
      this.bindEvents();
      this.loadData();
    }
    this.app.viewContainer.appendChild(this.container);
  }

  hide() {
    if (this.container && this.container.parentNode) {
      this.container.parentNode.removeChild(this.container);
    }
  }

  destroy() {}

  render() {
    const createBtn = this.options.showCreateButton
      ? `<button class="btn btn-primary" id="bvCreateBtn">${this.escapeHtml(this.options.createLabel)}</button>` : '';
    const search = this.options.searchable
      ? `<input type="search" class="form-input bv-search" id="bvSearch" placeholder="Search…" aria-label="Search">` : '';

    this.container.innerHTML = `
      <div class="view-header">
        <h2>${this.escapeHtml(this.options.title)}</h2>
        <div class="view-header-actions">
          ${search}
          ${createBtn}
          <button class="icon-btn" id="bvRefresh" aria-label="Refresh" title="Refresh">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg>
          </button>
        </div>
      </div>
      <div class="bv-body" id="bvBody">
        <div class="loading-state"><div class="spinner"></div><p>Loading…</p></div>
      </div>
    `;
  }

  bindEvents() {
    const refresh = this.container.querySelector('#bvRefresh');
    if (refresh) refresh.addEventListener('click', () => this.loadData());
    const search = this.container.querySelector('#bvSearch');
    if (search) {
      let t;
      search.addEventListener('input', () => {
        clearTimeout(t);
        t = setTimeout(() => { this.searchQuery = search.value.trim().toLowerCase(); this.renderData(); }, 250);
      });
    }
    const create = this.container.querySelector('#bvCreateBtn');
    if (create) create.addEventListener('click', () => this.openCreateModal());
  }

  extract(response) {
    if (this.options.dataKey && response && typeof response === 'object') return response[this.options.dataKey] || [];
    if (Array.isArray(response)) return response;
    return [];
  }

  async loadData() {
    const body = this.container.querySelector('#bvBody');
    if (!body || !this.options.apiEndpoint) return;
    this.loading = true;
    this.error = null;
    body.innerHTML = '<div class="loading-state"><div class="spinner"></div><p>Loading…</p></div>';
    try {
      const response = await this.app.api[this.options.apiEndpoint]();
      this.data = this.extract(response);
      this.renderData();
    } catch (err) {
      this.error = err;
      body.innerHTML = `
        <div class="error-state">
          <div class="icon">⚠️</div>
          <h3>Failed to load</h3>
          <p>${this.escapeHtml(err.message || 'Request failed')}</p>
          <button class="btn btn-secondary" onclick="window.location.reload()">Retry</button>
        </div>`;
    } finally {
      this.loading = false;
    }
  }

  renderData() {
    const body = this.container.querySelector('#bvBody');
    if (!body) return;
    let rows = this.data;
    if (this.searchQuery) {
      rows = rows.filter(r => JSON.stringify(r).toLowerCase().includes(this.searchQuery));
    }
    if (!rows.length) {
      body.innerHTML = `<div class="empty-state"><div class="icon">🗂</div><div class="title">${this.escapeHtml(this.options.title)}</div><div class="desc">${this.escapeHtml(this.options.emptyMessage)}</div></div>`;
      return;
    }
    const cols = this.options.columns;
    const hasActions = this.options.actions.length > 0;
    body.innerHTML = `
      <div class="table-container">
        <table class="data-table">
          <thead><tr>
            ${cols.map(c => `<th>${this.escapeHtml(c.label)}</th>`).join('')}
            ${hasActions ? '<th></th>' : ''}
          </tr></thead>
          <tbody>
            ${rows.map((row, i) => `
              <tr data-row="${i}">
                ${cols.map(c => `<td>${this.renderCell(row, c)}</td>`).join('')}
                ${hasActions ? `<td class="row-actions">${this.options.actions.map(a =>
                  `<button class="task-action-btn" data-action="${a.key}" title="${this.escapeHtml(a.label)}">${this.escapeHtml(a.label)}</button>`).join('')}</td>` : ''}
              </tr>`).join('')}
          </tbody>
        </table>
      </div>`;
    body.querySelectorAll('[data-action]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const idx = parseInt(e.target.closest('tr').dataset.row, 10);
        this.handleAction(btn.dataset.action, rows[idx]);
      });
    });
  }

  renderCell(row, col) {
    let value = typeof col.key === 'function' ? col.key(row) : row[col.key];
    if (col.render) {
      const out = col.render(value, row);
      return out === undefined || out === null ? '—' : out;
    }
    if (value === undefined || value === null || value === '') return '—';
    return this.escapeHtml(String(value));
  }

  handleAction(key, row) {}
  async openCreateModal() {}

  truncate(str, length) {
    if (!str || str.length <= length) return str || '';
    return str.slice(0, length - 3) + '...';
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }
}
