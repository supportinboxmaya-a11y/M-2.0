import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import 'learning_models.dart';
import 'learning_providers.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen>
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
          title: const Text('Learning Layer', style: MayaTheme.headlineSmall),
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
                ref.invalidate(learningStatsProvider);
                ref.invalidate(learningExperienceProvider);
                ref.invalidate(learningPromptsProvider);
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
              Tab(icon: Icon(Icons.feedback_rounded), text: 'Feedback'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Experience'),
              Tab(icon: Icon(Icons.psychology_rounded), text: 'Prompts'),
              Tab(icon: Icon(Icons.compress_rounded), text: 'Compression'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedbackTab(),
            _buildExperienceTab(),
            _buildPromptsTab(),
            _buildCompressionTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackTab() {
    final statsAsync = ref.watch(learningStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Submit Feedback Form
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: _FeedbackForm(onSubmit: () {
                ref.invalidate(learningStatsProvider);
              }),
            ),

            const SizedBox(height: 24),

            // Stats Summary
            Row(
              children: [
                Expanded(
                    child: _FeedbackStatCard(
                        label: 'Total',
                        value: stats.feedback.total.toString(),
                        color: MayaTheme.neonCyan)),
                const SizedBox(width: 12),
                Expanded(
                    child: _FeedbackStatCard(
                        label: 'Positive',
                        value: stats.feedback.positive.toString(),
                        color: MayaTheme.neonEmerald)),
                const SizedBox(width: 12),
                Expanded(
                    child: _FeedbackStatCard(
                        label: 'Negative',
                        value: stats.feedback.negative.toString(),
                        color: MayaTheme.error)),
                const SizedBox(width: 12),
                Expanded(
                    child: _FeedbackStatCard(
                        label: 'Satisfaction',
                        value: stats.feedback.satisfaction != null
                            ? '${(stats.feedback.satisfaction! * 100).toStringAsFixed(1)}%'
                            : 'N/A',
                        color: MayaTheme.neonViolet)),
              ],
            ),

            const SizedBox(height: 24),

            // Lessons (from negative feedback)
            if (stats.lessons.isNotEmpty) ...[
              const Text('Lessons Learned (from negative feedback)',
                  style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              ...stats.lessons.map((lesson) => _LessonTile(lesson: lesson)),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: const Text(
                    'No lessons recorded yet. Submit feedback with comments on negative ratings.',
                    style: MayaTheme.bodyMedium),
              ),
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

  Widget _buildExperienceTab() {
    final experienceAsync = ref.watch(learningExperienceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Similar Experience Lookup
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: _ExperienceLookup(onSearch: () {
              ref.invalidate(learningExperienceProvider);
            }),
          ),

          const SizedBox(height: 24),

          // Experience History
          const Text('Recent Experience History', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          experienceAsync.when(
            data: (exp) {
              final history = exp.history ?? [];
              if (history.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: const Text('No experience recorded yet',
                      style: MayaTheme.bodyMedium),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final episode = history[index];
                  return _ExperienceTile(episode: episode);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
            ),
            error: (err, _) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                children: [
                  const Icon(Icons.error_rounded,
                      size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading experience',
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

  Widget _buildPromptsTab() {
    final promptsAsync = ref.watch(learningPromptsProvider);

    return promptsAsync.when(
      data: (prompts) {
        if (prompts.prompts.isEmpty) {
          return const Center(
            child: Text('No prompt variants recorded yet',
                style: MayaTheme.bodyMedium),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: prompts.prompts.entries.map((entry) {
            final task = entry.key;
            final variants = entry.value;
            return _PromptTaskTile(task: task, variants: variants);
          }).toList(),
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
            Text('Error loading prompts',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Memory Compression', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Compress long-term memory (chat, episodic, semantic) to reduce storage and improve retrieval. Dry-run shows what would be compressed without making changes.',
                  style: MayaTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: 'chat',
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Memory Type',
                          labelStyle: MayaTheme.bodyMedium
                              .copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'chat', child: Text('Chat History')),
                          DropdownMenuItem(
                              value: 'episodic',
                              child: Text('Episodic Memory')),
                          DropdownMenuItem(
                              value: 'semantic',
                              child: Text('Semantic Memory')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Dry Run'),
                        subtitle: const Text('Preview only, no changes'),
                        value: true,
                        activeThumbColor: MayaTheme.neonCyan,
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final api = ref.read(mayaApiProvider);
                          final result = await api
                              .postJson('/api/v1/learning/compress', data: {
                            'dry_run': true,
                            'memory_type': 'chat',
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Compression dry-run complete'),
                                  backgroundColor: MayaTheme.neonEmerald),
                            );
                          }
                        },
                        icon: const Icon(Icons.preview_rounded),
                        label: const Text('Dry Run'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MayaTheme.neonCyan,
                          foregroundColor: MayaTheme.slate900,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: MayaTheme.slate800,
                              title: const Text('Confirm Compression'),
                              content: const Text(
                                  'This will permanently compress memory. Continue?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: MayaTheme.error),
                                    child: const Text('Compress')),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            final api = ref.read(mayaApiProvider);
                            final result = await api
                                .postJson('/api/v1/learning/compress', data: {
                              'dry_run': false,
                              'memory_type': 'chat',
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Compression executed'),
                                    backgroundColor: MayaTheme.neonEmerald),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.compress_rounded),
                        label: const Text('Execute'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MayaTheme.error,
                          side: BorderSide(
                              color: MayaTheme.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Compression Stats (from stats endpoint)
          Consumer(
            builder: (context, ref, _) {
              final statsAsync = ref.watch(learningStatsProvider);
              return statsAsync.when(
                data: (stats) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Compression Status',
                          style: MayaTheme.titleMedium),
                      const SizedBox(height: 12),
                      _CompressionStatRow(
                          label: 'Prompt Variants',
                          value: stats.prompts.length.toString()),
                      _CompressionStatRow(
                          label: 'Feedback Entries',
                          value: stats.feedback.total.toString()),
                      _CompressionStatRow(
                          label: 'Satisfaction Rate',
                          value: stats.feedback.satisfaction != null
                              ? '${(stats.feedback.satisfaction! * 100).toStringAsFixed(1)}%'
                              : 'N/A'),
                    ],
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeedbackForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmit;

  const _FeedbackForm({required this.onSubmit});

  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  final _goalController = TextEditingController();
  final _outputController = TextEditingController();
  final _commentController = TextEditingController();
  int _rating = 0; // -1, 0, 1

  @override
  void dispose() {
    _goalController.dispose();
    _outputController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Submit Feedback', style: MayaTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _goalController,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Goal / Task',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _outputController,
          style: MayaTheme.bodyMedium,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Maya\'s Output',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Rating:', style: MayaTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            _RatingButton(
                label: '👎 Bad',
                value: -1,
                selected: _rating == -1,
                color: MayaTheme.error,
                onTap: () => setState(() => _rating = -1)),
            const SizedBox(width: 8),
            _RatingButton(
                label: '😐 Neutral',
                value: 0,
                selected: _rating == 0,
                color: MayaTheme.neonOrange,
                onTap: () => setState(() => _rating = 0)),
            const SizedBox(width: 8),
            _RatingButton(
                label: '👍 Good',
                value: 1,
                selected: _rating == 1,
                color: MayaTheme.neonEmerald,
                onTap: () => setState(() => _rating = 1)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          style: MayaTheme.bodyMedium,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Comment (optional)',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
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
          child: ElevatedButton(
            onPressed: _rating != 0 ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.neonCyan,
              foregroundColor: MayaTheme.slate900,
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: Colors.white12,
            ),
            child: const Text('Submit Feedback'),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    final goal = _goalController.text.trim();
    final output = _outputController.text.trim();
    final comment = _commentController.text.trim();
    if (goal.isEmpty || output.isEmpty) return;

    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson('/api/v1/learning/feedback', data: {
        'goal': goal,
        'output': output,
        'rating': _rating,
        'comment': comment,
      });
      _goalController.clear();
      _outputController.clear();
      _commentController.clear();
      setState(() => _rating = 0);
      widget.onSubmit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Feedback submitted'),
              backgroundColor: MayaTheme.neonEmerald),
        );
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
}

class _RatingButton extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton(
      {required this.label,
      required this.value,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.3) : MayaTheme.slate700,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : MayaTheme.glassWhite10, width: 2),
          ),
          child: Center(
              child: Text(label,
                  style: MayaTheme.bodyMedium
                      .copyWith(color: selected ? color : Colors.white))),
        ),
      ),
    );
  }
}

class _FeedbackStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FeedbackStatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCardGlow(glowColor: color),
      child: Column(
        children: [
          Text(value, style: MayaTheme.headlineMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch((lesson.ts * 1000).round())
        .toString()
        .substring(0, 19);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: MayaTheme.neonOrange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Lesson from negative feedback',
                      style: MayaTheme.titleSmall
                          .copyWith(color: MayaTheme.neonOrange))),
            ],
          ),
          const SizedBox(height: 8),
          Text(lesson.goal, style: MayaTheme.bodyMedium),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MayaTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(lesson.comment,
                style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
          ),
          const SizedBox(height: 4),
          Text(time,
              style: MayaTheme.labelSmall.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }
}

class _ExperienceLookup extends ConsumerStatefulWidget {
  final VoidCallback onSearch;

  const _ExperienceLookup({required this.onSearch});

  @override
  ConsumerState<_ExperienceLookup> createState() => _ExperienceLookupState();
}

class _ExperienceLookupState extends ConsumerState<_ExperienceLookup> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_controller.text.trim().isEmpty) return;
    final api = ref.read(mayaApiProvider);
    try {
      final response =
          await api.getJson('/api/v1/learning/experience', queryParameters: {
        'goal': _controller.text.trim(),
        'limit': 5,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Found similar experiences'),
              backgroundColor: MayaTheme.neonEmerald),
        );
      }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Find Similar Experience', style: MayaTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Enter a goal to find similar past experiences and their outcomes.',
          style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Goal / Task',
            hintText: 'e.g., Deploy a Flask app to VPS',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Find Similar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.neonCyan,
              foregroundColor: MayaTheme.slate900,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  final ExperienceEpisode episode;

  const _ExperienceTile({required this.episode});

  @override
  Widget build(BuildContext context) {
    final time =
        DateTime.fromMillisecondsSinceEpoch((episode.ts * 1000).round())
            .toString()
            .substring(0, 19);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  color:
                      _getOutcomeColor(episode.outcome).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  episode.outcome == 'success'
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: _getOutcomeColor(episode.outcome),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(episode.goal, style: MayaTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                            'Confidence: ${(episode.confidence * 100).toStringAsFixed(1)}%',
                            style: MayaTheme.bodySmall
                                .copyWith(color: MayaTheme.neonCyan)),
                        if (episode.similarity != null) ...[
                          const SizedBox(width: 16),
                          Text(
                              'Similarity: ${(episode.similarity! * 100).toStringAsFixed(1)}%',
                              style: MayaTheme.bodySmall
                                  .copyWith(color: MayaTheme.neonViolet)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(time,
                  style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Steps: ${episode.steps.length} | Outcome: ${episode.outcome}',
            style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Color _getOutcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'success':
        return MayaTheme.neonEmerald;
      case 'failure':
        return MayaTheme.error;
      default:
        return MayaTheme.neonOrange;
    }
  }
}

class _PromptTaskTile extends StatelessWidget {
  final String task;
  final Map<String, PromptVariant> variants;

  const _PromptTaskTile({required this.task, required this.variants});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task, style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          ...variants.entries.map((entry) {
            final variant = entry.key;
            final stats = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MayaTheme.slate700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(variant,
                            style: MayaTheme.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(
                            'OK: ${stats.ok} | Fail: ${stats.fail} | Score: ${stats.score.toStringAsFixed(2)}',
                            style: MayaTheme.bodySmall
                                .copyWith(color: Colors.white54)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: stats.score > 0.5
                          ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                          : MayaTheme.neonOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${(stats.score * 100).toStringAsFixed(1)}%',
                        style: MayaTheme.labelSmall.copyWith(
                            color: stats.score > 0.5
                                ? MayaTheme.neonEmerald
                                : MayaTheme.neonOrange)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CompressionStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompressionStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
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
