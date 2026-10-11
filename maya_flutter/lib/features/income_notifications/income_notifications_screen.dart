import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final notificationsApprovalsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.notificationListApprovals(limit: 50);
});

final notificationsTemplatesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.notificationListTemplates();
});

final notificationsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.notificationGetStats();
});

final notificationsChannelsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.notificationGetChannels();
});

class IncomeNotificationsScreen extends ConsumerStatefulWidget {
  const IncomeNotificationsScreen({super.key});

  @override
  ConsumerState<IncomeNotificationsScreen> createState() =>
      _IncomeNotificationsScreenState();
}

class _IncomeNotificationsScreenState extends ConsumerState<IncomeNotificationsScreen>
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
          title: const Text('Income Notifications', style: MayaTheme.headlineSmall),
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
                ref.invalidate(notificationsApprovalsProvider);
                ref.invalidate(notificationsTemplatesProvider);
                ref.invalidate(notificationsStatsProvider);
                ref.invalidate(notificationsChannelsProvider);
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
              Tab(icon: Icon(Icons.approval_rounded), text: 'Approvals'),
              Tab(icon: Icon(Icons.campaign_rounded), text: 'Templates'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ApprovalsTab(),
            _TemplatesTab(),
            _StatsTab(),
          ],
        ),
      ),
    );
  }
}

class _ApprovalsTab extends ConsumerWidget {
  const _ApprovalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(notificationsApprovalsProvider);

    return approvalsAsync.when(
      data: (data) {
        final approvals = data['approvals'] as List? ?? [];
        if (approvals.isEmpty) {
          return const MayaEmptyState(
            'No Approvals',
            icon: Icons.approval_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: approvals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final approval = approvals[index];
            return _ApprovalCard(approval: approval);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading approvals', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  final Map<String, dynamic> approval;

  const _ApprovalCard({required this.approval});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  color: _getStatusColor(approval['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.approval_rounded, color: _getStatusColor(approval['status']), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(approval['title'] ?? '', style: MayaTheme.titleMedium),
                    Text(approval['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(approval['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(approval['status'])),
                ),
                child: Text(
                  approval['status']?.toString().toUpperCase() ?? 'PENDING',
                  style: MayaTheme.labelSmall.copyWith(color: _getStatusColor(approval['status'])),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MayaTheme.neonViolet),
                ),
                child: Text(approval['channel']?.toString().toUpperCase() ?? 'WEBHOOK', style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
              ),
              const Spacer(),
              Text(approval['createdAt']?.toString().substring(0, 19) ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 12),
          if (approval['status'] == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final api = ref.read(mayaApiProvider);
                      try {
                        await api.notificationDecideApproval(approval['id'], false, decidedBy: 'user', reason: 'Rejected via UI');
                        ref.invalidate(notificationsApprovalsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Approval rejected'), backgroundColor: MayaTheme.error),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel_rounded, color: MayaTheme.error),
                    label: const Text('Reject', style: TextStyle(color: MayaTheme.error)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MayaTheme.error,
                      side: BorderSide(color: MayaTheme.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final api = ref.read(mayaApiProvider);
                      try {
                        await api.notificationDecideApproval(approval['id'], true, decidedBy: 'user', reason: 'Approved via UI');
                        ref.invalidate(notificationsApprovalsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Approval granted'), backgroundColor: MayaTheme.neonEmerald),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonEmerald,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Color _getStatusColor(String? status) {
      switch (status?.toLowerCase()) {
        case 'approved':
          return MayaTheme.neonEmerald;
        case 'pending':
          return MayaTheme.neonOrange;
        case 'rejected':
          return MayaTheme.error;
        default:
          return Colors.white54;
      }
    }
  }
}

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(notificationsTemplatesProvider);

    return templatesAsync.when(
      data: (data) {
        final templates = data['templates'] as List? ?? [];
        if (templates.isEmpty) {
          return const MayaEmptyState(
            'No Templates',
            icon: Icons.campaign_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: templates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final template = templates[index];
            return _TemplateCard(template: template);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading templates', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final Map<String, dynamic> template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded, color: MayaTheme.neonCyan, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template['name'] ?? '', style: MayaTheme.titleMedium),
                    Text(template['channel']?.toString() ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Subject: ${template['subjectTemplate'] ?? ''}', style: MayaTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(template['bodyTemplate'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: MayaTheme.neonViolet.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MayaTheme.neonViolet),
            ),
            child: Text('Channels: ${template['channels']?.toString() ?? ''}', style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonViolet)),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(notificationsStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notification Statistics', style: MayaTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Overview of notification delivery performance',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _NotifStatCard(
                    label: 'Total Sent',
                    value: stats['total_notifications']?.toString() ?? '0',
                    color: MayaTheme.neonCyan,
                    icon: Icons.send_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NotifStatCard(
                    label: 'Delivered',
                    value: stats['by_status']?.firstWhere(
                      (r) => r['status'] == 'delivered',
                      orElse: () => {'count': 0})['count']?.toString() ?? '0',
                    color: MayaTheme.neonEmerald,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NotifStatCard(
                    label: 'Failed',
                    value: stats['by_status']?.firstWhere(
                      (r) => r['status'] == 'failed',
                      orElse: () => {'count': 0})['count']?.toString() ?? '0',
                    color: MayaTheme.error,
                    icon: Icons.error_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NotifStatCard(
                    label: 'Pending',
                    value: stats['by_status']?.firstWhere(
                      (r) => r['status'] == 'pending',
                      orElse: () => {'count': 0})['count']?.toString() ?? '0',
                    color: MayaTheme.neonOrange,
                    icon: Icons.hourglass_empty_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('By Type', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            ...((stats['by_type'] as List? ?? []).map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t['type'] ?? '', style: MayaTheme.bodyMedium),
                  ),
                  Text('${t['count'] ?? 0}', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
                ],
              ),
            )).toList(),
            const SizedBox(height: 24),
            const Text('By Priority', style: MayaTheme.titleMedium),
            const SizedBox(height: 12),
            ...(stats['by_priority'] as List? ?? []).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Row(
                children: [
                  Text(p['priority'] ?? '', style: MayaTheme.bodyMedium),
                  const Spacer(),
                  Text('${p['count'] ?? 0}', style: MayaTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading stats', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _NotifStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _NotifStatCard({
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
          Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    }
  }
}