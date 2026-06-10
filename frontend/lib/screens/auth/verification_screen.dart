// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  int _cooldown = 0;
  Timer? _timer;

  bool get _complete => _controller.text.length == 9; // XXXX-XXXX

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (!_complete || _busy) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(_controller.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? context.tr('verify.invalid'))),
      );
    }
    // On success the AuthGate rebuilds automatically (emailVerified == true).
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final resentMsg = context.tr('verify.resent');
    final failMsg = context.tr('verify.resendFail');
    _startCooldown();
    final ok = await auth.resendCode();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? resentMsg : (auth.error ?? failMsg)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final email = context.watch<AuthProvider>().user?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                      alignment: Alignment.centerRight, child: LanguageToggle()),
                  const SizedBox(height: 12),
                  const Center(child: BrandHeader(iconSize: 36, fontSize: 28)),
                  const SizedBox(height: 28),
                  Icon(Icons.mark_email_unread_outlined,
                      size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(context.tr('verify.title'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: context.tr('verify.sentTo'),
                          style: TextStyle(color: p.textMuted)),
                      TextSpan(
                          text: email,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary)),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [CodeInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _verify(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'XXXX-XXXX',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    onPressed: (_busy || !_complete) ? null : _verify,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(context.tr('verify.cta')),
                  ),
                  const SizedBox(height: 12),
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
                      onPressed: () => context.read<AuthProvider>().logout(),
                      child: Text(context.tr('verify.changeAccount'),
                          style: TextStyle(color: p.textMuted)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
