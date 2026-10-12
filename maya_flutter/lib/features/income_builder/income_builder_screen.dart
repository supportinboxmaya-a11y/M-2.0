import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final builderProjectsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.builderListProjects(limit: 50);
});

final builderStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.builderGetStats();
});

class IncomeBuilderScreen extends ConsumerStatefulWidget {
  const IncomeBuilderScreen({super.key});

  @override
  ConsumerState<IncomeBuilderScreen> createState() => _IncomeBuilderScreenState();
}

class _IncomeBuilderScreenState extends ConsumerState<IncomeBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          title: const Text('Income Builder', style: MayaTheme.headlineSmall),
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
                ref.invalidate(builderProjectsProvider);
                ref.invalidate(builderStatsProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.folder_rounded), text: 'Projects'),
              Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'Build from Plan'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ProjectsTab(),
            _BuildFromPlanTab(),
          ],
        ),
      ),
    );
  }
}

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(builderProjectsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(builderProjectsProvider);
        ref.invalidate(builderStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Builder Projects', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Manage and track your building projects',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            // Stats
            ref.watch(builderStatsProvider).when(
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: _BuilderStatCard(
                      label: 'Total Projects',
                      value: stats['total_projects']?.toString() ?? '0',
                      color: MayaTheme.neonCyan,
                      icon: Icons.folder_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BuilderStatCard(
                      label: 'Completed',
                      value: stats['by_status']?['completed']?.toString() ?? '0',
                      color: MayaTheme.neonEmerald,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BuilderStatCard(
                      label: 'Active',
                      value: stats['by_status']?['building']?.toString() ?? '0',
                      color: MayaTheme.neonOrange,
                      icon: Icons.play_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BuilderStatCard(
                      label: 'Steps Executed',
                      value: stats['total_steps']?.toString() ?? '0',
                      color: MayaTheme.neonViolet,
                      icon: Icons.play_arrow_rounded,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
                ),
              ),
              error: (err, stackTrace) => Row(
                children: [
                  const Icon(Icons.error_rounded, size: 28, color: MayaTheme.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error: $err', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Projects List
            const Text('Projects', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            projectsAsync.when(
              data: (data) {
                final projects = data['projects'] as List? ?? [];
                if (projects.isEmpty) {
                  return const MayaEmptyState(
                    'No Projects',
                    icon: Icons.folder_rounded,
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final project = projects[index];
                    return _BuilderProjectCard(project: project);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
              ),
              error: (err, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading projects', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                    const SizedBox(height: 8),
                    Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                  ],
                ),
              ),
            ),
],
        ),
      ),
);
    }
  }

class _BuilderStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _BuilderStatCard({
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
    );
  }
}

class _BuilderProjectCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> project;

  const _BuilderProjectCard({required this.project, super.key});

  @override
  ConsumerState<_BuilderProjectCard> createState() => _BuilderProjectCardState();
}

class _BuilderProjectCardState extends ConsumerState<_BuilderProjectCard> {
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return MayaTheme.neonEmerald;
      case 'building':
        return MayaTheme.neonCyan;
      case 'testing':
        return MayaTheme.neonViolet;
      case 'deploying':
        return MayaTheme.neonOrange;
      case 'failed':
        return MayaTheme.error;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
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
                  color: _getStatusColor(project['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.folder_rounded, color: _getStatusColor(project['status']), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project['title'] ?? '', style: MayaTheme.titleMedium),
                    Text(project['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(project['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(project['status'])),
                ),
                child: Text(
                  project['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                  style: MayaTheme.labelSmall.copyWith(color: _getStatusColor(project['status'])),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Plan: ${project['planId'] ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
              const Spacer(),
              Text('Created: ${project['createdAt']?.toString().substring(0, 10) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${project['steps']?.length ?? 0} steps', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              const Spacer(),
              Text('Iteration: ${project['currentIteration'] ?? 0}/${project['maxIterations'] ?? 0}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to project detail
                  },
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MayaTheme.neonCyan,
                    side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (project['status'] == 'failed') {
                      final api = ref.read(mayaApiProvider);
                      try {
                        await api.builderUpdateProjectStatus(project['id'], 'retry');
                        ref.invalidate(builderProjectsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Retrying...'), backgroundColor: MayaTheme.neonEmerald),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildFromPlanTab extends ConsumerStatefulWidget {
  const _BuildFromPlanTab();

  @override
  ConsumerState<_BuildFromPlanTab> createState() => _BuildFromPlanTabState();
}

class _BuildFromPlanTabState extends ConsumerState<_BuildFromPlanTab> {
  final _planIdController = TextEditingController();
  bool _isExecuting = false;

  @override
  void dispose() {
    _planIdController.dispose();
    super.dispose();
  }

  Future<void> _buildFromPlan() async {
    if (_planIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan ID is required'), backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isExecuting = true);
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.builderBuildFromPlan(_planIdController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project created: ${result['projectId']}'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
        _planIdController.clear();
        ref.invalidate(builderProjectsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Build failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Build from Plan', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Enter a Strategist plan ID to automatically build the project',
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
                  controller: _planIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Plan ID *',
                    hintText: 'e.g., plan_abc123',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.assignment_rounded, color: Colors.white54),
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
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _planIdController.text.trim().isEmpty ? null : () {
                      setState(() {});
                      _buildFromPlan();
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(_isExecuting ? 'Building...' : 'Build Project'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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