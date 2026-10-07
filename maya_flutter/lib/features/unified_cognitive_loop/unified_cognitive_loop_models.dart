class UnifiedLoopStatus {
  final String state;
  final int activeGoals;
  final int pendingTasks;
  final int totalCycles;
  final String currentPhase;
  final String? currentGoal;

  UnifiedLoopStatus({
    required this.state,
    required this.activeGoals,
    required this.pendingTasks,
    required this.totalCycles,
    required this.currentPhase,
    this.currentGoal,
  });

  factory UnifiedLoopStatus.fromJson(Map<String, dynamic> json) {
    return UnifiedLoopStatus(
      state: json['state'] as String? ?? '',
      activeGoals: json['active_goals'] as int? ?? 0,
      pendingTasks: json['pending_tasks'] as int? ?? 0,
      totalCycles: json['total_cycles'] as int? ?? 0,
      currentPhase: json['current_phase'] as String? ?? '',
      currentGoal: json['current_goal'] as String?,
    );
  }
}

class UnifiedLoopHistoryEntry {
  final int id;
  final String goalId;
  final String phase;
  final String status;
  final String timestamp;
  final String? result;

  UnifiedLoopHistoryEntry({
    required this.id,
    required this.goalId,
    required this.phase,
    required this.status,
    required this.timestamp,
    this.result,
  });

  factory UnifiedLoopHistoryEntry.fromJson(Map<String, dynamic> json) {
    return UnifiedLoopHistoryEntry(
      id: json['id'] as int? ?? 0,
      goalId: json['goal_id'] as String? ?? '',
      phase: json['phase'] as String? ?? '',
      status: json['status'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      result: json['result'] as String?,
    );
  }
}

class UnifiedLoopHistoryResponse {
  final List<UnifiedLoopHistoryEntry> history;

  UnifiedLoopHistoryResponse({required this.history});

  factory UnifiedLoopHistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['history'] as List<dynamic>? ?? [];
    return UnifiedLoopHistoryResponse(
      history: list.map((e) => UnifiedLoopHistoryEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class UnifiedLoopControlsResponse {
  final bool success;
  final String? message;

  UnifiedLoopControlsResponse({required this.success, this.message});

  factory UnifiedLoopControlsResponse.fromJson(Map<String, dynamic> json) {
    return UnifiedLoopControlsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}