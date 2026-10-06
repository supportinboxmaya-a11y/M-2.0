class KnowledgeItem {
  final String id;
  final String proposition;
  final double confidence;
  final String source;
  final String domain;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> evidence;

  KnowledgeItem({
    required this.id,
    required this.proposition,
    required this.confidence,
    required this.source,
    required this.domain,
    required this.createdAt,
    this.updatedAt,
    required this.evidence,
  });

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) {
    return KnowledgeItem(
      id: json['id'] as String? ?? '',
      proposition: json['proposition'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class KnowledgeQueryResponse {
  final List<KnowledgeItem> results;

  KnowledgeQueryResponse({required this.results});

  factory KnowledgeQueryResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>? ?? [];
    return KnowledgeQueryResponse(
      results: resultsList
          .map((e) => KnowledgeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KnowledgeStatsResponse {
  final int totalBeliefs;
  final int domains;
  final double avgConfidence;
  final int retrievalEngine;

  KnowledgeStatsResponse({
    required this.totalBeliefs,
    required this.domains,
    required this.avgConfidence,
    required this.retrievalEngine,
  });

  factory KnowledgeStatsResponse.fromJson(Map<String, dynamic> json) {
    return KnowledgeStatsResponse(
      totalBeliefs: json['total_beliefs'] as int? ?? 0,
      domains: json['domains'] as int? ?? 0,
      avgConfidence: (json['avg_confidence'] as num?)?.toDouble() ?? 0.0,
      retrievalEngine: json['retrieval_engine'] as int? ?? 0,
    );
  }
}

class KnowledgeLearnResponse {
  final String beliefId;
  final double confidence;
  final String action;

  KnowledgeLearnResponse({
    required this.beliefId,
    required this.confidence,
    required this.action,
  });

  factory KnowledgeLearnResponse.fromJson(Map<String, dynamic> json) {
    return KnowledgeLearnResponse(
      beliefId: json['belief_id'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      action: json['action'] as String? ?? '',
    );
  }
}

class Belief {
  final String id;
  final String proposition;
  final double confidence;
  final String domain;
  final String source;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? evidence;

  Belief({
    required this.id,
    required this.proposition,
    required this.confidence,
    required this.domain,
    required this.source,
    required this.createdAt,
    this.updatedAt,
    this.evidence,
  });

  factory Belief.fromJson(Map<String, dynamic> json) {
    return Belief(
      id: json['id'] as String? ?? '',
      proposition: json['proposition'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      domain: json['domain'] as String? ?? '',
      source: json['source'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      evidence: (json['evidence'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

class BeliefsQueryResponse {
  final List<Belief> beliefs;

  BeliefsQueryResponse({required this.beliefs});

  factory BeliefsQueryResponse.fromJson(Map<String, dynamic> json) {
    final beliefsList = json['beliefs'] as List<dynamic>? ?? [];
    return BeliefsQueryResponse(
      beliefs: beliefsList
          .map((e) => Belief.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
