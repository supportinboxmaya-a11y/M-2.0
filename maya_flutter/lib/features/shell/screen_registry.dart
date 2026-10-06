import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ScreenEntry {
  final String id;
  final String title;
  final String group;
  final IconData icon;
  final Widget Function(BuildContext) builder;

  const ScreenEntry({
    required this.id,
    required this.title,
    required this.group,
    required this.icon,
    required this.builder,
  });
}

final List<ScreenEntry> kScreens = <ScreenEntry>[];
