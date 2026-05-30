import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

/// Languages the app ships with. English is the default + fallback.
const List<String> kSupportedLanguages = ['en', 'fr'];

/// Master translation table. Keys are dot-namespaced; English is the source of
/// truth and the fallback when a key is missing in another language.
///
/// Strings are added here as screens are localized. `context.tr('key')` looks
/// up the active language (from [SettingsProvider]); `{placeholders}` in a
/// value are replaced from the optional args map.
const Map<String, Map<String, String>> _strings = {
  'en': {
    // Common
    'common.email': 'Email',
    'common.password': 'Password',
    'common.or': 'or',
    'common.cancel': 'Cancel',
    'common.google': 'Continue with Google',
    'common.googleMobileOnly': 'Google sign-in is available on the mobile app.',
    'common.googleNoToken': 'Google: could not retrieve the token.',
    'common.googleFailed': 'Google sign-in failed',

    // Login
    'login.title': 'Sign in',
    'login.subtitle': 'Find your team.',
    'login.cta': 'Sign in',
    'login.fail': 'Sign-in failed',
    'login.noAccount': "No account? Sign up",

    // Register
    'register.title': 'Create an account',
    'register.subtitle': 'Join TeamUp.',
    'register.fullName': 'Full name',
    'register.passwordHint': 'Password (min. 8 characters)',
    'register.cta': 'Sign up',
    'register.fail': 'Sign-up failed',
    'register.existsTitle': 'Account already exists',
    'register.existsEmail': 'A TeamUp account already uses this e-mail address.',
    'register.existsGoogle': 'A TeamUp account is already linked to this Google account.',
    'register.goLogin': 'Go to sign in',
    'register.backToSignup': 'Back to sign up',
    'register.signMeIn': 'Sign me in',

    // Password rules
    'pwd.min8': 'At least 8 characters',
    'pwd.upper': 'An uppercase letter',
    'pwd.lower': 'A lowercase letter',
    'pwd.digit': 'A digit',
    'pwd.special': 'A special character',

    // E-mail verification
    'verify.title': 'Verify your e-mail',
    'verify.sentTo': 'We sent an 8-character code to\n',
    'verify.cta': 'Verify',
    'verify.invalid': 'Invalid code',
    'verify.noToken': 'Verification: could not read the token.',
    'verify.resend': 'Resend code',
    'verify.resendIn': 'Resend code ({s} s)',
    'verify.resent': 'A new code has been sent.',
    'verify.resendFail': 'Could not send the code',
    'verify.changeAccount': 'Change account',

    // Onboarding
    'common.skip': 'Skip',
    'onb.next': 'Next',
    'onb.start': 'Get started',
    'onb.s1.title': 'Welcome to TeamUp',
    'onb.s1.sub': 'The network that connects students to build project teams.',
    'onb.s2.title': 'Find the right teammates',
    'onb.s2.sub': 'Skill- and interest-based matching suggests the most relevant profiles.',
    'onb.s3.title': 'Collaborate in real time',
    'onb.s3.sub': 'Chat, apply to projects and build your team, right inside the app.',

    // Complete profile
    'cp.title': 'Complete your profile',
    'cp.subtitle': 'Add your skills and interests for better suggestions.',
    'cp.bio': 'Bio',
    'cp.school': 'School',
    'cp.skills': 'Skills',
    'cp.skillsHint': 'Tap to add; set your level (1–5).',
    'cp.interests': 'Interests',
    'cp.finish': 'Finish',

    // Language screen
    'lang.title': 'Language',
    'lang.choose': 'Choose a language',
    'lang.en': 'English',
    'lang.fr': 'French',
    'lang.note': 'Your choice is saved and applies across the whole app.',

    // Navigation (drawer + headers)
    'nav.home': 'Home',
    'nav.createProject': 'Create a project',
    'nav.findTeammates': 'Find teammates',
    'nav.myTeams': 'My teams',
    'nav.chat': 'Messages',
    'nav.notifications': 'Notifications',
    'nav.settings': 'Settings',
    'nav.logout': 'Sign out',
    'nav.profileRow': 'View / edit profile',

    // Settings hub
    'set.account': 'Account',
    'set.email': 'Email address',
    'set.password': 'Password',
    'set.privacy': 'Privacy',
    'set.privacySub': 'Visibility, search',
    'set.notifSub': 'Push, email, sound',
    'set.preferences': 'Preferences',
    'set.darkMode': 'Dark mode',
    'set.theme': 'Theme',
    'set.support': 'Support',
    'set.help': 'Help center',
    'set.about': 'About',
    'set.danger': 'Danger Zone',
    'set.delete': 'Delete account',

    // Notification popup
    'popup.markAll': 'Mark all read',
    'popup.empty': 'No notification',
    'popup.seeAll': 'See all notifications',
  },
  'fr': {
    // Common
    'common.email': 'Email',
    'common.password': 'Mot de passe',
    'common.or': 'ou',
    'common.cancel': 'Annuler',
    'common.google': 'Continuer avec Google',
    'common.googleMobileOnly': 'La connexion Google est disponible sur l’app mobile.',
    'common.googleNoToken': 'Google : impossible de récupérer le token.',
    'common.googleFailed': 'Échec de la connexion Google',

    // Login
    'login.title': 'Connexion',
    'login.subtitle': 'Retrouve ton équipe.',
    'login.cta': 'Se connecter',
    'login.fail': 'Échec de la connexion',
    'login.noAccount': "Pas de compte ? S'inscrire",

    // Register
    'register.title': 'Créer un compte',
    'register.subtitle': 'Rejoins TeamUp.',
    'register.fullName': 'Nom complet',
    'register.passwordHint': 'Mot de passe (min. 8 caractères)',
    'register.cta': "S'inscrire",
    'register.fail': "Échec de l'inscription",
    'register.existsTitle': 'Compte déjà existant',
    'register.existsEmail': 'Un compte TeamUp utilise déjà cette adresse e-mail.',
    'register.existsGoogle': 'Un compte TeamUp est déjà associé à ce compte Google.',
    'register.goLogin': 'Aller à la connexion',
    'register.backToSignup': "Retour à l'inscription",
    'register.signMeIn': 'Me connecter',

    // Password rules
    'pwd.min8': 'Au moins 8 caractères',
    'pwd.upper': 'Une lettre majuscule',
    'pwd.lower': 'Une lettre minuscule',
    'pwd.digit': 'Un chiffre',
    'pwd.special': 'Un caractère spécial',

    // E-mail verification
    'verify.title': 'Vérifie ton adresse e-mail',
    'verify.sentTo': 'Nous avons envoyé un code à 8 caractères à\n',
    'verify.cta': 'Vérifier',
    'verify.invalid': 'Code invalide',
    'verify.noToken': 'Vérification : impossible de lire le token.',
    'verify.resend': 'Renvoyer le code',
    'verify.resendIn': 'Renvoyer le code ({s} s)',
    'verify.resent': 'Un nouveau code a été envoyé.',
    'verify.resendFail': "Échec de l'envoi du code",
    'verify.changeAccount': 'Changer de compte',

    // Onboarding
    'common.skip': 'Passer',
    'onb.next': 'Suivant',
    'onb.start': 'Commencer',
    'onb.s1.title': 'Bienvenue sur TeamUp',
    'onb.s1.sub': 'Le réseau qui connecte les étudiants pour monter des équipes de projet.',
    'onb.s2.title': 'Trouve les bons coéquipiers',
    'onb.s2.sub': "Un matching par compétences et centres d'intérêt te propose les profils les plus pertinents.",
    'onb.s3.title': 'Collabore en temps réel',
    'onb.s3.sub': "Discute, postule à des projets et construis ton équipe, directement dans l'app.",

    // Complete profile
    'cp.title': 'Complète ton profil',
    'cp.subtitle': "Ajoute tes compétences et centres d'intérêt pour de meilleures suggestions.",
    'cp.bio': 'Bio',
    'cp.school': 'École',
    'cp.skills': 'Compétences',
    'cp.skillsHint': 'Touche pour ajouter ; règle ton niveau (1–5).',
    'cp.interests': "Centres d'intérêt",
    'cp.finish': 'Terminer',

    // Language screen
    'lang.title': 'Langue',
    'lang.choose': 'Choisir une langue',
    'lang.en': 'Anglais',
    'lang.fr': 'Français',
    'lang.note': "Ton choix est enregistré et s'applique à toute l'app.",

    // Navigation (drawer + headers)
    'nav.home': 'Accueil',
    'nav.createProject': 'Créer un projet',
    'nav.findTeammates': 'Trouver des coéquipiers',
    'nav.myTeams': 'Mes équipes',
    'nav.chat': 'Messages',
    'nav.notifications': 'Notifications',
    'nav.settings': 'Réglages',
    'nav.logout': 'Se déconnecter',
    'nav.profileRow': 'Voir / modifier le profil',

    // Settings hub
    'set.account': 'Compte',
    'set.email': 'Adresse e-mail',
    'set.password': 'Mot de passe',
    'set.privacy': 'Confidentialité',
    'set.privacySub': 'Visibilité, recherche',
    'set.notifSub': 'Push, e-mail, son',
    'set.preferences': 'Préférences',
    'set.darkMode': 'Mode sombre',
    'set.theme': 'Thème',
    'set.support': 'Support',
    'set.help': "Centre d'aide",
    'set.about': 'À propos',
    'set.danger': 'Danger Zone',
    'set.delete': 'Supprimer le compte',

    // Notification popup
    'popup.markAll': 'Tout lire',
    'popup.empty': 'Aucune notification',
    'popup.seeAll': 'Voir toutes les notifications',
  },
};

String translate(String code, String key, [Map<String, String>? args]) {
  var value = _strings[code]?[key] ?? _strings['en']?[key] ?? key;
  if (args != null) {
    args.forEach((k, v) => value = value.replaceAll('{$k}', v));
  }
  return value;
}

extension AppStringsX on BuildContext {
  /// Translates [key] for the active language. The whole tree rebuilds when the
  /// language changes (MaterialApp is rebuilt from SettingsProvider), so a
  /// non-listening read is enough here.
  String tr(String key, [Map<String, String>? args]) {
    final code = Provider.of<SettingsProvider>(this, listen: false).language;
    return translate(code, key, args);
  }
}
