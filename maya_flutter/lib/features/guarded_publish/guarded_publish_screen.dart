import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class GuardedPublishScreen extends ConsumerStatefulWidget {
  const GuardedPublishScreen({super.key});

  @override
  ConsumerState<GuardedPublishScreen> createState() =>
      _GuardedPublishScreenState();
}

class _GuardedPublishScreenState extends ConsumerState<GuardedPublishScreen>
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
          title: const Text('Guarded Publish', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.pending_actions_rounded), text: 'Pending'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
              Tab(icon: Icon(Icons.add_rounded), text: 'New Request'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _PendingTab(),
            _HistoryTab(),
            _NewRequestTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No Pending Requests',
      icon: Icons.pending_actions_rounded,
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No History',
      icon: Icons.history_rounded,
    );
  }
}

class _NewRequestTab extends ConsumerWidget {
  const _NewRequestTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.add_rounded,
    );
  }
}
