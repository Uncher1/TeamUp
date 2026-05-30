import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
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
    (Icons.person_outline, 'Ton profil et tes données personnelles'),
    (Icons.work_outline, 'Tous tes projets'),
    (Icons.groups_outlined, 'Tes adhésions aux équipes'),
    (Icons.chat_bubble_outline, 'Messages et conversations'),
  ];

  Future<void> _confirmAndDelete() async {
    final userRepo = context.read<UserRepository>();
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text(
            'Cette action est irréversible. Toutes tes données seront définitivement supprimées.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFDC2626))),
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
      title: 'Delete Account',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cette action est irréversible',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFFB91C1C))),
                SizedBox(height: 4),
                Text(
                    'La suppression de ton compte effacera définitivement toutes tes données, projets et adhésions.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const SettingsSectionLabel('Ce qui sera supprimé'),
        for (final (icon, label) in _items)
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
                Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C))),
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
                'Je comprends que cette action est irréversible et que toutes mes données seront supprimées.',
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
              : const Text('Supprimer mon compte'),
        ),
      ],
    );
  }
}
