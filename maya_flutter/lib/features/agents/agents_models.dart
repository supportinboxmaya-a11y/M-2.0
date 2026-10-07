class AgentInfo {
  final String id;
  final String name;
  final String description;
  final String status;
  final String type;
  final int ok;
  final int errors;
  final double? lastActive;

  AgentInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.type,
    required this.ok,
    required this.errors,
    this.lastActive,
  });

  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    return AgentInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      type: json['type'] as String? ?? '',
      ok: json['ok'] as int? ?? 0,
      errors: json['errors'] as int? ?? 0,
      lastActive: (json['last_active'] as num?)?.toDouble(),
    );
  }
}

class AgentsListResponse {
  final List<AgentInfo> agents;

  AgentsListResponse({required this.agents});

  factory AgentsListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['agents'] as List<dynamic>? ?? [];
    return AgentsListResponse(
        agents: list
            .map((e) => AgentInfo.fromJson(e as Map<String, dynamic>))
            .toList());
  }
}

class AgentsOrchestrateResponse {
  final String goal;
  final String plan;
  final List<AgentAssignment> assignments;

  AgentsOrchestrateResponse({
    required this.goal,
    required this.plan,
    required this.assignments,
  });

  factory AgentsOrchestrateResponse.fromJson(Map<String, dynamic> json) {
    return AgentsOrchestrateResponse(
      goal: json['goal'] as String? ?? '',
      plan: json['plan'] as String? ?? '',
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((e) => AgentAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AgentAssignment {
  final String agentId;
  final String task;
  final String status;

  AgentAssignment({
    required this.agentId,
    required this.task,
    required this.status,
  });

  factory AgentAssignment.fromJson(Map<String, dynamic> json) {
    return AgentAssignment(
      agentId: json['agent_id'] as String? ?? '',
      task: json['task'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class AgentMessage {
  final String id;
  final String fromAgent;
  final String toAgent;
  final String type;
  final String content;
  final String timestamp;

  AgentMessage({
    required this.id,
    required this.fromAgent,
    required this.toAgent,
    required this.type,
    required this.content,
    required this.timestamp,
  });

  factory AgentMessage.fromJson(Map<String, dynamic> json) {
    return AgentMessage(
      id: json['id'] as String? ?? '',
      fromAgent: json['from_agent'] as String? ?? '',
      toAgent: json['to_agent'] as String? ?? '',
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

class AgentsMessagesResponse {
  final List<AgentMessage> messages;

  AgentsMessagesResponse({required this.messages});

  factory AgentsMessagesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['messages'] as List<dynamic>? ?? [];
    return AgentsMessagesResponse(
        messages: list
            .map((e) => AgentMessage.fromJson(e as Map<String, dynamic>))
            .toList());
  }
}
