class ExtendedProject {
  final String id;
  final String name;
  final String description;
  final String status;
  final String createdAt;

  ExtendedProject({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory ExtendedProject.fromJson(Map<String, dynamic> json) {
    return ExtendedProject(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ExtendedProjectsResponse {
  final List<ExtendedProject> projects;

  ExtendedProjectsResponse({required this.projects});

  factory ExtendedProjectsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['projects'] as List<dynamic>? ?? [];
    return ExtendedProjectsResponse(
      projects: list
          .map((e) => ExtendedProject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExtendedProjectCreateResponse {
  final bool success;
  final String? projectId;
  final String? error;

  ExtendedProjectCreateResponse(
      {required this.success, this.projectId, this.error});

  factory ExtendedProjectCreateResponse.fromJson(Map<String, dynamic> json) {
    return ExtendedProjectCreateResponse(
      success: json['success'] as bool? ?? false,
      projectId: json['project_id'] as String?,
      error: json['error'] as String?,
    );
  }
}
