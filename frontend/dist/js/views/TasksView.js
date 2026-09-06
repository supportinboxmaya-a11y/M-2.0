// Maya 2.0 ULTRA - Tasks View
export class TasksView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.tasks = [];
    this.currentFilter = 'all';
    this.selectedTask = null;
    this.detailOpen = false;
    this.eventSource = null;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view tasks-view';
      this.render();
      this.bindEvents();
      this.loadTasks();
    }
    this.app.viewContainer.appendChild(this.container);
  }
  
  hide() {
    if (this.container && this.container.parentNode) {
      this.container.parentNode.removeChild(this.container);
    }
    this.closeDetail();
  }

  destroy() {
    if (this.eventSource) { this.eventSource.close(); this.eventSource = null; }
  }
  
  render() {
    this.container.innerHTML = `
      <div class="tasks-header">
        <h2>Tasks</h2>
        <div class="tasks-filters" id="taskFilters">
          <button class="filter-btn active" data-filter="all">All</button>
          <button class="filter-btn" data-filter="pending">Pending</button>
          <button class="filter-btn" data-filter="running">Running</button>
          <button class="filter-btn" data-filter="done">Done</button>
          <button class="filter-btn" data-filter="failed">Failed</button>
        </div>
        <button class="btn btn-primary" id="newTaskBtn">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          New Task
        </button>
      </div>
      
      <div class="tasks-kanban" id="tasksKanban">
        <div class="kanban-column" data-status="pending">
          <div class="kanban-header">
            <div class="kanban-title">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle></svg>
              Pending
              <span class="kanban-count" id="countPending">0</span>
            </div>
          </div>
          <div class="kanban-drop-zone" id="zonePending"></div>
        </div>
        
        <div class="kanban-column" data-status="running">
          <div class="kanban-header">
            <div class="kanban-title">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="4"></circle><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"></path></svg>
              Running
              <span class="kanban-count" id="countRunning">0</span>
            </div>
          </div>
          <div class="kanban-drop-zone" id="zoneRunning"></div>
        </div>
        
        <div class="kanban-column" data-status="done">
          <div class="kanban-header">
            <div class="kanban-title">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
              Done
              <span class="kanban-count" id="countDone">0</span>
            </div>
          </div>
          <div class="kanban-drop-zone" id="zoneDone"></div>
        </div>
        
        <div class="kanban-column" data-status="failed">
          <div class="kanban-header">
            <div class="kanban-title">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
              Failed
              <span class="kanban-count" id="countFailed">0</span>
            </div>
          </div>
          <div class="kanban-drop-zone" id="zoneFailed"></div>
        </div>
      </div>
      
      <!-- Task Detail Drawer -->
      <div class="task-detail" id="taskDetail" style="display: none;">
        <div class="task-detail-header">
          <h3 class="task-detail-title" id="detailTitle">Task Details</h3>
          <button class="modal-close" id="closeDetail" aria-label="Close detail">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
          </button>
        </div>
        <div class="task-detail-body" id="detailBody"></div>
        <div class="task-detail-footer">
          <button class="btn btn-secondary" id="closeDetailBtn">Close</button>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    // Filters
    this.container.querySelector('#taskFilters').addEventListener('click', (e) => {
      const btn = e.target.closest('.filter-btn');
      if (btn) this.setFilter(btn.dataset.filter);
    });
    
    // New task
    this.container.querySelector('#newTaskBtn').addEventListener('click', () => this.openNewTaskModal());
    
    // Close detail
    this.container.querySelector('#closeDetail').addEventListener('click', () => this.closeDetail());
    this.container.querySelector('#closeDetailBtn').addEventListener('click', () => this.closeDetail());
  }
  
  async loadTasks() {
    try {
      const tasks = await this.app.api.getTasks(100);
      this.tasks = tasks;
      this.renderKanban();
    } catch (error) {
      this.app.toast.error('Failed to load tasks', error.message);
    }
  }
  
  setFilter(filter) {
    this.currentFilter = filter;
    this.container.querySelectorAll('.filter-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.filter === filter);
    });
    this.renderKanban();
  }
  
  renderKanban() {
    const statuses = ['pending', 'running', 'done', 'failed'];
    
    statuses.forEach(status => {
      const zone = this.container.querySelector(`#zone${status.charAt(0).toUpperCase() + status.slice(1)}`);
      const countEl = this.container.querySelector(`#count${status.charAt(0).toUpperCase() + status.slice(1)}`);
      
      let tasks = this.tasks.filter(t => t.status === status);
      if (this.currentFilter !== 'all') {
        tasks = tasks.filter(t => t.status === this.currentFilter);
      }
      
      countEl.textContent = tasks.length;
      
      zone.innerHTML = tasks.map(task => `
        <div class="kanban-task" data-id="${task.id}" draggable="true">
          <div class="task-header">
            <span class="task-id">${task.id.slice(0, 8)}</span>
            <span class="task-status-badge task-status-${task.status}">${status}</span>
          </div>
          <div class="task-goal">${this.escapeHtml(this.truncate(task.goal, 100))}</div>
          <div class="task-meta">
            ${task.provider_used ? `<span class="task-provider">${task.provider_used}</span>` : ''}
            ${task.cost_usd ? `<span class="task-cost">$${task.cost_usd.toFixed(4)}</span>` : ''}
            <span>${this.formatRelativeTime(task.created_at)}</span>
          </div>
          <div class="task-actions">
            <button class="task-action-btn" data-action="view" title="View details" aria-label="View details">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
            </button>
            ${task.status === 'done' ? `
              <button class="task-action-btn" data-action="reflect" title="Reflect" aria-label="Reflect on task">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.92 9.62a10 10 0 1 1-7.84 7.84"></path><polyline points="12 2 12 4 12 20 12 22"></polyline></svg>
              </button>
            ` : ''}
            ${task.status !== 'done' && task.status !== 'running' ? `
              <button class="task-action-btn" data-action="delete" title="Delete" aria-label="Delete task">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
              </button>
            ` : ''}
          </div>
        </div>
      `).join('');
      
      // Bind events
      zone.querySelectorAll('.kanban-task').forEach(taskEl => {
        taskEl.addEventListener('click', (e) => {
          if (e.target.closest('.task-action-btn')) return;
          this.openDetail(taskEl.dataset.id);
        });
        
        taskEl.querySelectorAll('.task-action-btn').forEach(btn => {
          btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const action = btn.dataset.action;
            const id = taskEl.dataset.id;
            if (action === 'view') this.openDetail(id);
            else if (action === 'reflect') this.reflectTask(id);
            else if (action === 'delete') this.deleteTask(id);
          });
        });
      });
    });
  }
  
  async openNewTaskModal() {
    const modal = new this.app.Modal({
      title: 'New Task',
      size: 'medium',
      onConfirm: async () => {
        const goal = modal.element.querySelector('#taskGoal').value.trim();
        const budget = parseFloat(modal.element.querySelector('#taskBudget').value) || 1.0;
        
        if (!goal) {
          this.app.toast.error('Goal is required');
          return false;
        }
        
        try {
          await this.app.api.createTask(goal, budget);
          this.app.toast.success('Task created');
          this.loadTasks();
          return true;
        } catch (error) {
          this.app.toast.error('Failed to create task', error.message);
          return false;
        }
      }
    });
    
    modal.setContent(`
      <div class="form-group">
        <label class="form-label" for="taskGoal">Goal <span class="required">*</span></label>
        <textarea class="form-textarea" id="taskGoal" rows="4" placeholder="Describe what you want Maya to do..."></textarea>
      </div>
      <div class="form-group">
        <label class="form-label" for="taskBudget">Budget (USD)</label>
        <input type="number" class="form-input" id="taskBudget" value="1.0" step="0.1" min="0.01">
      </div>
    `);
    
    await modal.open();
  }
  
  async openDetail(taskId) {
    const task = this.tasks.find(t => t.id === taskId);
    if (!task) return;
    
    this.selectedTask = task;
    this.detailOpen = true;
    
    const detail = this.container.querySelector('#taskDetail');
    const title = this.container.querySelector('#detailTitle');
    const body = this.container.querySelector('#detailBody');
    
    title.textContent = `Task ${task.id.slice(0, 8)}`;
    
    body.innerHTML = `
      <div class="task-detail-section">
        <div class="task-detail-section-title">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"></path></svg>
          Goal
        </div>
        <div class="task-detail-field">
          <div class="task-detail-label">Goal</div>
          <div class="task-detail-value">${this.escapeHtml(task.goal)}</div>
        </div>
      </div>
      
      <div class="task-detail-section">
        <div class="task-detail-section-title">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle></svg>
          Status
        </div>
        <div class="task-detail-field">
          <div class="task-detail-label">Status</div>
          <div class="task-detail-value">
            <span class="task-status-badge task-status-${task.status}">${task.status}</span>
          </div>
        </div>
        <div class="task-detail-field">
          <div class="task-detail-label">Created</div>
          <div class="task-detail-value">${this.formatDateTime(task.created_at)}</div>
        </div>
        ${task.completed_at ? `
          <div class="task-detail-field">
            <div class="task-detail-label">Completed</div>
            <div class="task-detail-value">${this.formatDateTime(task.completed_at)}</div>
          </div>
        ` : ''}
        ${task.provider_used ? `
          <div class="task-detail-field">
            <div class="task-detail-label">Provider</div>
            <div class="task-detail-value">${task.provider_used}</div>
          </div>
        ` : ''}
        ${task.cost_usd ? `
          <div class="task-detail-field">
            <div class="task-detail-label">Cost</div>
            <div class="task-detail-value">$${task.cost_usd.toFixed(6)}</div>
          </div>
        ` : ''}
        ${task.tokens_used ? `
          <div class="task-detail-field">
            <div class="task-detail-label">Tokens</div>
            <div class="task-detail-value">${task.tokens_used.toLocaleString()}</div>
          </div>
        ` : ''}
      </div>
      
      ${task.result ? `
        <div class="task-detail-section">
          <div class="task-detail-section-title">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path></svg>
            Result
          </div>
          <div class="task-detail-field">
            <div class="task-detail-value" style="white-space: pre-wrap; font-family: var(--font-mono); font-size: var(--text-sm);">${this.escapeHtml(task.result)}</div>
          </div>
        </div>
      ` : ''}
      
      ${task.error ? `
        <div class="task-detail-section">
          <div class="task-detail-section-title">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
            Error
          </div>
          <div class="task-detail-field">
            <div class="task-detail-value" style="color: var(--error);">${this.escapeHtml(task.error)}</div>
          </div>
        </div>
      ` : ''}
      
      ${task.steps && task.steps.length > 0 ? `
        <div class="task-detail-section">
          <div class="task-detail-section-title">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="9" y1="18" x2="20.48 18"></line><path d="M5.29 5.29a10 10 0 0 1 13.42 13.42"></path><line x1="12" y1="12" x2="19.11 19.11"></line></svg>
            Steps (${task.steps.length})
          </div>
          <div class="task-steps">
            ${task.steps.map((step, index) => `
              <div class="task-step">
                <div class="task-step-number">${index + 1}</div>
                <div class="task-step-content">
                  <div class="task-step-title">${this.escapeHtml(step.title || step.description || `Step ${index + 1}`)}</div>
                  ${step.description ? `<div class="task-step-description">${this.escapeHtml(step.description)}</div>` : ''}
                  ${step.tool ? `<div class="task-step-tool">Tool: ${step.tool}</div>` : ''}
                  ${step.result ? `
                    <div class="task-step-result">${this.escapeHtml(typeof step.result === 'object' ? JSON.stringify(step.result, null, 2) : step.result)}</div>
                  ` : ''}
                  <div class="task-step-status ${step.success ? 'success' : 'failed'}">
                    ${step.success ? '✓ Success' : '✗ Failed'}
                  </div>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      ` : ''}
      
      ${task.reflection ? `
        <div class="task-reflection">
          <div class="task-reflection-title">Reflection</div>
          <div class="task-reflection-content">${this.escapeHtml(task.reflection)}</div>
        </div>
      ` : ''}

      ${(task.status === 'running' || task.status === 'pending' || task.status === 'paused') ? `
      <div class="task-detail-section">
        <div class="task-detail-section-title">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
          Live execution
        </div>
        <div class="row-actions" style="margin-bottom:var(--space-2)">
          ${task.status === 'running' ? `<button class="btn btn-secondary btn-sm" data-tact="pause">Pause</button>` : ''}
          ${task.status === 'paused' ? `<button class="btn btn-secondary btn-sm" data-tact="resume">Resume</button>` : ''}
          ${task.status !== 'done' && task.status !== 'failed' ? `<button class="btn btn-danger btn-sm" data-tact="cancel">Cancel</button>` : ''}
          <span id="streamState" class="muted small"></span>
        </div>
        <div id="liveEventLog" class="live-event-log"><p class="muted small">Connecting to event stream…</p></div>
      </div>` : ''}
    `;

    detail.style.display = 'block';
    document.body.style.overflow = 'hidden';

    body.querySelectorAll('[data-tact]').forEach(btn => btn.addEventListener('click', async () => {
      const act = btn.dataset.tact;
      try {
        if (act === 'pause') await this.app.api.pauseTask(taskId);
        if (act === 'resume') await this.app.api.resumeTask(taskId);
        if (act === 'cancel') {
          const ok = await this.app.confirm('Cancel this running task?', 'Cancel task');
          if (!ok) return;
          await this.app.api.cancelTask(taskId);
        }
        this.loadTasks();
        setTimeout(() => this.openDetail(taskId), 400);
      } catch (err) { this.app.toast.error(`${act} failed`, err.message); }
    }));

    if (task.status === 'running' || task.status === 'pending' || task.status === 'paused') {
      this.attachStream(taskId);
    }
  }

  attachStream(taskId) {
    this.detachStream();
    const log = this.container.querySelector('#liveEventLog');
    const state = this.container.querySelector('#streamState');
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const token = this.app.auth.getToken();
    this.wsStream = new WebSocket(`${protocol}//${window.location.host}/ws/stream/${taskId}?token=${encodeURIComponent(token)}`);
    
    this.wsStream.onopen = () => { if (state) state.textContent = '● live'; };
    this.wsStream.onmessage = (event) => {
      let data;
      try { data = JSON.parse(event.data); } catch { return; }
      if (!log) return;
      if (data.type === 'heartbeat') return;
      if (data.type === 'connected' || data.type === 'reconnect') {
        log.innerHTML = '';
        const status = data.status || 'connected';
        const step = data.current_step ? ` · step: ${data.current_step}` : '';
        this.appendEvent(log, 'connected', `status=${status}${step}`);
        return;
      }
      const summary = data.tool_name || data.step_title || data.message || data.event_type || data.type;
      this.appendEvent(log, data.type, typeof summary === 'string' ? summary : JSON.stringify(summary));
      if (data.type === 'task_completed' || data.type === 'task_failed' || data.status === 'completed' || data.status === 'failed') {
        this.detachStream();
        this.loadTasks();
      }
    };
    this.wsStream.onerror = () => {
      if (state) state.textContent = '○ stream disconnected';
    };
    this.wsStream.onclose = () => {
      if (state) state.textContent = '○ stream closed';
    };
  }

  appendEvent(log, type, text) {
    const row = document.createElement('div');
    row.className = 'live-event-row';
    const t = new Date().toLocaleTimeString();
    row.innerHTML = `<span class="evt-time">${t}</span><span class="badge badge-neutral">${this.escapeHtml(String(type))}</span> <span>${this.escapeHtml(text)}</span>`;
    log.appendChild(row);
    log.scrollTop = log.scrollHeight;
  }

  detachStream() {
    if (this.wsStream) {
      this.wsStream.close();
      this.wsStream = null;
    }
    if (this.eventSource) {
      this.eventSource.close();
      this.eventSource = null;
    }
  }
  
  closeDetail() {
    this.detailOpen = false;
    this.selectedTask = null;
    this.detachStream();
    this.container.querySelector('#taskDetail').style.display = 'none';
    document.body.style.overflow = '';
  }
  
  async reflectTask(taskId) {
    try {
      const result = await this.app.api.reflectTask(taskId, { retry: false });
      this.app.toast.success('Reflection completed');
      this.loadTasks();
      if (this.selectedTask?.id === taskId) this.openDetail(taskId);
    } catch (error) {
      this.app.toast.error('Reflection failed', error.message);
    }
  }
  
  async deleteTask(taskId) {
    const confirmed = await this.app.confirmDelete('task');
    if (!confirmed) return;
    
    try {
      await this.app.api.deleteTask(taskId);
      this.app.toast.success('Task deleted');
      this.loadTasks();
      if (this.selectedTask?.id === taskId) this.closeDetail();
    } catch (error) {
      this.app.toast.error('Failed to delete task', error.message);
    }
  }
  
  formatRelativeTime(timestamp) {
    if (!timestamp) return 'Unknown';
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    const mins = Math.floor(diff / 60000);
    const hours = Math.floor(mins / 60);
    const days = Math.floor(hours / 24);
    
    if (mins < 1) return 'Just now';
    if (mins < 60) return `${mins}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  }
  
  formatDateTime(timestamp) {
    if (!timestamp) return 'Unknown';
    return new Date(timestamp).toLocaleString();
  }
  
  truncate(str, length) {
    if (!str || str.length <= length) return str || '';
    return str.slice(0, length - 3) + '...';
  }
  
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  
  onTaskEvent(type, data) {
    if (type === 'started' || type === 'progress') {
      this.loadTasks(); // Refresh to show updates
    } else if (type === 'done') {
      this.loadTasks();
      if (this.selectedTask?.id === data.id) this.openDetail(data.id);
    }
  }
  
  destroy() {}
}