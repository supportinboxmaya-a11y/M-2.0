import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final provisionerScanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.provisionerScanFreeApis();
});

final provisionerAuditProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.provisionerGetAuditLog();
});

class ApiKeyProvisionerScreen extends ConsumerStatefulWidget {
  const ApiKeyProvisionerScreen({super.key});

  @override
  ConsumerState<ApiKeyProvisionerScreen> createState() =>
      _ApiKeyProvisionerScreenState();
}

class _ApiKeyProvisionerScreenState extends ConsumerState<ApiKeyProvisionerScreen>
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
          title:
              const Text('API Key Provisioner', style: MayaTheme.headlineSmall),
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
                ref.invalidate(provisionerScanProvider);
                ref.invalidate(provisionerAuditProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.search_rounded), text: 'Scan Free APIs'),
              Tab(icon: Icon(Icons.key_rounded), text: 'Provision Key'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Audit Log'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ScanFreeApisTab(),
            _ProvisionKeyTab(),
            _AuditTab(),
          ],
        ),
      ),
    );
  }
}

class _ScanFreeApisTab extends ConsumerWidget {
  const _ScanFreeApisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanAsync = ref.watch(provisionerScanProvider);

    return scanAsync.when(
      data: (data) {
        final apis = data['apis'] as List? ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Free API Scan', style: MayaTheme.titleLarge),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(provisionerScanProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Rescan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                    ),
                  ),
                ],
              ),
            ),
            if (apis.isEmpty)
              const Expanded(
                child: MayaEmptyState(
                  'No Free APIs Found',
                  icon: Icons.search_rounded,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: apis.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final api = apis[index];
                    return _FreeApiCard(api: api);
                  },
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error scanning APIs', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _FreeApiCard extends ConsumerWidget {
  final Map<String, dynamic> api;

  const _FreeApiCard({required this.api, super.key});

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
                child: const Icon(Icons.search_rounded, color: MayaTheme.neonCyan, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(api['name'] ?? 'Unknown API', style: MayaTheme.titleMedium),
                    Text(api['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MayaTheme.neonCyan),
                ),
                child: Text(
                  api['category'] ?? 'Uncategorized',
                  style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ApiStat(label: 'Tier', value: api['tier'] ?? 'free', color: MayaTheme.neonCyan),
              const SizedBox(width: 16),
              _ApiStat(label: 'Rate Limit', value: '${api['rateLimit'] ?? 'N/A'}/min', color: MayaTheme.neonViolet),
              const SizedBox(width: 16),
              _ApiStat(label: 'Auth', value: api['authType'] ?? 'None', color: MayaTheme.neonEmerald),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Provisioning ${api['name']}...'), backgroundColor: MayaTheme.neonCyan),
                );
              },
              icon: const Icon(Icons.key_rounded, size: 18),
              label: const Text('Provision Key'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ApiStat({required this.label, required this.value, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MayaTheme.labelSmall.copyWith(color: Colors.white38)),
        Text(value, style: MayaTheme.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ProvisionKeyTab extends ConsumerStatefulWidget {
  const _ProvisionKeyTab({super.key});

  @override
  ConsumerState<_ProvisionKeyTab> createState() => _ProvisionKeyTabState();
}

class _ProvisionKeyTabState extends ConsumerState<_ProvisionKeyTab> {
  final _apiNameController = TextEditingController();
  String _tier = 'free';
  final _configController = TextEditingController();
  bool _isProvisioning = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _apiNameController.dispose();
    _configController.dispose();
    super.dispose();
  }

  Future<void> _provision() async {
    if (_apiNameController.text.trim().isEmpty) return;

    setState(() {
      _isProvisioning = true;
      _result = null;
    });

    try {
      final config = _configController.text.isNotEmpty
          ? {'custom_config': _configController.text.trim()}
          : <String, dynamic>{};
      final result = await ref.read(mayaApiProvider).provisionerProvisionKey(
        apiName: _apiNameController.text.trim(),
        tier: _tier,
        config: config,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isProvisioning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProvisioning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
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
          const Text('Provision API Key', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Request a new API key for a supported service.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _apiNameController,
            decoration: const InputDecoration(
              labelText: 'API Name',
              hintText: 'e.g., github, stripe, openai',
            ),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _tier,
            decoration: const InputDecoration(labelText: 'Tier'),
            style: MayaTheme.bodyMedium,
            dropdownColor: MayaTheme.slate800,
            items: const [
              DropdownMenuItem(value: 'free', child: Text('Free')),
              DropdownMenuItem(value: 'starter', child: Text('Starter')),
              DropdownMenuItem(value: 'pro', child: Text('Pro')),
              DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
            ],
            onChanged: (value) => setState(() => _tier = value ?? 'free'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _configController,
            decoration: const InputDecoration(
              labelText: 'Custom Config (JSON, optional)',
              hintText: '{"region": "us-east-1"}',
            ),
            style: MayaTheme.bodyMedium,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProvisioning ? null : _provision,
              icon: _isProvisioning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.key_rounded),
              label: Text(_isProvisioning ? 'Provisioning...' : 'Provision Key'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MayaTheme.neonEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MayaTheme.neonEmerald.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: MayaTheme.neonEmerald, size: 24),
                      const SizedBox(width: 12),
                      Text('Key Provisioned', style: MayaTheme.titleMedium.copyWith(color: MayaTheme.neonEmerald)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _result!['apiKey']?.toString() ?? 'N/A',
                    style: MayaTheme.bodySmall.copyWith(fontFamily: 'monospace', color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text('Store this key securely - it will not be shown again.', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  if (_result!['expiresAt'] != null)
                    Text('Expires: ${_result!['expiresAt']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuditTab extends ConsumerWidget {
  const _AuditTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(provisionerAuditProvider);

    return auditAsync.when(
      data: (data) {
        final logs = data['auditLog'] as List? ?? [];
        if (logs.isEmpty) {
          return const MayaEmptyState(
            'No Audit Logs',
            icon: Icons.history_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final log = logs[index];
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
                        child: const Icon(Icons.key_rounded, color: MayaTheme.neonCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['action'] ?? 'Unknown Action', style: MayaTheme.titleSmall),
                            Text(log['apiName'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                          ],
                        ),
                      ),
                      Text(log['timestamp']?.toString().substring(0, 19) ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white38, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('User: ${log['userId'] ?? 'system'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                      const Spacer(),
                      Text('Tier: ${log['tier'] ?? 'free'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                    ],
                  ),
                ],
              ));
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
            Text('Error loading audit log', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}