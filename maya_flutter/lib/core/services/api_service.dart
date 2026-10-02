import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/app_config.dart';

part 'api_service.freezed.dart';
part 'api_service.g.dart';

final _logger = Logger();

class RectConverter implements JsonConverter<Rect, Map<String, double>> {
  const RectConverter();

  @override
  Rect fromJson(Map<String, double> json) {
    return Rect.fromLTRB(
      json['left'] ?? 0,
      json['top'] ?? 0,
      json['right'] ?? 0,
      json['bottom'] ?? 0,
    );
  }

  @override
  Map<String, double> toJson(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
    };
  }
}

@riverpod
ApiService apiService(Ref ref) {
  return ApiService();
}

class ApiService {
  late final Dio _dio;
  final _wsController = StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _wsChannel;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'maya_auth_token';
  static const _refreshTokenKey = 'maya_refresh_token';

  ApiService() {
    _initDio();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    _storedToken = await _secureStorage.read(key: _tokenKey);
    _storedRefreshToken = await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> _saveTokens() async {
    if (_storedToken != null) {
      await _secureStorage.write(key: _tokenKey, value: _storedToken!);
    }
    if (_storedRefreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: _storedRefreshToken!);
    }
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    _storedToken = null;
    _storedRefreshToken = null;
  }

  String? _getToken() {
    return _storedToken;
  }

  String? _storedToken;
  String? _storedRefreshToken;

  /// Public getter for Dio instance (for health checks, etc.)
  Dio get dio => _dio;

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer ${_getToken()}';
              final retry = await _dio.fetch(options);
              return handler.resolve(retry);
            }
          }
          handler.next(error);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    if (_storedRefreshToken == null) return false;

    try {
      final response = await _dio.post(
        AppConfig.authRefresh,
        data: {'refresh_token': _storedRefreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _storedToken = data['access_token'];
        _storedRefreshToken = data['refresh_token'] ?? _storedRefreshToken;
        await _saveTokens();
        return true;
      }
    } catch (e) {
      _logger.e('Token refresh failed: $e');
    }
    return false;
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    _storedToken = accessToken;
    _storedRefreshToken = refreshToken;
    await _saveTokens();
  }

  Future<void> clearTokens() async {
    await _clearTokens();
  }

  // Auth
  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post(
      AppConfig.authLogin,
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      AppConfig.authRegister,
      data: {'name': name, 'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<void> logout() async {
    await _dio.post(AppConfig.authLogout);
    clearTokens();
  }

  Future<UserProfile> getMe() async {
    final response = await _dio.get(AppConfig.authMe);
    return UserProfile.fromJson(response.data);
  }

  // Generic HTTP methods
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response.data;
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<dynamic> delete(String path) async {
    final response = await _dio.delete(path);
    return response.data;
  }

  // Voice / Chat
  Future<AgentChatResponse> agentChat(String message, {String? chatId, String? instanceId}) async {
    final response = await _dio.post(
      AppConfig.agentChat,
      data: {'message': message, 'chat_id': chatId, 'instance_id': instanceId},
    );
    return AgentChatResponse.fromJson(response.data);
  }

  Future<TtsResult> speakText(String text, {String voice = 'en-US-AriaNeural'}) async {
    final response = await _dio.post(
      AppConfig.voiceSpeak,
      data: {'text': text, 'voice': voice},
    );
    return TtsResult.fromJson(response.data);
  }

  Future<QueueStatus> getQueueStatus() async {
    final response = await _dio.get(AppConfig.queueStatus);
    return QueueStatus.fromJson(response.data);
  }

  Future<AutonomousStatus> getAutonomousStatus() async {
    final response = await _dio.get(AppConfig.autonomousStatus);
    return AutonomousStatus.fromJson(response.data);
  }

  Future<CognitiveStatusResponse> getCognitiveStatus() async {
    final response = await _dio.get(AppConfig.cognitiveStatus);
    return CognitiveStatusResponse.fromJson(response.data);
  }

  Future<ApprovalsListResponse> getApprovals({String? status}) async {
    final response = await _dio.get(
      AppConfig.approvalsList,
      queryParameters: status != null ? {'status': status} : null,
    );
    return ApprovalsListResponse.fromJson(response.data);
  }

  Future<ApprovalDecideResponse> decideApproval({
    required String approvalId,
    required String decision,
  }) async {
    final response = await _dio.post(
      '${AppConfig.approvalsDecide}$approvalId/$decision',
    );
    return ApprovalDecideResponse.fromJson(response.data);
  }

  Future<ApprovalModeResponse> getApprovalMode() async {
    final response = await _dio.get(AppConfig.approvalMode);
    return ApprovalModeResponse.fromJson(response.data);
  }

  // Voice
  Future<TranscriptionResult> transcribeAudio(File audioFile) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'recording.webm',
      ),
    });

    final response = await _dio.post(
      AppConfig.voiceTranscribe,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return TranscriptionResult.fromJson(response.data);
  }

  Future<TtsResult> synthesizeText(String text, {String? voice}) async {
    final response = await _dio.post(
      AppConfig.voiceSynthesize,
      data: {'text': text, 'voice': voice ?? 'en_US-amy-medium'},
    );
    return TtsResult.fromJson(response.data);
  }

  // Agent
  Future<AgentChatResponse> chat(
    String message, {
    String? chatId,
    String? instanceId,
  }) async {
    final response = await _dio.post(
      AppConfig.agentChat,
      data: {'message': message, 'chat_id': chatId, 'instance_id': instanceId},
    );
    return AgentChatResponse.fromJson(response.data);
  }

  Stream<ChatStreamChunk> chatStream(
    String message, {
    String? chatId,
    String? instanceId,
  }) async* {
    final response = await _dio.post(
      AppConfig.agentChatStream,
      data: {'message': message, 'chat_id': chatId, 'instance_id': instanceId},
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final stream = response.data as Stream<List<int>>;
    final decoder = Utf8Decoder();
    String buffer = '';

    await for (final chunk in stream) {
      buffer += decoder.convert(chunk);
      final lines = buffer.split('\n\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final data = jsonDecode(line.substring(6));
            if (data['delta'] != null) {
              yield ChatStreamChunk(
                delta: data['delta'],
                done: data['done'] ?? false,
                error: data['error'],
              );
            } else if (data['error'] != null) {
              yield ChatStreamChunk(error: data['error']);
            } else if (data['done'] == true) {
              yield ChatStreamChunk(done: true);
            }
          } catch (e) {
            _logger.w('Failed to parse SSE chunk: $e');
          }
        }
      }
    }
  }

  // Task Execution Streaming (SSE)
  Stream<TaskStreamEvent> taskStream(String taskId) async* {
    final response = await _dio.get(
      '${AppConfig.taskStreamSse}$taskId/stream',
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final stream = response.data as Stream<List<int>>;
    final decoder = Utf8Decoder();
    String buffer = '';

    await for (final chunk in stream) {
      buffer += decoder.convert(chunk);
      final lines = buffer.split('\n\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final data = jsonDecode(line.substring(6));
            yield TaskStreamEvent.fromJson(data);
          } catch (e) {
            _logger.w('Failed to parse SSE chunk: $e');
          }
        }
      }
    }
  }

  Future<AgentRunResponse> runAgent(
    String goal, {
    double budgetUsd = 1.0,
  }) async {
    final response = await _dio.post(
      AppConfig.agentRun,
      data: {'goal': goal, 'budget_usd': budgetUsd},
    );
    return AgentRunResponse.fromJson(response.data);
  }

  Future<AgentThinkResponse> think(
    String problem, {
    String depth = 'normal',
  }) async {
    final response = await _dio.post(
      AppConfig.agentThink,
      data: {'problem': problem, 'depth': depth},
    );
    return AgentThinkResponse.fromJson(response.data);
  }

  // Learn & Complete (Phase 37/39)
  Future<LearnCompleteResponse> learnAndComplete({
    required String goal,
    int maxRetries = 3,
    String? taskId,
    String? scope,
  }) async {
    final response = await _dio.post(
      AppConfig.agentLearnComplete,
      data: {
        'goal': goal,
        'max_retries': maxRetries,
        if (taskId != null) 'instance_id': taskId,
        if (scope != null) 'scope': scope,
      },
    );
    return LearnCompleteResponse.fromJson(response.data);
  }

  // Vision/Camera
  Future<VisionAnalysisResult> analyzeImage(
    File imageFile, {
    String? prompt,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      if (prompt != null) 'prompt': prompt,
    });

    final response = await _dio.post(
      AppConfig.cameraAnalyze,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return VisionAnalysisResult.fromJson(response.data);
  }

  Future<OcrResult> extractText(File imageFile) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
    });

    final response = await _dio.post(
      AppConfig.cameraOcr,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return OcrResult.fromJson(response.data);
  }

  // System
  Future<SystemStatus> getSystemStatus() async {
    final response = await _dio.get(AppConfig.systemStatus);
    return SystemStatus.fromJson(response.data);
  }

  Future<SystemStats> getSystemStats() async {
    final response = await _dio.post(AppConfig.systemStats);
    return SystemStats.fromJson(response.data);
  }

  // Task Queue
  Future<QueueStats> getQueueStats() async {
    final response = await _dio.get(AppConfig.queueStats);
    return QueueStats.fromJson(response.data);
  }

  Future<QueueTaskStatus> getQueueTask(String taskId) async {
    final response = await _dio.get('${AppConfig.queueTask}$taskId');
    return QueueTaskStatus.fromJson(response.data);
  }

  Future<QueueSubmitResult> submitQueueJob({
    required String job,
    required Map<String, dynamic> payload,
    int priority = 0,
  }) async {
    final response = await _dio.post(
      AppConfig.queueSubmit,
      data: {'job': job, 'payload': payload, 'priority': priority},
    );
    return QueueSubmitResult.fromJson(response.data);
  }

  Future<bool> cancelQueueTask(String taskId) async {
    try {
      final response = await _dio.post('${AppConfig.queueCancel}$taskId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Metrics & Flags
  Future<MetricsSnapshot> getMetrics() async {
    final response = await _dio.get(AppConfig.metrics);
    return MetricsSnapshot.fromJson(response.data);
  }

  Future<FlagsSnapshot> getFlags() async {
    final response = await _dio.get(AppConfig.flags);
    return FlagsSnapshot.fromJson(response.data);
  }

  // Memory
  Future<MemoryListResponse> getMemoryList({int limit = 50, int offset = 0}) async {
    final response = await _dio.get(
      AppConfig.memoryList,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return MemoryListResponse.fromJson(response.data);
  }

  Future<MemorySearchResponse> searchMemory({
    required String query,
    int limit = 20,
    double threshold = 0.7,
  }) async {
    final response = await _dio.post(
      AppConfig.memorySearch,
      data: {'query': query, 'limit': limit, 'threshold': threshold},
    );
    return MemorySearchResponse.fromJson(response.data);
  }

  Future<MemoryCreateResponse> createMemory({
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      AppConfig.memoryCreate,
      data: {'content': content, 'metadata': metadata ?? {}},
    );
    return MemoryCreateResponse.fromJson(response.data);
  }

  Future<MemoryStatsResponse> getMemoryStats() async {
    final response = await _dio.get(AppConfig.memoryStats);
    return MemoryStatsResponse.fromJson(response.data);
  }

  // Tools & Providers
  Future<ToolsListResponse> getToolsList() async {
    final response = await _dio.get(AppConfig.toolsList);
    return ToolsListResponse.fromJson(response.data);
  }

  Future<ToolRunResponse> runTool({
    required String toolName,
    required Map<String, dynamic> input,
  }) async {
    final response = await _dio.post(
      '${AppConfig.toolsRun}$toolName/run',
      data: {'input': input},
    );
    return ToolRunResponse.fromJson(response.data);
  }

  Future<ToolsLogsResponse> getToolsLogs({int limit = 50}) async {
    final response = await _dio.get(
      AppConfig.toolsLogs,
      queryParameters: {'limit': limit},
    );
    return ToolsLogsResponse.fromJson(response.data);
  }

  Future<ToolsFrameworkResponse> getToolsFramework() async {
    final response = await _dio.get(AppConfig.toolsFramework);
    return ToolsFrameworkResponse.fromJson(response.data);
  }

  Future<ProvidersListResponse> getProvidersList() async {
    final response = await _dio.get(AppConfig.providersList);
    return ProvidersListResponse.fromJson(response.data);
  }

  Future<bool> toggleProvider(String providerId, bool enabled) async {
    try {
      final response = await _dio.put(
        '${AppConfig.providersToggle}$providerId',
        data: {'enabled': enabled},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Brain Engine
  Future<BrainAnalyzeResponse> analyzeGoal(String goal) async {
    final response = await _dio.get(
      AppConfig.brainAnalyze,
      queryParameters: {'goal': goal},
    );
    return BrainAnalyzeResponse.fromJson(response.data);
  }

  Future<BrainGraphResponse> buildGraph(List<Map<String, dynamic>> steps) async {
    final response = await _dio.post(
      AppConfig.brainGraph,
      data: {'steps': steps},
    );
    return BrainGraphResponse.fromJson(response.data);
  }

  // Multi-Agent System
  Future<AgentsListResponse> getAgentsList() async {
    final response = await _dio.get(AppConfig.agentsList);
    return AgentsListResponse.fromJson(response.data);
  }

  Future<AgentsOrchestrateResponse> orchestrateGoal(String goal) async {
    final response = await _dio.post(
      AppConfig.agentsOrchestrate,
      data: {'goal': goal},
    );
    return AgentsOrchestrateResponse.fromJson(response.data);
  }

  Future<AgentsMessagesResponse> getAgentsMessages({int limit = 50}) async {
    final response = await _dio.get(
      AppConfig.agentsMessages,
      queryParameters: {'limit': limit},
    );
    return AgentsMessagesResponse.fromJson(response.data);
  }

  // Workflow Engine
  Future<WorkflowPlanResponse> planWorkflow(String goal) async {
    final response = await _dio.post(
      AppConfig.workflowsPlan,
      data: {'goal': goal},
    );
    return WorkflowPlanResponse.fromJson(response.data);
  }

  Future<WorkflowsRunsResponse> getWorkflowsRuns() async {
    final response = await _dio.get(AppConfig.workflowsRuns);
    return WorkflowsRunsResponse.fromJson(response.data);
  }

  Future<WorkflowRunState> getWorkflowRun(String runId) async {
    final response = await _dio.get('${AppConfig.workflowsRun}$runId');
    return WorkflowRunState.fromJson(response.data);
  }

  Future<bool> cancelWorkflowRun(String runId) async {
    try {
      final response = await _dio.post('${AppConfig.workflowsCancel}$runId/cancel');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<WorkflowExecuteResponse> executeWorkflowRun(String runId) async {
    final response = await _dio.post('${AppConfig.workflowsExecute}$runId/execute');
    return WorkflowExecuteResponse.fromJson(response.data);
  }

  // Autonomous Mode
  Future<AutonomousRunResponse> runAutonomous({
    required String goal,
    bool approveDangerous = false,
    int maxRetries = 3,
  }) async {
    final response = await _dio.post(
      AppConfig.autonomousRun,
      data: {'goal': goal, 'approve_dangerous': approveDangerous, 'max_retries': maxRetries},
    );
    return AutonomousRunResponse.fromJson(response.data);
  }

  // Multi-Model Router
  Future<LLMProvidersResponse> getLLMProviders() async {
    final response = await _dio.get(AppConfig.llmProviders);
    return LLMProvidersResponse.fromJson(response.data);
  }

  Future<bool> toggleLLMProvider(String providerId, bool enabled) async {
    try {
      final response = await _dio.post(
        '${AppConfig.llmProviderToggle}$providerId/toggle',
        data: {'enabled': enabled},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<LLMStatsResponse> getLLMStats() async {
    final response = await _dio.get(AppConfig.llmStats);
    return LLMStatsResponse.fromJson(response.data);
  }

  Future<LLMStrategyResponse> getLLMStrategy({String strategy = 'balanced'}) async {
    final response = await _dio.get(
      AppConfig.llmStrategy,
      queryParameters: {'strategy': strategy},
    );
    return LLMStrategyResponse.fromJson(response.data);
  }

  // Enterprise Layer
  Future<AdminRolesResponse> getAdminRoles() async {
    final response = await _dio.get(AppConfig.adminRoles);
    return AdminRolesResponse.fromJson(response.data);
  }

  Future<AdminOrgsResponse> getAdminOrgs() async {
    final response = await _dio.get(AppConfig.adminOrgs);
    return AdminOrgsResponse.fromJson(response.data);
  }

  Future<AdminOrgResponse> createAdminOrg(String name) async {
    final response = await _dio.post(
      AppConfig.adminOrgs,
      data: {'name': name},
    );
    return AdminOrgResponse.fromJson(response.data);
  }

  Future<bool> deleteAdminOrg(String orgId) async {
    try {
      final response = await _dio.delete('${AppConfig.adminOrg}$orgId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<AdminOrgMembersResponse> getAdminOrgMembers(String orgId) async {
    final response = await _dio.get('${AppConfig.adminOrg}$orgId/members');
    return AdminOrgMembersResponse.fromJson(response.data);
  }

  Future<AdminApiKeysResponse> getAdminApiKeys() async {
    final response = await _dio.get(AppConfig.adminApiKeys);
    return AdminApiKeysResponse.fromJson(response.data);
  }

  Future<AdminApiKeyCreatedResponse> createAdminApiKey(String name) async {
    final response = await _dio.post(
      AppConfig.adminApiKeys,
      data: {'name': name},
    );
    return AdminApiKeyCreatedResponse.fromJson(response.data);
  }

  Future<bool> revokeAdminApiKey(String keyId) async {
    try {
      final response = await _dio.delete('${AppConfig.adminApiKey}$keyId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<AdminAuditResponse> getAdminAudit({String? actor, String? action, int limit = 100}) async {
    final response = await _dio.get(
      AppConfig.adminAudit,
      queryParameters: {
        if (actor != null) 'actor': actor,
        if (action != null) 'action': action,
        'limit': limit,
      },
    );
    return AdminAuditResponse.fromJson(response.data);
  }

  Future<AdminUsageResponse> getAdminUsage({double sinceTs = 0.0}) async {
    final response = await _dio.get(
      AppConfig.adminUsage,
      queryParameters: {'since_ts': sinceTs},
    );
    return AdminUsageResponse.fromJson(response.data);
  }

  Future<AdminDashboardResponse> getAdminDashboard() async {
    final response = await _dio.get(AppConfig.adminDashboard);
    return AdminDashboardResponse.fromJson(response.data);
  }

  Future<AdminOwnerModeResponse> getAdminOwnerMode() async {
    final response = await _dio.get(AppConfig.adminOwnerMode);
    return AdminOwnerModeResponse.fromJson(response.data);
  }

  Future<AdminOwnerModeResponse> setAdminOwnerMode(String mode) async {
    final response = await _dio.post(
      AppConfig.adminOwnerMode,
      data: {'mode': mode},
    );
    return AdminOwnerModeResponse.fromJson(response.data);
  }

  // Learning Layer
  Future<LearningFeedbackResponse> submitFeedback({
    required String goal,
    required String output,
    required int rating, // 1, 0, -1
    String comment = '',
  }) async {
    final response = await _dio.post(
      AppConfig.learningFeedback,
      data: {'goal': goal, 'output': output, 'rating': rating, 'comment': comment},
    );
    return LearningFeedbackResponse.fromJson(response.data);
  }

  Future<LearningStatsResponse> getLearningStats() async {
    final response = await _dio.get(AppConfig.learningStats);
    return LearningStatsResponse.fromJson(response.data);
  }

  Future<LearningExperienceResponse> getLearningExperience({String? goal, int limit = 5}) async {
    final response = await _dio.get(
      AppConfig.learningExperience,
      queryParameters: {
        if (goal != null) 'goal': goal,
        'limit': limit,
      },
    );
    return LearningExperienceResponse.fromJson(response.data);
  }

  Future<LearningCompressResponse> compressMemory({bool dryRun = true, String memoryType = 'chat'}) async {
    final response = await _dio.post(
      AppConfig.learningCompress,
      data: {'dry_run': dryRun, 'memory_type': memoryType},
    );
    return LearningCompressResponse.fromJson(response.data);
  }

  Future<LearningPromptsResponse> getLearningPrompts() async {
    final response = await _dio.get(AppConfig.learningPrompts);
    return LearningPromptsResponse.fromJson(response.data);
  }

  // RAG (Phase 11)
  Future<RAGStatsResponse> getRAGStats() async {
    final response = await _dio.get(AppConfig.ragStats);
    return RAGStatsResponse.fromJson(response.data);
  }

  Future<RAGDocumentsResponse> getRAGDocuments({int limit = 200}) async {
    final response = await _dio.get(
      AppConfig.ragDocuments,
      queryParameters: {'limit': limit},
    );
    return RAGDocumentsResponse.fromJson(response.data);
  }

  Future<RAGIngestResponse> ingestRAGDocument({
    String? text,
    String? title,
    String? docType,
    String? path,
  }) async {
    final data = <String, dynamic>{};
    if (text != null) data['text'] = text;
    if (title != null) data['title'] = title;
    if (docType != null) data['doc_type'] = docType;
    if (path != null) data['path'] = path;
    
    final response = await _dio.post(AppConfig.ragIngest, data: data);
    return RAGIngestResponse.fromJson(response.data);
  }

  Future<bool> deleteRAGDocument(String docId) async {
    try {
      final response = await _dio.delete('${AppConfig.ragDocument}$docId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<RAGSearchResponse> searchRAG({
    required String query,
    int limit = 5,
    String mode = 'hybrid',
  }) async {
    final response = await _dio.get(
      AppConfig.ragSearch,
      queryParameters: {'q': query, 'limit': limit, 'mode': mode},
    );
    return RAGSearchResponse.fromJson(response.data);
  }

  Future<RAGContextResponse> getRAGContext({
    required String query,
    int limit = 5,
    int maxChars = 6000,
  }) async {
    final response = await _dio.get(
      AppConfig.ragContext,
      queryParameters: {'q': query, 'limit': limit, 'max_chars': maxChars},
    );
    return RAGContextResponse.fromJson(response.data);
  }

  // Device Bridge / Phone Control
  Future<DeviceListResponse> getDeviceList() async {
    final response = await _dio.get(AppConfig.deviceList);
    return DeviceListResponse.fromJson(response.data);
  }

  Future<DevicePairStartResponse> startDevicePairing({String name = 'My computer'}) async {
    final response = await _dio.post(
      AppConfig.devicePairStart,
      data: {'name': name},
    );
    return DevicePairStartResponse.fromJson(response.data);
  }

  Future<DevicePairCompleteResponse> completeDevicePairing(String code) async {
    final response = await _dio.post(
      AppConfig.devicePairComplete,
      data: {'code': code},
    );
    return DevicePairCompleteResponse.fromJson(response.data);
  }

  Future<bool> revokeDevice(String deviceId) async {
    try {
      final response = await _dio.delete('${AppConfig.deviceRevoke}$deviceId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<DeviceHistoryResponse> getDeviceHistory(String deviceId, {int limit = 50}) async {
    final response = await _dio.get(
      '${AppConfig.deviceHistory}$deviceId/history',
      queryParameters: {'limit': limit},
    );
    return DeviceHistoryResponse.fromJson(response.data);
  }

  Future<DeviceCommandResponse> sendDeviceCommand({
    required String deviceId,
    required String action,
    Map<String, dynamic> params = const {},
  }) async {
    final response = await _dio.post(
      AppConfig.deviceCommand,
      data: {'device_id': deviceId, 'action': action, 'params': params},
    );
    return DeviceCommandResponse.fromJson(response.data);
  }

  Future<DeviceCommandResult> getDeviceCommandResult(String commandId) async {
    final response = await _dio.get('${AppConfig.deviceCommandResult}$commandId');
    return DeviceCommandResult.fromJson(response.data);
  }

  // Instance CRUD (Phase 14)
  Future<InstancesListResponse> getInstancesList() async {
    final response = await _dio.get(AppConfig.instancesList);
    return InstancesListResponse.fromJson(response.data);
  }

  Future<InstanceCreateResponse> createInstance({
    required String name,
    required String persona,
    List<String>? skills,
    double budgetUsd = 5.0,
  }) async {
    final response = await _dio.post(
      AppConfig.instancesCreate,
      data: {
        'name': name,
        'persona': persona,
        'skills': skills ?? [],
        'budget_usd': budgetUsd,
      },
    );
    return InstanceCreateResponse.fromJson(response.data);
  }

  Future<InstanceResponse> getInstance(String instanceId) async {
    final response = await _dio.get('${AppConfig.instancesGet}$instanceId');
    return InstanceResponse.fromJson(response.data);
  }

  Future<bool> deleteInstance(String instanceId) async {
    try {
      final response = await _dio.delete('${AppConfig.instancesDelete}$instanceId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Hosting API (Phase 15)
  Future<HostingAppsResponse> getHostingApps() async {
    final response = await _dio.get(AppConfig.hostingApps);
    return HostingAppsResponse.fromJson(response.data);
  }

  Future<HostingDeployResponse> deployHostingApp({
    required String name,
    required String kind,
    String entry = '',
    String path = '',
    String command = '',
    int? port,
    Map<String, String>? env,
    String? owner,
    bool autostart = true,
    bool tunnel = false,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'kind': kind,
      'entry': entry,
      'path': path,
      'command': command,
      'autostart': autostart,
      'tunnel': tunnel,
    };
    if (entry.isNotEmpty) data['entry'] = entry;
    if (path.isNotEmpty) data['path'] = path;
    if (command.isNotEmpty) data['command'] = command;
    if (port != null) data['port'] = port;
    if (env != null && env.isNotEmpty) data['env'] = env;
    if (owner != null) data['owner'] = owner;

    final response = await _dio.post(
      AppConfig.hostingDeploy,
      data: data,
    );
    return HostingDeployResponse.fromJson(response.data);
  }

  Future<HostingAppResponse> getHostingApp(String name) async {
    final response = await _dio.get('${AppConfig.hostingApp}$name');
    return HostingAppResponse.fromJson(response.data);
  }

  Future<bool> startHostingApp(String name) async {
    try {
      final response = await _dio.post('${AppConfig.hostingStart}$name/start');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stopHostingApp(String name) async {
    try {
      final response = await _dio.post('${AppConfig.hostingStop}$name/stop');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restartHostingApp(String name) async {
    try {
      final response = await _dio.post('${AppConfig.hostingRestart}$name/restart');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> openHostingTunnel(String name) async {
    try {
      final response = await _dio.post('${AppConfig.hostingTunnel}$name/tunnel');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<HostingLogsResponse> getHostingLogs(String name, {int lines = 100}) async {
    final response = await _dio.get(
      '${AppConfig.hostingLogs}$name/logs',
      queryParameters: {'lines': lines},
    );
    return HostingLogsResponse.fromJson(response.data);
  }

  Future<bool> removeHostingApp(String name) async {
    try {
      final response = await _dio.delete('${AppConfig.hostingRemove}$name');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Remote VPS Deploy (Phase 16)
  Future<RemoteConfigResponse> getRemoteConfig() async {
    final response = await _dio.get(AppConfig.remoteConfig);
    return RemoteConfigResponse.fromJson(response.data);
  }

  Future<RemoteDeployResponse> deployRemote({
    required String app,
    required String image,
    String? dockerfileDir,
    Map<String, String>? ports,
    Map<String, String>? env,
  }) async {
    final data = <String, dynamic>{
      'app': app,
      'image': image,
    };
    if (dockerfileDir != null) data['dockerfile_dir'] = dockerfileDir;
    if (ports != null && ports.isNotEmpty) data['ports'] = ports;
    if (env != null && env.isNotEmpty) data['env'] = env;

    final response = await _dio.post(
      AppConfig.remoteDeploy,
      data: data,
    );
    return RemoteDeployResponse.fromJson(response.data);
  }

  Future<RemoteActionResponse> remoteAction({
    required String app,
    required String action, // start, stop, restart, logs
  }) async {
    final response = await _dio.post(
      '${AppConfig.remoteAction}$app/$action',
    );
    return RemoteActionResponse.fromJson(response.data);
  }

  Future<RemoteLogsResponse> getRemoteLogs(String app, {int lines = 100}) async {
    final response = await _dio.get(
      '${AppConfig.remoteAction}$app/logs',
      queryParameters: {'lines': lines},
    );
    return RemoteLogsResponse.fromJson(response.data);
  }

  Future<CognitiveCycleResponse> triggerCognitiveCycle() async {
    final response = await _dio.post(AppConfig.cognitiveCycle);
    return CognitiveCycleResponse.fromJson(response.data);
  }

  Future<bool> pauseCognitiveLoop() async {
    try {
      final response = await _dio.post(AppConfig.cognitivePause);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resumeCognitiveLoop() async {
    try {
      final response = await _dio.post(AppConfig.cognitiveResume);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // WebSocket
  Stream<Map<String, dynamic>> get eventStream => _wsController.stream;
  bool get isConnected => _isConnected;

  void connectWebSocket() {
    if (_isConnected) return;

    final token = _getToken();
    if (token == null) return;

    try {
      _wsChannel = IOWebSocketChannel.connect(
        '${AppConfig.wsBaseUrl}${AppConfig.wsEvents}?token=$_storedToken',
      );

      _wsChannel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString());
            _wsController.add(json);
          } catch (e) {
            _logger.w('Failed to parse WS message: $e');
          }
        },
        onError: (error) {
          _logger.e('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          _logger.i('WebSocket disconnected');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _isConnected = true;
    } catch (e) {
      _logger.e('Failed to connect WebSocket: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connectWebSocket();
      }
    });
  }

  void disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _wsChannel?.sink.close();
    _wsChannel = null;
    _isConnected = false;
  }

  Future<HealthCheckResult> checkHealth() async {
    try {
      final response = await _dio.get('/health/live');
      return HealthCheckResult(
        live: true,
        ready: true,
        system: 'healthy',
        latency: 0,
        lastCheck: DateTime.now(),
      );
    } catch (e) {
      try {
        // Try the system health endpoint as fallback
        final response = await _dio.get('/health/system');
        return HealthCheckResult(
          live: true,
          ready: true,
          system: 'healthy',
          latency: 0,
          lastCheck: DateTime.now(),
        );
      } catch (e) {
        return HealthCheckResult(
          live: false,
          ready: false,
          system: 'unhealthy',
          latency: 0,
          lastCheck: DateTime.now(),
          error: e.toString(),
        );
}
    }
  }

// AGI Architecture (Phase 18 Part 1)
  Future<KernelStatusResponse> getKernelStatus({bool summary = false}) async {
    final response = await _dio.get(
      AppConfig.kernelStatus,
      queryParameters: {'summary': summary},
    );
    return KernelStatusResponse.fromJson(response.data);
  }

  Future<KernelProcessGoalResponse> processGoal({
    required String description,
    String priority = 'normal',
    bool execute = false,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      AppConfig.kernelProcessGoal,
      data: {
        'description': description,
        'priority': priority,
        'execute': execute,
        'metadata': metadata ?? {},
      },
    );
    return KernelProcessGoalResponse.fromJson(response.data);
  }

  Future<KernelCheckpointResponse> createCheckpoint() async {
    final response = await _dio.post(AppConfig.kernelCheckpoint);
    return KernelCheckpointResponse.fromJson(response.data);
  }

  Future<KernelCheckpointsResponse> getCheckpoints() async {
    final response = await _dio.get(AppConfig.kernelCheckpoints);
    return KernelCheckpointsResponse.fromJson(response.data);
  }

  Future<KernelAuditResponse> getKernelAudit({int limit = 5}) async {
    final response = await _dio.get(
      AppConfig.kernelAudit,
      queryParameters: {'limit': limit},
    );
    return KernelAuditResponse.fromJson(response.data);
  }

  Future<KernelRestoreResponse> restoreCheckpoint(String checkpointId) async {
    final response = await _dio.post(
      AppConfig.kernelRestore,
      data: {'checkpoint_id': checkpointId},
    );
    return KernelRestoreResponse.fromJson(response.data);
  }

  Future<KernelIncompleteGoalsResponse> kernelGetIncompleteGoals() async {
    final response = await _dio.get(AppConfig.kernelIncompleteGoals);
    return KernelIncompleteGoalsResponse.fromJson(response.data);
  }

  Future<KernelResumeGoalResponse> kernelResumeGoal(String goalId, {bool execute = false}) async {
    final response = await _dio.post(
      '${AppConfig.kernelResumeGoal}$goalId/resume',
      data: {'execute': execute},
    );
    return KernelResumeGoalResponse.fromJson(response.data);
  }

  Future<KernelResumeIncompleteResponse> kernelResumeIncomplete({bool planProposals = true, int maxGoals = 3}) async {
    final response = await _dio.post(
      AppConfig.kernelResumeIncomplete,
      data: {'plan_proposals': planProposals, 'max_goals': maxGoals},
    );
    return KernelResumeIncompleteResponse.fromJson(response.data);
  }

  Future<PlanCreateResponse> createPlan(String goalId) async {
    final response = await _dio.post(
      AppConfig.planCreate,
      data: {'goal_id': goalId},
    );
    return PlanCreateResponse.fromJson(response.data);
  }

  Future<PlanGetResponse> getPlan(String planId) async {
    final response = await _dio.get('${AppConfig.planGet}$planId');
    return PlanGetResponse.fromJson(response.data);
  }

  Future<PlanExecuteResponse> executePlan(String planId) async {
    final response = await _dio.post('${AppConfig.planExecute}$planId/execute');
    return PlanExecuteResponse.fromJson(response.data);
  }

  Future<PlanReplanResponse> replanPlan(String planId, {int fromStep = 0, String? reason}) async {
    final response = await _dio.post(
      '${AppConfig.planReplan}$planId/replan',
      data: {'from_step': fromStep, 'reason': reason ?? ''},
    );
    return PlanReplanResponse.fromJson(response.data);
  }

  Future<SynthesizeCreateResponse> createSynthesis({
    required String goal,
    List<String>? requirements,
    bool asyncMode = true,
  }) async {
    final response = await _dio.post(
      AppConfig.synthesizeCreate,
      data: {
        'goal': goal,
        'requirements': requirements ?? [],
        'async': asyncMode,
      },
    );
    return SynthesizeCreateResponse.fromJson(response.data);
  }

  Future<SynthesizeGetResponse> getSynthesis(String jobId) async {
    final response = await _dio.get('${AppConfig.synthesizeGet}$jobId');
    return SynthesizeGetResponse.fromJson(response.data);
  }

  Future<SynthesizeStatsResponse> getSynthesizeStats() async {
    final response = await _dio.get(AppConfig.synthesizeStats);
    return SynthesizeStatsResponse.fromJson(response.data);
  }

  Future<MetaStatusResponse> getMetaStatus() async {
    final response = await _dio.get(AppConfig.metaStatus);
    return MetaStatusResponse.fromJson(response.data);
  }

  Future<MetaMonitorResponse> monitorMeta({required String context}) async {
    final response = await _dio.post(
      AppConfig.metaMonitor,
      data: {'context': context},
    );
    return MetaMonitorResponse.fromJson(response.data);
  }

  Future<MetaStepResultResponse> submitMetaStepResult({
    required String context,
    required dynamic expected,
    required dynamic actual,
    required bool verified,
  }) async {
    final response = await _dio.post(
      AppConfig.metaStepResult,
      data: {
        'context': context,
        'expected': expected,
        'actual': actual,
        'verified': verified,
      },
    );
    return MetaStepResultResponse.fromJson(response.data);
  }

  Future<MetaEventsResponse> getMetaEvents({int limit = 5}) async {
    final response = await _dio.get(
      AppConfig.metaEvents,
      queryParameters: {'limit': limit},
    );
    return MetaEventsResponse.fromJson(response.data);
  }


  // AGI Architecture Part 2 (Phase 18 Part 2) - Synthesizer, Society, Procedural Memory

  // Synthesizer
  Future<SynthesizeListResponse> getSynthesisList() async {
    final response = await _dio.get(AppConfig.synthesizeList);
    return SynthesizeListResponse.fromJson(response.data);
  }

  // Society
  Future<SocietyStatusResponse> getSocietyStatus() async {
    final response = await _dio.get(AppConfig.societyStatus);
    return SocietyStatusResponse.fromJson(response.data);
  }

  Future<SocietySpawnResponse> spawnAgent({
    required String role,
    required String spec,
  }) async {
    final response = await _dio.post(
      AppConfig.societySpawn,
      data: {"role": role, "spec": spec},
    );
    return SocietySpawnResponse.fromJson(response.data);
  }

  Future<SocietyAgentsResponse> getSocietyAgents() async {
    final response = await _dio.get(AppConfig.societyAgents);
    return SocietyAgentsResponse.fromJson(response.data);
  }

  Future<SocietyTaskResponse> assignAgentTask({
    required String agentId,
    required Map<String, dynamic> task,
  }) async {
    final response = await _dio.post(
      "${AppConfig.societyAgentTask}$agentId/task",
      data: task,
    );
    return SocietyTaskResponse.fromJson(response.data);
  }

  Future<SocietyTenderResponse> tenderTask({
    required Map<String, dynamic> taskSpec,
    required String deadline,
    List<String>? eligibleRoles,
  }) async {
    final response = await _dio.post(
      AppConfig.societyTender,
      data: {
        "task_spec": taskSpec,
        "deadline": deadline,
        "eligible_roles": eligibleRoles ?? [],
      },
    );
    return SocietyTenderResponse.fromJson(response.data);
  }

  Future<SocietyBidResponse> bidTask({
    required String taskId,
    required String agentId,
  }) async {
    final response = await _dio.post(
      "${AppConfig.societyBid}$taskId/bid",
      data: {"agent_id": agentId},
    );
    return SocietyBidResponse.fromJson(response.data);
  }

  Future<SocietyAwardResponse> awardTask({
    required String taskId,
    required String agentId,
  }) async {
    final response = await _dio.post(
      "${AppConfig.societyAward}$taskId/award",
      data: {"agent_id": agentId},
    );
    return SocietyAwardResponse.fromJson(response.data);
  }

  Future<SocietyBlackboardWriteResponse> writeBlackboard({
    required String agentId,
    required String key,
    required dynamic value,
    List<String>? tags,
    int? ttl,
  }) async {
    final response = await _dio.post(
      AppConfig.societyBlackboardWrite,
      data: {
        "agent_id": agentId,
        "key": key,
        "value": value,
        "tags": tags ?? [],
        "ttl": ttl,
      },
    );
    return SocietyBlackboardWriteResponse.fromJson(response.data);
  }

  Future<SocietyBlackboardReadResponse> readBlackboard({
    required String key,
  }) async {
    final response = await _dio.get(
      AppConfig.societyBlackboardRead,
      queryParameters: {"key": key},
    );
    return SocietyBlackboardReadResponse.fromJson(response.data);
  }

  Future<SocietyBlackboardQueryResponse> queryBlackboard({
    required String pattern,
  }) async {
    final response = await _dio.get(
      AppConfig.societyBlackboardQuery,
      queryParameters: {"pattern": pattern},
    );
    return SocietyBlackboardQueryResponse.fromJson(response.data);
  }

  // Procedural Memory
  Future<ProceduralListResponse> getProceduralSkills({
    bool? verified,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      AppConfig.proceduralList,
      queryParameters: {
        if (verified != null) "verified": verified,
        "limit": limit,
      },
    );
    return ProceduralListResponse.fromJson(response.data);
  }

  Future<ProceduralApplicableResponse> getApplicableProcedures({
    required String goal,
    String? context,
  }) async {
    final response = await _dio.get(
      AppConfig.proceduralApplicable,
      queryParameters: {
        "goal": goal,
        if (context != null) "context": context,
      },
    );
    return ProceduralApplicableResponse.fromJson(response.data);
  }

  Future<ProceduralUseResponse> useProceduralSkill({
    required String skillId,
    required bool success,
    double? reward,
  }) async {
    final response = await _dio.post(
      "${AppConfig.proceduralUse}$skillId/use",
      data: {
        "success": success,
        if (reward != null) "reward": reward,
      },
    );
    return ProceduralUseResponse.fromJson(response.data);
  }

  Future<ProceduralStatsResponse> getProceduralStats() async {
    final response = await _dio.get(AppConfig.proceduralStats);
    return ProceduralStatsResponse.fromJson(response.data);
  }

  Future<ProceduralSearchResponse> searchProcedural({
    required String query,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      AppConfig.proceduralSearch,
      queryParameters: {"q": query, "limit": limit},
    );
    return ProceduralSearchResponse.fromJson(response.data);
  }

  Future<ProceduralComposeResponse> composeProcedural({
    required List<String> skillIds,
    required String name,
    required String description,
  }) async {
    final response = await _dio.post(
      AppConfig.proceduralCompose,
      data: {
        "skill_ids": skillIds,
        "name": name,
        "description": description,
      },
    );
    return ProceduralComposeResponse.fromJson(response.data);
  }

  // Maya Cognitive Core (Phase 19)

  Future<CoreStatusResponse> getCoreStatus() async {
    final response = await _dio.get(AppConfig.coreStatus);
    return CoreStatusResponse.fromJson(response.data);
  }

  Future<CoreInitializeResponse> initializeCore() async {
    final response = await _dio.post(AppConfig.coreInitialize);
    return CoreInitializeResponse.fromJson(response.data);
  }

  Future<CoreLoopResponse> startCoreLoop({double interval = 30.0}) async {
    final response = await _dio.post(
      AppConfig.coreLoopStart,
      queryParameters: {"interval": interval},
    );
    return CoreLoopResponse.fromJson(response.data);
  }

  Future<CoreLoopResponse> pauseCoreLoop() async {
    final response = await _dio.post(AppConfig.coreLoopPause);
    return CoreLoopResponse.fromJson(response.data);
  }

  Future<CoreLoopResponse> resumeCoreLoop() async {
    final response = await _dio.post(AppConfig.coreLoopResume);
    return CoreLoopResponse.fromJson(response.data);
  }

  Future<CoreLoopResponse> stopCoreLoop() async {
    final response = await _dio.post(AppConfig.coreLoopStop);
    return CoreLoopResponse.fromJson(response.data);
  }

  Future<CoreMissionResponse> runMission({
    required String description,
    String missionType = "general",
    bool selfGen = true,
  }) async {
    final response = await _dio.post(
      AppConfig.coreRunMission,
      data: {
        "description": description,
        "mission_type": missionType,
        "self_gen": selfGen,
      },
    );
    return CoreMissionResponse.fromJson(response.data);
  }

  Future<CoreGoalResponse> executeGoal({
    required String goal,
    int maxSteps = 10,
  }) async {
    final response = await _dio.post(
      AppConfig.coreExecuteGoal,
      data: {
        "goal": goal,
        "max_steps": maxSteps,
      },
    );
    return CoreGoalResponse.fromJson(response.data);
  }

  Future<CoreIdentityResponse> getIdentity() async {
    final response = await _dio.get(AppConfig.coreIdentity);
    return CoreIdentityResponse.fromJson(response.data);
  }

  Future<CoreModelsResponse> getModels() async {
    final response = await _dio.get(AppConfig.coreModels);
    return CoreModelsResponse.fromJson(response.data);
  }

  Future<CoreSwitchModelResponse> switchModel(String modelId) async {
    final response = await _dio.post(
      AppConfig.coreSwitchModel,
      data: {"model_id": modelId},
    );
    return CoreSwitchModelResponse.fromJson(response.data);
  }

  Future<CoreInvokeModelResponse> invokeModel({
    required String prompt,
    String? modelId,
    String taskType = "general",
    int maxTokens = 4000,
  }) async {
    final response = await _dio.post(
      AppConfig.coreInvokeModel,
      data: {
        "prompt": prompt,
        if (modelId != null) "model_id": modelId,
        "task_type": taskType,
        "max_tokens": maxTokens,
      },
    );
    return CoreInvokeModelResponse.fromJson(response.data);
  }

  Future<CoreCheckpointResponse> createCoreCheckpoint() async {
    final response = await _dio.post(AppConfig.coreCheckpoint);
    return CoreCheckpointResponse.fromJson(response.data);
  }

  Future<CoreRestoreCheckpointResponse> restoreCoreCheckpoint(String checkpointId) async {
    final response = await _dio.post(
      AppConfig.coreRestoreCheckpoint,
      data: {"checkpoint_id": checkpointId},
    );
    return CoreRestoreCheckpointResponse.fromJson(response.data);
  }

  Future<CoreCheckpointsResponse> listCheckpoints() async {
    final response = await _dio.get(AppConfig.coreCheckpoints);
    return CoreCheckpointsResponse.fromJson(response.data);
  }

  Future<CoreAuditResponse> getCoreAudit({int limit = 50}) async {
    final response = await _dio.get(
      AppConfig.coreAudit,
      queryParameters: {"limit": limit},
    );
    return CoreAuditResponse.fromJson(response.data);
  }

  Future<CoreShutdownResponse> shutdownCore() async {
    final response = await _dio.post(AppConfig.coreShutdown);
    return CoreShutdownResponse.fromJson(response.data);
  }

  // Unified Cognitive Loop (Phase 34)
  Future<UnifiedLoopStatusResponse> getUnifiedLoopStatus() async {
    final response = await _dio.get(AppConfig.unifiedLoopStatus);
    return UnifiedLoopStatusResponse.fromJson(response.data);
  }

  Future<UnifiedLoopHistoryResponse> getUnifiedLoopHistory({int limit = 50}) async {
    final response = await _dio.get(
      AppConfig.unifiedLoopHistory,
      queryParameters: {'limit': limit},
    );
    return UnifiedLoopHistoryResponse.fromJson(response.data);
  }

  Future<UnifiedLoopControlResponse> startUnifiedLoop({double interval = 30.0}) async {
    final response = await _dio.post(
      AppConfig.coreLoopStart,
      queryParameters: {'interval': interval},
    );
    return UnifiedLoopControlResponse.fromJson(response.data);
  }

  Future<UnifiedLoopControlResponse> pauseUnifiedLoop() async {
    final response = await _dio.post(AppConfig.coreLoopPause);
    return UnifiedLoopControlResponse.fromJson(response.data);
  }

  Future<UnifiedLoopControlResponse> resumeUnifiedLoop() async {
    final response = await _dio.post(AppConfig.coreLoopResume);
    return UnifiedLoopControlResponse.fromJson(response.data);
  }

  Future<UnifiedLoopControlResponse> stopUnifiedLoop() async {
    final response = await _dio.post(AppConfig.coreLoopStop);
    return UnifiedLoopControlResponse.fromJson(response.data);
  }

  // Persistent Goal Pursuit (Phase 35)
  Future<GoalsListResponse> getIncompleteGoals() async {
    final response = await _dio.get(AppConfig.goalsIncomplete);
    return GoalsListResponse.fromJson(response.data);
  }

  Future<GoalsListResponse> getGoals({String? status}) async {
    final response = await _dio.get(
      AppConfig.goalsList,
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    return GoalsListResponse.fromJson(response.data);
  }

  Future<GoalDetailResponse> getGoalDetail(String goalId) async {
    final response = await _dio.get('${AppConfig.goalDetail}$goalId');
    return GoalDetailResponse.fromJson(response.data);
  }

  Future<GoalResumeResponse> resumeGoal({
    required String goalId,
    bool execute = false,
  }) async {
    final response = await _dio.post(
      '${AppConfig.goalResume}$goalId/resume',
      data: {'execute': execute},
    );
    return GoalResumeResponse.fromJson(response.data);
  }

  Future<GoalCreateResponse> createGoal({
    required String description,
    String? parentId,
    double priority = 50.0,
    String? successCriteria,
    List<String>? constraints,
    List<String>? requiredCapabilities,
  }) async {
    final response = await _dio.post(
      AppConfig.goalCreate,
      data: {
        'description': description,
        if (parentId != null) 'parent_id': parentId,
        'priority': priority,
        if (successCriteria != null) 'success_criteria': successCriteria,
        if (constraints != null) 'constraints': constraints,
        if (requiredCapabilities != null) 'required_capabilities': requiredCapabilities,
      },
    );
    return GoalCreateResponse.fromJson(response.data);
  }

  Future<GoalUpdateResponse> updateGoal({
    required String goalId,
    Map<String, dynamic>? updates,
  }) async {
    final response = await _dio.patch(
      '${AppConfig.goalUpdate}$goalId',
      data: updates ?? {},
    );
    return GoalUpdateResponse.fromJson(response.data);
  }

  Future<GoalDecomposeResponse> decomposeGoal({
    required String goalId,
    int numSubgoals = 5,
  }) async {
    final response = await _dio.post(
      '${AppConfig.goalDecompose}$goalId/decompose',
      data: {'num_subgoals': numSubgoals},
    );
    return GoalDecomposeResponse.fromJson(response.data);
  }

  // Hippocampus / Episodic Memory
  Future<EpisodicListResponse> getEpisodicMemory({
    int limit = 50,
    String? outcome,
  }) async {
    final response = await _dio.get(
      AppConfig.episodicList,
      queryParameters: {
        "limit": limit,
        if (outcome != null) "outcome": outcome,
      },
    );
    return EpisodicListResponse.fromJson(response.data);
  }

  Future<EpisodicSearchResponse> searchEpisodicMemory({
    required String goal,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      AppConfig.episodicSearch,
      queryParameters: {"goal": goal, "limit": limit},
    );
    return EpisodicSearchResponse.fromJson(response.data);
  }

  Future<EpisodicStatsResponse> getEpisodicStats() async {
    final response = await _dio.get(AppConfig.episodicStats);
    return EpisodicStatsResponse.fromJson(response.data);
  }

  Future<HippocampusSchemaQueryResponse> queryHippocampusSchema({
    required String query,
    int limit = 10,
  }) async {
    final response = await _dio.post(
      AppConfig.hippocampusSchemaQuery,
      data: {"query": query, "limit": limit},
    );
    return HippocampusSchemaQueryResponse.fromJson(response.data);
  }

  Future<HippocampusSchemaApplyResponse> applyHippocampusSchema({
    required String schemaId,
    required Map<String, dynamic> context,
  }) async {
    final response = await _dio.post(
      AppConfig.hippocampusSchemaApply,
      data: {"schema_id": schemaId, "context": context},
    );
    return HippocampusSchemaApplyResponse.fromJson(response.data);
  }

  // Semantic Memory / Knowledge
  Future<KnowledgeQueryResponse> queryKnowledge({
    String query = "",
    String? domain,
    int limit = 5,
  }) async {
    final response = await _dio.get(
      AppConfig.knowledgeQuery,
      queryParameters: {
        if (query.isNotEmpty) "q": query,
        if (domain != null) "domain": domain,
        "limit": limit,
      },
    );
    return KnowledgeQueryResponse.fromJson(response.data);
  }

  Future<KnowledgeStatsResponse> getKnowledgeStats() async {
    final response = await _dio.get(AppConfig.knowledgeStats);
    return KnowledgeStatsResponse.fromJson(response.data);
  }

  Future<KnowledgeLearnResponse> learnKnowledge({
    required String proposition,
    double confidence = 0.6,
    String source = "testimony",
    String domain = "general",
    Map<String, dynamic>? evidence,
  }) async {
    final response = await _dio.post(
      AppConfig.knowledgeLearn,
      data: {
        "proposition": proposition,
        "confidence": confidence,
        "source": source,
        "domain": domain,
        if (evidence != null) "evidence": evidence,
      },
    );
    return KnowledgeLearnResponse.fromJson(response.data);
  }

  // Beliefs (Phase 36 - Knowledge Engine)
  Future<BeliefAddResponse> addBelief({
    required String proposition,
    double confidence = 0.5,
    String? evidence,
    String source = "observation",
    String domain = "general",
  }) async {
    final response = await _dio.post(
      AppConfig.beliefsAdd,
      data: {
        "proposition": proposition,
        "confidence": confidence,
        if (evidence != null) "evidence": evidence,
        "source": source,
        "domain": domain,
      },
    );
    return BeliefAddResponse.fromJson(response.data);
  }

  Future<BeliefsQueryResponse> queryBeliefs({
    String? domain,
    double minConfidence = 0.0,
  }) async {
    final response = await _dio.get(
      AppConfig.beliefsQuery,
      queryParameters: {
        if (domain != null) "domain": domain,
        "min_conf": minConfidence,
      },
    );
    return BeliefsQueryResponse.fromJson(response.data);
  }

  // MCP Client (Phase 38)
  Future<McpStatusResponse> getMcpStatus() async {
    final response = await _dio.get(AppConfig.mcpStatus);
    return McpStatusResponse.fromJson(response.data);
  }

  Future<McpConnectResponse> connectMcpServer({
    required String name,
    List<String>? command,
    String? url,
    List<String>? toolsAllow,
    List<String>? toolsDeny,
  }) async {
    final response = await _dio.post(
      AppConfig.mcpConnect,
      data: {
        'name': name,
        if (command != null) 'command': command,
        if (url != null) 'url': url,
        if (toolsAllow != null) 'tools_allow': toolsAllow,
        if (toolsDeny != null) 'tools_deny': toolsDeny,
      },
    );
    return McpConnectResponse.fromJson(response.data);
  }

  Future<McpDisconnectResponse> disconnectMcpServer() async {
    final response = await _dio.post(AppConfig.mcpDisconnect);
    return McpDisconnectResponse.fromJson(response.data);
  }

  Future<McpCallResponse> callMcpTool({
    required String server,
    required String tool,
    Map<String, dynamic>? arguments,
  }) async {
    final response = await _dio.post(
      '${AppConfig.mcpCall}$server/$tool',
      data: arguments ?? {},
    );
    return McpCallResponse.fromJson(response.data);
  }

  // Self Model (Phase 39)
  Future<SelfProfileResponse> getSelfProfile() async {
    final response = await _dio.get(AppConfig.selfProfile);
    return SelfProfileResponse.fromJson(response.data);
  }

  Future<SelfAssessResponse> assessSelf({required String goal}) async {
    final response = await _dio.get(
      AppConfig.selfAssess,
      queryParameters: {'q': goal},
    );
    return SelfAssessResponse.fromJson(response.data);
  }

  Future<SelfTraitResponse> setSelfTrait({
    required String key,
    required dynamic value,
  }) async {
    final response = await _dio.post(
      AppConfig.selfTraits,
      data: {'key': key, 'value': value},
    );
    return SelfTraitResponse.fromJson(response.data);
  }

  // Working Memory
  Future<WorkingMemoryAddResponse> addWorkingMemory({
    required String content,
    String type = "fact",
    double attention = 1.0,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? bindings,
  }) async {
    final response = await _dio.post(
      AppConfig.workingMemoryAdd,
      data: {
        "content": content,
        "type": type,
        "attention": attention,
        if (metadata != null) "metadata": metadata,
        if (bindings != null) "bindings": bindings,
      },
    );
    return WorkingMemoryAddResponse.fromJson(response.data);
  }

  Future<WorkingMemorySearchResponse> searchWorkingMemory({
    required String query,
    int limit = 10,
    String? type,
  }) async {
    final response = await _dio.get(
      AppConfig.workingMemorySearch,
      queryParameters: {
        "q": query,
        "limit": limit,
        if (type != null) "type": type,
      },
    );
    return WorkingMemorySearchResponse.fromJson(response.data);
  }

  Future<WorkingMemoryCapacityResponse> getWorkingMemoryCapacity() async {
    final response = await _dio.get(AppConfig.workingMemoryCapacity);
    return WorkingMemoryCapacityResponse.fromJson(response.data);
  }

  // Working Memory v2
  Future<WMAddResponse> wmAdd({
    required String content,
    String? chunkId,
    double attention = 1.0,
  }) async {
    final response = await _dio.post(
      AppConfig.workingMemoryV2Add,
      data: {
        "content": content,
        if (chunkId != null) "chunk_id": chunkId,
        "attention": attention,
      },
    );
    return WMAddResponse.fromJson(response.data);
  }

  Future<WMRetrieveResponse> wmRetrieve({
    required String query,
    int limit = 10,
  }) async {
    final response = await _dio.post(
      AppConfig.workingMemoryV2Retrieve,
      data: {"query": query, "limit": limit},
    );
    return WMRetrieveResponse.fromJson(response.data);
  }

  Future<WMDecayResponse> wmDecay() async {
    final response = await _dio.post(AppConfig.workingMemoryV2Decay);
    return WMDecayResponse.fromJson(response.data);
  }

  // Browser & Sandbox
  Future<BrowserActionResponse> browserAction({
    required String action,
    String? url,
    String? selector,
    String? text,
    String? query,
  }) async {
    final response = await _dio.post(
      AppConfig.browserAction,
      data: {
        "action": action,
        if (url != null) "url": url,
        if (selector != null) "selector": selector,
        if (text != null) "text": text,
        if (query != null) "query": query,
      },
    );
    return BrowserActionResponse.fromJson(response.data);
  }

  Future<SandboxExecuteResponse> sandboxExecute({
    required String code,
    String language = "python",
    int timeoutSeconds = 30,
  }) async {
    final response = await _dio.post(
      AppConfig.sandboxExecute,
      data: {
        "code": code,
        "language": language,
        "timeout_seconds": timeoutSeconds,
      },
    );
    return SandboxExecuteResponse.fromJson(response.data);
  }

  // Business Analysis (Phase 20)
  Future<MissionListResponse> getBusinessMissions({bool activeOnly = false}) async {
    final response = await _dio.get(
      AppConfig.missionsList,
      queryParameters: {
        'mission_type': 'business',
        'active_only': activeOnly,
      },
    );
    return MissionListResponse.fromJson(response.data);
  }

  Future<BusinessAnalyzeResponse> runBusinessAnalysis({
    required String missionId,
    String? objectiveId,
  }) async {
    final response = await _dio.post(
      '${AppConfig.missionAnalyze}$missionId/analyze',
      data: {
        if (objectiveId != null) 'objective_id': objectiveId,
      },
    );
    return BusinessAnalyzeResponse.fromJson(response.data);
  }

  Future<BusinessReportsListResponse> getBusinessReports(String missionId) async {
    final response = await _dio.get(
      '${AppConfig.missionReports}$missionId/reports',
    );
    return BusinessReportsListResponse.fromJson(response.data);
  }

  Future<BusinessReportDetailResponse> getBusinessReport({
    required String missionId,
    required String reportId,
  }) async {
    final response = await _dio.get(
      '${AppConfig.missionReportDetail}$missionId/reports/$reportId',
    );
    return BusinessReportDetailResponse.fromJson(response.data);
  }

  // Guarded Publish (Phase 21)
  Future<PublishProposeResponse> proposePublish({
    required String siteName,
    required Map<String, String> files,
    String description = '',
  }) async {
    final response = await _dio.post(
      AppConfig.publishPropose,
      data: {
        'site_name': siteName,
        'files': files,
        'description': description,
      },
    );
    return PublishProposeResponse.fromJson(response.data);
  }

  Future<PublishHistoryListResponse> getPublishHistory() async {
    final response = await _dio.get(AppConfig.publishHistory);
    return PublishHistoryListResponse.fromJson(response.data);
  }

  Future<PublishHistoryDetailResponse> getPublishHistoryDetail(String proposalId) async {
    final response = await _dio.get('${AppConfig.publishHistoryDetail}$proposalId');
    return PublishHistoryDetailResponse.fromJson(response.data);
  }

  Future<PublishDecideResponse> decidePublish({
    required String proposalId,
    required String decision, // 'approve' or 'reject'
  }) async {
    final response = await _dio.post(
      '${AppConfig.publishHistoryDetail}$proposalId/decide',
      data: {'decision': decision},
    );
    return PublishDecideResponse.fromJson(response.data);
  }

  // Approvals System (Phase 21 Enhanced)
  Future<ApprovalRequestResponse> requestApproval({
    required String action,
    String reason = '',
    String riskLevel = 'low',
  }) async {
    final response = await _dio.post(
      AppConfig.approvalsRequest,
      data: {
        'action': action,
        'reason': reason,
        'risk_level': riskLevel,
      },
    );
    return ApprovalRequestResponse.fromJson(response.data);
  }

  Future<ApprovalModeResponse> setApprovalMode(String mode) async {
    final response = await _dio.put(
      AppConfig.approvalMode,
      data: {'mode': mode},
    );
    return ApprovalModeResponse.fromJson(response.data);
  }

  // API Key Provisioner (Phase 33)
  Future<ProvisionerSearchResponse> searchFreeApis({String? providerFilter}) async {
    final response = await _dio.post(
      AppConfig.provisionerSearchFree,
      data: {
        if (providerFilter != null) 'provider_filter': providerFilter,
      },
    );
    return ProvisionerSearchResponse.fromJson(response.data);
  }

  Future<ProvisionerProvisionResponse> provisionApiKey({
    required String provider,
    String? email,
    String? name,
  }) async {
    final response = await _dio.post(
      AppConfig.provisionerProvision,
      data: {
        'provider': provider,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
      },
    );
    return ProvisionerProvisionResponse.fromJson(response.data);
  }

  Future<ProvisionerAuditResponse> getProvisionerAudit({int limit = 50}) async {
    final response = await _dio.get(
      AppConfig.provisionerAudit,
      queryParameters: {'limit': limit},
    );
    return ProvisionerAuditResponse.fromJson(response.data);
  }

  // Communication Tools (Phase 33)
  Future<EmailToolResponse> runEmailTool({
    required String action,
    String? to,
    String? subject,
    String? body,
  }) async {
    final response = await _dio.post(
      AppConfig.emailToolRun,
      data: {
        'action': action,
        if (to != null) 'to': to,
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );
    return EmailToolResponse.fromJson(response.data);
  }

  Future<WebhookToolResponse> runWebhookTool({
    required String action,
    String? message,
    String? channel,
    String? title,
    Map<String, dynamic>? rawPayload,
  }) async {
    final response = await _dio.post(
      AppConfig.webhookToolRun,
      data: {
        'action': action,
        if (message != null) 'message': message,
        if (channel != null) 'channel': channel,
        if (title != null) 'title': title,
        if (rawPayload != null) 'raw_payload': rawPayload,
      },
    );
    return WebhookToolResponse.fromJson(response.data);
  }
}

// AGI Architecture Models (Phase 18 Part 1)
@freezed
class KernelStatusResponse with _$KernelStatusResponse {
  const factory KernelStatusResponse({
    required bool running,
    required String status,
    required int activeGoals,
    required int activeAgents,
    required int memoryItems,
    required int totalCheckpoints,
    required String uptime,
  }) = _KernelStatusResponse;

  factory KernelStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelStatusResponseFromJson(json);
}

@freezed
class KernelProcessGoalResponse with _$KernelProcessGoalResponse {
  const factory KernelProcessGoalResponse({
    required bool ok,
    required String goalId,
    required String status,
    required String plan,
    List<String>? steps,
  }) = _KernelProcessGoalResponse;

  factory KernelProcessGoalResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelProcessGoalResponseFromJson(json);
}

@freezed
class KernelCheckpointResponse with _$KernelCheckpointResponse {
  const factory KernelCheckpointResponse({
    required bool ok,
    required String checkpointId,
    required String goalId,
    required String status,
    required double timestamp,
  }) = _KernelCheckpointResponse;

  factory KernelCheckpointResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelCheckpointResponseFromJson(json);
}

@freezed
class KernelCheckpointsResponse with _$KernelCheckpointsResponse {
  const factory KernelCheckpointsResponse({
    @JsonKey(fromJson: _checkpointsFromJson, toJson: _checkpointsToJson)
    required List<KernelCheckpoint> checkpoints,
  }) = _KernelCheckpointsResponse;

  factory KernelCheckpointsResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelCheckpointsResponseFromJson(json);
}

@JsonSerializable()
class KernelCheckpointsResponseWrapper {
  @JsonKey(fromJson: _checkpointsFromJson, toJson: _checkpointsToJson)
  final List<KernelCheckpoint> checkpoints;

  const KernelCheckpointsResponseWrapper({
    required this.checkpoints,
  });

  factory KernelCheckpointsResponseWrapper.fromJson(Map<String, dynamic> json) =>
      _$KernelCheckpointsResponseWrapperFromJson(json);

  Map<String, dynamic> toJson() => _$KernelCheckpointsResponseWrapperToJson(this);
}

List<KernelCheckpoint> _checkpointsFromJson(List<dynamic> json) =>
    json.map((e) => KernelCheckpoint.fromJson(e as Map<String, dynamic>)).toList();

List<dynamic> _checkpointsToJson(List<KernelCheckpoint> checkpoints) =>
    checkpoints.map((e) => e.toJson()).toList();



@freezed
class KernelCheckpoint with _$KernelCheckpoint {
  const factory KernelCheckpoint({
    required String id,
    required String goalId,
    required String status,
    required double timestamp,
    @Default('') @JsonKey(includeIfNull: false) String stateJson,
  }) = _KernelCheckpoint;

  factory KernelCheckpoint.fromJson(Map<String, dynamic> json) =>
      _$KernelCheckpointFromJson(json);
}

@freezed
class KernelAuditResponse with _$KernelAuditResponse {
  const factory KernelAuditResponse({
    required List<KernelAuditEntry> entries,
  }) = _KernelAuditResponse;

  factory KernelAuditResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelAuditResponseFromJson(json);
}

@JsonSerializable()
class KernelAuditEntry {
  final String id;
  final String action;
  final String goalId;
  final String result;
  final double timestamp;

  const KernelAuditEntry({
    required this.id,
    required this.action,
    required this.goalId,
    required this.result,
    required this.timestamp,
  });

  factory KernelAuditEntry.fromJson(Map<String, dynamic> json) =>
      _$KernelAuditEntryFromJson(json);

  Map<String, dynamic> toJson() => _$KernelAuditEntryToJson(this);
}

@freezed
class KernelRestoreResponse with _$KernelRestoreResponse {
  const factory KernelRestoreResponse({
    required bool ok,
    required String checkpointId,
    required String goalId,
    required String status,
  }) = _KernelRestoreResponse;

  factory KernelRestoreResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelRestoreResponseFromJson(json);
}

@freezed
class KernelIncompleteGoalsResponse with _$KernelIncompleteGoalsResponse {
  const factory KernelIncompleteGoalsResponse({
    required List<String> goalIds,
    required int count,
  }) = _KernelIncompleteGoalsResponse;

  factory KernelIncompleteGoalsResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelIncompleteGoalsResponseFromJson(json);
}

@freezed
class KernelResumeGoalResponse with _$KernelResumeGoalResponse {
  const factory KernelResumeGoalResponse({
    required bool ok,
    required String goalId,
    required String status,
    String? plan,
  }) = _KernelResumeGoalResponse;

  factory KernelResumeGoalResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelResumeGoalResponseFromJson(json);
}

@freezed
class KernelResumeIncompleteResponse with _$KernelResumeIncompleteResponse {
  const factory KernelResumeIncompleteResponse({
    required bool ok,
    required List<String> resumedGoalIds,
    required int count,
  }) = _KernelResumeIncompleteResponse;

  factory KernelResumeIncompleteResponse.fromJson(Map<String, dynamic> json) =>
      _$KernelResumeIncompleteResponseFromJson(json);
}

@freezed
class PlanCreateResponse with _$PlanCreateResponse {
  const factory PlanCreateResponse({
    required String planId,
    required String goal,
    required List<PlanStep> steps,
  }) = _PlanCreateResponse;

  factory PlanCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$PlanCreateResponseFromJson(json);
}

@JsonSerializable()
class PlanStep {
  final String id;
  final String description;
  final String agent;
  final String tool;
  final Map<String, dynamic> params;
  final String status;

  const PlanStep({
    required this.id,
    required this.description,
    required this.agent,
    required this.tool,
    required this.params,
    required this.status,
  });

  factory PlanStep.fromJson(Map<String, dynamic> json) =>
      _$PlanStepFromJson(json);

  Map<String, dynamic> toJson() => _$PlanStepToJson(this);
}

@freezed
class PlanGetResponse with _$PlanGetResponse {
  const factory PlanGetResponse({
    required String planId,
    required String goal,
    required String status,
    required List<PlanStep> steps,
    String? currentStep,
  }) = _PlanGetResponse;

  factory PlanGetResponse.fromJson(Map<String, dynamic> json) =>
      _$PlanGetResponseFromJson(json);
}

@freezed
class PlanExecuteResponse with _$PlanExecuteResponse {
  const factory PlanExecuteResponse({
    required bool ok,
    required String planId,
    required String result,
  }) = _PlanExecuteResponse;

  factory PlanExecuteResponse.fromJson(Map<String, dynamic> json) =>
      _$PlanExecuteResponseFromJson(json);
}

@freezed
class PlanReplanResponse with _$PlanReplanResponse {
  const factory PlanReplanResponse({
    required bool ok,
    required String planId,
    required String result,
  }) = _PlanReplanResponse;

  factory PlanReplanResponse.fromJson(Map<String, dynamic> json) =>
      _$PlanReplanResponseFromJson(json);
}

@freezed
class SynthesizeCreateResponse with _$SynthesizeCreateResponse {
  const factory SynthesizeCreateResponse({
    required String jobId,
    required String status,
  }) = _SynthesizeCreateResponse;

  factory SynthesizeCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$SynthesizeCreateResponseFromJson(json);
}

@freezed
class SynthesizeGetResponse with _$SynthesizeGetResponse {
  const factory SynthesizeGetResponse({
    required String jobId,
    required String status,
    required String result,
    Map<String, dynamic>? artifacts,
  }) = _SynthesizeGetResponse;

  factory SynthesizeGetResponse.fromJson(Map<String, dynamic> json) =>
      _$SynthesizeGetResponseFromJson(json);
}

@freezed
class SynthesizeStatsResponse with _$SynthesizeStatsResponse {
  const factory SynthesizeStatsResponse({
    required int totalJobs,
    required int completedJobs,
    required int failedJobs,
  }) = _SynthesizeStatsResponse;

  factory SynthesizeStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$SynthesizeStatsResponseFromJson(json);
}

@freezed
class MetaStatusResponse with _$MetaStatusResponse {
  const factory MetaStatusResponse({
    required bool running,
    required int monitoredSteps,
    required int errorsDetected,
    required int correctionsApplied,
  }) = _MetaStatusResponse;

  factory MetaStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$MetaStatusResponseFromJson(json);
}

@freezed
class MetaMonitorResponse with _$MetaMonitorResponse {
  const factory MetaMonitorResponse({
    required bool ok,
    required String stepId,
    required String status,
    String? correction,
  }) = _MetaMonitorResponse;

  factory MetaMonitorResponse.fromJson(Map<String, dynamic> json) =>
      _$MetaMonitorResponseFromJson(json);
}

@freezed
class MetaStepResultResponse with _$MetaStepResultResponse {
  const factory MetaStepResultResponse({
    required bool ok,
    required String stepId,
    required bool verified,
    String? issues,
  }) = _MetaStepResultResponse;

  factory MetaStepResultResponse.fromJson(Map<String, dynamic> json) =>
      _$MetaStepResultResponseFromJson(json);
}

@freezed
class MetaEventsResponse with _$MetaEventsResponse {
  const factory MetaEventsResponse({
    required List<MetaEvent> events,
  }) = _MetaEventsResponse;

  factory MetaEventsResponse.fromJson(Map<String, dynamic> json) =>
      _$MetaEventsResponseFromJson(json);
}

@JsonSerializable()
class MetaEvent {
  final String id;
  final String type;
  final String description;
  final double timestamp;

  const MetaEvent({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory MetaEvent.fromJson(Map<String, dynamic> json) =>
      _$MetaEventFromJson(json);

  Map<String, dynamic> toJson() => _$MetaEventToJson(this);
}

// Synthesizer Models (Phase 18 Part 2)
@freezed
class SynthesizeListResponse with _$SynthesizeListResponse {
  const factory SynthesizeListResponse({
    required List<SynthesisItem> items,
  }) = _SynthesizeListResponse;

  factory SynthesizeListResponse.fromJson(Map<String, dynamic> json) =>
      _$SynthesizeListResponseFromJson(json);
}

@JsonSerializable()
class SynthesisItem {
  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? result;

  const SynthesisItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.result,
  });

  factory SynthesisItem.fromJson(Map<String, dynamic> json) =>
      _$SynthesisItemFromJson(json);

  Map<String, dynamic> toJson() => _$SynthesisItemToJson(this);
}

// Society Models (Phase 18 Part 2)
@freezed
class SocietyStatusResponse with _$SocietyStatusResponse {
  const factory SocietyStatusResponse({
    required int totalAgents,
    required int activeAgents,
    required int tasksQueued,
    required int tasksRunning,
    required int tasksCompleted,
    required int tasksFailed,
  }) = _SocietyStatusResponse;

  factory SocietyStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyStatusResponseFromJson(json);
}

@freezed
class SocietySpawnResponse with _$SocietySpawnResponse {
  const factory SocietySpawnResponse({
    required String agentId,
    required String role,
    required String status,
  }) = _SocietySpawnResponse;

  factory SocietySpawnResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietySpawnResponseFromJson(json);
}

@freezed
class SocietyAgentsResponse with _$SocietyAgentsResponse {
  const factory SocietyAgentsResponse({
    required List<SocietyAgent> agents,
  }) = _SocietyAgentsResponse;

  factory SocietyAgentsResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyAgentsResponseFromJson(json);
}

@JsonSerializable()
class SocietyAgent {
  final String id;
  final String role;
  final String status;
  final Map<String, dynamic>? capabilities;
  final DateTime createdAt;
  final DateTime? lastActive;

  const SocietyAgent({
    required this.id,
    required this.role,
    required this.status,
    this.capabilities,
    required this.createdAt,
    this.lastActive,
  });

  factory SocietyAgent.fromJson(Map<String, dynamic> json) =>
      _$SocietyAgentFromJson(json);

  Map<String, dynamic> toJson() => _$SocietyAgentToJson(this);
}

@freezed
class SocietyTaskResponse with _$SocietyTaskResponse {
  const factory SocietyTaskResponse({
    required String taskId,
    required String agentId,
    required String status,
    required Map<String, dynamic> task,
  }) = _SocietyTaskResponse;

  factory SocietyTaskResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyTaskResponseFromJson(json);
}

@freezed
class SocietyTenderResponse with _$SocietyTenderResponse {
  const factory SocietyTenderResponse({
    required String taskId,
    required String status,
    required Map<String, dynamic> taskSpec,
    required String deadline,
    required List<String> eligibleRoles,
  }) = _SocietyTenderResponse;

  factory SocietyTenderResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyTenderResponseFromJson(json);
}

@freezed
class SocietyBidResponse with _$SocietyBidResponse {
  const factory SocietyBidResponse({
    required String taskId,
    required String agentId,
    required String status,
    double? score,
  }) = _SocietyBidResponse;

  factory SocietyBidResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyBidResponseFromJson(json);
}

@freezed
class SocietyAwardResponse with _$SocietyAwardResponse {
  const factory SocietyAwardResponse({
    required String taskId,
    required String agentId,
    required String status,
  }) = _SocietyAwardResponse;

  factory SocietyAwardResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyAwardResponseFromJson(json);
}

@freezed
class SocietyBlackboardWriteResponse with _$SocietyBlackboardWriteResponse {
  const factory SocietyBlackboardWriteResponse({
    required bool success,
    required String key,
  }) = _SocietyBlackboardWriteResponse;

  factory SocietyBlackboardWriteResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyBlackboardWriteResponseFromJson(json);
}

@freezed
class SocietyBlackboardReadResponse with _$SocietyBlackboardReadResponse {
  const factory SocietyBlackboardReadResponse({
    required bool found,
    required String key,
    required dynamic value,
    required List<String> tags,
    int? ttl,
  }) = _SocietyBlackboardReadResponse;

  factory SocietyBlackboardReadResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyBlackboardReadResponseFromJson(json);
}

@freezed
class SocietyBlackboardQueryResponse with _$SocietyBlackboardQueryResponse {
  const factory SocietyBlackboardQueryResponse({
    required List<BlackboardEntry> entries,
  }) = _SocietyBlackboardQueryResponse;

  factory SocietyBlackboardQueryResponse.fromJson(Map<String, dynamic> json) =>
      _$SocietyBlackboardQueryResponseFromJson(json);
}

@JsonSerializable()
class BlackboardEntry {
  final String key;
  final dynamic value;
  final List<String> tags;
  final int? ttl;
  final DateTime createdAt;
  final String agentId;

  const BlackboardEntry({
    required this.key,
    required this.value,
    required this.tags,
    this.ttl,
    required this.createdAt,
    required this.agentId,
  });

  factory BlackboardEntry.fromJson(Map<String, dynamic> json) =>
      _$BlackboardEntryFromJson(json);

  Map<String, dynamic> toJson() => _$BlackboardEntryToJson(this);
}

// Procedural Memory Models (Phase 18 Part 2)
@freezed
class ProceduralListResponse with _$ProceduralListResponse {
  const factory ProceduralListResponse({
    required List<ProceduralSkill> skills,
    required int total,
  }) = _ProceduralListResponse;

  factory ProceduralListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProceduralListResponseFromJson(json);
}

@JsonSerializable()
class ProceduralSkill {
  final String id;
  final String name;
  final String description;
  final bool verified;
  final double confidence;
  final int usageCount;
  final double successRate;
  final List<String> applicableGoals;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProceduralSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.verified,
    required this.confidence,
    required this.usageCount,
    required this.successRate,
    required this.applicableGoals,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProceduralSkill.fromJson(Map<String, dynamic> json) =>
      _$ProceduralSkillFromJson(json);

  Map<String, dynamic> toJson() => _$ProceduralSkillToJson(this);
}

@freezed
class ProceduralApplicableResponse with _$ProceduralApplicableResponse {
  const factory ProceduralApplicableResponse({
    required List<ProceduralSkill> skills,
    required String goal,
  }) = _ProceduralApplicableResponse;

  factory ProceduralApplicableResponse.fromJson(Map<String, dynamic> json) =>
      _$ProceduralApplicableResponseFromJson(json);
}

@freezed
class ProceduralUseResponse with _$ProceduralUseResponse {
  const factory ProceduralUseResponse({
    required String skillId,
    required bool success,
    required double newConfidence,
    required int newUsageCount,
    double? reward,
  }) = _ProceduralUseResponse;

  factory ProceduralUseResponse.fromJson(Map<String, dynamic> json) =>
      _$ProceduralUseResponseFromJson(json);
}

@freezed
class ProceduralStatsResponse with _$ProceduralStatsResponse {
  const factory ProceduralStatsResponse({
    required int totalSkills,
    required int verifiedSkills,
    required double avgConfidence,
    required double avgSuccessRate,
    required int totalUsages,
  }) = _ProceduralStatsResponse;

  factory ProceduralStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$ProceduralStatsResponseFromJson(json);
}

@freezed
class ProceduralSearchResponse with _$ProceduralSearchResponse {
  const factory ProceduralSearchResponse({
    required List<ProceduralSkill> skills,
    required String query,
  }) = _ProceduralSearchResponse;

  factory ProceduralSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$ProceduralSearchResponseFromJson(json);
}

@freezed
class ProceduralComposeResponse with _$ProceduralComposeResponse {
  const factory ProceduralComposeResponse({
    required String skillId,
    required String name,
    required String description,
    required bool verified,
  }) = _ProceduralComposeResponse;

  factory ProceduralComposeResponse.fromJson(Map<String, dynamic> json) =>
      _$ProceduralComposeResponseFromJson(json);
}

// Maya Cognitive Core Models (Phase 19)
@freezed
class CoreStatusResponse with _$CoreStatusResponse {
  const factory CoreStatusResponse({
    required bool initialized,
    required bool loopRunning,
    required double loopInterval,
    required int cycleCount,
    required String activeModel,
    required Map<String, dynamic> identity,
    required Map<String, dynamic> selfState,
    required Map<String, dynamic> kernelStatus,
  }) = _CoreStatusResponse;

  factory CoreStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreStatusResponseFromJson(json);
}

@freezed
class CoreInitializeResponse with _$CoreInitializeResponse {
  const factory CoreInitializeResponse({
    required bool success,
    required String message,
  }) = _CoreInitializeResponse;

  factory CoreInitializeResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreInitializeResponseFromJson(json);
}

@freezed
class CoreLoopResponse with _$CoreLoopResponse {
  const factory CoreLoopResponse({
    required bool success,
    double? interval,
  }) = _CoreLoopResponse;

  factory CoreLoopResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreLoopResponseFromJson(json);
}

@freezed
class CoreMissionResponse with _$CoreMissionResponse {
  const factory CoreMissionResponse({
    required bool success,
    required String missionId,
    String? result,
  }) = _CoreMissionResponse;

  factory CoreMissionResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreMissionResponseFromJson(json);
}

@freezed
class CoreGoalResponse with _$CoreGoalResponse {
  const factory CoreGoalResponse({
    required bool success,
    required String goalId,
    required int stepsExecuted,
    String? result,
  }) = _CoreGoalResponse;

  factory CoreGoalResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreGoalResponseFromJson(json);
}

@freezed
class CoreIdentityResponse with _$CoreIdentityResponse {
  const factory CoreIdentityResponse({
    required String id,
    required String name,
    required String purpose,
    required List<String> values,
    required DateTime createdAt,
    required int version,
  }) = _CoreIdentityResponse;

  factory CoreIdentityResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreIdentityResponseFromJson(json);
}

@freezed
class CoreModelsResponse with _$CoreModelsResponse {
  const factory CoreModelsResponse({
    required String activeModel,
    required List<String> fallbackChain,
    required List<ModelInfo> availableModels,
  }) = _CoreModelsResponse;

  factory CoreModelsResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreModelsResponseFromJson(json);
}

@JsonSerializable()
class ModelInfo {
  final String id;
  final String provider;
  final String taskType;
  final bool available;

  const ModelInfo({
    required this.id,
    required this.provider,
    required this.taskType,
    required this.available,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ModelInfoToJson(this);
}

@freezed
class CoreSwitchModelResponse with _$CoreSwitchModelResponse {
  const factory CoreSwitchModelResponse({
    required bool success,
    required String activeModel,
  }) = _CoreSwitchModelResponse;

  factory CoreSwitchModelResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreSwitchModelResponseFromJson(json);
}

@freezed
class CoreInvokeModelResponse with _$CoreInvokeModelResponse {
  const factory CoreInvokeModelResponse({
    required String modelId,
    required String content,
    required int tokensUsed,
    required double latencyMs,
    bool? cached,
  }) = _CoreInvokeModelResponse;

  factory CoreInvokeModelResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreInvokeModelResponseFromJson(json);
}

@freezed
class CoreCheckpointResponse with _$CoreCheckpointResponse {
  const factory CoreCheckpointResponse({
    required String checkpointId,
    required DateTime timestamp,
  }) = _CoreCheckpointResponse;

  factory CoreCheckpointResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreCheckpointResponseFromJson(json);
}

@freezed
class CoreRestoreCheckpointResponse with _$CoreRestoreCheckpointResponse {
  const factory CoreRestoreCheckpointResponse({
    required bool success,
    required String checkpointId,
  }) = _CoreRestoreCheckpointResponse;

  factory CoreRestoreCheckpointResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreRestoreCheckpointResponseFromJson(json);
}

@freezed
class CoreCheckpointsResponse with _$CoreCheckpointsResponse {
  const factory CoreCheckpointsResponse({
    required List<CheckpointInfo> checkpoints,
  }) = _CoreCheckpointsResponse;

  factory CoreCheckpointsResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreCheckpointsResponseFromJson(json);
}

@JsonSerializable()
class CheckpointInfo {
  final String id;
  final DateTime timestamp;
  final int cycleCount;
  final String description;

  const CheckpointInfo({
    required this.id,
    required this.timestamp,
    required this.cycleCount,
    required this.description,
  });

  factory CheckpointInfo.fromJson(Map<String, dynamic> json) =>
      _$CheckpointInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointInfoToJson(this);
}

@freezed
class CoreAuditResponse with _$CoreAuditResponse {
  const factory CoreAuditResponse({
    required List<AuditEntry> audit,
  }) = _CoreAuditResponse;

  factory CoreAuditResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreAuditResponseFromJson(json);
}

@JsonSerializable()
class AuditEntry {
  final String eventType;
  final String details;
  final DateTime timestamp;
  final int cycleId;

  const AuditEntry({
    required this.eventType,
    required this.details,
    required this.timestamp,
    required this.cycleId,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);

  Map<String, dynamic> toJson() => _$AuditEntryToJson(this);
}

@freezed
class CoreShutdownResponse with _$CoreShutdownResponse {
  const factory CoreShutdownResponse({
    required bool success,
    required String message,
  }) = _CoreShutdownResponse;

  factory CoreShutdownResponse.fromJson(Map<String, dynamic> json) =>
      _$CoreShutdownResponseFromJson(json);
}

// Unified Cognitive Loop Models (Phase 34)
@freezed
class UnifiedLoopStatusResponse with _$UnifiedLoopStatusResponse {
  const factory UnifiedLoopStatusResponse({
    required String loopState,
    required String currentPhase,
    required int cyclesCompleted,
    required int missionsCompleted,
    required int skillsAcquired,
    required int errorCount,
    String? lastError,
    String? activeGoalId,
    String? activePlanId,
    String? currentStepId,
    String? activeModelId,
    List<String>? availableModels,
    Map<String, dynamic>? resourceUsage,
    required double uptime,
    String? instanceId,
    String? name,
    String? version,
  }) = _UnifiedLoopStatusResponse;

  factory UnifiedLoopStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$UnifiedLoopStatusResponseFromJson(json);
}

@freezed
class UnifiedLoopHistoryResponse with _$UnifiedLoopHistoryResponse {
  const factory UnifiedLoopHistoryResponse({
    required List<UnifiedLoopHistoryEntry> entries,
  }) = _UnifiedLoopHistoryResponse;

  factory UnifiedLoopHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$UnifiedLoopHistoryResponseFromJson(json);
}

@freezed
class UnifiedLoopHistoryEntry with _$UnifiedLoopHistoryEntry {
  const factory UnifiedLoopHistoryEntry({
    required String id,
    required int cycleId,
    required String phase,
    required double timestamp,
    required String details,
    required bool success,
    required int durationMs,
  }) = _UnifiedLoopHistoryEntry;

  factory UnifiedLoopHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$UnifiedLoopHistoryEntryFromJson(json);
}

@freezed
class UnifiedLoopControlResponse with _$UnifiedLoopControlResponse {
  const factory UnifiedLoopControlResponse({
    required bool success,
    String? message,
    double? interval,
  }) = _UnifiedLoopControlResponse;

  factory UnifiedLoopControlResponse.fromJson(Map<String, dynamic> json) =>
      _$UnifiedLoopControlResponseFromJson(json);
}

// Persistent Goal Pursuit Models (Phase 35)
@freezed
class GoalsListResponse with _$GoalsListResponse {
  const factory GoalsListResponse({
    required List<GoalSummary> goals,
  }) = _GoalsListResponse;

  factory GoalsListResponse.fromJson(Map<String, dynamic> json) =>
      _$GoalsListResponseFromJson(json);
}

@freezed
class GoalSummary with _$GoalSummary {
  const factory GoalSummary({
    required String id,
    required String description,
    required String status,
    required double priority,
    required double progress,
    required double createdAt,
    required double updatedAt,
    Map<String, dynamic>? metadata,
  }) = _GoalSummary;

  factory GoalSummary.fromJson(Map<String, dynamic> json) =>
      _$GoalSummaryFromJson(json);
}

@freezed
class GoalDetailResponse with _$GoalDetailResponse {
  const factory GoalDetailResponse({
    required String id,
    required String description,
    required String status,
    required double priority,
    required double progress,
    required double createdAt,
    required double updatedAt,
    Map<String, dynamic>? metadata,
    String? parentId,
    String? successCriteria,
    List<String>? constraints,
    List<String>? requiredCapabilities,
    List<GoalSummary>? subgoals,
  }) = _GoalDetailResponse;

  factory GoalDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$GoalDetailResponseFromJson(json);
}

@freezed
class GoalResumeResponse with _$GoalResumeResponse {
  const factory GoalResumeResponse({
    required bool success,
    String? goalId,
    String? error,
    String? action,
    String? detail,
    bool? resumed,
    Map<String, dynamic>? metadata,
  }) = _GoalResumeResponse;

  factory GoalResumeResponse.fromJson(Map<String, dynamic> json) =>
      _$GoalResumeResponseFromJson(json);
}

@freezed
class GoalCreateResponse with _$GoalCreateResponse {
  const factory GoalCreateResponse({
    required String goalId,
    required String description,
    required String status,
    required double priority,
    required double progress,
    required double createdAt,
    required double updatedAt,
    Map<String, dynamic>? metadata,
  }) = _GoalCreateResponse;

  factory GoalCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$GoalCreateResponseFromJson(json);
}

@freezed
class GoalUpdateResponse with _$GoalUpdateResponse {
  const factory GoalUpdateResponse({
    required String id,
    required String description,
    required String status,
    required double priority,
    required double progress,
    required double createdAt,
    required double updatedAt,
    Map<String, dynamic>? metadata,
  }) = _GoalUpdateResponse;

  factory GoalUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$GoalUpdateResponseFromJson(json);
}

@freezed
class GoalDecomposeResponse with _$GoalDecomposeResponse {
  const factory GoalDecomposeResponse({
    required List<GoalSummary> subgoals,
  }) = _GoalDecomposeResponse;

  factory GoalDecomposeResponse.fromJson(Map<String, dynamic> json) =>
      _$GoalDecomposeResponseFromJson(json);
}

// Hippocampus / Episodic Memory Models
@freezed
class EpisodicListResponse with _$EpisodicListResponse {
  const factory EpisodicListResponse({
    required List<EpisodicMemory> episodes,
  }) = _EpisodicListResponse;

  factory EpisodicListResponse.fromJson(Map<String, dynamic> json) =>
      _$EpisodicListResponseFromJson(json);
}

@JsonSerializable()
class EpisodicMemory {
  final String id;
  final String goal;
  final String outcome;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const EpisodicMemory({
    required this.id,
    required this.goal,
    required this.outcome,
    required this.confidence,
    required this.timestamp,
    this.metadata,
  });

  factory EpisodicMemory.fromJson(Map<String, dynamic> json) =>
      _$EpisodicMemoryFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodicMemoryToJson(this);
}

@freezed
class EpisodicSearchResponse with _$EpisodicSearchResponse {
  const factory EpisodicSearchResponse({
    required List<EpisodicMemory> episodes,
  }) = _EpisodicSearchResponse;

  factory EpisodicSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$EpisodicSearchResponseFromJson(json);
}

@freezed
class EpisodicStatsResponse with _$EpisodicStatsResponse {
  const factory EpisodicStatsResponse({
    required int totalEpisodes,
    required int successfulEpisodes,
    required int failedEpisodes,
    required double avgConfidence,
    required Map<String, int> outcomesByType,
  }) = _EpisodicStatsResponse;

  factory EpisodicStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$EpisodicStatsResponseFromJson(json);
}

@freezed
class HippocampusSchemaQueryResponse with _$HippocampusSchemaQueryResponse {
  const factory HippocampusSchemaQueryResponse({
    required List<SchemaInfo> schemas,
  }) = _HippocampusSchemaQueryResponse;

  factory HippocampusSchemaQueryResponse.fromJson(Map<String, dynamic> json) =>
      _$HippocampusSchemaQueryResponseFromJson(json);
}

@JsonSerializable()
class SchemaInfo {
  final String id;
  final String name;
  final String description;
  final double relevance;
  final Map<String, dynamic>? parameters;

  const SchemaInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.relevance,
    this.parameters,
  });

  factory SchemaInfo.fromJson(Map<String, dynamic> json) =>
      _$SchemaInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SchemaInfoToJson(this);
}

@freezed
class HippocampusSchemaApplyResponse with _$HippocampusSchemaApplyResponse {
  const factory HippocampusSchemaApplyResponse({
    required bool success,
    required String schemaId,
    String? result,
  }) = _HippocampusSchemaApplyResponse;

  factory HippocampusSchemaApplyResponse.fromJson(Map<String, dynamic> json) =>
      _$HippocampusSchemaApplyResponseFromJson(json);
}

// Semantic Memory / Knowledge Models
@freezed
class KnowledgeQueryResponse with _$KnowledgeQueryResponse {
  const factory KnowledgeQueryResponse({
    required List<KnowledgeItem> results,
  }) = _KnowledgeQueryResponse;

  factory KnowledgeQueryResponse.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeQueryResponseFromJson(json);
}

@JsonSerializable()
class KnowledgeItem {
  final String id;
  final String proposition;
  final double confidence;
  final String source;
  final String domain;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> evidence;

  const KnowledgeItem({
    required this.id,
    required this.proposition,
    required this.confidence,
    required this.source,
    required this.domain,
    required this.createdAt,
    this.updatedAt,
    required this.evidence,
  });

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeItemFromJson(json);

  Map<String, dynamic> toJson() => _$KnowledgeItemToJson(this);
}

@freezed
class KnowledgeStatsResponse with _$KnowledgeStatsResponse {
  const factory KnowledgeStatsResponse({
    required int totalBeliefs,
    required int domains,
    required double avgConfidence,
    required int retrievalEngine,
  }) = _KnowledgeStatsResponse;

  factory KnowledgeStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeStatsResponseFromJson(json);
}

@freezed
class KnowledgeLearnResponse with _$KnowledgeLearnResponse {
  const factory KnowledgeLearnResponse({
    required String beliefId,
    required double confidence,
    required String action, // "created" or "merged"
  }) = _KnowledgeLearnResponse;

  factory KnowledgeLearnResponse.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeLearnResponseFromJson(json);
}

// Belief Models (Phase 36 - Knowledge Engine)
@freezed
class BeliefAddResponse with _$BeliefAddResponse {
  const factory BeliefAddResponse({
    required String beliefId,
    required String proposition,
    required double confidence,
    required String domain,
    required String source,
  }) = _BeliefAddResponse;

  factory BeliefAddResponse.fromJson(Map<String, dynamic> json) =>
      _$BeliefAddResponseFromJson(json);
}

@freezed
class BeliefsQueryResponse with _$BeliefsQueryResponse {
  const factory BeliefsQueryResponse({
    required List<Belief> beliefs,
  }) = _BeliefsQueryResponse;

  factory BeliefsQueryResponse.fromJson(Map<String, dynamic> json) =>
      _$BeliefsQueryResponseFromJson(json);
}

// MCP Client Models (Phase 38)
@freezed
class McpStatusResponse with _$McpStatusResponse {
  const factory McpStatusResponse({
    required bool enabled,
    required List<McpServerStatus> servers,
  }) = _McpStatusResponse;

  factory McpStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$McpStatusResponseFromJson(json);
}

@freezed
class McpServerStatus with _$McpServerStatus {
  const factory McpServerStatus({
    required String name,
    required String status, // "connected", "disconnected", "error"
    required int toolCount,
    required List<String> tools,
    String? error,
  }) = _McpServerStatus;

  factory McpServerStatus.fromJson(Map<String, dynamic> json) =>
      _$McpServerStatusFromJson(json);
}

@freezed
class McpConnectResponse with _$McpConnectResponse {
  const factory McpConnectResponse({
    required String server,
    required int toolsRegistered,
  }) = _McpConnectResponse;

  factory McpConnectResponse.fromJson(Map<String, dynamic> json) =>
      _$McpConnectResponseFromJson(json);
}

@freezed
class McpDisconnectResponse with _$McpDisconnectResponse {
  const factory McpDisconnectResponse({
    required bool disconnected,
    required int toolsRemoved,
  }) = _McpDisconnectResponse;

  factory McpDisconnectResponse.fromJson(Map<String, dynamic> json) =>
      _$McpDisconnectResponseFromJson(json);
}

@freezed
class McpCallResponse with _$McpCallResponse {
  const factory McpCallResponse({
    required dynamic result,
  }) = _McpCallResponse;

  factory McpCallResponse.fromJson(Map<String, dynamic> json) =>
      _$McpCallResponseFromJson(json);
}

// Self Model (Phase 39)
@freezed
class SelfProfileResponse with _$SelfProfileResponse {
  const factory SelfProfileResponse({
    required int totalOutcomes,
    required double? overallSuccessRate,
    required List<SelfTypeStat> byTaskType,
    required List<SelfTypeStat> strengths,
    required List<SelfTypeStat> weaknesses,
    required Map<String, dynamic> traits,
  }) = _SelfProfileResponse;

  factory SelfProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$SelfProfileResponseFromJson(json);
}

@freezed
class SelfTypeStat with _$SelfTypeStat {
  const factory SelfTypeStat({
    required String taskType,
    required int attempts,
    required double successRate,
    required double avgDuration,
    double? avgQuality,
  }) = _SelfTypeStat;

  factory SelfTypeStat.fromJson(Map<String, dynamic> json) =>
      _$SelfTypeStatFromJson(json);
}

@freezed
class SelfAssessResponse with _$SelfAssessResponse {
  const factory SelfAssessResponse({
    required String taskType,
    required SelfTypeStat? experience,
    required bool novel,
    required bool knownWeakness,
    required String recommendation,
  }) = _SelfAssessResponse;

  factory SelfAssessResponse.fromJson(Map<String, dynamic> json) =>
      _$SelfAssessResponseFromJson(json);
}

@freezed
class SelfTraitResponse with _$SelfTraitResponse {
  const factory SelfTraitResponse({
    required bool recorded,
  }) = _SelfTraitResponse;

  factory SelfTraitResponse.fromJson(Map<String, dynamic> json) =>
      _$SelfTraitResponseFromJson(json);
}

@JsonSerializable()
class Belief {
  final String id;
  final String proposition;
  final double confidence;
  final String domain;
  final String source;
  final String? evidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Belief({
    required this.id,
    required this.proposition,
    required this.confidence,
    required this.domain,
    required this.source,
    this.evidence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Belief.fromJson(Map<String, dynamic> json) =>
      _$BeliefFromJson(json);

  Map<String, dynamic> toJson() => _$BeliefToJson(this);
}

// Working Memory Models
@freezed
class WorkingMemoryAddResponse with _$WorkingMemoryAddResponse {
  const factory WorkingMemoryAddResponse({
    required String slotId,
  }) = _WorkingMemoryAddResponse;

  factory WorkingMemoryAddResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkingMemoryAddResponseFromJson(json);
}

@freezed
class WorkingMemorySearchResponse with _$WorkingMemorySearchResponse {
  const factory WorkingMemorySearchResponse({
    required List<WorkingMemoryItem> results,
  }) = _WorkingMemorySearchResponse;

  factory WorkingMemorySearchResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkingMemorySearchResponseFromJson(json);
}

@JsonSerializable()
class WorkingMemoryItem {
  final String id;
  final String content;
  final String type;
  final double attention;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? bindings;
  final DateTime createdAt;

  const WorkingMemoryItem({
    required this.id,
    required this.content,
    required this.type,
    required this.attention,
    this.metadata,
    this.bindings,
    required this.createdAt,
  });

  factory WorkingMemoryItem.fromJson(Map<String, dynamic> json) =>
      _$WorkingMemoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$WorkingMemoryItemToJson(this);
}

@freezed
class WorkingMemoryCapacityResponse with _$WorkingMemoryCapacityResponse {
  const factory WorkingMemoryCapacityResponse({
    required int totalSlots,
    required int usedSlots,
    required int freeSlots,
    required Map<String, int> byType,
    required double totalAttention,
  }) = _WorkingMemoryCapacityResponse;

  factory WorkingMemoryCapacityResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkingMemoryCapacityResponseFromJson(json);
}

// Working Memory v2 Models
@freezed
class WMAddResponse with _$WMAddResponse {
  const factory WMAddResponse({
    required String itemId,
    required bool success,
  }) = _WMAddResponse;

  factory WMAddResponse.fromJson(Map<String, dynamic> json) =>
      _$WMAddResponseFromJson(json);
}

@freezed
class WMRetrieveResponse with _$WMRetrieveResponse {
  const factory WMRetrieveResponse({
    required List<WMItem> results,
  }) = _WMRetrieveResponse;

  factory WMRetrieveResponse.fromJson(Map<String, dynamic> json) =>
      _$WMRetrieveResponseFromJson(json);
}

@JsonSerializable()
class WMItem {
  final String id;
  final String content;
  final String? chunkId;
  final double attention;
  final DateTime createdAt;

  const WMItem({
    required this.id,
    required this.content,
    this.chunkId,
    required this.attention,
    required this.createdAt,
  });

  factory WMItem.fromJson(Map<String, dynamic> json) =>
      _$WMItemFromJson(json);

  Map<String, dynamic> toJson() => _$WMItemToJson(this);
}

@freezed
class WMDecayResponse with _$WMDecayResponse {
  const factory WMDecayResponse({
    required int removed,
  }) = _WMDecayResponse;

  factory WMDecayResponse.fromJson(Map<String, dynamic> json) =>
      _$WMDecayResponseFromJson(json);
}

// Browser & Sandbox Models
@freezed
class BrowserActionResponse with _$BrowserActionResponse {
  const factory BrowserActionResponse({
    required bool success,
    String? content,
    String? url,
    String? screenshotPath,
    String? error,
  }) = _BrowserActionResponse;

  factory BrowserActionResponse.fromJson(Map<String, dynamic> json) =>
      _$BrowserActionResponseFromJson(json);
}

@freezed
class SandboxExecuteResponse with _$SandboxExecuteResponse {
  const factory SandboxExecuteResponse({
    required bool success,
    String? output,
    String? error,
    int? exitCode,
    double? executionTimeMs,
  }) = _SandboxExecuteResponse;

  factory SandboxExecuteResponse.fromJson(Map<String, dynamic> json) =>
      _$SandboxExecuteResponseFromJson(json);
}

// Business Analysis Models (Phase 20)
@freezed
class MissionListResponse with _$MissionListResponse {
  const factory MissionListResponse({
    required List<MissionInfo> missions,
  }) = _MissionListResponse;

  factory MissionListResponse.fromJson(Map<String, dynamic> json) =>
      _$MissionListResponseFromJson(json);
}

@JsonSerializable()
class MissionInfo {
  final String id;
  final String name;
  final String description;
  final String missionType;
  final bool active;
  final bool selfGen;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MissionInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.missionType,
    required this.active,
    required this.selfGen,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory MissionInfo.fromJson(Map<String, dynamic> json) =>
      _$MissionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$MissionInfoToJson(this);
}

@freezed
class BusinessAnalyzeResponse with _$BusinessAnalyzeResponse {
  const factory BusinessAnalyzeResponse({
    required String id,
    required String missionId,
    required String objectiveId,
    required String objectiveDesc,
    required Map<String, String> agentResponses,
    required String combinedSummary,
    required double createdAt,
  }) = _BusinessAnalyzeResponse;

  factory BusinessAnalyzeResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessAnalyzeResponseFromJson(json);
}

@freezed
class BusinessReportsListResponse with _$BusinessReportsListResponse {
  const factory BusinessReportsListResponse({
    required List<BusinessReportSummary> reports,
    required int count,
  }) = _BusinessReportsListResponse;

  factory BusinessReportsListResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessReportsListResponseFromJson(json);
}

@JsonSerializable()
class BusinessReportSummary {
  final String id;
  final String missionId;
  final String objectiveId;
  final String objectiveDesc;
  final String combinedSummary;
  final double createdAt;

  const BusinessReportSummary({
    required this.id,
    required this.missionId,
    required this.objectiveId,
    required this.objectiveDesc,
    required this.combinedSummary,
    required this.createdAt,
  });

  factory BusinessReportSummary.fromJson(Map<String, dynamic> json) =>
      _$BusinessReportSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessReportSummaryToJson(this);
}

@freezed
class BusinessReportDetailResponse with _$BusinessReportDetailResponse {
  const factory BusinessReportDetailResponse({
    required String id,
    required String missionId,
    required String objectiveId,
    required String objectiveDesc,
    required Map<String, String> agentResponses,
    required String combinedSummary,
    required double createdAt,
  }) = _BusinessReportDetailResponse;

  factory BusinessReportDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessReportDetailResponseFromJson(json);
}

// Guarded Publish Models (Phase 21)
@freezed
class PublishProposeResponse with _$PublishProposeResponse {
  const factory PublishProposeResponse({
    required String id,
    required String siteName,
    required String filesJson,
    required String description,
    required String action,
    required String approver,
    required String resultUrl,
    required String error,
    required double createdAt,
    double? decidedAt,
  }) = _PublishProposeResponse;

  factory PublishProposeResponse.fromJson(Map<String, dynamic> json) =>
      _$PublishProposeResponseFromJson(json);
}

@freezed
class PublishHistoryListResponse with _$PublishHistoryListResponse {
  const factory PublishHistoryListResponse({
    required List<PublishHistoryItem> proposals,
  }) = _PublishHistoryListResponse;

  factory PublishHistoryListResponse.fromJson(Map<String, dynamic> json) =>
      _$PublishHistoryListResponseFromJson(json);
}

@JsonSerializable()
class PublishHistoryItem {
  final String id;
  final String siteName;
  final String description;
  final String action;
  final String approver;
  final String resultUrl;
  final String riskLevel;
  final double createdAt;
  final double? decidedAt;

  const PublishHistoryItem({
    required this.id,
    required this.siteName,
    required this.description,
    required this.action,
    required this.approver,
    required this.resultUrl,
    required this.riskLevel,
    required this.createdAt,
    this.decidedAt,
  });

  factory PublishHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$PublishHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$PublishHistoryItemToJson(this);
}

@freezed
class PublishHistoryDetailResponse with _$PublishHistoryDetailResponse {
  const factory PublishHistoryDetailResponse({
    required String id,
    required String siteName,
    required String filesJson,
    required String description,
    required String action,
    required String approver,
    required String resultUrl,
    required String error,
    required String riskLevel,
    required double createdAt,
    double? decidedAt,
  }) = _PublishHistoryDetailResponse;

  factory PublishHistoryDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$PublishHistoryDetailResponseFromJson(json);
}

@freezed
class PublishDecideResponse with _$PublishDecideResponse {
  const factory PublishDecideResponse({
    required String status,
    required String siteName,
    required String url,
    required String proposalId,
    required String riskLevel,
    bool? autoApplied,
    String? error,
  }) = _PublishDecideResponse;

  factory PublishDecideResponse.fromJson(Map<String, dynamic> json) =>
      _$PublishDecideResponseFromJson(json);
}

// Approvals System Models (Phase 21 Enhanced)
@freezed
class ApprovalRequestResponse with _$ApprovalRequestResponse {
  const factory ApprovalRequestResponse({
    required String id,
    required String action,
    required String reason,
    required String riskLevel,
    required String status,
    required String createdAt,
  }) = _ApprovalRequestResponse;

  factory ApprovalRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestResponseFromJson(json);
}

@freezed
class ApprovalsListResponse with _$ApprovalsListResponse {
  const factory ApprovalsListResponse({
    required List<ApprovalItem> approvals,
  }) = _ApprovalsListResponse;

  factory ApprovalsListResponse.fromJson(Map<String, dynamic> json) =>
      _$ApprovalsListResponseFromJson(json);
}

@JsonSerializable()
class ApprovalItem {
  final String id;
  final String action;
  final String reason;
  final String riskLevel;
  final String status;
  final String taskId;
  final String createdAt;
  final String? decidedAt;

  const ApprovalItem({
    required this.id,
    required this.action,
    required this.reason,
    required this.riskLevel,
    required this.status,
    required this.taskId,
    required this.createdAt,
    this.decidedAt,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) =>
      _$ApprovalItemFromJson(json);

  Map<String, dynamic> toJson() => _$ApprovalItemToJson(this);
}

@freezed
class ApprovalDecideResponse with _$ApprovalDecideResponse {
  const factory ApprovalDecideResponse({
    required String id,
    required String action,
    required String reason,
    required String riskLevel,
    required String status,
    required String taskId,
    required String createdAt,
    required String decidedAt,
  }) = _ApprovalDecideResponse;

  factory ApprovalDecideResponse.fromJson(Map<String, dynamic> json) =>
      _$ApprovalDecideResponseFromJson(json);
}

@freezed
class ApprovalModeResponse with _$ApprovalModeResponse {
  const factory ApprovalModeResponse({
    required String mode,
  }) = _ApprovalModeResponse;

  factory ApprovalModeResponse.fromJson(Map<String, dynamic> json) =>
      _$ApprovalModeResponseFromJson(json);
}

// API Key Provisioner Models (Phase 33)
@freezed
class ProvisionerSearchResponse with _$ProvisionerSearchResponse {
  const factory ProvisionerSearchResponse({
    required String report,
    required int findingsCount,
  }) = _ProvisionerSearchResponse;

  factory ProvisionerSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$ProvisionerSearchResponseFromJson(json);
}

@freezed
class ProvisionerProvisionResponse with _$ProvisionerProvisionResponse {
  const factory ProvisionerProvisionResponse({
    required bool ok,
    required String provider,
    String? apiKey,
    String? envVar,
    required bool validated,
    required String message,
  }) = _ProvisionerProvisionResponse;

  factory ProvisionerProvisionResponse.fromJson(Map<String, dynamic> json) =>
      _$ProvisionerProvisionResponseFromJson(json);
}

@freezed
class ProvisionerAuditResponse with _$ProvisionerAuditResponse {
  const factory ProvisionerAuditResponse({
    required List<ProvisionerAuditEntry> entries,
  }) = _ProvisionerAuditResponse;

  factory ProvisionerAuditResponse.fromJson(Map<String, dynamic> json) =>
      _$ProvisionerAuditResponseFromJson(json);
}

@freezed
class ProvisionerAuditEntry with _$ProvisionerAuditEntry {
  const factory ProvisionerAuditEntry({
    required String id,
    required String action,
    required String status,
    required String timestamp,
    String? provider,
    String? result,
  }) = _ProvisionerAuditEntry;

  factory ProvisionerAuditEntry.fromJson(Map<String, dynamic> json) =>
      _$ProvisionerAuditEntryFromJson(json);
}

// Communication Tools Models (Phase 33)
@freezed
class EmailToolResponse with _$EmailToolResponse {
  const factory EmailToolResponse({
    required bool ok,
    required String message,
    bool? configured,
  }) = _EmailToolResponse;

  factory EmailToolResponse.fromJson(Map<String, dynamic> json) =>
      _$EmailToolResponseFromJson(json);
}

@freezed
class WebhookToolResponse with _$WebhookToolResponse {
  const factory WebhookToolResponse({
    required bool ok,
    required String message,
    bool? configured,
  }) = _WebhookToolResponse;

  factory WebhookToolResponse.fromJson(Map<String, dynamic> json) =>
      _$WebhookToolResponseFromJson(json);
}

@freezed
class HealthCheckResult with _$HealthCheckResult {
  const factory HealthCheckResult({
    required bool live,
    required bool ready,
    required String system,
    required int latency,
    required DateTime lastCheck,
    String? error,
  }) = _HealthCheckResult;

  factory HealthCheckResult.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckResultFromJson(json);
}

// Data Models
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    required String refreshToken,
    required UserProfile user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    required String name,
    String? avatar,
    String? role,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
class TranscriptionResult with _$TranscriptionResult {
  const factory TranscriptionResult({
    required String transcript,
    required String language,
    required double languageProbability,
    required double duration,
    List<TranscriptionSegment>? segments,
  }) = _TranscriptionResult;

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionResultFromJson(json);
}

@freezed
class TranscriptionSegment with _$TranscriptionSegment {
  const factory TranscriptionSegment({
    required double start,
    required double end,
    required String text,
    double? avgLogprob,
  }) = _TranscriptionSegment;

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionSegmentFromJson(json);
}

@freezed
class TtsResult with _$TtsResult {
  const factory TtsResult({
    required bool success,
    String? audioBase64,
    String? format,
    String? provider,
    String? error,
  }) = _TtsResult;

  factory TtsResult.fromJson(Map<String, dynamic> json) =>
      _$TtsResultFromJson(json);
}

@freezed
class AgentChatResponse with _$AgentChatResponse {
  const factory AgentChatResponse({
    required String reply,
    required String timestamp,
    String? taskId,
  }) = _AgentChatResponse;

  factory AgentChatResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentChatResponseFromJson(json);
}

@freezed
class ChatStreamChunk with _$ChatStreamChunk {
  const factory ChatStreamChunk({String? delta, bool? done, String? error}) =
      _ChatStreamChunk;
}

// Task Streaming Events
@freezed
class TaskStreamEvent with _$TaskStreamEvent {
  const factory TaskStreamEvent({
    required String type,
    String? taskId,
    String? sessionId,
    String? status,
    int? currentStep,
    String? goal,
    String? stepId,
    String? stepName,
    String? stepDescription,
    String? agentName,
    String? toolName,
    String? toolStatus,
    String? toolResult,
    String? llmToken,
    String? verificationStatus,
    String? memoryAction,
    String? skillName,
    double? confidence,
    double? progress,
    String? message,
    String? error,
    double? timestamp,
  }) = _TaskStreamEvent;

  factory TaskStreamEvent.fromJson(Map<String, dynamic> json) =>
      _$TaskStreamEventFromJson(json);
}

@freezed
class AgentRunResponse with _$AgentRunResponse {
  const factory AgentRunResponse({
    required String taskId,
    required String status,
    String? result,
    String? error,
  }) = _AgentRunResponse;

  factory AgentRunResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentRunResponseFromJson(json);
}

@freezed
class AgentThinkResponse with _$AgentThinkResponse {
  const factory AgentThinkResponse({
    required String analysis,
    String? plan,
    List<String>? steps,
  }) = _AgentThinkResponse;

  factory AgentThinkResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentThinkResponseFromJson(json);
}

@freezed
class LearnCompleteResponse with _$LearnCompleteResponse {
  const factory LearnCompleteResponse({
    required bool success,
    required String result,
    required bool learned,
    String? skillHints,
    String? researchFindings,
    bool? sandboxVerified,
    String? testCode,
    String? riskLevel,
    String? error,
  }) = _LearnCompleteResponse;

  factory LearnCompleteResponse.fromJson(Map<String, dynamic> json) =>
      _$LearnCompleteResponseFromJson(json);
}

@freezed
class VisionAnalysisResult with _$VisionAnalysisResult {
  const factory VisionAnalysisResult({
    required String analysis,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) = _VisionAnalysisResult;

  factory VisionAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$VisionAnalysisResultFromJson(json);
}

@freezed
class OcrResult with _$OcrResult {
  const factory OcrResult({required String text, List<OcrRegion>? regions}) =
      _OcrResult;

  factory OcrResult.fromJson(Map<String, dynamic> json) =>
      _$OcrResultFromJson(json);
}

@freezed
class OcrRegion with _$OcrRegion {
  const factory OcrRegion({
    required String text,
    @RectConverter() required Rect bounds,
    double? confidence,
  }) = _OcrRegion;

  factory OcrRegion.fromJson(Map<String, dynamic> json) =>
      _$OcrRegionFromJson(json);
}

@freezed
class SystemStatus with _$SystemStatus {
  const factory SystemStatus({required String status, required String maya}) =
      _SystemStatus;

  factory SystemStatus.fromJson(Map<String, dynamic> json) =>
      _$SystemStatusFromJson(json);
}

@freezed
class SystemStats with _$SystemStats {
  const factory SystemStats({
    required CpuStats cpu,
    required MemoryStats memory,
    required DiskStats disk,
    required LoadStats load,
    NetworkStats? network,
  }) = _SystemStats;

  factory SystemStats.fromJson(Map<String, dynamic> json) =>
      _$SystemStatsFromJson(json);
}

@freezed
class CpuStats with _$CpuStats {
  const factory CpuStats({required double percent, required int count}) =
      _CpuStats;

  factory CpuStats.fromJson(Map<String, dynamic> json) =>
      _$CpuStatsFromJson(json);
}

@freezed
class MemoryStats with _$MemoryStats {
  const factory MemoryStats({
    required double totalGb,
    required double availableGb,
    required double usedGb,
    required double percent,
  }) = _MemoryStats;

  factory MemoryStats.fromJson(Map<String, dynamic> json) =>
      _$MemoryStatsFromJson(json);
}

@freezed
class DiskStats with _$DiskStats {
  const factory DiskStats({
    required double totalGb,
    required double usedGb,
    required double freeGb,
    required double percent,
  }) = _DiskStats;

  factory DiskStats.fromJson(Map<String, dynamic> json) =>
      _$DiskStatsFromJson(json);
}

@freezed
class LoadStats with _$LoadStats {
  const factory LoadStats({required List<double> loadAvg}) = _LoadStats;

  factory LoadStats.fromJson(Map<String, dynamic> json) =>
      _$LoadStatsFromJson(json);
}

@freezed
class NetworkStats with _$NetworkStats {
  const factory NetworkStats({required int bytesSent, required int bytesRecv}) =
      _NetworkStats;

  factory NetworkStats.fromJson(Map<String, dynamic> json) =>
      _$NetworkStatsFromJson(json);
}

// Task Queue Models
@freezed
class QueueStatus with _$QueueStatus {
  const factory QueueStatus({
    required Map<String, dynamic> tasks,
    required int workers,
    required bool running,
  }) = _QueueStatus;

  factory QueueStatus.fromJson(Map<String, dynamic> json) =>
      _$QueueStatusFromJson(json);
}

@freezed
class QueueStats with _$QueueStats {
  const factory QueueStats({
    required int pending,
    required int running,
    required int completed,
    required int failed,
    required int cancelled,
    required int total,
  }) = _QueueStats;

  factory QueueStats.fromJson(Map<String, dynamic> json) =>
      _$QueueStatsFromJson(json);
}

@freezed
class AutonomousStatus with _$AutonomousStatus {
  const factory AutonomousStatus({
    required bool enabled,
    required bool running,
    String? mission,
    String? currentObjective,
    int? cycleCount,
    double? lastCycleAt,
  }) = _AutonomousStatus;

  factory AutonomousStatus.fromJson(Map<String, dynamic> json) =>
      _$AutonomousStatusFromJson(json);
}

@freezed
class QueueTaskStatus with _$QueueTaskStatus {
  const factory QueueTaskStatus({
    required String taskId,
    required String job,
    required String state,
    required Map<String, dynamic> payload,
    int? priority,
    String? result,
    String? error,
    String? createdAt,
    String? startedAt,
    String? completedAt,
    String? workerId,
  }) = _QueueTaskStatus;

  factory QueueTaskStatus.fromJson(Map<String, dynamic> json) =>
      _$QueueTaskStatusFromJson(json);
}

@freezed
class QueueSubmitResult with _$QueueSubmitResult {
  const factory QueueSubmitResult({
    required String taskId,
    required Map<String, dynamic> job,
    required String state,
  }) = _QueueSubmitResult;

  factory QueueSubmitResult.fromJson(Map<String, dynamic> json) =>
      _$QueueSubmitResultFromJson(json);
}

// Metrics & Flags Models
@freezed
class MetricsSnapshot with _$MetricsSnapshot {
  const factory MetricsSnapshot({
    required double uptimeS,
    required Map<String, dynamic> counters,
    required Map<String, dynamic> latency,
  }) = _MetricsSnapshot;

  factory MetricsSnapshot.fromJson(Map<String, dynamic> json) =>
      _$MetricsSnapshotFromJson(json);
}

@freezed
class LatencyStats with _$LatencyStats {
  const factory LatencyStats({
    required int count,
    required double avgMs,
    required double p95Ms,
  }) = _LatencyStats;

  factory LatencyStats.fromJson(Map<String, dynamic> json) =>
      _$LatencyStatsFromJson(json);
}

@freezed
class FlagsSnapshot with _$FlagsSnapshot {
  const factory FlagsSnapshot({
    required Map<String, bool> flags,
  }) = _FlagsSnapshot;

  factory FlagsSnapshot.fromJson(Map<String, dynamic> json) =>
      _$FlagsSnapshotFromJson(json);
}

// Memory Models
@freezed
class MemoryItem with _$MemoryItem {
  const factory MemoryItem({
    required String id,
    required String content,
    Map<String, dynamic>? metadata,
    String? createdAt,
    double? score,
  }) = _MemoryItem;

  factory MemoryItem.fromJson(Map<String, dynamic> json) =>
      _$MemoryItemFromJson(json);
}

@freezed
class MemoryListResponse with _$MemoryListResponse {
  const factory MemoryListResponse({
    required List<MemoryItem> items,
    required int total,
    int? limit,
    int? offset,
  }) = _MemoryListResponse;

  factory MemoryListResponse.fromJson(Map<String, dynamic> json) =>
      _$MemoryListResponseFromJson(json);
}

@freezed
class MemorySearchResponse with _$MemorySearchResponse {
  const factory MemorySearchResponse({
    required List<MemoryItem> results,
    required String query,
    required int count,
  }) = _MemorySearchResponse;

  factory MemorySearchResponse.fromJson(Map<String, dynamic> json) =>
      _$MemorySearchResponseFromJson(json);
}

@freezed
class MemoryCreateResponse with _$MemoryCreateResponse {
  const factory MemoryCreateResponse({
    required String id,
    required String content,
    Map<String, dynamic>? metadata,
    String? createdAt,
  }) = _MemoryCreateResponse;

  factory MemoryCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$MemoryCreateResponseFromJson(json);
}

@freezed
class MemoryStatsResponse with _$MemoryStatsResponse {
  const factory MemoryStatsResponse({
    required int totalMemories,
    required int totalVectors,
    required String indexType,
    required double indexSizeMb,
  }) = _MemoryStatsResponse;

  factory MemoryStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$MemoryStatsResponseFromJson(json);
}

// Tools & Providers Models
@freezed
class ToolInfo with _$ToolInfo {
  const factory ToolInfo({
    required String name,
    required String description,
    required String category,
    required bool enabled,
    Map<String, dynamic>? schema,
    Map<String, dynamic>? metadata,
  }) = _ToolInfo;

  factory ToolInfo.fromJson(Map<String, dynamic> json) =>
      _$ToolInfoFromJson(json);
}

@freezed
class ToolsListResponse with _$ToolsListResponse {
  const factory ToolsListResponse({
    required List<ToolInfo> tools,
  }) = _ToolsListResponse;

  factory ToolsListResponse.fromJson(Map<String, dynamic> json) =>
      _$ToolsListResponseFromJson(json);
}

@freezed
class ToolRunResponse with _$ToolRunResponse {
  const factory ToolRunResponse({
    required dynamic result,
    String? error,
  }) = _ToolRunResponse;

  factory ToolRunResponse.fromJson(Map<String, dynamic> json) =>
      _$ToolRunResponseFromJson(json);
}

@freezed
class ToolLogEntry with _$ToolLogEntry {
  const factory ToolLogEntry({
    required String tool,
    required int calls,
    required int successes,
    required int failures,
    required double avgTime,
    String? lastError,
  }) = _ToolLogEntry;

  factory ToolLogEntry.fromJson(Map<String, dynamic> json) =>
      _$ToolLogEntryFromJson(json);
}

@freezed
class ToolsLogsResponse with _$ToolsLogsResponse {
  const factory ToolsLogsResponse({
    required List<ToolLogEntry> logs,
  }) = _ToolsLogsResponse;

  factory ToolsLogsResponse.fromJson(Map<String, dynamic> json) =>
      _$ToolsLogsResponseFromJson(json);
}

@freezed
class FrameworkTool with _$FrameworkTool {
  const factory FrameworkTool({
    required String name,
    required String description,
    required String category,
    required bool enabled,
    required String permission,
    required int timeoutSeconds,
    required int maxRetries,
    required bool dangerous,
  }) = _FrameworkTool;

  factory FrameworkTool.fromJson(Map<String, dynamic> json) =>
      _$FrameworkToolFromJson(json);
}

@freezed
class ToolsFrameworkResponse with _$ToolsFrameworkResponse {
  const factory ToolsFrameworkResponse({
    required List<FrameworkTool> tools,
  }) = _ToolsFrameworkResponse;

  factory ToolsFrameworkResponse.fromJson(Map<String, dynamic> json) =>
      _$ToolsFrameworkResponseFromJson(json);
}

@freezed
class ProviderInfo with _$ProviderInfo {
  const factory ProviderInfo({
    required String id,
    required String label,
    required bool configured,
    required bool enabled,
    required bool active,
    required int errorCount,
  }) = _ProviderInfo;

  factory ProviderInfo.fromJson(Map<String, dynamic> json) =>
      _$ProviderInfoFromJson(json);
}

@freezed
class ProvidersListResponse with _$ProvidersListResponse {
  const factory ProvidersListResponse({
    required List<ProviderInfo> providers,
  }) = _ProvidersListResponse;

  factory ProvidersListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProvidersListResponseFromJson(json);
}

// Brain Engine Models
@freezed
class BrainAnalyzeResponse with _$BrainAnalyzeResponse {
  const factory BrainAnalyzeResponse({
    required String goal,
    required String complexity,
    required int estimatedSteps,
    required List<String> suggestedTools,
    required List<String> subGoals,
  }) = _BrainAnalyzeResponse;

  factory BrainAnalyzeResponse.fromJson(Map<String, dynamic> json) =>
      _$BrainAnalyzeResponseFromJson(json);
}

@freezed
class GraphNode with _$GraphNode {
  const factory GraphNode({
    required String id,
    required String description,
    String? tool,
    String? agent,
    required List<String> dependsOn,
    required String state,
    required int attempts,
    String? error,
  }) = _GraphNode;

  factory GraphNode.fromJson(Map<String, dynamic> json) =>
      _$GraphNodeFromJson(json);
}

@freezed
class GraphProgress with _$GraphProgress {
  const factory GraphProgress({
    required int total,
    required Map<String, int> states,
    required double percent,
    required bool finished,
    required bool stuck,
  }) = _GraphProgress;

  factory GraphProgress.fromJson(Map<String, dynamic> json) =>
      _$GraphProgressFromJson(json);
}

@freezed
class BrainGraphResponse with _$BrainGraphResponse {
  const factory BrainGraphResponse({
    required List<GraphNode> nodes,
    required GraphProgress progress,
  }) = _BrainGraphResponse;

  factory BrainGraphResponse.fromJson(Map<String, dynamic> json) =>
      _$BrainGraphResponseFromJson(json);
}

// Multi-Agent System Models
@freezed
class AgentInfo with _$AgentInfo {
  const factory AgentInfo({
    required String name,
    required String role,
    required List<String> skills,
    required List<String> permissions,
    required int ok,
    required int errors,
    double? successRate,
    String? lastError,
    double? lastActive,
    required String status,
  }) = _AgentInfo;

  factory AgentInfo.fromJson(Map<String, dynamic> json) =>
      _$AgentInfoFromJson(json);
}

@freezed
class AgentsListResponse with _$AgentsListResponse {
  const factory AgentsListResponse({
    required List<AgentInfo> agents,
  }) = _AgentsListResponse;

  factory AgentsListResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentsListResponseFromJson(json);
}

@freezed
class OrchestrationAssignment with _$OrchestrationAssignment {
  const factory OrchestrationAssignment({
    required String nodeId,
    required String agentName,
    String? description,
    String? tool,
  }) = _OrchestrationAssignment;

  factory OrchestrationAssignment.fromJson(Map<String, dynamic> json) =>
      _$OrchestrationAssignmentFromJson(json);
}

@freezed
class AgentsOrchestrateResponse with _$AgentsOrchestrateResponse {
  const factory AgentsOrchestrateResponse({
    required BrainAnalyzeResponse analysis,
    required Map<String, String> assignments,
    required BrainGraphResponse graph,
  }) = _AgentsOrchestrateResponse;

  factory AgentsOrchestrateResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentsOrchestrateResponseFromJson(json);
}

@freezed
class AgentMessage with _$AgentMessage {
  const factory AgentMessage({
    required String from,
    required String to,
    required dynamic content,
    required double ts,
  }) = _AgentMessage;

  factory AgentMessage.fromJson(Map<String, dynamic> json) =>
      _$AgentMessageFromJson(json);
}

@freezed
class AgentsMessagesResponse with _$AgentsMessagesResponse {
  const factory AgentsMessagesResponse({
    required List<AgentMessage> messages,
  }) = _AgentsMessagesResponse;

  factory AgentsMessagesResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentsMessagesResponseFromJson(json);
}

// Workflow Engine Models
@freezed
class WorkflowPlanResponse with _$WorkflowPlanResponse {
  const factory WorkflowPlanResponse({
    required String runId,
    required Map<String, String> state,
  }) = _WorkflowPlanResponse;

  factory WorkflowPlanResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkflowPlanResponseFromJson(json);
}

@freezed
class WorkflowNode with _$WorkflowNode {
  const factory WorkflowNode({
    required String id,
    required String description,
    String? tool,
    String? agent,
    required List<String> dependsOn,
    required String state,
    required int attempts,
    String? error,
    String? recoveryNote,
  }) = _WorkflowNode;

  factory WorkflowNode.fromJson(Map<String, dynamic> json) =>
      _$WorkflowNodeFromJson(json);
}

@freezed
class WorkflowRunState with _$WorkflowRunState {
  const factory WorkflowRunState({
    required String id,
    required String goal,
    required String status,
    required double created,
    required List<dynamic> results,
    required List<WorkflowNode> nodes,
    int? replansLeft,
    List<dynamic>? recoveryLog,
    int? replanCount,
  }) = _WorkflowRunState;

  factory WorkflowRunState.fromJson(Map<String, dynamic> json) =>
      _$WorkflowRunStateFromJson(json);
}

@freezed
class WorkflowsRunsResponse with _$WorkflowsRunsResponse {
  const factory WorkflowsRunsResponse({
    required List<String> checkpoints,
  }) = _WorkflowsRunsResponse;

  factory WorkflowsRunsResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkflowsRunsResponseFromJson(json);
}

@freezed
class WorkflowExecuteResponse with _$WorkflowExecuteResponse {
  const factory WorkflowExecuteResponse({
    required String runId,
    required String status,
    required Map<String, dynamic> progress,
    required List<dynamic> results,
    required List<dynamic> recoveryLog,
    required int replansUsed,
    double? planConfidence,
    bool? shouldReplan,
    int? stepCount,
  }) = _WorkflowExecuteResponse;

  factory WorkflowExecuteResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkflowExecuteResponseFromJson(json);
}

// Autonomous Mode Models
@freezed
class AutonomousRunResponse with _$AutonomousRunResponse {
  const factory AutonomousRunResponse({
    required String goal,
    required String status,
    required Map<String, dynamic> progress,
    required List<dynamic> results,
    required List<dynamic> recoveryLog,
    required int replansUsed,
    double? planConfidence,
    bool? shouldReplan,
    int? stepCount,
  }) = _AutonomousRunResponse;

  factory AutonomousRunResponse.fromJson(Map<String, dynamic> json) =>
      _$AutonomousRunResponseFromJson(json);
}

// Multi-Model Router Models
@freezed
class LLMProviderInfo with _$LLMProviderInfo {
  const factory LLMProviderInfo({
    required String id,
    required String label,
    required bool configured,
    required bool enabled,
    required bool active,
    required int errorCount,
  }) = _LLMProviderInfo;

  factory LLMProviderInfo.fromJson(Map<String, dynamic> json) =>
      _$LLMProviderInfoFromJson(json);
}

@freezed
class LLMProvidersResponse with _$LLMProvidersResponse {
  const factory LLMProvidersResponse({
    required List<LLMProviderInfo> providers,
  }) = _LLMProvidersResponse;

  factory LLMProvidersResponse.fromJson(Map<String, dynamic> json) =>
      _$LLMProvidersResponseFromJson(json);
}

@freezed
class LLMProviderStat with _$LLMProviderStat {
  const factory LLMProviderStat({
    required double latencyEmaS,
    required int ok,
    required int errors,
    required double errorRate,
  }) = _LLMProviderStat;

  factory LLMProviderStat.fromJson(Map<String, dynamic> json) =>
      _$LLMProviderStatFromJson(json);
}

@freezed
class LLMStatsResponse with _$LLMStatsResponse {
  const factory LLMStatsResponse({
    required Map<String, LLMProviderStat> stats,
    required Map<String, Map<String, dynamic>> table,
  }) = _LLMStatsResponse;

  factory LLMStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$LLMStatsResponseFromJson(json);
}

@freezed
class LLMStrategyResponse with _$LLMStrategyResponse {
  const factory LLMStrategyResponse({
    required String strategy,
    required List<String> order,
  }) = _LLMStrategyResponse;

  factory LLMStrategyResponse.fromJson(Map<String, dynamic> json) =>
      _$LLMStrategyResponseFromJson(json);
}

// Enterprise Layer Models
@freezed
class RoleInfo with _$RoleInfo {
  const factory RoleInfo({
    required String name,
    required String description,
    required List<String> permissions,
  }) = _RoleInfo;

  factory RoleInfo.fromJson(Map<String, dynamic> json) =>
      _$RoleInfoFromJson(json);
}

@freezed
class AdminRolesResponse with _$AdminRolesResponse {
  const factory AdminRolesResponse({
    required Map<String, RoleInfo> roles,
  }) = _AdminRolesResponse;

  factory AdminRolesResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminRolesResponseFromJson(json);
}

@freezed
class AdminOrg with _$AdminOrg {
  const factory AdminOrg({
    required String id,
    required String name,
    required String createdAt,
    int? memberCount,
  }) = _AdminOrg;

  factory AdminOrg.fromJson(Map<String, dynamic> json) =>
      _$AdminOrgFromJson(json);
}

@freezed
class AdminOrgsResponse with _$AdminOrgsResponse {
  const factory AdminOrgsResponse({
    required List<AdminOrg> orgs,
  }) = _AdminOrgsResponse;

  factory AdminOrgsResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminOrgsResponseFromJson(json);
}

@freezed
class AdminOrgResponse with _$AdminOrgResponse {
  const factory AdminOrgResponse({
    required String id,
    required String name,
  }) = _AdminOrgResponse;

  factory AdminOrgResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminOrgResponseFromJson(json);
}

@freezed
class OrgMember with _$OrgMember {
  const factory OrgMember({
    required String email,
    required String role,
    String? teamId,
    required String joinedAt,
  }) = _OrgMember;

  factory OrgMember.fromJson(Map<String, dynamic> json) =>
      _$OrgMemberFromJson(json);
}

@freezed
class AdminOrgMembersResponse with _$AdminOrgMembersResponse {
  const factory AdminOrgMembersResponse({
    required List<OrgMember> members,
  }) = _AdminOrgMembersResponse;

  factory AdminOrgMembersResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminOrgMembersResponseFromJson(json);
}

@freezed
class AdminApiKey with _$AdminApiKey {
  const factory AdminApiKey({
    required String id,
    required String name,
    required String prefix,
    required String createdAt,
    String? lastUsedAt,
    required bool revoked,
  }) = _AdminApiKey;

  factory AdminApiKey.fromJson(Map<String, dynamic> json) =>
      _$AdminApiKeyFromJson(json);
}

@freezed
class AdminApiKeysResponse with _$AdminApiKeysResponse {
  const factory AdminApiKeysResponse({
    required List<AdminApiKey> keys,
  }) = _AdminApiKeysResponse;

  factory AdminApiKeysResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminApiKeysResponseFromJson(json);
}

@freezed
class AdminApiKeyCreatedResponse with _$AdminApiKeyCreatedResponse {
  const factory AdminApiKeyCreatedResponse({
    required String id,
    required String name,
    required String key,  // Only shown once at creation
    required String prefix,
    required String createdAt,
  }) = _AdminApiKeyCreatedResponse;

  factory AdminApiKeyCreatedResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminApiKeyCreatedResponseFromJson(json);
}

@freezed
class AuditEvent with _$AuditEvent {
  const factory AuditEvent({
    required String id,
    required String actor,
    required String action,
    required String target,
    required Map<String, dynamic> details,
    required double timestamp,
  }) = _AuditEvent;

  factory AuditEvent.fromJson(Map<String, dynamic> json) =>
      _$AuditEventFromJson(json);
}

@freezed
class AdminAuditResponse with _$AdminAuditResponse {
  const factory AdminAuditResponse({
    required List<AuditEvent> events,
  }) = _AdminAuditResponse;

  factory AdminAuditResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminAuditResponseFromJson(json);
}

@freezed
class AdminUsageResponse with _$AdminUsageResponse {
  const factory AdminUsageResponse({
    required Map<String, dynamic> summary,
  }) = _AdminUsageResponse;

  factory AdminUsageResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminUsageResponseFromJson(json);
}

@freezed
class AdminDashboardResponse with _$AdminDashboardResponse {
  const factory AdminDashboardResponse({
    required Map<String, dynamic> metrics,
    required Map<String, dynamic> agents,
    required Map<String, dynamic> providers,
    required int queueDepth,
  }) = _AdminDashboardResponse;

  factory AdminDashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardResponseFromJson(json);
}

@freezed
class AdminOwnerModeResponse with _$AdminOwnerModeResponse {
  const factory AdminOwnerModeResponse({
    required String mode,
    String? message,
  }) = _AdminOwnerModeResponse;

  factory AdminOwnerModeResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminOwnerModeResponseFromJson(json);
}

// Learning Layer Models
@freezed
class LearningFeedbackResponse with _$LearningFeedbackResponse {
  const factory LearningFeedbackResponse({
    required bool recorded,
    required Map<String, dynamic> stats,
  }) = _LearningFeedbackResponse;

  factory LearningFeedbackResponse.fromJson(Map<String, dynamic> json) =>
      _$LearningFeedbackResponseFromJson(json);
}

@freezed
class FeedbackStats with _$FeedbackStats {
  const factory FeedbackStats({
    required int total,
    required int positive,
    required int negative,
    double? satisfaction,
  }) = _FeedbackStats;

  factory FeedbackStats.fromJson(Map<String, dynamic> json) =>
      _$FeedbackStatsFromJson(json);
}

@freezed
class Lesson with _$Lesson {
  const factory Lesson({
    required double ts,
    required String goal,
    required String comment,
  }) = _Lesson;

  factory Lesson.fromJson(Map<String, dynamic> json) =>
      _$LessonFromJson(json);
}

@freezed
class LearningStatsResponse with _$LearningStatsResponse {
  const factory LearningStatsResponse({
    required FeedbackStats feedback,
    required List<Lesson> lessons,
    required Map<String, dynamic> prompts,
  }) = _LearningStatsResponse;

  factory LearningStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$LearningStatsResponseFromJson(json);
}

@freezed
class ExperienceEpisode with _$ExperienceEpisode {
  const factory ExperienceEpisode({
    required int id,
    required double ts,
    required String goal,
    required List<dynamic> steps,
    required String outcome,
    required double confidence,
    double? similarity,
  }) = _ExperienceEpisode;

  factory ExperienceEpisode.fromJson(Map<String, dynamic> json) =>
      _$ExperienceEpisodeFromJson(json);
}

@freezed
class LearningExperienceResponse with _$LearningExperienceResponse {
  const factory LearningExperienceResponse({
    List<ExperienceEpisode>? similar,
    List<ExperienceEpisode>? history,
    Map<String, dynamic>? successRate,
  }) = _LearningExperienceResponse;

  factory LearningExperienceResponse.fromJson(Map<String, dynamic> json) =>
      _$LearningExperienceResponseFromJson(json);
}

@freezed
class LearningCompressResponse with _$LearningCompressResponse {
  const factory LearningCompressResponse({
    required bool dryRun,
    required String memoryType,
    required Map<String, dynamic> result,
  }) = _LearningCompressResponse;

  factory LearningCompressResponse.fromJson(Map<String, dynamic> json) =>
      _$LearningCompressResponseFromJson(json);
}

@freezed
class PromptVariant with _$PromptVariant {
  const factory PromptVariant({
    required int ok,
    required int fail,
    required double score,
  }) = _PromptVariant;

  factory PromptVariant.fromJson(Map<String, dynamic> json) =>
      _$PromptVariantFromJson(json);
}

@freezed
class LearningPromptsResponse with _$LearningPromptsResponse {
  const factory LearningPromptsResponse({
    required Map<String, Map<String, PromptVariant>> prompts,
  }) = _LearningPromptsResponse;

  factory LearningPromptsResponse.fromJson(Map<String, dynamic> json) =>
      _$LearningPromptsResponseFromJson(json);
}

// RAG (Phase 11) Models
@freezed
class RAGStatsResponse with _$RAGStatsResponse {
  const factory RAGStatsResponse({
    required int totalDocuments,
    required int totalChunks,
    required String indexType,
    required double indexSizeMb,
    required Map<String, dynamic> searchEngines,
  }) = _RAGStatsResponse;

  factory RAGStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$RAGStatsResponseFromJson(json);
}

@freezed
class RAGDocument with _$RAGDocument {
  const factory RAGDocument({
    required String id,
    required String title,
    required String docType,
    required int chunkCount,
    required String createdAt,
    required double sizeKb,
  }) = _RAGDocument;

  factory RAGDocument.fromJson(Map<String, dynamic> json) =>
      _$RAGDocumentFromJson(json);
}

@freezed
class RAGDocumentsResponse with _$RAGDocumentsResponse {
  const factory RAGDocumentsResponse({
    required List<RAGDocument> documents,
  }) = _RAGDocumentsResponse;

  factory RAGDocumentsResponse.fromJson(Map<String, dynamic> json) =>
      _$RAGDocumentsResponseFromJson(json);
}

@freezed
class RAGIngestResponse with _$RAGIngestResponse {
  const factory RAGIngestResponse({
    required String docId,
    required int chunksCreated,
    required String title,
  }) = _RAGIngestResponse;

  factory RAGIngestResponse.fromJson(Map<String, dynamic> json) =>
      _$RAGIngestResponseFromJson(json);
}

@freezed
class RAGSearchResult with _$RAGSearchResult {
  const factory RAGSearchResult({
    required String docId,
    required String title,
    required String content,
    required double score,
    required String docType,
  }) = _RAGSearchResult;

  factory RAGSearchResult.fromJson(Map<String, dynamic> json) =>
      _$RAGSearchResultFromJson(json);
}

@freezed
class RAGSearchResponse with _$RAGSearchResponse {
  const factory RAGSearchResponse({
    required String query,
    required String mode,
    required List<RAGSearchResult> results,
  }) = _RAGSearchResponse;

  factory RAGSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$RAGSearchResponseFromJson(json);
}

@freezed
class RAGContextResponse with _$RAGContextResponse {
  const factory RAGContextResponse({
    required String context,
    required List<RAGSearchResult> citations,
  }) = _RAGContextResponse;

  factory RAGContextResponse.fromJson(Map<String, dynamic> json) =>
      _$RAGContextResponseFromJson(json);
}

// Device Bridge / Phone Control Models
@freezed
class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String id,
    required String name,
    required double pairedAt,
    double? lastSeen,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}

@freezed
class DeviceListResponse with _$DeviceListResponse {
  const factory DeviceListResponse({
    required List<DeviceInfo> devices,
  }) = _DeviceListResponse;

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceListResponseFromJson(json);
}

@freezed
class DevicePairStartResponse with _$DevicePairStartResponse {
  const factory DevicePairStartResponse({
    required String pairingCode,
    required String name,
  }) = _DevicePairStartResponse;

  factory DevicePairStartResponse.fromJson(Map<String, dynamic> json) =>
      _$DevicePairStartResponseFromJson(json);
}

@freezed
class DevicePairCompleteResponse with _$DevicePairCompleteResponse {
  const factory DevicePairCompleteResponse({
    required String deviceId,
    required String secret,
  }) = _DevicePairCompleteResponse;

  factory DevicePairCompleteResponse.fromJson(Map<String, dynamic> json) =>
      _$DevicePairCompleteResponseFromJson(json);
}

@freezed
class DeviceCommandEntry with _$DeviceCommandEntry {
  const factory DeviceCommandEntry({
    required String id,
    required String deviceId,
    required String action,
    required Map<String, dynamic> params,
    required String status,
    required double createdAt,
    Map<String, dynamic>? result,
  }) = _DeviceCommandEntry;

  factory DeviceCommandEntry.fromJson(Map<String, dynamic> json) =>
      _$DeviceCommandEntryFromJson(json);
}

@freezed
class DeviceHistoryResponse with _$DeviceHistoryResponse {
  const factory DeviceHistoryResponse({
    required List<DeviceCommandEntry> commands,
  }) = _DeviceHistoryResponse;

  factory DeviceHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceHistoryResponseFromJson(json);
}

@freezed
class DeviceCommandResponse with _$DeviceCommandResponse {
  const factory DeviceCommandResponse({
    required String id,
    required String deviceId,
    required String action,
    required Map<String, dynamic> params,
    required String status,
    required double createdAt,
  }) = _DeviceCommandResponse;

  factory DeviceCommandResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceCommandResponseFromJson(json);
}

@freezed
class DeviceCommandResult with _$DeviceCommandResult {
  const factory DeviceCommandResult({
    required String id,
    required String status,
    Map<String, dynamic>? result,
  }) = _DeviceCommandResult;

  factory DeviceCommandResult.fromJson(Map<String, dynamic> json) =>
      _$DeviceCommandResultFromJson(json);
}

// Instance CRUD Models (Phase 14)
@freezed
class InstanceInfo with _$InstanceInfo {
  const factory InstanceInfo({
    required String id,
    required String name,
    required String persona,
    required String memoryScope,
    required List<String> skills,
    required double budgetUsd,
    required String owner,
    required double createdAt,
  }) = _InstanceInfo;

  factory InstanceInfo.fromJson(Map<String, dynamic> json) =>
      _$InstanceInfoFromJson(json);
}

@freezed
class InstancesListResponse with _$InstancesListResponse {
  const factory InstancesListResponse({
    required List<InstanceInfo> instances,
  }) = _InstancesListResponse;

  factory InstancesListResponse.fromJson(Map<String, dynamic> json) =>
      _$InstancesListResponseFromJson(json);
}

@freezed
class InstanceCreateResponse with _$InstanceCreateResponse {
  const factory InstanceCreateResponse({
    required String id,
    required String name,
    required String persona,
    required String memoryScope,
    required List<String> skills,
    required double budgetUsd,
    required String owner,
    required double createdAt,
  }) = _InstanceCreateResponse;

  factory InstanceCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$InstanceCreateResponseFromJson(json);
}

@freezed
class InstanceResponse with _$InstanceResponse {
  const factory InstanceResponse({
    required InstanceInfo instance,
  }) = _InstanceResponse;

  factory InstanceResponse.fromJson(Map<String, dynamic> json) =>
      _$InstanceResponseFromJson(json);
}

// Hosting API Models (Phase 15)
@freezed
class HostingAppInfo with _$HostingAppInfo {
  const factory HostingAppInfo({
    required String id,
    required String name,
    required String kind,
    required String entry,
    required String path,
    required String command,
    required int port,
    required Map<String, String> env,
    required String owner,
    required bool autostart,
    required bool tunnel,
    required String tunnelUrl,
    required int pid,
    required String logFile,
    required double createdAt,
    double? startedAt,
    required bool alive,
    required bool reachable,
  }) = _HostingAppInfo;

  factory HostingAppInfo.fromJson(Map<String, dynamic> json) =>
      _$HostingAppInfoFromJson(json);
}

@freezed
class HostingAppsResponse with _$HostingAppsResponse {
  const factory HostingAppsResponse({
    required List<HostingAppInfo> apps,
  }) = _HostingAppsResponse;

  factory HostingAppsResponse.fromJson(Map<String, dynamic> json) =>
      _$HostingAppsResponseFromJson(json);
}

@freezed
class HostingDeployResponse with _$HostingDeployResponse {
  const factory HostingDeployResponse({
    required bool ok,
    required String id,
    required String name,
    required String kind,
    required String entry,
    required String path,
    required String command,
    required int port,
    required Map<String, String> env,
    required String owner,
    required bool autostart,
    required bool tunnel,
    String? tunnelUrl,
    int? pid,
    String? logFile,
    double? createdAt,
    double? startedAt,
    String? error,
  }) = _HostingDeployResponse;

  factory HostingDeployResponse.fromJson(Map<String, dynamic> json) =>
      _$HostingDeployResponseFromJson(json);
}

@freezed
class HostingAppResponse with _$HostingAppResponse {
  const factory HostingAppResponse({
    required bool ok,
    required HostingAppInfo app,
  }) = _HostingAppResponse;

  factory HostingAppResponse.fromJson(Map<String, dynamic> json) =>
      _$HostingAppResponseFromJson(json);
}

@freezed
class HostingLogsResponse with _$HostingLogsResponse {
  const factory HostingLogsResponse({
    required bool ok,
    required String name,
    required List<String> lines,
  }) = _HostingLogsResponse;

  factory HostingLogsResponse.fromJson(Map<String, dynamic> json) =>
      _$HostingLogsResponseFromJson(json);
}

// Remote VPS Deploy Models (Phase 16)
@freezed
class RemoteConfigResponse with _$RemoteConfigResponse {
  const factory RemoteConfigResponse({
    required String host,
    required int port,
    required String user,
    required bool hasPassword,
    required bool hasKey,
    required String? sshCmd,
    required String? scpCmd,
    required bool paramiko,
  }) = _RemoteConfigResponse;

  factory RemoteConfigResponse.fromJson(Map<String, dynamic> json) =>
      _$RemoteConfigResponseFromJson(json);
}

@freezed
class RemoteDeployResponse with _$RemoteDeployResponse {
  const factory RemoteDeployResponse({
    required bool ok,
    required String app,
    required String image,
    String? dockerfileDir,
    Map<String, String>? ports,
    Map<String, String>? env,
    int? pid,
    String? containerId,
    String? output,
    String? error,
  }) = _RemoteDeployResponse;

  factory RemoteDeployResponse.fromJson(Map<String, dynamic> json) =>
      _$RemoteDeployResponseFromJson(json);
}

@freezed
class RemoteActionResponse with _$RemoteActionResponse {
  const factory RemoteActionResponse({
    required bool ok,
    required String app,
    required String action,
    String? output,
    String? error,
  }) = _RemoteActionResponse;

  factory RemoteActionResponse.fromJson(Map<String, dynamic> json) =>
      _$RemoteActionResponseFromJson(json);
}

@freezed
class RemoteLogsResponse with _$RemoteLogsResponse {
  const factory RemoteLogsResponse({
    required bool ok,
    required String app,
    required String logs,
  }) = _RemoteLogsResponse;

  factory RemoteLogsResponse.fromJson(Map<String, dynamic> json) =>
      _$RemoteLogsResponseFromJson(json);
}

// Cognitive Loop Models (Phase 17)
@freezed
class CognitiveStatusResponse with _$CognitiveStatusResponse {
  const factory CognitiveStatusResponse({
    required bool enabled,
    required bool running,
    required String status,
    required String mode,
    int? cycleCount,
    double? lastCycleAt,
    String? currentStep,
  }) = _CognitiveStatusResponse;

  factory CognitiveStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$CognitiveStatusResponseFromJson(json);
}

@freezed
class CognitiveCycleResponse with _$CognitiveCycleResponse {
  const factory CognitiveCycleResponse({
    required bool ok,
    required String cycleId,
    required String step,
    required String thinking,
    String? action,
    String? observation,
    String? error,
  }) = _CognitiveCycleResponse;

  factory CognitiveCycleResponse.fromJson(Map<String, dynamic> json) =>
      _$CognitiveCycleResponseFromJson(json);
}

