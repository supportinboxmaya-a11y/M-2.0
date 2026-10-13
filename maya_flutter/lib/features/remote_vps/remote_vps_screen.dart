import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final vpsConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.vpsConfig();
});

final vpsContainersProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.vpsListContainers();
});

class RemoteVpsScreen extends ConsumerWidget {
  const RemoteVpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(vpsConfigProvider);
    final containersAsync = ref.watch(vpsContainersProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title:
              const Text('Remote VPS Deploy', style: MayaTheme.headlineSmall),
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
                ref.invalidate(vpsConfigProvider);
                ref.invalidate(vpsContainersProvider);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VPS Config Status
              configAsync.maybeWhen(
                data: (config) => _buildConfigView(config),
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(MayaTheme.neonCyan))),
                error: (err, _) => _ErrorCard(error: err.toString()),
                orElse: () => const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(MayaTheme.neonCyan))),
              ),
              const SizedBox(height: 24),

              // Deploy New Container
              const Text('Deploy New Container', style: MayaTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Build and deploy a Docker container to the remote VPS.',
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              const _DeployContainerForm(),
              const SizedBox(height: 24),

              // Container List
              const Text('Running Containers', style: MayaTheme.titleLarge),
              const SizedBox(height: 16),
              containersAsync.maybeWhen(
                data: (data) => _buildContainersList(data),
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(MayaTheme.neonCyan))),
                error: (err, _) => _ErrorCard(error: err.toString()),
                orElse: () => const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(MayaTheme.neonCyan))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigView(Map<String, dynamic> config) {
    final configured = config['configured'] == true;
    final host = config['host'] ?? '';
    final port = config['port'] ?? 22;
    final user = config['user'] ?? '';
    final hasKey = config['has_key'] == true;
    final hasPassword = config['has_password'] == true;
    final paramiko = config['paramiko'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VPS Configuration', style: MayaTheme.titleLarge),
        const SizedBox(height: 16),
        Container(
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
                      color: MayaTheme.neonEmerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_rounded,
                      color: MayaTheme.neonEmerald,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VPS Configuration',
                          style: MayaTheme.titleMedium.copyWith(
                            color: MayaTheme.neonCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (configured) ...[
          _ConfigRow(label: 'Host', value: host),
          _ConfigRow(label: 'Port', value: port.toString()),
          _ConfigRow(label: 'User', value: user),
          _ConfigRow(
              label: 'SSH Key',
              value: hasKey ? 'Configured' : 'Not set',
              color: hasKey ? MayaTheme.neonEmerald : MayaTheme.error),
          _ConfigRow(
              label: 'Password Auth',
              value: hasPassword ? 'Enabled' : 'Disabled',
              color: hasPassword ? MayaTheme.neonEmerald : MayaTheme.error),
          _ConfigRow(
              label: 'Paramiko',
              value: paramiko ? 'Available' : 'Not available',
              color: paramiko ? MayaTheme.neonEmerald : MayaTheme.error),
        ] else ...[
          Text(
            'Set VPS_HOST, VPS_PORT, VPS_USER, and VPS_SSH_KEY_PATH or VPS_PASSWORD environment variables to configure.',
            style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
          ),
        ],
      ],
    );
  }

  Widget _buildContainersList(Map<String, dynamic> data) {
    final containers = data['containers'] as List? ?? [];
    if (containers.isEmpty) {
      return const MayaEmptyState(
        'No containers running on VPS',
        icon: Icons.developer_board_rounded,
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: containers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final c = containers[index];
        return _ContainerCard(container: c);
      },
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ConfigRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label:',
              style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          const SizedBox(width: 8),
          Text(value,
              style: MayaTheme.bodySmall.copyWith(
                  color: color ?? Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MayaTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MayaTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: MayaTheme.error),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Error: $error',
                  style: MayaTheme.bodySmall.copyWith(color: MayaTheme.error))),
        ],
      ),
    );
  }
}

class _DeployContainerForm extends ConsumerStatefulWidget {
  const _DeployContainerForm();

  @override
  ConsumerState<_DeployContainerForm> createState() =>
      _DeployContainerFormState();
}

class _DeployContainerFormState extends ConsumerState<_DeployContainerForm> {
  final _appController = TextEditingController();
  final _imageController = TextEditingController();
  final _dockerfileController = TextEditingController();
  final _portsController = TextEditingController(text: '8080:80');
  final _envController = TextEditingController();
  bool _isBuilding = false;
  bool _isRunning = false;
  String? _builtImage;

  @override
  void dispose() {
    _appController.dispose();
    _imageController.dispose();
    _dockerfileController.dispose();
    _portsController.dispose();
    _envController.dispose();
    super.dispose();
  }

  Future<void> _buildImage() async {
    if (_appController.text.trim().isEmpty ||
        _dockerfileController.text.trim().isEmpty) return;

    setState(() => _isBuilding = true);
    try {
      final result = await ref.read(mayaApiProvider).vpsBuildImage(
            app: _appController.text.trim(),
            dockerfileDir: _dockerfileController.text.trim(),
          );
      if (mounted) {
        setState(() {
          _builtImage = _appController.text.trim();
          _imageController.text = _builtImage!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Image built: ${result['output']}'),
              backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuilding = false);
    }
  }

  Future<void> _runContainer() async {
    if (_appController.text.trim().isEmpty ||
        _imageController.text.trim().isEmpty) return;

    final ports = <String, String>{};
    for (final p in _portsController.text.split(',')) {
      final parts = p.trim().split(':');
      if (parts.length == 2) {
        ports[parts[0].trim()] = parts[1].trim();
      }
    }

    final env = <String, String>{};
    for (final e in _envController.text.split(',')) {
      final parts = e.trim().split('=');
      if (parts.length == 2) {
        env[parts[0].trim()] = parts[1].trim();
      }
    }

    setState(() => _isRunning = true);
    try {
      final result = await ref.read(mayaApiProvider).vpsRunContainer(
            app: _appController.text.trim(),
            image: _imageController.text.trim(),
            ports: ports.isEmpty ? null : ports,
            env: env.isEmpty ? null : env,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Container started: ${result['container_id']}'),
              backgroundColor: MayaTheme.neonEmerald),
        );
        ref.invalidate(vpsContainersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowChildren = <Widget>[
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _isBuilding ? null : _buildImage,
          icon: _isBuilding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: MayaTheme.slate900))
              : const Icon(Icons.construction_rounded),
          label: Text(_isBuilding ? 'Building...' : 'Build Image'),
          style: ElevatedButton.styleFrom(
            backgroundColor: MayaTheme.neonViolet,
            foregroundColor: MayaTheme.slate900,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ];
    if (_builtImage != null) {
      rowChildren.addAll([
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isRunning ? null : _runContainer,
            icon: _isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MayaTheme.slate900))
                : const Icon(Icons.rocket_launch_rounded),
            label: Text(_isRunning ? 'Running...' : 'Run Container'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.neonCyan,
              foregroundColor: MayaTheme.slate900,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _appController,
          decoration: const InputDecoration(
            labelText: 'App Name',
            hintText: 'my-app',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _imageController,
          decoration: const InputDecoration(
            labelText: 'Docker Image',
            hintText: 'my-app:latest or nginx:latest',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dockerfileController,
          decoration: const InputDecoration(
            labelText: 'Dockerfile Directory (for build)',
            hintText: './docker or /path/to/dockerfile',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: rowChildren),
        const SizedBox(height: 16),
        TextField(
          controller: _portsController,
          decoration: const InputDecoration(
            labelText: 'Ports (comma-separated, host:container)',
            hintText: '8080:80, 8443:443',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _envController,
          decoration: const InputDecoration(
            labelText: 'Environment Variables (comma-separated, KEY=VALUE)',
            hintText: 'ENV=production, DEBUG=false',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _ContainerCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> container;

  const _ContainerCard({required this.container});

  @override
  ConsumerState<_ContainerCard> createState() => _ContainerCardState();
}

class _ContainerCardState extends ConsumerState<_ContainerCard> {
  bool _isActing = false;

  Future<void> _performAction(String action) async {
    setState(() => _isActing = true);
    try {
      final app =
          widget.container['Names']?.toString().replaceAll('/', '') ?? '';
      if (app.isEmpty) return;

      switch (action) {
        case 'start':
          await ref.read(mayaApiProvider).vpsStartContainer(app);
          break;
        case 'stop':
          await ref.read(mayaApiProvider).vpsStopContainer(app);
          break;
        case 'restart':
          await ref.read(mayaApiProvider).vpsRestartContainer(app);
          break;
        case 'remove':
          await ref.read(mayaApiProvider).vpsRemoveContainer(app);
          break;
      }
      ref.invalidate(vpsContainersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: MayaTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _viewLogs() async {
    final app = widget.container['Names']?.toString().replaceAll('/', '') ?? '';
    if (app.isEmpty) return;

    try {
      final result = await ref.read(mayaApiProvider).vpsContainerLogs(app: app);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: MayaTheme.slate800,
          isScrollControlled: true,
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder: (_, controller) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Logs: $app', style: MayaTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: SelectableText(
                        result['logs'] ?? 'No logs',
                        style: MayaTheme.bodySmall.copyWith(
                            fontFamily: 'monospace', color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: MayaTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.container;
    final name = c['Names']?.toString().replaceAll('/', '') ?? 'unknown';
    final image = c['Image'] ?? 'unknown';
    final status = c['Status'] ?? 'unknown';
    final ports = c['Ports'] ?? '';
    final running = status.toLowerCase().startsWith('up');

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
                  color:
                      (running ? MayaTheme.neonEmerald : MayaTheme.neonOrange)
                          .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.developer_board_rounded,
                  color: running ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: MayaTheme.titleMedium),
                    Text('Image: $image',
                        style: MayaTheme.bodySmall.copyWith(
                            color: Colors.white54, fontFamily: 'monospace')),
                    Text('Ports: $ports',
                        style: MayaTheme.bodySmall.copyWith(
                            color: Colors.white54, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (running ? MayaTheme.neonEmerald : MayaTheme.neonOrange)
                          .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: running
                          ? MayaTheme.neonEmerald
                          : MayaTheme.neonOrange),
                ),
                child: Text(
                  running ? 'RUNNING' : 'STOPPED',
                  style: MayaTheme.labelSmall.copyWith(
                      color: running
                          ? MayaTheme.neonEmerald
                          : MayaTheme.neonOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Status: $status',
              style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _isActing ? null : () => _performAction('start'),
                icon: _isActing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: MayaTheme.slate900))
                    : const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(_isActing ? 'Starting...' : 'Start'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonEmerald,
                    foregroundColor: MayaTheme.slate900),
              ),
              ElevatedButton.icon(
                onPressed: _isActing ? null : () => _performAction('stop'),
                icon: _isActing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: MayaTheme.slate900))
                    : const Icon(Icons.stop_rounded, size: 16),
                label: Text(_isActing ? 'Stopping...' : 'Stop'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.error,
                    foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: _isActing ? null : () => _performAction('restart'),
                icon: _isActing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: MayaTheme.slate900))
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(_isActing ? 'Restarting...' : 'Restart'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonCyan,
                    foregroundColor: MayaTheme.slate900),
              ),
              ElevatedButton.icon(
                onPressed: _viewLogs,
                icon: const Icon(Icons.article_rounded, size: 16),
                label: const Text('Logs'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonViolet,
                    foregroundColor: MayaTheme.slate900),
              ),
              ElevatedButton.icon(
                onPressed: _isActing ? null : () => _performAction('remove'),
                icon: const Icon(Icons.delete_rounded, size: 16),
                label: const Text('Remove'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.error,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
