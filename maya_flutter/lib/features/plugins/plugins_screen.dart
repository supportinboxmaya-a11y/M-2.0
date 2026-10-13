import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final pluginsListProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.pluginsList();
});

class PluginsScreen extends ConsumerStatefulWidget {
  const PluginsScreen({super.key});

  @override
  ConsumerState<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends ConsumerState<PluginsScreen>
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
          title: const Text('Plugins', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(pluginsListProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.extension_rounded), text: 'Installed'),
              Tab(icon: Icon(Icons.add_circle_rounded), text: 'Install'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _PluginsListTab(),
            _PluginsInstallTab(),
          ],
        ),
      ),
    );
  }
}

class _PluginsListTab extends ConsumerWidget {
  const _PluginsListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginsAsync = ref.watch(pluginsListProvider);

    return pluginsAsync.when(
      data: (data) {
        final plugins = data['plugins'] as List? ?? [];
        if (plugins.isEmpty) {
          return const MayaEmptyState(
            'No Plugins installed',
            icon: Icons.extension_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: plugins.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final plugin = plugins[index] as Map<String, dynamic>;
            return _PluginCard(plugin: plugin);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading plugins', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _PluginCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> plugin;

  const _PluginCard({required this.plugin});

  @override
  ConsumerState<_PluginCard> createState() => _PluginCardState();
}

class _PluginCardState extends ConsumerState<_PluginCard> {
  bool _isUpdating = false;

  Future<void> _toggleEnabled() async {
    setState(() => _isUpdating = true);
    try {
      final api = ref.read(mayaApiProvider);
      final newEnabled = !(widget.plugin['enabled'] == true);
      await api.pluginsUpdate(widget.plugin['id'] ?? widget.plugin['name'] ?? '', enabled: newEnabled);
      ref.invalidate(pluginsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plugin ${newEnabled ? 'enabled' : 'disabled'}'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _uninstall() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Uninstall Plugin', style: MayaTheme.titleMedium),
        content: Text('Are you sure you want to uninstall "${widget.plugin['name']}"?', style: MayaTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      final api = ref.read(mayaApiProvider);
      await api.pluginsDelete(widget.plugin['id'] ?? widget.plugin['name'] ?? '');
      ref.invalidate(pluginsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Plugin uninstalled'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plugin = widget.plugin;
    final enabled = plugin['enabled'] == true;

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
                  color: (enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plugin['name'] ?? '', style: MayaTheme.titleMedium),
                    Text('v${plugin['version'] ?? '1.0.0'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                ),
                child: Text(
                  enabled ? 'ENABLED' : 'DISABLED',
                  style: MayaTheme.labelSmall.copyWith(color: enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(enabled ? Icons.toggle_off_rounded : Icons.toggle_on_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(enabled ? 'Disable' : 'Enable'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'uninstall',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18, color: MayaTheme.error),
                        SizedBox(width: 8),
                        Text('Uninstall', style: TextStyle(color: MayaTheme.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'toggle') {
                    await _toggleEnabled();
                  } else if (value == 'uninstall') {
                    await _uninstall();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(plugin['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Installed: ${plugin['installedAt'] ?? 'unknown'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }
}

class _PluginsInstallTab extends ConsumerStatefulWidget {
  const _PluginsInstallTab();

  @override
  ConsumerState<_PluginsInstallTab> createState() => _PluginsInstallTabState();
}

class _PluginsInstallTabState extends ConsumerState<_PluginsInstallTab> {
  final _nameController = TextEditingController();
  bool _isInstalling = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _install() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plugin name required'), backgroundColor: MayaTheme.error));
      return;
    }

    setState(() => _isInstalling = true);
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.pluginsInstall(_nameController.text.trim());
      _nameController.clear();
      ref.invalidate(pluginsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['installed'] == true ? 'Plugin installed: ${result['id']}' : 'Failed: ${result['detail'] ?? 'Unknown error'}'),
            backgroundColor: result['installed'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Install failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isInstalling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Install Plugin', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Install a new plugin by name (e.g., maya-plugin-github)',
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
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Plugin Name *',
                    hintText: 'e.g., maya-plugin-github',
                    labelStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.extension_rounded, color: Colors.white54),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isInstalling ? null : _install,
                    icon: _isInstalling
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.extension_rounded),
                    label: Text(_isInstalling ? 'Installing...' : 'Install Plugin'),
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