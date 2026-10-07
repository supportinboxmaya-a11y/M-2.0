import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'agi_architecture_models.dart';

final agiComponentsProvider = FutureProvider<AGIArchitectureComponentsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/agi/architecture/components');
  return AGIArchitectureComponentsResponse.fromJson(response);
});

final agiConnectionsProvider = FutureProvider<AGIArchitectureConnectionsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/agi/architecture/connections');
  return AGIArchitectureConnectionsResponse.fromJson(response);
});

final agiStatsProvider = FutureProvider<AGIArchitectureStats>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/agi/architecture/stats');
  return AGIArchitectureStats.fromJson(response);
});