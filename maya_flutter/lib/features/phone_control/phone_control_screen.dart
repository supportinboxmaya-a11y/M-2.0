import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final phoneDevicesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.deviceListDevices();
});

final phoneCommandHistoryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.deviceGetCommandHistory(deviceId: '');
});

class PhoneControlScreen extends ConsumerStatefulWidget {
  const PhoneControlScreen({super.key});

  @override
  ConsumerState<PhoneControlScreen> createState() => _PhoneControlScreenState();
}

class _PhoneControlScreenState extends ConsumerState<PhoneControlScreen>
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
          title: const Text('Phone / Device Control', style: MayaTheme.headlineSmall),
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
                ref.invalidate(phoneDevicesProvider);
                ref.invalidate(phoneCommandHistoryProvider);
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
              Tab(icon: Icon(Icons.devices_rounded), text: 'Devices'),
              Tab(icon: Icon(Icons.link_rounded), text: 'Pair Device'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Command History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _DevicesTab(),
            _PairTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _DevicesTab extends ConsumerWidget {
  const _DevicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(phoneDevicesProvider);

    return devicesAsync.when(
      data: (data) {
        final devices = data['devices'] as List? ?? [];
        if (devices.isEmpty) {
          return const MayaEmptyState(
            'No paired devices',
            icon: Icons.devices_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: devices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final device = devices[index];
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
                    child: const Icon(Icons.devices_rounded, color: MayaTheme.neonCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device['name'] ?? 'Unknown Device', style: MayaTheme.titleMedium),
                        Text('ID: ${device['id']?.toString().substring(0, 12) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
                        Text('Status: ${device['status'] ?? 'unknown'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: MayaTheme.error),
                    onPressed: () async {
                      await ref.read(mayaApiProvider).deviceRevoke(device['id']);
                      ref.invalidate(phoneDevicesProvider);
                    },
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
            Text('Error loading devices', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _PairTab extends ConsumerStatefulWidget {
  const _PairTab();

  @override
  ConsumerState<_PairTab> createState() => _PairTabState();
}

class _PairTabState extends ConsumerState<_PairTab> {
  final _nameController = TextEditingController();
  bool _isPairing = false;
  String? _pairingCode;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startPairing() async {
    final name = _nameController.text.trim().isEmpty ? 'My Computer' : _nameController.text.trim();

    setState(() => _isPairing = true);
    try {
      final result = await ref.read(mayaApiProvider).devicePairStart(name: name);
      if (mounted) {
        setState(() {
          _pairingCode = result['code'];
          _isPairing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
        setState(() => _isPairing = false);
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
          const Text('Pair New Device', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Start pairing to get a one-time code. Enter the code on the device to complete pairing.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Device Name',
              hintText: 'e.g., My Laptop',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPairing ? null : _startPairing,
              icon: _isPairing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.link_rounded),
              label: Text(_isPairing ? 'Starting Pairing...' : 'Start Pairing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_pairingCode != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MayaTheme.neonEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MayaTheme.neonEmerald.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.vpn_key_rounded, color: MayaTheme.neonEmerald, size: 48),
                  const SizedBox(height: 16),
                  const Text('Pairing Code', style: MayaTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(
                    _pairingCode!,
                    style: MayaTheme.headlineMedium.copyWith(
                      color: MayaTheme.neonEmerald,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter this code on the device within 10 minutes.',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(phoneCommandHistoryProvider);

    return historyAsync.when(
      data: (data) {
        final commands = data['commands'] as List? ?? [];
        if (commands.isEmpty) {
          return const MayaEmptyState(
            'No command history',
            icon: Icons.history_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: commands.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final cmd = commands[index];
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
                        child: const Icon(Icons.terminal_rounded, color: MayaTheme.neonCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cmd['action'] ?? 'Unknown', style: MayaTheme.titleSmall),
                            Text('Device: ${cmd['deviceId']?.toString().substring(0, 12) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                      Text(cmd['timestamp']?.toString().substring(0, 19) ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Status: ${cmd['status'] ?? 'pending'}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                      const Spacer(),
                      if (cmd['result'] != null)
                        Text('Completed', style: MayaTheme.bodySmall.copyWith(color: MayaTheme.neonEmerald)),
                    ],
                  ),
                ],
              );
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