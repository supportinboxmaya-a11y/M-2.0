import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'agi_architecture_models.dart';
import 'agi_architecture_providers.dart';

class AGIArchitectureScreen extends ConsumerStatefulWidget {
  const AGIArchitectureScreen({super.key});

  @override
  ConsumerState<AGIArchitectureScreen> createState() =>
      _AGIArchitectureScreenState();
}

class _AGIArchitectureScreenState extends ConsumerState<AGIArchitectureScreen>
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
          title: const Text('AGI Architecture', style: MayaTheme.headlineSmall),
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
                ref.invalidate(agiComponentsProvider);
                ref.invalidate(agiConnectionsProvider);
                ref.invalidate(agiStatsProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.psychology_rounded), text: 'Components'),
              Tab(icon: Icon(Icons.link_rounded), text: 'Connections'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ComponentsTab(),
            _ConnectionsTab(),
            _StatsTab(),
          ],
        ),
      ),
    );
  }
}

class _ComponentsTab extends ConsumerWidget {
  const _ComponentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentsAsync = ref.watch(agiComponentsProvider);

    return componentsAsync.when(
      data: (data) => data.components.isEmpty
          ? const MayaEmptyState(
              'No Components',
              icon: Icons.psychology_rounded,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Architecture Components',
                      style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Core components of the AGI architecture',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.components.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final component = data.components[index];
                      return _ComponentCard(component: component);
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
        Text('Error loading components',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _ComponentCard extends ConsumerWidget {
  final AGIArchitectureComponent component;

  const _ComponentCard({required this.component});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return MayaTheme.neonEmerald;
      case 'inactive':
        return MayaTheme.neonOrange;
      case 'error':
        return MayaTheme.error;
      default:
        return Colors.white54;
    }
  }

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
                  color:
                      _getStatusColor(component.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.psychology_rounded,
                    color: _getStatusColor(component.status), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(component.name, style: MayaTheme.titleMedium),
                    Text(component.type,
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(component.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(component.status)),
                ),
                child: Text(component.status.toUpperCase(),
                    style: MayaTheme.labelSmall
                        .copyWith(color: _getStatusColor(component.status))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(component.description, style: MayaTheme.bodyMedium),
          if (component.config != null && component.config!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Config:', style: MayaTheme.labelMedium),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MayaTheme.slate800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                component.config.toString(),
                style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionsTab extends ConsumerWidget {
  const _ConnectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(agiConnectionsProvider);

    return connectionsAsync.when(
      data: (data) => data.connections.isEmpty
          ? const MayaEmptyState(
              'No Connections',
              icon: Icons.link_rounded,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Component Connections',
                      style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Data flow and dependencies between components',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.connections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final connection = data.connections[index];
                      return _ConnectionCard(connection: connection);
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
        Text('Error loading connections',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final AGIConnection connection;

  const _ConnectionCard({required this.connection});

  @override
  Widget build(BuildContext context) {
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
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded,
                    color: MayaTheme.neonViolet, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${connection.from} → ${connection.to}',
                        style: MayaTheme.titleMedium),
                    Text(connection.type,
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    'Weight: ${(connection.weight * 100).toStringAsFixed(1)}%',
                    style: MayaTheme.labelSmall
                        .copyWith(color: MayaTheme.neonCyan)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Type: ${connection.type}',
              style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(agiStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Architecture Statistics', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Overview of the AGI architecture health',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Total Components',
                        value: stats.totalComponents.toString(),
                        color: MayaTheme.neonCyan,
                        icon: Icons.psychology_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Active',
                        value: stats.activeComponents.toString(),
                        color: MayaTheme.neonEmerald,
                        icon: Icons.check_circle_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Connections',
                        value: stats.connections.toString(),
                        color: MayaTheme.neonViolet,
                        icon: Icons.link_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Health',
                        value: stats.overallHealth.toUpperCase(),
                        color: MayaTheme.neonEmerald,
                        icon: Icons.favorite_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: const Text(
                'Detailed architecture metrics and component health would be displayed here.',
                style: MayaTheme.bodyMedium,
              ),
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
        Text('Error loading stats',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
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
