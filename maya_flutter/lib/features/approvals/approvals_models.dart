class ApprovalItem {
  final String id;
  final String type;
  final String title;
  final String description;
  final String status;
  final String riskLevel;
  final String createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic>? context;

  ApprovalItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.riskLevel,
    required this.createdAt,
    this.updatedAt,
    this.payload,
    this.context,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      context: json['context'] as Map<String, dynamic>?,
    );
  }
}

class ApprovalsListResponse {
  final List<ApprovalItem> approvals;

  ApprovalsListResponse({required this.approvals});

  factory ApprovalsListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['approvals'] as List<dynamic>? ?? [];
    return ApprovalsListResponse(
      approvals: list
          .map((e) => ApprovalItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApprovalModeResponse {
  final String mode;

  ApprovalModeResponse({required this.mode});

  factory ApprovalModeResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalModeResponse(mode: json['mode'] as String? ?? 'human');
  }
}

class ApprovalActionResponse {
  final bool success;
  final String? action;
  final String? error;

  ApprovalActionResponse({required this.success, this.action, this.error});

  factory ApprovalActionResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalActionResponse(
      success: json['success'] as bool? ?? false,
      action: json['action'] as String?,
      error: json['error'] as String?,
    );
  }
}
