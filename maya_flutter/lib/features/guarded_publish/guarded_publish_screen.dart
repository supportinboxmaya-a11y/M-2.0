import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final guardedPendingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.guardedListPending();
});

final guardedHistoryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.guardedListHistory();
});

class GuardedPublishScreen extends ConsumerStatefulWidget {
  const GuardedPublishScreen({super.key});

  @override
  ConsumerState<GuardedPublishScreen> createState() =>
      _GuardedPublishScreenState();
}

class _GuardedPublishScreenState extends ConsumerState<GuardedPublishScreen>
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
          title: const Text('Guarded Publish', style: MayaTheme.headlineSmall),
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
                ref.invalidate(guardedPendingProvider);
                ref.invalidate(guardedHistoryProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.pending_actions_rounded), text: 'Pending'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
              Tab(icon: Icon(Icons.add_rounded), text: 'New Request'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _PendingTab(),
            _HistoryTab(),
            _NewRequestTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(guardedPendingProvider);

    return pendingAsync.map(
      data: (data) {
        final requests = data.value['requests'] as List? ?? [];
        if (requests.isEmpty) {
          return const MayaEmptyState(
            'No Pending Requests',
            icon: Icons.pending_actions_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final request = requests[index];
            return _PendingRequestCard(request: request);
          },
        );
      },
      loading: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading pending requests', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> request;

  const _PendingRequestCard({required this.request, super.key});

  @override
  ConsumerState<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends ConsumerState<_PendingRequestCard> {
  bool _isProcessing = false;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(mayaApiProvider).guardedApproveRequest(widget.request['id'] ?? '');
      ref.invalidate(guardedPendingProvider);
      ref.invalidate(guardedHistoryProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _showReasonDialog(context);
    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(mayaApiProvider).guardedRejectRequest(widget.request['id'] ?? '', reason: reason);
      ref.invalidate(guardedPendingProvider);
      ref.invalidate(guardedHistoryProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showReasonDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Rejection Reason', style: MayaTheme.titleMedium),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason...'),
          style: MayaTheme.bodyMedium,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: MayaTheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
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
                  color: MayaTheme.neonOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pending_actions_rounded, color: MayaTheme.neonOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req['title'] ?? 'Untitled Request', style: MayaTheme.titleMedium),
                    Text(req['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MayaTheme.neonOrange),
                ),
                child: Text(
                  'PENDING',
                  style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Environment: ${req['targetEnvironment'] ?? 'production'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              const Spacer(),
              Text('Created: ${req['createdAt']?.toString().substring(0, 19) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _reject,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MayaTheme.error,
                    side: BorderSide(color: MayaTheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _approve,
                  icon: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(_isProcessing ? 'Approving...' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MayaTheme.neonEmerald,
                    foregroundColor: MayaTheme.slate900,
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

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(guardedHistoryProvider);

    return historyAsync.map(
      data: (data) {
        final requests = data.value['requests'] as List? ?? [];
        if (requests.isEmpty) {
          return const MayaEmptyState(
            'No History',
            icon: Icons.history_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final request = requests[index];
            return _HistoryRequestCard(request: request);
          },
        );
      },
      loading: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading history', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _HistoryRequestCard extends ConsumerWidget {
  final Map<String, dynamic> request;

  const _HistoryRequestCard({required this.request, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final req = request;
    Color statusColor;
    switch (req['status']?.toLowerCase()) {
      case 'approved':
        statusColor = MayaTheme.neonEmerald;
        break;
      case 'rejected':
        statusColor = MayaTheme.error;
        break;
      default:
        statusColor = Colors.white54;
    }

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
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  req['status'] == 'approved' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req['title'] ?? 'Untitled Request', style: MayaTheme.titleMedium),
                    Text(req['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  req['status']?.toUpperCase() ?? 'UNKNOWN',
                  style: MayaTheme.labelSmall.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Environment: ${req['targetEnvironment'] ?? 'production'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              const Spacer(),
              Text('Decided: ${req['decidedAt']?.toString().substring(0, 19) ?? req['createdAt']?.toString().substring(0, 19) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
          if (req['reason'] != null && req['reason'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Reason: ${req['reason']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _NewRequestTab extends ConsumerStatefulWidget {
  const _NewRequestTab({super.key});

  @override
  ConsumerState<_NewRequestTab> createState() => _NewRequestTabState();
}

class _NewRequestTabState extends ConsumerState<_NewRequestTab> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _targetEnvironment = 'production';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please fill in all fields'), backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(mayaApiProvider).guardedCreateRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        targetEnvironment: _targetEnvironment,
        payload: {},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Request created successfully'), backgroundColor: MayaTheme.neonEmerald),
        );
        _titleController.clear();
        _descriptionController.clear();
        ref.invalidate(guardedPendingProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create New Guarded Request', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Submit a new publish request for review and approval.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Brief title for the request',
            ),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Detailed description of the change',
            ),
            style: MayaTheme.bodyMedium,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _targetEnvironment,
            decoration: const InputDecoration(labelText: 'Target Environment'),
            style: MayaTheme.bodyMedium,
            dropdownColor: MayaTheme.slate800,
            items: const [
              DropdownMenuItem(value: 'staging', child: Text('Staging')),
              DropdownMenuItem(value: 'production', child: Text('Production')),
            ],
            onChanged: (value) => setState(() => _targetEnvironment = value ?? 'production'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}