// Maya 2.0 ULTRA - Form Component
import { validators, validateForm, validateField } from '../utils/validation.js';

export class Form {
  constructor(container, options = {}) {
    this.container = container;
    this.options = {
      fields: [],
      initialValues: {},
      onSubmit: null,
      onChange: null,
      validateOnChange: true,
      validateOnBlur: true,
      ...options
    };
    this.values = { ...this.options.initialValues };
    this.errors = {};
    this.touched = {};
    this.submitting = false;
    this.render();
    this.bindEvents();
  }
  
  render() {
    const { fields } = this.options;
    
    const fieldsHtml = fields.map(field => this.renderField(field)).join('');
    
    this.container.innerHTML = `
      <form class="form" novalidate>
        ${fieldsHtml}
        ${this.options.onSubmit ? `
          <div class="form-actions">
            <button type="button" class="btn btn-secondary form-cancel">Cancel</button>
            <button type="submit" class="btn btn-primary form-submit" disabled>${this.options.submitText || 'Submit'}</button>
          </div>
        ` : ''}
      </form>
    `;
  }
  
  renderField(field) {
    const { key, label, type = 'text', required = false, placeholder = '', help = '', error = '', options = [], rows = 4 } = field;
    const value = this.values[key] || '';
    const hasError = this.errors[key] && this.touched[key];
    const showError = hasError ? this.errors[key] : '';
    
    let inputHtml = '';
    const commonAttrs = `
      id="field-${key}"
      name="${key}"
      value="${this.escapeHtml(value)}"
      placeholder="${this.escapeHtml(placeholder)}"
      ${required ? 'required' : ''}
      ${field.disabled ? 'disabled' : ''}
      aria-describedby="${help ? `field-${key}-help` : ''} ${hasError ? `field-${key}-error` : ''}"
      aria-invalid="${hasError ? 'true' : 'false'}"
    `;
    
    switch (type) {
      case 'textarea':
        inputHtml = `<textarea class="form-textarea${hasError ? ' error' : ''}" rows="${rows}" ${commonAttrs}>${this.escapeHtml(value)}</textarea>`;
        break;
      case 'select':
        inputHtml = `
          <select class="form-select${hasError ? ' error' : ''}" ${commonAttrs}>
            <option value="">Select...</option>
            ${options.map(opt => `<option value="${opt.value}" ${value === opt.value ? 'selected' : ''}>${opt.label}</option>`).join('')}
          </select>
        `;
        break;
      case 'checkbox':
        inputHtml = `
          <div class="form-check">
            <input type="checkbox" class="form-check-input" id="field-${key}" name="${key}" ${value ? 'checked' : ''} ${required ? 'required' : ''} ${field.disabled ? 'disabled' : ''}>
            <label class="form-check-label" for="field-${key}">${label}</label>
          </div>
        `;
        return `
          <div class="form-group">
            ${inputHtml}
            ${help ? `<div class="form-help" id="field-${key}-help">${help}</div>` : ''}
            ${showError ? `<div class="form-error" id="field-${key}-error">${showError}</div>` : ''}
          </div>
        `;
      case 'switch':
        inputHtml = `
          <label class="form-switch">
            <input type="checkbox" class="form-switch-input" id="field-${key}" name="${key}" ${value ? 'checked' : ''} ${field.disabled ? 'disabled' : ''}>
            <span class="form-switch-slider"></span>
            <span class="form-switch-label">${label}</span>
          </label>
        `;
        return `
          <div class="form-group">
            ${inputHtml}
            ${help ? `<div class="form-help" id="field-${key}-help">${help}</div>` : ''}
          </div>
        `;
      case 'radio':
        inputHtml = `
          <div class="form-radio-group">
            ${options.map(opt => `
              <label class="form-check">
                <input type="radio" class="form-check-input" name="${key}" value="${opt.value}" ${value === opt.value ? 'checked' : ''} ${field.disabled ? 'disabled' : ''}>
                <span class="form-check-label">${opt.label}</span>
              </label>
            `).join('')}
          </div>
        `;
        break;
      default:
        inputHtml = `<input type="${type}" class="form-input${hasError ? ' error' : ''}" ${commonAttrs}>`;
    }
    
    if (type === 'checkbox' || type === 'switch' || type === 'radio') {
      return inputHtml; // Already wrapped above
    }
    
    return `
      <div class="form-group">
        ${label ? `<label class="form-label" for="field-${key}">${label}${required ? '<span class="required">*</span>' : ''}</label>` : ''}
        ${inputHtml}
        ${help ? `<div class="form-help" id="field-${key}-help">${help}</div>` : ''}
        ${showError ? `<div class="form-error" id="field-${key}-error">${showError}</div>` : ''}
      </div>
    `;
  }
  
  bindEvents() {
    const form = this.container.querySelector('form');
    if (!form) return;
    
    // Input changes
    form.querySelectorAll('input, select, textarea').forEach(input => {
      input.addEventListener('input', (e) => this.handleInput(e));
      input.addEventListener('change', (e) => this.handleChange(e));
      input.addEventListener('blur', (e) => this.handleBlur(e));
    });
    
    // Submit
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      this.handleSubmit();
    });
    
    // Cancel
    const cancelBtn = form.querySelector('.form-cancel');
    if (cancelBtn) {
      cancelBtn.addEventListener('click', () => {
        if (this.options.onCancel) this.options.onCancel();
      });
    }
  }
  
  handleInput(e) {
    const { name, value, type, checked } = e.target;
    this.values[name] = type === 'checkbox' ? checked : value;
    this.validateField(name);
    this.updateSubmitButton();
    
    if (this.options.onChange) {
      this.options.onChange(this.values, name);
    }
  }
  
  handleChange(e) {
    const { name, value, type, checked } = e.target;
    this.values[name] = type === 'checkbox' ? checked : value;
    
    if (this.options.onChange) {
      this.options.onChange(this.values, name);
    }
  }
  
  handleBlur(e) {
    const { name } = e.target;
    this.touched[name] = true;
    this.validateField(name);
    this.renderField(name);
  }
  
  validateField(name) {
    const field = this.options.fields.find(f => f.key === name);
    if (!field || !field.validate) return true;
    
    const value = this.values[name];
    const error = validateField(value, field.validate);
    this.errors[name] = error;
    return !error;
  }
  
  validateAll() {
    let isValid = true;
    this.touched = {};
    
    for (const field of this.options.fields) {
      if (!field.validate) continue;
      this.touched[field.key] = true;
      const error = validateField(this.values[field.key], field.validate);
      this.errors[field.key] = error;
      if (error) isValid = false;
    }
    
    return isValid;
  }
  
  async handleSubmit() {
    if (this.submitting) return;
    
    if (!this.validateAll()) {
      this.render();
      return;
    }
    
    this.submitting = true;
    this.updateSubmitButton(true);
    
    try {
      if (this.options.onSubmit) {
        await this.options.onSubmit(this.values);
      }
    } catch (error) {
      console.error('Form submit error:', error);
      this.errors._form = error.message;
    } finally {
      this.submitting = false;
      this.updateSubmitButton();
    }
  }
  
  updateSubmitButton(loading = false) {
    const submitBtn = this.container.querySelector('.form-submit');
    if (submitBtn) {
      submitBtn.disabled = loading || !this.isValid();
      if (loading) {
        submitBtn.innerHTML = '<div class="spinner" style="width: 16px; height: 16px;"></div>';
      } else {
        submitBtn.textContent = this.options.submitText || 'Submit';
      }
    }
  }
  
  isValid() {
    return Object.values(this.errors).every(e => !e);
  }
  
  renderField(key) {
    const field = this.options.fields.find(f => f.key === key);
    if (!field) return;
    
    const group = this.container.querySelector(`#field-${key}`)?.closest('.form-group');
    if (group) {
      const newHtml = this.renderField(field);
      const temp = document.createElement('div');
      temp.innerHTML = newHtml;
      group.replaceWith(temp.firstElementChild);
    }
  }
  
  getValues() {
    return { ...this.values };
  }
  
  setValues(values) {
    this.values = { ...this.values, ...values };
    this.render();
  }
  
  setError(key, message) {
    this.errors[key] = message;
    this.touched[key] = true;
    this.renderField(key);
  }
  
  clearError(key) {
    delete this.errors[key];
    this.renderField(key);
  }
  
  reset() {
    this.values = { ...this.options.initialValues };
    this.errors = {};
    this.touched = {};
    this.render();
  }
  
  destroy() {
    // Cleanup if needed
  }
  
  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
}