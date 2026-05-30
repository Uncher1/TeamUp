import 'dart:async';

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
  final _code = TextEditingController();
  bool _busy = false;
  bool _codeSent = false; // phase 1 (request) → phase 2 (confirm)
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _requestCode() async {
    if (_new.text.length < 8) {
      return _snack('Le nouveau mot de passe doit faire au moins 8 caractères.');
    }
    if (_new.text != _confirm.text) {
      return _snack('Les deux mots de passe ne correspondent pas.');
    }
    setState(() => _busy = true);
    try {
      await context
          .read<UserRepository>()
          .requestPasswordChange(_current.text, _new.text);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startCooldown();
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCode() async {
    if (_code.text.length != 9) return;
    setState(() => _busy = true);
    try {
      await context.read<UserRepository>().confirmChange(_code.text);
      if (!mounted) return;
      _snack('Mot de passe mis à jour.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    _startCooldown();
    try {
      await context.read<UserRepository>().resendChange();
      if (mounted) _snack('Un nouveau code a été envoyé.');
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFromError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsScaffold(
      title: 'Mot de passe',
      children: _codeSent ? _confirmPhase(p) : _requestPhase(p),
    );
  }

  // ── Phase 1: current + new password with the reactive checklist ─────────────
  List<Widget> _requestPhase(AppPalette p) {
    final pwd = _new.text;
    final rules = <(String, bool)>[
      ('Au moins 8 caractères', pwd.length >= 8),
      ('Une lettre majuscule', pwd.contains(RegExp(r'[A-Z]'))),
      ('Une lettre minuscule', pwd.contains(RegExp(r'[a-z]'))),
      ('Un chiffre', pwd.contains(RegExp(r'[0-9]'))),
      ('Un caractère spécial', pwd.contains(RegExp(r'[^A-Za-z0-9]'))),
    ];
    return [
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
        onChanged: (_) => setState(() {}),
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
      // Smoothly expand/collapse the strength checklist.
      AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          opacity: pwd.isEmpty ? 0.0 : 1.0,
          child: pwd.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recommandations :',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: p.textMuted)),
                      const SizedBox(height: 8),
                      for (final (label, met) in rules)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 16,
                              height: 16,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: met ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(met ? Icons.check : Icons.close,
                                  size: 10,
                                  color: met ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                            ),
                            const SizedBox(width: 8),
                            Text(label, style: TextStyle(fontSize: 12, color: p.textMuted)),
                          ]),
                        ),
                    ],
                  ),
                ),
        ),
      ),
      const SizedBox(height: 16),
      _infoBox("Un code de confirmation sera envoyé à ton adresse e-mail. "
          "Le mot de passe ne change qu'une fois ce code saisi ici."),
      const SizedBox(height: 16),
      AppButton(
        onPressed: _busy ? null : _requestCode,
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Envoyer le code'),
      ),
    ];
  }

  // ── Phase 2: enter the e-mailed code ────────────────────────────────────────
  List<Widget> _confirmPhase(AppPalette p) => [
        const SettingsSectionLabel('Confirmer le changement'),
        Text('Saisis le code à 8 caractères envoyé à ton adresse e-mail.',
            style: TextStyle(fontSize: 13, color: p.textMuted)),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          autofocus: true,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [CodeInputFormatter()],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _confirmCode(),
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 5, fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: 'XXXX-XXXX'),
        ),
        const SizedBox(height: 16),
        AppButton(
          onPressed: (_busy || _code.text.length != 9) ? null : _confirmCode,
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirmer le changement'),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _cooldown > 0 ? null : _resend,
            child: Text(_cooldown > 0 ? 'Renvoyer le code ($_cooldown s)' : 'Renvoyer le code'),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _codeSent = false),
            child: Text('Annuler', style: TextStyle(color: p.textMuted)),
          ),
        ),
      ];

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
        ]),
      );
}
