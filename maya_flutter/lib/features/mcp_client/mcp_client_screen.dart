import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

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
              onPressed: () {},
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
    return const MayaEmptyState(
      'No MCP Servers connected',
      icon: Icons.extension_rounded,
    );
  }
}

class _McpConnectTab extends ConsumerWidget {
  const _McpConnectTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.add_circle_rounded,
    );
  }
}

class _McpCallTab extends ConsumerWidget {
  const _McpCallTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.terminal_rounded,
    );
  }
}
