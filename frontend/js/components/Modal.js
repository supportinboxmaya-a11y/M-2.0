// Maya 2.0 ULTRA - Modal Component
export class Modal {
  constructor(options = {}) {
    this.options = {
      title: '',
      size: 'medium', // small, medium, large, full
      closable: true,
      onClose: null,
      onConfirm: null,
      ...options
    };
    this.element = null;
    this.resolvePromise = null;
    this.render();
  }
  
  render() {
    const sizeClass = `modal-${this.options.size}`;
    const closeBtn = this.options.closable ? `
      <button class="modal-close" aria-label="Close modal">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
      </button>
    ` : '';
    
    this.element = document.createElement('div');
    this.element.className = `modal-overlay`;
    this.element.innerHTML = `
      <div class="modal ${sizeClass}" role="dialog" aria-modal="true" aria-labelledby="modal-title">
        <div class="modal-header">
          <h2 id="modal-title" class="modal-title">${this.options.title}</h2>
          ${closeBtn}
        </div>
        <div class="modal-body"></div>
        ${this.options.onConfirm ? `
          <div class="modal-footer">
            <button class="btn btn-secondary modal-cancel">Cancel</button>
            <button class="btn btn-primary modal-confirm">Confirm</button>
          </div>
        ` : ''}
      </div>
    `;
    
    document.getElementById('modalsContainer').appendChild(this.element);
    
    // Bind events
    const modal = this.element.querySelector('.modal');
    const overlay = this.element;
    
    if (this.options.closable) {
      const closeBtn = this.element.querySelector('.modal-close');
      closeBtn?.addEventListener('click', () => this.close(false));
      
      overlay.addEventListener('click', (e) => {
        if (e.target === overlay) this.close(false);
      });
    }
    
    const cancelBtn = this.element.querySelector('.modal-cancel');
    cancelBtn?.addEventListener('click', () => this.close(false));
    
    const confirmBtn = this.element.querySelector('.modal-confirm');
    confirmBtn?.addEventListener('click', () => this.close(true));
    
    // ESC key
    this.keydownHandler = (e) => {
      if (e.key === 'Escape' && this.options.closable) {
        this.close(false);
      }
    };
    document.addEventListener('keydown', this.keydownHandler);
    
    // Focus trap
    this.focusableElements = modal.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    this.firstFocusable = this.focusableElements[0];
    this.lastFocusable = this.focusableElements[this.focusableElements.length - 1];
    
    modal.addEventListener('keydown', this.trapFocus.bind(this));
    
    // Auto-focus first input
    setTimeout(() => {
      const firstInput = modal.querySelector('input, select, textarea');
      if (firstInput) firstInput.focus();
      else this.firstFocusable?.focus();
    }, 50);
  }
  
  trapFocus(e) {
    if (e.key !== 'Tab') return;
    
    if (e.shiftKey) {
      if (document.activeElement === this.firstFocusable) {
        e.preventDefault();
        this.lastFocusable?.focus();
      }
    } else {
      if (document.activeElement === this.lastFocusable) {
        e.preventDefault();
        this.firstFocusable?.focus();
      }
    }
  }
  
  setContent(content) {
    const body = this.element.querySelector('.modal-body');
    if (typeof content === 'string') {
      body.innerHTML = content;
    } else if (content instanceof Node) {
      body.appendChild(content);
    }
  }
  
  setTitle(title) {
    this.options.title = title;
    const titleEl = this.element.querySelector('.modal-title');
    if (titleEl) titleEl.textContent = title;
  }
  
  open() {
    return new Promise((resolve) => {
      this.resolvePromise = resolve;
      this.element.classList.add('open');
      document.body.style.overflow = 'hidden';
    });
  }
  
  close(confirmed) {
    this.element.classList.remove('open');
    document.body.style.overflow = '';
    
    setTimeout(() => {
      document.removeEventListener('keydown', this.keydownHandler);
      this.element.remove();
      
      if (this.resolvePromise) {
        this.resolvePromise(confirmed);
        this.resolvePromise = null;
      }
      
      if (this.options.onClose) {
        this.options.onClose(confirmed);
      }
    }, 200);
  }
  
  static async confirm(title, message, options = {}) {
    const modal = new Modal({
      title,
      size: 'small',
      ...options
    });
    
    modal.setContent(`
      <p style="color: var(--text-secondary); margin-bottom: var(--space-4);">${message}</p>
    `);
    
    return modal.open();
  }
  
  static async prompt(title, message, defaultValue = '', options = {}) {
    const modal = new Modal({
      title,
      size: 'small',
      ...options
    });
    
    let resolvePromise;
    const promise = new Promise((resolve) => { resolvePromise = resolve; });
    
    modal.setContent(`
      <p style="color: var(--text-secondary); margin-bottom: var(--space-4);">${message}</p>
      <input type="text" class="form-input modal-prompt-input" value="${defaultValue}" placeholder="${options.placeholder || ''}">
    `);
    
    const originalClose = modal.close;
    modal.close = (confirmed) => {
      const input = modal.element.querySelector('.modal-prompt-input');
      originalClose(confirmed ? input?.value : null);
    };
    
    await modal.open();
    return resolvePromise;
  }
  
  destroy() {
    if (this.element && this.element.parentNode) {
      this.element.remove();
    }
    document.removeEventListener('keydown', this.keydownHandler);
  }
}