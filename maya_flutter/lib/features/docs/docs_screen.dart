import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final docsDocumentsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(mayaApiProvider);
  return api.docsListDocuments();
});

class DocsScreen extends ConsumerStatefulWidget {
  const DocsScreen({super.key});

  @override
  ConsumerState<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends ConsumerState<DocsScreen>
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
          title: const Text('Documentation', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(docsDocumentsProvider),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'Documents'),
              Tab(icon: Icon(Icons.add_circle_rounded), text: 'Create'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _DocumentsTab(),
            _CreateTab(),
          ],
        ),
      ),
    );
  }
}

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(docsDocumentsProvider);

    return docsAsync.map(
      data: (data) {
        final documents = data.value['documents'] as List? ?? [];
        if (documents.isEmpty) {
          return const MayaEmptyState(
            'No Documents',
            icon: Icons.list_alt_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final doc = documents[index];
            return _DocumentCard(doc: doc);
          },
        );
      },
      loading: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan))),
      error: (err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading documents', style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.error.toString(), style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final Map<String, dynamic> doc;

  const _DocumentCard({required this.doc, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.list_alt_rounded, color: MayaTheme.neonCyan, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['title'] ?? 'Untitled', style: MayaTheme.titleMedium),
                    if (doc['category'] != null)
                      Text('Category: ${doc['category']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MayaTheme.neonCyan),
                ),
                child: Text(
                  doc['status']?.toUpperCase() ?? 'PUBLISHED',
                  style: MayaTheme.labelSmall.copyWith(color: MayaTheme.neonCyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(doc['content'] ?? '', style: MayaTheme.bodySmall.copyWith(color: Colors.white70), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Updated: ${doc['updatedAt']?.toString().substring(0, 19) ?? doc['createdAt']?.toString().substring(0, 19) ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38, fontFamily: 'monospace')),
              const Spacer(),
              Text('Doc ID: ${doc['id'] ?? ''}', style: MayaTheme.bodySmall.copyWith(color: Colors.white38, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateTab extends ConsumerStatefulWidget {
  const _CreateTab({super.key});

  @override
  ConsumerState<_CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends ConsumerState<_CreateTab> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _createDocument() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Title and content are required'), backgroundColor: MayaTheme.error),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await ref.read(mayaApiProvider).docsCreateDocument(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      );
      _titleController.clear();
      _contentController.clear();
      _categoryController.clear();
      ref.invalidate(docsDocumentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Document created successfully'), backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Document', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Create a new documentation page.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title', hintText: 'Document title'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Category (optional)', hintText: 'e.g., api, guide, reference'),
            style: MayaTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(labelText: 'Content', hintText: 'Document content (markdown supported)'),
            style: MayaTheme.bodyMedium,
            maxLines: 15,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createDocument,
              icon: _isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.save_rounded),
              label: Text(_isCreating ? 'Creating...' : 'Create Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}