import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio_background/just_audio_background.dart';

import 'api_service.dart';
import 'app_config.dart';

part 'voice_service.freezed.dart';
part 'voice_service.g.dart';

@riverpod
VoiceService voiceService(Ref ref) {
  return VoiceService(ref.read(apiServiceProvider));
}

class VoiceService {
  final ApiService _apiService;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FlutterSoundRecorder _flutterRecorder = FlutterSoundRecorder();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  StreamController<VoiceState>? _stateController;
  StreamController<String>? _transcriptController;
  StreamController<double>? _amplitudeController;

  AudioRecorder? _recorderInstance;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSpeaking = false;
  String _currentTranscript = '';
  Timer? _amplitudeTimer;

  VoiceService(this._apiService);

  Stream<VoiceState> get stateStream =>
      _stateController?.stream ?? const Stream.empty();
  Stream<String> get transcriptStream =>
      _transcriptController?.stream ?? const Stream.empty();
  Stream<double> get amplitudeStream =>
      _amplitudeController?.stream ?? const Stream.empty();

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isSpeaking => _isSpeaking;
  String get currentTranscript => _currentTranscript;

  Future<void> initialize() async {
    _stateController = StreamController<VoiceState>.broadcast();
    _transcriptController = StreamController<String>.broadcast();
    _amplitudeController = StreamController<double>.broadcast();

    await _recorder.open();
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse('asset:///assets/silence.mp3')),
    );
    await _flutterRecorder.openRecorder();
    await _speechToText.initialize();

    if (kIsWeb) {
      await just_audio_background.JustAudioBackground.init(
        androidNotificationChannelId: 'com.maya.voice',
        androidNotificationChannelName: 'Maya Voice',
        androidNotificationOngoing: true,
      );
    }
  }

  Future<void> startRecording({bool useSpeechToText = true}) async {
    if (_isRecording) return;

    if (useSpeechToText) {
      _startSpeechToText();
    } else {
      _startAudioRecording();
    }
  }

  void _startSpeechToText() async {
    _isRecording = true;
    _currentTranscript = '';
    _stateController?.add(VoiceState.recording);

    await _speechToText.listen(
      onResult: (result) {
        _currentTranscript = result.recognizedWords;
        _transcriptController?.add(_currentTranscript);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );

    _isRecording = true;
    _stateController?.add(VoiceState.recording);

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      _amplitudeController?.add(0.5); // Placeholder
    });
  }

  void _startAudioRecording() async {
    if (await _recorder.hasPermission()) {
      _isRecording = true;
      _stateController?.add(VoiceState.recording);

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: 'recording_${DateTime.now().millisecondsSinceEpoch}.wav',
      );

      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) async {
        final amplitude = await _recorder.getAmplitude();
        _amplitudeController?.add(amplitude.current ?? 0.0);
      });
    }
  }

  Future<File?> stopRecording({bool useSpeechToText = true}) async {
    if (!_isRecording) return null;

    if (useSpeechToText) {
      await _speechToText.stop();
      _amplitudeTimer?.cancel();
      _amplitudeTimer = null;
    } else {
      final path = await _recorder.stop();
      _amplitudeTimer?.cancel();
      _amplitudeTimer = null;

      if (path != null) {
        final file = File(path);
        return file;
      }
    }

    _isRecording = false;
    _stateController?.add(VoiceState.idle);
    return null;
  }

  Future<String?> transcribeAudio(File audioFile) async {
    try {
      final result = await _apiService.transcribeAudio(audioFile);
      _currentTranscript = result.transcript;
      _transcriptController?.add(_currentTranscript);
      return _currentTranscript;
    } catch (e) {
      debugPrint('Transcription error: $e');
      return null;
    }
  }

  Future<void> speak(String text, {String voice = 'en-US-AriaNeural'}) async {
    if (_isSpeaking) return;

    _isSpeaking = true;
    _stateController?.add(VoiceState.speaking);

    try {
      final result = await _apiService.speakText(text, voice: voice);
      if (result.success && result.audioBase64 != null) {
        final bytes = base64Decode(result.audioBase64!);
        final tempFile = File(
          '${Directory.systemTemp.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );
        await tempFile.writeAsBytes(bytes);
        await _player.setFilePath(tempFile.path);
        await _player.play();

        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _isSpeaking = false;
            _stateController?.add(VoiceState.idle);
          }
        });
      }
    } catch (e) {
      debugPrint('TTS error: $e');
      _isSpeaking = false;
      _stateController?.add(VoiceState.idle);
    }
  }

  Future<void> playAudioBytes(Uint8List bytes) async {
    if (_isSpeaking) return;

    _isSpeaking = true;
    _stateController?.add(VoiceState.speaking);

    final tempFile = File(
      '${Directory.systemTemp.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    await tempFile.writeAsBytes(bytes);
    await _player.setFilePath(tempFile.path);
    await _player.play();

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isSpeaking = false;
        _stateController?.add(VoiceState.idle);
      }
    });
  }

  Future<void> stopSpeaking() async {
    await _player.stop();
    _isSpeaking = false;
    _stateController?.add(VoiceState.idle);
  }

  Future<void> connectVoiceGateway() async {
    // Connect to voice gateway WebSocket
    // Implementation depends on backend WebSocket protocol
  }

  void dispose() {
    _stateController?.close();
    _transcriptController?.close();
    _amplitudeController?.close();
    _amplitudeTimer?.cancel();
    _recorder.close();
    _player.dispose();
    _flutterRecorder.closeRecorder();
    _speechToText.stop();
  }
}

@freezed
class VoiceState with _$VoiceState {
  const factory VoiceState.idle() = _Idle;
  const factory VoiceState.recording() = _Recording;
  const factory VoiceState.processing() = _Processing;
  const factory VoiceState.speaking() = _Speaking;
  const factory VoiceState.error(String message) = _Error;
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
