import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'brain_engine_models.dart';

final brainAnalyzeProvider =
    FutureProvider.family<BrainAnalyzeResponse, String>((ref, goal) async {
  if (goal.isEmpty) {
    return BrainAnalyzeResponse(
        complexity: '', estimatedSteps: 0, subGoals: [], suggestedTools: []);
  }
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.postJson('/api/v1/brain/analyze', data: {'goal': goal});
  return BrainAnalyzeResponse.fromJson(response);
});

final brainGraphProvider =
    FutureProvider.family<BrainGraphResponse, String>((ref, runId) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/brain/graph/$runId');
  return BrainGraphResponse.fromJson(response);
});
