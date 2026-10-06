import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import '../../../shared/widgets/maya_loading.dart';
import '../../../shared/widgets/maya_error_view.dart';

class FlagsScreen extends ConsumerWidget {
  const FlagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Feature Flags', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(flagsProvider),
            ),
          ],
        ),
        body: Consumer(
          builder: (context, ref, _) {
            final flagsAsync = ref.watch(flagsProvider);

            return flagsAsync.when(
              data: (flags) {
                final entries = flags.flags.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_rounded,
                            size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('No feature flags configured',
                            style: MayaTheme.bodyMedium
                                .copyWith(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _FlagTile(flagKey: entry.key, value: entry.value);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(MayaTheme.neonCyan),
                ),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_rounded,
                        size: 48, color: MayaTheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading flags',
                        style: MayaTheme.bodyMedium
                            .copyWith(color: MayaTheme.error)),
                    const SizedBox(height: 8),
                    Text(err.toString(),
                        style:
                            MayaTheme.bodySmall.copyWith(color: Colors.white38),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final String flagKey;
  final bool value;

  const _FlagTile({
    super.key,
    required this.flagKey,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value
                  ? MayaTheme.neonEmerald.withValues(alpha: 0.2)
                  : MayaTheme.neonOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              value ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              color: value ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(flagKey, style: MayaTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  value ? 'Enabled' : 'Disabled',
                  style: MayaTheme.labelSmall.copyWith(
                    color: value ? MayaTheme.neonEmerald : MayaTheme.neonOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FlagsSnapshot {
  final Map<String, bool> flags;

  FlagsSnapshot({required this.flags});

  factory FlagsSnapshot.fromJson(Map<String, dynamic> json) {
    final flagsMap = json['flags'] as Map<String, dynamic>? ?? {};
    return FlagsSnapshot(
      flags: flagsMap.map((k, v) => MapEntry(k, v as bool)),
    );
  }
}

final flagsProvider = FutureProvider<FlagsSnapshot>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/flags');
  return FlagsSnapshot.fromJson(response);
});
