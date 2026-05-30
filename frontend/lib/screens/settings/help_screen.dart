import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  static const _faq = [
    ('Comment créer un projet ?', 'Va dans « Create Project » et remplis les informations.'),
    ('Comment trouver des coéquipiers ?', 'Utilise « Find Teammates » pour chercher par compétences.'),
    ('Comment rejoindre une équipe ?', 'Accepte une invitation ou postule à un projet.'),
    ('Comment modifier mon profil ?', 'Settings > la carte profil > Edit Profile.'),
    ('Comment supprimer mon compte ?', 'Settings > Danger Zone > Delete Account.'),
  ];

  // Quick action cards: (label, icon, bg, fg). Colors match the mockup's
  // tailwind 100/600 pairs (indigo / emerald / amber / rose).
  static const _actions = [
    ('Nous contacter', Icons.chat_bubble_outline, Color(0xFFE0E7FF), Color(0xFF4F46E5)),
    ("Guide d'utilisation", Icons.description_outlined, Color(0xFFD1FAE5), Color(0xFF059669)),
    ("Noter l'app", Icons.star_outline, Color(0xFFFEF3C7), Color(0xFFD97706)),
    ('Site web', Icons.open_in_new, Color(0xFFFFE4E6), Color(0xFFE11D48)),
  ];

  String _query = '';

  void _stub(String label) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('« $label » — bientôt disponible.')),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = _query.trim().toLowerCase();
    final faq = q.isEmpty
        ? _faq
        : _faq
            .where((f) => f.$1.toLowerCase().contains(q) || f.$2.toLowerCase().contains(q))
            .toList();

    return SettingsScaffold(
      title: 'Help Center',
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: "Rechercher dans l'aide...",
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        const SettingsSectionLabel('Actions rapides'),
        Row(children: [
          Expanded(child: _ActionCard(data: _actions[0], onTap: () => _stub(_actions[0].$1))),
          const SizedBox(width: 12),
          Expanded(child: _ActionCard(data: _actions[1], onTap: () => _stub(_actions[1].$1))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _ActionCard(data: _actions[2], onTap: () => _stub(_actions[2].$1))),
          const SizedBox(width: 12),
          Expanded(child: _ActionCard(data: _actions[3], onTap: () => _stub(_actions[3].$1))),
        ]),
        const SizedBox(height: 20),
        const SettingsSectionLabel('Questions fréquentes'),
        if (faq.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Aucun résultat pour « $_query ».',
                style: TextStyle(fontSize: 13, color: p.textMuted)),
          ),
        for (final (question, answer) in faq)
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
                  title: Text(question,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: p.textPrimary)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.topLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(answer, style: TextStyle(fontSize: 13, color: p.textMuted)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final (String, IconData, Color, Color) data;
  final VoidCallback onTap;
  const _ActionCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, icon, bg, fg) = data;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.slate200),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: p.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
