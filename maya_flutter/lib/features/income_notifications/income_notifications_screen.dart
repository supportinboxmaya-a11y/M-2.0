import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class IncomeNotificationsScreen extends ConsumerStatefulWidget {
  const IncomeNotificationsScreen({super.key});

  @override
  ConsumerState<IncomeNotificationsScreen> createState() =>
      _IncomeNotificationsScreenState();
}

class _IncomeNotificationsScreenState
    extends ConsumerState<IncomeNotificationsScreen>
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
          title: const Text('Income Notifications',
              style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.approval_rounded), text: 'Approvals'),
              Tab(icon: Icon(Icons.campaign_rounded), text: 'Templates'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ApprovalsTab(),
            _TemplatesTab(),
            _StatsTab(),
          ],
        ),
      ),
    );
  }
}

class _ApprovalsTab extends ConsumerWidget {
  const _ApprovalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No Approvals',
      icon: Icons.approval_rounded,
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.campaign_rounded,
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.analytics_rounded,
    );
  }
}
