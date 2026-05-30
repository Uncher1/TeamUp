import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../design_system/ds.dart';
import '../../providers/settings_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  // (settingKey, icon, labelKey, descKey)
  static const _visibility = [
    ('profilePublic', Icons.visibility_outlined, 'priv.profilePublic', 'priv.profilePublicD'),
    ('showOnlineStatus', Icons.bolt_outlined, 'priv.online', 'priv.onlineD'),
    ('showLastSeen', Icons.schedule_outlined, 'priv.lastSeen', 'priv.lastSeenD'),
  ];
  static const _team = [
    ('allowTeamInvites', Icons.group_add_outlined, 'priv.teamInvites', 'priv.teamInvitesD'),
    ('showProjects', Icons.work_outline, 'priv.showProjects', 'priv.showProjectsD'),
    ('appearInSearch', Icons.search, 'priv.appearSearch', 'priv.appearSearchD'),
  ];
  static const _comm = [
    ('allowMessages', Icons.chat_bubble_outline, 'priv.allowMessages', 'priv.allowMessagesD'),
    ('showEmail', Icons.mail_outline, 'priv.showEmail', 'priv.showEmailD'),
    ('showPhone', Icons.phone_outlined, 'priv.showPhone', 'priv.showPhoneD'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    Widget group(String label, List<(String, IconData, String, String)> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionLabel(label),
            for (final (key, icon, titleKey, descKey) in items)
              SettingToggleTile(
                icon: icon,
                label: context.tr(titleKey),
                desc: context.tr(descKey),
                value: s.toggle(key),
                onChanged: (v) => context.read<SettingsProvider>().setToggle(key, v),
              ),
            const SizedBox(height: 8),
          ],
        );
    return SettingsScaffold(
      title: context.tr('set.privacy'),
      children: [
        group(context.tr('priv.gVisibility'), _visibility),
        group(context.tr('priv.gTeam'), _team),
        group(context.tr('priv.gComm'), _comm),
      ],
    );
  }
}
