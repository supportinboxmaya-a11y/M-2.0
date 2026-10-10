import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../settings/settings_screen.dart';
import '../logs/logs_screen.dart';
import '../metrics/metrics_screen.dart';
import '../flags/flags_screen.dart';
import '../router/router_screen.dart';
import '../instance/instance_screen.dart';
import '../memory/memory_screen.dart';
import '../memory_preferences/memory_preferences_screen.dart';
import '../semantic_index/semantic_index_screen.dart';
import '../knowledge_engine/knowledge_engine_screen.dart';
import '../learning/learning_screen.dart';
import '../skill_generalization/skill_generalization_screen.dart';
import '../extended_projects/extended_projects_screen.dart';
import '../extended_tasks/extended_tasks_screen.dart';
import '../maya_cognitive_core/maya_cognitive_core_screen.dart';
import '../unified_cognitive_loop/unified_cognitive_loop_screen.dart';
import '../self_improve/self_improve_screen.dart';
import '../self_model/self_model_screen.dart';
import '../brain_engine/brain_engine_screen.dart';
import '../agi_architecture/agi_architecture_screen.dart';
import '../autonomous_mode/autonomous_mode_screen.dart';
import '../auto_resume/auto_resume_screen.dart';
import '../approvals/approvals_screen.dart';
import '../workflow_engine/workflow_engine_screen.dart';
import '../agents/agents_screen.dart';
import '../capabilities/capabilities_screen.dart';
import '../plugins/plugins_screen.dart';
import '../vision/vision_screen.dart';
import '../browser_tools/browser_tools_screen.dart';
import '../sandbox_tools/sandbox_tools_screen.dart';
import '../communication_tools/communication_tools_screen.dart';
import '../tools_providers/tools_providers_screen.dart';
import '../mcp_client/mcp_client_screen.dart';
import '../phone_control/phone_control_screen.dart';
import '../webhooks/webhooks_screen.dart';
import '../app_registry/app_registry_screen.dart';

class ScreenEntry {
  final String id;
  final String title;
  final String group;
  final IconData icon;
  final Widget Function(BuildContext) builder;

  ScreenEntry({
    required this.id,
    required this.title,
    required this.group,
    required this.icon,
    required this.builder,
  });
}

final List<ScreenEntry> kScreens = <ScreenEntry>[
  ScreenEntry(
    id: 'settings',
    title: 'Settings',
    group: 'Core',
    icon: Icons.settings_rounded,
    builder: (context) => const SettingsScreen(),
  ),
  ScreenEntry(
    id: 'logs',
    title: 'Logs',
    group: 'Core',
    icon: Icons.article_rounded,
    builder: (context) => const LogsScreen(),
  ),
  ScreenEntry(
    id: 'metrics',
    title: 'Metrics',
    group: 'Core',
    icon: Icons.analytics_rounded,
    builder: (context) => const MetricsScreen(),
  ),
  ScreenEntry(
    id: 'flags',
    title: 'Flags',
    group: 'Core',
    icon: Icons.flag_rounded,
    builder: (context) => const FlagsScreen(),
  ),
  ScreenEntry(
    id: 'router',
    title: 'Router',
    group: 'Core',
    icon: Icons.router_rounded,
    builder: (context) => const RouterScreen(),
  ),
  ScreenEntry(
    id: 'instance',
    title: 'Instance',
    group: 'Core',
    icon: Icons.dns_rounded,
    builder: (context) => const InstanceScreen(),
  ),
  ScreenEntry(
    id: 'memory',
    title: 'Memory',
    group: 'Memory and knowledge',
    icon: Icons.memory_rounded,
    builder: (context) => const MemoryScreen(),
  ),
  ScreenEntry(
    id: 'memory_preferences',
    title: 'Memory Preferences',
    group: 'Memory and knowledge',
    icon: Icons.tune_rounded,
    builder: (context) => const MemoryPreferencesScreen(),
  ),
  ScreenEntry(
    id: 'semantic_index',
    title: 'Semantic Index',
    group: 'Memory and knowledge',
    icon: Icons.search_rounded,
    builder: (context) => const SemanticIndexScreen(),
  ),
  ScreenEntry(
    id: 'knowledge_engine',
    title: 'Knowledge Engine',
    group: 'Memory and knowledge',
    icon: Icons.psychology_rounded,
    builder: (context) => const KnowledgeEngineScreen(),
  ),
  ScreenEntry(
    id: 'learning',
    title: 'Learning',
    group: 'Memory and knowledge',
    icon: Icons.school_rounded,
    builder: (context) => const LearningScreen(),
  ),
  ScreenEntry(
    id: 'skill_generalization',
    title: 'Skill Generalization',
    group: 'Memory and knowledge',
    icon: Icons.auto_awesome_rounded,
    builder: (context) => const SkillGeneralizationScreen(),
  ),
  ScreenEntry(
    id: 'extended_projects',
    title: 'Extended Projects',
    group: 'Goals and tasks',
    icon: Icons.folder_rounded,
    builder: (context) => const ExtendedProjectsScreen(),
  ),
  ScreenEntry(
    id: 'extended_tasks',
    title: 'Extended Tasks',
    group: 'Goals and tasks',
    icon: Icons.task_alt_rounded,
    builder: (context) => const ExtendedTasksScreen(),
  ),
  ScreenEntry(
    id: 'maya_cognitive_core',
    title: 'Maya Cognitive Core',
    group: 'Brain',
    icon: Icons.psychology_rounded,
    builder: (context) => const MayaCognitiveCoreScreen(),
  ),
  ScreenEntry(
    id: 'unified_cognitive_loop',
    title: 'Unified Cognitive Loop',
    group: 'Brain',
    icon: Icons.sync_rounded,
    builder: (context) => const UnifiedCognitiveLoopScreen(),
  ),
  ScreenEntry(
    id: 'self_improve',
    title: 'Self-Improvement',
    group: 'Brain',
    icon: Icons.auto_awesome_rounded,
    builder: (context) => const SelfImproveScreen(),
  ),
  ScreenEntry(
    id: 'self_model',
    title: 'Self Model',
    group: 'Brain',
    icon: Icons.person_search_rounded,
    builder: (context) => const SelfModelScreen(),
  ),
  ScreenEntry(
    id: 'brain_engine',
    title: 'Brain Engine',
    group: 'Brain',
    icon: Icons.memory_rounded,
    builder: (context) => const BrainEngineScreen(),
  ),
  ScreenEntry(
    id: 'agi_architecture',
    title: 'AGI Architecture',
    group: 'Brain',
    icon: Icons.architecture_rounded,
    builder: (context) => const AGIArchitectureScreen(),
  ),
  ScreenEntry(
    id: 'autonomous_mode',
    title: 'Autonomous Mode',
    group: 'Autonomy',
    icon: Icons.rocket_launch_rounded,
    builder: (context) => const AutonomousModeScreen(),
  ),
  ScreenEntry(
    id: 'auto_resume',
    title: 'Auto-Resume',
    group: 'Autonomy',
    icon: Icons.replay_rounded,
    builder: (context) => const AutoResumeScreen(),
  ),
  ScreenEntry(
    id: 'approvals',
    title: 'Approvals Center',
    group: 'Autonomy',
    icon: Icons.rule_rounded,
    builder: (context) => const ApprovalsScreen(),
  ),
  ScreenEntry(
    id: 'workflow_engine',
    title: 'Workflow Engine',
    group: 'Autonomy',
    icon: Icons.account_tree_rounded,
    builder: (context) => const WorkflowEngineScreen(),
  ),
  ScreenEntry(
    id: 'agents',
    title: 'Multi-Agent System',
    group: 'Autonomy',
    icon: Icons.people_rounded,
    builder: (context) => const AgentsScreen(),
  ),
  ScreenEntry(
    id: 'capabilities',
    title: 'Capabilities',
    group: 'Autonomy',
    icon: Icons.list_alt_rounded,
    builder: (context) => const CapabilitiesScreen(),
  ),
  ScreenEntry(
    id: 'plugins',
    title: 'Plugins',
    group: 'Platform',
    icon: Icons.extension_rounded,
    builder: (context) => const PluginsScreen(),
  ),
  ScreenEntry(
    id: 'vision',
    title: 'Vision AI',
    group: 'Platform',
    icon: Icons.visibility_rounded,
    builder: (context) => const VisionScreen(),
  ),
  ScreenEntry(
    id: 'browser_tools',
    title: 'Browser Tools',
    group: 'Tools',
    icon: Icons.web_rounded,
    builder: (context) => const BrowserToolsScreen(),
  ),
  ScreenEntry(
    id: 'sandbox_tools',
    title: 'Sandbox Tools',
    group: 'Tools',
    icon: Icons.code_rounded,
    builder: (context) => const SandboxToolsScreen(),
  ),
  ScreenEntry(
    id: 'communication_tools',
    title: 'Communication Tools',
    group: 'Tools',
    icon: Icons.email_rounded,
    builder: (context) => const CommunicationToolsScreen(),
  ),
  ScreenEntry(
    id: 'tools_providers',
    title: 'Tools & Providers',
    group: 'Tools',
    icon: Icons.build_rounded,
    builder: (context) => const ToolsProvidersScreen(),
  ),
  ScreenEntry(
    id: 'mcp_client',
    title: 'MCP Client',
    group: 'Tools',
    icon: Icons.extension_rounded,
    builder: (context) => const McpClientScreen(),
  ),
  ScreenEntry(
    id: 'phone_control',
    title: 'Phone / Device Control',
    group: 'Tools',
    icon: Icons.devices_rounded,
    builder: (context) => const PhoneControlScreen(),
  ),
  ScreenEntry(
    id: 'webhooks',
    title: 'Webhooks',
    group: 'Platform',
    icon: Icons.webhook_rounded,
    builder: (context) => const WebhooksScreen(),
  ),
  ScreenEntry(
    id: 'app_registry',
    title: 'App Registry & Monitoring',
    group: 'Platform',
    icon: Icons.apps_rounded,
    builder: (context) => const AppRegistryScreen(),
  ),
];
