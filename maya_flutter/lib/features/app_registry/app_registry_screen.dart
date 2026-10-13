import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final registryListProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.registryList();
});

final registryCheckAllProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.registryCheckAll();
});

class AppRegistryScreen extends ConsumerStatefulWidget {
  const AppRegistryScreen({super.key});

  @override
  ConsumerState<AppRegistryScreen> createState() => _AppRegistryScreenState();
}

class _AppRegistryScreenState extends ConsumerState<AppRegistryScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(registryListProvider);
        ref.invalidate(registryCheckAllProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('App Registry & Monitoring', style: MayaTheme.headlineSmall),
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
                ref.invalidate(registryListProvider);
                ref.invalidate(registryCheckAllProvider);
              },
            ),
          ],
        ),
        body: _AppRegistryList(),
      ),
    );
  }
}

class _AppRegistryList extends ConsumerWidget {
  const _AppRegistryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(registryListProvider);
    final checkAllAsync = ref.watch(registryCheckAllProvider);

    return listAsync.when(
      data: (listData) {
        final apps = listData['apps'] as List? ?? [];
        if (apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apps_rounded, size: 48, color: Colors.white38),
                const SizedBox(height: 16),
                const Text('No Registered Apps', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Deploy an app to VPS to see it here', style: MayaTheme.bodyMedium),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/remote_vps');
                  },
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Deploy to VPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(registryListProvider);
            ref.invalidate(registryCheckAllProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final app = apps[index] as Map<String, dynamic>;
              return _AppRegistryTile(app: app, checkAllAsync: checkAllAsync);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading apps', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _AppRegistryTile extends ConsumerWidget {
  final Map<String, dynamic> app;
  final AsyncValue<Map<String, dynamic>> checkAllAsync;

  const _AppRegistryTile({required this.app, required this.checkAllAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkAllData = checkAllAsync.value;
    String healthStatus = 'unknown';
    String? healthError;

    if (checkAllData != null) {
      final results = checkAllData['results'] as List? ?? [];
      for (final result in results) {
        if (result['name'] == app['name']) {
          healthStatus = result['status'] ?? 'unknown';
          healthError = result['error'];
        }
      }
    }

    final status = app['status'] ?? 'unknown';
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'running':
        statusColor = MayaTheme.neonEmerald;
        break;
      case 'stopped':
        statusColor = MayaTheme.error;
        break;
      case 'error':
        statusColor = MayaTheme.error;
        break;
      default:
        statusColor = Colors.white38;
    }

    String healthIndicator = healthStatus;
    Color healthColor = Colors.white38;
    if (healthStatus.toLowerCase() == 'running') healthColor = MayaTheme.neonEmerald;
    if (healthStatus.toLowerCase() == 'stopped' || healthStatus.toLowerCase() == 'error') healthColor = MayaTheme.error;

    return Container(
      decoration: MayaTheme.glassCard(),
      child: ListTile(
        onTap: () => _showAppDetail(context, ref, app),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getAppIcon(app['image'] ?? ''), color: statusColor, size: 24),
        ),
        title: Text(app['name'] ?? '', style: MayaTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image: ${app['image'] ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: MayaTheme.labelSmall.copyWith(color: statusColor),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: healthColor),
                  ),
                  child: Text(
                    'Health: $healthIndicator',
                    style: MayaTheme.labelSmall.copyWith(color: healthColor),
                  ),
                ),
                if (app['monitor'] == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: MayaTheme.neonCyan),
                    ),
                    child: Text(
                      'MONITORED',
                      style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.toLowerCase() != 'running')
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded, color: MayaTheme.neonViolet),
                onPressed: () => _restartApp(context, ref, app),
                tooltip: 'Restart',
              ),
            IconButton(
              icon: const Icon(Icons.article_rounded, color: MayaTheme.neonCyan),
              onPressed: () => _showLogs(context, ref, app),
              tooltip: 'View Logs',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
              onPressed: () => _showMoreOptions(context, ref, app),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAppIcon(String image) {
    final lower = image.toLowerCase();
    if (lower.contains('nginx') || lower.contains('http')) return Icons.web_rounded;
    if (lower.contains('postgres') || lower.contains('mysql') || lower.contains('mongo') || lower.contains('redis')) return Icons.storage_rounded;
    if (lower.contains('python') || lower.contains('node') || lower.contains('golang') || lower.contains('rust')) return Icons.code_rounded;
    if (lower.contains('prometheus') || lower.contains('grafana')) return Icons.analytics_rounded;
    return Icons.apps_rounded;
  }

  void _showAppDetail(BuildContext context, WidgetRef ref, Map<String, dynamic> app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MayaTheme.slate800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AppDetailSheet(app: app),
    );
  }

  Future<void> _restartApp(BuildContext context, WidgetRef ref, Map<String, dynamic> app) async {
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.registryRestart(app['name']);
      if (context.mounted) {
        ref.invalidate(registryListProvider);
        ref.invalidate(registryCheckAllProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['ok'] == true ? 'Restart triggered' : 'Restart failed: ${result['error']}'),
            backgroundColor: result['ok'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _showLogs(BuildContext context, WidgetRef ref, Map<String, dynamic> app) async {
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.registryLogs(app['name'], lines: 100);
      if (context.mounted) {
        _showLogsSheet(context, app['name'], result['logs'] ?? '');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  void _showLogsSheet(BuildContext context, String appName, String logs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MayaTheme.slate800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: MayaTheme.slate800,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Logs: $appName', style: MayaTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    logs,
                    style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace', color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref, Map<String, dynamic> app) {
    final monitorEnabled = app['monitor'] == true;
    showModalBottomSheet(
      context: context,
      backgroundColor: MayaTheme.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(app['name'] ?? '', style: MayaTheme.titleLarge),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(monitorEnabled ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: MayaTheme.neonCyan),
              title: Text(monitorEnabled ? 'Disable Monitoring' : 'Enable Monitoring', style: MayaTheme.bodyMedium),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final api = ref.read(mayaApiProvider);
                  final result = await api.registrySetMonitor(app['name'], !monitorEnabled);
                  if (context.mounted) {
                    ref.invalidate(registryListProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Monitoring ${!monitorEnabled ? 'enabled' : 'disabled'}'),
                        backgroundColor: MayaTheme.neonCyan,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: MayaTheme.error),
              title: const Text('Unregister', style: TextStyle(color: MayaTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, app);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref, Map<String, dynamic> app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Unregister App', style: MayaTheme.titleLarge),
        content: Text(
          'Are you sure you want to unregister "${app['name']}"? This will remove it from the registry but will NOT delete the container on the VPS.',
          style: MayaTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unregister'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(mayaApiProvider);
        final result = await api.registryUnregister(app['name']);
        if (context.mounted) {
          ref.invalidate(registryListProvider);
          ref.invalidate(registryCheckAllProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['ok'] == true ? '${app['name']} unregistered' : 'Failed: ${result['error']}'),
              backgroundColor: result['ok'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
          );
        }
      }
    }
  }
}

class _AppDetailSheet extends ConsumerWidget {
  final Map<String, dynamic> app;

  const _AppDetailSheet({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: MayaTheme.slate800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(app['status']).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getStatusIcon(app['status']), color: _getStatusColor(app['status']), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app['name'] ?? '', style: MayaTheme.titleLarge),
                        Text('Image: ${app['image'] ?? ''}', style: MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(app['status']).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (app['status'] ?? '').toUpperCase(),
                      style: MayaTheme.labelSmall.copyWith(color: _getStatusColor(app['status'])),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: MayaTheme.glassWhite10),
              const SizedBox(height: 16),
              _DetailRow(label: 'Container ID', value: app['containerId']?.toString().isNotEmpty == true ? app['containerId'] : 'N/A'),
              _DetailRow(label: 'Image', value: app['image'] ?? ''),
              _DetailRow(label: 'Host', value: app['host']?.toString().isNotEmpty == true ? app['host'] : 'Default VPS'),
              _DetailRow(label: 'Status', value: app['status'] ?? '', valueColor: _getStatusColor(app['status'])),
              _DetailRow(label: 'Monitoring', value: app['monitor'] == true ? 'Enabled' : 'Disabled'),
              if (app['deployedAt'] != null)
                _DetailRow(label: 'Deployed', value: DateTime.fromMillisecondsSinceEpoch((app['deployedAt'] * 1000).round()).toString().substring(0, 19)),
              if (app['lastSeen'] != null)
                _DetailRow(label: 'Last Check-in', value: DateTime.fromMillisecondsSinceEpoch((app['lastSeen'] * 1000).round()).toString().substring(0, 19)),
              if (app['lastError'] != null && app['lastError'].toString().isNotEmpty)
                _DetailRow(label: 'Last Error', value: app['lastError'], valueColor: MayaTheme.error),
              const SizedBox(height: 24),
              const Divider(color: MayaTheme.glassWhite10),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final monitorEnabled = app['monitor'] == true;
                        _toggleMonitor(context, ref, app['name'], !monitorEnabled);
                      },
                      icon: Icon(app['monitor'] == true ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      label: Text(app['monitor'] == true ? 'Disable Monitoring' : 'Enable Monitoring'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MayaTheme.neonCyan,
                        side: const BorderSide(color: MayaTheme.neonCyan),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          final api = ref.read(mayaApiProvider);
                          final result = await api.registryRestart(app['name']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['ok'] == true ? 'Restart triggered' : 'Restart failed: ${result['error']}'),
                                backgroundColor: result['ok'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Restart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MayaTheme.neonViolet,
                        foregroundColor: MayaTheme.slate900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final api = ref.read(mayaApiProvider);
                      final result = await api.registryLogs(app['name'], lines: 100);
                      if (context.mounted) {
                        _showLogsSheet(context, app['name'], result['logs'] ?? '');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.article_rounded),
                  label: const Text('View Logs'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MayaTheme.neonCyan,
                    side: const BorderSide(color: MayaTheme.neonCyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, ref, app);
                  },
                  icon: const Icon(Icons.delete_rounded, color: MayaTheme.error),
                  label: const Text('Unregister', style: TextStyle(color: MayaTheme.error)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MayaTheme.error,
                    side: const BorderSide(color: MayaTheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogsSheet(BuildContext context, String appName, String logs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MayaTheme.slate800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: MayaTheme.slate800,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Logs: $appName', style: MayaTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    logs,
                    style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace', color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleMonitor(BuildContext context, WidgetRef ref, String name, bool enabled) async {
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.registrySetMonitor(name, enabled);
      if (context.mounted) {
        ref.invalidate(registryListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monitoring ${enabled ? 'enabled' : 'disabled'}'),
            backgroundColor: MayaTheme.neonCyan,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Unregister App', style: MayaTheme.titleLarge),
        content: Text(
          'Are you sure you want to unregister "${app['name']}"? This will remove it from the registry but will NOT delete the container on the VPS.',
          style: MayaTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final api = ref.read(mayaApiProvider);
                final result = await api.registryUnregister(app['name']);
                if (context.mounted) {
                  ref.invalidate(registryListProvider);
                  ref.invalidate(registryCheckAllProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['ok'] == true ? '${app['name']} unregistered' : 'Failed: ${result['error']}'),
                      backgroundColor: result['ok'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unregister'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'running':
        return MayaTheme.neonEmerald;
      case 'stopped':
        return MayaTheme.error;
      case 'error':
        return MayaTheme.error;
      default:
        return Colors.white38;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'running':
        return Icons.check_circle_rounded;
      case 'stopped':
        return Icons.cancel_rounded;
      case 'error':
        return Icons.error_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: MayaTheme.labelMedium.copyWith(color: Colors.white54)),
          ),
          Expanded(
            child: Text(value, style: MayaTheme.bodyMedium.copyWith(color: valueColor ?? Colors.white)),
          ),
        ],
      ),
    );
  }
}