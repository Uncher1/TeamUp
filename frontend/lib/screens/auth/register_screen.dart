import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';

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
    final ok = await authProvider.register(_name.text, _email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      final err = context.read<AuthProvider>().error ?? "Échec de l'inscription";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _googleSoon() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'inscription avec Google arrive bientôt.")),
      );

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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const Center(child: BrandHeader(iconSize: 36, fontSize: 28)),
                  const SizedBox(height: 24),
                  Text('Créer un compte', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Rejoins TeamUp.', style: TextStyle(color: context.palette.textMuted)),
                  const SizedBox(height: 24),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet')),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe (min. 8 caractères)'),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("S'inscrire"),
                  ),
                  const SizedBox(height: 16),
                  const OrDivider(),
                  const SizedBox(height: 16),
                  GoogleAuthButton(onPressed: busy ? () {} : _googleSoon),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
