// Maya 2.0 ULTRA - Sidebar Component
import { auth } from '../auth.js';

const NAV_GROUPS = [
  { label: null, items: [
    { id: 'chat', label: 'Chat', icon: 'chat', href: '#chat' },
    { id: 'goals', label: 'Goals', icon: 'target', href: '#goals' },
    { id: 'tasks', label: 'Tasks', icon: 'check-square', href: '#tasks' },
  ]},
  { label: 'Mind', items: [
    { id: 'kernel', label: 'Cognitive Kernel', icon: 'brain', href: '#kernel' },
    { id: 'cognition', label: 'Cognition Loop', icon: 'activity', href: '#cognition' },
    { id: 'coreloop', label: 'Core Loop', icon: 'cpu', href: '#coreloop' },
    { id: 'metacognition', label: 'Metacognition', icon: 'compass', href: '#metacognition' },
    { id: 'selfmodel', label: 'Self-Model', icon: 'eye', href: '#selfmodel' },
    { id: 'skills', label: 'Skills', icon: 'zap', href: '#skills' },
    { id: 'society', label: 'Agent Society', icon: 'users', href: '#society' },
    { id: 'capabilities', label: 'Capabilities', icon: 'layers', href: '#capabilities' },
    { id: 'mcp', label: 'MCP Servers', icon: 'plug', href: '#mcp' },
  ]},
  { label: 'Memory & Knowledge', items: [
    { id: 'memory', label: 'Memory', icon: 'database', href: '#memory' },
    { id: 'rag', label: 'RAG / KB', icon: 'book-open', href: '#rag' },
    { id: 'learning', label: 'Learning', icon: 'lightbulb', href: '#learning' },
  ]},
  { label: 'Capabilities', items: [
    { id: 'tools', label: 'Tools', icon: 'tool', href: '#tools' },
    { id: 'agents', label: 'Agents', icon: 'user-check', href: '#agents' },
    { id: 'workflows', label: 'Workflows', icon: 'git-branch', href: '#workflows' },
    { id: 'prompts', label: 'Prompts', icon: 'file-text', href: '#prompts' },
    { id: 'hosting', label: 'Hosting', icon: 'server', href: '#hosting' },
    { id: 'research', label: 'Research & Publish', icon: 'file-text', href: '#research' },
  ]},
  { label: 'Safety & Ops', items: [
    { id: 'approvals', label: 'Approvals', icon: 'alert-triangle', href: '#approvals' },
    { id: 'security', label: 'Security', icon: 'lock', href: '#security' },
    { id: 'analytics', label: 'Analytics', icon: 'bar-chart', href: '#analytics' },
    { id: 'logs', label: 'Logs', icon: 'list', href: '#logs' },
  ]},
  { label: 'System', items: [
    { id: 'workspace', label: 'Workspace', icon: 'folder', href: '#workspace' },
    { id: 'backups', label: 'Backups', icon: 'archive', href: '#backups' },
    { id: 'devices', label: 'Devices', icon: 'smartphone', href: '#devices' },
    { id: 'instances', label: 'Instances', icon: 'user-plus', href: '#instances' },
    { id: 'webhooks', label: 'Webhooks', icon: 'webhook', href: '#webhooks' },
    { id: 'translate', label: 'Translate', icon: 'globe', href: '#translate' },
    { id: 'docs', label: 'Docs', icon: 'book', href: '#docs' },
    { id: 'settings', label: 'Settings', icon: 'settings', href: '#settings' },
    { id: 'admin', label: 'Admin', icon: 'shield', href: '#admin', admin: true },
  ]},
];

const ICONS = {
  chat: '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>',
  database: '<path d="M6 2v14a2 2 0 0 0 2 2h12"></path><path d="M6 2h12"></path><path d="M16 2v14"></path>',
  tool: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path>',
  'check-square': '<path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7"></path>',
  'book-open': '<path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path>',
  'git-branch': '<path d="M6 3v12"></path><path d="M18 9v6"></path><path d="M6 3a6 6 0 0 1 12 0v12"></path><path d="M18 9a6 6 0 0 1 0 12"></path>',
  server: '<rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect><rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect><line x1="6" y1="6" x2="6.01" y2="6"></line><line x1="6" y1="18" x2="6.01" y2="18"></line>',
  brain: '<path d="M12 5a3 3 0 1 0-3 3c0 1.5 1.5 3 3 3s3-1.5 3-3a3 3 0 0 0-3-3z"></path><path d="M12 3v2"></path><path d="M12 19v2"></path><path d="M4.93 4.93l1.41 1.41"></path><path d="M17.66 17.66l1.41 1.41"></path><path d="M2 12h2"></path><path d="M20 12h2"></path><path d="M4.93 19.07l1.41-1.41"></path><path d="M17.66 6.34l1.41-1.41"></path>',
  settings: '<circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>',
  lightbulb: '<path d="M18 11c0 4.51-6 7.49-6 11.51 0 2.24 1.76 4 4 4s4-1.76 4-4C24 18.49 18 15.51 18 11c0-5.5 4.5-10 10-10s10 4.5 10 10z"></path><line x1="12" y1="2" x2="12" y2="5.5"></line>',
  'file-text': '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline>',
  webhook: '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path><polyline points="15 3 21 3 21 9"></path><line x1="10" y1="14" x2="21" y2="3"></line>',
  globe: '<circle cx="12" cy="12" r="10"></circle><line x1="2" y1="12" x2="22" y2="12"></line><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>',
  'bar-chart': '<line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line>',
  users: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path>',
  'user-check': '<path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="8.5" cy="7" r="4"></circle><polyline points="17 11 19 13 23 9"></polyline>',
  target: '<circle cx="12" cy="12" r="10"></circle><circle cx="12" cy="12" r="6"></circle><circle cx="12" cy="12" r="2"></circle>',
  activity: '<polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>',
  cpu: '<rect x="4" y="4" width="16" height="16" rx="2" ry="2"></rect><rect x="9" y="9" width="6" height="6"></rect><line x1="9" y1="1" x2="9" y2="4"></line><line x1="15" y1="1" x2="15" y2="4"></line><line x1="9" y1="20" x2="9" y2="23"></line><line x1="15" y1="20" x2="15" y2="23"></line><line x1="20" y1="9" x2="23" y2="9"></line><line x1="20" y1="14" x2="23" y2="14"></line><line x1="1" y1="9" x2="4" y2="9"></line><line x1="1" y1="14" x2="4" y2="14"></line>',
  compass: '<circle cx="12" cy="12" r="10"></circle><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"></polygon>',
  eye: '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle>',
  zap: '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>',
  layers: '<polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline>',
  plug: '<path d="M12 22v-5"></path><path d="M9 8V2"></path><path d="M15 8V2"></path><path d="M18 8v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4V8z"></path>',
  list: '<line x1="8" y1="6" x2="21" y2="6"></line><line x1="8" y1="12" x2="21" y2="12"></line><line x1="8" y1="18" x2="21" y2="18"></line><line x1="3" y1="6" x2="3.01" y2="6"></line><line x1="3" y1="12" x2="3.01" y2="12"></line><line x1="3" y1="18" x2="3.01" y2="18"></line>',
  'user-plus': '<path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="8.5" cy="7" r="4"></circle><line x1="20" y1="8" x2="20" y2="14"></line><line x1="23" y1="11" x2="17" y2="11"></line>',
  smartphone: '<rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line>',
  folder: '<path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>',
  archive: '<polyline points="21 8 21 21 3 21 3 8"></polyline><rect x="1" y="3" width="22" height="5"></rect><line x1="10" y1="12" x2="14" y2="12"></line>',
  lock: '<rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path>',
  'alert-triangle': '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line>'
};

export class Sidebar {
  constructor(container) {
    this.container = container;
    this.collapsed = false;
    this.mobileOpen = false;
    this.currentView = 'chat';
    this.unsubscribeAuth = null;
    this.render();
    this.bindEvents();
    this.setupAuthListener();
  }
  
  setupAuthListener() {
    this.unsubscribeAuth = auth.subscribe(() => {
      this.render();
    });
  }
  
  render() {
    const isAdmin = auth.isAdmin();
    const groupHtml = NAV_GROUPS.map(group => {
      const items = group.items.filter(item => !item.admin || isAdmin);
      if (!items.length) return '';
      return `${group.label ? `<div class="nav-group-label">${group.label}</div>` : ''}` +
        items.map(item => `
        <a href="${item.href}" class="nav-item" data-view="${item.id}" data-active="${item.id === this.currentView ? 'true' : 'false'}">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${ICONS[item.icon] || ICONS.tool}</svg>
          <span class="label">${item.label}</span>
        </a>`).join('');
    }).join('');
    
    const user = auth.getUser();
    const userName = user?.email?.split('@')[0] || 'User';
    const userInitial = userName.charAt(0).toUpperCase();
    
    this.container.innerHTML = `
      <div class="sidebar-header">
        <a href="#chat" class="sidebar-brand" aria-label="Maya Home">
          <svg class="brand-icon" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
            <circle cx="16" cy="16" r="14" stroke="currentColor" stroke-width="2"/>
            <path d="M16 8c-4.4 0-8 3.6-8 8s3.6 8 8 8 8-3.6 8-8-3.6-8-8-8zm0 14c-3.3 0-6-2.7-6-6s2.7-6 6-6 6 2.7 6 6-2.7 6-6 6z" fill="currentColor"/>
          </svg>
          <span class="brand-text">Maya 2.0</span>
        </a>
        <button id="sidebarToggle" class="sidebar-toggle" aria-label="Collapse sidebar" aria-expanded="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"></polyline></svg>
        </button>
      </div>
      <nav class="sidebar-nav">
        ${groupHtml}
      </nav>
      <div class="sidebar-footer">
        <div class="sidebar-user">
          <div class="user-avatar">${userInitial}</div>
          <div class="user-info">
            <span class="user-name">${userName}</span>
            <span class="user-role">${auth.isAdmin() ? 'Admin' : 'User'}</span>
          </div>
        </div>
      </div>
    `;
    this.bindEvents();
  }

  bindEvents() {
    // Toggle collapse
    const toggleBtn = this.container.querySelector('#sidebarToggle');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => this.toggleCollapse());
    }

    // Navigation clicks
    this.container.querySelectorAll('.nav-item').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const view = link.dataset.view;
        this.setActiveView(view);
        window.location.hash = link.getAttribute('href');

        // Close mobile sidebar on navigation
        if (window.innerWidth <= 768) {
          this.closeMobile();
        }
      });
    });

    // Global listeners must be registered exactly once, not per re-render.
    if (!this._globalBound) {
      this._globalBound = true;
      window.addEventListener('sidebar:toggle', () => this.toggleMobile());
    }
  }
  
  toggleCollapse() {
    this.collapsed = !this.collapsed;
    this.container.classList.toggle('collapsed', this.collapsed);
    
    const toggleBtn = this.container.querySelector('#sidebarToggle');
    if (toggleBtn) {
      toggleBtn.setAttribute('aria-expanded', (!this.collapsed).toString());
    }
    
    localStorage.setItem('sidebar_collapsed', this.collapsed.toString());
  }
  
  toggleMobile() {
    this.mobileOpen = !this.mobileOpen;
    this.container.classList.toggle('mobile-open', this.mobileOpen);
    
    const overlay = document.getElementById('sidebarOverlay');
    if (overlay) {
      overlay.classList.toggle('visible', this.mobileOpen);
    }
  }
  
  closeMobile() {
    if (this.mobileOpen) {
      this.mobileOpen = false;
      this.container.classList.remove('mobile-open');
      
      const overlay = document.getElementById('sidebarOverlay');
      if (overlay) {
        overlay.classList.remove('visible');
      }
    }
  }
  
  setActiveView(view) {
    this.currentView = view;
    this.container.querySelectorAll('.nav-item').forEach(link => {
      link.dataset.active = link.dataset.view === view ? 'true' : 'false';
    });
  }
  
  destroy() {
    if (this.unsubscribeAuth) {
      this.unsubscribeAuth();
    }
  }
}