import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'knowledge_engine_models.dart';
import 'knowledge_engine_providers.dart';

class KnowledgeEngineScreen extends ConsumerStatefulWidget {
  const KnowledgeEngineScreen({super.key});

  @override
  ConsumerState<KnowledgeEngineScreen> createState() =>
      _KnowledgeEngineScreenState();
}

class _KnowledgeEngineScreenState extends ConsumerState<KnowledgeEngineScreen>
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
          title: const Text('Knowledge Engine', style: MayaTheme.headlineSmall),
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
                ref.invalidate(knowledgeStatsProvider);
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
              Tab(icon: Icon(Icons.search_rounded), text: 'Query Knowledge'),
              Tab(icon: Icon(Icons.lightbulb_rounded), text: 'Learn / Teach'),
              Tab(icon: Icon(Icons.psychology_rounded), text: 'Beliefs'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _KnowledgeQueryTab(),
            _KnowledgeLearnTab(),
            _BeliefsTab(),
            _KnowledgeStatsTab(),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeQueryTab extends ConsumerStatefulWidget {
  const _KnowledgeQueryTab();

  @override
  ConsumerState<_KnowledgeQueryTab> createState() => _KnowledgeQueryTabState();
}

class _KnowledgeQueryTabState extends ConsumerState<_KnowledgeQueryTab> {
  final _queryController = TextEditingController();
  final _domainController = TextEditingController();
  int _limit = 10;
  KnowledgeQueryResponse? _lastResult;
  bool _isQuerying = false;

  @override
  void dispose() {
    _queryController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _runQuery() async {
    if (_queryController.text.trim().isEmpty) return;

    setState(() => _isQuerying = true);
    try {
      final api = ref.read(mayaApiProvider);
      final response = await api
          .getJson('/api/v1/cognitive/knowledge/query', queryParameters: {
        'q': _queryController.text.trim(),
        if (_domainController.text.trim().isNotEmpty)
          'domain': _domainController.text.trim(),
        'limit': _limit,
      });
      setState(() {
        _lastResult = KnowledgeQueryResponse.fromJson(response);
        _isQuerying = false;
      });
    } catch (e) {
      setState(() => _isQuerying = false);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Query Knowledge Base', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Search Maya\'s structured knowledge base using semantic similarity.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          // Query Form
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
                    hintText: 'e.g., What is the VPS SSH port?',
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
                TextField(
                  controller: _domainController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Domain Filter (optional)',
                    hintText: 'e.g., general, vps, deployment',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.category_rounded,
                        color: Colors.white54),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isQuerying ? null : _runQuery,
                    icon: _isQuerying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(_isQuerying ? 'Querying...' : 'Run Query'),
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
                      final item = _lastResult!.results[index];
                      return _KnowledgeResultCard(item: item, rank: index + 1);
                    },
                  ),
          ],
        ],
      ),
    );
  }
}

class _KnowledgeResultCard extends StatelessWidget {
  final KnowledgeItem item;
  final int rank;

  const _KnowledgeResultCard({required this.item, required this.rank});

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
                child: Text(item.proposition, style: MayaTheme.bodyLarge),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                  label: 'Domain',
                  value: item.domain,
                  color: MayaTheme.neonViolet),
              _InfoChip(
                  label: 'Source',
                  value: item.source,
                  color: MayaTheme.neonEmerald),
              _InfoChip(
                  label: 'Confidence',
                  value: '${(item.confidence * 100).toStringAsFixed(1)}%',
                  color: MayaTheme.neonOrange),
            ],
          ),
          if (item.evidence.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Evidence:', style: MayaTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: item.evidence
                  .map((e) => Chip(
                        label: Text(e, style: MayaTheme.bodySmall),
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

class _KnowledgeLearnTab extends ConsumerStatefulWidget {
  const _KnowledgeLearnTab();

  @override
  ConsumerState<_KnowledgeLearnTab> createState() => _KnowledgeLearnTabState();
}

class _KnowledgeLearnTabState extends ConsumerState<_KnowledgeLearnTab> {
  final _propositionController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _sourceController = TextEditingController(text: 'testimony');
  final _domainController = TextEditingController(text: 'general');
  double _confidence = 0.6;
  KnowledgeLearnResponse? _lastResult;
  bool _isLearning = false;

  @override
  void dispose() {
    _propositionController.dispose();
    _evidenceController.dispose();
    _sourceController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _teachKnowledge() async {
    if (_propositionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Proposition is required'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isLearning = true);
    try {
      final api = ref.read(mayaApiProvider);
      final response =
          await api.postJson('/api/v1/cognitive/knowledge/learn', data: {
        'proposition': _propositionController.text.trim(),
        'confidence': _confidence,
        'source': _sourceController.text.trim(),
        'domain': _domainController.text.trim(),
        'evidence': _evidenceController.text.trim().isEmpty
            ? null
            : _evidenceController.text
                .trim()
                .split('|')
                .map((e) => e.trim())
                .toList(),
      });
      setState(() {
        _lastResult = KnowledgeLearnResponse.fromJson(response);
        _isLearning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Knowledge ${_lastResult!.action}: ${_lastResult!.beliefId} (confidence: ${_lastResult!.confidence})'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLearning = false);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Learn / Teach Knowledge', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Teach Maya a new fact. Belief revision merges with existing knowledge (agreeing strengthens, conflicting weakens).',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _propositionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Proposition *',
                    hintText: 'e.g., The VPS SSH port is 20045',
                    labelStyle: const TextStyle(color: Colors.white54),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child:
                          Icon(Icons.lightbulb_rounded, color: Colors.white54),
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
                    Text(
                        'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                        style: MayaTheme.bodyMedium
                            .copyWith(color: MayaTheme.neonCyan)),
                    Expanded(
                        child: Slider(
                      value: _confidence,
                      min: 0.1,
                      max: 1.0,
                      divisions: 18,
                      activeColor: MayaTheme.neonCyan,
                      inactiveColor: Colors.white24,
                      onChanged: (v) => setState(() => _confidence = v),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sourceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Source',
                    hintText: 'testimony, observation, research, deduction',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.source_rounded, color: Colors.white54),
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
                TextField(
                  controller: _domainController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Domain',
                    hintText: 'general, vps, deployment, coding, etc.',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.category_rounded,
                        color: Colors.white54),
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
                TextField(
                  controller: _evidenceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Evidence (pipe-separated, optional)',
                    hintText:
                        'e.g., config file | deployment log | vendor docs',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.fact_check_rounded,
                        color: Colors.white54),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLearning ? null : _teachKnowledge,
                    icon: _isLearning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Icon(Icons.school_rounded),
                    label:
                        Text(_isLearning ? 'Learning...' : 'Teach Knowledge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_lastResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MayaTheme.neonEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MayaTheme.neonEmerald),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              color: MayaTheme.neonEmerald, size: 20),
                          const SizedBox(width: 8),
                          Text('Knowledge ${_lastResult!.action.toUpperCase()}',
                              style: MayaTheme.labelMedium
                                  .copyWith(color: MayaTheme.neonEmerald)),
                        ]),
                        const SizedBox(height: 8),
                        Text('Belief ID: ${_lastResult!.beliefId}',
                            style: MayaTheme.bodySmall
                                .copyWith(fontFamily: 'monospace')),
                        Text('Confidence: ${_lastResult!.confidence}',
                            style: MayaTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeliefsTab extends ConsumerStatefulWidget {
  const _BeliefsTab();

  @override
  ConsumerState<_BeliefsTab> createState() => _BeliefsTabState();
}

class _BeliefsTabState extends ConsumerState<_BeliefsTab> {
  final _domainController = TextEditingController();
  double _minConfidence = 0.0;
  BeliefsQueryResponse? _lastResult;

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _queryBeliefs() async {
    try {
      final api = ref.read(mayaApiProvider);
      final response =
          await api.getJson('/api/v1/cognitive/beliefs', queryParameters: {
        if (_domainController.text.trim().isNotEmpty)
          'domain': _domainController.text.trim(),
        'min_confidence': _minConfidence,
      });
      setState(() => _lastResult = BeliefsQueryResponse.fromJson(response));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Beliefs', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Query Maya\'s beliefs. Beliefs are individual propositions with confidence levels and domains.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          // Query Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _domainController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Domain Filter (optional)',
                    hintText: 'e.g., general, vps, coding',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.category_rounded,
                        color: Colors.white54),
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
                    Text(
                        'Min Confidence: ${(_minConfidence * 100).toStringAsFixed(0)}%',
                        style: MayaTheme.bodyMedium
                            .copyWith(color: MayaTheme.neonCyan)),
                    Expanded(
                        child: Slider(
                      value: _minConfidence,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: MayaTheme.neonCyan,
                      inactiveColor: Colors.white24,
                      onChanged: (v) => setState(() => _minConfidence = v),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _queryBeliefs,
                    icon: const Icon(Icons.psychology_rounded),
                    label: const Text('Query Beliefs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonViolet,
                      foregroundColor: Colors.white,
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
            const Text('Beliefs', style: MayaTheme.titleLarge),
            const SizedBox(height: 12),
            _lastResult!.beliefs.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(
                        child: Text('No beliefs found',
                            style: MayaTheme.bodyMedium)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lastResult!.beliefs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final belief = _lastResult!.beliefs[index];
                      return _BeliefCard(belief: belief);
                    },
                  ),
          ],
        ],
      ),
    );
  }
}

class _BeliefCard extends StatelessWidget {
  final Belief belief;

  const _BeliefCard({required this.belief});

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(belief.confidence)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.psychology_rounded,
                    color: _getConfidenceColor(belief.confidence), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(belief.proposition, style: MayaTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label:
                              Text(belief.domain, style: MayaTheme.labelSmall),
                          backgroundColor:
                              MayaTheme.neonViolet.withValues(alpha: 0.2),
                          side: const BorderSide(color: MayaTheme.neonViolet),
                        ),
                        Chip(
                          label:
                              Text(belief.source, style: MayaTheme.labelSmall),
                          backgroundColor:
                              MayaTheme.neonEmerald.withValues(alpha: 0.2),
                          side: const BorderSide(color: MayaTheme.neonEmerald),
                        ),
                        Chip(
                          label: Text(
                              '${(belief.confidence * 100).toStringAsFixed(0)}%',
                              style: MayaTheme.labelSmall),
                          backgroundColor:
                              _getConfidenceColor(belief.confidence)
                                  .withValues(alpha: 0.2),
                          side: BorderSide(
                              color: _getConfidenceColor(belief.confidence)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (belief.evidence != null && belief.evidence!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Evidence:', style: MayaTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: belief.evidence!
                  .map((e) => Chip(
                        label: Text(e, style: MayaTheme.bodySmall),
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return MayaTheme.neonEmerald;
    if (confidence >= 0.5) return MayaTheme.neonCyan;
    if (confidence >= 0.3) return MayaTheme.neonOrange;
    return MayaTheme.error;
  }
}

class _KnowledgeStatsTab extends ConsumerWidget {
  const _KnowledgeStatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(knowledgeStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Knowledge Base Statistics',
                style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Overview of Maya\'s structured knowledge base',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            // Main Stats
            Row(
              children: [
                Expanded(
                    child: _KnowledgeStatCard(
                        label: 'Total Beliefs',
                        value: stats.totalBeliefs.toString(),
                        color: MayaTheme.neonCyan,
                        icon: Icons.lightbulb_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _KnowledgeStatCard(
                        label: 'Domains',
                        value: stats.domains.toString(),
                        color: MayaTheme.neonViolet,
                        icon: Icons.category_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _KnowledgeStatCard(
                        label: 'Avg Confidence',
                        value:
                            '${(stats.avgConfidence * 100).toStringAsFixed(1)}%',
                        color: MayaTheme.neonEmerald,
                        icon: Icons.trending_up_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _KnowledgeStatCard(
                        label: 'Retrieval Engine',
                        value: stats.retrievalEngine.toString(),
                        color: MayaTheme.neonOrange,
                        icon: Icons.memory_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            // Domain Breakdown (placeholder - would need backend to return domain counts)
            const Text('Domain Distribution', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: const Text(
                'Domain breakdown requires backend enhancement to return per-domain counts.\nCurrently showing total stats only.',
                style: MayaTheme.bodyMedium,
              ),
            ),
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
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _KnowledgeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KnowledgeStatCard({
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text('$label: $value',
          style: MayaTheme.labelSmall.copyWith(color: color)),
    );
  }
}
