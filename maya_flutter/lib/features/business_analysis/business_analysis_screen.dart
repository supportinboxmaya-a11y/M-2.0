import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class BusinessAnalysisScreen extends ConsumerStatefulWidget {
  const BusinessAnalysisScreen({super.key});

  @override
  ConsumerState<BusinessAnalysisScreen> createState() =>
      _BusinessAnalysisScreenState();
}

class _BusinessAnalysisScreenState extends ConsumerState<BusinessAnalysisScreen>
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
              const Text('Business Analysis', style: MayaTheme.headlineSmall),
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
              Tab(
                  icon: Icon(Icons.business_rounded),
                  text: 'Missions & Reports'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Run Analysis'),
              Tab(icon: Icon(Icons.description_rounded), text: 'Report Detail'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _MissionsTab(),
            _RunAnalysisTab(),
            _ReportDetailTab(),
          ],
        ),
      ),
    );
  }
}

class _MissionsTab extends ConsumerWidget {
  const _MissionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No Business Missions',
      icon: Icons.business_rounded,
    );
  }
}

class _RunAnalysisTab extends ConsumerWidget {
  const _RunAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.analytics_rounded,
    );
  }
}

class _ReportDetailTab extends ConsumerWidget {
  const _ReportDetailTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.description_rounded,
    );
  }
}
