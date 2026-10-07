import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';

// Autonomous Mode providers using mayaApiProvider
final autonomousStatusProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/autonomous/status');
  return response;
});

final autonomousToggleProvider =
    FutureProvider.family<Map<String, dynamic>, bool>((ref, enabled) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api
      .postJson('/api/v1/autonomous/toggle', data: {'enabled': enabled});
  return response;
});

final autonomousRunProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
        (ref, params) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson('/api/v1/autonomous/run', data: params);
  return response;
});
