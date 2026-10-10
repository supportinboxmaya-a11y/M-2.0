import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class IncomeLauncherScreen extends ConsumerStatefulWidget {
  const IncomeLauncherScreen({super.key});

  @override
  ConsumerState<IncomeLauncherScreen> createState() =>
      _IncomeLauncherScreenState();
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
              onPressed: () {},
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
    return const MayaEmptyState(
      'No Launches yet',
      icon: Icons.rocket_launch_rounded,
    );
  }
}

class _ContentTab extends ConsumerWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.content_paste_rounded,
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.bar_chart_rounded,
    );
  }
}
