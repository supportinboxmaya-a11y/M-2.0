import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import 'workflow_engine_models.dart';
import 'workflow_engine_providers.dart';

class WorkflowEngineScreen extends ConsumerStatefulWidget {
  const WorkflowEngineScreen({super.key});

  @override
  ConsumerState<WorkflowEngineScreen> createState() =>
      _WorkflowEngineScreenState();
}

class _WorkflowEngineScreenState extends ConsumerState<WorkflowEngineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  final _goalController =
      TextEditingController(text: 'Build a REST API with FastAPI');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(workflowsRunsProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Workflow Engine', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(workflowsRunsProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.list_rounded), text: 'Runs'),
              Tab(icon: Icon(Icons.add_rounded), text: 'New Workflow'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRunsTab(),
            _buildNewWorkflowTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRunsTab() {
    final runsAsync = ref.watch(workflowsRunsProvider);

    return runsAsync.when(
      data: (response) {
        if (response.checkpoints.isEmpty) {
          return const Center(
            child: Text('No workflow runs yet', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.checkpoints.length,
          itemBuilder: (context, index) {
            final runId = response.checkpoints[index];
            return _WorkflowRunTile(runId: runId);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading runs',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewWorkflowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create New Workflow', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _goalController,
                  style: MayaTheme.bodyMedium,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the goal for the workflow...',
                    hintStyle:
                        MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createWorkflow,
                    icon: const Icon(Icons.psychology_rounded),
                    label: const Text('Plan Workflow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, _) {
              final planAsync =
                  ref.watch(workflowPlanProvider(_goalController.text.trim()));

              return planAsync.when(
                data: (plan) => _WorkflowPlanCard(plan: plan),
                loading: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: MayaTheme.glassCard(),
                  child: const Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    children: [
                      const Icon(Icons.error_rounded,
                          size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Planning error',
                          style: MayaTheme.bodyMedium
                              .copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(),
                          style: MayaTheme.bodySmall
                              .copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createWorkflow() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;

    ref.invalidate(workflowPlanProvider(goal));
  }
}

class _WorkflowRunTile extends ConsumerWidget {
  final String runId;

  const _WorkflowRunTile({required this.runId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runAsync = ref.watch(workflowRunProvider(runId));

    return runAsync.when(
      data: (run) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: MayaTheme.glassCard(),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(run.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(run.status),
              color: _getStatusColor(run.status),
              size: 20,
            ),
          ),
          title: Text(run.goal,
              style: MayaTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
            'Run ID: ${run.id.substring(0, 12)}...',
            style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(run.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  run.status.toUpperCase(),
                  style: MayaTheme.labelSmall.copyWith(
                    color: _getStatusColor(run.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton(
                icon:
                    const Icon(Icons.more_vert_rounded, color: Colors.white54),
                itemBuilder: (context) => [
                  if (run.status == 'pending' || run.status == 'running')
                    const PopupMenuItem(
                      value: 'execute',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Execute'),
                        ],
                      ),
                    ),
                  if (run.status == 'running' || run.status == 'pending')
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded,
                              size: 18, color: MayaTheme.error),
                          SizedBox(width: 8),
                          Text('Cancel',
                              style: TextStyle(color: MayaTheme.error)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'execute') {
                    await _executeRun(run.id, ref, context);
                  } else if (value == 'cancel') {
                    await _cancelRun(run.id, ref, context);
                  } else if (value == 'refresh') {
                    ref.invalidate(workflowsRunsProvider);
                    ref.invalidate(workflowRunProvider(run.id));
                  }
                },
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Run ID', value: run.id),
                  _DetailRow(label: 'Goal', value: run.goal),
                  _DetailRow(label: 'Status', value: run.status),
                  _DetailRow(
                      label: 'Created',
                      value: DateTime.fromMillisecondsSinceEpoch(
                              run.created * 1000)
                          .toString()),
                  _DetailRow(label: 'Steps', value: '${run.nodes.length}'),
                  const SizedBox(height: 12),
                  const Text('Steps / Checkpoints',
                      style: MayaTheme.labelMedium),
                  const SizedBox(height: 8),
                  ...run.nodes.map((node) => _WorkflowNodeTile(node: node)),
                  if (run.recoveryLog != null &&
                      run.recoveryLog!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Recovery Log', style: MayaTheme.labelMedium),
                    const SizedBox(height: 8),
                    ...run.recoveryLog!
                        .map((entry) => _RecoveryLogTile(entry: entry)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: MayaTheme.glassCard(),
        child: const ListTile(
          leading: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
          title: Text('Loading...', style: MayaTheme.bodyMedium),
        ),
      ),
      error: (err, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: MayaTheme.glassCard(),
        child: ListTile(
          leading: const Icon(Icons.error_rounded, color: MayaTheme.error),
          title: Text('Error loading run',
              style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          subtitle: Text(err.toString(),
              style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return MayaTheme.neonEmerald;
      case 'running':
        return MayaTheme.neonCyan;
      case 'pending':
        return MayaTheme.neonOrange;
      case 'failed':
        return MayaTheme.error;
      case 'cancelled':
        return MayaTheme.neonViolet;
      default:
        return Colors.white54;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'running':
        return Icons.play_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'failed':
        return Icons.error_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Future<void> _executeRun(
      String runId, WidgetRef ref, BuildContext context) async {
    try {
      final api = ref.read(mayaApiProvider);
      final result =
          await api.postJson('/api/v1/workflows/runs/$runId/execute');
      if (context.mounted) {
        ref.invalidate(workflowsRunsProvider);
        ref.invalidate(workflowRunProvider(runId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow executed: ${result['status']}'),
            backgroundColor: result['status'] == 'completed'
                ? MayaTheme.neonEmerald
                : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Execution failed: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelRun(
      String runId, WidgetRef ref, BuildContext context) async {
    try {
      final api = ref.read(mayaApiProvider);
      final response =
          await api.postJson('/api/v1/workflows/runs/$runId/cancel');
      final success = response['success'] as bool? ?? false;
      if (success && context.mounted) {
        ref.invalidate(workflowsRunsProvider);
        ref.invalidate(workflowRunProvider(runId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workflow cancelled'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancel failed'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancel error: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }
}

class _WorkflowNodeTile extends StatelessWidget {
  final WorkflowNode node;

  const _WorkflowNodeTile({required this.node});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return MayaTheme.neonEmerald;
      case 'running':
        return MayaTheme.neonCyan;
      case 'pending':
        return MayaTheme.neonOrange;
      case 'failed':
        return MayaTheme.error;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getStatusColor(node.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getStatusIcon(node.status),
                  color: _getStatusColor(node.status),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.name, style: MayaTheme.bodyMedium),
                    if (node.agent != null)
                      Text('Agent: ${node.agent}',
                          style: MayaTheme.bodySmall
                              .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(node.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(node.status.toUpperCase(),
                    style: MayaTheme.labelSmall
                        .copyWith(color: _getStatusColor(node.status))),
              ),
            ],
          ),
          if (node.error != null) ...[
            const SizedBox(height: 8),
            Text('Error: ${node.error}',
                style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
          ],
          if (node.output != null) ...[
            const SizedBox(height: 8),
            Text('Output: ${node.output!.keys.join(', ')}',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'running':
        return Icons.play_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'failed':
        return Icons.error_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}

class _RecoveryLogTile extends StatelessWidget {
  final RecoveryLogEntry entry;

  const _RecoveryLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MayaTheme.slate800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.restore_rounded,
              color: MayaTheme.neonViolet, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.event, style: MayaTheme.bodyMedium),
                Text(entry.details,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          Text(
            DateTime.fromMillisecondsSinceEpoch(entry.timestamp * 1000)
                .toString()
                .substring(11, 19),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _WorkflowPlanCard extends StatelessWidget {
  final WorkflowPlanResponse plan;

  const _WorkflowPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workflow Plan', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          Text(plan.plan, style: MayaTheme.bodyMedium),
          const SizedBox(height: 16),
          const Text('Steps', style: MayaTheme.labelMedium),
          const SizedBox(height: 8),
          ...plan.steps.map((step) => _PlanStepTile(step: step)),
        ],
      ),
    );
  }
}

class _PlanStepTile extends StatelessWidget {
  final WorkflowStep step;

  const _PlanStepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_right_rounded,
                    color: MayaTheme.neonViolet, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.name,
                        style: MayaTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text('Agent: ${step.agent}',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(step.description,
              style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
          if (step.dependsOn.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Depends on: ${step.dependsOn.join(', ')}',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          ),
          Expanded(
              child: Text(value,
                  style:
                      MayaTheme.bodyMedium.copyWith(fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}
