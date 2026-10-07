import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'self_improve_models.dart';

final selfImproveStatusProvider = FutureProvider<SelfImproveStatus>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/self_improve/status');
  return SelfImproveStatus.fromJson(response);
});

final selfImproveProposalsProvider = FutureProvider<SelfImproveProposalsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/self_improve/proposals');
  return SelfImproveProposalsResponse.fromJson(response);
});

final selfImproveGapsProvider = FutureProvider<SelfImproveGapsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/self_improve/gaps');
  return SelfImproveGapsResponse.fromJson(response);
});

final selfImproveConfigProvider = FutureProvider<SelfImproveConfigResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/self_improve/config');
  return SelfImproveConfigResponse.fromJson(response);
});