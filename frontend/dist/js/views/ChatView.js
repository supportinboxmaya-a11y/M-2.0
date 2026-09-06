// Maya 2.0 ULTRA - Chat View
export class ChatView {
  constructor(app) {
    this.app = app;
    this.container = null;
    this.messages = [];
    this.chatId = null;
    this.streaming = false;
    this.currentAssistantMessage = null;
    this.attachments = [];
  }
  
  show() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'view chat-view';
      this.render();
      this.bindEvents();
      this.loadHistory();
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
      <div class="chat-header">
        <div>
          <h2 class="chat-title">Maya Assistant</h2>
        </div>
        <div class="chat-actions">
          <div class="chat-mode">
            <button class="mode-btn active" data-mode="chat" title="Chat mode">💬</button>
            <button class="mode-btn" data-mode="run" title="Run goal">▶</button>
            <button class="mode-btn" data-mode="think" title="Deep think">🧠</button>
          </div>
          <button class="btn btn-secondary btn-sm" id="newChatBtn" title="New conversation">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            New
          </button>
        </div>
      </div>
      
      <div class="chat-messages" id="chatMessages" role="log" aria-live="polite">
        <div class="welcome-message">
          <div class="message assistant">
            <div class="message-avatar">🧠</div>
            <div class="message-content">
              <div class="message-text">
                <p>Welcome to Maya 2.0 ULTRA! I'm your autonomous AI assistant.</p>
                <p>You can:</p>
                <ul>
                  <li><strong>Chat</strong> - Ask questions, get explanations</li>
                  <li><strong>Run goals</strong> - Execute multi-step tasks with tools</li>
                  <li><strong>Deep think</strong> - Complex reasoning and analysis</li>
                </ul>
                <p>Try asking me to "Create a Python script that..." or "Research the latest..."</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div class="chat-input-area">
        <div class="chat-input-wrapper">
          <textarea 
            class="chat-input" 
            id="chatInput" 
            placeholder="Message Maya... (Shift+Enter for new line)"
            rows="1"
            aria-label="Chat input"
          ></textarea>
          <button class="chat-send-btn" id="chatSendBtn" aria-label="Send message" disabled>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"></polygon></svg>
          </button>
        </div>
        <div class="chat-input-footer">
          <div class="chat-input-hints">
            <span>Enter to send</span>
            <span>Shift+Enter for new line</span>
            <span>⌘/Ctrl+Enter to run goal</span>
          </div>
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    const input = this.container.querySelector('#chatInput');
    const sendBtn = this.container.querySelector('#chatSendBtn');
    const newChatBtn = this.container.querySelector('#newChatBtn');
    const modeBtns = this.container.querySelectorAll('.mode-btn');
    
    // Input handling
    input.addEventListener('input', () => this.handleInputChange());
    input.addEventListener('keydown', (e) => this.handleKeydown(e));
    
    // Send button
    sendBtn.addEventListener('click', () => this.sendMessage());
    
    // New chat
    newChatBtn.addEventListener('click', () => this.newChat());
    
    // Mode buttons
    modeBtns.forEach(btn => {
      btn.addEventListener('click', () => this.setMode(btn.dataset.mode));
    });
    
    // Auto-resize textarea
    input.addEventListener('input', () => {
      input.style.height = 'auto';
      input.style.height = Math.min(input.scrollHeight, 200) + 'px';
    });
  }
  
  handleInputChange() {
    const input = this.container.querySelector('#chatInput');
    const sendBtn = this.container.querySelector('#chatSendBtn');
    const hasText = input.value.trim().length > 0;
    sendBtn.disabled = !hasText || this.streaming;
  }
  
  handleKeydown(e) {
    const input = this.container.querySelector('#chatInput');
    
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      if (!this.streaming && input.value.trim()) {
        this.sendMessage();
      }
    } else if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      this.runGoal(input.value.trim());
    }
  }
  
  setMode(mode) {
    this.container.querySelectorAll('.mode-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.mode === mode);
    });
  }
  
  async sendMessage() {
    const input = this.container.querySelector('#chatInput');
    const message = input.value.trim();
    if (!message || this.streaming) return;

    // Clear input
    input.value = '';
    input.style.height = 'auto';
    this.handleInputChange();

    // Add user message
    this.addMessage('user', message);

    // Stream the reply via POST + Server-Sent Events
    this.streaming = true;
    this.currentAssistantMessage = this.addStreamingMessage();

    try {
      await this.app.api.streamChat(message, {
        chatId: this.chatId,
        onDelta: (delta) => this.appendToStreamingMessage(delta),
        onDone: () => {
          if (!this.currentAssistantMessage?.querySelector('.message-text').textContent.trim()) {
            this.appendToStreamingMessage('(empty response)');
          }
          this.finishStreamingMessage();
        },
        onError: (err) => this.finishStreamingMessage(err.message),
      });
      // If stream ended without an explicit done event, close cleanly
      if (this.streaming) this.finishStreamingMessage();
    } catch (error) {
      this.finishStreamingMessage(error.message);
    }
  }
  
  addMessage(role, content) {
    const messagesContainer = this.container.querySelector('#chatMessages');
    const welcomeMessage = messagesContainer.querySelector('.welcome-message');
    if (welcomeMessage) welcomeMessage.remove();
    
    const messageEl = document.createElement('div');
    messageEl.className = `message ${role}`;
    messageEl.innerHTML = `
      <div class="message-avatar">${role === 'user' ? '👤' : '🧠'}</div>
      <div class="message-content">
        <div class="message-text">${this.formatMessage(content)}</div>
        <div class="message-meta">
          <span>${new Date().toLocaleTimeString()}</span>
        </div>
      </div>
    `;
    
    messagesContainer.appendChild(messageEl);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
    
    this.messages.push({ role, content, timestamp: Date.now() });
    return messageEl;
  }
  
  addStreamingMessage() {
    const messagesContainer = this.container.querySelector('#chatMessages');
    
    const messageEl = document.createElement('div');
    messageEl.className = 'message assistant message-streaming';
    messageEl.innerHTML = `
      <div class="message-avatar">🧠</div>
      <div class="message-content">
        <div class="message-text"></div>
      </div>
    `;
    
    messagesContainer.appendChild(messageEl);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
    return messageEl;
  }
  
  appendToStreamingMessage(delta) {
    if (!this.currentAssistantMessage) return;
    const textEl = this.currentAssistantMessage.querySelector('.message-text');
    textEl.textContent += delta;
    this.scrollToBottom();
  }
  
  finishStreamingMessage(error = null) {
    this.streaming = false;
    this.app.sse.disconnect();
    
    if (this.currentAssistantMessage) {
      this.currentAssistantMessage.classList.remove('message-streaming');
      
      if (error) {
        this.currentAssistantMessage.querySelector('.message-text').innerHTML = 
          `<span style="color: var(--error);">Error: ${error}</span>`;
      }
      
      // Add meta
      const contentEl = this.currentAssistantMessage.querySelector('.message-content');
      const metaEl = document.createElement('div');
      metaEl.className = 'message-meta';
      metaEl.innerHTML = `<span>${new Date().toLocaleTimeString()}</span>`;
      contentEl.appendChild(metaEl);
      
      this.currentAssistantMessage = null;
    }
    
    this.handleInputChange();
  }
  
  async runGoal(goal) {
    if (!goal) return;

    this.addMessage('user', goal);

    try {
      const task = await this.app.api.runAgent(goal);
      this.app.toast.success('Goal started', `Task ${task.id.slice(0, 8)}`);

      // Switch to tasks view to watch live execution
      window.location.hash = '#tasks';
    } catch (error) {
      this.app.toast.error('Failed to start goal', error.message);
    }
  }
  
  newChat() {
    this.chatId = null;
    this.messages = [];
    
    const messagesContainer = this.container.querySelector('#chatMessages');
    messagesContainer.innerHTML = `
      <div class="welcome-message">
        <div class="message assistant">
          <div class="message-avatar">🧠</div>
          <div class="message-content">
            <div class="message-text">
              <p>New conversation started. How can I help you?</p>
            </div>
          </div>
        </div>
      </div>
    `;
    
    toast.info('New conversation started');
  }
  
  async loadHistory() {
    // Load recent chats if chatId exists
  }
  
  formatMessage(content) {
    // Simple markdown-like formatting
    return content
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\n/g, '<br>');
  }
  
  scrollToBottom() {
    const messagesContainer = this.container.querySelector('#chatMessages');
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }
  
  onTaskEvent(type, data) {
    // Handle task events from WebSocket
  }
  
  destroy() {
    this.app.sse.disconnect();
  }
}