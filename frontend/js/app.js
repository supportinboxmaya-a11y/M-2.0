// Maya 2.0 ULTRA - Main Application
import { auth } from './auth.js';
import { api } from './api.js';
import { ws } from './ws.js';
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
import { ChatView } from './views/ChatView.js';
import { MemoryView } from './views/MemoryView.js';
import { ToolsView } from './views/ToolsView.js';
import { TasksView } from './views/TasksView.js';
import { HostingView } from './views/HostingView.js';
import { CognitionView } from './views/CognitionView.js';
import { SettingsView } from './views/SettingsView.js';
import { AdminView } from './views/AdminView.js';
import { LoginView } from './views/LoginView.js';

// Cognitive-architecture views (Phases 18/34–42)
import { KernelView } from './views/KernelView.js';
import { GoalsView } from './views/GoalsView.js';
import { SkillsView } from './views/SkillsView.js';
import { SelfModelView } from './views/SelfModelView.js';
import { CapabilitiesView } from './views/CapabilitiesView.js';
import { MetacognitionView } from './views/MetacognitionView.js';
import { SocietyView } from './views/SocietyView.js';
import { MCPView } from './views/MCPView.js';
import { CoreLoopView } from './views/CoreLoopView.js';
import { ResearchView } from './views/ResearchView.js';

// Income Engine views
import { IncomeScoutView } from './views/IncomeScoutView.js';
import { IncomeStrategistView } from './views/IncomeStrategistView.js';
import { IncomeBuilderView } from './views/IncomeBuilderView.js';
import { IncomeLauncherView } from './views/IncomeLauncherView.js';
import { IncomeGrowthView } from './views/IncomeGrowthView.js';
import { IncomePortfolioView } from './views/IncomePortfolioView.js';

// Notifications view
import { NotificationsView } from './views/NotificationsView.js';

// Generic CRUD/list views
import {
  RAGView, WorkflowsView, LearningView, PromptsView, WebhooksView,
  TranslateView, AnalyticsView, LogsView, DocsView, AgentsView,
  InstancesView, DevicesView, WorkspaceView, BackupsView,
  SecurityView, ApprovalsView,
} from './views/GenericViews.js';

class App {
  constructor() {
    this.views = new Map();
    this.currentView = null;
    this.sidebar = null;
    this.header = null;
    this.viewContainer = null;
    this.modalsContainer = null;

    // Utilities views rely on via `this.app.*`
    this.api = api;
    this.auth = auth;
    this.ws = ws;
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

    // Sidebar owns the whole <aside> so state classes (.collapsed/.mobile-open)
    // land on the element the CSS targets.
    this.sidebar = new Sidebar(document.getElementById('sidebar'));
    this.header = new Header(document.getElementById('header'));

    this.registerViews();
    this.setupRouting();

    if (hasAuth && auth.getToken()) {
      this.connectWebSocket();
    }

    // Offline sync is best-effort; a storage failure must never block boot.
    try {
      await sync.init();
    } catch (err) {
      console.error('Offline sync unavailable:', err);
    }
    this.registerServiceWorker();

    this.handleRoute(window.location.hash || '#chat');

    auth.subscribe((event) => {
      if (event === 'login') {
        this.connectWebSocket();
        this.header.render?.();
        this.sidebar.render();
      } else if (event === 'logout') {
        this.disconnectWebSocket();
        window.location.hash = '#login';
      }
    });

    window.addEventListener('hashchange', () => this.handleRoute(window.location.hash));

    const overlay = document.getElementById('sidebarOverlay');
    if (overlay) overlay.addEventListener('click', () => this.sidebar.closeMobile());

    console.log('Maya 2.0 ULTRA initialized');
  }

  registerViews() {
    const viewClasses = {
      login: LoginView,
      chat: ChatView,
      tasks: TasksView,
      memory: MemoryView,
      tools: ToolsView,
      hosting: HostingView,
      cognition: CognitionView,
      settings: SettingsView,
      admin: AdminView,
      // Cognitive architecture
      kernel: KernelView,
      goals: GoalsView,
      skills: SkillsView,
      selfmodel: SelfModelView,
      capabilities: CapabilitiesView,
      metacognition: MetacognitionView,
      society: SocietyView,
      mcp: MCPView,
      coreloop: CoreLoopView,
      research: ResearchView,
      // Income Engine
      scout: IncomeScoutView,
      strategist: IncomeStrategistView,
      builder: IncomeBuilderView,
      launcher: IncomeLauncherView,
      growth: IncomeGrowthView,
      portfolio: IncomePortfolioView,
      // Notifications
      notifications: NotificationsView,
      // Generic list/detail views
      rag: RAGView,
      workflows: WorkflowsView,
      learning: LearningView,
      prompts: PromptsView,
      webhooks: WebhooksView,
      translate: TranslateView,
      analytics: AnalyticsView,
      logs: LogsView,
      docs: DocsView,
      agents: AgentsView,
      instances: InstancesView,
      devices: DevicesView,
      workspace: WorkspaceView,
      backups: BackupsView,
      security: SecurityView,
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
      tasks: 'Tasks',
      memory: 'Memory',
      tools: 'Tools',
      hosting: 'Hosting',
      cognition: 'Cognition',
      settings: 'Settings',
      admin: 'Admin',
      kernel: 'Cognitive Kernel',
      goals: 'Goals',
      skills: 'Skills',
      selfmodel: 'Self-Model',
      capabilities: 'Capabilities',
      metacognition: 'Metacognition',
      society: 'Agent Society',
      mcp: 'MCP Servers',
      coreloop: 'Core Loop',
      research: 'Research & Publish',
      // Income Engine
      scout: 'Scout - Opportunities',
      strategist: 'Strategist - Plans',
      builder: 'Builder - Projects',
      launcher: 'Launcher - Launches',
      growth: 'Growth - Proposals',
      portfolio: 'Portfolio Manager',
      // Notifications
      notifications: 'Notifications',
      // Generic list/detail views
      rag: 'RAG / Knowledge Base',
      workflows: 'Workflows',
      learning: 'Learning',
      prompts: 'Prompt Library',
      webhooks: 'Webhooks',
      translate: 'Translate',
      analytics: 'Analytics',
      logs: 'Logs',
      docs: 'Documentation',
      agents: 'Agents',
      instances: 'Instances',
      devices: 'Devices',
      workspace: 'Workspace',
      backups: 'Backups',
      security: 'Security',
      approvals: 'Approvals',
    };
  }

  handleRoute(hash) {
    const viewName = hash.replace('#', '').split('/')[0] || 'chat';

    // Auth gate: everything except login requires a session
    if (!auth.getToken() && viewName !== 'login') {
      window.location.hash = '#login';
      return;
    }
    if (auth.getToken() && viewName === 'login') {
      window.location.hash = '#chat';
      return;
    }
    if (viewName === 'admin' && !auth.isAdmin()) {
      window.location.hash = '#chat';
      return;
    }

    const view = this.views.get(viewName);
    if (!view) {
      console.warn(`View not found: ${viewName}`);
      window.location.hash = '#chat';
      return;
    }

    // Clear any stale error state from a previously failed view
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
      errBox.innerHTML =
        `<div class="icon">⚠️</div><h3>Screen failed to load</h3><p>${(err && err.message) || err}</p>`;
      this.viewContainer.appendChild(errBox);
    }

    this.header.setViewTitle?.(this.viewTitles[viewName] || viewName);
    this.sidebar.setActiveView(viewName);

    document.querySelectorAll('.mobile-nav-item').forEach(item => {
      item.classList.toggle('active', item.dataset.view === viewName);
    });

    this.viewContainer.scrollTop = 0;
  }

  connectWebSocket() {
    const token = auth.getToken();
    if (token) {
      ws.connect(token);
      ws.on('task_started', (task) => this.handleTaskEvent('started', task));
      ws.on('task_progress', (data) => this.handleTaskEvent('progress', data));
      ws.on('task_done', (task) => this.handleTaskEvent('done', task));
      ws.on('approval_requested', (approval) => this.handleApprovalRequested(approval));
    }
  }

  disconnectWebSocket() {
    ws.disconnect();
  }

  handleTaskEvent(type, data) {
    if (this.currentView && this.currentView.onTaskEvent) {
      this.currentView.onTaskEvent(type, data);
    }
    if (type === 'done' && data.status === 'done') {
      toast.success(`Task completed: ${(data.goal || '').slice(0, 50)}…`);
    } else if (type === 'done' && data.status === 'failed') {
      toast.error(`Task failed: ${data.error || 'Unknown error'}`);
    }
  }

  handleApprovalRequested(approval) {
    this.header.updateApprovalStatus?.(1);
    toast.warning('Approval Required', approval.action, {
      action: {
        label: 'Review',
        onClick: () => {
          window.location.hash = '#approvals';
          if (this.currentView && this.currentView.onApprovalRequested) {
            this.currentView.onApprovalRequested(approval);
          }
        },
      },
    });
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

  // Global utilities
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

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  window.app = new App();
  window.toast = toast;
  window.confirm = ConfirmDialog.confirm;
  window.confirmDelete = ConfirmDialog.destructive;
  window.api = api;
  window.auth = auth;
  window.ws = ws;
  window.sync = sync;
});

window.addEventListener('unhandledrejection', (event) => {
  console.error('Unhandled rejection:', event.reason);
});
