import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final growthProposalsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.growthListProposals(limit: 50);
});

final growthMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.growthGetMetrics(limit: 30);
});

final growthRecommendationsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.growthGetRecommendations(limit: 50);
});

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
              onPressed: () {
                ref.invalidate(growthProposalsProvider);
                ref.invalidate(growthMetricsProvider);
                ref.invalidate(growthRecommendationsProvider);
              },
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
    final proposalsAsync = ref.watch(growthProposalsProvider);

    return proposalsAsync.when(
      data: (data) {
        final proposals = data['proposals'] as List? ?? [];
        if (proposals.isEmpty) {
          return const MayaEmptyState(
            'No Proposals',
            message: 'Submit a growth proposal to get started',
            icon: Icons.lightbulb_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: proposals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final proposal = proposals[index];
            return _ProposalCard(proposal: proposal);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading proposals', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _ProposalCard extends ConsumerWidget {
  final Map<String, dynamic> proposal;

  const _ProposalCard({required this.proposal});

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
                child: const Icon(Icons.lightbulb_rounded, color: MayaTheme.neonViolet, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proposal['title'] ?? '', style: MayaTheme.titleMedium),
                    Text(proposal['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(proposal['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(proposal['status'])),
                ),
                child: Text(
                  proposal['status']?.toString().toUpperCase() ?? 'PENDING',
                  style: MayaTheme.labelSmall.copyWith(color: _getStatusColor(proposal['status'])),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Project: ${proposal['projectId'] ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
              const Spacer(),
              Text('Impact: ${proposal['impactScore']?.toStringAsFixed(1) ?? '0'}', style: MayaTheme.bodySmall.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
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
        case 'implemented':
          return MayaTheme.neonCyan;
        default:
          return Colors.white54;
      }
    }
  }
}

class _MetricsTab extends ConsumerWidget {
  const _MetricsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(growthMetricsProvider);

    return metricsAsync.when(
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Growth Metrics', style: MayaTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Portfolio performance metrics across all projects',
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              // Stats cards would go here
              const MayaEmptyState(
                'Endpoint not connected',
                icon: Icons.trending_up_rounded,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading metrics', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsTab extends ConsumerWidget {
  const _RecommendationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(growthRecommendationsProvider);

    return recsAsync.when(
      data: (data) {
        final recs = data['recommendations'] as List? ?? [];
        if (recs.isEmpty) {
          return const MayaEmptyState(
            'No Recommendations',
            message: 'Run a portfolio review to generate recommendations',
            icon: Icons.recommend_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: recs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final rec = recs[index];
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
                        child: const Icon(Icons.recommend_rounded, color: MayaTheme.neonViolet, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec['action']?.toString() ?? '', style: MayaTheme.titleMedium),
                            Text(rec['rationale'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rec['confidence'] != null && rec['confidence'] > 0.8
                              ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                              : MayaTheme.neonOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rec['confidence'] != null && rec['confidence'] > 0.8 ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                        ),
                        child: Text(
                          'Confidence: ${(rec['confidence'] != null ? (rec['confidence'] * 100).toStringAsFixed(1) : 'N/A')}%',
                          style: MayaTheme.labelSmall.copyWith(color: rec['confidence'] != null && rec['confidence'] > 0.8 ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(rec['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Project: ${rec['projectId'] ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MayaTheme.neonViolet),
                        ),
                        child: Text(
                          'Confidence: ${rec['confidence'] != null ? (rec['confidence'] * 100).toStringAsFixed(1) : 'N/A'}%',
                          style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading recommendations', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}