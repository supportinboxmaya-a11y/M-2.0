import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'skill_generalization_models.dart';
import 'skill_generalization_providers.dart';

class SkillGeneralizationScreen extends ConsumerStatefulWidget {
  const SkillGeneralizationScreen({super.key});

  @override
  ConsumerState<SkillGeneralizationScreen> createState() =>
      _SkillGeneralizationScreenState();
}

class _SkillGeneralizationScreenState
    extends ConsumerState<SkillGeneralizationScreen>
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
          title: const Text('Skill Generalization',
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
              onPressed: () {
                ref.invalidate(proceduralListProvider);
                ref.invalidate(proceduralStatsProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.search_rounded), text: 'Search Skills'),
              Tab(
                  icon: Icon(Icons.auto_awesome_rounded),
                  text: 'Compose Skills'),
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'All Skills'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _SkillSearchTab(),
            _SkillComposeTab(),
            _AllSkillsTab(),
          ],
        ),
      ),
    );
  }
}

class _SkillSearchTab extends ConsumerStatefulWidget {
  const _SkillSearchTab();

  @override
  ConsumerState<_SkillSearchTab> createState() => _SkillSearchTabState();
}

class _SkillSearchTabState extends ConsumerState<_SkillSearchTab> {
  final _queryController = TextEditingController();
  int _limit = 10;
  ProceduralSearchResponse? _lastResult;
  bool _isSearching = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _searchSkills() async {
    if (_queryController.text.trim().isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final api = ref.read(mayaApiProvider);
      final response = await api.getJson(
          '/api/v1/cognitive/memory/procedural/search',
          queryParameters: {
            'q': _queryController.text.trim(),
            'limit': _limit,
          });
      setState(() {
        _lastResult = ProceduralSearchResponse.fromJson(response);
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
          const Text('Search Skills', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Find relevant skills for a goal using semantic search. Skills generalize to novel-but-similar tasks.',
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
                    labelText: 'Goal / Task Description *',
                    hintText: 'e.g., Build a REST API with authentication',
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
                    Text('Max Results: $_limit',
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
                    onPressed: _isSearching ? null : _searchSkills,
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
                    label:
                        Text(_isSearching ? 'Searching...' : 'Search Skills'),
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
            const Text('Matching Skills', style: MayaTheme.titleLarge),
            const SizedBox(height: 12),
            _lastResult!.skills.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(
                        child: Text('No matching skills found',
                            style: MayaTheme.bodyMedium)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lastResult!.skills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final skill = _lastResult!.skills[index];
                      return _SkillResultCard(skill: skill, rank: index + 1);
                    },
                  ),
          ],
        ],
      ),
    );
  }
}

class _SkillResultCard extends StatelessWidget {
  final ProceduralSkill skill;
  final int rank;

  const _SkillResultCard({required this.skill, required this.rank});

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
                    Text(skill.name, style: MayaTheme.titleMedium),
                    Text(skill.description,
                        style:
                            MayaTheme.bodySmall.copyWith(color: Colors.white54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SkillInfoChip(
                  label: 'Verified',
                  value: skill.verified ? 'Yes' : 'No',
                  color: skill.verified
                      ? MayaTheme.neonEmerald
                      : MayaTheme.neonOrange),
              _SkillInfoChip(
                  label: 'Confidence',
                  value: '${(skill.confidence * 100).toStringAsFixed(1)}%',
                  color: MayaTheme.neonViolet),
              _SkillInfoChip(
                  label: 'Success Rate',
                  value: '${(skill.successRate * 100).toStringAsFixed(1)}%',
                  color: MayaTheme.neonOrange),
              _SkillInfoChip(
                  label: 'Usage Count',
                  value: skill.usageCount.toString(),
                  color: MayaTheme.neonCyan),
            ],
          ),
          if (skill.applicableGoals.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Applicable Goals:', style: MayaTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: skill.applicableGoals
                  .map((g) => Chip(
                        label: Text(g, style: MayaTheme.bodySmall),
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

class _SkillComposeTab extends ConsumerStatefulWidget {
  const _SkillComposeTab();

  @override
  ConsumerState<_SkillComposeTab> createState() => _SkillComposeTabState();
}

class _SkillComposeTabState extends ConsumerState<_SkillComposeTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedSkillIds = [];
  ProceduralComposeResponse? _lastResult;
  bool _isComposing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _composeSkills() async {
    if (_selectedSkillIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select at least 2 skills to compose'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name is required'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isComposing = true);
    try {
      final api = ref.read(mayaApiProvider);
      final response = await api
          .postJson('/api/v1/cognitive/memory/procedural/compose', data: {
        'skill_ids': _selectedSkillIds,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      setState(() {
        _lastResult = ProceduralComposeResponse.fromJson(response);
        _isComposing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Skill composed: ${_lastResult!.skillId} (${_lastResult!.name})'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      setState(() => _isComposing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Compose failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(proceduralListProvider);

    return skillsAsync.when(
      data: (skillsData) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compose Skills', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Combine existing skills into a new higher-order skill. Select 2+ skills that work well together.',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            // Skill Selection
            const Text('Select Skills to Combine',
                style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            skillsData.skills.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(
                        child: Text(
                            'No skills available. Learn some skills first.',
                            style: MayaTheme.bodyMedium)),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: MayaTheme.glassCard(),
                    child: Column(
                      children: skillsData.skills
                          .map((skill) => CheckboxListTile(
                                value: _selectedSkillIds.contains(skill.id),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedSkillIds.add(skill.id);
                                    } else {
                                      _selectedSkillIds.remove(skill.id);
                                    }
                                  });
                                },
                                title: Text(skill.name,
                                    style: MayaTheme.bodyMedium),
                                subtitle: Text(skill.description,
                                    style: MayaTheme.bodySmall
                                        .copyWith(color: Colors.white54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                secondary: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: skill.verified
                                        ? MayaTheme.neonEmerald
                                            .withValues(alpha: 0.2)
                                        : MayaTheme.neonOrange
                                            .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                      skill.verified
                                          ? 'VERIFIED'
                                          : 'UNVERIFIED',
                                      style: MayaTheme.labelSmall.copyWith(
                                          color: skill.verified
                                              ? MayaTheme.neonEmerald
                                              : MayaTheme.neonOrange)),
                                ),
                                activeColor: MayaTheme.neonCyan,
                                checkColor: Colors.black,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ))
                          .toList(),
                    ),
                  ),
            const SizedBox(height: 24),
            // Compose Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'New Skill Name *',
                      hintText: 'e.g., REST API with Auth',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.auto_awesome_rounded,
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
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'What this combined skill does...',
                      labelStyle: const TextStyle(color: Colors.white54),
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.description_rounded,
                            color: Colors.white54),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedSkillIds.length < 2 || _isComposing
                          ? null
                          : _composeSkills,
                      icon: _isComposing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label:
                          Text(_isComposing ? 'Composing...' : 'Compose Skill'),
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
                            Text('Skill Composed Successfully',
                                style: MayaTheme.labelMedium
                                    .copyWith(color: MayaTheme.neonEmerald)),
                          ]),
                          const SizedBox(height: 8),
                          Text('ID: ${_lastResult!.skillId}',
                              style: MayaTheme.bodySmall
                                  .copyWith(fontFamily: 'monospace')),
                          Text('Name: ${_lastResult!.name}',
                              style: MayaTheme.bodySmall),
                          Text(
                              'Verified: ${_lastResult!.verified ? "Yes" : "No"}',
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
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
        const SizedBox(height: 16),
        Text('Error loading skills',
            style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
        const SizedBox(height: 8),
        Text(err.toString(),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
      ])),
    );
  }
}

class _AllSkillsTab extends ConsumerWidget {
  const _AllSkillsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(proceduralListProvider);
    final statsAsync = ref.watch(proceduralStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('All Skills', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Complete list of all learned procedural skills',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          // Stats
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                    child: _SkillStatCard(
                        label: 'Total Skills',
                        value: stats.totalSkills.toString(),
                        color: MayaTheme.neonCyan,
                        icon: Icons.memory_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _SkillStatCard(
                        label: 'Verified',
                        value: stats.verifiedSkills.toString(),
                        color: MayaTheme.neonEmerald,
                        icon: Icons.verified_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _SkillStatCard(
                        label: 'Avg Confidence',
                        value: stats.avgConfidence.toStringAsFixed(2),
                        color: MayaTheme.neonViolet,
                        icon: Icons.trending_up_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _SkillStatCard(
                        label: 'Avg Success Rate',
                        value:
                            '${(stats.avgSuccessRate * 100).toStringAsFixed(1)}%',
                        color: MayaTheme.neonOrange,
                        icon: Icons.check_circle_rounded)),
              ],
            ),
            loading: () => const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Text('Error: $err',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
          ),
          const SizedBox(height: 24),
          // Skills List
          listAsync.when(
            data: (data) => data.skills.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: MayaTheme.glassCard(),
                    child: const Center(
                        child: Text('No skills learned yet',
                            style: MayaTheme.bodyMedium)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.skills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final skill = data.skills[index];
                      return _AllSkillCard(skill: skill);
                    },
                  ),
            loading: () => const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
            error: (err, _) => Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(Icons.error_rounded,
                      size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading skills',
                      style: MayaTheme.bodyMedium
                          .copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(),
                      style:
                          MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ])),
          ),
        ],
      ),
    );
  }
}

class _SkillStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SkillStatCard({
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

class _AllSkillCard extends StatelessWidget {
  final ProceduralSkill skill;

  const _AllSkillCard({required this.skill});

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
                  color: skill.verified
                      ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                      : MayaTheme.neonOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.psychology_rounded,
                    color: skill.verified
                        ? MayaTheme.neonEmerald
                        : MayaTheme.neonOrange,
                    size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child:
                                Text(skill.name, style: MayaTheme.titleMedium)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: skill.verified
                                ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                                : MayaTheme.neonOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: skill.verified
                                    ? MayaTheme.neonEmerald
                                    : MayaTheme.neonOrange),
                          ),
                          child: Text(
                              skill.verified ? 'VERIFIED' : 'UNVERIFIED',
                              style: MayaTheme.labelSmall.copyWith(
                                  color: skill.verified
                                      ? MayaTheme.neonEmerald
                                      : MayaTheme.neonOrange)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(skill.description,
                        style:
                            MayaTheme.bodySmall.copyWith(color: Colors.white54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SkillInfoChip(
                  label: 'Confidence',
                  value: '${(skill.confidence * 100).toStringAsFixed(1)}%',
                  color: MayaTheme.neonViolet),
              _SkillInfoChip(
                  label: 'Success Rate',
                  value: '${(skill.successRate * 100).toStringAsFixed(1)}%',
                  color: MayaTheme.neonOrange),
              _SkillInfoChip(
                  label: 'Usage Count',
                  value: skill.usageCount.toString(),
                  color: MayaTheme.neonCyan),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SkillInfoChip({
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
