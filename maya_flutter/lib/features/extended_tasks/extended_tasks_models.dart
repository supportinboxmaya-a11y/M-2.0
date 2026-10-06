class ExtendedTask {
  final String id;
  final String description;
  final String status;
  final String createdAt;

  ExtendedTask({
    required this.id,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory ExtendedTask.fromJson(Map<String, dynamic> json) {
    return ExtendedTask(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ExtendedTasksResponse {
  final List<ExtendedTask> tasks;

  ExtendedTasksResponse({required this.tasks});

  factory ExtendedTasksResponse.fromJson(Map<String, dynamic> json) {
    final list = json['tasks'] as List<dynamic>? ?? [];
    return ExtendedTasksResponse(
      tasks: list
          .map((e) => ExtendedTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExtendedTaskCreateResponse {
  final bool success;
  final String? taskId;
  final String? error;

  ExtendedTaskCreateResponse({required this.success, this.taskId, this.error});

  factory ExtendedTaskCreateResponse.fromJson(Map<String, dynamic> json) {
    return ExtendedTaskCreateResponse(
      success: json['success'] as bool? ?? false,
      taskId: json['task_id'] as String?,
      error: json['error'] as String?,
    );
  }
}
