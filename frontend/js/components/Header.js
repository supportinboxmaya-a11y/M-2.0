// Maya 2.0 ULTRA - Header Component
import { auth } from '../auth.js';

export class Header {
  constructor(container) {
    this.container = container;
    this.notifications = [];
    this.unreadCount = 0;
    this.notificationsDropdownOpen = false;
    this.userMenuOpen = false;
    this.unsubscribeAuth = null;
    this.unsubscribeWS = null;
    this.render();
    this.bindEvents();
    this.setupListeners();
  }
  
  setupListeners() {
    this.unsubscribeAuth = auth.subscribe((event) => {
      if (event === 'login' || event === 'userUpdated') {
        this.render();
      } else if (event === 'logout') {
        this.render();
      }
    });
    
    // Listen for WebSocket approval events
    this.unsubscribeWS = window.ws?.on?.('approval_requested', (approval) => {
      this.addNotification({
        id: approval.id,
        title: 'Approval Required',
        body: approval.action,
        level: 'warning',
        meta: { approvalId: approval.id }
      });
    });
  }
  
  render() {
    const user = auth.getUser();
    const isDark = document.documentElement.dataset.theme === 'dark' || 
      (!document.documentElement.dataset.theme && window.matchMedia('(prefers-color-scheme: dark)').matches);
    
    this.container.innerHTML = `
      <div class="header-left">
        <button id="mobileMenuBtn" class="mobile-menu-btn" aria-label="Open menu" aria-expanded="false">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
        </button>
        <h1 id="viewTitle" class="view-title">Chat</h1>
      </div>
      <div class="header-right">
        <div class="header-status" id="headerStatus">
          <span class="status-pill" id="cognitionStatus" title="Cognition loop">◐</span>
          <span class="status-pill" id="approvalStatus" title="Pending approvals" style="display:none">⚠</span>
        </div>
        <button id="notificationsBtn" class="icon-btn header-icon-btn" aria-label="Notifications" aria-expanded="false">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path><path d="M13.73 21a2 2 0 0 1-3.46 0"></path></svg>
          <span class="badge" id="notificationBadge" style="display:${this.unreadCount > 0 ? 'flex' : 'none'}">${this.unreadCount}</span>
        </button>
        <button id="themeToggle" class="icon-btn header-icon-btn" aria-label="Toggle theme">
          <svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>
          <svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
        </button>
        <div class="user-menu" id="userMenu">
          <button id="userMenuBtn" class="user-menu-btn" aria-label="User menu" aria-expanded="false" aria-haspopup="true">
            <div class="user-avatar" id="userAvatar">${user?.email?.charAt(0).toUpperCase() || 'M'}</div>
            <span class="user-name" id="userName">${user?.email?.split('@')[0] || 'Admin'}</span>
            <svg class="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"></polyline></svg>
          </button>
          <div class="user-dropdown" id="userDropdown" role="menu" aria-orientation="vertical" style="display:none">
            <div class="dropdown-header">
              <span id="dropdownEmail">${user?.email || 'admin@maya.ai'}</span>
              <span id="dropdownRole" class="role-badge">${auth.isAdmin() ? 'Admin' : 'User'}</span>
            </div>
            <a href="#settings" class="dropdown-item" role="menuitem" data-view="settings">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>
              Settings
            </a>
            <a href="#approvals" class="dropdown-item" role="menuitem" data-view="approvals">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
              Approvals
            </a>
            <hr class="dropdown-divider">
            <button id="logoutBtn" class="dropdown-item dropdown-danger" role="menuitem">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
              Logout
            </button>
          </div>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    // Mobile menu toggle
    const mobileMenuBtn = this.container.querySelector('#mobileMenuBtn');
    if (mobileMenuBtn) {
      mobileMenuBtn.addEventListener('click', () => {
        const expanded = mobileMenuBtn.getAttribute('aria-expanded') === 'true';
        mobileMenuBtn.setAttribute('aria-expanded', (!expanded).toString());
        window.dispatchEvent(new CustomEvent('sidebar:toggle'));
      });
    }
    
    // Theme toggle
    const themeToggle = this.container.querySelector('#themeToggle');
    if (themeToggle) {
      themeToggle.addEventListener('click', () => this.toggleTheme());
    }
    
    // Notifications
    const notificationsBtn = this.container.querySelector('#notificationsBtn');
    if (notificationsBtn) {
      notificationsBtn.addEventListener('click', () => this.toggleNotifications());
    }
    
    // User menu
    const userMenuBtn = this.container.querySelector('#userMenuBtn');
    const userDropdown = this.container.querySelector('#userDropdown');
    
    if (userMenuBtn) {
      userMenuBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.toggleUserMenu();
      });
    }
    
    // Close dropdowns on outside click
    document.addEventListener('click', (e) => {
      if (this.notificationsDropdownOpen && !e.target.closest('#notificationsBtn') && !e.target.closest('.notifications-dropdown')) {
        this.closeNotifications();
      }
      if (this.userMenuOpen && !e.target.closest('.user-menu')) {
        this.closeUserMenu();
      }
    });
    
    // Logout
    const logoutBtn = this.container.querySelector('#logoutBtn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => auth.logout());
    }
    
    // Dropdown navigation
    this.container.querySelectorAll('[data-view]').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        window.location.hash = link.getAttribute('href');
        this.closeUserMenu();
        this.closeNotifications();
      });
    });
    
    // Initialize theme
    this.applyTheme();
  }
  
  toggleTheme() {
    const currentTheme = document.documentElement.dataset.theme;
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    document.documentElement.dataset.theme = newTheme;
    localStorage.setItem('theme', newTheme);
    this.applyTheme();
  }
  
  applyTheme() {
    const theme = document.documentElement.dataset.theme || 
      (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    document.documentElement.dataset.theme = theme;
  }
  
  toggleNotifications() {
    this.notificationsDropdownOpen = !this.notificationsDropdownOpen;
    this.renderNotificationsDropdown();
  }
  
  closeNotifications() {
    this.notificationsDropdownOpen = false;
    // Would render dropdown here if implemented
  }
  
  toggleUserMenu() {
    this.userMenuOpen = !this.userMenuOpen;
    const btn = this.container.querySelector('#userMenuBtn');
    const dropdown = this.container.querySelector('#userDropdown');
    
    if (btn && dropdown) {
      btn.setAttribute('aria-expanded', this.userMenuOpen.toString());
      dropdown.style.display = this.userMenuOpen ? 'block' : 'none';
    }
  }
  
  closeUserMenu() {
    this.userMenuOpen = false;
    const btn = this.container.querySelector('#userMenuBtn');
    const dropdown = this.container.querySelector('#userDropdown');
    
    if (btn && dropdown) {
      btn.setAttribute('aria-expanded', 'false');
      dropdown.style.display = 'none';
    }
  }
  
  addNotification(notification) {
    this.notifications.unshift({
      ...notification,
      id: notification.id || crypto.randomUUID(),
      timestamp: Date.now(),
      read: false
    });
    
    this.unreadCount = this.notifications.filter(n => !n.read).length;
    this.updateNotificationBadge();
    
    // Show toast for important notifications
    if (notification.level === 'warning' || notification.level === 'critical') {
      window.toast?.warning(notification.title, notification.body);
    }
  }
  
  updateNotificationBadge() {
    const badge = this.container.querySelector('#notificationBadge');
    if (badge) {
      badge.textContent = this.unreadCount > 9 ? '9+' : this.unreadCount;
      badge.style.display = this.unreadCount > 0 ? 'flex' : 'none';
    }
  }
  
  renderNotificationsDropdown() {
    // Would implement dropdown rendering here
  }
  
  setViewTitle(title) {
    const titleEl = this.container.querySelector('#viewTitle');
    if (titleEl) {
      titleEl.textContent = title;
    }
  }
  
  updateCognitionStatus(enabled, autorun) {
    const statusEl = this.container.querySelector('#cognitionStatus');
    if (statusEl) {
      if (enabled) {
        statusEl.textContent = autorun ? '▶' : '⏸';
        statusEl.classList.add('active');
        statusEl.title = autorun ? 'Cognition running' : 'Cognition paused';
      } else {
        statusEl.textContent = '⏹';
        statusEl.classList.remove('active');
        statusEl.title = 'Cognition disabled';
      }
    }
  }
  
  updateApprovalStatus(count) {
    const statusEl = this.container.querySelector('#approvalStatus');
    if (statusEl) {
      statusEl.style.display = count > 0 ? 'flex' : 'none';
      if (count > 0) {
        statusEl.textContent = count > 9 ? '9+' : count;
      }
    }
  }
  
  destroy() {
    if (this.unsubscribeAuth) this.unsubscribeAuth();
    if (this.unsubscribeWS) this.unsubscribeWS();
  }
}