class SelfImproveStatus {
  final String status;
  final int iterations;
  final int proposals;
  final int accepted;
  final int rejected;
  final String? currentProposal;

  SelfImproveStatus({
    required this.status,
    required this.iterations,
    required this.proposals,
    required this.accepted,
    required this.rejected,
    this.currentProposal,
  });

  factory SelfImproveStatus.fromJson(Map<String, dynamic> json) {
    return SelfImproveStatus(
      status: json['status'] as String? ?? '',
      iterations: json['iterations'] as int? ?? 0,
      proposals: json['proposals'] as int? ?? 0,
      accepted: json['accepted'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
      currentProposal: json['current_proposal'] as String?,
    );
  }
}

class SelfImproveProposal {
  final String id;
  final String description;
  final String status;
  final double confidence;
  final String createdAt;

  SelfImproveProposal({
    required this.id,
    required this.description,
    required this.status,
    required this.confidence,
    required this.createdAt,
  });

  factory SelfImproveProposal.fromJson(Map<String, dynamic> json) {
    return SelfImproveProposal(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class SelfImproveProposalsResponse {
  final List<SelfImproveProposal> proposals;

  SelfImproveProposalsResponse({required this.proposals});

  factory SelfImproveProposalsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['proposals'] as List<dynamic>? ?? [];
    return SelfImproveProposalsResponse(
      proposals: list.map((e) => SelfImproveProposal.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SelfImproveGapsResponse {
  final List<String> gaps;

  SelfImproveGapsResponse({required this.gaps});

  factory SelfImproveGapsResponse.fromJson(Map<String, dynamic> json) {
    return SelfImproveGapsResponse(
      gaps: (json['gaps'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    );
  }
}

class SelfImproveConfigResponse {
  final bool enabled;
  final int intervalMinutes;
  final double threshold;

  SelfImproveConfigResponse({
    required this.enabled,
    required this.intervalMinutes,
    required this.threshold,
  });

  factory SelfImproveConfigResponse.fromJson(Map<String, dynamic> json) {
    return SelfImproveConfigResponse(
      enabled: json['enabled'] as bool? ?? false,
      intervalMinutes: json['interval_minutes'] as int? ?? 60,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.7,
    );
  }
}