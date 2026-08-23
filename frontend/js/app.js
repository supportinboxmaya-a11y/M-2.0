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

// View imports
import { ChatView } from './views/ChatView.js';
import { MemoryView } from './views/MemoryView.js';
import { ToolsView } from './views/ToolsView.js';
import { TasksView } from './views/TasksView.js';
import { RAGView } from './views/RAGView.js';
import { WorkflowsView } from './views/WorkflowsView.js';
import { HostingView } from './views/HostingView.js';
import { CognitionView } from './views/CognitionView.js';
import { SettingsView } from './views/SettingsView.js';
import { AdminView } from './views/AdminView.js';
import { LearningView } from './views/LearningView.js';
import { PromptsView } from './views/PromptsView.js';
import { WebhooksView } from './views/WebhooksView.js';
import { TranslateView } from './views/TranslateView.js';
import { AnalyticsView } from './views/AnalyticsView.js';
import { LogsView } from './views/LogsView.js';
import { DocsView } from './views/DocsView.js';
import { AgentsView } from './views/AgentsView.js';
import { InstancesView } from './views/InstancesView.js';
import { DevicesView } from './views/DevicesView.js';
import { WorkspaceView } from './views/WorkspaceView.js';
import { BackupsView } from './views/BackupsView.js';
import { SecurityView } from './views/SecurityView.js';
import { ApprovalsView } from './views/ApprovalsView.js';

// Generic views
import { RAGView as GenericRAGView } from './views/GenericViews.js';
import { WorkflowsView as GenericWorkflowsView } from './views/GenericViews.js';
import { LearningView as GenericLearningView } from './views/GenericViews.js';
import { PromptsView as GenericPromptsView } from './views/GenericViews.js';
import { WebhooksView as GenericWebhooksView } from './views/GenericViews.js';
import { TranslateView as GenericTranslateView } from './views/GenericViews.js';
import { AnalyticsView as GenericAnalyticsView } from './views/GenericViews.js';
import { LogsView as GenericLogsView } from './views/GenericViews.js';
import { DocsView as GenericDocsView } from './views/GenericViews.js';
import { AgentsView as GenericAgentsView } from './views/GenericViews.js';
import { InstancesView as GenericInstancesView } from './views/GenericViews.js';
import { DevicesView as GenericDevicesView } from './views/GenericViews.js';
import { WorkspaceView as GenericWorkspaceView } from './views/GenericViews.js';
import { BackupsView as GenericBackupsView } from './views/GenericViews.js';
import { SecurityView as GenericSecurityView } from './views/GenericViews.js';
import { ApprovalsView as GenericApprovalsView } from './views/GenericViews.js';

class App {
  constructor() {
    this.views = new Map();
    this.currentView = null;
    this.sidebar = null;
    this.header = null;
    this.viewContainer = null;
    this.modalsContainer = null;
    this.init();
  }
  
  async init() {
    // Initialize auth
    const hasAuth = auth.init();
    
    // Get DOM elements
    this.viewContainer = document.getElementById('viewContainer');
    this.modalsContainer = document.getElementById('modalsContainer');
    
    // Initialize components
    this.sidebar = new Sidebar(document.getElementById('sidebarNav'));
    this.header = new Header(document.getElementById('header'));
    
    // Initialize views
    this.registerViews();
    
    // Setup routing
    this.setupRouting();
    
    // Setup WebSocket
    if (hasAuth && auth.getToken()) {
      this.connectWebSocket();
    }
    
    // Initialize sync
    await sync.init();
    
    // Register service worker
    this.registerServiceWorker();
    
    // Handle initial route
    this.handleRoute(window.location.hash || '#chat');
    
    // Listen for auth changes
    auth.subscribe((event) => {
      if (event === 'login') {
        this.connectWebSocket();
        this.header.render();
        this.sidebar.render();
      } else if (event === 'logout') {
        this.disconnectWebSocket();
        this.header.render();
        this.sidebar.render();
      }
    });
    
    // Listen for route changes
    window.addEventListener('hashchange', () => {
      this.handleRoute(window.location.hash);
    });
    
    // Mobile sidebar overlay
    const overlay = document.getElementById('sidebarOverlay');
    if (overlay) {
      overlay.addEventListener('click', () => this.sidebar.closeMobile());
    }
    
    console.log('Maya 2.0 ULTRA initialized');
  }
  
  registerViews() {
    const viewClasses = {
      chat: ChatView,
      memory: MemoryView,
      tools: ToolsView,
      tasks: TasksView,
      rag: RAGView,
      workflows: WorkflowsView,
      hosting: HostingView,
      cognition: CognitionView,
      settings: SettingsView,
      admin: AdminView,
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
      approvals: ApprovalsView
    };
    
    // Use generic views for views that don't have custom implementations
    const genericViews = {
      rag: GenericRAGView,
      workflows: GenericWorkflowsView,
      learning: GenericLearningView,
      prompts: GenericPromptsView,
      webhooks: GenericWebhooksView,
      translate: GenericTranslateView,
      analytics: GenericAnalyticsView,
      logs: GenericLogsView,
      docs: GenericDocsView,
      agents: GenericAgentsView,
      instances: GenericInstancesView,
      devices: GenericDevicesView,
      workspace: GenericWorkspaceView,
      backups: GenericBackupsView,
      security: GenericSecurityView,
      approvals: GenericApprovalsView
    };
    
    // Prefer custom views, fall back to generic
    for (const [name, ViewClass] of Object.entries({ ...genericViews, ...viewClasses })) {
      this.views.set(name, new ViewClass(this));
    }
  }
  
  setupRouting() {
    // View title mapping
    this.viewTitles = {
      chat: 'Chat',
      memory: 'Memory',
      tools: 'Tools',
      tasks: 'Tasks',
      rag: 'RAG / Knowledge Base',
      workflows: 'Workflows',
      hosting: 'Hosting',
      cognition: 'Cognition',
      settings: 'Settings',
      admin: 'Admin',
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
      approvals: 'Approvals'
    };
  }
  
  handleRoute(hash) {
    const viewName = hash.replace('#', '').split('/')[0] || 'chat';
    
    // Check admin access
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
    
    // Hide current view
    if (this.currentView && this.currentView !== view) {
      this.currentView.hide();
    }
    
    // Show new view
    this.currentView = view;
    this.currentView.show();
    
    // Update UI
    this.header.setViewTitle(this.viewTitles[viewName] || viewName);
    this.sidebar.setActiveView(viewName);
    
    // Update mobile nav
    document.querySelectorAll('.mobile-nav-item').forEach(item => {
      item.classList.toggle('active', item.dataset.view === viewName);
    });
    
    // Scroll to top
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
    
    // Update notifications
    if (type === 'done' && data.status === 'done') {
      toast.success(`Task completed: ${data.goal?.slice(0, 50)}...`);
    } else if (type === 'done' && data.status === 'failed') {
      toast.error(`Task failed: ${data.error || 'Unknown error'}`);
    }
  }
  
  handleApprovalRequested(approval) {
    this.header.updateApprovalStatus(1); // Would count actual pending
    toast.warning('Approval Required', approval.action, {
      action: {
        label: 'Review',
        onClick: () => {
          window.location.hash = '#approvals';
          if (this.currentView && this.currentView.onApprovalRequested) {
            this.currentView.onApprovalRequested(approval);
          }
        }
      }
    });
  }
  
  async registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      try {
        await navigator.serviceWorker.register('/sw.js');
        console.log('Service Worker registered');
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
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  window.app = new App();
  
  // Expose global utilities
  window.toast = toast;
  window.confirm = ConfirmDialog.confirm;
  window.confirmDelete = ConfirmDialog.destructive;
  window.api = api;
  window.auth = auth;
  window.ws = ws;
  window.sync = sync;
});

// Handle unhandled promise rejections
window.addEventListener('unhandledrejection', (event) => {
  console.error('Unhandled rejection:', event.reason);
  toast.error(event.reason?.message || 'An unexpected error occurred');
});