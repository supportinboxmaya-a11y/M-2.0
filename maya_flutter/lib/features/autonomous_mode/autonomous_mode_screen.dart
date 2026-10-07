import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../flags/flags_screen.dart';
import 'autonomous_mode_models.dart';
import 'autonomous_mode_providers.dart';

class AutonomousModeScreen extends ConsumerStatefulWidget {
  const AutonomousModeScreen({super.key});

  @override
  ConsumerState<AutonomousModeScreen> createState() =>
      _AutonomousModeScreenState();
}

class _AutonomousModeScreenState extends ConsumerState<AutonomousModeScreen> {
  Timer? _refreshTimer;
  bool _isRunning = false;
  String _currentGoal = '';
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(autonomousStatusProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(autonomousStatusProvider);
    final flagsAsync = ref.watch(flagsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Autonomous Mode', style: MayaTheme.headlineSmall),
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
                ref.invalidate(autonomousStatusProvider);
                ref.invalidate(flagsProvider);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MayaTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: MayaTheme.error.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: MayaTheme.error, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '⚠️ Autonomous Mode executes goals without step-by-step approval. Maya will plan, use tools, and iterate automatically. Ensure you trust the goal and have set appropriate limits.',
                            style: MayaTheme.bodyMedium
                                .copyWith(color: MayaTheme.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildMainToggle(),
              const SizedBox(height: 24),
              _buildPermissionsSection(flagsAsync),
              const SizedBox(height: 24),
              _buildLiveStatus(statusAsync),
              const SizedBox(height: 24),
              _buildRunSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: MayaTheme.glassCardGlow(glowColor: MayaTheme.neonCyan),
      child: Column(
        children: [
          const Text('Autonomous Mode', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'When enabled, Maya can execute goals end-to-end without manual approval for each step.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, _) {
              final flags = ref.watch(flagsProvider);
              final isEnabled = flags.valueOrNull?.flags['autonomous'] ?? false;

              return Switch(
                value: isEnabled,
                activeThumbColor: MayaTheme.neonCyan,
                activeTrackColor: MayaTheme.neonCyan.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white12,
                thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Icon(Icons.check_rounded,
                        color: MayaTheme.slate900, size: 18);
                  }
                  return const Icon(Icons.close_rounded,
                      color: Colors.white38, size: 18);
                }),
                onChanged: (value) => _showSafetyDialog(value),
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) {
              final flags = ref.watch(flagsProvider);
              final isEnabled = flags.valueOrNull?.flags['autonomous'] ?? false;
              return Text(
                isEnabled
                    ? 'ENABLED — Maya runs autonomously'
                    : 'DISABLED — Manual approval required',
                style: MayaTheme.bodyMedium.copyWith(
                  color:
                      isEnabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSafetyDialog(bool newValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: Row(
          children: [
            Icon(newValue ? Icons.warning_amber_rounded : Icons.info_rounded,
                color: newValue ? MayaTheme.error : MayaTheme.neonCyan),
            const SizedBox(width: 8),
            Text(
                newValue
                    ? 'Enable Autonomous Mode?'
                    : 'Disable Autonomous Mode?',
                style: MayaTheme.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newValue
                  ? 'Maya will execute goals autonomously. This means:\n'
                      '• Maya plans and decomposes goals\n'
                      '• Maya selects and uses tools automatically\n'
                      '• Maya iterates on failures without asking\n'
                      '• Dangerous tools require approve_dangerous flag\n\n'
                      'Ensure you have set FLAG_AUTONOMOUS=true on the server.'
                  : 'Maya will require manual approval for each step.',
              style: MayaTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text('Are you sure you want to continue?',
                style: MayaTheme.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _toggleAutonomousMode(newValue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newValue ? MayaTheme.error : MayaTheme.neonCyan,
              foregroundColor: newValue ? Colors.white : MayaTheme.slate900,
            ),
            child: Text(newValue ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAutonomousMode(bool enabled) async {
    try {
      final api = ref.read(mayaApiProvider);
      await api
          .postJson('/api/v1/autonomous/toggle', data: {'enabled': enabled});
      if (mounted) {
        ref.invalidate(flagsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? 'Autonomous mode enabled'
                : 'Autonomous mode disabled'),
            backgroundColor:
                enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildPermissionsSection(AsyncValue<FlagsSnapshot> flagsAsync) {
    return flagsAsync.when(
      data: (flags) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: MayaTheme.glassCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Permissions & Scope', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            _PermissionRow(
              label: 'Autonomous Execution',
              enabled: flags.flags['autonomous'] ?? false,
              description: 'Maya can run goals end-to-end',
            ),
            _PermissionRow(
              label: 'Tool Execution',
              enabled: flags.flags['tool_execute'] ?? false,
              description: 'Remote tool execution allowed',
            ),
            _PermissionRow(
              label: 'Cognition Autorun',
              enabled: flags.flags['cognition_autorun'] ?? false,
              description: 'Cognitive cycles execute (not just propose)',
            ),
            _PermissionRow(
              label: 'Deploy Pipeline',
              enabled: flags.flags['deploy_pipeline_enabled'] ?? false,
              description: 'Build → Deploy pipeline active',
            ),
            _PermissionRow(
              label: 'App Monitor',
              enabled: flags.flags['app_monitor_enabled'] ?? false,
              description: 'Remote app health monitoring',
            ),
            _PermissionRow(
              label: 'Research Engine',
              enabled: flags.flags['research_engine_enabled'] ?? false,
              description: 'Web research & analysis enabled',
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildLiveStatus(AsyncValue<dynamic> statusAsync) {
    return statusAsync.when(
      data: (status) {
        if (!_isRunning && _currentGoal.isEmpty) {
          return const SizedBox();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isRunning
                ? MayaTheme.neonCyan.withValues(alpha: 0.15)
                : MayaTheme.neonEmerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isRunning
                  ? MayaTheme.neonCyan.withValues(alpha: 0.5)
                  : MayaTheme.neonEmerald.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isRunning
                        ? Icons.play_circle_rounded
                        : Icons.check_circle_rounded,
                    color:
                        _isRunning ? MayaTheme.neonCyan : MayaTheme.neonEmerald,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isRunning ? 'Autonomous Run Active' : 'Last Run Completed',
                    style: MayaTheme.titleMedium.copyWith(
                      color: _isRunning
                          ? MayaTheme.neonCyan
                          : MayaTheme.neonEmerald,
                    ),
                  ),
                  const Spacer(),
                  if (_isRunning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currentGoal.isNotEmpty) ...[
                Text('Goal: $_currentGoal', style: MayaTheme.bodyMedium),
                const SizedBox(height: 4),
              ],
              if (_currentStatus.isNotEmpty)
                Text('Status: $_currentStatus',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildRunSection() {
    final goalController =
        TextEditingController(text: 'Build a REST API with FastAPI');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Run Autonomous Goal', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: goalController,
            style: MayaTheme.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter a goal for autonomous execution...',
              hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _runAutonomous(goalController.text.trim()),
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: const Text('Run Autonomously'),
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
                  onPressed: () => _runAutonomous(goalController.text.trim(),
                      approveDangerous: true),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Run (Dangerous)'),
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
          const SizedBox(height: 12),
          const Text(
            '⚠️ Normal run: dangerous tools blocked. Dangerous run: approve_dangerous=true',
            style: MayaTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _runAutonomous(String goal,
      {bool approveDangerous = false}) async {
    if (goal.isEmpty) return;

    setState(() {
      _isRunning = true;
      _currentGoal = goal;
      _currentStatus = 'Starting...';
    });

    try {
      final api = ref.read(mayaApiProvider);
      final result = await api.postJson(
        '/api/v1/autonomous/run',
        data: {
          'goal': goal,
          'approve_dangerous': approveDangerous,
        },
      );

      if (mounted) {
        setState(() {
          _isRunning = false;
          _currentStatus = result['status'] ?? 'Unknown';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autonomous run: ${result['status']}'),
            backgroundColor: result['status'] == 'completed'
                ? MayaTheme.neonEmerald
                : MayaTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _currentStatus = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autonomous run failed: $e'),
            backgroundColor: MayaTheme.error,
          ),
        );
      }
    }
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final String description;

  const _PermissionRow({
    required this.label,
    required this.enabled,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: enabled
                  ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                  : MayaTheme.neonOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                enabled ? Icons.check_rounded : Icons.close_rounded,
                color: enabled ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: MayaTheme.bodyMedium),
                Text(description,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
