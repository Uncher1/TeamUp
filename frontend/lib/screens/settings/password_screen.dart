import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../repositories/user_repo.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_new.text.length < 8) {
      _snack('Le nouveau mot de passe doit faire au moins 8 caractères.');
      return;
    }
    if (_new.text != _confirm.text) {
      _snack('Les deux mots de passe ne correspondent pas.');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<UserRepository>().changePassword(_current.text, _new.text);
      if (!mounted) return;
      _snack('Mot de passe mis à jour.');
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
    const reqs = [
      'Au moins 8 caractères',
      'Une lettre majuscule',
      'Une lettre minuscule',
      'Un chiffre',
      'Un caractère spécial',
    ];
    return SettingsScaffold(
      title: 'Change Password',
      children: [
        const SettingsSectionLabel('Mettre à jour le mot de passe'),
        TextField(
          controller: _current,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'Mot de passe actuel', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _new,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 16),
        Text('Recommandations :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textMuted)),
        const SizedBox(height: 8),
        for (final r in reqs)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                width: 16, height: 16, alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 10, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 8),
              Text(r, style: TextStyle(fontSize: 12, color: p.textMuted)),
            ]),
          ),
        const SizedBox(height: 16),
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
