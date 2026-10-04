import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:ui';

import '../../core/services/api_service.dart';
import '../../config/app_config.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(ref.read(apiServiceProvider));
});

class HealthService {
  final ApiService _apiService;

  HealthService(this._apiService);

  /// Health status from the backend
  Future<HealthStatus> checkHealth() async {
    try {
      // In a real implementation, you'd have dedicated health endpoints
      // For now, we'll use the system status endpoint as a proxy
      // and check if the API is responsive
      try {
        // Try to hit the system status endpoint as a health check
        final dio = _apiService.dio;
        await dio.get('/health/live');
        return HealthStatus(
          live: true,
          ready: true,
          system: 'healthy',
          latency: 0,
          lastCheck: DateTime.now(),
        );
      } catch (e) {
        return HealthStatus(
          live: false,
          ready: false,
          system: 'unhealthy',
          latency: 0,
          lastCheck: DateTime.now(),
          error: e.toString(),
        );
      }
    } catch (e) {
      return HealthStatus(
        live: false,
        ready: false,
        system: 'error',
        latency: 0,
        lastCheck: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Stream of health checks at regular intervals
  Stream<HealthStatus> watchHealth({Duration interval = const Duration(seconds: 30)}) {
    final controller = StreamController<HealthStatus>.broadcast();
    Timer? timer;

    void check() async {
      final status = await checkHealth();
      controller.add(status);
    }

    check(); // Initial check
    final healthTimer = Timer.periodic(const Duration(seconds: 30), (_) => check());

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }
}

/// Health status from the backend
class HealthStatus {
  final bool live;
  final bool ready;
  final String system;
  final int latency;
  final DateTime lastCheck;
  final String? error;

  const HealthStatus({
    required this.live,
    required this.ready,
    required this.system,
    required this.latency,
    required this.lastCheck,
    this.error,
  });

  bool get isHealthy => live && ready && system == 'healthy';

  Color get statusColor {
    if (!live) return const Color(0xFFFF3366);
    if (!ready) return const Color(0xFFFF6B35);
    return const Color(0xFF00FF87);
  }

  String get statusText {
    if (!live) return 'Offline';
    if (!ready) return 'Degraded';
    return 'Healthy';
  }
}