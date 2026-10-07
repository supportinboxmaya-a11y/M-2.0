import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'unified_cognitive_loop_models.dart';
import 'unified_cognitive_loop_providers.dart';

class UnifiedCognitiveLoopScreen extends ConsumerStatefulWidget {
  const UnifiedCognitiveLoopScreen({super.key});

  @override
  ConsumerState<UnifiedCognitiveLoopScreen> createState() =>
      _UnifiedCognitiveLoopScreenState();
}

class _UnifiedCognitiveLoopScreenState
    extends ConsumerState<UnifiedCognitiveLoopScreen>
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
          title: const Text('Unified Cognitive Loop',
              style: MayaTheme.headlineSmall),
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
                ref.invalidate(unifiedLoopStatusProvider);
                ref.invalidate(unifiedLoopHistoryProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.psychology_rounded), text: 'Status'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Controls'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _StatusTab(),
            _HistoryTab(),
            _ControlsTab(),
          ],
        ),
      ),
    );
  }
}

class _StatusTab extends ConsumerWidget {
  const _StatusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(unifiedLoopStatusProvider);

    return statusAsync.when(
      data: (status) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cognitive Loop Status', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Real-time status of the unified cognitive loop',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCardGlow(
                glowColor: status.state == 'running'
                    ? MayaTheme.neonEmerald
                    : MayaTheme.neonOrange,
              ),
              child: Row(
                children: [
                  Icon(
                    status.state == 'running'
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    color: status.state == 'running'
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
                          status.state.toUpperCase(),
                          style: MayaTheme.headlineMedium.copyWith(
                            color: status.state == 'running'
                                ? MayaTheme.neonEmerald
                                : MayaTheme.neonOrange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phase: ${status.currentPhase}',
                          style: MayaTheme.bodyMedium
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  if (status.currentGoal != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status.currentGoal!,
                        style:
                            MayaTheme.bodySmall.copyWith(color: Colors.white54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _CoreStatCard(
                        label: 'Active Goals',
                        value: status.activeGoals.toString(),
                        color: MayaTheme.neonCyan,
                        icon: Icons.flag_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Pending Tasks',
                        value: status.pendingTasks.toString(),
                        color: MayaTheme.neonOrange,
                        icon: Icons.pending_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Total Cycles',
                        value: status.totalCycles.toString(),
                        color: MayaTheme.neonViolet,
                        icon: Icons.repeat_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Current Phase',
                        value: status.currentPhase,
                        color: MayaTheme.neonEmerald,
                        icon: Icons.psychology_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            if (status.currentGoal != null) ...[
              const Text('Current Goal', style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.currentGoal!, style: MayaTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Active Goals: ${status.activeGoals} • Pending Tasks: ${status.pendingTasks}',
                      style:
                          MayaTheme.bodySmall.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
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

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(unifiedLoopHistoryProvider);

    return historyAsync.when(
      data: (response) => response.history.isEmpty
          ? const MayaEmptyState(
              'No loop cycles recorded yet',
              icon: Icons.history_rounded,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loop History', style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Recent cognitive loop cycles and their outcomes',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: response.history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final entry = response.history[index];
                      return _HistoryEntryCard(entry: entry);
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
        Text('Error loading history',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final UnifiedLoopHistoryEntry entry;

  const _HistoryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (entry.status.toLowerCase()) {
      case 'success':
        statusColor = MayaTheme.neonEmerald;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'failed':
        statusColor = MayaTheme.error;
        statusIcon = Icons.error_rounded;
        break;
      case 'running':
        statusColor = MayaTheme.neonCyan;
        statusIcon = Icons.play_circle_rounded;
        break;
      default:
        statusColor = Colors.white54;
        statusIcon = Icons.help_rounded;
    }

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
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.goalId,
                        style: MayaTheme.titleMedium
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Phase: ${entry.phase}',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  entry.status.toUpperCase(),
                  style: MayaTheme.labelSmall.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Time: ${entry.timestamp}',
              style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          if (entry.result != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MayaTheme.slate800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                entry.result!,
                style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlsTab extends ConsumerWidget {
  const _ControlsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loop Controls', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Control the cognitive loop execution',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Execution Control', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pauseLoop(context, ref),
                        icon: const Icon(Icons.pause_rounded),
                        label: const Text('Pause Loop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MayaTheme.neonOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _resumeLoop(context, ref),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Resume Loop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MayaTheme.neonEmerald,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Single Step', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Execute one iteration of the cognitive loop',
                  style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _stepLoop(context, ref),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Step Once'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Danger Zone', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Reset the entire cognitive loop state. This cannot be undone.',
                  style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmReset(context, ref),
                    icon: const Icon(Icons.restart_alt_rounded,
                        color: MayaTheme.error),
                    label: const Text('Reset Loop',
                        style: TextStyle(color: MayaTheme.error)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MayaTheme.error,
                      side: BorderSide(
                          color: MayaTheme.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pauseLoop(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson('/api/v1/cognitive/loop/pause');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Loop paused'),
              backgroundColor: MayaTheme.neonOrange),
        );
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

  Future<void> _resumeLoop(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson('/api/v1/cognitive/loop/resume');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Loop resumed'),
              backgroundColor: MayaTheme.neonEmerald),
        );
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

  Future<void> _stepLoop(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson('/api/v1/cognitive/loop/step');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Step executed'),
              backgroundColor: MayaTheme.neonEmerald),
        );
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

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Reset Cognitive Loop?'),
        content: const Text(
            'This will reset all loop state and clear history. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = ref.read(mayaApiProvider);
        await api.postJson('/api/v1/cognitive/loop/reset');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Loop reset'),
                backgroundColor: MayaTheme.neonEmerald),
          );
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
  }
}

class _CoreStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _CoreStatCard({
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
          Text(label,
              style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}
