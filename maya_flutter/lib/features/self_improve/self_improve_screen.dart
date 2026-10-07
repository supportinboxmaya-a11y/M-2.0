import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'self_improve_models.dart';
import 'self_improve_providers.dart';

class SelfImproveScreen extends ConsumerStatefulWidget {
  const SelfImproveScreen({super.key});

  @override
  ConsumerState<SelfImproveScreen> createState() => _SelfImproveScreenState();
}

class _SelfImproveScreenState extends ConsumerState<SelfImproveScreen>
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
          title: const Text('Self-Improvement', style: MayaTheme.headlineSmall),
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
                ref.invalidate(selfImproveStatusProvider);
                ref.invalidate(selfImproveProposalsProvider);
                ref.invalidate(selfImproveGapsProvider);
                ref.invalidate(selfImproveConfigProvider);
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
              Tab(icon: Icon(Icons.psychology_rounded), text: 'Status'),
              Tab(icon: Icon(Icons.lightbulb_rounded), text: 'Proposals'),
              Tab(icon: Icon(Icons.report_problem_rounded), text: 'Gaps'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Config'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _StatusTab(),
            _ProposalsTab(),
            _GapsTab(),
            _ConfigTab(),
          ],
        ),
      ),
    );
  }
}

class _StatusTab extends ConsumerWidget {
  const _StatusTab();

  Future<void> _triggerIteration(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson('/api/v1/self_improve/trigger');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Iteration triggered'),
              backgroundColor: MayaTheme.neonEmerald),
        );
        ref.invalidate(selfImproveStatusProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _toggleEnabled(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson('/api/v1/self_improve/toggle');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Toggled'), backgroundColor: MayaTheme.neonEmerald),
        );
        ref.invalidate(selfImproveStatusProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(selfImproveStatusProvider);

    return statusAsync.when(
      data: (status) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Self-Improvement Status', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Monitor and control Maya\'s self-improvement system',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCardGlow(
                glowColor: status.status == 'running'
                    ? MayaTheme.neonEmerald
                    : MayaTheme.neonOrange,
              ),
              child: Row(
                children: [
                  Icon(
                    status.status == 'running'
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    color: status.status == 'running'
                        ? MayaTheme.neonEmerald
                        : MayaTheme.neonOrange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.status.toUpperCase(),
                          style: MayaTheme.headlineMedium.copyWith(
                            color: status.status == 'running'
                                ? MayaTheme.neonEmerald
                                : MayaTheme.neonOrange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (status.currentProposal != null)
                          Text(
                            'Current: ${status.currentProposal}',
                            style: MayaTheme.bodySmall
                                .copyWith(color: Colors.white54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Iterations',
                        value: status.iterations.toString(),
                        color: MayaTheme.neonCyan,
                        icon: Icons.repeat_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Proposals',
                        value: status.proposals.toString(),
                        color: MayaTheme.neonViolet,
                        icon: Icons.lightbulb_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Accepted',
                        value: status.accepted.toString(),
                        color: MayaTheme.neonEmerald,
                        icon: Icons.check_circle_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Rejected',
                        value: status.rejected.toString(),
                        color: MayaTheme.error,
                        icon: Icons.cancel_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Actions', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _triggerIteration(context, ref),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Run Iteration Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleEnabled(context, ref),
                    icon: Icon(status.status == 'running'
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    label:
                        Text(status.status == 'running' ? 'Pause' : 'Enable'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: status.status == 'running'
                          ? MayaTheme.neonOrange
                          : MayaTheme.neonEmerald,
                      side: BorderSide(
                          color: status.status == 'running'
                              ? MayaTheme.neonOrange
                              : MayaTheme.neonEmerald),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
        const SizedBox(height: 16),
        Text('Error loading status',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _ProposalsTab extends ConsumerWidget {
  const _ProposalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(selfImproveProposalsProvider);

    return proposalsAsync.when(
      data: (response) => response.proposals.isEmpty
          ? const MayaEmptyState(
              'No improvement proposals generated yet',
              icon: Icons.lightbulb_rounded,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Improvement Proposals',
                      style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Proposed improvements awaiting review',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: response.proposals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final proposal = response.proposals[index];
                      return _ProposalCard(proposal: proposal);
                    },
                  ),
                ],
              ),
            ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
        const SizedBox(height: 16),
        Text('Error loading proposals',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final SelfImproveProposal proposal;

  const _ProposalCard({required this.proposal});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return MayaTheme.neonEmerald;
      case 'rejected':
        return MayaTheme.error;
      case 'pending':
        return MayaTheme.neonOrange;
      case 'reviewing':
        return MayaTheme.neonCyan;
      default:
        return Colors.white54;
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
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    color: MayaTheme.neonViolet, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proposal.description,
                        style: MayaTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                        'Created: ${proposal.createdAt.toString().substring(0, 19)}',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(proposal.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(proposal.status)),
                ),
                child: Text(proposal.status.toUpperCase(),
                    style: MayaTheme.labelSmall
                        .copyWith(color: _getStatusColor(proposal.status))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                  label: 'Confidence',
                  value: '${(proposal.confidence * 100).toStringAsFixed(1)}%',
                  color: MayaTheme.neonCyan),
              _InfoChip(
                  label: 'Status',
                  value: proposal.status.toUpperCase(),
                  color: _getStatusColor(proposal.status)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GapsTab extends ConsumerWidget {
  const _GapsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gapsAsync = ref.watch(selfImproveGapsProvider);

    return gapsAsync.when(
      data: (gaps) => gaps.gaps.isEmpty
          ? const MayaEmptyState(
              'No improvement gaps identified yet',
              icon: Icons.report_problem_rounded,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Improvement Gaps', style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Areas where Maya could improve',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gaps.gaps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final gap = gaps.gaps[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    MayaTheme.neonOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.report_problem_rounded,
                                  color: MayaTheme.neonOrange, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(gap, style: MayaTheme.bodyMedium),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
        const SizedBox(height: 16),
        Text('Error loading gaps',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _ConfigTab extends ConsumerWidget {
  const _ConfigTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(selfImproveConfigProvider);

    return configAsync.when(
      data: (config) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Self-Improvement Configuration',
                style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Configure the self-improvement system behavior',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('General Settings', style: MayaTheme.titleMedium),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enabled', style: MayaTheme.bodyMedium),
                    subtitle: Text('Enable/disable self-improvement',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                    value: config.enabled,
                    activeThumbColor: MayaTheme.neonEmerald,
                    onChanged: (value) =>
                        _updateConfig(context, ref, enabled: value),
                  ),
                  const SizedBox(height: 16),
                  Text('Interval: ${config.intervalMinutes} minutes',
                      style: MayaTheme.bodyMedium),
                  Slider(
                    value: config.intervalMinutes.toDouble(),
                    min: 5,
                    max: 1440,
                    divisions: 287,
                    activeColor: MayaTheme.neonCyan,
                    inactiveColor: Colors.white24,
                    onChanged: (value) {},
                    onChangeEnd: (value) => _updateConfig(context, ref,
                        intervalMinutes: value.toInt()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'Threshold: ${(config.threshold * 100).toStringAsFixed(0)}%',
                      style: MayaTheme.bodyMedium),
                  Slider(
                    value: config.threshold,
                    min: 0.1,
                    max: 1.0,
                    divisions: 90,
                    activeColor: MayaTheme.neonCyan,
                    inactiveColor: Colors.white24,
                    onChanged: (value) {},
                    onChangeEnd: (value) =>
                        _updateConfig(context, ref, threshold: value),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveConfig(context, ref),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Configuration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MayaTheme.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
        const SizedBox(height: 16),
        Text('Error loading config',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }

  Future<void> _updateConfig(BuildContext context, WidgetRef ref,
      {bool? enabled, int? intervalMinutes, double? threshold}) async {
    try {
      final api = ref.read(mayaApiProvider);
      final data = <String, dynamic>{};
      if (enabled != null) data['enabled'] = enabled;
      if (intervalMinutes != null) data['interval_minutes'] = intervalMinutes;
      if (threshold != null) data['threshold'] = threshold;
      await api.postJson('/api/v1/self_improve/config', data: data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Config updated'),
              backgroundColor: MayaTheme.neonEmerald),
        );
        ref.invalidate(selfImproveConfigProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _saveConfig(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Configuration saved'),
          backgroundColor: MayaTheme.neonEmerald),
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
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text('$label: $value',
          style: MayaTheme.labelSmall.copyWith(color: color)),
    );
  }
}
