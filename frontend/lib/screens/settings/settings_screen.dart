import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../profile/profile_screen.dart';
import 'about_screen.dart';
import 'admin_panel_screen.dart';
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
                  Row(children: [
                    Flexible(
                      child: Text(user?.fullName ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    RoleBadge(role: user?.role ?? 'user', size: 17),
                  ]),
                  const SizedBox(height: 2),
                  Text(context.tr('nav.profileRow'),
                      style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        SettingsSectionLabel(context.tr('set.account')),
        SettingsTile(
          icon: Icons.mail_outline,
          label: context.tr('set.email'),
          subtitle: user?.email,
          onTap: () => _push(context, const EmailScreen()),
        ),
        SettingsTile(
          icon: Icons.lock_outline,
          label: context.tr('set.password'),
          onTap: () => _push(context, const PasswordScreen()),
        ),
        SettingsTile(
          icon: Icons.shield_outlined,
          label: context.tr('set.privacy'),
          subtitle: context.tr('set.privacySub'),
          onTap: () => _push(context, const PrivacyScreen()),
        ),

        SettingsSectionLabel(context.tr('nav.notifications')),
        SettingsTile(
          icon: Icons.notifications_active_outlined,
          label: context.tr('nav.notifications'),
          subtitle: context.tr('set.notifSub'),
          onTap: () => _push(context, const NotificationsSettingsScreen()),
        ),

        SettingsSectionLabel(context.tr('set.preferences')),
        SettingToggleTile(
          icon: Icons.dark_mode_outlined,
          label: context.tr('set.darkMode'),
          value: settings.darkMode,
          onChanged: (v) => context.read<SettingsProvider>().setDarkMode(v),
        ),
        SettingsTile(
          icon: Icons.palette_outlined,
          label: context.tr('set.theme'),
          subtitle: settings.themeColor,
          onTap: () => _push(context, const ThemeColorScreen()),
        ),
        SettingsTile(
          icon: Icons.language,
          label: context.tr('lang.title'),
          subtitle: context.tr(settings.language == 'fr' ? 'lang.fr' : 'lang.en'),
          onTap: () => _push(context, const LanguageScreen()),
        ),

        SettingsSectionLabel(context.tr('set.support')),
        SettingsTile(
          icon: Icons.help_outline,
          label: context.tr('set.help'),
          onTap: () => _push(context, const HelpScreen()),
        ),
        SettingsTile(
          icon: Icons.info_outline,
          label: context.tr('set.about'),
          subtitle: 'v1.0.0',
          onTap: () => _push(context, const AboutScreen()),
        ),

        if (user?.role == 'admin') ...[
          SettingsSectionLabel(context.tr('admin.title')),
          SettingsTile(
            icon: Icons.shield_outlined,
            label: context.tr('admin.manageAccounts'),
            subtitle: context.tr('role.admin'),
            onTap: () => _push(context, const AdminPanelScreen()),
          ),
        ],

        SettingsSectionLabel(context.tr('set.danger')),
        SettingsTile(
          icon: Icons.delete_outline,
          label: context.tr('set.delete'),
          danger: true,
          onTap: () => _push(context, const DeleteAccountScreen()),
        ),
        SettingsTile(
          icon: Icons.logout,
          label: context.tr('nav.logout'),
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
}
