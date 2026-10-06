import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import '../../../shared/widgets/maya_loading.dart';
import '../../../shared/widgets/maya_error_view.dart';

class MetricsScreen extends ConsumerWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title:
              const Text('Metrics Dashboard', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(metricsProvider),
            ),
          ],
        ),
        body: Consumer(
          builder: (context, ref, _) {
            final metricsAsync = ref.watch(metricsProvider);

            return metricsAsync.when(
              data: (metrics) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Uptime Card
                    _MetricsCard(
                      title: 'Uptime',
                      value: _formatUptime(metrics.uptimeS),
                      icon: Icons.timer_rounded,
                      color: MayaTheme.neonCyan,
                    ),
                    const SizedBox(height: 16),

                    // Counters Section
                    const Text('Counters', style: MayaTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildCountersGrid(metrics.counters),
                    const SizedBox(height: 24),

                    // Latency Section
                    const Text('Latency (ms)', style: MayaTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (metrics.latency.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: MayaTheme.glassCard(),
                        child: const Center(
                          child: Text('No latency data yet',
                              style: MayaTheme.bodyMedium),
                        ),
                      )
                    else
                      _buildLatencyTable(metrics.latency),
                  ],
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
                ),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_rounded,
                        size: 48, color: MayaTheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading metrics',
                        style: MayaTheme.bodyMedium
                            .copyWith(color: MayaTheme.error)),
                    const SizedBox(height: 8),
                    Text(err.toString(),
                        style:
                            MayaTheme.bodySmall.copyWith(color: Colors.white38),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatUptime(double seconds) {
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m ${s.toInt()}s';
    if (m > 0) return '${m}m ${s.toInt()}s';
    return '${s.toStringAsFixed(1)}s';
  }

  Widget _buildCountersGrid(Map<String, dynamic> counters) {
    if (counters.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: MayaTheme.glassCard(),
        child: const Center(
          child: Text('No counters yet', style: MayaTheme.bodyMedium),
        ),
      );
    }

    final entries = counters.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: MayaTheme.glassCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.key,
                style: MayaTheme.labelSmall.copyWith(color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatNumber(entry.value),
                style: MayaTheme.headlineMedium
                    .copyWith(color: MayaTheme.neonCyan),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(dynamic value) {
    if (value is int) {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
      return value.toString();
    }
    if (value is double) {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }

  Widget _buildLatencyTable(Map<String, dynamic> latency) {
    final entries = latency.entries.toList()
      ..sort((a, b) => ((b.value['avg_ms'] as num?)?.toDouble() ?? 0.0)
          .compareTo((a.value['avg_ms'] as num?)?.toDouble() ?? 0.0));

    return Container(
      decoration: MayaTheme.glassCard(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: MayaTheme.slate800,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Endpoint', style: MayaTheme.labelMedium)),
                Expanded(
                    flex: 1,
                    child: Text('Count',
                        style: MayaTheme.labelMedium,
                        textAlign: TextAlign.center)),
                Expanded(
                    flex: 1,
                    child: Text('Avg (ms)',
                        style: MayaTheme.labelMedium,
                        textAlign: TextAlign.center)),
                Expanded(
                    flex: 1,
                    child: Text('P95 (ms)',
                        style: MayaTheme.labelMedium,
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Rows
          ...entries.map((entry) {
            final stats = entry.value as Map<String, dynamic>;
            final count = stats['count'] as int? ?? 0;
            final avgMs = (stats['avg_ms'] as num?)?.toDouble() ?? 0.0;
            final p95Ms = (stats['p95_ms'] as num?)?.toDouble() ?? 0.0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: MayaTheme.glassWhite10)),
              ),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(entry.key,
                          style: MayaTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Expanded(
                      flex: 1,
                      child: Text(count.toString(),
                          style: MayaTheme.bodySmall,
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 1,
                      child: Text(avgMs.toStringAsFixed(1),
                          style: MayaTheme.bodySmall,
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 1,
                      child: Text(p95Ms.toStringAsFixed(1),
                          style: MayaTheme.bodySmall,
                          textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: MayaTheme.glassCardGlow(glowColor: color),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        MayaTheme.labelMedium.copyWith(color: Colors.white54)),
                const SizedBox(height: 4),
                Text(value,
                    style: MayaTheme.headlineMedium.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricsSnapshot {
  final double uptimeS;
  final Map<String, dynamic> counters;
  final Map<String, dynamic> latency;

  MetricsSnapshot({
    required this.uptimeS,
    required this.counters,
    required this.latency,
  });

  factory MetricsSnapshot.fromJson(Map<String, dynamic> json) {
    return MetricsSnapshot(
      uptimeS: (json['uptime_s'] as num?)?.toDouble() ?? 0.0,
      counters: (json['counters'] as Map<String, dynamic>?) ?? {},
      latency: (json['latency'] as Map<String, dynamic>?) ?? {},
    );
  }
}

final metricsProvider = FutureProvider<MetricsSnapshot>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/metrics');
  return MetricsSnapshot.fromJson(response);
});
