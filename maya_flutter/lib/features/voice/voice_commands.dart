import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_providers.dart';
import 'voice_service.dart';
import '../../core/services/api_service.dart';

enum VoiceCommandType {
  appControl,
  generalTask,
  unknown,
}

enum VoiceCommandCategory {
  navigate,
  startAction,
  stopAction,
  statusQuery,
  approvalAction,
  generalQuestion,
}

class VoiceCommand {
  final VoiceCommandType type;
  final VoiceCommandCategory category;
  final String action;
  final String target;
  final Map<String, dynamic> parameters;
  final String originalText;

  VoiceCommand({
    required this.type,
    required this.category,
    required this.action,
    required this.target,
    required this.parameters,
    required this.originalText,
  });
}

class VoiceCommandResult {
  final bool success;
  final String message;
  final String? ttsResponse;
  final bool shouldNavigate;
  final String? targetScreen;

  VoiceCommandResult({
    required this.success,
    required this.message,
    this.ttsResponse,
    this.shouldNavigate = false,
    this.targetScreen,
  });
}

class AppScreenMapping {
  static const Map<String, String> screenRoutes = {
    'health': 'health',
    'health probes': 'health',
    'queue': 'queue',
    'task queue': 'queue',
    'memory': 'memory',
    'memory rag': 'memory',
    'rag': 'memory',
    'tools': 'tools',
    'tools providers': 'tools',
    'providers': 'tools',
    'agents': 'agents',
    'brain': 'brain',
    'brain engine': 'brain',
    'workflow': 'workflow',
    'workflow engine': 'workflow',
    'autonomous': 'autonomous',
    'autonomous mode': 'autonomous',
    'router': 'router',
    'multi model router': 'router',
    'enterprise': 'enterprise',
    'learning': 'learning',
    'multimodal': 'multimodal',
    'phone': 'phone',
    'phone control': 'phone',
    'device control': 'phone',
    'instance': 'instance',
    'instance manager': 'instance',
    'hosting': 'hosting',
    'hosting manager': 'hosting',
    'deploy': 'deploy',
    'remote deploy': 'deploy',
    'cognition': 'cognition',
    'cognition loop': 'cognition',
    'agi architecture': 'agi',
    'agi': 'agi',
    'cognitive core': 'cognitive_core',
    'maya cognitive core': 'cognitive_core',
    'business analysis': 'business',
    'business': 'business',
    'guarded publish': 'guarded_publish',
    'publish': 'guarded_publish',
    'approvals': 'approvals',
    'approval center': 'approvals',
    'chat': 'chat',
    'voice': 'voice',
    'camera': 'camera',
    'vision': 'camera',
    'settings': 'settings',
    'app registry': 'app_registry',
    'registry': 'app_registry',
    'app monitoring': 'app_registry',
    'monitoring': 'app_registry',
    'provisioner': 'provisioner',
    'api key provisioner': 'provisioner',
    'key provisioner': 'provisioner',
    'provision api key': 'provisioner',
    'communication': 'communication',
    'communication tools': 'communication',
    'email tool': 'communication',
    'webhook tool': 'communication',
    'webhook': 'communication',
    'slack': 'communication',
    'discord': 'communication',
    'unified loop': 'unified_loop',
    'unified cognitive loop': 'unified_loop',
    'cognitive loop': 'unified_loop',
    'loop status': 'unified_loop',
    'loop control': 'unified_loop',
    'persistent goals': 'persistent_goals',
    'persistent goal': 'persistent_goals',
    'goals list': 'persistent_goals',
    'my goals': 'persistent_goals',
    'goal status': 'persistent_goals',
    'incomplete goals': 'persistent_goals',
    'create goal': 'persistent_goals',
    'new goal': 'persistent_goals',
    'resume goal': 'persistent_goals',
    'pause goal': 'persistent_goals',
    'cancel goal': 'persistent_goals',
    'goal progress': 'persistent_goals',
    'knowledge engine': 'knowledge_engine',
    'knowledge': 'knowledge_engine',
    'knowledge base': 'knowledge_engine',
    'query knowledge': 'knowledge_engine',
    'teach knowledge': 'knowledge_engine',
    'learn knowledge': 'knowledge_engine',
    'beliefs': 'knowledge_engine',
    'my beliefs': 'knowledge_engine',
    'knowledge stats': 'knowledge_engine',
    'skill generalization': 'skill_generalization',
    'skill': 'skill_generalization',
    'skills': 'skill_generalization',
    'skill search': 'skill_generalization',
    'search skill': 'skill_generalization',
    'compose skill': 'skill_generalization',
    'skill compose': 'skill_generalization',
    'mcp': 'mcp_client',
    'mcp servers': 'mcp_client',
    'mcp server': 'mcp_client',
    'model context protocol': 'mcp_client',
    'connect mcp': 'mcp_client',
    'self model': 'self_model',
    'self': 'self_model',
    'capability map': 'self_model',
    'strengths': 'self_model',
    'weaknesses': 'self_model',
    'self assess': 'self_model',
    'assess myself': 'self_model',
    'semantic index': 'semantic_index',
    'vector search': 'semantic_index',
    'vector store': 'semantic_index',
    'embedding': 'semantic_index',
  };

  static const Map<String, String> screenDisplayNames = {
    'health': 'Health Probes',
    'queue': 'Task Queue Monitor',
    'memory': 'Memory & RAG',
    'tools': 'Tools & Providers',
    'agents': 'Multi-Agent System',
    'brain': 'Brain Engine',
    'workflow': 'Workflow Engine',
    'autonomous': 'Autonomous Mode',
    'router': 'Multi-Model Router',
    'enterprise': 'Enterprise Layer',
    'learning': 'Learning Layer',
    'multimodal': 'Multimodal',
    'phone': 'Phone Control',
    'instance': 'Instance Manager',
    'hosting': 'Hosting Manager',
    'deploy': 'Remote VPS Deploy',
    'cognition': 'Cognition Loop',
    'agi': 'AGI Architecture',
    'cognitive_core': 'Maya Cognitive Core',
    'business': 'Business Analysis',
    'guarded_publish': 'Guarded Publish',
    'approvals': 'Approvals Center',
    'chat': 'Chat',
    'voice': 'Voice Control',
    'camera': 'Vision AI',
    'settings': 'Settings',
    'app_registry': 'App Registry & Monitoring',
    'provisioner': 'API Key Provisioner',
    'communication': 'Communication Tools',
    'unified_loop': 'Unified Cognitive Loop',
    'persistent_goals': 'Persistent Goal Pursuit',
    'knowledge_engine': 'Knowledge Engine',
    'skill_generalization': 'Skill Generalization',
    'mcp_client': 'MCP Servers',
    'self_model': 'Self Model',
    'semantic_index': 'Semantic Index',
  };

  static String? resolveScreenRoute(String command) {
    final lower = command.toLowerCase().trim();
    for (final entry in screenRoutes.entries) {
      if (lower.contains(entry.key)) {
        return entry.key;
      }
    }
    return null;
  }

  static String getDisplayName(String routeKey) {
    return screenDisplayNames[routeKey] ?? routeKey;
  }
}

class VoiceCommandPatterns {
  static const List<String> navigatePatterns = [
    r'(open|show|go to|navigate to|display|view)\s+(.+)',
    r'(\w+)\s*(screen|page|view)\s*(open|show|khulo|dekhao)',
  ];

  static const List<String> startPatterns = [
    r'(start|begin|run|execute|launch|shuru)\s+(.+)',
    r'(\w+)\s*(start|shuru|chalu|koro)',
  ];

  static const List<String> stopPatterns = [
    r'(stop|end|cancel|halt|bandho|close|rokho)\s+(.+)',
    r'(\w+)\s*(stop|bandho|rokho|band)',
  ];

  static const List<String> statusPatterns = [
    r'(what.*status|status.*ki|how.*going|ki hocche|ki holo|current state)',
    r'status\s+of\s+(.+)',
  ];

  static const List<String> approvalPatterns = [
    r'(approve|accept|yes|ok|thik ache)\s*(.*)',
    r'(reject|deny|no|cancel|na)\s*(.*)',
  ];

  static const List<String> generalQuestionPatterns = [
    r'^(what|how|why|when|where|who|which|can you|could you|please|tell me|explain)',
    r'\?$',
  ];
}

typedef NavigationCallback = void Function(String screenKey);

class VoiceCommandExecutor {
  final Ref ref;
  final NavigationCallback onNavigate;

  VoiceCommandExecutor(this.ref, this.onNavigate);

  Future<VoiceCommandResult> execute(VoiceCommand command) async {
    switch (command.type) {
      case VoiceCommandType.appControl:
        return _executeAppControl(command);
      case VoiceCommandType.generalTask:
        return _executeGeneralTask(command);
      case VoiceCommandType.unknown:
        return VoiceCommandResult(
          success: false,
          message: 'Could not understand. Please provide more details.',
          ttsResponse: 'I did not understand. Please provide more details and try again.',
        );
    }
  }

  Future<VoiceCommandResult> _executeAppControl(VoiceCommand command) async {
    switch (command.category) {
      case VoiceCommandCategory.navigate:
        return _handleNavigate(command);
      case VoiceCommandCategory.startAction:
        return _handleStartAction(command);
      case VoiceCommandCategory.stopAction:
        return _handleStopAction(command);
      case VoiceCommandCategory.statusQuery:
        return _handleStatusQuery(command);
      case VoiceCommandCategory.approvalAction:
        return _handleApprovalAction(command);
      default:
        return VoiceCommandResult(
          success: false,
          message: 'Unknown app control command',
          ttsResponse: 'I could not process that command.',
        );
    }
  }

  Future<VoiceCommandResult> _handleNavigate(VoiceCommand command) async {
    final screenKey = AppScreenMapping.resolveScreenRoute(command.target);
    if (screenKey == null) {
      return VoiceCommandResult(
        success: false,
        message: 'Screen not found: ${command.target}',
        ttsResponse: 'I could not find that screen. Available screens are: ${AppScreenMapping.screenDisplayNames.values.join(', ')}.',
      );
    }

    onNavigate(screenKey);

    return VoiceCommandResult(
      success: true,
      message: 'Navigated to ${AppScreenMapping.getDisplayName(screenKey)}',
      ttsResponse: 'Opening ${AppScreenMapping.getDisplayName(screenKey)}.',
      shouldNavigate: true,
      targetScreen: screenKey,
    );
  }

  Future<VoiceCommandResult> _handleStartAction(VoiceCommand command) async {
    final target = command.target.toLowerCase();

    if (target.contains('autonomous') || target.contains('auto mode')) {
      await _callApi('/api/v1/autonomous/start', method: 'POST');
      return VoiceCommandResult(
        success: true,
        message: 'Autonomous mode started',
        ttsResponse: 'Autonomous mode has been started.',
      );
    }

    if (target.contains('cognition') || target.contains('cognitive')) {
      await _callApi('/api/v1/cognitive/loop/start', method: 'POST');
      return VoiceCommandResult(
        success: true,
        message: 'Cognition loop started',
        ttsResponse: 'Cognition loop has been started.',
      );
    }

    if (target.contains('queue') || target.contains('task queue')) {
      await _callApi('/api/v1/queue/start', method: 'POST');
      return VoiceCommandResult(
        success: true,
        message: 'Task queue started',
        ttsResponse: 'Task queue has been started.',
      );
    }

    if (target.contains('deploy') || target.contains('vps')) {
      await _callApi('/api/v1/deploy/start', method: 'POST');
      return VoiceCommandResult(
        success: true,
        message: 'Deploy pipeline started',
        ttsResponse: 'Deploy pipeline has been started.',
      );
    }

    return VoiceCommandResult(
      success: false,
      message: 'Unknown start action: ${command.target}',
      ttsResponse: 'I do not know how to start that.',
    );
  }

  Future<VoiceCommandResult> _handleStopAction(VoiceCommand command) async {
    final target = command.target.toLowerCase();

    if (target.contains('autonomous') || target.contains('auto mode')) {
      await _callApi('/api/v1/autonomous/stop', method: 'POST');
      return VoiceCommandResult(
        success: true,
        message: 'Autonomous mode stopped',
        ttsResponse: 'Autonomous mode has been stopped.',
      );
    }

    if (target.contains('cognition') || target.contains('cognitive')) {
      await _callApi('/api/v1/cognitive/loop/stop', method: 'POST');
      return VoiceCommandResult(
        success: true,
        message: 'Cognition loop stopped',
        ttsResponse: 'Cognition loop has been stopped.',
      );
    }

    if (target.contains('queue') || target.contains('task queue')) {
      await _callApi('/api/v1/queue/stop', method: 'POST');
      return VoiceCommandResult(
        success: true,
        message: 'Task queue stopped',
        ttsResponse: 'Task queue has been stopped.',
      );
    }

    if (target.contains('voice') || target.contains('speech') || target.contains('recording')) {
      await ref.read(voiceServiceProvider).stopRecording();
      await ref.read(voiceServiceProvider).stopSpeaking();
      return VoiceCommandResult(
        success: true,
        message: 'Voice recording and speaking stopped',
        ttsResponse: 'Voice has been stopped.',
      );
    }

    return VoiceCommandResult(
      success: false,
      message: 'Unknown stop action: ${command.target}',
      ttsResponse: 'I do not know how to stop that.',
    );
  }

  Future<VoiceCommandResult> _handleStatusQuery(VoiceCommand command) async {
    final apiService = ref.read(apiServiceProvider);
    final target = command.target.toLowerCase();

    try {
      String statusMessage = '';
      String ttsMessage = '';

      if (target.contains('health') || target.contains('system')) {
        final health = await apiService.checkHealth();
        statusMessage = 'System: ${health.system} | Live: ${health.live} | Ready: ${health.ready}';
        ttsMessage = 'System is ${health.live ? 'healthy' : 'unhealthy'}.';
      } else if (target.contains('queue') || target.contains('task')) {
        final queue = await apiService.getQueueStats();
        statusMessage = 'Queue: ${queue.pending} pending, ${queue.running} running, ${queue.completed} completed';
        ttsMessage = 'Task queue has ${queue.pending} pending and ${queue.running} running jobs.';
      } else if (target.contains('autonomous')) {
        final auto = await apiService.getAutonomousStatus();
        statusMessage = 'Autonomous: ${auto.enabled ? 'Enabled' : 'Disabled'} | Running: ${auto.running}';
        ttsMessage = 'Autonomous mode is ${auto.enabled ? 'enabled' : 'disabled'} and ${auto.running ? 'running' : 'stopped'}.';
      } else if (target.contains('cognition')) {
        final cog = await apiService.getCognitiveStatus();
        statusMessage = 'Cognition: ${cog.running ? 'Running' : 'Stopped'} | Cycle: ${cog.cycleCount}';
        ttsMessage = 'Cognition loop is ${cog.running ? 'running' : 'stopped'} with ${cog.cycleCount} cycles completed.';
      } else if (target.contains('voice')) {
        final voiceService = ref.read(voiceServiceProvider);
        statusMessage = 'Voice: ${voiceService.isRecording ? 'Recording' : voiceService.isSpeaking ? 'Speaking' : 'Idle'}';
        ttsMessage = 'Voice is currently ${voiceService.isRecording ? 'recording' : voiceService.isSpeaking ? 'speaking' : 'idle'}.';
      } else if (target.contains('approval') || target.contains('publish')) {
        final approvals = await apiService.getApprovals(status: 'pending');
        statusMessage = 'Pending approvals: ${approvals.approvals.length}';
        ttsMessage = 'There are ${approvals.approvals.length} pending approvals.';
      } else {
        final health = await apiService.checkHealth();
        statusMessage = 'Overall: ${health.system} | Live: ${health.live} | Ready: ${health.ready}';
        ttsMessage = 'System status is ${health.live ? 'healthy' : 'unhealthy'}.';
      }

      return VoiceCommandResult(
        success: true,
        message: statusMessage,
        ttsResponse: ttsMessage,
      );
    } catch (e) {
      return VoiceCommandResult(
        success: false,
        message: 'Failed to get status: $e',
        ttsResponse: 'Failed to get status information.',
      );
    }
  }

  Future<VoiceCommandResult> _handleApprovalAction(VoiceCommand command) async {
    final apiService = ref.read(apiServiceProvider);
    final action = command.action.toLowerCase();

    try {
      final approvals = await apiService.getApprovals(status: 'pending');
      if (approvals.approvals.isEmpty) {
        return VoiceCommandResult(
          success: false,
          message: 'No pending approvals',
          ttsResponse: 'There are no pending approvals at the moment.',
        );
      }

      final targetApproval = approvals.approvals.first;
      final decision = action.contains('approve') || action.contains('accept') ? 'approve' : 'reject';

      await apiService.decideApproval(
        approvalId: targetApproval.id,
        decision: decision,
      );

      return VoiceCommandResult(
        success: true,
        message: '$decision approval ${targetApproval.id}',
        ttsResponse: 'Approval ${targetApproval.id} has been $decision.',
      );
    } catch (e) {
      return VoiceCommandResult(
        success: false,
        message: 'Approval action failed: $e',
        ttsResponse: 'Failed to process approval.',
      );
    }
  }

  Future<VoiceCommandResult> _executeGeneralTask(VoiceCommand command) async {
    final apiService = ref.read(apiServiceProvider);

    try {
      final response = await apiService.agentChat(command.originalText);
      return VoiceCommandResult(
        success: true,
        message: response.reply,
        ttsResponse: response.reply,
      );
    } catch (e) {
      return VoiceCommandResult(
        success: false,
        message: 'General task failed: $e',
        ttsResponse: 'I encountered an error processing your request.',
      );
    }
  }

  Future<void> _callApi(String endpoint, {String method = 'POST', Map<String, dynamic>? body}) async {
    final apiService = ref.read(apiServiceProvider);
    if (method == 'POST') {
      await apiService.post(endpoint, data: body ?? {});
    } else {
      await apiService.get(endpoint);
    }
  }
}

class VoiceCommandClassifier {
  static VoiceCommand classify(String text) {
    final lower = text.toLowerCase().trim();

    for (final pattern in VoiceCommandPatterns.navigatePatterns) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(lower);
      if (match != null) {
        String target = match.group(2) ?? match.group(1) ?? '';
        target = target.replaceAll(RegExp(r'\s+(screen|page|view|khulo|dekhao)$'), '').trim();
        return VoiceCommand(
          type: VoiceCommandType.appControl,
          category: VoiceCommandCategory.navigate,
          action: 'navigate',
          target: target,
          parameters: {},
          originalText: text,
        );
      }
    }

    for (final pattern in VoiceCommandPatterns.startPatterns) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(lower);
      if (match != null) {
        String target = match.group(2) ?? match.group(1) ?? '';
        target = target.replaceAll(RegExp(r'\s+(start|shuru|chalu|koro)$'), '').trim();
        return VoiceCommand(
          type: VoiceCommandType.appControl,
          category: VoiceCommandCategory.startAction,
          action: 'start',
          target: target,
          parameters: {},
          originalText: text,
        );
      }
    }

    for (final pattern in VoiceCommandPatterns.stopPatterns) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(lower);
      if (match != null) {
        String target = match.group(2) ?? match.group(1) ?? '';
        target = target.replaceAll(RegExp(r'\s+(stop|bandho|rokho|band)$'), '').trim();
        return VoiceCommand(
          type: VoiceCommandType.appControl,
          category: VoiceCommandCategory.stopAction,
          action: 'stop',
          target: target,
          parameters: {},
          originalText: text,
        );
      }
    }

    for (final pattern in VoiceCommandPatterns.statusPatterns) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(lower);
      if (match != null) {
        String target = match.group(1) ?? 'system';
        target = target.replaceAll(RegExp(r'^(what.*status|status.*ki|how.*going|ki hocche|ki holo|current state)\s+'), '').trim();
        return VoiceCommand(
          type: VoiceCommandType.appControl,
          category: VoiceCommandCategory.statusQuery,
          action: 'status',
          target: target.isEmpty ? 'system' : target,
          parameters: {},
          originalText: text,
        );
      }
    }

    for (final pattern in VoiceCommandPatterns.approvalPatterns) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(lower);
      if (match != null) {
        return VoiceCommand(
          type: VoiceCommandType.appControl,
          category: VoiceCommandCategory.approvalAction,
          action: match.group(1) ?? (lower.contains('approve') || lower.contains('accept') ? 'approve' : 'reject'),
          target: match.group(2) ?? '',
          parameters: {},
          originalText: text,
        );
      }
    }

    for (final pattern in VoiceCommandPatterns.generalQuestionPatterns) {
      final regex = RegExp(pattern);
      if (regex.hasMatch(lower)) {
        return VoiceCommand(
          type: VoiceCommandType.generalTask,
          category: VoiceCommandCategory.generalQuestion,
          action: 'question',
          target: text,
          parameters: {},
          originalText: text,
        );
      }
    }

    return VoiceCommand(
      type: VoiceCommandType.generalTask,
      category: VoiceCommandCategory.generalQuestion,
      action: 'general',
      target: text,
      parameters: {},
      originalText: text,
    );
  }
}

class VoiceCommandLogEntry {
  final String id;
  final DateTime timestamp;
  final String transcript;
  final VoiceCommand command;
  final VoiceCommandResult result;
  final Duration? processingTime;

  VoiceCommandLogEntry({
    required this.id,
    required this.timestamp,
    required this.transcript,
    required this.command,
    required this.result,
    this.processingTime,
  });
}

class VoiceCommandLogNotifier extends StateNotifier<List<VoiceCommandLogEntry>> {
  VoiceCommandLogNotifier() : super([]);

  void addEntry(VoiceCommandLogEntry entry) {
    state = [entry, ...state];
    if (state.length > 100) {
      state = state.sublist(0, 100);
    }
  }

  void clear() {
    state = [];
  }
}