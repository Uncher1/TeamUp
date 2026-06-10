// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../design_system/menu_drawer.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';
import '../profile/friends_screen.dart';

/// Maps a notification type to the shell section to open when it's tapped.
AppSection _sectionFor(String type) {
  switch (type) {
    case 'message':
      return AppSection.chat;
    case 'application':
    case 'team_join':
    case 'team_invite':
    case 'project_update':
    case 'project_complete':
      return AppSection.myTeams;
    default:
      return AppSection.home;
  }
}

/// Section to open for a notification, preferring its link target (more reliable
/// than the type). Friend notifications are handled separately (they push the
/// Friends screen rather than switching section) - see [openFriendNotification].
AppSection sectionForNotification(AppNotification n) {
  switch (n.linkType) {
    case 'conversation':
      return AppSection.chat;
    case 'project':
    case 'team_invite':
      return AppSection.myTeams;
    default:
      return _sectionFor(n.type);
  }
}

/// True when tapping [n] should open the Friends screen instead of a section.
bool isFriendNotification(AppNotification n) => n.linkType == 'friends';

/// Pushes the Friends screen on [nav], opening the Requests tab for an incoming
/// request and the Friends tab for an accepted one.
void openFriendNotification(NavigatorState nav, AppNotification n) {
  nav.push(MaterialPageRoute(
    builder: (_) => FriendsScreen(initialTab: n.type == 'friend_request' ? 1 : 0),
  ));
}

class NotificationsInboxScreen extends StatefulWidget {
  /// Called when a notification is tapped, to switch the shell to its section.
  final void Function(AppSection section)? onNavigate;
  const NotificationsInboxScreen({super.key, this.onNavigate});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(context.tr('nav.notifications'), style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (provider.unread > 0)
                TextButton(
                  onPressed: () => context.read<NotificationsProvider>().markAllRead(),
                  child: Text(context.tr('ninbox.markAll')),
                ),
            ],
          ),
        ),
        Expanded(child: _body(provider)),
      ],
    );
  }

  Widget _body(NotificationsProvider provider) {
    if (provider.loading && provider.items.isEmpty) {
      return const SingleChildScrollView(child: SkeletonList());
    }
    if (provider.error != null && provider.items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 48, color: context.palette.textMuted),
        const SizedBox(height: 12),
        Center(child: Text(provider.error!, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(child: OutlinedButton(onPressed: () => context.read<NotificationsProvider>().load(), child: Text(context.tr('feed.retry')))),
      ]);
    }
    if (provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none,
        title: context.tr('popup.empty'),
        subtitle: context.tr('ninbox.emptySub'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<NotificationsProvider>().load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: provider.items.length,
        separatorBuilder: (context2, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _NotificationTile(
          n: provider.items[i],
          onTap: () {
            final n = provider.items[i];
            context.read<NotificationsProvider>().markRead(n.id);
            if (isFriendNotification(n)) {
              openFriendNotification(Navigator.of(context), n);
            } else {
              widget.onNavigate?.call(sectionForNotification(n));
            }
          },
        ),
      ),
    );
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'team_invite': return Icons.group_add_outlined;
    case 'message': return Icons.chat_bubble_outline;
    case 'project_update': return Icons.work_outline;
    case 'mention': return Icons.alternate_email;
    case 'team_join': return Icons.favorite_border;
    case 'project_complete': return Icons.check_circle_outline;
    case 'application': return Icons.person_add_alt_1;
    default: return Icons.notifications_none_rounded;
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppTheme.typeColors(n.type);
    return PressableScale(
      onPressed: onTap,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.isRead ? context.palette.surface : context.palette.itemHoverBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: n.isRead ? context.palette.slate200 : context.palette.itemHoverBg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(_iconFor(n.type), size: 20, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (n.body != null && n.body!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(n.body!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.palette.textMuted)),
                ],
                const SizedBox(height: 4),
                Text(timeAgo(context, n.createdAt), style: TextStyle(fontSize: 11, color: context.palette.textMuted)),
              ],
            ),
          ),
          if (!n.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 9, height: 9,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            ),
        ],
      ),
      ),
    );
  }

}
