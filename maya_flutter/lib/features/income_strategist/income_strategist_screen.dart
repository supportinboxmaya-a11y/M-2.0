import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class IncomeStrategistScreen extends ConsumerStatefulWidget {
  const IncomeStrategistScreen({super.key});

  @override
  ConsumerState<IncomeStrategistScreen> createState() =>
      _IncomeStrategistScreenState();
}

class _IncomeStrategistScreenState extends ConsumerState<IncomeStrategistScreen>
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
              const Text('Income Strategist', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.rate_review_rounded), text: 'Reviews'),
              Tab(icon: Icon(Icons.assignment_rounded), text: 'Plans'),
              Tab(icon: Icon(Icons.leaderboard_rounded), text: 'Ranked'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ReviewsTab(),
            _PlansTab(),
            _RankedTab(),
          ],
        ),
      ),
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No Reviews',
      icon: Icons.rate_review_rounded,
    );
  }
}

class _PlansTab extends ConsumerWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.assignment_rounded,
    );
  }
}

class _RankedTab extends ConsumerWidget {
  const _RankedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.leaderboard_rounded,
    );
  }
}
