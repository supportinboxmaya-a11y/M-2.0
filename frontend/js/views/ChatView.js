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
    // Restore chat history sidebar state
    this.restoreSidebarState();
  }
  
  hide() {
    if (this.container && this.container.parentNode) {
      this.container.parentNode.removeChild(this.container);
    }
  }
  
render() {
    this.container.innerHTML = `
      <div class="chat-layout">
        <!-- Chat History Sidebar -->
        <aside class="chat-history-sidebar" id="chatHistorySidebar">
          <div class="sidebar-header">
            <h3>Chats</h3>
            <button class="btn btn-primary btn-sm" id="newChatSidebarBtn" title="New conversation">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
              New Chat
            </button>
          </div>
          <div class="sidebar-search">
            <input type="text" id="chatSearchInput" placeholder="Search chats..." aria-label="Search chats">
          </div>
          <div class="sidebar-chats" id="sidebarChats">
            <div class="no-chats">No previous conversations</div>
          </div>
        </aside>
        
        <!-- Main Chat Area -->
        <div class="chat-main">
          <div class="chat-header">
            <div>
              <h2 class="chat-title">Maya Assistant</h2>
              <div class="chat-status">
                <span class="token-counter" id="tokenCounter" title="Estimated tokens">~0 tokens</span>
              </div>
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
        </div>
      </div>
    `;
  }
  
  bindEvents() {
    const input = this.container.querySelector('#chatInput');
    const sendBtn = this.container.querySelector('#chatSendBtn');
    const newChatBtn = this.container.querySelector('#newChatBtn');
    const newChatSidebarBtn = this.container.querySelector('#newChatSidebarBtn');
    const modeBtns = this.container.querySelectorAll('.mode-btn');
    const searchInput = this.container.querySelector('#chatSearchInput');
    
    // Input handling
    input.addEventListener('input', () => this.handleInputChange());
    input.addEventListener('keydown', (e) => this.handleKeydown(e));
    
    // Send button
    sendBtn.addEventListener('click', () => this.sendMessage());
    
    // New chat buttons
    newChatBtn.addEventListener('click', () => this.newChat());
    if (newChatSidebarBtn) {
      newChatSidebarBtn.addEventListener('click', () => this.newChat());
    }
    
    // Mode buttons
    modeBtns.forEach(btn => {
      btn.addEventListener('click', () => this.setMode(btn.dataset.mode));
    });
    
    // Search input
    if (searchInput) {
      searchInput.addEventListener('input', (e) => this.filterChats(e.target.value));
    }
    
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
    this.saveChat();

    // Stream the reply via POST + Server-Sent Events
    this.streaming = true;
    this.currentAssistantMessage = this.addStreamingMessage();
    this.abortController = new AbortController();

    try {
      await this.app.api.streamChat(message, {
        chatId: this.chatId,
        signal: this.abortController.signal,
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
    
    // Add message actions
    this.addMessageActions(messageEl, role);
    
    // Update token counter
    this.updateTokenCounter();
    
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
        <div class="message-actions">
          <button class="msg-action-btn stop-btn" title="Stop generating" aria-label="Stop generating">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect></svg>
          </button>
        </div>
      </div>
    `;
    
    messagesContainer.appendChild(messageEl);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
    
    // Bind stop button
    const stopBtn = messageEl.querySelector('.stop-btn');
    if (stopBtn) {
      stopBtn.addEventListener('click', () => this.stopStreaming());
    }
    
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
    this.abortController = null;
    this.app.sse.disconnect();
    
    if (this.currentAssistantMessage) {
      this.currentAssistantMessage.classList.remove('message-streaming');
      
      // Remove stop button
      const stopBtn = this.currentAssistantMessage.querySelector('.stop-btn');
      if (stopBtn) stopBtn.remove();
      
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
      
      // Add message actions
      this.addMessageActions(this.currentAssistantMessage, 'assistant');
      
      this.currentAssistantMessage = null;
    }
    
    // Save chat after assistant response
    this.saveChat();
    
    this.handleInputChange();
  }

  stopStreaming() {
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }
    this.finishStreamingMessage('Stopped by user');
  }

  addMessageActions(messageEl, role) {
    const contentEl = messageEl.querySelector('.message-content');
    const actionsEl = document.createElement('div');
    actionsEl.className = 'message-actions';
    
    // Copy button
    const copyBtn = document.createElement('button');
    copyBtn.className = 'msg-action-btn';
    copyBtn.title = 'Copy message';
    copyBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>`;
    copyBtn.addEventListener('click', () => {
      const text = messageEl.querySelector('.message-text').textContent;
      navigator.clipboard.writeText(text).then(() => {
        this.app.toast.success('Copied to clipboard');
      });
    });
    actionsEl.appendChild(copyBtn);

    if (role === 'user') {
      // Edit button
      const editBtn = document.createElement('button');
      editBtn.className = 'msg-action-btn';
      editBtn.title = 'Edit message';
      editBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5a2.121 2.121 0 0 1 3 3z"></path></svg>`;
      editBtn.addEventListener('click', () => this.editMessage(messageEl));
      actionsEl.appendChild(editBtn);

      // Regenerate button
      const regenBtn = document.createElement('button');
      regenBtn.className = 'msg-action-btn';
      regenBtn.title = 'Regenerate response';
      regenBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg>`;
      regenBtn.addEventListener('click', () => this.regenerateResponse(messageEl));
      actionsEl.appendChild(regenBtn);

      // Delete button
      const deleteBtn = document.createElement('button');
      deleteBtn.className = 'msg-action-btn';
      deleteBtn.title = 'Delete message';
      deleteBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>`;
      deleteBtn.addEventListener('click', () => this.deleteMessage(messageEl));
      actionsEl.appendChild(deleteBtn);
    } else {
      // Regenerate button for assistant
      const regenBtn = document.createElement('button');
      regenBtn.className = 'msg-action-btn';
      regenBtn.title = 'Regenerate response';
      regenBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path></svg>`;
      regenBtn.addEventListener('click', () => this.regenerateResponse(messageEl));
      actionsEl.appendChild(regenBtn);
    }

    // Insert actions after message-meta
    const metaEl = contentEl.querySelector('.message-meta');
    if (metaEl) {
      metaEl.after(actionsEl);
    } else {
      contentEl.appendChild(actionsEl);
    }
  }
  
  stopStreaming() {
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }
    this.finishStreamingMessage('Stopped by user');
  }

  editMessage(messageEl) {
    const textEl = messageEl.querySelector('.message-text');
    const originalText = textEl.textContent;
    
    // Replace with textarea
    const textarea = document.createElement('textarea');
    textarea.className = 'edit-textarea';
    textarea.value = originalText;
    textarea.rows = 3;
    textEl.replaceWith(textarea);
    textarea.focus();
    
    // Replace actions with save/cancel
    const actionsEl = messageEl.querySelector('.message-actions');
    if (actionsEl) {
      actionsEl.innerHTML = '';
      const saveBtn = document.createElement('button');
      saveBtn.className = 'msg-action-btn save-btn';
      saveBtn.title = 'Save';
      saveBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path><polyline points="17 21 17 13 7 13 7 21"></polyline></svg>`;
      saveBtn.addEventListener('click', () => this.saveEditedMessage(messageEl, originalText));
      actionsEl.appendChild(saveBtn);
      
      const cancelBtn = document.createElement('button');
      cancelBtn.className = 'msg-action-btn cancel-btn';
      cancelBtn.title = 'Cancel';
      cancelBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></svg>`;
      cancelBtn.addEventListener('click', () => this.cancelEditMessage(messageEl, originalText));
      actionsEl.appendChild(cancelBtn);
    }
  }

  saveEditedMessage(messageEl, originalText) {
    const textarea = messageEl.querySelector('.edit-textarea');
    const newText = textarea.value.trim();
    
    if (!newText || newText === originalText) {
      this.cancelEditMessage(messageEl, originalText);
      return;
    }
    
    // Update the message in the messages array
    const msgIndex = this.messages.findIndex(m => m.content === originalText && m.role === 'user');
    if (msgIndex !== -1) {
      this.messages[msgIndex].content = newText;
    }
    
    // Update the DOM
    const textEl = document.createElement('div');
    textEl.className = 'message-text';
    textEl.innerHTML = this.formatMessage(newText);
    textarea.replaceWith(textEl);
    
    // Restore actions
    const actionsEl = messageEl.querySelector('.message-actions');
    if (actionsEl) {
      actionsEl.innerHTML = '';
      this.addMessageActions(messageEl, 'user');
    }
    
    // Re-send the edited message to get new response
    if (newText !== originalText) {
      this.regenerateResponse(messageEl);
    }
  }

  cancelEditMessage(messageEl, originalText) {
    const textarea = messageEl.querySelector('.edit-textarea');
    const textEl = document.createElement('div');
    textEl.className = 'message-text';
    textEl.innerHTML = this.formatMessage(originalText);
    textarea.replaceWith(textEl);
    
    // Restore actions
    const actionsEl = messageEl.querySelector('.message-actions');
    if (actionsEl) {
      actionsEl.innerHTML = '';
      this.addMessageActions(messageEl, 'user');
    }
  }

  regenerateResponse(messageEl) {
    // Find the user message that precedes this assistant message
    const messagesContainer = this.container.querySelector('#chatMessages');
    const messages = Array.from(messagesContainer.querySelectorAll('.message'));
    const msgIndex = messages.indexOf(messageEl);
    
    let userMessageEl = null;
    for (let i = msgIndex - 1; i >= 0; i--) {
      if (messages[i].classList.contains('user')) {
        userMessageEl = messages[i];
        break;
      }
    }
    
    if (!userMessageEl) return;
    
    const userText = userMessageEl.querySelector('.message-text').textContent;
    
    // Remove all messages after the user message
    const messagesAfter = messages.slice(messages.indexOf(userMessageEl) + 1);
    messagesAfter.forEach(el => el.remove());
    
    // Re-send the user message
    this.sendMessage = this.sendMessage.bind(this);
    this.sendMessage(userText);
  }

  deleteMessage(messageEl) {
    // Find the message in the messages array
    const text = messageEl.querySelector('.message-text').textContent;
    const role = messageEl.classList.contains('user') ? 'user' : 'assistant';
    
    const msgIndex = this.messages.findIndex(m => m.content === text && m.role === role);
    if (msgIndex !== -1) {
      this.messages.splice(msgIndex, 1);
    }
    
    // If deleting a user message, also delete the next assistant message
    if (role === 'user') {
      const messagesContainer = this.container.querySelector('#chatMessages');
      const messages = Array.from(messagesContainer.querySelectorAll('.message'));
      const msgIndex = messages.indexOf(messageEl);
      if (msgIndex + 1 < messages.length && messages[msgIndex + 1].classList.contains('assistant')) {
        const nextMsg = messages[msgIndex + 1];
        const nextText = nextMsg.querySelector('.message-text').textContent;
        const nextMsgIndex = this.messages.findIndex(m => m.content === nextText && m.role === 'assistant');
        if (nextMsgIndex !== -1) {
          this.messages.splice(nextMsgIndex, 1);
        }
        nextMsg.remove();
      }
    }
    
    messageEl.remove();
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
    
    // Update token counter for new empty chat
    this.updateTokenCounter();
    
    toast.info('New conversation started');
  }
  
async loadHistory() {
    // Load recent chats if chatId exists
    this.loadChats();
  }

  // Chat history sidebar methods
  saveChat() {
    if (!this.messages.length) return;
    
    const chat = {
      id: this.chatId || Date.now().toString(),
      title: this.messages[0]?.content?.slice(0, 50) || 'New Chat',
      messages: this.messages,
      timestamp: Date.now()
    };
    
    let chats = JSON.parse(localStorage.getItem('maya_chats') || '[]');
    const existingIndex = chats.findIndex(c => c.id === chat.id);
    if (existingIndex >= 0) {
      chats[existingIndex] = chat;
    } else {
      chats.unshift(chat);
    }
    // Keep only last 50 chats
    chats = chats.slice(0, 50);
    localStorage.setItem('maya_chats', JSON.stringify(chats));
    
    this.chatId = chat.id;
    this.renderChats();
  }

  loadChats() {
    const chats = JSON.parse(localStorage.getItem('maya_chats') || '[]');
    this.renderChats(chats);
  }

  renderChats(chats = null) {
    const sidebarChats = this.container.querySelector('#sidebarChats');
    if (!sidebarChats) return;
    
    const chatsToRender = chats || JSON.parse(localStorage.getItem('maya_chats') || '[]');
    
    if (!chatsToRender.length) {
      sidebarChats.innerHTML = '<div class="no-chats">No previous conversations</div>';
      return;
    }
    
    sidebarChats.innerHTML = chatsToRender.map(chat => `
      <div class="chat-history-item" data-chat-id="${chat.id}">
        <div class="chat-item-title">${this.escapeHtml(chat.title)}</div>
        <div class="chat-item-time">${new Date(chat.timestamp).toLocaleDateString()}</div>
      </div>
    `).join('');
    
    // Bind click events
    sidebarChats.querySelectorAll('.chat-history-item').forEach(item => {
      item.addEventListener('click', () => this.loadChat(item.dataset.chatId));
    });
  }

  filterChats(query) {
    const items = this.container.querySelectorAll('.chat-history-item');
    const lowerQuery = query.toLowerCase();
    items.forEach(item => {
      const title = item.querySelector('.chat-item-title').textContent.toLowerCase();
      item.style.display = title.includes(lowerQuery) ? '' : 'none';
    });
  }

  loadChat(chatId) {
    const chats = JSON.parse(localStorage.getItem('maya_chats') || '[]');
    const chat = chats.find(c => c.id === chatId);
    if (!chat) return;
    
    this.chatId = chat.id;
    this.messages = chat.messages || [];
    
    // Update sidebar active state
    this.container.querySelectorAll('.chat-history-item').forEach(item => {
      item.classList.toggle('active', item.dataset.chatId === chatId);
    });
    
    // Render messages
    const messagesContainer = this.container.querySelector('#chatMessages');
    messagesContainer.innerHTML = '';
    
    if (this.messages.length === 0) {
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
        `;
      return;
    }
    
    this.messages.forEach(msg => {
      this.addMessage(msg.role, msg.content);
    });
    
    // Update sidebar active state
    this.container.querySelectorAll('.chat-history-item').forEach(item => {
      item.classList.toggle('active', item.dataset.chatId === chatId);
    });
    
    // Update token counter
    this.updateTokenCounter();
  }

  restoreSidebarState() {
    if (this.chatId) {
      this.container.querySelectorAll('.chat-history-item').forEach(item => {
        item.classList.toggle('active', item.dataset.chatId === this.chatId);
      });
    }
  }

  formatMessage(content) {
    // Enhanced markdown-like formatting
    return content
      // Code blocks
      .replace(/```(\w*)\n([\s\S]*?)```/g, '<pre><code class="language-$1">$2</code></pre>')
      // Inline code
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      // Bold
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      // Italic
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      // Links
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>')
      // Newlines
      .replace(/\n/g, '<br>');
  }
  
  scrollToBottom() {
    const messagesContainer = this.container.querySelector('#chatMessages');
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  updateTokenCounter() {
    const counter = this.container.querySelector('#tokenCounter');
    if (!counter) return;
    
    // Estimate tokens: ~1 token per 4 characters for English text
    const totalChars = this.messages.reduce((sum, msg) => sum + (msg.content?.length || 0), 0);
    const estimatedTokens = Math.ceil(totalChars / 4);
    counter.textContent = `~${estimatedTokens.toLocaleString()} tokens`;
  }
  
  onTaskEvent(type, data) {
    // Handle task events from WebSocket
  }
  
  destroy() {
    this.app.sse.disconnect();
  }
}