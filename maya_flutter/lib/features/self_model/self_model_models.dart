class SelfModelStats {
  final int totalModels;
  final int activeModels;
  final int deprecatedModels;
  final double avgAccuracy;

  SelfModelStats({
    required this.totalModels,
    required this.activeModels,
    required this.deprecatedModels,
    required this.avgAccuracy,
  });

  factory SelfModelStats.fromJson(Map<String, dynamic> json) {
    return SelfModelStats(
      totalModels: json['total_models'] as int? ?? 0,
      activeModels: json['active_models'] as int? ?? 0,
      deprecatedModels: json['deprecated_models'] as int? ?? 0,
      avgAccuracy: (json['avg_accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SelfModel {
  final String id;
  final String name;
  final String type;
  final String status;
  final double accuracy;
  final String version;
  final String createdAt;
  final String? updatedAt;

  SelfModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.accuracy,
    required this.version,
    required this.createdAt,
    this.updatedAt,
  });

  factory SelfModel.fromJson(Map<String, dynamic> json) {
    return SelfModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      version: json['version'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class SelfModelListResponse {
  final List<SelfModel> models;

  SelfModelListResponse({required this.models});

  factory SelfModelListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['models'] as List<dynamic>? ?? [];
    return SelfModelListResponse(
      models: list.map((e) => SelfModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SelfModelDetailResponse {
  final String id;
  final String name;
  final String type;
  final String status;
  final double accuracy;
  final String version;
  final String createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? config;
  final List<String>? tags;

  SelfModelDetailResponse({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.accuracy,
    required this.version,
    required this.createdAt,
    this.updatedAt,
    this.config,
    this.tags,
  });

  factory SelfModelDetailResponse.fromJson(Map<String, dynamic> json) {
    return SelfModelDetailResponse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      version: json['version'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      config: json['config'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
}