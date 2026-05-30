import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/ds.dart';
import '../../providers/settings_provider.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  static const _push = [
    ('pushMessages', Icons.chat_bubble_outline, 'Nouveaux messages', 'Quand tu reçois un message'),
    ('pushTeamUpdates', Icons.groups_outlined, 'Mises à jour d\'équipe', 'Activité et changements d\'équipe'),
    ('pushProjectUpdates', Icons.work_outline, 'Mises à jour de projet', 'Jalons et tâches du projet'),
    ('pushMentions', Icons.star_outline, 'Mentions', 'Quand quelqu\'un te mentionne'),
  ];
  static const _email = [
    ('emailDigest', Icons.description_outlined, 'Résumé hebdomadaire', 'Synthèse de ton activité'),
    ('emailInvites', Icons.favorite_outline, 'Invitations d\'équipe', 'Nouvelles invitations'),
    ('emailNews', Icons.bolt_outlined, 'Nouveautés produit', 'Nouvelles fonctionnalités et astuces'),
  ];
  static const _sound = [
    ('sound', Icons.volume_up_outlined, 'Son', 'Jouer un son de notification'),
    ('vibration', Icons.vibration, 'Vibration', 'Vibrer lors des notifications'),
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
            for (final (key, icon, title, desc) in items)
              SettingToggleTile(
                icon: icon,
                label: title,
                desc: desc,
                value: master && s.toggle(key),
                onChanged: master
                    ? (v) => context.read<SettingsProvider>().setToggle(key, v)
                    : (_) {},
              ),
            const SizedBox(height: 8),
          ],
        );
    return SettingsScaffold(
      title: 'Notifications',
      children: [
        GradientBanner(
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Toutes les notifications',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('Interrupteur général',
                      style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
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
        group('Notifications push', 'Alertes sur ton appareil', _push),
        group('Notifications e-mail', 'Envoyées sur ton e-mail', _email),
        group('Son & vibration', "Préférences d'alerte", _sound),
      ],
    );
  }
}
