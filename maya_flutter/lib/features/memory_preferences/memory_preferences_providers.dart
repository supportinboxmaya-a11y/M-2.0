import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'memory_preferences_models.dart';

// Memory Preferences providers using mayaApiProvider
final memoryPrefsProvider =
    FutureProvider.family<ExtMemPrefsListResponse, String>((ref, userId) async {
  if (userId.isEmpty) {
    return ExtMemPrefsListResponse(preferences: {});
  }
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.getJson('/api/v1/extended/memory/preferences/$userId');
  return ExtMemPrefsListResponse.fromJson(response);
});

final memoryFactsProvider =
    FutureProvider.family<ExtMemFactsListResponse, String>((ref, userId) async {
  if (userId.isEmpty) {
    return ExtMemFactsListResponse(facts: []);
  }
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/extended/memory/facts/$userId');
  return ExtMemFactsListResponse.fromJson(response);
});
