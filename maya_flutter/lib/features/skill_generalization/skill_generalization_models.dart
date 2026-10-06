class ProceduralSkill {
  final String id;
  final String name;
  final String description;
  final bool verified;
  final double confidence;
  final int usageCount;
  final double successRate;
  final List<String> applicableGoals;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProceduralSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.verified,
    required this.confidence,
    required this.usageCount,
    required this.successRate,
    required this.applicableGoals,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProceduralSkill.fromJson(Map<String, dynamic> json) {
    return ProceduralSkill(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      usageCount: json['usage_count'] as int? ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      applicableGoals: (json['applicable_goals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}

class ProceduralListResponse {
  final List<ProceduralSkill> skills;
  final int total;

  ProceduralListResponse({required this.skills, required this.total});

  factory ProceduralListResponse.fromJson(Map<String, dynamic> json) {
    final skillsList = json['skills'] as List<dynamic>? ?? [];
    return ProceduralListResponse(
      skills: skillsList
          .map((e) => ProceduralSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}

class ProceduralSearchResponse {
  final List<ProceduralSkill> skills;
  final String query;

  ProceduralSearchResponse({required this.skills, required this.query});

  factory ProceduralSearchResponse.fromJson(Map<String, dynamic> json) {
    final skillsList = json['skills'] as List<dynamic>? ?? [];
    return ProceduralSearchResponse(
      skills: skillsList
          .map((e) => ProceduralSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
      query: json['query'] as String? ?? '',
    );
  }
}

class ProceduralComposeResponse {
  final String skillId;
  final String name;
  final String description;
  final bool verified;

  ProceduralComposeResponse({
    required this.skillId,
    required this.name,
    required this.description,
    required this.verified,
  });

  factory ProceduralComposeResponse.fromJson(Map<String, dynamic> json) {
    return ProceduralComposeResponse(
      skillId: json['skill_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
    );
  }
}

class ProceduralStatsResponse {
  final int totalSkills;
  final int verifiedSkills;
  final double avgConfidence;
  final double avgSuccessRate;
  final int totalUsages;

  ProceduralStatsResponse({
    required this.totalSkills,
    required this.verifiedSkills,
    required this.avgConfidence,
    required this.avgSuccessRate,
    required this.totalUsages,
  });

  factory ProceduralStatsResponse.fromJson(Map<String, dynamic> json) {
    return ProceduralStatsResponse(
      totalSkills: json['total_skills'] as int? ?? 0,
      verifiedSkills: json['verified_skills'] as int? ?? 0,
      avgConfidence: (json['avg_confidence'] as num?)?.toDouble() ?? 0.0,
      avgSuccessRate: (json['avg_success_rate'] as num?)?.toDouble() ?? 0.0,
      totalUsages: json['total_usages'] as int? ?? 0,
    );
  }
}
