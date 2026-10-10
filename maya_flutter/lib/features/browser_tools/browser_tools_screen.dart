import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

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
              onPressed: () {},
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

  void _executeAction() {
    setState(() => _isExecuting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isExecuting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endpoint not connected'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    });
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
          MayaEmptyState(
            'Endpoint not connected',
            icon: Icons.web_rounded,
            onAction: _isExecuting ? null : _executeAction,
            actionLabel: 'Retry',
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
    return const MayaEmptyState(
      'Browser action history will appear here',
      icon: Icons.history_rounded,
    );
  }
}
