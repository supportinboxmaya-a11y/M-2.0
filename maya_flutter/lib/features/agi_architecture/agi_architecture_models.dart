class AGIArchitectureComponent {
  final String id;
  final String name;
  final String type;
  final String status;
  final String description;
  final Map<String, dynamic>? config;

  AGIArchitectureComponent({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.description,
    this.config,
  });

  factory AGIArchitectureComponent.fromJson(Map<String, dynamic> json) {
    return AGIArchitectureComponent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      description: json['description'] as String? ?? '',
      config: json['config'] as Map<String, dynamic>?,
    );
  }
}

class AGIArchitectureComponentsResponse {
  final List<AGIArchitectureComponent> components;

  AGIArchitectureComponentsResponse({required this.components});

  factory AGIArchitectureComponentsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['components'] as List<dynamic>? ?? [];
    return AGIArchitectureComponentsResponse(
      components: list.map((e) => AGIArchitectureComponent.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class AGIArchitectureConnectionsResponse {
  final List<AGIConnection> connections;

  AGIArchitectureConnectionsResponse({required this.connections});

  factory AGIArchitectureConnectionsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['connections'] as List<dynamic>? ?? [];
    return AGIArchitectureConnectionsResponse(
      connections: list.map((e) => AGIConnection.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class AGIConnection {
  final String from;
  final String to;
  final String type;
  final double weight;

  AGIConnection({
    required this.from,
    required this.to,
    required this.type,
    required this.weight,
  });

  factory AGIConnection.fromJson(Map<String, dynamic> json) {
    return AGIConnection(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      type: json['type'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AGIArchitectureStats {
  final int totalComponents;
  final int activeComponents;
  final int connections;
  final String overallHealth;

  AGIArchitectureStats({
    required this.totalComponents,
    required this.activeComponents,
    required this.connections,
    required this.overallHealth,
  });

  factory AGIArchitectureStats.fromJson(Map<String, dynamic> json) {
    return AGIArchitectureStats(
      totalComponents: json['total_components'] as int? ?? 0,
      activeComponents: json['active_components'] as int? ?? 0,
      connections: json['connections'] as int? ?? 0,
      overallHealth: json['overall_health'] as String? ?? 'unknown',
    );
  }
}