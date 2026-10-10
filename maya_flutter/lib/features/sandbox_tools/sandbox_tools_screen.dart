import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class SandboxToolsScreen extends ConsumerStatefulWidget {
  const SandboxToolsScreen({super.key});

  @override
  ConsumerState<SandboxToolsScreen> createState() => _SandboxToolsScreenState();
}

class _SandboxToolsScreenState extends ConsumerState<SandboxToolsScreen>
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
          title: const Text('Sandbox Tools', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.code_rounded), text: 'Execute'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _SandboxExecuteTab(),
            _SandboxHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _SandboxExecuteTab extends ConsumerStatefulWidget {
  const _SandboxExecuteTab();

  @override
  ConsumerState<_SandboxExecuteTab> createState() => _SandboxExecuteTabState();
}

class _SandboxExecuteTabState extends ConsumerState<_SandboxExecuteTab> {
  final _codeController =
      TextEditingController(text: 'print("Hello from Maya Sandbox!")');
  final _languageController = TextEditingController(text: 'python');
  final _timeoutController = TextEditingController(text: '30');
  bool _isExecuting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _languageController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  void _executeCode() {
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
          const Text('Sandbox Execute', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Execute code in a secure sandbox environment',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          MayaEmptyState(
            'Endpoint not connected',
            icon: Icons.code_rounded,
            onAction: _isExecuting ? null : _executeCode,
            actionLabel: 'Retry',
          ),
        ],
      ),
    );
  }
}

class _SandboxHistoryTab extends ConsumerWidget {
  const _SandboxHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Code execution history will appear here',
      icon: Icons.history_rounded,
    );
  }
}
