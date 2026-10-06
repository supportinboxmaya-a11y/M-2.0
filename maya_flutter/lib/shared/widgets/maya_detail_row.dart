import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/maya_theme.dart';

class MayaDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? leadingIcon;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final Widget? trailing;

  const MayaDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.leadingIcon,
    this.valueColor,
    this.valueStyle,
    this.labelStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 18, color: MayaTheme.neonCyan),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: labelStyle ?? MayaTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: (valueStyle ?? MayaTheme.bodyMedium).copyWith(
                    color: valueColor ?? Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
