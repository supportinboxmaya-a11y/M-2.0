import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'maya_cognitive_core_models.dart';

// Maya Cognitive Core providers using mayaApiProvider
final coreStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/core/status');
  return response;
});

final coreIdentityProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/core/identity');
  return response;
});

final coreModelsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/core/models');
  return response;
});

final coreCheckpointsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/core/checkpoints');
  return response;
});

final coreAuditProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/core/audit');
  return response;
});

final episodicListProvider = FutureProvider<EpisodicListResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/memory/episodic');
  return EpisodicListResponse.fromJson(response);
});

final episodicStatsProvider = FutureProvider<EpisodicStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/memory/episodic/stats');
  return EpisodicStatsResponse.fromJson(response);
});

final knowledgeStatsProvider = FutureProvider<KnowledgeStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/knowledge/stats');
  return KnowledgeStatsResponse.fromJson(response);
});

final knowledgeQueryProvider = FutureProvider.family<KnowledgeQueryResponse, Map<String, dynamic>>((ref, params) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/knowledge/query', queryParameters: params);
  return KnowledgeQueryResponse.fromJson(response);
});

final knowledgeLearnProvider = FutureProvider.family<KnowledgeLearnResponse, Map<String, dynamic>>((ref, data) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson('/api/v1/cognitive/knowledge/learn', data: data);
  return KnowledgeLearnResponse.fromJson(response);
});

final beliefsQueryProvider = FutureProvider.family<BeliefsQueryResponse, Map<String, dynamic>>((ref, params) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/beliefs', queryParameters: params);
  return BeliefsQueryResponse.fromJson(response);
});

final workingMemoryCapacityProvider = FutureProvider<WorkingMemoryStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/memory/working/capacity');
  return WorkingMemoryStatsResponse.fromJson(response);
});

final browserActionProvider = FutureProvider.family<BrowserActionResponse, Map<String, dynamic>>((ref, data) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson('/api/v1/browser/action', data: data);
  return BrowserActionResponse.fromJson(response);
});

final sandboxExecuteProvider = FutureProvider.family<SandboxExecuteResponse, Map<String, dynamic>>((ref, data) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson('/api/v1/sandbox/execute', data: data);
  return SandboxExecuteResponse.fromJson(response);
});