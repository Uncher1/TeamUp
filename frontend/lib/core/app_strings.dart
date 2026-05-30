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

    // Feed
    'feed.retry': 'Retry',
    'feed.emptyTitle': 'No posts yet',
    'feed.emptySub': 'Be the first to share something with your community.',
    'feed.composeHint': 'Share something...',
    'feed.share': 'Share',
    'feed.shareTitle': 'Share this post',
    'feed.copy': 'Copy text',
    'feed.copied': 'Text copied — ready to share',
    'feed.newPost': 'New post',
    'feed.publish': 'Publish',
    'feed.publishFail': 'Failed to publish',
    'feed.commentsTitle': 'Comments',
    'feed.commentHint': 'Add a comment...',
    'feed.noCommentsTitle': 'No comments',
    'feed.noCommentsSub': 'Be the first to comment.',
    'feed.editComment': 'Edit comment',
    'feed.commentContent': 'Comment content',
    'feed.deleteCommentTitle': 'Delete comment',
    'feed.irreversible': 'This action cannot be undone.',
    'common.save': 'Save',
    'common.edit': 'Edit',
    'common.delete': 'Delete',

    // Post types
    'posttype.general': 'General',
    'posttype.project_launch': 'Project launch',
    'posttype.team_update': 'Team update',
    'posttype.looking_for': 'Looking for',
    'posttype.milestone': 'Milestone',

    // Relative time
    'time.now': 'just now',
    'time.min': '{n} min ago',
    'time.hour': '{n} h ago',
    'time.day': '{n} d ago',

    // About
    'about.users': 'Users',
    'about.projects': 'Projects',
    'about.schools': 'Schools',
    'about.desc': 'TeamUp is a student social network that helps students collaborate on projects, find teammates with complementary skills, and build together.',
    'about.madeBy': 'Made with ❤️ by',
    'about.copyright': '© 2026 — Student project',

    // Theme color
    'theme.choose': 'Choose a color',
    'theme.note': 'The theme color applies to buttons, links and accent elements across the app.',
    'theme.active': 'Active',

    // Delete account
    'del.warnTitle': 'This action is irreversible',
    'del.warnBody': 'Deleting your account will permanently erase all your data, projects and memberships.',
    'del.whatTitle': 'What will be deleted',
    'del.item1': 'Your profile and personal data',
    'del.item2': 'All your projects',
    'del.item3': 'Your team memberships',
    'del.item4': 'Messages and conversations',
    'del.confirm': 'I understand this action is irreversible and all my data will be deleted.',
    'del.cta': 'Delete my account',
    'del.dialogTitle': 'Delete account?',
    'del.dialogBody': 'This action is irreversible. All your data will be permanently deleted.',

    // Privacy
    'priv.gVisibility': 'Profile visibility',
    'priv.gTeam': 'Teams & projects',
    'priv.gComm': 'Communication',
    'priv.profilePublic': 'Public profile',
    'priv.profilePublicD': 'Anyone can see your profile',
    'priv.online': 'Online status',
    'priv.onlineD': 'Others see when you are online',
    'priv.lastSeen': 'Last seen',
    'priv.lastSeenD': 'Show your last activity',
    'priv.teamInvites': 'Team invitations',
    'priv.teamInvitesD': 'Receive invitations to join teams',
    'priv.showProjects': 'Show my projects',
    'priv.showProjectsD': 'Show your projects on your profile',
    'priv.appearSearch': 'Appear in search',
    'priv.appearSearchD': 'Be found by your skills',
    'priv.allowMessages': 'Allow messages',
    'priv.allowMessagesD': 'Receive messages from everyone',
    'priv.showEmail': 'Show email',
    'priv.showEmailD': 'Show your email on your profile',
    'priv.showPhone': 'Show phone',
    'priv.showPhoneD': 'Show your phone on your profile',

    // Notification settings
    'notif.master': 'All notifications',
    'notif.masterSub': 'Master switch',
    'notif.gPush': 'Push notifications',
    'notif.gPushSub': 'Alerts on your device',
    'notif.gEmail': 'Email notifications',
    'notif.gEmailSub': 'Sent to your email',
    'notif.gSound': 'Sound & vibration',
    'notif.gSoundSub': 'Alert preferences',
    'notif.messages': 'New messages',
    'notif.messagesD': 'When you receive a message',
    'notif.teamUpdates': 'Team updates',
    'notif.teamUpdatesD': 'Team activity and changes',
    'notif.projectUpdates': 'Project updates',
    'notif.projectUpdatesD': 'Project milestones and tasks',
    'notif.mentions': 'Mentions',
    'notif.mentionsD': 'When someone mentions you',
    'notif.digest': 'Weekly digest',
    'notif.digestD': 'Summary of your activity',
    'notif.invites': 'Team invitations',
    'notif.invitesD': 'New invitations',
    'notif.news': 'Product news',
    'notif.newsD': 'New features and tips',
    'notif.sound': 'Sound',
    'notif.soundD': 'Play a notification sound',
    'notif.vibration': 'Vibration',
    'notif.vibrationD': 'Vibrate on notifications',

    // Help center
    'help.search': 'Search help...',
    'help.quickActions': 'Quick actions',
    'help.contact': 'Contact us',
    'help.guide': 'User guide',
    'help.rate': 'Rate the app',
    'help.website': 'Website',
    'help.faq': 'Frequently asked questions',
    'help.noResult': 'No result for « {q} ».',
    'help.guideTitle': 'Quick guide',
    'help.guideSub': 'The key steps to get started.',
    'help.step1': 'Complete your profile with your skills and interests.',
    'help.step2': 'Create or join a project from the main tab.',
    'help.step3': 'Find teammates via "Find teammates" — the score helps you choose.',
    'help.step4': 'Accept or reject applications received on your project.',
    'help.step5': 'Chat in real time with your team in the "Messages" tab.',
    'help.rateBody': 'Your rating helps us improve TeamUp.',
    'help.rateThanks': 'Thanks!',
    'help.rateThanksSnack': 'Thanks for your rating!',
    'help.mailErr': "Couldn't open the mail app",
    'help.webErr': "Couldn't open the browser",
    'help.q1': 'How do I create a project?',
    'help.a1': 'Open "Create a project" from the menu. Give it a title and a description, pick a type, then add the required skills with a weight from 1 to 5 (the higher the weight, the more the skill counts in matching) and some interests. Once published, your project appears in "My teams" and can receive applications.',
    'help.q2': 'How does teammate matching work?',
    'help.a2': "The score combines two measures: 70% skill match (your levels weighted by the project's required weights) and 30% interest match (shared interests). Each candidate gets a % score, and the list is ranked from most to least relevant.",
    'help.q3': 'How do I find teammates for my project?',
    'help.a3': 'Go to "Find teammates", pick one of your projects, and the best-ranked profiles appear with their compatibility score. You can filter by name with the search bar, then contact a profile via "Message".',
    'help.q4': 'How do I apply to a project / join a team?',
    'help.a4': 'Open a project you like and apply. The project owner sees your application in the "Applications" section and can accept or reject it. If accepted, you join the team and get notified.',
    'help.q5': 'How do I manage applications I receive?',
    'help.a5': 'On the detail page of a project you own, the "Applications" section lists the profiles who applied, with Accept and Reject buttons. The applicant is notified of your decision.',
    'help.q6': 'How does messaging work?',
    'help.a6': 'Chat is real-time: messages arrive instantly without refreshing. You can chat directly with a profile (from Find teammates) or in a project conversation. Find all your chats in the "Messages" tab.',
    'help.q7': 'What are notifications for?',
    'help.a7': "You're notified when someone applies to your project, when your application is accepted, and when you receive a message. The bell at the top shows your unread count; open \"Notifications\" to see everything.",
    'help.q8': 'How do I set my skills and levels?',
    'help.a8': 'In "Edit profile", add your skills and set your level from 1 (beginner) to 5 (expert) for each. These levels directly feed the matching algorithm, so the more precise your profile, the more relevant the suggestions.',
    'help.q9': 'How do I control my privacy?',
    'help.a9': 'In Settings > Privacy, you choose who can see your profile, whether you appear in search, who can contact you, and whether your online status is visible.',
    'help.q10': 'How do I enable dark mode or change the color?',
    'help.a10': 'Settings > Preferences: turn on "Dark mode" to switch the whole app, and open "Theme" to pick an accent color. The change applies immediately and is remembered.',
    'help.q11': 'How do I change my email or password?',
    'help.a11': 'Settings > Account: "Email address" to update your email, "Password" to change it. A confirmation code is sent by email to validate the change.',
    'help.q12': 'How do I delete my account?',
    'help.a12': 'Settings > Danger Zone > "Delete account". This action is irreversible: your profile, projects, memberships and messages are permanently erased. A confirmation checkbox is required before you confirm.',

    // Find teammates
    'ft.intro': 'Pick one of your projects to see the best-ranked profiles.',
    'ft.noProjects': 'Create a project first to find teammates.',
    'ft.myProject': 'My project',
    'ft.searchHint': 'Search a profile...',
    'ft.convErr': "Couldn't open the conversation",
    'ft.emptyTitle': 'No teammate found',
    'ft.emptySub': "No profile matches this project's skills yet.",
    'ft.noResultTitle': 'No result',
    'ft.noResultSub': 'No profile matches « {q} ».',
    'ft.skills': 'Skills',
    'ft.interests': 'Interests',
    'ft.invitesSoon': 'Invitations coming soon',
    'ft.invite': 'Invite',
    'ft.message': 'Message',

    // My teams
    'mt.partOf': 'You are part of',
    'mt.team': 'team',
    'mt.teamsP': 'teams',
    'mt.member': 'member',
    'mt.membersP': 'members',
    'mt.emptyTitle': 'No team',
    'mt.emptySub': 'Create a project or join a team to get started.',

    // Timeline + status
    'timeline.short': 'Short',
    'timeline.medium': 'Medium',
    'timeline.long': 'Long',
    'status.open': 'Open',
    'status.active': 'Active',
    'status.in_progress': 'In progress',
    'status.completed': 'Completed',
    'status.paused': 'Paused',
    'status.closed': 'Closed',

    // Create project
    'proj.bannerTitle': 'New project',
    'proj.bannerSub': 'Build something with your team',
    'proj.info': 'Details',
    'proj.titleLabel': 'Project title',
    'proj.description': 'Description',
    'proj.category': 'Category',
    'proj.teamSize': 'Team size',
    'proj.duration': 'Estimated duration',
    'proj.skillsRequired': 'Required skills',
    'proj.skillsHint': 'Tap to add; set the weight (1–5).',
    'proj.themes': 'Topics',
    'proj.create': 'Create project',
    'proj.required': 'Title and description are required',
    'proj.created': 'Project created',
    'category.mobile': 'Mobile App',
    'category.web': 'Web App',
    'category.ai': 'AI / ML',
    'category.game': 'Video game',
    'category.hardware': 'Hardware / IoT',
    'category.data': 'Data',
    'category.design': 'Design',
    'category.other': 'Other',
    'timeline.shortR': '1-2 weeks',
    'timeline.mediumR': '1-2 months',
    'timeline.longR': '3+ months',

    // Chat
    'chat.emptyTitle': 'No conversation',
    'chat.emptySub': 'Start a chat from a profile or a project.',
    'chat.start': 'Start the conversation',
    'chat.noMessages': 'No messages yet. Say hi 👋',
    'chat.inputHint': 'Message...',

    // Notifications inbox
    'ninbox.markAll': 'Mark all as read',
    'ninbox.emptySub': 'Your notifications will appear here.',
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

    // Feed
    'feed.retry': 'Réessayer',
    'feed.emptyTitle': "Aucun post pour l'instant",
    'feed.emptySub': 'Sois le premier à partager quelque chose avec ta communauté.',
    'feed.composeHint': 'Partage quelque chose...',
    'feed.share': 'Partager',
    'feed.shareTitle': 'Partager cette publication',
    'feed.copy': 'Copier le texte',
    'feed.copied': 'Texte copié — prêt à partager',
    'feed.newPost': 'Nouveau post',
    'feed.publish': 'Publier',
    'feed.publishFail': 'Échec de la publication',
    'feed.commentsTitle': 'Commentaires',
    'feed.commentHint': 'Ajoute un commentaire...',
    'feed.noCommentsTitle': 'Aucun commentaire',
    'feed.noCommentsSub': 'Sois le premier à commenter.',
    'feed.editComment': 'Modifier le commentaire',
    'feed.commentContent': 'Contenu du commentaire',
    'feed.deleteCommentTitle': 'Supprimer le commentaire',
    'feed.irreversible': 'Cette action est irréversible.',
    'common.save': 'Enregistrer',
    'common.edit': 'Modifier',
    'common.delete': 'Supprimer',

    // Post types
    'posttype.general': 'Général',
    'posttype.project_launch': 'Lancement',
    'posttype.team_update': 'Mise à jour',
    'posttype.looking_for': 'Recherche',
    'posttype.milestone': 'Jalon',

    // Relative time
    'time.now': "à l'instant",
    'time.min': 'il y a {n} min',
    'time.hour': 'il y a {n} h',
    'time.day': 'il y a {n} j',

    // About
    'about.users': 'Utilisateurs',
    'about.projects': 'Projets',
    'about.schools': 'Écoles',
    'about.desc': 'TeamUp est un réseau social étudiant qui aide les étudiants à collaborer sur des projets, à trouver des coéquipiers aux compétences complémentaires et à construire ensemble.',
    'about.madeBy': 'Fait avec ❤️ par',
    'about.copyright': '© 2026 — Projet étudiant',

    // Theme color
    'theme.choose': 'Choisir une couleur',
    'theme.note': "La couleur du thème s'applique aux boutons, liens et éléments d'accent de toute l'app.",
    'theme.active': 'Actif',

    // Delete account
    'del.warnTitle': 'Cette action est irréversible',
    'del.warnBody': 'La suppression de ton compte effacera définitivement toutes tes données, projets et adhésions.',
    'del.whatTitle': 'Ce qui sera supprimé',
    'del.item1': 'Ton profil et tes données personnelles',
    'del.item2': 'Tous tes projets',
    'del.item3': 'Tes adhésions aux équipes',
    'del.item4': 'Messages et conversations',
    'del.confirm': 'Je comprends que cette action est irréversible et que toutes mes données seront supprimées.',
    'del.cta': 'Supprimer mon compte',
    'del.dialogTitle': 'Supprimer le compte ?',
    'del.dialogBody': 'Cette action est irréversible. Toutes tes données seront définitivement supprimées.',

    // Privacy
    'priv.gVisibility': 'Visibilité du profil',
    'priv.gTeam': 'Équipes & projets',
    'priv.gComm': 'Communication',
    'priv.profilePublic': 'Profil public',
    'priv.profilePublicD': 'Tout le monde peut voir ton profil',
    'priv.online': 'Statut en ligne',
    'priv.onlineD': 'Les autres voient quand tu es en ligne',
    'priv.lastSeen': 'Dernière connexion',
    'priv.lastSeenD': 'Affiche ta dernière activité',
    'priv.teamInvites': "Invitations d'équipe",
    'priv.teamInvitesD': 'Recevoir des invitations à rejoindre des équipes',
    'priv.showProjects': 'Afficher mes projets',
    'priv.showProjectsD': 'Affiche tes projets sur ton profil',
    'priv.appearSearch': 'Apparaître dans la recherche',
    'priv.appearSearchD': 'Être trouvé par tes compétences',
    'priv.allowMessages': 'Autoriser les messages',
    'priv.allowMessagesD': 'Recevoir des messages de tout le monde',
    'priv.showEmail': "Afficher l'e-mail",
    'priv.showEmailD': 'Affiche ton e-mail sur ton profil',
    'priv.showPhone': 'Afficher le téléphone',
    'priv.showPhoneD': 'Affiche ton téléphone sur ton profil',

    // Notification settings
    'notif.master': 'Toutes les notifications',
    'notif.masterSub': 'Interrupteur général',
    'notif.gPush': 'Notifications push',
    'notif.gPushSub': 'Alertes sur ton appareil',
    'notif.gEmail': 'Notifications e-mail',
    'notif.gEmailSub': 'Envoyées sur ton e-mail',
    'notif.gSound': 'Son & vibration',
    'notif.gSoundSub': "Préférences d'alerte",
    'notif.messages': 'Nouveaux messages',
    'notif.messagesD': 'Quand tu reçois un message',
    'notif.teamUpdates': "Mises à jour d'équipe",
    'notif.teamUpdatesD': "Activité et changements d'équipe",
    'notif.projectUpdates': 'Mises à jour de projet',
    'notif.projectUpdatesD': 'Jalons et tâches du projet',
    'notif.mentions': 'Mentions',
    'notif.mentionsD': "Quand quelqu'un te mentionne",
    'notif.digest': 'Résumé hebdomadaire',
    'notif.digestD': 'Synthèse de ton activité',
    'notif.invites': "Invitations d'équipe",
    'notif.invitesD': 'Nouvelles invitations',
    'notif.news': 'Nouveautés produit',
    'notif.newsD': 'Nouvelles fonctionnalités et astuces',
    'notif.sound': 'Son',
    'notif.soundD': 'Jouer un son de notification',
    'notif.vibration': 'Vibration',
    'notif.vibrationD': 'Vibrer lors des notifications',

    // Help center
    'help.search': "Rechercher dans l'aide...",
    'help.quickActions': 'Actions rapides',
    'help.contact': 'Nous contacter',
    'help.guide': "Guide d'utilisation",
    'help.rate': "Noter l'app",
    'help.website': 'Site web',
    'help.faq': 'Questions fréquentes',
    'help.noResult': 'Aucun résultat pour « {q} ».',
    'help.guideTitle': 'Guide rapide',
    'help.guideSub': 'Les étapes essentielles pour bien démarrer.',
    'help.step1': "Complète ton profil avec tes compétences et centres d'intérêt.",
    'help.step2': "Crée ou rejoins un projet depuis l'onglet principal.",
    'help.step3': "Trouve des coéquipiers via « Trouver des coéquipiers » — le score t'aide à choisir.",
    'help.step4': 'Accepte ou refuse les candidatures reçues sur ton projet.',
    'help.step5': "Discute en temps réel avec ton équipe dans l'onglet « Messages ».",
    'help.rateBody': 'Ta note nous aide à améliorer TeamUp.',
    'help.rateThanks': 'Merci !',
    'help.rateThanksSnack': 'Merci pour ta note !',
    'help.mailErr': "Impossible d'ouvrir l'app mail",
    'help.webErr': "Impossible d'ouvrir le navigateur",
    'help.q1': 'Comment créer un projet ?',
    'help.a1': "Ouvre « Créer un projet » depuis le menu. Donne un titre et une description, choisis un type, puis ajoute les compétences requises avec un poids de 1 à 5 (plus le poids est élevé, plus la compétence pèse dans le matching) et des centres d'intérêt. Une fois publié, ton projet apparaît dans « Mes équipes » et peut recevoir des candidatures.",
    'help.q2': 'Comment fonctionne le matching de coéquipiers ?',
    'help.a2': "Le score combine deux mesures : 70 % la correspondance de compétences (tes niveaux pondérés par les poids demandés par le projet) et 30 % la correspondance d'intérêts (intérêts en commun). Chaque candidat reçoit un score en %, et la liste est classée du plus pertinent au moins pertinent.",
    'help.q3': 'Comment trouver des coéquipiers pour mon projet ?',
    'help.a3': "Va dans « Trouver des coéquipiers », choisis l'un de tes projets, et la liste des profils les mieux classés s'affiche avec leur score de compatibilité. Tu peux filtrer par nom avec la barre de recherche, puis contacter un profil via « Message ».",
    'help.q4': 'Comment postuler à un projet / rejoindre une équipe ?',
    'help.a4': "Ouvre un projet qui t'intéresse et postule. Le porteur du projet voit ta candidature dans la section « Candidatures » et peut l'accepter ou la refuser. S'il accepte, tu rejoins l'équipe et tu es notifié.",
    'help.q5': 'Comment gérer les candidatures reçues ?',
    'help.a5': "Sur la page de détail d'un projet dont tu es le porteur, la section « Candidatures » liste les profils ayant postulé, avec un bouton Accepter et Refuser. Le candidat est notifié de ta décision.",
    'help.q6': 'Comment fonctionne la messagerie ?',
    'help.a6': "Le chat est en temps réel : les messages arrivent instantanément sans rafraîchir. Tu peux discuter en direct avec un profil (depuis Trouver des coéquipiers) ou dans la conversation d'un projet. Retrouve toutes tes discussions dans l'onglet « Messages ».",
    'help.q7': 'À quoi servent les notifications ?',
    'help.a7': "Tu es notifié quand quelqu'un postule à ton projet, quand ta candidature est acceptée, et quand tu reçois un message. La cloche en haut affiche le nombre de notifications non lues ; ouvre « Notifications » pour tout voir.",
    'help.q8': 'Comment renseigner mes compétences et niveaux ?',
    'help.a8': "Dans « Modifier le profil », ajoute tes compétences et règle ton niveau de 1 (débutant) à 5 (expert) pour chacune. Ces niveaux alimentent directement l'algorithme de matching, donc plus ton profil est précis, plus les suggestions sont pertinentes.",
    'help.q9': 'Comment contrôler ma confidentialité ?',
    'help.a9': "Dans Réglages > Confidentialité, tu choisis qui peut voir ton profil, si tu apparais dans la recherche, qui peut te contacter, et si ton statut en ligne est visible.",
    'help.q10': 'Comment activer le mode sombre ou changer la couleur ?',
    'help.a10': "Réglages > Préférences : active « Mode sombre » pour basculer toute l'app, et ouvre « Thème » pour choisir une couleur d'accent. Le changement s'applique immédiatement et est mémorisé.",
    'help.q11': 'Comment changer mon e-mail ou mon mot de passe ?',
    'help.a11': "Réglages > Compte : « Adresse e-mail » pour mettre à jour ton e-mail, « Mot de passe » pour le changer. Un code de confirmation est envoyé par e-mail pour valider le changement.",
    'help.q12': 'Comment supprimer mon compte ?',
    'help.a12': "Réglages > Danger Zone > « Supprimer le compte ». Cette action est irréversible : ton profil, tes projets, tes adhésions et tes messages sont définitivement effacés. Une case de confirmation est requise avant de valider.",

    // Find teammates
    'ft.intro': 'Choisis un de tes projets pour voir les profils les mieux classés.',
    'ft.noProjects': "Crée d'abord un projet pour trouver des coéquipiers.",
    'ft.myProject': 'Mon projet',
    'ft.searchHint': 'Rechercher un profil...',
    'ft.convErr': "Impossible d'ouvrir la conversation",
    'ft.emptyTitle': 'Aucun coéquipier trouvé',
    'ft.emptySub': 'Aucun profil ne correspond encore aux compétences de ce projet.',
    'ft.noResultTitle': 'Aucun résultat',
    'ft.noResultSub': 'Aucun profil ne correspond à « {q} ».',
    'ft.skills': 'Compétences',
    'ft.interests': 'Intérêts',
    'ft.invitesSoon': 'Invitations à venir',
    'ft.invite': 'Inviter',
    'ft.message': 'Message',

    // My teams
    'mt.partOf': 'Tu fais partie de',
    'mt.team': 'équipe',
    'mt.teamsP': 'équipes',
    'mt.member': 'membre',
    'mt.membersP': 'membres',
    'mt.emptyTitle': 'Aucune équipe',
    'mt.emptySub': 'Crée un projet ou rejoins une équipe pour commencer.',

    // Timeline + status
    'timeline.short': 'Court',
    'timeline.medium': 'Moyen',
    'timeline.long': 'Long',
    'status.open': 'Ouvert',
    'status.active': 'Actif',
    'status.in_progress': 'En cours',
    'status.completed': 'Terminé',
    'status.paused': 'En pause',
    'status.closed': 'Fermé',

    // Create project
    'proj.bannerTitle': 'Nouveau projet',
    'proj.bannerSub': 'Construis quelque chose avec ton équipe',
    'proj.info': 'Informations',
    'proj.titleLabel': 'Titre du projet',
    'proj.description': 'Description',
    'proj.category': 'Catégorie',
    'proj.teamSize': "Taille de l'équipe",
    'proj.duration': 'Durée estimée',
    'proj.skillsRequired': 'Compétences requises',
    'proj.skillsHint': 'Touche pour ajouter ; règle le poids (1–5).',
    'proj.themes': 'Thématiques',
    'proj.create': 'Créer le projet',
    'proj.required': 'Titre et description sont requis',
    'proj.created': 'Projet créé',
    'category.mobile': 'Mobile App',
    'category.web': 'Web App',
    'category.ai': 'IA / ML',
    'category.game': 'Jeu vidéo',
    'category.hardware': 'Hardware / IoT',
    'category.data': 'Data',
    'category.design': 'Design',
    'category.other': 'Autre',
    'timeline.shortR': '1-2 semaines',
    'timeline.mediumR': '1-2 mois',
    'timeline.longR': '3+ mois',

    // Chat
    'chat.emptyTitle': 'Aucune conversation',
    'chat.emptySub': 'Lance une discussion depuis un profil ou un projet.',
    'chat.start': 'Démarre la conversation',
    'chat.noMessages': 'Aucun message. Dis bonjour 👋',
    'chat.inputHint': 'Message...',

    // Notifications inbox
    'ninbox.markAll': 'Tout marquer lu',
    'ninbox.emptySub': 'Tes notifications apparaîtront ici.',
  },
};

String translate(String code, String key, [Map<String, String>? args]) {
  var value = _strings[code]?[key] ?? _strings['en']?[key] ?? key;
  if (args != null) {
    args.forEach((k, v) => value = value.replaceAll('{$k}', v));
  }
  return value;
}

/// Localized relative time ("just now" / "il y a 3 h"), shared by the feed,
/// comments and anywhere a timestamp is shown.
String timeAgo(BuildContext context, DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return context.tr('time.now');
  if (d.inMinutes < 60) return context.tr('time.min', {'n': '${d.inMinutes}'});
  if (d.inHours < 24) return context.tr('time.hour', {'n': '${d.inHours}'});
  return context.tr('time.day', {'n': '${d.inDays}'});
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
