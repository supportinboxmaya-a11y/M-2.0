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

MemoryItem _$MemoryItemFromJson(Map<String, dynamic> json) {
  return _MemoryItem.fromJson(json);
}

/// @nodoc
mixin _$MemoryItem {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  double? get score => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemoryItemCopyWith<MemoryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryItemCopyWith<$Res> {
  factory $MemoryItemCopyWith(
          MemoryItem value, $Res Function(MemoryItem) then) =
      _$MemoryItemCopyWithImpl<$Res, MemoryItem>;
  @useResult
  $Res call(
      {String id,
      String content,
      Map<String, dynamic>? metadata,
      String? createdAt,
      double? score});
}

/// @nodoc
class _$MemoryItemCopyWithImpl<$Res, $Val extends MemoryItem>
    implements $MemoryItemCopyWith<$Res> {
  _$MemoryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? score = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      score: freezed == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoryItemImplCopyWith<$Res>
    implements $MemoryItemCopyWith<$Res> {
  factory _$$MemoryItemImplCopyWith(
          _$MemoryItemImpl value, $Res Function(_$MemoryItemImpl) then) =
      __$$MemoryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String content,
      Map<String, dynamic>? metadata,
      String? createdAt,
      double? score});
}

/// @nodoc
class __$$MemoryItemImplCopyWithImpl<$Res>
    extends _$MemoryItemCopyWithImpl<$Res, _$MemoryItemImpl>
    implements _$$MemoryItemImplCopyWith<$Res> {
  __$$MemoryItemImplCopyWithImpl(
      _$MemoryItemImpl _value, $Res Function(_$MemoryItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? score = freezed,
  }) {
    return _then(_$MemoryItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      score: freezed == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemoryItemImpl implements _MemoryItem {
  const _$MemoryItemImpl(
      {required this.id,
      required this.content,
      final Map<String, dynamic>? metadata,
      this.createdAt,
      this.score})
      : _metadata = metadata;

  factory _$MemoryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoryItemImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
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
  final String? createdAt;
  @override
  final double? score;

  @override
  String toString() {
    return 'MemoryItem(id: $id, content: $content, metadata: $metadata, createdAt: $createdAt, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, content,
      const DeepCollectionEquality().hash(_metadata), createdAt, score);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryItemImplCopyWith<_$MemoryItemImpl> get copyWith =>
      __$$MemoryItemImplCopyWithImpl<_$MemoryItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoryItemImplToJson(
      this,
    );
  }
}

abstract class _MemoryItem implements MemoryItem {
  const factory _MemoryItem(
      {required final String id,
      required final String content,
      final Map<String, dynamic>? metadata,
      final String? createdAt,
      final double? score}) = _$MemoryItemImpl;

  factory _MemoryItem.fromJson(Map<String, dynamic> json) =
      _$MemoryItemImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  Map<String, dynamic>? get metadata;
  @override
  String? get createdAt;
  @override
  double? get score;
  @override
  @JsonKey(ignore: true)
  _$$MemoryItemImplCopyWith<_$MemoryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoryListResponse _$MemoryListResponseFromJson(Map<String, dynamic> json) {
  return _MemoryListResponse.fromJson(json);
}

/// @nodoc
mixin _$MemoryListResponse {
  List<MemoryItem> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int? get limit => throw _privateConstructorUsedError;
  int? get offset => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemoryListResponseCopyWith<MemoryListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryListResponseCopyWith<$Res> {
  factory $MemoryListResponseCopyWith(
          MemoryListResponse value, $Res Function(MemoryListResponse) then) =
      _$MemoryListResponseCopyWithImpl<$Res, MemoryListResponse>;
  @useResult
  $Res call({List<MemoryItem> items, int total, int? limit, int? offset});
}

/// @nodoc
class _$MemoryListResponseCopyWithImpl<$Res, $Val extends MemoryListResponse>
    implements $MemoryListResponseCopyWith<$Res> {
  _$MemoryListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? limit = freezed,
    Object? offset = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MemoryItem>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      limit: freezed == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
      offset: freezed == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoryListResponseImplCopyWith<$Res>
    implements $MemoryListResponseCopyWith<$Res> {
  factory _$$MemoryListResponseImplCopyWith(_$MemoryListResponseImpl value,
          $Res Function(_$MemoryListResponseImpl) then) =
      __$$MemoryListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MemoryItem> items, int total, int? limit, int? offset});
}

/// @nodoc
class __$$MemoryListResponseImplCopyWithImpl<$Res>
    extends _$MemoryListResponseCopyWithImpl<$Res, _$MemoryListResponseImpl>
    implements _$$MemoryListResponseImplCopyWith<$Res> {
  __$$MemoryListResponseImplCopyWithImpl(_$MemoryListResponseImpl _value,
      $Res Function(_$MemoryListResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? limit = freezed,
    Object? offset = freezed,
  }) {
    return _then(_$MemoryListResponseImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MemoryItem>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      limit: freezed == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
      offset: freezed == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemoryListResponseImpl implements _MemoryListResponse {
  const _$MemoryListResponseImpl(
      {required final List<MemoryItem> items,
      required this.total,
      this.limit,
      this.offset})
      : _items = items;

  factory _$MemoryListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoryListResponseImplFromJson(json);

  final List<MemoryItem> _items;
  @override
  List<MemoryItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int? limit;
  @override
  final int? offset;

  @override
  String toString() {
    return 'MemoryListResponse(items: $items, total: $total, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryListResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), total, limit, offset);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryListResponseImplCopyWith<_$MemoryListResponseImpl> get copyWith =>
      __$$MemoryListResponseImplCopyWithImpl<_$MemoryListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoryListResponseImplToJson(
      this,
    );
  }
}

abstract class _MemoryListResponse implements MemoryListResponse {
  const factory _MemoryListResponse(
      {required final List<MemoryItem> items,
      required final int total,
      final int? limit,
      final int? offset}) = _$MemoryListResponseImpl;

  factory _MemoryListResponse.fromJson(Map<String, dynamic> json) =
      _$MemoryListResponseImpl.fromJson;

  @override
  List<MemoryItem> get items;
  @override
  int get total;
  @override
  int? get limit;
  @override
  int? get offset;
  @override
  @JsonKey(ignore: true)
  _$$MemoryListResponseImplCopyWith<_$MemoryListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemorySearchResponse _$MemorySearchResponseFromJson(Map<String, dynamic> json) {
  return _MemorySearchResponse.fromJson(json);
}

/// @nodoc
mixin _$MemorySearchResponse {
  List<MemoryItem> get results => throw _privateConstructorUsedError;
  String get query => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemorySearchResponseCopyWith<MemorySearchResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemorySearchResponseCopyWith<$Res> {
  factory $MemorySearchResponseCopyWith(MemorySearchResponse value,
          $Res Function(MemorySearchResponse) then) =
      _$MemorySearchResponseCopyWithImpl<$Res, MemorySearchResponse>;
  @useResult
  $Res call({List<MemoryItem> results, String query, int count});
}

/// @nodoc
class _$MemorySearchResponseCopyWithImpl<$Res,
        $Val extends MemorySearchResponse>
    implements $MemorySearchResponseCopyWith<$Res> {
  _$MemorySearchResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? results = null,
    Object? query = null,
    Object? count = null,
  }) {
    return _then(_value.copyWith(
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<MemoryItem>,
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemorySearchResponseImplCopyWith<$Res>
    implements $MemorySearchResponseCopyWith<$Res> {
  factory _$$MemorySearchResponseImplCopyWith(_$MemorySearchResponseImpl value,
          $Res Function(_$MemorySearchResponseImpl) then) =
      __$$MemorySearchResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MemoryItem> results, String query, int count});
}

/// @nodoc
class __$$MemorySearchResponseImplCopyWithImpl<$Res>
    extends _$MemorySearchResponseCopyWithImpl<$Res, _$MemorySearchResponseImpl>
    implements _$$MemorySearchResponseImplCopyWith<$Res> {
  __$$MemorySearchResponseImplCopyWithImpl(_$MemorySearchResponseImpl _value,
      $Res Function(_$MemorySearchResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? results = null,
    Object? query = null,
    Object? count = null,
  }) {
    return _then(_$MemorySearchResponseImpl(
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<MemoryItem>,
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemorySearchResponseImpl implements _MemorySearchResponse {
  const _$MemorySearchResponseImpl(
      {required final List<MemoryItem> results,
      required this.query,
      required this.count})
      : _results = results;

  factory _$MemorySearchResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemorySearchResponseImplFromJson(json);

  final List<MemoryItem> _results;
  @override
  List<MemoryItem> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final String query;
  @override
  final int count;

  @override
  String toString() {
    return 'MemorySearchResponse(results: $results, query: $query, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemorySearchResponseImpl &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_results), query, count);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemorySearchResponseImplCopyWith<_$MemorySearchResponseImpl>
      get copyWith =>
          __$$MemorySearchResponseImplCopyWithImpl<_$MemorySearchResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemorySearchResponseImplToJson(
      this,
    );
  }
}

abstract class _MemorySearchResponse implements MemorySearchResponse {
  const factory _MemorySearchResponse(
      {required final List<MemoryItem> results,
      required final String query,
      required final int count}) = _$MemorySearchResponseImpl;

  factory _MemorySearchResponse.fromJson(Map<String, dynamic> json) =
      _$MemorySearchResponseImpl.fromJson;

  @override
  List<MemoryItem> get results;
  @override
  String get query;
  @override
  int get count;
  @override
  @JsonKey(ignore: true)
  _$$MemorySearchResponseImplCopyWith<_$MemorySearchResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MemoryCreateResponse _$MemoryCreateResponseFromJson(Map<String, dynamic> json) {
  return _MemoryCreateResponse.fromJson(json);
}

/// @nodoc
mixin _$MemoryCreateResponse {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemoryCreateResponseCopyWith<MemoryCreateResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryCreateResponseCopyWith<$Res> {
  factory $MemoryCreateResponseCopyWith(MemoryCreateResponse value,
          $Res Function(MemoryCreateResponse) then) =
      _$MemoryCreateResponseCopyWithImpl<$Res, MemoryCreateResponse>;
  @useResult
  $Res call(
      {String id,
      String content,
      Map<String, dynamic>? metadata,
      String? createdAt});
}

/// @nodoc
class _$MemoryCreateResponseCopyWithImpl<$Res,
        $Val extends MemoryCreateResponse>
    implements $MemoryCreateResponseCopyWith<$Res> {
  _$MemoryCreateResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoryCreateResponseImplCopyWith<$Res>
    implements $MemoryCreateResponseCopyWith<$Res> {
  factory _$$MemoryCreateResponseImplCopyWith(_$MemoryCreateResponseImpl value,
          $Res Function(_$MemoryCreateResponseImpl) then) =
      __$$MemoryCreateResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String content,
      Map<String, dynamic>? metadata,
      String? createdAt});
}

/// @nodoc
class __$$MemoryCreateResponseImplCopyWithImpl<$Res>
    extends _$MemoryCreateResponseCopyWithImpl<$Res, _$MemoryCreateResponseImpl>
    implements _$$MemoryCreateResponseImplCopyWith<$Res> {
  __$$MemoryCreateResponseImplCopyWithImpl(_$MemoryCreateResponseImpl _value,
      $Res Function(_$MemoryCreateResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$MemoryCreateResponseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemoryCreateResponseImpl implements _MemoryCreateResponse {
  const _$MemoryCreateResponseImpl(
      {required this.id,
      required this.content,
      final Map<String, dynamic>? metadata,
      this.createdAt})
      : _metadata = metadata;

  factory _$MemoryCreateResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoryCreateResponseImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
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
  final String? createdAt;

  @override
  String toString() {
    return 'MemoryCreateResponse(id: $id, content: $content, metadata: $metadata, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryCreateResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, content,
      const DeepCollectionEquality().hash(_metadata), createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryCreateResponseImplCopyWith<_$MemoryCreateResponseImpl>
      get copyWith =>
          __$$MemoryCreateResponseImplCopyWithImpl<_$MemoryCreateResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoryCreateResponseImplToJson(
      this,
    );
  }
}

abstract class _MemoryCreateResponse implements MemoryCreateResponse {
  const factory _MemoryCreateResponse(
      {required final String id,
      required final String content,
      final Map<String, dynamic>? metadata,
      final String? createdAt}) = _$MemoryCreateResponseImpl;

  factory _MemoryCreateResponse.fromJson(Map<String, dynamic> json) =
      _$MemoryCreateResponseImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  Map<String, dynamic>? get metadata;
  @override
  String? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$MemoryCreateResponseImplCopyWith<_$MemoryCreateResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MemoryStatsResponse _$MemoryStatsResponseFromJson(Map<String, dynamic> json) {
  return _MemoryStatsResponse.fromJson(json);
}

/// @nodoc
mixin _$MemoryStatsResponse {
  int get totalMemories => throw _privateConstructorUsedError;
  int get totalVectors => throw _privateConstructorUsedError;
  String get indexType => throw _privateConstructorUsedError;
  double get indexSizeMb => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemoryStatsResponseCopyWith<MemoryStatsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryStatsResponseCopyWith<$Res> {
  factory $MemoryStatsResponseCopyWith(
          MemoryStatsResponse value, $Res Function(MemoryStatsResponse) then) =
      _$MemoryStatsResponseCopyWithImpl<$Res, MemoryStatsResponse>;
  @useResult
  $Res call(
      {int totalMemories,
      int totalVectors,
      String indexType,
      double indexSizeMb});
}

/// @nodoc
class _$MemoryStatsResponseCopyWithImpl<$Res, $Val extends MemoryStatsResponse>
    implements $MemoryStatsResponseCopyWith<$Res> {
  _$MemoryStatsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalMemories = null,
    Object? totalVectors = null,
    Object? indexType = null,
    Object? indexSizeMb = null,
  }) {
    return _then(_value.copyWith(
      totalMemories: null == totalMemories
          ? _value.totalMemories
          : totalMemories // ignore: cast_nullable_to_non_nullable
              as int,
      totalVectors: null == totalVectors
          ? _value.totalVectors
          : totalVectors // ignore: cast_nullable_to_non_nullable
              as int,
      indexType: null == indexType
          ? _value.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as String,
      indexSizeMb: null == indexSizeMb
          ? _value.indexSizeMb
          : indexSizeMb // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoryStatsResponseImplCopyWith<$Res>
    implements $MemoryStatsResponseCopyWith<$Res> {
  factory _$$MemoryStatsResponseImplCopyWith(_$MemoryStatsResponseImpl value,
          $Res Function(_$MemoryStatsResponseImpl) then) =
      __$$MemoryStatsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalMemories,
      int totalVectors,
      String indexType,
      double indexSizeMb});
}

/// @nodoc
class __$$MemoryStatsResponseImplCopyWithImpl<$Res>
    extends _$MemoryStatsResponseCopyWithImpl<$Res, _$MemoryStatsResponseImpl>
    implements _$$MemoryStatsResponseImplCopyWith<$Res> {
  __$$MemoryStatsResponseImplCopyWithImpl(_$MemoryStatsResponseImpl _value,
      $Res Function(_$MemoryStatsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalMemories = null,
    Object? totalVectors = null,
    Object? indexType = null,
    Object? indexSizeMb = null,
  }) {
    return _then(_$MemoryStatsResponseImpl(
      totalMemories: null == totalMemories
          ? _value.totalMemories
          : totalMemories // ignore: cast_nullable_to_non_nullable
              as int,
      totalVectors: null == totalVectors
          ? _value.totalVectors
          : totalVectors // ignore: cast_nullable_to_non_nullable
              as int,
      indexType: null == indexType
          ? _value.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as String,
      indexSizeMb: null == indexSizeMb
          ? _value.indexSizeMb
          : indexSizeMb // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemoryStatsResponseImpl implements _MemoryStatsResponse {
  const _$MemoryStatsResponseImpl(
      {required this.totalMemories,
      required this.totalVectors,
      required this.indexType,
      required this.indexSizeMb});

  factory _$MemoryStatsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoryStatsResponseImplFromJson(json);

  @override
  final int totalMemories;
  @override
  final int totalVectors;
  @override
  final String indexType;
  @override
  final double indexSizeMb;

  @override
  String toString() {
    return 'MemoryStatsResponse(totalMemories: $totalMemories, totalVectors: $totalVectors, indexType: $indexType, indexSizeMb: $indexSizeMb)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryStatsResponseImpl &&
            (identical(other.totalMemories, totalMemories) ||
                other.totalMemories == totalMemories) &&
            (identical(other.totalVectors, totalVectors) ||
                other.totalVectors == totalVectors) &&
            (identical(other.indexType, indexType) ||
                other.indexType == indexType) &&
            (identical(other.indexSizeMb, indexSizeMb) ||
                other.indexSizeMb == indexSizeMb));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, totalMemories, totalVectors, indexType, indexSizeMb);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryStatsResponseImplCopyWith<_$MemoryStatsResponseImpl> get copyWith =>
      __$$MemoryStatsResponseImplCopyWithImpl<_$MemoryStatsResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoryStatsResponseImplToJson(
      this,
    );
  }
}

abstract class _MemoryStatsResponse implements MemoryStatsResponse {
  const factory _MemoryStatsResponse(
      {required final int totalMemories,
      required final int totalVectors,
      required final String indexType,
      required final double indexSizeMb}) = _$MemoryStatsResponseImpl;

  factory _MemoryStatsResponse.fromJson(Map<String, dynamic> json) =
      _$MemoryStatsResponseImpl.fromJson;

  @override
  int get totalMemories;
  @override
  int get totalVectors;
  @override
  String get indexType;
  @override
  double get indexSizeMb;
  @override
  @JsonKey(ignore: true)
  _$$MemoryStatsResponseImplCopyWith<_$MemoryStatsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolInfo _$ToolInfoFromJson(Map<String, dynamic> json) {
  return _ToolInfo.fromJson(json);
}

/// @nodoc
mixin _$ToolInfo {
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  Map<String, dynamic>? get schema => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ToolInfoCopyWith<ToolInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolInfoCopyWith<$Res> {
  factory $ToolInfoCopyWith(ToolInfo value, $Res Function(ToolInfo) then) =
      _$ToolInfoCopyWithImpl<$Res, ToolInfo>;
  @useResult
  $Res call(
      {String name,
      String description,
      String category,
      bool enabled,
      Map<String, dynamic>? schema,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$ToolInfoCopyWithImpl<$Res, $Val extends ToolInfo>
    implements $ToolInfoCopyWith<$Res> {
  _$ToolInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? category = null,
    Object? enabled = null,
    Object? schema = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      schema: freezed == schema
          ? _value.schema
          : schema // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolInfoImplCopyWith<$Res>
    implements $ToolInfoCopyWith<$Res> {
  factory _$$ToolInfoImplCopyWith(
          _$ToolInfoImpl value, $Res Function(_$ToolInfoImpl) then) =
      __$$ToolInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String description,
      String category,
      bool enabled,
      Map<String, dynamic>? schema,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$ToolInfoImplCopyWithImpl<$Res>
    extends _$ToolInfoCopyWithImpl<$Res, _$ToolInfoImpl>
    implements _$$ToolInfoImplCopyWith<$Res> {
  __$$ToolInfoImplCopyWithImpl(
      _$ToolInfoImpl _value, $Res Function(_$ToolInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? category = null,
    Object? enabled = null,
    Object? schema = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$ToolInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      schema: freezed == schema
          ? _value._schema
          : schema // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolInfoImpl implements _ToolInfo {
  const _$ToolInfoImpl(
      {required this.name,
      required this.description,
      required this.category,
      required this.enabled,
      final Map<String, dynamic>? schema,
      final Map<String, dynamic>? metadata})
      : _schema = schema,
        _metadata = metadata;

  factory _$ToolInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolInfoImplFromJson(json);

  @override
  final String name;
  @override
  final String description;
  @override
  final String category;
  @override
  final bool enabled;
  final Map<String, dynamic>? _schema;
  @override
  Map<String, dynamic>? get schema {
    final value = _schema;
    if (value == null) return null;
    if (_schema is EqualUnmodifiableMapView) return _schema;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
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
    return 'ToolInfo(name: $name, description: $description, category: $category, enabled: $enabled, schema: $schema, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            const DeepCollectionEquality().equals(other._schema, _schema) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      description,
      category,
      enabled,
      const DeepCollectionEquality().hash(_schema),
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolInfoImplCopyWith<_$ToolInfoImpl> get copyWith =>
      __$$ToolInfoImplCopyWithImpl<_$ToolInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolInfoImplToJson(
      this,
    );
  }
}

abstract class _ToolInfo implements ToolInfo {
  const factory _ToolInfo(
      {required final String name,
      required final String description,
      required final String category,
      required final bool enabled,
      final Map<String, dynamic>? schema,
      final Map<String, dynamic>? metadata}) = _$ToolInfoImpl;

  factory _ToolInfo.fromJson(Map<String, dynamic> json) =
      _$ToolInfoImpl.fromJson;

  @override
  String get name;
  @override
  String get description;
  @override
  String get category;
  @override
  bool get enabled;
  @override
  Map<String, dynamic>? get schema;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$ToolInfoImplCopyWith<_$ToolInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolsListResponse _$ToolsListResponseFromJson(Map<String, dynamic> json) {
  return _ToolsListResponse.fromJson(json);
}

/// @nodoc
mixin _$ToolsListResponse {
  List<ToolInfo> get tools => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ToolsListResponseCopyWith<ToolsListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolsListResponseCopyWith<$Res> {
  factory $ToolsListResponseCopyWith(
          ToolsListResponse value, $Res Function(ToolsListResponse) then) =
      _$ToolsListResponseCopyWithImpl<$Res, ToolsListResponse>;
  @useResult
  $Res call({List<ToolInfo> tools});
}

/// @nodoc
class _$ToolsListResponseCopyWithImpl<$Res, $Val extends ToolsListResponse>
    implements $ToolsListResponseCopyWith<$Res> {
  _$ToolsListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tools = null,
  }) {
    return _then(_value.copyWith(
      tools: null == tools
          ? _value.tools
          : tools // ignore: cast_nullable_to_non_nullable
              as List<ToolInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolsListResponseImplCopyWith<$Res>
    implements $ToolsListResponseCopyWith<$Res> {
  factory _$$ToolsListResponseImplCopyWith(_$ToolsListResponseImpl value,
          $Res Function(_$ToolsListResponseImpl) then) =
      __$$ToolsListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ToolInfo> tools});
}

/// @nodoc
class __$$ToolsListResponseImplCopyWithImpl<$Res>
    extends _$ToolsListResponseCopyWithImpl<$Res, _$ToolsListResponseImpl>
    implements _$$ToolsListResponseImplCopyWith<$Res> {
  __$$ToolsListResponseImplCopyWithImpl(_$ToolsListResponseImpl _value,
      $Res Function(_$ToolsListResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tools = null,
  }) {
    return _then(_$ToolsListResponseImpl(
      tools: null == tools
          ? _value._tools
          : tools // ignore: cast_nullable_to_non_nullable
              as List<ToolInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolsListResponseImpl implements _ToolsListResponse {
  const _$ToolsListResponseImpl({required final List<ToolInfo> tools})
      : _tools = tools;

  factory _$ToolsListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolsListResponseImplFromJson(json);

  final List<ToolInfo> _tools;
  @override
  List<ToolInfo> get tools {
    if (_tools is EqualUnmodifiableListView) return _tools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tools);
  }

  @override
  String toString() {
    return 'ToolsListResponse(tools: $tools)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolsListResponseImpl &&
            const DeepCollectionEquality().equals(other._tools, _tools));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_tools));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolsListResponseImplCopyWith<_$ToolsListResponseImpl> get copyWith =>
      __$$ToolsListResponseImplCopyWithImpl<_$ToolsListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolsListResponseImplToJson(
      this,
    );
  }
}

abstract class _ToolsListResponse implements ToolsListResponse {
  const factory _ToolsListResponse({required final List<ToolInfo> tools}) =
      _$ToolsListResponseImpl;

  factory _ToolsListResponse.fromJson(Map<String, dynamic> json) =
      _$ToolsListResponseImpl.fromJson;

  @override
  List<ToolInfo> get tools;
  @override
  @JsonKey(ignore: true)
  _$$ToolsListResponseImplCopyWith<_$ToolsListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolRunResponse _$ToolRunResponseFromJson(Map<String, dynamic> json) {
  return _ToolRunResponse.fromJson(json);
}

/// @nodoc
mixin _$ToolRunResponse {
  dynamic get result => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ToolRunResponseCopyWith<ToolRunResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolRunResponseCopyWith<$Res> {
  factory $ToolRunResponseCopyWith(
          ToolRunResponse value, $Res Function(ToolRunResponse) then) =
      _$ToolRunResponseCopyWithImpl<$Res, ToolRunResponse>;
  @useResult
  $Res call({dynamic result, String? error});
}

/// @nodoc
class _$ToolRunResponseCopyWithImpl<$Res, $Val extends ToolRunResponse>
    implements $ToolRunResponseCopyWith<$Res> {
  _$ToolRunResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? result = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as dynamic,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolRunResponseImplCopyWith<$Res>
    implements $ToolRunResponseCopyWith<$Res> {
  factory _$$ToolRunResponseImplCopyWith(_$ToolRunResponseImpl value,
          $Res Function(_$ToolRunResponseImpl) then) =
      __$$ToolRunResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({dynamic result, String? error});
}

/// @nodoc
class __$$ToolRunResponseImplCopyWithImpl<$Res>
    extends _$ToolRunResponseCopyWithImpl<$Res, _$ToolRunResponseImpl>
    implements _$$ToolRunResponseImplCopyWith<$Res> {
  __$$ToolRunResponseImplCopyWithImpl(
      _$ToolRunResponseImpl _value, $Res Function(_$ToolRunResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? result = freezed,
    Object? error = freezed,
  }) {
    return _then(_$ToolRunResponseImpl(
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as dynamic,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolRunResponseImpl implements _ToolRunResponse {
  const _$ToolRunResponseImpl({required this.result, this.error});

  factory _$ToolRunResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolRunResponseImplFromJson(json);

  @override
  final dynamic result;
  @override
  final String? error;

  @override
  String toString() {
    return 'ToolRunResponse(result: $result, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolRunResponseImpl &&
            const DeepCollectionEquality().equals(other.result, result) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(result), error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolRunResponseImplCopyWith<_$ToolRunResponseImpl> get copyWith =>
      __$$ToolRunResponseImplCopyWithImpl<_$ToolRunResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolRunResponseImplToJson(
      this,
    );
  }
}

abstract class _ToolRunResponse implements ToolRunResponse {
  const factory _ToolRunResponse(
      {required final dynamic result,
      final String? error}) = _$ToolRunResponseImpl;

  factory _ToolRunResponse.fromJson(Map<String, dynamic> json) =
      _$ToolRunResponseImpl.fromJson;

  @override
  dynamic get result;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$ToolRunResponseImplCopyWith<_$ToolRunResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolLogEntry _$ToolLogEntryFromJson(Map<String, dynamic> json) {
  return _ToolLogEntry.fromJson(json);
}

/// @nodoc
mixin _$ToolLogEntry {
  String get tool => throw _privateConstructorUsedError;
  int get calls => throw _privateConstructorUsedError;
  int get successes => throw _privateConstructorUsedError;
  int get failures => throw _privateConstructorUsedError;
  double get avgTime => throw _privateConstructorUsedError;
  String? get lastError => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ToolLogEntryCopyWith<ToolLogEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolLogEntryCopyWith<$Res> {
  factory $ToolLogEntryCopyWith(
          ToolLogEntry value, $Res Function(ToolLogEntry) then) =
      _$ToolLogEntryCopyWithImpl<$Res, ToolLogEntry>;
  @useResult
  $Res call(
      {String tool,
      int calls,
      int successes,
      int failures,
      double avgTime,
      String? lastError});
}

/// @nodoc
class _$ToolLogEntryCopyWithImpl<$Res, $Val extends ToolLogEntry>
    implements $ToolLogEntryCopyWith<$Res> {
  _$ToolLogEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tool = null,
    Object? calls = null,
    Object? successes = null,
    Object? failures = null,
    Object? avgTime = null,
    Object? lastError = freezed,
  }) {
    return _then(_value.copyWith(
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String,
      calls: null == calls
          ? _value.calls
          : calls // ignore: cast_nullable_to_non_nullable
              as int,
      successes: null == successes
          ? _value.successes
          : successes // ignore: cast_nullable_to_non_nullable
              as int,
      failures: null == failures
          ? _value.failures
          : failures // ignore: cast_nullable_to_non_nullable
              as int,
      avgTime: null == avgTime
          ? _value.avgTime
          : avgTime // ignore: cast_nullable_to_non_nullable
              as double,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolLogEntryImplCopyWith<$Res>
    implements $ToolLogEntryCopyWith<$Res> {
  factory _$$ToolLogEntryImplCopyWith(
          _$ToolLogEntryImpl value, $Res Function(_$ToolLogEntryImpl) then) =
      __$$ToolLogEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tool,
      int calls,
      int successes,
      int failures,
      double avgTime,
      String? lastError});
}

/// @nodoc
class __$$ToolLogEntryImplCopyWithImpl<$Res>
    extends _$ToolLogEntryCopyWithImpl<$Res, _$ToolLogEntryImpl>
    implements _$$ToolLogEntryImplCopyWith<$Res> {
  __$$ToolLogEntryImplCopyWithImpl(
      _$ToolLogEntryImpl _value, $Res Function(_$ToolLogEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tool = null,
    Object? calls = null,
    Object? successes = null,
    Object? failures = null,
    Object? avgTime = null,
    Object? lastError = freezed,
  }) {
    return _then(_$ToolLogEntryImpl(
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String,
      calls: null == calls
          ? _value.calls
          : calls // ignore: cast_nullable_to_non_nullable
              as int,
      successes: null == successes
          ? _value.successes
          : successes // ignore: cast_nullable_to_non_nullable
              as int,
      failures: null == failures
          ? _value.failures
          : failures // ignore: cast_nullable_to_non_nullable
              as int,
      avgTime: null == avgTime
          ? _value.avgTime
          : avgTime // ignore: cast_nullable_to_non_nullable
              as double,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolLogEntryImpl implements _ToolLogEntry {
  const _$ToolLogEntryImpl(
      {required this.tool,
      required this.calls,
      required this.successes,
      required this.failures,
      required this.avgTime,
      this.lastError});

  factory _$ToolLogEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolLogEntryImplFromJson(json);

  @override
  final String tool;
  @override
  final int calls;
  @override
  final int successes;
  @override
  final int failures;
  @override
  final double avgTime;
  @override
  final String? lastError;

  @override
  String toString() {
    return 'ToolLogEntry(tool: $tool, calls: $calls, successes: $successes, failures: $failures, avgTime: $avgTime, lastError: $lastError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolLogEntryImpl &&
            (identical(other.tool, tool) || other.tool == tool) &&
            (identical(other.calls, calls) || other.calls == calls) &&
            (identical(other.successes, successes) ||
                other.successes == successes) &&
            (identical(other.failures, failures) ||
                other.failures == failures) &&
            (identical(other.avgTime, avgTime) || other.avgTime == avgTime) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, tool, calls, successes, failures, avgTime, lastError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolLogEntryImplCopyWith<_$ToolLogEntryImpl> get copyWith =>
      __$$ToolLogEntryImplCopyWithImpl<_$ToolLogEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolLogEntryImplToJson(
      this,
    );
  }
}

abstract class _ToolLogEntry implements ToolLogEntry {
  const factory _ToolLogEntry(
      {required final String tool,
      required final int calls,
      required final int successes,
      required final int failures,
      required final double avgTime,
      final String? lastError}) = _$ToolLogEntryImpl;

  factory _ToolLogEntry.fromJson(Map<String, dynamic> json) =
      _$ToolLogEntryImpl.fromJson;

  @override
  String get tool;
  @override
  int get calls;
  @override
  int get successes;
  @override
  int get failures;
  @override
  double get avgTime;
  @override
  String? get lastError;
  @override
  @JsonKey(ignore: true)
  _$$ToolLogEntryImplCopyWith<_$ToolLogEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolsLogsResponse _$ToolsLogsResponseFromJson(Map<String, dynamic> json) {
  return _ToolsLogsResponse.fromJson(json);
}

/// @nodoc
mixin _$ToolsLogsResponse {
  List<ToolLogEntry> get logs => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ToolsLogsResponseCopyWith<ToolsLogsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolsLogsResponseCopyWith<$Res> {
  factory $ToolsLogsResponseCopyWith(
          ToolsLogsResponse value, $Res Function(ToolsLogsResponse) then) =
      _$ToolsLogsResponseCopyWithImpl<$Res, ToolsLogsResponse>;
  @useResult
  $Res call({List<ToolLogEntry> logs});
}

/// @nodoc
class _$ToolsLogsResponseCopyWithImpl<$Res, $Val extends ToolsLogsResponse>
    implements $ToolsLogsResponseCopyWith<$Res> {
  _$ToolsLogsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? logs = null,
  }) {
    return _then(_value.copyWith(
      logs: null == logs
          ? _value.logs
          : logs // ignore: cast_nullable_to_non_nullable
              as List<ToolLogEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolsLogsResponseImplCopyWith<$Res>
    implements $ToolsLogsResponseCopyWith<$Res> {
  factory _$$ToolsLogsResponseImplCopyWith(_$ToolsLogsResponseImpl value,
          $Res Function(_$ToolsLogsResponseImpl) then) =
      __$$ToolsLogsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ToolLogEntry> logs});
}

/// @nodoc
class __$$ToolsLogsResponseImplCopyWithImpl<$Res>
    extends _$ToolsLogsResponseCopyWithImpl<$Res, _$ToolsLogsResponseImpl>
    implements _$$ToolsLogsResponseImplCopyWith<$Res> {
  __$$ToolsLogsResponseImplCopyWithImpl(_$ToolsLogsResponseImpl _value,
      $Res Function(_$ToolsLogsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? logs = null,
  }) {
    return _then(_$ToolsLogsResponseImpl(
      logs: null == logs
          ? _value._logs
          : logs // ignore: cast_nullable_to_non_nullable
              as List<ToolLogEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolsLogsResponseImpl implements _ToolsLogsResponse {
  const _$ToolsLogsResponseImpl({required final List<ToolLogEntry> logs})
      : _logs = logs;

  factory _$ToolsLogsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolsLogsResponseImplFromJson(json);

  final List<ToolLogEntry> _logs;
  @override
  List<ToolLogEntry> get logs {
    if (_logs is EqualUnmodifiableListView) return _logs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_logs);
  }

  @override
  String toString() {
    return 'ToolsLogsResponse(logs: $logs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolsLogsResponseImpl &&
            const DeepCollectionEquality().equals(other._logs, _logs));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_logs));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolsLogsResponseImplCopyWith<_$ToolsLogsResponseImpl> get copyWith =>
      __$$ToolsLogsResponseImplCopyWithImpl<_$ToolsLogsResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolsLogsResponseImplToJson(
      this,
    );
  }
}

abstract class _ToolsLogsResponse implements ToolsLogsResponse {
  const factory _ToolsLogsResponse({required final List<ToolLogEntry> logs}) =
      _$ToolsLogsResponseImpl;

  factory _ToolsLogsResponse.fromJson(Map<String, dynamic> json) =
      _$ToolsLogsResponseImpl.fromJson;

  @override
  List<ToolLogEntry> get logs;
  @override
  @JsonKey(ignore: true)
  _$$ToolsLogsResponseImplCopyWith<_$ToolsLogsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FrameworkTool _$FrameworkToolFromJson(Map<String, dynamic> json) {
  return _FrameworkTool.fromJson(json);
}

/// @nodoc
mixin _$FrameworkTool {
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  String get permission => throw _privateConstructorUsedError;
  int get timeoutSeconds => throw _privateConstructorUsedError;
  int get maxRetries => throw _privateConstructorUsedError;
  bool get dangerous => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FrameworkToolCopyWith<FrameworkTool> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FrameworkToolCopyWith<$Res> {
  factory $FrameworkToolCopyWith(
          FrameworkTool value, $Res Function(FrameworkTool) then) =
      _$FrameworkToolCopyWithImpl<$Res, FrameworkTool>;
  @useResult
  $Res call(
      {String name,
      String description,
      String category,
      bool enabled,
      String permission,
      int timeoutSeconds,
      int maxRetries,
      bool dangerous});
}

/// @nodoc
class _$FrameworkToolCopyWithImpl<$Res, $Val extends FrameworkTool>
    implements $FrameworkToolCopyWith<$Res> {
  _$FrameworkToolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? category = null,
    Object? enabled = null,
    Object? permission = null,
    Object? timeoutSeconds = null,
    Object? maxRetries = null,
    Object? dangerous = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      permission: null == permission
          ? _value.permission
          : permission // ignore: cast_nullable_to_non_nullable
              as String,
      timeoutSeconds: null == timeoutSeconds
          ? _value.timeoutSeconds
          : timeoutSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      maxRetries: null == maxRetries
          ? _value.maxRetries
          : maxRetries // ignore: cast_nullable_to_non_nullable
              as int,
      dangerous: null == dangerous
          ? _value.dangerous
          : dangerous // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FrameworkToolImplCopyWith<$Res>
    implements $FrameworkToolCopyWith<$Res> {
  factory _$$FrameworkToolImplCopyWith(
          _$FrameworkToolImpl value, $Res Function(_$FrameworkToolImpl) then) =
      __$$FrameworkToolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String description,
      String category,
      bool enabled,
      String permission,
      int timeoutSeconds,
      int maxRetries,
      bool dangerous});
}

/// @nodoc
class __$$FrameworkToolImplCopyWithImpl<$Res>
    extends _$FrameworkToolCopyWithImpl<$Res, _$FrameworkToolImpl>
    implements _$$FrameworkToolImplCopyWith<$Res> {
  __$$FrameworkToolImplCopyWithImpl(
      _$FrameworkToolImpl _value, $Res Function(_$FrameworkToolImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? category = null,
    Object? enabled = null,
    Object? permission = null,
    Object? timeoutSeconds = null,
    Object? maxRetries = null,
    Object? dangerous = null,
  }) {
    return _then(_$FrameworkToolImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      permission: null == permission
          ? _value.permission
          : permission // ignore: cast_nullable_to_non_nullable
              as String,
      timeoutSeconds: null == timeoutSeconds
          ? _value.timeoutSeconds
          : timeoutSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      maxRetries: null == maxRetries
          ? _value.maxRetries
          : maxRetries // ignore: cast_nullable_to_non_nullable
              as int,
      dangerous: null == dangerous
          ? _value.dangerous
          : dangerous // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FrameworkToolImpl implements _FrameworkTool {
  const _$FrameworkToolImpl(
      {required this.name,
      required this.description,
      required this.category,
      required this.enabled,
      required this.permission,
      required this.timeoutSeconds,
      required this.maxRetries,
      required this.dangerous});

  factory _$FrameworkToolImpl.fromJson(Map<String, dynamic> json) =>
      _$$FrameworkToolImplFromJson(json);

  @override
  final String name;
  @override
  final String description;
  @override
  final String category;
  @override
  final bool enabled;
  @override
  final String permission;
  @override
  final int timeoutSeconds;
  @override
  final int maxRetries;
  @override
  final bool dangerous;

  @override
  String toString() {
    return 'FrameworkTool(name: $name, description: $description, category: $category, enabled: $enabled, permission: $permission, timeoutSeconds: $timeoutSeconds, maxRetries: $maxRetries, dangerous: $dangerous)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FrameworkToolImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.permission, permission) ||
                other.permission == permission) &&
            (identical(other.timeoutSeconds, timeoutSeconds) ||
                other.timeoutSeconds == timeoutSeconds) &&
            (identical(other.maxRetries, maxRetries) ||
                other.maxRetries == maxRetries) &&
            (identical(other.dangerous, dangerous) ||
                other.dangerous == dangerous));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, description, category,
      enabled, permission, timeoutSeconds, maxRetries, dangerous);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FrameworkToolImplCopyWith<_$FrameworkToolImpl> get copyWith =>
      __$$FrameworkToolImplCopyWithImpl<_$FrameworkToolImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FrameworkToolImplToJson(
      this,
    );
  }
}

abstract class _FrameworkTool implements FrameworkTool {
  const factory _FrameworkTool(
      {required final String name,
      required final String description,
      required final String category,
      required final bool enabled,
      required final String permission,
      required final int timeoutSeconds,
      required final int maxRetries,
      required final bool dangerous}) = _$FrameworkToolImpl;

  factory _FrameworkTool.fromJson(Map<String, dynamic> json) =
      _$FrameworkToolImpl.fromJson;

  @override
  String get name;
  @override
  String get description;
  @override
  String get category;
  @override
  bool get enabled;
  @override
  String get permission;
  @override
  int get timeoutSeconds;
  @override
  int get maxRetries;
  @override
  bool get dangerous;
  @override
  @JsonKey(ignore: true)
  _$$FrameworkToolImplCopyWith<_$FrameworkToolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolsFrameworkResponse _$ToolsFrameworkResponseFromJson(
    Map<String, dynamic> json) {
  return _ToolsFrameworkResponse.fromJson(json);
}

/// @nodoc
mixin _$ToolsFrameworkResponse {
  List<FrameworkTool> get tools => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ToolsFrameworkResponseCopyWith<ToolsFrameworkResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolsFrameworkResponseCopyWith<$Res> {
  factory $ToolsFrameworkResponseCopyWith(ToolsFrameworkResponse value,
          $Res Function(ToolsFrameworkResponse) then) =
      _$ToolsFrameworkResponseCopyWithImpl<$Res, ToolsFrameworkResponse>;
  @useResult
  $Res call({List<FrameworkTool> tools});
}

/// @nodoc
class _$ToolsFrameworkResponseCopyWithImpl<$Res,
        $Val extends ToolsFrameworkResponse>
    implements $ToolsFrameworkResponseCopyWith<$Res> {
  _$ToolsFrameworkResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tools = null,
  }) {
    return _then(_value.copyWith(
      tools: null == tools
          ? _value.tools
          : tools // ignore: cast_nullable_to_non_nullable
              as List<FrameworkTool>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolsFrameworkResponseImplCopyWith<$Res>
    implements $ToolsFrameworkResponseCopyWith<$Res> {
  factory _$$ToolsFrameworkResponseImplCopyWith(
          _$ToolsFrameworkResponseImpl value,
          $Res Function(_$ToolsFrameworkResponseImpl) then) =
      __$$ToolsFrameworkResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<FrameworkTool> tools});
}

/// @nodoc
class __$$ToolsFrameworkResponseImplCopyWithImpl<$Res>
    extends _$ToolsFrameworkResponseCopyWithImpl<$Res,
        _$ToolsFrameworkResponseImpl>
    implements _$$ToolsFrameworkResponseImplCopyWith<$Res> {
  __$$ToolsFrameworkResponseImplCopyWithImpl(
      _$ToolsFrameworkResponseImpl _value,
      $Res Function(_$ToolsFrameworkResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tools = null,
  }) {
    return _then(_$ToolsFrameworkResponseImpl(
      tools: null == tools
          ? _value._tools
          : tools // ignore: cast_nullable_to_non_nullable
              as List<FrameworkTool>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolsFrameworkResponseImpl implements _ToolsFrameworkResponse {
  const _$ToolsFrameworkResponseImpl({required final List<FrameworkTool> tools})
      : _tools = tools;

  factory _$ToolsFrameworkResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolsFrameworkResponseImplFromJson(json);

  final List<FrameworkTool> _tools;
  @override
  List<FrameworkTool> get tools {
    if (_tools is EqualUnmodifiableListView) return _tools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tools);
  }

  @override
  String toString() {
    return 'ToolsFrameworkResponse(tools: $tools)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolsFrameworkResponseImpl &&
            const DeepCollectionEquality().equals(other._tools, _tools));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_tools));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolsFrameworkResponseImplCopyWith<_$ToolsFrameworkResponseImpl>
      get copyWith => __$$ToolsFrameworkResponseImplCopyWithImpl<
          _$ToolsFrameworkResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolsFrameworkResponseImplToJson(
      this,
    );
  }
}

abstract class _ToolsFrameworkResponse implements ToolsFrameworkResponse {
  const factory _ToolsFrameworkResponse(
          {required final List<FrameworkTool> tools}) =
      _$ToolsFrameworkResponseImpl;

  factory _ToolsFrameworkResponse.fromJson(Map<String, dynamic> json) =
      _$ToolsFrameworkResponseImpl.fromJson;

  @override
  List<FrameworkTool> get tools;
  @override
  @JsonKey(ignore: true)
  _$$ToolsFrameworkResponseImplCopyWith<_$ToolsFrameworkResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProviderInfo _$ProviderInfoFromJson(Map<String, dynamic> json) {
  return _ProviderInfo.fromJson(json);
}

/// @nodoc
mixin _$ProviderInfo {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  bool get configured => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  int get errorCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProviderInfoCopyWith<ProviderInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProviderInfoCopyWith<$Res> {
  factory $ProviderInfoCopyWith(
          ProviderInfo value, $Res Function(ProviderInfo) then) =
      _$ProviderInfoCopyWithImpl<$Res, ProviderInfo>;
  @useResult
  $Res call(
      {String id,
      String label,
      bool configured,
      bool enabled,
      bool active,
      int errorCount});
}

/// @nodoc
class _$ProviderInfoCopyWithImpl<$Res, $Val extends ProviderInfo>
    implements $ProviderInfoCopyWith<$Res> {
  _$ProviderInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? configured = null,
    Object? enabled = null,
    Object? active = null,
    Object? errorCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      configured: null == configured
          ? _value.configured
          : configured // ignore: cast_nullable_to_non_nullable
              as bool,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      errorCount: null == errorCount
          ? _value.errorCount
          : errorCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProviderInfoImplCopyWith<$Res>
    implements $ProviderInfoCopyWith<$Res> {
  factory _$$ProviderInfoImplCopyWith(
          _$ProviderInfoImpl value, $Res Function(_$ProviderInfoImpl) then) =
      __$$ProviderInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      bool configured,
      bool enabled,
      bool active,
      int errorCount});
}

/// @nodoc
class __$$ProviderInfoImplCopyWithImpl<$Res>
    extends _$ProviderInfoCopyWithImpl<$Res, _$ProviderInfoImpl>
    implements _$$ProviderInfoImplCopyWith<$Res> {
  __$$ProviderInfoImplCopyWithImpl(
      _$ProviderInfoImpl _value, $Res Function(_$ProviderInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? configured = null,
    Object? enabled = null,
    Object? active = null,
    Object? errorCount = null,
  }) {
    return _then(_$ProviderInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      configured: null == configured
          ? _value.configured
          : configured // ignore: cast_nullable_to_non_nullable
              as bool,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      errorCount: null == errorCount
          ? _value.errorCount
          : errorCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProviderInfoImpl implements _ProviderInfo {
  const _$ProviderInfoImpl(
      {required this.id,
      required this.label,
      required this.configured,
      required this.enabled,
      required this.active,
      required this.errorCount});

  factory _$ProviderInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProviderInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final bool configured;
  @override
  final bool enabled;
  @override
  final bool active;
  @override
  final int errorCount;

  @override
  String toString() {
    return 'ProviderInfo(id: $id, label: $label, configured: $configured, enabled: $enabled, active: $active, errorCount: $errorCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProviderInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.configured, configured) ||
                other.configured == configured) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, label, configured, enabled, active, errorCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProviderInfoImplCopyWith<_$ProviderInfoImpl> get copyWith =>
      __$$ProviderInfoImplCopyWithImpl<_$ProviderInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProviderInfoImplToJson(
      this,
    );
  }
}

abstract class _ProviderInfo implements ProviderInfo {
  const factory _ProviderInfo(
      {required final String id,
      required final String label,
      required final bool configured,
      required final bool enabled,
      required final bool active,
      required final int errorCount}) = _$ProviderInfoImpl;

  factory _ProviderInfo.fromJson(Map<String, dynamic> json) =
      _$ProviderInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  bool get configured;
  @override
  bool get enabled;
  @override
  bool get active;
  @override
  int get errorCount;
  @override
  @JsonKey(ignore: true)
  _$$ProviderInfoImplCopyWith<_$ProviderInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProvidersListResponse _$ProvidersListResponseFromJson(
    Map<String, dynamic> json) {
  return _ProvidersListResponse.fromJson(json);
}

/// @nodoc
mixin _$ProvidersListResponse {
  List<ProviderInfo> get providers => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProvidersListResponseCopyWith<ProvidersListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProvidersListResponseCopyWith<$Res> {
  factory $ProvidersListResponseCopyWith(ProvidersListResponse value,
          $Res Function(ProvidersListResponse) then) =
      _$ProvidersListResponseCopyWithImpl<$Res, ProvidersListResponse>;
  @useResult
  $Res call({List<ProviderInfo> providers});
}

/// @nodoc
class _$ProvidersListResponseCopyWithImpl<$Res,
        $Val extends ProvidersListResponse>
    implements $ProvidersListResponseCopyWith<$Res> {
  _$ProvidersListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? providers = null,
  }) {
    return _then(_value.copyWith(
      providers: null == providers
          ? _value.providers
          : providers // ignore: cast_nullable_to_non_nullable
              as List<ProviderInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProvidersListResponseImplCopyWith<$Res>
    implements $ProvidersListResponseCopyWith<$Res> {
  factory _$$ProvidersListResponseImplCopyWith(
          _$ProvidersListResponseImpl value,
          $Res Function(_$ProvidersListResponseImpl) then) =
      __$$ProvidersListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ProviderInfo> providers});
}

/// @nodoc
class __$$ProvidersListResponseImplCopyWithImpl<$Res>
    extends _$ProvidersListResponseCopyWithImpl<$Res,
        _$ProvidersListResponseImpl>
    implements _$$ProvidersListResponseImplCopyWith<$Res> {
  __$$ProvidersListResponseImplCopyWithImpl(_$ProvidersListResponseImpl _value,
      $Res Function(_$ProvidersListResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? providers = null,
  }) {
    return _then(_$ProvidersListResponseImpl(
      providers: null == providers
          ? _value._providers
          : providers // ignore: cast_nullable_to_non_nullable
              as List<ProviderInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProvidersListResponseImpl implements _ProvidersListResponse {
  const _$ProvidersListResponseImpl(
      {required final List<ProviderInfo> providers})
      : _providers = providers;

  factory _$ProvidersListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProvidersListResponseImplFromJson(json);

  final List<ProviderInfo> _providers;
  @override
  List<ProviderInfo> get providers {
    if (_providers is EqualUnmodifiableListView) return _providers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_providers);
  }

  @override
  String toString() {
    return 'ProvidersListResponse(providers: $providers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProvidersListResponseImpl &&
            const DeepCollectionEquality()
                .equals(other._providers, _providers));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_providers));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProvidersListResponseImplCopyWith<_$ProvidersListResponseImpl>
      get copyWith => __$$ProvidersListResponseImplCopyWithImpl<
          _$ProvidersListResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProvidersListResponseImplToJson(
      this,
    );
  }
}

abstract class _ProvidersListResponse implements ProvidersListResponse {
  const factory _ProvidersListResponse(
          {required final List<ProviderInfo> providers}) =
      _$ProvidersListResponseImpl;

  factory _ProvidersListResponse.fromJson(Map<String, dynamic> json) =
      _$ProvidersListResponseImpl.fromJson;

  @override
  List<ProviderInfo> get providers;
  @override
  @JsonKey(ignore: true)
  _$$ProvidersListResponseImplCopyWith<_$ProvidersListResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

BrainAnalyzeResponse _$BrainAnalyzeResponseFromJson(Map<String, dynamic> json) {
  return _BrainAnalyzeResponse.fromJson(json);
}

/// @nodoc
mixin _$BrainAnalyzeResponse {
  String get goal => throw _privateConstructorUsedError;
  String get complexity => throw _privateConstructorUsedError;
  int get estimatedSteps => throw _privateConstructorUsedError;
  List<String> get suggestedTools => throw _privateConstructorUsedError;
  List<String> get subGoals => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BrainAnalyzeResponseCopyWith<BrainAnalyzeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BrainAnalyzeResponseCopyWith<$Res> {
  factory $BrainAnalyzeResponseCopyWith(BrainAnalyzeResponse value,
          $Res Function(BrainAnalyzeResponse) then) =
      _$BrainAnalyzeResponseCopyWithImpl<$Res, BrainAnalyzeResponse>;
  @useResult
  $Res call(
      {String goal,
      String complexity,
      int estimatedSteps,
      List<String> suggestedTools,
      List<String> subGoals});
}

/// @nodoc
class _$BrainAnalyzeResponseCopyWithImpl<$Res,
        $Val extends BrainAnalyzeResponse>
    implements $BrainAnalyzeResponseCopyWith<$Res> {
  _$BrainAnalyzeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? goal = null,
    Object? complexity = null,
    Object? estimatedSteps = null,
    Object? suggestedTools = null,
    Object? subGoals = null,
  }) {
    return _then(_value.copyWith(
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      complexity: null == complexity
          ? _value.complexity
          : complexity // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedSteps: null == estimatedSteps
          ? _value.estimatedSteps
          : estimatedSteps // ignore: cast_nullable_to_non_nullable
              as int,
      suggestedTools: null == suggestedTools
          ? _value.suggestedTools
          : suggestedTools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subGoals: null == subGoals
          ? _value.subGoals
          : subGoals // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BrainAnalyzeResponseImplCopyWith<$Res>
    implements $BrainAnalyzeResponseCopyWith<$Res> {
  factory _$$BrainAnalyzeResponseImplCopyWith(_$BrainAnalyzeResponseImpl value,
          $Res Function(_$BrainAnalyzeResponseImpl) then) =
      __$$BrainAnalyzeResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String goal,
      String complexity,
      int estimatedSteps,
      List<String> suggestedTools,
      List<String> subGoals});
}

/// @nodoc
class __$$BrainAnalyzeResponseImplCopyWithImpl<$Res>
    extends _$BrainAnalyzeResponseCopyWithImpl<$Res, _$BrainAnalyzeResponseImpl>
    implements _$$BrainAnalyzeResponseImplCopyWith<$Res> {
  __$$BrainAnalyzeResponseImplCopyWithImpl(_$BrainAnalyzeResponseImpl _value,
      $Res Function(_$BrainAnalyzeResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? goal = null,
    Object? complexity = null,
    Object? estimatedSteps = null,
    Object? suggestedTools = null,
    Object? subGoals = null,
  }) {
    return _then(_$BrainAnalyzeResponseImpl(
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      complexity: null == complexity
          ? _value.complexity
          : complexity // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedSteps: null == estimatedSteps
          ? _value.estimatedSteps
          : estimatedSteps // ignore: cast_nullable_to_non_nullable
              as int,
      suggestedTools: null == suggestedTools
          ? _value._suggestedTools
          : suggestedTools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subGoals: null == subGoals
          ? _value._subGoals
          : subGoals // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BrainAnalyzeResponseImpl implements _BrainAnalyzeResponse {
  const _$BrainAnalyzeResponseImpl(
      {required this.goal,
      required this.complexity,
      required this.estimatedSteps,
      required final List<String> suggestedTools,
      required final List<String> subGoals})
      : _suggestedTools = suggestedTools,
        _subGoals = subGoals;

  factory _$BrainAnalyzeResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BrainAnalyzeResponseImplFromJson(json);

  @override
  final String goal;
  @override
  final String complexity;
  @override
  final int estimatedSteps;
  final List<String> _suggestedTools;
  @override
  List<String> get suggestedTools {
    if (_suggestedTools is EqualUnmodifiableListView) return _suggestedTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_suggestedTools);
  }

  final List<String> _subGoals;
  @override
  List<String> get subGoals {
    if (_subGoals is EqualUnmodifiableListView) return _subGoals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subGoals);
  }

  @override
  String toString() {
    return 'BrainAnalyzeResponse(goal: $goal, complexity: $complexity, estimatedSteps: $estimatedSteps, suggestedTools: $suggestedTools, subGoals: $subGoals)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BrainAnalyzeResponseImpl &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.complexity, complexity) ||
                other.complexity == complexity) &&
            (identical(other.estimatedSteps, estimatedSteps) ||
                other.estimatedSteps == estimatedSteps) &&
            const DeepCollectionEquality()
                .equals(other._suggestedTools, _suggestedTools) &&
            const DeepCollectionEquality().equals(other._subGoals, _subGoals));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      goal,
      complexity,
      estimatedSteps,
      const DeepCollectionEquality().hash(_suggestedTools),
      const DeepCollectionEquality().hash(_subGoals));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BrainAnalyzeResponseImplCopyWith<_$BrainAnalyzeResponseImpl>
      get copyWith =>
          __$$BrainAnalyzeResponseImplCopyWithImpl<_$BrainAnalyzeResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BrainAnalyzeResponseImplToJson(
      this,
    );
  }
}

abstract class _BrainAnalyzeResponse implements BrainAnalyzeResponse {
  const factory _BrainAnalyzeResponse(
      {required final String goal,
      required final String complexity,
      required final int estimatedSteps,
      required final List<String> suggestedTools,
      required final List<String> subGoals}) = _$BrainAnalyzeResponseImpl;

  factory _BrainAnalyzeResponse.fromJson(Map<String, dynamic> json) =
      _$BrainAnalyzeResponseImpl.fromJson;

  @override
  String get goal;
  @override
  String get complexity;
  @override
  int get estimatedSteps;
  @override
  List<String> get suggestedTools;
  @override
  List<String> get subGoals;
  @override
  @JsonKey(ignore: true)
  _$$BrainAnalyzeResponseImplCopyWith<_$BrainAnalyzeResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

GraphNode _$GraphNodeFromJson(Map<String, dynamic> json) {
  return _GraphNode.fromJson(json);
}

/// @nodoc
mixin _$GraphNode {
  String get id => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get tool => throw _privateConstructorUsedError;
  String? get agent => throw _privateConstructorUsedError;
  List<String> get dependsOn => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  int get attempts => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GraphNodeCopyWith<GraphNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GraphNodeCopyWith<$Res> {
  factory $GraphNodeCopyWith(GraphNode value, $Res Function(GraphNode) then) =
      _$GraphNodeCopyWithImpl<$Res, GraphNode>;
  @useResult
  $Res call(
      {String id,
      String description,
      String? tool,
      String? agent,
      List<String> dependsOn,
      String state,
      int attempts,
      String? error});
}

/// @nodoc
class _$GraphNodeCopyWithImpl<$Res, $Val extends GraphNode>
    implements $GraphNodeCopyWith<$Res> {
  _$GraphNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? tool = freezed,
    Object? agent = freezed,
    Object? dependsOn = null,
    Object? state = null,
    Object? attempts = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
      agent: freezed == agent
          ? _value.agent
          : agent // ignore: cast_nullable_to_non_nullable
              as String?,
      dependsOn: null == dependsOn
          ? _value.dependsOn
          : dependsOn // ignore: cast_nullable_to_non_nullable
              as List<String>,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      attempts: null == attempts
          ? _value.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GraphNodeImplCopyWith<$Res>
    implements $GraphNodeCopyWith<$Res> {
  factory _$$GraphNodeImplCopyWith(
          _$GraphNodeImpl value, $Res Function(_$GraphNodeImpl) then) =
      __$$GraphNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String description,
      String? tool,
      String? agent,
      List<String> dependsOn,
      String state,
      int attempts,
      String? error});
}

/// @nodoc
class __$$GraphNodeImplCopyWithImpl<$Res>
    extends _$GraphNodeCopyWithImpl<$Res, _$GraphNodeImpl>
    implements _$$GraphNodeImplCopyWith<$Res> {
  __$$GraphNodeImplCopyWithImpl(
      _$GraphNodeImpl _value, $Res Function(_$GraphNodeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? tool = freezed,
    Object? agent = freezed,
    Object? dependsOn = null,
    Object? state = null,
    Object? attempts = null,
    Object? error = freezed,
  }) {
    return _then(_$GraphNodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
      agent: freezed == agent
          ? _value.agent
          : agent // ignore: cast_nullable_to_non_nullable
              as String?,
      dependsOn: null == dependsOn
          ? _value._dependsOn
          : dependsOn // ignore: cast_nullable_to_non_nullable
              as List<String>,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      attempts: null == attempts
          ? _value.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GraphNodeImpl implements _GraphNode {
  const _$GraphNodeImpl(
      {required this.id,
      required this.description,
      this.tool,
      this.agent,
      required final List<String> dependsOn,
      required this.state,
      required this.attempts,
      this.error})
      : _dependsOn = dependsOn;

  factory _$GraphNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$GraphNodeImplFromJson(json);

  @override
  final String id;
  @override
  final String description;
  @override
  final String? tool;
  @override
  final String? agent;
  final List<String> _dependsOn;
  @override
  List<String> get dependsOn {
    if (_dependsOn is EqualUnmodifiableListView) return _dependsOn;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dependsOn);
  }

  @override
  final String state;
  @override
  final int attempts;
  @override
  final String? error;

  @override
  String toString() {
    return 'GraphNode(id: $id, description: $description, tool: $tool, agent: $agent, dependsOn: $dependsOn, state: $state, attempts: $attempts, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GraphNodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            (identical(other.agent, agent) || other.agent == agent) &&
            const DeepCollectionEquality()
                .equals(other._dependsOn, _dependsOn) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.attempts, attempts) ||
                other.attempts == attempts) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, description, tool, agent,
      const DeepCollectionEquality().hash(_dependsOn), state, attempts, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GraphNodeImplCopyWith<_$GraphNodeImpl> get copyWith =>
      __$$GraphNodeImplCopyWithImpl<_$GraphNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GraphNodeImplToJson(
      this,
    );
  }
}

abstract class _GraphNode implements GraphNode {
  const factory _GraphNode(
      {required final String id,
      required final String description,
      final String? tool,
      final String? agent,
      required final List<String> dependsOn,
      required final String state,
      required final int attempts,
      final String? error}) = _$GraphNodeImpl;

  factory _GraphNode.fromJson(Map<String, dynamic> json) =
      _$GraphNodeImpl.fromJson;

  @override
  String get id;
  @override
  String get description;
  @override
  String? get tool;
  @override
  String? get agent;
  @override
  List<String> get dependsOn;
  @override
  String get state;
  @override
  int get attempts;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$GraphNodeImplCopyWith<_$GraphNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GraphProgress _$GraphProgressFromJson(Map<String, dynamic> json) {
  return _GraphProgress.fromJson(json);
}

/// @nodoc
mixin _$GraphProgress {
  int get total => throw _privateConstructorUsedError;
  Map<String, int> get states => throw _privateConstructorUsedError;
  double get percent => throw _privateConstructorUsedError;
  bool get finished => throw _privateConstructorUsedError;
  bool get stuck => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GraphProgressCopyWith<GraphProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GraphProgressCopyWith<$Res> {
  factory $GraphProgressCopyWith(
          GraphProgress value, $Res Function(GraphProgress) then) =
      _$GraphProgressCopyWithImpl<$Res, GraphProgress>;
  @useResult
  $Res call(
      {int total,
      Map<String, int> states,
      double percent,
      bool finished,
      bool stuck});
}

/// @nodoc
class _$GraphProgressCopyWithImpl<$Res, $Val extends GraphProgress>
    implements $GraphProgressCopyWith<$Res> {
  _$GraphProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? states = null,
    Object? percent = null,
    Object? finished = null,
    Object? stuck = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      states: null == states
          ? _value.states
          : states // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
      finished: null == finished
          ? _value.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      stuck: null == stuck
          ? _value.stuck
          : stuck // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GraphProgressImplCopyWith<$Res>
    implements $GraphProgressCopyWith<$Res> {
  factory _$$GraphProgressImplCopyWith(
          _$GraphProgressImpl value, $Res Function(_$GraphProgressImpl) then) =
      __$$GraphProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int total,
      Map<String, int> states,
      double percent,
      bool finished,
      bool stuck});
}

/// @nodoc
class __$$GraphProgressImplCopyWithImpl<$Res>
    extends _$GraphProgressCopyWithImpl<$Res, _$GraphProgressImpl>
    implements _$$GraphProgressImplCopyWith<$Res> {
  __$$GraphProgressImplCopyWithImpl(
      _$GraphProgressImpl _value, $Res Function(_$GraphProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? states = null,
    Object? percent = null,
    Object? finished = null,
    Object? stuck = null,
  }) {
    return _then(_$GraphProgressImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      states: null == states
          ? _value._states
          : states // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
      finished: null == finished
          ? _value.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      stuck: null == stuck
          ? _value.stuck
          : stuck // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GraphProgressImpl implements _GraphProgress {
  const _$GraphProgressImpl(
      {required this.total,
      required final Map<String, int> states,
      required this.percent,
      required this.finished,
      required this.stuck})
      : _states = states;

  factory _$GraphProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$GraphProgressImplFromJson(json);

  @override
  final int total;
  final Map<String, int> _states;
  @override
  Map<String, int> get states {
    if (_states is EqualUnmodifiableMapView) return _states;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_states);
  }

  @override
  final double percent;
  @override
  final bool finished;
  @override
  final bool stuck;

  @override
  String toString() {
    return 'GraphProgress(total: $total, states: $states, percent: $percent, finished: $finished, stuck: $stuck)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GraphProgressImpl &&
            (identical(other.total, total) || other.total == total) &&
            const DeepCollectionEquality().equals(other._states, _states) &&
            (identical(other.percent, percent) || other.percent == percent) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            (identical(other.stuck, stuck) || other.stuck == stuck));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, total,
      const DeepCollectionEquality().hash(_states), percent, finished, stuck);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GraphProgressImplCopyWith<_$GraphProgressImpl> get copyWith =>
      __$$GraphProgressImplCopyWithImpl<_$GraphProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GraphProgressImplToJson(
      this,
    );
  }
}

abstract class _GraphProgress implements GraphProgress {
  const factory _GraphProgress(
      {required final int total,
      required final Map<String, int> states,
      required final double percent,
      required final bool finished,
      required final bool stuck}) = _$GraphProgressImpl;

  factory _GraphProgress.fromJson(Map<String, dynamic> json) =
      _$GraphProgressImpl.fromJson;

  @override
  int get total;
  @override
  Map<String, int> get states;
  @override
  double get percent;
  @override
  bool get finished;
  @override
  bool get stuck;
  @override
  @JsonKey(ignore: true)
  _$$GraphProgressImplCopyWith<_$GraphProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BrainGraphResponse _$BrainGraphResponseFromJson(Map<String, dynamic> json) {
  return _BrainGraphResponse.fromJson(json);
}

/// @nodoc
mixin _$BrainGraphResponse {
  List<GraphNode> get nodes => throw _privateConstructorUsedError;
  GraphProgress get progress => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BrainGraphResponseCopyWith<BrainGraphResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BrainGraphResponseCopyWith<$Res> {
  factory $BrainGraphResponseCopyWith(
          BrainGraphResponse value, $Res Function(BrainGraphResponse) then) =
      _$BrainGraphResponseCopyWithImpl<$Res, BrainGraphResponse>;
  @useResult
  $Res call({List<GraphNode> nodes, GraphProgress progress});

  $GraphProgressCopyWith<$Res> get progress;
}

/// @nodoc
class _$BrainGraphResponseCopyWithImpl<$Res, $Val extends BrainGraphResponse>
    implements $BrainGraphResponseCopyWith<$Res> {
  _$BrainGraphResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodes = null,
    Object? progress = null,
  }) {
    return _then(_value.copyWith(
      nodes: null == nodes
          ? _value.nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<GraphNode>,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as GraphProgress,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $GraphProgressCopyWith<$Res> get progress {
    return $GraphProgressCopyWith<$Res>(_value.progress, (value) {
      return _then(_value.copyWith(progress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BrainGraphResponseImplCopyWith<$Res>
    implements $BrainGraphResponseCopyWith<$Res> {
  factory _$$BrainGraphResponseImplCopyWith(_$BrainGraphResponseImpl value,
          $Res Function(_$BrainGraphResponseImpl) then) =
      __$$BrainGraphResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<GraphNode> nodes, GraphProgress progress});

  @override
  $GraphProgressCopyWith<$Res> get progress;
}

/// @nodoc
class __$$BrainGraphResponseImplCopyWithImpl<$Res>
    extends _$BrainGraphResponseCopyWithImpl<$Res, _$BrainGraphResponseImpl>
    implements _$$BrainGraphResponseImplCopyWith<$Res> {
  __$$BrainGraphResponseImplCopyWithImpl(_$BrainGraphResponseImpl _value,
      $Res Function(_$BrainGraphResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodes = null,
    Object? progress = null,
  }) {
    return _then(_$BrainGraphResponseImpl(
      nodes: null == nodes
          ? _value._nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<GraphNode>,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as GraphProgress,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BrainGraphResponseImpl implements _BrainGraphResponse {
  const _$BrainGraphResponseImpl(
      {required final List<GraphNode> nodes, required this.progress})
      : _nodes = nodes;

  factory _$BrainGraphResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BrainGraphResponseImplFromJson(json);

  final List<GraphNode> _nodes;
  @override
  List<GraphNode> get nodes {
    if (_nodes is EqualUnmodifiableListView) return _nodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodes);
  }

  @override
  final GraphProgress progress;

  @override
  String toString() {
    return 'BrainGraphResponse(nodes: $nodes, progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BrainGraphResponseImpl &&
            const DeepCollectionEquality().equals(other._nodes, _nodes) &&
            (identical(other.progress, progress) ||
                other.progress == progress));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_nodes), progress);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BrainGraphResponseImplCopyWith<_$BrainGraphResponseImpl> get copyWith =>
      __$$BrainGraphResponseImplCopyWithImpl<_$BrainGraphResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BrainGraphResponseImplToJson(
      this,
    );
  }
}

abstract class _BrainGraphResponse implements BrainGraphResponse {
  const factory _BrainGraphResponse(
      {required final List<GraphNode> nodes,
      required final GraphProgress progress}) = _$BrainGraphResponseImpl;

  factory _BrainGraphResponse.fromJson(Map<String, dynamic> json) =
      _$BrainGraphResponseImpl.fromJson;

  @override
  List<GraphNode> get nodes;
  @override
  GraphProgress get progress;
  @override
  @JsonKey(ignore: true)
  _$$BrainGraphResponseImplCopyWith<_$BrainGraphResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AgentInfo _$AgentInfoFromJson(Map<String, dynamic> json) {
  return _AgentInfo.fromJson(json);
}

/// @nodoc
mixin _$AgentInfo {
  String get name => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  List<String> get skills => throw _privateConstructorUsedError;
  List<String> get permissions => throw _privateConstructorUsedError;
  int get ok => throw _privateConstructorUsedError;
  int get errors => throw _privateConstructorUsedError;
  double? get successRate => throw _privateConstructorUsedError;
  String? get lastError => throw _privateConstructorUsedError;
  double? get lastActive => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentInfoCopyWith<AgentInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentInfoCopyWith<$Res> {
  factory $AgentInfoCopyWith(AgentInfo value, $Res Function(AgentInfo) then) =
      _$AgentInfoCopyWithImpl<$Res, AgentInfo>;
  @useResult
  $Res call(
      {String name,
      String role,
      List<String> skills,
      List<String> permissions,
      int ok,
      int errors,
      double? successRate,
      String? lastError,
      double? lastActive,
      String status});
}

/// @nodoc
class _$AgentInfoCopyWithImpl<$Res, $Val extends AgentInfo>
    implements $AgentInfoCopyWith<$Res> {
  _$AgentInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? role = null,
    Object? skills = null,
    Object? permissions = null,
    Object? ok = null,
    Object? errors = null,
    Object? successRate = freezed,
    Object? lastError = freezed,
    Object? lastActive = freezed,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      skills: null == skills
          ? _value.skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      permissions: null == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as int,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as int,
      successRate: freezed == successRate
          ? _value.successRate
          : successRate // ignore: cast_nullable_to_non_nullable
              as double?,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
      lastActive: freezed == lastActive
          ? _value.lastActive
          : lastActive // ignore: cast_nullable_to_non_nullable
              as double?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentInfoImplCopyWith<$Res>
    implements $AgentInfoCopyWith<$Res> {
  factory _$$AgentInfoImplCopyWith(
          _$AgentInfoImpl value, $Res Function(_$AgentInfoImpl) then) =
      __$$AgentInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String role,
      List<String> skills,
      List<String> permissions,
      int ok,
      int errors,
      double? successRate,
      String? lastError,
      double? lastActive,
      String status});
}

/// @nodoc
class __$$AgentInfoImplCopyWithImpl<$Res>
    extends _$AgentInfoCopyWithImpl<$Res, _$AgentInfoImpl>
    implements _$$AgentInfoImplCopyWith<$Res> {
  __$$AgentInfoImplCopyWithImpl(
      _$AgentInfoImpl _value, $Res Function(_$AgentInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? role = null,
    Object? skills = null,
    Object? permissions = null,
    Object? ok = null,
    Object? errors = null,
    Object? successRate = freezed,
    Object? lastError = freezed,
    Object? lastActive = freezed,
    Object? status = null,
  }) {
    return _then(_$AgentInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      skills: null == skills
          ? _value._skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      permissions: null == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as int,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as int,
      successRate: freezed == successRate
          ? _value.successRate
          : successRate // ignore: cast_nullable_to_non_nullable
              as double?,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
      lastActive: freezed == lastActive
          ? _value.lastActive
          : lastActive // ignore: cast_nullable_to_non_nullable
              as double?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentInfoImpl implements _AgentInfo {
  const _$AgentInfoImpl(
      {required this.name,
      required this.role,
      required final List<String> skills,
      required final List<String> permissions,
      required this.ok,
      required this.errors,
      this.successRate,
      this.lastError,
      this.lastActive,
      required this.status})
      : _skills = skills,
        _permissions = permissions;

  factory _$AgentInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentInfoImplFromJson(json);

  @override
  final String name;
  @override
  final String role;
  final List<String> _skills;
  @override
  List<String> get skills {
    if (_skills is EqualUnmodifiableListView) return _skills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skills);
  }

  final List<String> _permissions;
  @override
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  final int ok;
  @override
  final int errors;
  @override
  final double? successRate;
  @override
  final String? lastError;
  @override
  final double? lastActive;
  @override
  final String status;

  @override
  String toString() {
    return 'AgentInfo(name: $name, role: $role, skills: $skills, permissions: $permissions, ok: $ok, errors: $errors, successRate: $successRate, lastError: $lastError, lastActive: $lastActive, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality().equals(other._skills, _skills) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions) &&
            (identical(other.ok, ok) || other.ok == ok) &&
            (identical(other.errors, errors) || other.errors == errors) &&
            (identical(other.successRate, successRate) ||
                other.successRate == successRate) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError) &&
            (identical(other.lastActive, lastActive) ||
                other.lastActive == lastActive) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      role,
      const DeepCollectionEquality().hash(_skills),
      const DeepCollectionEquality().hash(_permissions),
      ok,
      errors,
      successRate,
      lastError,
      lastActive,
      status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentInfoImplCopyWith<_$AgentInfoImpl> get copyWith =>
      __$$AgentInfoImplCopyWithImpl<_$AgentInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentInfoImplToJson(
      this,
    );
  }
}

abstract class _AgentInfo implements AgentInfo {
  const factory _AgentInfo(
      {required final String name,
      required final String role,
      required final List<String> skills,
      required final List<String> permissions,
      required final int ok,
      required final int errors,
      final double? successRate,
      final String? lastError,
      final double? lastActive,
      required final String status}) = _$AgentInfoImpl;

  factory _AgentInfo.fromJson(Map<String, dynamic> json) =
      _$AgentInfoImpl.fromJson;

  @override
  String get name;
  @override
  String get role;
  @override
  List<String> get skills;
  @override
  List<String> get permissions;
  @override
  int get ok;
  @override
  int get errors;
  @override
  double? get successRate;
  @override
  String? get lastError;
  @override
  double? get lastActive;
  @override
  String get status;
  @override
  @JsonKey(ignore: true)
  _$$AgentInfoImplCopyWith<_$AgentInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AgentsListResponse _$AgentsListResponseFromJson(Map<String, dynamic> json) {
  return _AgentsListResponse.fromJson(json);
}

/// @nodoc
mixin _$AgentsListResponse {
  List<AgentInfo> get agents => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentsListResponseCopyWith<AgentsListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentsListResponseCopyWith<$Res> {
  factory $AgentsListResponseCopyWith(
          AgentsListResponse value, $Res Function(AgentsListResponse) then) =
      _$AgentsListResponseCopyWithImpl<$Res, AgentsListResponse>;
  @useResult
  $Res call({List<AgentInfo> agents});
}

/// @nodoc
class _$AgentsListResponseCopyWithImpl<$Res, $Val extends AgentsListResponse>
    implements $AgentsListResponseCopyWith<$Res> {
  _$AgentsListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? agents = null,
  }) {
    return _then(_value.copyWith(
      agents: null == agents
          ? _value.agents
          : agents // ignore: cast_nullable_to_non_nullable
              as List<AgentInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentsListResponseImplCopyWith<$Res>
    implements $AgentsListResponseCopyWith<$Res> {
  factory _$$AgentsListResponseImplCopyWith(_$AgentsListResponseImpl value,
          $Res Function(_$AgentsListResponseImpl) then) =
      __$$AgentsListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AgentInfo> agents});
}

/// @nodoc
class __$$AgentsListResponseImplCopyWithImpl<$Res>
    extends _$AgentsListResponseCopyWithImpl<$Res, _$AgentsListResponseImpl>
    implements _$$AgentsListResponseImplCopyWith<$Res> {
  __$$AgentsListResponseImplCopyWithImpl(_$AgentsListResponseImpl _value,
      $Res Function(_$AgentsListResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? agents = null,
  }) {
    return _then(_$AgentsListResponseImpl(
      agents: null == agents
          ? _value._agents
          : agents // ignore: cast_nullable_to_non_nullable
              as List<AgentInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentsListResponseImpl implements _AgentsListResponse {
  const _$AgentsListResponseImpl({required final List<AgentInfo> agents})
      : _agents = agents;

  factory _$AgentsListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentsListResponseImplFromJson(json);

  final List<AgentInfo> _agents;
  @override
  List<AgentInfo> get agents {
    if (_agents is EqualUnmodifiableListView) return _agents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_agents);
  }

  @override
  String toString() {
    return 'AgentsListResponse(agents: $agents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentsListResponseImpl &&
            const DeepCollectionEquality().equals(other._agents, _agents));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_agents));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentsListResponseImplCopyWith<_$AgentsListResponseImpl> get copyWith =>
      __$$AgentsListResponseImplCopyWithImpl<_$AgentsListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentsListResponseImplToJson(
      this,
    );
  }
}

abstract class _AgentsListResponse implements AgentsListResponse {
  const factory _AgentsListResponse({required final List<AgentInfo> agents}) =
      _$AgentsListResponseImpl;

  factory _AgentsListResponse.fromJson(Map<String, dynamic> json) =
      _$AgentsListResponseImpl.fromJson;

  @override
  List<AgentInfo> get agents;
  @override
  @JsonKey(ignore: true)
  _$$AgentsListResponseImplCopyWith<_$AgentsListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrchestrationAssignment _$OrchestrationAssignmentFromJson(
    Map<String, dynamic> json) {
  return _OrchestrationAssignment.fromJson(json);
}

/// @nodoc
mixin _$OrchestrationAssignment {
  String get nodeId => throw _privateConstructorUsedError;
  String get agentName => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get tool => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OrchestrationAssignmentCopyWith<OrchestrationAssignment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrchestrationAssignmentCopyWith<$Res> {
  factory $OrchestrationAssignmentCopyWith(OrchestrationAssignment value,
          $Res Function(OrchestrationAssignment) then) =
      _$OrchestrationAssignmentCopyWithImpl<$Res, OrchestrationAssignment>;
  @useResult
  $Res call(
      {String nodeId, String agentName, String? description, String? tool});
}

/// @nodoc
class _$OrchestrationAssignmentCopyWithImpl<$Res,
        $Val extends OrchestrationAssignment>
    implements $OrchestrationAssignmentCopyWith<$Res> {
  _$OrchestrationAssignmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? agentName = null,
    Object? description = freezed,
    Object? tool = freezed,
  }) {
    return _then(_value.copyWith(
      nodeId: null == nodeId
          ? _value.nodeId
          : nodeId // ignore: cast_nullable_to_non_nullable
              as String,
      agentName: null == agentName
          ? _value.agentName
          : agentName // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrchestrationAssignmentImplCopyWith<$Res>
    implements $OrchestrationAssignmentCopyWith<$Res> {
  factory _$$OrchestrationAssignmentImplCopyWith(
          _$OrchestrationAssignmentImpl value,
          $Res Function(_$OrchestrationAssignmentImpl) then) =
      __$$OrchestrationAssignmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String nodeId, String agentName, String? description, String? tool});
}

/// @nodoc
class __$$OrchestrationAssignmentImplCopyWithImpl<$Res>
    extends _$OrchestrationAssignmentCopyWithImpl<$Res,
        _$OrchestrationAssignmentImpl>
    implements _$$OrchestrationAssignmentImplCopyWith<$Res> {
  __$$OrchestrationAssignmentImplCopyWithImpl(
      _$OrchestrationAssignmentImpl _value,
      $Res Function(_$OrchestrationAssignmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? agentName = null,
    Object? description = freezed,
    Object? tool = freezed,
  }) {
    return _then(_$OrchestrationAssignmentImpl(
      nodeId: null == nodeId
          ? _value.nodeId
          : nodeId // ignore: cast_nullable_to_non_nullable
              as String,
      agentName: null == agentName
          ? _value.agentName
          : agentName // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrchestrationAssignmentImpl implements _OrchestrationAssignment {
  const _$OrchestrationAssignmentImpl(
      {required this.nodeId,
      required this.agentName,
      this.description,
      this.tool});

  factory _$OrchestrationAssignmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrchestrationAssignmentImplFromJson(json);

  @override
  final String nodeId;
  @override
  final String agentName;
  @override
  final String? description;
  @override
  final String? tool;

  @override
  String toString() {
    return 'OrchestrationAssignment(nodeId: $nodeId, agentName: $agentName, description: $description, tool: $tool)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrchestrationAssignmentImpl &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.agentName, agentName) ||
                other.agentName == agentName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.tool, tool) || other.tool == tool));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, nodeId, agentName, description, tool);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OrchestrationAssignmentImplCopyWith<_$OrchestrationAssignmentImpl>
      get copyWith => __$$OrchestrationAssignmentImplCopyWithImpl<
          _$OrchestrationAssignmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrchestrationAssignmentImplToJson(
      this,
    );
  }
}

abstract class _OrchestrationAssignment implements OrchestrationAssignment {
  const factory _OrchestrationAssignment(
      {required final String nodeId,
      required final String agentName,
      final String? description,
      final String? tool}) = _$OrchestrationAssignmentImpl;

  factory _OrchestrationAssignment.fromJson(Map<String, dynamic> json) =
      _$OrchestrationAssignmentImpl.fromJson;

  @override
  String get nodeId;
  @override
  String get agentName;
  @override
  String? get description;
  @override
  String? get tool;
  @override
  @JsonKey(ignore: true)
  _$$OrchestrationAssignmentImplCopyWith<_$OrchestrationAssignmentImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AgentsOrchestrateResponse _$AgentsOrchestrateResponseFromJson(
    Map<String, dynamic> json) {
  return _AgentsOrchestrateResponse.fromJson(json);
}

/// @nodoc
mixin _$AgentsOrchestrateResponse {
  BrainAnalyzeResponse get analysis => throw _privateConstructorUsedError;
  Map<String, String> get assignments => throw _privateConstructorUsedError;
  BrainGraphResponse get graph => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentsOrchestrateResponseCopyWith<AgentsOrchestrateResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentsOrchestrateResponseCopyWith<$Res> {
  factory $AgentsOrchestrateResponseCopyWith(AgentsOrchestrateResponse value,
          $Res Function(AgentsOrchestrateResponse) then) =
      _$AgentsOrchestrateResponseCopyWithImpl<$Res, AgentsOrchestrateResponse>;
  @useResult
  $Res call(
      {BrainAnalyzeResponse analysis,
      Map<String, String> assignments,
      BrainGraphResponse graph});

  $BrainAnalyzeResponseCopyWith<$Res> get analysis;
  $BrainGraphResponseCopyWith<$Res> get graph;
}

/// @nodoc
class _$AgentsOrchestrateResponseCopyWithImpl<$Res,
        $Val extends AgentsOrchestrateResponse>
    implements $AgentsOrchestrateResponseCopyWith<$Res> {
  _$AgentsOrchestrateResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? analysis = null,
    Object? assignments = null,
    Object? graph = null,
  }) {
    return _then(_value.copyWith(
      analysis: null == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as BrainAnalyzeResponse,
      assignments: null == assignments
          ? _value.assignments
          : assignments // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      graph: null == graph
          ? _value.graph
          : graph // ignore: cast_nullable_to_non_nullable
              as BrainGraphResponse,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BrainAnalyzeResponseCopyWith<$Res> get analysis {
    return $BrainAnalyzeResponseCopyWith<$Res>(_value.analysis, (value) {
      return _then(_value.copyWith(analysis: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $BrainGraphResponseCopyWith<$Res> get graph {
    return $BrainGraphResponseCopyWith<$Res>(_value.graph, (value) {
      return _then(_value.copyWith(graph: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AgentsOrchestrateResponseImplCopyWith<$Res>
    implements $AgentsOrchestrateResponseCopyWith<$Res> {
  factory _$$AgentsOrchestrateResponseImplCopyWith(
          _$AgentsOrchestrateResponseImpl value,
          $Res Function(_$AgentsOrchestrateResponseImpl) then) =
      __$$AgentsOrchestrateResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {BrainAnalyzeResponse analysis,
      Map<String, String> assignments,
      BrainGraphResponse graph});

  @override
  $BrainAnalyzeResponseCopyWith<$Res> get analysis;
  @override
  $BrainGraphResponseCopyWith<$Res> get graph;
}

/// @nodoc
class __$$AgentsOrchestrateResponseImplCopyWithImpl<$Res>
    extends _$AgentsOrchestrateResponseCopyWithImpl<$Res,
        _$AgentsOrchestrateResponseImpl>
    implements _$$AgentsOrchestrateResponseImplCopyWith<$Res> {
  __$$AgentsOrchestrateResponseImplCopyWithImpl(
      _$AgentsOrchestrateResponseImpl _value,
      $Res Function(_$AgentsOrchestrateResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? analysis = null,
    Object? assignments = null,
    Object? graph = null,
  }) {
    return _then(_$AgentsOrchestrateResponseImpl(
      analysis: null == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as BrainAnalyzeResponse,
      assignments: null == assignments
          ? _value._assignments
          : assignments // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      graph: null == graph
          ? _value.graph
          : graph // ignore: cast_nullable_to_non_nullable
              as BrainGraphResponse,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentsOrchestrateResponseImpl implements _AgentsOrchestrateResponse {
  const _$AgentsOrchestrateResponseImpl(
      {required this.analysis,
      required final Map<String, String> assignments,
      required this.graph})
      : _assignments = assignments;

  factory _$AgentsOrchestrateResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentsOrchestrateResponseImplFromJson(json);

  @override
  final BrainAnalyzeResponse analysis;
  final Map<String, String> _assignments;
  @override
  Map<String, String> get assignments {
    if (_assignments is EqualUnmodifiableMapView) return _assignments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_assignments);
  }

  @override
  final BrainGraphResponse graph;

  @override
  String toString() {
    return 'AgentsOrchestrateResponse(analysis: $analysis, assignments: $assignments, graph: $graph)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentsOrchestrateResponseImpl &&
            (identical(other.analysis, analysis) ||
                other.analysis == analysis) &&
            const DeepCollectionEquality()
                .equals(other._assignments, _assignments) &&
            (identical(other.graph, graph) || other.graph == graph));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, analysis,
      const DeepCollectionEquality().hash(_assignments), graph);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentsOrchestrateResponseImplCopyWith<_$AgentsOrchestrateResponseImpl>
      get copyWith => __$$AgentsOrchestrateResponseImplCopyWithImpl<
          _$AgentsOrchestrateResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentsOrchestrateResponseImplToJson(
      this,
    );
  }
}

abstract class _AgentsOrchestrateResponse implements AgentsOrchestrateResponse {
  const factory _AgentsOrchestrateResponse(
          {required final BrainAnalyzeResponse analysis,
          required final Map<String, String> assignments,
          required final BrainGraphResponse graph}) =
      _$AgentsOrchestrateResponseImpl;

  factory _AgentsOrchestrateResponse.fromJson(Map<String, dynamic> json) =
      _$AgentsOrchestrateResponseImpl.fromJson;

  @override
  BrainAnalyzeResponse get analysis;
  @override
  Map<String, String> get assignments;
  @override
  BrainGraphResponse get graph;
  @override
  @JsonKey(ignore: true)
  _$$AgentsOrchestrateResponseImplCopyWith<_$AgentsOrchestrateResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AgentMessage _$AgentMessageFromJson(Map<String, dynamic> json) {
  return _AgentMessage.fromJson(json);
}

/// @nodoc
mixin _$AgentMessage {
  String get from => throw _privateConstructorUsedError;
  String get to => throw _privateConstructorUsedError;
  dynamic get content => throw _privateConstructorUsedError;
  double get ts => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentMessageCopyWith<AgentMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentMessageCopyWith<$Res> {
  factory $AgentMessageCopyWith(
          AgentMessage value, $Res Function(AgentMessage) then) =
      _$AgentMessageCopyWithImpl<$Res, AgentMessage>;
  @useResult
  $Res call({String from, String to, dynamic content, double ts});
}

/// @nodoc
class _$AgentMessageCopyWithImpl<$Res, $Val extends AgentMessage>
    implements $AgentMessageCopyWith<$Res> {
  _$AgentMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? from = null,
    Object? to = null,
    Object? content = freezed,
    Object? ts = null,
  }) {
    return _then(_value.copyWith(
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as dynamic,
      ts: null == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentMessageImplCopyWith<$Res>
    implements $AgentMessageCopyWith<$Res> {
  factory _$$AgentMessageImplCopyWith(
          _$AgentMessageImpl value, $Res Function(_$AgentMessageImpl) then) =
      __$$AgentMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String from, String to, dynamic content, double ts});
}

/// @nodoc
class __$$AgentMessageImplCopyWithImpl<$Res>
    extends _$AgentMessageCopyWithImpl<$Res, _$AgentMessageImpl>
    implements _$$AgentMessageImplCopyWith<$Res> {
  __$$AgentMessageImplCopyWithImpl(
      _$AgentMessageImpl _value, $Res Function(_$AgentMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? from = null,
    Object? to = null,
    Object? content = freezed,
    Object? ts = null,
  }) {
    return _then(_$AgentMessageImpl(
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as dynamic,
      ts: null == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentMessageImpl implements _AgentMessage {
  const _$AgentMessageImpl(
      {required this.from,
      required this.to,
      required this.content,
      required this.ts});

  factory _$AgentMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentMessageImplFromJson(json);

  @override
  final String from;
  @override
  final String to;
  @override
  final dynamic content;
  @override
  final double ts;

  @override
  String toString() {
    return 'AgentMessage(from: $from, to: $to, content: $content, ts: $ts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentMessageImpl &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            const DeepCollectionEquality().equals(other.content, content) &&
            (identical(other.ts, ts) || other.ts == ts));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, from, to, const DeepCollectionEquality().hash(content), ts);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentMessageImplCopyWith<_$AgentMessageImpl> get copyWith =>
      __$$AgentMessageImplCopyWithImpl<_$AgentMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentMessageImplToJson(
      this,
    );
  }
}

abstract class _AgentMessage implements AgentMessage {
  const factory _AgentMessage(
      {required final String from,
      required final String to,
      required final dynamic content,
      required final double ts}) = _$AgentMessageImpl;

  factory _AgentMessage.fromJson(Map<String, dynamic> json) =
      _$AgentMessageImpl.fromJson;

  @override
  String get from;
  @override
  String get to;
  @override
  dynamic get content;
  @override
  double get ts;
  @override
  @JsonKey(ignore: true)
  _$$AgentMessageImplCopyWith<_$AgentMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AgentsMessagesResponse _$AgentsMessagesResponseFromJson(
    Map<String, dynamic> json) {
  return _AgentsMessagesResponse.fromJson(json);
}

/// @nodoc
mixin _$AgentsMessagesResponse {
  List<AgentMessage> get messages => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AgentsMessagesResponseCopyWith<AgentsMessagesResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentsMessagesResponseCopyWith<$Res> {
  factory $AgentsMessagesResponseCopyWith(AgentsMessagesResponse value,
          $Res Function(AgentsMessagesResponse) then) =
      _$AgentsMessagesResponseCopyWithImpl<$Res, AgentsMessagesResponse>;
  @useResult
  $Res call({List<AgentMessage> messages});
}

/// @nodoc
class _$AgentsMessagesResponseCopyWithImpl<$Res,
        $Val extends AgentsMessagesResponse>
    implements $AgentsMessagesResponseCopyWith<$Res> {
  _$AgentsMessagesResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
  }) {
    return _then(_value.copyWith(
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<AgentMessage>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentsMessagesResponseImplCopyWith<$Res>
    implements $AgentsMessagesResponseCopyWith<$Res> {
  factory _$$AgentsMessagesResponseImplCopyWith(
          _$AgentsMessagesResponseImpl value,
          $Res Function(_$AgentsMessagesResponseImpl) then) =
      __$$AgentsMessagesResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AgentMessage> messages});
}

/// @nodoc
class __$$AgentsMessagesResponseImplCopyWithImpl<$Res>
    extends _$AgentsMessagesResponseCopyWithImpl<$Res,
        _$AgentsMessagesResponseImpl>
    implements _$$AgentsMessagesResponseImplCopyWith<$Res> {
  __$$AgentsMessagesResponseImplCopyWithImpl(
      _$AgentsMessagesResponseImpl _value,
      $Res Function(_$AgentsMessagesResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
  }) {
    return _then(_$AgentsMessagesResponseImpl(
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<AgentMessage>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentsMessagesResponseImpl implements _AgentsMessagesResponse {
  const _$AgentsMessagesResponseImpl(
      {required final List<AgentMessage> messages})
      : _messages = messages;

  factory _$AgentsMessagesResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentsMessagesResponseImplFromJson(json);

  final List<AgentMessage> _messages;
  @override
  List<AgentMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'AgentsMessagesResponse(messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentsMessagesResponseImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_messages));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentsMessagesResponseImplCopyWith<_$AgentsMessagesResponseImpl>
      get copyWith => __$$AgentsMessagesResponseImplCopyWithImpl<
          _$AgentsMessagesResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentsMessagesResponseImplToJson(
      this,
    );
  }
}

abstract class _AgentsMessagesResponse implements AgentsMessagesResponse {
  const factory _AgentsMessagesResponse(
          {required final List<AgentMessage> messages}) =
      _$AgentsMessagesResponseImpl;

  factory _AgentsMessagesResponse.fromJson(Map<String, dynamic> json) =
      _$AgentsMessagesResponseImpl.fromJson;

  @override
  List<AgentMessage> get messages;
  @override
  @JsonKey(ignore: true)
  _$$AgentsMessagesResponseImplCopyWith<_$AgentsMessagesResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

WorkflowPlanResponse _$WorkflowPlanResponseFromJson(Map<String, dynamic> json) {
  return _WorkflowPlanResponse.fromJson(json);
}

/// @nodoc
mixin _$WorkflowPlanResponse {
  String get runId => throw _privateConstructorUsedError;
  Map<String, dynamic> get state => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkflowPlanResponseCopyWith<WorkflowPlanResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowPlanResponseCopyWith<$Res> {
  factory $WorkflowPlanResponseCopyWith(WorkflowPlanResponse value,
          $Res Function(WorkflowPlanResponse) then) =
      _$WorkflowPlanResponseCopyWithImpl<$Res, WorkflowPlanResponse>;
  @useResult
  $Res call({String runId, Map<String, dynamic> state});
}

/// @nodoc
class _$WorkflowPlanResponseCopyWithImpl<$Res,
        $Val extends WorkflowPlanResponse>
    implements $WorkflowPlanResponseCopyWith<$Res> {
  _$WorkflowPlanResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? runId = null,
    Object? state = null,
  }) {
    return _then(_value.copyWith(
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkflowPlanResponseImplCopyWith<$Res>
    implements $WorkflowPlanResponseCopyWith<$Res> {
  factory _$$WorkflowPlanResponseImplCopyWith(_$WorkflowPlanResponseImpl value,
          $Res Function(_$WorkflowPlanResponseImpl) then) =
      __$$WorkflowPlanResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String runId, Map<String, dynamic> state});
}

/// @nodoc
class __$$WorkflowPlanResponseImplCopyWithImpl<$Res>
    extends _$WorkflowPlanResponseCopyWithImpl<$Res, _$WorkflowPlanResponseImpl>
    implements _$$WorkflowPlanResponseImplCopyWith<$Res> {
  __$$WorkflowPlanResponseImplCopyWithImpl(_$WorkflowPlanResponseImpl _value,
      $Res Function(_$WorkflowPlanResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? runId = null,
    Object? state = null,
  }) {
    return _then(_$WorkflowPlanResponseImpl(
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value._state
          : state // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowPlanResponseImpl implements _WorkflowPlanResponse {
  const _$WorkflowPlanResponseImpl(
      {required this.runId, required final Map<String, dynamic> state})
      : _state = state;

  factory _$WorkflowPlanResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowPlanResponseImplFromJson(json);

  @override
  final String runId;
  final Map<String, dynamic> _state;
  @override
  Map<String, dynamic> get state {
    if (_state is EqualUnmodifiableMapView) return _state;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_state);
  }

  @override
  String toString() {
    return 'WorkflowPlanResponse(runId: $runId, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowPlanResponseImpl &&
            (identical(other.runId, runId) || other.runId == runId) &&
            const DeepCollectionEquality().equals(other._state, _state));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, runId, const DeepCollectionEquality().hash(_state));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowPlanResponseImplCopyWith<_$WorkflowPlanResponseImpl>
      get copyWith =>
          __$$WorkflowPlanResponseImplCopyWithImpl<_$WorkflowPlanResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowPlanResponseImplToJson(
      this,
    );
  }
}

abstract class _WorkflowPlanResponse implements WorkflowPlanResponse {
  const factory _WorkflowPlanResponse(
      {required final String runId,
      required final Map<String, dynamic> state}) = _$WorkflowPlanResponseImpl;

  factory _WorkflowPlanResponse.fromJson(Map<String, dynamic> json) =
      _$WorkflowPlanResponseImpl.fromJson;

  @override
  String get runId;
  @override
  Map<String, dynamic> get state;
  @override
  @JsonKey(ignore: true)
  _$$WorkflowPlanResponseImplCopyWith<_$WorkflowPlanResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

WorkflowNode _$WorkflowNodeFromJson(Map<String, dynamic> json) {
  return _WorkflowNode.fromJson(json);
}

/// @nodoc
mixin _$WorkflowNode {
  String get id => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get tool => throw _privateConstructorUsedError;
  String? get agent => throw _privateConstructorUsedError;
  List<String> get dependsOn => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  int get attempts => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get recoveryNote => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkflowNodeCopyWith<WorkflowNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowNodeCopyWith<$Res> {
  factory $WorkflowNodeCopyWith(
          WorkflowNode value, $Res Function(WorkflowNode) then) =
      _$WorkflowNodeCopyWithImpl<$Res, WorkflowNode>;
  @useResult
  $Res call(
      {String id,
      String description,
      String? tool,
      String? agent,
      List<String> dependsOn,
      String state,
      int attempts,
      String? error,
      String? recoveryNote});
}

/// @nodoc
class _$WorkflowNodeCopyWithImpl<$Res, $Val extends WorkflowNode>
    implements $WorkflowNodeCopyWith<$Res> {
  _$WorkflowNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? tool = freezed,
    Object? agent = freezed,
    Object? dependsOn = null,
    Object? state = null,
    Object? attempts = null,
    Object? error = freezed,
    Object? recoveryNote = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
      agent: freezed == agent
          ? _value.agent
          : agent // ignore: cast_nullable_to_non_nullable
              as String?,
      dependsOn: null == dependsOn
          ? _value.dependsOn
          : dependsOn // ignore: cast_nullable_to_non_nullable
              as List<String>,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      attempts: null == attempts
          ? _value.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      recoveryNote: freezed == recoveryNote
          ? _value.recoveryNote
          : recoveryNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkflowNodeImplCopyWith<$Res>
    implements $WorkflowNodeCopyWith<$Res> {
  factory _$$WorkflowNodeImplCopyWith(
          _$WorkflowNodeImpl value, $Res Function(_$WorkflowNodeImpl) then) =
      __$$WorkflowNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String description,
      String? tool,
      String? agent,
      List<String> dependsOn,
      String state,
      int attempts,
      String? error,
      String? recoveryNote});
}

/// @nodoc
class __$$WorkflowNodeImplCopyWithImpl<$Res>
    extends _$WorkflowNodeCopyWithImpl<$Res, _$WorkflowNodeImpl>
    implements _$$WorkflowNodeImplCopyWith<$Res> {
  __$$WorkflowNodeImplCopyWithImpl(
      _$WorkflowNodeImpl _value, $Res Function(_$WorkflowNodeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? tool = freezed,
    Object? agent = freezed,
    Object? dependsOn = null,
    Object? state = null,
    Object? attempts = null,
    Object? error = freezed,
    Object? recoveryNote = freezed,
  }) {
    return _then(_$WorkflowNodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
      agent: freezed == agent
          ? _value.agent
          : agent // ignore: cast_nullable_to_non_nullable
              as String?,
      dependsOn: null == dependsOn
          ? _value._dependsOn
          : dependsOn // ignore: cast_nullable_to_non_nullable
              as List<String>,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      attempts: null == attempts
          ? _value.attempts
          : attempts // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      recoveryNote: freezed == recoveryNote
          ? _value.recoveryNote
          : recoveryNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowNodeImpl implements _WorkflowNode {
  const _$WorkflowNodeImpl(
      {required this.id,
      required this.description,
      this.tool,
      this.agent,
      required final List<String> dependsOn,
      required this.state,
      required this.attempts,
      this.error,
      this.recoveryNote})
      : _dependsOn = dependsOn;

  factory _$WorkflowNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowNodeImplFromJson(json);

  @override
  final String id;
  @override
  final String description;
  @override
  final String? tool;
  @override
  final String? agent;
  final List<String> _dependsOn;
  @override
  List<String> get dependsOn {
    if (_dependsOn is EqualUnmodifiableListView) return _dependsOn;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dependsOn);
  }

  @override
  final String state;
  @override
  final int attempts;
  @override
  final String? error;
  @override
  final String? recoveryNote;

  @override
  String toString() {
    return 'WorkflowNode(id: $id, description: $description, tool: $tool, agent: $agent, dependsOn: $dependsOn, state: $state, attempts: $attempts, error: $error, recoveryNote: $recoveryNote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowNodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            (identical(other.agent, agent) || other.agent == agent) &&
            const DeepCollectionEquality()
                .equals(other._dependsOn, _dependsOn) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.attempts, attempts) ||
                other.attempts == attempts) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.recoveryNote, recoveryNote) ||
                other.recoveryNote == recoveryNote));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      description,
      tool,
      agent,
      const DeepCollectionEquality().hash(_dependsOn),
      state,
      attempts,
      error,
      recoveryNote);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowNodeImplCopyWith<_$WorkflowNodeImpl> get copyWith =>
      __$$WorkflowNodeImplCopyWithImpl<_$WorkflowNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowNodeImplToJson(
      this,
    );
  }
}

abstract class _WorkflowNode implements WorkflowNode {
  const factory _WorkflowNode(
      {required final String id,
      required final String description,
      final String? tool,
      final String? agent,
      required final List<String> dependsOn,
      required final String state,
      required final int attempts,
      final String? error,
      final String? recoveryNote}) = _$WorkflowNodeImpl;

  factory _WorkflowNode.fromJson(Map<String, dynamic> json) =
      _$WorkflowNodeImpl.fromJson;

  @override
  String get id;
  @override
  String get description;
  @override
  String? get tool;
  @override
  String? get agent;
  @override
  List<String> get dependsOn;
  @override
  String get state;
  @override
  int get attempts;
  @override
  String? get error;
  @override
  String? get recoveryNote;
  @override
  @JsonKey(ignore: true)
  _$$WorkflowNodeImplCopyWith<_$WorkflowNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkflowRunState _$WorkflowRunStateFromJson(Map<String, dynamic> json) {
  return _WorkflowRunState.fromJson(json);
}

/// @nodoc
mixin _$WorkflowRunState {
  String get id => throw _privateConstructorUsedError;
  String get goal => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  double get created => throw _privateConstructorUsedError;
  List<dynamic> get results => throw _privateConstructorUsedError;
  List<WorkflowNode> get nodes => throw _privateConstructorUsedError;
  int? get replansLeft => throw _privateConstructorUsedError;
  List<dynamic>? get recoveryLog => throw _privateConstructorUsedError;
  int? get replanCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkflowRunStateCopyWith<WorkflowRunState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowRunStateCopyWith<$Res> {
  factory $WorkflowRunStateCopyWith(
          WorkflowRunState value, $Res Function(WorkflowRunState) then) =
      _$WorkflowRunStateCopyWithImpl<$Res, WorkflowRunState>;
  @useResult
  $Res call(
      {String id,
      String goal,
      String status,
      double created,
      List<dynamic> results,
      List<WorkflowNode> nodes,
      int? replansLeft,
      List<dynamic>? recoveryLog,
      int? replanCount});
}

/// @nodoc
class _$WorkflowRunStateCopyWithImpl<$Res, $Val extends WorkflowRunState>
    implements $WorkflowRunStateCopyWith<$Res> {
  _$WorkflowRunStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? goal = null,
    Object? status = null,
    Object? created = null,
    Object? results = null,
    Object? nodes = null,
    Object? replansLeft = freezed,
    Object? recoveryLog = freezed,
    Object? replanCount = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as double,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      nodes: null == nodes
          ? _value.nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<WorkflowNode>,
      replansLeft: freezed == replansLeft
          ? _value.replansLeft
          : replansLeft // ignore: cast_nullable_to_non_nullable
              as int?,
      recoveryLog: freezed == recoveryLog
          ? _value.recoveryLog
          : recoveryLog // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      replanCount: freezed == replanCount
          ? _value.replanCount
          : replanCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkflowRunStateImplCopyWith<$Res>
    implements $WorkflowRunStateCopyWith<$Res> {
  factory _$$WorkflowRunStateImplCopyWith(_$WorkflowRunStateImpl value,
          $Res Function(_$WorkflowRunStateImpl) then) =
      __$$WorkflowRunStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String goal,
      String status,
      double created,
      List<dynamic> results,
      List<WorkflowNode> nodes,
      int? replansLeft,
      List<dynamic>? recoveryLog,
      int? replanCount});
}

/// @nodoc
class __$$WorkflowRunStateImplCopyWithImpl<$Res>
    extends _$WorkflowRunStateCopyWithImpl<$Res, _$WorkflowRunStateImpl>
    implements _$$WorkflowRunStateImplCopyWith<$Res> {
  __$$WorkflowRunStateImplCopyWithImpl(_$WorkflowRunStateImpl _value,
      $Res Function(_$WorkflowRunStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? goal = null,
    Object? status = null,
    Object? created = null,
    Object? results = null,
    Object? nodes = null,
    Object? replansLeft = freezed,
    Object? recoveryLog = freezed,
    Object? replanCount = freezed,
  }) {
    return _then(_$WorkflowRunStateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as double,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      nodes: null == nodes
          ? _value._nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<WorkflowNode>,
      replansLeft: freezed == replansLeft
          ? _value.replansLeft
          : replansLeft // ignore: cast_nullable_to_non_nullable
              as int?,
      recoveryLog: freezed == recoveryLog
          ? _value._recoveryLog
          : recoveryLog // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      replanCount: freezed == replanCount
          ? _value.replanCount
          : replanCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowRunStateImpl implements _WorkflowRunState {
  const _$WorkflowRunStateImpl(
      {required this.id,
      required this.goal,
      required this.status,
      required this.created,
      required final List<dynamic> results,
      required final List<WorkflowNode> nodes,
      this.replansLeft,
      final List<dynamic>? recoveryLog,
      this.replanCount})
      : _results = results,
        _nodes = nodes,
        _recoveryLog = recoveryLog;

  factory _$WorkflowRunStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowRunStateImplFromJson(json);

  @override
  final String id;
  @override
  final String goal;
  @override
  final String status;
  @override
  final double created;
  final List<dynamic> _results;
  @override
  List<dynamic> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  final List<WorkflowNode> _nodes;
  @override
  List<WorkflowNode> get nodes {
    if (_nodes is EqualUnmodifiableListView) return _nodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodes);
  }

  @override
  final int? replansLeft;
  final List<dynamic>? _recoveryLog;
  @override
  List<dynamic>? get recoveryLog {
    final value = _recoveryLog;
    if (value == null) return null;
    if (_recoveryLog is EqualUnmodifiableListView) return _recoveryLog;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? replanCount;

  @override
  String toString() {
    return 'WorkflowRunState(id: $id, goal: $goal, status: $status, created: $created, results: $results, nodes: $nodes, replansLeft: $replansLeft, recoveryLog: $recoveryLog, replanCount: $replanCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowRunStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.created, created) || other.created == created) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            const DeepCollectionEquality().equals(other._nodes, _nodes) &&
            (identical(other.replansLeft, replansLeft) ||
                other.replansLeft == replansLeft) &&
            const DeepCollectionEquality()
                .equals(other._recoveryLog, _recoveryLog) &&
            (identical(other.replanCount, replanCount) ||
                other.replanCount == replanCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      goal,
      status,
      created,
      const DeepCollectionEquality().hash(_results),
      const DeepCollectionEquality().hash(_nodes),
      replansLeft,
      const DeepCollectionEquality().hash(_recoveryLog),
      replanCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowRunStateImplCopyWith<_$WorkflowRunStateImpl> get copyWith =>
      __$$WorkflowRunStateImplCopyWithImpl<_$WorkflowRunStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowRunStateImplToJson(
      this,
    );
  }
}

abstract class _WorkflowRunState implements WorkflowRunState {
  const factory _WorkflowRunState(
      {required final String id,
      required final String goal,
      required final String status,
      required final double created,
      required final List<dynamic> results,
      required final List<WorkflowNode> nodes,
      final int? replansLeft,
      final List<dynamic>? recoveryLog,
      final int? replanCount}) = _$WorkflowRunStateImpl;

  factory _WorkflowRunState.fromJson(Map<String, dynamic> json) =
      _$WorkflowRunStateImpl.fromJson;

  @override
  String get id;
  @override
  String get goal;
  @override
  String get status;
  @override
  double get created;
  @override
  List<dynamic> get results;
  @override
  List<WorkflowNode> get nodes;
  @override
  int? get replansLeft;
  @override
  List<dynamic>? get recoveryLog;
  @override
  int? get replanCount;
  @override
  @JsonKey(ignore: true)
  _$$WorkflowRunStateImplCopyWith<_$WorkflowRunStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkflowsRunsResponse _$WorkflowsRunsResponseFromJson(
    Map<String, dynamic> json) {
  return _WorkflowsRunsResponse.fromJson(json);
}

/// @nodoc
mixin _$WorkflowsRunsResponse {
  List<String> get checkpoints => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkflowsRunsResponseCopyWith<WorkflowsRunsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowsRunsResponseCopyWith<$Res> {
  factory $WorkflowsRunsResponseCopyWith(WorkflowsRunsResponse value,
          $Res Function(WorkflowsRunsResponse) then) =
      _$WorkflowsRunsResponseCopyWithImpl<$Res, WorkflowsRunsResponse>;
  @useResult
  $Res call({List<String> checkpoints});
}

/// @nodoc
class _$WorkflowsRunsResponseCopyWithImpl<$Res,
        $Val extends WorkflowsRunsResponse>
    implements $WorkflowsRunsResponseCopyWith<$Res> {
  _$WorkflowsRunsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkpoints = null,
  }) {
    return _then(_value.copyWith(
      checkpoints: null == checkpoints
          ? _value.checkpoints
          : checkpoints // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkflowsRunsResponseImplCopyWith<$Res>
    implements $WorkflowsRunsResponseCopyWith<$Res> {
  factory _$$WorkflowsRunsResponseImplCopyWith(
          _$WorkflowsRunsResponseImpl value,
          $Res Function(_$WorkflowsRunsResponseImpl) then) =
      __$$WorkflowsRunsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> checkpoints});
}

/// @nodoc
class __$$WorkflowsRunsResponseImplCopyWithImpl<$Res>
    extends _$WorkflowsRunsResponseCopyWithImpl<$Res,
        _$WorkflowsRunsResponseImpl>
    implements _$$WorkflowsRunsResponseImplCopyWith<$Res> {
  __$$WorkflowsRunsResponseImplCopyWithImpl(_$WorkflowsRunsResponseImpl _value,
      $Res Function(_$WorkflowsRunsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkpoints = null,
  }) {
    return _then(_$WorkflowsRunsResponseImpl(
      checkpoints: null == checkpoints
          ? _value._checkpoints
          : checkpoints // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowsRunsResponseImpl implements _WorkflowsRunsResponse {
  const _$WorkflowsRunsResponseImpl({required final List<String> checkpoints})
      : _checkpoints = checkpoints;

  factory _$WorkflowsRunsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowsRunsResponseImplFromJson(json);

  final List<String> _checkpoints;
  @override
  List<String> get checkpoints {
    if (_checkpoints is EqualUnmodifiableListView) return _checkpoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_checkpoints);
  }

  @override
  String toString() {
    return 'WorkflowsRunsResponse(checkpoints: $checkpoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowsRunsResponseImpl &&
            const DeepCollectionEquality()
                .equals(other._checkpoints, _checkpoints));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_checkpoints));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowsRunsResponseImplCopyWith<_$WorkflowsRunsResponseImpl>
      get copyWith => __$$WorkflowsRunsResponseImplCopyWithImpl<
          _$WorkflowsRunsResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowsRunsResponseImplToJson(
      this,
    );
  }
}

abstract class _WorkflowsRunsResponse implements WorkflowsRunsResponse {
  const factory _WorkflowsRunsResponse(
      {required final List<String> checkpoints}) = _$WorkflowsRunsResponseImpl;

  factory _WorkflowsRunsResponse.fromJson(Map<String, dynamic> json) =
      _$WorkflowsRunsResponseImpl.fromJson;

  @override
  List<String> get checkpoints;
  @override
  @JsonKey(ignore: true)
  _$$WorkflowsRunsResponseImplCopyWith<_$WorkflowsRunsResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

WorkflowExecuteResponse _$WorkflowExecuteResponseFromJson(
    Map<String, dynamic> json) {
  return _WorkflowExecuteResponse.fromJson(json);
}

/// @nodoc
mixin _$WorkflowExecuteResponse {
  String get runId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  Map<String, dynamic> get progress => throw _privateConstructorUsedError;
  List<dynamic> get results => throw _privateConstructorUsedError;
  List<dynamic> get recoveryLog => throw _privateConstructorUsedError;
  int get replansUsed => throw _privateConstructorUsedError;
  double? get planConfidence => throw _privateConstructorUsedError;
  bool? get shouldReplan => throw _privateConstructorUsedError;
  int? get stepCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkflowExecuteResponseCopyWith<WorkflowExecuteResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowExecuteResponseCopyWith<$Res> {
  factory $WorkflowExecuteResponseCopyWith(WorkflowExecuteResponse value,
          $Res Function(WorkflowExecuteResponse) then) =
      _$WorkflowExecuteResponseCopyWithImpl<$Res, WorkflowExecuteResponse>;
  @useResult
  $Res call(
      {String runId,
      String status,
      Map<String, dynamic> progress,
      List<dynamic> results,
      List<dynamic> recoveryLog,
      int replansUsed,
      double? planConfidence,
      bool? shouldReplan,
      int? stepCount});
}

/// @nodoc
class _$WorkflowExecuteResponseCopyWithImpl<$Res,
        $Val extends WorkflowExecuteResponse>
    implements $WorkflowExecuteResponseCopyWith<$Res> {
  _$WorkflowExecuteResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? runId = null,
    Object? status = null,
    Object? progress = null,
    Object? results = null,
    Object? recoveryLog = null,
    Object? replansUsed = null,
    Object? planConfidence = freezed,
    Object? shouldReplan = freezed,
    Object? stepCount = freezed,
  }) {
    return _then(_value.copyWith(
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      recoveryLog: null == recoveryLog
          ? _value.recoveryLog
          : recoveryLog // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      replansUsed: null == replansUsed
          ? _value.replansUsed
          : replansUsed // ignore: cast_nullable_to_non_nullable
              as int,
      planConfidence: freezed == planConfidence
          ? _value.planConfidence
          : planConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      shouldReplan: freezed == shouldReplan
          ? _value.shouldReplan
          : shouldReplan // ignore: cast_nullable_to_non_nullable
              as bool?,
      stepCount: freezed == stepCount
          ? _value.stepCount
          : stepCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkflowExecuteResponseImplCopyWith<$Res>
    implements $WorkflowExecuteResponseCopyWith<$Res> {
  factory _$$WorkflowExecuteResponseImplCopyWith(
          _$WorkflowExecuteResponseImpl value,
          $Res Function(_$WorkflowExecuteResponseImpl) then) =
      __$$WorkflowExecuteResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String runId,
      String status,
      Map<String, dynamic> progress,
      List<dynamic> results,
      List<dynamic> recoveryLog,
      int replansUsed,
      double? planConfidence,
      bool? shouldReplan,
      int? stepCount});
}

/// @nodoc
class __$$WorkflowExecuteResponseImplCopyWithImpl<$Res>
    extends _$WorkflowExecuteResponseCopyWithImpl<$Res,
        _$WorkflowExecuteResponseImpl>
    implements _$$WorkflowExecuteResponseImplCopyWith<$Res> {
  __$$WorkflowExecuteResponseImplCopyWithImpl(
      _$WorkflowExecuteResponseImpl _value,
      $Res Function(_$WorkflowExecuteResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? runId = null,
    Object? status = null,
    Object? progress = null,
    Object? results = null,
    Object? recoveryLog = null,
    Object? replansUsed = null,
    Object? planConfidence = freezed,
    Object? shouldReplan = freezed,
    Object? stepCount = freezed,
  }) {
    return _then(_$WorkflowExecuteResponseImpl(
      runId: null == runId
          ? _value.runId
          : runId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _value._progress
          : progress // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      recoveryLog: null == recoveryLog
          ? _value._recoveryLog
          : recoveryLog // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      replansUsed: null == replansUsed
          ? _value.replansUsed
          : replansUsed // ignore: cast_nullable_to_non_nullable
              as int,
      planConfidence: freezed == planConfidence
          ? _value.planConfidence
          : planConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      shouldReplan: freezed == shouldReplan
          ? _value.shouldReplan
          : shouldReplan // ignore: cast_nullable_to_non_nullable
              as bool?,
      stepCount: freezed == stepCount
          ? _value.stepCount
          : stepCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowExecuteResponseImpl implements _WorkflowExecuteResponse {
  const _$WorkflowExecuteResponseImpl(
      {required this.runId,
      required this.status,
      required final Map<String, dynamic> progress,
      required final List<dynamic> results,
      required final List<dynamic> recoveryLog,
      required this.replansUsed,
      this.planConfidence,
      this.shouldReplan,
      this.stepCount})
      : _progress = progress,
        _results = results,
        _recoveryLog = recoveryLog;

  factory _$WorkflowExecuteResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowExecuteResponseImplFromJson(json);

  @override
  final String runId;
  @override
  final String status;
  final Map<String, dynamic> _progress;
  @override
  Map<String, dynamic> get progress {
    if (_progress is EqualUnmodifiableMapView) return _progress;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_progress);
  }

  final List<dynamic> _results;
  @override
  List<dynamic> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  final List<dynamic> _recoveryLog;
  @override
  List<dynamic> get recoveryLog {
    if (_recoveryLog is EqualUnmodifiableListView) return _recoveryLog;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recoveryLog);
  }

  @override
  final int replansUsed;
  @override
  final double? planConfidence;
  @override
  final bool? shouldReplan;
  @override
  final int? stepCount;

  @override
  String toString() {
    return 'WorkflowExecuteResponse(runId: $runId, status: $status, progress: $progress, results: $results, recoveryLog: $recoveryLog, replansUsed: $replansUsed, planConfidence: $planConfidence, shouldReplan: $shouldReplan, stepCount: $stepCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowExecuteResponseImpl &&
            (identical(other.runId, runId) || other.runId == runId) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._progress, _progress) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            const DeepCollectionEquality()
                .equals(other._recoveryLog, _recoveryLog) &&
            (identical(other.replansUsed, replansUsed) ||
                other.replansUsed == replansUsed) &&
            (identical(other.planConfidence, planConfidence) ||
                other.planConfidence == planConfidence) &&
            (identical(other.shouldReplan, shouldReplan) ||
                other.shouldReplan == shouldReplan) &&
            (identical(other.stepCount, stepCount) ||
                other.stepCount == stepCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      runId,
      status,
      const DeepCollectionEquality().hash(_progress),
      const DeepCollectionEquality().hash(_results),
      const DeepCollectionEquality().hash(_recoveryLog),
      replansUsed,
      planConfidence,
      shouldReplan,
      stepCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowExecuteResponseImplCopyWith<_$WorkflowExecuteResponseImpl>
      get copyWith => __$$WorkflowExecuteResponseImplCopyWithImpl<
          _$WorkflowExecuteResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowExecuteResponseImplToJson(
      this,
    );
  }
}

abstract class _WorkflowExecuteResponse implements WorkflowExecuteResponse {
  const factory _WorkflowExecuteResponse(
      {required final String runId,
      required final String status,
      required final Map<String, dynamic> progress,
      required final List<dynamic> results,
      required final List<dynamic> recoveryLog,
      required final int replansUsed,
      final double? planConfidence,
      final bool? shouldReplan,
      final int? stepCount}) = _$WorkflowExecuteResponseImpl;

  factory _WorkflowExecuteResponse.fromJson(Map<String, dynamic> json) =
      _$WorkflowExecuteResponseImpl.fromJson;

  @override
  String get runId;
  @override
  String get status;
  @override
  Map<String, dynamic> get progress;
  @override
  List<dynamic> get results;
  @override
  List<dynamic> get recoveryLog;
  @override
  int get replansUsed;
  @override
  double? get planConfidence;
  @override
  bool? get shouldReplan;
  @override
  int? get stepCount;
  @override
  @JsonKey(ignore: true)
  _$$WorkflowExecuteResponseImplCopyWith<_$WorkflowExecuteResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AutonomousRunResponse _$AutonomousRunResponseFromJson(
    Map<String, dynamic> json) {
  return _AutonomousRunResponse.fromJson(json);
}

/// @nodoc
mixin _$AutonomousRunResponse {
  String get goal => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  Map<String, dynamic> get progress => throw _privateConstructorUsedError;
  List<dynamic> get results => throw _privateConstructorUsedError;
  List<dynamic> get recoveryLog => throw _privateConstructorUsedError;
  int get replansUsed => throw _privateConstructorUsedError;
  double? get planConfidence => throw _privateConstructorUsedError;
  bool? get shouldReplan => throw _privateConstructorUsedError;
  int? get stepCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AutonomousRunResponseCopyWith<AutonomousRunResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AutonomousRunResponseCopyWith<$Res> {
  factory $AutonomousRunResponseCopyWith(AutonomousRunResponse value,
          $Res Function(AutonomousRunResponse) then) =
      _$AutonomousRunResponseCopyWithImpl<$Res, AutonomousRunResponse>;
  @useResult
  $Res call(
      {String goal,
      String status,
      Map<String, dynamic> progress,
      List<dynamic> results,
      List<dynamic> recoveryLog,
      int replansUsed,
      double? planConfidence,
      bool? shouldReplan,
      int? stepCount});
}

/// @nodoc
class _$AutonomousRunResponseCopyWithImpl<$Res,
        $Val extends AutonomousRunResponse>
    implements $AutonomousRunResponseCopyWith<$Res> {
  _$AutonomousRunResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? goal = null,
    Object? status = null,
    Object? progress = null,
    Object? results = null,
    Object? recoveryLog = null,
    Object? replansUsed = null,
    Object? planConfidence = freezed,
    Object? shouldReplan = freezed,
    Object? stepCount = freezed,
  }) {
    return _then(_value.copyWith(
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      recoveryLog: null == recoveryLog
          ? _value.recoveryLog
          : recoveryLog // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      replansUsed: null == replansUsed
          ? _value.replansUsed
          : replansUsed // ignore: cast_nullable_to_non_nullable
              as int,
      planConfidence: freezed == planConfidence
          ? _value.planConfidence
          : planConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      shouldReplan: freezed == shouldReplan
          ? _value.shouldReplan
          : shouldReplan // ignore: cast_nullable_to_non_nullable
              as bool?,
      stepCount: freezed == stepCount
          ? _value.stepCount
          : stepCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AutonomousRunResponseImplCopyWith<$Res>
    implements $AutonomousRunResponseCopyWith<$Res> {
  factory _$$AutonomousRunResponseImplCopyWith(
          _$AutonomousRunResponseImpl value,
          $Res Function(_$AutonomousRunResponseImpl) then) =
      __$$AutonomousRunResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String goal,
      String status,
      Map<String, dynamic> progress,
      List<dynamic> results,
      List<dynamic> recoveryLog,
      int replansUsed,
      double? planConfidence,
      bool? shouldReplan,
      int? stepCount});
}

/// @nodoc
class __$$AutonomousRunResponseImplCopyWithImpl<$Res>
    extends _$AutonomousRunResponseCopyWithImpl<$Res,
        _$AutonomousRunResponseImpl>
    implements _$$AutonomousRunResponseImplCopyWith<$Res> {
  __$$AutonomousRunResponseImplCopyWithImpl(_$AutonomousRunResponseImpl _value,
      $Res Function(_$AutonomousRunResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? goal = null,
    Object? status = null,
    Object? progress = null,
    Object? results = null,
    Object? recoveryLog = null,
    Object? replansUsed = null,
    Object? planConfidence = freezed,
    Object? shouldReplan = freezed,
    Object? stepCount = freezed,
  }) {
    return _then(_$AutonomousRunResponseImpl(
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _value._progress
          : progress // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      recoveryLog: null == recoveryLog
          ? _value._recoveryLog
          : recoveryLog // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      replansUsed: null == replansUsed
          ? _value.replansUsed
          : replansUsed // ignore: cast_nullable_to_non_nullable
              as int,
      planConfidence: freezed == planConfidence
          ? _value.planConfidence
          : planConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      shouldReplan: freezed == shouldReplan
          ? _value.shouldReplan
          : shouldReplan // ignore: cast_nullable_to_non_nullable
              as bool?,
      stepCount: freezed == stepCount
          ? _value.stepCount
          : stepCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AutonomousRunResponseImpl implements _AutonomousRunResponse {
  const _$AutonomousRunResponseImpl(
      {required this.goal,
      required this.status,
      required final Map<String, dynamic> progress,
      required final List<dynamic> results,
      required final List<dynamic> recoveryLog,
      required this.replansUsed,
      this.planConfidence,
      this.shouldReplan,
      this.stepCount})
      : _progress = progress,
        _results = results,
        _recoveryLog = recoveryLog;

  factory _$AutonomousRunResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AutonomousRunResponseImplFromJson(json);

  @override
  final String goal;
  @override
  final String status;
  final Map<String, dynamic> _progress;
  @override
  Map<String, dynamic> get progress {
    if (_progress is EqualUnmodifiableMapView) return _progress;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_progress);
  }

  final List<dynamic> _results;
  @override
  List<dynamic> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  final List<dynamic> _recoveryLog;
  @override
  List<dynamic> get recoveryLog {
    if (_recoveryLog is EqualUnmodifiableListView) return _recoveryLog;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recoveryLog);
  }

  @override
  final int replansUsed;
  @override
  final double? planConfidence;
  @override
  final bool? shouldReplan;
  @override
  final int? stepCount;

  @override
  String toString() {
    return 'AutonomousRunResponse(goal: $goal, status: $status, progress: $progress, results: $results, recoveryLog: $recoveryLog, replansUsed: $replansUsed, planConfidence: $planConfidence, shouldReplan: $shouldReplan, stepCount: $stepCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AutonomousRunResponseImpl &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._progress, _progress) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            const DeepCollectionEquality()
                .equals(other._recoveryLog, _recoveryLog) &&
            (identical(other.replansUsed, replansUsed) ||
                other.replansUsed == replansUsed) &&
            (identical(other.planConfidence, planConfidence) ||
                other.planConfidence == planConfidence) &&
            (identical(other.shouldReplan, shouldReplan) ||
                other.shouldReplan == shouldReplan) &&
            (identical(other.stepCount, stepCount) ||
                other.stepCount == stepCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      goal,
      status,
      const DeepCollectionEquality().hash(_progress),
      const DeepCollectionEquality().hash(_results),
      const DeepCollectionEquality().hash(_recoveryLog),
      replansUsed,
      planConfidence,
      shouldReplan,
      stepCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AutonomousRunResponseImplCopyWith<_$AutonomousRunResponseImpl>
      get copyWith => __$$AutonomousRunResponseImplCopyWithImpl<
          _$AutonomousRunResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AutonomousRunResponseImplToJson(
      this,
    );
  }
}

abstract class _AutonomousRunResponse implements AutonomousRunResponse {
  const factory _AutonomousRunResponse(
      {required final String goal,
      required final String status,
      required final Map<String, dynamic> progress,
      required final List<dynamic> results,
      required final List<dynamic> recoveryLog,
      required final int replansUsed,
      final double? planConfidence,
      final bool? shouldReplan,
      final int? stepCount}) = _$AutonomousRunResponseImpl;

  factory _AutonomousRunResponse.fromJson(Map<String, dynamic> json) =
      _$AutonomousRunResponseImpl.fromJson;

  @override
  String get goal;
  @override
  String get status;
  @override
  Map<String, dynamic> get progress;
  @override
  List<dynamic> get results;
  @override
  List<dynamic> get recoveryLog;
  @override
  int get replansUsed;
  @override
  double? get planConfidence;
  @override
  bool? get shouldReplan;
  @override
  int? get stepCount;
  @override
  @JsonKey(ignore: true)
  _$$AutonomousRunResponseImplCopyWith<_$AutonomousRunResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

LLMProviderInfo _$LLMProviderInfoFromJson(Map<String, dynamic> json) {
  return _LLMProviderInfo.fromJson(json);
}

/// @nodoc
mixin _$LLMProviderInfo {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  bool get configured => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  int get errorCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LLMProviderInfoCopyWith<LLMProviderInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LLMProviderInfoCopyWith<$Res> {
  factory $LLMProviderInfoCopyWith(
          LLMProviderInfo value, $Res Function(LLMProviderInfo) then) =
      _$LLMProviderInfoCopyWithImpl<$Res, LLMProviderInfo>;
  @useResult
  $Res call(
      {String id,
      String label,
      bool configured,
      bool enabled,
      bool active,
      int errorCount});
}

/// @nodoc
class _$LLMProviderInfoCopyWithImpl<$Res, $Val extends LLMProviderInfo>
    implements $LLMProviderInfoCopyWith<$Res> {
  _$LLMProviderInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? configured = null,
    Object? enabled = null,
    Object? active = null,
    Object? errorCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      configured: null == configured
          ? _value.configured
          : configured // ignore: cast_nullable_to_non_nullable
              as bool,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      errorCount: null == errorCount
          ? _value.errorCount
          : errorCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LLMProviderInfoImplCopyWith<$Res>
    implements $LLMProviderInfoCopyWith<$Res> {
  factory _$$LLMProviderInfoImplCopyWith(_$LLMProviderInfoImpl value,
          $Res Function(_$LLMProviderInfoImpl) then) =
      __$$LLMProviderInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      bool configured,
      bool enabled,
      bool active,
      int errorCount});
}

/// @nodoc
class __$$LLMProviderInfoImplCopyWithImpl<$Res>
    extends _$LLMProviderInfoCopyWithImpl<$Res, _$LLMProviderInfoImpl>
    implements _$$LLMProviderInfoImplCopyWith<$Res> {
  __$$LLMProviderInfoImplCopyWithImpl(
      _$LLMProviderInfoImpl _value, $Res Function(_$LLMProviderInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? configured = null,
    Object? enabled = null,
    Object? active = null,
    Object? errorCount = null,
  }) {
    return _then(_$LLMProviderInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      configured: null == configured
          ? _value.configured
          : configured // ignore: cast_nullable_to_non_nullable
              as bool,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      errorCount: null == errorCount
          ? _value.errorCount
          : errorCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LLMProviderInfoImpl implements _LLMProviderInfo {
  const _$LLMProviderInfoImpl(
      {required this.id,
      required this.label,
      required this.configured,
      required this.enabled,
      required this.active,
      required this.errorCount});

  factory _$LLMProviderInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LLMProviderInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final bool configured;
  @override
  final bool enabled;
  @override
  final bool active;
  @override
  final int errorCount;

  @override
  String toString() {
    return 'LLMProviderInfo(id: $id, label: $label, configured: $configured, enabled: $enabled, active: $active, errorCount: $errorCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LLMProviderInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.configured, configured) ||
                other.configured == configured) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, label, configured, enabled, active, errorCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LLMProviderInfoImplCopyWith<_$LLMProviderInfoImpl> get copyWith =>
      __$$LLMProviderInfoImplCopyWithImpl<_$LLMProviderInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LLMProviderInfoImplToJson(
      this,
    );
  }
}

abstract class _LLMProviderInfo implements LLMProviderInfo {
  const factory _LLMProviderInfo(
      {required final String id,
      required final String label,
      required final bool configured,
      required final bool enabled,
      required final bool active,
      required final int errorCount}) = _$LLMProviderInfoImpl;

  factory _LLMProviderInfo.fromJson(Map<String, dynamic> json) =
      _$LLMProviderInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  bool get configured;
  @override
  bool get enabled;
  @override
  bool get active;
  @override
  int get errorCount;
  @override
  @JsonKey(ignore: true)
  _$$LLMProviderInfoImplCopyWith<_$LLMProviderInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LLMProvidersResponse _$LLMProvidersResponseFromJson(Map<String, dynamic> json) {
  return _LLMProvidersResponse.fromJson(json);
}

/// @nodoc
mixin _$LLMProvidersResponse {
  List<LLMProviderInfo> get providers => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LLMProvidersResponseCopyWith<LLMProvidersResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LLMProvidersResponseCopyWith<$Res> {
  factory $LLMProvidersResponseCopyWith(LLMProvidersResponse value,
          $Res Function(LLMProvidersResponse) then) =
      _$LLMProvidersResponseCopyWithImpl<$Res, LLMProvidersResponse>;
  @useResult
  $Res call({List<LLMProviderInfo> providers});
}

/// @nodoc
class _$LLMProvidersResponseCopyWithImpl<$Res,
        $Val extends LLMProvidersResponse>
    implements $LLMProvidersResponseCopyWith<$Res> {
  _$LLMProvidersResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? providers = null,
  }) {
    return _then(_value.copyWith(
      providers: null == providers
          ? _value.providers
          : providers // ignore: cast_nullable_to_non_nullable
              as List<LLMProviderInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LLMProvidersResponseImplCopyWith<$Res>
    implements $LLMProvidersResponseCopyWith<$Res> {
  factory _$$LLMProvidersResponseImplCopyWith(_$LLMProvidersResponseImpl value,
          $Res Function(_$LLMProvidersResponseImpl) then) =
      __$$LLMProvidersResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<LLMProviderInfo> providers});
}

/// @nodoc
class __$$LLMProvidersResponseImplCopyWithImpl<$Res>
    extends _$LLMProvidersResponseCopyWithImpl<$Res, _$LLMProvidersResponseImpl>
    implements _$$LLMProvidersResponseImplCopyWith<$Res> {
  __$$LLMProvidersResponseImplCopyWithImpl(_$LLMProvidersResponseImpl _value,
      $Res Function(_$LLMProvidersResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? providers = null,
  }) {
    return _then(_$LLMProvidersResponseImpl(
      providers: null == providers
          ? _value._providers
          : providers // ignore: cast_nullable_to_non_nullable
              as List<LLMProviderInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LLMProvidersResponseImpl implements _LLMProvidersResponse {
  const _$LLMProvidersResponseImpl(
      {required final List<LLMProviderInfo> providers})
      : _providers = providers;

  factory _$LLMProvidersResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LLMProvidersResponseImplFromJson(json);

  final List<LLMProviderInfo> _providers;
  @override
  List<LLMProviderInfo> get providers {
    if (_providers is EqualUnmodifiableListView) return _providers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_providers);
  }

  @override
  String toString() {
    return 'LLMProvidersResponse(providers: $providers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LLMProvidersResponseImpl &&
            const DeepCollectionEquality()
                .equals(other._providers, _providers));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_providers));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LLMProvidersResponseImplCopyWith<_$LLMProvidersResponseImpl>
      get copyWith =>
          __$$LLMProvidersResponseImplCopyWithImpl<_$LLMProvidersResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LLMProvidersResponseImplToJson(
      this,
    );
  }
}

abstract class _LLMProvidersResponse implements LLMProvidersResponse {
  const factory _LLMProvidersResponse(
          {required final List<LLMProviderInfo> providers}) =
      _$LLMProvidersResponseImpl;

  factory _LLMProvidersResponse.fromJson(Map<String, dynamic> json) =
      _$LLMProvidersResponseImpl.fromJson;

  @override
  List<LLMProviderInfo> get providers;
  @override
  @JsonKey(ignore: true)
  _$$LLMProvidersResponseImplCopyWith<_$LLMProvidersResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

LLMProviderStat _$LLMProviderStatFromJson(Map<String, dynamic> json) {
  return _LLMProviderStat.fromJson(json);
}

/// @nodoc
mixin _$LLMProviderStat {
  double get latencyEmaS => throw _privateConstructorUsedError;
  int get ok => throw _privateConstructorUsedError;
  int get errors => throw _privateConstructorUsedError;
  double get errorRate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LLMProviderStatCopyWith<LLMProviderStat> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LLMProviderStatCopyWith<$Res> {
  factory $LLMProviderStatCopyWith(
          LLMProviderStat value, $Res Function(LLMProviderStat) then) =
      _$LLMProviderStatCopyWithImpl<$Res, LLMProviderStat>;
  @useResult
  $Res call({double latencyEmaS, int ok, int errors, double errorRate});
}

/// @nodoc
class _$LLMProviderStatCopyWithImpl<$Res, $Val extends LLMProviderStat>
    implements $LLMProviderStatCopyWith<$Res> {
  _$LLMProviderStatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latencyEmaS = null,
    Object? ok = null,
    Object? errors = null,
    Object? errorRate = null,
  }) {
    return _then(_value.copyWith(
      latencyEmaS: null == latencyEmaS
          ? _value.latencyEmaS
          : latencyEmaS // ignore: cast_nullable_to_non_nullable
              as double,
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as int,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as int,
      errorRate: null == errorRate
          ? _value.errorRate
          : errorRate // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LLMProviderStatImplCopyWith<$Res>
    implements $LLMProviderStatCopyWith<$Res> {
  factory _$$LLMProviderStatImplCopyWith(_$LLMProviderStatImpl value,
          $Res Function(_$LLMProviderStatImpl) then) =
      __$$LLMProviderStatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double latencyEmaS, int ok, int errors, double errorRate});
}

/// @nodoc
class __$$LLMProviderStatImplCopyWithImpl<$Res>
    extends _$LLMProviderStatCopyWithImpl<$Res, _$LLMProviderStatImpl>
    implements _$$LLMProviderStatImplCopyWith<$Res> {
  __$$LLMProviderStatImplCopyWithImpl(
      _$LLMProviderStatImpl _value, $Res Function(_$LLMProviderStatImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latencyEmaS = null,
    Object? ok = null,
    Object? errors = null,
    Object? errorRate = null,
  }) {
    return _then(_$LLMProviderStatImpl(
      latencyEmaS: null == latencyEmaS
          ? _value.latencyEmaS
          : latencyEmaS // ignore: cast_nullable_to_non_nullable
              as double,
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as int,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as int,
      errorRate: null == errorRate
          ? _value.errorRate
          : errorRate // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LLMProviderStatImpl implements _LLMProviderStat {
  const _$LLMProviderStatImpl(
      {required this.latencyEmaS,
      required this.ok,
      required this.errors,
      required this.errorRate});

  factory _$LLMProviderStatImpl.fromJson(Map<String, dynamic> json) =>
      _$$LLMProviderStatImplFromJson(json);

  @override
  final double latencyEmaS;
  @override
  final int ok;
  @override
  final int errors;
  @override
  final double errorRate;

  @override
  String toString() {
    return 'LLMProviderStat(latencyEmaS: $latencyEmaS, ok: $ok, errors: $errors, errorRate: $errorRate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LLMProviderStatImpl &&
            (identical(other.latencyEmaS, latencyEmaS) ||
                other.latencyEmaS == latencyEmaS) &&
            (identical(other.ok, ok) || other.ok == ok) &&
            (identical(other.errors, errors) || other.errors == errors) &&
            (identical(other.errorRate, errorRate) ||
                other.errorRate == errorRate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, latencyEmaS, ok, errors, errorRate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LLMProviderStatImplCopyWith<_$LLMProviderStatImpl> get copyWith =>
      __$$LLMProviderStatImplCopyWithImpl<_$LLMProviderStatImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LLMProviderStatImplToJson(
      this,
    );
  }
}

abstract class _LLMProviderStat implements LLMProviderStat {
  const factory _LLMProviderStat(
      {required final double latencyEmaS,
      required final int ok,
      required final int errors,
      required final double errorRate}) = _$LLMProviderStatImpl;

  factory _LLMProviderStat.fromJson(Map<String, dynamic> json) =
      _$LLMProviderStatImpl.fromJson;

  @override
  double get latencyEmaS;
  @override
  int get ok;
  @override
  int get errors;
  @override
  double get errorRate;
  @override
  @JsonKey(ignore: true)
  _$$LLMProviderStatImplCopyWith<_$LLMProviderStatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LLMStatsResponse _$LLMStatsResponseFromJson(Map<String, dynamic> json) {
  return _LLMStatsResponse.fromJson(json);
}

/// @nodoc
mixin _$LLMStatsResponse {
  Map<String, LLMProviderStat> get stats => throw _privateConstructorUsedError;
  Map<String, Map<String, dynamic>> get table =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LLMStatsResponseCopyWith<LLMStatsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LLMStatsResponseCopyWith<$Res> {
  factory $LLMStatsResponseCopyWith(
          LLMStatsResponse value, $Res Function(LLMStatsResponse) then) =
      _$LLMStatsResponseCopyWithImpl<$Res, LLMStatsResponse>;
  @useResult
  $Res call(
      {Map<String, LLMProviderStat> stats,
      Map<String, Map<String, dynamic>> table});
}

/// @nodoc
class _$LLMStatsResponseCopyWithImpl<$Res, $Val extends LLMStatsResponse>
    implements $LLMStatsResponseCopyWith<$Res> {
  _$LLMStatsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stats = null,
    Object? table = null,
  }) {
    return _then(_value.copyWith(
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, LLMProviderStat>,
      table: null == table
          ? _value.table
          : table // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LLMStatsResponseImplCopyWith<$Res>
    implements $LLMStatsResponseCopyWith<$Res> {
  factory _$$LLMStatsResponseImplCopyWith(_$LLMStatsResponseImpl value,
          $Res Function(_$LLMStatsResponseImpl) then) =
      __$$LLMStatsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Map<String, LLMProviderStat> stats,
      Map<String, Map<String, dynamic>> table});
}

/// @nodoc
class __$$LLMStatsResponseImplCopyWithImpl<$Res>
    extends _$LLMStatsResponseCopyWithImpl<$Res, _$LLMStatsResponseImpl>
    implements _$$LLMStatsResponseImplCopyWith<$Res> {
  __$$LLMStatsResponseImplCopyWithImpl(_$LLMStatsResponseImpl _value,
      $Res Function(_$LLMStatsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stats = null,
    Object? table = null,
  }) {
    return _then(_$LLMStatsResponseImpl(
      stats: null == stats
          ? _value._stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, LLMProviderStat>,
      table: null == table
          ? _value._table
          : table // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<String, dynamic>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LLMStatsResponseImpl implements _LLMStatsResponse {
  const _$LLMStatsResponseImpl(
      {required final Map<String, LLMProviderStat> stats,
      required final Map<String, Map<String, dynamic>> table})
      : _stats = stats,
        _table = table;

  factory _$LLMStatsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LLMStatsResponseImplFromJson(json);

  final Map<String, LLMProviderStat> _stats;
  @override
  Map<String, LLMProviderStat> get stats {
    if (_stats is EqualUnmodifiableMapView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stats);
  }

  final Map<String, Map<String, dynamic>> _table;
  @override
  Map<String, Map<String, dynamic>> get table {
    if (_table is EqualUnmodifiableMapView) return _table;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_table);
  }

  @override
  String toString() {
    return 'LLMStatsResponse(stats: $stats, table: $table)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LLMStatsResponseImpl &&
            const DeepCollectionEquality().equals(other._stats, _stats) &&
            const DeepCollectionEquality().equals(other._table, _table));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_stats),
      const DeepCollectionEquality().hash(_table));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LLMStatsResponseImplCopyWith<_$LLMStatsResponseImpl> get copyWith =>
      __$$LLMStatsResponseImplCopyWithImpl<_$LLMStatsResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LLMStatsResponseImplToJson(
      this,
    );
  }
}

abstract class _LLMStatsResponse implements LLMStatsResponse {
  const factory _LLMStatsResponse(
          {required final Map<String, LLMProviderStat> stats,
          required final Map<String, Map<String, dynamic>> table}) =
      _$LLMStatsResponseImpl;

  factory _LLMStatsResponse.fromJson(Map<String, dynamic> json) =
      _$LLMStatsResponseImpl.fromJson;

  @override
  Map<String, LLMProviderStat> get stats;
  @override
  Map<String, Map<String, dynamic>> get table;
  @override
  @JsonKey(ignore: true)
  _$$LLMStatsResponseImplCopyWith<_$LLMStatsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LLMStrategyResponse _$LLMStrategyResponseFromJson(Map<String, dynamic> json) {
  return _LLMStrategyResponse.fromJson(json);
}

/// @nodoc
mixin _$LLMStrategyResponse {
  String get strategy => throw _privateConstructorUsedError;
  List<String> get order => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LLMStrategyResponseCopyWith<LLMStrategyResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LLMStrategyResponseCopyWith<$Res> {
  factory $LLMStrategyResponseCopyWith(
          LLMStrategyResponse value, $Res Function(LLMStrategyResponse) then) =
      _$LLMStrategyResponseCopyWithImpl<$Res, LLMStrategyResponse>;
  @useResult
  $Res call({String strategy, List<String> order});
}

/// @nodoc
class _$LLMStrategyResponseCopyWithImpl<$Res, $Val extends LLMStrategyResponse>
    implements $LLMStrategyResponseCopyWith<$Res> {
  _$LLMStrategyResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strategy = null,
    Object? order = null,
  }) {
    return _then(_value.copyWith(
      strategy: null == strategy
          ? _value.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LLMStrategyResponseImplCopyWith<$Res>
    implements $LLMStrategyResponseCopyWith<$Res> {
  factory _$$LLMStrategyResponseImplCopyWith(_$LLMStrategyResponseImpl value,
          $Res Function(_$LLMStrategyResponseImpl) then) =
      __$$LLMStrategyResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String strategy, List<String> order});
}

/// @nodoc
class __$$LLMStrategyResponseImplCopyWithImpl<$Res>
    extends _$LLMStrategyResponseCopyWithImpl<$Res, _$LLMStrategyResponseImpl>
    implements _$$LLMStrategyResponseImplCopyWith<$Res> {
  __$$LLMStrategyResponseImplCopyWithImpl(_$LLMStrategyResponseImpl _value,
      $Res Function(_$LLMStrategyResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strategy = null,
    Object? order = null,
  }) {
    return _then(_$LLMStrategyResponseImpl(
      strategy: null == strategy
          ? _value.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _value._order
          : order // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LLMStrategyResponseImpl implements _LLMStrategyResponse {
  const _$LLMStrategyResponseImpl(
      {required this.strategy, required final List<String> order})
      : _order = order;

  factory _$LLMStrategyResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LLMStrategyResponseImplFromJson(json);

  @override
  final String strategy;
  final List<String> _order;
  @override
  List<String> get order {
    if (_order is EqualUnmodifiableListView) return _order;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_order);
  }

  @override
  String toString() {
    return 'LLMStrategyResponse(strategy: $strategy, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LLMStrategyResponseImpl &&
            (identical(other.strategy, strategy) ||
                other.strategy == strategy) &&
            const DeepCollectionEquality().equals(other._order, _order));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, strategy, const DeepCollectionEquality().hash(_order));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LLMStrategyResponseImplCopyWith<_$LLMStrategyResponseImpl> get copyWith =>
      __$$LLMStrategyResponseImplCopyWithImpl<_$LLMStrategyResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LLMStrategyResponseImplToJson(
      this,
    );
  }
}

abstract class _LLMStrategyResponse implements LLMStrategyResponse {
  const factory _LLMStrategyResponse(
      {required final String strategy,
      required final List<String> order}) = _$LLMStrategyResponseImpl;

  factory _LLMStrategyResponse.fromJson(Map<String, dynamic> json) =
      _$LLMStrategyResponseImpl.fromJson;

  @override
  String get strategy;
  @override
  List<String> get order;
  @override
  @JsonKey(ignore: true)
  _$$LLMStrategyResponseImplCopyWith<_$LLMStrategyResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoleInfo _$RoleInfoFromJson(Map<String, dynamic> json) {
  return _RoleInfo.fromJson(json);
}

/// @nodoc
mixin _$RoleInfo {
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get permissions => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoleInfoCopyWith<RoleInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoleInfoCopyWith<$Res> {
  factory $RoleInfoCopyWith(RoleInfo value, $Res Function(RoleInfo) then) =
      _$RoleInfoCopyWithImpl<$Res, RoleInfo>;
  @useResult
  $Res call({String name, String description, List<String> permissions});
}

/// @nodoc
class _$RoleInfoCopyWithImpl<$Res, $Val extends RoleInfo>
    implements $RoleInfoCopyWith<$Res> {
  _$RoleInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? permissions = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: null == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoleInfoImplCopyWith<$Res>
    implements $RoleInfoCopyWith<$Res> {
  factory _$$RoleInfoImplCopyWith(
          _$RoleInfoImpl value, $Res Function(_$RoleInfoImpl) then) =
      __$$RoleInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String description, List<String> permissions});
}

/// @nodoc
class __$$RoleInfoImplCopyWithImpl<$Res>
    extends _$RoleInfoCopyWithImpl<$Res, _$RoleInfoImpl>
    implements _$$RoleInfoImplCopyWith<$Res> {
  __$$RoleInfoImplCopyWithImpl(
      _$RoleInfoImpl _value, $Res Function(_$RoleInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? permissions = null,
  }) {
    return _then(_$RoleInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: null == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoleInfoImpl implements _RoleInfo {
  const _$RoleInfoImpl(
      {required this.name,
      required this.description,
      required final List<String> permissions})
      : _permissions = permissions;

  factory _$RoleInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoleInfoImplFromJson(json);

  @override
  final String name;
  @override
  final String description;
  final List<String> _permissions;
  @override
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  String toString() {
    return 'RoleInfo(name: $name, description: $description, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoleInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, description,
      const DeepCollectionEquality().hash(_permissions));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoleInfoImplCopyWith<_$RoleInfoImpl> get copyWith =>
      __$$RoleInfoImplCopyWithImpl<_$RoleInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoleInfoImplToJson(
      this,
    );
  }
}

abstract class _RoleInfo implements RoleInfo {
  const factory _RoleInfo(
      {required final String name,
      required final String description,
      required final List<String> permissions}) = _$RoleInfoImpl;

  factory _RoleInfo.fromJson(Map<String, dynamic> json) =
      _$RoleInfoImpl.fromJson;

  @override
  String get name;
  @override
  String get description;
  @override
  List<String> get permissions;
  @override
  @JsonKey(ignore: true)
  _$$RoleInfoImplCopyWith<_$RoleInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminRolesResponse _$AdminRolesResponseFromJson(Map<String, dynamic> json) {
  return _AdminRolesResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminRolesResponse {
  Map<String, RoleInfo> get roles => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminRolesResponseCopyWith<AdminRolesResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminRolesResponseCopyWith<$Res> {
  factory $AdminRolesResponseCopyWith(
          AdminRolesResponse value, $Res Function(AdminRolesResponse) then) =
      _$AdminRolesResponseCopyWithImpl<$Res, AdminRolesResponse>;
  @useResult
  $Res call({Map<String, RoleInfo> roles});
}

/// @nodoc
class _$AdminRolesResponseCopyWithImpl<$Res, $Val extends AdminRolesResponse>
    implements $AdminRolesResponseCopyWith<$Res> {
  _$AdminRolesResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roles = null,
  }) {
    return _then(_value.copyWith(
      roles: null == roles
          ? _value.roles
          : roles // ignore: cast_nullable_to_non_nullable
              as Map<String, RoleInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminRolesResponseImplCopyWith<$Res>
    implements $AdminRolesResponseCopyWith<$Res> {
  factory _$$AdminRolesResponseImplCopyWith(_$AdminRolesResponseImpl value,
          $Res Function(_$AdminRolesResponseImpl) then) =
      __$$AdminRolesResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, RoleInfo> roles});
}

/// @nodoc
class __$$AdminRolesResponseImplCopyWithImpl<$Res>
    extends _$AdminRolesResponseCopyWithImpl<$Res, _$AdminRolesResponseImpl>
    implements _$$AdminRolesResponseImplCopyWith<$Res> {
  __$$AdminRolesResponseImplCopyWithImpl(_$AdminRolesResponseImpl _value,
      $Res Function(_$AdminRolesResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roles = null,
  }) {
    return _then(_$AdminRolesResponseImpl(
      roles: null == roles
          ? _value._roles
          : roles // ignore: cast_nullable_to_non_nullable
              as Map<String, RoleInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminRolesResponseImpl implements _AdminRolesResponse {
  const _$AdminRolesResponseImpl({required final Map<String, RoleInfo> roles})
      : _roles = roles;

  factory _$AdminRolesResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminRolesResponseImplFromJson(json);

  final Map<String, RoleInfo> _roles;
  @override
  Map<String, RoleInfo> get roles {
    if (_roles is EqualUnmodifiableMapView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_roles);
  }

  @override
  String toString() {
    return 'AdminRolesResponse(roles: $roles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminRolesResponseImpl &&
            const DeepCollectionEquality().equals(other._roles, _roles));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_roles));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminRolesResponseImplCopyWith<_$AdminRolesResponseImpl> get copyWith =>
      __$$AdminRolesResponseImplCopyWithImpl<_$AdminRolesResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminRolesResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminRolesResponse implements AdminRolesResponse {
  const factory _AdminRolesResponse(
      {required final Map<String, RoleInfo> roles}) = _$AdminRolesResponseImpl;

  factory _AdminRolesResponse.fromJson(Map<String, dynamic> json) =
      _$AdminRolesResponseImpl.fromJson;

  @override
  Map<String, RoleInfo> get roles;
  @override
  @JsonKey(ignore: true)
  _$$AdminRolesResponseImplCopyWith<_$AdminRolesResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminOrg _$AdminOrgFromJson(Map<String, dynamic> json) {
  return _AdminOrg.fromJson(json);
}

/// @nodoc
mixin _$AdminOrg {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  int? get memberCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminOrgCopyWith<AdminOrg> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminOrgCopyWith<$Res> {
  factory $AdminOrgCopyWith(AdminOrg value, $Res Function(AdminOrg) then) =
      _$AdminOrgCopyWithImpl<$Res, AdminOrg>;
  @useResult
  $Res call({String id, String name, String createdAt, int? memberCount});
}

/// @nodoc
class _$AdminOrgCopyWithImpl<$Res, $Val extends AdminOrg>
    implements $AdminOrgCopyWith<$Res> {
  _$AdminOrgCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? memberCount = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      memberCount: freezed == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminOrgImplCopyWith<$Res>
    implements $AdminOrgCopyWith<$Res> {
  factory _$$AdminOrgImplCopyWith(
          _$AdminOrgImpl value, $Res Function(_$AdminOrgImpl) then) =
      __$$AdminOrgImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String createdAt, int? memberCount});
}

/// @nodoc
class __$$AdminOrgImplCopyWithImpl<$Res>
    extends _$AdminOrgCopyWithImpl<$Res, _$AdminOrgImpl>
    implements _$$AdminOrgImplCopyWith<$Res> {
  __$$AdminOrgImplCopyWithImpl(
      _$AdminOrgImpl _value, $Res Function(_$AdminOrgImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? memberCount = freezed,
  }) {
    return _then(_$AdminOrgImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      memberCount: freezed == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminOrgImpl implements _AdminOrg {
  const _$AdminOrgImpl(
      {required this.id,
      required this.name,
      required this.createdAt,
      this.memberCount});

  factory _$AdminOrgImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminOrgImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String createdAt;
  @override
  final int? memberCount;

  @override
  String toString() {
    return 'AdminOrg(id: $id, name: $name, createdAt: $createdAt, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminOrgImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, createdAt, memberCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminOrgImplCopyWith<_$AdminOrgImpl> get copyWith =>
      __$$AdminOrgImplCopyWithImpl<_$AdminOrgImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminOrgImplToJson(
      this,
    );
  }
}

abstract class _AdminOrg implements AdminOrg {
  const factory _AdminOrg(
      {required final String id,
      required final String name,
      required final String createdAt,
      final int? memberCount}) = _$AdminOrgImpl;

  factory _AdminOrg.fromJson(Map<String, dynamic> json) =
      _$AdminOrgImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get createdAt;
  @override
  int? get memberCount;
  @override
  @JsonKey(ignore: true)
  _$$AdminOrgImplCopyWith<_$AdminOrgImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminOrgsResponse _$AdminOrgsResponseFromJson(Map<String, dynamic> json) {
  return _AdminOrgsResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminOrgsResponse {
  List<AdminOrg> get orgs => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminOrgsResponseCopyWith<AdminOrgsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminOrgsResponseCopyWith<$Res> {
  factory $AdminOrgsResponseCopyWith(
          AdminOrgsResponse value, $Res Function(AdminOrgsResponse) then) =
      _$AdminOrgsResponseCopyWithImpl<$Res, AdminOrgsResponse>;
  @useResult
  $Res call({List<AdminOrg> orgs});
}

/// @nodoc
class _$AdminOrgsResponseCopyWithImpl<$Res, $Val extends AdminOrgsResponse>
    implements $AdminOrgsResponseCopyWith<$Res> {
  _$AdminOrgsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orgs = null,
  }) {
    return _then(_value.copyWith(
      orgs: null == orgs
          ? _value.orgs
          : orgs // ignore: cast_nullable_to_non_nullable
              as List<AdminOrg>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminOrgsResponseImplCopyWith<$Res>
    implements $AdminOrgsResponseCopyWith<$Res> {
  factory _$$AdminOrgsResponseImplCopyWith(_$AdminOrgsResponseImpl value,
          $Res Function(_$AdminOrgsResponseImpl) then) =
      __$$AdminOrgsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AdminOrg> orgs});
}

/// @nodoc
class __$$AdminOrgsResponseImplCopyWithImpl<$Res>
    extends _$AdminOrgsResponseCopyWithImpl<$Res, _$AdminOrgsResponseImpl>
    implements _$$AdminOrgsResponseImplCopyWith<$Res> {
  __$$AdminOrgsResponseImplCopyWithImpl(_$AdminOrgsResponseImpl _value,
      $Res Function(_$AdminOrgsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orgs = null,
  }) {
    return _then(_$AdminOrgsResponseImpl(
      orgs: null == orgs
          ? _value._orgs
          : orgs // ignore: cast_nullable_to_non_nullable
              as List<AdminOrg>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminOrgsResponseImpl implements _AdminOrgsResponse {
  const _$AdminOrgsResponseImpl({required final List<AdminOrg> orgs})
      : _orgs = orgs;

  factory _$AdminOrgsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminOrgsResponseImplFromJson(json);

  final List<AdminOrg> _orgs;
  @override
  List<AdminOrg> get orgs {
    if (_orgs is EqualUnmodifiableListView) return _orgs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_orgs);
  }

  @override
  String toString() {
    return 'AdminOrgsResponse(orgs: $orgs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminOrgsResponseImpl &&
            const DeepCollectionEquality().equals(other._orgs, _orgs));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_orgs));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminOrgsResponseImplCopyWith<_$AdminOrgsResponseImpl> get copyWith =>
      __$$AdminOrgsResponseImplCopyWithImpl<_$AdminOrgsResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminOrgsResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminOrgsResponse implements AdminOrgsResponse {
  const factory _AdminOrgsResponse({required final List<AdminOrg> orgs}) =
      _$AdminOrgsResponseImpl;

  factory _AdminOrgsResponse.fromJson(Map<String, dynamic> json) =
      _$AdminOrgsResponseImpl.fromJson;

  @override
  List<AdminOrg> get orgs;
  @override
  @JsonKey(ignore: true)
  _$$AdminOrgsResponseImplCopyWith<_$AdminOrgsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminOrgResponse _$AdminOrgResponseFromJson(Map<String, dynamic> json) {
  return _AdminOrgResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminOrgResponse {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminOrgResponseCopyWith<AdminOrgResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminOrgResponseCopyWith<$Res> {
  factory $AdminOrgResponseCopyWith(
          AdminOrgResponse value, $Res Function(AdminOrgResponse) then) =
      _$AdminOrgResponseCopyWithImpl<$Res, AdminOrgResponse>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$AdminOrgResponseCopyWithImpl<$Res, $Val extends AdminOrgResponse>
    implements $AdminOrgResponseCopyWith<$Res> {
  _$AdminOrgResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminOrgResponseImplCopyWith<$Res>
    implements $AdminOrgResponseCopyWith<$Res> {
  factory _$$AdminOrgResponseImplCopyWith(_$AdminOrgResponseImpl value,
          $Res Function(_$AdminOrgResponseImpl) then) =
      __$$AdminOrgResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$AdminOrgResponseImplCopyWithImpl<$Res>
    extends _$AdminOrgResponseCopyWithImpl<$Res, _$AdminOrgResponseImpl>
    implements _$$AdminOrgResponseImplCopyWith<$Res> {
  __$$AdminOrgResponseImplCopyWithImpl(_$AdminOrgResponseImpl _value,
      $Res Function(_$AdminOrgResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$AdminOrgResponseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminOrgResponseImpl implements _AdminOrgResponse {
  const _$AdminOrgResponseImpl({required this.id, required this.name});

  factory _$AdminOrgResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminOrgResponseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'AdminOrgResponse(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminOrgResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminOrgResponseImplCopyWith<_$AdminOrgResponseImpl> get copyWith =>
      __$$AdminOrgResponseImplCopyWithImpl<_$AdminOrgResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminOrgResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminOrgResponse implements AdminOrgResponse {
  const factory _AdminOrgResponse(
      {required final String id,
      required final String name}) = _$AdminOrgResponseImpl;

  factory _AdminOrgResponse.fromJson(Map<String, dynamic> json) =
      _$AdminOrgResponseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$AdminOrgResponseImplCopyWith<_$AdminOrgResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrgMember _$OrgMemberFromJson(Map<String, dynamic> json) {
  return _OrgMember.fromJson(json);
}

/// @nodoc
mixin _$OrgMember {
  String get email => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  String? get teamId => throw _privateConstructorUsedError;
  String get joinedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OrgMemberCopyWith<OrgMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrgMemberCopyWith<$Res> {
  factory $OrgMemberCopyWith(OrgMember value, $Res Function(OrgMember) then) =
      _$OrgMemberCopyWithImpl<$Res, OrgMember>;
  @useResult
  $Res call({String email, String role, String? teamId, String joinedAt});
}

/// @nodoc
class _$OrgMemberCopyWithImpl<$Res, $Val extends OrgMember>
    implements $OrgMemberCopyWith<$Res> {
  _$OrgMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? role = null,
    Object? teamId = freezed,
    Object? joinedAt = null,
  }) {
    return _then(_value.copyWith(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      teamId: freezed == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String?,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrgMemberImplCopyWith<$Res>
    implements $OrgMemberCopyWith<$Res> {
  factory _$$OrgMemberImplCopyWith(
          _$OrgMemberImpl value, $Res Function(_$OrgMemberImpl) then) =
      __$$OrgMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String email, String role, String? teamId, String joinedAt});
}

/// @nodoc
class __$$OrgMemberImplCopyWithImpl<$Res>
    extends _$OrgMemberCopyWithImpl<$Res, _$OrgMemberImpl>
    implements _$$OrgMemberImplCopyWith<$Res> {
  __$$OrgMemberImplCopyWithImpl(
      _$OrgMemberImpl _value, $Res Function(_$OrgMemberImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? role = null,
    Object? teamId = freezed,
    Object? joinedAt = null,
  }) {
    return _then(_$OrgMemberImpl(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      teamId: freezed == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String?,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrgMemberImpl implements _OrgMember {
  const _$OrgMemberImpl(
      {required this.email,
      required this.role,
      this.teamId,
      required this.joinedAt});

  factory _$OrgMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrgMemberImplFromJson(json);

  @override
  final String email;
  @override
  final String role;
  @override
  final String? teamId;
  @override
  final String joinedAt;

  @override
  String toString() {
    return 'OrgMember(email: $email, role: $role, teamId: $teamId, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrgMemberImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, email, role, teamId, joinedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OrgMemberImplCopyWith<_$OrgMemberImpl> get copyWith =>
      __$$OrgMemberImplCopyWithImpl<_$OrgMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrgMemberImplToJson(
      this,
    );
  }
}

abstract class _OrgMember implements OrgMember {
  const factory _OrgMember(
      {required final String email,
      required final String role,
      final String? teamId,
      required final String joinedAt}) = _$OrgMemberImpl;

  factory _OrgMember.fromJson(Map<String, dynamic> json) =
      _$OrgMemberImpl.fromJson;

  @override
  String get email;
  @override
  String get role;
  @override
  String? get teamId;
  @override
  String get joinedAt;
  @override
  @JsonKey(ignore: true)
  _$$OrgMemberImplCopyWith<_$OrgMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminOrgMembersResponse _$AdminOrgMembersResponseFromJson(
    Map<String, dynamic> json) {
  return _AdminOrgMembersResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminOrgMembersResponse {
  List<OrgMember> get members => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminOrgMembersResponseCopyWith<AdminOrgMembersResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminOrgMembersResponseCopyWith<$Res> {
  factory $AdminOrgMembersResponseCopyWith(AdminOrgMembersResponse value,
          $Res Function(AdminOrgMembersResponse) then) =
      _$AdminOrgMembersResponseCopyWithImpl<$Res, AdminOrgMembersResponse>;
  @useResult
  $Res call({List<OrgMember> members});
}

/// @nodoc
class _$AdminOrgMembersResponseCopyWithImpl<$Res,
        $Val extends AdminOrgMembersResponse>
    implements $AdminOrgMembersResponseCopyWith<$Res> {
  _$AdminOrgMembersResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? members = null,
  }) {
    return _then(_value.copyWith(
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<OrgMember>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminOrgMembersResponseImplCopyWith<$Res>
    implements $AdminOrgMembersResponseCopyWith<$Res> {
  factory _$$AdminOrgMembersResponseImplCopyWith(
          _$AdminOrgMembersResponseImpl value,
          $Res Function(_$AdminOrgMembersResponseImpl) then) =
      __$$AdminOrgMembersResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<OrgMember> members});
}

/// @nodoc
class __$$AdminOrgMembersResponseImplCopyWithImpl<$Res>
    extends _$AdminOrgMembersResponseCopyWithImpl<$Res,
        _$AdminOrgMembersResponseImpl>
    implements _$$AdminOrgMembersResponseImplCopyWith<$Res> {
  __$$AdminOrgMembersResponseImplCopyWithImpl(
      _$AdminOrgMembersResponseImpl _value,
      $Res Function(_$AdminOrgMembersResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? members = null,
  }) {
    return _then(_$AdminOrgMembersResponseImpl(
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<OrgMember>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminOrgMembersResponseImpl implements _AdminOrgMembersResponse {
  const _$AdminOrgMembersResponseImpl({required final List<OrgMember> members})
      : _members = members;

  factory _$AdminOrgMembersResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminOrgMembersResponseImplFromJson(json);

  final List<OrgMember> _members;
  @override
  List<OrgMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  String toString() {
    return 'AdminOrgMembersResponse(members: $members)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminOrgMembersResponseImpl &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_members));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminOrgMembersResponseImplCopyWith<_$AdminOrgMembersResponseImpl>
      get copyWith => __$$AdminOrgMembersResponseImplCopyWithImpl<
          _$AdminOrgMembersResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminOrgMembersResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminOrgMembersResponse implements AdminOrgMembersResponse {
  const factory _AdminOrgMembersResponse(
      {required final List<OrgMember> members}) = _$AdminOrgMembersResponseImpl;

  factory _AdminOrgMembersResponse.fromJson(Map<String, dynamic> json) =
      _$AdminOrgMembersResponseImpl.fromJson;

  @override
  List<OrgMember> get members;
  @override
  @JsonKey(ignore: true)
  _$$AdminOrgMembersResponseImplCopyWith<_$AdminOrgMembersResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AdminApiKey _$AdminApiKeyFromJson(Map<String, dynamic> json) {
  return _AdminApiKey.fromJson(json);
}

/// @nodoc
mixin _$AdminApiKey {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get prefix => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String? get lastUsedAt => throw _privateConstructorUsedError;
  bool get revoked => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminApiKeyCopyWith<AdminApiKey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminApiKeyCopyWith<$Res> {
  factory $AdminApiKeyCopyWith(
          AdminApiKey value, $Res Function(AdminApiKey) then) =
      _$AdminApiKeyCopyWithImpl<$Res, AdminApiKey>;
  @useResult
  $Res call(
      {String id,
      String name,
      String prefix,
      String createdAt,
      String? lastUsedAt,
      bool revoked});
}

/// @nodoc
class _$AdminApiKeyCopyWithImpl<$Res, $Val extends AdminApiKey>
    implements $AdminApiKeyCopyWith<$Res> {
  _$AdminApiKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? prefix = null,
    Object? createdAt = null,
    Object? lastUsedAt = freezed,
    Object? revoked = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      prefix: null == prefix
          ? _value.prefix
          : prefix // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsedAt: freezed == lastUsedAt
          ? _value.lastUsedAt
          : lastUsedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      revoked: null == revoked
          ? _value.revoked
          : revoked // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminApiKeyImplCopyWith<$Res>
    implements $AdminApiKeyCopyWith<$Res> {
  factory _$$AdminApiKeyImplCopyWith(
          _$AdminApiKeyImpl value, $Res Function(_$AdminApiKeyImpl) then) =
      __$$AdminApiKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String prefix,
      String createdAt,
      String? lastUsedAt,
      bool revoked});
}

/// @nodoc
class __$$AdminApiKeyImplCopyWithImpl<$Res>
    extends _$AdminApiKeyCopyWithImpl<$Res, _$AdminApiKeyImpl>
    implements _$$AdminApiKeyImplCopyWith<$Res> {
  __$$AdminApiKeyImplCopyWithImpl(
      _$AdminApiKeyImpl _value, $Res Function(_$AdminApiKeyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? prefix = null,
    Object? createdAt = null,
    Object? lastUsedAt = freezed,
    Object? revoked = null,
  }) {
    return _then(_$AdminApiKeyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      prefix: null == prefix
          ? _value.prefix
          : prefix // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsedAt: freezed == lastUsedAt
          ? _value.lastUsedAt
          : lastUsedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      revoked: null == revoked
          ? _value.revoked
          : revoked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminApiKeyImpl implements _AdminApiKey {
  const _$AdminApiKeyImpl(
      {required this.id,
      required this.name,
      required this.prefix,
      required this.createdAt,
      this.lastUsedAt,
      required this.revoked});

  factory _$AdminApiKeyImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminApiKeyImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String prefix;
  @override
  final String createdAt;
  @override
  final String? lastUsedAt;
  @override
  final bool revoked;

  @override
  String toString() {
    return 'AdminApiKey(id: $id, name: $name, prefix: $prefix, createdAt: $createdAt, lastUsedAt: $lastUsedAt, revoked: $revoked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminApiKeyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.prefix, prefix) || other.prefix == prefix) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastUsedAt, lastUsedAt) ||
                other.lastUsedAt == lastUsedAt) &&
            (identical(other.revoked, revoked) || other.revoked == revoked));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, prefix, createdAt, lastUsedAt, revoked);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminApiKeyImplCopyWith<_$AdminApiKeyImpl> get copyWith =>
      __$$AdminApiKeyImplCopyWithImpl<_$AdminApiKeyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminApiKeyImplToJson(
      this,
    );
  }
}

abstract class _AdminApiKey implements AdminApiKey {
  const factory _AdminApiKey(
      {required final String id,
      required final String name,
      required final String prefix,
      required final String createdAt,
      final String? lastUsedAt,
      required final bool revoked}) = _$AdminApiKeyImpl;

  factory _AdminApiKey.fromJson(Map<String, dynamic> json) =
      _$AdminApiKeyImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get prefix;
  @override
  String get createdAt;
  @override
  String? get lastUsedAt;
  @override
  bool get revoked;
  @override
  @JsonKey(ignore: true)
  _$$AdminApiKeyImplCopyWith<_$AdminApiKeyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminApiKeysResponse _$AdminApiKeysResponseFromJson(Map<String, dynamic> json) {
  return _AdminApiKeysResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminApiKeysResponse {
  List<AdminApiKey> get keys => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminApiKeysResponseCopyWith<AdminApiKeysResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminApiKeysResponseCopyWith<$Res> {
  factory $AdminApiKeysResponseCopyWith(AdminApiKeysResponse value,
          $Res Function(AdminApiKeysResponse) then) =
      _$AdminApiKeysResponseCopyWithImpl<$Res, AdminApiKeysResponse>;
  @useResult
  $Res call({List<AdminApiKey> keys});
}

/// @nodoc
class _$AdminApiKeysResponseCopyWithImpl<$Res,
        $Val extends AdminApiKeysResponse>
    implements $AdminApiKeysResponseCopyWith<$Res> {
  _$AdminApiKeysResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keys = null,
  }) {
    return _then(_value.copyWith(
      keys: null == keys
          ? _value.keys
          : keys // ignore: cast_nullable_to_non_nullable
              as List<AdminApiKey>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminApiKeysResponseImplCopyWith<$Res>
    implements $AdminApiKeysResponseCopyWith<$Res> {
  factory _$$AdminApiKeysResponseImplCopyWith(_$AdminApiKeysResponseImpl value,
          $Res Function(_$AdminApiKeysResponseImpl) then) =
      __$$AdminApiKeysResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AdminApiKey> keys});
}

/// @nodoc
class __$$AdminApiKeysResponseImplCopyWithImpl<$Res>
    extends _$AdminApiKeysResponseCopyWithImpl<$Res, _$AdminApiKeysResponseImpl>
    implements _$$AdminApiKeysResponseImplCopyWith<$Res> {
  __$$AdminApiKeysResponseImplCopyWithImpl(_$AdminApiKeysResponseImpl _value,
      $Res Function(_$AdminApiKeysResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keys = null,
  }) {
    return _then(_$AdminApiKeysResponseImpl(
      keys: null == keys
          ? _value._keys
          : keys // ignore: cast_nullable_to_non_nullable
              as List<AdminApiKey>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminApiKeysResponseImpl implements _AdminApiKeysResponse {
  const _$AdminApiKeysResponseImpl({required final List<AdminApiKey> keys})
      : _keys = keys;

  factory _$AdminApiKeysResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminApiKeysResponseImplFromJson(json);

  final List<AdminApiKey> _keys;
  @override
  List<AdminApiKey> get keys {
    if (_keys is EqualUnmodifiableListView) return _keys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keys);
  }

  @override
  String toString() {
    return 'AdminApiKeysResponse(keys: $keys)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminApiKeysResponseImpl &&
            const DeepCollectionEquality().equals(other._keys, _keys));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_keys));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminApiKeysResponseImplCopyWith<_$AdminApiKeysResponseImpl>
      get copyWith =>
          __$$AdminApiKeysResponseImplCopyWithImpl<_$AdminApiKeysResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminApiKeysResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminApiKeysResponse implements AdminApiKeysResponse {
  const factory _AdminApiKeysResponse({required final List<AdminApiKey> keys}) =
      _$AdminApiKeysResponseImpl;

  factory _AdminApiKeysResponse.fromJson(Map<String, dynamic> json) =
      _$AdminApiKeysResponseImpl.fromJson;

  @override
  List<AdminApiKey> get keys;
  @override
  @JsonKey(ignore: true)
  _$$AdminApiKeysResponseImplCopyWith<_$AdminApiKeysResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AdminApiKeyCreatedResponse _$AdminApiKeyCreatedResponseFromJson(
    Map<String, dynamic> json) {
  return _AdminApiKeyCreatedResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminApiKeyCreatedResponse {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get key =>
      throw _privateConstructorUsedError; // Only shown once at creation
  String get prefix => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminApiKeyCreatedResponseCopyWith<AdminApiKeyCreatedResponse>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminApiKeyCreatedResponseCopyWith<$Res> {
  factory $AdminApiKeyCreatedResponseCopyWith(AdminApiKeyCreatedResponse value,
          $Res Function(AdminApiKeyCreatedResponse) then) =
      _$AdminApiKeyCreatedResponseCopyWithImpl<$Res,
          AdminApiKeyCreatedResponse>;
  @useResult
  $Res call(
      {String id, String name, String key, String prefix, String createdAt});
}

/// @nodoc
class _$AdminApiKeyCreatedResponseCopyWithImpl<$Res,
        $Val extends AdminApiKeyCreatedResponse>
    implements $AdminApiKeyCreatedResponseCopyWith<$Res> {
  _$AdminApiKeyCreatedResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? key = null,
    Object? prefix = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      prefix: null == prefix
          ? _value.prefix
          : prefix // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminApiKeyCreatedResponseImplCopyWith<$Res>
    implements $AdminApiKeyCreatedResponseCopyWith<$Res> {
  factory _$$AdminApiKeyCreatedResponseImplCopyWith(
          _$AdminApiKeyCreatedResponseImpl value,
          $Res Function(_$AdminApiKeyCreatedResponseImpl) then) =
      __$$AdminApiKeyCreatedResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String name, String key, String prefix, String createdAt});
}

/// @nodoc
class __$$AdminApiKeyCreatedResponseImplCopyWithImpl<$Res>
    extends _$AdminApiKeyCreatedResponseCopyWithImpl<$Res,
        _$AdminApiKeyCreatedResponseImpl>
    implements _$$AdminApiKeyCreatedResponseImplCopyWith<$Res> {
  __$$AdminApiKeyCreatedResponseImplCopyWithImpl(
      _$AdminApiKeyCreatedResponseImpl _value,
      $Res Function(_$AdminApiKeyCreatedResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? key = null,
    Object? prefix = null,
    Object? createdAt = null,
  }) {
    return _then(_$AdminApiKeyCreatedResponseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      prefix: null == prefix
          ? _value.prefix
          : prefix // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminApiKeyCreatedResponseImpl implements _AdminApiKeyCreatedResponse {
  const _$AdminApiKeyCreatedResponseImpl(
      {required this.id,
      required this.name,
      required this.key,
      required this.prefix,
      required this.createdAt});

  factory _$AdminApiKeyCreatedResponseImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$AdminApiKeyCreatedResponseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String key;
// Only shown once at creation
  @override
  final String prefix;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'AdminApiKeyCreatedResponse(id: $id, name: $name, key: $key, prefix: $prefix, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminApiKeyCreatedResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.prefix, prefix) || other.prefix == prefix) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, key, prefix, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminApiKeyCreatedResponseImplCopyWith<_$AdminApiKeyCreatedResponseImpl>
      get copyWith => __$$AdminApiKeyCreatedResponseImplCopyWithImpl<
          _$AdminApiKeyCreatedResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminApiKeyCreatedResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminApiKeyCreatedResponse
    implements AdminApiKeyCreatedResponse {
  const factory _AdminApiKeyCreatedResponse(
      {required final String id,
      required final String name,
      required final String key,
      required final String prefix,
      required final String createdAt}) = _$AdminApiKeyCreatedResponseImpl;

  factory _AdminApiKeyCreatedResponse.fromJson(Map<String, dynamic> json) =
      _$AdminApiKeyCreatedResponseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get key;
  @override // Only shown once at creation
  String get prefix;
  @override
  String get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$AdminApiKeyCreatedResponseImplCopyWith<_$AdminApiKeyCreatedResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AuditEvent _$AuditEventFromJson(Map<String, dynamic> json) {
  return _AuditEvent.fromJson(json);
}

/// @nodoc
mixin _$AuditEvent {
  String get id => throw _privateConstructorUsedError;
  String get actor => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String get target => throw _privateConstructorUsedError;
  Map<String, dynamic> get details => throw _privateConstructorUsedError;
  double get timestamp => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AuditEventCopyWith<AuditEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuditEventCopyWith<$Res> {
  factory $AuditEventCopyWith(
          AuditEvent value, $Res Function(AuditEvent) then) =
      _$AuditEventCopyWithImpl<$Res, AuditEvent>;
  @useResult
  $Res call(
      {String id,
      String actor,
      String action,
      String target,
      Map<String, dynamic> details,
      double timestamp});
}

/// @nodoc
class _$AuditEventCopyWithImpl<$Res, $Val extends AuditEvent>
    implements $AuditEventCopyWith<$Res> {
  _$AuditEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? actor = null,
    Object? action = null,
    Object? target = null,
    Object? details = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      actor: null == actor
          ? _value.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuditEventImplCopyWith<$Res>
    implements $AuditEventCopyWith<$Res> {
  factory _$$AuditEventImplCopyWith(
          _$AuditEventImpl value, $Res Function(_$AuditEventImpl) then) =
      __$$AuditEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String actor,
      String action,
      String target,
      Map<String, dynamic> details,
      double timestamp});
}

/// @nodoc
class __$$AuditEventImplCopyWithImpl<$Res>
    extends _$AuditEventCopyWithImpl<$Res, _$AuditEventImpl>
    implements _$$AuditEventImplCopyWith<$Res> {
  __$$AuditEventImplCopyWithImpl(
      _$AuditEventImpl _value, $Res Function(_$AuditEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? actor = null,
    Object? action = null,
    Object? target = null,
    Object? details = null,
    Object? timestamp = null,
  }) {
    return _then(_$AuditEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      actor: null == actor
          ? _value.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuditEventImpl implements _AuditEvent {
  const _$AuditEventImpl(
      {required this.id,
      required this.actor,
      required this.action,
      required this.target,
      required final Map<String, dynamic> details,
      required this.timestamp})
      : _details = details;

  factory _$AuditEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuditEventImplFromJson(json);

  @override
  final String id;
  @override
  final String actor;
  @override
  final String action;
  @override
  final String target;
  final Map<String, dynamic> _details;
  @override
  Map<String, dynamic> get details {
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_details);
  }

  @override
  final double timestamp;

  @override
  String toString() {
    return 'AuditEvent(id: $id, actor: $actor, action: $action, target: $target, details: $details, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuditEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.actor, actor) || other.actor == actor) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.target, target) || other.target == target) &&
            const DeepCollectionEquality().equals(other._details, _details) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, actor, action, target,
      const DeepCollectionEquality().hash(_details), timestamp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuditEventImplCopyWith<_$AuditEventImpl> get copyWith =>
      __$$AuditEventImplCopyWithImpl<_$AuditEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuditEventImplToJson(
      this,
    );
  }
}

abstract class _AuditEvent implements AuditEvent {
  const factory _AuditEvent(
      {required final String id,
      required final String actor,
      required final String action,
      required final String target,
      required final Map<String, dynamic> details,
      required final double timestamp}) = _$AuditEventImpl;

  factory _AuditEvent.fromJson(Map<String, dynamic> json) =
      _$AuditEventImpl.fromJson;

  @override
  String get id;
  @override
  String get actor;
  @override
  String get action;
  @override
  String get target;
  @override
  Map<String, dynamic> get details;
  @override
  double get timestamp;
  @override
  @JsonKey(ignore: true)
  _$$AuditEventImplCopyWith<_$AuditEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminAuditResponse _$AdminAuditResponseFromJson(Map<String, dynamic> json) {
  return _AdminAuditResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminAuditResponse {
  List<AuditEvent> get events => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminAuditResponseCopyWith<AdminAuditResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminAuditResponseCopyWith<$Res> {
  factory $AdminAuditResponseCopyWith(
          AdminAuditResponse value, $Res Function(AdminAuditResponse) then) =
      _$AdminAuditResponseCopyWithImpl<$Res, AdminAuditResponse>;
  @useResult
  $Res call({List<AuditEvent> events});
}

/// @nodoc
class _$AdminAuditResponseCopyWithImpl<$Res, $Val extends AdminAuditResponse>
    implements $AdminAuditResponseCopyWith<$Res> {
  _$AdminAuditResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? events = null,
  }) {
    return _then(_value.copyWith(
      events: null == events
          ? _value.events
          : events // ignore: cast_nullable_to_non_nullable
              as List<AuditEvent>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminAuditResponseImplCopyWith<$Res>
    implements $AdminAuditResponseCopyWith<$Res> {
  factory _$$AdminAuditResponseImplCopyWith(_$AdminAuditResponseImpl value,
          $Res Function(_$AdminAuditResponseImpl) then) =
      __$$AdminAuditResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AuditEvent> events});
}

/// @nodoc
class __$$AdminAuditResponseImplCopyWithImpl<$Res>
    extends _$AdminAuditResponseCopyWithImpl<$Res, _$AdminAuditResponseImpl>
    implements _$$AdminAuditResponseImplCopyWith<$Res> {
  __$$AdminAuditResponseImplCopyWithImpl(_$AdminAuditResponseImpl _value,
      $Res Function(_$AdminAuditResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? events = null,
  }) {
    return _then(_$AdminAuditResponseImpl(
      events: null == events
          ? _value._events
          : events // ignore: cast_nullable_to_non_nullable
              as List<AuditEvent>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminAuditResponseImpl implements _AdminAuditResponse {
  const _$AdminAuditResponseImpl({required final List<AuditEvent> events})
      : _events = events;

  factory _$AdminAuditResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminAuditResponseImplFromJson(json);

  final List<AuditEvent> _events;
  @override
  List<AuditEvent> get events {
    if (_events is EqualUnmodifiableListView) return _events;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_events);
  }

  @override
  String toString() {
    return 'AdminAuditResponse(events: $events)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminAuditResponseImpl &&
            const DeepCollectionEquality().equals(other._events, _events));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_events));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminAuditResponseImplCopyWith<_$AdminAuditResponseImpl> get copyWith =>
      __$$AdminAuditResponseImplCopyWithImpl<_$AdminAuditResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminAuditResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminAuditResponse implements AdminAuditResponse {
  const factory _AdminAuditResponse({required final List<AuditEvent> events}) =
      _$AdminAuditResponseImpl;

  factory _AdminAuditResponse.fromJson(Map<String, dynamic> json) =
      _$AdminAuditResponseImpl.fromJson;

  @override
  List<AuditEvent> get events;
  @override
  @JsonKey(ignore: true)
  _$$AdminAuditResponseImplCopyWith<_$AdminAuditResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminUsageResponse _$AdminUsageResponseFromJson(Map<String, dynamic> json) {
  return _AdminUsageResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminUsageResponse {
  Map<String, dynamic> get summary => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminUsageResponseCopyWith<AdminUsageResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminUsageResponseCopyWith<$Res> {
  factory $AdminUsageResponseCopyWith(
          AdminUsageResponse value, $Res Function(AdminUsageResponse) then) =
      _$AdminUsageResponseCopyWithImpl<$Res, AdminUsageResponse>;
  @useResult
  $Res call({Map<String, dynamic> summary});
}

/// @nodoc
class _$AdminUsageResponseCopyWithImpl<$Res, $Val extends AdminUsageResponse>
    implements $AdminUsageResponseCopyWith<$Res> {
  _$AdminUsageResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summary = null,
  }) {
    return _then(_value.copyWith(
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminUsageResponseImplCopyWith<$Res>
    implements $AdminUsageResponseCopyWith<$Res> {
  factory _$$AdminUsageResponseImplCopyWith(_$AdminUsageResponseImpl value,
          $Res Function(_$AdminUsageResponseImpl) then) =
      __$$AdminUsageResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, dynamic> summary});
}

/// @nodoc
class __$$AdminUsageResponseImplCopyWithImpl<$Res>
    extends _$AdminUsageResponseCopyWithImpl<$Res, _$AdminUsageResponseImpl>
    implements _$$AdminUsageResponseImplCopyWith<$Res> {
  __$$AdminUsageResponseImplCopyWithImpl(_$AdminUsageResponseImpl _value,
      $Res Function(_$AdminUsageResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summary = null,
  }) {
    return _then(_$AdminUsageResponseImpl(
      summary: null == summary
          ? _value._summary
          : summary // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminUsageResponseImpl implements _AdminUsageResponse {
  const _$AdminUsageResponseImpl({required final Map<String, dynamic> summary})
      : _summary = summary;

  factory _$AdminUsageResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminUsageResponseImplFromJson(json);

  final Map<String, dynamic> _summary;
  @override
  Map<String, dynamic> get summary {
    if (_summary is EqualUnmodifiableMapView) return _summary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_summary);
  }

  @override
  String toString() {
    return 'AdminUsageResponse(summary: $summary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminUsageResponseImpl &&
            const DeepCollectionEquality().equals(other._summary, _summary));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_summary));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminUsageResponseImplCopyWith<_$AdminUsageResponseImpl> get copyWith =>
      __$$AdminUsageResponseImplCopyWithImpl<_$AdminUsageResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminUsageResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminUsageResponse implements AdminUsageResponse {
  const factory _AdminUsageResponse(
      {required final Map<String, dynamic> summary}) = _$AdminUsageResponseImpl;

  factory _AdminUsageResponse.fromJson(Map<String, dynamic> json) =
      _$AdminUsageResponseImpl.fromJson;

  @override
  Map<String, dynamic> get summary;
  @override
  @JsonKey(ignore: true)
  _$$AdminUsageResponseImplCopyWith<_$AdminUsageResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminDashboardResponse _$AdminDashboardResponseFromJson(
    Map<String, dynamic> json) {
  return _AdminDashboardResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminDashboardResponse {
  Map<String, dynamic> get metrics => throw _privateConstructorUsedError;
  Map<String, dynamic> get agents => throw _privateConstructorUsedError;
  Map<String, dynamic> get providers => throw _privateConstructorUsedError;
  int get queueDepth => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminDashboardResponseCopyWith<AdminDashboardResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminDashboardResponseCopyWith<$Res> {
  factory $AdminDashboardResponseCopyWith(AdminDashboardResponse value,
          $Res Function(AdminDashboardResponse) then) =
      _$AdminDashboardResponseCopyWithImpl<$Res, AdminDashboardResponse>;
  @useResult
  $Res call(
      {Map<String, dynamic> metrics,
      Map<String, dynamic> agents,
      Map<String, dynamic> providers,
      int queueDepth});
}

/// @nodoc
class _$AdminDashboardResponseCopyWithImpl<$Res,
        $Val extends AdminDashboardResponse>
    implements $AdminDashboardResponseCopyWith<$Res> {
  _$AdminDashboardResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metrics = null,
    Object? agents = null,
    Object? providers = null,
    Object? queueDepth = null,
  }) {
    return _then(_value.copyWith(
      metrics: null == metrics
          ? _value.metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      agents: null == agents
          ? _value.agents
          : agents // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      providers: null == providers
          ? _value.providers
          : providers // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      queueDepth: null == queueDepth
          ? _value.queueDepth
          : queueDepth // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminDashboardResponseImplCopyWith<$Res>
    implements $AdminDashboardResponseCopyWith<$Res> {
  factory _$$AdminDashboardResponseImplCopyWith(
          _$AdminDashboardResponseImpl value,
          $Res Function(_$AdminDashboardResponseImpl) then) =
      __$$AdminDashboardResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Map<String, dynamic> metrics,
      Map<String, dynamic> agents,
      Map<String, dynamic> providers,
      int queueDepth});
}

/// @nodoc
class __$$AdminDashboardResponseImplCopyWithImpl<$Res>
    extends _$AdminDashboardResponseCopyWithImpl<$Res,
        _$AdminDashboardResponseImpl>
    implements _$$AdminDashboardResponseImplCopyWith<$Res> {
  __$$AdminDashboardResponseImplCopyWithImpl(
      _$AdminDashboardResponseImpl _value,
      $Res Function(_$AdminDashboardResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metrics = null,
    Object? agents = null,
    Object? providers = null,
    Object? queueDepth = null,
  }) {
    return _then(_$AdminDashboardResponseImpl(
      metrics: null == metrics
          ? _value._metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      agents: null == agents
          ? _value._agents
          : agents // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      providers: null == providers
          ? _value._providers
          : providers // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      queueDepth: null == queueDepth
          ? _value.queueDepth
          : queueDepth // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminDashboardResponseImpl implements _AdminDashboardResponse {
  const _$AdminDashboardResponseImpl(
      {required final Map<String, dynamic> metrics,
      required final Map<String, dynamic> agents,
      required final Map<String, dynamic> providers,
      required this.queueDepth})
      : _metrics = metrics,
        _agents = agents,
        _providers = providers;

  factory _$AdminDashboardResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminDashboardResponseImplFromJson(json);

  final Map<String, dynamic> _metrics;
  @override
  Map<String, dynamic> get metrics {
    if (_metrics is EqualUnmodifiableMapView) return _metrics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metrics);
  }

  final Map<String, dynamic> _agents;
  @override
  Map<String, dynamic> get agents {
    if (_agents is EqualUnmodifiableMapView) return _agents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_agents);
  }

  final Map<String, dynamic> _providers;
  @override
  Map<String, dynamic> get providers {
    if (_providers is EqualUnmodifiableMapView) return _providers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_providers);
  }

  @override
  final int queueDepth;

  @override
  String toString() {
    return 'AdminDashboardResponse(metrics: $metrics, agents: $agents, providers: $providers, queueDepth: $queueDepth)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminDashboardResponseImpl &&
            const DeepCollectionEquality().equals(other._metrics, _metrics) &&
            const DeepCollectionEquality().equals(other._agents, _agents) &&
            const DeepCollectionEquality()
                .equals(other._providers, _providers) &&
            (identical(other.queueDepth, queueDepth) ||
                other.queueDepth == queueDepth));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_metrics),
      const DeepCollectionEquality().hash(_agents),
      const DeepCollectionEquality().hash(_providers),
      queueDepth);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminDashboardResponseImplCopyWith<_$AdminDashboardResponseImpl>
      get copyWith => __$$AdminDashboardResponseImplCopyWithImpl<
          _$AdminDashboardResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminDashboardResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminDashboardResponse implements AdminDashboardResponse {
  const factory _AdminDashboardResponse(
      {required final Map<String, dynamic> metrics,
      required final Map<String, dynamic> agents,
      required final Map<String, dynamic> providers,
      required final int queueDepth}) = _$AdminDashboardResponseImpl;

  factory _AdminDashboardResponse.fromJson(Map<String, dynamic> json) =
      _$AdminDashboardResponseImpl.fromJson;

  @override
  Map<String, dynamic> get metrics;
  @override
  Map<String, dynamic> get agents;
  @override
  Map<String, dynamic> get providers;
  @override
  int get queueDepth;
  @override
  @JsonKey(ignore: true)
  _$$AdminDashboardResponseImplCopyWith<_$AdminDashboardResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AdminOwnerModeResponse _$AdminOwnerModeResponseFromJson(
    Map<String, dynamic> json) {
  return _AdminOwnerModeResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminOwnerModeResponse {
  String get mode => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AdminOwnerModeResponseCopyWith<AdminOwnerModeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminOwnerModeResponseCopyWith<$Res> {
  factory $AdminOwnerModeResponseCopyWith(AdminOwnerModeResponse value,
          $Res Function(AdminOwnerModeResponse) then) =
      _$AdminOwnerModeResponseCopyWithImpl<$Res, AdminOwnerModeResponse>;
  @useResult
  $Res call({String mode, String? message});
}

/// @nodoc
class _$AdminOwnerModeResponseCopyWithImpl<$Res,
        $Val extends AdminOwnerModeResponse>
    implements $AdminOwnerModeResponseCopyWith<$Res> {
  _$AdminOwnerModeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminOwnerModeResponseImplCopyWith<$Res>
    implements $AdminOwnerModeResponseCopyWith<$Res> {
  factory _$$AdminOwnerModeResponseImplCopyWith(
          _$AdminOwnerModeResponseImpl value,
          $Res Function(_$AdminOwnerModeResponseImpl) then) =
      __$$AdminOwnerModeResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String mode, String? message});
}

/// @nodoc
class __$$AdminOwnerModeResponseImplCopyWithImpl<$Res>
    extends _$AdminOwnerModeResponseCopyWithImpl<$Res,
        _$AdminOwnerModeResponseImpl>
    implements _$$AdminOwnerModeResponseImplCopyWith<$Res> {
  __$$AdminOwnerModeResponseImplCopyWithImpl(
      _$AdminOwnerModeResponseImpl _value,
      $Res Function(_$AdminOwnerModeResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? message = freezed,
  }) {
    return _then(_$AdminOwnerModeResponseImpl(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminOwnerModeResponseImpl implements _AdminOwnerModeResponse {
  const _$AdminOwnerModeResponseImpl({required this.mode, this.message});

  factory _$AdminOwnerModeResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminOwnerModeResponseImplFromJson(json);

  @override
  final String mode;
  @override
  final String? message;

  @override
  String toString() {
    return 'AdminOwnerModeResponse(mode: $mode, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminOwnerModeResponseImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, mode, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminOwnerModeResponseImplCopyWith<_$AdminOwnerModeResponseImpl>
      get copyWith => __$$AdminOwnerModeResponseImplCopyWithImpl<
          _$AdminOwnerModeResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminOwnerModeResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminOwnerModeResponse implements AdminOwnerModeResponse {
  const factory _AdminOwnerModeResponse(
      {required final String mode,
      final String? message}) = _$AdminOwnerModeResponseImpl;

  factory _AdminOwnerModeResponse.fromJson(Map<String, dynamic> json) =
      _$AdminOwnerModeResponseImpl.fromJson;

  @override
  String get mode;
  @override
  String? get message;
  @override
  @JsonKey(ignore: true)
  _$$AdminOwnerModeResponseImplCopyWith<_$AdminOwnerModeResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

LearningFeedbackResponse _$LearningFeedbackResponseFromJson(
    Map<String, dynamic> json) {
  return _LearningFeedbackResponse.fromJson(json);
}

/// @nodoc
mixin _$LearningFeedbackResponse {
  bool get recorded => throw _privateConstructorUsedError;
  Map<String, dynamic> get stats => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LearningFeedbackResponseCopyWith<LearningFeedbackResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LearningFeedbackResponseCopyWith<$Res> {
  factory $LearningFeedbackResponseCopyWith(LearningFeedbackResponse value,
          $Res Function(LearningFeedbackResponse) then) =
      _$LearningFeedbackResponseCopyWithImpl<$Res, LearningFeedbackResponse>;
  @useResult
  $Res call({bool recorded, Map<String, dynamic> stats});
}

/// @nodoc
class _$LearningFeedbackResponseCopyWithImpl<$Res,
        $Val extends LearningFeedbackResponse>
    implements $LearningFeedbackResponseCopyWith<$Res> {
  _$LearningFeedbackResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recorded = null,
    Object? stats = null,
  }) {
    return _then(_value.copyWith(
      recorded: null == recorded
          ? _value.recorded
          : recorded // ignore: cast_nullable_to_non_nullable
              as bool,
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LearningFeedbackResponseImplCopyWith<$Res>
    implements $LearningFeedbackResponseCopyWith<$Res> {
  factory _$$LearningFeedbackResponseImplCopyWith(
          _$LearningFeedbackResponseImpl value,
          $Res Function(_$LearningFeedbackResponseImpl) then) =
      __$$LearningFeedbackResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool recorded, Map<String, dynamic> stats});
}

/// @nodoc
class __$$LearningFeedbackResponseImplCopyWithImpl<$Res>
    extends _$LearningFeedbackResponseCopyWithImpl<$Res,
        _$LearningFeedbackResponseImpl>
    implements _$$LearningFeedbackResponseImplCopyWith<$Res> {
  __$$LearningFeedbackResponseImplCopyWithImpl(
      _$LearningFeedbackResponseImpl _value,
      $Res Function(_$LearningFeedbackResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recorded = null,
    Object? stats = null,
  }) {
    return _then(_$LearningFeedbackResponseImpl(
      recorded: null == recorded
          ? _value.recorded
          : recorded // ignore: cast_nullable_to_non_nullable
              as bool,
      stats: null == stats
          ? _value._stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LearningFeedbackResponseImpl implements _LearningFeedbackResponse {
  const _$LearningFeedbackResponseImpl(
      {required this.recorded, required final Map<String, dynamic> stats})
      : _stats = stats;

  factory _$LearningFeedbackResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LearningFeedbackResponseImplFromJson(json);

  @override
  final bool recorded;
  final Map<String, dynamic> _stats;
  @override
  Map<String, dynamic> get stats {
    if (_stats is EqualUnmodifiableMapView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stats);
  }

  @override
  String toString() {
    return 'LearningFeedbackResponse(recorded: $recorded, stats: $stats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LearningFeedbackResponseImpl &&
            (identical(other.recorded, recorded) ||
                other.recorded == recorded) &&
            const DeepCollectionEquality().equals(other._stats, _stats));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, recorded, const DeepCollectionEquality().hash(_stats));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LearningFeedbackResponseImplCopyWith<_$LearningFeedbackResponseImpl>
      get copyWith => __$$LearningFeedbackResponseImplCopyWithImpl<
          _$LearningFeedbackResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LearningFeedbackResponseImplToJson(
      this,
    );
  }
}

abstract class _LearningFeedbackResponse implements LearningFeedbackResponse {
  const factory _LearningFeedbackResponse(
          {required final bool recorded,
          required final Map<String, dynamic> stats}) =
      _$LearningFeedbackResponseImpl;

  factory _LearningFeedbackResponse.fromJson(Map<String, dynamic> json) =
      _$LearningFeedbackResponseImpl.fromJson;

  @override
  bool get recorded;
  @override
  Map<String, dynamic> get stats;
  @override
  @JsonKey(ignore: true)
  _$$LearningFeedbackResponseImplCopyWith<_$LearningFeedbackResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

FeedbackStats _$FeedbackStatsFromJson(Map<String, dynamic> json) {
  return _FeedbackStats.fromJson(json);
}

/// @nodoc
mixin _$FeedbackStats {
  int get total => throw _privateConstructorUsedError;
  int get positive => throw _privateConstructorUsedError;
  int get negative => throw _privateConstructorUsedError;
  double? get satisfaction => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeedbackStatsCopyWith<FeedbackStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedbackStatsCopyWith<$Res> {
  factory $FeedbackStatsCopyWith(
          FeedbackStats value, $Res Function(FeedbackStats) then) =
      _$FeedbackStatsCopyWithImpl<$Res, FeedbackStats>;
  @useResult
  $Res call({int total, int positive, int negative, double? satisfaction});
}

/// @nodoc
class _$FeedbackStatsCopyWithImpl<$Res, $Val extends FeedbackStats>
    implements $FeedbackStatsCopyWith<$Res> {
  _$FeedbackStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? positive = null,
    Object? negative = null,
    Object? satisfaction = freezed,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      positive: null == positive
          ? _value.positive
          : positive // ignore: cast_nullable_to_non_nullable
              as int,
      negative: null == negative
          ? _value.negative
          : negative // ignore: cast_nullable_to_non_nullable
              as int,
      satisfaction: freezed == satisfaction
          ? _value.satisfaction
          : satisfaction // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedbackStatsImplCopyWith<$Res>
    implements $FeedbackStatsCopyWith<$Res> {
  factory _$$FeedbackStatsImplCopyWith(
          _$FeedbackStatsImpl value, $Res Function(_$FeedbackStatsImpl) then) =
      __$$FeedbackStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, int positive, int negative, double? satisfaction});
}

/// @nodoc
class __$$FeedbackStatsImplCopyWithImpl<$Res>
    extends _$FeedbackStatsCopyWithImpl<$Res, _$FeedbackStatsImpl>
    implements _$$FeedbackStatsImplCopyWith<$Res> {
  __$$FeedbackStatsImplCopyWithImpl(
      _$FeedbackStatsImpl _value, $Res Function(_$FeedbackStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? positive = null,
    Object? negative = null,
    Object? satisfaction = freezed,
  }) {
    return _then(_$FeedbackStatsImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      positive: null == positive
          ? _value.positive
          : positive // ignore: cast_nullable_to_non_nullable
              as int,
      negative: null == negative
          ? _value.negative
          : negative // ignore: cast_nullable_to_non_nullable
              as int,
      satisfaction: freezed == satisfaction
          ? _value.satisfaction
          : satisfaction // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedbackStatsImpl implements _FeedbackStats {
  const _$FeedbackStatsImpl(
      {required this.total,
      required this.positive,
      required this.negative,
      this.satisfaction});

  factory _$FeedbackStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedbackStatsImplFromJson(json);

  @override
  final int total;
  @override
  final int positive;
  @override
  final int negative;
  @override
  final double? satisfaction;

  @override
  String toString() {
    return 'FeedbackStats(total: $total, positive: $positive, negative: $negative, satisfaction: $satisfaction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedbackStatsImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.positive, positive) ||
                other.positive == positive) &&
            (identical(other.negative, negative) ||
                other.negative == negative) &&
            (identical(other.satisfaction, satisfaction) ||
                other.satisfaction == satisfaction));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, total, positive, negative, satisfaction);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedbackStatsImplCopyWith<_$FeedbackStatsImpl> get copyWith =>
      __$$FeedbackStatsImplCopyWithImpl<_$FeedbackStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedbackStatsImplToJson(
      this,
    );
  }
}

abstract class _FeedbackStats implements FeedbackStats {
  const factory _FeedbackStats(
      {required final int total,
      required final int positive,
      required final int negative,
      final double? satisfaction}) = _$FeedbackStatsImpl;

  factory _FeedbackStats.fromJson(Map<String, dynamic> json) =
      _$FeedbackStatsImpl.fromJson;

  @override
  int get total;
  @override
  int get positive;
  @override
  int get negative;
  @override
  double? get satisfaction;
  @override
  @JsonKey(ignore: true)
  _$$FeedbackStatsImplCopyWith<_$FeedbackStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Lesson _$LessonFromJson(Map<String, dynamic> json) {
  return _Lesson.fromJson(json);
}

/// @nodoc
mixin _$Lesson {
  double get ts => throw _privateConstructorUsedError;
  String get goal => throw _privateConstructorUsedError;
  String get comment => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LessonCopyWith<Lesson> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LessonCopyWith<$Res> {
  factory $LessonCopyWith(Lesson value, $Res Function(Lesson) then) =
      _$LessonCopyWithImpl<$Res, Lesson>;
  @useResult
  $Res call({double ts, String goal, String comment});
}

/// @nodoc
class _$LessonCopyWithImpl<$Res, $Val extends Lesson>
    implements $LessonCopyWith<$Res> {
  _$LessonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ts = null,
    Object? goal = null,
    Object? comment = null,
  }) {
    return _then(_value.copyWith(
      ts: null == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as double,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      comment: null == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LessonImplCopyWith<$Res> implements $LessonCopyWith<$Res> {
  factory _$$LessonImplCopyWith(
          _$LessonImpl value, $Res Function(_$LessonImpl) then) =
      __$$LessonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double ts, String goal, String comment});
}

/// @nodoc
class __$$LessonImplCopyWithImpl<$Res>
    extends _$LessonCopyWithImpl<$Res, _$LessonImpl>
    implements _$$LessonImplCopyWith<$Res> {
  __$$LessonImplCopyWithImpl(
      _$LessonImpl _value, $Res Function(_$LessonImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ts = null,
    Object? goal = null,
    Object? comment = null,
  }) {
    return _then(_$LessonImpl(
      ts: null == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as double,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      comment: null == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LessonImpl implements _Lesson {
  const _$LessonImpl(
      {required this.ts, required this.goal, required this.comment});

  factory _$LessonImpl.fromJson(Map<String, dynamic> json) =>
      _$$LessonImplFromJson(json);

  @override
  final double ts;
  @override
  final String goal;
  @override
  final String comment;

  @override
  String toString() {
    return 'Lesson(ts: $ts, goal: $goal, comment: $comment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LessonImpl &&
            (identical(other.ts, ts) || other.ts == ts) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.comment, comment) || other.comment == comment));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, ts, goal, comment);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LessonImplCopyWith<_$LessonImpl> get copyWith =>
      __$$LessonImplCopyWithImpl<_$LessonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LessonImplToJson(
      this,
    );
  }
}

abstract class _Lesson implements Lesson {
  const factory _Lesson(
      {required final double ts,
      required final String goal,
      required final String comment}) = _$LessonImpl;

  factory _Lesson.fromJson(Map<String, dynamic> json) = _$LessonImpl.fromJson;

  @override
  double get ts;
  @override
  String get goal;
  @override
  String get comment;
  @override
  @JsonKey(ignore: true)
  _$$LessonImplCopyWith<_$LessonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LearningStatsResponse _$LearningStatsResponseFromJson(
    Map<String, dynamic> json) {
  return _LearningStatsResponse.fromJson(json);
}

/// @nodoc
mixin _$LearningStatsResponse {
  FeedbackStats get feedback => throw _privateConstructorUsedError;
  List<Lesson> get lessons => throw _privateConstructorUsedError;
  Map<String, dynamic> get prompts => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LearningStatsResponseCopyWith<LearningStatsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LearningStatsResponseCopyWith<$Res> {
  factory $LearningStatsResponseCopyWith(LearningStatsResponse value,
          $Res Function(LearningStatsResponse) then) =
      _$LearningStatsResponseCopyWithImpl<$Res, LearningStatsResponse>;
  @useResult
  $Res call(
      {FeedbackStats feedback,
      List<Lesson> lessons,
      Map<String, dynamic> prompts});

  $FeedbackStatsCopyWith<$Res> get feedback;
}

/// @nodoc
class _$LearningStatsResponseCopyWithImpl<$Res,
        $Val extends LearningStatsResponse>
    implements $LearningStatsResponseCopyWith<$Res> {
  _$LearningStatsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? feedback = null,
    Object? lessons = null,
    Object? prompts = null,
  }) {
    return _then(_value.copyWith(
      feedback: null == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as FeedbackStats,
      lessons: null == lessons
          ? _value.lessons
          : lessons // ignore: cast_nullable_to_non_nullable
              as List<Lesson>,
      prompts: null == prompts
          ? _value.prompts
          : prompts // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $FeedbackStatsCopyWith<$Res> get feedback {
    return $FeedbackStatsCopyWith<$Res>(_value.feedback, (value) {
      return _then(_value.copyWith(feedback: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LearningStatsResponseImplCopyWith<$Res>
    implements $LearningStatsResponseCopyWith<$Res> {
  factory _$$LearningStatsResponseImplCopyWith(
          _$LearningStatsResponseImpl value,
          $Res Function(_$LearningStatsResponseImpl) then) =
      __$$LearningStatsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {FeedbackStats feedback,
      List<Lesson> lessons,
      Map<String, dynamic> prompts});

  @override
  $FeedbackStatsCopyWith<$Res> get feedback;
}

/// @nodoc
class __$$LearningStatsResponseImplCopyWithImpl<$Res>
    extends _$LearningStatsResponseCopyWithImpl<$Res,
        _$LearningStatsResponseImpl>
    implements _$$LearningStatsResponseImplCopyWith<$Res> {
  __$$LearningStatsResponseImplCopyWithImpl(_$LearningStatsResponseImpl _value,
      $Res Function(_$LearningStatsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? feedback = null,
    Object? lessons = null,
    Object? prompts = null,
  }) {
    return _then(_$LearningStatsResponseImpl(
      feedback: null == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as FeedbackStats,
      lessons: null == lessons
          ? _value._lessons
          : lessons // ignore: cast_nullable_to_non_nullable
              as List<Lesson>,
      prompts: null == prompts
          ? _value._prompts
          : prompts // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LearningStatsResponseImpl implements _LearningStatsResponse {
  const _$LearningStatsResponseImpl(
      {required this.feedback,
      required final List<Lesson> lessons,
      required final Map<String, dynamic> prompts})
      : _lessons = lessons,
        _prompts = prompts;

  factory _$LearningStatsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LearningStatsResponseImplFromJson(json);

  @override
  final FeedbackStats feedback;
  final List<Lesson> _lessons;
  @override
  List<Lesson> get lessons {
    if (_lessons is EqualUnmodifiableListView) return _lessons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lessons);
  }

  final Map<String, dynamic> _prompts;
  @override
  Map<String, dynamic> get prompts {
    if (_prompts is EqualUnmodifiableMapView) return _prompts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_prompts);
  }

  @override
  String toString() {
    return 'LearningStatsResponse(feedback: $feedback, lessons: $lessons, prompts: $prompts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LearningStatsResponseImpl &&
            (identical(other.feedback, feedback) ||
                other.feedback == feedback) &&
            const DeepCollectionEquality().equals(other._lessons, _lessons) &&
            const DeepCollectionEquality().equals(other._prompts, _prompts));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      feedback,
      const DeepCollectionEquality().hash(_lessons),
      const DeepCollectionEquality().hash(_prompts));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LearningStatsResponseImplCopyWith<_$LearningStatsResponseImpl>
      get copyWith => __$$LearningStatsResponseImplCopyWithImpl<
          _$LearningStatsResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LearningStatsResponseImplToJson(
      this,
    );
  }
}

abstract class _LearningStatsResponse implements LearningStatsResponse {
  const factory _LearningStatsResponse(
          {required final FeedbackStats feedback,
          required final List<Lesson> lessons,
          required final Map<String, dynamic> prompts}) =
      _$LearningStatsResponseImpl;

  factory _LearningStatsResponse.fromJson(Map<String, dynamic> json) =
      _$LearningStatsResponseImpl.fromJson;

  @override
  FeedbackStats get feedback;
  @override
  List<Lesson> get lessons;
  @override
  Map<String, dynamic> get prompts;
  @override
  @JsonKey(ignore: true)
  _$$LearningStatsResponseImplCopyWith<_$LearningStatsResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ExperienceEpisode _$ExperienceEpisodeFromJson(Map<String, dynamic> json) {
  return _ExperienceEpisode.fromJson(json);
}

/// @nodoc
mixin _$ExperienceEpisode {
  int get id => throw _privateConstructorUsedError;
  double get ts => throw _privateConstructorUsedError;
  String get goal => throw _privateConstructorUsedError;
  List<dynamic> get steps => throw _privateConstructorUsedError;
  String get outcome => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  double? get similarity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExperienceEpisodeCopyWith<ExperienceEpisode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExperienceEpisodeCopyWith<$Res> {
  factory $ExperienceEpisodeCopyWith(
          ExperienceEpisode value, $Res Function(ExperienceEpisode) then) =
      _$ExperienceEpisodeCopyWithImpl<$Res, ExperienceEpisode>;
  @useResult
  $Res call(
      {int id,
      double ts,
      String goal,
      List<dynamic> steps,
      String outcome,
      double confidence,
      double? similarity});
}

/// @nodoc
class _$ExperienceEpisodeCopyWithImpl<$Res, $Val extends ExperienceEpisode>
    implements $ExperienceEpisodeCopyWith<$Res> {
  _$ExperienceEpisodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ts = null,
    Object? goal = null,
    Object? steps = null,
    Object? outcome = null,
    Object? confidence = null,
    Object? similarity = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      ts: null == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as double,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      outcome: null == outcome
          ? _value.outcome
          : outcome // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      similarity: freezed == similarity
          ? _value.similarity
          : similarity // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExperienceEpisodeImplCopyWith<$Res>
    implements $ExperienceEpisodeCopyWith<$Res> {
  factory _$$ExperienceEpisodeImplCopyWith(_$ExperienceEpisodeImpl value,
          $Res Function(_$ExperienceEpisodeImpl) then) =
      __$$ExperienceEpisodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      double ts,
      String goal,
      List<dynamic> steps,
      String outcome,
      double confidence,
      double? similarity});
}

/// @nodoc
class __$$ExperienceEpisodeImplCopyWithImpl<$Res>
    extends _$ExperienceEpisodeCopyWithImpl<$Res, _$ExperienceEpisodeImpl>
    implements _$$ExperienceEpisodeImplCopyWith<$Res> {
  __$$ExperienceEpisodeImplCopyWithImpl(_$ExperienceEpisodeImpl _value,
      $Res Function(_$ExperienceEpisodeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ts = null,
    Object? goal = null,
    Object? steps = null,
    Object? outcome = null,
    Object? confidence = null,
    Object? similarity = freezed,
  }) {
    return _then(_$ExperienceEpisodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      ts: null == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as double,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      steps: null == steps
          ? _value._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      outcome: null == outcome
          ? _value.outcome
          : outcome // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      similarity: freezed == similarity
          ? _value.similarity
          : similarity // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExperienceEpisodeImpl implements _ExperienceEpisode {
  const _$ExperienceEpisodeImpl(
      {required this.id,
      required this.ts,
      required this.goal,
      required final List<dynamic> steps,
      required this.outcome,
      required this.confidence,
      this.similarity})
      : _steps = steps;

  factory _$ExperienceEpisodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExperienceEpisodeImplFromJson(json);

  @override
  final int id;
  @override
  final double ts;
  @override
  final String goal;
  final List<dynamic> _steps;
  @override
  List<dynamic> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  @override
  final String outcome;
  @override
  final double confidence;
  @override
  final double? similarity;

  @override
  String toString() {
    return 'ExperienceEpisode(id: $id, ts: $ts, goal: $goal, steps: $steps, outcome: $outcome, confidence: $confidence, similarity: $similarity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExperienceEpisodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ts, ts) || other.ts == ts) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.outcome, outcome) || other.outcome == outcome) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.similarity, similarity) ||
                other.similarity == similarity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      ts,
      goal,
      const DeepCollectionEquality().hash(_steps),
      outcome,
      confidence,
      similarity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExperienceEpisodeImplCopyWith<_$ExperienceEpisodeImpl> get copyWith =>
      __$$ExperienceEpisodeImplCopyWithImpl<_$ExperienceEpisodeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExperienceEpisodeImplToJson(
      this,
    );
  }
}

abstract class _ExperienceEpisode implements ExperienceEpisode {
  const factory _ExperienceEpisode(
      {required final int id,
      required final double ts,
      required final String goal,
      required final List<dynamic> steps,
      required final String outcome,
      required final double confidence,
      final double? similarity}) = _$ExperienceEpisodeImpl;

  factory _ExperienceEpisode.fromJson(Map<String, dynamic> json) =
      _$ExperienceEpisodeImpl.fromJson;

  @override
  int get id;
  @override
  double get ts;
  @override
  String get goal;
  @override
  List<dynamic> get steps;
  @override
  String get outcome;
  @override
  double get confidence;
  @override
  double? get similarity;
  @override
  @JsonKey(ignore: true)
  _$$ExperienceEpisodeImplCopyWith<_$ExperienceEpisodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LearningExperienceResponse _$LearningExperienceResponseFromJson(
    Map<String, dynamic> json) {
  return _LearningExperienceResponse.fromJson(json);
}

/// @nodoc
mixin _$LearningExperienceResponse {
  List<ExperienceEpisode>? get similar => throw _privateConstructorUsedError;
  List<ExperienceEpisode>? get history => throw _privateConstructorUsedError;
  Map<String, dynamic>? get successRate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LearningExperienceResponseCopyWith<LearningExperienceResponse>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LearningExperienceResponseCopyWith<$Res> {
  factory $LearningExperienceResponseCopyWith(LearningExperienceResponse value,
          $Res Function(LearningExperienceResponse) then) =
      _$LearningExperienceResponseCopyWithImpl<$Res,
          LearningExperienceResponse>;
  @useResult
  $Res call(
      {List<ExperienceEpisode>? similar,
      List<ExperienceEpisode>? history,
      Map<String, dynamic>? successRate});
}

/// @nodoc
class _$LearningExperienceResponseCopyWithImpl<$Res,
        $Val extends LearningExperienceResponse>
    implements $LearningExperienceResponseCopyWith<$Res> {
  _$LearningExperienceResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? similar = freezed,
    Object? history = freezed,
    Object? successRate = freezed,
  }) {
    return _then(_value.copyWith(
      similar: freezed == similar
          ? _value.similar
          : similar // ignore: cast_nullable_to_non_nullable
              as List<ExperienceEpisode>?,
      history: freezed == history
          ? _value.history
          : history // ignore: cast_nullable_to_non_nullable
              as List<ExperienceEpisode>?,
      successRate: freezed == successRate
          ? _value.successRate
          : successRate // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LearningExperienceResponseImplCopyWith<$Res>
    implements $LearningExperienceResponseCopyWith<$Res> {
  factory _$$LearningExperienceResponseImplCopyWith(
          _$LearningExperienceResponseImpl value,
          $Res Function(_$LearningExperienceResponseImpl) then) =
      __$$LearningExperienceResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ExperienceEpisode>? similar,
      List<ExperienceEpisode>? history,
      Map<String, dynamic>? successRate});
}

/// @nodoc
class __$$LearningExperienceResponseImplCopyWithImpl<$Res>
    extends _$LearningExperienceResponseCopyWithImpl<$Res,
        _$LearningExperienceResponseImpl>
    implements _$$LearningExperienceResponseImplCopyWith<$Res> {
  __$$LearningExperienceResponseImplCopyWithImpl(
      _$LearningExperienceResponseImpl _value,
      $Res Function(_$LearningExperienceResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? similar = freezed,
    Object? history = freezed,
    Object? successRate = freezed,
  }) {
    return _then(_$LearningExperienceResponseImpl(
      similar: freezed == similar
          ? _value._similar
          : similar // ignore: cast_nullable_to_non_nullable
              as List<ExperienceEpisode>?,
      history: freezed == history
          ? _value._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<ExperienceEpisode>?,
      successRate: freezed == successRate
          ? _value._successRate
          : successRate // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LearningExperienceResponseImpl implements _LearningExperienceResponse {
  const _$LearningExperienceResponseImpl(
      {final List<ExperienceEpisode>? similar,
      final List<ExperienceEpisode>? history,
      final Map<String, dynamic>? successRate})
      : _similar = similar,
        _history = history,
        _successRate = successRate;

  factory _$LearningExperienceResponseImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$LearningExperienceResponseImplFromJson(json);

  final List<ExperienceEpisode>? _similar;
  @override
  List<ExperienceEpisode>? get similar {
    final value = _similar;
    if (value == null) return null;
    if (_similar is EqualUnmodifiableListView) return _similar;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ExperienceEpisode>? _history;
  @override
  List<ExperienceEpisode>? get history {
    final value = _history;
    if (value == null) return null;
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _successRate;
  @override
  Map<String, dynamic>? get successRate {
    final value = _successRate;
    if (value == null) return null;
    if (_successRate is EqualUnmodifiableMapView) return _successRate;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'LearningExperienceResponse(similar: $similar, history: $history, successRate: $successRate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LearningExperienceResponseImpl &&
            const DeepCollectionEquality().equals(other._similar, _similar) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            const DeepCollectionEquality()
                .equals(other._successRate, _successRate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_similar),
      const DeepCollectionEquality().hash(_history),
      const DeepCollectionEquality().hash(_successRate));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LearningExperienceResponseImplCopyWith<_$LearningExperienceResponseImpl>
      get copyWith => __$$LearningExperienceResponseImplCopyWithImpl<
          _$LearningExperienceResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LearningExperienceResponseImplToJson(
      this,
    );
  }
}

abstract class _LearningExperienceResponse
    implements LearningExperienceResponse {
  const factory _LearningExperienceResponse(
          {final List<ExperienceEpisode>? similar,
          final List<ExperienceEpisode>? history,
          final Map<String, dynamic>? successRate}) =
      _$LearningExperienceResponseImpl;

  factory _LearningExperienceResponse.fromJson(Map<String, dynamic> json) =
      _$LearningExperienceResponseImpl.fromJson;

  @override
  List<ExperienceEpisode>? get similar;
  @override
  List<ExperienceEpisode>? get history;
  @override
  Map<String, dynamic>? get successRate;
  @override
  @JsonKey(ignore: true)
  _$$LearningExperienceResponseImplCopyWith<_$LearningExperienceResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

LearningCompressResponse _$LearningCompressResponseFromJson(
    Map<String, dynamic> json) {
  return _LearningCompressResponse.fromJson(json);
}

/// @nodoc
mixin _$LearningCompressResponse {
  bool get dryRun => throw _privateConstructorUsedError;
  String get memoryType => throw _privateConstructorUsedError;
  Map<String, dynamic> get result => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LearningCompressResponseCopyWith<LearningCompressResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LearningCompressResponseCopyWith<$Res> {
  factory $LearningCompressResponseCopyWith(LearningCompressResponse value,
          $Res Function(LearningCompressResponse) then) =
      _$LearningCompressResponseCopyWithImpl<$Res, LearningCompressResponse>;
  @useResult
  $Res call({bool dryRun, String memoryType, Map<String, dynamic> result});
}

/// @nodoc
class _$LearningCompressResponseCopyWithImpl<$Res,
        $Val extends LearningCompressResponse>
    implements $LearningCompressResponseCopyWith<$Res> {
  _$LearningCompressResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dryRun = null,
    Object? memoryType = null,
    Object? result = null,
  }) {
    return _then(_value.copyWith(
      dryRun: null == dryRun
          ? _value.dryRun
          : dryRun // ignore: cast_nullable_to_non_nullable
              as bool,
      memoryType: null == memoryType
          ? _value.memoryType
          : memoryType // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LearningCompressResponseImplCopyWith<$Res>
    implements $LearningCompressResponseCopyWith<$Res> {
  factory _$$LearningCompressResponseImplCopyWith(
          _$LearningCompressResponseImpl value,
          $Res Function(_$LearningCompressResponseImpl) then) =
      __$$LearningCompressResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool dryRun, String memoryType, Map<String, dynamic> result});
}

/// @nodoc
class __$$LearningCompressResponseImplCopyWithImpl<$Res>
    extends _$LearningCompressResponseCopyWithImpl<$Res,
        _$LearningCompressResponseImpl>
    implements _$$LearningCompressResponseImplCopyWith<$Res> {
  __$$LearningCompressResponseImplCopyWithImpl(
      _$LearningCompressResponseImpl _value,
      $Res Function(_$LearningCompressResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dryRun = null,
    Object? memoryType = null,
    Object? result = null,
  }) {
    return _then(_$LearningCompressResponseImpl(
      dryRun: null == dryRun
          ? _value.dryRun
          : dryRun // ignore: cast_nullable_to_non_nullable
              as bool,
      memoryType: null == memoryType
          ? _value.memoryType
          : memoryType // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _value._result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LearningCompressResponseImpl implements _LearningCompressResponse {
  const _$LearningCompressResponseImpl(
      {required this.dryRun,
      required this.memoryType,
      required final Map<String, dynamic> result})
      : _result = result;

  factory _$LearningCompressResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LearningCompressResponseImplFromJson(json);

  @override
  final bool dryRun;
  @override
  final String memoryType;
  final Map<String, dynamic> _result;
  @override
  Map<String, dynamic> get result {
    if (_result is EqualUnmodifiableMapView) return _result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_result);
  }

  @override
  String toString() {
    return 'LearningCompressResponse(dryRun: $dryRun, memoryType: $memoryType, result: $result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LearningCompressResponseImpl &&
            (identical(other.dryRun, dryRun) || other.dryRun == dryRun) &&
            (identical(other.memoryType, memoryType) ||
                other.memoryType == memoryType) &&
            const DeepCollectionEquality().equals(other._result, _result));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, dryRun, memoryType,
      const DeepCollectionEquality().hash(_result));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LearningCompressResponseImplCopyWith<_$LearningCompressResponseImpl>
      get copyWith => __$$LearningCompressResponseImplCopyWithImpl<
          _$LearningCompressResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LearningCompressResponseImplToJson(
      this,
    );
  }
}

abstract class _LearningCompressResponse implements LearningCompressResponse {
  const factory _LearningCompressResponse(
          {required final bool dryRun,
          required final String memoryType,
          required final Map<String, dynamic> result}) =
      _$LearningCompressResponseImpl;

  factory _LearningCompressResponse.fromJson(Map<String, dynamic> json) =
      _$LearningCompressResponseImpl.fromJson;

  @override
  bool get dryRun;
  @override
  String get memoryType;
  @override
  Map<String, dynamic> get result;
  @override
  @JsonKey(ignore: true)
  _$$LearningCompressResponseImplCopyWith<_$LearningCompressResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PromptVariant _$PromptVariantFromJson(Map<String, dynamic> json) {
  return _PromptVariant.fromJson(json);
}

/// @nodoc
mixin _$PromptVariant {
  int get ok => throw _privateConstructorUsedError;
  int get fail => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PromptVariantCopyWith<PromptVariant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromptVariantCopyWith<$Res> {
  factory $PromptVariantCopyWith(
          PromptVariant value, $Res Function(PromptVariant) then) =
      _$PromptVariantCopyWithImpl<$Res, PromptVariant>;
  @useResult
  $Res call({int ok, int fail, double score});
}

/// @nodoc
class _$PromptVariantCopyWithImpl<$Res, $Val extends PromptVariant>
    implements $PromptVariantCopyWith<$Res> {
  _$PromptVariantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? fail = null,
    Object? score = null,
  }) {
    return _then(_value.copyWith(
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as int,
      fail: null == fail
          ? _value.fail
          : fail // ignore: cast_nullable_to_non_nullable
              as int,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PromptVariantImplCopyWith<$Res>
    implements $PromptVariantCopyWith<$Res> {
  factory _$$PromptVariantImplCopyWith(
          _$PromptVariantImpl value, $Res Function(_$PromptVariantImpl) then) =
      __$$PromptVariantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int ok, int fail, double score});
}

/// @nodoc
class __$$PromptVariantImplCopyWithImpl<$Res>
    extends _$PromptVariantCopyWithImpl<$Res, _$PromptVariantImpl>
    implements _$$PromptVariantImplCopyWith<$Res> {
  __$$PromptVariantImplCopyWithImpl(
      _$PromptVariantImpl _value, $Res Function(_$PromptVariantImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? fail = null,
    Object? score = null,
  }) {
    return _then(_$PromptVariantImpl(
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as int,
      fail: null == fail
          ? _value.fail
          : fail // ignore: cast_nullable_to_non_nullable
              as int,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PromptVariantImpl implements _PromptVariant {
  const _$PromptVariantImpl(
      {required this.ok, required this.fail, required this.score});

  factory _$PromptVariantImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromptVariantImplFromJson(json);

  @override
  final int ok;
  @override
  final int fail;
  @override
  final double score;

  @override
  String toString() {
    return 'PromptVariant(ok: $ok, fail: $fail, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromptVariantImpl &&
            (identical(other.ok, ok) || other.ok == ok) &&
            (identical(other.fail, fail) || other.fail == fail) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, ok, fail, score);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PromptVariantImplCopyWith<_$PromptVariantImpl> get copyWith =>
      __$$PromptVariantImplCopyWithImpl<_$PromptVariantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PromptVariantImplToJson(
      this,
    );
  }
}

abstract class _PromptVariant implements PromptVariant {
  const factory _PromptVariant(
      {required final int ok,
      required final int fail,
      required final double score}) = _$PromptVariantImpl;

  factory _PromptVariant.fromJson(Map<String, dynamic> json) =
      _$PromptVariantImpl.fromJson;

  @override
  int get ok;
  @override
  int get fail;
  @override
  double get score;
  @override
  @JsonKey(ignore: true)
  _$$PromptVariantImplCopyWith<_$PromptVariantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LearningPromptsResponse _$LearningPromptsResponseFromJson(
    Map<String, dynamic> json) {
  return _LearningPromptsResponse.fromJson(json);
}

/// @nodoc
mixin _$LearningPromptsResponse {
  Map<String, Map<String, PromptVariant>> get prompts =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LearningPromptsResponseCopyWith<LearningPromptsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LearningPromptsResponseCopyWith<$Res> {
  factory $LearningPromptsResponseCopyWith(LearningPromptsResponse value,
          $Res Function(LearningPromptsResponse) then) =
      _$LearningPromptsResponseCopyWithImpl<$Res, LearningPromptsResponse>;
  @useResult
  $Res call({Map<String, Map<String, PromptVariant>> prompts});
}

/// @nodoc
class _$LearningPromptsResponseCopyWithImpl<$Res,
        $Val extends LearningPromptsResponse>
    implements $LearningPromptsResponseCopyWith<$Res> {
  _$LearningPromptsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompts = null,
  }) {
    return _then(_value.copyWith(
      prompts: null == prompts
          ? _value.prompts
          : prompts // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<String, PromptVariant>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LearningPromptsResponseImplCopyWith<$Res>
    implements $LearningPromptsResponseCopyWith<$Res> {
  factory _$$LearningPromptsResponseImplCopyWith(
          _$LearningPromptsResponseImpl value,
          $Res Function(_$LearningPromptsResponseImpl) then) =
      __$$LearningPromptsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, Map<String, PromptVariant>> prompts});
}

/// @nodoc
class __$$LearningPromptsResponseImplCopyWithImpl<$Res>
    extends _$LearningPromptsResponseCopyWithImpl<$Res,
        _$LearningPromptsResponseImpl>
    implements _$$LearningPromptsResponseImplCopyWith<$Res> {
  __$$LearningPromptsResponseImplCopyWithImpl(
      _$LearningPromptsResponseImpl _value,
      $Res Function(_$LearningPromptsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompts = null,
  }) {
    return _then(_$LearningPromptsResponseImpl(
      prompts: null == prompts
          ? _value._prompts
          : prompts // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<String, PromptVariant>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LearningPromptsResponseImpl implements _LearningPromptsResponse {
  const _$LearningPromptsResponseImpl(
      {required final Map<String, Map<String, PromptVariant>> prompts})
      : _prompts = prompts;

  factory _$LearningPromptsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LearningPromptsResponseImplFromJson(json);

  final Map<String, Map<String, PromptVariant>> _prompts;
  @override
  Map<String, Map<String, PromptVariant>> get prompts {
    if (_prompts is EqualUnmodifiableMapView) return _prompts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_prompts);
  }

  @override
  String toString() {
    return 'LearningPromptsResponse(prompts: $prompts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LearningPromptsResponseImpl &&
            const DeepCollectionEquality().equals(other._prompts, _prompts));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_prompts));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LearningPromptsResponseImplCopyWith<_$LearningPromptsResponseImpl>
      get copyWith => __$$LearningPromptsResponseImplCopyWithImpl<
          _$LearningPromptsResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LearningPromptsResponseImplToJson(
      this,
    );
  }
}

abstract class _LearningPromptsResponse implements LearningPromptsResponse {
  const factory _LearningPromptsResponse(
          {required final Map<String, Map<String, PromptVariant>> prompts}) =
      _$LearningPromptsResponseImpl;

  factory _LearningPromptsResponse.fromJson(Map<String, dynamic> json) =
      _$LearningPromptsResponseImpl.fromJson;

  @override
  Map<String, Map<String, PromptVariant>> get prompts;
  @override
  @JsonKey(ignore: true)
  _$$LearningPromptsResponseImplCopyWith<_$LearningPromptsResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

RAGStatsResponse _$RAGStatsResponseFromJson(Map<String, dynamic> json) {
  return _RAGStatsResponse.fromJson(json);
}

/// @nodoc
mixin _$RAGStatsResponse {
  int get totalDocuments => throw _privateConstructorUsedError;
  int get totalChunks => throw _privateConstructorUsedError;
  String get indexType => throw _privateConstructorUsedError;
  double get indexSizeMb => throw _privateConstructorUsedError;
  Map<String, dynamic> get searchEngines => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RAGStatsResponseCopyWith<RAGStatsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RAGStatsResponseCopyWith<$Res> {
  factory $RAGStatsResponseCopyWith(
          RAGStatsResponse value, $Res Function(RAGStatsResponse) then) =
      _$RAGStatsResponseCopyWithImpl<$Res, RAGStatsResponse>;
  @useResult
  $Res call(
      {int totalDocuments,
      int totalChunks,
      String indexType,
      double indexSizeMb,
      Map<String, dynamic> searchEngines});
}

/// @nodoc
class _$RAGStatsResponseCopyWithImpl<$Res, $Val extends RAGStatsResponse>
    implements $RAGStatsResponseCopyWith<$Res> {
  _$RAGStatsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalDocuments = null,
    Object? totalChunks = null,
    Object? indexType = null,
    Object? indexSizeMb = null,
    Object? searchEngines = null,
  }) {
    return _then(_value.copyWith(
      totalDocuments: null == totalDocuments
          ? _value.totalDocuments
          : totalDocuments // ignore: cast_nullable_to_non_nullable
              as int,
      totalChunks: null == totalChunks
          ? _value.totalChunks
          : totalChunks // ignore: cast_nullable_to_non_nullable
              as int,
      indexType: null == indexType
          ? _value.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as String,
      indexSizeMb: null == indexSizeMb
          ? _value.indexSizeMb
          : indexSizeMb // ignore: cast_nullable_to_non_nullable
              as double,
      searchEngines: null == searchEngines
          ? _value.searchEngines
          : searchEngines // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RAGStatsResponseImplCopyWith<$Res>
    implements $RAGStatsResponseCopyWith<$Res> {
  factory _$$RAGStatsResponseImplCopyWith(_$RAGStatsResponseImpl value,
          $Res Function(_$RAGStatsResponseImpl) then) =
      __$$RAGStatsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalDocuments,
      int totalChunks,
      String indexType,
      double indexSizeMb,
      Map<String, dynamic> searchEngines});
}

/// @nodoc
class __$$RAGStatsResponseImplCopyWithImpl<$Res>
    extends _$RAGStatsResponseCopyWithImpl<$Res, _$RAGStatsResponseImpl>
    implements _$$RAGStatsResponseImplCopyWith<$Res> {
  __$$RAGStatsResponseImplCopyWithImpl(_$RAGStatsResponseImpl _value,
      $Res Function(_$RAGStatsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalDocuments = null,
    Object? totalChunks = null,
    Object? indexType = null,
    Object? indexSizeMb = null,
    Object? searchEngines = null,
  }) {
    return _then(_$RAGStatsResponseImpl(
      totalDocuments: null == totalDocuments
          ? _value.totalDocuments
          : totalDocuments // ignore: cast_nullable_to_non_nullable
              as int,
      totalChunks: null == totalChunks
          ? _value.totalChunks
          : totalChunks // ignore: cast_nullable_to_non_nullable
              as int,
      indexType: null == indexType
          ? _value.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as String,
      indexSizeMb: null == indexSizeMb
          ? _value.indexSizeMb
          : indexSizeMb // ignore: cast_nullable_to_non_nullable
              as double,
      searchEngines: null == searchEngines
          ? _value._searchEngines
          : searchEngines // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RAGStatsResponseImpl implements _RAGStatsResponse {
  const _$RAGStatsResponseImpl(
      {required this.totalDocuments,
      required this.totalChunks,
      required this.indexType,
      required this.indexSizeMb,
      required final Map<String, dynamic> searchEngines})
      : _searchEngines = searchEngines;

  factory _$RAGStatsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RAGStatsResponseImplFromJson(json);

  @override
  final int totalDocuments;
  @override
  final int totalChunks;
  @override
  final String indexType;
  @override
  final double indexSizeMb;
  final Map<String, dynamic> _searchEngines;
  @override
  Map<String, dynamic> get searchEngines {
    if (_searchEngines is EqualUnmodifiableMapView) return _searchEngines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_searchEngines);
  }

  @override
  String toString() {
    return 'RAGStatsResponse(totalDocuments: $totalDocuments, totalChunks: $totalChunks, indexType: $indexType, indexSizeMb: $indexSizeMb, searchEngines: $searchEngines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RAGStatsResponseImpl &&
            (identical(other.totalDocuments, totalDocuments) ||
                other.totalDocuments == totalDocuments) &&
            (identical(other.totalChunks, totalChunks) ||
                other.totalChunks == totalChunks) &&
            (identical(other.indexType, indexType) ||
                other.indexType == indexType) &&
            (identical(other.indexSizeMb, indexSizeMb) ||
                other.indexSizeMb == indexSizeMb) &&
            const DeepCollectionEquality()
                .equals(other._searchEngines, _searchEngines));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalDocuments,
      totalChunks,
      indexType,
      indexSizeMb,
      const DeepCollectionEquality().hash(_searchEngines));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RAGStatsResponseImplCopyWith<_$RAGStatsResponseImpl> get copyWith =>
      __$$RAGStatsResponseImplCopyWithImpl<_$RAGStatsResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RAGStatsResponseImplToJson(
      this,
    );
  }
}

abstract class _RAGStatsResponse implements RAGStatsResponse {
  const factory _RAGStatsResponse(
          {required final int totalDocuments,
          required final int totalChunks,
          required final String indexType,
          required final double indexSizeMb,
          required final Map<String, dynamic> searchEngines}) =
      _$RAGStatsResponseImpl;

  factory _RAGStatsResponse.fromJson(Map<String, dynamic> json) =
      _$RAGStatsResponseImpl.fromJson;

  @override
  int get totalDocuments;
  @override
  int get totalChunks;
  @override
  String get indexType;
  @override
  double get indexSizeMb;
  @override
  Map<String, dynamic> get searchEngines;
  @override
  @JsonKey(ignore: true)
  _$$RAGStatsResponseImplCopyWith<_$RAGStatsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RAGDocument _$RAGDocumentFromJson(Map<String, dynamic> json) {
  return _RAGDocument.fromJson(json);
}

/// @nodoc
mixin _$RAGDocument {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get docType => throw _privateConstructorUsedError;
  int get chunkCount => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  double get sizeKb => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RAGDocumentCopyWith<RAGDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RAGDocumentCopyWith<$Res> {
  factory $RAGDocumentCopyWith(
          RAGDocument value, $Res Function(RAGDocument) then) =
      _$RAGDocumentCopyWithImpl<$Res, RAGDocument>;
  @useResult
  $Res call(
      {String id,
      String title,
      String docType,
      int chunkCount,
      String createdAt,
      double sizeKb});
}

/// @nodoc
class _$RAGDocumentCopyWithImpl<$Res, $Val extends RAGDocument>
    implements $RAGDocumentCopyWith<$Res> {
  _$RAGDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? docType = null,
    Object? chunkCount = null,
    Object? createdAt = null,
    Object? sizeKb = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      docType: null == docType
          ? _value.docType
          : docType // ignore: cast_nullable_to_non_nullable
              as String,
      chunkCount: null == chunkCount
          ? _value.chunkCount
          : chunkCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      sizeKb: null == sizeKb
          ? _value.sizeKb
          : sizeKb // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RAGDocumentImplCopyWith<$Res>
    implements $RAGDocumentCopyWith<$Res> {
  factory _$$RAGDocumentImplCopyWith(
          _$RAGDocumentImpl value, $Res Function(_$RAGDocumentImpl) then) =
      __$$RAGDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String docType,
      int chunkCount,
      String createdAt,
      double sizeKb});
}

/// @nodoc
class __$$RAGDocumentImplCopyWithImpl<$Res>
    extends _$RAGDocumentCopyWithImpl<$Res, _$RAGDocumentImpl>
    implements _$$RAGDocumentImplCopyWith<$Res> {
  __$$RAGDocumentImplCopyWithImpl(
      _$RAGDocumentImpl _value, $Res Function(_$RAGDocumentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? docType = null,
    Object? chunkCount = null,
    Object? createdAt = null,
    Object? sizeKb = null,
  }) {
    return _then(_$RAGDocumentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      docType: null == docType
          ? _value.docType
          : docType // ignore: cast_nullable_to_non_nullable
              as String,
      chunkCount: null == chunkCount
          ? _value.chunkCount
          : chunkCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      sizeKb: null == sizeKb
          ? _value.sizeKb
          : sizeKb // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RAGDocumentImpl implements _RAGDocument {
  const _$RAGDocumentImpl(
      {required this.id,
      required this.title,
      required this.docType,
      required this.chunkCount,
      required this.createdAt,
      required this.sizeKb});

  factory _$RAGDocumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$RAGDocumentImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String docType;
  @override
  final int chunkCount;
  @override
  final String createdAt;
  @override
  final double sizeKb;

  @override
  String toString() {
    return 'RAGDocument(id: $id, title: $title, docType: $docType, chunkCount: $chunkCount, createdAt: $createdAt, sizeKb: $sizeKb)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RAGDocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.docType, docType) || other.docType == docType) &&
            (identical(other.chunkCount, chunkCount) ||
                other.chunkCount == chunkCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.sizeKb, sizeKb) || other.sizeKb == sizeKb));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, title, docType, chunkCount, createdAt, sizeKb);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RAGDocumentImplCopyWith<_$RAGDocumentImpl> get copyWith =>
      __$$RAGDocumentImplCopyWithImpl<_$RAGDocumentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RAGDocumentImplToJson(
      this,
    );
  }
}

abstract class _RAGDocument implements RAGDocument {
  const factory _RAGDocument(
      {required final String id,
      required final String title,
      required final String docType,
      required final int chunkCount,
      required final String createdAt,
      required final double sizeKb}) = _$RAGDocumentImpl;

  factory _RAGDocument.fromJson(Map<String, dynamic> json) =
      _$RAGDocumentImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get docType;
  @override
  int get chunkCount;
  @override
  String get createdAt;
  @override
  double get sizeKb;
  @override
  @JsonKey(ignore: true)
  _$$RAGDocumentImplCopyWith<_$RAGDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RAGDocumentsResponse _$RAGDocumentsResponseFromJson(Map<String, dynamic> json) {
  return _RAGDocumentsResponse.fromJson(json);
}

/// @nodoc
mixin _$RAGDocumentsResponse {
  List<RAGDocument> get documents => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RAGDocumentsResponseCopyWith<RAGDocumentsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RAGDocumentsResponseCopyWith<$Res> {
  factory $RAGDocumentsResponseCopyWith(RAGDocumentsResponse value,
          $Res Function(RAGDocumentsResponse) then) =
      _$RAGDocumentsResponseCopyWithImpl<$Res, RAGDocumentsResponse>;
  @useResult
  $Res call({List<RAGDocument> documents});
}

/// @nodoc
class _$RAGDocumentsResponseCopyWithImpl<$Res,
        $Val extends RAGDocumentsResponse>
    implements $RAGDocumentsResponseCopyWith<$Res> {
  _$RAGDocumentsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? documents = null,
  }) {
    return _then(_value.copyWith(
      documents: null == documents
          ? _value.documents
          : documents // ignore: cast_nullable_to_non_nullable
              as List<RAGDocument>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RAGDocumentsResponseImplCopyWith<$Res>
    implements $RAGDocumentsResponseCopyWith<$Res> {
  factory _$$RAGDocumentsResponseImplCopyWith(_$RAGDocumentsResponseImpl value,
          $Res Function(_$RAGDocumentsResponseImpl) then) =
      __$$RAGDocumentsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<RAGDocument> documents});
}

/// @nodoc
class __$$RAGDocumentsResponseImplCopyWithImpl<$Res>
    extends _$RAGDocumentsResponseCopyWithImpl<$Res, _$RAGDocumentsResponseImpl>
    implements _$$RAGDocumentsResponseImplCopyWith<$Res> {
  __$$RAGDocumentsResponseImplCopyWithImpl(_$RAGDocumentsResponseImpl _value,
      $Res Function(_$RAGDocumentsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? documents = null,
  }) {
    return _then(_$RAGDocumentsResponseImpl(
      documents: null == documents
          ? _value._documents
          : documents // ignore: cast_nullable_to_non_nullable
              as List<RAGDocument>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RAGDocumentsResponseImpl implements _RAGDocumentsResponse {
  const _$RAGDocumentsResponseImpl({required final List<RAGDocument> documents})
      : _documents = documents;

  factory _$RAGDocumentsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RAGDocumentsResponseImplFromJson(json);

  final List<RAGDocument> _documents;
  @override
  List<RAGDocument> get documents {
    if (_documents is EqualUnmodifiableListView) return _documents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_documents);
  }

  @override
  String toString() {
    return 'RAGDocumentsResponse(documents: $documents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RAGDocumentsResponseImpl &&
            const DeepCollectionEquality()
                .equals(other._documents, _documents));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_documents));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RAGDocumentsResponseImplCopyWith<_$RAGDocumentsResponseImpl>
      get copyWith =>
          __$$RAGDocumentsResponseImplCopyWithImpl<_$RAGDocumentsResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RAGDocumentsResponseImplToJson(
      this,
    );
  }
}

abstract class _RAGDocumentsResponse implements RAGDocumentsResponse {
  const factory _RAGDocumentsResponse(
          {required final List<RAGDocument> documents}) =
      _$RAGDocumentsResponseImpl;

  factory _RAGDocumentsResponse.fromJson(Map<String, dynamic> json) =
      _$RAGDocumentsResponseImpl.fromJson;

  @override
  List<RAGDocument> get documents;
  @override
  @JsonKey(ignore: true)
  _$$RAGDocumentsResponseImplCopyWith<_$RAGDocumentsResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

RAGIngestResponse _$RAGIngestResponseFromJson(Map<String, dynamic> json) {
  return _RAGIngestResponse.fromJson(json);
}

/// @nodoc
mixin _$RAGIngestResponse {
  String get docId => throw _privateConstructorUsedError;
  int get chunksCreated => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RAGIngestResponseCopyWith<RAGIngestResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RAGIngestResponseCopyWith<$Res> {
  factory $RAGIngestResponseCopyWith(
          RAGIngestResponse value, $Res Function(RAGIngestResponse) then) =
      _$RAGIngestResponseCopyWithImpl<$Res, RAGIngestResponse>;
  @useResult
  $Res call({String docId, int chunksCreated, String title});
}

/// @nodoc
class _$RAGIngestResponseCopyWithImpl<$Res, $Val extends RAGIngestResponse>
    implements $RAGIngestResponseCopyWith<$Res> {
  _$RAGIngestResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docId = null,
    Object? chunksCreated = null,
    Object? title = null,
  }) {
    return _then(_value.copyWith(
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
      chunksCreated: null == chunksCreated
          ? _value.chunksCreated
          : chunksCreated // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RAGIngestResponseImplCopyWith<$Res>
    implements $RAGIngestResponseCopyWith<$Res> {
  factory _$$RAGIngestResponseImplCopyWith(_$RAGIngestResponseImpl value,
          $Res Function(_$RAGIngestResponseImpl) then) =
      __$$RAGIngestResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String docId, int chunksCreated, String title});
}

/// @nodoc
class __$$RAGIngestResponseImplCopyWithImpl<$Res>
    extends _$RAGIngestResponseCopyWithImpl<$Res, _$RAGIngestResponseImpl>
    implements _$$RAGIngestResponseImplCopyWith<$Res> {
  __$$RAGIngestResponseImplCopyWithImpl(_$RAGIngestResponseImpl _value,
      $Res Function(_$RAGIngestResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docId = null,
    Object? chunksCreated = null,
    Object? title = null,
  }) {
    return _then(_$RAGIngestResponseImpl(
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
      chunksCreated: null == chunksCreated
          ? _value.chunksCreated
          : chunksCreated // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RAGIngestResponseImpl implements _RAGIngestResponse {
  const _$RAGIngestResponseImpl(
      {required this.docId, required this.chunksCreated, required this.title});

  factory _$RAGIngestResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RAGIngestResponseImplFromJson(json);

  @override
  final String docId;
  @override
  final int chunksCreated;
  @override
  final String title;

  @override
  String toString() {
    return 'RAGIngestResponse(docId: $docId, chunksCreated: $chunksCreated, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RAGIngestResponseImpl &&
            (identical(other.docId, docId) || other.docId == docId) &&
            (identical(other.chunksCreated, chunksCreated) ||
                other.chunksCreated == chunksCreated) &&
            (identical(other.title, title) || other.title == title));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, docId, chunksCreated, title);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RAGIngestResponseImplCopyWith<_$RAGIngestResponseImpl> get copyWith =>
      __$$RAGIngestResponseImplCopyWithImpl<_$RAGIngestResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RAGIngestResponseImplToJson(
      this,
    );
  }
}

abstract class _RAGIngestResponse implements RAGIngestResponse {
  const factory _RAGIngestResponse(
      {required final String docId,
      required final int chunksCreated,
      required final String title}) = _$RAGIngestResponseImpl;

  factory _RAGIngestResponse.fromJson(Map<String, dynamic> json) =
      _$RAGIngestResponseImpl.fromJson;

  @override
  String get docId;
  @override
  int get chunksCreated;
  @override
  String get title;
  @override
  @JsonKey(ignore: true)
  _$$RAGIngestResponseImplCopyWith<_$RAGIngestResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RAGSearchResult _$RAGSearchResultFromJson(Map<String, dynamic> json) {
  return _RAGSearchResult.fromJson(json);
}

/// @nodoc
mixin _$RAGSearchResult {
  String get docId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  String get docType => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RAGSearchResultCopyWith<RAGSearchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RAGSearchResultCopyWith<$Res> {
  factory $RAGSearchResultCopyWith(
          RAGSearchResult value, $Res Function(RAGSearchResult) then) =
      _$RAGSearchResultCopyWithImpl<$Res, RAGSearchResult>;
  @useResult
  $Res call(
      {String docId,
      String title,
      String content,
      double score,
      String docType});
}

/// @nodoc
class _$RAGSearchResultCopyWithImpl<$Res, $Val extends RAGSearchResult>
    implements $RAGSearchResultCopyWith<$Res> {
  _$RAGSearchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docId = null,
    Object? title = null,
    Object? content = null,
    Object? score = null,
    Object? docType = null,
  }) {
    return _then(_value.copyWith(
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      docType: null == docType
          ? _value.docType
          : docType // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RAGSearchResultImplCopyWith<$Res>
    implements $RAGSearchResultCopyWith<$Res> {
  factory _$$RAGSearchResultImplCopyWith(_$RAGSearchResultImpl value,
          $Res Function(_$RAGSearchResultImpl) then) =
      __$$RAGSearchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String docId,
      String title,
      String content,
      double score,
      String docType});
}

/// @nodoc
class __$$RAGSearchResultImplCopyWithImpl<$Res>
    extends _$RAGSearchResultCopyWithImpl<$Res, _$RAGSearchResultImpl>
    implements _$$RAGSearchResultImplCopyWith<$Res> {
  __$$RAGSearchResultImplCopyWithImpl(
      _$RAGSearchResultImpl _value, $Res Function(_$RAGSearchResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docId = null,
    Object? title = null,
    Object? content = null,
    Object? score = null,
    Object? docType = null,
  }) {
    return _then(_$RAGSearchResultImpl(
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      docType: null == docType
          ? _value.docType
          : docType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RAGSearchResultImpl implements _RAGSearchResult {
  const _$RAGSearchResultImpl(
      {required this.docId,
      required this.title,
      required this.content,
      required this.score,
      required this.docType});

  factory _$RAGSearchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$RAGSearchResultImplFromJson(json);

  @override
  final String docId;
  @override
  final String title;
  @override
  final String content;
  @override
  final double score;
  @override
  final String docType;

  @override
  String toString() {
    return 'RAGSearchResult(docId: $docId, title: $title, content: $content, score: $score, docType: $docType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RAGSearchResultImpl &&
            (identical(other.docId, docId) || other.docId == docId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.docType, docType) || other.docType == docType));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, docId, title, content, score, docType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RAGSearchResultImplCopyWith<_$RAGSearchResultImpl> get copyWith =>
      __$$RAGSearchResultImplCopyWithImpl<_$RAGSearchResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RAGSearchResultImplToJson(
      this,
    );
  }
}

abstract class _RAGSearchResult implements RAGSearchResult {
  const factory _RAGSearchResult(
      {required final String docId,
      required final String title,
      required final String content,
      required final double score,
      required final String docType}) = _$RAGSearchResultImpl;

  factory _RAGSearchResult.fromJson(Map<String, dynamic> json) =
      _$RAGSearchResultImpl.fromJson;

  @override
  String get docId;
  @override
  String get title;
  @override
  String get content;
  @override
  double get score;
  @override
  String get docType;
  @override
  @JsonKey(ignore: true)
  _$$RAGSearchResultImplCopyWith<_$RAGSearchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RAGSearchResponse _$RAGSearchResponseFromJson(Map<String, dynamic> json) {
  return _RAGSearchResponse.fromJson(json);
}

/// @nodoc
mixin _$RAGSearchResponse {
  String get query => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  List<RAGSearchResult> get results => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RAGSearchResponseCopyWith<RAGSearchResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RAGSearchResponseCopyWith<$Res> {
  factory $RAGSearchResponseCopyWith(
          RAGSearchResponse value, $Res Function(RAGSearchResponse) then) =
      _$RAGSearchResponseCopyWithImpl<$Res, RAGSearchResponse>;
  @useResult
  $Res call({String query, String mode, List<RAGSearchResult> results});
}

/// @nodoc
class _$RAGSearchResponseCopyWithImpl<$Res, $Val extends RAGSearchResponse>
    implements $RAGSearchResponseCopyWith<$Res> {
  _$RAGSearchResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? mode = null,
    Object? results = null,
  }) {
    return _then(_value.copyWith(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<RAGSearchResult>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RAGSearchResponseImplCopyWith<$Res>
    implements $RAGSearchResponseCopyWith<$Res> {
  factory _$$RAGSearchResponseImplCopyWith(_$RAGSearchResponseImpl value,
          $Res Function(_$RAGSearchResponseImpl) then) =
      __$$RAGSearchResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String query, String mode, List<RAGSearchResult> results});
}

/// @nodoc
class __$$RAGSearchResponseImplCopyWithImpl<$Res>
    extends _$RAGSearchResponseCopyWithImpl<$Res, _$RAGSearchResponseImpl>
    implements _$$RAGSearchResponseImplCopyWith<$Res> {
  __$$RAGSearchResponseImplCopyWithImpl(_$RAGSearchResponseImpl _value,
      $Res Function(_$RAGSearchResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? mode = null,
    Object? results = null,
  }) {
    return _then(_$RAGSearchResponseImpl(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<RAGSearchResult>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RAGSearchResponseImpl implements _RAGSearchResponse {
  const _$RAGSearchResponseImpl(
      {required this.query,
      required this.mode,
      required final List<RAGSearchResult> results})
      : _results = results;

  factory _$RAGSearchResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RAGSearchResponseImplFromJson(json);

  @override
  final String query;
  @override
  final String mode;
  final List<RAGSearchResult> _results;
  @override
  List<RAGSearchResult> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  String toString() {
    return 'RAGSearchResponse(query: $query, mode: $mode, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RAGSearchResponseImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(other._results, _results));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, query, mode, const DeepCollectionEquality().hash(_results));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RAGSearchResponseImplCopyWith<_$RAGSearchResponseImpl> get copyWith =>
      __$$RAGSearchResponseImplCopyWithImpl<_$RAGSearchResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RAGSearchResponseImplToJson(
      this,
    );
  }
}

abstract class _RAGSearchResponse implements RAGSearchResponse {
  const factory _RAGSearchResponse(
      {required final String query,
      required final String mode,
      required final List<RAGSearchResult> results}) = _$RAGSearchResponseImpl;

  factory _RAGSearchResponse.fromJson(Map<String, dynamic> json) =
      _$RAGSearchResponseImpl.fromJson;

  @override
  String get query;
  @override
  String get mode;
  @override
  List<RAGSearchResult> get results;
  @override
  @JsonKey(ignore: true)
  _$$RAGSearchResponseImplCopyWith<_$RAGSearchResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RAGContextResponse _$RAGContextResponseFromJson(Map<String, dynamic> json) {
  return _RAGContextResponse.fromJson(json);
}

/// @nodoc
mixin _$RAGContextResponse {
  String get context => throw _privateConstructorUsedError;
  List<RAGSearchResult> get citations => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RAGContextResponseCopyWith<RAGContextResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RAGContextResponseCopyWith<$Res> {
  factory $RAGContextResponseCopyWith(
          RAGContextResponse value, $Res Function(RAGContextResponse) then) =
      _$RAGContextResponseCopyWithImpl<$Res, RAGContextResponse>;
  @useResult
  $Res call({String context, List<RAGSearchResult> citations});
}

/// @nodoc
class _$RAGContextResponseCopyWithImpl<$Res, $Val extends RAGContextResponse>
    implements $RAGContextResponseCopyWith<$Res> {
  _$RAGContextResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? context = null,
    Object? citations = null,
  }) {
    return _then(_value.copyWith(
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as String,
      citations: null == citations
          ? _value.citations
          : citations // ignore: cast_nullable_to_non_nullable
              as List<RAGSearchResult>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RAGContextResponseImplCopyWith<$Res>
    implements $RAGContextResponseCopyWith<$Res> {
  factory _$$RAGContextResponseImplCopyWith(_$RAGContextResponseImpl value,
          $Res Function(_$RAGContextResponseImpl) then) =
      __$$RAGContextResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String context, List<RAGSearchResult> citations});
}

/// @nodoc
class __$$RAGContextResponseImplCopyWithImpl<$Res>
    extends _$RAGContextResponseCopyWithImpl<$Res, _$RAGContextResponseImpl>
    implements _$$RAGContextResponseImplCopyWith<$Res> {
  __$$RAGContextResponseImplCopyWithImpl(_$RAGContextResponseImpl _value,
      $Res Function(_$RAGContextResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? context = null,
    Object? citations = null,
  }) {
    return _then(_$RAGContextResponseImpl(
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as String,
      citations: null == citations
          ? _value._citations
          : citations // ignore: cast_nullable_to_non_nullable
              as List<RAGSearchResult>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RAGContextResponseImpl implements _RAGContextResponse {
  const _$RAGContextResponseImpl(
      {required this.context, required final List<RAGSearchResult> citations})
      : _citations = citations;

  factory _$RAGContextResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RAGContextResponseImplFromJson(json);

  @override
  final String context;
  final List<RAGSearchResult> _citations;
  @override
  List<RAGSearchResult> get citations {
    if (_citations is EqualUnmodifiableListView) return _citations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_citations);
  }

  @override
  String toString() {
    return 'RAGContextResponse(context: $context, citations: $citations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RAGContextResponseImpl &&
            (identical(other.context, context) || other.context == context) &&
            const DeepCollectionEquality()
                .equals(other._citations, _citations));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, context, const DeepCollectionEquality().hash(_citations));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RAGContextResponseImplCopyWith<_$RAGContextResponseImpl> get copyWith =>
      __$$RAGContextResponseImplCopyWithImpl<_$RAGContextResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RAGContextResponseImplToJson(
      this,
    );
  }
}

abstract class _RAGContextResponse implements RAGContextResponse {
  const factory _RAGContextResponse(
          {required final String context,
          required final List<RAGSearchResult> citations}) =
      _$RAGContextResponseImpl;

  factory _RAGContextResponse.fromJson(Map<String, dynamic> json) =
      _$RAGContextResponseImpl.fromJson;

  @override
  String get context;
  @override
  List<RAGSearchResult> get citations;
  @override
  @JsonKey(ignore: true)
  _$$RAGContextResponseImplCopyWith<_$RAGContextResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) {
  return _DeviceInfo.fromJson(json);
}

/// @nodoc
mixin _$DeviceInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get pairedAt => throw _privateConstructorUsedError;
  double? get lastSeen => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceInfoCopyWith<DeviceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceInfoCopyWith<$Res> {
  factory $DeviceInfoCopyWith(
          DeviceInfo value, $Res Function(DeviceInfo) then) =
      _$DeviceInfoCopyWithImpl<$Res, DeviceInfo>;
  @useResult
  $Res call({String id, String name, double pairedAt, double? lastSeen});
}

/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res, $Val extends DeviceInfo>
    implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? pairedAt = null,
    Object? lastSeen = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      pairedAt: null == pairedAt
          ? _value.pairedAt
          : pairedAt // ignore: cast_nullable_to_non_nullable
              as double,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceInfoImplCopyWith<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  factory _$$DeviceInfoImplCopyWith(
          _$DeviceInfoImpl value, $Res Function(_$DeviceInfoImpl) then) =
      __$$DeviceInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, double pairedAt, double? lastSeen});
}

/// @nodoc
class __$$DeviceInfoImplCopyWithImpl<$Res>
    extends _$DeviceInfoCopyWithImpl<$Res, _$DeviceInfoImpl>
    implements _$$DeviceInfoImplCopyWith<$Res> {
  __$$DeviceInfoImplCopyWithImpl(
      _$DeviceInfoImpl _value, $Res Function(_$DeviceInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? pairedAt = null,
    Object? lastSeen = freezed,
  }) {
    return _then(_$DeviceInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      pairedAt: null == pairedAt
          ? _value.pairedAt
          : pairedAt // ignore: cast_nullable_to_non_nullable
              as double,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceInfoImpl implements _DeviceInfo {
  const _$DeviceInfoImpl(
      {required this.id,
      required this.name,
      required this.pairedAt,
      this.lastSeen});

  factory _$DeviceInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double pairedAt;
  @override
  final double? lastSeen;

  @override
  String toString() {
    return 'DeviceInfo(id: $id, name: $name, pairedAt: $pairedAt, lastSeen: $lastSeen)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.pairedAt, pairedAt) ||
                other.pairedAt == pairedAt) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, pairedAt, lastSeen);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceInfoImplCopyWith<_$DeviceInfoImpl> get copyWith =>
      __$$DeviceInfoImplCopyWithImpl<_$DeviceInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceInfoImplToJson(
      this,
    );
  }
}

abstract class _DeviceInfo implements DeviceInfo {
  const factory _DeviceInfo(
      {required final String id,
      required final String name,
      required final double pairedAt,
      final double? lastSeen}) = _$DeviceInfoImpl;

  factory _DeviceInfo.fromJson(Map<String, dynamic> json) =
      _$DeviceInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get pairedAt;
  @override
  double? get lastSeen;
  @override
  @JsonKey(ignore: true)
  _$$DeviceInfoImplCopyWith<_$DeviceInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceListResponse _$DeviceListResponseFromJson(Map<String, dynamic> json) {
  return _DeviceListResponse.fromJson(json);
}

/// @nodoc
mixin _$DeviceListResponse {
  List<DeviceInfo> get devices => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceListResponseCopyWith<DeviceListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceListResponseCopyWith<$Res> {
  factory $DeviceListResponseCopyWith(
          DeviceListResponse value, $Res Function(DeviceListResponse) then) =
      _$DeviceListResponseCopyWithImpl<$Res, DeviceListResponse>;
  @useResult
  $Res call({List<DeviceInfo> devices});
}

/// @nodoc
class _$DeviceListResponseCopyWithImpl<$Res, $Val extends DeviceListResponse>
    implements $DeviceListResponseCopyWith<$Res> {
  _$DeviceListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? devices = null,
  }) {
    return _then(_value.copyWith(
      devices: null == devices
          ? _value.devices
          : devices // ignore: cast_nullable_to_non_nullable
              as List<DeviceInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceListResponseImplCopyWith<$Res>
    implements $DeviceListResponseCopyWith<$Res> {
  factory _$$DeviceListResponseImplCopyWith(_$DeviceListResponseImpl value,
          $Res Function(_$DeviceListResponseImpl) then) =
      __$$DeviceListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<DeviceInfo> devices});
}

/// @nodoc
class __$$DeviceListResponseImplCopyWithImpl<$Res>
    extends _$DeviceListResponseCopyWithImpl<$Res, _$DeviceListResponseImpl>
    implements _$$DeviceListResponseImplCopyWith<$Res> {
  __$$DeviceListResponseImplCopyWithImpl(_$DeviceListResponseImpl _value,
      $Res Function(_$DeviceListResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? devices = null,
  }) {
    return _then(_$DeviceListResponseImpl(
      devices: null == devices
          ? _value._devices
          : devices // ignore: cast_nullable_to_non_nullable
              as List<DeviceInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceListResponseImpl implements _DeviceListResponse {
  const _$DeviceListResponseImpl({required final List<DeviceInfo> devices})
      : _devices = devices;

  factory _$DeviceListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceListResponseImplFromJson(json);

  final List<DeviceInfo> _devices;
  @override
  List<DeviceInfo> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  @override
  String toString() {
    return 'DeviceListResponse(devices: $devices)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceListResponseImpl &&
            const DeepCollectionEquality().equals(other._devices, _devices));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_devices));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceListResponseImplCopyWith<_$DeviceListResponseImpl> get copyWith =>
      __$$DeviceListResponseImplCopyWithImpl<_$DeviceListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceListResponseImplToJson(
      this,
    );
  }
}

abstract class _DeviceListResponse implements DeviceListResponse {
  const factory _DeviceListResponse({required final List<DeviceInfo> devices}) =
      _$DeviceListResponseImpl;

  factory _DeviceListResponse.fromJson(Map<String, dynamic> json) =
      _$DeviceListResponseImpl.fromJson;

  @override
  List<DeviceInfo> get devices;
  @override
  @JsonKey(ignore: true)
  _$$DeviceListResponseImplCopyWith<_$DeviceListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DevicePairStartResponse _$DevicePairStartResponseFromJson(
    Map<String, dynamic> json) {
  return _DevicePairStartResponse.fromJson(json);
}

/// @nodoc
mixin _$DevicePairStartResponse {
  String get pairingCode => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DevicePairStartResponseCopyWith<DevicePairStartResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DevicePairStartResponseCopyWith<$Res> {
  factory $DevicePairStartResponseCopyWith(DevicePairStartResponse value,
          $Res Function(DevicePairStartResponse) then) =
      _$DevicePairStartResponseCopyWithImpl<$Res, DevicePairStartResponse>;
  @useResult
  $Res call({String pairingCode, String name});
}

/// @nodoc
class _$DevicePairStartResponseCopyWithImpl<$Res,
        $Val extends DevicePairStartResponse>
    implements $DevicePairStartResponseCopyWith<$Res> {
  _$DevicePairStartResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pairingCode = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      pairingCode: null == pairingCode
          ? _value.pairingCode
          : pairingCode // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DevicePairStartResponseImplCopyWith<$Res>
    implements $DevicePairStartResponseCopyWith<$Res> {
  factory _$$DevicePairStartResponseImplCopyWith(
          _$DevicePairStartResponseImpl value,
          $Res Function(_$DevicePairStartResponseImpl) then) =
      __$$DevicePairStartResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String pairingCode, String name});
}

/// @nodoc
class __$$DevicePairStartResponseImplCopyWithImpl<$Res>
    extends _$DevicePairStartResponseCopyWithImpl<$Res,
        _$DevicePairStartResponseImpl>
    implements _$$DevicePairStartResponseImplCopyWith<$Res> {
  __$$DevicePairStartResponseImplCopyWithImpl(
      _$DevicePairStartResponseImpl _value,
      $Res Function(_$DevicePairStartResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pairingCode = null,
    Object? name = null,
  }) {
    return _then(_$DevicePairStartResponseImpl(
      pairingCode: null == pairingCode
          ? _value.pairingCode
          : pairingCode // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DevicePairStartResponseImpl implements _DevicePairStartResponse {
  const _$DevicePairStartResponseImpl(
      {required this.pairingCode, required this.name});

  factory _$DevicePairStartResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$DevicePairStartResponseImplFromJson(json);

  @override
  final String pairingCode;
  @override
  final String name;

  @override
  String toString() {
    return 'DevicePairStartResponse(pairingCode: $pairingCode, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DevicePairStartResponseImpl &&
            (identical(other.pairingCode, pairingCode) ||
                other.pairingCode == pairingCode) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, pairingCode, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DevicePairStartResponseImplCopyWith<_$DevicePairStartResponseImpl>
      get copyWith => __$$DevicePairStartResponseImplCopyWithImpl<
          _$DevicePairStartResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DevicePairStartResponseImplToJson(
      this,
    );
  }
}

abstract class _DevicePairStartResponse implements DevicePairStartResponse {
  const factory _DevicePairStartResponse(
      {required final String pairingCode,
      required final String name}) = _$DevicePairStartResponseImpl;

  factory _DevicePairStartResponse.fromJson(Map<String, dynamic> json) =
      _$DevicePairStartResponseImpl.fromJson;

  @override
  String get pairingCode;
  @override
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$DevicePairStartResponseImplCopyWith<_$DevicePairStartResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

DevicePairCompleteResponse _$DevicePairCompleteResponseFromJson(
    Map<String, dynamic> json) {
  return _DevicePairCompleteResponse.fromJson(json);
}

/// @nodoc
mixin _$DevicePairCompleteResponse {
  String get deviceId => throw _privateConstructorUsedError;
  String get secret => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DevicePairCompleteResponseCopyWith<DevicePairCompleteResponse>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DevicePairCompleteResponseCopyWith<$Res> {
  factory $DevicePairCompleteResponseCopyWith(DevicePairCompleteResponse value,
          $Res Function(DevicePairCompleteResponse) then) =
      _$DevicePairCompleteResponseCopyWithImpl<$Res,
          DevicePairCompleteResponse>;
  @useResult
  $Res call({String deviceId, String secret});
}

/// @nodoc
class _$DevicePairCompleteResponseCopyWithImpl<$Res,
        $Val extends DevicePairCompleteResponse>
    implements $DevicePairCompleteResponseCopyWith<$Res> {
  _$DevicePairCompleteResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? secret = null,
  }) {
    return _then(_value.copyWith(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      secret: null == secret
          ? _value.secret
          : secret // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DevicePairCompleteResponseImplCopyWith<$Res>
    implements $DevicePairCompleteResponseCopyWith<$Res> {
  factory _$$DevicePairCompleteResponseImplCopyWith(
          _$DevicePairCompleteResponseImpl value,
          $Res Function(_$DevicePairCompleteResponseImpl) then) =
      __$$DevicePairCompleteResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String deviceId, String secret});
}

/// @nodoc
class __$$DevicePairCompleteResponseImplCopyWithImpl<$Res>
    extends _$DevicePairCompleteResponseCopyWithImpl<$Res,
        _$DevicePairCompleteResponseImpl>
    implements _$$DevicePairCompleteResponseImplCopyWith<$Res> {
  __$$DevicePairCompleteResponseImplCopyWithImpl(
      _$DevicePairCompleteResponseImpl _value,
      $Res Function(_$DevicePairCompleteResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? secret = null,
  }) {
    return _then(_$DevicePairCompleteResponseImpl(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      secret: null == secret
          ? _value.secret
          : secret // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DevicePairCompleteResponseImpl implements _DevicePairCompleteResponse {
  const _$DevicePairCompleteResponseImpl(
      {required this.deviceId, required this.secret});

  factory _$DevicePairCompleteResponseImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$DevicePairCompleteResponseImplFromJson(json);

  @override
  final String deviceId;
  @override
  final String secret;

  @override
  String toString() {
    return 'DevicePairCompleteResponse(deviceId: $deviceId, secret: $secret)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DevicePairCompleteResponseImpl &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.secret, secret) || other.secret == secret));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, deviceId, secret);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DevicePairCompleteResponseImplCopyWith<_$DevicePairCompleteResponseImpl>
      get copyWith => __$$DevicePairCompleteResponseImplCopyWithImpl<
          _$DevicePairCompleteResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DevicePairCompleteResponseImplToJson(
      this,
    );
  }
}

abstract class _DevicePairCompleteResponse
    implements DevicePairCompleteResponse {
  const factory _DevicePairCompleteResponse(
      {required final String deviceId,
      required final String secret}) = _$DevicePairCompleteResponseImpl;

  factory _DevicePairCompleteResponse.fromJson(Map<String, dynamic> json) =
      _$DevicePairCompleteResponseImpl.fromJson;

  @override
  String get deviceId;
  @override
  String get secret;
  @override
  @JsonKey(ignore: true)
  _$$DevicePairCompleteResponseImplCopyWith<_$DevicePairCompleteResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

DeviceCommandEntry _$DeviceCommandEntryFromJson(Map<String, dynamic> json) {
  return _DeviceCommandEntry.fromJson(json);
}

/// @nodoc
mixin _$DeviceCommandEntry {
  String get id => throw _privateConstructorUsedError;
  String get deviceId => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  Map<String, dynamic> get params => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  double get createdAt => throw _privateConstructorUsedError;
  Map<String, dynamic>? get result => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceCommandEntryCopyWith<DeviceCommandEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceCommandEntryCopyWith<$Res> {
  factory $DeviceCommandEntryCopyWith(
          DeviceCommandEntry value, $Res Function(DeviceCommandEntry) then) =
      _$DeviceCommandEntryCopyWithImpl<$Res, DeviceCommandEntry>;
  @useResult
  $Res call(
      {String id,
      String deviceId,
      String action,
      Map<String, dynamic> params,
      String status,
      double createdAt,
      Map<String, dynamic>? result});
}

/// @nodoc
class _$DeviceCommandEntryCopyWithImpl<$Res, $Val extends DeviceCommandEntry>
    implements $DeviceCommandEntryCopyWith<$Res> {
  _$DeviceCommandEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? action = null,
    Object? params = null,
    Object? status = null,
    Object? createdAt = null,
    Object? result = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value.params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceCommandEntryImplCopyWith<$Res>
    implements $DeviceCommandEntryCopyWith<$Res> {
  factory _$$DeviceCommandEntryImplCopyWith(_$DeviceCommandEntryImpl value,
          $Res Function(_$DeviceCommandEntryImpl) then) =
      __$$DeviceCommandEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String deviceId,
      String action,
      Map<String, dynamic> params,
      String status,
      double createdAt,
      Map<String, dynamic>? result});
}

/// @nodoc
class __$$DeviceCommandEntryImplCopyWithImpl<$Res>
    extends _$DeviceCommandEntryCopyWithImpl<$Res, _$DeviceCommandEntryImpl>
    implements _$$DeviceCommandEntryImplCopyWith<$Res> {
  __$$DeviceCommandEntryImplCopyWithImpl(_$DeviceCommandEntryImpl _value,
      $Res Function(_$DeviceCommandEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? action = null,
    Object? params = null,
    Object? status = null,
    Object? createdAt = null,
    Object? result = freezed,
  }) {
    return _then(_$DeviceCommandEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value._params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
      result: freezed == result
          ? _value._result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceCommandEntryImpl implements _DeviceCommandEntry {
  const _$DeviceCommandEntryImpl(
      {required this.id,
      required this.deviceId,
      required this.action,
      required final Map<String, dynamic> params,
      required this.status,
      required this.createdAt,
      final Map<String, dynamic>? result})
      : _params = params,
        _result = result;

  factory _$DeviceCommandEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceCommandEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String deviceId;
  @override
  final String action;
  final Map<String, dynamic> _params;
  @override
  Map<String, dynamic> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  final String status;
  @override
  final double createdAt;
  final Map<String, dynamic>? _result;
  @override
  Map<String, dynamic>? get result {
    final value = _result;
    if (value == null) return null;
    if (_result is EqualUnmodifiableMapView) return _result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'DeviceCommandEntry(id: $id, deviceId: $deviceId, action: $action, params: $params, status: $status, createdAt: $createdAt, result: $result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceCommandEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.action, action) || other.action == action) &&
            const DeepCollectionEquality().equals(other._params, _params) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._result, _result));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      deviceId,
      action,
      const DeepCollectionEquality().hash(_params),
      status,
      createdAt,
      const DeepCollectionEquality().hash(_result));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceCommandEntryImplCopyWith<_$DeviceCommandEntryImpl> get copyWith =>
      __$$DeviceCommandEntryImplCopyWithImpl<_$DeviceCommandEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceCommandEntryImplToJson(
      this,
    );
  }
}

abstract class _DeviceCommandEntry implements DeviceCommandEntry {
  const factory _DeviceCommandEntry(
      {required final String id,
      required final String deviceId,
      required final String action,
      required final Map<String, dynamic> params,
      required final String status,
      required final double createdAt,
      final Map<String, dynamic>? result}) = _$DeviceCommandEntryImpl;

  factory _DeviceCommandEntry.fromJson(Map<String, dynamic> json) =
      _$DeviceCommandEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get deviceId;
  @override
  String get action;
  @override
  Map<String, dynamic> get params;
  @override
  String get status;
  @override
  double get createdAt;
  @override
  Map<String, dynamic>? get result;
  @override
  @JsonKey(ignore: true)
  _$$DeviceCommandEntryImplCopyWith<_$DeviceCommandEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceHistoryResponse _$DeviceHistoryResponseFromJson(
    Map<String, dynamic> json) {
  return _DeviceHistoryResponse.fromJson(json);
}

/// @nodoc
mixin _$DeviceHistoryResponse {
  List<DeviceCommandEntry> get commands => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceHistoryResponseCopyWith<DeviceHistoryResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceHistoryResponseCopyWith<$Res> {
  factory $DeviceHistoryResponseCopyWith(DeviceHistoryResponse value,
          $Res Function(DeviceHistoryResponse) then) =
      _$DeviceHistoryResponseCopyWithImpl<$Res, DeviceHistoryResponse>;
  @useResult
  $Res call({List<DeviceCommandEntry> commands});
}

/// @nodoc
class _$DeviceHistoryResponseCopyWithImpl<$Res,
        $Val extends DeviceHistoryResponse>
    implements $DeviceHistoryResponseCopyWith<$Res> {
  _$DeviceHistoryResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commands = null,
  }) {
    return _then(_value.copyWith(
      commands: null == commands
          ? _value.commands
          : commands // ignore: cast_nullable_to_non_nullable
              as List<DeviceCommandEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceHistoryResponseImplCopyWith<$Res>
    implements $DeviceHistoryResponseCopyWith<$Res> {
  factory _$$DeviceHistoryResponseImplCopyWith(
          _$DeviceHistoryResponseImpl value,
          $Res Function(_$DeviceHistoryResponseImpl) then) =
      __$$DeviceHistoryResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<DeviceCommandEntry> commands});
}

/// @nodoc
class __$$DeviceHistoryResponseImplCopyWithImpl<$Res>
    extends _$DeviceHistoryResponseCopyWithImpl<$Res,
        _$DeviceHistoryResponseImpl>
    implements _$$DeviceHistoryResponseImplCopyWith<$Res> {
  __$$DeviceHistoryResponseImplCopyWithImpl(_$DeviceHistoryResponseImpl _value,
      $Res Function(_$DeviceHistoryResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commands = null,
  }) {
    return _then(_$DeviceHistoryResponseImpl(
      commands: null == commands
          ? _value._commands
          : commands // ignore: cast_nullable_to_non_nullable
              as List<DeviceCommandEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceHistoryResponseImpl implements _DeviceHistoryResponse {
  const _$DeviceHistoryResponseImpl(
      {required final List<DeviceCommandEntry> commands})
      : _commands = commands;

  factory _$DeviceHistoryResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceHistoryResponseImplFromJson(json);

  final List<DeviceCommandEntry> _commands;
  @override
  List<DeviceCommandEntry> get commands {
    if (_commands is EqualUnmodifiableListView) return _commands;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_commands);
  }

  @override
  String toString() {
    return 'DeviceHistoryResponse(commands: $commands)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceHistoryResponseImpl &&
            const DeepCollectionEquality().equals(other._commands, _commands));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_commands));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceHistoryResponseImplCopyWith<_$DeviceHistoryResponseImpl>
      get copyWith => __$$DeviceHistoryResponseImplCopyWithImpl<
          _$DeviceHistoryResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceHistoryResponseImplToJson(
      this,
    );
  }
}

abstract class _DeviceHistoryResponse implements DeviceHistoryResponse {
  const factory _DeviceHistoryResponse(
          {required final List<DeviceCommandEntry> commands}) =
      _$DeviceHistoryResponseImpl;

  factory _DeviceHistoryResponse.fromJson(Map<String, dynamic> json) =
      _$DeviceHistoryResponseImpl.fromJson;

  @override
  List<DeviceCommandEntry> get commands;
  @override
  @JsonKey(ignore: true)
  _$$DeviceHistoryResponseImplCopyWith<_$DeviceHistoryResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

DeviceCommandResponse _$DeviceCommandResponseFromJson(
    Map<String, dynamic> json) {
  return _DeviceCommandResponse.fromJson(json);
}

/// @nodoc
mixin _$DeviceCommandResponse {
  String get id => throw _privateConstructorUsedError;
  String get deviceId => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  Map<String, dynamic> get params => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  double get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceCommandResponseCopyWith<DeviceCommandResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceCommandResponseCopyWith<$Res> {
  factory $DeviceCommandResponseCopyWith(DeviceCommandResponse value,
          $Res Function(DeviceCommandResponse) then) =
      _$DeviceCommandResponseCopyWithImpl<$Res, DeviceCommandResponse>;
  @useResult
  $Res call(
      {String id,
      String deviceId,
      String action,
      Map<String, dynamic> params,
      String status,
      double createdAt});
}

/// @nodoc
class _$DeviceCommandResponseCopyWithImpl<$Res,
        $Val extends DeviceCommandResponse>
    implements $DeviceCommandResponseCopyWith<$Res> {
  _$DeviceCommandResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? action = null,
    Object? params = null,
    Object? status = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value.params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceCommandResponseImplCopyWith<$Res>
    implements $DeviceCommandResponseCopyWith<$Res> {
  factory _$$DeviceCommandResponseImplCopyWith(
          _$DeviceCommandResponseImpl value,
          $Res Function(_$DeviceCommandResponseImpl) then) =
      __$$DeviceCommandResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String deviceId,
      String action,
      Map<String, dynamic> params,
      String status,
      double createdAt});
}

/// @nodoc
class __$$DeviceCommandResponseImplCopyWithImpl<$Res>
    extends _$DeviceCommandResponseCopyWithImpl<$Res,
        _$DeviceCommandResponseImpl>
    implements _$$DeviceCommandResponseImplCopyWith<$Res> {
  __$$DeviceCommandResponseImplCopyWithImpl(_$DeviceCommandResponseImpl _value,
      $Res Function(_$DeviceCommandResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? action = null,
    Object? params = null,
    Object? status = null,
    Object? createdAt = null,
  }) {
    return _then(_$DeviceCommandResponseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value._params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceCommandResponseImpl implements _DeviceCommandResponse {
  const _$DeviceCommandResponseImpl(
      {required this.id,
      required this.deviceId,
      required this.action,
      required final Map<String, dynamic> params,
      required this.status,
      required this.createdAt})
      : _params = params;

  factory _$DeviceCommandResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceCommandResponseImplFromJson(json);

  @override
  final String id;
  @override
  final String deviceId;
  @override
  final String action;
  final Map<String, dynamic> _params;
  @override
  Map<String, dynamic> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  final String status;
  @override
  final double createdAt;

  @override
  String toString() {
    return 'DeviceCommandResponse(id: $id, deviceId: $deviceId, action: $action, params: $params, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceCommandResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.action, action) || other.action == action) &&
            const DeepCollectionEquality().equals(other._params, _params) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, deviceId, action,
      const DeepCollectionEquality().hash(_params), status, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceCommandResponseImplCopyWith<_$DeviceCommandResponseImpl>
      get copyWith => __$$DeviceCommandResponseImplCopyWithImpl<
          _$DeviceCommandResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceCommandResponseImplToJson(
      this,
    );
  }
}

abstract class _DeviceCommandResponse implements DeviceCommandResponse {
  const factory _DeviceCommandResponse(
      {required final String id,
      required final String deviceId,
      required final String action,
      required final Map<String, dynamic> params,
      required final String status,
      required final double createdAt}) = _$DeviceCommandResponseImpl;

  factory _DeviceCommandResponse.fromJson(Map<String, dynamic> json) =
      _$DeviceCommandResponseImpl.fromJson;

  @override
  String get id;
  @override
  String get deviceId;
  @override
  String get action;
  @override
  Map<String, dynamic> get params;
  @override
  String get status;
  @override
  double get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$DeviceCommandResponseImplCopyWith<_$DeviceCommandResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

DeviceCommandResult _$DeviceCommandResultFromJson(Map<String, dynamic> json) {
  return _DeviceCommandResult.fromJson(json);
}

/// @nodoc
mixin _$DeviceCommandResult {
  String get id => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  Map<String, dynamic>? get result => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceCommandResultCopyWith<DeviceCommandResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceCommandResultCopyWith<$Res> {
  factory $DeviceCommandResultCopyWith(
          DeviceCommandResult value, $Res Function(DeviceCommandResult) then) =
      _$DeviceCommandResultCopyWithImpl<$Res, DeviceCommandResult>;
  @useResult
  $Res call({String id, String status, Map<String, dynamic>? result});
}

/// @nodoc
class _$DeviceCommandResultCopyWithImpl<$Res, $Val extends DeviceCommandResult>
    implements $DeviceCommandResultCopyWith<$Res> {
  _$DeviceCommandResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? result = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceCommandResultImplCopyWith<$Res>
    implements $DeviceCommandResultCopyWith<$Res> {
  factory _$$DeviceCommandResultImplCopyWith(_$DeviceCommandResultImpl value,
          $Res Function(_$DeviceCommandResultImpl) then) =
      __$$DeviceCommandResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String status, Map<String, dynamic>? result});
}

/// @nodoc
class __$$DeviceCommandResultImplCopyWithImpl<$Res>
    extends _$DeviceCommandResultCopyWithImpl<$Res, _$DeviceCommandResultImpl>
    implements _$$DeviceCommandResultImplCopyWith<$Res> {
  __$$DeviceCommandResultImplCopyWithImpl(_$DeviceCommandResultImpl _value,
      $Res Function(_$DeviceCommandResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? result = freezed,
  }) {
    return _then(_$DeviceCommandResultImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      result: freezed == result
          ? _value._result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceCommandResultImpl implements _DeviceCommandResult {
  const _$DeviceCommandResultImpl(
      {required this.id,
      required this.status,
      final Map<String, dynamic>? result})
      : _result = result;

  factory _$DeviceCommandResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceCommandResultImplFromJson(json);

  @override
  final String id;
  @override
  final String status;
  final Map<String, dynamic>? _result;
  @override
  Map<String, dynamic>? get result {
    final value = _result;
    if (value == null) return null;
    if (_result is EqualUnmodifiableMapView) return _result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'DeviceCommandResult(id: $id, status: $status, result: $result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceCommandResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._result, _result));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, status, const DeepCollectionEquality().hash(_result));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceCommandResultImplCopyWith<_$DeviceCommandResultImpl> get copyWith =>
      __$$DeviceCommandResultImplCopyWithImpl<_$DeviceCommandResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceCommandResultImplToJson(
      this,
    );
  }
}

abstract class _DeviceCommandResult implements DeviceCommandResult {
  const factory _DeviceCommandResult(
      {required final String id,
      required final String status,
      final Map<String, dynamic>? result}) = _$DeviceCommandResultImpl;

  factory _DeviceCommandResult.fromJson(Map<String, dynamic> json) =
      _$DeviceCommandResultImpl.fromJson;

  @override
  String get id;
  @override
  String get status;
  @override
  Map<String, dynamic>? get result;
  @override
  @JsonKey(ignore: true)
  _$$DeviceCommandResultImplCopyWith<_$DeviceCommandResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InstanceInfo _$InstanceInfoFromJson(Map<String, dynamic> json) {
  return _InstanceInfo.fromJson(json);
}

/// @nodoc
mixin _$InstanceInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get persona => throw _privateConstructorUsedError;
  String get memoryScope => throw _privateConstructorUsedError;
  List<String> get skills => throw _privateConstructorUsedError;
  double get budgetUsd => throw _privateConstructorUsedError;
  String get owner => throw _privateConstructorUsedError;
  double get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InstanceInfoCopyWith<InstanceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InstanceInfoCopyWith<$Res> {
  factory $InstanceInfoCopyWith(
          InstanceInfo value, $Res Function(InstanceInfo) then) =
      _$InstanceInfoCopyWithImpl<$Res, InstanceInfo>;
  @useResult
  $Res call(
      {String id,
      String name,
      String persona,
      String memoryScope,
      List<String> skills,
      double budgetUsd,
      String owner,
      double createdAt});
}

/// @nodoc
class _$InstanceInfoCopyWithImpl<$Res, $Val extends InstanceInfo>
    implements $InstanceInfoCopyWith<$Res> {
  _$InstanceInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? persona = null,
    Object? memoryScope = null,
    Object? skills = null,
    Object? budgetUsd = null,
    Object? owner = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      persona: null == persona
          ? _value.persona
          : persona // ignore: cast_nullable_to_non_nullable
              as String,
      memoryScope: null == memoryScope
          ? _value.memoryScope
          : memoryScope // ignore: cast_nullable_to_non_nullable
              as String,
      skills: null == skills
          ? _value.skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      budgetUsd: null == budgetUsd
          ? _value.budgetUsd
          : budgetUsd // ignore: cast_nullable_to_non_nullable
              as double,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InstanceInfoImplCopyWith<$Res>
    implements $InstanceInfoCopyWith<$Res> {
  factory _$$InstanceInfoImplCopyWith(
          _$InstanceInfoImpl value, $Res Function(_$InstanceInfoImpl) then) =
      __$$InstanceInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String persona,
      String memoryScope,
      List<String> skills,
      double budgetUsd,
      String owner,
      double createdAt});
}

/// @nodoc
class __$$InstanceInfoImplCopyWithImpl<$Res>
    extends _$InstanceInfoCopyWithImpl<$Res, _$InstanceInfoImpl>
    implements _$$InstanceInfoImplCopyWith<$Res> {
  __$$InstanceInfoImplCopyWithImpl(
      _$InstanceInfoImpl _value, $Res Function(_$InstanceInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? persona = null,
    Object? memoryScope = null,
    Object? skills = null,
    Object? budgetUsd = null,
    Object? owner = null,
    Object? createdAt = null,
  }) {
    return _then(_$InstanceInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      persona: null == persona
          ? _value.persona
          : persona // ignore: cast_nullable_to_non_nullable
              as String,
      memoryScope: null == memoryScope
          ? _value.memoryScope
          : memoryScope // ignore: cast_nullable_to_non_nullable
              as String,
      skills: null == skills
          ? _value._skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      budgetUsd: null == budgetUsd
          ? _value.budgetUsd
          : budgetUsd // ignore: cast_nullable_to_non_nullable
              as double,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InstanceInfoImpl implements _InstanceInfo {
  const _$InstanceInfoImpl(
      {required this.id,
      required this.name,
      required this.persona,
      required this.memoryScope,
      required final List<String> skills,
      required this.budgetUsd,
      required this.owner,
      required this.createdAt})
      : _skills = skills;

  factory _$InstanceInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$InstanceInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String persona;
  @override
  final String memoryScope;
  final List<String> _skills;
  @override
  List<String> get skills {
    if (_skills is EqualUnmodifiableListView) return _skills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skills);
  }

  @override
  final double budgetUsd;
  @override
  final String owner;
  @override
  final double createdAt;

  @override
  String toString() {
    return 'InstanceInfo(id: $id, name: $name, persona: $persona, memoryScope: $memoryScope, skills: $skills, budgetUsd: $budgetUsd, owner: $owner, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InstanceInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.persona, persona) || other.persona == persona) &&
            (identical(other.memoryScope, memoryScope) ||
                other.memoryScope == memoryScope) &&
            const DeepCollectionEquality().equals(other._skills, _skills) &&
            (identical(other.budgetUsd, budgetUsd) ||
                other.budgetUsd == budgetUsd) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      persona,
      memoryScope,
      const DeepCollectionEquality().hash(_skills),
      budgetUsd,
      owner,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InstanceInfoImplCopyWith<_$InstanceInfoImpl> get copyWith =>
      __$$InstanceInfoImplCopyWithImpl<_$InstanceInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InstanceInfoImplToJson(
      this,
    );
  }
}

abstract class _InstanceInfo implements InstanceInfo {
  const factory _InstanceInfo(
      {required final String id,
      required final String name,
      required final String persona,
      required final String memoryScope,
      required final List<String> skills,
      required final double budgetUsd,
      required final String owner,
      required final double createdAt}) = _$InstanceInfoImpl;

  factory _InstanceInfo.fromJson(Map<String, dynamic> json) =
      _$InstanceInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get persona;
  @override
  String get memoryScope;
  @override
  List<String> get skills;
  @override
  double get budgetUsd;
  @override
  String get owner;
  @override
  double get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$InstanceInfoImplCopyWith<_$InstanceInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InstancesListResponse _$InstancesListResponseFromJson(
    Map<String, dynamic> json) {
  return _InstancesListResponse.fromJson(json);
}

/// @nodoc
mixin _$InstancesListResponse {
  List<InstanceInfo> get instances => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InstancesListResponseCopyWith<InstancesListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InstancesListResponseCopyWith<$Res> {
  factory $InstancesListResponseCopyWith(InstancesListResponse value,
          $Res Function(InstancesListResponse) then) =
      _$InstancesListResponseCopyWithImpl<$Res, InstancesListResponse>;
  @useResult
  $Res call({List<InstanceInfo> instances});
}

/// @nodoc
class _$InstancesListResponseCopyWithImpl<$Res,
        $Val extends InstancesListResponse>
    implements $InstancesListResponseCopyWith<$Res> {
  _$InstancesListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? instances = null,
  }) {
    return _then(_value.copyWith(
      instances: null == instances
          ? _value.instances
          : instances // ignore: cast_nullable_to_non_nullable
              as List<InstanceInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InstancesListResponseImplCopyWith<$Res>
    implements $InstancesListResponseCopyWith<$Res> {
  factory _$$InstancesListResponseImplCopyWith(
          _$InstancesListResponseImpl value,
          $Res Function(_$InstancesListResponseImpl) then) =
      __$$InstancesListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<InstanceInfo> instances});
}

/// @nodoc
class __$$InstancesListResponseImplCopyWithImpl<$Res>
    extends _$InstancesListResponseCopyWithImpl<$Res,
        _$InstancesListResponseImpl>
    implements _$$InstancesListResponseImplCopyWith<$Res> {
  __$$InstancesListResponseImplCopyWithImpl(_$InstancesListResponseImpl _value,
      $Res Function(_$InstancesListResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? instances = null,
  }) {
    return _then(_$InstancesListResponseImpl(
      instances: null == instances
          ? _value._instances
          : instances // ignore: cast_nullable_to_non_nullable
              as List<InstanceInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InstancesListResponseImpl implements _InstancesListResponse {
  const _$InstancesListResponseImpl(
      {required final List<InstanceInfo> instances})
      : _instances = instances;

  factory _$InstancesListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$InstancesListResponseImplFromJson(json);

  final List<InstanceInfo> _instances;
  @override
  List<InstanceInfo> get instances {
    if (_instances is EqualUnmodifiableListView) return _instances;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_instances);
  }

  @override
  String toString() {
    return 'InstancesListResponse(instances: $instances)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InstancesListResponseImpl &&
            const DeepCollectionEquality()
                .equals(other._instances, _instances));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_instances));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InstancesListResponseImplCopyWith<_$InstancesListResponseImpl>
      get copyWith => __$$InstancesListResponseImplCopyWithImpl<
          _$InstancesListResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InstancesListResponseImplToJson(
      this,
    );
  }
}

abstract class _InstancesListResponse implements InstancesListResponse {
  const factory _InstancesListResponse(
          {required final List<InstanceInfo> instances}) =
      _$InstancesListResponseImpl;

  factory _InstancesListResponse.fromJson(Map<String, dynamic> json) =
      _$InstancesListResponseImpl.fromJson;

  @override
  List<InstanceInfo> get instances;
  @override
  @JsonKey(ignore: true)
  _$$InstancesListResponseImplCopyWith<_$InstancesListResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

InstanceCreateResponse _$InstanceCreateResponseFromJson(
    Map<String, dynamic> json) {
  return _InstanceCreateResponse.fromJson(json);
}

/// @nodoc
mixin _$InstanceCreateResponse {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get persona => throw _privateConstructorUsedError;
  String get memoryScope => throw _privateConstructorUsedError;
  List<String> get skills => throw _privateConstructorUsedError;
  double get budgetUsd => throw _privateConstructorUsedError;
  String get owner => throw _privateConstructorUsedError;
  double get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InstanceCreateResponseCopyWith<InstanceCreateResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InstanceCreateResponseCopyWith<$Res> {
  factory $InstanceCreateResponseCopyWith(InstanceCreateResponse value,
          $Res Function(InstanceCreateResponse) then) =
      _$InstanceCreateResponseCopyWithImpl<$Res, InstanceCreateResponse>;
  @useResult
  $Res call(
      {String id,
      String name,
      String persona,
      String memoryScope,
      List<String> skills,
      double budgetUsd,
      String owner,
      double createdAt});
}

/// @nodoc
class _$InstanceCreateResponseCopyWithImpl<$Res,
        $Val extends InstanceCreateResponse>
    implements $InstanceCreateResponseCopyWith<$Res> {
  _$InstanceCreateResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? persona = null,
    Object? memoryScope = null,
    Object? skills = null,
    Object? budgetUsd = null,
    Object? owner = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      persona: null == persona
          ? _value.persona
          : persona // ignore: cast_nullable_to_non_nullable
              as String,
      memoryScope: null == memoryScope
          ? _value.memoryScope
          : memoryScope // ignore: cast_nullable_to_non_nullable
              as String,
      skills: null == skills
          ? _value.skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      budgetUsd: null == budgetUsd
          ? _value.budgetUsd
          : budgetUsd // ignore: cast_nullable_to_non_nullable
              as double,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InstanceCreateResponseImplCopyWith<$Res>
    implements $InstanceCreateResponseCopyWith<$Res> {
  factory _$$InstanceCreateResponseImplCopyWith(
          _$InstanceCreateResponseImpl value,
          $Res Function(_$InstanceCreateResponseImpl) then) =
      __$$InstanceCreateResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String persona,
      String memoryScope,
      List<String> skills,
      double budgetUsd,
      String owner,
      double createdAt});
}

/// @nodoc
class __$$InstanceCreateResponseImplCopyWithImpl<$Res>
    extends _$InstanceCreateResponseCopyWithImpl<$Res,
        _$InstanceCreateResponseImpl>
    implements _$$InstanceCreateResponseImplCopyWith<$Res> {
  __$$InstanceCreateResponseImplCopyWithImpl(
      _$InstanceCreateResponseImpl _value,
      $Res Function(_$InstanceCreateResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? persona = null,
    Object? memoryScope = null,
    Object? skills = null,
    Object? budgetUsd = null,
    Object? owner = null,
    Object? createdAt = null,
  }) {
    return _then(_$InstanceCreateResponseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      persona: null == persona
          ? _value.persona
          : persona // ignore: cast_nullable_to_non_nullable
              as String,
      memoryScope: null == memoryScope
          ? _value.memoryScope
          : memoryScope // ignore: cast_nullable_to_non_nullable
              as String,
      skills: null == skills
          ? _value._skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      budgetUsd: null == budgetUsd
          ? _value.budgetUsd
          : budgetUsd // ignore: cast_nullable_to_non_nullable
              as double,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InstanceCreateResponseImpl implements _InstanceCreateResponse {
  const _$InstanceCreateResponseImpl(
      {required this.id,
      required this.name,
      required this.persona,
      required this.memoryScope,
      required final List<String> skills,
      required this.budgetUsd,
      required this.owner,
      required this.createdAt})
      : _skills = skills;

  factory _$InstanceCreateResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$InstanceCreateResponseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String persona;
  @override
  final String memoryScope;
  final List<String> _skills;
  @override
  List<String> get skills {
    if (_skills is EqualUnmodifiableListView) return _skills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skills);
  }

  @override
  final double budgetUsd;
  @override
  final String owner;
  @override
  final double createdAt;

  @override
  String toString() {
    return 'InstanceCreateResponse(id: $id, name: $name, persona: $persona, memoryScope: $memoryScope, skills: $skills, budgetUsd: $budgetUsd, owner: $owner, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InstanceCreateResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.persona, persona) || other.persona == persona) &&
            (identical(other.memoryScope, memoryScope) ||
                other.memoryScope == memoryScope) &&
            const DeepCollectionEquality().equals(other._skills, _skills) &&
            (identical(other.budgetUsd, budgetUsd) ||
                other.budgetUsd == budgetUsd) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      persona,
      memoryScope,
      const DeepCollectionEquality().hash(_skills),
      budgetUsd,
      owner,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InstanceCreateResponseImplCopyWith<_$InstanceCreateResponseImpl>
      get copyWith => __$$InstanceCreateResponseImplCopyWithImpl<
          _$InstanceCreateResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InstanceCreateResponseImplToJson(
      this,
    );
  }
}

abstract class _InstanceCreateResponse implements InstanceCreateResponse {
  const factory _InstanceCreateResponse(
      {required final String id,
      required final String name,
      required final String persona,
      required final String memoryScope,
      required final List<String> skills,
      required final double budgetUsd,
      required final String owner,
      required final double createdAt}) = _$InstanceCreateResponseImpl;

  factory _InstanceCreateResponse.fromJson(Map<String, dynamic> json) =
      _$InstanceCreateResponseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get persona;
  @override
  String get memoryScope;
  @override
  List<String> get skills;
  @override
  double get budgetUsd;
  @override
  String get owner;
  @override
  double get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$InstanceCreateResponseImplCopyWith<_$InstanceCreateResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

InstanceResponse _$InstanceResponseFromJson(Map<String, dynamic> json) {
  return _InstanceResponse.fromJson(json);
}

/// @nodoc
mixin _$InstanceResponse {
  InstanceInfo get instance => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InstanceResponseCopyWith<InstanceResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InstanceResponseCopyWith<$Res> {
  factory $InstanceResponseCopyWith(
          InstanceResponse value, $Res Function(InstanceResponse) then) =
      _$InstanceResponseCopyWithImpl<$Res, InstanceResponse>;
  @useResult
  $Res call({InstanceInfo instance});

  $InstanceInfoCopyWith<$Res> get instance;
}

/// @nodoc
class _$InstanceResponseCopyWithImpl<$Res, $Val extends InstanceResponse>
    implements $InstanceResponseCopyWith<$Res> {
  _$InstanceResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? instance = null,
  }) {
    return _then(_value.copyWith(
      instance: null == instance
          ? _value.instance
          : instance // ignore: cast_nullable_to_non_nullable
              as InstanceInfo,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $InstanceInfoCopyWith<$Res> get instance {
    return $InstanceInfoCopyWith<$Res>(_value.instance, (value) {
      return _then(_value.copyWith(instance: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InstanceResponseImplCopyWith<$Res>
    implements $InstanceResponseCopyWith<$Res> {
  factory _$$InstanceResponseImplCopyWith(_$InstanceResponseImpl value,
          $Res Function(_$InstanceResponseImpl) then) =
      __$$InstanceResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({InstanceInfo instance});

  @override
  $InstanceInfoCopyWith<$Res> get instance;
}

/// @nodoc
class __$$InstanceResponseImplCopyWithImpl<$Res>
    extends _$InstanceResponseCopyWithImpl<$Res, _$InstanceResponseImpl>
    implements _$$InstanceResponseImplCopyWith<$Res> {
  __$$InstanceResponseImplCopyWithImpl(_$InstanceResponseImpl _value,
      $Res Function(_$InstanceResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? instance = null,
  }) {
    return _then(_$InstanceResponseImpl(
      instance: null == instance
          ? _value.instance
          : instance // ignore: cast_nullable_to_non_nullable
              as InstanceInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InstanceResponseImpl implements _InstanceResponse {
  const _$InstanceResponseImpl({required this.instance});

  factory _$InstanceResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$InstanceResponseImplFromJson(json);

  @override
  final InstanceInfo instance;

  @override
  String toString() {
    return 'InstanceResponse(instance: $instance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InstanceResponseImpl &&
            (identical(other.instance, instance) ||
                other.instance == instance));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, instance);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InstanceResponseImplCopyWith<_$InstanceResponseImpl> get copyWith =>
      __$$InstanceResponseImplCopyWithImpl<_$InstanceResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InstanceResponseImplToJson(
      this,
    );
  }
}

abstract class _InstanceResponse implements InstanceResponse {
  const factory _InstanceResponse({required final InstanceInfo instance}) =
      _$InstanceResponseImpl;

  factory _InstanceResponse.fromJson(Map<String, dynamic> json) =
      _$InstanceResponseImpl.fromJson;

  @override
  InstanceInfo get instance;
  @override
  @JsonKey(ignore: true)
  _$$InstanceResponseImplCopyWith<_$InstanceResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HostingAppInfo _$HostingAppInfoFromJson(Map<String, dynamic> json) {
  return _HostingAppInfo.fromJson(json);
}

/// @nodoc
mixin _$HostingAppInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String get entry => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  String get command => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  Map<String, String> get env => throw _privateConstructorUsedError;
  String get owner => throw _privateConstructorUsedError;
  bool get autostart => throw _privateConstructorUsedError;
  bool get tunnel => throw _privateConstructorUsedError;
  String get tunnelUrl => throw _privateConstructorUsedError;
  int get pid => throw _privateConstructorUsedError;
  String get logFile => throw _privateConstructorUsedError;
  double get createdAt => throw _privateConstructorUsedError;
  double? get startedAt => throw _privateConstructorUsedError;
  bool get alive => throw _privateConstructorUsedError;
  bool get reachable => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HostingAppInfoCopyWith<HostingAppInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostingAppInfoCopyWith<$Res> {
  factory $HostingAppInfoCopyWith(
          HostingAppInfo value, $Res Function(HostingAppInfo) then) =
      _$HostingAppInfoCopyWithImpl<$Res, HostingAppInfo>;
  @useResult
  $Res call(
      {String id,
      String name,
      String kind,
      String entry,
      String path,
      String command,
      int port,
      Map<String, String> env,
      String owner,
      bool autostart,
      bool tunnel,
      String tunnelUrl,
      int pid,
      String logFile,
      double createdAt,
      double? startedAt,
      bool alive,
      bool reachable});
}

/// @nodoc
class _$HostingAppInfoCopyWithImpl<$Res, $Val extends HostingAppInfo>
    implements $HostingAppInfoCopyWith<$Res> {
  _$HostingAppInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? entry = null,
    Object? path = null,
    Object? command = null,
    Object? port = null,
    Object? env = null,
    Object? owner = null,
    Object? autostart = null,
    Object? tunnel = null,
    Object? tunnelUrl = null,
    Object? pid = null,
    Object? logFile = null,
    Object? createdAt = null,
    Object? startedAt = freezed,
    Object? alive = null,
    Object? reachable = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      entry: null == entry
          ? _value.entry
          : entry // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      env: null == env
          ? _value.env
          : env // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      autostart: null == autostart
          ? _value.autostart
          : autostart // ignore: cast_nullable_to_non_nullable
              as bool,
      tunnel: null == tunnel
          ? _value.tunnel
          : tunnel // ignore: cast_nullable_to_non_nullable
              as bool,
      tunnelUrl: null == tunnelUrl
          ? _value.tunnelUrl
          : tunnelUrl // ignore: cast_nullable_to_non_nullable
              as String,
      pid: null == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int,
      logFile: null == logFile
          ? _value.logFile
          : logFile // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as double?,
      alive: null == alive
          ? _value.alive
          : alive // ignore: cast_nullable_to_non_nullable
              as bool,
      reachable: null == reachable
          ? _value.reachable
          : reachable // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HostingAppInfoImplCopyWith<$Res>
    implements $HostingAppInfoCopyWith<$Res> {
  factory _$$HostingAppInfoImplCopyWith(_$HostingAppInfoImpl value,
          $Res Function(_$HostingAppInfoImpl) then) =
      __$$HostingAppInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String kind,
      String entry,
      String path,
      String command,
      int port,
      Map<String, String> env,
      String owner,
      bool autostart,
      bool tunnel,
      String tunnelUrl,
      int pid,
      String logFile,
      double createdAt,
      double? startedAt,
      bool alive,
      bool reachable});
}

/// @nodoc
class __$$HostingAppInfoImplCopyWithImpl<$Res>
    extends _$HostingAppInfoCopyWithImpl<$Res, _$HostingAppInfoImpl>
    implements _$$HostingAppInfoImplCopyWith<$Res> {
  __$$HostingAppInfoImplCopyWithImpl(
      _$HostingAppInfoImpl _value, $Res Function(_$HostingAppInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? entry = null,
    Object? path = null,
    Object? command = null,
    Object? port = null,
    Object? env = null,
    Object? owner = null,
    Object? autostart = null,
    Object? tunnel = null,
    Object? tunnelUrl = null,
    Object? pid = null,
    Object? logFile = null,
    Object? createdAt = null,
    Object? startedAt = freezed,
    Object? alive = null,
    Object? reachable = null,
  }) {
    return _then(_$HostingAppInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      entry: null == entry
          ? _value.entry
          : entry // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      env: null == env
          ? _value._env
          : env // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      autostart: null == autostart
          ? _value.autostart
          : autostart // ignore: cast_nullable_to_non_nullable
              as bool,
      tunnel: null == tunnel
          ? _value.tunnel
          : tunnel // ignore: cast_nullable_to_non_nullable
              as bool,
      tunnelUrl: null == tunnelUrl
          ? _value.tunnelUrl
          : tunnelUrl // ignore: cast_nullable_to_non_nullable
              as String,
      pid: null == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int,
      logFile: null == logFile
          ? _value.logFile
          : logFile // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as double?,
      alive: null == alive
          ? _value.alive
          : alive // ignore: cast_nullable_to_non_nullable
              as bool,
      reachable: null == reachable
          ? _value.reachable
          : reachable // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HostingAppInfoImpl implements _HostingAppInfo {
  const _$HostingAppInfoImpl(
      {required this.id,
      required this.name,
      required this.kind,
      required this.entry,
      required this.path,
      required this.command,
      required this.port,
      required final Map<String, String> env,
      required this.owner,
      required this.autostart,
      required this.tunnel,
      required this.tunnelUrl,
      required this.pid,
      required this.logFile,
      required this.createdAt,
      this.startedAt,
      required this.alive,
      required this.reachable})
      : _env = env;

  factory _$HostingAppInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostingAppInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String kind;
  @override
  final String entry;
  @override
  final String path;
  @override
  final String command;
  @override
  final int port;
  final Map<String, String> _env;
  @override
  Map<String, String> get env {
    if (_env is EqualUnmodifiableMapView) return _env;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_env);
  }

  @override
  final String owner;
  @override
  final bool autostart;
  @override
  final bool tunnel;
  @override
  final String tunnelUrl;
  @override
  final int pid;
  @override
  final String logFile;
  @override
  final double createdAt;
  @override
  final double? startedAt;
  @override
  final bool alive;
  @override
  final bool reachable;

  @override
  String toString() {
    return 'HostingAppInfo(id: $id, name: $name, kind: $kind, entry: $entry, path: $path, command: $command, port: $port, env: $env, owner: $owner, autostart: $autostart, tunnel: $tunnel, tunnelUrl: $tunnelUrl, pid: $pid, logFile: $logFile, createdAt: $createdAt, startedAt: $startedAt, alive: $alive, reachable: $reachable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostingAppInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.entry, entry) || other.entry == entry) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.port, port) || other.port == port) &&
            const DeepCollectionEquality().equals(other._env, _env) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.autostart, autostart) ||
                other.autostart == autostart) &&
            (identical(other.tunnel, tunnel) || other.tunnel == tunnel) &&
            (identical(other.tunnelUrl, tunnelUrl) ||
                other.tunnelUrl == tunnelUrl) &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.logFile, logFile) || other.logFile == logFile) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.alive, alive) || other.alive == alive) &&
            (identical(other.reachable, reachable) ||
                other.reachable == reachable));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      kind,
      entry,
      path,
      command,
      port,
      const DeepCollectionEquality().hash(_env),
      owner,
      autostart,
      tunnel,
      tunnelUrl,
      pid,
      logFile,
      createdAt,
      startedAt,
      alive,
      reachable);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HostingAppInfoImplCopyWith<_$HostingAppInfoImpl> get copyWith =>
      __$$HostingAppInfoImplCopyWithImpl<_$HostingAppInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostingAppInfoImplToJson(
      this,
    );
  }
}

abstract class _HostingAppInfo implements HostingAppInfo {
  const factory _HostingAppInfo(
      {required final String id,
      required final String name,
      required final String kind,
      required final String entry,
      required final String path,
      required final String command,
      required final int port,
      required final Map<String, String> env,
      required final String owner,
      required final bool autostart,
      required final bool tunnel,
      required final String tunnelUrl,
      required final int pid,
      required final String logFile,
      required final double createdAt,
      final double? startedAt,
      required final bool alive,
      required final bool reachable}) = _$HostingAppInfoImpl;

  factory _HostingAppInfo.fromJson(Map<String, dynamic> json) =
      _$HostingAppInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get kind;
  @override
  String get entry;
  @override
  String get path;
  @override
  String get command;
  @override
  int get port;
  @override
  Map<String, String> get env;
  @override
  String get owner;
  @override
  bool get autostart;
  @override
  bool get tunnel;
  @override
  String get tunnelUrl;
  @override
  int get pid;
  @override
  String get logFile;
  @override
  double get createdAt;
  @override
  double? get startedAt;
  @override
  bool get alive;
  @override
  bool get reachable;
  @override
  @JsonKey(ignore: true)
  _$$HostingAppInfoImplCopyWith<_$HostingAppInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HostingAppsResponse _$HostingAppsResponseFromJson(Map<String, dynamic> json) {
  return _HostingAppsResponse.fromJson(json);
}

/// @nodoc
mixin _$HostingAppsResponse {
  List<HostingAppInfo> get apps => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HostingAppsResponseCopyWith<HostingAppsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostingAppsResponseCopyWith<$Res> {
  factory $HostingAppsResponseCopyWith(
          HostingAppsResponse value, $Res Function(HostingAppsResponse) then) =
      _$HostingAppsResponseCopyWithImpl<$Res, HostingAppsResponse>;
  @useResult
  $Res call({List<HostingAppInfo> apps});
}

/// @nodoc
class _$HostingAppsResponseCopyWithImpl<$Res, $Val extends HostingAppsResponse>
    implements $HostingAppsResponseCopyWith<$Res> {
  _$HostingAppsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apps = null,
  }) {
    return _then(_value.copyWith(
      apps: null == apps
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as List<HostingAppInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HostingAppsResponseImplCopyWith<$Res>
    implements $HostingAppsResponseCopyWith<$Res> {
  factory _$$HostingAppsResponseImplCopyWith(_$HostingAppsResponseImpl value,
          $Res Function(_$HostingAppsResponseImpl) then) =
      __$$HostingAppsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<HostingAppInfo> apps});
}

/// @nodoc
class __$$HostingAppsResponseImplCopyWithImpl<$Res>
    extends _$HostingAppsResponseCopyWithImpl<$Res, _$HostingAppsResponseImpl>
    implements _$$HostingAppsResponseImplCopyWith<$Res> {
  __$$HostingAppsResponseImplCopyWithImpl(_$HostingAppsResponseImpl _value,
      $Res Function(_$HostingAppsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apps = null,
  }) {
    return _then(_$HostingAppsResponseImpl(
      apps: null == apps
          ? _value._apps
          : apps // ignore: cast_nullable_to_non_nullable
              as List<HostingAppInfo>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HostingAppsResponseImpl implements _HostingAppsResponse {
  const _$HostingAppsResponseImpl({required final List<HostingAppInfo> apps})
      : _apps = apps;

  factory _$HostingAppsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostingAppsResponseImplFromJson(json);

  final List<HostingAppInfo> _apps;
  @override
  List<HostingAppInfo> get apps {
    if (_apps is EqualUnmodifiableListView) return _apps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_apps);
  }

  @override
  String toString() {
    return 'HostingAppsResponse(apps: $apps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostingAppsResponseImpl &&
            const DeepCollectionEquality().equals(other._apps, _apps));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_apps));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HostingAppsResponseImplCopyWith<_$HostingAppsResponseImpl> get copyWith =>
      __$$HostingAppsResponseImplCopyWithImpl<_$HostingAppsResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostingAppsResponseImplToJson(
      this,
    );
  }
}

abstract class _HostingAppsResponse implements HostingAppsResponse {
  const factory _HostingAppsResponse(
      {required final List<HostingAppInfo> apps}) = _$HostingAppsResponseImpl;

  factory _HostingAppsResponse.fromJson(Map<String, dynamic> json) =
      _$HostingAppsResponseImpl.fromJson;

  @override
  List<HostingAppInfo> get apps;
  @override
  @JsonKey(ignore: true)
  _$$HostingAppsResponseImplCopyWith<_$HostingAppsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HostingDeployResponse _$HostingDeployResponseFromJson(
    Map<String, dynamic> json) {
  return _HostingDeployResponse.fromJson(json);
}

/// @nodoc
mixin _$HostingDeployResponse {
  bool get ok => throw _privateConstructorUsedError;
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String get entry => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  String get command => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  Map<String, String> get env => throw _privateConstructorUsedError;
  String get owner => throw _privateConstructorUsedError;
  bool get autostart => throw _privateConstructorUsedError;
  bool get tunnel => throw _privateConstructorUsedError;
  String? get tunnelUrl => throw _privateConstructorUsedError;
  int? get pid => throw _privateConstructorUsedError;
  String? get logFile => throw _privateConstructorUsedError;
  double? get createdAt => throw _privateConstructorUsedError;
  double? get startedAt => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HostingDeployResponseCopyWith<HostingDeployResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostingDeployResponseCopyWith<$Res> {
  factory $HostingDeployResponseCopyWith(HostingDeployResponse value,
          $Res Function(HostingDeployResponse) then) =
      _$HostingDeployResponseCopyWithImpl<$Res, HostingDeployResponse>;
  @useResult
  $Res call(
      {bool ok,
      String id,
      String name,
      String kind,
      String entry,
      String path,
      String command,
      int port,
      Map<String, String> env,
      String owner,
      bool autostart,
      bool tunnel,
      String? tunnelUrl,
      int? pid,
      String? logFile,
      double? createdAt,
      double? startedAt,
      String? error});
}

/// @nodoc
class _$HostingDeployResponseCopyWithImpl<$Res,
        $Val extends HostingDeployResponse>
    implements $HostingDeployResponseCopyWith<$Res> {
  _$HostingDeployResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? entry = null,
    Object? path = null,
    Object? command = null,
    Object? port = null,
    Object? env = null,
    Object? owner = null,
    Object? autostart = null,
    Object? tunnel = null,
    Object? tunnelUrl = freezed,
    Object? pid = freezed,
    Object? logFile = freezed,
    Object? createdAt = freezed,
    Object? startedAt = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as bool,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      entry: null == entry
          ? _value.entry
          : entry // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      env: null == env
          ? _value.env
          : env // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      autostart: null == autostart
          ? _value.autostart
          : autostart // ignore: cast_nullable_to_non_nullable
              as bool,
      tunnel: null == tunnel
          ? _value.tunnel
          : tunnel // ignore: cast_nullable_to_non_nullable
              as bool,
      tunnelUrl: freezed == tunnelUrl
          ? _value.tunnelUrl
          : tunnelUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      pid: freezed == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int?,
      logFile: freezed == logFile
          ? _value.logFile
          : logFile // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as double?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HostingDeployResponseImplCopyWith<$Res>
    implements $HostingDeployResponseCopyWith<$Res> {
  factory _$$HostingDeployResponseImplCopyWith(
          _$HostingDeployResponseImpl value,
          $Res Function(_$HostingDeployResponseImpl) then) =
      __$$HostingDeployResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool ok,
      String id,
      String name,
      String kind,
      String entry,
      String path,
      String command,
      int port,
      Map<String, String> env,
      String owner,
      bool autostart,
      bool tunnel,
      String? tunnelUrl,
      int? pid,
      String? logFile,
      double? createdAt,
      double? startedAt,
      String? error});
}

/// @nodoc
class __$$HostingDeployResponseImplCopyWithImpl<$Res>
    extends _$HostingDeployResponseCopyWithImpl<$Res,
        _$HostingDeployResponseImpl>
    implements _$$HostingDeployResponseImplCopyWith<$Res> {
  __$$HostingDeployResponseImplCopyWithImpl(_$HostingDeployResponseImpl _value,
      $Res Function(_$HostingDeployResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? entry = null,
    Object? path = null,
    Object? command = null,
    Object? port = null,
    Object? env = null,
    Object? owner = null,
    Object? autostart = null,
    Object? tunnel = null,
    Object? tunnelUrl = freezed,
    Object? pid = freezed,
    Object? logFile = freezed,
    Object? createdAt = freezed,
    Object? startedAt = freezed,
    Object? error = freezed,
  }) {
    return _then(_$HostingDeployResponseImpl(
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as bool,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      entry: null == entry
          ? _value.entry
          : entry // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      env: null == env
          ? _value._env
          : env // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      autostart: null == autostart
          ? _value.autostart
          : autostart // ignore: cast_nullable_to_non_nullable
              as bool,
      tunnel: null == tunnel
          ? _value.tunnel
          : tunnel // ignore: cast_nullable_to_non_nullable
              as bool,
      tunnelUrl: freezed == tunnelUrl
          ? _value.tunnelUrl
          : tunnelUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      pid: freezed == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int?,
      logFile: freezed == logFile
          ? _value.logFile
          : logFile // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as double?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as double?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HostingDeployResponseImpl implements _HostingDeployResponse {
  const _$HostingDeployResponseImpl(
      {required this.ok,
      required this.id,
      required this.name,
      required this.kind,
      required this.entry,
      required this.path,
      required this.command,
      required this.port,
      required final Map<String, String> env,
      required this.owner,
      required this.autostart,
      required this.tunnel,
      this.tunnelUrl,
      this.pid,
      this.logFile,
      this.createdAt,
      this.startedAt,
      this.error})
      : _env = env;

  factory _$HostingDeployResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostingDeployResponseImplFromJson(json);

  @override
  final bool ok;
  @override
  final String id;
  @override
  final String name;
  @override
  final String kind;
  @override
  final String entry;
  @override
  final String path;
  @override
  final String command;
  @override
  final int port;
  final Map<String, String> _env;
  @override
  Map<String, String> get env {
    if (_env is EqualUnmodifiableMapView) return _env;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_env);
  }

  @override
  final String owner;
  @override
  final bool autostart;
  @override
  final bool tunnel;
  @override
  final String? tunnelUrl;
  @override
  final int? pid;
  @override
  final String? logFile;
  @override
  final double? createdAt;
  @override
  final double? startedAt;
  @override
  final String? error;

  @override
  String toString() {
    return 'HostingDeployResponse(ok: $ok, id: $id, name: $name, kind: $kind, entry: $entry, path: $path, command: $command, port: $port, env: $env, owner: $owner, autostart: $autostart, tunnel: $tunnel, tunnelUrl: $tunnelUrl, pid: $pid, logFile: $logFile, createdAt: $createdAt, startedAt: $startedAt, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostingDeployResponseImpl &&
            (identical(other.ok, ok) || other.ok == ok) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.entry, entry) || other.entry == entry) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.port, port) || other.port == port) &&
            const DeepCollectionEquality().equals(other._env, _env) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.autostart, autostart) ||
                other.autostart == autostart) &&
            (identical(other.tunnel, tunnel) || other.tunnel == tunnel) &&
            (identical(other.tunnelUrl, tunnelUrl) ||
                other.tunnelUrl == tunnelUrl) &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.logFile, logFile) || other.logFile == logFile) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      ok,
      id,
      name,
      kind,
      entry,
      path,
      command,
      port,
      const DeepCollectionEquality().hash(_env),
      owner,
      autostart,
      tunnel,
      tunnelUrl,
      pid,
      logFile,
      createdAt,
      startedAt,
      error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HostingDeployResponseImplCopyWith<_$HostingDeployResponseImpl>
      get copyWith => __$$HostingDeployResponseImplCopyWithImpl<
          _$HostingDeployResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostingDeployResponseImplToJson(
      this,
    );
  }
}

abstract class _HostingDeployResponse implements HostingDeployResponse {
  const factory _HostingDeployResponse(
      {required final bool ok,
      required final String id,
      required final String name,
      required final String kind,
      required final String entry,
      required final String path,
      required final String command,
      required final int port,
      required final Map<String, String> env,
      required final String owner,
      required final bool autostart,
      required final bool tunnel,
      final String? tunnelUrl,
      final int? pid,
      final String? logFile,
      final double? createdAt,
      final double? startedAt,
      final String? error}) = _$HostingDeployResponseImpl;

  factory _HostingDeployResponse.fromJson(Map<String, dynamic> json) =
      _$HostingDeployResponseImpl.fromJson;

  @override
  bool get ok;
  @override
  String get id;
  @override
  String get name;
  @override
  String get kind;
  @override
  String get entry;
  @override
  String get path;
  @override
  String get command;
  @override
  int get port;
  @override
  Map<String, String> get env;
  @override
  String get owner;
  @override
  bool get autostart;
  @override
  bool get tunnel;
  @override
  String? get tunnelUrl;
  @override
  int? get pid;
  @override
  String? get logFile;
  @override
  double? get createdAt;
  @override
  double? get startedAt;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$HostingDeployResponseImplCopyWith<_$HostingDeployResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

HostingAppResponse _$HostingAppResponseFromJson(Map<String, dynamic> json) {
  return _HostingAppResponse.fromJson(json);
}

/// @nodoc
mixin _$HostingAppResponse {
  bool get ok => throw _privateConstructorUsedError;
  HostingAppInfo get app => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HostingAppResponseCopyWith<HostingAppResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostingAppResponseCopyWith<$Res> {
  factory $HostingAppResponseCopyWith(
          HostingAppResponse value, $Res Function(HostingAppResponse) then) =
      _$HostingAppResponseCopyWithImpl<$Res, HostingAppResponse>;
  @useResult
  $Res call({bool ok, HostingAppInfo app});

  $HostingAppInfoCopyWith<$Res> get app;
}

/// @nodoc
class _$HostingAppResponseCopyWithImpl<$Res, $Val extends HostingAppResponse>
    implements $HostingAppResponseCopyWith<$Res> {
  _$HostingAppResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? app = null,
  }) {
    return _then(_value.copyWith(
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as bool,
      app: null == app
          ? _value.app
          : app // ignore: cast_nullable_to_non_nullable
              as HostingAppInfo,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $HostingAppInfoCopyWith<$Res> get app {
    return $HostingAppInfoCopyWith<$Res>(_value.app, (value) {
      return _then(_value.copyWith(app: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HostingAppResponseImplCopyWith<$Res>
    implements $HostingAppResponseCopyWith<$Res> {
  factory _$$HostingAppResponseImplCopyWith(_$HostingAppResponseImpl value,
          $Res Function(_$HostingAppResponseImpl) then) =
      __$$HostingAppResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool ok, HostingAppInfo app});

  @override
  $HostingAppInfoCopyWith<$Res> get app;
}

/// @nodoc
class __$$HostingAppResponseImplCopyWithImpl<$Res>
    extends _$HostingAppResponseCopyWithImpl<$Res, _$HostingAppResponseImpl>
    implements _$$HostingAppResponseImplCopyWith<$Res> {
  __$$HostingAppResponseImplCopyWithImpl(_$HostingAppResponseImpl _value,
      $Res Function(_$HostingAppResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? app = null,
  }) {
    return _then(_$HostingAppResponseImpl(
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as bool,
      app: null == app
          ? _value.app
          : app // ignore: cast_nullable_to_non_nullable
              as HostingAppInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HostingAppResponseImpl implements _HostingAppResponse {
  const _$HostingAppResponseImpl({required this.ok, required this.app});

  factory _$HostingAppResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostingAppResponseImplFromJson(json);

  @override
  final bool ok;
  @override
  final HostingAppInfo app;

  @override
  String toString() {
    return 'HostingAppResponse(ok: $ok, app: $app)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostingAppResponseImpl &&
            (identical(other.ok, ok) || other.ok == ok) &&
            (identical(other.app, app) || other.app == app));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, ok, app);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HostingAppResponseImplCopyWith<_$HostingAppResponseImpl> get copyWith =>
      __$$HostingAppResponseImplCopyWithImpl<_$HostingAppResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostingAppResponseImplToJson(
      this,
    );
  }
}

abstract class _HostingAppResponse implements HostingAppResponse {
  const factory _HostingAppResponse(
      {required final bool ok,
      required final HostingAppInfo app}) = _$HostingAppResponseImpl;

  factory _HostingAppResponse.fromJson(Map<String, dynamic> json) =
      _$HostingAppResponseImpl.fromJson;

  @override
  bool get ok;
  @override
  HostingAppInfo get app;
  @override
  @JsonKey(ignore: true)
  _$$HostingAppResponseImplCopyWith<_$HostingAppResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HostingLogsResponse _$HostingLogsResponseFromJson(Map<String, dynamic> json) {
  return _HostingLogsResponse.fromJson(json);
}

/// @nodoc
mixin _$HostingLogsResponse {
  bool get ok => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String> get lines => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HostingLogsResponseCopyWith<HostingLogsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostingLogsResponseCopyWith<$Res> {
  factory $HostingLogsResponseCopyWith(
          HostingLogsResponse value, $Res Function(HostingLogsResponse) then) =
      _$HostingLogsResponseCopyWithImpl<$Res, HostingLogsResponse>;
  @useResult
  $Res call({bool ok, String name, List<String> lines});
}

/// @nodoc
class _$HostingLogsResponseCopyWithImpl<$Res, $Val extends HostingLogsResponse>
    implements $HostingLogsResponseCopyWith<$Res> {
  _$HostingLogsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? name = null,
    Object? lines = null,
  }) {
    return _then(_value.copyWith(
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as bool,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      lines: null == lines
          ? _value.lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HostingLogsResponseImplCopyWith<$Res>
    implements $HostingLogsResponseCopyWith<$Res> {
  factory _$$HostingLogsResponseImplCopyWith(_$HostingLogsResponseImpl value,
          $Res Function(_$HostingLogsResponseImpl) then) =
      __$$HostingLogsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool ok, String name, List<String> lines});
}

/// @nodoc
class __$$HostingLogsResponseImplCopyWithImpl<$Res>
    extends _$HostingLogsResponseCopyWithImpl<$Res, _$HostingLogsResponseImpl>
    implements _$$HostingLogsResponseImplCopyWith<$Res> {
  __$$HostingLogsResponseImplCopyWithImpl(_$HostingLogsResponseImpl _value,
      $Res Function(_$HostingLogsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? name = null,
    Object? lines = null,
  }) {
    return _then(_$HostingLogsResponseImpl(
      ok: null == ok
          ? _value.ok
          : ok // ignore: cast_nullable_to_non_nullable
              as bool,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      lines: null == lines
          ? _value._lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HostingLogsResponseImpl implements _HostingLogsResponse {
  const _$HostingLogsResponseImpl(
      {required this.ok, required this.name, required final List<String> lines})
      : _lines = lines;

  factory _$HostingLogsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostingLogsResponseImplFromJson(json);

  @override
  final bool ok;
  @override
  final String name;
  final List<String> _lines;
  @override
  List<String> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  String toString() {
    return 'HostingLogsResponse(ok: $ok, name: $name, lines: $lines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostingLogsResponseImpl &&
            (identical(other.ok, ok) || other.ok == ok) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._lines, _lines));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, ok, name, const DeepCollectionEquality().hash(_lines));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HostingLogsResponseImplCopyWith<_$HostingLogsResponseImpl> get copyWith =>
      __$$HostingLogsResponseImplCopyWithImpl<_$HostingLogsResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostingLogsResponseImplToJson(
      this,
    );
  }
}

abstract class _HostingLogsResponse implements HostingLogsResponse {
  const factory _HostingLogsResponse(
      {required final bool ok,
      required final String name,
      required final List<String> lines}) = _$HostingLogsResponseImpl;

  factory _HostingLogsResponse.fromJson(Map<String, dynamic> json) =
      _$HostingLogsResponseImpl.fromJson;

  @override
  bool get ok;
  @override
  String get name;
  @override
  List<String> get lines;
  @override
  @JsonKey(ignore: true)
  _$$HostingLogsResponseImplCopyWith<_$HostingLogsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
