// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../repositories/user_repo.dart';

/// A proper, guided report flow: pick a reason (each clearly described), add
/// optional details (required for "other"), then submit. The backend stores it
/// and emails the moderation team.
class ReportUserScreen extends StatefulWidget {
  final int userId;
  final String? userName;
  const ReportUserScreen({super.key, required this.userId, this.userName});

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  static const _reasons = <(String, IconData)>[
    ('spam', Icons.campaign_outlined),
    ('harassment', Icons.sentiment_very_dissatisfied_outlined),
    ('inappropriate', Icons.visibility_off_outlined),
    ('fake', Icons.person_off_outlined),
    ('other', Icons.more_horiz),
  ];

  String? _reason;
  final _details = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    final messenger = ScaffoldMessenger.of(context);
    if (reason == 'other' && _details.text.trim().isEmpty) {
      messenger.showSnackBar(
          SnackBar(content: Text(context.tr('report.detailsRequired'))));
      return;
    }
    final repo = context.read<UserRepository>();
    final navigator = Navigator.of(context);
    final sentMsg = context.tr('report.sent');
    final errMsg = context.tr('common.error');
    setState(() => _sending = true);
    try {
      await repo.reportUser(widget.userId, reason, _details.text.trim());
      messenger.showSnackBar(SnackBar(content: Text(sentMsg)));
      navigator.pop(true);
    } catch (_) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsScaffold(
      title: context.tr('report.title'),
      children: [
        Text(context.tr('report.subtitle'),
            style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.5)),
        const SizedBox(height: 16),
        SettingsSectionLabel(context.tr('report.chooseReason')),
        const SizedBox(height: 8),
        for (final (code, icon) in _reasons) _reasonCard(context, code, icon),
        const SizedBox(height: 16),
        SettingsSectionLabel(context.tr(
            _reason == 'other' ? 'report.details' : 'report.detailsOptional')),
        const SizedBox(height: 8),
        TextField(
          controller: _details,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        AppButton(
          onPressed: _reason == null || _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.tr('report.submit')),
        ),
      ],
    );
  }

  Widget _reasonCard(BuildContext context, String code, IconData icon) {
    final p = context.palette;
    final accent = Theme.of(context).colorScheme.primary;
    final selected = _reason == code;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _reason = code),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? accent : p.slate200, width: selected ? 1.6 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: selected ? accent : p.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('report.$code'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(context.tr('report.${code}Desc'),
                          style: TextStyle(fontSize: 12, color: p.textMuted)),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 20,
                  color: selected ? accent : p.slate200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
