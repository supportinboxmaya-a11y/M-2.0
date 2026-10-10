import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class ApiKeyProvisionerScreen extends ConsumerStatefulWidget {
  const ApiKeyProvisionerScreen({super.key});

  @override
  ConsumerState<ApiKeyProvisionerScreen> createState() =>
      _ApiKeyProvisionerScreenState();
}

class _ApiKeyProvisionerScreenState
    extends ConsumerState<ApiKeyProvisionerScreen>
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
              const Text('API Key Provisioner', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.search_rounded), text: 'Scan Free APIs'),
              Tab(icon: Icon(Icons.key_rounded), text: 'Provision Key'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Audit Log'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ScanFreeApisTab(),
            _ProvisionKeyTab(),
            _AuditTab(),
          ],
        ),
      ),
    );
  }
}

class _ScanFreeApisTab extends ConsumerWidget {
  const _ScanFreeApisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.search_rounded,
    );
  }
}

class _ProvisionKeyTab extends ConsumerWidget {
  const _ProvisionKeyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
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
