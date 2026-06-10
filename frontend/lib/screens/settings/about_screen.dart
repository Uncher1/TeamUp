// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _stats = [('10K+', 'about.users'), ('500+', 'about.projects'), ('150+', 'about.schools')];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsScaffold(
      title: context.tr('set.about'),
      children: [
        Center(
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 80, height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: AppTheme.gradientFor(Theme.of(context).colorScheme.primary),
                ),
              ),
              child: const Icon(Icons.hexagon_outlined, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            Text('TeamUp',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: p.textPrimary)),
            Text('Version ${AppInfo.version}',
                style: TextStyle(fontSize: 13, color: p.textMuted)),
            const SizedBox(height: 16),
          ]),
        ),
        Row(
          children: [
            for (final (value, labelKey) in _stats)
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
                    Text(context.tr(labelKey), style: TextStyle(fontSize: 11, color: p.textMuted)),
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
            context.tr('about.desc'),
            style: TextStyle(fontSize: 13, height: 1.5, color: p.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.slate100, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(context.tr('about.madeBy'), style: TextStyle(fontSize: 12, color: p.textMuted)),
            Text('Team 28', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.textPrimary)),
            const SizedBox(height: 2),
            Text(context.tr('about.copyright'), style: TextStyle(fontSize: 11, color: p.textMuted)),
          ]),
        ),
      ],
    );
  }
}
