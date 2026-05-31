// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/settings_provider.dart';

/// GDPR-oriented privacy policy. Content is kept here (not in the main string
/// table) because it is long-form; the active language picks FR or EN.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().language;
    final sections = lang == 'fr' ? _fr : _en;
    final p = context.palette;
    return SettingsScaffold(
      title: context.tr('set.privacyPolicy'),
      children: [
        Text(
          lang == 'fr'
              ? 'Dernière mise à jour : 2026. Cette politique explique quelles données TeamUp collecte, pourquoi, et tes droits.'
              : 'Last updated: 2026. This policy explains what data TeamUp collects, why, and your rights.',
          style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.5),
        ),
        const SizedBox(height: 16),
        for (final s in sections) ...[
          Text(s.$1,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 6),
          Text(s.$2, style: TextStyle(fontSize: 13.5, height: 1.55, color: p.textMuted)),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

const List<(String, String)> _en = [
  ('1. Data we collect',
      'Account: email and full name. Profile (optional): bio, school, department, year, location, skills, interests, avatar, phone and social links. Content you create: projects, applications, posts, comments, messages, polls and votes.'),
  ('2. Why we use it',
      'To provide the service: authenticate you, match you with teammates and projects by skills/interests, let you post, chat and build teams, and send transactional emails (verification and security codes).'),
  ('3. Legal basis',
      'Performance of our service to you (the features you use) and your consent, given when you create an account.'),
  ('4. Who processes your data',
      'We do not sell your data and show no advertising. Technical providers act only on our behalf: Render (API hosting), Aiven (database), Google (Google Sign-In) and Google Gmail (sending emails).'),
  ('5. How long we keep it',
      'Your data is kept while your account exists. Deleting your account permanently erases your profile, projects, messages and related data.'),
  ('6. Your rights',
      'Access and rectification: view and edit your profile in the app. Erasure: delete your account in Settings. Portability: export your data as JSON (Settings → Download my data). You may also contact us to object to processing.'),
  ('7. Security',
      'Passwords are stored hashed (never in clear text), traffic is encrypted over HTTPS, and access requires authentication.'),
  ('8. Minors',
      'TeamUp is intended for students. If you are below the age of digital consent in your country, please use it only with a parent or guardian’s agreement.'),
  ('9. Contact',
      'Questions or requests: teamup.team28@gmail.com'),
];

const List<(String, String)> _fr = [
  ('1. Données que nous collectons',
      'Compte : e-mail et nom complet. Profil (facultatif) : bio, école, filière, année, localisation, compétences, centres d’intérêt, photo, téléphone et liens. Contenu que tu crées : projets, candidatures, publications, commentaires, messages, sondages et votes.'),
  ('2. Pourquoi nous les utilisons',
      'Pour fournir le service : t’authentifier, te mettre en relation avec des équipiers et projets selon tes compétences/intérêts, te permettre de publier, discuter et monter des équipes, et envoyer des e-mails transactionnels (codes de vérification et de sécurité).'),
  ('3. Base légale',
      'L’exécution du service que tu utilises et ton consentement, donné lors de la création de ton compte.'),
  ('4. Qui traite tes données',
      'Nous ne vendons pas tes données et n’affichons aucune publicité. Des prestataires techniques agissent uniquement pour notre compte : Render (hébergement de l’API), Aiven (base de données), Google (connexion Google) et Google Gmail (envoi des e-mails).'),
  ('5. Durée de conservation',
      'Tes données sont conservées tant que ton compte existe. La suppression de ton compte efface définitivement ton profil, tes projets, tes messages et les données associées.'),
  ('6. Tes droits',
      'Accès et rectification : consulte et modifie ton profil dans l’app. Effacement : supprime ton compte dans les Réglages. Portabilité : exporte tes données en JSON (Réglages → Télécharger mes données). Tu peux aussi nous contacter pour t’opposer au traitement.'),
  ('7. Sécurité',
      'Les mots de passe sont stockés hachés (jamais en clair), le trafic est chiffré en HTTPS, et l’accès nécessite une authentification.'),
  ('8. Mineurs',
      'TeamUp s’adresse aux étudiants. Si tu n’as pas l’âge du consentement numérique dans ton pays, utilise l’app uniquement avec l’accord d’un parent ou tuteur.'),
  ('9. Contact',
      'Questions ou demandes : teamup.team28@gmail.com'),
];
