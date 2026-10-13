import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class CommunicationToolsScreen extends ConsumerStatefulWidget {
  const CommunicationToolsScreen({super.key});

  @override
  ConsumerState<CommunicationToolsScreen> createState() =>
      _CommunicationToolsScreenState();
}

class _CommunicationToolsScreenState
    extends ConsumerState<CommunicationToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title:
              const Text('Communication Tools', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.email_rounded), text: 'Email'),
              Tab(icon: Icon(Icons.webhook_rounded), text: 'Webhook'),
              Tab(icon: Icon(Icons.chat_rounded), text: 'WhatsApp (WAHA)'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _EmailToolTab(),
            _WebhookToolTab(),
            _WhatsAppTab(),
          ],
        ),
      ),
    );
  }
}

class _EmailToolTab extends ConsumerStatefulWidget {
  const _EmailToolTab();

  @override
  ConsumerState<_EmailToolTab> createState() => _EmailToolTabState();
}

class _EmailToolTabState extends ConsumerState<_EmailToolTab> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _textController = TextEditingController();
  final _htmlController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _textController.dispose();
    _htmlController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final to = _toController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (to.isEmpty ||
        _subjectController.text.trim().isEmpty ||
        (_textController.text.trim().isEmpty &&
            _htmlController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Please fill in To, Subject, and Text/HTML'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(mayaApiProvider).communicationSendEmail(
            to: to,
            subject: _subjectController.text.trim(),
            text: _textController.text.trim().isEmpty
                ? null
                : _textController.text.trim(),
            html: _htmlController.text.trim().isEmpty
                ? null
                : _htmlController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Email sent successfully'),
              backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Email Tool', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Send emails via SMTP. Configure SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM in .env.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _toController,
            decoration: const InputDecoration(
              labelText: 'To (comma-separated)',
              hintText: 'recipient@example.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Text Body',
              hintText: 'Plain text content',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _htmlController,
            decoration: const InputDecoration(
              labelText: 'HTML Body (optional)',
              hintText: '<p>HTML content</p>',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendEmail,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.send_rounded),
              label: Text(_isSending ? 'Sending...' : 'Send Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebhookToolTab extends ConsumerStatefulWidget {
  const _WebhookToolTab();

  @override
  ConsumerState<_WebhookToolTab> createState() => _WebhookToolTabState();
}

class _WebhookToolTabState extends ConsumerState<_WebhookToolTab> {
  final _urlController = TextEditingController();
  final _messageController = TextEditingController();
  String _platform = 'generic';
  bool _isSending = false;

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendWebhook() async {
    if (_urlController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Please fill in URL and Message'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(mayaApiProvider).communicationSendWebhook(
            url: _urlController.text.trim(),
            message: _messageController.text.trim(),
            platform: _platform,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Webhook sent successfully'),
              backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Webhook Tool', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Send messages to Slack, Discord, or generic webhooks.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Webhook URL',
              hintText: 'https://hooks.slack.com/...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _platform,
            decoration: const InputDecoration(
              labelText: 'Platform',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'generic', child: Text('Generic')),
              DropdownMenuItem(value: 'slack', child: Text('Slack')),
              DropdownMenuItem(value: 'discord', child: Text('Discord')),
            ],
            onChanged: (value) =>
                setState(() => _platform = value ?? 'generic'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Message to send',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendWebhook,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.webhook_rounded),
              label: Text(_isSending ? 'Sending...' : 'Send Webhook'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppTab extends ConsumerStatefulWidget {
  const _WhatsAppTab();

  @override
  ConsumerState<_WhatsAppTab> createState() => _WhatsAppTabState();
}

class _WhatsAppTabState extends ConsumerState<_WhatsAppTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  String? _sessionId;
  String? _qrCode;
  bool _isConnected = false;
  bool _isLoading = false;
  bool _autoReplyEnabled = false;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  String? _selectedConversation;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _loadSessionStatus();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionStatus() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(mayaApiProvider);
      final status = await api.wahaGetStatus();
      if (mounted) {
        setState(() {
          _isConnected = status['connected'] ?? false;
          _sessionId = status['session_id'];
          _qrCode = status['qr_code'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading status: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.wahaStartSession();
      if (mounted) {
        setState(() {
          _sessionId = result['session_id'];
          _qrCode = result['qr_code'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error starting session: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _loadConversations() async {
    if (_sessionId == null) return;
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.wahaListConversations(sessionId: _sessionId!);
      if (mounted) {
        setState(() {
          _conversations =
              List<Map<String, dynamic>>.from(result['conversations'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  Future<void> _loadMessages(String conversationId) async {
    if (_sessionId == null) return;
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.wahaGetMessages(
          sessionId: _sessionId!, chatId: conversationId);
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(result['messages'] ?? []);
          _selectedConversation = conversationId;
        });
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_sessionId == null ||
        _selectedConversation == null ||
        _messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      final api = ref.read(mayaApiProvider);
      await api.wahaSendMessage(
        sessionId: _sessionId!,
        chatId: _selectedConversation!,
        text: text,
      );
      await _loadMessages(_selectedConversation!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error sending: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _toggleAutoReply() async {
    if (_sessionId == null) return;
    try {
      final api = ref.read(mayaApiProvider);
      await api.wahaSetAutoReply(
        sessionId: _sessionId!,
        enabled: !_autoReplyEnabled,
      );
      setState(() => _autoReplyEnabled = !_autoReplyEnabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _logout() async {
    if (_sessionId == null) return;
    try {
      final api = ref.read(mayaApiProvider);
      await api.wahaLogout(_sessionId!);
      if (mounted) {
        setState(() {
          _isConnected = false;
          _sessionId = null;
          _qrCode = null;
          _conversations = [];
          _messages = [];
          _selectedConversation = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isConnected
                ? MayaTheme.neonEmerald.withValues(alpha: 0.1)
                : MayaTheme.slate800,
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Icon(
                _isConnected ? Icons.check_circle_rounded : Icons.error_rounded,
                color: _isConnected ? MayaTheme.neonEmerald : MayaTheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConnected
                          ? 'WhatsApp Connected'
                          : 'WhatsApp Disconnected',
                      style: MayaTheme.titleSmall.copyWith(
                        color: _isConnected
                            ? MayaTheme.neonEmerald
                            : MayaTheme.error,
                      ),
                    ),
                    if (_sessionId != null)
                      Text(
                        'Session: ${_sessionId!.substring(0, 16)}...',
                        style: MayaTheme.bodySmall.copyWith(
                            color: Colors.white54, fontFamily: 'monospace'),
                      ),
                  ],
                ),
              ),
              if (!_isConnected && _sessionId == null)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startSession,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.qr_code_rounded),
                  label: Text(_isLoading ? 'Starting...' : 'Start Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900,
                  ),
                )
              else if (!_isConnected && _qrCode != null)
                ElevatedButton.icon(
                  onPressed: _loadSessionStatus,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900,
                  ),
                )
              else
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadConversations,
                      icon: const Icon(Icons.refresh_rounded,
                          color: MayaTheme.neonCyan),
                      tooltip: 'Refresh Conversations',
                    ),
                    IconButton(
                      onPressed: _toggleAutoReply,
                      icon: Icon(
                        _autoReplyEnabled
                            ? Icons.smart_toy_rounded
                            : Icons.smart_toy_outlined,
                        color: _autoReplyEnabled
                            ? MayaTheme.neonEmerald
                            : Colors.white54,
                      ),
                      tooltip: _autoReplyEnabled
                          ? 'Auto-reply ON'
                          : 'Auto-reply OFF',
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded,
                          color: MayaTheme.error),
                      tooltip: 'Disconnect',
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Sub-tabs
        if (_isConnected)
          TabBar(
            controller: _subTabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'Conversations'),
              Tab(icon: Icon(Icons.message_rounded), text: 'Messages'),
              Tab(icon: Icon(Icons.settings_rounded), text: 'Settings'),
            ],
          ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: MayaTheme.neonCyan))
              : !_isConnected && _qrCode == null
                  ? const MayaEmptyState(
                      'No WhatsApp session active',
                      icon: Icons.chat_rounded,
                    )
                  : !_isConnected && _qrCode != null
                      ? _buildQrPairing()
                      : TabBarView(
                          controller: _subTabController,
                          children: [
                            _buildConversationsList(),
                            _buildMessagesView(),
                            _buildSettings(),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildQrPairing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_rounded,
              size: 64, color: MayaTheme.neonCyan),
          const SizedBox(height: 24),
          const Text('Scan QR Code to Link WhatsApp',
              style: MayaTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Open WhatsApp on your dedicated business phone → Settings → Linked Devices → Link a Device',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MayaTheme.slate800,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
            ),
            child: _qrCode != null && _qrCode!.isNotEmpty
                ? Image.memory(
                    _decodeBase64(_qrCode!),
                    width: 256,
                    height: 256,
                    errorBuilder: (_, __, ___) => const Text('Invalid QR code',
                        style: TextStyle(color: MayaTheme.error)),
                  )
                : const Center(
                    child:
                        CircularProgressIndicator(color: MayaTheme.neonCyan)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSessionStatus,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Check Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.neonCyan,
              foregroundColor: MayaTheme.slate900,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _sessionId = null;
                _qrCode = null;
              });
            },
            child: Text('Cancel',
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_conversations.isEmpty) {
      return MayaEmptyState(
        'No conversations yet',
        icon: Icons.chat_bubble_outline_rounded,
        onAction: _loadConversations,
        actionLabel: 'Load Conversations',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (_, index) {
        final conv = _conversations[index];
        final name = conv['name'] ??
            conv['push_name'] ??
            conv['contact_name'] ??
            'Unknown';
        final lastMessage = conv['last_message']?['body'] ?? '';
        final lastTime = conv['last_message']?['timestamp'] ?? '';
        final unread = conv['unread_count'] ?? 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: MayaTheme.neonCyan.withValues(alpha: 0.2),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: MayaTheme.neonCyan)),
          ),
          title: Text(name, style: MayaTheme.titleSmall),
          subtitle: Text(
            lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
            style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (lastTime.isNotEmpty)
                Text(_formatTime(lastTime),
                    style: MayaTheme.bodySmall
                        .copyWith(color: Colors.white38, fontSize: 11)),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: MayaTheme.neonCyan,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$unread',
                      style: MayaTheme.bodySmall
                          .copyWith(color: MayaTheme.slate900, fontSize: 10)),
                ),
            ],
          ),
          onTap: () => _loadMessages(conv['id'] ?? conv['chat_id'] ?? ''),
        );
      },
    );
  }

  Widget _buildMessagesView() {
    if (_selectedConversation == null) {
      return const MayaEmptyState(
        'Select a conversation to view messages',
        icon: Icons.message_rounded,
      );
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const MayaEmptyState('No messages', icon: Icons.message_rounded)
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, index) {
                    final msg = _messages[_messages.length - 1 - index];
                    final isOutgoing = msg['from_me'] == true;
                    final text = msg['body'] ?? msg['text'] ?? '';
                    final time = msg['timestamp'] ?? '';

                    return Align(
                      alignment: isOutgoing
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isOutgoing
                              ? MayaTheme.neonCyan
                              : MayaTheme.slate800,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isOutgoing
                                ? const Radius.circular(4)
                                : const Radius.circular(16),
                            bottomLeft: isOutgoing
                                ? const Radius.circular(16)
                                : const Radius.circular(4),
                          ),
                          border: isOutgoing
                              ? null
                              : Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(text,
                                style: MayaTheme.bodyMedium.copyWith(
                                    color: isOutgoing
                                        ? Colors.black
                                        : Colors.white)),
                            if (time.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(_formatTime(time),
                                  style: MayaTheme.bodySmall.copyWith(
                                      color: isOutgoing
                                          ? Colors.black54
                                          : Colors.white38,
                                      fontSize: 10)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MayaTheme.slate800,
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: MayaTheme.slate900,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, color: MayaTheme.neonCyan),
                style: IconButton.styleFrom(
                  backgroundColor: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WhatsApp Settings', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Configure auto-reply and session settings for your dedicated business WhatsApp number.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),

          // Auto-reply toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smart_toy_rounded,
                        color: MayaTheme.neonEmerald),
                    const SizedBox(width: 12),
                    Text('Auto-Reply', style: MayaTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'When enabled, Maya will automatically reply to incoming messages using Memory/Knowledge context. If confidence is low, escalates to you via Telegram.',
                  style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Enable Auto-Reply', style: MayaTheme.titleSmall),
                  subtitle: Text(
                    _autoReplyEnabled
                        ? 'Auto-reply is active'
                        : 'Auto-reply is disabled',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                  ),
                  value: _autoReplyEnabled,
                  onChanged: (_) => _toggleAutoReply(),
                  activeThumbColor: MayaTheme.neonEmerald,
                  activeTrackColor:
                      MayaTheme.neonEmerald.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Session info
          if (_sessionId != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Session Info', style: MayaTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildInfoRow('Session ID', _sessionId!),
                  _buildInfoRow('Connected', _isConnected ? 'Yes' : 'No'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Danger zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MayaTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MayaTheme.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: MayaTheme.error),
                    const SizedBox(width: 8),
                    Text('Danger Zone',
                        style: MayaTheme.titleMedium
                            .copyWith(color: MayaTheme.error)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Disconnecting will log out the WhatsApp session. You\'ll need to scan the QR code again to reconnect.',
                  style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Disconnect WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MayaTheme.error,
                      side: const BorderSide(color: MayaTheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
          Expanded(
            child: Text(
              value,
              style: MayaTheme.bodyMedium
                  .copyWith(color: Colors.white70, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  Uint8List _decodeBase64(String base64Str) {
    // Handle data URL format
    if (base64Str.startsWith('data:')) {
      base64Str = base64Str.split(',').last;
    }
    return base64.decode(base64Str);
  }
}
