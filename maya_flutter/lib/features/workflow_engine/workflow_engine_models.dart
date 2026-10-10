class WorkflowsRunsResponse {
  final List<String> checkpoints;

  WorkflowsRunsResponse({required this.checkpoints});

  factory WorkflowsRunsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['checkpoints'] as List<dynamic>? ?? [];
    return WorkflowsRunsResponse(
        checkpoints: list.map((e) => e as String).toList());
  }
}

class WorkflowRunState {
  final String id;
  final String goal;
  final String status;
  final int created;
  final List<WorkflowNode> nodes;
  final List<RecoveryLogEntry>? recoveryLog;

  WorkflowRunState({
    required this.id,
    required this.goal,
    required this.status,
    required this.created,
    required this.nodes,
    this.recoveryLog,
  });

  factory WorkflowRunState.fromJson(Map<String, dynamic> json) {
    return WorkflowRunState(
      id: json['id'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      status: json['status'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      nodes: (json['nodes'] as List<dynamic>? ?? [])
          .map((e) => WorkflowNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      recoveryLog: (json['recovery_log'] as List<dynamic>?)
          ?.map((e) => RecoveryLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkflowNode {
  final String id;
  final String name;
  final String status;
  final String? agent;
  final int? step;
  final Map<String, dynamic>? input;
  final Map<String, dynamic>? output;
  final String? error;
  final int? startedAt;
  final int? completedAt;

  WorkflowNode({
    required this.id,
    required this.name,
    required this.status,
    this.agent,
    this.step,
    this.input,
    this.output,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  factory WorkflowNode.fromJson(Map<String, dynamic> json) {
    return WorkflowNode(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      agent: json['agent'] as String?,
      step: json['step'] as int?,
      input: json['input'] as Map<String, dynamic>?,
      output: json['output'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      startedAt: json['started_at'] as int?,
      completedAt: json['completed_at'] as int?,
    );
  }
}

class RecoveryLogEntry {
  final int timestamp;
  final String event;
  final String details;

  RecoveryLogEntry({
    required this.timestamp,
    required this.event,
    required this.details,
  });

  factory RecoveryLogEntry.fromJson(Map<String, dynamic> json) {
    return RecoveryLogEntry(
      timestamp: json['timestamp'] as int? ?? 0,
      event: json['event'] as String? ?? '',
      details: json['details'] as String? ?? '',
    );
  }
}

class WorkflowPlanResponse {
  final String goal;
  final String plan;
  final List<WorkflowStep> steps;

  WorkflowPlanResponse({
    required this.goal,
    required this.plan,
    required this.steps,
  });

  factory WorkflowPlanResponse.fromJson(Map<String, dynamic> json) {
    return WorkflowPlanResponse(
      goal: json['goal'] as String? ?? '',
      plan: json['plan'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((e) => WorkflowStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkflowStep {
  final String name;
  final String agent;
  final String description;
  final List<String> dependsOn;

  WorkflowStep({
    required this.name,
    required this.agent,
    required this.description,
    required this.dependsOn,
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      name: json['name'] as String? ?? '',
      agent: json['agent'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dependsOn: (json['depends_on'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class WorkflowExecuteResponse {
  final String status;
  final String? error;

  WorkflowExecuteResponse({required this.status, this.error});

  factory WorkflowExecuteResponse.fromJson(Map<String, dynamic> json) {
    return WorkflowExecuteResponse(
      status: json['status'] as String? ?? '',
      error: json['error'] as String?,
    );
  }
}
