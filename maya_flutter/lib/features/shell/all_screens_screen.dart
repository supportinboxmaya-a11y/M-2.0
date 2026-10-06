import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/maya_theme.dart';
import '../../shared/widgets/maya_empty_state.dart';
import 'screen_registry.dart';

class AllScreensScreen extends StatefulWidget {
  const AllScreensScreen({super.key});

  @override
  State<AllScreensScreen> createState() => _AllScreensScreenState();
}

class _AllScreensScreenState extends State<AllScreensScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredScreens = _searchQuery.isEmpty
        ? kScreens
        : kScreens
            .where((s) =>
                s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.group.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final grouped = <String, List<ScreenEntry>>{};
    for (final screen in filteredScreens) {
      grouped.putIfAbsent(screen.group, () => []).add(screen);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Screens'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: MayaTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search screens...',
                hintStyle: MayaTheme.bodyMedium.copyWith(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: MayaTheme.slate800,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: MayaTheme.neonCyan, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: filteredScreens.isEmpty
                ? const MayaEmptyState('No screens added yet')
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: grouped.entries
                        .map((entry) => _buildGroup(entry.key, entry.value))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String groupName, List<ScreenEntry> screens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            groupName,
            style: MayaTheme.labelMedium.copyWith(color: MayaTheme.neonCyan),
          ),
        ),
        ...screens.map((screen) => _buildScreenTile(screen)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildScreenTile(ScreenEntry screen) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MayaTheme.neonCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(screen.icon, color: MayaTheme.neonCyan, size: 20),
      ),
      title: Text(screen.title, style: MayaTheme.titleSmall),
      subtitle: Text(screen.group, style: MayaTheme.bodySmall),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: screen.builder),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
    );
  }
}
