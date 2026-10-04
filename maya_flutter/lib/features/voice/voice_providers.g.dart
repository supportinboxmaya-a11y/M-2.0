// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$voiceStateStreamHash() => r'0d5ea08bcba475d19816333cfe339002ad25c636';

/// See also [voiceStateStream].
@ProviderFor(voiceStateStream)
final voiceStateStreamProvider = AutoDisposeStreamProvider<VoiceState>.internal(
  voiceStateStream,
  name: r'voiceStateStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voiceStateStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VoiceStateStreamRef = AutoDisposeStreamProviderRef<VoiceState>;
String _$voiceTranscriptStreamHash() =>
    r'8f02d97268b80c98ff6c5818121c0e256302b63f';

/// See also [voiceTranscriptStream].
@ProviderFor(voiceTranscriptStream)
final voiceTranscriptStreamProvider =
    AutoDisposeStreamProvider<String>.internal(
  voiceTranscriptStream,
  name: r'voiceTranscriptStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voiceTranscriptStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VoiceTranscriptStreamRef = AutoDisposeStreamProviderRef<String>;
String _$voiceAmplitudeStreamHash() =>
    r'7ab68f3b55e17a18079af98a897f0646f1f25556';

/// See also [voiceAmplitudeStream].
@ProviderFor(voiceAmplitudeStream)
final voiceAmplitudeStreamProvider = AutoDisposeStreamProvider<double>.internal(
  voiceAmplitudeStream,
  name: r'voiceAmplitudeStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voiceAmplitudeStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VoiceAmplitudeStreamRef = AutoDisposeStreamProviderRef<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
