import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'self_model_models.dart';
import 'self_model_providers.dart';

class SelfModelScreen extends ConsumerStatefulWidget {
  const SelfModelScreen({super.key});

  @override
  ConsumerState<SelfModelScreen> createState() => _SelfModelScreenState();
}

class _SelfModelScreenState extends ConsumerState<SelfModelScreen>
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

  Future<void> _showCreateModelDialog(
      BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Create model not implemented yet'),
          backgroundColor: MayaTheme.neonOrange),
    );
  }

  Future<void> _showDetail(BuildContext context, String modelId) async {
    final api = ref.read(mayaApiProvider);
    try {
      final response = await api.getJson('/api/v1/self_model/models/$modelId');
      final model = SelfModelDetailResponse.fromJson(response);
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ModelDetailSheet(model: model),
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

  void _editModel(BuildContext context, SelfModel model) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Edit not implemented yet'),
          backgroundColor: MayaTheme.neonOrange),
    );
  }

  Future<void> _deleteModel(
      BuildContext context, WidgetRef ref, String modelId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Delete Model?'),
        content: const Text(
            'This will permanently delete the model. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = ref.read(mayaApiProvider);
        await api.deleteJson('/api/v1/self_model/models/$modelId');
        ref.invalidate(selfModelListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Model deleted'),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Self Model', style: MayaTheme.headlineSmall),
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
                ref.invalidate(selfModelListProvider);
                ref.invalidate(selfModelStatsProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showCreateModelDialog(context, ref),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'Models'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ModelsTab(
              onShowDetail: _showDetail,
              onEditModel: _editModel,
              onDeleteModel: _deleteModel,
            ),
            const _StatsTab(),
          ],
        ),
      ),
    );
  }
}

class _ModelsTab extends ConsumerWidget {
  const _ModelsTab({
    required this.onShowDetail,
    required this.onEditModel,
    required this.onDeleteModel,
    super.key,
  });

  final void Function(BuildContext, String) onShowDetail;
  final void Function(BuildContext, SelfModel) onEditModel;
  final void Function(BuildContext, WidgetRef, String) onDeleteModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(selfModelListProvider);

    return modelsAsync.when(
      data: (data) => data.models.isEmpty
          ? const MayaEmptyState(
              'Create your first self-model to get started',
              icon: Icons.psychology_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.models.length,
              itemBuilder: (_, index) {
                final model = data.models[index];
                return _SelfModelCard(
                  model: model,
                  onShowDetail: onShowDetail,
                  onEditModel: onEditModel,
                  onDeleteModel: onDeleteModel,
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
        Text('Error loading models',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _SelfModelCard extends ConsumerWidget {
  final SelfModel model;
  final void Function(BuildContext, String) onShowDetail;
  final void Function(BuildContext, SelfModel) onEditModel;
  final void Function(BuildContext, WidgetRef, String) onDeleteModel;

  const _SelfModelCard({
    required this.model,
    required this.onShowDetail,
    required this.onEditModel,
    required this.onDeleteModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(model.status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            model.status == 'active'
                ? Icons.check_circle_rounded
                : Icons.psychology_rounded,
            color: _getStatusColor(model.status),
            size: 20,
          ),
        ),
        title: Text(model.name, style: MayaTheme.titleMedium),
        subtitle: Text(model.type,
            style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detail',
              child: Row(
                children: [
                  Icon(Icons.visibility_rounded,
                      size: 18, color: MayaTheme.neonCyan),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded,
                      size: 18, color: MayaTheme.neonViolet),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: MayaTheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'detail') onShowDetail(context, model.id);
            if (value == 'edit') onEditModel(context, model);
            if (value == 'delete') onDeleteModel(context, ref, model.id);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Type', value: model.type),
                _DetailRow(label: 'Status', value: model.status),
                _DetailRow(
                    label: 'Accuracy',
                    value: '${(model.accuracy * 100).toStringAsFixed(1)}%'),
                _DetailRow(label: 'Version', value: model.version),
                _DetailRow(
                    label: 'Created',
                    value: model.createdAt.toString().substring(0, 19)),
                if (model.updatedAt != null)
                  _DetailRow(
                      label: 'Updated',
                      value: model.updatedAt!.toString().substring(0, 19)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return MayaTheme.neonEmerald;
      case 'deprecated':
        return MayaTheme.neonOrange;
      case 'training':
        return MayaTheme.neonCyan;
      default:
        return Colors.white54;
    }
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(selfModelStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Self Model Statistics', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Overview of your self-models',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Total Models',
                        value: stats['total_models']?.toString() ?? '0',
                        color: MayaTheme.neonCyan,
                        icon: Icons.psychology_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Active',
                        value: stats['active_models']?.toString() ?? '0',
                        color: MayaTheme.neonEmerald,
                        icon: Icons.check_circle_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Deprecated',
                        value: stats['deprecated_models']?.toString() ?? '0',
                        color: MayaTheme.neonOrange,
                        icon: Icons.archive_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Avg Accuracy',
                        value:
                            '${(stats['avg_accuracy'] as double? ?? 0.0).toStringAsFixed(1)}%',
                        color: MayaTheme.neonViolet,
                        icon: Icons.trending_up_rounded)),
              ],
            ),
            const SizedBox(height: 24),
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
        Text('Error loading stats',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value, super.key});

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

class _ModelDetailSheet extends StatelessWidget {
  final SelfModelDetailResponse model;

  const _ModelDetailSheet({required this.model, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: MayaTheme.slate800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Model Detail', style: MayaTheme.headlineSmall),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'ID', value: model.id),
                  _DetailRow(label: 'Name', value: model.name),
                  _DetailRow(label: 'Type', value: model.type),
                  _DetailRow(label: 'Status', value: model.status),
                  _DetailRow(
                      label: 'Accuracy',
                      value: '${(model.accuracy * 100).toStringAsFixed(1)}%'),
                  _DetailRow(label: 'Version', value: model.version),
                  _DetailRow(label: 'Created', value: model.createdAt),
                  if (model.updatedAt != null)
                    _DetailRow(label: 'Updated', value: model.updatedAt!),
                  if (model.config != null) ...[
                    const SizedBox(height: 16),
                    const Text('Configuration', style: MayaTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MayaTheme.slate900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        model.config.toString(),
                        style: MayaTheme.bodySmall
                            .copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                  if (model.tags != null && model.tags!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Tags', style: MayaTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: model.tags!
                          .map((tag) => Chip(
                                label: Text(tag, style: MayaTheme.bodySmall),
                                backgroundColor:
                                    MayaTheme.neonViolet.withValues(alpha: 0.2),
                                side: const BorderSide(
                                    color: MayaTheme.neonViolet),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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
    super.key,
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
