import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../profile/profile_screen.dart';
import 'about_screen.dart';
import 'delete_account_screen.dart';
import 'email_screen.dart';
import 'help_screen.dart';
import 'language_screen.dart';
import 'notifications_settings_screen.dart';
import 'password_screen.dart';
import 'privacy_screen.dart';
import 'theme_color_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthProvider>().user;
    final settings = context.watch<SettingsProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Profile card → opens Profile (which has Edit).
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _push(context, const ProfileScreen()),
          child: GradientBanner(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GradientAvatar(name: user?.fullName ?? '?', size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  const Text('Voir / modifier le profil',
                      style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        const SettingsSectionLabel('Compte'),
        SettingsTile(
          icon: Icons.mail_outline,
          label: 'Adresse e-mail',
          subtitle: user?.email,
          onTap: () => _push(context, const EmailScreen()),
        ),
        SettingsTile(
          icon: Icons.lock_outline,
          label: 'Mot de passe',
          onTap: () => _push(context, const PasswordScreen()),
        ),
        SettingsTile(
          icon: Icons.shield_outlined,
          label: 'Confidentialité',
          subtitle: 'Visibilité, recherche',
          onTap: () => _push(context, const PrivacyScreen()),
        ),

        const SettingsSectionLabel('Notifications'),
        SettingsTile(
          icon: Icons.notifications_active_outlined,
          label: 'Notifications',
          subtitle: 'Push, e-mail, son',
          onTap: () => _push(context, const NotificationsSettingsScreen()),
        ),

        const SettingsSectionLabel('Préférences'),
        SettingToggleTile(
          icon: Icons.dark_mode_outlined,
          label: 'Mode sombre',
          value: settings.darkMode,
          onChanged: (v) => context.read<SettingsProvider>().setDarkMode(v),
        ),
        SettingsTile(
          icon: Icons.palette_outlined,
          label: 'Thème',
          subtitle: settings.themeColor,
          onTap: () => _push(context, const ThemeColorScreen()),
        ),
        SettingsTile(
          icon: Icons.language,
          label: 'Langue',
          subtitle: _languageName(settings.language),
          onTap: () => _push(context, const LanguageScreen()),
        ),

        const SettingsSectionLabel('Support'),
        SettingsTile(
          icon: Icons.help_outline,
          label: 'Centre d\'aide',
          onTap: () => _push(context, const HelpScreen()),
        ),
        SettingsTile(
          icon: Icons.info_outline,
          label: 'À propos',
          subtitle: 'v1.0.0',
          onTap: () => _push(context, const AboutScreen()),
        ),

        const SettingsSectionLabel('Danger Zone'),
        SettingsTile(
          icon: Icons.delete_outline,
          label: 'Supprimer le compte',
          danger: true,
          onTap: () => _push(context, const DeleteAccountScreen()),
        ),
        SettingsTile(
          icon: Icons.logout,
          label: 'Se déconnecter',
          danger: true,
          onTap: () => context.read<AuthProvider>().logout(),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('TeamUp · v1.0.0',
              style: TextStyle(fontSize: 12, color: p.textMuted)),
        ),
      ],
    );
  }

  static String _languageName(String code) {
    const map = {
      'fr': 'Français', 'en': 'English', 'es': 'Español', 'de': 'Deutsch',
      'it': 'Italiano', 'pt': 'Português', 'zh': '中文', 'ja': '日本語',
    };
    return map[code] ?? 'Français';
  }
}
