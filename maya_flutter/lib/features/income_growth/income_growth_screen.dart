import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class IncomeGrowthScreen extends ConsumerStatefulWidget {
  const IncomeGrowthScreen({super.key});

  @override
  ConsumerState<IncomeGrowthScreen> createState() => _IncomeGrowthScreenState();
}

class _IncomeGrowthScreenState extends ConsumerState<IncomeGrowthScreen>
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
          title: const Text('Growth Portfolio', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.lightbulb_rounded), text: 'Proposals'),
              Tab(icon: Icon(Icons.trending_up_rounded), text: 'Metrics'),
              Tab(icon: Icon(Icons.recommend_rounded), text: 'Recommendations'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ProposalsTab(),
            _MetricsTab(),
            _RecommendationsTab(),
          ],
        ),
      ),
    );
  }
}

class _ProposalsTab extends ConsumerWidget {
  const _ProposalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No Proposals',
      icon: Icons.lightbulb_rounded,
    );
  }
}

class _MetricsTab extends ConsumerWidget {
  const _MetricsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.trending_up_rounded,
    );
  }
}

class _RecommendationsTab extends ConsumerWidget {
  const _RecommendationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.recommend_rounded,
    );
  }
}
