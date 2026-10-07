import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import 'maya_cognitive_core_models.dart';
import 'maya_cognitive_core_providers.dart';

class MayaCognitiveCoreScreen extends ConsumerStatefulWidget {
  const MayaCognitiveCoreScreen({super.key});

  @override
  ConsumerState<MayaCognitiveCoreScreen> createState() =>
      _MayaCognitiveCoreScreenState();
}

class _MayaCognitiveCoreScreenState
    extends ConsumerState<MayaCognitiveCoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(coreStatusProvider);
        ref.invalidate(episodicListProvider);
        ref.invalidate(episodicStatsProvider);
        ref.invalidate(knowledgeStatsProvider);
        ref.invalidate(workingMemoryCapacityProvider);
        ref.invalidate(coreIdentityProvider);
        ref.invalidate(coreModelsProvider);
        ref.invalidate(coreCheckpointsProvider);
        ref.invalidate(coreAuditProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title:
              const Text('Maya Cognitive Core', style: MayaTheme.headlineSmall),
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
                ref.invalidate(coreStatusProvider);
                ref.invalidate(episodicListProvider);
                ref.invalidate(episodicStatsProvider);
                ref.invalidate(knowledgeStatsProvider);
                ref.invalidate(workingMemoryCapacityProvider);
                ref.invalidate(coreIdentityProvider);
                ref.invalidate(coreModelsProvider);
                ref.invalidate(coreCheckpointsProvider);
                ref.invalidate(coreAuditProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.psychology_rounded), text: 'Hippocampus'),
              Tab(icon: Icon(Icons.lightbulb_rounded), text: 'Semantic Memory'),
              Tab(icon: Icon(Icons.memory_rounded), text: 'Working Memory'),
              Tab(icon: Icon(Icons.web_rounded), text: 'Browser'),
              Tab(icon: Icon(Icons.code_rounded), text: 'Sandbox'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _HippocampusTab(),
            _SemanticMemoryTab(),
            _WorkingMemoryTab(),
            _BrowserTab(),
            _SandboxTab(),
          ],
        ),
      ),
    );
  }
}

class _HippocampusTab extends ConsumerWidget {
  const _HippocampusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(episodicListProvider);
    final statsAsync = ref.watch(episodicStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hippocampus (Episodic Memory)',
              style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Recent experiences and episodic memories',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                    child: _CoreStatCard(
                        label: 'Total Episodes',
                        value: stats.totalEpisodes.toString(),
                        color: MayaTheme.neonCyan,
                        icon: Icons.psychology_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Successful',
                        value: stats.successfulEpisodes.toString(),
                        color: MayaTheme.neonEmerald,
                        icon: Icons.check_circle_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Failed',
                        value: stats.failedEpisodes.toString(),
                        color: MayaTheme.error,
                        icon: Icons.cancel_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Avg Confidence',
                        value: stats.avgConfidence.toStringAsFixed(2),
                        color: MayaTheme.neonViolet,
                        icon: Icons.trending_up_rounded)),
              ],
            ),
            loading: () => const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          const Text('Recent Episodes', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          listAsync.when(
            data: (data) => data.episodes.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(
                        child: Text('No episodic memories yet',
                            style: MayaTheme.bodyMedium)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.episodes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final episode = data.episodes[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(episode.goal,
                                              style: MayaTheme.titleMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: episode.outcome ==
                                                      'success'
                                                  ? MayaTheme.neonEmerald
                                                      .withValues(alpha: 0.2)
                                                  : MayaTheme.error
                                                      .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color:
                                                    episode.outcome == 'success'
                                                        ? MayaTheme.neonEmerald
                                                        : MayaTheme.error,
                                              ),
                                            ),
                                            child: Text(
                                              episode.outcome.toUpperCase(),
                                              style:
                                                  MayaTheme.labelSmall.copyWith(
                                                color:
                                                    episode.outcome == 'success'
                                                        ? MayaTheme.neonEmerald
                                                        : MayaTheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          'Confidence: ${(episode.confidence * 100).toStringAsFixed(1)}%',
                                          style: MayaTheme.bodySmall
                                              .copyWith(color: Colors.white70)),
                                      Text(
                                          'Time: ${episode.timestamp.toString().substring(0, 19)}',
                                          style: MayaTheme.bodySmall
                                              .copyWith(color: Colors.white54)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (episode.metadata != null &&
                                episode.metadata!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Metadata: ${episode.metadata.toString()}',
                                  style: MayaTheme.bodySmall
                                      .copyWith(color: Colors.white38)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
            loading: () => const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SemanticMemoryTab extends ConsumerWidget {
  const _SemanticMemoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(knowledgeStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Semantic Memory (Knowledge)',
              style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Concepts, facts, and belief network',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                    child: _CoreStatCard(
                        label: 'Total Beliefs',
                        value: stats.totalBeliefs.toString(),
                        color: MayaTheme.neonCyan,
                        icon: Icons.lightbulb_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Domains',
                        value: stats.domains.toString(),
                        color: MayaTheme.neonViolet,
                        icon: Icons.category_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Avg Confidence',
                        value: stats.avgConfidence.toStringAsFixed(2),
                        color: MayaTheme.neonEmerald,
                        icon: Icons.trending_up_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _CoreStatCard(
                        label: 'Retrieval Engine',
                        value: stats.retrievalEngine.toString(),
                        color: MayaTheme.neonOrange,
                        icon: Icons.data_array_rounded)),
              ],
            ),
            loading: () => const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          const Text('Query Knowledge', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _KnowledgeQueryForm(),
          const SizedBox(height: 24),
          const Text('Teach Maya (Add Knowledge)',
              style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _LearnKnowledgeForm(),
        ],
      ),
    );
  }
}

class _KnowledgeQueryForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_KnowledgeQueryForm> createState() =>
      _KnowledgeQueryFormState();
}

class _KnowledgeQueryFormState extends ConsumerState<_KnowledgeQueryForm> {
  final _queryController = TextEditingController();
  final _domainController = TextEditingController();
  final _limitController = TextEditingController(text: '5');
  KnowledgeQueryResponse? _result;

  @override
  void dispose() {
    _queryController.dispose();
    _domainController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.getJson(
        '/api/v1/cognitive/knowledge/query',
        queryParameters: {
          'query': _queryController.text,
          'domain':
              _domainController.text.isEmpty ? null : _domainController.text,
          'limit': int.tryParse(_limitController.text) ?? 5,
        },
      );
      setState(() => _result = KnowledgeQueryResponse.fromJson(result));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Query failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _queryController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Query',
              hintText: 'Enter search query...',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _domainController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Domain (optional)',
                    hintText: 'general, coding, science...',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _limitController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Limit',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _query,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Query'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            const Divider(color: MayaTheme.glassWhite10),
            const SizedBox(height: 8),
            const Text('Results', style: MayaTheme.titleSmall),
            const SizedBox(height: 8),
            ..._result!.results.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(item.proposition,
                                  style: MayaTheme.bodyMedium)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                '${(item.confidence * 100).toStringAsFixed(0)}%',
                                style: MayaTheme.labelSmall
                                    .copyWith(color: MayaTheme.neonCyan)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Domain: ${item.domain} • Source: ${item.source}',
                          style: MayaTheme.bodySmall
                              .copyWith(color: Colors.white54)),
                      Text(
                          'Created: ${item.createdAt.toString().substring(0, 19)}',
                          style: MayaTheme.bodySmall
                              .copyWith(color: Colors.white38)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _LearnKnowledgeForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LearnKnowledgeForm> createState() =>
      _LearnKnowledgeFormState();
}

class _LearnKnowledgeFormState extends ConsumerState<_LearnKnowledgeForm> {
  final _propositionController = TextEditingController();
  final _confidenceController = TextEditingController(text: '0.6');
  final _sourceController = TextEditingController(text: 'testimony');
  final _domainController = TextEditingController(text: 'general');

  @override
  void dispose() {
    _propositionController.dispose();
    _confidenceController.dispose();
    _sourceController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _learn() async {
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.postJson(
        '/api/v1/cognitive/knowledge/learn',
        data: {
          'proposition': _propositionController.text,
          'confidence': double.tryParse(_confidenceController.text) ?? 0.6,
          'source': _sourceController.text,
          'domain': _domainController.text,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Knowledge ${result['action']}: ${result['belief_id']} (confidence: ${result['confidence']})'),
              backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Learn failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _propositionController,
            style: MayaTheme.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Proposition (fact to learn)',
              hintText: 'e.g., "The capital of France is Paris"',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _confidenceController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Confidence (0-1)',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sourceController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Source',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _domainController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Domain',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _learn,
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: const Text('Learn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonEmerald,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkingMemoryTab extends ConsumerWidget {
  const _WorkingMemoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityAsync = ref.watch(workingMemoryCapacityProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Working Memory', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Current active context and attention slots',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          capacityAsync.when(
            data: (capacity) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _CoreStatCard(
                            label: 'Total Slots',
                            value: capacity.capacity.toString(),
                            color: MayaTheme.neonCyan,
                            icon: Icons.casino_rounded)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _CoreStatCard(
                            label: 'Used',
                            value: capacity.used.toString(),
                            color: MayaTheme.neonOrange,
                            icon: Icons.memory_rounded)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _CoreStatCard(
                            label: 'Pending',
                            value: capacity.pending.toString(),
                            color: MayaTheme.neonViolet,
                            icon: Icons.pending_rounded)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _CoreStatCard(
                            label: 'Processing',
                            value: capacity.processing.toString(),
                            color: MayaTheme.neonEmerald,
                            icon: Icons.storage_rounded)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
            loading: () => const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          const Text('Search Working Memory', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _WorkingMemorySearchForm(),
          const SizedBox(height: 24),
          const Text('Add to Working Memory', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          _WorkingMemoryAddForm(),
        ],
      ),
    );
  }
}

class _WorkingMemorySearchForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WorkingMemorySearchForm> createState() =>
      _WorkingMemorySearchFormState();
}

class _WorkingMemorySearchFormState
    extends ConsumerState<_WorkingMemorySearchForm> {
  final _queryController = TextEditingController();
  final _limitController = TextEditingController(text: '10');
  final _typeController = TextEditingController();
  BeliefsQueryResponse? _result;

  @override
  void dispose() {
    _queryController.dispose();
    _limitController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.getJson(
        '/api/v1/cognitive/beliefs',
        queryParameters: {
          'query': _queryController.text,
          'limit': int.tryParse(_limitController.text) ?? 10,
          'type': _typeController.text.isEmpty ? null : _typeController.text,
        },
      );
      setState(() => _result = BeliefsQueryResponse.fromJson(result));
    } catch (e) {
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _queryController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Query',
              hintText: 'Search working memory...',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _typeController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Type (optional)',
                    hintText: 'fact, goal, observation...',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _limitController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Limit',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            const Divider(color: MayaTheme.glassWhite10),
            const SizedBox(height: 8),
            const Text('Results', style: MayaTheme.titleSmall),
            const SizedBox(height: 8),
            ..._result!.beliefs.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(item.proposition,
                                  style: MayaTheme.bodyMedium)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(item.domain.toUpperCase(),
                                style: MayaTheme.labelSmall
                                    .copyWith(color: MayaTheme.neonCyan)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Confidence: ${(item.confidence * 100).toStringAsFixed(1)}% • Time: ${item.createdAt.toString().substring(0, 19)}',
                          style: MayaTheme.bodySmall
                              .copyWith(color: Colors.white54)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _WorkingMemoryAddForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WorkingMemoryAddForm> createState() =>
      _WorkingMemoryAddFormState();
}

class _WorkingMemoryAddFormState extends ConsumerState<_WorkingMemoryAddForm> {
  final _contentController = TextEditingController();
  final _typeController = TextEditingController(text: 'fact');
  final _attentionController = TextEditingController(text: '1.0');

  @override
  void dispose() {
    _contentController.dispose();
    _typeController.dispose();
    _attentionController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson(
        '/api/v1/cognitive/memory/working/add',
        data: {
          'content': _contentController.text,
          'type': _typeController.text,
          'attention': double.tryParse(_attentionController.text) ?? 1.0,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Added to working memory'),
              backgroundColor: MayaTheme.neonEmerald),
        );
        _contentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Add failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _contentController,
            style: MayaTheme.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Content',
              hintText: 'What to remember...',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _typeController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _attentionController,
                  style: MayaTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Attention (0-1)',
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add to Working Memory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonEmerald,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowserTab extends ConsumerWidget {
  const _BrowserTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Browser Automation', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Control browser actions and view results',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          _BrowserActionForm(),
        ],
      ),
    );
  }
}

class _BrowserActionForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BrowserActionForm> createState() => _BrowserActionFormState();
}

class _BrowserActionFormState extends ConsumerState<_BrowserActionForm> {
  String _selectedAction = 'open';
  final _urlController = TextEditingController();
  final _selectorController = TextEditingController();
  final _textController = TextEditingController();
  final _queryController = TextEditingController();
  Map<String, dynamic>? _result;

  final List<String> _actions = [
    'open',
    'click',
    'type',
    'get_text',
    'screenshot',
    'search_google'
  ];

  @override
  void dispose() {
    _urlController.dispose();
    _selectorController.dispose();
    _textController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _execute() async {
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.postJson(
        '/api/v1/browser/action',
        data: {
          'action': _selectedAction,
          'url': _urlController.text.isEmpty ? null : _urlController.text,
          'selector': _selectorController.text.isEmpty
              ? null
              : _selectorController.text,
          'text': _textController.text.isEmpty ? null : _textController.text,
          'query': _queryController.text.isEmpty ? null : _queryController.text,
        },
      );
      setState(() => _result = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] == true
                ? 'Action completed'
                : 'Action failed: ${result['error'] ?? 'Unknown error'}'),
            backgroundColor: result['success'] == true
                ? MayaTheme.neonEmerald
                : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Browser action failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedAction,
            decoration: InputDecoration(
              labelText: 'Action',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            dropdownColor: MayaTheme.slate800,
            style: MayaTheme.bodyMedium,
            items: _actions
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) => setState(() => _selectedAction = v!),
          ),
          const SizedBox(height: 12),
          if (_selectedAction == 'open' || _selectedAction == 'search_google')
            TextField(
              controller:
                  _selectedAction == 'open' ? _urlController : _queryController,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: _selectedAction == 'open' ? 'URL' : 'Search Query',
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          if (_selectedAction == 'click' ||
              _selectedAction == 'type' ||
              _selectedAction == 'get_text')
            TextField(
              controller: _selectorController,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'CSS Selector',
                hintText: 'e.g., button.submit, #main-content',
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          if (_selectedAction == 'type')
            TextField(
              controller: _textController,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Text to Type',
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _execute,
              icon: const Icon(Icons.web_rounded),
              label: const Text('Execute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            const Divider(color: MayaTheme.glassWhite10),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                    _result!['success'] == true
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: _result!['success'] == true
                        ? MayaTheme.neonEmerald
                        : MayaTheme.error),
                const SizedBox(width: 8),
                Text(_result!['success'] == true ? 'Success' : 'Failed',
                    style: MayaTheme.bodyMedium),
              ],
            ),
            if (_result!['content'] != null) ...[
              const SizedBox(height: 12),
              const Text('Content:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard(),
                child: SingleChildScrollView(
                  child: SelectableText(_result!['content']!,
                      style: MayaTheme.bodySmall
                          .copyWith(fontFamily: 'monospace')),
                ),
              ),
            ],
            if (_result!['screenshot_path'] != null) ...[
              const SizedBox(height: 12),
              const Text('Screenshot:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard(),
                child: Text(_result!['screenshot_path']!,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
              ),
            ],
            if (_result!['error'] != null) ...[
              const SizedBox(height: 12),
              const Text('Error:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard().copyWith(
                  border:
                      Border.all(color: MayaTheme.error.withValues(alpha: 0.5)),
                ),
                child: Text(_result!['error']!,
                    style:
                        MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SandboxTab extends ConsumerWidget {
  const _SandboxTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Code Sandbox', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Execute code in secure sandbox environment',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          _SandboxExecuteForm(),
        ],
      ),
    );
  }
}

class _SandboxExecuteForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SandboxExecuteForm> createState() =>
      _SandboxExecuteFormState();
}

class _SandboxExecuteFormState extends ConsumerState<_SandboxExecuteForm> {
  String _selectedLanguage = 'python';
  final _codeController = TextEditingController();
  final _timeoutController = TextEditingController(text: '30');
  Map<String, dynamic>? _result;

  final List<String> _languages = [
    'python',
    'javascript',
    'bash',
    'typescript'
  ];

  @override
  void dispose() {
    _codeController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  Future<void> _execute() async {
    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.postJson(
        '/api/v1/sandbox/execute',
        data: {
          'code': _codeController.text,
          'language': _selectedLanguage,
          'timeout_seconds': int.tryParse(_timeoutController.text) ?? 30,
        },
      );
      setState(() => _result = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] == true
                ? 'Execution completed'
                : 'Execution failed: ${result['error'] ?? 'Unknown error'}'),
            backgroundColor: result['success'] == true
                ? MayaTheme.neonEmerald
                : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Sandbox execution failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            decoration: InputDecoration(
              labelText: 'Language',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            dropdownColor: MayaTheme.slate800,
            style: MayaTheme.bodyMedium,
            items: _languages
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => setState(() => _selectedLanguage = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            style: MayaTheme.codeStyle,
            maxLines: 15,
            decoration: InputDecoration(
              labelText: 'Code',
              hintText: 'Enter code to execute...',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeoutController,
            style: MayaTheme.bodyMedium,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Timeout (seconds)',
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _execute,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Execute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            const Divider(color: MayaTheme.glassWhite10),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                    _result!['success'] == true
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: _result!['success'] == true
                        ? MayaTheme.neonEmerald
                        : MayaTheme.error),
                const SizedBox(width: 8),
                Text(_result!['success'] == true ? 'Success' : 'Failed',
                    style: MayaTheme.bodyMedium),
              ],
            ),
            if (_result!['output'] != null) ...[
              const SizedBox(height: 12),
              const Text('Output:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard(),
                child: SingleChildScrollView(
                  child: SelectableText(_result!['output']!,
                      style: MayaTheme.bodySmall
                          .copyWith(fontFamily: 'monospace')),
                ),
              ),
            ],
            if (_result!['error'] != null) ...[
              const SizedBox(height: 12),
              const Text('Error:', style: MayaTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard().copyWith(
                  border:
                      Border.all(color: MayaTheme.error.withValues(alpha: 0.5)),
                ),
                child: Text(_result!['error']!,
                    style:
                        MayaTheme.bodySmall.copyWith(color: MayaTheme.error)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CoreStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _CoreStatCard({
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
