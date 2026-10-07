import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import 'capabilities_models.dart';
import 'capabilities_providers.dart';

class CapabilitiesScreen extends ConsumerStatefulWidget {
  const CapabilitiesScreen({super.key});

  @override
  ConsumerState<CapabilitiesScreen> createState() => _CapabilitiesScreenState();
}

class _CapabilitiesScreenState extends ConsumerState<CapabilitiesScreen>
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
          title: const Text('Capabilities', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ref.invalidate(capabilitiesProvider);
                  ref.invalidate(capabilitiesStatsProvider);
                })
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'All'),
              Tab(icon: Icon(Icons.search_rounded), text: 'Search'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _CapabilitiesListTab(),
            _CapabilitiesSearchTab(),
            _CapabilitiesStatsTab(),
          ],
        ),
      ),
    );
  }
}

class _CapabilitiesListTab extends ConsumerWidget {
  const _CapabilitiesListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilitiesAsync = ref.watch(capabilitiesProvider);

    return capabilitiesAsync.when(
      data: (data) => data.capabilities.isEmpty
          ? _emptyState('No Capabilities', 'No capabilities registered yet',
              Icons.list_alt_rounded)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('All Capabilities', style: MayaTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Registered capabilities in the registry',
                      style:
                          MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
                  const SizedBox(height: 16),
                  ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.capabilities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final cap = data.capabilities[index];
                        return _CapabilityCard(capability: cap);
                      }),
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
        Text('Error loading capabilities',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38))
      ])),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  final Capability capability;

  const _CapabilityCard({required this.capability});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: MayaTheme.glassCard(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: capability.verified
                        ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                        : MayaTheme.neonOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(
                    capability.verified
                        ? Icons.verified_rounded
                        : Icons.psychology_rounded,
                    color: capability.verified
                        ? MayaTheme.neonEmerald
                        : MayaTheme.neonOrange,
                    size: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(capability.name, style: MayaTheme.titleMedium),
                  Text(capability.description,
                      style:
                          MayaTheme.bodySmall.copyWith(color: Colors.white54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ])),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: capability.verified
                        ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                        : MayaTheme.neonOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: capability.verified
                            ? MayaTheme.neonEmerald
                            : MayaTheme.neonOrange)),
                child: Text(capability.verified ? 'VERIFIED' : 'UNVERIFIED',
                    style: MayaTheme.labelSmall.copyWith(
                        color: capability.verified
                            ? MayaTheme.neonEmerald
                            : MayaTheme.neonOrange))),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _CapInfoChip(
                label: 'Usage',
                value: capability.usageCount.toString(),
                color: MayaTheme.neonCyan),
            _CapInfoChip(
                label: 'Success Rate',
                value: '${(capability.successRate * 100).toStringAsFixed(1)}%',
                color: capability.successRate >= 0.8
                    ? MayaTheme.neonEmerald
                    : (capability.successRate >= 0.5
                        ? MayaTheme.neonOrange
                        : MayaTheme.error)),
          ]),
        ]));
  }
}

class _CapInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CapInfoChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color)),
        child: Text('$label: $value',
            style: MayaTheme.labelSmall.copyWith(color: color)));
  }
}

class _CapabilitiesSearchTab extends ConsumerStatefulWidget {
  const _CapabilitiesSearchTab();

  @override
  ConsumerState<_CapabilitiesSearchTab> createState() =>
      _CapabilitiesSearchTabState();
}

class _CapabilitiesSearchTabState
    extends ConsumerState<_CapabilitiesSearchTab> {
  final _queryController = TextEditingController();
  CapabilitiesSearchResponse? _lastResult;
  bool _isSearching = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_queryController.text.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.getJson(
          '/api/v1/capabilities/search?q=${Uri.encodeComponent(_queryController.text.trim())}');
      setState(() {
        _lastResult = CapabilitiesSearchResponse.fromJson(result);
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: MayaTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search Capabilities', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Search capabilities by name or description',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _queryController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Search Query *',
                    hintText: 'e.g., file operations, web search',
                    labelStyle: const TextStyle(color: Colors.white54),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child:
                            Icon(Icons.search_rounded, color: Colors.white54)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: MayaTheme.neonCyan)),
                    filled: true,
                    fillColor: MayaTheme.slate800,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _search,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.search_rounded),
                    label: Text(_isSearching ? 'Searching...' : 'Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_lastResult != null) ...[
            const Text('Results', style: MayaTheme.titleLarge),
            const SizedBox(height: 12),
            _lastResult!.capabilities.isEmpty
                ? _emptyState('No Results', 'No capabilities match your query',
                    Icons.search_rounded)
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lastResult!.capabilities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final cap = _lastResult!.capabilities[index];
                      return _CapabilityCard(capability: cap);
                    },
                  ),
          ],
        ],
      ),
    );
  }
}

class _CapabilitiesStatsTab extends ConsumerWidget {
  const _CapabilitiesStatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(capabilitiesStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Capabilities Statistics', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Overview of the capability registry',
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: _CapStatCard(
                      label: 'Total',
                      value: stats.totalCapabilities.toString(),
                      color: MayaTheme.neonCyan,
                      icon: Icons.list_alt_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: _CapStatCard(
                      label: 'Verified',
                      value: stats.verifiedCapabilities.toString(),
                      color: MayaTheme.neonEmerald,
                      icon: Icons.verified_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: _CapStatCard(
                      label: 'Total Usages',
                      value: stats.totalUsages.toString(),
                      color: MayaTheme.neonViolet,
                      icon: Icons.play_arrow_rounded)),
            ]),
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
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38))
      ])),
    );
  }
}

class _CapStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _CapStatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: MayaTheme.glassCardGlow(glowColor: color),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: MayaTheme.headlineMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: MayaTheme.labelSmall.copyWith(color: Colors.white54))
        ]));
  }
}

Widget _emptyState(String title, String subtitle, IconData icon) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MayaTheme.neonCyan.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MayaTheme.neonCyan, size: 48),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: MayaTheme.bodyLarge.copyWith(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
