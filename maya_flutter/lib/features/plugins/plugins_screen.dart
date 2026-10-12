import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final pluginsListProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.listPlugins();
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
        final plugins = data as List? ?? [];
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
            final plugin = plugins[index];
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
  final dynamic plugin;

  const _PluginCard({required this.plugin});

  @override
  ConsumerState<_PluginCard> createState() => _PluginCardState();
}

class _PluginCardState extends ConsumerState<_PluginCard> {
  bool _isToggling = false;

  Future<void> _toggle() async {
    setState(() => _isToggling = true);
    try {
      await ref.read(mayaApiProvider).updatePlugin(
        widget.plugin['id'] ?? widget.plugin['name'],
        {'enabled': !(widget.plugin['enabled'] ?? false)},
      );
      ref.invalidate(pluginsListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plugin = widget.plugin;
    final enabled = plugin['enabled'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: enabled ? MayaTheme.neonEmerald.withValues(alpha: 0.2) : MayaTheme.neonOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.extension_rounded,
              color: enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plugin['name'] ?? 'Unknown Plugin', style: MayaTheme.titleMedium),
                Text(plugin['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (plugin['version'] != null)
                  Text('Version: ${plugin['version']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: _isToggling ? null : (_) => _toggle(),
            activeColor: MayaTheme.neonEmerald,
            inactiveThumbColor: MayaTheme.neonOrange,
          ),
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
  final _pluginIdController = TextEditingController();
  bool _isInstalling = false;

  @override
  void dispose() {
    _pluginIdController.dispose();
    super.dispose();
  }

  Future<void> _install() async {
    final pluginId = _pluginIdController.text.trim();
    if (pluginId.isEmpty) return;

    setState(() => _isInstalling = true);
    try {
      await ref.read(mayaApiProvider).installPlugin(pluginId);
      _pluginIdController.clear();
      ref.invalidate(pluginsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Plugin installed'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
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
            'Install a new plugin from the catalog. Note: New plugins can also be added by dropping .py files into the plugins/ folder.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pluginIdController,
            decoration: const InputDecoration(
              labelText: 'Plugin ID',
              hintText: 'e.g., my_plugin',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isInstalling ? null : _install,
              icon: _isInstalling
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.add_circle_rounded),
              label: Text(_isInstalling ? 'Installing...' : 'Install Plugin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}