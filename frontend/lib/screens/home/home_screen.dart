import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// J0 placeholder. Confirms the end-to-end auth flow by showing the profile
/// loaded from `GET /api/users/me`. Replaced by the real feed + bottom nav in J1.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TeamUp'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primary,
                      child: Text(user.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(user.email,
                              style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Compétences',
                  child: user.skills.isEmpty
                      ? const Text('Aucune compétence déclarée.')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in user.skills)
                              Chip(label: Text('${s.name} · ${s.level}/5')),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Centres d\'intérêt',
                  child: user.interests.isEmpty
                      ? const Text('Aucun intérêt déclaré.')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final i in user.interests)
                              Chip(label: Text(i.name)),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('J0 — auth de bout en bout ✓\nLe feed arrive en J1.',
                      textAlign: TextAlign.center),
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
