import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
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
      return _snack(context.tr('pwd2.min8msg'));
    }
    if (_new.text != _confirm.text) {
      return _snack(context.tr('pwd2.mismatch'));
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
      _snack(context.tr('pwd2.updated'));
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
      if (mounted) _snack(context.tr('verify.resent'));
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFromError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsScaffold(
      title: context.tr('set.password'),
      children: _codeSent ? _confirmPhase(p) : _requestPhase(p),
    );
  }

  // ── Phase 1: current + new password with the reactive checklist ─────────────
  List<Widget> _requestPhase(AppPalette p) {
    final pwd = _new.text;
    final rules = <(String, bool)>[
      (context.tr('pwd.min8'), pwd.length >= 8),
      (context.tr('pwd.upper'), pwd.contains(RegExp(r'[A-Z]'))),
      (context.tr('pwd.lower'), pwd.contains(RegExp(r'[a-z]'))),
      (context.tr('pwd.digit'), pwd.contains(RegExp(r'[0-9]'))),
      (context.tr('pwd.special'), pwd.contains(RegExp(r'[^A-Za-z0-9]'))),
    ];
    return [
      SettingsSectionLabel(context.tr('pwd2.section')),
      PasswordField(
        controller: _current,
        label: context.tr('pwd2.current'),
        prefixIcon: const Icon(Icons.lock_outline),
      ),
      const SizedBox(height: 12),
      PasswordField(
        controller: _new,
        label: context.tr('pwd2.new'),
        prefixIcon: const Icon(Icons.lock_outline),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      PasswordField(
        controller: _confirm,
        label: context.tr('pwd2.confirm'),
        prefixIcon: const Icon(Icons.lock_outline),
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
                      Text(context.tr('pwd2.recommend'),
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
      _infoBox(context.tr('pwd2.info')),
      const SizedBox(height: 16),
      AppButton(
        onPressed: _busy ? null : _requestCode,
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(context.tr('cc.sendCode')),
      ),
    ];
  }

  // ── Phase 2: enter the e-mailed code ────────────────────────────────────────
  List<Widget> _confirmPhase(AppPalette p) => [
        SettingsSectionLabel(context.tr('cc.confirmChange')),
        Text(context.tr('pwd2.enterCode'),
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
              : Text(context.tr('cc.confirmChange')),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _cooldown > 0 ? null : _resend,
            child: Text(_cooldown > 0
                ? context.tr('verify.resendIn', {'s': '$_cooldown'})
                : context.tr('verify.resend')),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _codeSent = false),
            child: Text(context.tr('common.cancel'), style: TextStyle(color: p.textMuted)),
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
