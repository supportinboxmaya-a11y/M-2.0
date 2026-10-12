import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final enterpriseRolesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.enterpriseListRoles();
});

final enterpriseOrgsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.enterpriseListOrgs();
});

final enterpriseApiKeysProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.enterpriseListApiKeys();
});

final enterpriseAuditLogProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.enterpriseGetAuditLog();
});

final enterpriseDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.enterpriseGetDashboard();
});

class EnterpriseScreen extends ConsumerStatefulWidget {
  const EnterpriseScreen({super.key});

  @override
  ConsumerState<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends ConsumerState<EnterpriseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          title: const Text('Enterprise Layer', style: MayaTheme.headlineSmall),
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
                ref.invalidate(enterpriseRolesProvider);
                ref.invalidate(enterpriseOrgsProvider);
                ref.invalidate(enterpriseApiKeysProvider);
                ref.invalidate(enterpriseAuditLogProvider);
                ref.invalidate(enterpriseDashboardProvider);
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
              Tab(icon: Icon(Icons.security_rounded), text: 'RBAC'),
              Tab(icon: Icon(Icons.groups_rounded), text: 'Organizations'),
              Tab(icon: Icon(Icons.key_rounded), text: 'API Keys'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Audit Log'),
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _RBTab(),
            _OrgsTab(),
            _ApiKeysTab(),
            _AuditTab(),
            _DashboardTab(),
          ],
        ),
      ),
    );
  }
}

class _RBTab extends ConsumerStatefulWidget {
  const _RBTab({super.key});

  @override
  ConsumerState<_RBTab> createState() => _RBTabState();
}

class _RBTabState extends ConsumerState<_RBTab> {
  final _nameController = TextEditingController();
  final _permissionsController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _permissionsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRole() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isCreating = true);
    try {
      final permissions = _permissionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await ref.read(mayaApiProvider).enterpriseCreateRole(
        name: _nameController.text.trim(),
        permissions: permissions,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );
      _nameController.clear();
      _permissionsController.clear();
      _descriptionController.clear();
      ref.invalidate(enterpriseRolesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(enterpriseRolesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Role-Based Access Control', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Manage roles and permissions for enterprise access control.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          rolesAsync.when(
            data: (data) {
              final roles = data['roles'] as List? ?? [];
              if (roles.isEmpty) {
                return const MayaEmptyState(
                  'No roles found',
                  icon: Icons.security_rounded,
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: roles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final role = roles[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: MayaTheme.glassCard(),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.security_rounded, color: MayaTheme.neonCyan, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role['name'] ?? 'Unnamed Role', style: MayaTheme.titleMedium),
                              Text(role['description'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: (role['permissions'] as List? ?? []).map((p) => Chip(
                                  label: Text(p.toString(), style: MayaTheme.labelSmall),
                                  backgroundColor: MayaTheme.neonCyan.withValues(alpha: 0.2),
                                  side: BorderSide(color: MayaTheme.neonCyan.withValues(alpha: 0.5)),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
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
                  Text('Error loading roles', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Create New Role', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Role Name', hintText: 'e.g., admin, developer, viewer'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _permissionsController,
            decoration: const InputDecoration(labelText: 'Permissions (comma-separated)', hintText: 'e.g., read:all, write:projects, delete:reports'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createRole,
              icon: _isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.add_rounded),
              label: Text(_isCreating ? 'Creating...' : 'Create Role'),
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

class _OrgsTab extends ConsumerStatefulWidget {
  const _OrgsTab({super.key});

  @override
  ConsumerState<_OrgsTab> createState() => _OrgsTabState();
}

class _OrgsTabState extends ConsumerState<_OrgsTab> {
  final _nameController = TextEditingController();
  final _domainController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _createOrg() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isCreating = true);
    try {
      await ref.read(mayaApiProvider).enterpriseCreateOrg(
        name: _nameController.text.trim(),
        domain: _domainController.text.trim().isEmpty ? null : _domainController.text.trim(),
      );
      _nameController.clear();
      _domainController.clear();
      ref.invalidate(enterpriseOrgsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(enterpriseOrgsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Organizations', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Manage enterprise organizations and their settings.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          orgsAsync.when(
            data: (data) {
              final orgs = data['organizations'] as List? ?? [];
              if (orgs.isEmpty) {
                return const MayaEmptyState(
                  'No organizations',
                  icon: Icons.groups_rounded,
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orgs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final org = orgs[index];
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
                          child: const Icon(Icons.groups_rounded, color: MayaTheme.neonViolet, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(org['name'] ?? 'Unnamed Org', style: MayaTheme.titleMedium),
                              if (org['domain'] != null)
                                Text('Domain: ${org['domain']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                            ],
                          ),
                        ),
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
                  Text('Error loading organizations', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Create Organization', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Organization Name'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _domainController,
            decoration: const InputDecoration(labelText: 'Domain (optional)', hintText: 'example.com'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createOrg,
              icon: _isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.add_rounded),
              label: Text(_isCreating ? 'Creating...' : 'Create Organization'),
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

class _ApiKeysTab extends ConsumerStatefulWidget {
  const _ApiKeysTab({super.key});

  @override
  ConsumerState<_ApiKeysTab> createState() => _ApiKeysTabState();
}

class _ApiKeysTabState extends ConsumerState<_ApiKeysTab> {
  final _nameController = TextEditingController();
  final _scopesController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _scopesController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _createApiKey() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isCreating = true);
    try {
      final scopes = _scopesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final expiry = int.tryParse(_expiryController.text);
      await ref.read(mayaApiProvider).enterpriseCreateApiKey(
        name: _nameController.text.trim(),
        scopes: scopes,
        expiresInDays: expiry,
      );
      _nameController.clear();
      _scopesController.clear();
      _expiryController.clear();
      ref.invalidate(enterpriseApiKeysProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keysAsync = ref.watch(enterpriseApiKeysProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('API Keys', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Manage API keys for programmatic access.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          keysAsync.when(
            data: (data) {
              final keys = data['apiKeys'] as List? ?? [];
              if (keys.isEmpty) {
                return const MayaEmptyState(
                  'No API keys yet',
                  icon: Icons.key_rounded,
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final key = keys[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: MayaTheme.glassCard(),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: MayaTheme.neonEmerald.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.key_rounded, color: MayaTheme.neonEmerald, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(key['name'] ?? 'Unnamed Key', style: MayaTheme.titleMedium),
                              Text('Prefix: ${key['prefix'] ?? 'N/A'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: (key['scopes'] as List? ?? []).map((s) => Chip(
                                  label: Text(s.toString(), style: MayaTheme.labelSmall),
                                  backgroundColor: MayaTheme.neonEmerald.withValues(alpha: 0.2),
                                  side: BorderSide(color: MayaTheme.neonEmerald.withValues(alpha: 0.5)),
                                )).toList(),
                              ),
                              if (key['expiresAt'] != null)
                                Text('Expires: ${key['expiresAt'].toString().substring(0, 10)}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                            ],
                          ),
                        ),
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
                  Text('Error loading API keys', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Create API Key', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Key Name', hintText: 'e.g., production-api, ci-cd-key'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scopesController,
            decoration: const InputDecoration(labelText: 'Scopes (comma-separated)', hintText: 'e.g., read:all, write:projects'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _expiryController,
            decoration: const InputDecoration(labelText: 'Expires In (days, optional)', hintText: '90'),
            style: MayaTheme.bodyMedium,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createApiKey,
              icon: _isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.add_rounded),
              label: Text(_isCreating ? 'Creating...' : 'Create API Key'),
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

class _AuditTab extends ConsumerWidget {
  const _AuditTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(enterpriseAuditLogProvider);

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
                          color: MayaTheme.neonOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history_rounded, color: MayaTheme.neonOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['action'] ?? 'Unknown Action', style: MayaTheme.titleSmall),
                            Text(log['resource'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
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
                      Text('IP: ${log['ip'] ?? 'N/A'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38, fontFamily: 'monospace')),
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

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(enterpriseDashboardProvider);

    return dashboardAsync.when(
      data: (dashboard) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enterprise Dashboard', style: MayaTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Overview of enterprise metrics and activity.',
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Total Roles', value: dashboard['totalRoles']?.toString() ?? '0', color: MayaTheme.neonCyan, icon: Icons.security_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Organizations', value: dashboard['totalOrgs']?.toString() ?? '0', color: MayaTheme.neonViolet, icon: Icons.groups_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'API Keys', value: dashboard['totalApiKeys']?.toString() ?? '0', color: MayaTheme.neonEmerald, icon: Icons.key_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Audit Events (24h)', value: dashboard['auditEvents24h']?.toString() ?? '0', color: MayaTheme.neonOrange, icon: Icons.history_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Recent Activity', style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              ...(dashboard['recentActivity'] as List? ?? []).map((activity) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: MayaTheme.glassCard(),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: MayaTheme.neonCyan),
                    const SizedBox(width: 12),
                    Expanded(child: Text(activity['description'] ?? '', style: MayaTheme.bodySmall)),
                    Text(activity['timestamp']?.toString().substring(0, 19) ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                  ],
                ),
              )).toList(),
            ],
          ));
        },
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading dashboard', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    super.key,
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
    );
  }
}