import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class RemoteVpsScreen extends ConsumerWidget {
  const RemoteVpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title:
              const Text('Remote VPS Deploy', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VPS Config Status
              const MayaEmptyState(
                'VPS Not Configured',
                icon: Icons.cloud_rounded,
              ),

              const SizedBox(height: 24),

              // Deploy New Container
              const MayaEmptyState(
                'Endpoint not connected',
                icon: Icons.rocket_launch_rounded,
              ),

              const SizedBox(height: 24),

              // Container List
              const MayaEmptyState(
                'No containers running on VPS',
                icon: Icons.developer_board_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
