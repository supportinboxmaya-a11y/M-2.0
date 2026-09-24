import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flashlight/flashlight.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_service.dart';
import 'app_config.dart';

part 'system_service.freezed.dart';
part 'system_service.g.dart';

@riverpod
SystemService systemService(Ref ref) {
  return SystemService(ref.read(apiServiceProvider));
}

class SystemService {
  final ApiService _apiService;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  StreamController<SystemState>? _stateController;
  StreamController<BatteryState>? _batteryController;
  StreamController<List<ConnectivityResult>>? _connectivityController;
  Timer? _statusTimer;

  SystemService(this._apiService);

  Stream<SystemState> get stateStream => _stateController?.stream ?? const Stream.empty();
  Stream<BatteryState> get batteryStream => _batteryController?.stream ?? const Stream.empty();
  Stream<List<ConnectivityResult>> get connectivityStream => _connectivityController?.stream ?? const Stream.empty();

  Future<void> initialize() async {
    _stateController = StreamController<SystemState>.broadcast();
    _batteryController = StreamController<BatteryState>.broadcast();
    _connectivityController = StreamController<List<ConnectivityResult>>.broadcast();

    await _requestPermissions();
    _startStatusMonitoring();
  }

  Future<void> _requestPermissions() async {
    await Permission.locationWhenInUse.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.nearbyWifiDevices.request();
  }

  void _startStatusMonitoring() {
    // Battery
    _batteryController = StreamController<BatteryState>.broadcast();
    _battery.batteryStateStream.listen((state) {
      _batteryController?.add(state);
    });

    // Connectivity (v6.x returns List<ConnectivityResult>)
    _connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
    _connectivity.onConnectivityChanged.listen((result) {
      _connectivityController?.add(result);
    });

    // Periodic system status
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final status = await getSystemStatus();
      _stateController?.add(status);
    });

    // Initial status
    getSystemStatus().then((status) => _stateController?.add(status));
  }

  // System Status
  Future<SystemStatus> getSystemStatus() async {
    try {
      return await _apiService.getSystemStatus();
    } catch (e) {
      return SystemStatus(status: 'error', maya: 'offline');
    }
  }

  Future<SystemStats> getSystemStats() async {
    try {
      return await _apiService.getSystemStats();
    } catch (e) {
      return SystemStats(
        cpu: CpuStats(percent: 0, count: 0),
        memory: MemoryStats(totalGb: 0, availableGb: 0, usedGb: 0, percent: 0),
        disk: DiskStats(totalGb: 0, usedGb: 0, freeGb: 0, percent: 0),
        load: LoadStats(loadAvg: [0, 0, 0]),
      );
    }
  }

  // Device Controls
  Future<bool> toggleFlashlight(bool on) async {
    try {
      if (on) {
        await Flashlight.lightOn();
      } else {
        await Flashlight.lightOff();
      }
      return true;
    } catch (e) {
      debugPrint('Flashlight error: $e');
      return false;
    }
  }

  Future<bool> setVolume(double volume) async {
    try {
      await VolumeController().setVolume(volume.clamp(0.0, 1.0));
      return true;
    } catch (e) {
      debugPrint('Volume error: $e');
      return false;
    }
  }

  Future<double> getVolume() async {
    return await VolumeController().getVolume();
  }

  Future<BatteryState> getBatteryState() async {
    return await _battery.batteryState;
  }

  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  Future<bool> isCharging() async {
    final state = await _battery.batteryState;
    return state == BatteryState.charging || state == BatteryState.full;
  }

  Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }

  Future<void> openWifiSettings() async {
    await AppSettings.openWIFISettings();
  }

  Future<void> openBluetoothSettings() async {
    await AppSettings.openBluetoothSettings();
  }

  Future<void> openLocationSettings() async {
    await AppSettings.openLocationSettings();
  }

  Future<void> launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> openApp(String packageName) async {
    // Platform-specific app launching
    // Implementation depends on platform
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> info = {};

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      info = {
        'model': androidInfo.model,
        'brand': androidInfo.brand,
        'version': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'manufacturer': androidInfo.manufacturer,
        'device': androidInfo.device,
        'product': androidInfo.product,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      info = {
        'model': iosInfo.model,
        'systemName': iosInfo.systemName,
        'systemVersion': iosInfo.systemVersion,
        'name': iosInfo.name,
      };
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      info = {
        'name': linuxInfo.name,
        'version': linuxInfo.version,
        'id': linuxInfo.id,
        'prettyName': linuxInfo.prettyName,
      };
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      info = {
        'deviceName': windowsInfo.computerName,
        'buildNumber': windowsInfo.buildNumber,
        'version': windowsInfo.productName,
      };
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      info = {
        'model': macInfo.model,
        'version': macInfo.osRelease,
        'buildNumber': macInfo.buildNumber,
      };
    }

    return info;
  }

  Future<List<ConnectivityResult>> getConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _stateController?.close();
    _batteryController?.close();
    _connectivityController?.close();
    _statusTimer?.cancel();
  }
}

@freezed
class SystemState with _$SystemState {
  const factory SystemState({
    required String status,
    required String maya,
    String? version,
    int? uptime,
  }) = _SystemState;

  factory SystemState.fromJson(Map<String, dynamic> json) => _$SystemStateFromJson(json);
}