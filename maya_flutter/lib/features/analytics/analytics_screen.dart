import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final analyticsSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.analyticsGetSummary();
});

final analyticsDailyProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.analyticsGetDaily();
});

final analyticsProvidersProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.analyticsGetProviders();
});

final analyticsToolsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.analyticsGetTools();
});

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
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
          title: const Text('Analytics', style: MayaTheme.headlineSmall),
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
                ref.invalidate(analyticsSummaryProvider);
                ref.invalidate(analyticsDailyProvider);
                ref.invalidate(analyticsProvidersProvider);
                ref.invalidate(analyticsToolsProvider);
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
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Summary'),
              Tab(icon: Icon(Icons.calendar_today_rounded), text: 'Daily'),
              Tab(icon: Icon(Icons.memory_rounded), text: 'Providers'),
              Tab(icon: Icon(Icons.build_rounded), text: 'Tools'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _SummaryTab(),
            _DailyTab(),
            _ProvidersTab(),
            _ToolsTab(),
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);

    return summaryAsync.when(
      data: (summary) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analytics Summary', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'High-level overview of system metrics.',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Total Requests',
                        value: summary['totalRequests']?.toString() ?? '0',
                        color: MayaTheme.neonCyan,
                        icon: Icons.dashboard_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Success Rate',
                        value:
                            '${(summary['successRate'] ?? 0.0).toStringAsFixed(1)}%',
                        color: MayaTheme.neonEmerald,
                        icon: Icons.check_circle_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Avg Latency',
                        value:
                            '${summary['avgLatencyMs']?.toString() ?? '0'}ms',
                        color: MayaTheme.neonOrange,
                        icon: Icons.speed_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Error Rate',
                        value:
                            '${(summary['errorRate'] ?? 0.0).toStringAsFixed(2)}%',
                        color: MayaTheme.error,
                        icon: Icons.error_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Top Endpoints', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            ...(summary['topEndpoints'] as List? ?? [])
                .map((ep) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: MayaTheme.glassCard(),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: MayaTheme.neonCyan),
                            ),
                            child: Text(ep['method'] ?? 'GET',
                                style: MayaTheme.labelSmall.copyWith(
                                    color: MayaTheme.neonCyan,
                                    fontFamily: 'monospace')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(ep['path'] ?? '',
                                  style: MayaTheme.bodySmall
                                      .copyWith(fontFamily: 'monospace'))),
                          Text('${ep['count'] ?? 0} calls',
                              style: MayaTheme.bodySmall
                                  .copyWith(color: Colors.white54)),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading summary',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _DailyTab extends ConsumerWidget {
  const _DailyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(analyticsDailyProvider);

    return dailyAsync.when(
      data: (data) {
        final daily = data['daily'] as List? ?? [];
        if (daily.isEmpty) {
          return const MayaEmptyState(
            'No Daily Data',
            icon: Icons.calendar_today_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: daily.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final day = daily[index];
            return Container(
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(day['date'] ?? '', style: MayaTheme.titleMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: day['successRate'] != null &&
                                    day['successRate'] > 95
                                ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                                : MayaTheme.neonOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: day['successRate'] != null &&
                                        day['successRate'] > 95
                                    ? MayaTheme.neonEmerald
                                    : MayaTheme.neonOrange),
                          ),
                          child: Text(
                            '${day['successRate']?.toStringAsFixed(1) ?? '0.0'}% success',
                            style: MayaTheme.labelSmall.copyWith(
                                color: day['successRate'] != null &&
                                        day['successRate'] > 95
                                    ? MayaTheme.neonEmerald
                                    : MayaTheme.neonOrange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _MiniStat(
                                label: 'Requests',
                                value: day['requestCount']?.toString() ?? '0',
                                color: MayaTheme.neonCyan)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Avg Latency',
                                value: '${day['avgLatencyMs'] ?? '0'}ms',
                                color: MayaTheme.neonViolet)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Errors',
                                value: day['errorCount']?.toString() ?? '0',
                                color: MayaTheme.error)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Unique Users',
                                value: day['uniqueUsers']?.toString() ?? '0',
                                color: MayaTheme.neonEmerald)),
                      ],
                    ),
                  ],
                ));
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading daily data',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _ProvidersTab extends ConsumerWidget {
  const _ProvidersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(analyticsProvidersProvider);

    return providersAsync.when(
      data: (data) {
        final providers = data['providers'] as List? ?? [];
        if (providers.isEmpty) {
          return const MayaEmptyState(
            'No Provider Data',
            icon: Icons.memory_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: providers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final provider = providers[index];
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
                          child: const Icon(Icons.memory_rounded,
                              color: MayaTheme.neonViolet, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(provider['name'] ?? 'Unknown Provider',
                                  style: MayaTheme.titleMedium),
                              Text('Type: ${provider['type'] ?? 'N/A'}',
                                  style: MayaTheme.bodySmall
                                      .copyWith(color: Colors.white54)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: MayaTheme.neonViolet),
                          ),
                          child: Text(
                            provider['status']?.toUpperCase() ?? 'ACTIVE',
                            style: MayaTheme.labelSmall
                                .copyWith(color: MayaTheme.neonViolet),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _MiniStat(
                                label: 'Requests',
                                value:
                                    provider['requestCount']?.toString() ?? '0',
                                color: MayaTheme.neonCyan)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Avg Latency',
                                value: '${provider['avgLatencyMs'] ?? '0'}ms',
                                color: MayaTheme.neonViolet)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Error Rate',
                                value:
                                    '${(provider['errorRate'] ?? 0.0).toStringAsFixed(2)}%',
                                color: MayaTheme.error)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Uptime',
                                value:
                                    '${(provider['uptime'] ?? 100.0).toStringAsFixed(1)}%',
                                color: MayaTheme.neonEmerald)),
                      ],
                    ),
                  ],
                ));
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading providers',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _ToolsTab extends ConsumerWidget {
  const _ToolsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(analyticsToolsProvider);

    return toolsAsync.when(
      data: (data) {
        final tools = data['tools'] as List? ?? [];
        if (tools.isEmpty) {
          return const MayaEmptyState(
            'No Tool Data',
            icon: Icons.build_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tools.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final tool = tools[index];
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
                            color: MayaTheme.neonOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.build_rounded,
                              color: MayaTheme.neonOrange, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tool['name'] ?? 'Unknown Tool',
                                  style: MayaTheme.titleMedium),
                              Text('Category: ${tool['category'] ?? 'N/A'}',
                                  style: MayaTheme.bodySmall
                                      .copyWith(color: Colors.white54)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MayaTheme.neonOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: MayaTheme.neonOrange),
                          ),
                          child: Text(
                            tool['status']?.toUpperCase() ?? 'ENABLED',
                            style: MayaTheme.labelSmall
                                .copyWith(color: MayaTheme.neonOrange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _MiniStat(
                                label: 'Invocations',
                                value:
                                    tool['invocationCount']?.toString() ?? '0',
                                color: MayaTheme.neonCyan)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Avg Duration',
                                value: '${tool['avgDurationMs'] ?? '0'}ms',
                                color: MayaTheme.neonViolet)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Success Rate',
                                value:
                                    '${(tool['successRate'] ?? 0.0).toStringAsFixed(1)}%',
                                color: MayaTheme.neonEmerald)),
                        Expanded(
                            child: _MiniStat(
                                label: 'Cost',
                                value:
                                    '\$${(tool['cost'] ?? 0.0).toStringAsFixed(4)}',
                                color: MayaTheme.neonOrange)),
                      ],
                    ),
                  ],
                ));
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading tools',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCardGlow(glowColor: color),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: MayaTheme.headlineMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: MayaTheme.titleSmall
                .copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
      ],
    );
  }
}
