import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class EnterpriseScreen extends ConsumerStatefulWidget {
  const EnterpriseScreen({super.key});

  @override
  ConsumerState<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends ConsumerState<EnterpriseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          title: const Text('Enterprise Layer', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.security_rounded), text: 'RBAC'),
              Tab(icon: Icon(Icons.groups_rounded), text: 'Organizations'),
              Tab(icon: Icon(Icons.key_rounded), text: 'API Keys'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Audit Log'),
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _RBTab(),
            _OrgsTab(),
            _ApiKeysTab(),
            _AuditTab(),
            _DashboardTab(),
          ],
        ),
      ),
    );
  }
}

class _RBTab extends ConsumerWidget {
  const _RBTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No roles found',
      icon: Icons.security_rounded,
    );
  }
}

class _OrgsTab extends ConsumerWidget {
  const _OrgsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No organizations',
      icon: Icons.groups_rounded,
    );
  }
}

class _ApiKeysTab extends ConsumerWidget {
  const _ApiKeysTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No API keys yet',
      icon: Icons.key_rounded,
    );
  }
}

class _AuditTab extends ConsumerWidget {
  const _AuditTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.history_rounded,
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.dashboard_rounded,
    );
  }
}
