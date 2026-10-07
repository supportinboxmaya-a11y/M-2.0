import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'self_model_models.dart';

final selfModelListProvider = FutureProvider<SelfModelListResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/self_model/models');
  return SelfModelListResponse.fromJson(response);
});

final selfModelStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/self_model/stats');
  return response;
});