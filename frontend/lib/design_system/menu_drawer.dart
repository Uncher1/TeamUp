// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_strings.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'brand_header.dart';
import 'gradient_avatar.dart';
import 'role_badge.dart';

/// A drawer destination the shell can switch to.
enum AppSection { home, createProject, findTeammates, myTeams, chat, notifications, settings }

class _MenuEntry {
  final AppSection section;
  final IconData icon;
  final String labelKey;
  const _MenuEntry(this.section, this.icon, this.labelKey);
}

const _entries = <_MenuEntry>[
  _MenuEntry(AppSection.home, Icons.home_outlined, 'nav.home'),
  _MenuEntry(AppSection.createProject, Icons.add_circle_outline, 'nav.createProject'),
  _MenuEntry(AppSection.findTeammates, Icons.search, 'nav.findTeammates'),
  _MenuEntry(AppSection.myTeams, Icons.groups_outlined, 'nav.myTeams'),
  _MenuEntry(AppSection.chat, Icons.chat_bubble_outline, 'nav.chat'),
  _MenuEntry(AppSection.notifications, Icons.notifications_outlined, 'nav.notifications'),
  _MenuEntry(AppSection.settings, Icons.settings_outlined, 'nav.settings'),
];

/// Hamburger drawer faithful to the mockup: brand header, profile row, 7 items.
class MenuDrawer extends StatelessWidget {
  final AppSection current;
  final ValueChanged<AppSection> onSelect;
  final VoidCallback? onProfileTap;
  const MenuDrawer({super.key, required this.current, required this.onSelect, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Drawer(
      backgroundColor: context.palette.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: BrandHeader(),
            ),
            if (user != null)
              InkWell(
                onTap: onProfileTap == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onProfileTap!();
                      },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(
                    children: [
                      GradientAvatar(name: user.fullName, size: 40, imageUrl: user.avatarUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(user.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                RoleBadge(role: user.role, size: 14),
                              ],
                            ),
                            Text(user.email,
                                style: TextStyle(fontSize: 12, color: context.palette.textMuted),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Divider(color: context.palette.slate100, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: [
                  for (final e in _entries) _item(context, e),
                ],
              ),
            ),
            Divider(color: context.palette.slate100, height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: context.palette.textMuted),
              title: Text(context.tr('nav.logout')),
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, _MenuEntry e) {
    final selected = e.section == current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? context.palette.itemHoverBg : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).pop();
            onSelect(e.section);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? context.palette.itemBorderHover : context.palette.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(e.icon,
                      size: 20, color: selected ? context.palette.primaryHover : context.palette.textMuted),
                ),
                const SizedBox(width: 16),
                Text(context.tr(e.labelKey),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: selected ? context.palette.primaryHover : context.palette.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
