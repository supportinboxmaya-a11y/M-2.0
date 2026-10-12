import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final launcherLaunchesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.launcherListLaunches(limit: 50);
});

final launcherStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.launcherGetStats();
});

class IncomeLauncherScreen extends ConsumerStatefulWidget {
  const IncomeLauncherScreen({super.key});

  @override
  ConsumerState<IncomeLauncherScreen> createState() => _IncomeLauncherScreenState();
}

class _IncomeLauncherScreenState extends ConsumerState<IncomeLauncherScreen>
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
          title: const Text('Income Launcher', style: MayaTheme.headlineSmall),
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
                ref.invalidate(launcherLaunchesProvider);
                ref.invalidate(launcherStatsProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.rocket_launch_rounded), text: 'Launches'),
              Tab(icon: Icon(Icons.content_paste_rounded), text: 'Content'),
              Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _LaunchesTab(),
            _ContentTab(),
            _StatsTab(),
          ],
        ),
      ),
    );
  }
}

class _LaunchesTab extends ConsumerWidget {
  const _LaunchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchesAsync = ref.watch(launcherLaunchesProvider);

    return launchesAsync.when(
      data: (data) {
        final launches = data['launches'] as List? ?? [];
        if (launches.isEmpty) {
          return const MayaEmptyState(
            'No Launches yet',
            icon: Icons.rocket_launch_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: launches.length,
          itemBuilder: (context, index) {
            final launch = launches[index];
            return _LaunchCard(launch: launch);
          },
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
            Text('Error loading launches', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _LaunchCard extends ConsumerWidget {
  final Map<String, dynamic> launch;

  const _LaunchCard({required this.launch});

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'launched':
        return MayaTheme.neonEmerald;
      case 'ready':
        return MayaTheme.neonCyan;
      case 'draft':
        return MayaTheme.neonOrange;
      case 'failed':
        return MayaTheme.error;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  color: _getStatusColor(launch['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.rocket_launch_rounded, color: _getStatusColor(launch['status']), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(launch['title'] ?? '', style: MayaTheme.titleMedium),
                    Text('Project: ${launch['projectId'] ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(launch['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(launch['status'])),
                ),
                child: Text(
                  launch['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                  style: MayaTheme.labelSmall.copyWith(color: _getStatusColor(launch['status'])),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Created: ${launch['createdAt']?.toString().substring(0, 10) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              const Spacer(),
              if (launch['launchedAt'] != null)
                Text('Launched: ${launch['launchedAt']?.toString().substring(0, 10) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentTab extends ConsumerWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No Content yet',
      icon: Icons.content_paste_rounded,
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(launcherStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Launcher Stats', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Overview of launch performance and content',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _LauncherStatCard(
                    label: 'Total Launches',
                    value: stats['total_launches']?.toString() ?? '0',
                    color: MayaTheme.neonCyan,
                    icon: Icons.rocket_launch_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LauncherStatCard(
                    label: 'Total Content',
                    value: stats['total_content_pieces']?.toString() ?? '0',
                    color: MayaTheme.neonViolet,
                    icon: Icons.content_paste_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LauncherStatCard(
                    label: 'Content Approved',
                    value: stats['content_approved']?.toString() ?? '0',
                    color: MayaTheme.neonEmerald,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading stats', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _LauncherStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _LauncherStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  }) : super();

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
          Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}