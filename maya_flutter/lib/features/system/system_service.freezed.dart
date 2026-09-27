// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SystemState _$SystemStateFromJson(Map<String, dynamic> json) {
  return _SystemState.fromJson(json);
}

/// @nodoc
mixin _$SystemState {
  String get status => throw _privateConstructorUsedError;
  String get maya => throw _privateConstructorUsedError;
  String? get version => throw _privateConstructorUsedError;
  int? get uptime => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SystemStateCopyWith<SystemState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SystemStateCopyWith<$Res> {
  factory $SystemStateCopyWith(
          SystemState value, $Res Function(SystemState) then) =
      _$SystemStateCopyWithImpl<$Res, SystemState>;
  @useResult
  $Res call({String status, String maya, String? version, int? uptime});
}

/// @nodoc
class _$SystemStateCopyWithImpl<$Res, $Val extends SystemState>
    implements $SystemStateCopyWith<$Res> {
  _$SystemStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? maya = null,
    Object? version = freezed,
    Object? uptime = freezed,
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
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      uptime: freezed == uptime
          ? _value.uptime
          : uptime // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SystemStateImplCopyWith<$Res>
    implements $SystemStateCopyWith<$Res> {
  factory _$$SystemStateImplCopyWith(
          _$SystemStateImpl value, $Res Function(_$SystemStateImpl) then) =
      __$$SystemStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String status, String maya, String? version, int? uptime});
}

/// @nodoc
class __$$SystemStateImplCopyWithImpl<$Res>
    extends _$SystemStateCopyWithImpl<$Res, _$SystemStateImpl>
    implements _$$SystemStateImplCopyWith<$Res> {
  __$$SystemStateImplCopyWithImpl(
      _$SystemStateImpl _value, $Res Function(_$SystemStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? maya = null,
    Object? version = freezed,
    Object? uptime = freezed,
  }) {
    return _then(_$SystemStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      maya: null == maya
          ? _value.maya
          : maya // ignore: cast_nullable_to_non_nullable
              as String,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      uptime: freezed == uptime
          ? _value.uptime
          : uptime // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SystemStateImpl with DiagnosticableTreeMixin implements _SystemState {
  const _$SystemStateImpl(
      {required this.status, required this.maya, this.version, this.uptime});

  factory _$SystemStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$SystemStateImplFromJson(json);

  @override
  final String status;
  @override
  final String maya;
  @override
  final String? version;
  @override
  final int? uptime;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SystemState(status: $status, maya: $maya, version: $version, uptime: $uptime)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SystemState'))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('maya', maya))
      ..add(DiagnosticsProperty('version', version))
      ..add(DiagnosticsProperty('uptime', uptime));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SystemStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.maya, maya) || other.maya == maya) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.uptime, uptime) || other.uptime == uptime));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, status, maya, version, uptime);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SystemStateImplCopyWith<_$SystemStateImpl> get copyWith =>
      __$$SystemStateImplCopyWithImpl<_$SystemStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SystemStateImplToJson(
      this,
    );
  }
}

abstract class _SystemState implements SystemState {
  const factory _SystemState(
      {required final String status,
      required final String maya,
      final String? version,
      final int? uptime}) = _$SystemStateImpl;

  factory _SystemState.fromJson(Map<String, dynamic> json) =
      _$SystemStateImpl.fromJson;

  @override
  String get status;
  @override
  String get maya;
  @override
  String? get version;
  @override
  int? get uptime;
  @override
  @JsonKey(ignore: true)
  _$$SystemStateImplCopyWith<_$SystemStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
