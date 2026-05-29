import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../design_system/ds_placeholder.dart';
import '../../design_system/menu_drawer.dart';
import '../../providers/notifications_provider.dart';
import '../feed/home_feed_screen.dart';

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
    });
  }

  String get _title {
    switch (_section) {
      case AppSection.home: return 'Home Feed';
      case AppSection.createProject: return 'Create Project';
      case AppSection.findTeammates: return 'Find Teammates';
      case AppSection.myTeams: return 'My Teams';
      case AppSection.chat: return 'Chat';
      case AppSection.notifications: return 'Notifications';
      case AppSection.settings: return 'Settings';
    }
  }

  Widget get _body {
    switch (_section) {
      case AppSection.home:
        return const HomeFeedScreen();
      case AppSection.createProject:
        return const DSPlaceholder(title: 'Create Project', icon: Icons.add_circle_outline);
      case AppSection.findTeammates:
        return const DSPlaceholder(title: 'Find Teammates', icon: Icons.search);
      case AppSection.myTeams:
        return const DSPlaceholder(title: 'My Teams', icon: Icons.groups_outlined);
      case AppSection.chat:
        return const DSPlaceholder(title: 'Chat', icon: Icons.chat_bubble_outline);
      case AppSection.notifications:
        return const DSPlaceholder(title: 'Notifications', icon: Icons.notifications_outlined);
      case AppSection.settings:
        return const DSPlaceholder(title: 'Settings', icon: Icons.settings_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsProvider>().unread;
    return Scaffold(
      key: _scaffoldKey,
      drawer: MenuDrawer(
        current: _section,
        onSelect: (s) => setState(() => _section = s),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: _title,
              unread: unread,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onBell: () => setState(() => _section = AppSection.notifications),
            ),
            Expanded(child: _body),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final int unread;
  final VoidCallback onMenu;
  final VoidCallback onBell;
  const _Header({required this.title, required this.unread, required this.onMenu, required this.onBell});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.slate100)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: AppTheme.textPrimary,
            onPressed: onMenu,
          ),
          const Spacer(),
          const BrandHeader(),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppTheme.textPrimary,
                onPressed: onBell,
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
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
