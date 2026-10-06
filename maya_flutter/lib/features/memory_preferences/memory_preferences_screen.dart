import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'memory_preferences_models.dart';
import 'memory_preferences_providers.dart';

class MemoryPreferencesScreen extends ConsumerStatefulWidget {
  const MemoryPreferencesScreen({super.key});

  @override
  ConsumerState<MemoryPreferencesScreen> createState() =>
      _MemoryPreferencesScreenState();
}

class _MemoryPreferencesScreenState
    extends ConsumerState<MemoryPreferencesScreen>
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
          title:
              const Text('Memory Preferences', style: MayaTheme.headlineSmall),
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
                // Refresh will be handled by individual tabs
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.settings_rounded), text: 'Preferences'),
              Tab(icon: Icon(Icons.fact_check_rounded), text: 'Facts'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _MemPrefsTab(),
            _MemFactsTab(),
          ],
        ),
      ),
    );
  }
}

class _MemPrefsTab extends ConsumerStatefulWidget {
  const _MemPrefsTab();

  @override
  ConsumerState<_MemPrefsTab> createState() => _MemPrefsTabState();
}

class _MemPrefsTabState extends ConsumerState<_MemPrefsTab> {
  final _userIdController = TextEditingController(text: 'default');
  bool _isLoading = false;

  Future<void> _loadPrefs() async {
    setState(() => _isLoading = true);
    ref.invalidate(memoryPrefsProvider(_userIdController.text.trim()));
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync =
        ref.watch(memoryPrefsProvider(_userIdController.text.trim()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Memory Preferences', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text('User-specific key-value preferences stored in extended memory',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _userIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    hintText: 'default',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.person_rounded, color: Colors.white54),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadPrefs,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(_isLoading ? 'Loading...' : 'Load Preferences'),
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
          prefsAsync.when(
            data: (prefs) {
              if (prefs.preferences.isEmpty) {
                return const MayaEmptyState(
                  'No Preferences',
                  icon: Icons.settings_rounded,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preferences', style: MayaTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: prefs.preferences.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final entry = prefs.preferences.entries.elementAt(index);
                      return _PrefCard(prefKey: entry.key, value: entry.value);
                    },
                  ),
                ],
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
                  const Icon(Icons.error_rounded,
                      size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading preferences',
                      style: MayaTheme.bodyMedium
                          .copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(),
                      style:
                          MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefCard extends StatelessWidget {
  final String prefKey;
  final String value;

  const _PrefCard({required this.prefKey, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MayaTheme.neonViolet.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.key_rounded,
                color: MayaTheme.neonViolet, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prefKey, style: MayaTheme.titleMedium),
                Text(value,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemFactsTab extends ConsumerStatefulWidget {
  const _MemFactsTab();

  @override
  ConsumerState<_MemFactsTab> createState() => _MemFactsTabState();
}

class _MemFactsTabState extends ConsumerState<_MemFactsTab> {
  final _userIdController = TextEditingController(text: 'default');
  final _factController = TextEditingController();
  final _sourceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _factController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _loadFacts() async {
    setState(() => _isLoading = true);
    ref.invalidate(memoryFactsProvider(_userIdController.text.trim()));
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addFact() async {
    if (_factController.text.trim().isEmpty ||
        _sourceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Fact and source required'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }
    try {
      final api = ref.read(mayaApiProvider);
      final response =
          await api.postJson('/api/v1/extended/memory/facts', data: {
        'fact': _factController.text.trim(),
        'source': _sourceController.text.trim(),
      });
      final result = ExtMemFactsResponse.fromJson(response);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Fact added: ${result.factId}'),
              backgroundColor: MayaTheme.neonEmerald),
        );
        _factController.clear();
        _sourceController.clear();
        _loadFacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final factsAsync =
        ref.watch(memoryFactsProvider(_userIdController.text.trim()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Memory Facts', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Facts stored in extended memory',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _userIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    hintText: 'default',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.person_rounded, color: Colors.white54),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadFacts,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(_isLoading ? 'Loading...' : 'Load Facts'),
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
          const Text('Add New Fact', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              children: [
                TextField(
                  controller: _factController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Fact *',
                    hintText: 'The fact to store...',
                    labelStyle: const TextStyle(color: Colors.white54),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child:
                          Icon(Icons.fact_check_rounded, color: Colors.white54),
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
                  controller: _sourceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Source *',
                    hintText: 'e.g., observation, research, deduction',
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addFact,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Fact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonEmerald,
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
          factsAsync.when(
            data: (facts) {
              if (facts.facts.isEmpty) {
                return const MayaEmptyState(
                  'No Facts',
                  icon: Icons.fact_check_rounded,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Facts', style: MayaTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: facts.facts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final fact = facts.facts[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fact.fact, style: MayaTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Source: ${fact.source} • ${fact.createdAt.toString().substring(0, 19)}',
                              style: MayaTheme.bodySmall
                                  .copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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
                  const Icon(Icons.error_rounded,
                      size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading facts',
                      style: MayaTheme.bodyMedium
                          .copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(),
                      style:
                          MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
