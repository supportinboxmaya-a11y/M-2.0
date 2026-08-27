// Maya 2.0 ULTRA - Login View
import { auth } from '../auth.js';

export class LoginView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.mode = 'login';
  }

  show() {
    document.getElementById('sidebar')?.classList.add('hidden');
    document.getElementById('mobileNav')?.classList.add('hidden');
    document.getElementById('header')?.classList.add('hidden');

    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'login-wrap';
      this.render();
      this.bindEvents();
    }
    this.app.viewContainer.appendChild(this.container);
  }

  hide() {
    if (this.container && this.container.parentNode) {
      this.container.parentNode.removeChild(this.container);
    }
    document.getElementById('sidebar')?.classList.remove('hidden');
    document.getElementById('mobileNav')?.classList.remove('hidden');
    document.getElementById('header')?.classList.remove('hidden');
  }

  render() {
    const registerFields = this.mode === 'register'
      ? `<div class="form-group"><label class="form-label" for="authName">Name</label><input type="text" class="form-input" id="authName" autocomplete="name" placeholder="Your name"></div>`
      : '';
    const submitLabel = this.mode === 'register' ? 'Create account' : 'Sign in';
    const toggle = this.mode === 'register'
      ? `Already have an account? <a href="#" id="authToggle">Sign in</a>`
      : `Need an account? <a href="#" id="authToggle">Register</a>`;

    this.container.innerHTML = `
      <div class="login-card fade-in">
        <div class="login-brand">
          <svg class="brand-icon" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <circle cx="16" cy="16" r="14" stroke="currentColor" stroke-width="2"/>
            <path d="M16 8c-4.4 0-8 3.6-8 8s3.6 8 8 8 8-3.6 8-8-3.6-8-8-8zm0 14c-3.3 0-6-2.7-6-6s2.7-6 6-6 6 2.7 6 6-2.7 6-6 6z" fill="currentColor"/>
          </svg>
          <h1>Maya 2.0</h1>
          <p class="login-sub">Autonomous AI Operating System</p>
        </div>
        <form class="form login-form" id="authForm">
          ${registerFields}
          <div class="form-group">
            <label class="form-label" for="authEmail">Email</label>
            <input type="email" class="form-input" id="authEmail" required autocomplete="username" placeholder="you@example.com">
          </div>
          <div class="form-group">
            <label class="form-label" for="authPassword">Password</label>
            <input type="password" class="form-input" id="authPassword" required autocomplete="current-password" placeholder="••••••••">
          </div>
          <div class="login-error" id="authError" style="display:none" role="alert"></div>
          <button type="submit" class="btn btn-primary btn-block" id="authSubmit">${submitLabel}</button>
          <p class="login-toggle">${toggle}</p>
        </form>
      </div>
    `;
  }

  bindEvents() {
    this.container.querySelector('#authForm').addEventListener('submit', (e) => this.submit(e));
    this.container.querySelector('#authToggle')?.addEventListener('click', (e) => {
      e.preventDefault();
      this.mode = this.mode === 'login' ? 'register' : 'login';
      this.render();
      this.bindEvents();
    });
  }

  async submit(e) {
    e.preventDefault();
    const errEl = this.container.querySelector('#authError');
    const btn = this.container.querySelector('#authSubmit');
    errEl.style.display = 'none';
    btn.disabled = true;
    btn.textContent = this.mode === 'login' ? 'Signing in…' : 'Creating…';
    try {
      const email = this.container.querySelector('#authEmail').value.trim();
      const password = this.container.querySelector('#authPassword').value;
      if (this.mode === 'login') {
        await auth.login(email, password);
      } else {
        const name = this.container.querySelector('#authName')?.value.trim() || '';
        await auth.register(name, email, password);
      }
      window.location.hash = '#chat';
    } catch (err) {
      errEl.textContent = err.message || 'Authentication failed';
      errEl.style.display = 'block';
    } finally {
      btn.disabled = false;
      btn.textContent = this.mode === 'login' ? 'Sign in' : 'Create account';
    }
  }
}
