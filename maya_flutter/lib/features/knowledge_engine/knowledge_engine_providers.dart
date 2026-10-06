import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'knowledge_engine_models.dart';

// Knowledge Engine providers using mayaApiProvider
final knowledgeStatsProvider =
    FutureProvider<KnowledgeStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/knowledge/stats');
  return KnowledgeStatsResponse.fromJson(response);
});

final knowledgeQueryProvider =
    FutureProvider.family<KnowledgeQueryResponse, String>((ref, query) async {
  if (query.isEmpty) {
    return KnowledgeQueryResponse(results: []);
  }
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.getJson('/api/v1/cognitive/knowledge/query', queryParameters: {
    'q': query,
    'limit': 10,
  });
  return KnowledgeQueryResponse.fromJson(response);
});

final knowledgeLearnProvider =
    FutureProvider.family<KnowledgeLearnResponse, Map<String, dynamic>>(
        (ref, data) async {
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.postJson('/api/v1/cognitive/knowledge/learn', data: data);
  return KnowledgeLearnResponse.fromJson(response);
});

final beliefsQueryProvider =
    FutureProvider.family<BeliefsQueryResponse, Map<String, dynamic>>(
        (ref, params) async {
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.getJson('/api/v1/cognitive/beliefs', queryParameters: params);
  return BeliefsQueryResponse.fromJson(response);
});
