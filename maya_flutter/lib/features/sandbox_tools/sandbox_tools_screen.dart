import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final sandboxExecuteProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final api = ref.watch(mayaApiProvider);
  return api.sandboxExecute(
    code: params['code'] ?? '',
    language: params['language'] ?? 'python',
    timeout: params['timeout'] ?? 30,
  );
});

final sandboxHistoryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.sandboxGetHistory();
});

class SandboxToolsScreen extends ConsumerStatefulWidget {
  const SandboxToolsScreen({super.key});

  @override
  ConsumerState<SandboxToolsScreen> createState() => _SandboxToolsScreenState();
}

class _SandboxToolsScreenState extends ConsumerState<SandboxToolsScreen>
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
          title: const Text('Sandbox Tools', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(sandboxHistoryProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.code_rounded), text: 'Execute'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _SandboxExecuteTab(),
            _SandboxHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _SandboxExecuteTab extends ConsumerStatefulWidget {
  const _SandboxExecuteTab();

  @override
  ConsumerState<_SandboxExecuteTab> createState() => _SandboxExecuteTabState();
}

class _SandboxExecuteTabState extends ConsumerState<_SandboxExecuteTab> {
  final _codeController = TextEditingController(text: 'print("Hello from Maya Sandbox!")');
  final _languageController = TextEditingController(text: 'python');
  final _timeoutController = TextEditingController(text: '30');
  bool _isExecuting = false;
  Map<String, dynamic>? _lastResult;

  @override
  void dispose() {
    _codeController.dispose();
    _languageController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  Future<void> _executeCode() async {
    setState(() {
      _isExecuting = true;
      _lastResult = null;
    });
    try {
      final result = await ref.read(mayaApiProvider).sandboxExecute(
        code: _codeController.text,
        language: _languageController.text,
        timeout: int.tryParse(_timeoutController.text) ?? 30,
      );
      if (mounted) {
        setState(() => _lastResult = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  Widget _buildResultWidget(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Result', style: MayaTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: MayaTheme.glassCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    result['success'] == true ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: result['success'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result['success'] == true ? 'Success' : 'Error',
                    style: MayaTheme.titleSmall.copyWith(
                      color: result['success'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (result['stdout'] != null && result['stdout'].toString().isNotEmpty)
                Text('stdout:\n${result['stdout']}', style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace', color: Colors.white70)),
              if (result['stderr'] != null && result['stderr'].toString().isNotEmpty)
                Text('stderr:\n${result['stderr']}', style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace', color: MayaTheme.error)),
              if (result['output'] != null)
                Text('Output: ${result['output']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultWidget = _lastResult != null ? _buildResultWidget(_lastResult!) : const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sandbox Execute', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Execute code in a secure sandbox environment',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Code',
              hintText: 'Enter code to execute',
              border: OutlineInputBorder(),
            ),
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _languageController,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    hintText: 'python',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _timeoutController,
                  decoration: const InputDecoration(
                    labelText: 'Timeout (s)',
                    hintText: '30',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExecuting ? null : _executeCode,
              icon: _isExecuting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_isExecuting ? 'Executing...' : 'Execute Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          resultWidget,
        ],
      ),
    );
  }
}

class _SandboxHistoryTab extends ConsumerWidget {
  const _SandboxHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sandboxHistoryProvider);

    return historyAsync.when(
      data: (data) {
        final history = data['history'] as List? ?? [];
        if (history.isEmpty) {
          return const MayaEmptyState(
            'No execution history yet',
            icon: Icons.history_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final item = history[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Row(
                children: [
                  const Icon(Icons.code_rounded, color: MayaTheme.neonViolet, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['language'] ?? 'python', style: MayaTheme.titleMedium),
                        Text(item['code']?.toString().substring(0, 50) ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(item['timestamp']?.toString().substring(0, 19) ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading history', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}