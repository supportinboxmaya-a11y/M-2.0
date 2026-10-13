import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final phoneDevicesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.deviceListDevices();
});

final phoneCommandHistoryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.deviceGetCommandHistory(deviceId: '');
});

final nativePhoneServiceProvider = Provider<NativePhoneService>((ref) {
  return NativePhoneService();
});

class NativePhoneService {
  static const MethodChannel _channel = MethodChannel('maya/phone_control');

  Future<bool> requestPermissions() async {
    try {
      return await _channel.invokeMethod('requestPermissions');
    } on PlatformException catch (e) {
      debugPrint('Permission request failed: ${e.message}');
      return false;
    }
  }

  Future<bool> checkPermissions() async {
    try {
      return await _channel.invokeMethod('checkPermissions');
    } on PlatformException catch (e) {
      debugPrint('Check permissions failed: ${e.message}');
      return false;
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException catch (e) {
      debugPrint('Open battery settings failed: ${e.message}');
    }
  }

  Future<String> makeCall(String number) async {
    try {
      return await _channel.invokeMethod('makeCall', {'number': number});
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Call failed');
    }
  }

  Future<String> sendSms(String number, String message) async {
    try {
      return await _channel
          .invokeMethod('sendSms', {'number': number, 'message': message});
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'SMS failed');
    }
  }

  Future<void> setAutonomyEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setAutonomyEnabled', {'enabled': enabled});
    } on PlatformException catch (e) {
      debugPrint('Set autonomy failed: ${e.message}');
    }
  }

  Future<bool> getAutonomyEnabled() async {
    try {
      return await _channel.invokeMethod('getAutonomyEnabled');
    } on PlatformException catch (e) {
      debugPrint('Get autonomy failed: ${e.message}');
      return false;
    }
  }

  Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod('startForegroundService');
    } on PlatformException catch (e) {
      debugPrint('Start service failed: ${e.message}');
    }
  }

  Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
    } on PlatformException catch (e) {
      debugPrint('Stop service failed: ${e.message}');
    }
  }

  Future<String> getDeviceId() async {
    try {
      return await _channel.invokeMethod('getDeviceId');
    } on PlatformException catch (e) {
      debugPrint('Get device ID failed: ${e.message}');
      return '';
    }
  }

  Future<void> setVpsUrl(String url) async {
    try {
      await _channel.invokeMethod('setVpsUrl', {'url': url});
    } on PlatformException catch (e) {
      debugPrint('Set VPS URL failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final result = await _channel.invokeMethod('getServiceStatus');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('Get service status failed: ${e.message}');
      return {};
    }
  }
}

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
          title: const Text('Phone / Device Control',
              style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.sim_card_rounded), text: 'Native SIM'),
              Tab(icon: Icon(Icons.devices_rounded), text: 'Paired Devices'),
              Tab(icon: Icon(Icons.link_rounded), text: 'Pair Device'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Command History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _NativeSimTab(),
            _DevicesTab(),
            _PairTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _NativeSimTab extends ConsumerStatefulWidget {
  const _NativeSimTab();

  @override
  ConsumerState<_NativeSimTab> createState() => _NativeSimTabState();
}

class _NativeSimTabState extends ConsumerState<_NativeSimTab> {
  final _numberController = TextEditingController();
  final _messageController = TextEditingController();
  final _vpsUrlController =
      TextEditingController(text: 'ws://130.210.46.182:8000/api/v1/device/ws');

  bool _permissionsGranted = false;
  bool _autonomyEnabled = false;
  bool _serviceRunning = false;
  bool _isLoading = true;
  String _deviceId = '';
  String _lastAction = '';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _statusTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _loadStatus());
  }

  @override
  void dispose() {
    _numberController.dispose();
    _messageController.dispose();
    _vpsUrlController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final service = ref.read(nativePhoneServiceProvider);
    final permissions = await service.checkPermissions();
    final autonomy = await service.getAutonomyEnabled();
    final deviceId = await service.getDeviceId();
    final status = await service.getServiceStatus();

    if (mounted) {
      setState(() {
        _permissionsGranted = permissions;
        _autonomyEnabled = autonomy;
        _deviceId = deviceId;
        _serviceRunning = status['service_running'] ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final service = ref.read(nativePhoneServiceProvider);
    final granted = await service.requestPermissions();
    if (mounted) {
      setState(() => _permissionsGranted = granted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              granted ? 'All permissions granted' : 'Some permissions denied'),
          backgroundColor: granted ? MayaTheme.neonEmerald : MayaTheme.error,
        ),
      );
    }
  }

  Future<void> _toggleAutonomy(bool enabled) async {
    final service = ref.read(nativePhoneServiceProvider);
    await service.setAutonomyEnabled(enabled);
    setState(() => _autonomyEnabled = enabled);
  }

  Future<void> _toggleService(bool running) async {
    final service = ref.read(nativePhoneServiceProvider);
    if (running) {
      await service.startForegroundService();
    } else {
      await service.stopForegroundService();
    }
    await _loadStatus();
  }

  Future<void> _saveVpsUrl() async {
    final service = ref.read(nativePhoneServiceProvider);
    await service.setVpsUrl(_vpsUrlController.text.trim());
    await _loadStatus();
  }

  Future<void> _makeCall() async {
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a phone number'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }

    final service = ref.read(nativePhoneServiceProvider);
    try {
      final result = await service.makeCall(number);
      setState(() => _lastAction = 'Call: $result');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: MayaTheme.neonEmerald),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Call failed: $e'), backgroundColor: MayaTheme.error),
      );
    }
  }

  Future<void> _sendSms() async {
    final number = _numberController.text.trim();
    final message = _messageController.text.trim();
    if (number.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter number and message'),
            backgroundColor: MayaTheme.error),
      );
      return;
    }

    final service = ref.read(nativePhoneServiceProvider);
    try {
      final result = await service.sendSms(number, message);
      setState(() => _lastAction = 'SMS: $result');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: MayaTheme.neonEmerald),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('SMS failed: $e'), backgroundColor: MayaTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: MayaTheme.neonCyan));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sim_card_rounded,
                        color: MayaTheme.neonCyan, size: 28),
                    const SizedBox(width: 12),
                    Text('Native SIM Control', style: MayaTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatusRow(
                    'Permissions',
                    _permissionsGranted ? 'Granted' : 'Missing',
                    _permissionsGranted),
                _buildStatusRow(
                    'Autonomy Mode',
                    _autonomyEnabled
                        ? 'FULL (no confirmation)'
                        : 'SAFE (confirmation required)',
                    _autonomyEnabled),
                _buildStatusRow('Foreground Service',
                    _serviceRunning ? 'Running' : 'Stopped', _serviceRunning),
                _buildStatusRow(
                    'Device ID',
                    _deviceId.isNotEmpty
                        ? _deviceId.substring(0, 16) + '...'
                        : 'Unknown',
                    _deviceId.isNotEmpty),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Permissions Section
          if (!_permissionsGranted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MayaTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: MayaTheme.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: MayaTheme.error),
                      const SizedBox(width: 8),
                      Text('Permissions Required',
                          style: MayaTheme.titleMedium
                              .copyWith(color: MayaTheme.error)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maya needs these permissions for autonomous phone control:\n'
                    '• CALL_PHONE - Make calls without confirmation\n'
                    '• SEND_SMS - Send SMS silently\n'
                    '• READ_PHONE_STATE - Monitor call state\n'
                    '• READ_CALL_LOG - Log call history\n'
                    '• READ_SMS - Log incoming SMS\n'
                    '• Disable battery optimization for background operation',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _requestPermissions,
                          icon: const Icon(Icons.security_rounded),
                          label: const Text('Grant Permissions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MayaTheme.neonCyan,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final service =
                                ref.read(nativePhoneServiceProvider);
                            service.openBatteryOptimizationSettings();
                          },
                          icon: const Icon(Icons.battery_charging_full_rounded),
                          label: const Text('Battery Optimization'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MayaTheme.neonCyan,
                            side: const BorderSide(color: MayaTheme.neonCyan),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Controls Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Controls', style: MayaTheme.titleMedium),
                const SizedBox(height: 16),

                // Autonomy Toggle
                SwitchListTile(
                  title:
                      Text('Full Autonomy Mode', style: MayaTheme.titleSmall),
                  subtitle: Text(
                    _autonomyEnabled
                        ? 'Maya can make calls/SMS without confirmation'
                        : 'Maya will request confirmation for each call/SMS',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                  ),
                  value: _autonomyEnabled,
                  onChanged: _permissionsGranted ? _toggleAutonomy : null,
                  activeColor: MayaTheme.neonCyan,
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
                const Divider(color: Colors.white12),

                // Foreground Service Toggle
                SwitchListTile(
                  title:
                      Text('Background Service', style: MayaTheme.titleSmall),
                  subtitle: Text(
                    _serviceRunning
                        ? 'Service running - receiving VPS commands'
                        : 'Service stopped - cannot receive autonomous commands',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                  ),
                  value: _serviceRunning,
                  onChanged: _permissionsGranted ? _toggleService : null,
                  activeColor: MayaTheme.neonCyan,
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
                const Divider(color: Colors.white12),

                // VPS URL
                TextField(
                  controller: _vpsUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'VPS WebSocket URL',
                    hintText: 'ws://your-vps:8000/api/v1/device/ws',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.cloud_rounded, color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: MayaTheme.neonCyan),
                    ),
                    filled: true,
                    fillColor: MayaTheme.slate800,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saveVpsUrl,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save & Reconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MayaTheme.neonCyan,
                      side: const BorderSide(color: MayaTheme.neonCyan),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Manual Override Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manual Override', style: MayaTheme.titleMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: _numberController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+15551234567',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.phone_rounded, color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: MayaTheme.neonCyan),
                    ),
                    filled: true,
                    fillColor: MayaTheme.slate800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'SMS Message',
                    hintText: 'Enter message for SMS...',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.message_rounded,
                        color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: MayaTheme.neonCyan),
                    ),
                    filled: true,
                    fillColor: MayaTheme.slate800,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _permissionsGranted ? _makeCall : null,
                        icon: const Icon(Icons.call_rounded),
                        label: const Text('Make Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MayaTheme.neonCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _permissionsGranted ? _sendSms : null,
                        icon: const Icon(Icons.sms_rounded),
                        label: const Text('Send SMS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MayaTheme.neonEmerald,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Last Action
          if (_lastAction.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MayaTheme.slate800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: MayaTheme.neonCyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last Action',
                      style: MayaTheme.labelLarge
                          .copyWith(color: MayaTheme.neonCyan)),
                  const SizedBox(height: 8),
                  SelectableText(
                    _lastAction,
                    style: MayaTheme.bodySmall.copyWith(
                        fontFamily: 'monospace', color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool positive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            positive ? Icons.check_circle_rounded : Icons.error_rounded,
            color: positive ? MayaTheme.neonEmerald : MayaTheme.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text('$label: ',
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white70)),
          Expanded(
            child: Text(
              value,
              style: MayaTheme.bodyMedium.copyWith(
                color: positive ? MayaTheme.neonEmerald : MayaTheme.error,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
                    child: const Icon(Icons.devices_rounded,
                        color: MayaTheme.neonCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device['name'] ?? 'Unknown Device',
                            style: MayaTheme.titleMedium),
                        Text(
                            'ID: ${device['id']?.toString().substring(0, 12) ?? ''}',
                            style: MayaTheme.bodySmall.copyWith(
                                color: Colors.white54,
                                fontFamily: 'monospace')),
                        Text('Status: ${device['status'] ?? 'unknown'}',
                            style: MayaTheme.bodySmall
                                .copyWith(color: Colors.white38)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded,
                        color: MayaTheme.error),
                    onPressed: () async {
                      await ref
                          .read(mayaApiProvider)
                          .deviceRevoke(device['id']);
                      ref.invalidate(phoneDevicesProvider);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading devices',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

Widget _buildHistoryItem(Map<String, dynamic> cmd) {
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
              child: const Icon(Icons.terminal_rounded,
                  color: MayaTheme.neonCyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cmd['action'] ?? 'Unknown', style: MayaTheme.titleSmall),
                  Text(
                      'Device: ${cmd['deviceId']?.toString().substring(0, 12) ?? ''}',
                      style: MayaTheme.bodySmall.copyWith(
                          color: Colors.white54, fontFamily: 'monospace')),
                ],
              ),
            ),
            Text(cmd['timestamp']?.toString().substring(0, 19) ?? '',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Status: ${cmd['status'] ?? 'pending'}',
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
            const Spacer(),
            if (cmd['result'] != null)
              Text('Completed',
                  style: MayaTheme.bodySmall
                      .copyWith(color: MayaTheme.neonEmerald)),
          ],
        ),
      ],
    ),
  );
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
    final name = _nameController.text.trim().isEmpty
        ? 'My Computer'
        : _nameController.text.trim();

    setState(() => _isPairing = true);
    try {
      final result =
          await ref.read(mayaApiProvider).devicePairStart(name: name);
      if (mounted) {
        setState(() {
          _pairingCode = result['code'];
          _isPairing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: MayaTheme.error),
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
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MayaTheme.slate900))
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
                border: Border.all(
                    color: MayaTheme.neonEmerald.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.vpn_key_rounded,
                      color: MayaTheme.neonEmerald, size: 48),
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
          itemBuilder: (_, index) => _buildHistoryItem(commands[index]),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading history',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}
