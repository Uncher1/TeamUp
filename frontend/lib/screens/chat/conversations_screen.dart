import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/conversation.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ChatProvider>().loadConversations(),
        child: _body(provider),
      ),
    );
  }

  Widget _body(ChatProvider provider) {
    if (provider.loadingConvs && provider.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.convError != null && provider.conversations.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
        const SizedBox(height: 12),
        Center(child: Text(provider.convError!, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: () => context.read<ChatProvider>().loadConversations(),
            child: const Text('Réessayer'),
          ),
        ),
      ]);
    }
    if (provider.conversations.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(
          child: Text(
            'Aucune conversation.\nPostule à un projet pour démarrer !',
            textAlign: TextAlign.center,
          ),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.conversations.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _ConvTile(conv: provider.conversations[i]),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  const _ConvTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
        child: Icon(
          conv.type == 'project'
              ? Icons.workspaces_outlined
              : Icons.person_outline,
          color: AppTheme.primary,
        ),
      ),
      title: Text(conv.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: conv.lastMessage != null
          ? Text(
              conv.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            )
          : null,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conv),
        ));
      },
    );
  }
}
