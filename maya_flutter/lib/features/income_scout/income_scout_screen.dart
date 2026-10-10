import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class IncomeScoutScreen extends ConsumerStatefulWidget {
  const IncomeScoutScreen({super.key});

  @override
  ConsumerState<IncomeScoutScreen> createState() => _IncomeScoutScreenState();
}

class _IncomeScoutScreenState extends ConsumerState<IncomeScoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          title: const Text('Income Scout', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.radar_rounded), text: 'Scan'),
              Tab(
                  icon: Icon(Icons.signal_cellular_alt_rounded),
                  text: 'Signals'),
              Tab(icon: Icon(Icons.flag_rounded), text: 'Opportunities'),
              Tab(icon: Icon(Icons.settings_rounded), text: 'Config'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ScanTab(),
            _SignalsTab(),
            _OpportunitiesTab(),
            _ConfigTab(),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends ConsumerWidget {
  const _ScanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Run Scout Scan', style: MayaTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Scans Reddit, Hacker News, and other sources for new income opportunities.',
                  style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                const MayaEmptyState(
                  'Endpoint not connected',
                  icon: Icons.radar_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Scan History
          const Text('Scan History', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          const MayaEmptyState(
            'No Scans Yet',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 24),
          // Stats
          const Text('Statistics', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          const MayaEmptyState(
            'Endpoint not connected',
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }
}

class _SignalsTab extends ConsumerWidget {
  const _SignalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'No Signals',
      icon: Icons.signal_cellular_alt_rounded,
    );
  }
}

class _OpportunitiesTab extends ConsumerWidget {
  const _OpportunitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.flag_rounded,
    );
  }
}

class _ConfigTab extends ConsumerWidget {
  const _ConfigTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.settings_rounded,
    );
  }
}
