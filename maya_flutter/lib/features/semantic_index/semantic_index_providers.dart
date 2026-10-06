import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'semantic_index_models.dart';

// Semantic Index providers using mayaApiProvider
final vectorSearchStatsProvider =
    FutureProvider<VectorSearchStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/vector/stats');
  return VectorSearchStatsResponse.fromJson(response);
});

final vectorSearchProvider =
    FutureProvider.family<VectorSearchResponse, String>((ref, query) async {
  if (query.isEmpty) {
    return VectorSearchResponse(results: []);
  }
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson('/vector/search', data: {
    'query': query,
    'limit': 10,
    'hybrid': true,
  });
  return VectorSearchResponse.fromJson(response);
});
