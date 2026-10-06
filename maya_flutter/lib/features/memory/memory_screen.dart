import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import '../../../shared/widgets/maya_loading.dart';
import '../../../shared/widgets/maya_error_view.dart';
import 'memory_models.dart';
import 'memory_providers.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoryListAsync = ref.watch(memoryListProvider);
    final memoryStatsAsync = ref.watch(memoryStatsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Memory & RAG', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.invalidate(memoryListProvider);
                ref.invalidate(memoryStatsProvider);
                ref.invalidate(ragStatsProvider);
                ref.invalidate(ragDocumentsProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _showAddMemoryDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.memory_rounded), text: 'Memories'),
              Tab(icon: Icon(Icons.description_rounded), text: 'Documents'),
              Tab(icon: Icon(Icons.search_rounded), text: 'RAG Search'),
              Tab(icon: Icon(Icons.settings_rounded), text: 'RAG Context'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMemoriesTab(memoryListAsync, memoryStatsAsync),
            _buildDocumentsTab(),
            _buildRAGSearchTab(),
            _buildRAGContextTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoriesTab(
    AsyncValue<MemoryListResponse> memoryListAsync,
    AsyncValue<MemoryStatsResponse> memoryStatsAsync,
  ) {
    return Column(
      children: [
        // Stats Cards
        memoryStatsAsync.when(
          data: (stats) => Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Total Memories',
                    value: stats.totalMemories.toString(),
                    color: MayaTheme.neonCyan,
                    icon: Icons.memory_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Vectors',
                    value: stats.totalVectors.toString(),
                    color: MayaTheme.neonViolet,
                    icon: Icons.data_array_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Index Type',
                    value: stats.indexType,
                    color: MayaTheme.neonEmerald,
                    icon: Icons.category_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Size (MB)',
                    value: stats.indexSizeMb.toStringAsFixed(1),
                    color: MayaTheme.neonOrange,
                    icon: Icons.storage_rounded,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox(height: 100),
          error: (_, __) => const SizedBox(height: 100),
        ),

        const Divider(color: MayaTheme.glassWhite10, height: 1),

        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search memories...',
                    hintStyle:
                        MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              ref
                                  .read(memorySearchTriggerProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    ref.read(memorySearchTriggerProvider.notifier).state =
                        value;
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: MayaTheme.neonCyan,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                      ref.read(memorySearchTriggerProvider.notifier).state = '';
                    }
                  });
                  ref.invalidate(memoryListProvider);
                  ref.invalidate(memorySearchProvider);
                },
                style: IconButton.styleFrom(
                  backgroundColor: MayaTheme.glassWhite10,
                ),
              ),
            ],
          ),
        ),

        // Memory List / Search Results
        Expanded(
          child: _isSearching && _searchQuery.isNotEmpty
              ? _buildSearchResults()
              : _buildMemoryList(memoryListAsync),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    final ragStatsAsync = ref.watch(ragStatsProvider);
    final ragDocsAsync = ref.watch(ragDocumentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RAG Stats
          ragStatsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _MemoryStatCard(
                      label: 'Documents',
                      value: stats.totalDocuments.toString(),
                      color: MayaTheme.neonCyan,
                      icon: Icons.description_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MemoryStatCard(
                      label: 'Chunks',
                      value: stats.totalChunks.toString(),
                      color: MayaTheme.neonViolet,
                      icon: Icons.data_array_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MemoryStatCard(
                      label: 'Index Type',
                      value: stats.indexType,
                      color: MayaTheme.neonEmerald,
                      icon: Icons.category_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MemoryStatCard(
                      label: 'Size (MB)',
                      value: stats.indexSizeMb.toStringAsFixed(1),
                      color: MayaTheme.neonOrange,
                      icon: Icons.storage_rounded,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox(height: 100),
          ),

          const SizedBox(height: 24),

          // Ingest Document
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ingest Document', style: MayaTheme.titleMedium),
                const SizedBox(height: 12),
                _IngestDocumentForm(onSuccess: () {
                  ref.invalidate(ragDocumentsProvider);
                  ref.invalidate(ragStatsProvider);
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Documents List
          const Text('Documents', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          ragDocsAsync.when(
            data: (response) {
              if (response.documents.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: MayaTheme.glassCard(),
                  child: const Center(
                    child: Text(
                        'No documents yet. Ingest a document to get started.',
                        style: MayaTheme.bodyMedium),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: response.documents.length,
                itemBuilder: (context, index) {
                  final doc = response.documents[index];
                  return _RAGDocumentTile(
                    doc: doc,
                    onDelete: () async {
                      final api = ref.read(mayaApiProvider);
                      try {
                        await api.deleteJson('/api/v1/rag/documents/${doc.id}');
                        if (mounted) {
                          ref.invalidate(ragDocumentsProvider);
                          ref.invalidate(ragStatsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Document deleted'), backgroundColor: MayaTheme.neonEmerald),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
            ),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_rounded,
                      size: 48, color: MayaTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading documents',
                      style: MayaTheme.bodyMedium
                          .copyWith(color: MayaTheme.error)),
                  const SizedBox(height: 8),
                  Text(err.toString(),
                      style:
                          MayaTheme.bodySmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRAGSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RAG Hybrid Search', style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Search the knowledge base with hybrid (vector + keyword), keyword-only, or vector-only modes.',
                  style: MayaTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Query',
                    labelStyle:
                        MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    ref.invalidate(ragSearchProvider(_searchQuery));
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: 'hybrid',
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Search Mode',
                          labelStyle: MayaTheme.bodyMedium
                              .copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'hybrid',
                              child: Text('Hybrid (Vector + Keyword)')),
                          DropdownMenuItem(
                              value: 'keyword',
                              child: Text('Keyword Only (BM25)')),
                          DropdownMenuItem(
                              value: 'vector', child: Text('Vector Only')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: 5,
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Limit',
                          labelStyle: MayaTheme.bodyMedium
                              .copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3')),
                          DropdownMenuItem(value: 5, child: Text('5')),
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 20, child: Text('20')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _searchQuery = _searchController.text);
                      ref.invalidate(ragSearchProvider(_searchQuery));
                    },
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search Results
          Consumer(
            builder: (context, ref, _) {
              final searchAsync = ref.watch(ragSearchProvider(_searchQuery));
              return searchAsync.when(
                data: (result) {
                  if (result.results.isEmpty && _searchQuery.isNotEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: MayaTheme.glassCard(),
                      child: const Center(
                        child: Text('No results found',
                            style: MayaTheme.bodyMedium),
                      ),
                    );
                  }
                  if (_searchQuery.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: MayaTheme.glassCard(),
                      child: const Center(
                        child: Text('Enter a query and tap Search',
                            style: MayaTheme.bodyMedium),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Results for "${result.query}" (${result.mode})',
                          style: MayaTheme.titleMedium),
                      const SizedBox(height: 12),
                      ...result.results
                          .map((hit) => _RAGSearchResultTile(hit: hit)),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_rounded,
                          size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Search error',
                          style: MayaTheme.bodyMedium
                              .copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(),
                          style: MayaTheme.bodySmall
                              .copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRAGContextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: MayaTheme.glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RAG Context with Attribution',
                    style: MayaTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Get an LLM-ready context block with numbered citations for a query.',
                  style: MayaTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: MayaTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Query',
                    labelStyle:
                        MayaTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: MayaTheme.slate700,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: 5,
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Limit',
                          labelStyle: MayaTheme.bodyMedium
                              .copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3')),
                          DropdownMenuItem(value: 5, child: Text('5')),
                          DropdownMenuItem(value: 10, child: Text('10')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: 6000,
                        dropdownColor: MayaTheme.slate800,
                        style: MayaTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Max Chars',
                          labelStyle: MayaTheme.bodyMedium
                              .copyWith(color: Colors.white54),
                          filled: true,
                          fillColor: MayaTheme.slate700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 2000, child: Text('2000')),
                          DropdownMenuItem(value: 4000, child: Text('4000')),
                          DropdownMenuItem(value: 6000, child: Text('6000')),
                          DropdownMenuItem(value: 8000, child: Text('8000')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(
                          ragContextProvider(_searchController.text));
                    },
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('Get Context'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MayaTheme.neonCyan,
                      foregroundColor: MayaTheme.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Context Result
          Consumer(
            builder: (context, ref, _) {
              final contextAsync =
                  ref.watch(ragContextProvider(_searchController.text));
              return contextAsync.when(
                data: (result) {
                  if (result.context.isEmpty &&
                      _searchController.text.isEmpty) {
                    return const SizedBox();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Context Block', style: MayaTheme.titleMedium),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: MayaTheme.glassCard(),
                        child: SelectableText(
                          result.context,
                          style: MayaTheme.bodyMedium
                              .copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                      if (result.citations.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Citations', style: MayaTheme.titleMedium),
                        const SizedBox(height: 12),
                        ...result.citations.asMap().entries.map((entry) {
                          final index = entry.key;
                          final citation = entry.value;
                          return _RAGCitationTile(
                              index: index + 1, citation: citation);
                        }),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_rounded,
                          size: 48, color: MayaTheme.error),
                      const SizedBox(height: 16),
                      Text('Context error',
                          style: MayaTheme.bodyMedium
                              .copyWith(color: MayaTheme.error)),
                      const SizedBox(height: 8),
                      Text(err.toString(),
                          style: MayaTheme.bodySmall
                              .copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryList(AsyncValue<MemoryListResponse> memoryListAsync) {
    return memoryListAsync.when(
      data: (response) {
        if (response.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.memory_rounded,
                    size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text('No memories yet',
                    style:
                        MayaTheme.bodyMedium.copyWith(color: Colors.white38)),
                const SizedBox(height: 8),
                Text('Tap + to add a memory',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white24)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: response.items.length,
          itemBuilder: (context, index) {
            final item = response.items[index];
            return _MemoryItemTile(item: item);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 48, color: MayaTheme.error),
            const SizedBox(height: 16),
            Text('Error loading memories',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ref.watch(memorySearchProvider).when(
          data: (response) {
            if (response.results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text('No results for "$_searchQuery"',
                        style: MayaTheme.bodyMedium
                            .copyWith(color: Colors.white38)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: response.results.length,
              itemBuilder: (context, index) {
                final item = response.results[index];
                return _MemoryItemTile(item: item, showScore: true);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan)),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_rounded,
                    size: 48, color: MayaTheme.error),
                const SizedBox(height: 16),
                Text('Search error',
                    style:
                        MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
                const SizedBox(height: 8),
                Text(err.toString(),
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
  }

  void _showAddMemoryDialog() {
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MayaTheme.slate800,
        title: const Text('Add Memory', style: MayaTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              maxLines: 4,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter memory content...',
                hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                filled: true,
                fillColor: MayaTheme.slate700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = contentController.text.trim();
              if (content.isNotEmpty) {
                final api = ref.read(mayaApiProvider);
                await api.postJson('/api/v1/memory',
                    data: {'content': content, 'metadata': {}});
                ref.invalidate(memoryListProvider);
                ref.invalidate(memoryStatsProvider);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Memory added'),
                        backgroundColor: MayaTheme.neonEmerald),
                  );
                }
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: MayaTheme.neonCyan),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _MemoryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MemoryStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: MayaTheme.headlineMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: MayaTheme.labelSmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _MemoryItemTile extends StatelessWidget {
  final MemoryItem item;
  final bool showScore;

  const _MemoryItemTile({required this.item, this.showScore = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.memory_rounded,
                    color: MayaTheme.neonCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.id,
                  style: MayaTheme.bodySmall
                      .copyWith(color: Colors.white54, fontFamily: 'monospace'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showScore && item.score != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MayaTheme.neonEmerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(item.score! * 100).toStringAsFixed(1)}%',
                    style: MayaTheme.labelSmall.copyWith(
                        color: MayaTheme.neonEmerald,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.content,
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Created: ${item.createdAt}',
              style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
            ),
          ],
        ],
      ),
    );
  }
}

class _RAGDocumentTile extends ConsumerWidget {
  final RAGDocument doc;
  final VoidCallback onDelete;

  const _RAGDocumentTile({required this.doc, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_rounded,
                    color: MayaTheme.neonViolet, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, style: MayaTheme.titleMedium),
                    Text('${doc.chunkCount} chunks • ${doc.docType}',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              PopupMenuButton(
                icon:
                    const Icon(Icons.more_vert_rounded, color: Colors.white54),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: MayaTheme.error),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: MayaTheme.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('ID: ${doc.id}',
                  style: MayaTheme.bodySmall.copyWith(
                      color: Colors.white54, fontFamily: 'monospace')),
              const Spacer(),
              Text('Size: ${doc.sizeKb.toStringAsFixed(1)} KB',
                  style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
              const SizedBox(width: 12),
              Text(doc.createdAt,
                  style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RAGSearchResultTile extends StatelessWidget {
  final RAGSearchResult hit;

  const _RAGSearchResultTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search_rounded,
                    color: MayaTheme.neonCyan, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hit.title, style: MayaTheme.titleSmall),
                    Text(
                        '${hit.docType} • Score: ${(hit.score * 100).toStringAsFixed(1)}%',
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(hit.content,
              style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _RAGCitationTile extends StatelessWidget {
  final int index;
  final RAGSearchResult citation;

  const _RAGCitationTile({required this.index, required this.citation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MayaTheme.slate700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MayaTheme.glassWhite10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('[$index]',
                  style: MayaTheme.labelSmall.copyWith(
                      color: MayaTheme.neonCyan, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(citation.title,
                    style: MayaTheme.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(citation.content,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IngestDocumentForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const _IngestDocumentForm({required this.onSuccess});

  @override
  ConsumerState<_IngestDocumentForm> createState() =>
      _IngestDocumentFormState();
}

class _IngestDocumentFormState extends ConsumerState<_IngestDocumentForm> {
  final _textController = TextEditingController();
  final _titleController = TextEditingController();
  final _docTypeController = TextEditingController(text: 'text');
  final _pathController = TextEditingController();
  bool _usePath = false;

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _docTypeController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Title',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: 'text',
          dropdownColor: MayaTheme.slate800,
          style: MayaTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Document Type',
            labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
            filled: true,
            fillColor: MayaTheme.slate700,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'text', child: Text('Text')),
            DropdownMenuItem(value: 'markdown', child: Text('Markdown')),
            DropdownMenuItem(value: 'json', child: Text('JSON')),
          ],
          onChanged: (value) {
            if (value != null) _docTypeController.text = value;
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Ingest from File Path'),
          subtitle: Text('Enter a file path instead of text',
              style: MayaTheme.bodySmall),
          value: _usePath,
          onChanged: (value) => setState(() => _usePath = value),
          activeColor: MayaTheme.neonCyan,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        if (!_usePath)
          TextField(
            controller: _textController,
            maxLines: 4,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Content',
              labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          )
        else
          TextField(
            controller: _pathController,
            style: MayaTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'File Path',
              labelStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              filled: true,
              fillColor: MayaTheme.slate700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _ingest,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Ingest Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MayaTheme.neonCyan,
              foregroundColor: MayaTheme.slate900,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _ingest() async {
    final api = ref.read(mayaApiProvider);
    try {
      RAGIngestResponse? response;
      if (_usePath && _pathController.text.isNotEmpty) {
        final resp = await api.postJson('/api/v1/rag/ingest', data: {
          'path': _pathController.text,
          'doc_type': _docTypeController.text,
          'title': _titleController.text,
        });
        response = RAGIngestResponse.fromJson(resp);
      } else if (!_usePath && _textController.text.isNotEmpty) {
        final resp = await api.postJson('/api/v1/rag/ingest', data: {
          'text': _textController.text,
          'doc_type': _docTypeController.text,
          'title': _titleController.text,
        });
        response = RAGIngestResponse.fromJson(resp);
      }
      if (response != null && mounted) {
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Document ingested: ${response!.docId}'),
              backgroundColor: MayaTheme.neonEmerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: MayaTheme.error),
        );
      }
    }
  }
}
