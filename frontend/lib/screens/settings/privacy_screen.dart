import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/ds.dart';
import '../../providers/settings_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  // (key, icon, label, desc)
  static const _visibility = [
    ('profilePublic', Icons.visibility_outlined, 'Profil public', 'Tout le monde peut voir ton profil'),
    ('showOnlineStatus', Icons.bolt_outlined, 'Statut en ligne', 'Les autres voient quand tu es en ligne'),
    ('showLastSeen', Icons.schedule_outlined, 'Dernière connexion', 'Affiche ta dernière activité'),
  ];
  static const _team = [
    ('allowTeamInvites', Icons.group_add_outlined, 'Invitations d\'équipe', 'Recevoir des invitations à rejoindre des équipes'),
    ('showProjects', Icons.work_outline, 'Afficher mes projets', 'Affiche tes projets sur ton profil'),
    ('appearInSearch', Icons.search, 'Apparaître dans la recherche', 'Être trouvé par compétences'),
  ];
  static const _comm = [
    ('allowMessages', Icons.chat_bubble_outline, 'Autoriser les messages', 'Recevoir des messages de tout le monde'),
    ('showEmail', Icons.mail_outline, 'Afficher l\'e-mail', 'Affiche ton e-mail sur ton profil'),
    ('showPhone', Icons.phone_outlined, 'Afficher le téléphone', 'Affiche ton téléphone sur ton profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    Widget group(String label, List<(String, IconData, String, String)> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionLabel(label),
            for (final (key, icon, title, desc) in items)
              SettingToggleTile(
                icon: icon,
                label: title,
                desc: desc,
                value: s.toggle(key),
                onChanged: (v) => context.read<SettingsProvider>().setToggle(key, v),
              ),
            const SizedBox(height: 8),
          ],
        );
    return SettingsScaffold(
      title: 'Privacy',
      children: [
        group('Visibilité du profil', _visibility),
        group('Équipes & projets', _team),
        group('Communication', _comm),
      ],
    );
  }
}
