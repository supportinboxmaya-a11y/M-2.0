class VectorSearchResult {
  final String id;
  final String content;
  final double score;
  final Map<String, dynamic>? metadata;

  VectorSearchResult({
    required this.id,
    required this.content,
    required this.score,
    this.metadata,
  });

  factory VectorSearchResult.fromJson(Map<String, dynamic> json) {
    return VectorSearchResult(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class VectorSearchResponse {
  final List<VectorSearchResult> results;

  VectorSearchResponse({required this.results});

  factory VectorSearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>? ?? [];
    return VectorSearchResponse(
      results: resultsList
          .map((e) => VectorSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VectorSearchStatsResponse {
  final int totalVectors;
  final String retrievalEngine;
  final int dimensions;

  VectorSearchStatsResponse({
    required this.totalVectors,
    required this.retrievalEngine,
    required this.dimensions,
  });

  factory VectorSearchStatsResponse.fromJson(Map<String, dynamic> json) {
    return VectorSearchStatsResponse(
      totalVectors: json['total_vectors'] as int? ?? 0,
      retrievalEngine: json['retrieval_engine'] as String? ?? '',
      dimensions: json['dimensions'] as int? ?? 0,
    );
  }
}
