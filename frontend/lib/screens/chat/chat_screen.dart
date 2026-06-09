// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
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
        Center(child: OutlinedButton(onPressed: () => context.read<ChatProvider>().loadConversations(), child: Text(context.tr('feed.retry')))),
      ]);
    }
    if (provider.conversations.isEmpty) {
      return EmptyState(
        icon: Icons.forum_outlined,
        title: context.tr('chat.emptyTitle'),
        subtitle: context.tr('chat.emptySub'),
      );
    }
    final myId = context.read<AuthProvider>().user?.id ?? -1;
    return RefreshIndicator(
      onRefresh: () => context.read<ChatProvider>().loadConversations(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.conversations.length,
        separatorBuilder: (context, _) => Divider(color: context.palette.slate100, height: 1, indent: 82),
        itemBuilder: (_, i) {
          final c = provider.conversations[i];
          return _ConvTile(conv: c, myId: myId, onTap: () => _open(c));
        },
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final int myId;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.myId, required this.onTap});

  /// The preview line: "You: …" / "Alice: …" prefix + a label for media
  /// messages (Photo / File / Voice message / Poll).
  String _preview(BuildContext context) {
    String body;
    switch (conv.lastAttachmentType) {
      case 'image':
        body = context.tr('chat.lastImage');
        break;
      case 'file':
        body = context.tr('chat.lastFile');
        break;
      case 'audio':
        body = context.tr('chat.lastVoice');
        break;
      case 'gif':
        body = context.tr('gif.lastGif');
        break;
      case 'poll':
        body = context.tr('chat.lastPoll');
        break;
      default:
        body = (conv.lastMessage ?? '').trim();
    }
    if (body.isEmpty) return '';
    String? prefix;
    if (conv.lastSenderId != null && conv.lastSenderId == myId) {
      prefix = context.tr('chat.you');
    } else if (conv.isTeam && (conv.lastSenderName ?? '').isNotEmpty) {
      // First name only, keeps the line short.
      prefix = conv.lastSenderName!.trim().split(' ').first;
    }
    return prefix == null ? body : '$prefix : $body';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final preview = _preview(context);
    final hasMessage = preview.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GradientAvatar(
                name: conv.displayName,
                size: 52,
                imageUrl: conv.avatarImageUrl,
                presenceStatus: conv.avatarStatus,
                isTeam: conv.isTeam),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(conv.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (conv.lastMessageAt != null) ...[
                        const SizedBox(width: 8),
                        Text(timeAgo(context, conv.lastMessageAt!),
                            style: TextStyle(fontSize: 11, color: p.textMuted)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasMessage ? preview : context.tr('chat.start'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: p.textMuted,
                      fontStyle: hasMessage ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
