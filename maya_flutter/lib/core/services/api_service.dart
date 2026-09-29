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

  Future<TtsResult> speakText(
    String text, {
    String voice = 'en-US-AriaNeural',
  }) async {
    final response = await _dio.post(
      AppConfig.voiceSpeak,
      data: {'text': text, 'voice': voice},
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
  Future<QueueStatus> getQueueStatus() async {
    final response = await _dio.get(AppConfig.queueStatus);
    return QueueStatus.fromJson(response.data);
  }

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
    required Map<String, dynamic> state,
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
