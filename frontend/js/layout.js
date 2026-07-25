/**
 * Maya 2.0 — Layout Manager
 *
 * Sidebar, bottom bar, top bar, right panel, modal, toast, drawer, sheet.
 */
(function () {
  'use strict';

  const $ = (sel, ctx) => (ctx || document).querySelector(sel);
  const $$ = (sel, ctx) => Array.from((ctx || document).querySelectorAll(sel));

  const Layout = {};
  window.MayaLayout = Layout;

  /* ── Config ── */
  const SIDEBAR_ITEMS = [
    { id: 'chat',       icon: '💬', label: 'Chat' },
    { id: 'research',   icon: '🔬', label: 'Research' },
    { id: 'business',   icon: '💼', label: 'Business' },
    { id: 'coding',     icon: '💻', label: 'Coding' },
    { id: 'documents',  icon: '📄', label: 'Documents' },
    { id: 'files',      icon: '📁', label: 'Files' },
    { id: 'automation', icon: '⚡', label: 'Automation' },
    { id: 'agents',     icon: '🤖', label: 'Agents' },
    { id: 'analytics',  icon: '📊', label: 'Analytics' },
  ];

  const ADMIN_ITEMS = [
    { id: 'admin', icon: '⚙️', label: 'Admin' },
  ];

  const BOTTOM_PRIMARY = [
    { id: 'chat',       icon: '💬', label: 'Chat' },
    { id: 'research',   icon: '🔬', label: 'Research' },
    { id: 'business',   icon: '💼', label: 'Biz' },
    { id: 'coding',     icon: '💻', label: 'Code' },
    { id: 'documents',  icon: '📄', label: 'Docs' },
  ];
  const BOTTOM_SECONDARY = [
    { id: 'files',      icon: '📁', label: 'Files' },
    { id: 'automation', icon: '⚡', label: 'Auto' },
    { id: 'agents',     icon: '🤖', label: 'Agents' },
    { id: 'analytics',  icon: '📊', label: 'Analytics' },
    { id: 'admin',      icon: '⚙️', label: 'Admin' },
  ];

  /* ── Init ── */

  Layout.init = function (activeRoute) {
    buildSidebar(activeRoute);
    buildBottombar(activeRoute);
    bindGlobalUI();
  };

  /* ── Sidebar ── */

  function buildSidebar(activeId) {
    const primary = document.getElementById('primaryNav');
    primary.innerHTML = SIDEBAR_ITEMS.map(item =>
      `<button class="sidebar-item${item.id === activeId ? ' active' : ''}" data-route="${item.id}">
        <span class="sidebar-item-icon">${item.icon}</span>
        <span>${item.label}</span>
      </button>`
    ).join('') + `<div class="sidebar-separator"></div>`;

    // "More" section: show admin at bottom
    const tertiary = document.getElementById('tertiaryNav');
    tertiary.innerHTML = ADMIN_ITEMS.map(item =>
      `<button class="sidebar-item${item.id === activeId ? ' active' : ''}" data-route="${item.id}">
        <span class="sidebar-item-icon">${item.icon}</span>
        <span>${item.label}</span>
      </button>`
    ).join('');
  }

  /* ── Bottom Bar ── */

  function buildBottombar(activeId) {
    const bar = document.getElementById('bottombar');
    let html = '<div class="bottombar-scroll">';
    html += BOTTOM_PRIMARY.map(item =>
      `<button class="bottombar-item${item.id === activeId ? ' active' : ''}" data-route="${item.id}">
        <span class="icon">${item.icon}</span>
        <span>${item.label}</span>
      </button>`
    ).join('');
    html += `<button class="bottombar-item" id="moreNavBtn" data-route="more">
      <span class="icon">⋯</span>
      <span>More</span>
    </button>`;
    html += '</div>';
    bar.innerHTML = html;
  }

  /* ── Open secondary nav bottom sheet ── */

  function openMoreNav() {
    const html = `<div class="right-panel-handle"></div>
      <div style="padding:var(--space-3)">
        <div style="font-size:var(--font-size-sm);font-weight:var(--font-weight-semibold);margin-bottom:var(--space-2);color:var(--text-secondary)">More</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--space-2)">${BOTTOM_SECONDARY.map(item =>
          `<button class="quick-btn" data-route="${item.id}" onclick="MayaLayout.closeSheet();window.MayaRouter.navigate('${item.id}')">
            <span class="icon">${item.icon}</span>
            <span class="label">${item.label}</span>
          </button>`
        ).join('')}</div>
      </div>`;
    Layout.openSheet(html);
  }

  /* ── Navigation highlight update ── */

  Layout.setActive = function (routeId) {
    $$('.sidebar-item').forEach(el => {
      el.classList.toggle('active', el.dataset.route === routeId);
    });
    $$('.bottombar-item').forEach(el => {
      el.classList.toggle('active', el.dataset.route === routeId);
    });
  };

  /* ── Sidebar collapse toggle ── */

  Layout.toggleSidebar = function () {
    const sidebar = document.getElementById('sidebar');
    const isMobile = window.innerWidth < 768;
    if (isMobile) {
      sidebar.classList.toggle('open');
    } else {
      sidebar.classList.toggle('collapsed');
    }
  };

  Layout.closeSidebar = function () {
    const sidebar = document.getElementById('sidebar');
    sidebar.classList.remove('open');
  };

  /* ── Right panel ── */

  Layout.openRightPanel = function (html) {
    const panel = document.getElementById('rightPanel');
    const content = document.getElementById('rightPanelContent');
    content.innerHTML = html;
    panel.classList.add('open');
    // On mobile, add active class after a tick for slide-up animation
    if (window.innerWidth < 768) {
      setTimeout(function () { panel.classList.add('active'); }, 10);
    }
  };

  Layout.closeRightPanel = function () {
    const panel = document.getElementById('rightPanel');
    panel.classList.remove('active');
    panel.classList.remove('open');
  };

  Layout.setRightPanel = function (html) {
    document.getElementById('rightPanelContent').innerHTML = html;
  };

  /* ── Modal ── */

  Layout.openModal = function (html) {
    document.getElementById('modalContent').innerHTML = html;
    document.getElementById('modalOverlay').classList.add('active');
  };

  Layout.closeModal = function () {
    document.getElementById('modalOverlay').classList.remove('active');
  };

  /* ── Toast ── */

  Layout.toast = function (msg, type, duration) {
    type = type || 'info';
    duration = duration || 4000;
    const el = document.createElement('div');
    el.className = 'toast toast-' + type;
    el.textContent = msg;
    document.getElementById('toasts').appendChild(el);
    setTimeout(() => {
      el.style.opacity = '0';
      setTimeout(() => el.remove(), 300);
    }, duration);
  };

  /* ── Drawer (mobile) ── */

  Layout.openDrawer = function (html) {
    document.getElementById('drawerContent').innerHTML = html;
    document.getElementById('drawerOverlay').classList.add('active');
    document.getElementById('drawer').classList.add('open');
  };

  Layout.closeDrawer = function () {
    document.getElementById('drawerOverlay').classList.remove('active');
    document.getElementById('drawer').classList.remove('open');
  };

  /* ── Bottom sheet (mobile) ── */

  Layout.openSheet = function (html) {
    document.getElementById('sheetContent').innerHTML = html;
    document.getElementById('sheetOverlay').classList.add('active');
    document.getElementById('sheet').classList.add('open');
  };

  Layout.closeSheet = function () {
    document.getElementById('sheetOverlay').classList.remove('active');
    document.getElementById('sheet').classList.remove('open');
  };

  /* ── Status bar ── */

  Layout.setConnectionStatus = function (online) {
    const dot = document.getElementById('connDot');
    const label = document.getElementById('connLabel');
    dot.className = 'connection-dot ' + (online ? 'online' : '');
    label.textContent = online ? 'Connected' : 'Disconnected';
  };

  Layout.setTaskCount = function (count) {
    const el = document.getElementById('taskCountLabel');
    el.textContent = count > 0 ? count + ' task' + (count > 1 ? 's' : '') + ' running' : '';
  };

  Layout.setCost = function (cost) {
    const el = document.getElementById('costLabel');
    el.textContent = cost ? '$' + cost.toFixed(2) : '';
  };

  /* ── User info ── */

  Layout.setUser = function (user) {
    const avatar = document.getElementById('userAvatar');
    const nameLabel = document.getElementById('userNameLabel');
    if (user) {
      const initial = (user.email || 'U')[0].toUpperCase();
      avatar.textContent = initial;
      nameLabel.textContent = user.email || 'User';
    } else {
      avatar.textContent = '?';
      nameLabel.textContent = 'Not logged in';
    }
  };

  Layout.setNotificationBadge = function (count) {
    const badge = document.getElementById('notifBadge');
    if (count > 0) {
      badge.classList.remove('hidden');
      badge.textContent = count > 99 ? '99+' : count;
    } else {
      badge.classList.add('hidden');
    }
  };

  /* ── Global UI event bindings ── */

  function bindGlobalUI() {
    // Sidebar toggle
    document.getElementById('sidebarToggle').addEventListener('click', function (e) {
      e.stopPropagation();
      Layout.toggleSidebar();
    });

    // Sidebar navigation clicks
    document.getElementById('sidebar').addEventListener('click', function (e) {
      const item = e.target.closest('.sidebar-item');
      if (!item) return;
      const route = item.dataset.route;
      if (route && window.MayaRouter) {
        if (window.innerWidth < 768) Layout.closeSidebar();
        window.MayaRouter.navigate(route);
      }
    });

    // Bottom bar navigation clicks
    document.getElementById('bottombar').addEventListener('click', function (e) {
      const item = e.target.closest('.bottombar-item');
      if (!item) return;
      const route = item.dataset.route;
      if (route === 'more') {
        openMoreNav();
        return;
      }
      if (route && window.MayaRouter) {
        window.MayaRouter.navigate(route);
      }
    });

    // Close modal on overlay click
    document.getElementById('modalOverlay').addEventListener('click', function (e) {
      if (e.target === this) Layout.closeModal();
    });

    // Close drawer on overlay click
    document.getElementById('drawerOverlay').addEventListener('click', function () {
      Layout.closeDrawer();
    });

    // Close sheet on overlay click
    document.getElementById('sheetOverlay').addEventListener('click', function () {
      Layout.closeSheet();
    });

    // Escape key
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        Layout.closeModal();
        Layout.closeDrawer();
        Layout.closeSheet();
      }
      // Ctrl+B toggle sidebar
      if (e.ctrlKey && e.key === 'b') {
        e.preventDefault();
        Layout.toggleSidebar();
      }
    });

    // Global search
    const searchInput = document.getElementById('globalSearch');
    searchInput.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' && this.value.trim()) {
        // TODO: global search screen
        Layout.toast('Search: ' + this.value, 'info');
      }
    });

    // Notification bell
    document.getElementById('notifBtn').addEventListener('click', function () {
      // TODO: notification panel
      Layout.toast('Notifications panel', 'info');
    });

    // Window resize — close mobile drawers
    window.addEventListener('resize', function () {
      if (window.innerWidth >= 768) {
        document.getElementById('sidebar').classList.remove('open');
      }
    });
  }

  /* ── Loading screen helper ── */

  Layout.showLoading = function (msg) {
    const el = document.getElementById('workspaceContent');
    el.innerHTML = `<div class="loading-screen"><span class="spinner spinner-lg"></span><span>${msg || 'Loading...'}</span></div>`;
  };

  Layout.render = function (html) {
    document.getElementById('workspaceContent').innerHTML = html;
  };

  Layout.setTitle = function (title) {
    document.title = title ? 'Maya — ' + title : 'Maya 2.0';
  };

})();
