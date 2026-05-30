import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/conversation.dart';
import '../../providers/chat_provider.dart';
import 'chat_thread_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  void _open(Conversation c) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatThreadScreen(conversation: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    if (provider.loadingConvs && provider.conversations.isEmpty) {
      return const SingleChildScrollView(child: SkeletonList());
    }
    if (provider.convError != null && provider.conversations.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 48, color: context.palette.textMuted),
        const SizedBox(height: 12),
        Center(child: Text(provider.convError!, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(child: OutlinedButton(onPressed: () => context.read<ChatProvider>().loadConversations(), child: const Text('Réessayer'))),
      ]);
    }
    if (provider.conversations.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'Aucune conversation',
        subtitle: 'Lance une discussion depuis un profil ou un projet.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ChatProvider>().loadConversations(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.conversations.length,
        separatorBuilder: (context, _) => Divider(color: context.palette.slate100, height: 1, indent: 76),
        itemBuilder: (_, i) {
          final c = provider.conversations[i];
          return _ConvTile(conv: c, onTap: () => _open(c));
        },
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GradientAvatar(name: conv.displayName, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(conv.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (conv.lastMessageAt != null)
                        Text(_ago(conv.lastMessageAt!),
                            style: TextStyle(fontSize: 11, color: context.palette.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(conv.lastMessage ?? 'Démarre la conversation',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: context.palette.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return "à l'instant";
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    return 'il y a ${d.inDays} j';
  }
}
