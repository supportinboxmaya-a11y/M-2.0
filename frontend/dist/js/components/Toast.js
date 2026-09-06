// Maya 2.0 ULTRA - Toast Component
const TOAST_TYPES = {
  success: { icon: 'check-circle', class: 'toast-success' },
  error: { icon: 'x-circle', class: 'toast-error' },
  warning: { icon: 'alert-triangle', class: 'toast-warning' },
  info: { icon: 'info', class: 'toast-info' }
};

const ICONS = {
  'check-circle': '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline>',
  'x-circle': '<circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line>',
  'alert-triangle': '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line>',
  'info': '<circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line>'
};

class ToastManager {
  constructor() {
    this.container = null;
    this.toasts = new Map();
    this.init();
  }
  
  init() {
    this.container = document.getElementById('toastContainer');
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.id = 'toastContainer';
      this.container.className = 'toast-container';
      this.container.setAttribute('aria-live', 'polite');
      this.container.setAttribute('aria-atomic', 'true');
      document.body.appendChild(this.container);
    }
  }
  
  show(message, type = 'info', title = '', options = {}) {
    const { duration = 5000, action } = options;
    const config = TOAST_TYPES[type] || TOAST_TYPES.info;
    const id = crypto.randomUUID();
    
    const toast = document.createElement('div');
    toast.className = `toast ${config.class}`;
    toast.dataset.id = id;
    toast.innerHTML = `
      <svg class="toast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${ICONS[config.icon]}</svg>
      <div class="toast-content">
        ${title ? `<div class="toast-title">${this.escapeHtml(title)}</div>` : ''}
        <div class="toast-message">${this.escapeHtml(message)}</div>
      </div>
      <button class="toast-close" aria-label="Dismiss">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
      </button>
    `;
    
    if (action) {
      const actionBtn = document.createElement('button');
      actionBtn.className = 'btn btn-sm btn-ghost toast-action';
      actionBtn.textContent = action.label;
      actionBtn.addEventListener('click', () => {
        action.onClick();
        this.dismiss(id);
      });
      toast.querySelector('.toast-content').appendChild(actionBtn);
    }
    
    this.container.appendChild(toast);
    this.toasts.set(id, { element: toast, timeout: null });
    
    // Animate in
    requestAnimationFrame(() => {
      toast.classList.add('show');
    });
    
    // Auto dismiss
    if (duration > 0) {
      const timeout = setTimeout(() => this.dismiss(id), duration);
      this.toasts.get(id).timeout = timeout;
    }
    
    // Close button
    toast.querySelector('.toast-close').addEventListener('click', () => this.dismiss(id));
    
    return id;
  }
  
  dismiss(id) {
    const toastData = this.toasts.get(id);
    if (!toastData) return;
    
    const { element, timeout } = toastData;
    if (timeout) clearTimeout(timeout);
    
    element.classList.add('removing');
    element.addEventListener('animationend', () => {
      element.remove();
      this.toasts.delete(id);
    }, { once: true });
  }
  
  dismissAll() {
    for (const id of this.toasts.keys()) {
      this.dismiss(id);
    }
  }
  
  success(message, title, options) { return this.show(message, 'success', title, options); }
  error(message, title, options) { return this.show(message, 'error', title, options); }
  warning(message, title, options) { return this.show(message, 'warning', title, options); }
  info(message, title, options) { return this.show(message, 'info', title, options); }
  
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
}

export const toast = new ToastManager();

// Convenience functions
export function showToast(message, type, title, options) {
  return toast.show(message, type, title, options);
}

export function toastSuccess(message, title, options) { return toast.success(message, title, options); }
export function toastError(message, title, options) { return toast.error(message, title, options); }
export function toastWarning(message, title, options) { return toast.warning(message, title, options); }
export function toastInfo(message, title, options) { return toast.info(message, title, options); }