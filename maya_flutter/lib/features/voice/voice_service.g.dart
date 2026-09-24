// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$voiceServiceHash() => r'3818e7b60e493f436ac5d27a5c0136e26ab619cb';

/// See also [voiceService].
@ProviderFor(voiceService)
final voiceServiceProvider = AutoDisposeProvider<VoiceService>.internal(
  voiceService,
  name: r'voiceServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$voiceServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VoiceServiceRef = AutoDisposeProviderRef<VoiceService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
