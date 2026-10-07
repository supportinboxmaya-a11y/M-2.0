import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'unified_cognitive_loop_models.dart';

final unifiedLoopStatusProvider = FutureProvider<UnifiedLoopStatus>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/loop/status');
  return UnifiedLoopStatus.fromJson(response);
});

final unifiedLoopHistoryProvider = FutureProvider<UnifiedLoopHistoryResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/cognitive/loop/history');
  return UnifiedLoopHistoryResponse.fromJson(response);
});