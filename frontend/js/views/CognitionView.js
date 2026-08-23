// Maya 2.0 ULTRA - Cognition View
export class CognitionView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.currentTab = 'missions';
    this.missions = [];
    this.objectives = [];
    this.cognitionStatus = null;
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view cognition-view';
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
  
  render() {
    this.container.innerHTML = `
      <div class="cognition-header">
        <div class="cognition-status" id="cognitionStatus">
          <div class="cognition-status-item">
            <span class="cognition-status-label">Status</span>
            <span class="cognition-status-value" id="statusEnabled">—</span>
          </div>
          <div class="cognition-status-divider"></div>
          <div class="cognition-status-item">
            <span class="cognition-status-label">Autorun</span>
            <span class="cognition-status-value" id="statusAutorun">—</span>
          </div>
          <div class="cognition-status-divider"></div>
          <div class="cognition-status-item">
            <span class="cognition-status-label">Missions</span>
            <span class="cognition-status-value" id="statusMissions">—</span>
          </div>
          <div class="cognition-status-divider"></div>
          <div class="cognition-status-item">
            <span class="cognition-status-label">Pending</span>
            <span class="cognition-status-value" id="statusPending">—</span>
          </div>
        </div>
        <div class="cognition-controls">
          <button class="btn btn-primary" id="triggerCycle">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg>
            Run Cycle
          </button>
          <button class="btn btn-secondary" id="pauseCognition">Pause</button>
          <button class="btn btn-secondary" id="resumeCognition">Resume</button>
        </div>
      </div>
      
      <div class="cognition-tabs" id="cognitionTabs">
        <button class="cognition-tab active" data-tab="missions">Missions</button>
        <button class="cognition-tab" data-tab="objectives">Objectives</button>
        <button class="cognition-tab" data-tab="audit">Audit Log</button>
        <button class="cognition-tab" data-tab="business">Business</button>
      </div>
      
      <div class="cognition-tab-panel active" id="panelMissions">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4);">
          <h3>Missions</h3>
          <button class="btn btn-primary" id="newMissionBtn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            New Mission
          </button>
        </div>
        <div class="mission-list" id="missionsList">
          <div class="loading-state"><div class="spinner"></div><p>Loading missions...</p></div>
        </div>
      </div>
      
      <div class="cognition-tab-panel" id="panelObjectives" style="display: none;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4);">
          <h3>Objectives</h3>
          <button class="btn btn-primary" id="newObjectiveBtn">New Objective</button>
        </div>
        <div class="objective-table-container" id="objectivesTable">
          <div class="loading-state"><div class="spinner"></div><p>Loading objectives...</p></div>
        </div>
      </div>
      
      <div class="cognition-tab-panel" id="panelAudit" style="display: none;">
        <div class="audit-list" id="auditList">
          <div class="loading-state"><div class="spinner"></div><p>Loading audit log...</p></div>
        </div>
      </div>
      
      <div class="cognition-tab-panel" id="panelBusiness" style="display: none;">
        <div class="business-reports" id="businessReports">
          <div class="empty-state">
            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>
            <h3>Business Reports</h3>
            <p>Create a business mission and run analysis to see reports here</p>
          </div>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    // Tabs
    this.container.querySelectorAll('.cognition-tab').forEach(tab => {
      tab.addEventListener('click', () => this.setTab(tab.dataset.tab));
    });
    
    // Controls
    this.container.querySelector('#triggerCycle').addEventListener('click', () => this.triggerCycle());
    this.container.querySelector('#pauseCognition').addEventListener('click', () => this.pauseCognition());
    this.container.querySelector('#resumeCognition').addEventListener('click', () => this.resumeCognition());
    
    // Mission actions
    this.container.querySelector('#newMissionBtn').addEventListener('click', () => this.openMissionModal());
    this.container.querySelector('#newObjectiveBtn').addEventListener('click', () => this.openObjectiveModal());
  }
  
  setTab(tab) {
    this.currentTab = tab;
    this.container.querySelectorAll('.cognition-tab').forEach(t => {
      t.classList.toggle('active', t.dataset.tab === tab);
    });
    this.container.querySelectorAll('.cognition-tab-panel').forEach(p => {
      p.style.display = p.id === `panel${tab.charAt(0).toUpperCase() + tab.slice(1)}` ? 'block' : 'none';
    });
  }
  
  async loadData() {
    await Promise.all([
      this.loadStatus(),
      this.loadMissions(),
      this.loadObjectives(),
      this.loadAudit()
    ]);
  }
  
  async loadStatus() {
    try {
      const status = await this.app.api.getCognitionStatus();
      this.cognitionStatus = status;
      this.renderStatus(status);
    } catch (error) {
      console.error('Failed to load cognition status:', error);
    }
  }
  
  renderStatus(status) {
    this.container.querySelector('#statusEnabled').textContent = status.enabled ? 'Enabled' : 'Disabled';
    this.container.querySelector('#statusEnabled').style.color = status.enabled ? 'var(--success)' : 'var(--text-tertiary)';
    this.container.querySelector('#statusAutorun').textContent = status.autorun ? 'On' : 'Off';
    this.container.querySelector('#statusMissions').textContent = status.missions_active;
    this.container.querySelector('#statusPending').textContent = status.objectives_pending;
    
    // Update control buttons
    const pauseBtn = this.container.querySelector('#pauseCognition');
    const resumeBtn = this.container.querySelector('#resumeCognition');
    if (status.enabled) {
      pauseBtn.style.display = 'inline-flex';
      resumeBtn.style.display = 'none';
    } else {
      pauseBtn.style.display = 'none';
      resumeBtn.style.display = 'inline-flex';
    }
  }
  
  async loadMissions() {
    try {
      const response = await this.app.api.getMissions();
      this.missions = response.missions || [];
      this.renderMissions();
    } catch (error) {
      this.renderMissionsError(error.message);
    }
  }
  
  renderMissions() {
    const el = this.container.querySelector('#missionsList');
    
    if (this.missions.length === 0) {
      el.innerHTML = `
        <div class="empty-state">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>
          <h3>No missions yet</h3>
          <p>Create a mission to give Maya a persistent goal</p>
        </div>
      `;
      return;
    }
    
    el.innerHTML = this.missions.map(mission => `
      <div class="mission-card">
        <div class="mission-card-header">
          <div class="mission-info">
            <div class="mission-name-row">
              <span class="mission-name">${this.escapeHtml(mission.name)}</span>
              <span class="mission-type-badge mission-type-${mission.mission_type}">${mission.mission_type}</span>
            </div>
            ${mission.self_gen ? '<span class="mission-self-gen active">🔄 Auto-generates objectives</span>' : ''}
            ${mission.description ? `<div class="mission-description">${this.escapeHtml(mission.description)}</div>` : ''}
            <div class="mission-meta">
              <span>ID: ${mission.id}</span>
              <span>${mission.active ? '🟢 Active' : '🔴 Inactive'}</span>
            </div>
          </div>
          <div class="mission-actions">
            <button class="mission-action-btn" data-action="generate" data-id="${mission.id}" title="Generate objectives">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>
            </button>
            <button class="mission-action-btn" data-action="toggle" data-id="${mission.id}" title="${mission.active ? 'Deactivate' : 'Activate'}">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><path d="M12 6v6l4 2"></path></svg>
            </button>
            <button class="mission-action-btn" data-action="delete" data-id="${mission.id}" title="Delete">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
            </button>
          </div>
        </div>
        <div class="mission-objectives" id="objectives-${mission.id}"></div>
        <div class="mission-footer">
          <button class="btn btn-secondary btn-sm mission-footer-btn" data-action="objectives" data-id="${mission.id}">View Objectives</button>
          <button class="btn btn-primary btn-sm mission-footer-btn" data-action="generate" data-id="${mission.id}">Generate</button>
        </div>
      </div>
    `).join('');
    
    // Bind events
    el.querySelectorAll('.mission-action-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const action = btn.dataset.action;
        const id = btn.dataset.id;
        if (action === 'generate') this.generateObjectives(id);
        else if (action === 'toggle') this.toggleMission(id);
        else if (action === 'delete') this.deleteMission(id);
        else if (action === 'objectives') this.showMissionObjectives(id);
      });
    });
    
    el.querySelectorAll('.mission-footer-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const action = btn.dataset.action;
        const id = btn.dataset.id;
        if (action === 'generate') this.generateObjectives(id);
        else if (action === 'objectives') this.showMissionObjectives(id);
      });
    });
  }
  
  renderMissionsError(message) {
    this.container.querySelector('#missionsList').innerHTML = `
      <div class="error-state">
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
        <h3>Failed to load missions</h3>
        <p>${this.escapeHtml(message)}</p>
      </div>
    `;
  }
  
  async loadObjectives() {
    try {
      const response = await this.app.api.getObjectives();
      this.objectives = response.objectives || [];
      this.renderObjectives();
    } catch (error) {
      this.container.querySelector('#objectivesTable').innerHTML = `
        <div class="error-state">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
          <h3>Failed to load objectives</h3>
          <p>${this.escapeHtml(error.message)}</p>
        </div>
      `;
    }
  }
  
  renderObjectives() {
    const el = this.container.querySelector('#objectivesTable');
    
    if (this.objectives.length === 0) {
      el.innerHTML = `
        <div class="empty-state">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7"></path></svg>
          <h3>No objectives yet</h3>
          <p>Objectives will appear here when missions generate them</p>
        </div>
      `;
      return;
    }
    
    el.innerHTML = `
      <table class="table">
        <thead>
          <tr>
            <th>Description</th>
            <th>Mission</th>
            <th>Priority</th>
            <th>Status</th>
            <th>Approval</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${this.objectives.map(obj => `
            <tr>
              <td>${this.escapeHtml(this.truncate(obj.description, 80))}</td>
              <td>${obj.mission_id}</td>
              <td>${obj.priority?.toFixed(1) || 0}</td>
              <td><span class="badge badge-${this.getStatusBadge(obj.status)}">${obj.status}</span></td>
              <td>${obj.requires_approval ? '<span class="badge badge-warning">Required</span>' : '<span class="badge badge-success">Not needed</span>'}</td>
              <td>
                <div class="cell-actions">
                  ${obj.status === 'proposed' ? `<button class="btn btn-primary btn-sm" data-action="execute" data-id="${obj.id}">Execute</button>` : ''}
                  <button class="btn btn-secondary btn-sm" data-action="view" data-id="${obj.id}">View</button>
                </div>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
    
    // Bind events
    el.querySelectorAll('[data-action="execute"]').forEach(btn => {
      btn.addEventListener('click', () => this.executeObjective(btn.dataset.id));
    });
    el.querySelectorAll('[data-action="view"]').forEach(btn => {
      btn.addEventListener('click', () => this.openObjectiveDetail(btn.dataset.id));
    });
  }
  
  async loadAudit() {
    try {
      const response = await this.app.api.getCognitionStatus();
      this.renderAudit(response.recent_audit || []);
    } catch (error) {
      this.container.querySelector('#auditList').innerHTML = `
        <div class="error-state">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
          <h3>Failed to load audit log</h3>
          <p>${this.escapeHtml(error.message)}</p>
        </div>
      `;
    }
  }
  
  renderAudit(audit) {
    const el = this.container.querySelector('#auditList');
    
    if (!audit.length) {
      el.innerHTML = `
        <div class="empty-state">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
          <h3>No audit entries</h3>
          <p>Audit entries will appear here as cognition cycles run</p>
        </div>
      `;
      return;
    }
    
    el.innerHTML = audit.map(entry => `
      <div class="audit-entry" style="padding: var(--space-3); border-bottom: 1px solid var(--border);">
        <div style="display: flex; justify-content: space-between; margin-bottom: var(--space-1);">
          <span class="badge badge-${this.getAuditActionBadge(entry.action)}">${entry.action}</span>
          <span style="color: var(--text-tertiary); font-size: var(--text-xs);">${new Date(entry.timestamp * 1000).toLocaleString()}</span>
        </div>
        <div style="font-weight: 500; color: var(--text-primary);">${this.escapeHtml(entry.objective_desc || 'N/A')}</div>
        <div style="color: var(--text-secondary); font-size: var(--text-sm); margin-top: var(--space-1);">${this.escapeHtml(entry.detail)}</div>
      </div>
    `).join('');
  }
  
  async triggerCycle() {
    try {
      const result = await this.app.api.triggerCognitionCycle();
      this.app.toast.success('Cycle triggered', result.detail || 'Cognition cycle completed');
      this.loadData();
    } catch (error) {
      this.app.toast.error('Cycle failed', error.message);
    }
  }
  
  async pauseCognition() {
    try {
      await this.app.api.pauseCognition();
      this.app.toast.success('Cognition paused');
      this.loadStatus();
    } catch (error) {
      this.app.toast.error('Failed to pause', error.message);
    }
  }
  
  async resumeCognition() {
    try {
      await this.app.api.resumeCognition();
      this.app.toast.success('Cognition resumed');
      this.loadStatus();
    } catch (error) {
      this.app.toast.error('Failed to resume', error.message);
    }
  }
  
  async openMissionModal(mission = null) {
    // Implementation
  }
  
  async openObjectiveModal() {
    // Implementation
  }
  
  async generateObjectives(missionId) {
    try {
      const result = await this.app.api.generateObjectives(missionId);
      this.app.toast.success(`Generated ${result.count} objectives`);
      this.loadMissions();
      this.loadObjectives();
    } catch (error) {
      this.app.toast.error('Failed to generate objectives', error.message);
    }
  }
  
  async toggleMission(missionId) {
    const mission = this.missions.find(m => m.id === missionId);
    if (!mission) return;
    
    try {
      await this.app.api.updateMission(missionId, { active: !mission.active });
      this.app.toast.success(`Mission ${mission.active ? 'deactivated' : 'activated'}`);
      this.loadMissions();
    } catch (error) {
      this.app.toast.error('Failed to toggle mission', error.message);
    }
  }
  
  async deleteMission(missionId) {
    const confirmed = await this.app.confirmDelete('mission');
    if (!confirmed) return;
    
    try {
      await this.app.api.deleteMission(missionId);
      this.app.toast.success('Mission deleted');
      this.loadMissions();
    } catch (error) {
      this.app.toast.error('Failed to delete mission', error.message);
    }
  }
  
  showMissionObjectives(missionId) {
    this.setTab('objectives');
    // Filter objectives table by mission
  }
  
  async executeObjective(objectiveId) {
    try {
      const result = await this.app.api.executeObjective(objectiveId);
      this.app.toast.success('Objective executed', result.status);
      this.loadObjectives();
      this.loadAudit();
    } catch (error) {
      this.app.toast.error('Execution failed', error.message);
    }
  }
  
  openObjectiveDetail(objectiveId) {
    // Open detail modal
  }
  
  getStatusBadge(status) {
    const badges = {
      'pending': 'warning',
      'proposed': 'info',
      'in_progress': 'warning',
      'done': 'success',
      'failed': 'error',
      'blocked': 'neutral'
    };
    return badges[status] || 'neutral';
  }
  
  getAuditActionBadge(action) {
    const badges = {
      'proposed': 'info',
      'run': 'warning',
      'done': 'success',
      'failed': 'error',
      'blocked': 'neutral',
      'skipped': 'neutral'
    };
    return badges[action] || 'neutral';
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
  
  destroy() {}
}