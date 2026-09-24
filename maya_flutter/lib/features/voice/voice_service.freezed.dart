// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voice_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VoiceState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() recording,
    required TResult Function() processing,
    required TResult Function() speaking,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? recording,
    TResult? Function()? processing,
    TResult? Function()? speaking,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? recording,
    TResult Function()? processing,
    TResult Function()? speaking,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Recording value) recording,
    required TResult Function(_Processing value) processing,
    required TResult Function(_Speaking value) speaking,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Recording value)? recording,
    TResult? Function(_Processing value)? processing,
    TResult? Function(_Speaking value)? speaking,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Recording value)? recording,
    TResult Function(_Processing value)? processing,
    TResult Function(_Speaking value)? speaking,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoiceStateCopyWith<$Res> {
  factory $VoiceStateCopyWith(
          VoiceState value, $Res Function(VoiceState) then) =
      _$VoiceStateCopyWithImpl<$Res, VoiceState>;
}

/// @nodoc
class _$VoiceStateCopyWithImpl<$Res, $Val extends VoiceState>
    implements $VoiceStateCopyWith<$Res> {
  _$VoiceStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$IdleImplCopyWith<$Res> {
  factory _$$IdleImplCopyWith(
          _$IdleImpl value, $Res Function(_$IdleImpl) then) =
      __$$IdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$IdleImplCopyWithImpl<$Res>
    extends _$VoiceStateCopyWithImpl<$Res, _$IdleImpl>
    implements _$$IdleImplCopyWith<$Res> {
  __$$IdleImplCopyWithImpl(_$IdleImpl _value, $Res Function(_$IdleImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$IdleImpl with DiagnosticableTreeMixin implements _Idle {
  const _$IdleImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'VoiceState.idle()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('type', 'VoiceState.idle'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$IdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() recording,
    required TResult Function() processing,
    required TResult Function() speaking,
    required TResult Function(String message) error,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? recording,
    TResult? Function()? processing,
    TResult? Function()? speaking,
    TResult? Function(String message)? error,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? recording,
    TResult Function()? processing,
    TResult Function()? speaking,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Recording value) recording,
    required TResult Function(_Processing value) processing,
    required TResult Function(_Speaking value) speaking,
    required TResult Function(_Error value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Recording value)? recording,
    TResult? Function(_Processing value)? processing,
    TResult? Function(_Speaking value)? speaking,
    TResult? Function(_Error value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Recording value)? recording,
    TResult Function(_Processing value)? processing,
    TResult Function(_Speaking value)? speaking,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class _Idle implements VoiceState {
  const factory _Idle() = _$IdleImpl;
}

/// @nodoc
abstract class _$$RecordingImplCopyWith<$Res> {
  factory _$$RecordingImplCopyWith(
          _$RecordingImpl value, $Res Function(_$RecordingImpl) then) =
      __$$RecordingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RecordingImplCopyWithImpl<$Res>
    extends _$VoiceStateCopyWithImpl<$Res, _$RecordingImpl>
    implements _$$RecordingImplCopyWith<$Res> {
  __$$RecordingImplCopyWithImpl(
      _$RecordingImpl _value, $Res Function(_$RecordingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RecordingImpl with DiagnosticableTreeMixin implements _Recording {
  const _$RecordingImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'VoiceState.recording()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('type', 'VoiceState.recording'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RecordingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() recording,
    required TResult Function() processing,
    required TResult Function() speaking,
    required TResult Function(String message) error,
  }) {
    return recording();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? recording,
    TResult? Function()? processing,
    TResult? Function()? speaking,
    TResult? Function(String message)? error,
  }) {
    return recording?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? recording,
    TResult Function()? processing,
    TResult Function()? speaking,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (recording != null) {
      return recording();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Recording value) recording,
    required TResult Function(_Processing value) processing,
    required TResult Function(_Speaking value) speaking,
    required TResult Function(_Error value) error,
  }) {
    return recording(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Recording value)? recording,
    TResult? Function(_Processing value)? processing,
    TResult? Function(_Speaking value)? speaking,
    TResult? Function(_Error value)? error,
  }) {
    return recording?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Recording value)? recording,
    TResult Function(_Processing value)? processing,
    TResult Function(_Speaking value)? speaking,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (recording != null) {
      return recording(this);
    }
    return orElse();
  }
}

abstract class _Recording implements VoiceState {
  const factory _Recording() = _$RecordingImpl;
}

/// @nodoc
abstract class _$$ProcessingImplCopyWith<$Res> {
  factory _$$ProcessingImplCopyWith(
          _$ProcessingImpl value, $Res Function(_$ProcessingImpl) then) =
      __$$ProcessingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ProcessingImplCopyWithImpl<$Res>
    extends _$VoiceStateCopyWithImpl<$Res, _$ProcessingImpl>
    implements _$$ProcessingImplCopyWith<$Res> {
  __$$ProcessingImplCopyWithImpl(
      _$ProcessingImpl _value, $Res Function(_$ProcessingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$ProcessingImpl with DiagnosticableTreeMixin implements _Processing {
  const _$ProcessingImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'VoiceState.processing()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('type', 'VoiceState.processing'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ProcessingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() recording,
    required TResult Function() processing,
    required TResult Function() speaking,
    required TResult Function(String message) error,
  }) {
    return processing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? recording,
    TResult? Function()? processing,
    TResult? Function()? speaking,
    TResult? Function(String message)? error,
  }) {
    return processing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? recording,
    TResult Function()? processing,
    TResult Function()? speaking,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (processing != null) {
      return processing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Recording value) recording,
    required TResult Function(_Processing value) processing,
    required TResult Function(_Speaking value) speaking,
    required TResult Function(_Error value) error,
  }) {
    return processing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Recording value)? recording,
    TResult? Function(_Processing value)? processing,
    TResult? Function(_Speaking value)? speaking,
    TResult? Function(_Error value)? error,
  }) {
    return processing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Recording value)? recording,
    TResult Function(_Processing value)? processing,
    TResult Function(_Speaking value)? speaking,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (processing != null) {
      return processing(this);
    }
    return orElse();
  }
}

abstract class _Processing implements VoiceState {
  const factory _Processing() = _$ProcessingImpl;
}

/// @nodoc
abstract class _$$SpeakingImplCopyWith<$Res> {
  factory _$$SpeakingImplCopyWith(
          _$SpeakingImpl value, $Res Function(_$SpeakingImpl) then) =
      __$$SpeakingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SpeakingImplCopyWithImpl<$Res>
    extends _$VoiceStateCopyWithImpl<$Res, _$SpeakingImpl>
    implements _$$SpeakingImplCopyWith<$Res> {
  __$$SpeakingImplCopyWithImpl(
      _$SpeakingImpl _value, $Res Function(_$SpeakingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SpeakingImpl with DiagnosticableTreeMixin implements _Speaking {
  const _$SpeakingImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'VoiceState.speaking()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('type', 'VoiceState.speaking'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SpeakingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() recording,
    required TResult Function() processing,
    required TResult Function() speaking,
    required TResult Function(String message) error,
  }) {
    return speaking();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? recording,
    TResult? Function()? processing,
    TResult? Function()? speaking,
    TResult? Function(String message)? error,
  }) {
    return speaking?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? recording,
    TResult Function()? processing,
    TResult Function()? speaking,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (speaking != null) {
      return speaking();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Recording value) recording,
    required TResult Function(_Processing value) processing,
    required TResult Function(_Speaking value) speaking,
    required TResult Function(_Error value) error,
  }) {
    return speaking(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Recording value)? recording,
    TResult? Function(_Processing value)? processing,
    TResult? Function(_Speaking value)? speaking,
    TResult? Function(_Error value)? error,
  }) {
    return speaking?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Recording value)? recording,
    TResult Function(_Processing value)? processing,
    TResult Function(_Speaking value)? speaking,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (speaking != null) {
      return speaking(this);
    }
    return orElse();
  }
}

abstract class _Speaking implements VoiceState {
  const factory _Speaking() = _$SpeakingImpl;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$VoiceStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ErrorImpl with DiagnosticableTreeMixin implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'VoiceState.error(message: $message)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'VoiceState.error'))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() recording,
    required TResult Function() processing,
    required TResult Function() speaking,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? recording,
    TResult? Function()? processing,
    TResult? Function()? speaking,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? recording,
    TResult Function()? processing,
    TResult Function()? speaking,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Recording value) recording,
    required TResult Function(_Processing value) processing,
    required TResult Function(_Speaking value) speaking,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Recording value)? recording,
    TResult? Function(_Processing value)? processing,
    TResult? Function(_Speaking value)? speaking,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Recording value)? recording,
    TResult Function(_Processing value)? processing,
    TResult Function(_Speaking value)? speaking,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements VoiceState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;
  @JsonKey(ignore: true)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TtsResult _$TtsResultFromJson(Map<String, dynamic> json) {
  return _TtsResult.fromJson(json);
}

/// @nodoc
mixin _$TtsResult {
  bool get success => throw _privateConstructorUsedError;
  String? get audioBase64 => throw _privateConstructorUsedError;
  String? get format => throw _privateConstructorUsedError;
  String? get provider => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TtsResultCopyWith<TtsResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TtsResultCopyWith<$Res> {
  factory $TtsResultCopyWith(TtsResult value, $Res Function(TtsResult) then) =
      _$TtsResultCopyWithImpl<$Res, TtsResult>;
  @useResult
  $Res call(
      {bool success,
      String? audioBase64,
      String? format,
      String? provider,
      String? error});
}

/// @nodoc
class _$TtsResultCopyWithImpl<$Res, $Val extends TtsResult>
    implements $TtsResultCopyWith<$Res> {
  _$TtsResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? audioBase64 = freezed,
    Object? format = freezed,
    Object? provider = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      audioBase64: freezed == audioBase64
          ? _value.audioBase64
          : audioBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      format: freezed == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String?,
      provider: freezed == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TtsResultImplCopyWith<$Res>
    implements $TtsResultCopyWith<$Res> {
  factory _$$TtsResultImplCopyWith(
          _$TtsResultImpl value, $Res Function(_$TtsResultImpl) then) =
      __$$TtsResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      String? audioBase64,
      String? format,
      String? provider,
      String? error});
}

/// @nodoc
class __$$TtsResultImplCopyWithImpl<$Res>
    extends _$TtsResultCopyWithImpl<$Res, _$TtsResultImpl>
    implements _$$TtsResultImplCopyWith<$Res> {
  __$$TtsResultImplCopyWithImpl(
      _$TtsResultImpl _value, $Res Function(_$TtsResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? audioBase64 = freezed,
    Object? format = freezed,
    Object? provider = freezed,
    Object? error = freezed,
  }) {
    return _then(_$TtsResultImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      audioBase64: freezed == audioBase64
          ? _value.audioBase64
          : audioBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      format: freezed == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String?,
      provider: freezed == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TtsResultImpl with DiagnosticableTreeMixin implements _TtsResult {
  const _$TtsResultImpl(
      {required this.success,
      this.audioBase64,
      this.format,
      this.provider,
      this.error});

  factory _$TtsResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TtsResultImplFromJson(json);

  @override
  final bool success;
  @override
  final String? audioBase64;
  @override
  final String? format;
  @override
  final String? provider;
  @override
  final String? error;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TtsResult(success: $success, audioBase64: $audioBase64, format: $format, provider: $provider, error: $error)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'TtsResult'))
      ..add(DiagnosticsProperty('success', success))
      ..add(DiagnosticsProperty('audioBase64', audioBase64))
      ..add(DiagnosticsProperty('format', format))
      ..add(DiagnosticsProperty('provider', provider))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TtsResultImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.audioBase64, audioBase64) ||
                other.audioBase64 == audioBase64) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, success, audioBase64, format, provider, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TtsResultImplCopyWith<_$TtsResultImpl> get copyWith =>
      __$$TtsResultImplCopyWithImpl<_$TtsResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TtsResultImplToJson(
      this,
    );
  }
}

abstract class _TtsResult implements TtsResult {
  const factory _TtsResult(
      {required final bool success,
      final String? audioBase64,
      final String? format,
      final String? provider,
      final String? error}) = _$TtsResultImpl;

  factory _TtsResult.fromJson(Map<String, dynamic> json) =
      _$TtsResultImpl.fromJson;

  @override
  bool get success;
  @override
  String? get audioBase64;
  @override
  String? get format;
  @override
  String? get provider;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$TtsResultImplCopyWith<_$TtsResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
