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
              ? 'Dernière mise à jour : 31 mai 2026. Cette politique explique, en toute transparence, quelles données TeamUp collecte, pourquoi, sur quelle base légale, avec qui elles sont partagées, combien de temps elles sont conservées et quels sont tes droits au titre du RGPD.'
              : 'Last updated: 31 May 2026. This policy explains, transparently, what data TeamUp collects, why, on what legal basis, who it is shared with, how long it is kept, and your rights under the GDPR.',
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
  ('1. Who we are (data controller)',
      'TeamUp is a student application built by Team 28 as part of an engineering-school project. For the purposes of the EU General Data Protection Regulation (GDPR), the team acts as the data controller for the personal data processed in the app. You can reach us at any time at teamup.team28@gmail.com for any privacy question or to exercise your rights.'),
  ('2. Data we collect',
      'Account data: your email address and full name (and, for Google Sign-In, the identifier Google returns). '
          'Profile data (all optional, provided by you): biography, school, department, year of study, location, skills, interests, profile photo, phone number, presence status and social links (GitHub, LinkedIn, website…). '
          'Content you create: projects, applications, posts, comments, direct and team messages with their attachments (images, files, voice notes), polls and votes, friend requests, blocks and reports. '
          'Technical data: an authentication token stored on your device to keep you signed in, and standard server logs kept by our hosting providers (such as connection timestamps and IP addresses) for security and reliability. We do not use advertising identifiers or third-party analytics/tracking SDKs.'),
  ('3. How we use your data (purposes)',
      'We use your data only to operate the service: to create and secure your account, to authenticate you, to suggest relevant teammates and projects based on your skills and interests, to let you publish, chat, build teams and run polls, to deliver transactional emails (email verification, security codes, your data export, and abuse reports you send), and to keep the platform safe (moderation, blocking and handling of reports). We never sell your data and we do not use it for advertising.'),
  ('4. Legal bases (GDPR Art. 6)',
      'Performance of a contract: processing strictly necessary to provide the features you use (account, matching, messaging, teams). '
          'Consent: the consent you give when creating your account, for optional profile information you choose to add, and which you can withdraw at any time by editing or deleting that data. '
          'Legitimate interests: keeping the service secure and free of abuse (authentication, rate-limiting, moderation, handling reports), balanced against your rights.'),
  ('5. Matching and automated processing',
      'The teammate/project suggestions are produced by a simple, transparent scoring rule: we compare the skills and interests on your profile with those required by a project (or held by other users) and rank by overlap. This ranking is only a suggestion to help you find people - it does not produce legal or similarly significant effects, and nothing happens automatically without your action. You stay in control: edit your skills/interests, or turn off appearing in search, at any time in your profile and privacy settings.'),
  ('6. What other users can see',
      'Your name, photo, role badge and the public part of your profile are visible to other signed-in users so they can find teammates. You control this in Privacy settings: you can make your profile private, hide your email or phone, stop appearing in search, and refuse direct messages. Your presence status (online / do not disturb / offline) may be shown next to your avatar. Your password, security codes and private settings are never visible to anyone.'),
  ('7. Sharing and processors',
      'We do not sell or rent your data and display no advertising. A small number of technical providers process data solely on our behalf, under their own security and data-protection commitments: Render (API hosting), Aiven (managed database), Google (Google Sign-In, if you use it) and Google Gmail / SMTP (sending our transactional emails). We share data with these providers only as needed to run the service, and with public authorities only where legally required.'),
  ('8. Where your data is stored (international transfers)',
      'Your data is hosted within the European Union: the database is in the Netherlands (Aiven) and the API in Germany (Render), which keeps personal data inside the EU/EEA. If a provider ever processes data outside the EEA, it is done under appropriate safeguards such as the European Commission’s Standard Contractual Clauses.'),
  ('9. How long we keep it',
      'We keep your personal data for as long as your account exists. When you delete your account (Settings → Delete account), your profile, projects, posts, comments, messages, polls, friend/block/report records and related data are permanently erased from the live database; residual copies in short-lived technical backups are overwritten in the normal backup cycle. Some minimal records may be kept longer only where the law requires it.'),
  ('10. Security',
      'We apply reasonable technical measures: passwords are stored hashed with bcrypt (never in clear text), all traffic is encrypted over HTTPS/TLS, access to the API requires an authentication token, sensitive actions are rate-limited, and the database connection is encrypted. As TeamUp is a student project provided “as is”, we cannot guarantee absolute security; please use a unique password.'),
  ('11. Your rights',
      'Under the GDPR you have the right to access, rectify, erase, restrict and object to the processing of your data, and the right to data portability. In the app you can: view and edit your data (Profile → Edit), export it as a structured file (Settings → Download my data / receive by email), and permanently delete your account (Settings → Delete account). You can also email teamup.team28@gmail.com for any request. We aim to respond within one month. You also have the right to lodge a complaint with a supervisory authority - in France, the CNIL (www.cnil.fr).'),
  ('12. Cookies and tracking',
      'The app uses no advertising cookies and no third-party tracking. It only stores, locally on your device, the authentication token and your preferences (theme, language) needed for it to work.'),
  ('13. Minors',
      'TeamUp is intended for students. If you are below the age of digital consent in your country (for example 15 in France), please use the app only with the agreement of a parent or guardian.'),
  ('14. Changes to this policy',
      'We may update this policy as the app evolves. The date at the top reflects the latest version; significant changes will be made visible in the app.'),
  ('15. Contact and complaints',
      'Privacy questions, rights requests or concerns: teamup.team28@gmail.com. You may also contact your local data-protection authority (in France, the CNIL).'),
];

const List<(String, String)> _fr = [
  ('1. Qui sommes-nous (responsable de traitement)',
      'TeamUp est une application étudiante développée par l’Équipe 28 dans le cadre d’un projet d’école d’ingénieurs. Au sens du Règlement général sur la protection des données (RGPD), l’équipe agit en tant que responsable de traitement des données personnelles traitées dans l’app. Tu peux nous joindre à tout moment à teamup.team28@gmail.com pour toute question relative à la confidentialité ou pour exercer tes droits.'),
  ('2. Données que nous collectons',
      'Données de compte : ton adresse e-mail et ton nom complet (et, pour la connexion Google, l’identifiant renvoyé par Google). '
          'Données de profil (toutes facultatives, fournies par toi) : biographie, école, filière, année d’étude, localisation, compétences, centres d’intérêt, photo de profil, numéro de téléphone, statut de présence et liens (GitHub, LinkedIn, site web…). '
          'Contenu que tu crées : projets, candidatures, publications, commentaires, messages directs et d’équipe avec leurs pièces jointes (images, fichiers, messages vocaux), sondages et votes, demandes d’ami, blocages et signalements. '
          'Données techniques : un jeton d’authentification stocké sur ton appareil pour te garder connecté, et les journaux serveur standard conservés par nos hébergeurs (horodatages de connexion, adresses IP) à des fins de sécurité et de fiabilité. Nous n’utilisons aucun identifiant publicitaire ni outil d’analyse/pistage tiers.'),
  ('3. Pourquoi nous les utilisons (finalités)',
      'Nous utilisons tes données uniquement pour faire fonctionner le service : créer et sécuriser ton compte, t’authentifier, te suggérer des équipiers et projets pertinents selon tes compétences et intérêts, te permettre de publier, discuter, monter des équipes et lancer des sondages, t’envoyer des e-mails transactionnels (vérification d’e-mail, codes de sécurité, export de tes données, et signalements que tu envoies) et garder la plateforme sûre (modération, blocage, traitement des signalements). Nous ne vendons jamais tes données et ne les utilisons pas à des fins publicitaires.'),
  ('4. Bases légales (art. 6 du RGPD)',
      'Exécution d’un contrat : les traitements strictement nécessaires pour fournir les fonctionnalités que tu utilises (compte, matching, messagerie, équipes). '
          'Consentement : celui que tu donnes à la création de ton compte, pour les informations de profil facultatives que tu choisis d’ajouter, et que tu peux retirer à tout moment en modifiant ou supprimant ces données. '
          'Intérêt légitime : assurer la sécurité du service et lutter contre les abus (authentification, limitation du débit, modération, traitement des signalements), mis en balance avec tes droits.'),
  ('5. Matching et traitement automatisé',
      'Les suggestions d’équipiers/projets reposent sur une règle de score simple et transparente : nous comparons les compétences et intérêts de ton profil avec ceux requis par un projet (ou détenus par d’autres utilisateurs) et classons selon le recoupement. Ce classement n’est qu’une suggestion pour t’aider à trouver des personnes - il ne produit aucun effet juridique ou significatif, et rien ne se déclenche automatiquement sans ton action. Tu gardes le contrôle : modifie tes compétences/intérêts ou désactive ton apparition dans la recherche à tout moment dans ton profil et tes réglages de confidentialité.'),
  ('6. Ce que les autres utilisateurs voient',
      'Ton nom, ta photo, ton badge de rôle et la partie publique de ton profil sont visibles par les autres utilisateurs connectés afin qu’ils puissent trouver des équipiers. Tu contrôles cela dans les réglages de Confidentialité : tu peux rendre ton profil privé, masquer ton e-mail ou ton téléphone, ne plus apparaître dans la recherche et refuser les messages directs. Ton statut de présence (en ligne / ne pas déranger / hors ligne) peut être affiché à côté de ton avatar. Ton mot de passe, tes codes de sécurité et tes réglages privés ne sont jamais visibles.'),
  ('7. Partage et sous-traitants',
      'Nous ne vendons ni ne louons tes données et n’affichons aucune publicité. Un petit nombre de prestataires techniques traitent les données uniquement pour notre compte, selon leurs propres engagements de sécurité et de protection des données : Render (hébergement de l’API), Aiven (base de données managée), Google (connexion Google, si tu l’utilises) et Google Gmail / SMTP (envoi de nos e-mails transactionnels). Nous ne partageons les données avec ces prestataires que dans la mesure nécessaire au service, et avec les autorités publiques uniquement lorsque la loi l’exige.'),
  ('8. Où tes données sont stockées (transferts)',
      'Tes données sont hébergées au sein de l’Union européenne : la base de données est aux Pays-Bas (Aiven) et l’API en Allemagne (Render), ce qui maintient les données personnelles dans l’UE/EEE. Si un prestataire venait à traiter des données hors EEE, ce serait sous des garanties appropriées, telles que les clauses contractuelles types de la Commission européenne.'),
  ('9. Durée de conservation',
      'Nous conservons tes données personnelles tant que ton compte existe. Lorsque tu supprimes ton compte (Réglages → Supprimer le compte), ton profil, tes projets, publications, commentaires, messages, sondages, enregistrements d’ami/blocage/signalement et données associées sont effacés définitivement de la base active ; les copies résiduelles dans les sauvegardes techniques de courte durée sont écrasées lors du cycle de sauvegarde normal. Certaines données minimales peuvent être conservées plus longtemps uniquement si la loi l’impose.'),
  ('10. Sécurité',
      'Nous appliquons des mesures techniques raisonnables : les mots de passe sont stockés hachés avec bcrypt (jamais en clair), tout le trafic est chiffré en HTTPS/TLS, l’accès à l’API nécessite un jeton d’authentification, les actions sensibles sont limitées en débit et la connexion à la base de données est chiffrée. TeamUp étant un projet étudiant fourni « en l’état », nous ne pouvons garantir une sécurité absolue ; utilise un mot de passe unique.'),
  ('11. Tes droits',
      'Au titre du RGPD, tu disposes des droits d’accès, de rectification, d’effacement, de limitation et d’opposition au traitement, ainsi que du droit à la portabilité. Dans l’app, tu peux : consulter et modifier tes données (Profil → Modifier), les exporter dans un fichier structuré (Réglages → Télécharger mes données / recevoir par e-mail) et supprimer définitivement ton compte (Réglages → Supprimer le compte). Tu peux aussi écrire à teamup.team28@gmail.com pour toute demande. Nous nous efforçons de répondre sous un mois. Tu as également le droit d’introduire une réclamation auprès d’une autorité de contrôle - en France, la CNIL (www.cnil.fr).'),
  ('12. Cookies et pistage',
      'L’app n’utilise aucun cookie publicitaire ni pistage tiers. Elle ne stocke localement, sur ton appareil, que le jeton d’authentification et tes préférences (thème, langue) nécessaires à son fonctionnement.'),
  ('13. Mineurs',
      'TeamUp s’adresse aux étudiants. Si tu n’as pas l’âge du consentement numérique dans ton pays (par exemple 15 ans en France), utilise l’app uniquement avec l’accord d’un parent ou tuteur.'),
  ('14. Modifications de cette politique',
      'Nous pouvons mettre à jour cette politique à mesure que l’app évolue. La date en haut indique la dernière version ; les changements importants seront rendus visibles dans l’app.'),
  ('15. Contact et réclamations',
      'Questions, demandes d’exercice de droits ou préoccupations : teamup.team28@gmail.com. Tu peux aussi contacter ton autorité locale de protection des données (en France, la CNIL).'),
];
