// Maya 2.0 ULTRA - DataTable Component
export class DataTable {
  constructor(container, options = {}) {
    this.container = container;
    this.options = {
      columns: [],
      data: [],
      sortable: true,
      filterable: false,
      selectable: false,
      pagination: true,
      pageSize: 20,
      rowClick: null,
      renderRow: null,
      actions: null,
      emptyMessage: 'No data available',
      loading: false,
      ...options
    };
    this.sortColumn = null;
    this.sortDirection = 'asc';
    this.currentPage = 1;
    this.filterText = '';
    this.selectedRows = new Set();
    this.filteredData = [];
    this.render();
    this.bindEvents();
  }
  
  setData(data) {
    this.options.data = data;
    this.currentPage = 1;
    this.applyFilters();
    this.render();
  }
  
  setColumns(columns) {
    this.options.columns = columns;
    this.render();
  }
  
  setLoading(loading) {
    this.options.loading = loading;
    this.render();
  }
  
  applyFilters() {
    let data = [...this.options.data];
    
    // Apply text filter
    if (this.filterText && this.options.filterable) {
      const search = this.filterText.toLowerCase();
      data = data.filter(row => 
        this.options.columns.some(col => {
          const value = row[col.key];
          return value && String(value).toLowerCase().includes(search);
        })
      );
    }
    
    // Apply sort
    if (this.sortColumn) {
      data.sort((a, b) => {
        const aVal = a[this.sortColumn];
        const bVal = b[this.sortColumn];
        const direction = this.sortDirection === 'asc' ? 1 : -1;
        
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1 * direction;
        if (bVal == null) return -1 * direction;
        
        if (typeof aVal === 'string') {
          return aVal.localeCompare(bVal) * direction;
        }
        return (aVal - bVal) * direction;
      });
    }
    
    this.filteredData = data;
  }
  
  getPaginatedData() {
    if (!this.options.pagination) return this.filteredData;
    
    const start = (this.currentPage - 1) * this.options.pageSize;
    const end = start + this.options.pageSize;
    return this.filteredData.slice(start, end);
  }
  
  getTotalPages() {
    if (!this.options.pagination) return 1;
    return Math.ceil(this.filteredData.length / this.options.pageSize);
  }
  
  render() {
    const { columns, selectable, actions, emptyMessage, loading } = this.options;
    const data = this.getPaginatedData();
    const totalPages = this.getTotalPages();
    
    const columnsHtml = columns.map(col => `
      <th data-column="${col.key}" style="width: ${col.width || 'auto'}" ${col.sortable !== false ? 'class="sortable"' : ''}>
        ${col.label}
        ${col.sortable !== false ? '<svg class="sort-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"></polyline></svg>' : ''}
      </th>
    `).join('');
    
    const selectHeader = selectable ? '<th style="width: 40px"><input type="checkbox" class="select-all" aria-label="Select all"></th>' : '';
    const actionsHeader = actions ? '<th style="width: 120px">Actions</th>' : '';
    
    let rowsHtml = '';
    
    if (loading) {
      rowsHtml = `
        <tr class="loading-row">
          <td colspan="${columns.length + (selectable ? 1 : 0) + (actions ? 1 : 0)}" style="text-align: center; padding: var(--space-8);">
            <div class="loading-state">
              <div class="spinner"></div>
              <p>Loading...</p>
            </div>
          </td>
        </tr>
      `;
    } else if (data.length === 0) {
      rowsHtml = `
        <tr class="empty-row">
          <td colspan="${columns.length + (selectable ? 1 : 0) + (actions ? 1 : 0)}" style="text-align: center; padding: var(--space-8); color: var(--text-tertiary);">
            ${emptyMessage}
          </td>
        </tr>
      `;
    } else {
      rowsHtml = data.map((row, index) => {
        const rowId = row.id || index;
        const isSelected = this.selectedRows.has(rowId);
        
        const cellsHtml = columns.map(col => {
          const value = row[col.key];
          let displayValue = value;
          
          if (col.render) {
            displayValue = col.render(value, row);
          } else if (value === null || value === undefined) {
            displayValue = '<span style="color: var(--text-tertiary);">—</span>';
          } else if (typeof value === 'object') {
            displayValue = JSON.stringify(value);
          }
          
          return `<td data-column="${col.key}">${displayValue}</td>`;
        }).join('');
        
        const selectCell = selectable ? `<td><input type="checkbox" class="row-select" data-id="${rowId}" ${isSelected ? 'checked' : ''} aria-label="Select row"></td>` : '';
        const actionsCell = actions ? `<td><div class="cell-actions">${actions.map(a => a.render ? a.render(row) : `<button class="btn btn-sm btn-ghost" data-action="${a.key}" data-id="${rowId}" title="${a.label}">${a.icon || a.label}</button>`).join('')}</div></td>` : '';
        
        return `
          <tr data-id="${rowId}" class="${isSelected ? 'selected' : ''}" ${this.options.rowClick ? 'style="cursor: pointer;"' : ''}>
            ${selectCell}
            ${cellsHtml}
            ${actionsCell}
          </tr>
        `;
      }).join('');
    }
    
    const paginationHtml = this.options.pagination && totalPages > 1 ? `
      <div class="table-pagination">
        <button class="btn btn-sm btn-secondary pagination-btn" data-page="first" ${this.currentPage === 1 ? 'disabled' : ''} aria-label="First page">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"></polyline><line x1="3" y1="12" x2="9" y2="12"></line></svg>
        </button>
        <button class="btn btn-sm btn-secondary pagination-btn" data-page="prev" ${this.currentPage === 1 ? 'disabled' : ''} aria-label="Previous page">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"></polyline></svg>
        </button>
        <span class="pagination-info">Page ${this.currentPage} of ${totalPages} (${this.filteredData.length} items)</span>
        <button class="btn btn-sm btn-secondary pagination-btn" data-page="next" ${this.currentPage === totalPages ? 'disabled' : ''} aria-label="Next page">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"></polyline></svg>
        </button>
        <button class="btn btn-sm btn-secondary pagination-btn" data-page="last" ${this.currentPage === totalPages ? 'disabled' : ''} aria-label="Last page">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"></polyline><line x1="15" y1="12" x2="21" y2="12"></line></svg>
        </button>
      </div>
    ` : '';
    
    const filterHtml = this.options.filterable ? `
      <div class="table-toolbar">
        <div class="table-search">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
          <input type="text" class="form-input table-filter-input" placeholder="Filter..." value="${this.filterText}" aria-label="Filter table">
        </div>
        <div class="table-info">${this.filteredData.length} of ${this.options.data.length} items</div>
      </div>
    ` : '';
    
    this.container.innerHTML = `
      ${filterHtml}
      <div class="table-container">
        <table class="table" role="grid">
          <thead>
            <tr>
              ${selectHeader}
              ${columnsHtml}
              ${actionsHeader}
            </tr>
          </thead>
          <tbody>
            ${rowsHtml}
          </tbody>
        </table>
      </div>
      ${paginationHtml}
    `;
  }
  
  bindEvents() {
    // Sort
    this.container.querySelectorAll('th.sortable').forEach(th => {
      th.addEventListener('click', () => {
        const column = th.dataset.column;
        if (this.sortColumn === column) {
          this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
          this.sortColumn = column;
          this.sortDirection = 'asc';
        }
        this.applyFilters();
        this.currentPage = 1;
        this.render();
      });
    });
    
    // Filter
    const filterInput = this.container.querySelector('.table-filter-input');
    if (filterInput) {
      filterInput.addEventListener('input', (e) => {
        this.filterText = e.target.value;
        this.currentPage = 1;
        this.applyFilters();
        this.render();
      });
    }
    
    // Select all
    const selectAll = this.container.querySelector('.select-all');
    if (selectAll) {
      selectAll.addEventListener('change', (e) => {
        const checked = e.target.checked;
        const data = this.getPaginatedData();
        
        if (checked) {
          data.forEach(row => this.selectedRows.add(row.id));
        } else {
          data.forEach(row => this.selectedRows.delete(row.id));
        }
        this.render();
      });
    }
    
    // Row select
    this.container.querySelectorAll('.row-select').forEach(checkbox => {
      checkbox.addEventListener('change', (e) => {
        const id = e.target.dataset.id;
        if (e.target.checked) {
          this.selectedRows.add(id);
        } else {
          this.selectedRows.delete(id);
        }
        
        // Update select all
        const selectAll = this.container.querySelector('.select-all');
        if (selectAll) {
          const data = this.getPaginatedData();
          selectAll.checked = data.every(row => this.selectedRows.has(row.id));
          selectAll.indeterminate = data.some(row => this.selectedRows.has(row.id)) && !selectAll.checked;
        }
        
        this.render();
      });
    });
    
    // Row click
    if (this.options.rowClick) {
      this.container.querySelectorAll('tbody tr[data-id]').forEach(tr => {
        tr.addEventListener('click', (e) => {
          if (e.target.tagName === 'INPUT' || e.target.tagName === 'BUTTON' || e.target.closest('button')) return;
          const id = tr.dataset.id;
          const row = this.options.data.find(r => r.id == id);
          if (row) this.options.rowClick(row, e);
        });
      });
    }
    
    // Actions
    if (this.options.actions) {
      this.container.querySelectorAll('[data-action]').forEach(btn => {
        btn.addEventListener('click', (e) => {
          e.stopPropagation();
          const actionKey = btn.dataset.action;
          const id = btn.dataset.id;
          const row = this.options.data.find(r => r.id == id);
          const action = this.options.actions.find(a => a.key === actionKey);
          if (action && row && action.onClick) {
            action.onClick(row, e);
          }
        });
      });
    }
    
    // Pagination
    this.container.querySelectorAll('.pagination-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const page = btn.dataset.page;
        const totalPages = this.getTotalPages();
        
        if (page === 'first') this.currentPage = 1;
        else if (page === 'prev') this.currentPage = Math.max(1, this.currentPage - 1);
        else if (page === 'next') this.currentPage = Math.min(totalPages, this.currentPage + 1);
        else if (page === 'last') this.currentPage = totalPages;
        
        this.render();
      });
    });
  }
  
  getSelectedRows() {
    return this.options.data.filter(row => this.selectedRows.has(row.id));
  }
  
  clearSelection() {
    this.selectedRows.clear();
    this.render();
  }
  
  destroy() {
    // Cleanup if needed
  }
}