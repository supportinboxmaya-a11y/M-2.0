import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final webhooksListProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.webhooksList();
});

class WebhooksScreen extends ConsumerStatefulWidget {
  const WebhooksScreen({super.key});

  @override
  ConsumerState<WebhooksScreen> createState() => _WebhooksScreenState();
}

class _WebhooksScreenState extends ConsumerState<WebhooksScreen>
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
          title: const Text('Webhooks', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(webhooksListProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.webhook_rounded), text: 'Webhooks'),
              Tab(icon: Icon(Icons.add_circle_rounded), text: 'Create'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _WebhooksListTab(),
            _WebhookCreateTab(),
          ],
        ),
      ),
    );
  }
}

class _WebhooksListTab extends ConsumerWidget {
  const _WebhooksListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webhooksAsync = ref.watch(webhooksListProvider);

    return webhooksAsync.when(
      data: (data) {
        final webhooks = data['webhooks'] as List? ?? [];
        if (webhooks.isEmpty) {
          return const MayaEmptyState(
            'No Webhooks registered',
            icon: Icons.webhook_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: webhooks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final wh = webhooks[index];
            return _WebhookCard(webhook: wh);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading webhooks', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _WebhookCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> webhook;

  const _WebhookCard({required this.webhook});

  @override
  ConsumerState<_WebhookCard> createState() => _WebhookCardState();
}

class _WebhookCardState extends ConsumerState<_WebhookCard> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(mayaApiProvider).webhooksDelete(widget.webhook['id']);
      ref.invalidate(webhooksListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wh = widget.webhook;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.webhook_rounded, color: MayaTheme.neonCyan, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wh['url'] ?? '', style: MayaTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Events: ${(wh['events'] as List?)?.join(', ') ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (wh['active'] == true ? MayaTheme.neonEmerald : MayaTheme.neonOrange).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: wh['active'] == true ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                ),
                child: Text(
                  wh['active'] == true ? 'ACTIVE' : 'INACTIVE',
                  style: MayaTheme.labelSmall.copyWith(color: wh['active'] == true ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: MayaTheme.error),
                onPressed: _isDeleting ? null : _delete,
              ),
            ],
          ),
          if (wh['events'] != null && (wh['events'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (wh['events'] as List).map((e) => Chip(
                label: Text(e.toString(), style: MayaTheme.labelSmall),
                backgroundColor: MayaTheme.neonCyan.withValues(alpha: 0.2),
                side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _WebhookCreateTab extends ConsumerStatefulWidget {
  const _WebhookCreateTab();

  @override
  ConsumerState<_WebhookCreateTab> createState() => _WebhookCreateTabState();
}

class _WebhookCreateTabState extends ConsumerState<_WebhookCreateTab> {
  final _urlController = TextEditingController();
  final _secretController = TextEditingController();
  final _eventsController = TextEditingController(text: 'task.started,task.done,task.failed');
  bool _isCreating = false;
  bool _active = true;

  @override
  void dispose() {
    _urlController.dispose();
    _secretController.dispose();
    _eventsController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_urlController.text.trim().isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final events = _eventsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await ref.read(mayaApiProvider).webhooksCreate(
        url: _urlController.text.trim(),
        events: events,
        secret: _secretController.text.trim().isEmpty ? null : _secretController.text.trim(),
        active: _active,
      );
      _urlController.clear();
      _secretController.clear();
      _eventsController.text = 'task.started,task.done,task.failed';
      _active = true;
      ref.invalidate(webhooksListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Webhook created successfully'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Webhook', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Register a new webhook endpoint to receive event notifications.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Webhook URL',
              hintText: 'https://your-server.com/webhook',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _secretController,
            decoration: const InputDecoration(
              labelText: 'Secret (optional)',
              hintText: 'Shared secret for signature verification',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _eventsController,
            decoration: const InputDecoration(
              labelText: 'Events (comma-separated)',
              hintText: 'task.started, task.done, task.failed',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Active'),
            subtitle: const Text('Receive events immediately'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            activeColor: MayaTheme.neonEmerald,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _create,
              icon: _isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.add_circle_rounded),
              label: Text(_isCreating ? 'Creating...' : 'Create Webhook'),
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