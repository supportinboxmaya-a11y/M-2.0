import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

class CommunicationToolsScreen extends ConsumerStatefulWidget {
  const CommunicationToolsScreen({super.key});

  @override
  ConsumerState<CommunicationToolsScreen> createState() =>
      _CommunicationToolsScreenState();
}

class _CommunicationToolsScreenState
    extends ConsumerState<CommunicationToolsScreen>
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
          title:
              const Text('Communication Tools', style: MayaTheme.headlineSmall),
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
              Tab(icon: Icon(Icons.email_rounded), text: 'Email'),
              Tab(icon: Icon(Icons.webhook_rounded), text: 'Webhook'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _EmailToolTab(),
            _WebhookToolTab(),
          ],
        ),
      ),
    );
  }
}

class _EmailToolTab extends ConsumerWidget {
  const _EmailToolTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Email Tool', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Send emails via SMTP. Configure SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM in .env.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          MayaEmptyState(
            'Endpoint not connected',
            icon: Icons.email_rounded,
            actionLabel: 'Retry',
            onAction: () {},
          ),
        ],
      ),
    );
  }
}

class _WebhookToolTab extends ConsumerWidget {
  const _WebhookToolTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Webhook Tool', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Send messages to Slack, Discord, or generic webhooks. Configure WEBHOOK_SLACK_URL, WEBHOOK_DISCORD_URL, WEBHOOK_GENERIC_URL in .env.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          MayaEmptyState(
            'Endpoint not connected',
            icon: Icons.webhook_rounded,
            actionLabel: 'Retry',
            onAction: () {},
          ),
        ],
      ),
    );
  }
}
