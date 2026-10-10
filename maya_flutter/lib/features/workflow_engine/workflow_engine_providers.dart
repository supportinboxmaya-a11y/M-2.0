import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'workflow_engine_models.dart';

// Workflow Engine providers using mayaApiProvider
final workflowsRunsProvider =
    FutureProvider<WorkflowsRunsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/workflows/runs');
  return WorkflowsRunsResponse.fromJson(response);
});

final workflowPlanProvider =
    FutureProvider.family<WorkflowPlanResponse, String>((ref, goal) async {
  if (goal.isEmpty) {
    throw Exception('Empty goal');
  }
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.postJson('/api/v1/workflows/plan', data: {'goal': goal});
  return WorkflowPlanResponse.fromJson(response);
});

final workflowRunProvider =
    FutureProvider.family<WorkflowRunState, String>((ref, runId) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/workflows/runs/$runId');
  return WorkflowRunState.fromJson(response);
});

final workflowExecuteProvider =
    FutureProvider.family<WorkflowExecuteResponse, String>((ref, runId) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson('/api/v1/workflows/runs/$runId/execute');
  return WorkflowExecuteResponse.fromJson(response);
});

final workflowCancelProvider =
    FutureProvider.family<bool, String>((ref, runId) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson('/api/v1/workflows/runs/$runId/cancel');
  return response['success'] as bool? ?? false;
});
