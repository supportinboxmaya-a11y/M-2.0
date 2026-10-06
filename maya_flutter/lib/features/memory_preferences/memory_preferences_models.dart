class ExtMemPrefsListResponse {
  final Map<String, String> preferences;

  ExtMemPrefsListResponse({required this.preferences});

  factory ExtMemPrefsListResponse.fromJson(Map<String, dynamic> json) {
    final prefs = json['preferences'] as Map<String, dynamic>? ?? {};
    return ExtMemPrefsListResponse(
      preferences: prefs.map((k, v) => MapEntry(k, v as String)),
    );
  }
}

class ExtMemFactsListResponse {
  final List<ExtMemFact> facts;

  ExtMemFactsListResponse({required this.facts});

  factory ExtMemFactsListResponse.fromJson(Map<String, dynamic> json) {
    final factsList = json['facts'] as List<dynamic>? ?? [];
    return ExtMemFactsListResponse(
      facts: factsList
          .map((e) => ExtMemFact.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExtMemFact {
  final String id;
  final String fact;
  final String source;
  final DateTime createdAt;

  ExtMemFact({
    required this.id,
    required this.fact,
    required this.source,
    required this.createdAt,
  });

  factory ExtMemFact.fromJson(Map<String, dynamic> json) {
    return ExtMemFact(
      id: json['id'] as String? ?? '',
      fact: json['fact'] as String? ?? '',
      source: json['source'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ExtMemFactsResponse {
  final String factId;
  final bool success;

  ExtMemFactsResponse({required this.factId, required this.success});

  factory ExtMemFactsResponse.fromJson(Map<String, dynamic> json) {
    return ExtMemFactsResponse(
      factId: json['fact_id'] as String? ?? '',
      success: json['success'] as bool? ?? false,
    );
  }
}

class ExtMemProjectsResponse {
  final String projectId;
  final bool success;

  ExtMemProjectsResponse({required this.projectId, required this.success});

  factory ExtMemProjectsResponse.fromJson(Map<String, dynamic> json) {
    return ExtMemProjectsResponse(
      projectId: json['project_id'] as String? ?? '',
      success: json['success'] as bool? ?? false,
    );
  }
}

class ExtMemContextResponse {
  final String context;
  final List<ExtMemFact> citations;

  ExtMemContextResponse({required this.context, required this.citations});

  factory ExtMemContextResponse.fromJson(Map<String, dynamic> json) {
    final citationsList = json['citations'] as List<dynamic>? ?? [];
    return ExtMemContextResponse(
      context: json['context'] as String? ?? '',
      citations: citationsList
          .map((e) => ExtMemFact.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
