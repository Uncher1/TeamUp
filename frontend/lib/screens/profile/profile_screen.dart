import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pills.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
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
                      radius: 30,
                      backgroundColor: AppTheme.primary,
                      child: Text(user.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22)),
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
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(user.bio!, style: const TextStyle(height: 1.5)),
                ],
                const SizedBox(height: 24),
                Text('Compétences',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                user.skills.isEmpty
                    ? Text('Aucune compétence déclarée.',
                        style: TextStyle(color: AppTheme.textMuted))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in user.skills)
                            Pill('${s.name} · ${s.level}/5', accent: true),
                        ],
                      ),
                const SizedBox(height: 24),
                Text('Centres d\'intérêt',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                user.interests.isEmpty
                    ? Text('Aucun intérêt déclaré.',
                        style: TextStyle(color: AppTheme.textMuted))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final i in user.interests) Pill(i.name)],
                      ),
              ],
            ),
    );
  }
}
