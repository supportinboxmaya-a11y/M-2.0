import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_models.freezed.dart';
part 'app_models.g.dart';

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

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    required String refreshToken,
    required UserProfile user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
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

  factory UserProfile.fromJson(Map<String, dynamic> json) => _UserProfileFromJson(json);
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

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) => _$TranscriptionResultFromJson(json);
}

@freezed
class TranscriptionSegment with _$TranscriptionSegment {
  const factory TranscriptionSegment({
    required double start,
    required double end,
    required String text,
    double? avgLogprob,
  }) = _TranscriptionSegment;

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) => _TranscriptionSegmentFromJson(json);
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

  factory TtsResult.fromJson(Map<String, dynamic> json) => _$TtsResultFromJson(json);
}

@freezed
class AgentChatResponse with _$AgentChatResponse {
  const factory AgentChatResponse({
    required String reply,
    required String timestamp,
    String? taskId,
  }) = _AgentChatResponse;

  factory AgentChatResponse.fromJson(Map<String, dynamic> json) => _AgentChatResponseFromJson(json);
}

@freezed
class ChatStreamChunk with _$ChatStreamChunk {
  const factory ChatStreamChunk({
    String? delta,
    bool? done,
    String? error,
  }) = _ChatStreamChunk;

  factory ChatStreamChunk.fromJson(Map<String, dynamic> json) => _ChatStreamChunkFromJson(json);
}

@freezed
class AgentRunResponse with _$AgentRunResponse {
  const factory AgentRunResponse({
    required String taskId,
    required String status,
    String? result,
    String? error,
  }) = _AgentRunResponse;

  factory AgentRunResponse.fromJson(Map<String, dynamic> json) => _AgentRunResponseFromJson(json);
}

@freezed
class AgentThinkResponse with _$AgentThinkResponse {
  const factory AgentThinkResponse({
    required String analysis,
    String? plan,
    List<String>? steps,
  }) = _AgentThinkResponse;

  factory AgentThinkResponse.fromJson(Map<String, dynamic> json) => _AgentThinkResponseFromJson(json);
}

@freezed
class VisionAnalysisResult with _$VisionAnalysisResult {
  const factory VisionAnalysisResult({
    required String description,
    List<String>? objects,
    String? text,
    String? analysis,
  }) = _VisionAnalysisResult;

  factory VisionAnalysisResult.fromJson(Map<String, dynamic> json) => _VisionAnalysisResultFromJson(json);
}

@freezed
class OcrResult with _$OcrResult {
  const factory OcrResult({
    required String text,
    List<OcrRegion>? regions,
  }) = _OcrResult;

  factory OcrResult.fromJson(Map<String, dynamic> json) => _OcrResultFromJson(json);
}

@freezed
class OcrRegion with _$OcrRegion {
  const factory OcrRegion({
    required String text,
    @RectConverter() required Rect bounds,
    double? confidence,
  }) = _OcrRegion;

  factory OcrRegion.fromJson(Map<String, dynamic> json) => _OcrRegionFromJson(json);
}

@freezed
class SystemStatus with _$SystemStatus {
  const factory SystemStatus({
    required String status,
    required String maya,
    String? version,
    int? uptime,
  }) = _SystemStatus;

  factory SystemStatus.fromJson(Map<String, dynamic> json) => _SystemStatusFromJson(json);
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

  factory SystemStats.fromJson(Map<String, dynamic> json) => _SystemStatsFromJson(json);
}

@freezed
class CpuStats with _$CpuStats {
  const factory CpuStats({
    required double percent,
    required int count,
  }) = _CpuStats;

  factory CpuStats.fromJson(Map<String, dynamic> json) => _CpuStatsFromJson(json);
}

@freezed
class MemoryStats with _$MemoryStats {
  const factory MemoryStats({
    required double totalGb,
    required double availableGb,
    required double usedGb,
    required double percent,
  }) = _MemoryStats;

  factory MemoryStats.fromJson(Map<String, dynamic> json) => _MemoryStatsFromJson(json);
}

@freezed
class DiskStats with _$DiskStats {
  const factory DiskStats({
    required double totalGb,
    required double usedGb,
    required double freeGb,
    required double percent,
  }) = _DiskStats;

  factory DiskStats.fromJson(Map<String, dynamic> json) => _DiskStatsFromJson(json);
}

@freezed
class LoadStats with _$LoadStats {
  const factory LoadStats({
    required List<double> loadAvg,
  }) = _LoadStats;

  factory LoadStats.fromJson(Map<String, dynamic> json) => _LoadStatsFromJson(json);
}

@freezed
class NetworkStats with _$NetworkStats {
  const factory NetworkStats({
    required int bytesSent,
    required int bytesRecv,
  }) = _NetworkStats;

  factory NetworkStats.fromJson(Map<String, dynamic> json) => _NetworkStatsFromJson(json);
}
