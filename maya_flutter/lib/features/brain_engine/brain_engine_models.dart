class BrainAnalyzeResponse {
  final String complexity;
  final int estimatedSteps;
  final List<String> subGoals;
  final List<String> suggestedTools;

  BrainAnalyzeResponse({
    required this.complexity,
    required this.estimatedSteps,
    required this.subGoals,
    required this.suggestedTools,
  });

  factory BrainAnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return BrainAnalyzeResponse(
      complexity: json['complexity'] as String? ?? '',
      estimatedSteps: json['estimated_steps'] as int? ?? 0,
      subGoals: (json['sub_goals'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      suggestedTools: (json['suggested_tools'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class BrainRunGraphResponse {
  final String runId;
  final String status;
  final String? result;

  BrainRunGraphResponse(
      {required this.runId, required this.status, this.result});

  factory BrainRunGraphResponse.fromJson(Map<String, dynamic> json) {
    return BrainRunGraphResponse(
      runId: json['run_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      result: json['result'] as String?,
    );
  }
}

class BrainGraphResponse {
  final String graphId;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  BrainGraphResponse(
      {required this.graphId, required this.nodes, required this.edges});

  factory BrainGraphResponse.fromJson(Map<String, dynamic> json) {
    final nodesList = json['nodes'] as List<dynamic>? ?? [];
    final edgesList = json['edges'] as List<dynamic>? ?? [];
    return BrainGraphResponse(
      graphId: json['graph_id'] as String? ?? '',
      nodes: nodesList
          .map((e) => GraphNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      edges: edgesList
          .map((e) => GraphEdge.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GraphNode {
  final String id;
  final String label;
  final String type;
  final String status;
  final Map<String, dynamic>? metadata;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    required this.status,
    this.metadata,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class GraphEdge {
  final String from;
  final String to;
  final String type;
  final double weight;

  GraphEdge(
      {required this.from,
      required this.to,
      required this.type,
      required this.weight});

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      type: json['type'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BrainRunResponse {
  final String runId;
  final String status;
  final String? result;

  BrainRunResponse({required this.runId, required this.status, this.result});

  factory BrainRunResponse.fromJson(Map<String, dynamic> json) {
    return BrainRunResponse(
      runId: json['run_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      result: json['result'] as String?,
    );
  }
}
