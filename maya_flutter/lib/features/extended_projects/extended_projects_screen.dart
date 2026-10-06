import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'extended_projects_models.dart';
import 'extended_projects_providers.dart';

class ExtendedProjectsScreen extends ConsumerStatefulWidget {
  const ExtendedProjectsScreen({super.key});

  @override
  ConsumerState<ExtendedProjectsScreen> createState() =>
      _ExtendedProjectsScreenState();
}

class _ExtendedProjectsScreenState extends ConsumerState<ExtendedProjectsScreen>
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
          title:
              const Text('Extended Projects', style: MayaTheme.headlineSmall),
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
                ref.invalidate(extendedProjectsProvider);
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
              Tab(icon: Icon(Icons.add_circle_rounded), text: 'Create'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ExtProjectsListTab(),
            _ExtCreateProjectTab(),
          ],
        ),
      ),
    );
  }
}

class _ExtProjectsListTab extends ConsumerWidget {
  const _ExtProjectsListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(extendedProjectsProvider);

    return projectsAsync.when(
      data: (data) => data.projects.isEmpty
          ? const MayaEmptyState(
              'No Extended Projects',
              icon: Icons.folder_rounded,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Projects', style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your memory projects and track progress',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final project = data.projects[index];
                      return _ExtProjectCard(project: project);
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
        Text('Error loading projects',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _ExtProjectCard extends ConsumerWidget {
  final ExtendedProject project;

  const _ExtProjectCard({required this.project});

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
                  color: _getStatusColor(project.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.folder_rounded,
                    color: _getStatusColor(project.status), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: MayaTheme.titleMedium),
                    Text(project.description,
                        style:
                            MayaTheme.bodySmall.copyWith(color: Colors.white54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(project.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(project.status)),
                ),
                child: Text(project.status.toUpperCase(),
                    style: MayaTheme.labelSmall
                        .copyWith(color: _getStatusColor(project.status))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('ID: ${project.id}',
                  style: MayaTheme.bodySmall.copyWith(
                      color: Colors.white54, fontFamily: 'monospace')),
              const Spacer(),
              Text('Created: ${project.createdAt.toString().substring(0, 10)}',
                  style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return MayaTheme.neonEmerald;
      case 'completed':
        return MayaTheme.neonCyan;
      case 'archived':
        return MayaTheme.neonOrange;
      default:
        return Colors.white54;
    }
  }
}

class _ExtCreateProjectTab extends ConsumerStatefulWidget {
  const _ExtCreateProjectTab();

  @override
  ConsumerState<_ExtCreateProjectTab> createState() =>
      _ExtCreateProjectTabState();
}

class _ExtCreateProjectTabState extends ConsumerState<_ExtCreateProjectTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name is required'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final api = ref.read(mayaApiProvider);
      final response =
          await api.postJson('/api/v1/extended/memory/projects', data: {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      final result = ExtendedProjectCreateResponse.fromJson(response);
      setState(() => _isCreating = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.success
                  ? 'Project created: ${result.projectId}'
                  : 'Failed: ${result.error}'),
              backgroundColor:
                  result.success ? MayaTheme.neonEmerald : MayaTheme.error),
        );
        if (result.success) {
          _nameController.clear();
          _descriptionController.clear();
          ref.invalidate(extendedProjectsProvider);
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
          const Text('Create Memory Project', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Create a project to organize related memory facts',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Project Name *',
                    hintText: 'e.g., research_project',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.label_rounded, color: Colors.white54),
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
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What this project is about...',
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
                    onPressed: _isCreating ? null : _createProject,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.add_circle_rounded),
                    label: Text(_isCreating ? 'Creating...' : 'Create Project'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
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
