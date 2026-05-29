import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

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
              Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (provider.unread > 0)
                TextButton(
                  onPressed: () => context.read<NotificationsProvider>().markAllRead(),
                  child: const Text('Tout marquer lu'),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
        const SizedBox(height: 12),
        Center(child: Text(provider.error!, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(child: OutlinedButton(onPressed: () => context.read<NotificationsProvider>().load(), child: const Text('Réessayer'))),
      ]);
    }
    if (provider.items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.notifications_none_rounded, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        Center(child: Text('Aucune notification', style: TextStyle(color: AppTheme.textMuted))),
      ]);
    }
    return RefreshIndicator(
      onRefresh: () => context.read<NotificationsProvider>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: provider.items.length,
        separatorBuilder: (context2, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _NotificationTile(n: provider.items[i]),
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
  const _NotificationTile({required this.n});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppTheme.typeColors(n.type);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.isRead ? AppTheme.surface : AppTheme.itemHoverBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: n.isRead ? AppTheme.slate200 : AppTheme.itemHoverBg),
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
                  Text(n.body!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
                const SizedBox(height: 4),
                Text(_ago(n.createdAt), style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          if (!n.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 9, height: 9,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            ),
        ],
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
