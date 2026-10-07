class AutoResumeResult {
  final String goalId;
  final String priorStatus;
  final bool success;
  final bool autoExecuted;
  final String? description;
  final String? action;
  final String? error;

  AutoResumeResult({
    required this.goalId,
    required this.priorStatus,
    required this.success,
    required this.autoExecuted,
    this.description,
    this.action,
    this.error,
  });

  factory AutoResumeResult.fromJson(Map<String, dynamic> json) {
    return AutoResumeResult(
      goalId: json['goal_id'] as String? ?? '',
      priorStatus: json['prior_status'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      autoExecuted: json['auto_executed'] as bool? ?? false,
      description: json['description'] as String?,
      action: json['action'] as String?,
      error: json['error'] as String?,
    );
  }
}

class AutoResumeResponse {
  final List<AutoResumeResult> results;

  AutoResumeResponse({required this.results});

  factory AutoResumeResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return AutoResumeResponse(
      results: list
          .map((e) => AutoResumeResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Reuse Goal model from persistent_goals
class Goal {
  final String id;
  final String description;
  final String status;
  final int priority;
  final String createdAt;
  final String? updatedAt;

  Goal({
    required this.id,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class GoalsListResponse {
  final List<Goal> goals;

  GoalsListResponse({required this.goals});

  factory GoalsListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['goals'] as List<dynamic>? ?? [];
    return GoalsListResponse(
      goals: list.map((e) => Goal.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
