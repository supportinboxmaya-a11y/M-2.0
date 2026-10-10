class Capability {
  final String id;
  final String name;
  final String description;
  final bool verified;
  final int usageCount;
  final double successRate;

  Capability({
    required this.id,
    required this.name,
    required this.description,
    required this.verified,
    required this.usageCount,
    required this.successRate,
  });

  factory Capability.fromJson(Map<String, dynamic> json) {
    return Capability(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      usageCount: json['usage_count'] as int? ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CapabilitiesListResponse {
  final List<Capability> capabilities;

  CapabilitiesListResponse({required this.capabilities});

  factory CapabilitiesListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['capabilities'] as List<dynamic>? ?? [];
    return CapabilitiesListResponse(
        capabilities: list
            .map((e) => Capability.fromJson(e as Map<String, dynamic>))
            .toList());
  }
}

class CapabilitiesSearchResponse {
  final List<Capability> capabilities;

  CapabilitiesSearchResponse({required this.capabilities});

  factory CapabilitiesSearchResponse.fromJson(Map<String, dynamic> json) {
    final list = json['capabilities'] as List<dynamic>? ?? [];
    return CapabilitiesSearchResponse(
        capabilities: list
            .map((e) => Capability.fromJson(e as Map<String, dynamic>))
            .toList());
  }
}

class CapabilitiesStatsResponse {
  final int totalCapabilities;
  final int verifiedCapabilities;
  final int totalUsages;

  CapabilitiesStatsResponse({
    required this.totalCapabilities,
    required this.verifiedCapabilities,
    required this.totalUsages,
  });

  factory CapabilitiesStatsResponse.fromJson(Map<String, dynamic> json) {
    return CapabilitiesStatsResponse(
      totalCapabilities: json['total_capabilities'] as int? ?? 0,
      verifiedCapabilities: json['verified_capabilities'] as int? ?? 0,
      totalUsages: json['total_usages'] as int? ?? 0,
    );
  }
}

class CapabilityDetailResponse {
  final String id;
  final String name;
  final String description;
  final bool verified;
  final int usageCount;
  final double successRate;
  final Map<String, dynamic>? metadata;

  CapabilityDetailResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.verified,
    required this.usageCount,
    required this.successRate,
    this.metadata,
  });

  factory CapabilityDetailResponse.fromJson(Map<String, dynamic> json) {
    return CapabilityDetailResponse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      usageCount: json['usage_count'] as int? ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
