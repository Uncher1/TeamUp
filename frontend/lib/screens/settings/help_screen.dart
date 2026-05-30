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
    (
      'Comment créer un projet ?',
      'Ouvre « Create Project » depuis le menu. Donne un titre et une description, '
          'choisis un type, puis ajoute les compétences requises avec un poids de 1 à 5 '
          '(plus le poids est élevé, plus la compétence pèse dans le matching) et des '
          'centres d\'intérêt. Une fois publié, ton projet apparaît dans « My Teams » et '
          'peut recevoir des candidatures.'
    ),
    (
      'Comment fonctionne le matching de coéquipiers ?',
      'Le score combine deux mesures : 70 % la correspondance de compétences (tes niveaux '
          'pondérés par les poids demandés par le projet) et 30 % la correspondance d\'intérêts '
          '(intérêts en commun). Chaque candidat reçoit un score en %, et la liste est classée '
          'du plus pertinent au moins pertinent.'
    ),
    (
      'Comment trouver des coéquipiers pour mon projet ?',
      'Va dans « Find Teammates », choisis l\'un de tes projets, et la liste des profils les '
          'mieux classés s\'affiche avec leur score de compatibilité. Tu peux filtrer par nom '
          'avec la barre de recherche, puis contacter un profil via « Message ».'
    ),
    (
      'Comment postuler à un projet / rejoindre une équipe ?',
      'Ouvre un projet qui t\'intéresse et postule. Le porteur du projet voit ta candidature '
          'dans la section « Candidatures » et peut l\'accepter ou la refuser. S\'il accepte, tu '
          'rejoins l\'équipe et tu es notifié.'
    ),
    (
      'Comment gérer les candidatures reçues ?',
      'Sur la page de détail d\'un projet dont tu es le porteur, la section « Candidatures » '
          'liste les profils ayant postulé, avec un bouton Accepter et Refuser. Le candidat est '
          'notifié de ta décision.'
    ),
    (
      'Comment fonctionne la messagerie ?',
      'Le chat est en temps réel : les messages arrivent instantanément sans rafraîchir. Tu '
          'peux discuter en direct avec un profil (depuis Find Teammates) ou dans la conversation '
          'd\'un projet. Retrouve toutes tes discussions dans l\'onglet « Chat ».'
    ),
    (
      'À quoi servent les notifications ?',
      'Tu es notifié quand quelqu\'un postule à ton projet, quand ta candidature est acceptée, '
          'et quand tu reçois un message. La cloche en haut affiche le nombre de notifications '
          'non lues ; ouvre « Notifications » pour tout voir.'
    ),
    (
      'Comment renseigner mes compétences et niveaux ?',
      'Dans « Edit Profile », ajoute tes compétences et règle ton niveau de 1 (débutant) à 5 '
          '(expert) pour chacune. Ces niveaux alimentent directement l\'algorithme de matching, '
          'donc plus ton profil est précis, plus les suggestions sont pertinentes.'
    ),
    (
      'Comment contrôler ma confidentialité ?',
      'Dans Settings > Confidentialité, tu choisis qui peut voir ton profil, si tu apparais '
          'dans la recherche, qui peut te contacter, et si ton statut en ligne est visible.'
    ),
    (
      'Comment activer le mode sombre ou changer la couleur ?',
      'Settings > Préférences : active « Mode sombre » pour basculer toute l\'app, et ouvre '
          '« Thème » pour choisir une couleur d\'accent parmi 8. Le changement s\'applique '
          'immédiatement et est mémorisé.'
    ),
    (
      'Comment changer mon e-mail ou mon mot de passe ?',
      'Settings > Compte : « Adresse e-mail » pour mettre à jour ton e-mail, « Mot de passe » '
          'pour le changer (un nouveau mot de passe doit faire au moins 8 caractères et respecter '
          'les recommandations affichées).'
    ),
    (
      'Comment supprimer mon compte ?',
      'Settings > Danger Zone > « Supprimer le compte ». Cette action est irréversible : ton '
          'profil, tes projets, tes adhésions et tes messages sont définitivement effacés. Une '
          'case de confirmation est requise avant de valider.'
    ),
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
