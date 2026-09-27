// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SystemStateImpl _$$SystemStateImplFromJson(Map<String, dynamic> json) =>
    _$SystemStateImpl(
      status: json['status'] as String,
      maya: json['maya'] as String,
      version: json['version'] as String?,
      uptime: (json['uptime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SystemStateImplToJson(_$SystemStateImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'maya': instance.maya,
      'version': instance.version,
      'uptime': instance.uptime,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$systemServiceHash() => r'186381aa88f24d90fcae1d33cfca8168852c13c5';

/// See also [systemService].
@ProviderFor(systemService)
final systemServiceProvider = AutoDisposeProvider<SystemService>.internal(
  systemService,
  name: r'systemServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$systemServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SystemServiceRef = AutoDisposeProviderRef<SystemService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
