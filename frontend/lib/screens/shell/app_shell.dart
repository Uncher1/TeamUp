import 'package:flutter/material.dart';

import '../common/coming_soon.dart';
import '../profile/profile_screen.dart';
import '../projects/projects_feed_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    ProjectsFeedScreen(),
    ComingSoon(
      title: 'Matching',
      icon: Icons.auto_awesome_rounded,
      note: 'Le matching arrive en J2.',
    ),
    ComingSoon(
      title: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      note: 'Le chat temps réel arrive en J3.',
    ),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.workspaces_outline),
              selectedIcon: Icon(Icons.workspaces),
              label: 'Projets'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Matching'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Messages'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}
