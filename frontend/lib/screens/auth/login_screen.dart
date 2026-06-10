// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/update_checker.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prompt for an app update even before the user signs in.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => maybePromptForUpdate(context));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.login(_email.text, _password.text);
    if (!ok && mounted) {
      final err = context.read<AuthProvider>().error ?? context.tr('login.fail');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: language switch pinned top-right ──────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                  alignment: Alignment.centerRight, child: LanguageToggle()),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                            child: BrandHeader(iconSize: 48, fontSize: 34)),
                        const SizedBox(height: 28),
                        Text(
                          context.tr('login.title'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('login.subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.palette.textMuted),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                              labelText: context.tr('common.email')),
                        ),
                        const SizedBox(height: 14),
                        PasswordField(
                          controller: _password,
                          label: context.tr('common.password'),
                          onSubmitted: (_) => busy ? null : _submit(),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(context.tr('login.cta')),
                        ),
                        const SizedBox(height: 16),
                        const OrDivider(),
                        const SizedBox(height: 16),
                        GoogleAuthButton(
                            onPressed: busy
                                ? () {}
                                : () => handleGoogleSignIn(context)),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterScreen())),
                            child: Text(context.tr('login.noAccount')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
