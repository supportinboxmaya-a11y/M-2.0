import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../settings/settings_screen.dart';
import '../logs/logs_screen.dart';
import '../metrics/metrics_screen.dart';
import '../flags/flags_screen.dart';
import '../router/router_screen.dart';

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
];
