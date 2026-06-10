// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../design_system/ds.dart';
import '../../providers/settings_provider.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  // (settingKey, icon, labelKey, descKey)
  static const _push = [
    ('pushMessages', Icons.chat_bubble_outline, 'notif.messages', 'notif.messagesD'),
    ('pushTeamUpdates', Icons.groups_outlined, 'notif.teamUpdates', 'notif.teamUpdatesD'),
    ('pushProjectUpdates', Icons.work_outline, 'notif.projectUpdates', 'notif.projectUpdatesD'),
    ('pushMentions', Icons.star_outline, 'notif.mentions', 'notif.mentionsD'),
  ];
  static const _email = [
    ('emailDigest', Icons.description_outlined, 'notif.digest', 'notif.digestD'),
    ('emailInvites', Icons.favorite_outline, 'notif.invites', 'notif.invitesD'),
    ('emailNews', Icons.bolt_outlined, 'notif.news', 'notif.newsD'),
  ];
  static const _sound = [
    ('sound', Icons.volume_up_outlined, 'notif.sound', 'notif.soundD'),
    ('vibration', Icons.vibration, 'notif.vibration', 'notif.vibrationD'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final master = s.toggle('allNotifications');
    Widget group(String label, String subtitle,
            List<(String, IconData, String, String)> items) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionLabel(label, subtitle: subtitle),
            for (final (key, icon, titleKey, descKey) in items)
              SettingToggleTile(
                icon: icon,
                label: context.tr(titleKey),
                desc: context.tr(descKey),
                value: master && s.toggle(key),
                onChanged: master
                    ? (v) => context.read<SettingsProvider>().setToggle(key, v)
                    : (_) {},
              ),
            const SizedBox(height: 8),
          ],
        );
    return SettingsScaffold(
      title: context.tr('nav.notifications'),
      children: [
        GradientBanner(
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr('notif.master'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(context.tr('notif.masterSub'),
                      style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
                ]),
              ),
              Switch(
                value: master,
                onChanged: (v) => context.read<SettingsProvider>().setToggle('allNotifications', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        group(context.tr('notif.gPush'), context.tr('notif.gPushSub'), _push),
        group(context.tr('notif.gEmail'), context.tr('notif.gEmailSub'), _email),
        group(context.tr('notif.gSound'), context.tr('notif.gSoundSub'), _sound),
      ],
    );
  }
}
