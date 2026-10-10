class AutonomousStatusResponse {
  final bool isRunning;
  final String? currentGoal;
  final String? currentStatus;
  final String? startedAt;

  AutonomousStatusResponse({
    required this.isRunning,
    this.currentGoal,
    this.currentStatus,
    this.startedAt,
  });

  factory AutonomousStatusResponse.fromJson(Map<String, dynamic> json) {
    return AutonomousStatusResponse(
      isRunning: json['is_running'] as bool? ?? false,
      currentGoal: json['current_goal'] as String?,
      currentStatus: json['current_status'] as String?,
      startedAt: json['started_at'] as String?,
    );
  }
}

class AutonomousRunResponse {
  final String status;
  final String? goalId;
  final String? error;

  AutonomousRunResponse({
    required this.status,
    this.goalId,
    this.error,
  });

  factory AutonomousRunResponse.fromJson(Map<String, dynamic> json) {
    return AutonomousRunResponse(
      status: json['status'] as String? ?? '',
      goalId: json['goal_id'] as String?,
      error: json['error'] as String?,
    );
  }
}
