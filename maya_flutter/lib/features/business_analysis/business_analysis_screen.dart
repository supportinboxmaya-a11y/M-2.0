import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final businessMissionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.businessListMissions();
});

final businessReportsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.businessListReports();
});

final businessRunAnalysisProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, missionId) async {
  final api = ref.watch(mayaApiProvider);
  return api.businessRunAnalysis(missionId: missionId);
});

final businessReportDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, reportId) async {
  final api = ref.watch(mayaApiProvider);
  return api.businessGetReport(reportId);
});

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
              onPressed: () {
                ref.invalidate(businessMissionsProvider);
                ref.invalidate(businessReportsProvider);
              },
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
    final missionsAsync = ref.watch(businessMissionsProvider);
    final reportsAsync = ref.watch(businessReportsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Missions', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Available missions for business analysis and reporting.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          missionsAsync.map(
            data: (data) {
              final missions = data.value['missions'] as List? ?? [];
              if (missions.isEmpty) {
                return const MayaEmptyState(
                  'No Business Missions',
                  icon: Icons.business_rounded,
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: missions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final mission = missions[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: MayaTheme.glassCard(),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.business_rounded, color: MayaTheme.neonCyan, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mission['name'] ?? 'Unnamed Mission', style: MayaTheme.titleMedium),
                              Text(mission['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: MayaTheme.neonCyan),
                          ),
                          child: Text(
                            mission['status']?.toUpperCase() ?? 'ACTIVE',
                            style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading missions', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Reports', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          reportsAsync.map(
            data: (data) {
              final reports = data.value['reports'] as List? ?? [];
              if (reports.isEmpty) {
                return const MayaEmptyState(
                  'No Reports',
                  icon: Icons.description_rounded,
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final report = reports[index];
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
                          child: const Icon(Icons.description_rounded, color: MayaTheme.neonViolet, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(report['title'] ?? 'Untitled Report', style: MayaTheme.titleMedium),
                              Text('${report['missionName'] ?? 'Unknown Mission'} • ${report['createdAt']?.toString().substring(0, 10) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: MayaTheme.neonCyan),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading reports', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
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
}

class _RunAnalysisTab extends ConsumerWidget {
  const _RunAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(businessMissionsProvider);

    return missionsAsync.map(
      data: (data) {
        final missions = data.value['missions'] as List? ?? [];
        if (missions.isEmpty) {
          return const MayaEmptyState(
            'No Missions Available',
            icon: Icons.analytics_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: missions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final mission = missions[index];
            return _MissionAnalysisCard(mission: mission);
          },
        );
      },
      loading: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading missions', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _MissionAnalysisCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> mission;

  const _MissionAnalysisCard({required this.mission, super.key});

  @override
  ConsumerState<_MissionAnalysisCard> createState() => _MissionAnalysisCardState();
}

class _MissionAnalysisCardState extends ConsumerState<_MissionAnalysisCard> {
  bool _isRunning = false;
  Map<String, dynamic>? _result;

  Future<void> _runAnalysis() async {
    setState(() => _isRunning = true);
    try {
      final result = await ref.read(mayaApiProvider).businessRunAnalysis(missionId: widget.mission['id'] ?? '');
      if (mounted) {
        setState(() {
          _result = result;
          _isRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.analytics_rounded, color: MayaTheme.neonCyan, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.mission['name'] ?? 'Unnamed Mission', style: MayaTheme.titleMedium),
                    Text(widget.mission['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_result != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MayaTheme.neonEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MayaTheme.neonEmerald.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: MayaTheme.neonEmerald, size: 20),
                      const SizedBox(width: 8),
                      Text('Analysis Complete', style: MayaTheme.titleSmall.copyWith(color: MayaTheme.neonEmerald)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Report ID: ${_result!['reportId'] ?? 'N/A'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
                  Text('Status: ${_result!['status'] ?? 'completed'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  Text('Insights: ${_result!['insights']?.length ?? 0} found', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runAnalysis,
              icon: _isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_isRunning ? 'Running...' : 'Run Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailTab extends ConsumerWidget {
  const _ReportDetailTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(businessReportsProvider);

    return reportsAsync.map(
      data: (data) {
        final reports = data.value['reports'] as List? ?? [];
        if (reports.isEmpty) {
          return const MayaEmptyState(
            'No Reports Available',
            icon: Icons.description_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final report = reports[index];
            return _ReportDetailCard(report: report);
          },
        );
      },
      loading: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading reports', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailCard extends ConsumerWidget {
  final Map<String, dynamic> report;

  const _ReportDetailCard({required this.report, super.key});

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
                child: const Icon(Icons.description_rounded, color: MayaTheme.neonViolet, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report['title'] ?? 'Untitled Report', style: MayaTheme.titleMedium),
                    Text('Mission: ${report['missionName'] ?? 'Unknown'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
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
                  report['status']?.toUpperCase() ?? 'COMPLETED',
                  style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(report['summary'] ?? 'No summary available', style: MayaTheme.bodySmall.copyWith(color: Colors.white70), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Created: ${report['createdAt']?.toString().substring(0, 19) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38, fontFamily: 'monospace')),
              const Spacer(),
              Text('Report ID: ${report['id'] ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}