import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import '../../../shared/widgets/maya_loading.dart';
import '../../../shared/widgets/maya_error_view.dart';

class RouterScreen extends ConsumerStatefulWidget {
  const RouterScreen({super.key});

  @override
  ConsumerState<RouterScreen> createState() => _RouterScreenState();
}

class _RouterScreenState extends ConsumerState<RouterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStrategy = 'balanced';

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
          title:
              const Text('Multi-Model Router', style: MayaTheme.headlineSmall),
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
                ref.invalidate(llmProvidersProvider);
                ref.invalidate(llmStatsProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.cloud_rounded), text: 'Providers'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Strategy'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProvidersTab(),
            _buildStatsTab(),
            _buildStrategyTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersTab() {
    final providersAsync = ref.watch(llmProvidersProvider);

    return providersAsync.when(
      data: (response) {
        if (response.providers.isEmpty) {
          return const Center(
            child: Text('No providers configured', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.providers.length,
          itemBuilder: (context, index) {
            final provider = response.providers[index];
            return _ProviderTile(
              provider: provider,
              onToggle: (enabled) async {
                final success = await ref.read(mayaApiProvider).postJson(
                  '/api/v1/llm/providers/${provider.id}/toggle',
                  data: {'enabled': enabled},
                );
                if (success.isNotEmpty && mounted) {
                  ref.invalidate(llmProvidersProvider);
                }
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading providers',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final statsAsync = ref.watch(llmStatsProvider);

    return statsAsync.when(
      data: (stats) {
        if (stats.stats.isEmpty) {
          return const Center(
            child: Text('No stats available yet', style: MayaTheme.bodyMedium),
          );
        }

        final entries = stats.stats.entries.toList()
          ..sort((a, b) => (b.value.ok as int).compareTo(a.value.ok as int));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live Provider Stats', style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final providerId = entry.key;
                  final stat = entry.value;
                  final tableInfo = stats.table[providerId] ?? {};
                  final cost = (tableInfo['cost'] as num?)?.toDouble() ?? 0.0;
                  final quality =
                      (tableInfo['quality'] as num?)?.toDouble() ?? 0.0;

                  return _StatTile(
                    providerId: providerId,
                    latency: (stat.latencyEmaS as num?)?.toDouble() ?? 0.0,
                    ok: stat.ok as int? ?? 0,
                    errors: stat.errors as int? ?? 0,
                    errorRate: (stat.errorRate as num?)?.toDouble() ?? 0.0,
                    cost: cost,
                    quality: quality,
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Provider Cost/Quality Reference',
                  style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              _buildReferenceTable(stats.table),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading stats',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceTable(Map<String, Map<String, dynamic>> table) {
    final entries = table.entries.toList()
      ..sort((a, b) => ((a.value['cost'] as num?)?.toDouble() ?? 0.0)
          .compareTo((b.value['cost'] as num?)?.toDouble() ?? 0.0));

    return Container(
      decoration: MayaTheme.glassCard(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: MayaTheme.slate800,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Provider', style: MayaTheme.labelMedium)),
                Expanded(
                    flex: 1,
                    child: Text('Cost (\$/1M)',
                        style: MayaTheme.labelMedium,
                        textAlign: TextAlign.center)),
                Expanded(
                    flex: 1,
                    child: Text('Quality (0-1)',
                        style: MayaTheme.labelMedium,
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...entries.map((entry) {
            final cost = (entry.value['cost'] as num?)?.toDouble() ?? 0.0;
            final quality = (entry.value['quality'] as num?)?.toDouble() ?? 0.0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: MayaTheme.glassWhite10)),
              ),
              child: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text(entry.key, style: MayaTheme.bodyMedium)),
                  Expanded(
                      flex: 1,
                      child: Text('\$${cost.toStringAsFixed(2)}',
                          style: MayaTheme.bodyMedium,
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 1,
                      child: Text(quality.toStringAsFixed(2),
                          style: MayaTheme.bodyMedium,
                          textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStrategyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Routing Strategy', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Choose how Maya selects the best model for each task. The strategy determines the priority order of providers.',
                  style: MayaTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStrategy,
                  dropdownColor: MayaTheme.slate800,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Strategy',
                    labelStyle:
                        MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'balanced',
                        child: Text(
                            'Balanced (quality per \$, tempered by latency)')),
                    DropdownMenuItem(
                        value: 'cost', child: Text('Cost (cheapest first)')),
                    DropdownMenuItem(
                        value: 'latency',
                        child: Text('Latency (fastest first)')),
                    DropdownMenuItem(
                        value: 'quality',
                        child: Text('Quality (best quality first)')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStrategy = value ?? 'balanced');
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(llmStrategyProvider(_selectedStrategy)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Preview Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, _) {
              final strategyAsync =
                  ref.watch(llmStrategyProvider(_selectedStrategy));

              return strategyAsync.when(
                data: (result) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  MayaTheme.neonViolet.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_tree_rounded,
                                color: MayaTheme.neonViolet, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Strategy: ${result.strategy}',
                                    style: MayaTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text('Provider order (1st → last)',
                                    style: MayaTheme.bodySmall
                                        .copyWith(color: Colors.white54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...result.order.asMap().entries.map((entry) {
                        final index = entry.key;
                        final provider = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MayaTheme.slate700,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: MayaTheme.glassWhite10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      MayaTheme.neonCyan.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${index + 1}',
                                      style: MayaTheme.labelMedium.copyWith(
                                          color: MayaTheme.neonCyan,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child:
                                    Text(provider, style: MayaTheme.bodyMedium),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_rounded,
                          size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Error loading strategy',
                          style: MayaTheme.bodyMedium
                              .copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(),
                          style: MayaTheme.bodySmall
                              .copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final LLMProviderInfo provider;
  final ValueChanged<bool> onToggle;

  const _ProviderTile({
    required this.provider,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider.enabled
                  ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                  : MayaTheme.neonOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              provider.enabled
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color: provider.enabled
                  ? MayaTheme.neonEmerald
                  : MayaTheme.neonOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name, style: MayaTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${provider.model} • \$${provider.costPer1M.toStringAsFixed(2)}/1M tokens',
                  style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
          Switch(
            value: provider.enabled,
            onChanged: onToggle,
            activeColor: MayaTheme.neonCyan,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String providerId;
  final double latency;
  final int ok;
  final int errors;
  final double errorRate;
  final double cost;
  final double quality;

  const _StatTile({
    required this.providerId,
    required this.latency,
    required this.ok,
    required this.errors,
    required this.errorRate,
    required this.cost,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(providerId, style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(
                  label: 'Latency',
                  value: '${latency.toStringAsFixed(2)}s',
                  color: MayaTheme.neonCyan),
              const SizedBox(width: 16),
              _StatItem(
                  label: 'OK',
                  value: ok.toString(),
                  color: MayaTheme.neonEmerald),
              const SizedBox(width: 16),
              _StatItem(
                  label: 'Errors',
                  value: errors.toString(),
                  color: MayaTheme.error),
              const SizedBox(width: 16),
              _StatItem(
                  label: 'Error Rate',
                  value: '${(errorRate * 100).toStringAsFixed(1)}%',
                  color: MayaTheme.neonOrange),
              const SizedBox(width: 16),
              _StatItem(
                  label: 'Cost/1M',
                  value: '\$${cost.toStringAsFixed(2)}',
                  color: MayaTheme.neonViolet),
              const SizedBox(width: 16),
              _StatItem(
                  label: 'Quality',
                  value: quality.toStringAsFixed(2),
                  color: MayaTheme.neonPink),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value,
            style: MayaTheme.bodyMedium
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class LLMProviderInfo {
  final String id;
  final String name;
  final String model;
  final bool enabled;
  final double costPer1M;

  LLMProviderInfo({
    required this.id,
    required this.name,
    required this.model,
    required this.enabled,
    required this.costPer1M,
  });

  factory LLMProviderInfo.fromJson(Map<String, dynamic> json) {
    return LLMProviderInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      costPer1M: (json['cost_per_1m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LLMProvidersResponse {
  final List<LLMProviderInfo> providers;

  LLMProvidersResponse({required this.providers});

  factory LLMProvidersResponse.fromJson(Map<String, dynamic> json) {
    final list = json['providers'] as List<dynamic>? ?? [];
    return LLMProvidersResponse(
      providers: list
          .map((e) => LLMProviderInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LLMStatsResponse {
  final Map<String, LLMStat> stats;
  final Map<String, Map<String, dynamic>> table;

  LLMStatsResponse({required this.stats, required this.table});

  factory LLMStatsResponse.fromJson(Map<String, dynamic> json) {
    final statsMap = (json['stats'] as Map<String, dynamic>?) ?? {};
    final tableMap = (json['table'] as Map<String, dynamic>?) ?? {};
    return LLMStatsResponse(
      stats: statsMap.map(
          (k, v) => MapEntry(k, LLMStat.fromJson(v as Map<String, dynamic>))),
      table: tableMap
          .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map))),
    );
  }
}

class LLMStat {
  final double latencyEmaS;
  final int ok;
  final int errors;
  final double errorRate;

  LLMStat({
    required this.latencyEmaS,
    required this.ok,
    required this.errors,
    required this.errorRate,
  });

  factory LLMStat.fromJson(Map<String, dynamic> json) {
    return LLMStat(
      latencyEmaS: (json['latency_ema_s'] as num?)?.toDouble() ?? 0.0,
      ok: json['ok'] as int? ?? 0,
      errors: json['errors'] as int? ?? 0,
      errorRate: (json['error_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LLMStrategyResult {
  final String strategy;
  final List<String> order;

  LLMStrategyResult({required this.strategy, required this.order});

  factory LLMStrategyResult.fromJson(Map<String, dynamic> json) {
    return LLMStrategyResult(
      strategy: json['strategy'] as String? ?? 'balanced',
      order:
          (json['order'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }
}

final llmProvidersProvider = FutureProvider<LLMProvidersResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/llm/providers');
  return LLMProvidersResponse.fromJson(response);
});

final llmStatsProvider = FutureProvider<LLMStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/llm/stats');
  return LLMStatsResponse.fromJson(response);
});

final llmStrategyProvider =
    FutureProvider.family<LLMStrategyResult, String>((ref, strategy) async {
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.postJson('/api/v1/llm/strategy', data: {'strategy': strategy});
  return LLMStrategyResult.fromJson(response);
});
