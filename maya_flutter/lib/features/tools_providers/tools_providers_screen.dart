import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class ToolsProvidersScreen extends ConsumerStatefulWidget {
  const ToolsProvidersScreen({super.key});

  @override
  ConsumerState<ToolsProvidersScreen> createState() =>
      _ToolsProvidersScreenState();
}

class _ToolsProvidersScreenState extends ConsumerState<ToolsProvidersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
              const Text('Tools & Providers', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.build_rounded), text: 'Tools'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Logs'),
              Tab(icon: Icon(Icons.policy_rounded), text: 'Policies'),
              Tab(icon: Icon(Icons.cloud_rounded), text: 'Providers'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ToolsTab(),
            _LogsTab(),
            _PoliciesTab(),
            _ProvidersTab(),
          ],
        ),
      ),
    );
  }
}

class _ToolsTab extends ConsumerWidget {
  const _ToolsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No tools available',
      icon: Icons.build_rounded,
      actionLabel: 'Retry',
      onAction: null,
    );
  }
}

class _LogsTab extends ConsumerWidget {
  const _LogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No tool logs yet',
      icon: Icons.history_rounded,
    );
  }
}

class _PoliciesTab extends ConsumerWidget {
  const _PoliciesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No managed tools found',
      icon: Icons.policy_rounded,
    );
  }
}

class _ProvidersTab extends ConsumerWidget {
  const _ProvidersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No providers configured',
      icon: Icons.cloud_rounded,
    );
  }
}
