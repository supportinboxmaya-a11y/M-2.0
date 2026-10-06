import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_detail_row.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import '../../../shared/widgets/maya_loading.dart';
import '../../../shared/widgets/maya_error_view.dart';

class InstanceScreen extends ConsumerWidget {
  const InstanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Instance Manager', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(instancesListProvider),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showCreateInstanceDialog(context, ref),
            ),
          ],
        ),
        body: Consumer(
          builder: (context, ref, _) {
            final instancesAsync = ref.watch(instancesListProvider);

            return instancesAsync.when(
              data: (response) {
                if (response.instances.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.computer_rounded,
                            size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('No instances yet', style: MayaTheme.bodyMedium),
                        SizedBox(height: 8),
                        Text('Tap + to create your first Maya instance',
                            style: MayaTheme.bodySmall
                                .copyWith(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: response.instances.length,
                  itemBuilder: (context, index) {
                    final instance = response.instances[index];
                    return _InstanceTile(instance: instance);
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
                    const Icon(Icons.error_rounded,
                        size: 48, color: MayaTheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading instances',
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
      ),
    );
  }

  void _showCreateInstanceDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final personaController = TextEditingController();
    final skillsController = TextEditingController();
    final budgetController = TextEditingController(text: '5.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Create Instance', style: MayaTheme.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: MayaTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Instance Name',
                  labelStyle:
                      MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: personaController,
                style: MayaTheme.bodyMedium,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Persona',
                  labelStyle:
                      MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsController,
                style: MayaTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Skills (comma-separated)',
                  labelStyle:
                      MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: MayaTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Budget (USD)',
                  labelStyle:
                      MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: MayaTheme.slate700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final persona = personaController.text.trim();
              if (name.isEmpty || persona.isEmpty) return;

              final skills = skillsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final budget = double.tryParse(budgetController.text) ?? 5.0;

              try {
                final api = ref.read(mayaApiProvider);
                await api.postJson(
                  '/api/v1/instances',
                  data: {
                    'name': name,
                    'persona': persona,
                    'skills': skills,
                    'budget_usd': budget,
                  },
                );
                ref.invalidate(instancesListProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Instance created'),
                        backgroundColor: MayaTheme.neonEmerald),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: MayaTheme.error),
                  );
                }
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _InstanceTile extends ConsumerWidget {
  final InstanceInfo instance;

  const _InstanceTile({required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.computer_rounded,
              color: MayaTheme.neonCyan, size: 20),
        ),
        title: Text(instance.name, style: MayaTheme.titleMedium),
        subtitle: Text(instance.persona,
            style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          itemBuilder: (context) => [
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
            if (value == 'delete') _deleteInstance(context, ref, instance.id);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MayaDetailRow(label: 'Instance ID', value: instance.id),
                MayaDetailRow(label: 'Persona', value: instance.persona),
                MayaDetailRow(
                    label: 'Memory Scope', value: instance.memoryScope),
                MayaDetailRow(
                    label: 'Budget (USD)',
                    value: instance.budgetUsd.toString()),
                MayaDetailRow(label: 'Owner', value: instance.owner),
                MayaDetailRow(
                    label: 'Created',
                    value: DateTime.fromMillisecondsSinceEpoch(
                            (instance.createdAt * 1000).round())
                        .toString()),
                const SizedBox(height: 12),
                const Text('Skills', style: MayaTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: instance.skills
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  MayaTheme.neonViolet.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: MayaTheme.neonViolet
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(skill,
                                style: MayaTheme.labelSmall
                                    .copyWith(color: MayaTheme.neonViolet)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to instance detail
                        },
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.neonCyan,
                          side: BorderSide(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _deleteInstance(context, ref, instance.id),
                        icon: const Icon(Icons.delete_rounded,
                            color: MayaTheme.error),
                        label: const Text('Delete',
                            style: TextStyle(color: MayaTheme.error)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.error,
                          side: BorderSide(
                              color: MayaTheme.error.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteInstance(BuildContext context, WidgetRef ref, String instanceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Delete Instance?'),
        content: const Text(
            'This will permanently delete the instance and all its memory. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteInstanceConfirmed(ref, instanceId);
      }
    });
  }

  void _deleteInstanceConfirmed(WidgetRef ref, String instanceId) async {
    try {
      final api = ref.read(mayaApiProvider);
      await api.deleteJson('/api/v1/instances/$instanceId');
      ref.invalidate(instancesListProvider);
    } catch (e) {
      // Error handling could be improved
    }
  }
}

class InstanceInfo {
  final String id;
  final String name;
  final String persona;
  final String memoryScope;
  final double budgetUsd;
  final String owner;
  final int createdAt;
  final List<String> skills;

  InstanceInfo({
    required this.id,
    required this.name,
    required this.persona,
    required this.memoryScope,
    required this.budgetUsd,
    required this.owner,
    required this.createdAt,
    required this.skills,
  });

  factory InstanceInfo.fromJson(Map<String, dynamic> json) {
    return InstanceInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      persona: json['persona'] as String? ?? '',
      memoryScope: json['memory_scope'] as String? ?? '',
      budgetUsd: (json['budget_usd'] as num?)?.toDouble() ?? 0.0,
      owner: json['owner'] as String? ?? '',
      createdAt: json['created_at'] as int? ?? 0,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class InstancesResponse {
  final List<InstanceInfo> instances;

  InstancesResponse({required this.instances});

  factory InstancesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['instances'] as List<dynamic>? ?? [];
    return InstancesResponse(
      instances: list
          .map((e) => InstanceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final instancesListProvider = FutureProvider<InstancesResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/instances');
  return InstancesResponse.fromJson(response);
});
