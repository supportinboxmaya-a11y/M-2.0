import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Vision AI', style: MayaTheme.headlineSmall),
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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.image_rounded), text: 'Analyze'),
              Tab(icon: Icon(Icons.text_fields_rounded), text: 'OCR'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _VisionAnalyzeTab(),
            _VisionOCRTab(),
          ],
        ),
      ),
    );
  }
}

class _VisionAnalyzeTab extends ConsumerWidget {
  const _VisionAnalyzeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.image_rounded,
    );
  }
}

class _VisionOCRTab extends ConsumerWidget {
  const _VisionOCRTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MayaEmptyState(
      'Endpoint not connected',
      icon: Icons.text_fields_rounded,
    );
  }
}
