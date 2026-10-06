import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/maya_theme.dart';

class MayaErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData? icon;

  const MayaErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MayaTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon ?? Icons.error_outline,
                  color: MayaTheme.error, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: MayaTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryLabel ?? 'Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
