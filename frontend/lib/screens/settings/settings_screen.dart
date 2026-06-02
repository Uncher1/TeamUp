// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_info.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/settings_repo.dart';
import '../../repositories/user_repo.dart';
import '../profile/friends_screen.dart';
import '../profile/profile_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
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
              GradientAvatar(
                  name: user?.fullName ?? '?',
                  size: 56,
                  imageUrl: user?.avatarUrl,
                  presenceStatus: user?.presenceStatus),
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
          icon: Icons.people_outline,
          label: context.tr('set.friends'),
          onTap: () => _push(context, const FriendsScreen()),
        ),
        SettingsTile(
          icon: Icons.shield_outlined,
          label: context.tr('set.privacy'),
          subtitle: context.tr('set.privacySub'),
          onTap: () => _push(context, const PrivacyScreen()),
        ),
        SettingsTile(
          icon: Icons.download_outlined,
          label: context.tr('set.exportData'),
          subtitle: context.tr('set.exportDataSub'),
          onTap: () => _exportData(context),
        ),

        SettingsSectionLabel(context.tr('nav.notifications')),
        SettingsTile(
          icon: Icons.notifications_active_outlined,
          label: context.tr('nav.notifications'),
          subtitle: context.tr('set.notifSub'),
          onTap: () => _push(context, const NotificationsSettingsScreen()),
        ),

        SettingsSectionLabel(context.tr('set.preferences')),
        SettingsTile(
          icon: Icons.online_prediction,
          label: context.tr('presence.title'),
          subtitle: context.tr('presence.sub'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: GradientAvatar.presenceColor(user?.presenceStatus) ??
                      p.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(_presenceLabel(context, user?.presenceStatus ?? 'online'),
                  style: TextStyle(fontSize: 12, color: p.textMuted)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: p.textMuted),
            ],
          ),
          onTap: () => _pickPresence(context, user?.presenceStatus ?? 'online'),
        ),
        SettingsTile(
          icon: Icons.visibility_outlined,
          label: context.tr('presence.visTitle'),
          subtitle: context.tr('presence.visSub'),
          onTap: () => _pickPresenceVisibility(context),
        ),
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
          icon: Icons.privacy_tip_outlined,
          label: context.tr('set.privacyPolicy'),
          onTap: () => _push(context, const PrivacyPolicyScreen()),
        ),
        SettingsTile(
          icon: Icons.info_outline,
          label: context.tr('set.about'),
          subtitle: 'v${AppInfo.version}',
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
          child: Text('TeamUp · v${AppInfo.version}',
              style: TextStyle(fontSize: 12, color: p.textMuted)),
        ),
      ],
    );
  }
}

String _presenceLabel(BuildContext context, String status) {
  switch (status) {
    case 'dnd':
      return context.tr('presence.dnd');
    case 'offline':
      return context.tr('presence.offline');
    case 'online':
    default:
      return context.tr('presence.online');
  }
}

/// Discord-style status picker: updates presence on the backend and refreshes
/// the in-memory user so the dot updates everywhere immediately.
Future<void> _pickPresence(BuildContext context, String current) async {
  final repo = context.read<UserRepository>();
  final auth = context.read<AuthProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final failMsg = context.tr('common.error');
  final chosen = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final status in const ['online', 'dnd', 'offline'])
            ListTile(
              leading: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: GradientAvatar.presenceColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(_presenceLabel(ctx, status)),
              trailing: status == current
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, status),
            ),
        ],
      ),
    ),
  );
  if (chosen == null || chosen == current) return;
  try {
    final updated = await repo.updateProfile(presenceStatus: chosen);
    auth.setUser(updated);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
  }
}

String _presenceVisLabel(BuildContext context, String v) {
  switch (v) {
    case 'friends':
      return context.tr('presence.visFriends');
    case 'nobody':
      return context.tr('presence.visNobody');
    case 'everyone':
    default:
      return context.tr('presence.visEveryone');
  }
}

/// WhatsApp-style: choose who may see your online status (everyone/friends/nobody).
Future<void> _pickPresenceVisibility(BuildContext context) async {
  final repo = context.read<SettingsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final failMsg = context.tr('common.error');
  var current = 'everyone';
  try {
    final s = await repo.getAll();
    current = s['presenceVisibility'] ?? 'everyone';
  } catch (_) {}
  if (!context.mounted) return;
  final chosen = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in const ['everyone', 'friends', 'nobody'])
            ListTile(
              leading: Icon(v == 'everyone'
                  ? Icons.public
                  : v == 'friends'
                      ? Icons.people_outline
                      : Icons.lock_outline),
              title: Text(_presenceVisLabel(ctx, v)),
              trailing: v == current
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, v),
            ),
        ],
      ),
    ),
  );
  if (chosen == null || chosen == current) return;
  try {
    await repo.update({'presenceVisibility': chosen});
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
  }
}

/// GDPR data portability: build a downloadable JSON copy and open the system
/// share/save sheet. (E-mail delivery is on hold until the prod mail provider
/// is sorted - tracked as tech debt.)
Future<void> _exportData(BuildContext context) async {
  final repo = context.read<UserRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final preparingMsg = context.tr('set.exportPreparing');
  final failMsg = context.tr('set.exportFail');
  messenger.showSnackBar(SnackBar(content: Text(preparingMsg)));
  try {
    await _shareExportFile(repo);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
  }
}

/// Writes the export JSON to a temp file and opens the system share sheet.
Future<void> _shareExportFile(UserRepository repo) async {
  final data = await repo.fetchExportJson();
  final json = const JsonEncoder.withIndent('  ').convert(data);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/teamup-my-data.json');
  await file.writeAsString(json);
  await Share.shareXFiles([XFile(file.path)]);
}
