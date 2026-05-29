import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    ('Comment créer un projet ?', 'Va dans « Create Project » et remplis les informations.'),
    ('Comment trouver des coéquipiers ?', 'Utilise « Find Teammates » pour chercher par compétences.'),
    ('Comment rejoindre une équipe ?', 'Accepte une invitation ou postule à un projet.'),
    ('Comment modifier mon profil ?', 'Settings > la carte profil > Edit Profile.'),
    ('Comment supprimer mon compte ?', 'Settings > Danger Zone > Delete Account.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsScaffold(
      title: 'Help Center',
      children: [
        const SettingsSectionLabel('Questions fréquentes'),
        for (final (q, a) in _faq)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.slate200),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(q,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: p.textPrimary)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.topLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a, style: TextStyle(fontSize: 13, color: p.textMuted)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
