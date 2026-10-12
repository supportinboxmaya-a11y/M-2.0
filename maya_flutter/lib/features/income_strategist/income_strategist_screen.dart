import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final strategistReviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.strategistTriggerReview();
});

final strategistReviewHistoryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.strategistGetReviewHistory(limit: 20);
});

final strategistPlansProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.strategistListPlans(limit: 20);
});

final strategistRankedProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.strategistGetRankedOpportunities(limit: 20);
});

final strategistConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.strategistGetConfig();
});

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
              onPressed: () {
                ref.invalidate(strategistReviewProvider);
                ref.invalidate(strategistReviewHistoryProvider);
                ref.invalidate(strategistPlansProvider);
                ref.invalidate(strategistRankedProvider);
                ref.invalidate(strategistConfigProvider);
              },
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
    final reviewAsync = ref.watch(strategistReviewProvider);

    return reviewAsync.map(
      data: (data) => _buildReviewsTab(data.value, ref),
      loading: (_) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading review', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

Widget _buildReviewsTab(Map<String, dynamic> data, WidgetRef ref) {
  final historyAsync = ref.watch(strategistReviewHistoryProvider);
  final reviewAsync = ref.watch(strategistReviewProvider);

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daily Strategy Review', style: MayaTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Run a comprehensive review of opportunities and generate strategic plans.',
          style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
        ),
        const SizedBox(height: 24),
        reviewAsync.map(
          data: (data) {
            final result = data.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(strategistReviewProvider),
                  icon: const Icon(Icons.rate_review_rounded),
                  label: const Text('Run Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                if (result['reviewId'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: MayaTheme.glassCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Review Complete', style: MayaTheme.titleMedium.copyWith(color: MayaTheme.neonEmerald)),
                        const SizedBox(height: 8),
                        Text('Review ID: ${result['reviewId']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
                        Text('Opportunities Reviewed: ${result['opportunitiesReviewed'] ?? 0}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                        Text('Plans Created: ${result['plansCreated'] ?? 0}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                        if (result['timestamp'] != null)
                          Text('Timestamp: ${result['timestamp'].toString().substring(0, 19)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
          loading: (_) => const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
          ),
          error: (err) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(strategistReviewProvider),
                icon: const Icon(Icons.rate_review_rounded),
                label: const Text('Run Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MayaTheme.neonCyan,
                  foregroundColor: MayaTheme.slate900,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              Text('Error: ${err.error}', style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Review History', style: MayaTheme.titleMedium),
        const SizedBox(height: 12),
        historyAsync.map(
          data: (data) => _buildReviewHistoryList(data.value),
          loading: (_) => const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
          ),
          error: (err) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                const SizedBox(height: 16),
                Text('Error loading reviews', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                const SizedBox(height: 8),
                Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildReviewHistoryList(Map<String, dynamic> data) {
  final reviews = data['reviews'] as List? ?? [];
  if (reviews.isEmpty) {
    return const MayaEmptyState(
      'No Reviews',
      icon: Icons.rate_review_rounded,
    );
  }
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: reviews.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, index) {
      final review = reviews[index];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: MayaTheme.glassCard(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rate_review_rounded, color: MayaTheme.neonViolet, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Review ${review['reviewId']}', style: MayaTheme.titleMedium),
                  Text('${review['opportunitiesReviewed']} opportunities \u2022 ${review['plansCreated']} plans',
                      style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  Text(review['timestamp'].toString().substring(0, 19),
                      style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PlansTab extends ConsumerWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(strategistPlansProvider);

    return plansAsync.map(
      data: (data) => _buildPlansList(data.value),
      loading: (_) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading plans', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

Widget _buildPlansList(Map<String, dynamic> data) {
  final plans = data['plans'] as List? ?? [];
  if (plans.isEmpty) {
    return const MayaEmptyState(
      'No Plans',
      icon: Icons.assignment_rounded,
    );
  }

  return ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: plans.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, index) {
      final plan = plans[index];
      return _PlanCard(plan: plan);
    },
  );
}

class _PlanCard extends ConsumerWidget {
  final Map<String, dynamic> plan;

  const _PlanCard({required this.plan, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded, color: MayaTheme.neonViolet, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan['title'] ?? '', style: MayaTheme.titleMedium),
                    Text(
                      plan['description'] ?? '',
                      style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(plan['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(plan['status'])),
                ),
                child: Text(
                  plan['status']?.toUpperCase() ?? 'DRAFT',
                  style: MayaTheme.labelSmall.copyWith(color: _getStatusColor(plan['status'])),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Opp ID: ${plan['opportunityId'] ?? ''}',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace'),
              ),
              const Spacer(),
              Text(
                'Created: ${plan['createdAt']?.toString().substring(0, 10) ?? ''}',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return MayaTheme.neonEmerald;
      case 'pending':
        return MayaTheme.neonOrange;
      case 'rejected':
        return MayaTheme.error;
      default:
        return Colors.white54;
    }
  }
}

class _RankedTab extends ConsumerWidget {
  const _RankedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankedAsync = ref.watch(strategistRankedProvider);

    return rankedAsync.map(
      data: (data) => _buildRankedList(data.value),
      loading: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading ranked', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

Widget _buildRankedList(Map<String, dynamic> data) {
  final opps = data['opportunities'] as List? ?? [];
  if (opps.isEmpty) {
    return const MayaEmptyState(
      'No Ranked Opportunities',
      icon: Icons.leaderboard_rounded,
    );
  }

  return ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: opps.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, index) {
      final opp = opps[index];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: MayaTheme.glassCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('#${index + 1}', style: MayaTheme.labelMedium.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opp['title'] ?? '', style: MayaTheme.titleMedium),
                      Text(opp['reason'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}