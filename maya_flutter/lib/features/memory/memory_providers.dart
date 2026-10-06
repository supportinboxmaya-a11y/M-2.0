import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'memory_models.dart';

// Memory providers using mayaApiProvider
final memoryListProvider = FutureProvider<MemoryListResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api
      .getJson('/api/v1/memory', queryParameters: {'limit': 50, 'offset': 0});
  return MemoryListResponse.fromJson(response);
});

final memoryStatsProvider = FutureProvider<MemoryStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/memory/stats');
  return MemoryStatsResponse.fromJson(response);
});

// Search trigger state
final memorySearchTriggerProvider = StateProvider<String>((ref) => '');

final memorySearchProvider = FutureProvider<MemorySearchResponse>((ref) async {
  final query = ref.watch(memorySearchTriggerProvider);
  if (query.isEmpty) {
    return MemorySearchResponse(results: [], query: '', count: 0);
  }
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson('/api/v1/memory/search', data: {
    'query': query,
    'limit': 20,
    'threshold': 0.7,
  });
  return MemorySearchResponse.fromJson(response);
});

// RAG Providers
final ragStatsProvider = FutureProvider<RAGStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/rag/stats');
  return RAGStatsResponse.fromJson(response);
});

final ragDocumentsProvider = FutureProvider<RAGDocumentsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api
      .getJson('/api/v1/rag/documents', queryParameters: {'limit': 200});
  return RAGDocumentsResponse.fromJson(response);
});

final ragSearchProvider =
    FutureProvider.family<RAGSearchResponse, String>((ref, query) async {
  if (query.isEmpty) {
    throw Exception('Empty query');
  }
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/rag/search', queryParameters: {
    'q': query,
    'limit': 5,
    'mode': 'hybrid',
  });
  return RAGSearchResponse.fromJson(response);
});

final ragContextProvider =
    FutureProvider.family<RAGContextResponse, String>((ref, query) async {
  if (query.isEmpty) {
    throw Exception('Empty query');
  }
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/rag/context', queryParameters: {
    'q': query,
    'limit': 5,
    'max_chars': 6000,
  });
  return RAGContextResponse.fromJson(response);
});
