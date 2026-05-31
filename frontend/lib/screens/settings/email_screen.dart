import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
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
  final _code = TextEditingController();
  bool _busy = false;
  bool _codeSent = false; // phase 1 (request) → phase 2 (confirm)
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
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
    final email = _new.text.trim();
    if (email.isEmpty) return _snack(context.tr('em.needNew'));
    if (email != _confirm.text.trim()) {
      return _snack(context.tr('em.mismatch'));
    }
    setState(() => _busy = true);
    try {
      await context.read<UserRepository>().requestEmailChange(email);
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
      final user = await context.read<UserRepository>().confirmChange(_code.text);
      if (!mounted) return;
      context.read<AuthProvider>().setUser(user);
      _snack(context.tr('em.updated'));
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
    final current = context.watch<AuthProvider>().user?.email ?? '';
    return SettingsScaffold(
      title: context.tr('set.email'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.itemHoverBg,
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
                      Text(context.tr('em.current'),
                          style: TextStyle(fontSize: 12, color: p.textMuted)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!_codeSent) ..._requestPhase(p, current) else ..._confirmPhase(p, current),
      ],
    );
  }

  // ── Phase 1: enter the new address ─────────────────────────────────────────
  List<Widget> _requestPhase(AppPalette p, String current) => [
        SettingsSectionLabel(context.tr('em.change')),
        TextField(
          controller: _new,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
              labelText: context.tr('em.new'), prefixIcon: const Icon(Icons.mail_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
              labelText: context.tr('em.confirm'), prefixIcon: const Icon(Icons.mail_outline)),
        ),
        const SizedBox(height: 12),
        _infoBox(context.tr('em.info')),
        const SizedBox(height: 20),
        AppButton(
          onPressed: _busy ? null : _requestCode,
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.tr('cc.sendCode')),
        ),
      ];

  // ── Phase 2: enter the code received on the OLD address ─────────────────────
  List<Widget> _confirmPhase(AppPalette p, String current) => [
        SettingsSectionLabel(context.tr('cc.confirmChange')),
        Text(
          context.tr('em.enterCode', {'email': current}),
          style: TextStyle(fontSize: 13, color: p.textMuted),
        ),
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
