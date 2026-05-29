import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _stats = [('10K+', 'Utilisateurs'), ('500+', 'Projets'), ('150+', 'Écoles')];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsScaffold(
      title: 'About TeamUp',
      children: [
        Center(
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 80, height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                ),
              ),
              child: const Icon(Icons.hexagon_outlined, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            Text('TeamUp',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: p.textPrimary)),
            Text('Version 1.0.0', style: TextStyle(fontSize: 13, color: p.textMuted)),
            const SizedBox(height: 16),
          ]),
        ),
        Row(
          children: [
            for (final (value, label) in _stats)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: p.slate100, borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary)),
                    Text(label, style: TextStyle(fontSize: 11, color: p.textMuted)),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.slate200),
          ),
          child: Text(
            'TeamUp est un réseau social étudiant qui aide les étudiants à collaborer sur des projets, à trouver des coéquipiers aux compétences complémentaires et à construire ensemble.',
            style: TextStyle(fontSize: 13, height: 1.5, color: p.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.slate100, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text('Fait avec ❤️ par', style: TextStyle(fontSize: 12, color: p.textMuted)),
            Text('Team 28', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.textPrimary)),
            const SizedBox(height: 2),
            Text('© 2026 — Projet étudiant', style: TextStyle(fontSize: 11, color: p.textMuted)),
          ]),
        ),
      ],
    );
  }
}
