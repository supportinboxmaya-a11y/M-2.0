import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/maya_theme.dart';

class MayaLoading extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final double strokeWidth;

  const MayaLoading({
    super.key,
    this.message,
    this.size = 24,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? MayaTheme.neonCyan,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class MayaLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? color;

  const MayaLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: MayaTheme.slate900.withValues(alpha: 0.7),
            child: MayaLoading(message: message, color: color),
          ),
      ],
    );
  }
}
