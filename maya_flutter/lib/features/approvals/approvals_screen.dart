import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import 'approvals_models.dart';
import 'approvals_providers.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(approvalsProvider(null));
        ref.invalidate(approvalsProvider('pending'));
        ref.invalidate(approvalsProvider('approved'));
        ref.invalidate(approvalsProvider('rejected'));
        ref.invalidate(approvalModeProvider);
        ref.invalidate(pendingApprovalsCountProvider);
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
    final countAsync = ref.watch(pendingApprovalsCountProvider);
    final modeAsync = ref.watch(approvalModeProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Approvals Center', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            countAsync.when(
              data: (count) => count > 0
                  ? Stack(
                      alignment: Alignment.topRight,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_rounded),
                          onPressed: () {
                            _tabController.animateTo(0);
                          },
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: MayaTheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: MayaTheme.labelSmall
                                  .copyWith(color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      onPressed: () {},
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings_rounded),
              onSelected: (value) async {
                if (value == 'mode') {
                  final current = await ref.read(approvalModeProvider.future);
                  _showModeDialog(context, ref, current.mode);
                } else if (value == 'refresh') {
                  ref.invalidate(approvalsProvider(null));
                  ref.invalidate(pendingApprovalsCountProvider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mode',
                  child: Row(
                    children: [
                      Icon(Icons.rule_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Approval Mode'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.pending_actions_rounded), text: 'Pending'),
              Tab(icon: Icon(Icons.check_circle_rounded), text: 'Approved'),
              Tab(icon: Icon(Icons.cancel_rounded), text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ApprovalsListTab(status: 'pending'),
            _ApprovalsListTab(status: 'approved'),
            _ApprovalsListTab(status: 'rejected'),
          ],
        ),
      ),
    );
  }

  void _showModeDialog(
      BuildContext context, WidgetRef ref, String currentMode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Approval Mode', style: MayaTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Auto (low-risk auto-apply)',
                  style: MayaTheme.bodyMedium),
              value: 'auto',
              groupValue: currentMode,
              activeColor: MayaTheme.neonCyan,
              onChanged: (v) async {
                Navigator.pop(context);
                await _setMode(ref, v!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Human (all require approval)',
                  style: MayaTheme.bodyMedium),
              value: 'human',
              groupValue: currentMode,
              activeColor: MayaTheme.neonCyan,
              onChanged: (v) async {
                Navigator.pop(context);
                await _setMode(ref, v!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Skip (no approvals)',
                  style: MayaTheme.bodyMedium),
              value: 'skip',
              groupValue: currentMode,
              activeColor: MayaTheme.neonCyan,
              onChanged: (v) async {
                Navigator.pop(context);
                await _setMode(ref, v!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _setMode(WidgetRef ref, String mode) async {
    try {
      final api = ref.read(mayaApiProvider);
      await api.postJson('/api/v1/approvals/mode', data: {'mode': mode});
      ref.invalidate(approvalModeProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Approval mode set to $mode'),
              backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to set mode: $e'),
              backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _ApprovalsListTab extends ConsumerWidget {
  final String status;

  const _ApprovalsListTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalsProvider(status));

    return approvalsAsync.when(
      data: (data) => data.approvals.isEmpty
          ? _emptyState(
              _emptyTitle(status),
              _emptySubtitle(status),
              _emptyIcon(status),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.approvals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final approval = data.approvals[index];
                return _ApprovalCard(approval: approval);
              },
            ),
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => _errorState(err.toString()),
    );
  }

  String _emptyTitle(String status) {
    switch (status) {
      case 'pending':
        return 'No Pending Approvals';
      case 'approved':
        return 'No Approved Items';
      case 'rejected':
        return 'No Rejected Items';
      default:
        return 'No Approvals';
    }
  }

  String _emptySubtitle(String status) {
    switch (status) {
      case 'pending':
        return 'All clear! No items awaiting your decision';
      case 'approved':
        return 'Approved items will appear here';
      case 'rejected':
        return 'Rejected items will appear here';
      default:
        return 'Approval history will appear here';
    }
  }

  IconData _emptyIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.rule_rounded;
    }
  }

  Widget _emptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MayaTheme.neonCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: MayaTheme.neonCyan, size: 48),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: MayaTheme.bodyLarge.copyWith(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
      const SizedBox(height: 16),
      Text('Error loading approvals',
          style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
      const SizedBox(height: 8),
      Text(error, style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
    ]));
  }
}

class _ApprovalCard extends ConsumerWidget {
  final ApprovalItem approval;

  const _ApprovalCard({required this.approval});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    IconData statusIcon;
    switch (approval.status) {
      case 'approved':
        statusColor = MayaTheme.neonEmerald;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = MayaTheme.error;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'pending':
        statusColor = MayaTheme.neonOrange;
        statusIcon = Icons.pending_rounded;
        break;
      default:
        statusColor = Colors.white38;
        statusIcon = Icons.help_rounded;
    }

    Color riskColor;
    switch (approval.riskLevel.toLowerCase()) {
      case 'critical':
        riskColor = MayaTheme.error;
        break;
      case 'high':
        riskColor = MayaTheme.neonOrange;
        break;
      case 'medium':
        riskColor = MayaTheme.neonViolet;
        break;
      case 'low':
        riskColor = MayaTheme.neonCyan;
        break;
      default:
        riskColor = Colors.white54;
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
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(approval.title, style: MayaTheme.titleMedium),
                    Text(approval.type,
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
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
                child: Text(approval.status.toUpperCase(),
                    style: MayaTheme.labelSmall.copyWith(color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(approval.description, style: MayaTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _RiskChip(
                  label: 'Risk',
                  value: approval.riskLevel.toUpperCase(),
                  color: riskColor),
              const SizedBox(width: 8),
              if (approval.payload != null) ...[
                const SizedBox(width: 8),
                _InfoChip(
                    label: 'Payload',
                    value: approval.payload!.keys.join(', '),
                    color: MayaTheme.neonCyan),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (approval.status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _decide(context, ref, approval.id, false),
                    icon: const Icon(Icons.cancel_rounded,
                        color: MayaTheme.error),
                    label: const Text('Reject',
                        style: TextStyle(color: MayaTheme.error)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MayaTheme.error,
                      side: BorderSide(
                          color: MayaTheme.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _decide(context, ref, approval.id, true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonEmerald,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _decide(BuildContext context, WidgetRef ref, String approvalId, bool approve) async {
    try {
      final api = ref.read(mayaApiProvider);
      final endpoint = approve
          ? '/api/v1/approvals/$approvalId/approve'
          : '/api/v1/approvals/$approvalId/reject';
      final result = await api.postJson(endpoint, data: {});

      if (context.mounted) {
        ref.invalidate(approvalsProvider(null));
        ref.invalidate(approvalsProvider('pending'));
        ref.invalidate(approvalsProvider('approved'));
        ref.invalidate(approvalsProvider('rejected'));
        ref.invalidate(pendingApprovalsCountProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Approved' : 'Rejected'),
            backgroundColor:
                approve ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}

class _RiskChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RiskChip({
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
