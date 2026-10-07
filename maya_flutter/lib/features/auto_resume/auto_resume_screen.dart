import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'auto_resume_models.dart';
import 'auto_resume_providers.dart';

class AutoResumeScreen extends ConsumerStatefulWidget {
  const AutoResumeScreen({super.key});

  @override
  ConsumerState<AutoResumeScreen> createState() => _AutoResumeScreenState();
}

class _AutoResumeScreenState extends ConsumerState<AutoResumeScreen>
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
          title: const Text('Auto-Resume', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.replay_rounded), text: 'Resume Now'),
              Tab(icon: Icon(Icons.settings_rounded), text: 'Configuration'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ResumeNowTab(),
            _AutoResumeConfigTab(),
            _AutoResumeHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _ResumeNowTab extends ConsumerWidget {
  const _ResumeNowTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Batch Resume Incomplete Goals',
              style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Resume goals that were left incomplete across restarts. Choose execution mode and limits.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          _ResumeNowForm(),
          const SizedBox(height: 24),
          const Text('Incomplete Goals Preview', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _IncompleteGoalsPreview(),
        ],
      ),
    );
  }
}

class _ResumeNowForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ResumeNowForm> createState() => _ResumeNowFormState();
}

class _ResumeNowFormState extends ConsumerState<_ResumeNowForm> {
  bool _execute = false;
  int _maxGoals = 5;
  bool _planProposals = true;
  bool _isResuming = false;
  AutoResumeResponse? _lastResult;

  Future<void> _resumeGoals() async {
    setState(() => _isResuming = true);
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.postJson(
        '/api/v1/goals/auto_resume',
        data: {
          'execute': _execute,
          'max_goals': _maxGoals,
          'plan_proposals': _planProposals,
        },
      );
      setState(() {
        _lastResult = AutoResumeResponse.fromJson(result);
        _isResuming = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Resumed ${_lastResult!.results.length} goals (${_lastResult!.results.where((r) => r.success).length} succeeded)'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      setState(() => _isResuming = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Resume failed: $e'),
              backgroundColor: MayaTheme.error),
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
          const Text('Execution Mode', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Execute (not just propose)',
                style: MayaTheme.bodyMedium),
            subtitle: Text(
                'When ON, actually re-executes ACTIVE goals through the gated pipeline. Requires RBAC execute.',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
            value: _execute,
            onChanged: (v) => setState(() => _execute = v),
            activeThumbColor: MayaTheme.neonEmerald,
          ),
          const Divider(color: Colors.white12),
          SwitchListTile(
            title: const Text('Plan Proposals', style: MayaTheme.bodyMedium),
            subtitle: Text(
                'When OFF, performs cheap policy scan without LLM calls (scan-only mode).',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
            value: _planProposals,
            onChanged: (v) => setState(() => _planProposals = v),
            activeThumbColor: MayaTheme.neonCyan,
          ),
          const Divider(color: Colors.white12),
          Row(
            children: [
              Text('Max Goals: $_maxGoals',
                  style:
                      MayaTheme.bodyMedium.copyWith(color: MayaTheme.neonCyan)),
              Expanded(
                  child: Slider(
                value: _maxGoals.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: MayaTheme.neonCyan,
                inactiveColor: Colors.white24,
                onChanged: (v) => setState(() => _maxGoals = v.toInt()),
              )),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isResuming ? null : _resumeGoals,
              icon: _isResuming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Icon(Icons.replay_rounded),
              label: Text(_isResuming ? 'Resuming...' : 'Resume Goals Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            const Text('Last Result', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lastResult!.results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final r = _lastResult!.results[index];
                return _AutoResumeResultCard(result: r);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoResumeResultCard extends StatelessWidget {
  final AutoResumeResult result;

  const _AutoResumeResultCard({required this.result});

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: result.success
                      ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                      : MayaTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  result.success
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color:
                      result.success ? MayaTheme.neonEmerald : MayaTheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Goal: ${result.goalId}', style: MayaTheme.titleSmall),
                    Text(
                        'Prior: ${result.priorStatus} • ${result.autoExecuted ? "Executed" : "Propose-only"}',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
          if (result.description != null) ...[
            const SizedBox(height: 8),
            Text('Description: ${result.description}',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
          ],
          if (result.action != null) ...[
            const SizedBox(height: 8),
            Text('Action: ${result.action}',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
          ],
          if (result.error != null) ...[
            const SizedBox(height: 8),
            Text('Error: ${result.error}',
                style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
          ],
        ],
      ),
    );
  }
}

class _IncompleteGoalsPreview extends ConsumerWidget {
  const _IncompleteGoalsPreview();

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return MayaTheme.neonEmerald;
      case 'suspended':
        return MayaTheme.neonOrange;
      case 'blocked':
        return MayaTheme.error;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incompleteAsync = ref.watch(incompleteGoalsProvider);

    return incompleteAsync.when(
      data: (data) => data.goals.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: MayaTheme.glassCard(),
              child: const Center(
                  child: Text('No incomplete goals found',
                      style: MayaTheme.bodyMedium)),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.goals.length > 10 ? 10 : data.goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final goal = data.goals[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: MayaTheme.glassCard(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(goal.status)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.flag_rounded,
                            color: _getStatusColor(goal.status), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.description,
                                style: MayaTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                                '${goal.status.toUpperCase()} • Priority: ${goal.priority.toInt()}',
                                style: MayaTheme.bodySmall
                                    .copyWith(color: Colors.white54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
        const SizedBox(height: 16),
        Text('Error loading goals',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _AutoResumeConfigTab extends ConsumerWidget {
  const _AutoResumeConfigTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Auto-Resume Configuration', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Configure automatic resume behavior on server restart. Controlled via environment variables.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Environment Variables', style: MayaTheme.titleMedium),
                SizedBox(height: 12),
                _ConfigItem(
                  name: 'MAYA_AUTO_RESUME',
                  description:
                      'Enable automatic resume of ACTIVE goals on boot. When "true", previously-ACTIVE goals are re-executed through the gated pipeline. SUSPENDED/BLOCKED goals stay propose-only.',
                  defaultValue: 'false',
                  currentValue: String.fromEnvironment('MAYA_AUTO_RESUME',
                      defaultValue: 'false'),
                ),
                SizedBox(height: 16),
                _ConfigItem(
                  name: 'MAYA_UNIFIED_LOOP',
                  description:
                      'Route maya.run() through the CognitiveKernel. Required for auto-resume to work through the unified loop.',
                  defaultValue: 'false',
                  currentValue: String.fromEnvironment('MAYA_UNIFIED_LOOP',
                      defaultValue: 'false'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Behavior Policy', style: MayaTheme.titleMedium),
                SizedBox(height: 12),
                _PolicyRow(
                  label: 'ACTIVE goals',
                  description:
                      'Re-driven through registered executor when execute=true (default from MAYA_AUTO_RESUME). Already authorized through all pipeline gates.',
                  status: 'Auto-execute',
                  statusColor: MayaTheme.neonEmerald,
                ),
                SizedBox(height: 12),
                _PolicyRow(
                  label: 'SUSPENDED / BLOCKED goals',
                  description:
                      'Never auto-executed. Receive propose-only plans and stay awaiting explicit operator resume.',
                  status: 'Propose-only',
                  statusColor: MayaTheme.neonOrange,
                ),
                SizedBox(height: 12),
                _PolicyRow(
                  label: 'plan_proposals=false',
                  description:
                      'Cheap policy scan of WHOLE backlog with zero LLM calls. Useful for large backlogs / dry audits.',
                  status: 'Scan-only',
                  statusColor: MayaTheme.neonCyan,
                ),
                SizedBox(height: 12),
                _PolicyRow(
                  label: 'max_goals',
                  description:
                      'Limits how many goals to process per batch. Default 5. Higher values process more goals per restart.',
                  status: 'Configurable',
                  statusColor: MayaTheme.neonViolet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoResumeHistoryTab extends ConsumerWidget {
  const _AutoResumeHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Auto-Resume History', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Audit log of all auto-resume operations. Each resumed goal writes an auto_resume audit row.',
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
                const Text('Coming Soon', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Auto-resume audit history will be displayed here. Each batch resume creates audit rows with goal_id, prior_status, executed, success.',
                  style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final String label;
  final String description;
  final String status;
  final Color statusColor;

  const _PolicyRow({
    required this.label,
    required this.description,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: MayaTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(status,
                    style: MayaTheme.labelSmall.copyWith(color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description,
              style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final String name;
  final String description;
  final String defaultValue;
  final String currentValue;

  const _ConfigItem({
    required this.name,
    required this.description,
    required this.defaultValue,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name,
                  style: MayaTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600, color: MayaTheme.neonCyan)),
              const SizedBox(width: 8),
              Text('Default: $defaultValue',
                  style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: currentValue == 'true'
                      ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                      : MayaTheme.neonOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentValue == 'true' ? 'ENABLED' : 'DISABLED',
                  style: MayaTheme.labelSmall.copyWith(
                      color: currentValue == 'true'
                          ? MayaTheme.neonEmerald
                          : MayaTheme.neonOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description,
              style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
