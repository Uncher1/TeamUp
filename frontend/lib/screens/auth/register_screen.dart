import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.register(_name.text, _email.text, _password.text,
        language: context.read<SettingsProvider>().language);
    if (!mounted) return;
    if (ok) {
      // Reveal the AuthGate, which routes the new account to verification.
      Navigator.of(context).pop();
      return;
    }
    // Duplicate e-mail → tell the user and offer to go to the login screen.
    if (authProvider.errorCode == 409) {
      await _showExistsDialog(context.tr('register.existsEmail'));
      return;
    }
    final err = authProvider.error ?? context.tr('register.fail');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  /// Shown when the account already exists (classic or Google). Offers to jump
  /// to the login screen (popping this pushed route reveals it).
  Future<void> _showExistsDialog(String message) async {
    final goLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('register.existsTitle')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('register.goLogin')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (goLogin == true) Navigator.of(context).pop();
  }

  Future<void> _handleGoogle() async {
    final outcome = await handleGoogleSignIn(context);
    if (!mounted || !outcome.signedIn) return;
    if (outcome.isNew) {
      // New Google account → reveal AuthGate, which routes to profile completion.
      Navigator.of(context).pop();
      return;
    }
    // Existing account → let the user choose.
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('register.existsTitle')),
        content: Text(context.tr('register.existsGoogle')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'back'),
            child: Text(context.tr('register.backToSignup')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'login'),
            child: Text(context.tr('register.signMeIn')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'login') {
      Navigator.of(context).pop(); // reveal AuthGate (shell or verification)
    } else {
      await context.read<AuthProvider>().logout(); // discard, stay on register
    }
  }

  /// Reactive password-strength checklist (✗ red → ✓ green), shown only once
  /// the user starts typing — mirrors the change-password screen.
  List<Widget> _passwordRules() {
    final p = context.palette;
    final pwd = _password.text;
    final rules = <(String, bool)>[
      (context.tr('pwd.min8'), pwd.length >= 8),
      (context.tr('pwd.upper'), pwd.contains(RegExp(r'[A-Z]'))),
      (context.tr('pwd.lower'), pwd.contains(RegExp(r'[a-z]'))),
      (context.tr('pwd.digit'), pwd.contains(RegExp(r'[0-9]'))),
      (context.tr('pwd.special'), pwd.contains(RegExp(r'[^A-Za-z0-9]'))),
    ];
    return [
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const LanguageToggle(),
                    ],
                  ),
                  const Center(child: BrandHeader(iconSize: 36, fontSize: 28)),
                  const SizedBox(height: 24),
                  Text(context.tr('register.title'), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(context.tr('register.subtitle'), style: TextStyle(color: context.palette.textMuted)),
                  const SizedBox(height: 24),
                  TextField(controller: _name, decoration: InputDecoration(labelText: context.tr('register.fullName'))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: context.tr('common.email')),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: context.tr('register.passwordHint')),
                  ),
                  // Smoothly expand/collapse the strength checklist.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      opacity: _password.text.isEmpty ? 0.0 : 1.0,
                      child: _password.text.isEmpty
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _passwordRules(),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(context.tr('register.cta')),
                  ),
                  const SizedBox(height: 16),
                  const OrDivider(),
                  const SizedBox(height: 16),
                  GoogleAuthButton(onPressed: busy ? () {} : _handleGoogle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
