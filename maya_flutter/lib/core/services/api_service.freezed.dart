// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HealthCheckResult _$HealthCheckResultFromJson(Map<String, dynamic> json) {
  return _HealthCheckResult.fromJson(json);
}

/// @nodoc
mixin _$HealthCheckResult {
  bool get live => throw _privateConstructorUsedError;
  bool get ready => throw _privateConstructorUsedError;
  String get system => throw _privateConstructorUsedError;
  int get latency => throw _privateConstructorUsedError;
  DateTime get lastCheck => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HealthCheckResultCopyWith<HealthCheckResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthCheckResultCopyWith<$Res> {
  factory $HealthCheckResultCopyWith(
          HealthCheckResult value, $Res Function(HealthCheckResult) then) =
      _$HealthCheckResultCopyWithImpl<$Res, HealthCheckResult>;
  @useResult
  $Res call(
      {bool live,
      bool ready,
      String system,
      int latency,
      DateTime lastCheck,
      String? error});
}

/// @nodoc
class _$HealthCheckResultCopyWithImpl<$Res, $Val extends HealthCheckResult>
    implements $HealthCheckResultCopyWith<$Res> {
  _$HealthCheckResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? live = null,
    Object? ready = null,
    Object? system = null,
    Object? latency = null,
    Object? lastCheck = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      live: null == live
          ? _value.live
          : live // ignore: cast_nullable_to_non_nullable
              as bool,
      ready: null == ready
          ? _value.ready
          : ready // ignore: cast_nullable_to_non_nullable
              as bool,
      system: null == system
          ? _value.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      latency: null == latency
          ? _value.latency
          : latency // ignore: cast_nullable_to_non_nullable
              as int,
      lastCheck: null == lastCheck
          ? _value.lastCheck
          : lastCheck // ignore: cast_nullable_to_non_nullable
              as DateTime,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthCheckResultImplCopyWith<$Res>
    implements $HealthCheckResultCopyWith<$Res> {
  factory _$$HealthCheckResultImplCopyWith(_$HealthCheckResultImpl value,
          $Res Function(_$HealthCheckResultImpl) then) =
      __$$HealthCheckResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool live,
      bool ready,
      String system,
      int latency,
      DateTime lastCheck,
      String? error});
}

/// @nodoc
class __$$HealthCheckResultImplCopyWithImpl<$Res>
    extends _$HealthCheckResultCopyWithImpl<$Res, _$HealthCheckResultImpl>
    implements _$$HealthCheckResultImplCopyWith<$Res> {
  __$$HealthCheckResultImplCopyWithImpl(_$HealthCheckResultImpl _value,
      $Res Function(_$HealthCheckResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? live = null,
    Object? ready = null,
    Object? system = null,
    Object? latency = null,
    Object? lastCheck = null,
    Object? error = freezed,
  }) {
    return _then(_$HealthCheckResultImpl(
      live: null == live
          ? _value.live
          : live // ignore: cast_nullable_to_non_nullable
              as bool,
      ready: null == ready
          ? _value.ready
          : ready // ignore: cast_nullable_to_non_nullable
              as bool,
      system: null == system
          ? _value.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      latency: null == latency
          ? _value.latency
          : latency // ignore: cast_nullable_to_non_nullable
              as int,
      lastCheck: null == lastCheck
          ? _value.lastCheck
          : lastCheck // ignore: cast_nullable_to_non_nullable
              as DateTime,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthCheckResultImpl implements _HealthCheckResult {
  const _$HealthCheckResultImpl(
      {required this.live,
      required this.ready,
      required this.system,
      required this.latency,
      required this.lastCheck,
      this.error});

  factory _$HealthCheckResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthCheckResultImplFromJson(json);

  @override
  final bool live;
  @override
  final bool ready;
  @override
  final String system;
  @override
  final int latency;
  @override
  final DateTime lastCheck;
  @override
  final String? error;

  @override
  String toString() {
    return 'HealthCheckResult(live: $live, ready: $ready, system: $system, latency: $latency, lastCheck: $lastCheck, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthCheckResultImpl &&
            (identical(other.live, live) || other.live == live) &&
            (identical(other.ready, ready) || other.ready == ready) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.latency, latency) || other.latency == latency) &&
            (identical(other.lastCheck, lastCheck) ||
                other.lastCheck == lastCheck) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, live, ready, system, latency, lastCheck, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthCheckResultImplCopyWith<_$HealthCheckResultImpl> get copyWith =>
      __$$HealthCheckResultImplCopyWithImpl<_$HealthCheckResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthCheckResultImplToJson(
      this,
    );
  }
}

abstract class _HealthCheckResult implements HealthCheckResult {
  const factory _HealthCheckResult(
      {required final bool live,
      required final bool ready,
      required final String system,
      required final int latency,
      required final DateTime lastCheck,
      final String? error}) = _$HealthCheckResultImpl;

  factory _HealthCheckResult.fromJson(Map<String, dynamic> json) =
      _$HealthCheckResultImpl.fromJson;

  @override
  bool get live;
  @override
  bool get ready;
  @override
  String get system;
  @override
  int get latency;
  @override
  DateTime get lastCheck;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$HealthCheckResultImplCopyWith<_$HealthCheckResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) {
  return _AuthResponse.fromJson(json);
}

/// @nodoc
mixin _$AuthResponse {
  String get accessToken => throw _privateConstructorUsedError;
  String get refreshToken => throw _privateConstructorUsedError;
  UserProfile get user => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AuthResponseCopyWith<AuthResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResponseCopyWith<$Res> {
  factory $AuthResponseCopyWith(
          AuthResponse value, $Res Function(AuthResponse) then) =
      _$AuthResponseCopyWithImpl<$Res, AuthResponse>;
  @useResult
  $Res call({String accessToken, String refreshToken, UserProfile user});

  $UserProfileCopyWith<$Res> get user;
}

/// @nodoc
class _$AuthResponseCopyWithImpl<$Res, $Val extends AuthResponse>
    implements $AuthResponseCopyWith<$Res> {
  _$AuthResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? user = null,
  }) {
    return _then(_value.copyWith(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserProfile,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res> get user {
    return $UserProfileCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthResponseImplCopyWith<$Res>
    implements $AuthResponseCopyWith<$Res> {
  factory _$$AuthResponseImplCopyWith(
          _$AuthResponseImpl value, $Res Function(_$AuthResponseImpl) then) =
      __$$AuthResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String accessToken, String refreshToken, UserProfile user});

  @override
  $UserProfileCopyWith<$Res> get user;
}

/// @nodoc
class __$$AuthResponseImplCopyWithImpl<$Res>
    extends _$AuthResponseCopyWithImpl<$Res, _$AuthResponseImpl>
    implements _$$AuthResponseImplCopyWith<$Res> {
  __$$AuthResponseImplCopyWithImpl(
      _$AuthResponseImpl _value, $Res Function(_$AuthResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? user = null,
  }) {
    return _then(_$AuthResponseImpl(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserProfile,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthResponseImpl implements _AuthResponse {
  const _$AuthResponseImpl(
      {required this.accessToken,
      required this.refreshToken,
      required this.user});

  factory _$AuthResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthResponseImplFromJson(json);

  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final UserProfile user;

  @override
  String toString() {
    return 'AuthResponse(accessToken: $accessToken, refreshToken: $refreshToken, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResponseImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, accessToken, refreshToken, user);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      __$$AuthResponseImplCopyWithImpl<_$AuthResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthResponseImplToJson(
      this,
    );
  }
}

abstract class _AuthResponse implements AuthResponse {
  const factory _AuthResponse(
      {required final String accessToken,
      required final String refreshToken,
      required final UserProfile user}) = _$AuthResponseImpl;

  factory _AuthResponse.fromJson(Map<String, dynamic> json) =
      _$AuthResponseImpl.fromJson;

  @override
  String get accessToken;
  @override
  String get refreshToken;
  @override
  UserProfile get user;
  @override
  @JsonKey(ignore: true)
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  String? get role => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {String id, String email, String name, String? avatar, String? role});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? name = null,
    Object? avatar = freezed,
    Object? role = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String email, String name, String? avatar, String? role});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? name = null,
    Object? avatar = freezed,
    Object? role = freezed,
  }) {
    return _then(_$UserProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {required this.id,
      required this.email,
      required this.name,
      this.avatar,
      this.role});

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  final String name;
  @override
  final String? avatar;
  @override
  final String? role;

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, name: $name, avatar: $avatar, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.role, role) || other.role == role));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, name, avatar, role);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {required final String id,
      required final String email,
      required final String name,
      final String? avatar,
      final String? role}) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  String get name;
  @override
  String? get avatar;
  @override
  String? get role;
  @override
  @JsonKey(ignore: true)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TranscriptionResult _$TranscriptionResultFromJson(Map<String, dynamic> json) {
  return _TranscriptionResult.fromJson(json);
}

/// @nodoc
mixin _$TranscriptionResult {
  String get transcript => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  double get languageProbability => throw _privateConstructorUsedError;
  double get duration => throw _privateConstructorUsedError;
  List<TranscriptionSegment>? get segments =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TranscriptionResultCopyWith<TranscriptionResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptionResultCopyWith<$Res> {
  factory $TranscriptionResultCopyWith(
          TranscriptionResult value, $Res Function(TranscriptionResult) then) =
      _$TranscriptionResultCopyWithImpl<$Res, TranscriptionResult>;
  @useResult
  $Res call(
      {String transcript,
      String language,
      double languageProbability,
      double duration,
      List<TranscriptionSegment>? segments});
}

/// @nodoc
class _$TranscriptionResultCopyWithImpl<$Res, $Val extends TranscriptionResult>
    implements $TranscriptionResultCopyWith<$Res> {
  _$TranscriptionResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transcript = null,
    Object? language = null,
    Object? languageProbability = null,
    Object? duration = null,
    Object? segments = freezed,
  }) {
    return _then(_value.copyWith(
      transcript: null == transcript
          ? _value.transcript
          : transcript // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      languageProbability: null == languageProbability
          ? _value.languageProbability
          : languageProbability // ignore: cast_nullable_to_non_nullable
              as double,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as double,
      segments: freezed == segments
          ? _value.segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<TranscriptionSegment>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TranscriptionResultImplCopyWith<$Res>
    implements $TranscriptionResultCopyWith<$Res> {
  factory _$$TranscriptionResultImplCopyWith(_$TranscriptionResultImpl value,
          $Res Function(_$TranscriptionResultImpl) then) =
      __$$TranscriptionResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String transcript,
      String language,
      double languageProbability,
      double duration,
      List<TranscriptionSegment>? segments});
}

/// @nodoc
class __$$TranscriptionResultImplCopyWithImpl<$Res>
    extends _$TranscriptionResultCopyWithImpl<$Res, _$TranscriptionResultImpl>
    implements _$$TranscriptionResultImplCopyWith<$Res> {
  __$$TranscriptionResultImplCopyWithImpl(_$TranscriptionResultImpl _value,
      $Res Function(_$TranscriptionResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transcript = null,
    Object? language = null,
    Object? languageProbability = null,
    Object? duration = null,
    Object? segments = freezed,
  }) {
    return _then(_$TranscriptionResultImpl(
      transcript: null == transcript
          ? _value.transcript
          : transcript // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      languageProbability: null == languageProbability
          ? _value.languageProbability
          : languageProbability // ignore: cast_nullable_to_non_nullable
              as double,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as double,
      segments: freezed == segments
          ? _value._segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<TranscriptionSegment>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptionResultImpl implements _TranscriptionResult {
  const _$TranscriptionResultImpl(
      {required this.transcript,
      required this.language,
      required this.languageProbability,
      required this.duration,
      final List<TranscriptionSegment>? segments})
      : _segments = segments;

  factory _$TranscriptionResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptionResultImplFromJson(json);

  @override
  final String transcript;
  @override
  final String language;
  @override
  final double languageProbability;
  @override
  final double duration;
  final List<TranscriptionSegment>? _segments;
  @override
  List<TranscriptionSegment>? get segments {
    final value = _segments;
    if (value == null) return null;
    if (_segments is EqualUnmodifiableListView) return _segments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'TranscriptionResult(transcript: $transcript, language: $language, languageProbability: $languageProbability, duration: $duration, segments: $segments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptionResultImpl &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.languageProbability, languageProbability) ||
                other.languageProbability == languageProbability) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            const DeepCollectionEquality().equals(other._segments, _segments));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      transcript,
      language,
      languageProbability,
      duration,
      const DeepCollectionEquality().hash(_segments));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptionResultImplCopyWith<_$TranscriptionResultImpl> get copyWith =>
      __$$TranscriptionResultImplCopyWithImpl<_$TranscriptionResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptionResultImplToJson(
      this,
    );
  }
}

abstract class _TranscriptionResult implements TranscriptionResult {
  const factory _TranscriptionResult(
      {required final String transcript,
      required final String language,
      required final double languageProbability,
      required final double duration,
      final List<TranscriptionSegment>? segments}) = _$TranscriptionResultImpl;

  factory _TranscriptionResult.fromJson(Map<String, dynamic> json) =
      _$TranscriptionResultImpl.fromJson;

  @override
  String get transcript;
  @override
  String get language;
  @override
  double get languageProbability;
  @override
  double get duration;
  @override
  List<TranscriptionSegment>? get segments;
  @override
  @JsonKey(ignore: true)
  _$$TranscriptionResultImplCopyWith<_$TranscriptionResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TranscriptionSegment _$TranscriptionSegmentFromJson(Map<String, dynamic> json) {
  return _TranscriptionSegment.fromJson(json);
}

/// @nodoc
mixin _$TranscriptionSegment {
  double get start => throw _privateConstructorUsedError;
  double get end => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  double? get avgLogprob => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TranscriptionSegmentCopyWith<TranscriptionSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptionSegmentCopyWith<$Res> {
  factory $TranscriptionSegmentCopyWith(TranscriptionSegment value,
          $Res Function(TranscriptionSegment) then) =
      _$TranscriptionSegmentCopyWithImpl<$Res, TranscriptionSegment>;
  @useResult
  $Res call({double start, double end, String text, double? avgLogprob});
}

/// @nodoc
class _$TranscriptionSegmentCopyWithImpl<$Res,
        $Val extends TranscriptionSegment>
    implements $TranscriptionSegmentCopyWith<$Res> {
  _$TranscriptionSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
    Object? text = null,
    Object? avgLogprob = freezed,
  }) {
    return _then(_value.copyWith(
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as double,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as double,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      avgLogprob: freezed == avgLogprob
          ? _value.avgLogprob
          : avgLogprob // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TranscriptionSegmentImplCopyWith<$Res>
    implements $TranscriptionSegmentCopyWith<$Res> {
  factory _$$TranscriptionSegmentImplCopyWith(_$TranscriptionSegmentImpl value,
          $Res Function(_$TranscriptionSegmentImpl) then) =
      __$$TranscriptionSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double start, double end, String text, double? avgLogprob});
}

/// @nodoc
class __$$TranscriptionSegmentImplCopyWithImpl<$Res>
    extends _$TranscriptionSegmentCopyWithImpl<$Res, _$TranscriptionSegmentImpl>
    implements _$$TranscriptionSegmentImplCopyWith<$Res> {
  __$$TranscriptionSegmentImplCopyWithImpl(_$TranscriptionSegmentImpl _value,
      $Res Function(_$TranscriptionSegmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
    Object? text = null,
    Object? avgLogprob = freezed,
  }) {
    return _then(_$TranscriptionSegmentImpl(
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as double,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as double,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      avgLogprob: freezed == avgLogprob
          ? _value.avgLogprob
          : avgLogprob // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptionSegmentImpl implements _TranscriptionSegment {
  const _$TranscriptionSegmentImpl(
      {required this.start,
      required this.end,
      required this.text,
      this.avgLogprob});

  factory _$TranscriptionSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptionSegmentImplFromJson(json);

  @override
  final double start;
  @override
  final double end;
  @override
  final String text;
  @override
  final double? avgLogprob;

  @override
  String toString() {
    return 'TranscriptionSegment(start: $start, end: $end, text: $text, avgLogprob: $avgLogprob)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptionSegmentImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.avgLogprob, avgLogprob) ||
                other.avgLogprob == avgLogprob));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, start, end, text, avgLogprob);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptionSegmentImplCopyWith<_$TranscriptionSegmentImpl>
      get copyWith =>
          __$$TranscriptionSegmentImplCopyWithImpl<_$TranscriptionSegmentImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptionSegmentImplToJson(
      this,
    );
  }
}

abstract class _TranscriptionSegment implements TranscriptionSegment {
  const factory _TranscriptionSegment(
      {required final double start,
      required final double end,
      required final String text,
      final double? avgLogprob}) = _$TranscriptionSegmentImpl;

  factory _TranscriptionSegment.fromJson(Map<String, dynamic> json) =
      _$TranscriptionSegmentImpl.fromJson;

  @override
  double get start;
  @override
  double get end;
  @override
  String get text;
  @override
  double? get avgLogprob;
  @override
  @JsonKey(ignore: true)
  _$$TranscriptionSegmentImplCopyWith<_$TranscriptionSegmentImpl>
      get copyWith => throw _privateConstructorUsedError;
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
class _$TtsResultImpl implements _TtsResult {
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
  String toString() {
    return 'TtsResult(success: $success, audioBase64: $audioBase64, format: $format, provider: $provider, error: $error)';
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

AgentChatResponse _$AgentChatResponseFromJson(Map<String, dynamic> json) {
  return _AgentChatResponse.fromJson(json);
}

/// @nodoc
mixin _$AgentChatResponse {
  String get reply => throw _privateConstructorUsedError;
  String get timestamp => throw _privateConstructorUsedError;
  String? get taskId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentChatResponseCopyWith<AgentChatResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentChatResponseCopyWith<$Res> {
  factory $AgentChatResponseCopyWith(
          AgentChatResponse value, $Res Function(AgentChatResponse) then) =
      _$AgentChatResponseCopyWithImpl<$Res, AgentChatResponse>;
  @useResult
  $Res call({String reply, String timestamp, String? taskId});
}

/// @nodoc
class _$AgentChatResponseCopyWithImpl<$Res, $Val extends AgentChatResponse>
    implements $AgentChatResponseCopyWith<$Res> {
  _$AgentChatResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reply = null,
    Object? timestamp = null,
    Object? taskId = freezed,
  }) {
    return _then(_value.copyWith(
      reply: null == reply
          ? _value.reply
          : reply // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: freezed == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentChatResponseImplCopyWith<$Res>
    implements $AgentChatResponseCopyWith<$Res> {
  factory _$$AgentChatResponseImplCopyWith(_$AgentChatResponseImpl value,
          $Res Function(_$AgentChatResponseImpl) then) =
      __$$AgentChatResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reply, String timestamp, String? taskId});
}

/// @nodoc
class __$$AgentChatResponseImplCopyWithImpl<$Res>
    extends _$AgentChatResponseCopyWithImpl<$Res, _$AgentChatResponseImpl>
    implements _$$AgentChatResponseImplCopyWith<$Res> {
  __$$AgentChatResponseImplCopyWithImpl(_$AgentChatResponseImpl _value,
      $Res Function(_$AgentChatResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reply = null,
    Object? timestamp = null,
    Object? taskId = freezed,
  }) {
    return _then(_$AgentChatResponseImpl(
      reply: null == reply
          ? _value.reply
          : reply // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: freezed == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentChatResponseImpl implements _AgentChatResponse {
  const _$AgentChatResponseImpl(
      {required this.reply, required this.timestamp, this.taskId});

  factory _$AgentChatResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentChatResponseImplFromJson(json);

  @override
  final String reply;
  @override
  final String timestamp;
  @override
  final String? taskId;

  @override
  String toString() {
    return 'AgentChatResponse(reply: $reply, timestamp: $timestamp, taskId: $taskId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentChatResponseImpl &&
            (identical(other.reply, reply) || other.reply == reply) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.taskId, taskId) || other.taskId == taskId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, reply, timestamp, taskId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentChatResponseImplCopyWith<_$AgentChatResponseImpl> get copyWith =>
      __$$AgentChatResponseImplCopyWithImpl<_$AgentChatResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentChatResponseImplToJson(
      this,
    );
  }
}

abstract class _AgentChatResponse implements AgentChatResponse {
  const factory _AgentChatResponse(
      {required final String reply,
      required final String timestamp,
      final String? taskId}) = _$AgentChatResponseImpl;

  factory _AgentChatResponse.fromJson(Map<String, dynamic> json) =
      _$AgentChatResponseImpl.fromJson;

  @override
  String get reply;
  @override
  String get timestamp;
  @override
  String? get taskId;
  @override
  @JsonKey(ignore: true)
  _$$AgentChatResponseImplCopyWith<_$AgentChatResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChatStreamChunk {
  String? get delta => throw _privateConstructorUsedError;
  bool? get done => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChatStreamChunkCopyWith<ChatStreamChunk> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStreamChunkCopyWith<$Res> {
  factory $ChatStreamChunkCopyWith(
          ChatStreamChunk value, $Res Function(ChatStreamChunk) then) =
      _$ChatStreamChunkCopyWithImpl<$Res, ChatStreamChunk>;
  @useResult
  $Res call({String? delta, bool? done, String? error});
}

/// @nodoc
class _$ChatStreamChunkCopyWithImpl<$Res, $Val extends ChatStreamChunk>
    implements $ChatStreamChunkCopyWith<$Res> {
  _$ChatStreamChunkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? delta = freezed,
    Object? done = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      delta: freezed == delta
          ? _value.delta
          : delta // ignore: cast_nullable_to_non_nullable
              as String?,
      done: freezed == done
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatStreamChunkImplCopyWith<$Res>
    implements $ChatStreamChunkCopyWith<$Res> {
  factory _$$ChatStreamChunkImplCopyWith(_$ChatStreamChunkImpl value,
          $Res Function(_$ChatStreamChunkImpl) then) =
      __$$ChatStreamChunkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? delta, bool? done, String? error});
}

/// @nodoc
class __$$ChatStreamChunkImplCopyWithImpl<$Res>
    extends _$ChatStreamChunkCopyWithImpl<$Res, _$ChatStreamChunkImpl>
    implements _$$ChatStreamChunkImplCopyWith<$Res> {
  __$$ChatStreamChunkImplCopyWithImpl(
      _$ChatStreamChunkImpl _value, $Res Function(_$ChatStreamChunkImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? delta = freezed,
    Object? done = freezed,
    Object? error = freezed,
  }) {
    return _then(_$ChatStreamChunkImpl(
      delta: freezed == delta
          ? _value.delta
          : delta // ignore: cast_nullable_to_non_nullable
              as String?,
      done: freezed == done
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ChatStreamChunkImpl implements _ChatStreamChunk {
  const _$ChatStreamChunkImpl({this.delta, this.done, this.error});

  @override
  final String? delta;
  @override
  final bool? done;
  @override
  final String? error;

  @override
  String toString() {
    return 'ChatStreamChunk(delta: $delta, done: $done, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatStreamChunkImpl &&
            (identical(other.delta, delta) || other.delta == delta) &&
            (identical(other.done, done) || other.done == done) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, delta, done, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatStreamChunkImplCopyWith<_$ChatStreamChunkImpl> get copyWith =>
      __$$ChatStreamChunkImplCopyWithImpl<_$ChatStreamChunkImpl>(
          this, _$identity);
}

abstract class _ChatStreamChunk implements ChatStreamChunk {
  const factory _ChatStreamChunk(
      {final String? delta,
      final bool? done,
      final String? error}) = _$ChatStreamChunkImpl;

  @override
  String? get delta;
  @override
  bool? get done;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$ChatStreamChunkImplCopyWith<_$ChatStreamChunkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AgentRunResponse _$AgentRunResponseFromJson(Map<String, dynamic> json) {
  return _AgentRunResponse.fromJson(json);
}

/// @nodoc
mixin _$AgentRunResponse {
  String get taskId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get result => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentRunResponseCopyWith<AgentRunResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentRunResponseCopyWith<$Res> {
  factory $AgentRunResponseCopyWith(
          AgentRunResponse value, $Res Function(AgentRunResponse) then) =
      _$AgentRunResponseCopyWithImpl<$Res, AgentRunResponse>;
  @useResult
  $Res call({String taskId, String status, String? result, String? error});
}

/// @nodoc
class _$AgentRunResponseCopyWithImpl<$Res, $Val extends AgentRunResponse>
    implements $AgentRunResponseCopyWith<$Res> {
  _$AgentRunResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? status = null,
    Object? result = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentRunResponseImplCopyWith<$Res>
    implements $AgentRunResponseCopyWith<$Res> {
  factory _$$AgentRunResponseImplCopyWith(_$AgentRunResponseImpl value,
          $Res Function(_$AgentRunResponseImpl) then) =
      __$$AgentRunResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String taskId, String status, String? result, String? error});
}

/// @nodoc
class __$$AgentRunResponseImplCopyWithImpl<$Res>
    extends _$AgentRunResponseCopyWithImpl<$Res, _$AgentRunResponseImpl>
    implements _$$AgentRunResponseImplCopyWith<$Res> {
  __$$AgentRunResponseImplCopyWithImpl(_$AgentRunResponseImpl _value,
      $Res Function(_$AgentRunResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? status = null,
    Object? result = freezed,
    Object? error = freezed,
  }) {
    return _then(_$AgentRunResponseImpl(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
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
class _$AgentRunResponseImpl implements _AgentRunResponse {
  const _$AgentRunResponseImpl(
      {required this.taskId, required this.status, this.result, this.error});

  factory _$AgentRunResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentRunResponseImplFromJson(json);

  @override
  final String taskId;
  @override
  final String status;
  @override
  final String? result;
  @override
  final String? error;

  @override
  String toString() {
    return 'AgentRunResponse(taskId: $taskId, status: $status, result: $result, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentRunResponseImpl &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, taskId, status, result, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentRunResponseImplCopyWith<_$AgentRunResponseImpl> get copyWith =>
      __$$AgentRunResponseImplCopyWithImpl<_$AgentRunResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentRunResponseImplToJson(
      this,
    );
  }
}

abstract class _AgentRunResponse implements AgentRunResponse {
  const factory _AgentRunResponse(
      {required final String taskId,
      required final String status,
      final String? result,
      final String? error}) = _$AgentRunResponseImpl;

  factory _AgentRunResponse.fromJson(Map<String, dynamic> json) =
      _$AgentRunResponseImpl.fromJson;

  @override
  String get taskId;
  @override
  String get status;
  @override
  String? get result;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$AgentRunResponseImplCopyWith<_$AgentRunResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AgentThinkResponse _$AgentThinkResponseFromJson(Map<String, dynamic> json) {
  return _AgentThinkResponse.fromJson(json);
}

/// @nodoc
mixin _$AgentThinkResponse {
  String get analysis => throw _privateConstructorUsedError;
  String? get plan => throw _privateConstructorUsedError;
  List<String>? get steps => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentThinkResponseCopyWith<AgentThinkResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentThinkResponseCopyWith<$Res> {
  factory $AgentThinkResponseCopyWith(
          AgentThinkResponse value, $Res Function(AgentThinkResponse) then) =
      _$AgentThinkResponseCopyWithImpl<$Res, AgentThinkResponse>;
  @useResult
  $Res call({String analysis, String? plan, List<String>? steps});
}

/// @nodoc
class _$AgentThinkResponseCopyWithImpl<$Res, $Val extends AgentThinkResponse>
    implements $AgentThinkResponseCopyWith<$Res> {
  _$AgentThinkResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? analysis = null,
    Object? plan = freezed,
    Object? steps = freezed,
  }) {
    return _then(_value.copyWith(
      analysis: null == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as String,
      plan: freezed == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String?,
      steps: freezed == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentThinkResponseImplCopyWith<$Res>
    implements $AgentThinkResponseCopyWith<$Res> {
  factory _$$AgentThinkResponseImplCopyWith(_$AgentThinkResponseImpl value,
          $Res Function(_$AgentThinkResponseImpl) then) =
      __$$AgentThinkResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String analysis, String? plan, List<String>? steps});
}

/// @nodoc
class __$$AgentThinkResponseImplCopyWithImpl<$Res>
    extends _$AgentThinkResponseCopyWithImpl<$Res, _$AgentThinkResponseImpl>
    implements _$$AgentThinkResponseImplCopyWith<$Res> {
  __$$AgentThinkResponseImplCopyWithImpl(_$AgentThinkResponseImpl _value,
      $Res Function(_$AgentThinkResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? analysis = null,
    Object? plan = freezed,
    Object? steps = freezed,
  }) {
    return _then(_$AgentThinkResponseImpl(
      analysis: null == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as String,
      plan: freezed == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String?,
      steps: freezed == steps
          ? _value._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentThinkResponseImpl implements _AgentThinkResponse {
  const _$AgentThinkResponseImpl(
      {required this.analysis, this.plan, final List<String>? steps})
      : _steps = steps;

  factory _$AgentThinkResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentThinkResponseImplFromJson(json);

  @override
  final String analysis;
  @override
  final String? plan;
  final List<String>? _steps;
  @override
  List<String>? get steps {
    final value = _steps;
    if (value == null) return null;
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'AgentThinkResponse(analysis: $analysis, plan: $plan, steps: $steps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentThinkResponseImpl &&
            (identical(other.analysis, analysis) ||
                other.analysis == analysis) &&
            (identical(other.plan, plan) || other.plan == plan) &&
            const DeepCollectionEquality().equals(other._steps, _steps));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, analysis, plan, const DeepCollectionEquality().hash(_steps));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentThinkResponseImplCopyWith<_$AgentThinkResponseImpl> get copyWith =>
      __$$AgentThinkResponseImplCopyWithImpl<_$AgentThinkResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentThinkResponseImplToJson(
      this,
    );
  }
}

abstract class _AgentThinkResponse implements AgentThinkResponse {
  const factory _AgentThinkResponse(
      {required final String analysis,
      final String? plan,
      final List<String>? steps}) = _$AgentThinkResponseImpl;

  factory _AgentThinkResponse.fromJson(Map<String, dynamic> json) =
      _$AgentThinkResponseImpl.fromJson;

  @override
  String get analysis;
  @override
  String? get plan;
  @override
  List<String>? get steps;
  @override
  @JsonKey(ignore: true)
  _$$AgentThinkResponseImplCopyWith<_$AgentThinkResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VisionAnalysisResult _$VisionAnalysisResultFromJson(Map<String, dynamic> json) {
  return _VisionAnalysisResult.fromJson(json);
}

/// @nodoc
mixin _$VisionAnalysisResult {
  String get analysis => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VisionAnalysisResultCopyWith<VisionAnalysisResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisionAnalysisResultCopyWith<$Res> {
  factory $VisionAnalysisResultCopyWith(VisionAnalysisResult value,
          $Res Function(VisionAnalysisResult) then) =
      _$VisionAnalysisResultCopyWithImpl<$Res, VisionAnalysisResult>;
  @useResult
  $Res call(
      {String analysis, List<String>? tags, Map<String, dynamic>? metadata});
}

/// @nodoc
class _$VisionAnalysisResultCopyWithImpl<$Res,
        $Val extends VisionAnalysisResult>
    implements $VisionAnalysisResultCopyWith<$Res> {
  _$VisionAnalysisResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? analysis = null,
    Object? tags = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      analysis: null == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as String,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisionAnalysisResultImplCopyWith<$Res>
    implements $VisionAnalysisResultCopyWith<$Res> {
  factory _$$VisionAnalysisResultImplCopyWith(_$VisionAnalysisResultImpl value,
          $Res Function(_$VisionAnalysisResultImpl) then) =
      __$$VisionAnalysisResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String analysis, List<String>? tags, Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$VisionAnalysisResultImplCopyWithImpl<$Res>
    extends _$VisionAnalysisResultCopyWithImpl<$Res, _$VisionAnalysisResultImpl>
    implements _$$VisionAnalysisResultImplCopyWith<$Res> {
  __$$VisionAnalysisResultImplCopyWithImpl(_$VisionAnalysisResultImpl _value,
      $Res Function(_$VisionAnalysisResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? analysis = null,
    Object? tags = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$VisionAnalysisResultImpl(
      analysis: null == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as String,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VisionAnalysisResultImpl implements _VisionAnalysisResult {
  const _$VisionAnalysisResultImpl(
      {required this.analysis,
      final List<String>? tags,
      final Map<String, dynamic>? metadata})
      : _tags = tags,
        _metadata = metadata;

  factory _$VisionAnalysisResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisionAnalysisResultImplFromJson(json);

  @override
  final String analysis;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'VisionAnalysisResult(analysis: $analysis, tags: $tags, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisionAnalysisResultImpl &&
            (identical(other.analysis, analysis) ||
                other.analysis == analysis) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      analysis,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VisionAnalysisResultImplCopyWith<_$VisionAnalysisResultImpl>
      get copyWith =>
          __$$VisionAnalysisResultImplCopyWithImpl<_$VisionAnalysisResultImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisionAnalysisResultImplToJson(
      this,
    );
  }
}

abstract class _VisionAnalysisResult implements VisionAnalysisResult {
  const factory _VisionAnalysisResult(
      {required final String analysis,
      final List<String>? tags,
      final Map<String, dynamic>? metadata}) = _$VisionAnalysisResultImpl;

  factory _VisionAnalysisResult.fromJson(Map<String, dynamic> json) =
      _$VisionAnalysisResultImpl.fromJson;

  @override
  String get analysis;
  @override
  List<String>? get tags;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$VisionAnalysisResultImplCopyWith<_$VisionAnalysisResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}

OcrResult _$OcrResultFromJson(Map<String, dynamic> json) {
  return _OcrResult.fromJson(json);
}

/// @nodoc
mixin _$OcrResult {
  String get text => throw _privateConstructorUsedError;
  List<OcrRegion>? get regions => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OcrResultCopyWith<OcrResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OcrResultCopyWith<$Res> {
  factory $OcrResultCopyWith(OcrResult value, $Res Function(OcrResult) then) =
      _$OcrResultCopyWithImpl<$Res, OcrResult>;
  @useResult
  $Res call({String text, List<OcrRegion>? regions});
}

/// @nodoc
class _$OcrResultCopyWithImpl<$Res, $Val extends OcrResult>
    implements $OcrResultCopyWith<$Res> {
  _$OcrResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? regions = freezed,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      regions: freezed == regions
          ? _value.regions
          : regions // ignore: cast_nullable_to_non_nullable
              as List<OcrRegion>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OcrResultImplCopyWith<$Res>
    implements $OcrResultCopyWith<$Res> {
  factory _$$OcrResultImplCopyWith(
          _$OcrResultImpl value, $Res Function(_$OcrResultImpl) then) =
      __$$OcrResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, List<OcrRegion>? regions});
}

/// @nodoc
class __$$OcrResultImplCopyWithImpl<$Res>
    extends _$OcrResultCopyWithImpl<$Res, _$OcrResultImpl>
    implements _$$OcrResultImplCopyWith<$Res> {
  __$$OcrResultImplCopyWithImpl(
      _$OcrResultImpl _value, $Res Function(_$OcrResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? regions = freezed,
  }) {
    return _then(_$OcrResultImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      regions: freezed == regions
          ? _value._regions
          : regions // ignore: cast_nullable_to_non_nullable
              as List<OcrRegion>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OcrResultImpl implements _OcrResult {
  const _$OcrResultImpl({required this.text, final List<OcrRegion>? regions})
      : _regions = regions;

  factory _$OcrResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$OcrResultImplFromJson(json);

  @override
  final String text;
  final List<OcrRegion>? _regions;
  @override
  List<OcrRegion>? get regions {
    final value = _regions;
    if (value == null) return null;
    if (_regions is EqualUnmodifiableListView) return _regions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'OcrResult(text: $text, regions: $regions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrResultImpl &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._regions, _regions));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, text, const DeepCollectionEquality().hash(_regions));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrResultImplCopyWith<_$OcrResultImpl> get copyWith =>
      __$$OcrResultImplCopyWithImpl<_$OcrResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OcrResultImplToJson(
      this,
    );
  }
}

abstract class _OcrResult implements OcrResult {
  const factory _OcrResult(
      {required final String text,
      final List<OcrRegion>? regions}) = _$OcrResultImpl;

  factory _OcrResult.fromJson(Map<String, dynamic> json) =
      _$OcrResultImpl.fromJson;

  @override
  String get text;
  @override
  List<OcrRegion>? get regions;
  @override
  @JsonKey(ignore: true)
  _$$OcrResultImplCopyWith<_$OcrResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OcrRegion _$OcrRegionFromJson(Map<String, dynamic> json) {
  return _OcrRegion.fromJson(json);
}

/// @nodoc
mixin _$OcrRegion {
  String get text => throw _privateConstructorUsedError;
  @RectConverter()
  Rect get bounds => throw _privateConstructorUsedError;
  double? get confidence => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OcrRegionCopyWith<OcrRegion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OcrRegionCopyWith<$Res> {
  factory $OcrRegionCopyWith(OcrRegion value, $Res Function(OcrRegion) then) =
      _$OcrRegionCopyWithImpl<$Res, OcrRegion>;
  @useResult
  $Res call({String text, @RectConverter() Rect bounds, double? confidence});
}

/// @nodoc
class _$OcrRegionCopyWithImpl<$Res, $Val extends OcrRegion>
    implements $OcrRegionCopyWith<$Res> {
  _$OcrRegionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? bounds = null,
    Object? confidence = freezed,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      bounds: null == bounds
          ? _value.bounds
          : bounds // ignore: cast_nullable_to_non_nullable
              as Rect,
      confidence: freezed == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OcrRegionImplCopyWith<$Res>
    implements $OcrRegionCopyWith<$Res> {
  factory _$$OcrRegionImplCopyWith(
          _$OcrRegionImpl value, $Res Function(_$OcrRegionImpl) then) =
      __$$OcrRegionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, @RectConverter() Rect bounds, double? confidence});
}

/// @nodoc
class __$$OcrRegionImplCopyWithImpl<$Res>
    extends _$OcrRegionCopyWithImpl<$Res, _$OcrRegionImpl>
    implements _$$OcrRegionImplCopyWith<$Res> {
  __$$OcrRegionImplCopyWithImpl(
      _$OcrRegionImpl _value, $Res Function(_$OcrRegionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? bounds = null,
    Object? confidence = freezed,
  }) {
    return _then(_$OcrRegionImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      bounds: null == bounds
          ? _value.bounds
          : bounds // ignore: cast_nullable_to_non_nullable
              as Rect,
      confidence: freezed == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OcrRegionImpl implements _OcrRegion {
  const _$OcrRegionImpl(
      {required this.text,
      @RectConverter() required this.bounds,
      this.confidence});

  factory _$OcrRegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$OcrRegionImplFromJson(json);

  @override
  final String text;
  @override
  @RectConverter()
  final Rect bounds;
  @override
  final double? confidence;

  @override
  String toString() {
    return 'OcrRegion(text: $text, bounds: $bounds, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrRegionImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.bounds, bounds) || other.bounds == bounds) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, text, bounds, confidence);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrRegionImplCopyWith<_$OcrRegionImpl> get copyWith =>
      __$$OcrRegionImplCopyWithImpl<_$OcrRegionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OcrRegionImplToJson(
      this,
    );
  }
}

abstract class _OcrRegion implements OcrRegion {
  const factory _OcrRegion(
      {required final String text,
      @RectConverter() required final Rect bounds,
      final double? confidence}) = _$OcrRegionImpl;

  factory _OcrRegion.fromJson(Map<String, dynamic> json) =
      _$OcrRegionImpl.fromJson;

  @override
  String get text;
  @override
  @RectConverter()
  Rect get bounds;
  @override
  double? get confidence;
  @override
  @JsonKey(ignore: true)
  _$$OcrRegionImplCopyWith<_$OcrRegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SystemStatus _$SystemStatusFromJson(Map<String, dynamic> json) {
  return _SystemStatus.fromJson(json);
}

/// @nodoc
mixin _$SystemStatus {
  String get status => throw _privateConstructorUsedError;
  String get maya => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SystemStatusCopyWith<SystemStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SystemStatusCopyWith<$Res> {
  factory $SystemStatusCopyWith(
          SystemStatus value, $Res Function(SystemStatus) then) =
      _$SystemStatusCopyWithImpl<$Res, SystemStatus>;
  @useResult
  $Res call({String status, String maya});
}

/// @nodoc
class _$SystemStatusCopyWithImpl<$Res, $Val extends SystemStatus>
    implements $SystemStatusCopyWith<$Res> {
  _$SystemStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? maya = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      maya: null == maya
          ? _value.maya
          : maya // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SystemStatusImplCopyWith<$Res>
    implements $SystemStatusCopyWith<$Res> {
  factory _$$SystemStatusImplCopyWith(
          _$SystemStatusImpl value, $Res Function(_$SystemStatusImpl) then) =
      __$$SystemStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String status, String maya});
}

/// @nodoc
class __$$SystemStatusImplCopyWithImpl<$Res>
    extends _$SystemStatusCopyWithImpl<$Res, _$SystemStatusImpl>
    implements _$$SystemStatusImplCopyWith<$Res> {
  __$$SystemStatusImplCopyWithImpl(
      _$SystemStatusImpl _value, $Res Function(_$SystemStatusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? maya = null,
  }) {
    return _then(_$SystemStatusImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      maya: null == maya
          ? _value.maya
          : maya // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SystemStatusImpl implements _SystemStatus {
  const _$SystemStatusImpl({required this.status, required this.maya});

  factory _$SystemStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$SystemStatusImplFromJson(json);

  @override
  final String status;
  @override
  final String maya;

  @override
  String toString() {
    return 'SystemStatus(status: $status, maya: $maya)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SystemStatusImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.maya, maya) || other.maya == maya));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, status, maya);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SystemStatusImplCopyWith<_$SystemStatusImpl> get copyWith =>
      __$$SystemStatusImplCopyWithImpl<_$SystemStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SystemStatusImplToJson(
      this,
    );
  }
}

abstract class _SystemStatus implements SystemStatus {
  const factory _SystemStatus(
      {required final String status,
      required final String maya}) = _$SystemStatusImpl;

  factory _SystemStatus.fromJson(Map<String, dynamic> json) =
      _$SystemStatusImpl.fromJson;

  @override
  String get status;
  @override
  String get maya;
  @override
  @JsonKey(ignore: true)
  _$$SystemStatusImplCopyWith<_$SystemStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SystemStats _$SystemStatsFromJson(Map<String, dynamic> json) {
  return _SystemStats.fromJson(json);
}

/// @nodoc
mixin _$SystemStats {
  CpuStats get cpu => throw _privateConstructorUsedError;
  MemoryStats get memory => throw _privateConstructorUsedError;
  DiskStats get disk => throw _privateConstructorUsedError;
  LoadStats get load => throw _privateConstructorUsedError;
  NetworkStats? get network => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SystemStatsCopyWith<SystemStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SystemStatsCopyWith<$Res> {
  factory $SystemStatsCopyWith(
          SystemStats value, $Res Function(SystemStats) then) =
      _$SystemStatsCopyWithImpl<$Res, SystemStats>;
  @useResult
  $Res call(
      {CpuStats cpu,
      MemoryStats memory,
      DiskStats disk,
      LoadStats load,
      NetworkStats? network});

  $CpuStatsCopyWith<$Res> get cpu;
  $MemoryStatsCopyWith<$Res> get memory;
  $DiskStatsCopyWith<$Res> get disk;
  $LoadStatsCopyWith<$Res> get load;
  $NetworkStatsCopyWith<$Res>? get network;
}

/// @nodoc
class _$SystemStatsCopyWithImpl<$Res, $Val extends SystemStats>
    implements $SystemStatsCopyWith<$Res> {
  _$SystemStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cpu = null,
    Object? memory = null,
    Object? disk = null,
    Object? load = null,
    Object? network = freezed,
  }) {
    return _then(_value.copyWith(
      cpu: null == cpu
          ? _value.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as CpuStats,
      memory: null == memory
          ? _value.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as MemoryStats,
      disk: null == disk
          ? _value.disk
          : disk // ignore: cast_nullable_to_non_nullable
              as DiskStats,
      load: null == load
          ? _value.load
          : load // ignore: cast_nullable_to_non_nullable
              as LoadStats,
      network: freezed == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as NetworkStats?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $CpuStatsCopyWith<$Res> get cpu {
    return $CpuStatsCopyWith<$Res>(_value.cpu, (value) {
      return _then(_value.copyWith(cpu: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $MemoryStatsCopyWith<$Res> get memory {
    return $MemoryStatsCopyWith<$Res>(_value.memory, (value) {
      return _then(_value.copyWith(memory: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $DiskStatsCopyWith<$Res> get disk {
    return $DiskStatsCopyWith<$Res>(_value.disk, (value) {
      return _then(_value.copyWith(disk: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $LoadStatsCopyWith<$Res> get load {
    return $LoadStatsCopyWith<$Res>(_value.load, (value) {
      return _then(_value.copyWith(load: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $NetworkStatsCopyWith<$Res>? get network {
    if (_value.network == null) {
      return null;
    }

    return $NetworkStatsCopyWith<$Res>(_value.network!, (value) {
      return _then(_value.copyWith(network: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SystemStatsImplCopyWith<$Res>
    implements $SystemStatsCopyWith<$Res> {
  factory _$$SystemStatsImplCopyWith(
          _$SystemStatsImpl value, $Res Function(_$SystemStatsImpl) then) =
      __$$SystemStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CpuStats cpu,
      MemoryStats memory,
      DiskStats disk,
      LoadStats load,
      NetworkStats? network});

  @override
  $CpuStatsCopyWith<$Res> get cpu;
  @override
  $MemoryStatsCopyWith<$Res> get memory;
  @override
  $DiskStatsCopyWith<$Res> get disk;
  @override
  $LoadStatsCopyWith<$Res> get load;
  @override
  $NetworkStatsCopyWith<$Res>? get network;
}

/// @nodoc
class __$$SystemStatsImplCopyWithImpl<$Res>
    extends _$SystemStatsCopyWithImpl<$Res, _$SystemStatsImpl>
    implements _$$SystemStatsImplCopyWith<$Res> {
  __$$SystemStatsImplCopyWithImpl(
      _$SystemStatsImpl _value, $Res Function(_$SystemStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cpu = null,
    Object? memory = null,
    Object? disk = null,
    Object? load = null,
    Object? network = freezed,
  }) {
    return _then(_$SystemStatsImpl(
      cpu: null == cpu
          ? _value.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as CpuStats,
      memory: null == memory
          ? _value.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as MemoryStats,
      disk: null == disk
          ? _value.disk
          : disk // ignore: cast_nullable_to_non_nullable
              as DiskStats,
      load: null == load
          ? _value.load
          : load // ignore: cast_nullable_to_non_nullable
              as LoadStats,
      network: freezed == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as NetworkStats?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SystemStatsImpl implements _SystemStats {
  const _$SystemStatsImpl(
      {required this.cpu,
      required this.memory,
      required this.disk,
      required this.load,
      this.network});

  factory _$SystemStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SystemStatsImplFromJson(json);

  @override
  final CpuStats cpu;
  @override
  final MemoryStats memory;
  @override
  final DiskStats disk;
  @override
  final LoadStats load;
  @override
  final NetworkStats? network;

  @override
  String toString() {
    return 'SystemStats(cpu: $cpu, memory: $memory, disk: $disk, load: $load, network: $network)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SystemStatsImpl &&
            (identical(other.cpu, cpu) || other.cpu == cpu) &&
            (identical(other.memory, memory) || other.memory == memory) &&
            (identical(other.disk, disk) || other.disk == disk) &&
            (identical(other.load, load) || other.load == load) &&
            (identical(other.network, network) || other.network == network));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, cpu, memory, disk, load, network);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SystemStatsImplCopyWith<_$SystemStatsImpl> get copyWith =>
      __$$SystemStatsImplCopyWithImpl<_$SystemStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SystemStatsImplToJson(
      this,
    );
  }
}

abstract class _SystemStats implements SystemStats {
  const factory _SystemStats(
      {required final CpuStats cpu,
      required final MemoryStats memory,
      required final DiskStats disk,
      required final LoadStats load,
      final NetworkStats? network}) = _$SystemStatsImpl;

  factory _SystemStats.fromJson(Map<String, dynamic> json) =
      _$SystemStatsImpl.fromJson;

  @override
  CpuStats get cpu;
  @override
  MemoryStats get memory;
  @override
  DiskStats get disk;
  @override
  LoadStats get load;
  @override
  NetworkStats? get network;
  @override
  @JsonKey(ignore: true)
  _$$SystemStatsImplCopyWith<_$SystemStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CpuStats _$CpuStatsFromJson(Map<String, dynamic> json) {
  return _CpuStats.fromJson(json);
}

/// @nodoc
mixin _$CpuStats {
  double get percent => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CpuStatsCopyWith<CpuStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CpuStatsCopyWith<$Res> {
  factory $CpuStatsCopyWith(CpuStats value, $Res Function(CpuStats) then) =
      _$CpuStatsCopyWithImpl<$Res, CpuStats>;
  @useResult
  $Res call({double percent, int count});
}

/// @nodoc
class _$CpuStatsCopyWithImpl<$Res, $Val extends CpuStats>
    implements $CpuStatsCopyWith<$Res> {
  _$CpuStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? percent = null,
    Object? count = null,
  }) {
    return _then(_value.copyWith(
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CpuStatsImplCopyWith<$Res>
    implements $CpuStatsCopyWith<$Res> {
  factory _$$CpuStatsImplCopyWith(
          _$CpuStatsImpl value, $Res Function(_$CpuStatsImpl) then) =
      __$$CpuStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double percent, int count});
}

/// @nodoc
class __$$CpuStatsImplCopyWithImpl<$Res>
    extends _$CpuStatsCopyWithImpl<$Res, _$CpuStatsImpl>
    implements _$$CpuStatsImplCopyWith<$Res> {
  __$$CpuStatsImplCopyWithImpl(
      _$CpuStatsImpl _value, $Res Function(_$CpuStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? percent = null,
    Object? count = null,
  }) {
    return _then(_$CpuStatsImpl(
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CpuStatsImpl implements _CpuStats {
  const _$CpuStatsImpl({required this.percent, required this.count});

  factory _$CpuStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CpuStatsImplFromJson(json);

  @override
  final double percent;
  @override
  final int count;

  @override
  String toString() {
    return 'CpuStats(percent: $percent, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CpuStatsImpl &&
            (identical(other.percent, percent) || other.percent == percent) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, percent, count);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CpuStatsImplCopyWith<_$CpuStatsImpl> get copyWith =>
      __$$CpuStatsImplCopyWithImpl<_$CpuStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CpuStatsImplToJson(
      this,
    );
  }
}

abstract class _CpuStats implements CpuStats {
  const factory _CpuStats(
      {required final double percent,
      required final int count}) = _$CpuStatsImpl;

  factory _CpuStats.fromJson(Map<String, dynamic> json) =
      _$CpuStatsImpl.fromJson;

  @override
  double get percent;
  @override
  int get count;
  @override
  @JsonKey(ignore: true)
  _$$CpuStatsImplCopyWith<_$CpuStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoryStats _$MemoryStatsFromJson(Map<String, dynamic> json) {
  return _MemoryStats.fromJson(json);
}

/// @nodoc
mixin _$MemoryStats {
  double get totalGb => throw _privateConstructorUsedError;
  double get availableGb => throw _privateConstructorUsedError;
  double get usedGb => throw _privateConstructorUsedError;
  double get percent => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemoryStatsCopyWith<MemoryStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryStatsCopyWith<$Res> {
  factory $MemoryStatsCopyWith(
          MemoryStats value, $Res Function(MemoryStats) then) =
      _$MemoryStatsCopyWithImpl<$Res, MemoryStats>;
  @useResult
  $Res call(
      {double totalGb, double availableGb, double usedGb, double percent});
}

/// @nodoc
class _$MemoryStatsCopyWithImpl<$Res, $Val extends MemoryStats>
    implements $MemoryStatsCopyWith<$Res> {
  _$MemoryStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalGb = null,
    Object? availableGb = null,
    Object? usedGb = null,
    Object? percent = null,
  }) {
    return _then(_value.copyWith(
      totalGb: null == totalGb
          ? _value.totalGb
          : totalGb // ignore: cast_nullable_to_non_nullable
              as double,
      availableGb: null == availableGb
          ? _value.availableGb
          : availableGb // ignore: cast_nullable_to_non_nullable
              as double,
      usedGb: null == usedGb
          ? _value.usedGb
          : usedGb // ignore: cast_nullable_to_non_nullable
              as double,
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoryStatsImplCopyWith<$Res>
    implements $MemoryStatsCopyWith<$Res> {
  factory _$$MemoryStatsImplCopyWith(
          _$MemoryStatsImpl value, $Res Function(_$MemoryStatsImpl) then) =
      __$$MemoryStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double totalGb, double availableGb, double usedGb, double percent});
}

/// @nodoc
class __$$MemoryStatsImplCopyWithImpl<$Res>
    extends _$MemoryStatsCopyWithImpl<$Res, _$MemoryStatsImpl>
    implements _$$MemoryStatsImplCopyWith<$Res> {
  __$$MemoryStatsImplCopyWithImpl(
      _$MemoryStatsImpl _value, $Res Function(_$MemoryStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalGb = null,
    Object? availableGb = null,
    Object? usedGb = null,
    Object? percent = null,
  }) {
    return _then(_$MemoryStatsImpl(
      totalGb: null == totalGb
          ? _value.totalGb
          : totalGb // ignore: cast_nullable_to_non_nullable
              as double,
      availableGb: null == availableGb
          ? _value.availableGb
          : availableGb // ignore: cast_nullable_to_non_nullable
              as double,
      usedGb: null == usedGb
          ? _value.usedGb
          : usedGb // ignore: cast_nullable_to_non_nullable
              as double,
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemoryStatsImpl implements _MemoryStats {
  const _$MemoryStatsImpl(
      {required this.totalGb,
      required this.availableGb,
      required this.usedGb,
      required this.percent});

  factory _$MemoryStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoryStatsImplFromJson(json);

  @override
  final double totalGb;
  @override
  final double availableGb;
  @override
  final double usedGb;
  @override
  final double percent;

  @override
  String toString() {
    return 'MemoryStats(totalGb: $totalGb, availableGb: $availableGb, usedGb: $usedGb, percent: $percent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryStatsImpl &&
            (identical(other.totalGb, totalGb) || other.totalGb == totalGb) &&
            (identical(other.availableGb, availableGb) ||
                other.availableGb == availableGb) &&
            (identical(other.usedGb, usedGb) || other.usedGb == usedGb) &&
            (identical(other.percent, percent) || other.percent == percent));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, totalGb, availableGb, usedGb, percent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryStatsImplCopyWith<_$MemoryStatsImpl> get copyWith =>
      __$$MemoryStatsImplCopyWithImpl<_$MemoryStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoryStatsImplToJson(
      this,
    );
  }
}

abstract class _MemoryStats implements MemoryStats {
  const factory _MemoryStats(
      {required final double totalGb,
      required final double availableGb,
      required final double usedGb,
      required final double percent}) = _$MemoryStatsImpl;

  factory _MemoryStats.fromJson(Map<String, dynamic> json) =
      _$MemoryStatsImpl.fromJson;

  @override
  double get totalGb;
  @override
  double get availableGb;
  @override
  double get usedGb;
  @override
  double get percent;
  @override
  @JsonKey(ignore: true)
  _$$MemoryStatsImplCopyWith<_$MemoryStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiskStats _$DiskStatsFromJson(Map<String, dynamic> json) {
  return _DiskStats.fromJson(json);
}

/// @nodoc
mixin _$DiskStats {
  double get totalGb => throw _privateConstructorUsedError;
  double get usedGb => throw _privateConstructorUsedError;
  double get freeGb => throw _privateConstructorUsedError;
  double get percent => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiskStatsCopyWith<DiskStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiskStatsCopyWith<$Res> {
  factory $DiskStatsCopyWith(DiskStats value, $Res Function(DiskStats) then) =
      _$DiskStatsCopyWithImpl<$Res, DiskStats>;
  @useResult
  $Res call({double totalGb, double usedGb, double freeGb, double percent});
}

/// @nodoc
class _$DiskStatsCopyWithImpl<$Res, $Val extends DiskStats>
    implements $DiskStatsCopyWith<$Res> {
  _$DiskStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalGb = null,
    Object? usedGb = null,
    Object? freeGb = null,
    Object? percent = null,
  }) {
    return _then(_value.copyWith(
      totalGb: null == totalGb
          ? _value.totalGb
          : totalGb // ignore: cast_nullable_to_non_nullable
              as double,
      usedGb: null == usedGb
          ? _value.usedGb
          : usedGb // ignore: cast_nullable_to_non_nullable
              as double,
      freeGb: null == freeGb
          ? _value.freeGb
          : freeGb // ignore: cast_nullable_to_non_nullable
              as double,
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiskStatsImplCopyWith<$Res>
    implements $DiskStatsCopyWith<$Res> {
  factory _$$DiskStatsImplCopyWith(
          _$DiskStatsImpl value, $Res Function(_$DiskStatsImpl) then) =
      __$$DiskStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double totalGb, double usedGb, double freeGb, double percent});
}

/// @nodoc
class __$$DiskStatsImplCopyWithImpl<$Res>
    extends _$DiskStatsCopyWithImpl<$Res, _$DiskStatsImpl>
    implements _$$DiskStatsImplCopyWith<$Res> {
  __$$DiskStatsImplCopyWithImpl(
      _$DiskStatsImpl _value, $Res Function(_$DiskStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalGb = null,
    Object? usedGb = null,
    Object? freeGb = null,
    Object? percent = null,
  }) {
    return _then(_$DiskStatsImpl(
      totalGb: null == totalGb
          ? _value.totalGb
          : totalGb // ignore: cast_nullable_to_non_nullable
              as double,
      usedGb: null == usedGb
          ? _value.usedGb
          : usedGb // ignore: cast_nullable_to_non_nullable
              as double,
      freeGb: null == freeGb
          ? _value.freeGb
          : freeGb // ignore: cast_nullable_to_non_nullable
              as double,
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiskStatsImpl implements _DiskStats {
  const _$DiskStatsImpl(
      {required this.totalGb,
      required this.usedGb,
      required this.freeGb,
      required this.percent});

  factory _$DiskStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiskStatsImplFromJson(json);

  @override
  final double totalGb;
  @override
  final double usedGb;
  @override
  final double freeGb;
  @override
  final double percent;

  @override
  String toString() {
    return 'DiskStats(totalGb: $totalGb, usedGb: $usedGb, freeGb: $freeGb, percent: $percent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiskStatsImpl &&
            (identical(other.totalGb, totalGb) || other.totalGb == totalGb) &&
            (identical(other.usedGb, usedGb) || other.usedGb == usedGb) &&
            (identical(other.freeGb, freeGb) || other.freeGb == freeGb) &&
            (identical(other.percent, percent) || other.percent == percent));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, totalGb, usedGb, freeGb, percent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiskStatsImplCopyWith<_$DiskStatsImpl> get copyWith =>
      __$$DiskStatsImplCopyWithImpl<_$DiskStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiskStatsImplToJson(
      this,
    );
  }
}

abstract class _DiskStats implements DiskStats {
  const factory _DiskStats(
      {required final double totalGb,
      required final double usedGb,
      required final double freeGb,
      required final double percent}) = _$DiskStatsImpl;

  factory _DiskStats.fromJson(Map<String, dynamic> json) =
      _$DiskStatsImpl.fromJson;

  @override
  double get totalGb;
  @override
  double get usedGb;
  @override
  double get freeGb;
  @override
  double get percent;
  @override
  @JsonKey(ignore: true)
  _$$DiskStatsImplCopyWith<_$DiskStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LoadStats _$LoadStatsFromJson(Map<String, dynamic> json) {
  return _LoadStats.fromJson(json);
}

/// @nodoc
mixin _$LoadStats {
  List<double> get loadAvg => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LoadStatsCopyWith<LoadStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoadStatsCopyWith<$Res> {
  factory $LoadStatsCopyWith(LoadStats value, $Res Function(LoadStats) then) =
      _$LoadStatsCopyWithImpl<$Res, LoadStats>;
  @useResult
  $Res call({List<double> loadAvg});
}

/// @nodoc
class _$LoadStatsCopyWithImpl<$Res, $Val extends LoadStats>
    implements $LoadStatsCopyWith<$Res> {
  _$LoadStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? loadAvg = null,
  }) {
    return _then(_value.copyWith(
      loadAvg: null == loadAvg
          ? _value.loadAvg
          : loadAvg // ignore: cast_nullable_to_non_nullable
              as List<double>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LoadStatsImplCopyWith<$Res>
    implements $LoadStatsCopyWith<$Res> {
  factory _$$LoadStatsImplCopyWith(
          _$LoadStatsImpl value, $Res Function(_$LoadStatsImpl) then) =
      __$$LoadStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<double> loadAvg});
}

/// @nodoc
class __$$LoadStatsImplCopyWithImpl<$Res>
    extends _$LoadStatsCopyWithImpl<$Res, _$LoadStatsImpl>
    implements _$$LoadStatsImplCopyWith<$Res> {
  __$$LoadStatsImplCopyWithImpl(
      _$LoadStatsImpl _value, $Res Function(_$LoadStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? loadAvg = null,
  }) {
    return _then(_$LoadStatsImpl(
      loadAvg: null == loadAvg
          ? _value._loadAvg
          : loadAvg // ignore: cast_nullable_to_non_nullable
              as List<double>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LoadStatsImpl implements _LoadStats {
  const _$LoadStatsImpl({required final List<double> loadAvg})
      : _loadAvg = loadAvg;

  factory _$LoadStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoadStatsImplFromJson(json);

  final List<double> _loadAvg;
  @override
  List<double> get loadAvg {
    if (_loadAvg is EqualUnmodifiableListView) return _loadAvg;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_loadAvg);
  }

  @override
  String toString() {
    return 'LoadStats(loadAvg: $loadAvg)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadStatsImpl &&
            const DeepCollectionEquality().equals(other._loadAvg, _loadAvg));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_loadAvg));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadStatsImplCopyWith<_$LoadStatsImpl> get copyWith =>
      __$$LoadStatsImplCopyWithImpl<_$LoadStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoadStatsImplToJson(
      this,
    );
  }
}

abstract class _LoadStats implements LoadStats {
  const factory _LoadStats({required final List<double> loadAvg}) =
      _$LoadStatsImpl;

  factory _LoadStats.fromJson(Map<String, dynamic> json) =
      _$LoadStatsImpl.fromJson;

  @override
  List<double> get loadAvg;
  @override
  @JsonKey(ignore: true)
  _$$LoadStatsImplCopyWith<_$LoadStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NetworkStats _$NetworkStatsFromJson(Map<String, dynamic> json) {
  return _NetworkStats.fromJson(json);
}

/// @nodoc
mixin _$NetworkStats {
  int get bytesSent => throw _privateConstructorUsedError;
  int get bytesRecv => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NetworkStatsCopyWith<NetworkStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkStatsCopyWith<$Res> {
  factory $NetworkStatsCopyWith(
          NetworkStats value, $Res Function(NetworkStats) then) =
      _$NetworkStatsCopyWithImpl<$Res, NetworkStats>;
  @useResult
  $Res call({int bytesSent, int bytesRecv});
}

/// @nodoc
class _$NetworkStatsCopyWithImpl<$Res, $Val extends NetworkStats>
    implements $NetworkStatsCopyWith<$Res> {
  _$NetworkStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytesSent = null,
    Object? bytesRecv = null,
  }) {
    return _then(_value.copyWith(
      bytesSent: null == bytesSent
          ? _value.bytesSent
          : bytesSent // ignore: cast_nullable_to_non_nullable
              as int,
      bytesRecv: null == bytesRecv
          ? _value.bytesRecv
          : bytesRecv // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NetworkStatsImplCopyWith<$Res>
    implements $NetworkStatsCopyWith<$Res> {
  factory _$$NetworkStatsImplCopyWith(
          _$NetworkStatsImpl value, $Res Function(_$NetworkStatsImpl) then) =
      __$$NetworkStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int bytesSent, int bytesRecv});
}

/// @nodoc
class __$$NetworkStatsImplCopyWithImpl<$Res>
    extends _$NetworkStatsCopyWithImpl<$Res, _$NetworkStatsImpl>
    implements _$$NetworkStatsImplCopyWith<$Res> {
  __$$NetworkStatsImplCopyWithImpl(
      _$NetworkStatsImpl _value, $Res Function(_$NetworkStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytesSent = null,
    Object? bytesRecv = null,
  }) {
    return _then(_$NetworkStatsImpl(
      bytesSent: null == bytesSent
          ? _value.bytesSent
          : bytesSent // ignore: cast_nullable_to_non_nullable
              as int,
      bytesRecv: null == bytesRecv
          ? _value.bytesRecv
          : bytesRecv // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NetworkStatsImpl implements _NetworkStats {
  const _$NetworkStatsImpl({required this.bytesSent, required this.bytesRecv});

  factory _$NetworkStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetworkStatsImplFromJson(json);

  @override
  final int bytesSent;
  @override
  final int bytesRecv;

  @override
  String toString() {
    return 'NetworkStats(bytesSent: $bytesSent, bytesRecv: $bytesRecv)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkStatsImpl &&
            (identical(other.bytesSent, bytesSent) ||
                other.bytesSent == bytesSent) &&
            (identical(other.bytesRecv, bytesRecv) ||
                other.bytesRecv == bytesRecv));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, bytesSent, bytesRecv);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkStatsImplCopyWith<_$NetworkStatsImpl> get copyWith =>
      __$$NetworkStatsImplCopyWithImpl<_$NetworkStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NetworkStatsImplToJson(
      this,
    );
  }
}

abstract class _NetworkStats implements NetworkStats {
  const factory _NetworkStats(
      {required final int bytesSent,
      required final int bytesRecv}) = _$NetworkStatsImpl;

  factory _NetworkStats.fromJson(Map<String, dynamic> json) =
      _$NetworkStatsImpl.fromJson;

  @override
  int get bytesSent;
  @override
  int get bytesRecv;
  @override
  @JsonKey(ignore: true)
  _$$NetworkStatsImplCopyWith<_$NetworkStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QueueStatus _$QueueStatusFromJson(Map<String, dynamic> json) {
  return _QueueStatus.fromJson(json);
}

/// @nodoc
mixin _$QueueStatus {
  Map<String, dynamic> get tasks => throw _privateConstructorUsedError;
  int get workers => throw _privateConstructorUsedError;
  bool get running => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QueueStatusCopyWith<QueueStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueueStatusCopyWith<$Res> {
  factory $QueueStatusCopyWith(
          QueueStatus value, $Res Function(QueueStatus) then) =
      _$QueueStatusCopyWithImpl<$Res, QueueStatus>;
  @useResult
  $Res call({Map<String, dynamic> tasks, int workers, bool running});
}

/// @nodoc
class _$QueueStatusCopyWithImpl<$Res, $Val extends QueueStatus>
    implements $QueueStatusCopyWith<$Res> {
  _$QueueStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tasks = null,
    Object? workers = null,
    Object? running = null,
  }) {
    return _then(_value.copyWith(
      tasks: null == tasks
          ? _value.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      workers: null == workers
          ? _value.workers
          : workers // ignore: cast_nullable_to_non_nullable
              as int,
      running: null == running
          ? _value.running
          : running // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QueueStatusImplCopyWith<$Res>
    implements $QueueStatusCopyWith<$Res> {
  factory _$$QueueStatusImplCopyWith(
          _$QueueStatusImpl value, $Res Function(_$QueueStatusImpl) then) =
      __$$QueueStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, dynamic> tasks, int workers, bool running});
}

/// @nodoc
class __$$QueueStatusImplCopyWithImpl<$Res>
    extends _$QueueStatusCopyWithImpl<$Res, _$QueueStatusImpl>
    implements _$$QueueStatusImplCopyWith<$Res> {
  __$$QueueStatusImplCopyWithImpl(
      _$QueueStatusImpl _value, $Res Function(_$QueueStatusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tasks = null,
    Object? workers = null,
    Object? running = null,
  }) {
    return _then(_$QueueStatusImpl(
      tasks: null == tasks
          ? _value._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      workers: null == workers
          ? _value.workers
          : workers // ignore: cast_nullable_to_non_nullable
              as int,
      running: null == running
          ? _value.running
          : running // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QueueStatusImpl implements _QueueStatus {
  const _$QueueStatusImpl(
      {required final Map<String, dynamic> tasks,
      required this.workers,
      required this.running})
      : _tasks = tasks;

  factory _$QueueStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$QueueStatusImplFromJson(json);

  final Map<String, dynamic> _tasks;
  @override
  Map<String, dynamic> get tasks {
    if (_tasks is EqualUnmodifiableMapView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_tasks);
  }

  @override
  final int workers;
  @override
  final bool running;

  @override
  String toString() {
    return 'QueueStatus(tasks: $tasks, workers: $workers, running: $running)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueueStatusImpl &&
            const DeepCollectionEquality().equals(other._tasks, _tasks) &&
            (identical(other.workers, workers) || other.workers == workers) &&
            (identical(other.running, running) || other.running == running));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_tasks), workers, running);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QueueStatusImplCopyWith<_$QueueStatusImpl> get copyWith =>
      __$$QueueStatusImplCopyWithImpl<_$QueueStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QueueStatusImplToJson(
      this,
    );
  }
}

abstract class _QueueStatus implements QueueStatus {
  const factory _QueueStatus(
      {required final Map<String, dynamic> tasks,
      required final int workers,
      required final bool running}) = _$QueueStatusImpl;

  factory _QueueStatus.fromJson(Map<String, dynamic> json) =
      _$QueueStatusImpl.fromJson;

  @override
  Map<String, dynamic> get tasks;
  @override
  int get workers;
  @override
  bool get running;
  @override
  @JsonKey(ignore: true)
  _$$QueueStatusImplCopyWith<_$QueueStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QueueStats _$QueueStatsFromJson(Map<String, dynamic> json) {
  return _QueueStats.fromJson(json);
}

/// @nodoc
mixin _$QueueStats {
  int get pending => throw _privateConstructorUsedError;
  int get running => throw _privateConstructorUsedError;
  int get completed => throw _privateConstructorUsedError;
  int get failed => throw _privateConstructorUsedError;
  int get cancelled => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QueueStatsCopyWith<QueueStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueueStatsCopyWith<$Res> {
  factory $QueueStatsCopyWith(
          QueueStats value, $Res Function(QueueStats) then) =
      _$QueueStatsCopyWithImpl<$Res, QueueStats>;
  @useResult
  $Res call(
      {int pending,
      int running,
      int completed,
      int failed,
      int cancelled,
      int total});
}

/// @nodoc
class _$QueueStatsCopyWithImpl<$Res, $Val extends QueueStats>
    implements $QueueStatsCopyWith<$Res> {
  _$QueueStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pending = null,
    Object? running = null,
    Object? completed = null,
    Object? failed = null,
    Object? cancelled = null,
    Object? total = null,
  }) {
    return _then(_value.copyWith(
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as int,
      running: null == running
          ? _value.running
          : running // ignore: cast_nullable_to_non_nullable
              as int,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as int,
      failed: null == failed
          ? _value.failed
          : failed // ignore: cast_nullable_to_non_nullable
              as int,
      cancelled: null == cancelled
          ? _value.cancelled
          : cancelled // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QueueStatsImplCopyWith<$Res>
    implements $QueueStatsCopyWith<$Res> {
  factory _$$QueueStatsImplCopyWith(
          _$QueueStatsImpl value, $Res Function(_$QueueStatsImpl) then) =
      __$$QueueStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int pending,
      int running,
      int completed,
      int failed,
      int cancelled,
      int total});
}

/// @nodoc
class __$$QueueStatsImplCopyWithImpl<$Res>
    extends _$QueueStatsCopyWithImpl<$Res, _$QueueStatsImpl>
    implements _$$QueueStatsImplCopyWith<$Res> {
  __$$QueueStatsImplCopyWithImpl(
      _$QueueStatsImpl _value, $Res Function(_$QueueStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pending = null,
    Object? running = null,
    Object? completed = null,
    Object? failed = null,
    Object? cancelled = null,
    Object? total = null,
  }) {
    return _then(_$QueueStatsImpl(
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as int,
      running: null == running
          ? _value.running
          : running // ignore: cast_nullable_to_non_nullable
              as int,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as int,
      failed: null == failed
          ? _value.failed
          : failed // ignore: cast_nullable_to_non_nullable
              as int,
      cancelled: null == cancelled
          ? _value.cancelled
          : cancelled // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QueueStatsImpl implements _QueueStats {
  const _$QueueStatsImpl(
      {required this.pending,
      required this.running,
      required this.completed,
      required this.failed,
      required this.cancelled,
      required this.total});

  factory _$QueueStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$QueueStatsImplFromJson(json);

  @override
  final int pending;
  @override
  final int running;
  @override
  final int completed;
  @override
  final int failed;
  @override
  final int cancelled;
  @override
  final int total;

  @override
  String toString() {
    return 'QueueStats(pending: $pending, running: $running, completed: $completed, failed: $failed, cancelled: $cancelled, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueueStatsImpl &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.running, running) || other.running == running) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.failed, failed) || other.failed == failed) &&
            (identical(other.cancelled, cancelled) ||
                other.cancelled == cancelled) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, pending, running, completed, failed, cancelled, total);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QueueStatsImplCopyWith<_$QueueStatsImpl> get copyWith =>
      __$$QueueStatsImplCopyWithImpl<_$QueueStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QueueStatsImplToJson(
      this,
    );
  }
}

abstract class _QueueStats implements QueueStats {
  const factory _QueueStats(
      {required final int pending,
      required final int running,
      required final int completed,
      required final int failed,
      required final int cancelled,
      required final int total}) = _$QueueStatsImpl;

  factory _QueueStats.fromJson(Map<String, dynamic> json) =
      _$QueueStatsImpl.fromJson;

  @override
  int get pending;
  @override
  int get running;
  @override
  int get completed;
  @override
  int get failed;
  @override
  int get cancelled;
  @override
  int get total;
  @override
  @JsonKey(ignore: true)
  _$$QueueStatsImplCopyWith<_$QueueStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QueueTaskStatus _$QueueTaskStatusFromJson(Map<String, dynamic> json) {
  return _QueueTaskStatus.fromJson(json);
}

/// @nodoc
mixin _$QueueTaskStatus {
  String get taskId => throw _privateConstructorUsedError;
  String get job => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  int? get priority => throw _privateConstructorUsedError;
  String? get result => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get startedAt => throw _privateConstructorUsedError;
  String? get completedAt => throw _privateConstructorUsedError;
  String? get workerId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QueueTaskStatusCopyWith<QueueTaskStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueueTaskStatusCopyWith<$Res> {
  factory $QueueTaskStatusCopyWith(
          QueueTaskStatus value, $Res Function(QueueTaskStatus) then) =
      _$QueueTaskStatusCopyWithImpl<$Res, QueueTaskStatus>;
  @useResult
  $Res call(
      {String taskId,
      String job,
      String state,
      Map<String, dynamic> payload,
      int? priority,
      String? result,
      String? error,
      String? createdAt,
      String? startedAt,
      String? completedAt,
      String? workerId});
}

/// @nodoc
class _$QueueTaskStatusCopyWithImpl<$Res, $Val extends QueueTaskStatus>
    implements $QueueTaskStatusCopyWith<$Res> {
  _$QueueTaskStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? job = null,
    Object? state = null,
    Object? payload = null,
    Object? priority = freezed,
    Object? result = freezed,
    Object? error = freezed,
    Object? createdAt = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? workerId = freezed,
  }) {
    return _then(_value.copyWith(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      job: null == job
          ? _value.job
          : job // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int?,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      workerId: freezed == workerId
          ? _value.workerId
          : workerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QueueTaskStatusImplCopyWith<$Res>
    implements $QueueTaskStatusCopyWith<$Res> {
  factory _$$QueueTaskStatusImplCopyWith(_$QueueTaskStatusImpl value,
          $Res Function(_$QueueTaskStatusImpl) then) =
      __$$QueueTaskStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String taskId,
      String job,
      String state,
      Map<String, dynamic> payload,
      int? priority,
      String? result,
      String? error,
      String? createdAt,
      String? startedAt,
      String? completedAt,
      String? workerId});
}

/// @nodoc
class __$$QueueTaskStatusImplCopyWithImpl<$Res>
    extends _$QueueTaskStatusCopyWithImpl<$Res, _$QueueTaskStatusImpl>
    implements _$$QueueTaskStatusImplCopyWith<$Res> {
  __$$QueueTaskStatusImplCopyWithImpl(
      _$QueueTaskStatusImpl _value, $Res Function(_$QueueTaskStatusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? job = null,
    Object? state = null,
    Object? payload = null,
    Object? priority = freezed,
    Object? result = freezed,
    Object? error = freezed,
    Object? createdAt = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? workerId = freezed,
  }) {
    return _then(_$QueueTaskStatusImpl(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      job: null == job
          ? _value.job
          : job // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int?,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      workerId: freezed == workerId
          ? _value.workerId
          : workerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QueueTaskStatusImpl implements _QueueTaskStatus {
  const _$QueueTaskStatusImpl(
      {required this.taskId,
      required this.job,
      required this.state,
      required final Map<String, dynamic> payload,
      this.priority,
      this.result,
      this.error,
      this.createdAt,
      this.startedAt,
      this.completedAt,
      this.workerId})
      : _payload = payload;

  factory _$QueueTaskStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$QueueTaskStatusImplFromJson(json);

  @override
  final String taskId;
  @override
  final String job;
  @override
  final String state;
  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  final int? priority;
  @override
  final String? result;
  @override
  final String? error;
  @override
  final String? createdAt;
  @override
  final String? startedAt;
  @override
  final String? completedAt;
  @override
  final String? workerId;

  @override
  String toString() {
    return 'QueueTaskStatus(taskId: $taskId, job: $job, state: $state, payload: $payload, priority: $priority, result: $result, error: $error, createdAt: $createdAt, startedAt: $startedAt, completedAt: $completedAt, workerId: $workerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueueTaskStatusImpl &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.job, job) || other.job == job) &&
            (identical(other.state, state) || other.state == state) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      taskId,
      job,
      state,
      const DeepCollectionEquality().hash(_payload),
      priority,
      result,
      error,
      createdAt,
      startedAt,
      completedAt,
      workerId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QueueTaskStatusImplCopyWith<_$QueueTaskStatusImpl> get copyWith =>
      __$$QueueTaskStatusImplCopyWithImpl<_$QueueTaskStatusImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QueueTaskStatusImplToJson(
      this,
    );
  }
}

abstract class _QueueTaskStatus implements QueueTaskStatus {
  const factory _QueueTaskStatus(
      {required final String taskId,
      required final String job,
      required final String state,
      required final Map<String, dynamic> payload,
      final int? priority,
      final String? result,
      final String? error,
      final String? createdAt,
      final String? startedAt,
      final String? completedAt,
      final String? workerId}) = _$QueueTaskStatusImpl;

  factory _QueueTaskStatus.fromJson(Map<String, dynamic> json) =
      _$QueueTaskStatusImpl.fromJson;

  @override
  String get taskId;
  @override
  String get job;
  @override
  String get state;
  @override
  Map<String, dynamic> get payload;
  @override
  int? get priority;
  @override
  String? get result;
  @override
  String? get error;
  @override
  String? get createdAt;
  @override
  String? get startedAt;
  @override
  String? get completedAt;
  @override
  String? get workerId;
  @override
  @JsonKey(ignore: true)
  _$$QueueTaskStatusImplCopyWith<_$QueueTaskStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QueueSubmitResult _$QueueSubmitResultFromJson(Map<String, dynamic> json) {
  return _QueueSubmitResult.fromJson(json);
}

/// @nodoc
mixin _$QueueSubmitResult {
  String get taskId => throw _privateConstructorUsedError;
  Map<String, dynamic> get job => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QueueSubmitResultCopyWith<QueueSubmitResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueueSubmitResultCopyWith<$Res> {
  factory $QueueSubmitResultCopyWith(
          QueueSubmitResult value, $Res Function(QueueSubmitResult) then) =
      _$QueueSubmitResultCopyWithImpl<$Res, QueueSubmitResult>;
  @useResult
  $Res call({String taskId, Map<String, dynamic> job, String state});
}

/// @nodoc
class _$QueueSubmitResultCopyWithImpl<$Res, $Val extends QueueSubmitResult>
    implements $QueueSubmitResultCopyWith<$Res> {
  _$QueueSubmitResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? job = null,
    Object? state = null,
  }) {
    return _then(_value.copyWith(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      job: null == job
          ? _value.job
          : job // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QueueSubmitResultImplCopyWith<$Res>
    implements $QueueSubmitResultCopyWith<$Res> {
  factory _$$QueueSubmitResultImplCopyWith(_$QueueSubmitResultImpl value,
          $Res Function(_$QueueSubmitResultImpl) then) =
      __$$QueueSubmitResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String taskId, Map<String, dynamic> job, String state});
}

/// @nodoc
class __$$QueueSubmitResultImplCopyWithImpl<$Res>
    extends _$QueueSubmitResultCopyWithImpl<$Res, _$QueueSubmitResultImpl>
    implements _$$QueueSubmitResultImplCopyWith<$Res> {
  __$$QueueSubmitResultImplCopyWithImpl(_$QueueSubmitResultImpl _value,
      $Res Function(_$QueueSubmitResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? job = null,
    Object? state = null,
  }) {
    return _then(_$QueueSubmitResultImpl(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      job: null == job
          ? _value._job
          : job // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QueueSubmitResultImpl implements _QueueSubmitResult {
  const _$QueueSubmitResultImpl(
      {required this.taskId,
      required final Map<String, dynamic> job,
      required this.state})
      : _job = job;

  factory _$QueueSubmitResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$QueueSubmitResultImplFromJson(json);

  @override
  final String taskId;
  final Map<String, dynamic> _job;
  @override
  Map<String, dynamic> get job {
    if (_job is EqualUnmodifiableMapView) return _job;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_job);
  }

  @override
  final String state;

  @override
  String toString() {
    return 'QueueSubmitResult(taskId: $taskId, job: $job, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueueSubmitResultImpl &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            const DeepCollectionEquality().equals(other._job, _job) &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, taskId, const DeepCollectionEquality().hash(_job), state);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QueueSubmitResultImplCopyWith<_$QueueSubmitResultImpl> get copyWith =>
      __$$QueueSubmitResultImplCopyWithImpl<_$QueueSubmitResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QueueSubmitResultImplToJson(
      this,
    );
  }
}

abstract class _QueueSubmitResult implements QueueSubmitResult {
  const factory _QueueSubmitResult(
      {required final String taskId,
      required final Map<String, dynamic> job,
      required final String state}) = _$QueueSubmitResultImpl;

  factory _QueueSubmitResult.fromJson(Map<String, dynamic> json) =
      _$QueueSubmitResultImpl.fromJson;

  @override
  String get taskId;
  @override
  Map<String, dynamic> get job;
  @override
  String get state;
  @override
  @JsonKey(ignore: true)
  _$$QueueSubmitResultImplCopyWith<_$QueueSubmitResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MetricsSnapshot _$MetricsSnapshotFromJson(Map<String, dynamic> json) {
  return _MetricsSnapshot.fromJson(json);
}

/// @nodoc
mixin _$MetricsSnapshot {
  double get uptimeS => throw _privateConstructorUsedError;
  Map<String, dynamic> get counters => throw _privateConstructorUsedError;
  Map<String, dynamic> get latency => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MetricsSnapshotCopyWith<MetricsSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MetricsSnapshotCopyWith<$Res> {
  factory $MetricsSnapshotCopyWith(
          MetricsSnapshot value, $Res Function(MetricsSnapshot) then) =
      _$MetricsSnapshotCopyWithImpl<$Res, MetricsSnapshot>;
  @useResult
  $Res call(
      {double uptimeS,
      Map<String, dynamic> counters,
      Map<String, dynamic> latency});
}

/// @nodoc
class _$MetricsSnapshotCopyWithImpl<$Res, $Val extends MetricsSnapshot>
    implements $MetricsSnapshotCopyWith<$Res> {
  _$MetricsSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uptimeS = null,
    Object? counters = null,
    Object? latency = null,
  }) {
    return _then(_value.copyWith(
      uptimeS: null == uptimeS
          ? _value.uptimeS
          : uptimeS // ignore: cast_nullable_to_non_nullable
              as double,
      counters: null == counters
          ? _value.counters
          : counters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      latency: null == latency
          ? _value.latency
          : latency // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MetricsSnapshotImplCopyWith<$Res>
    implements $MetricsSnapshotCopyWith<$Res> {
  factory _$$MetricsSnapshotImplCopyWith(_$MetricsSnapshotImpl value,
          $Res Function(_$MetricsSnapshotImpl) then) =
      __$$MetricsSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double uptimeS,
      Map<String, dynamic> counters,
      Map<String, dynamic> latency});
}

/// @nodoc
class __$$MetricsSnapshotImplCopyWithImpl<$Res>
    extends _$MetricsSnapshotCopyWithImpl<$Res, _$MetricsSnapshotImpl>
    implements _$$MetricsSnapshotImplCopyWith<$Res> {
  __$$MetricsSnapshotImplCopyWithImpl(
      _$MetricsSnapshotImpl _value, $Res Function(_$MetricsSnapshotImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uptimeS = null,
    Object? counters = null,
    Object? latency = null,
  }) {
    return _then(_$MetricsSnapshotImpl(
      uptimeS: null == uptimeS
          ? _value.uptimeS
          : uptimeS // ignore: cast_nullable_to_non_nullable
              as double,
      counters: null == counters
          ? _value._counters
          : counters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      latency: null == latency
          ? _value._latency
          : latency // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MetricsSnapshotImpl implements _MetricsSnapshot {
  const _$MetricsSnapshotImpl(
      {required this.uptimeS,
      required final Map<String, dynamic> counters,
      required final Map<String, dynamic> latency})
      : _counters = counters,
        _latency = latency;

  factory _$MetricsSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$MetricsSnapshotImplFromJson(json);

  @override
  final double uptimeS;
  final Map<String, dynamic> _counters;
  @override
  Map<String, dynamic> get counters {
    if (_counters is EqualUnmodifiableMapView) return _counters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_counters);
  }

  final Map<String, dynamic> _latency;
  @override
  Map<String, dynamic> get latency {
    if (_latency is EqualUnmodifiableMapView) return _latency;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_latency);
  }

  @override
  String toString() {
    return 'MetricsSnapshot(uptimeS: $uptimeS, counters: $counters, latency: $latency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MetricsSnapshotImpl &&
            (identical(other.uptimeS, uptimeS) || other.uptimeS == uptimeS) &&
            const DeepCollectionEquality().equals(other._counters, _counters) &&
            const DeepCollectionEquality().equals(other._latency, _latency));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      uptimeS,
      const DeepCollectionEquality().hash(_counters),
      const DeepCollectionEquality().hash(_latency));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MetricsSnapshotImplCopyWith<_$MetricsSnapshotImpl> get copyWith =>
      __$$MetricsSnapshotImplCopyWithImpl<_$MetricsSnapshotImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MetricsSnapshotImplToJson(
      this,
    );
  }
}

abstract class _MetricsSnapshot implements MetricsSnapshot {
  const factory _MetricsSnapshot(
      {required final double uptimeS,
      required final Map<String, dynamic> counters,
      required final Map<String, dynamic> latency}) = _$MetricsSnapshotImpl;

  factory _MetricsSnapshot.fromJson(Map<String, dynamic> json) =
      _$MetricsSnapshotImpl.fromJson;

  @override
  double get uptimeS;
  @override
  Map<String, dynamic> get counters;
  @override
  Map<String, dynamic> get latency;
  @override
  @JsonKey(ignore: true)
  _$$MetricsSnapshotImplCopyWith<_$MetricsSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LatencyStats _$LatencyStatsFromJson(Map<String, dynamic> json) {
  return _LatencyStats.fromJson(json);
}

/// @nodoc
mixin _$LatencyStats {
  int get count => throw _privateConstructorUsedError;
  double get avgMs => throw _privateConstructorUsedError;
  double get p95Ms => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LatencyStatsCopyWith<LatencyStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LatencyStatsCopyWith<$Res> {
  factory $LatencyStatsCopyWith(
          LatencyStats value, $Res Function(LatencyStats) then) =
      _$LatencyStatsCopyWithImpl<$Res, LatencyStats>;
  @useResult
  $Res call({int count, double avgMs, double p95Ms});
}

/// @nodoc
class _$LatencyStatsCopyWithImpl<$Res, $Val extends LatencyStats>
    implements $LatencyStatsCopyWith<$Res> {
  _$LatencyStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? avgMs = null,
    Object? p95Ms = null,
  }) {
    return _then(_value.copyWith(
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      avgMs: null == avgMs
          ? _value.avgMs
          : avgMs // ignore: cast_nullable_to_non_nullable
              as double,
      p95Ms: null == p95Ms
          ? _value.p95Ms
          : p95Ms // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LatencyStatsImplCopyWith<$Res>
    implements $LatencyStatsCopyWith<$Res> {
  factory _$$LatencyStatsImplCopyWith(
          _$LatencyStatsImpl value, $Res Function(_$LatencyStatsImpl) then) =
      __$$LatencyStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int count, double avgMs, double p95Ms});
}

/// @nodoc
class __$$LatencyStatsImplCopyWithImpl<$Res>
    extends _$LatencyStatsCopyWithImpl<$Res, _$LatencyStatsImpl>
    implements _$$LatencyStatsImplCopyWith<$Res> {
  __$$LatencyStatsImplCopyWithImpl(
      _$LatencyStatsImpl _value, $Res Function(_$LatencyStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? avgMs = null,
    Object? p95Ms = null,
  }) {
    return _then(_$LatencyStatsImpl(
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      avgMs: null == avgMs
          ? _value.avgMs
          : avgMs // ignore: cast_nullable_to_non_nullable
              as double,
      p95Ms: null == p95Ms
          ? _value.p95Ms
          : p95Ms // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LatencyStatsImpl implements _LatencyStats {
  const _$LatencyStatsImpl(
      {required this.count, required this.avgMs, required this.p95Ms});

  factory _$LatencyStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$LatencyStatsImplFromJson(json);

  @override
  final int count;
  @override
  final double avgMs;
  @override
  final double p95Ms;

  @override
  String toString() {
    return 'LatencyStats(count: $count, avgMs: $avgMs, p95Ms: $p95Ms)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LatencyStatsImpl &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.avgMs, avgMs) || other.avgMs == avgMs) &&
            (identical(other.p95Ms, p95Ms) || other.p95Ms == p95Ms));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, count, avgMs, p95Ms);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LatencyStatsImplCopyWith<_$LatencyStatsImpl> get copyWith =>
      __$$LatencyStatsImplCopyWithImpl<_$LatencyStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LatencyStatsImplToJson(
      this,
    );
  }
}

abstract class _LatencyStats implements LatencyStats {
  const factory _LatencyStats(
      {required final int count,
      required final double avgMs,
      required final double p95Ms}) = _$LatencyStatsImpl;

  factory _LatencyStats.fromJson(Map<String, dynamic> json) =
      _$LatencyStatsImpl.fromJson;

  @override
  int get count;
  @override
  double get avgMs;
  @override
  double get p95Ms;
  @override
  @JsonKey(ignore: true)
  _$$LatencyStatsImplCopyWith<_$LatencyStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FlagsSnapshot _$FlagsSnapshotFromJson(Map<String, dynamic> json) {
  return _FlagsSnapshot.fromJson(json);
}

/// @nodoc
mixin _$FlagsSnapshot {
  Map<String, bool> get flags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FlagsSnapshotCopyWith<FlagsSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FlagsSnapshotCopyWith<$Res> {
  factory $FlagsSnapshotCopyWith(
          FlagsSnapshot value, $Res Function(FlagsSnapshot) then) =
      _$FlagsSnapshotCopyWithImpl<$Res, FlagsSnapshot>;
  @useResult
  $Res call({Map<String, bool> flags});
}

/// @nodoc
class _$FlagsSnapshotCopyWithImpl<$Res, $Val extends FlagsSnapshot>
    implements $FlagsSnapshotCopyWith<$Res> {
  _$FlagsSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flags = null,
  }) {
    return _then(_value.copyWith(
      flags: null == flags
          ? _value.flags
          : flags // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FlagsSnapshotImplCopyWith<$Res>
    implements $FlagsSnapshotCopyWith<$Res> {
  factory _$$FlagsSnapshotImplCopyWith(
          _$FlagsSnapshotImpl value, $Res Function(_$FlagsSnapshotImpl) then) =
      __$$FlagsSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, bool> flags});
}

/// @nodoc
class __$$FlagsSnapshotImplCopyWithImpl<$Res>
    extends _$FlagsSnapshotCopyWithImpl<$Res, _$FlagsSnapshotImpl>
    implements _$$FlagsSnapshotImplCopyWith<$Res> {
  __$$FlagsSnapshotImplCopyWithImpl(
      _$FlagsSnapshotImpl _value, $Res Function(_$FlagsSnapshotImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flags = null,
  }) {
    return _then(_$FlagsSnapshotImpl(
      flags: null == flags
          ? _value._flags
          : flags // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FlagsSnapshotImpl implements _FlagsSnapshot {
  const _$FlagsSnapshotImpl({required final Map<String, bool> flags})
      : _flags = flags;

  factory _$FlagsSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$FlagsSnapshotImplFromJson(json);

  final Map<String, bool> _flags;
  @override
  Map<String, bool> get flags {
    if (_flags is EqualUnmodifiableMapView) return _flags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_flags);
  }

  @override
  String toString() {
    return 'FlagsSnapshot(flags: $flags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FlagsSnapshotImpl &&
            const DeepCollectionEquality().equals(other._flags, _flags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_flags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FlagsSnapshotImplCopyWith<_$FlagsSnapshotImpl> get copyWith =>
      __$$FlagsSnapshotImplCopyWithImpl<_$FlagsSnapshotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FlagsSnapshotImplToJson(
      this,
    );
  }
}

abstract class _FlagsSnapshot implements FlagsSnapshot {
  const factory _FlagsSnapshot({required final Map<String, bool> flags}) =
      _$FlagsSnapshotImpl;

  factory _FlagsSnapshot.fromJson(Map<String, dynamic> json) =
      _$FlagsSnapshotImpl.fromJson;

  @override
  Map<String, bool> get flags;
  @override
  @JsonKey(ignore: true)
  _$$FlagsSnapshotImplCopyWith<_$FlagsSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
