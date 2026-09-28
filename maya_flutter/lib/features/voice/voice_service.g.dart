// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TtsResultImpl _$$TtsResultImplFromJson(Map json) => $checkedCreate(
      r'_$TtsResultImpl',
      json,
      ($checkedConvert) {
        final val = _$TtsResultImpl(
          success: $checkedConvert('success', (v) => v as bool),
          audioBase64: $checkedConvert('audio_base64', (v) => v as String?),
          format: $checkedConvert('format', (v) => v as String?),
          provider: $checkedConvert('provider', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'audioBase64': 'audio_base64'},
    );

Map<String, dynamic> _$$TtsResultImplToJson(_$TtsResultImpl instance) {
  final val = <String, dynamic>{
    'success': instance.success,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('audio_base64', instance.audioBase64);
  writeNotNull('format', instance.format);
  writeNotNull('provider', instance.provider);
  writeNotNull('error', instance.error);
  return val;
}

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
