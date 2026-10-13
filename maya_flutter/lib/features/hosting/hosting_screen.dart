import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final hostingAppsProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, owner) async {
  final api = ref.watch(mayaApiProvider);
  return api.hostingListApps(owner: owner);
});

final hostingAppProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, name) async {
  final api = ref.watch(mayaApiProvider);
  return api.hostingGetApp(name);
});

class HostingScreen extends ConsumerStatefulWidget {
  const HostingScreen({super.key});

  @override
  ConsumerState<HostingScreen> createState() => _HostingScreenState();
}

class _HostingScreenState extends ConsumerState<HostingScreen>
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
          title: const Text('Hosting Manager', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(hostingAppsProvider(null)),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _tabController.animateTo(1),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.apps_rounded), text: 'Apps'),
              Tab(icon: Icon(Icons.rocket_launch_rounded), text: 'Deploy'),
              Tab(icon: Icon(Icons.person_rounded), text: 'My Apps'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _AppsTab(),
            _DeployTab(),
            _MyAppsTab(),
          ],
        ),
      ),
    );
  }
}

class _AppsTab extends ConsumerWidget {
  const _AppsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(hostingAppsProvider(null));

    return appsAsync.when(
      data: (data) {
        final apps = data['apps'] as List? ?? [];
        if (apps.isEmpty) {
          return const MayaEmptyState(
            'No hosted apps yet',
            icon: Icons.apps_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final app = apps[index];
            return _AppCard(app: app);
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
            Text('Error loading apps', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _AppCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> app;

  const _AppCard({required this.app});

  @override
  ConsumerState<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends ConsumerState<_AppCard> {
  bool _isActing = false;

  Future<void> _start() async {
    setState(() => _isActing = true);
    try {
      await ref.read(mayaApiProvider).hostingStart(widget.app['name']);
      ref.invalidate(hostingAppsProvider(null));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _isActing = true);
    try {
      await ref.read(mayaApiProvider).hostingStop(widget.app['name']);
      ref.invalidate(hostingAppsProvider(null));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _restart() async {
    setState(() => _isActing = true);
    try {
      await ref.read(mayaApiProvider).hostingRestart(widget.app['name']);
      ref.invalidate(hostingAppsProvider(null));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _remove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Remove App', style: MayaTheme.titleMedium),
        content: Text('Are you sure you want to permanently remove "${widget.app['name']}"?', style: MayaTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isActing = true);
    try {
      await ref.read(mayaApiProvider).hostingRemove(widget.app['name']);
      ref.invalidate(hostingAppsProvider(null));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final alive = app['alive'] == true;
    final reachable = app['reachable'] == true;
    final pid = app['pid'] ?? 0;

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
                  color: (alive ? MayaTheme.neonEmerald : MayaTheme.neonOrange).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.apps_rounded,
                  color: alive ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app['name'] ?? '', style: MayaTheme.titleMedium),
                    Text('Kind: ${app['kind']} • Port: ${app['port']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (alive ? MayaTheme.neonEmerald : MayaTheme.neonOrange).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: alive ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                ),
                child: Text(
                  alive ? 'RUNNING' : 'STOPPED',
                  style: MayaTheme.labelSmall.copyWith(color: alive ? MayaTheme.neonEmerald : MayaTheme.neonOrange),
                ),
              ),
              const SizedBox(width: 8),
              if (reachable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MayaTheme.neonCyan),
                  ),
                  child: Text(
                    'REACHABLE',
                    style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('PID: $pid', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _isActing ? null : _start,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(_isActing ? 'Starting...' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MayaTheme.neonEmerald,
                  foregroundColor: MayaTheme.slate900,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isActing ? null : _stop,
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: Text(_isActing ? 'Stopping...' : 'Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MayaTheme.error,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isActing ? null : _restart,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(_isActing ? 'Restarting...' : 'Restart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MayaTheme.neonCyan,
                  foregroundColor: MayaTheme.slate900,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isActing ? null : _remove,
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: Text(_isActing ? 'Removing...' : 'Remove'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MayaTheme.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeployTab extends ConsumerStatefulWidget {
  const _DeployTab();

  @override
  ConsumerState<_DeployTab> createState() => _DeployTabState();
}

class _DeployTabState extends ConsumerState<_DeployTab> {
  final _nameController = TextEditingController();
  final _entryController = TextEditingController();
  final _pathController = TextEditingController();
  final _commandController = TextEditingController();
  final _portController = TextEditingController();
  String _kind = 'python-asgi';
  bool _isDeploying = false;

  @override
  void dispose() {
    _nameController.dispose();
    _entryController.dispose();
    _pathController.dispose();
    _commandController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _deploy() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isDeploying = true);
    try {
      await ref.read(mayaApiProvider).hostingDeploy(
        name: _nameController.text.trim(),
        kind: _kind,
        entry: _entryController.text.trim().isEmpty ? null : _entryController.text.trim(),
        path: _pathController.text.trim().isEmpty ? null : _pathController.text.trim(),
        command: _commandController.text.trim().isEmpty ? null : _commandController.text.trim(),
        port: _portController.text.isEmpty ? null : int.tryParse(_portController.text),
      );
      _nameController.clear();
      _entryController.clear();
      _pathController.clear();
      _commandController.clear();
      _portController.clear();
      ref.invalidate(hostingAppsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('App deployed successfully'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeploying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deploy New App', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Deploy a new app to the local hosting manager. Supports Python ASGI, Python scripts, Node.js, static files, and custom commands.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'App Name', hintText: 'my-app', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _kind,
            decoration: const InputDecoration(labelText: 'App Kind', border: OutlineInputBorder()),
            dropdownColor: MayaTheme.slate800,
            items: const [
              DropdownMenuItem(value: 'python-asgi', child: Text('Python ASGI (FastAPI, Starlette)')),
              DropdownMenuItem(value: 'python', child: Text('Python Script')),
              DropdownMenuItem(value: 'node', child: Text('Node.js')),
              DropdownMenuItem(value: 'static', child: Text('Static Files')),
              DropdownMenuItem(value: 'command', child: Text('Custom Command')),
            ],
            onChanged: (v) => setState(() => _kind = v ?? 'python-asgi'),
          ),
          const SizedBox(height: 16),
          if (_kind == 'python-asgi' || _kind == 'python' || _kind == 'node')
            TextField(
              controller: _entryController,
              decoration: const InputDecoration(labelText: 'Entry Point', hintText: 'main:app or index.js', border: OutlineInputBorder()),
            ),
          if (_kind == 'static' || _kind == 'python' || _kind == 'node' || _kind == 'python-asgi')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: _pathController,
                decoration: const InputDecoration(labelText: 'Working Directory', hintText: '/path/to/app', border: OutlineInputBorder()),
              ),
            ),
          if (_kind == 'command')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: _commandController,
                decoration: const InputDecoration(labelText: 'Command', hintText: 'python main.py', border: OutlineInputBorder()),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(labelText: 'Port (optional, auto-assigned)', hintText: '8100-8999', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDeploying ? null : _deploy,
              icon: _isDeploying
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(_isDeploying ? 'Deploying...' : 'Deploy App'),
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

class _MyAppsTab extends ConsumerWidget {
  const _MyAppsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, show all apps. In a real app, this would filter by current user.
    final appsAsync = ref.watch(hostingAppsProvider('system'));

    return appsAsync.when(
      data: (data) {
        final apps = data['apps'] as List? ?? [];
        if (apps.isEmpty) {
          return const MayaEmptyState(
            'No hosted apps yet',
            icon: Icons.person_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final app = apps[index];
            return _AppCard(app: app);
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
            Text('Error loading apps', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}