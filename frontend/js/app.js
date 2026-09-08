// Maya 2.0 ULTRA - Full App with Phase 1-4 Capabilities
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

// Core views
import { LoginView } from './views/LoginView.js';
import { ChatView } from './views/ChatView.js';
import { CodeView } from './views/CodeView.js';
import { ApprovalsView } from './views/GenericViews.js';
import { DashboardView } from './views/DashboardView.js';

// Phase 1-4 views
import { BrowserView } from './views/BrowserView.js';
import { SandboxView } from './views/SandboxView.js';
import { VectorView } from './views/VectorView.js';
import { AgentGraphView } from './views/AgentGraphView.js';
import { MultiModalView } from './views/MultiModalView.js';
import { EnhancedMemoryView } from './views/EnhancedMemoryView.js';
import { SystemStatusView } from './views/SystemStatusView.js';

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
            this.connectSSE();
        }

        try {
            await sync.init();
        } catch (err) {
            console.error('Offline sync unavailable:', err);
        }
        this.registerServiceWorker();

        this.handleRoute(window.location.hash || '#dashboard');

        auth.subscribe((event) => {
            if (event === 'login') {
                this.header.render?.();
                this.sidebar.render();
                this.connectSSE();
            } else if (event === 'logout') {
                this.disconnectSSE();
                window.location.hash = '#login';
            }
        });

        window.addEventListener('hashchange', () => this.handleRoute(window.location.hash));

        const overlay = document.getElementById('sidebarOverlay');
        if (overlay) overlay.addEventListener('click', () => this.sidebar.closeMobile());

        console.log('Maya 2.0 ULTRA - Full App initialized');
    }

    connectSSE() {
        if (this.sseConnected) return;
        this.sseConnected = true;
        this.sse.connect('/api/v1/events', (event) => {
            this.handleSSEEvent(event);
        });
    }

    disconnectSSE() {
        if (this.sseConnected) {
            this.sse.disconnect();
            this.sseConnected = false;
        }
    }

    handleSSEEvent(event) {
        // Broadcast to current view if it has a handler
        if (this.currentView && typeof this.currentView.onSSEEvent === 'function') {
            this.currentView.onSSEEvent(event);
        }
        
        // Global handlers
        switch (event.type) {
            case 'task_started':
            case 'task_done':
            case 'approval_requested':
                this.showToast(event.type === 'approval_requested' ? 'Approval required' : `Task ${event.type}`, 'info');
                break;
        }
    }

    registerViews() {
        const viewClasses = {
            // Core
            login: LoginView,
            dashboard: DashboardView,
            chat: ChatView,
            code: CodeView,
            approvals: ApprovalsView,
            
            // Phase 1: Browser & Sandbox
            browser: BrowserView,
            sandbox: SandboxView,
            
            // Phase 2: Vector Store & Agent Graphs
            vector: VectorView,
            'agent-graph': AgentGraphView,
            
            // Phase 3: Multi-Modal
            multimodal: MultiModalView,
            
            // Phase 4: Enhanced Memory
            'enhanced-memory': EnhancedMemoryView,
            
            // System
            'system-status': SystemStatusView,
        };
        
        for (const [name, ViewClass] of Object.entries(viewClasses)) {
            this.views.set(name, new ViewClass(this));
        }
    }

    setupRouting() {
        this.viewTitles = {
            login: 'Sign in',
            dashboard: 'Dashboard',
            chat: 'Chat',
            code: 'Code',
            approvals: 'Approvals',
            browser: 'Browser Pool',
            sandbox: 'Sandbox',
            vector: 'Vector Store',
            'agent-graph': 'Agent Graphs',
            multimodal: 'Multi-Modal',
            'enhanced-memory': 'Enhanced Memory',
            'system-status': 'System Status',
        };
        
        this.viewIcons = {
            login: '🔐',
            dashboard: '📊',
            chat: '💬',
            code: '💻',
            approvals: '✅',
            browser: '🌐',
            sandbox: '🔒',
            vector: '🔍',
            'agent-graph': '🕸️',
            multimodal: '🎨',
            'enhanced-memory': '🧠',
            'system-status': '⚙️',
        };
    }

    handleRoute(hash) {
        const parts = hash.replace('#', '').split('/');
        const viewName = parts[0] || 'dashboard';
        const viewParams = parts.slice(1);

        if (!auth.getToken() && viewName !== 'login') {
            window.location.hash = '#login';
            return;
        }
        if (auth.getToken() && viewName === 'login') {
            window.location.hash = '#dashboard';
            return;
        }

        const view = this.views.get(viewName);
        if (!view) {
            console.warn(`View not found: ${viewName}`);
            window.location.hash = '#dashboard';
            return;
        }

        this.viewContainer.querySelectorAll('.error-state').forEach(n => n.remove());

        if (this.currentView && this.currentView !== view) {
            try { this.currentView.hide(); } catch {}
        }

        this.currentView = view;
        try { 
            this.currentView.show(viewParams); 
        } catch (err) {
            console.error('View render failed:', err);
            const errBox = document.createElement('div');
            errBox.className = 'error-state';
            errBox.style.padding = 'var(--space-6)';
            errBox.innerHTML = `<div class="icon">⚠️</div><h3>Screen failed to load</h3><p>${(err && err.message) || err}</p>`;
            this.viewContainer.appendChild(errBox);
        }

        this.header.setViewTitle?.(`${this.viewIcons[viewName] || '📄'} ${this.viewTitles[viewName] || viewName}`);
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

    formatDuration(ms) {
        if (!ms && ms !== 0) return '—';
        if (ms < 1000) return `${ms}ms`;
        if (ms < 60000) return `${(ms/1000).toFixed(1)}s`;
        return `${(ms/60000).toFixed(1)}m`;
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