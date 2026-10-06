import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'semantic_index_models.dart';
import 'semantic_index_providers.dart';

class SemanticIndexScreen extends ConsumerStatefulWidget {
  const SemanticIndexScreen({super.key});

  @override
  ConsumerState<SemanticIndexScreen> createState() =>
      _SemanticIndexScreenState();
}

class _SemanticIndexScreenState extends ConsumerState<SemanticIndexScreen>
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
          title: const Text('Semantic Index', style: MayaTheme.headlineSmall),
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
                ref.invalidate(vectorSearchStatsProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.data_array_rounded), text: 'Vector Store'),
              Tab(icon: Icon(Icons.search_rounded), text: 'Search'),
              Tab(icon: Icon(Icons.settings_rounded), text: 'Config'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _VectorStoreTab(),
            _VectorSearchTab(),
            _VectorConfigTab(),
          ],
        ),
      ),
    );
  }
}

class _VectorStoreTab extends ConsumerWidget {
  const _VectorStoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vectorSearchStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vector Store', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Maya\'s vector store for semantic retrieval. Uses TF-IDF cosine similarity with optional ONNX MiniLM embeddings.',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            // Stats
            Row(
              children: [
                Expanded(
                  child: _VectorStatCard(
                    label: 'Total Vectors',
                    value: stats.totalVectors.toString(),
                    color: MayaTheme.neonCyan,
                    icon: Icons.data_array_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VectorStatCard(
                    label: 'Dimensions',
                    value: stats.dimensions.toString(),
                    color: MayaTheme.neonViolet,
                    icon: Icons.square_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VectorStatCard(
                    label: 'Retrieval Engine',
                    value: stats.retrievalEngine,
                    color: MayaTheme.neonOrange,
                    icon: Icons.memory_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Engine Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Engine Details', style: MayaTheme.titleMedium),
                  const SizedBox(height: 12),
                  _VectorDetailRow(
                      label: 'Engine', value: stats.retrievalEngine),
                  _VectorDetailRow(
                      label: 'Total Vectors',
                      value: stats.totalVectors.toString()),
                  _VectorDetailRow(
                      label: 'Dimensions', value: stats.dimensions.toString()),
                  _VectorDetailRow(
                    label: 'TF-IDF Fallback',
                    value: stats.retrievalEngine.toLowerCase().contains('tfidf')
                        ? 'Active'
                        : 'N/A',
                  ),
                  _VectorDetailRow(
                    label: 'ONNX Embeddings',
                    value: stats.retrievalEngine.toLowerCase().contains('onnx')
                        ? 'Active'
                        : 'Disabled (set SEMANTIC_EMBEDDINGS=true)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Integration Status
            const Text('Integration Status', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            const _IntegrationCard(
                title: 'Procedural Memory',
                subtitle: 'Skills search via semantic index',
                status: 'Active',
                color: MayaTheme.neonEmerald),
            const _IntegrationCard(
                title: 'Knowledge Engine',
                subtitle: 'Belief grounding & query via semantic index',
                status: 'Active',
                color: MayaTheme.neonCyan),
            const _IntegrationCard(
                title: 'Kernel Goal Grounding',
                subtitle: 'Belief retrieval for planning',
                status: 'Active',
                color: MayaTheme.neonViolet),
            const _IntegrationCard(
                title: 'Learn/Dedup',
                subtitle: 'Cosine similarity + token-overlap confirmation',
                status: 'Active',
                color: MayaTheme.neonOrange),
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
        Text('Error loading vector store stats',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _VectorSearchTab extends ConsumerStatefulWidget {
  const _VectorSearchTab();

  @override
  ConsumerState<_VectorSearchTab> createState() => _VectorSearchTabState();
}

class _VectorSearchTabState extends ConsumerState<_VectorSearchTab> {
  final _queryController = TextEditingController();
  int _limit = 10;
  bool _hybrid = true;
  VectorSearchResponse? _lastResult;
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
      final response = await api.postJson('/vector/search', data: {
        'query': _queryController.text.trim(),
        'limit': _limit,
        'hybrid': _hybrid,
      });
      setState(() {
        _lastResult = VectorSearchResponse.fromJson(response);
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Search failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vector Search', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Search Maya\'s vector store using semantic similarity. Hybrid mode combines vector + keyword search.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          // Search Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _queryController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Query *',
                    hintText: 'e.g., How to deploy a Flutter app?',
                    labelStyle: const TextStyle(color: Colors.white54),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.search_rounded, color: Colors.white54),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: MayaTheme.neonCyan),
                    ),
                    filled: true,
                    fillColor: MayaTheme.slate800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Limit: $_limit',
                        style: MayaTheme.bodyMedium
                            .copyWith(color: MayaTheme.neonCyan)),
                    Expanded(
                        child: Slider(
                      value: _limit.toDouble(),
                      min: 1,
                      max: 25,
                      divisions: 24,
                      activeColor: MayaTheme.neonCyan,
                      inactiveColor: Colors.white24,
                      onChanged: (v) => setState(() => _limit = v.toInt()),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title:
                      const Text('Hybrid Search', style: MayaTheme.bodyMedium),
                  subtitle: Text('Combine vector + keyword search',
                      style:
                          MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  value: _hybrid,
                  onChanged: (v) => setState(() => _hybrid = v),
                  activeThumbColor: MayaTheme.neonCyan,
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
                                    AlwaysStoppedAnimation(Colors.white)),
                          )
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
          // Results
          if (_lastResult != null) ...[
            const Text('Results', style: MayaTheme.titleLarge),
            const SizedBox(height: 12),
            _lastResult!.results.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(
                        child: Text('No results found',
                            style: MayaTheme.bodyMedium)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lastResult!.results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final result = _lastResult!.results[index];
                      return _VectorSearchResultCard(
                          result: result, rank: index + 1);
                    },
                  ),
          ],
        ],
      ),
    );
  }
}

class _VectorSearchResultCard extends StatelessWidget {
  final VectorSearchResult result;
  final int rank;

  const _VectorSearchResultCard({required this.result, required this.rank});

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('#$rank',
                    style: MayaTheme.labelMedium.copyWith(
                        color: MayaTheme.neonCyan,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: ${(result.score * 100).toStringAsFixed(1)}%',
                        style: MayaTheme.titleSmall
                            .copyWith(color: MayaTheme.neonCyan)),
                    Text(result.content,
                        style: MayaTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if (result.metadata != null && result.metadata!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Metadata:', style: MayaTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.metadata!.entries
                  .map((e) => Chip(
                        label: Text('${e.key}: ${e.value}',
                            style: MayaTheme.bodySmall),
                        backgroundColor: MayaTheme.slate800,
                        side: const BorderSide(color: Colors.white12),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _VectorConfigTab extends ConsumerWidget {
  const _VectorConfigTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuration', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Configure semantic index settings. Some changes require server restart.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          // Retrieval Engine
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Retrieval Engine', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Current engine is determined by SEMANTIC_EMBEDDINGS env variable.',
                  style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                const _ConfigRow(
                  label: 'TF-IDF Cosine',
                  value: 'Always available (fallback)',
                  status: 'Active',
                  statusColor: MayaTheme.neonEmerald,
                ),
                const _ConfigRow(
                  label: 'ONNX MiniLM Embeddings',
                  value: 'Requires SEMANTIC_EMBEDDINGS=true',
                  status: 'Disabled',
                  statusColor: MayaTheme.neonOrange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Deduplication Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Belief Deduplication',
                    style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'When learning new knowledge, Maya checks for similar existing beliefs.',
                  style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                const _ConfigRow(
                  label: 'Vector Similarity Threshold',
                  value: '>= 0.85 (with real embeddings)',
                  status: 'Conservative',
                  statusColor: MayaTheme.neonCyan,
                ),
                const _ConfigRow(
                  label: 'Token Overlap Confirmation',
                  value: '>= 0.8 (fallback mode)',
                  status: 'Required',
                  statusColor: MayaTheme.neonViolet,
                ),
                const _ConfigRow(
                  label: 'Conflict Resolution',
                  value: 'Belief revision (odds-form Bayesian)',
                  status: 'Active',
                  statusColor: MayaTheme.neonEmerald,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Actions
          const Text('Actions', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Rebuild index not implemented yet'),
                          backgroundColor: MayaTheme.neonOrange),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Rebuild Index'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Clear index not implemented yet'),
                          backgroundColor: MayaTheme.neonOrange),
                    );
                  },
                  icon: const Icon(Icons.delete_rounded),
                  label: const Text('Clear Index'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VectorStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _VectorStatCard({
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

class _VectorDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _VectorDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          ),
          Expanded(
              child: Text(value,
                  style:
                      MayaTheme.bodyMedium.copyWith(fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const _IntegrationCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MayaTheme.bodyMedium),
                Text(subtitle,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Text(status,
                style: MayaTheme.labelSmall.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color statusColor;

  const _ConfigRow({
    required this.label,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: MayaTheme.bodyMedium),
                Text(value,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor),
            ),
            child: Text(status,
                style: MayaTheme.labelSmall.copyWith(color: statusColor)),
          ),
        ],
      ),
    );
  }
}
