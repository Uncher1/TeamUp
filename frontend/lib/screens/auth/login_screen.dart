import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'alice@school.fr');
  final _password = TextEditingController(text: 'password');

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandHeader(iconSize: 36, fontSize: 28)),
                  const SizedBox(height: 32),
                  Text(context.tr('login.title'), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(context.tr('login.subtitle'), style: TextStyle(color: context.palette.textMuted)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: context.tr('common.email')),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(labelText: context.tr('common.password')),
                    onSubmitted: (_) => busy ? null : _submit(),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(context.tr('login.cta')),
                  ),
                  const SizedBox(height: 16),
                  const OrDivider(),
                  const SizedBox(height: 16),
                  GoogleAuthButton(
                      onPressed: busy ? () {} : () => handleGoogleSignIn(context)),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text(context.tr('login.noAccount')),
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
