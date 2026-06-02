// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/settings_provider.dart';

/// Compact EN | FR switcher for the pre-auth screens (onboarding, login,
/// register, verification, complete-profile) - the only place the user can
/// pick a language before reaching Settings. The choice persists app-wide.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    Widget seg(String code, String asset) {
      final active = settings.language == code;
      return GestureDetector(
        onTap: () => context.read<SettingsProvider>().setLanguage(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Opacity(
            opacity: active ? 1.0 : 0.45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(asset, width: 26, height: 18, fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.itemHoverBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('en', 'assets/flag_en.png'),
          const SizedBox(width: 4),
          seg('fr', 'assets/flag_fr.png'),
        ],
      ),
    );
  }
}
