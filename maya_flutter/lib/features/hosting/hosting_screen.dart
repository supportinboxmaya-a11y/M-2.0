import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

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
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {},
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
    return const MayaEmptyState(
      'No hosted apps yet',
      icon: Icons.apps_rounded,
    );
  }
}

class _DeployTab extends ConsumerWidget {
  const _DeployTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.rocket_launch_rounded,
    );
  }
}

class _MyAppsTab extends ConsumerWidget {
  const _MyAppsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.person_rounded,
    );
  }
}
