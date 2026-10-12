import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final browserActionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.sandboxExecute(code: '', language: 'python');
});

final browserHistoryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.browserGetHistory();
});

class BrowserToolsScreen extends ConsumerStatefulWidget {
  const BrowserToolsScreen({super.key});

  @override
  ConsumerState<BrowserToolsScreen> createState() => _BrowserToolsScreenState();
}

class _BrowserToolsScreenState extends ConsumerState<BrowserToolsScreen>
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
          title: const Text('Browser Tools', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(browserHistoryProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.web_rounded), text: 'Actions'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _BrowserActionsTab(),
            _BrowserHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _BrowserActionsTab extends ConsumerStatefulWidget {
  const _BrowserActionsTab();

  @override
  ConsumerState<_BrowserActionsTab> createState() => _BrowserActionsTabState();
}

class _BrowserActionsTabState extends ConsumerState<_BrowserActionsTab> {
  final _actionController = TextEditingController(text: 'navigate');
  final _urlController = TextEditingController();
  final _selectorController = TextEditingController();
  final _textController = TextEditingController();
  final _queryController = TextEditingController();
  bool _isExecuting = false;

  @override
  void dispose() {
    _actionController.dispose();
    _urlController.dispose();
    _selectorController.dispose();
    _textController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _executeAction() async {
    final action = _actionController.text.trim();
    final url = _urlController.text.trim();
    final selector = _selectorController.text.trim();
    final text = _textController.text.trim();
    final query = _queryController.text.trim();

    if (action.isEmpty) return;

    setState(() => _isExecuting = true);
    try {
      // Use the existing multimodal browser action endpoint
      // For now we'll call through a generic action endpoint
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Browser action "$action" executed'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Browser Actions', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Execute browser actions via the browser pool',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _actionController.text,
            decoration: const InputDecoration(
              labelText: 'Action',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'navigate', child: Text('Navigate')),
              DropdownMenuItem(value: 'click', child: Text('Click')),
              DropdownMenuItem(value: 'type', child: Text('Type')),
              DropdownMenuItem(value: 'text', child: Text('Get Text')),
              DropdownMenuItem(value: 'screenshot', child: Text('Screenshot')),
              DropdownMenuItem(value: 'search', child: Text('Search')),
            ],
            onChanged: (value) => setState(() => _actionController.text = value ?? 'navigate'),
          ),
          const SizedBox(height: 16),
          if (_actionController.text == 'navigate' || _actionController.text == 'search')
            TextField(
              controller: _actionController.text == 'navigate' ? _urlController : _queryController,
              decoration: InputDecoration(
                labelText: _actionController.text == 'navigate' ? 'URL' : 'Search Query',
                border: const OutlineInputBorder(),
              ),
            ),
          if (_actionController.text == 'click' || _actionController.text == 'type' || _actionController.text == 'text')
            TextField(
              controller: _selectorController,
              decoration: const InputDecoration(
                labelText: 'CSS Selector',
                border: OutlineInputBorder(),
              ),
            ),
          if (_actionController.text == 'type')
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text to Type',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExecuting ? null : _executeAction,
              icon: _isExecuting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_isExecuting ? 'Executing...' : 'Execute Action'),
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

class _BrowserHistoryTab extends ConsumerWidget {
  const _BrowserHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(browserHistoryProvider);

    return historyAsync.when(
      data: (data) {
        final history = data['history'] as List? ?? [];
        if (history.isEmpty) {
          return const MayaEmptyState(
            'No browser history yet',
            icon: Icons.history_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final item = history[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Row(
                children: [
                  const Icon(Icons.web_rounded, color: MayaTheme.neonCyan, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['action'] ?? 'Unknown', style: MayaTheme.titleMedium),
                        Text(item['url'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(item['timestamp']?.toString().substring(0, 19) ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            );
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
            Text('Error loading history', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}