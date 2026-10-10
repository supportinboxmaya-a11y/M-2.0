import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class IncomeBuilderScreen extends ConsumerStatefulWidget {
  const IncomeBuilderScreen({super.key});

  @override
  ConsumerState<IncomeBuilderScreen> createState() =>
      _IncomeBuilderScreenState();
}

class _IncomeBuilderScreenState extends ConsumerState<IncomeBuilderScreen>
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
          title: const Text('Income Builder', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.folder_rounded), text: 'Projects'),
              Tab(
                  icon: Icon(Icons.auto_awesome_rounded),
                  text: 'Build from Plan'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ProjectsTab(),
            _BuildFromPlanTab(),
          ],
        ),
      ),
    );
  }
}

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No Projects yet',
      icon: Icons.folder_rounded,
    );
  }
}

class _BuildFromPlanTab extends ConsumerWidget {
  const _BuildFromPlanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.auto_awesome_rounded,
    );
  }
}
