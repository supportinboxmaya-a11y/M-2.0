import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';
import '../../../shared/widgets/maya_loading.dart';
import '../../../shared/widgets/maya_error_view.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: MayaTheme.slate900,
          appBar: AppBar(
            title: const Text('Logs', style: MayaTheme.headlineSmall),
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
                  ref.invalidate(logsLLMProvider);
                  ref.invalidate(logsToolsProvider);
                },
              ),
            ],
            bottom: const TabBar(
              indicatorColor: MayaTheme.neonCyan,
              labelColor: MayaTheme.neonCyan,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(icon: Icon(Icons.smart_toy_rounded), text: 'LLM Logs'),
                Tab(icon: Icon(Icons.build_rounded), text: 'Tool Logs'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _LogsLLMTab(),
              _LogsToolsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogsLLMTab extends ConsumerWidget {
  const _LogsLLMTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(logsLLMProvider);

    return async.when(
      data: (data) {
        if (data.logs.isEmpty) {
          return const MayaEmptyState(
            'No LLM Logs',
            icon: Icons.smart_toy_rounded,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LLM Logs', style: MayaTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Recent LLM request/response logs',
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final log = data.logs[index];
                  return _LogEntryCard(log: log);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const MayaLoading(message: 'Loading LLM logs...'),
      error: (err, _) => MayaErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(logsLLMProvider),
      ),
    );
  }
}

class _LogsToolsTab extends ConsumerWidget {
  const _LogsToolsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(logsToolsProvider);

    return async.when(
      data: (data) {
        if (data.logs.isEmpty) {
          return const MayaEmptyState(
            'No Tool Logs',
            icon: Icons.build_rounded,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tool Logs', style: MayaTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Recent tool execution logs',
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final log = data.logs[index];
                  return _LogEntryCard(log: log);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const MayaLoading(message: 'Loading tool logs...'),
      error: (err, _) => MayaErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(logsToolsProvider),
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final LogEntry log;

  const _LogEntryCard({required this.log});

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    switch (log.level.toLowerCase()) {
      case 'error':
      case 'critical':
        levelColor = MayaTheme.error;
        break;
      case 'warning':
        levelColor = MayaTheme.neonOrange;
        break;
      case 'info':
        levelColor = MayaTheme.neonCyan;
        break;
      default:
        levelColor = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.level.toUpperCase(),
                  style: MayaTheme.labelSmall.copyWith(color: levelColor),
                ),
              ),
              const Spacer(),
              Text(
                log.provider,
                style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.message,
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            log.timestamp.toString().substring(0, 19),
            style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class LogsResponse {
  final List<LogEntry> logs;

  LogsResponse({required this.logs});

  factory LogsResponse.fromJson(Map<String, dynamic> json) {
    final logsList = json['logs'] as List<dynamic>? ?? [];
    return LogsResponse(
      logs: logsList
          .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LogEntry {
  final String level;
  final String message;
  final String provider;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    required this.provider,
    required this.timestamp,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: json['level'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

final logsLLMProvider = FutureProvider<LogsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/logs/llm');
  return LogsResponse.fromJson(response);
});

final logsToolsProvider = FutureProvider<LogsResponse>((ref) async {
  final api = ref.watch(mayaApiProvider);
  final response = await api.getJson('/api/v1/logs/tools');
  return LogsResponse.fromJson(response);
});
