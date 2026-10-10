import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'agents_models.dart';

// Agents providers using mayaApiProvider
final agentsListProvider = FutureProvider<AgentsListResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/agents/list');
  return AgentsListResponse.fromJson(response);
});

final agentsOrchestrateProvider =
    FutureProvider<AgentsOrchestrateResponse>((ref) async {
  final goal = ref.watch(agentsOrchestrateGoalProvider);
  if (goal.isEmpty) {
    throw Exception('Empty goal');
  }
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.postJson('/api/v1/agents/orchestrate', data: {'goal': goal});
  return AgentsOrchestrateResponse.fromJson(response);
});

final agentsMessagesProvider =
    FutureProvider<AgentsMessagesResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/agents/messages');
  return AgentsMessagesResponse.fromJson(response);
});

final agentsOrchestrateGoalProvider = StateProvider<String>((ref) => '');
