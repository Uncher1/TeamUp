import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Profil',
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: user == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
              ],
            ),
            if (user == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    GradientBanner(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GradientAvatar(name: user.fullName, size: 64),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                                const SizedBox(height: 2),
                                Text(user.email,
                                    style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 13),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const SectionLabel('À propos'),
                      const SizedBox(height: 8),
                      Text(user.bio!, style: const TextStyle(height: 1.4)),
                    ],
                    const SizedBox(height: 20),
                    const SectionLabel('Compétences'),
                    const SizedBox(height: 8),
                    if (user.skills.isEmpty)
                      Text('Aucune compétence renseignée.', style: TextStyle(color: context.palette.textMuted))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in user.skills)
                            StatusPill(label: '${s.name} · ${s.level}', bg: context.palette.itemHoverBg, fg: context.palette.primaryHover),
                        ],
                      ),
                    const SizedBox(height: 20),
                    const SectionLabel('Thématiques'),
                    const SizedBox(height: 8),
                    if (user.interests.isEmpty)
                      Text('Aucune thématique renseignée.', style: TextStyle(color: context.palette.textMuted))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final i in user.interests)
                            StatusPill(label: i.name, bg: context.palette.slate100, fg: context.palette.textMuted),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
