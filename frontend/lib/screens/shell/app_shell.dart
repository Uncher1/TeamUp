import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../design_system/menu_drawer.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';
import '../chat/chat_screen.dart';
import '../feed/home_feed_screen.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../profile/profile_screen.dart';
import '../projects/create_project_screen.dart';
import '../settings/settings_screen.dart';
import '../teammates/find_teammates_screen.dart';
import '../teams/my_teams_screen.dart';

// ---------------------------------------------------------------------------
// Helpers shared between shell and popup
// ---------------------------------------------------------------------------

/// Maps a notification type to the shell section to navigate to.
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

IconData _iconFor(String type) {
  switch (type) {
    case 'team_invite':
      return Icons.group_add_outlined;
    case 'message':
      return Icons.chat_bubble_outline;
    case 'project_update':
      return Icons.work_outline;
    case 'mention':
      return Icons.alternate_email;
    case 'team_join':
      return Icons.favorite_border;
    case 'project_complete':
      return Icons.check_circle_outline;
    case 'application':
      return Icons.person_add_alt_1;
    default:
      return Icons.notifications_none_rounded;
  }
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return "à l'instant";
  if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
  if (d.inHours < 24) return 'il y a ${d.inHours} h';
  return 'il y a ${d.inDays} j';
}

// ---------------------------------------------------------------------------
// Custom PopupMenuEntry: wraps a full widget tree in one non-interactive item
// ---------------------------------------------------------------------------

class _PopupCard extends PopupMenuEntry<Never> {
  final Widget child;
  const _PopupCard({required this.child});

  @override
  double get height => 0; // showMenu uses this for height checks; 0 is fine here

  @override
  bool represents(Never? value) => false;

  @override
  State<_PopupCard> createState() => _PopupCardState();
}

class _PopupCardState extends State<_PopupCard> {
  @override
  Widget build(BuildContext context) => widget.child;
}

// ---------------------------------------------------------------------------
// App shell
// ---------------------------------------------------------------------------

/// App shell faithful to the mockup: a top header (menu button, brand, bell)
/// over a body that switches by [AppSection], with the hamburger [MenuDrawer].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AppSection _section = AppSection.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().refreshUnread();
      context.read<SettingsProvider>().load();
    });
  }

  String get _title {
    switch (_section) {
      case AppSection.home:
        return 'Accueil';
      case AppSection.createProject:
        return 'Créer un projet';
      case AppSection.findTeammates:
        return 'Trouver des coéquipiers';
      case AppSection.myTeams:
        return 'Mes équipes';
      case AppSection.chat:
        return 'Messages';
      case AppSection.notifications:
        return 'Notifications';
      case AppSection.settings:
        return 'Réglages';
    }
  }

  Widget get _body {
    switch (_section) {
      case AppSection.home:
        return const HomeFeedScreen();
      case AppSection.createProject:
        return const CreateProjectScreen();
      case AppSection.findTeammates:
        return const FindTeammatesScreen();
      case AppSection.myTeams:
        return const MyTeamsScreen();
      case AppSection.chat:
        return const ChatScreen();
      case AppSection.notifications:
        return NotificationsInboxScreen(
          onNavigate: (s) => setState(() => _section = s),
        );
      case AppSection.settings:
        return const SettingsScreen();
    }
  }

  void _navigateSection(AppSection s) => setState(() => _section = s);

  /// Opens the notification popup anchored near the top-right bell.
  Future<void> _showNotificationPopup(BuildContext bellContext) async {
    final provider = context.read<NotificationsProvider>();

    // Ensure notifications are loaded
    if (provider.items.isEmpty) {
      await provider.load();
    }

    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    // Position the popup: right-aligned, just below the header
    const double popupWidth = 320;
    const double rightMargin = 8;
    final double left = screenWidth - popupWidth - rightMargin;

    await showMenu<Never>(
      context: context,
      position: RelativeRect.fromLTRB(left, kToolbarHeight + 4, rightMargin, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.palette.surface,
      constraints: const BoxConstraints(maxWidth: popupWidth, minWidth: popupWidth),
      items: [
        _PopupCard(
          child: _NotificationPopupContent(
            onNavigateSection: _navigateSection,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsProvider>().unread;
    return Scaffold(
      key: _scaffoldKey,
      drawer: MenuDrawer(
        current: _section,
        onSelect: (s) => setState(() => _section = s),
        onProfileTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: _title,
              unread: unread,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onBell: _showNotificationPopup,
            ),
            Expanded(child: _body),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String title;
  final int unread;
  final VoidCallback onMenu;
  // Receives the bell's BuildContext so the popup can position itself
  final Future<void> Function(BuildContext bellContext) onBell;

  const _Header({
    required this.title,
    required this.unread,
    required this.onMenu,
    required this.onBell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(bottom: BorderSide(color: context.palette.slate100)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: context.palette.textPrimary,
            onPressed: onMenu,
          ),
          const Spacer(),
          const BrandHeader(),
          const Spacer(),
          Stack(
            children: [
              Builder(
                builder: (bellContext) => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: context.palette.textPrimary,
                  onPressed: () => onBell(bellContext),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification popup content (stateful to react to provider changes)
// ---------------------------------------------------------------------------

class _NotificationPopupContent extends StatelessWidget {
  final void Function(AppSection) onNavigateSection;

  const _NotificationPopupContent({required this.onNavigateSection});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    final palette = context.palette;
    final recent = provider.items.take(5).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Header row ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),
                if (provider.unread > 0)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      context.read<NotificationsProvider>().markAllRead();
                    },
                    child: Text(
                      'Tout lire',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: palette.slate100),

          // ---- Notification rows or empty state ----
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Text(
                'Aucune notification',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: palette.textMuted),
              ),
            )
          else
            for (final n in recent)
              _PopupNotifRow(
                n: n,
                onTap: () {
                  final section = _sectionFor(n.type);
                  context.read<NotificationsProvider>().markRead(n.id);
                  Navigator.pop(context);
                  onNavigateSection(section);
                },
              ),

          Divider(height: 1, color: palette.slate100),

          // ---- Footer ----
          InkWell(
            onTap: () {
              Navigator.pop(context);
              onNavigateSection(AppSection.notifications);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                'Voir toutes les notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupNotifRow extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;

  const _PopupNotifRow({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (bg, fg) = AppTheme.typeColors(n.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.isRead ? Colors.transparent : palette.itemHoverBg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(_iconFor(n.type), size: 16, color: fg),
            ),
            const SizedBox(width: 10),
            // Title + relative time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ago(n.createdAt),
                    style: TextStyle(fontSize: 11, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!n.isRead)
              Container(
                margin: const EdgeInsets.only(left: 6, top: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
