import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'skill_generalization_models.dart';

// Skill Generalization providers using mayaApiProvider
final proceduralListProvider =
    FutureProvider<ProceduralListResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.getJson('/api/v1/cognitive/memory/procedural/skills');
  return ProceduralListResponse.fromJson(response);
});

final proceduralStatsProvider =
    FutureProvider<ProceduralStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.getJson('/api/v1/cognitive/memory/procedural/stats');
  return ProceduralStatsResponse.fromJson(response);
});

final proceduralSearchProvider =
    FutureProvider.family<ProceduralSearchResponse, String>((ref, query) async {
  if (query.isEmpty) {
    return ProceduralSearchResponse(skills: [], query: '');
  }
  final api = ref.watch(mayaApiProvider);
  final response = await api
      .getJson('/api/v1/cognitive/memory/procedural/search', queryParameters: {
    'q': query,
    'limit': 10,
  });
  return ProceduralSearchResponse.fromJson(response);
});
