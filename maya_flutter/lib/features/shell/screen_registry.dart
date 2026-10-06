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
];
