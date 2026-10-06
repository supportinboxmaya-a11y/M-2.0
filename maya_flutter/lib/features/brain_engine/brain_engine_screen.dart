import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import 'brain_engine_models.dart';
import 'brain_engine_providers.dart';

class BrainEngineScreen extends ConsumerStatefulWidget {
  const BrainEngineScreen({super.key});

  @override
  ConsumerState<BrainEngineScreen> createState() => _BrainEngineScreenState();
}

class _BrainEngineScreenState extends ConsumerState<BrainEngineScreen> {
  final _goalController =
      TextEditingController(text: 'Build a todo app with Flutter');

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Brain Engine', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Input Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Goal Analysis', style: MayaTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _goalController,
                      style: MayaTheme.bodyMedium,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter a goal to analyze...',
                        hintStyle: MayaTheme.bodyMedium
                            .copyWith(color: Colors.white38),
                        filled: true,
                        fillColor: MayaTheme.slate700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _analyzeGoal,
                        icon: const Icon(Icons.psychology_rounded),
                        label: const Text('Analyze Goal'),
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

              // Analysis Result
              _buildAnalysisSection(),

              const SizedBox(height: 24),

              // Graph Builder Section
              _buildGraphSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeGoal() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;

    try {
      final api = ref.read(mayaApiProvider);
      final result =
          await api.postJson('/api/v1/brain/analyze', data: {'goal': goal});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Analysis complete: ${result['complexity']} (${result['estimated_steps']} steps)'),
            backgroundColor: MayaTheme.neonEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Analysis failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Future<void> _buildGraphFromAnalysis(BrainAnalyzeResponse analysis) async {
    // Convert sub-goals to steps for graph building
    final subGoals = analysis.subGoals;
    final steps = subGoals.asMap().entries.map((entry) {
      final index = entry.key;
      final subGoal = entry.value;
      return {
        'description': subGoal,
        'tool': analysis.suggestedTools.isNotEmpty
            ? analysis.suggestedTools.first
            : 'llm',
        'depends_on': index > 0 ? [index - 1] : [],
      };
    }).toList();

    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson('/api/v1/brain/graph/build', data: {'steps': steps});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Graph built from analysis'),
              backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Graph build failed: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }

  Widget _buildAnalysisSection() {
    final goal = _goalController.text.trim();
    final analysisAsync = ref.watch(brainAnalyzeProvider(goal));

    return analysisAsync.when(
      data: (analysis) => _AnalysisResultCard(
        analysis: analysis,
        onBuildGraph: () => _buildGraphFromAnalysis(analysis),
      ),
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: MayaTheme.glassCard(),
        child: const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
        ),
      ),
      error: (err, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: MayaTheme.glassCard(),
        child: Column(
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Analysis error',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Task Graph', style: MayaTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: MayaTheme.glassCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a goal above and tap "Analyze Goal" to see the task graph visualization.',
                style: MayaTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'The graph will show:',
                style: MayaTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              _GraphFeatureRow(
                  icon: Icons.circle_rounded,
                  text: 'Nodes = steps/tasks',
                  color: MayaTheme.neonCyan),
              _GraphFeatureRow(
                  icon: Icons.arrow_forward_rounded,
                  text: 'Edges = dependencies',
                  color: MayaTheme.neonViolet),
              _GraphFeatureRow(
                  icon: Icons.color_lens_rounded,
                  text: 'Colors = state (pending/running/done/failed)',
                  color: MayaTheme.neonEmerald),
              _GraphFeatureRow(
                  icon: Icons.build_rounded,
                  text: 'Tool/agent assignments per node',
                  color: MayaTheme.neonOrange),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalysisResultCard extends ConsumerWidget {
  final BrainAnalyzeResponse analysis;
  final VoidCallback onBuildGraph;

  const _AnalysisResultCard(
      {required this.analysis, required this.onBuildGraph});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subGoals = analysis.subGoals;
    final suggestedTools = analysis.suggestedTools;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            Text('Analysis Complete',
                style: MayaTheme.labelMedium
                    .copyWith(color: MayaTheme.neonEmerald)),
          ]),
          const SizedBox(height: 8),
          Text('Complexity: ${analysis.complexity}',
              style: MayaTheme.bodyMedium),
          Text('Estimated Steps: ${analysis.estimatedSteps}',
              style: MayaTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Sub-Goals:', style: MayaTheme.titleSmall),
          const SizedBox(height: 8),
          ...analysis.subGoals
              .map<Widget>((goal) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: MayaTheme.neonCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(goal.toString(),
                              style: MayaTheme.bodyMedium)),
                    ]),
                  ))
              .toList(),
          const SizedBox(height: 16),
          Text('Suggested Tools: ${suggestedTools.join(', ')}',
              style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onBuildGraph,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Build Graph from Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _GraphFeatureRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: MayaTheme.bodySmall),
        ],
      ),
    );
  }
}
