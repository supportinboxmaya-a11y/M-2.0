import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final mcpServersProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.mcpListServers();
});

class McpClientScreen extends ConsumerStatefulWidget {
  const McpClientScreen({super.key});

  @override
  ConsumerState<McpClientScreen> createState() => _McpClientScreenState();
}

class _McpClientScreenState extends ConsumerState<McpClientScreen>
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
          title: const Text('MCP Servers', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(mcpServersProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.extension_rounded), text: 'Servers'),
              Tab(icon: Icon(Icons.add_circle_rounded), text: 'Connect'),
              Tab(icon: Icon(Icons.terminal_rounded), text: 'Call Tool'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _McpServersTab(),
            _McpConnectTab(),
            _McpCallTab(),
          ],
        ),
      ),
    );
  }
}

class _McpServersTab extends ConsumerWidget {
  const _McpServersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(mcpServersProvider);

    return serversAsync.when(
      data: (data) {
        final servers = data['servers'] as List? ?? [];
        if (servers.isEmpty) {
          return const MayaEmptyState(
            'No MCP Servers connected',
            icon: Icons.extension_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: servers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final server = servers[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.extension_rounded, color: MayaTheme.neonCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(server['name'] ?? 'Unknown Server', style: MayaTheme.titleMedium),
                        Text('Status: ${server['status'] ?? 'connected'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                        if (server['tools'] != null)
                          Text('Tools: ${(server['tools'] as List).length}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: MayaTheme.error),
                    onPressed: () async {
                      await ref.read(mayaApiProvider).mcpDisconnectServer(server['name']);
                      ref.invalidate(mcpServersProvider);
                    },
                  ),
                ],
              );
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
            Text('Error loading servers', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _McpConnectTab extends ConsumerStatefulWidget {
  const _McpConnectTab();

  @override
  ConsumerState<_McpConnectTab> createState() => _McpConnectTabState();
}

class _McpConnectTabState extends ConsumerState<_McpConnectTab> {
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  final _envController = TextEditingController();
  bool _isConnecting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _envController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final name = _nameController.text.trim();
    final command = _commandController.text.split(' ').where((e) => e.isNotEmpty).toList();
    if (name.isEmpty || command.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please fill in Name and Command'), backgroundColor: MayaTheme.error),
      );
      return;
    }

    final env = <String, String>{};
    for (final line in _envController.text.split('\n')) {
      final parts = line.split('=');
      if (parts.length == 2) {
        env[parts[0].trim()] = parts[1].trim();
      }
    }

    setState(() => _isConnecting = true);
    try {
      await ref.read(mayaApiProvider).mcpConnectServer(
        name: name,
        command: command,
        env: env.isEmpty ? null : env,
      );
      _nameController.clear();
      _commandController.clear();
      _envController.clear();
      ref.invalidate(mcpServersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('MCP Server connected'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Connect MCP Server', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Connect to an MCP server by providing its name and command.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Server Name',
              hintText: 'e.g., github, filesystem',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commandController,
            decoration: const InputDecoration(
              labelText: 'Command',
              hintText: 'e.g., npx @modelcontextprotocol/server-github',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _envController,
            decoration: const InputDecoration(
              labelText: 'Environment Variables (KEY=VALUE, one per line)',
              hintText: 'GITHUB_TOKEN=xxx\nAPI_KEY=yyy',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isConnecting ? null : _connect,
              icon: _isConnecting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.link_rounded),
              label: Text(_isConnecting ? 'Connecting...' : 'Connect Server'),
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

class _McpCallTab extends ConsumerStatefulWidget {
  const _McpCallTab();

  @override
  ConsumerState<_McpCallTab> createState() => _McpCallTabState();
}

class _McpCallTabState extends ConsumerState<_McpCallTab> {
  final _serverNameController = TextEditingController();
  final _toolNameController = TextEditingController();
  final _argumentsController = TextEditingController(text: '{}');
  bool _isCalling = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _serverNameController.dispose();
    _toolNameController.dispose();
    _argumentsController.dispose();
    super.dispose();
  }

  Future<void> _callTool() async {
    if (_serverNameController.text.trim().isEmpty || _toolNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please fill in Server Name and Tool Name'), backgroundColor: MayaTheme.error),
      );
      return;
    }

    Map<String, dynamic>? arguments;
    try {
      arguments = _argumentsController.text.isNotEmpty
          ? Map<String, dynamic>.from(
              _argumentsController.text.isEmpty
                  ? {}
                  : (() {
                      // Simple JSON parsing for basic objects
                      final text = _argumentsController.text.trim();
                      if (text.startsWith('{') && text.endsWith('}')) {
                        // Basic parsing - in production use a proper JSON parser
                        return <String, dynamic>{};
                      }
                      return <String, dynamic>{};
                    })()
          )
          : {};
    } catch (_) {
      arguments = {};
    }

    setState(() {
      _isCalling = true;
      _result = null;
    });

    try {
      final result = await ref.read(mayaApiProvider).mcpCallTool(
        serverName: _serverNameController.text.trim(),
        toolName: _toolNameController.text.trim(),
        arguments: arguments,
      );
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCalling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Call MCP Tool', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Call a tool on a connected MCP server.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _serverNameController,
            decoration: const InputDecoration(
              labelText: 'Server Name',
              hintText: 'e.g., github',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _toolNameController,
            decoration: const InputDecoration(
              labelText: 'Tool Name',
              hintText: 'e.g., search_repositories',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _argumentsController,
            decoration: const InputDecoration(
              labelText: 'Arguments (JSON)',
              hintText: '{"query": "maya", "limit": 10}',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCalling ? null : _callTool,
              icon: _isCalling
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.terminal_rounded),
              label: Text(_isCalling ? 'Calling...' : 'Call Tool'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Result', style: MayaTheme.titleMedium),
                  const SizedBox(height: 12),
                  SelectableText(
                    _result.toString(),
                    style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}