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

  ApiService() {
    _initDio();
  }

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

  String? _getToken() {
    // In a real app, this would come from secure storage
    // For now, we'll use a simple in-memory approach
    return _storedToken;
  }

  String? _storedToken;
  String? _storedRefreshToken;

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
        return true;
      }
    } catch (e) {
      _logger.e('Token refresh failed: $e');
    }
    return false;
  }

  void setTokens(String accessToken, String refreshToken) {
    _storedToken = accessToken;
    _storedRefreshToken = refreshToken;
  }

  void clearTokens() {
    _storedToken = null;
    _storedRefreshToken = null;
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

  void dispose() {
    _wsController.close();
    _reconnectTimer?.cancel();
    disconnectWebSocket();
    _dio.close();
  }
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
    required String audioBase64,
    required String format,
    required String provider,
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
    required String description,
    List<String>? objects,
    String? text,
    String? analysis,
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
