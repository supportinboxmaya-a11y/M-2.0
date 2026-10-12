import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/app_config.dart';
import 'api_service.dart';

final mayaApiProvider = Provider<MayaApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MayaApi(apiService.dio);
});

class MayaApi {
  final Dio _dio;

  MayaApi(this._dio);

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteJson(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postFormData(String path,
      {required Map<String, dynamic> data}) async {
    final formData = FormData.fromMap(data);
    final response = await _dio.post(
      path,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Income Engine: Builder ──────────────────────────────────────
  Future<Map<String, dynamic>> builderCreateProject(String planId) async {
    final response = await _dio.post(
      '/api/v1/income/builder/projects',
      data: {'plan_id': planId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> builderListProjects({
    String? status,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/builder/projects',
      queryParameters: {
        if (status != null) 'status': status,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> builderGetProject(String projectId) async {
    final response = await _dio.get('/api/v1/income/builder/projects/$projectId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> builderUpdateProjectStatus(
    String projectId, String status,
  ) async {
    final response = await _dio.post(
      '/api/v1/income/builder/projects/$projectId/status',
      data: {'status': status},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> builderGetProjectSteps(String projectId) async {
    final response = await _dio.get('/api/v1/income/builder/projects/$projectId/steps');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> builderExecuteStep(
    String projectId, String stepId,
  ) async {
    final response = await _dio.post(
      '/api/v1/income/builder/projects/$projectId/steps/$stepId/execute',
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> builderBuildFromPlan(String planId) async {
    final response = await _dio.post(
      '/api/v1/income/builder/build-from-plan',
      data: {'plan_id': planId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> builderGetStats() async {
    final response = await _dio.get('/api/v1/income/builder/stats');
    return response.data as Map<String, dynamic>;
  }

  // ─── Income Engine: Growth ───────────────────────────────────────
  Future<Map<String, dynamic>> growthListProposals({
    String? projectId,
    String? status,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/growth/proposals',
      queryParameters: {
        if (projectId != null) 'project_id': projectId,
        if (status != null) 'status': status,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> growthGetProposal(String proposalId) async {
    final response = await _dio.get('/api/v1/income/growth/proposals/$proposalId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> growthDecideProposal(
    String proposalId, bool approved,
  ) async {
    final response = await _dio.post(
      '/api/v1/income/growth/proposals/$proposalId/decide',
      data: {'approved': approved},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> growthUpdateMetrics({
    required String projectId,
    int visitors = 0,
    int signups = 0,
    int conversions = 0,
    double revenue = 0.0,
    double churnRate = 0.0,
    double avgSessionDuration = 0.0,
    double bounceRate = 0.0,
    double errorRate = 0.0,
    double uptime = 100.0,
    double? npsScore,
  }) async {
    final response = await _dio.post(
      '/api/v1/income/growth/metrics',
      data: {
        'project_id': projectId,
        'visitors': visitors,
        'signups': signups,
        'conversions': conversions,
        'revenue': revenue,
        'churn_rate': churnRate,
        'avg_session_duration': avgSessionDuration,
        'bounce_rate': bounceRate,
        'error_rate': errorRate,
        'uptime': uptime,
        if (npsScore != null) 'nps_score': npsScore,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> growthGetMetrics(String projectId, {int limit = 30}) async {
    final response = await _dio.get(
      '/api/v1/income/growth/metrics/$projectId',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> growthGetRecommendations({
    String? projectId,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/growth/portfolio/recommendations',
      queryParameters: {
        if (projectId != null) 'project_id': projectId,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> growthTriggerPortfolioReview() async {
    final response = await _dio.post('/api/v1/income/growth/portfolio/review');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> growthGetPortfolioSummary() async {
    final response = await _dio.get('/api/v1/income/growth/portfolio/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> growthGetActionsLog({
    String? projectId,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/growth/actions/log',
      queryParameters: {
        if (projectId != null) 'project_id': projectId,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Income Engine: Launcher ─────────────────────────────────────
  Future<Map<String, dynamic>> launcherCreateLaunch(String buildProjectId) async {
    final response = await _dio.post(
      '/api/v1/income/launcher/launches',
      data: {'build_project_id': buildProjectId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherListLaunches({
    String? status,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/launcher/launches',
      queryParameters: {
        if (status != null) 'status': status,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherGetLaunch(String launchId) async {
    final response = await _dio.get('/api/v1/income/launcher/launches/$launchId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherGetContent(String launchId) async {
    final response = await _dio.get('/api/v1/income/launcher/launches/$launchId/content');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherApproveContent(
    String contentId, bool approved, {String feedback = ''}) async {
    final response = await _dio.post(
      '/api/v1/income/launcher/content/approve',
      data: {
        'content_id': contentId,
        'approved': approved,
        'feedback': feedback,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherUpdateContent(String contentId, String content) async {
    final response = await _dio.post(
      '/api/v1/income/launcher/content/update',
      data: {'content_id': contentId, 'content': content},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherConfigureLaunch(
    String launchId, {
      String? subdomain,
      String? customDomain,
      double? launchDate,
    }) async {
    final response = await _dio.post(
      '/api/v1/income/launcher/launches/$launchId/config',
      data: {
        if (subdomain != null) 'subdomain': subdomain,
        if (customDomain != null) 'custom_domain': customDomain,
        if (launchDate != null) 'launch_date': launchDate,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherStartLaunch(String launchId) async {
    final response = await _dio.post('/api/v1/income/launcher/launches/$launchId/start');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherRetryLaunch(String launchId) async {
    final response = await _dio.post('/api/v1/income/launcher/launches/$launchId/retry');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> launcherGetStats() async {
    final response = await _dio.get('/api/v1/income/launcher/stats');
    return response.data as Map<String, dynamic>;
  }

  // ─── Income Engine: Notifications ────────────────────────────────
  Future<Map<String, dynamic>> notificationSend({
    required String type,
    String priority = 'normal',
    required String title,
    required String message,
    List<String> channels = const ['webhook'],
    Map<String, dynamic> metadata = const {},
  }) async {
    final response = await _dio.post(
      '/api/v1/income/notifications/send',
      data: {
        'type': type,
        'priority': priority,
        'title': title,
        'message': message,
        'channels': channels,
        'metadata': metadata,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationCreateApprovalRequest({
    required String action,
    String reason = '',
    String riskLevel = 'high',
    String taskId = '',
    String planId = '',
    String opportunityId = '',
    String title = '',
    String description = '',
    int expiresInHours = 24,
  }) async {
    final response = await _dio.post(
      '/api/v1/income/notifications/approvals/request',
      data: {
        'action': action,
        'reason': reason,
        'risk_level': riskLevel,
        'task_id': taskId,
        'plan_id': planId,
        'opportunity_id': opportunityId,
        'title': title,
        'description': description,
        'expires_in_hours': expiresInHours,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationListApprovals({
    String? status,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/notifications/approvals',
      queryParameters: {
        if (status != null) 'status': status,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationGetApproval(String approvalId) async {
    final response = await _dio.get('/api/v1/income/notifications/approvals/$approvalId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationDecideApproval(
    String approvalId, bool approved, {
      String decidedBy = '',
      String reason = '',
    }) async {
    final response = await _dio.post(
      '/api/v1/income/notifications/approvals/$approvalId/decide',
      data: {
        'approved': approved,
        'decided_by': decidedBy,
        'reason': reason,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationSendDailyDigest({
    Map<String, dynamic> strategistResult = const {},
    Map<String, dynamic> scoutStats = const {},
  }) async {
    final response = await _dio.post(
      '/api/v1/income/notifications/digest/daily',
      data: {
        'strategist_result': strategistResult,
        'scout_stats': scoutStats,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationSendBuilderAlert({
    required String projectName,
    required String status,
    String details = '',
  }) async {
    final response = await _dio.post(
      '/api/v1/income/notifications/alerts/builder',
      data: {
        'project_name': projectName,
        'status': status,
        'details': details,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationSendLaunchReadyAlert({
    required String projectName,
    required String planId,
  }) async {
    final response = await _dio.post(
      '/api/v1/income/notifications/alerts/launch-ready',
      data: {'project_name': projectName, 'plan_id': planId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationSendErrorAlert({
    required String component,
    required String error,
    String context = '',
  }) async {
    final response = await _dio.post(
      '/api/v1/income/notifications/alerts/error',
      data: {'component': component, 'error': error, 'context': context},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationListTemplates() async {
    final response = await _dio.get('/api/v1/income/notifications/templates');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationCreateTemplate({
    required String name,
    required String subjectTemplate,
    required String bodyTemplate,
    List<String> channels = const ['webhook'],
  }) async {
    final response = await _dio.post(
      '/api/v1/income/notifications/templates',
      data: {
        'name': name,
        'subject_template': subjectTemplate,
        'body_template': bodyTemplate,
        'channels': channels,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationDeleteTemplate(String name) async {
    final response = await _dio.delete('/api/v1/income/notifications/templates/$name');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationGetChannels() async {
    final response = await _dio.get('/api/v1/income/notifications/channels');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> notificationGetStats() async {
    final response = await _dio.get('/api/v1/income/notifications/stats');
    return response.data as Map<String, dynamic>;
  }

  // ─── Income Engine: Scout ────────────────────────────────────────
  Future<Map<String, dynamic>> scoutTriggerScan({String? source}) async {
    final response = await _dio.post(
      '/api/v1/income/scout/scan',
      data: {'source': source},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutGetScanHistory({int limit = 20}) async {
    final response = await _dio.get(
      '/api/v1/income/scout/scan/history',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutGetSignals({
    String? source,
    String? signalType,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/scout/signals',
      queryParameters: {
        if (source != null) 'source': source,
        if (signalType != null) 'signal_type': signalType,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutListOpportunities({
    String? status,
    String? category,
    double minScore = 0,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/scout/opportunities',
      queryParameters: {
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        'min_score': minScore,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutGetOpportunity(String oppId) async {
    final response = await _dio.get('/api/v1/income/scout/opportunities/$oppId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutRecordDecision(
    String opportunityId, bool approved, {String feedback = ''}) async {
    final response = await _dio.post(
      '/api/v1/income/scout/opportunities/$opportunityId/decision',
      data: {'approved': approved, 'feedback': feedback},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutRejectOpportunity(String oppId) async {
    final response = await _dio.delete('/api/v1/income/scout/opportunities/$oppId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutGetPreferences() async {
    final response = await _dio.get('/api/v1/income/scout/preferences');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutSetPreference({
    required String category,
    required String preference,
    double confidence = 0.7,
    String notes = '',
  }) async {
    final response = await _dio.post(
      '/api/v1/income/scout/preferences',
      data: {
        'category': category,
        'preference': preference,
        'confidence': confidence,
        'notes': notes,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutDeletePreference(String category) async {
    final response = await _dio.delete('/api/v1/income/scout/preferences/$category');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scoutGetStats() async {
    final response = await _dio.get('/api/v1/income/scout/stats');
    return response.data as Map<String, dynamic>;
  }

  // ─── Income Engine: Strategist ───────────────────────────────────
  Future<Map<String, dynamic>> strategistTriggerReview() async {
    final response = await _dio.post('/api/v1/income/strategist/review');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> strategistGetReviewHistory({int limit = 20}) async {
    final response = await _dio.get(
      '/api/v1/income/strategist/review/history',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> strategistListPlans({
    String? status,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/income/strategist/plans',
      queryParameters: {
        if (status != null) 'status': status,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> strategistGetPlan(String planId) async {
    final response = await _dio.get('/api/v1/income/strategist/plans/$planId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> strategistApprovePlan(String planId) async {
    final response = await _dio.post('/api/v1/income/strategist/plans/$planId/approve');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> strategistRejectPlan(String planId, {String reason = ''}) async {
    final response = await _dio.post(
      '/api/v1/income/strategist/plans/$planId/reject',
      data: {'reason': reason},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> strategistGetRankedOpportunities({int limit = 20}) async {
    final response = await _dio.get(
      '/api/v1/income/strategist/ranked-opportunities',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> strategistGetConfig() async {
    final response = await _dio.get('/api/v1/income/strategist/config');
    return response.data as Map<String, dynamic>;
  }

  // ─── Business: Business Analysis ───────────────────────────────────
  Future<Map<String, dynamic>> businessListMissions({int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/business/missions',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> businessGetMission(String missionId) async {
    final response = await _dio.get('/api/v1/business/missions/$missionId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> businessRunAnalysis({
    required String missionId,
    Map<String, dynamic>? parameters,
  }) async {
    final response = await _dio.post(
      '/api/v1/business/missions/$missionId/analyze',
      data: parameters ?? {},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> businessGetReport(String reportId) async {
    final response = await _dio.get('/api/v1/business/reports/$reportId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> businessListReports({int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/business/reports',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Business: Guarded Publish ─────────────────────────────────────
  Future<Map<String, dynamic>> guardedListPending({int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/business/guarded/pending',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guardedListHistory({int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/business/guarded/history',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guardedCreateRequest({
    required String title,
    required String description,
    required String targetEnvironment,
    Map<String, dynamic>? payload,
  }) async {
    final response = await _dio.post(
      '/api/v1/business/guarded/requests',
      data: {
        'title': title,
        'description': description,
        'target_environment': targetEnvironment,
        'payload': payload ?? {},
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guardedGetRequest(String requestId) async {
    final response = await _dio.get('/api/v1/business/guarded/requests/$requestId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guardedApproveRequest(String requestId) async {
    final response = await _dio.post('/api/v1/business/guarded/requests/$requestId/approve');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guardedRejectRequest(String requestId, {String reason = ''}) async {
    final response = await _dio.post(
      '/api/v1/business/guarded/requests/$requestId/reject',
      data: {'reason': reason},
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Business: Enterprise ──────────────────────────────────────────
  Future<Map<String, dynamic>> enterpriseListRoles({int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/business/enterprise/roles',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enterpriseCreateRole({
    required String name,
    required List<String> permissions,
    String? description,
  }) async {
    final response = await _dio.post(
      '/api/v1/business/enterprise/roles',
      data: {
        'name': name,
        'permissions': permissions,
        if (description != null) 'description': description,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enterpriseListOrgs({int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/business/enterprise/organizations',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enterpriseCreateOrg({
    required String name,
    String? domain,
    String? settings,
  }) async {
    final response = await _dio.post(
      '/api/v1/business/enterprise/organizations',
      data: {
        'name': name,
        if (domain != null) 'domain': domain,
        if (settings != null) 'settings': settings,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enterpriseListApiKeys({int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/business/enterprise/api-keys',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enterpriseCreateApiKey({
    required String name,
    required List<String> scopes,
    int? expiresInDays,
  }) async {
    final response = await _dio.post(
      '/api/v1/business/enterprise/api-keys',
      data: {
        'name': name,
        'scopes': scopes,
        if (expiresInDays != null) 'expires_in_days': expiresInDays,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enterpriseGetAuditLog({int limit = 100}) async {
    final response = await _dio.get(
      '/api/v1/business/enterprise/audit-log',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enterpriseGetDashboard() async {
    final response = await _dio.get('/api/v1/business/enterprise/dashboard');
    return response.data as Map<String, dynamic>;
  }

  // ─── Business: Documentation ───────────────────────────────────────
  Future<Map<String, dynamic>> docsListDocuments({int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/business/docs/documents',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> docsGetDocument(String docId) async {
    final response = await _dio.get('/api/v1/business/docs/documents/$docId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> docsCreateDocument({
    required String title,
    required String content,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      '/api/v1/business/docs/documents',
      data: {
        'title': title,
        'content': content,
        if (category != null) 'category': category,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> docsUpdateDocument(
    String docId, {
    String? title,
    String? content,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.patch(
      '/api/v1/business/docs/documents/$docId',
      data: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (category != null) 'category': category,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> docsDeleteDocument(String docId) async {
    final response = await _dio.delete('/api/v1/business/docs/documents/$docId');
    return response.data as Map<String, dynamic>;
  }

  // ─── Business: Analytics ───────────────────────────────────────────
  Future<Map<String, dynamic>> analyticsGetSummary() async {
    final response = await _dio.get('/api/v1/business/analytics/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyticsGetDaily({int days = 30}) async {
    final response = await _dio.get(
      '/api/v1/business/analytics/daily',
      queryParameters: {'days': days},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyticsGetProviders() async {
    final response = await _dio.get('/api/v1/business/analytics/providers');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyticsGetTools() async {
    final response = await _dio.get('/api/v1/business/analytics/tools');
    return response.data as Map<String, dynamic>;
  }

  // ─── Business: API Key Provisioner ─────────────────────────────────
  Future<Map<String, dynamic>> provisionerScanFreeApis() async {
    final response = await _dio.get('/api/v1/business/provisioner/scan');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> provisionerProvisionKey({
    required String apiName,
    required String tier,
    Map<String, dynamic>? config,
  }) async {
    final response = await _dio.post(
      '/api/v1/business/provisioner/provision',
      data: {
        'api_name': apiName,
        'tier': tier,
        'config': config ?? {},
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> provisionerGetAuditLog({int limit = 100}) async {
    final response = await _dio.get(
      '/api/v1/business/provisioner/audit-log',
      queryParameters: {'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }
}
