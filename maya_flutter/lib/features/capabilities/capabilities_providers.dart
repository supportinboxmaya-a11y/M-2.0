import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'capabilities_models.dart';

// Capabilities providers using mayaApiProvider
final capabilitiesProvider =
    FutureProvider<CapabilitiesListResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/capabilities');
  return CapabilitiesListResponse.fromJson(response);
});

final capabilitiesSearchProvider =
    FutureProvider.family<CapabilitiesSearchResponse, String>(
        (ref, query) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/capabilities/search?q=$query');
  return CapabilitiesSearchResponse.fromJson(response);
});

final capabilitiesStatsProvider =
    FutureProvider<CapabilitiesStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/capabilities/stats');
  return CapabilitiesStatsResponse.fromJson(response);
});

final capabilityDetailProvider =
    FutureProvider.family<CapabilityDetailResponse, String>((ref, capId) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/capabilities/$capId');
  return CapabilityDetailResponse.fromJson(response);
});
