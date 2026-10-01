import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'voice_service.dart';
import 'voice_commands.dart';

part 'voice_providers.g.dart';

@riverpod
Stream<VoiceState> voiceStateStream(Ref ref) {
  final service = ref.watch(voiceServiceProvider);
  return service.stateStream;
}

@riverpod
Stream<String> voiceTranscriptStream(Ref ref) {
  final service = ref.watch(voiceServiceProvider);
  return service.transcriptStream;
}

@riverpod
Stream<double> voiceAmplitudeStream(Ref ref) {
  final service = ref.watch(voiceServiceProvider);
  return service.amplitudeStream;
}

// Regular StateNotifierProvider for voiceCommandLog (not auto-dispose)
final voiceCommandLogProvider = StateNotifierProvider<VoiceCommandLogNotifier, List<VoiceCommandLogEntry>>((ref) {
  return VoiceCommandLogNotifier();
});