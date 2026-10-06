class MemoryItem {
  final String id;
  final String content;
  final Map<String, dynamic>? metadata;
  final String? createdAt;
  final double? score;

  MemoryItem({
    required this.id,
    required this.content,
    this.metadata,
    this.createdAt,
    this.score,
  });

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'metadata': metadata,
      'created_at': createdAt,
      'score': score,
    };
  }
}

class MemoryListResponse {
  final List<MemoryItem> items;
  final int total;
  final int? limit;
  final int? offset;

  MemoryListResponse({
    required this.items,
    required this.total,
    this.limit,
    this.offset,
  });

  factory MemoryListResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return MemoryListResponse(
      items: itemsList
          .map((e) => MemoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
    );
  }
}

class MemorySearchResponse {
  final List<MemoryItem> results;
  final String query;
  final int count;

  MemorySearchResponse({
    required this.results,
    required this.query,
    required this.count,
  });

  factory MemorySearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>? ?? [];
    return MemorySearchResponse(
      results: resultsList
          .map((e) => MemoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      query: json['query'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class MemoryStatsResponse {
  final int totalMemories;
  final int totalVectors;
  final String indexType;
  final double indexSizeMb;

  MemoryStatsResponse({
    required this.totalMemories,
    required this.totalVectors,
    required this.indexType,
    required this.indexSizeMb,
  });

  factory MemoryStatsResponse.fromJson(Map<String, dynamic> json) {
    return MemoryStatsResponse(
      totalMemories: json['total_memories'] as int? ?? 0,
      totalVectors: json['total_vectors'] as int? ?? 0,
      indexType: json['index_type'] as String? ?? '',
      indexSizeMb: (json['index_size_mb'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RAGDocument {
  final String id;
  final String title;
  final String docType;
  final int chunkCount;
  final String createdAt;
  final double sizeKb;

  RAGDocument({
    required this.id,
    required this.title,
    required this.docType,
    required this.chunkCount,
    required this.createdAt,
    required this.sizeKb,
  });

  factory RAGDocument.fromJson(Map<String, dynamic> json) {
    return RAGDocument(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      docType: json['doc_type'] as String? ?? '',
      chunkCount: json['chunk_count'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      sizeKb: (json['size_kb'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RAGDocumentsResponse {
  final List<RAGDocument> documents;

  RAGDocumentsResponse({required this.documents});

  factory RAGDocumentsResponse.fromJson(Map<String, dynamic> json) {
    final docsList = json['documents'] as List<dynamic>? ?? [];
    return RAGDocumentsResponse(
      documents: docsList
          .map((e) => RAGDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RAGStatsResponse {
  final int totalDocuments;
  final int totalChunks;
  final String indexType;
  final double indexSizeMb;
  final Map<String, dynamic> searchEngines;

  RAGStatsResponse({
    required this.totalDocuments,
    required this.totalChunks,
    required this.indexType,
    required this.indexSizeMb,
    required this.searchEngines,
  });

  factory RAGStatsResponse.fromJson(Map<String, dynamic> json) {
    return RAGStatsResponse(
      totalDocuments: json['total_documents'] as int? ?? 0,
      totalChunks: json['total_chunks'] as int? ?? 0,
      indexType: json['index_type'] as String? ?? '',
      indexSizeMb: (json['index_size_mb'] as num?)?.toDouble() ?? 0.0,
      searchEngines: json['search_engines'] as Map<String, dynamic>? ?? {},
    );
  }
}

class RAGSearchResult {
  final String docId;
  final String title;
  final String content;
  final double score;
  final String docType;

  RAGSearchResult({
    required this.docId,
    required this.title,
    required this.content,
    required this.score,
    required this.docType,
  });

  factory RAGSearchResult.fromJson(Map<String, dynamic> json) {
    return RAGSearchResult(
      docId: json['doc_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      docType: json['doc_type'] as String? ?? '',
    );
  }
}

class RAGSearchResponse {
  final String query;
  final String mode;
  final List<RAGSearchResult> results;

  RAGSearchResponse({
    required this.query,
    required this.mode,
    required this.results,
  });

  factory RAGSearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>? ?? [];
    return RAGSearchResponse(
      query: json['query'] as String? ?? '',
      mode: json['mode'] as String? ?? 'hybrid',
      results: resultsList
          .map((e) => RAGSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RAGContextResponse {
  final String context;
  final List<RAGSearchResult> citations;

  RAGContextResponse({
    required this.context,
    required this.citations,
  });

  factory RAGContextResponse.fromJson(Map<String, dynamic> json) {
    final citationsList = json['citations'] as List<dynamic>? ?? [];
    return RAGContextResponse(
      context: json['context'] as String? ?? '',
      citations: citationsList
          .map((e) => RAGSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RAGIngestResponse {
  final String docId;
  final int chunksCreated;
  final String title;

  RAGIngestResponse({
    required this.docId,
    required this.chunksCreated,
    required this.title,
  });

  factory RAGIngestResponse.fromJson(Map<String, dynamic> json) {
    return RAGIngestResponse(
      docId: json['doc_id'] as String? ?? '',
      chunksCreated: json['chunks_created'] as int? ?? 0,
      title: json['title'] as String? ?? '',
    );
  }
}

class MemoryCreateResponse {
  final String id;
  final String content;
  final Map<String, dynamic>? metadata;
  final String? createdAt;

  MemoryCreateResponse({
    required this.id,
    required this.content,
    this.metadata,
    this.createdAt,
  });

  factory MemoryCreateResponse.fromJson(Map<String, dynamic> json) {
    return MemoryCreateResponse(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
    );
  }
}
