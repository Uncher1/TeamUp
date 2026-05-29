import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/user_repo.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _new.text.trim();
    if (email.isEmpty) {
      _snack('Saisis une nouvelle adresse e-mail.');
      return;
    }
    if (email != _confirm.text.trim()) {
      _snack('Les deux adresses ne correspondent pas.');
      return;
    }
    setState(() => _busy = true);
    try {
      final user = await context.read<UserRepository>().updateProfile(email: email);
      if (!mounted) return;
      context.read<AuthProvider>().setUser(user);
      _snack('Adresse e-mail mise à jour.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = context.watch<AuthProvider>().user?.email ?? '';
    return SettingsScaffold(
      title: 'Email Address',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.palette.itemHoverBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.mail_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current,
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: p.textPrimary)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.check, size: 12, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text('Adresse actuelle',
                          style: TextStyle(fontSize: 12, color: p.textMuted)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SettingsSectionLabel('Changer d\'adresse'),
        TextField(
          controller: _new,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
              labelText: 'Nouvelle adresse', prefixIcon: Icon(Icons.mail_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
              labelText: 'Confirmer l\'adresse', prefixIcon: Icon(Icons.mail_outline)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Expanded(
                child: Text('Ton adresse sera mise à jour immédiatement.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
          ]),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
