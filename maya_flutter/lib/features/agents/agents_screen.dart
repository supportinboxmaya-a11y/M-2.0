import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/theme/maya_theme.dart';
import '../../../core/services/maya_api.dart';
import 'agents_models.dart';
import 'agents_providers.dart';

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(agentsListProvider);
        ref.invalidate(agentsMessagesProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title:
              const Text('Multi-Agent System', style: MayaTheme.headlineSmall),
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
                ref.invalidate(agentsListProvider);
                ref.invalidate(agentsMessagesProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.people_rounded), text: 'Agents'),
              Tab(
                  icon: Icon(Icons.account_tree_rounded),
                  text: 'Orchestration'),
              Tab(icon: Icon(Icons.message_rounded), text: 'Messages'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAgentsTab(),
            _buildOrchestrationTab(),
            _buildMessagesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentsTab() {
    final agentsAsync = ref.watch(agentsListProvider);

    return agentsAsync.when(
      data: (response) {
        if (response.agents.isEmpty) {
          return const Center(
            child: Text('No agents found', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.agents.length,
          itemBuilder: (context, index) {
            final agent = response.agents[index];
            return _AgentTile(agent: agent);
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
            Text('Error loading agents',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrchestrationTab() {
    final agentsAsync = ref.watch(agentsListProvider);
    final goalController =
        TextEditingController(text: 'Build a todo app with Flutter');

    return agentsAsync.when(
      data: (response) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: MayaTheme.glassCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Orchestrate Goal',
                        style: MayaTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: goalController,
                      style: MayaTheme.bodyMedium,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Enter a goal to orchestrate across agents...',
                        hintStyle: MayaTheme.bodyMedium
                            .copyWith(color: Colors.white38),
                        filled: true,
                        fillColor: MayaTheme.slate700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _orchestrateGoal(goalController.text.trim()),
                        icon: const Icon(Icons.psychology_rounded),
                        label: const Text('Plan & Assign'),
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
              Consumer(
                builder: (context, ref, _) {
                  final orchestrationAsync =
                      ref.watch(agentsOrchestrateProvider);

                  return orchestrationAsync.when(
                    data: (result) => _OrchestrationResultCard(result: result),
                    loading: () => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: MayaTheme.glassCard(),
                      child: const Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation(MayaTheme.neonCyan)),
                      ),
                    ),
                    error: (err, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: MayaTheme.glassCard(),
                      child: Column(
                        children: [
                          const Icon(Icons.error_rounded,
                              size: 48, color: MayaTheme.error),
                          const SizedBox(height: 16),
                          Text('Orchestration error',
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
              const SizedBox(height: 24),
              const Text('Available Agents', style: MayaTheme.titleMedium),
              const SizedBox(height: 12),
              ...response.agents
                  .map((agent) => _AgentReferenceTile(agent: agent)),
            ],
          ),
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
            Text('Error loading agents',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    final messagesAsync = ref.watch(agentsMessagesProvider);

    return messagesAsync.when(
      data: (response) {
        if (response.messages.isEmpty) {
          return const Center(
            child: Text('No messages yet', style: MayaTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.messages.length,
          itemBuilder: (context, index) {
            final msg = response.messages[index];
            return _MessageTile(message: msg);
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
            Text('Error loading messages',
                style: MayaTheme.bodyMedium.copyWith(color: MayaTheme.error)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Future<void> _orchestrateGoal(String goal) async {
    if (goal.isEmpty) return;
    ref.read(agentsOrchestrateGoalProvider.notifier).state = goal;
    ref.invalidate(agentsOrchestrateProvider);
  }
}

class _AgentTile extends ConsumerWidget {
  final AgentInfo agent;

  const _AgentTile({required this.agent});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'healthy':
        return MayaTheme.neonEmerald;
      case 'degraded':
        return MayaTheme.neonOrange;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHealthy = agent.status == 'healthy';
    final totalTasks = agent.ok + agent.errors;
    final lastActive = agent.lastActive != null
        ? DateTime.fromMillisecondsSinceEpoch(
                (agent.lastActive! * 1000).round())
            .toString()
            .substring(11, 19)
        : 'Never';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MayaTheme.glassCard(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor(agent.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: _getStatusColor(agent.status),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: MayaTheme.titleMedium),
                  Text(agent.type,
                      style:
                          MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(agent.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(agent.status)),
                  ),
                  child: Text(agent.status.toUpperCase(),
                      style: MayaTheme.labelSmall
                          .copyWith(color: _getStatusColor(agent.status))),
                ),
                const SizedBox(height: 4),
                Text('Last: $lastActive',
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentReferenceTile extends StatelessWidget {
  final AgentInfo agent;

  const _AgentReferenceTile({required this.agent});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'healthy':
        return MayaTheme.neonEmerald;
      case 'degraded':
        return MayaTheme.neonOrange;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: MayaTheme.glassCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(agent.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              agent.status == 'healthy'
                  ? Icons.smart_toy_rounded
                  : Icons.warning_rounded,
              color: _getStatusColor(agent.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.name, style: MayaTheme.bodyMedium),
                Text(agent.description,
                    style: MayaTheme.bodySmall.copyWith(color: Colors.white54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(agent.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${agent.ok}/${agent.ok + agent.errors} OK',
                style: MayaTheme.labelSmall
                    .copyWith(color: _getStatusColor(agent.status))),
          ),
        ],
      ),
    );
  }
}

class _OrchestrationResultCard extends StatelessWidget {
  final AgentsOrchestrateResponse result;

  const _OrchestrationResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: MayaTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Orchestration Plan', style: MayaTheme.titleMedium),
          const SizedBox(height: 12),
          Text(result.plan, style: MayaTheme.bodyMedium),
          const SizedBox(height: 16),
          const Text('Assignments', style: MayaTheme.labelMedium),
          const SizedBox(height: 8),
          if (result.assignments.isEmpty)
            Text('No assignments made',
                style: MayaTheme.bodyMedium.copyWith(color: Colors.white54))
          else
            ...result.assignments
                .map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: MayaTheme.glassCard(),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MayaTheme.neonCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.assignment_rounded,
                                color: MayaTheme.neonCyan, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Agent: ${a.agentId}',
                                    style: MayaTheme.bodyMedium),
                                Text('Task: ${a.task}',
                                    style: MayaTheme.bodySmall
                                        .copyWith(color: Colors.white54)),
                                Text('Status: ${a.status}',
                                    style: MayaTheme.labelSmall
                                        .copyWith(color: MayaTheme.neonCyan)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final AgentMessage message;

  const _MessageTile({required this.message});

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
                  color: MayaTheme.neonViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.message_rounded,
                    color: MayaTheme.neonViolet, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${message.fromAgent} → ${message.toAgent}',
                        style: MayaTheme.bodyMedium),
                    Text(message.type,
                        style: MayaTheme.bodySmall
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              Text(
                DateTime.parse(message.timestamp).toString().substring(11, 19),
                style: MayaTheme.bodySmall.copyWith(color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message.content, style: MayaTheme.bodyMedium),
        ],
      ),
    );
  }
}
