import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final scoutScanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.scoutTriggerScan();
});

final scoutScanHistoryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.scoutGetScanHistory(limit: 20);
});

final scoutSignalsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.scoutGetSignals(limit: 50);
});

final scoutOpportunitiesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.scoutListOpportunities(limit: 50);
});

final scoutStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.scoutGetStats();
});

class IncomeScoutScreen extends ConsumerStatefulWidget {
  const IncomeScoutScreen({super.key});

  @override
  ConsumerState<IncomeScoutScreen> createState() => _IncomeScoutScreenState();
}

class _IncomeScoutScreenState extends ConsumerState<IncomeScoutScreen>
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
          title: const Text('Income Scout', style: MayaTheme.headlineSmall),
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
                ref.invalidate(scoutScanProvider);
                ref.invalidate(scoutScanHistoryProvider);
                ref.invalidate(scoutSignalsProvider);
                ref.invalidate(scoutOpportunitiesProvider);
                ref.invalidate(scoutStatsProvider);
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
              Tab(icon: Icon(Icons.radar_rounded), text: 'Scan'),
              Tab(icon: Icon(Icons.signal_cellular_alt_rounded), text: 'Signals'),
              Tab(icon: Icon(Icons.flag_rounded), text: 'Opportunities'),
              Tab(icon: Icon(Icons.settings_rounded), text: 'Config'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ScanTab(),
            _SignalsTab(),
            _OpportunitiesTab(),
            _ConfigTab(),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends ConsumerWidget {
  const _ScanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(scoutScanHistoryProvider);
    final statsAsync = ref.watch(scoutStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Run Scout Scan', style: MayaTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Scans Reddit, Hacker News, and other sources for new income opportunities.',
                  style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                const MayaEmptyState(
                  'Endpoint not connected',
                  icon: Icons.radar_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Scan History
          const Text('Scan History', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          historyAsync.when(
            data: (data) {
              final scans = data['scans'] as List? ?? [];
              if (scans.isEmpty) {
                return const MayaEmptyState(
                  'No Scans Yet',
                  icon: Icons.history_rounded,
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: scans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final scan = scans[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: MayaTheme.glassCard(),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scan['status'] == 'completed'
                                ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                                : MayaTheme.neonOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            scan['status'] == 'completed'
                                ? Icons.check_circle_rounded
                                : Icons.hourglass_empty_rounded,
                            color: scan['status'] == 'completed'
                                ? MayaTheme.neonEmerald
                                : MayaTheme.neonOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Scan ${scan['scanId']}', style: MayaTheme.titleMedium),
                              Text('${scan['signals']} signals \u2022 ${scan['opportunities']} opportunities',
                                  style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                              Text(scan['timestamp'].toString().substring(0, 19),
                                  style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scan['status'] == 'completed'
                                ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                                : MayaTheme.neonOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: scan['status'] == 'completed'
                                      ? MayaTheme.neonEmerald
                                      : MayaTheme.neonOrange,
                                ),
                          ),
                          child: Text(
                            scan['status'].toUpperCase(),
                            style: MayaTheme.labelSmall.copyWith(
                              color: scan['status'] == 'completed'
                                  ? MayaTheme.neonEmerald
                                  : MayaTheme.neonOrange),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            loading: () => const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
            ),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          // Stats
          const Text('Statistics', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(child: _ScoutStatCard(label: 'Total Scans', value: stats['totalScans'].toString(), color: MayaTheme.neonCyan, icon: Icons.radar_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _ScoutStatCard(label: 'Total Signals', value: stats['totalSignals'].toString(), color: MayaTheme.neonViolet, icon: Icons.signal_cellular_alt_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _ScoutStatCard(label: 'Total Opportunities', value: stats['totalOpportunities'].toString(), color: MayaTheme.neonEmerald, icon: Icons.flag_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _ScoutStatCard(label: 'Avg Score', value: stats['avgScore'].toStringAsFixed(2), color: MayaTheme.neonOrange, icon: Icons.trending_up_rounded)),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SignalsTab extends ConsumerWidget {
  const _SignalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalsAsync = ref.watch(scoutSignalsProvider);

    return signalsAsync.when(
      data: (data) {
        final signals = data['signals'] as List? ?? [];
        if (signals.isEmpty) {
          return const MayaEmptyState(
            'No Signals',
            icon: Icons.signal_cellular_alt_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: signals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final signal = signals[index];
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
                    child: const Icon(Icons.signal_cellular_alt_rounded, color: MayaTheme.neonViolet, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(signal['title'] ?? '', style: MayaTheme.titleMedium),
                        Text(signal['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MayaTheme.neonViolet),
                    ),
                    child: Text(
                      'Signal: ${signal['type'] ?? 'unknown'}',
                      style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
    );
  }
}

class _OpportunitiesTab extends ConsumerWidget {
  const _OpportunitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunitiesAsync = ref.watch(scoutOpportunitiesProvider);

    return opportunitiesAsync.when(
      data: (data) {
        final opps = data['opportunities'] as List? ?? [];
        if (opps.isEmpty) {
          return const MayaEmptyState(
            'No Opportunities',
            icon: Icons.flag_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: opps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final opp = opps[index];
            return _OpportunityCard(opp: opp);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading opportunities', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _OpportunityCard extends ConsumerWidget {
  final Map<String, dynamic> opp;

  const _OpportunityCard({required this.opp});

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
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded, color: MayaTheme.neonCyan, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opp['title'] ?? '', style: MayaTheme.titleMedium),
                    Text(opp['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(opp['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(opp['status'])),
                ),
                child: Text(
                  opp['status']?.toUpperCase() ?? 'PENDING',
                  style: MayaTheme.labelSmall.copyWith(color: _getStatusColor(opp['status'])),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Source: ${opp['sourceCategory'] ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              const Spacer(),
              Text('Score: ${(opp['totalScore'] * 100).toStringAsFixed(1)}%', style: MayaTheme.bodySmall.copyWith(color: MayaTheme.neonEmerald, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
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
}

class _ConfigTab extends ConsumerWidget {
  const _ConfigTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.settings_rounded,
    );
  }
}

class _ScoutStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ScoutStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
          Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    }
  }
}