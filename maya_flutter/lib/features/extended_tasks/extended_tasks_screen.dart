import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'extended_tasks_models.dart';
import 'extended_tasks_providers.dart';

class ExtendedTasksScreen extends ConsumerStatefulWidget {
  const ExtendedTasksScreen({super.key});

  @override
  ConsumerState<ExtendedTasksScreen> createState() =>
      _ExtendedTasksScreenState();
}

class _ExtendedTasksScreenState extends ConsumerState<ExtendedTasksScreen>
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
          title: const Text('Extended Tasks', style: MayaTheme.headlineSmall),
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
                ref.invalidate(extendedTasksProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'Tasks'),
              Tab(icon: Icon(Icons.add_task_rounded), text: 'Create'),
              Tab(icon: Icon(Icons.monitor_heart_rounded), text: 'Health'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ExtTasksListTab(),
            _ExtCreateTaskTab(),
            _ExtHealthTab(),
          ],
        ),
      ),
    );
  }
}

class _ExtTasksListTab extends ConsumerWidget {
  const _ExtTasksListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(extendedTasksProvider);

    return tasksAsync.when(
      data: (data) => data.tasks.isEmpty
          ? const MayaEmptyState(
              'No Tasks',
              icon: Icons.list_alt_rounded,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Extended Tasks', style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Background tasks managed by the extended agent',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final task = data.tasks[index];
                      return _ExtTaskCard(task: task);
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
        Text('Error loading tasks',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _ExtTaskCard extends ConsumerWidget {
  final ExtendedTask task;

  const _ExtTaskCard({required this.task});

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
                  color: _getStatusColor(task.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.task_alt_rounded,
                    color: _getStatusColor(task.status), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.description,
                        style: MayaTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                        'Created: ${task.createdAt.toString().substring(0, 19)}',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(task.status)),
                ),
                child: Text(task.status.toUpperCase(),
                    style: MayaTheme.labelSmall
                        .copyWith(color: _getStatusColor(task.status))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return MayaTheme.neonEmerald;
      case 'completed':
        return MayaTheme.neonCyan;
      case 'failed':
        return MayaTheme.error;
      case 'pending':
        return MayaTheme.neonOrange;
      default:
        return Colors.white54;
    }
  }
}

class _ExtCreateTaskTab extends ConsumerStatefulWidget {
  const _ExtCreateTaskTab();

  @override
  ConsumerState<_ExtCreateTaskTab> createState() => _ExtCreateTaskTabState();
}

class _ExtCreateTaskTabState extends ConsumerState<_ExtCreateTaskTab> {
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Description is required'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final api = ref.read(mayaApiProvider);
      final response = await api.postJson('/api/v1/extended/tasks',
          data: {'description': _descriptionController.text.trim()});
      final result = ExtendedTaskCreateResponse.fromJson(response);
      setState(() => _isCreating = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.success
                  ? 'Task created: ${result.taskId}'
                  : 'Failed: ${result.error}'),
              backgroundColor:
                  result.success ? MayaTheme.neonEmerald : MayaTheme.error),
        );
        if (result.success) {
          _descriptionController.clear();
          ref.invalidate(extendedTasksProvider);
        }
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Create failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Extended Task', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Create a new background task for the extended agent',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Task Description *',
                    hintText: 'Describe the task for the extended agent...',
                    labelStyle: const TextStyle(color: Colors.white54),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_rounded,
                          color: Colors.white54),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: MayaTheme.neonCyan),
                    ),
                    filled: true,
                    fillColor: MayaTheme.slate800,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _createTask,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.add_task_rounded),
                    label: Text(_isCreating ? 'Creating...' : 'Create Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
}

class _ExtHealthTab extends ConsumerWidget {
  const _ExtHealthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: These would need separate providers for extended agent status/health
    // For now, show a placeholder
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Extended Agent Health', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Monitor the health and status of the extended agent',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              children: [
                const Text('Extended agent health monitoring would go here',
                    style: MayaTheme.bodyMedium),
                const SizedBox(height: 16),
                _HealthItem(
                    label: 'Healthy',
                    value: 'N/A',
                    color: MayaTheme.neonOrange),
                _HealthItem(
                    label: 'Message',
                    value: 'Health endpoint not implemented',
                    color: MayaTheme.neonOrange),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Health Details', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          const Text(
              'Extended agent health endpoints would be implemented here',
              style: MayaTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _HealthItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HealthItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          ),
          Expanded(
              child: Text(value,
                  style: MayaTheme.bodyMedium
                      .copyWith(fontFamily: 'monospace', color: color))),
        ],
      ),
    );
  }
}
