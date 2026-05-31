// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/settings_provider.dart';

class ThemeColorScreen extends StatelessWidget {
  const ThemeColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.watch<SettingsProvider>();
    final entries = AppTheme.themeColors.entries.toList();
    return SettingsScaffold(
      title: context.tr('set.theme'),
      children: [
        SettingsSectionLabel(context.tr('theme.choose')),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            for (final e in entries)
              _ColorTile(
                name: e.key,
                color: e.value,
                selected: s.themeColor == e.key,
                onTap: () => context.read<SettingsProvider>().setThemeColor(e.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.slate100, borderRadius: BorderRadius.circular(14)),
          child: Text(
            context.tr('theme.note'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}

class _ColorTile extends StatelessWidget {
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorTile(
      {required this.name, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? p.slate100 : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? p.textPrimary : p.slate200, width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 8),
            Text(name,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: p.textPrimary)),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(context.tr('theme.active'),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF059669))),
              ),
          ],
        ),
      ),
    );
  }
}
