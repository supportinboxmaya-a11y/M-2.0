import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'auto_resume_models.dart';

// Auto-Resume providers using mayaApiProvider
final incompleteGoalsProvider = FutureProvider<GoalsListResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/goals/incomplete');
  return GoalsListResponse.fromJson(response);
});

final autoResumeProvider = FutureProvider.family<AutoResumeResponse,
    ({bool? execute, int maxGoals, bool planProposals})>((ref, params) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.postJson(
    '/api/v1/goals/auto_resume',
    data: {
      'execute': params.execute ?? false,
      'max_goals': params.maxGoals,
      'plan_proposals': params.planProposals,
    },
  );
  return AutoResumeResponse.fromJson(response);
});
