import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/maya_api.dart';
import 'approvals_models.dart';

// Approvals providers using mayaApiProvider
final approvalsProvider =
    FutureProvider.family<ApprovalsListResponse, String?>((ref, status) async {
  final api = ref.watch(mayaApiProvider);
  final query = status != null ? '?status=$status' : '';
  final response = await api.getJson('/api/v1/approvals$query');
  return ApprovalsListResponse.fromJson(response);
});

final approvalModeProvider = FutureProvider<ApprovalModeResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/approvals/mode');
  return ApprovalModeResponse.fromJson(response);
});

final pendingApprovalsCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/approvals?status=pending');
  final approvals = ApprovalsListResponse.fromJson(response);
  return approvals.approvals.length;
});

final approveActionProvider =
    FutureProvider.family<ApprovalActionResponse, Map<String, dynamic>>(
        (ref, params) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api
      .postJson('/api/v1/approvals/${params['id']}/approve', data: params);
  return ApprovalActionResponse.fromJson(response);
});

final rejectActionProvider =
    FutureProvider.family<ApprovalActionResponse, Map<String, dynamic>>(
        (ref, params) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api
      .postJson('/api/v1/approvals/${params['id']}/reject', data: params);
  return ApprovalActionResponse.fromJson(response);
});

final setApprovalModeProvider =
    FutureProvider.family<ApprovalModeResponse, String>((ref, mode) async {
  final api = ref.watch(mayaApiProvider);
  final response =
      await api.postJson('/api/v1/approvals/mode', data: {'mode': mode});
  return ApprovalModeResponse.fromJson(response);
});
