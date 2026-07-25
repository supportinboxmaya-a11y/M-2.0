/**
 * Maya 2.0 — Chat Workspace
 *
 * Full conversation UI with streaming, markdown, code highlighting,
 * message actions, voice, camera, file upload, slash commands.
 */
(function () {
  'use strict';

  const L = () => window.MayaLayout;
  const ESC = (s) => { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; };

  /* ── State ── */
  let _conversations = [];
  let _activeConvId = null;
  let _abortController = null;
  let _multiSelect = false;
  let _selectedMessages = [];
  let _attachments = [];
  let _recentUploads = [];
  let _isStreaming = false;
  let _lastUserMsg = '';

  /* ── Register screen ── */
  MayaRouter.registerScreen('chat', function () {
    L().showLoading('Loading chats...');
    loadConversations();
  });

  /* ── Conversations (localStorage) ── */
  function loadConversations() {
    try { _conversations = JSON.parse(localStorage.getItem('maya_conversations') || '[]'); } catch { _conversations = []; }
    if (_conversations.length === 0) {
      const id = generateId();
      _conversations.push({ id, title: 'New Chat', messages: [], pinned: false, archived: false, created: Date.now(), updated: Date.now() });
      saveConversations();
      _activeConvId = id;
    } else {
      _activeConvId = _conversations[0].id;
    }
    renderChat();
  }

  function saveConversations() { localStorage.setItem('maya_conversations', JSON.stringify(_conversations)); }
  function getConv(id) { return _conversations.find(c => c.id === id); }
  function generateId() { return Date.now().toString(36) + Math.random().toString(36).slice(2, 6); }

  /* ── Render chat ── */
  function renderChat() {
    const conv = getConv(_activeConvId);
    if (!conv) return;
    const wc = document.getElementById('workspaceContent');
    if (wc) wc.classList.add('chat-mode');

    let html = `<div style="display:flex;flex-direction:column;height:100%;max-width:100%;margin:0">`;

    // Header
    html += `<div style="display:flex;align-items:center;gap:var(--space-1);padding:var(--space-1) var(--space-2);border-bottom:1px solid var(--border-secondary);flex-shrink:0;min-height:36px">
      <button class="btn btn-ghost btn-sm" onclick="MayaScreens.chat.toggleHistory()" title="Conversations" style="font-size:18px;padding:2px 6px;min-height:28px">☰</button>
      <span style="font-size:var(--font-size-sm);font-weight:var(--font-weight-medium);flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" id="chatTitle">${ESC(conv.title)}</span>
      <button class="action-btn" onclick="MayaScreens.chat.newChat()" title="New chat">➕</button>
      <button class="action-btn" onclick="MayaScreens.chat.renameConv()" title="Rename">✏️</button>
      <button class="action-btn" onclick="MayaScreens.chat.toggleMultiSelect()" title="Select">☑️</button>
      <button class="action-btn" onclick="MayaScreens.chat.exportMenu()" title="Export">📤</button>
    </div>
    <div style="display:flex;gap:var(--space-1);padding:2px var(--space-2);border-bottom:1px solid var(--border-secondary);overflow-x:auto;flex-shrink:0;scrollbar-width:none">
      <button class="btn btn-ghost btn-sm" onclick="window.MayaRouter.navigate('research')" style="font-size:var(--font-size-xs);padding:2px 6px;white-space:nowrap">🔬 Research</button>
      <button class="btn btn-ghost btn-sm" onclick="window.MayaRouter.navigate('agents')" style="font-size:var(--font-size-xs);padding:2px 6px;white-space:nowrap">🤖 Agents</button>
      <button class="btn btn-ghost btn-sm" onclick="window.MayaRouter.navigate('business')" style="font-size:var(--font-size-xs);padding:2px 6px;white-space:nowrap">💼 Business</button>
      <button class="btn btn-ghost btn-sm" onclick="window.MayaRouter.navigate('files')" style="font-size:var(--font-size-xs);padding:2px 6px;white-space:nowrap">📁 Files</button>
      <button class="btn btn-ghost btn-sm" onclick="window.MayaRouter.navigate('automation')" style="font-size:var(--font-size-xs);padding:2px 6px;white-space:nowrap">⚡ Auto</button>
      <button class="btn btn-ghost btn-sm" onclick="window.MayaRouter.navigate('coding')" style="font-size:var(--font-size-xs);padding:2px 6px;white-space:nowrap">💻 Tools</button>
    </div>`;

    // Messages
    html += `<div class="chat-messages-wrap" id="chatMessages">`;
    if (conv.messages.length === 0) {
      html += `<div class="empty-state" style="padding-top:10vh">
        <div class="icon">💬</div>
        <div class="title">Start a conversation</div>
        <div class="desc">Type <strong>/</strong> for commands. Voice, camera, and file upload supported.</div>
      </div>`;
    } else {
      conv.messages.forEach((msg, idx) => { html += renderMessage(msg, idx); });
    }
    html += `</div>`;

    // Jump to latest button
    html += `<button id="jumpToBottom" onclick="scrollToBottom()" style="display:none;position:sticky;bottom:0;left:50%;transform:translateX(-50%);z-index:5;background:var(--bg-surface);border:1px solid var(--border-primary);border-radius:var(--radius-full);padding:4px 12px;font-size:var(--font-size-xs);color:var(--text-secondary);cursor:pointer;margin-bottom:2px">↓ Latest</button>`;

    // Multi-select bar
    if (_multiSelect) {
      html += `<div class="action-bar fade-in">
        <span class="count">${_selectedMessages.length} selected</span>
        <button class="btn btn-sm btn-ghost" onclick="MayaScreens.chat.batchCopy()">📋 Copy</button>
        <button class="btn btn-sm btn-ghost" onclick="MayaScreens.chat.batchExport()">📤 Export</button>
        <button class="btn btn-sm btn-danger" onclick="MayaScreens.chat.batchDelete()">🗑 Delete</button>
        <button class="btn btn-sm btn-ghost" onclick="MayaScreens.chat.toggleMultiSelect()">Cancel</button>
      </div>`;
    }

    // Attachment previews
    if (_attachments.length > 0) {
      html += `<div style="display:flex;gap:var(--space-1);padding:var(--space-1) var(--space-2);overflow-x:auto;flex-shrink:0;background:var(--bg-secondary);border-top:1px solid var(--border-secondary)">`;
      _attachments.forEach(function (a, i) {
        html += `<div style="display:flex;align-items:center;gap:var(--space-1);background:var(--bg-primary);border:1px solid var(--border-primary);border-radius:var(--radius-md);padding:2px var(--space-2);font-size:var(--font-size-xs);flex-shrink:0;max-width:180px">
          <span style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${a.type === 'image' ? '🖼' : '📎'} ${ESC(a.name)}</span>
          <button class="action-btn" onclick="MayaScreens.chat.removeAttachment(${i})" style="width:18px;height:18px;font-size:12px">✕</button>
        </div>`;
      });
      html += `</div>`;
    }

    // Input bar — AI Composer
    html += `<div class="chat-input-bar" style="flex-shrink:0">
      <div style="display:flex;align-items:flex-end;gap:var(--space-1);width:100%">
        <div style="display:flex;gap:1px;flex-shrink:0">
          <button class="action-btn" onclick="MayaScreens.chat.voiceInput()" title="Voice input">🎤</button>
          <button class="action-btn" onclick="MayaScreens.chat.cameraInput()" title="Camera">📷</button>
          <button class="action-btn" onclick="MayaScreens.chat.fileInput()" title="Attach file">📎</button>
        </div>
        <textarea id="chatInput" rows="1" placeholder="Type / for commands..." aria-label="Chat input" style="flex:1;resize:none;border-radius:var(--radius-lg);padding:var(--space-2) var(--space-3);font-size:var(--font-size-base);line-height:1.4;min-height:40px;max-height:120px;background:var(--bg-primary);border:1px solid var(--border-primary);color:var(--text-primary);outline:none;font-family:var(--font-sans)"></textarea>
        <button class="btn btn-primary" onclick="MayaScreens.chat.sendMessage()" title="Send" id="chatSendBtn" style="min-height:40px;width:40px;padding:0;border-radius:var(--radius-lg);flex-shrink:0">📤</button>
      </div>
      <div style="display:flex;align-items:center;gap:var(--space-2);padding:var(--space-1) 0 0 0;width:100%">
        <span style="font-size:var(--font-size-xs);color:var(--text-tertiary);flex-shrink:0">🤖 ${getCurrentModel()}</span>
        <span id="slashHint" style="font-size:var(--font-size-xs);color:var(--text-tertiary);flex:1"></span>
        <span style="font-size:var(--font-size-xs);color:var(--text-tertiary)" id="charCounter"></span>
      </div>
    </div>`;

    html += `</div>`;

    // Store _lastUserMsg for continue/regenerate
    const lastMsg = conv.messages[conv.messages.length - 1];
    if (lastMsg && lastMsg.role === 'user') _lastUserMsg = lastMsg.content;

    L().render(html);
    L().setTitle('Chat');

    // Event listeners
    const input = document.getElementById('chatInput');
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSlashCommand(this.value.trim()) || sendMessage();
      }
    });
    input.addEventListener('input', function () {
      this.style.height = 'auto';
      this.style.height = Math.min(this.scrollHeight, 120) + 'px';
      const counter = document.getElementById('charCounter');
      if (counter) { const l = this.value.length; counter.textContent = l > 0 ? l + ' chars' : ''; }
      showSlashHint(this.value);
    });
    input.addEventListener('paste', function (e) {
      const items = (e.clipboardData || e.originalEvent.clipboardData).items;
      for (let i = 0; i < items.length; i++) {
        if (items[i].type.indexOf('image') !== -1) {
          e.preventDefault();
          const file = items[i].getAsFile();
          if (file) { addAttachment(file); L().toast('Image pasted: ' + file.name, 'success'); }
          return;
        }
      }
    });

    // Scroll listener for jump-to-bottom button
    const msgEl = document.getElementById('chatMessages');
    if (msgEl) {
      msgEl.addEventListener('scroll', function () {
        const btn = document.getElementById('jumpToBottom');
        if (!btn) return;
        const threshold = 200;
        btn.style.display = (this.scrollHeight - this.scrollTop - this.clientHeight > threshold) ? 'block' : 'none';
      });
    }

    scrollToBottom();
    setTimeout(() => input.focus(), 100);
  }

  /* ── Slash commands ── */
  function handleSlashCommand(text) {
    if (!text.startsWith('/')) return false;
    const parts = text.split(' ');
    const cmd = parts[0].toLowerCase();
    const args = parts.slice(1).join(' ');

    if (cmd === '/research') { window.MayaRouter.navigate('research'); return true; }
    if (cmd === '/agent' || cmd === '/agents') { window.MayaRouter.navigate('agents'); return true; }
    if (cmd === '/code' || cmd === '/coding') { window.MayaRouter.navigate('coding'); return true; }
    if (cmd === '/files') { window.MayaRouter.navigate('files'); return true; }
    if (cmd === '/business' || cmd === '/biz') { window.MayaRouter.navigate('business'); return true; }
    if (cmd === '/docs' || cmd === '/documents') { window.MayaRouter.navigate('documents'); return true; }
    if (cmd === '/automation' || cmd === '/auto') { window.MayaRouter.navigate('automation'); return true; }
    if (cmd === '/analytics') { window.MayaRouter.navigate('analytics'); return true; }
    if (cmd === '/admin') { window.MayaRouter.navigate('admin'); return true; }
    if (cmd === '/new') { newChat(); return true; }
    if (cmd === '/clear') { _attachments = []; renderChat(); return true; }
    if (cmd === '/help') {
      L().openModal(`<h2>Slash Commands</h2>
        <div style="font-size:var(--font-size-sm);line-height:2">
          <code>/research</code> — Open Research<br>
          <code>/agent</code> — Open Agents<br>
          <code>/code</code> — Open Coding<br>
          <code>/files</code> — Open Files<br>
          <code>/business</code> — Open Business<br>
          <code>/docs</code> — Open Documents<br>
          <code>/automation</code> — Open Automation<br>
          <code>/analytics</code> — Open Analytics<br>
          <code>/admin</code> — Open Admin<br>
          <code>/new</code> — New conversation<br>
          <code>/clear</code> — Clear attachments
        </div>
        <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`);
      return true;
    }
    return false;
  }

  function showSlashHint(text) {
    const hint = document.getElementById('slashHint');
    if (!hint) return;
    if (text === '/') { hint.textContent = 'Commands: /research, /agent, /code, /files, /business, /docs, /automation, /analytics, /admin, /new, /clear, /help'; }
    else if (text.startsWith('/')) { hint.textContent = ''; }
    else { hint.textContent = ''; }
  }

  function getCurrentModel() {
    const sel = document.getElementById('modelSelector');
    return sel ? sel.value : 'Claude 5';
  }

  /* ── Render message ── */
  function renderMessage(msg, idx) {
    const role = msg.role;
    const isUser = role === 'user';
    const isSelected = _selectedMessages.includes(idx);
    const hasFiles = msg.attachments && msg.attachments.length > 0;

    let html = `<div class="msg-group fade-in" data-idx="${idx}">`;
    if (_multiSelect) {
      html += `<label style="display:flex;align-items:flex-start;gap:var(--space-2);padding:var(--space-1) 0">
        <input type="checkbox" ${isSelected ? 'checked' : ''} onchange="MayaScreens.chat.toggleSelect(${idx})" style="margin-top:8px;width:16px;height:16px">
        <div style="flex:1">`;
    }

    html += `<div class="msg-bubble ${isUser ? 'msg-user' : 'msg-assistant'}" style="${_multiSelect ? 'max-width:100%' : ''}">
      <div class="msg-role">
        <span>${isUser ? 'You' : 'Maya'}</span>
        <span style="flex:1"></span>
        ${msg.time ? `<span class="msg-time">${msg.time}</span>` : ''}
        ${msg.status === 'streaming' ? '<span class="tag tag-running" style="margin-left:4px">⏳ Streaming</span>' : ''}
        ${msg.pinned ? '<span style="margin-left:4px">📌</span>' : ''}
      </div>`;

    // Attachments in message
    if (hasFiles) {
      msg.attachments.forEach(function (a) {
        if (a.type === 'image') {
          html += `<div style="margin:var(--space-1) 0"><img src="${ESC(a.dataUrl)}" alt="${ESC(a.name)}" style="max-width:200px;max-height:200px;border-radius:var(--radius-md);border:1px solid var(--border-primary);cursor:pointer" onclick="MayaScreens.chat.previewImage('${ESC(a.dataUrl)}')"></div>`;
        } else {
          html += `<div class="file-card"><span class="icon">📎</span><div class="info"><div class="name">${ESC(a.name)}</div><div class="size">${a.size ? (a.size/1024).toFixed(1)+' KB' : ''}</div></div></div>`;
        }
      });
    }

    // Content with inline editor or rendered content
    if (msg.editing) {
      html += `<div style="margin:var(--space-1) 0">
        <textarea id="editInput_${idx}" class="textarea" rows="2" style="min-height:60px;font-size:var(--font-size-sm)">${ESC(msg.content)}</textarea>
        <div style="display:flex;gap:var(--space-1);margin-top:var(--space-1)">
          <button class="btn btn-sm btn-primary" onclick="MayaScreens.chat.saveEdit(${idx})">Save</button>
          <button class="btn btn-sm btn-ghost" onclick="MayaScreens.chat.cancelEdit(${idx})">Cancel</button>
        </div>
      </div>`;
    } else {
      html += `<div>${renderContent(msg.content)}</div>`;
    }

    if (msg.status === 'streaming') {
      html += `<div style="margin-top:var(--space-2);display:flex;gap:var(--space-1)"><button class="btn btn-sm btn-danger" onclick="MayaScreens.chat.stopGeneration()">⏹ Stop</button></div>`;
    }
    if (msg.status !== 'streaming') {
      html += `<div class="msg-actions visible">`;
      html += `<button class="action-btn" onclick="MayaScreens.chat.copyMessage(${idx})" title="Copy">📋</button>`;
      if (!isUser) {
        html += `<button class="action-btn" onclick="MayaScreens.chat.retryMessage(${idx})" title="Retry">↻</button>`;
        html += `<button class="action-btn" onclick="MayaScreens.chat.regenerateMessage(${idx})" title="Regenerate">🔄</button>`;
        html += `<button class="action-btn" onclick="MayaScreens.chat.continueMessage(${idx})" title="Continue">▶▶</button>`;
      }
      if (isUser) {
        html += `<button class="action-btn" onclick="MayaScreens.chat.editMessageInline(${idx})" title="Edit">✏️</button>`;
      }
      html += `<button class="action-btn" onclick="MayaScreens.chat.deleteMessage(${idx})" title="Delete">🗑</button>`;
      html += `<button class="action-btn" onclick="MayaScreens.chat.pinMessage(${idx})" title="Pin">📌</button>`;
      html += `<button class="action-btn" onclick="MayaScreens.chat.shareMessage(${idx})" title="Share">📤</button>`;
      html += `</div>`;
    }

    html += `</div>`;
    if (_multiSelect) { html += `</div></label>`; }
    html += `</div>`;
    return html;
  }

  /* ── Markdown renderer ── */
  function renderContent(content) {
    if (!content) return '';
    let text = ESC(content);

    // Code blocks with copy button
    text = text.replace(/```(\w*)\n?([\s\S]*?)```/g, function (_, lang, code) {
      var trimmed = ESC(code.trim());
      return '<div style="position:relative;margin:8px 0"><button class="action-btn" onclick="MayaHardware.clipboard.copy(document.querySelector(this.nextElementSibling).textContent);L().toast(\'Copied\',\'success\')" style="position:absolute;top:4px;right:4px;z-index:1;background:var(--bg-tertiary);width:24px;height:24px;font-size:12px;border-radius:var(--radius-sm)">📋</button><pre><code>' + trimmed + '</code></pre></div>';
    });

    // Inline code
    text = text.replace(/`([^`]+)`/g, '<code>$1</code>');

    // Bold + italic
    text = text.replace(/\*\*\*([^*]+)\*\*\*/g, '<strong><em>$1</em></strong>');
    text = text.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    text = text.replace(/\*([^*]+)\*/g, '<em>$1</em>');

    // Headings
    text = text.replace(/^### (.+)$/gm, '<h4 style="font-size:var(--font-size-base);font-weight:var(--font-weight-semibold);margin:8px 0 4px;color:var(--text-primary)">$1</h4>');
    text = text.replace(/^## (.+)$/gm, '<h3 style="font-size:var(--font-size-lg);font-weight:var(--font-weight-semibold);margin:8px 0 4px;color:var(--text-primary)">$1</h3>');
    text = text.replace(/^# (.+)$/gm, '<h2 style="font-size:var(--font-size-xl);font-weight:var(--font-weight-bold);margin:8px 0 4px;color:var(--text-primary)">$1</h2>');

    // Blockquote
    text = text.replace(/^> (.+)$/gm, '<blockquote style="border-left:3px solid var(--accent-blue);padding:4px 12px;margin:4px 0;color:var(--text-secondary);background:var(--bg-tertiary);border-radius:0 var(--radius-sm) var(--radius-sm) 0">$1</blockquote>');

    // Horizontal rule
    text = text.replace(/^---$/gm, '<hr style="border:none;border-top:1px solid var(--border-primary);margin:8px 0">');

    // Tables (simple)
    text = text.replace(/\|(.+)\|\n\|[-| ]+\|\n((?:\|.+\|\n?)*)/g, function (_, header, rows) {
      var cells = header.split('|').map(function(c){ return c.trim(); }).filter(Boolean);
      var h = '<tr>' + cells.map(function(c){ return '<th style="padding:4px 8px;text-align:left;border:1px solid var(--border-primary);background:var(--bg-tertiary)">'+ESC(c)+'</th>'; }).join('') + '</tr>';
      var r = rows.trim().split('\n').map(function(row) {
        return '<tr>' + row.split('|').map(function(c){ return '<td style="padding:4px 8px;border:1px solid var(--border-secondary)">'+ESC(c.trim())+'</td>'; }).filter(function(t,i){ return i>0 && i< cells.length+1; }).join('') + '</tr>';
      }).join('');
      return '<table style="border-collapse:collapse;margin:8px 0;width:100%">'+h+r+'</table>';
    });

    // Unordered list
    text = text.replace(/^- (.+)$/gm, '<li style="margin:2px 0">$1</li>');
    text = text.replace(/((?:<li[^>]*>.*<\/li>\n?)+)/g, '<ul style="margin:4px 0;padding-left:20px">$1</ul>');

    // Ordered list
    text = text.replace(/^\d+\.\s(.+)$/gm, '<li style="margin:2px 0">$1</li>');

    // Links
    text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');

    // Line breaks (preserve double breaks as paragraphs)
    text = text.replace(/\n\n/g, '</p><p style="margin:8px 0">');
    text = text.replace(/\n/g, '<br>');
    text = '<p style="margin:4px 0">' + text + '</p>';

    return text;
  }

  /* ── Send message ── */
  function sendMessage(text) {
    const input = document.getElementById('chatInput');
    const msgText = text || input.value.trim();
    if (!msgText && _attachments.length === 0) return;

    const conv = getConv(_activeConvId);
    if (!conv) return;

    // Add user message
    const userMsg = { role: 'user', content: msgText, time: formatTime(new Date()), pinned: false, status: 'done', attachments: _attachments.slice() };
    conv.messages.push(userMsg);
    conv.updated = Date.now();
    _lastUserMsg = msgText;
    saveConversations();
    input.value = '';
    input.style.height = 'auto';
    _attachments = [];

    // Assistant placeholder
    const placeholder = { role: 'assistant', content: '<span class="spinner"></span> Thinking...', time: formatTime(new Date()), pinned: false, status: 'streaming' };
    conv.messages.push(placeholder);
    saveConversations();

    _isStreaming = true;
    renderChat();
    scrollToBottom();

    _abortController = new AbortController();
    MayaAPI.agent.chat(msgText, { chatId: conv.id }).then(function (res) {
      conv.messages.pop();
      if (res.ok) {
        const reply = res.data?.reply || res.data?.text || res.data?.response || JSON.stringify(res.data);
        conv.messages.push({ role: 'assistant', content: typeof reply === 'string' ? reply : JSON.stringify(reply, null, 2), time: formatTime(new Date()), pinned: false, status: 'done' });
      } else {
        conv.messages.push({ role: 'assistant', content: 'Error: ' + (res.error || 'Failed'), time: formatTime(new Date()), pinned: false, status: 'done' });
      }
      _isStreaming = false;
      conv.updated = Date.now();
      saveConversations();
      renderChat();
      scrollToBottom();
    }).catch(function (err) {
      conv.messages.pop();
      if (err.name === 'AbortError') {
        conv.messages.push({ role: 'assistant', content: 'Generation stopped.', time: formatTime(new Date()), pinned: false, status: 'done' });
      } else {
        conv.messages.push({ role: 'assistant', content: 'Error: ' + err.message, time: formatTime(new Date()), pinned: false, status: 'done' });
      }
      _isStreaming = false;
      saveConversations();
      renderChat();
      scrollToBottom();
    });
  }

  /* ── Stop / Continue / Regenerate ── */
  function stopGeneration() {
    if (_abortController) { _abortController.abort(); _abortController = null; _isStreaming = false; }
  }

  function continueMessage(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx] || conv.messages[idx].role !== 'assistant') return;
    // Re-send last user message with continue flag (use API normally)
    if (_lastUserMsg) { sendMessage(_lastUserMsg); }
  }

  function regenerateMessage(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx] || conv.messages[idx].role !== 'assistant') return;
    conv.messages = conv.messages.slice(0, idx);
    saveConversations();
    if (_lastUserMsg) { sendMessage(_lastUserMsg); } else { renderChat(); }
  }

  /* ── Message actions ── */
  function copyMessage(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx]) return;
    MayaHardware.clipboard.copy(conv.messages[idx].content);
    L().toast('Copied!', 'success');
  }

  function retryMessage(idx) {
    const conv = getConv(_activeConvId);
    if (!conv) return;
    conv.messages = conv.messages.slice(0, idx);
    saveConversations();
    const lastUserIdx = idx - 1;
    if (lastUserIdx >= 0 && conv.messages[lastUserIdx] && conv.messages[lastUserIdx].role === 'user') {
      sendMessage(conv.messages[lastUserIdx].content);
    } else { renderChat(); }
  }

  function editMessageInline(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx]) return;
    // Replace message with inline editor
    conv.messages[idx].editing = true;
    renderChat();
    setTimeout(function () {
      var el = document.getElementById('editInput_' + idx);
      if (el) { el.focus(); el.select(); }
    }, 100);
  }

  // This is called from inline editor
  function saveEdit(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx]) return;
    var el = document.getElementById('editInput_' + idx);
    if (!el) return;
    var val = el.value.trim();
    if (val) {
      conv.messages[idx].content = val;
      conv.messages[idx].time = formatTime(new Date());
      delete conv.messages[idx].editing;
      saveConversations();
      renderChat();
    }
  }

  function cancelEdit(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx]) return;
    delete conv.messages[idx].editing;
    renderChat();
  }

  function deleteMessage(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx]) return;
    if (!confirm('Delete this message?')) return;
    conv.messages.splice(idx, 1);
    saveConversations();
    renderChat();
  }

  function pinMessage(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx]) return;
    conv.messages[idx].pinned = !conv.messages[idx].pinned;
    saveConversations();
    renderChat();
  }

  function shareMessage(idx) {
    const conv = getConv(_activeConvId);
    if (!conv || !conv.messages[idx]) return;
    if (navigator.share) { navigator.share({ text: conv.messages[idx].content }); }
    else { copyMessage(idx); }
  }

  function previewImage(url) {
    L().openModal(`<div style="text-align:center"><img src="${url}" style="max-width:100%;max-height:80vh;border-radius:var(--radius-md)"></div><div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Close</button></div>`);
  }

  /* ── Multi-select ── */
  function toggleMultiSelect() {
    _multiSelect = !_multiSelect;
    _selectedMessages = [];
    renderChat();
  }

  function toggleSelect(idx) {
    const i = _selectedMessages.indexOf(idx);
    if (i >= 0) _selectedMessages.splice(i, 1);
    else _selectedMessages.push(idx);
  }

  function batchCopy() {
    const conv = getConv(_activeConvId);
    if (!conv) return;
    const text = _selectedMessages.map(i => conv.messages[i]?.content || '').join('\n\n---\n\n');
    MayaHardware.clipboard.copy(text);
    L().toast('Copied ' + _selectedMessages.length + ' messages', 'success');
    toggleMultiSelect();
  }

  function batchExport() {
    const conv = getConv(_activeConvId);
    if (!conv) return;
    const selected = _selectedMessages.map(i => conv.messages[i]).filter(Boolean);
    const output = selected.map(function (m) { return (m.role === 'user' ? '**You**' : '**Maya**') + ' (' + (m.time || '') + ')\n' + m.content; }).join('\n\n---\n\n');
    const blob = new Blob([output], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'messages.md';
    a.click();
    URL.revokeObjectURL(url);
    toggleMultiSelect();
  }

  function batchDelete() {
    if (!confirm('Delete ' + _selectedMessages.length + ' messages?')) return;
    const conv = getConv(_activeConvId);
    if (!conv) return;
    _selectedMessages.sort((a, b) => b - a).forEach(i => conv.messages.splice(i, 1));
    saveConversations();
    toggleMultiSelect();
  }

  /* ── Conversation management ── */
  function newChat() {
    const id = generateId();
    _conversations.unshift({ id, title: 'New Chat', messages: [], pinned: false, archived: false, created: Date.now(), updated: Date.now() });
    _activeConvId = id;
    _attachments = [];
    saveConversations();
    renderChat();
  }

  /* ── Rename conversation (shared: from title bar or history) ── */
  function renameConv(convId) {
    const conv = getConv(convId || _activeConvId);
    if (!conv) return;
    L().openModal(`<h2>Rename Conversation</h2>
      <div class="form-group"><input class="input" id="renameInput" value="${ESC(conv.title)}" autofocus onkeydown="if(event.key==='Enter')doRename()"></div>
      <div class="modal-actions">
        <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
        <button class="btn btn-primary" onclick="doRename()">Rename</button>
      </div>`);
    setTimeout(function () { var el = document.getElementById('renameInput'); if (el) el.focus(); }, 100);
  }
  window.doRename = function () {
    var el = document.getElementById('renameInput');
    if (!el) return;
    var name = el.value.trim();
    if (name) {
      var conv = getConv(_activeConvId);
      if (conv) { conv.title = name; saveConversations(); renderChat(); }
    }
    L().closeModal();
  };

  function deleteConv(convId) {
    if (!confirm('Delete this conversation?')) return;
    _conversations = _conversations.filter(c => c.id !== convId);
    if (_activeConvId === convId) { _activeConvId = _conversations.length > 0 ? _conversations[0].id : null; }
    _attachments = [];
    saveConversations();
    renderChat();
  }

  function pinConv(convId) {
    const conv = getConv(convId);
    if (!conv) return;
    conv.pinned = !conv.pinned;
    saveConversations();
    renderChat();
  }

  function archiveConv(convId) {
    const conv = getConv(convId);
    if (!conv) return;
    conv.archived = !conv.archived;
    saveConversations();
    renderChat();
  }

  function duplicateConv(convId) {
    const conv = getConv(convId);
    if (!conv) return;
    const id = generateId();
    _conversations.unshift({ id, title: conv.title + ' (copy)', messages: JSON.parse(JSON.stringify(conv.messages)), pinned: false, archived: false, created: Date.now(), updated: Date.now() });
    _activeConvId = id;
    saveConversations();
    renderChat();
    L().toast('Conversation duplicated', 'success');
  }

  /* ── Attachment management ── */
  function addAttachment(file) {
    _attachments.push({ name: file.name, size: file.size, type: file.type.startsWith('image/') ? 'image' : 'file', file: file });
  }

  function removeAttachment(idx) {
    _attachments.splice(idx, 1);
    renderChat();
  }

  /* ── Input actions ── */
  function voiceInput() {
    MayaHardware.voice.startRecording().then(function (res) {
      if (!res.ok) { L().toast(res.error, 'error'); return; }
      L().toast('Recording... tap 🎤 again to stop', 'info');
      // Wait 4 seconds then auto-stop
      setTimeout(function () {
        MayaHardware.voice.stopRecording().then(function (stopRes) {
          if (!stopRes.ok) return;
          var reader = new FileReader();
          reader.onloadend = function () {
            var b64 = reader.result.split(',')[1];
            MayaAPI.voice.transcribe(b64, stopRes.blob.type).then(function (trans) {
              if (trans.ok && (trans.data?.text || trans.data?.transcript)) {
                var input = document.getElementById('chatInput');
                if (input) {
                  input.value += (trans.data.text || trans.data.transcript);
                  input.dispatchEvent(new Event('input'));
                }
              }
            });
          };
          reader.readAsDataURL(stopRes.blob);
        });
      }, 4000);
    });
  }

  function cameraInput() {
    L().toast('Opening camera...', 'info');
    MayaHardware.camera.start({ facing: 'environment' }).then(function (res) {
      if (!res.ok) { L().toast(res.error, 'error'); return; }
      MayaHardware.camera.captureFrame().then(function (frame) {
        MayaHardware.camera.stop();
        if (frame.ok && frame.blob) {
          var file = new File([frame.blob], 'camera_' + Date.now() + '.jpg', { type: 'image/jpeg' });
          addAttachment(file);
          renderChat();
          L().toast('Photo captured', 'success');
        }
      });
    });
  }

  function fileInput() {
    var input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*,.pdf,.csv,.md,.txt,.js,.ts,.py,.html,.css,.json,.xml,.yaml,.yml,.sh,.md,.jsx,.tsx';
    input.multiple = true;
    input.onchange = function (e) {
      for (var i = 0; i < e.target.files.length; i++) {
        addAttachment(e.target.files[i]);
      }
      renderChat();
      L().toast(e.target.files.length + ' file(s) attached', 'success');
    };
    input.click();
  }

  /* ── Export menu ── */
  function exportMenu() {
    L().openModal(`<h2>📤 Export Conversation</h2>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--space-2);padding:var(--space-2) 0">
        <button class="btn" onclick="MayaLayout.closeModal();MayaScreens.chat.exportChat('markdown')">📝 Markdown</button>
        <button class="btn" onclick="MayaLayout.closeModal();MayaScreens.chat.exportChat('json')">📄 JSON</button>
        <button class="btn" onclick="MayaLayout.closeModal();MayaScreens.chat.exportChat('html')">🌐 HTML</button>
        <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
      </div>`);
  }

  function exportChat(format) {
    const conv = getConv(_activeConvId);
    if (!conv || conv.messages.length === 0) { L().toast('No messages to export', 'warning'); return; }
    let output;
    if (format === 'json') {
      output = JSON.stringify(conv.messages, null, 2);
    } else if (format === 'markdown') {
      output = '# ' + conv.title + '\n\n';
      conv.messages.forEach(function (m) { output += '**' + (m.role === 'user' ? 'You' : 'Maya') + '** (' + (m.time || '') + ')\n' + m.content + '\n\n'; });
    } else {
      output = '<h1>' + ESC(conv.title) + '</h1>';
      conv.messages.forEach(function (m) {
        output += '<p><strong>' + (m.role === 'user' ? 'You' : 'Maya') + '</strong> (' + (m.time || '') + ')</p><div>' + renderContent(m.content) + '</div><hr>';
      });
    }
    const blob = new Blob([output], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = conv.title.replace(/[^a-z0-9]/gi, '_') + '.' + (format === 'json' ? 'json' : format === 'markdown' ? 'md' : 'html');
    a.click();
    URL.revokeObjectURL(url);
    L().toast('Exported as ' + format, 'success');
  }

  /* ── History drawer ── */
  function toggleHistory() {
    L().openDrawer(buildHistoryHtml());
  }

  function buildHistoryHtml() {
    let html = `<div class="drawer-header">
      <strong style="font-size:var(--font-size-sm)">Conversations</strong>
      <button class="action-btn" onclick="MayaScreens.chat.newChat();MayaLayout.closeDrawer()">➕</button>
    </div>
    <div style="padding:var(--space-2)">
      <input class="input" type="text" placeholder="Search conversations..." oninput="MayaScreens.chat.filterHistory(this.value)" style="font-size:var(--font-size-sm)">
    </div>`;

    const groups = groupConversations(_conversations.filter(c => !c.archived));
    Object.keys(groups).forEach(function (group) {
      html += `<div style="padding:var(--space-1) var(--space-3);font-size:var(--font-size-xs);color:var(--text-tertiary);text-transform:uppercase;letter-spacing:0.5px;font-weight:var(--font-weight-semibold)">${group}</div>`;
      groups[group].forEach(function (conv) {
        const isActive = conv.id === _activeConvId;
        const lastMsg = conv.messages.length > 0 ? conv.messages[conv.messages.length - 1].content.slice(0, 50) : 'No messages';
        html += `<div class="conv-item ${isActive ? 'active' : ''}" onclick="MayaScreens.chat.switchTo('${conv.id}')">
          <div class="info">
            <div class="title">${ESC(conv.title)} ${conv.pinned ? '📌' : ''}</div>
            <div class="preview">${ESC(lastMsg)}</div>
          </div>
          <div style="display:flex;gap:2px;flex-shrink:0">
            <button class="action-btn" onclick="event.stopPropagation();MayaScreens.chat.renameConv('${conv.id}')" title="Rename">✏️</button>
            <button class="action-btn" onclick="event.stopPropagation();MayaScreens.chat.pinConv('${conv.id}')" title="Pin">📌</button>
            <button class="action-btn" onclick="event.stopPropagation();MayaScreens.chat.archiveConv('${conv.id}')" title="Archive">📦</button>
            <button class="action-btn" onclick="event.stopPropagation();MayaScreens.chat.duplicateConv('${conv.id}')" title="Duplicate">📋</button>
            <button class="action-btn" onclick="event.stopPropagation();MayaScreens.chat.deleteConv('${conv.id}')" title="Delete">🗑</button>
          </div>
        </div>`;
      });
    });

    if (_conversations.length === 0) {
      html += `<div class="empty-state"><div class="title">No conversations</div><div class="desc">Start a new chat to begin</div></div>`;
    }
    return html;
  }

  function groupConversations(convs) {
    const groups = {};
    const today = new Date(); today.setHours(0, 0, 0, 0);
    const yesterday = new Date(today); yesterday.setDate(yesterday.getDate() - 1);
    const thisWeek = new Date(today); thisWeek.setDate(thisWeek.getDate() - today.getDay());
    convs.forEach(function (conv) {
      const d = new Date(conv.updated || conv.created);
      let key = d >= today ? 'Today' : d >= yesterday ? 'Yesterday' : d >= thisWeek ? 'This Week' : 'Earlier';
      if (!groups[key]) groups[key] = [];
      groups[key].push(conv);
    });
    Object.keys(groups).forEach(function (k) { groups[k].sort((a, b) => (b.updated || 0) - (a.updated || 0)); });
    return groups;
  }

  function switchTo(convId) {
    _activeConvId = convId;
    _attachments = [];
    L().closeDrawer();
    renderChat();
  }

  function filterHistory(query) {
    const drawer = document.getElementById('drawerContent');
    if (!query.trim()) { drawer.innerHTML = buildHistoryHtml(); return; }
    const q = query.toLowerCase();
    const filtered = _conversations.filter(c => c.title.toLowerCase().includes(q) || c.messages.some(m => m.content.toLowerCase().includes(q)));
    let html = `<div class="drawer-header"><strong>Search Results</strong></div>`;
    filtered.forEach(function (conv) {
      html += `<div class="conv-item ${conv.id === _activeConvId ? 'active' : ''}" onclick="MayaScreens.chat.switchTo('${conv.id}')"><div class="info"><div class="title">${ESC(conv.title)}</div></div></div>`;
    });
    if (filtered.length === 0) html += `<div class="empty-state"><div class="title">No results</div></div>`;
    drawer.innerHTML = html;
  }

  function searchConv() {
    L().openModal(`<h2>🔍 Search Conversations</h2>
      <div class="form-group"><input class="input" id="searchQuery" placeholder="Search messages and titles..." autofocus onkeydown="if(event.key==='Enter')doSearch()"></div>
      <div id="searchResults" class="text-sm" style="max-height:300px;overflow-y:auto;margin-bottom:var(--space-2)"></div>
      <div class="modal-actions"><button class="btn" onclick="MayaLayout.closeModal()">Cancel</button><button class="btn btn-primary" onclick="doSearch()">Search</button></div>`);
    setTimeout(function () { var el = document.getElementById('searchQuery'); if (el) el.focus(); }, 100);
  }
  window.doSearch = function () {
    var q = document.getElementById('searchQuery');
    if (!q) return;
    var query = q.value.trim();
    if (!query) { L().toast('Enter a search term', 'warning'); return; }
    var results = document.getElementById('searchResults');
    var found = _conversations.filter(function (c) { return c.title.toLowerCase().includes(query.toLowerCase()) || c.messages.some(function (m) { return m.content.toLowerCase().includes(query.toLowerCase()); }); });
    if (found.length > 0) {
      var h = '<div style="font-weight:var(--font-weight-medium);margin-bottom:var(--space-2)">' + found.length + ' conversation(s) found</div>';
      found.forEach(function (c) { h += '<div class="conv-item" onclick="MayaLayout.closeModal();MayaScreens.chat.switchTo(\'' + c.id + '\')"><div class="info"><div class="title">' + ESC(c.title) + '</div><div class="preview">' + ESC(c.messages.length + ' messages') + '</div></div></div>'; });
      results.innerHTML = h;
    } else { results.innerHTML = '<div class="empty-state" style="padding:20px"><div class="icon">🔍</div><div class="title">No results</div></div>'; }
  };

  /* ── TTS ── */
  function speakText() {
    L().openModal(`<h2>🔊 Text to Speech</h2>
      <div class="form-group"><textarea class="textarea" id="ttsText" rows="3" placeholder="Enter text to speak..."></textarea></div>
      <div class="modal-actions">
        <button class="btn" onclick="MayaLayout.closeModal()">Cancel</button>
        <button class="btn btn-primary" onclick="doTTS()">Speak</button>
      </div>
      <div id="ttsResult" class="mt-sm text-sm"></div>`);
  }
  window.doTTS = function () {
    var text = document.getElementById('ttsText');
    if (!text || !text.value.trim()) { L().toast('Enter text', 'warning'); return; }
    document.getElementById('ttsResult').innerHTML = '<span class="spinner"></span> Generating...';
    MayaAPI.voice.speak(text.value.trim(), 'alloy').then(function (res) {
      document.getElementById('ttsResult').innerHTML = res.ok ? '<span class="tag tag-success">Done</span>' : '<span class="tag tag-error">' + ESC(res.error) + '</span>';
    });
  };

  /* ── Helpers ── */
  function scrollToBottom() {
    setTimeout(function () {
      const el = document.getElementById('chatMessages');
      if (el) { el.scrollTop = el.scrollHeight; }
      const btn = document.getElementById('jumpToBottom');
      if (btn) btn.style.display = 'none';
    }, 50);
  }

  function formatTime(date) {
    const h = date.getHours(), m = date.getMinutes();
    return (h % 12 || 12) + ':' + (m < 10 ? '0' : '') + m + (h < 12 ? ' AM' : ' PM');
  }

  /* ── Export API ── */
  MayaScreens.chat = {
    sendMessage: sendMessage,
    stopGeneration: stopGeneration,
    continueMessage: continueMessage,
    regenerateMessage: regenerateMessage,
    copyMessage: copyMessage,
    retryMessage: retryMessage,
    editMessageInline: editMessageInline,
    saveEdit: saveEdit,
    cancelEdit: cancelEdit,
    deleteMessage: deleteMessage,
    pinMessage: pinMessage,
    shareMessage: shareMessage,
    previewImage: previewImage,
    toggleMultiSelect: toggleMultiSelect,
    toggleSelect: toggleSelect,
    batchCopy: batchCopy,
    batchExport: batchExport,
    batchDelete: batchDelete,
    newChat: newChat,
    deleteConv: deleteConv,
    renameConv: renameConv,
    pinConv: pinConv,
    archiveConv: archiveConv,
    duplicateConv: duplicateConv,
    voiceInput: voiceInput,
    cameraInput: cameraInput,
    fileInput: fileInput,
    addAttachment: addAttachment,
    removeAttachment: removeAttachment,
    speakText: speakText,
    toggleHistory: toggleHistory,
    switchTo: switchTo,
    filterHistory: filterHistory,
    searchConv: searchConv,
    exportChat: exportChat,
    exportMenu: exportMenu,
  };
})();
