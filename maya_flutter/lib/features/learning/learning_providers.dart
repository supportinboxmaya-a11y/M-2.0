import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'learning_models.dart';

// Learning providers using mayaApiProvider
final learningStatsProvider =
    FutureProvider<LearningStatsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/learning/stats');
  return LearningStatsResponse.fromJson(response);
});

final learningExperienceProvider =
    FutureProvider<LearningExperienceResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.getJson('/api/v1/learning/experience', queryParameters: {
    'limit': 5,
  });
  return LearningExperienceResponse.fromJson(response);
});

final learningPromptsProvider =
    FutureProvider<LearningPromptsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/learning/prompts');
  return LearningPromptsResponse.fromJson(response);
});
