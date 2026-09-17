// Maya 2.0 ULTRA - Authentication Manager
import { api } from './api.js';

const TOKEN_KEY = 'maya_token';
const USER_KEY = 'maya_user';
const REFRESH_INTERVAL = 5 * 60 * 1000; // 5 minutes

class AuthManager {
  constructor() {
    this.user = null;
    this.refreshTimer = null;
    this.listeners = new Set();
  }
  
  init() {
    const token = localStorage.getItem(TOKEN_KEY);
    const userStr = localStorage.getItem(USER_KEY);
    
    if (token && userStr) {
      this.token = token;
      this.user = JSON.parse(userStr);
      api.setToken(token);
      this.startRefreshTimer();
      return true;
    }
    return false;
  }
  
  async login(email, password) {
    const response = await api.login(email, password);
    this.setAuth(response.access_token, {
      email: response.email,
      role: response.role
    });
    return response;
  }
  
  async register(name, email, password) {
    const response = await api.register(name, email, password);
    this.setAuth(response.access_token, {
      email: response.email,
      role: response.role
    });
    return response;
  }
  
  async logout() {
    try {
      await api.logout();
    } catch {
      // Ignore
    }
    this.clearAuth();
    window.location.hash = '#login';
  }
  
  setAuth(token, user) {
    this.token = token;
    this.user = user;
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    api.setToken(token);
    this.startRefreshTimer();
    this.notifyListeners('login', user);
  }
  
  clearAuth() {
    this.token = null;
    this.user = null;
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    api.clearToken();
    this.stopRefreshTimer();
    this.notifyListeners('logout');
  }
  
  async refreshUser() {
    try {
      const user = await api.getMe();
      this.user = { ...this.user, ...user };
      localStorage.setItem(USER_KEY, JSON.stringify(this.user));
      this.notifyListeners('userUpdated', this.user);
      return this.user;
    } catch (error) {
      console.error('Failed to refresh user:', error);
      return null;
    }
  }
  
  startRefreshTimer() {
    this.stopRefreshTimer();
    this.refreshTimer = setInterval(() => {
      this.refreshUser();
    }, REFRESH_INTERVAL);
  }
  
  stopRefreshTimer() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = null;
    }
  }
  
  isAuthenticated() {
    return !!this.token;
  }
  
  isAdmin() {
    return this.user?.role === 'admin';
  }
  
  getUser() {
    return this.user;
  }
  
  getToken() {
    return this.token;
  }
  
  hasPermission(permission) {
    if (!this.user) return false;
    if (this.user.role === 'admin') return true;
    if (permission === 'view') return true;
    if (permission === 'execute') return this.user.role === 'developer';
    return false;
  }
  
  subscribe(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }
  
  notifyListeners(event, data) {
    for (const listener of this.listeners) {
      try {
        listener(event, data);
      } catch (error) {
        console.error('Auth listener error:', error);
      }
    }
  }
}

export const auth = new AuthManager();

// Listen for auth expiration
window.addEventListener('auth:expired', () => {
  auth.clearAuth();
  window.location.hash = '#login';
});