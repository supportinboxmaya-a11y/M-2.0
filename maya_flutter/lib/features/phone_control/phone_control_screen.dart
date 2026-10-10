import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class PhoneControlScreen extends ConsumerStatefulWidget {
  const PhoneControlScreen({super.key});

  @override
  ConsumerState<PhoneControlScreen> createState() => _PhoneControlScreenState();
}

class _PhoneControlScreenState extends ConsumerState<PhoneControlScreen>
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
          title: const Text('Phone / Device Control',
              style: MayaTheme.headlineSmall),
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
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.devices_rounded), text: 'Devices'),
              Tab(icon: Icon(Icons.link_rounded), text: 'Pair Device'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Command History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _DevicesTab(),
            _PairTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _DevicesTab extends ConsumerWidget {
  const _DevicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No paired devices',
      icon: Icons.devices_rounded,
    );
  }
}

class _PairTab extends ConsumerWidget {
  const _PairTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.link_rounded,
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.history_rounded,
    );
  }
}
