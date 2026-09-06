// Maya 2.0 ULTRA - Minimal App (Voice + Dashboard + Approvals)
import { auth } from './auth.js';
import { api } from './api.js';
import { sse } from './sse.js';
import { sync } from './sync.js';
import { Sidebar } from './components/Sidebar.js';
import { Header } from './components/Header.js';
import { Modal } from './components/Modal.js';
import { toast } from './components/Toast.js';
import { ConfirmDialog } from './components/ConfirmDialog.js';
import { MarkdownRenderer } from './components/MarkdownRenderer.js';
import { Chart } from './components/Chart.js';
import { DataTable } from './components/DataTable.js';

// Core views (minimal set)
import { ChatView } from './views/ChatView.js';
import { ApprovalsView } from './views/GenericViews.js';
import { LoginView } from './views/LoginView.js';

// Minimal Dashboard view
class DashboardView {
    constructor(app) {
        this.app = app;
        this.container = null;
    }

    show() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.className = 'view dashboard-view';
            this.render();
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
            <div class="view-header"><h2>Dashboard</h2></div>
            <div class="dashboard-grid">
                <div class="stat-card"><div class="stat-value">0</div><div class="stat-label">Opportunities</div></div>
                <div class="stat-card"><div class="stat-value">0</div><div class="stat-label">Projects</div></div>
                <div class="stat-card"><div class="stat-value">0</div><div class="stat-label">Active</div></div>
            </div>
            <div class="activity-section">
                <h3>Recent Activity</h3>
                <div class="activity-list">Loading...</div>
            </div>
        `;
        this.loadActivity();
    }

    async loadActivity() {
        try {
            const response = await this.app.api.get('/api/v1/income/scout/opportunities?limit=5');
            const opps = response.opportunities || [];
            const el = this.container.querySelector('.activity-list');
            if (!opps.length) {
                el.innerHTML = '<div class="empty-state">No activity yet</div>';
                return;
            }
            el.innerHTML = opps.map(o => `
                <div class="activity-item">
                    <div class="activity-title">${this.escapeHtml(o.title)}</div>
                    <div class="activity-meta">${o.source_category} • Score: ${o.total_score.toFixed(1)}</div>
                </div>
            `).join('');
        } catch (e) {
            console.error('Failed to load activity:', e);
        }
    }

    escapeHtml(str) {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }

    destroy() {}
}

class App {
    constructor() {
        this.views = new Map();
        this.currentView = null;
        this.sidebar = null;
        this.header = null;
        this.viewContainer = null;
        this.modalsContainer = null;

        this.api = api;
        this.auth = auth;
        this.sse = sse;
        this.toast = toast;
        this.Modal = Modal;
        this.Chart = Chart;
        this.DataTable = DataTable;
        this.MarkdownRenderer = MarkdownRenderer;

        this.init();
    }

    async init() {
        const hasAuth = auth.init();

        this.viewContainer = document.getElementById('viewContainer');
        this.modalsContainer = document.getElementById('modalsContainer');

        this.sidebar = new Sidebar(document.getElementById('sidebar'));
        this.header = new Header(document.getElementById('header'));

        this.registerViews();
        this.setupRouting();

        if (hasAuth && auth.getToken()) {
            // WebSocket removed - using SSE for real-time updates
        }

        try {
            await sync.init();
        } catch (err) {
            console.error('Offline sync unavailable:', err);
        }
        this.registerServiceWorker();

        this.handleRoute(window.location.hash || '#chat');

        auth.subscribe((event) => {
            if (event === 'login') {
                this.header.render?.();
                this.sidebar.render();
            } else if (event === 'logout') {
                window.location.hash = '#login';
            }
        });

        window.addEventListener('hashchange', () => this.handleRoute(window.location.hash));

        const overlay = document.getElementById('sidebarOverlay');
        if (overlay) overlay.addEventListener('click', () => this.sidebar.closeMobile());

        console.log('Maya 2.0 - Minimal App initialized');
    }

    registerViews() {
        const viewClasses = {
            login: LoginView,
            chat: ChatView,
            dashboard: DashboardView,
            approvals: ApprovalsView,
        };
        for (const [name, ViewClass] of Object.entries(viewClasses)) {
            this.views.set(name, new ViewClass(this));
        }
    }

    setupRouting() {
        this.viewTitles = {
            login: 'Sign in',
            chat: 'Chat',
            dashboard: 'Dashboard',
            approvals: 'Approvals',
        };
    }

    handleRoute(hash) {
        const viewName = hash.replace('#', '').split('/')[0] || 'chat';

        if (!auth.getToken() && viewName !== 'login') {
            window.location.hash = '#login';
            return;
        }
        if (auth.getToken() && viewName === 'login') {
            window.location.hash = '#chat';
            return;
        }

        const view = this.views.get(viewName);
        if (!view) {
            console.warn(`View not found: ${viewName}`);
            window.location.hash = '#chat';
            return;
        }

        this.viewContainer.querySelectorAll('.error-state').forEach(n => n.remove());

        if (this.currentView && this.currentView !== view) {
            try { this.currentView.hide(); } catch {}
        }

        this.currentView = view;
        try { this.currentView.show(); } catch (err) {
            console.error('View render failed:', err);
            const errBox = document.createElement('div');
            errBox.className = 'error-state';
            errBox.style.padding = 'var(--space-6)';
            errBox.innerHTML = `<div class="icon">⚠️</div><h3>Screen failed to load</h3><p>${(err && err.message) || err}</p>`;
            this.viewContainer.appendChild(errBox);
        }

        this.header.setViewTitle?.(this.viewTitles[viewName] || viewName);
        this.sidebar.setActiveView(viewName);

        document.querySelectorAll('.mobile-nav-item').forEach(item => {
            item.classList.toggle('active', item.dataset.view === viewName);
        });

        this.viewContainer.scrollTop = 0;
    }

    

    async registerServiceWorker() {
        if ('serviceWorker' in navigator) {
            try {
                await navigator.serviceWorker.register('/sw.js');
            } catch (error) {
                console.error('Service Worker registration failed:', error);
            }
        }
    }

    showModal(options) {
        return new Modal(options).open();
    }

    showToast(message, type, title, options) {
        return toast.show(message, type, title, options);
    }

    confirm(message, title) {
        return ConfirmDialog.confirm({ title, message });
    }

    confirmDelete(itemName) {
        return ConfirmDialog.destructive('item', itemName);
    }

    escapeHtml(str) {
        const div = document.createElement('div');
        div.textContent = str == null ? '' : String(str);
        return div.innerHTML;
    }

    formatBytes(bytes) {
        if (!bytes && bytes !== 0) return '—';
        const units = ['B', 'KB', 'MB', 'GB', 'TB'];
        let i = 0;
        let n = Number(bytes);
        while (n >= 1024 && i < units.length - 1) { n /= 1024; i++; }
        return `${n.toFixed(n < 10 && i > 0 ? 1 : 0)} ${units[i]}`;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    window.app = new App();
    window.toast = toast;
    window.confirm = ConfirmDialog.confirm;
    window.confirmDelete = ConfirmDialog.destructive;
    window.api = api;
    window.auth = auth;
    window.sync = sync;
});

window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled rejection:', event.reason);
});
