// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/user_repo.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _confirmed = false;
  bool _busy = false;

  static const _items = [
    (Icons.person_outline, 'del.item1'),
    (Icons.work_outline, 'del.item2'),
    (Icons.groups_outlined, 'del.item3'),
    (Icons.chat_bubble_outline, 'del.item4'),
  ];

  Future<void> _confirmAndDelete() async {
    final userRepo = context.read<UserRepository>();
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('del.dialogTitle')),
        content: Text(context.tr('del.dialogBody')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('common.delete'), style: const TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await userRepo.deleteAccount();
      if (!mounted) return;
      // Pop this pushed route back to the shell root before logging out, so
      // AuthGate's LoginScreen isn't left underneath an orphaned delete screen.
      navigator.popUntil((r) => r.isFirst);
      await auth.logout(); // returns to login via AuthGate
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiClient.messageFromError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsScaffold(
      title: context.tr('set.delete'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('del.warnTitle'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFFB91C1C))),
                const SizedBox(height: 4),
                Text(context.tr('del.warnBody'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        SettingsSectionLabel(context.tr('del.whatTitle')),
        for (final (icon, labelKey) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(icon, size: 18, color: const Color(0xFFEF4444)),
                const SizedBox(width: 10),
                Text(context.tr(labelKey), style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C))),
              ]),
            ),
          ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Checkbox(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                context.tr('del.confirm'),
                style: TextStyle(fontSize: 12, color: p.textMuted),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        AppButton(
          color: const Color(0xFFDC2626),
          onPressed: (!_confirmed || _busy) ? null : _confirmAndDelete,
          child: _busy
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.tr('del.cta')),
        ),
      ],
    );
  }
}
