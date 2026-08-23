// Maya 2.0 ULTRA - Confirm Dialog Component
import { Modal } from './Modal.js';

export class ConfirmDialog {
  static async confirm(options = {}) {
    const {
      title = 'Confirm',
      message = 'Are you sure?',
      confirmText = 'Confirm',
      cancelText = 'Cancel',
      variant = 'danger', // danger, warning, info
      confirmVariant = null // overrides variant for confirm button
    } = options;
    
    const modal = new Modal({
      title,
      size: 'small',
      closable: true
    });
    
    const variantClass = variant === 'danger' ? 'btn-danger' : 
                         variant === 'warning' ? 'btn-warning' : 
                         'btn-primary';
    const confirmBtnClass = confirmVariant ? `btn-${confirmVariant}` : variantClass;
    
    modal.setContent(`
      <p style="color: var(--text-secondary); margin-bottom: var(--space-4);">${message}</p>
    `);
    
    // Override footer buttons
    const footer = modal.element.querySelector('.modal-footer');
    if (footer) {
      footer.innerHTML = `
        <button class="btn btn-secondary modal-cancel">${cancelText}</button>
        <button class="btn ${confirmBtnClass} modal-confirm">${confirmText}</button>
      `;
      
      footer.querySelector('.modal-cancel').addEventListener('click', () => modal.close(false));
      footer.querySelector('.modal-confirm').addEventListener('click', () => modal.close(true));
    }
    
    return modal.open();
  }
  
  static async danger(title, message, confirmText = 'Delete') {
    return this.confirm({ title, message, confirmText, variant: 'danger' });
  }
  
  static async warning(title, message, confirmText = 'Continue') {
    return this.confirm({ title, message, confirmText, variant: 'warning' });
  }
  
  static async info(title, message, confirmText = 'OK') {
    return this.confirm({ title, message, confirmText, variant: 'info' });
  }
  
  static async destructive(actionName, itemName) {
    return this.danger(
      `Delete ${actionName}`,
      `Are you sure you want to delete "${itemName}"? This action cannot be undone.`,
      'Delete'
    );
  }
}

// Global confirm function
export async function confirm(message, title = 'Confirm') {
  return ConfirmDialog.confirm({ title, message });
}

export async function confirmDelete(itemName) {
  return ConfirmDialog.destructive('item', itemName);
}