// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map<String, dynamic> json) =>
    _$AuthResponseImpl(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'avatar': instance.avatar,
      'role': instance.role,
    };

_$TranscriptionResultImpl _$$TranscriptionResultImplFromJson(
        Map<String, dynamic> json) =>
    _$TranscriptionResultImpl(
      transcript: json['transcript'] as String,
      language: json['language'] as String,
      languageProbability: (json['languageProbability'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      segments: (json['segments'] as List<dynamic>?)
          ?.map((e) => TranscriptionSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$TranscriptionResultImplToJson(
        _$TranscriptionResultImpl instance) =>
    <String, dynamic>{
      'transcript': instance.transcript,
      'language': instance.language,
      'languageProbability': instance.languageProbability,
      'duration': instance.duration,
      'segments': instance.segments,
    };

_$TranscriptionSegmentImpl _$$TranscriptionSegmentImplFromJson(
        Map<String, dynamic> json) =>
    _$TranscriptionSegmentImpl(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String,
      avgLogprob: (json['avgLogprob'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$TranscriptionSegmentImplToJson(
        _$TranscriptionSegmentImpl instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'text': instance.text,
      'avgLogprob': instance.avgLogprob,
    };

_$TtsResultImpl _$$TtsResultImplFromJson(Map<String, dynamic> json) =>
    _$TtsResultImpl(
      success: json['success'] as bool,
      audioBase64: json['audioBase64'] as String?,
      format: json['format'] as String?,
      provider: json['provider'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$TtsResultImplToJson(_$TtsResultImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'audioBase64': instance.audioBase64,
      'format': instance.format,
      'provider': instance.provider,
      'error': instance.error,
    };

_$AgentChatResponseImpl _$$AgentChatResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$AgentChatResponseImpl(
      reply: json['reply'] as String,
      timestamp: json['timestamp'] as String,
      taskId: json['taskId'] as String?,
    );

Map<String, dynamic> _$$AgentChatResponseImplToJson(
        _$AgentChatResponseImpl instance) =>
    <String, dynamic>{
      'reply': instance.reply,
      'timestamp': instance.timestamp,
      'taskId': instance.taskId,
    };

_$AgentRunResponseImpl _$$AgentRunResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$AgentRunResponseImpl(
      taskId: json['taskId'] as String,
      status: json['status'] as String,
      result: json['result'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$AgentRunResponseImplToJson(
        _$AgentRunResponseImpl instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'status': instance.status,
      'result': instance.result,
      'error': instance.error,
    };

_$AgentThinkResponseImpl _$$AgentThinkResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$AgentThinkResponseImpl(
      analysis: json['analysis'] as String,
      plan: json['plan'] as String?,
      steps:
          (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$AgentThinkResponseImplToJson(
        _$AgentThinkResponseImpl instance) =>
    <String, dynamic>{
      'analysis': instance.analysis,
      'plan': instance.plan,
      'steps': instance.steps,
    };

_$VisionAnalysisResultImpl _$$VisionAnalysisResultImplFromJson(
        Map<String, dynamic> json) =>
    _$VisionAnalysisResultImpl(
      analysis: json['analysis'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$VisionAnalysisResultImplToJson(
        _$VisionAnalysisResultImpl instance) =>
    <String, dynamic>{
      'analysis': instance.analysis,
      'tags': instance.tags,
      'metadata': instance.metadata,
    };

_$OcrResultImpl _$$OcrResultImplFromJson(Map<String, dynamic> json) =>
    _$OcrResultImpl(
      text: json['text'] as String,
      regions: (json['regions'] as List<dynamic>?)
          ?.map((e) => OcrRegion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$OcrResultImplToJson(_$OcrResultImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'regions': instance.regions,
    };

_$OcrRegionImpl _$$OcrRegionImplFromJson(Map<String, dynamic> json) =>
    _$OcrRegionImpl(
      text: json['text'] as String,
      bounds:
          const RectConverter().fromJson(json['bounds'] as Map<String, double>),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$OcrRegionImplToJson(_$OcrRegionImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'bounds': const RectConverter().toJson(instance.bounds),
      'confidence': instance.confidence,
    };

_$SystemStatusImpl _$$SystemStatusImplFromJson(Map<String, dynamic> json) =>
    _$SystemStatusImpl(
      status: json['status'] as String,
      maya: json['maya'] as String,
    );

Map<String, dynamic> _$$SystemStatusImplToJson(_$SystemStatusImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'maya': instance.maya,
    };

_$SystemStatsImpl _$$SystemStatsImplFromJson(Map<String, dynamic> json) =>
    _$SystemStatsImpl(
      cpu: CpuStats.fromJson(json['cpu'] as Map<String, dynamic>),
      memory: MemoryStats.fromJson(json['memory'] as Map<String, dynamic>),
      disk: DiskStats.fromJson(json['disk'] as Map<String, dynamic>),
      load: LoadStats.fromJson(json['load'] as Map<String, dynamic>),
      network: json['network'] == null
          ? null
          : NetworkStats.fromJson(json['network'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SystemStatsImplToJson(_$SystemStatsImpl instance) =>
    <String, dynamic>{
      'cpu': instance.cpu,
      'memory': instance.memory,
      'disk': instance.disk,
      'load': instance.load,
      'network': instance.network,
    };

_$CpuStatsImpl _$$CpuStatsImplFromJson(Map<String, dynamic> json) =>
    _$CpuStatsImpl(
      percent: (json['percent'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$$CpuStatsImplToJson(_$CpuStatsImpl instance) =>
    <String, dynamic>{
      'percent': instance.percent,
      'count': instance.count,
    };

_$MemoryStatsImpl _$$MemoryStatsImplFromJson(Map<String, dynamic> json) =>
    _$MemoryStatsImpl(
      totalGb: (json['totalGb'] as num).toDouble(),
      availableGb: (json['availableGb'] as num).toDouble(),
      usedGb: (json['usedGb'] as num).toDouble(),
      percent: (json['percent'] as num).toDouble(),
    );

Map<String, dynamic> _$$MemoryStatsImplToJson(_$MemoryStatsImpl instance) =>
    <String, dynamic>{
      'totalGb': instance.totalGb,
      'availableGb': instance.availableGb,
      'usedGb': instance.usedGb,
      'percent': instance.percent,
    };

_$DiskStatsImpl _$$DiskStatsImplFromJson(Map<String, dynamic> json) =>
    _$DiskStatsImpl(
      totalGb: (json['totalGb'] as num).toDouble(),
      usedGb: (json['usedGb'] as num).toDouble(),
      freeGb: (json['freeGb'] as num).toDouble(),
      percent: (json['percent'] as num).toDouble(),
    );

Map<String, dynamic> _$$DiskStatsImplToJson(_$DiskStatsImpl instance) =>
    <String, dynamic>{
      'totalGb': instance.totalGb,
      'usedGb': instance.usedGb,
      'freeGb': instance.freeGb,
      'percent': instance.percent,
    };

_$LoadStatsImpl _$$LoadStatsImplFromJson(Map<String, dynamic> json) =>
    _$LoadStatsImpl(
      loadAvg: (json['loadAvg'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$$LoadStatsImplToJson(_$LoadStatsImpl instance) =>
    <String, dynamic>{
      'loadAvg': instance.loadAvg,
    };

_$NetworkStatsImpl _$$NetworkStatsImplFromJson(Map<String, dynamic> json) =>
    _$NetworkStatsImpl(
      bytesSent: (json['bytesSent'] as num).toInt(),
      bytesRecv: (json['bytesRecv'] as num).toInt(),
    );

Map<String, dynamic> _$$NetworkStatsImplToJson(_$NetworkStatsImpl instance) =>
    <String, dynamic>{
      'bytesSent': instance.bytesSent,
      'bytesRecv': instance.bytesRecv,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiServiceHash() => r'd76dea2a3d4afd840c19952cd59fe889ce36151d';

/// See also [apiService].
@ProviderFor(apiService)
final apiServiceProvider = AutoDisposeProvider<ApiService>.internal(
  apiService,
  name: r'apiServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiServiceRef = AutoDisposeProviderRef<ApiService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
