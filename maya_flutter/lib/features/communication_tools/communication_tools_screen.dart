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

class _CommunicationToolsScreenState extends ConsumerState<CommunicationToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          title: const Text('Communication Tools', style: MayaTheme.headlineSmall),
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
            tabs: const [
              Tab(icon: Icon(Icons.email_rounded), text: 'Email'),
              Tab(icon: Icon(Icons.webhook_rounded), text: 'Webhook'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _EmailToolTab(),
            _WebhookToolTab(),
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
    final to = _toController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (to.isEmpty || _subjectController.text.trim().isEmpty || (_textController.text.trim().isEmpty && _htmlController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please fill in To, Subject, and Text/HTML'), backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(mayaApiProvider).communicationSendEmail(
        to: to,
        subject: _subjectController.text.trim(),
        text: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
        html: _htmlController.text.trim().isEmpty ? null : _htmlController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Email sent successfully'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
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
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
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
    if (_urlController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please fill in URL and Message'), backgroundColor: MayaTheme.error),
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
          SnackBar(content: const Text('Webhook sent successfully'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
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
            onChanged: (value) => setState(() => _platform = value ?? 'generic'),
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
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
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