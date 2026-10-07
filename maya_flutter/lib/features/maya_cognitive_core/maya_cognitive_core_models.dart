class Episode {
  final String id;
  final String goal;
  final String outcome;
  final double confidence;
  final String timestamp;
  final Map<String, dynamic>? metadata;

  Episode({
    required this.id,
    required this.goal,
    required this.outcome,
    required this.confidence,
    required this.timestamp,
    this.metadata,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      outcome: json['outcome'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class EpisodicListResponse {
  final List<Episode> episodes;

  EpisodicListResponse({required this.episodes});

  factory EpisodicListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['episodes'] as List<dynamic>? ?? [];
    return EpisodicListResponse(
      episodes: list.map((e) => Episode.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class EpisodicStatsResponse {
  final int totalEpisodes;
  final int successfulEpisodes;
  final int failedEpisodes;
  final double avgConfidence;

  EpisodicStatsResponse({
    required this.totalEpisodes,
    required this.successfulEpisodes,
    required this.failedEpisodes,
    required this.avgConfidence,
  });

  factory EpisodicStatsResponse.fromJson(Map<String, dynamic> json) {
    return EpisodicStatsResponse(
      totalEpisodes: json['total_episodes'] as int? ?? 0,
      successfulEpisodes: json['successful_episodes'] as int? ?? 0,
      failedEpisodes: json['failed_episodes'] as int? ?? 0,
      avgConfidence: (json['avg_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class KnowledgeItem {
  final String id;
  final String proposition;
  final double confidence;
  final String source;
  final String domain;
  final String createdAt;
  final String? updatedAt;
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
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      evidence: (json['evidence'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

class KnowledgeQueryResponse {
  final List<KnowledgeItem> results;

  KnowledgeQueryResponse({required this.results});

  factory KnowledgeQueryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return KnowledgeQueryResponse(
      results: list.map((e) => KnowledgeItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class KnowledgeLearnResponse {
  final String beliefId;
  final double confidence;
  final String action;

  KnowledgeLearnResponse({required this.beliefId, required this.confidence, required this.action});

  factory KnowledgeLearnResponse.fromJson(Map<String, dynamic> json) {
    return KnowledgeLearnResponse(
      beliefId: json['belief_id'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      action: json['action'] as String? ?? '',
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

class Belief {
  final String id;
  final String proposition;
  final double confidence;
  final String domain;
  final String source;
  final String createdAt;
  final String? updatedAt;
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
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      evidence: (json['evidence'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
}

class BeliefsQueryResponse {
  final List<Belief> beliefs;

  BeliefsQueryResponse({required this.beliefs});

  factory BeliefsQueryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['beliefs'] as List<dynamic>? ?? [];
    return BeliefsQueryResponse(
      beliefs: list.map((e) => Belief.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class WorkingMemoryStatsResponse {
  final int capacity;
  final int used;
  final int pending;
  final int processing;

  WorkingMemoryStatsResponse({
    required this.capacity,
    required this.used,
    required this.pending,
    required this.processing,
  });

  factory WorkingMemoryStatsResponse.fromJson(Map<String, dynamic> json) {
    return WorkingMemoryStatsResponse(
      capacity: json['capacity'] as int? ?? 0,
      used: json['used'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      processing: json['processing'] as int? ?? 0,
    );
  }
}

class BrowserActionResponse {
  final bool success;
  final String? result;
  final String? error;
  final int? exitCode;
  final int? executionTimeMs;

  BrowserActionResponse({required this.success, this.result, this.error, this.exitCode, this.executionTimeMs});

  factory BrowserActionResponse.fromJson(Map<String, dynamic> json) {
    return BrowserActionResponse(
      success: json['success'] as bool? ?? false,
      result: json['result'] as String?,
      error: json['error'] as String?,
      exitCode: json['exit_code'] as int?,
      executionTimeMs: json['execution_time_ms'] as int?,
    );
  }
}

class SandboxExecuteResponse {
  final bool success;
  final String? output;
  final String? error;
  final int? exitCode;
  final int? executionTimeMs;

  SandboxExecuteResponse({required this.success, this.output, this.error, this.exitCode, this.executionTimeMs});

  factory SandboxExecuteResponse.fromJson(Map<String, dynamic> json) {
    return SandboxExecuteResponse(
      success: json['success'] as bool? ?? false,
      output: json['output'] as String?,
      error: json['error'] as String?,
      exitCode: json['exit_code'] as int?,
      executionTimeMs: json['execution_time_ms'] as int?,
    );
  }
}