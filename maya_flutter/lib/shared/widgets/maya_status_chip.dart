import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/maya_theme.dart';

class MayaStatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool showBorder;

  const MayaStatusChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            showBorder ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: MayaTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
