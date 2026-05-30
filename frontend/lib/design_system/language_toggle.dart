import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/settings_provider.dart';

/// Compact EN | FR switcher for the pre-auth screens (onboarding, login,
/// register, verification, complete-profile) — the only place the user can
/// pick a language before reaching Settings. The choice persists app-wide.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    Widget seg(String code, String label) {
      final active = settings.language == code;
      return GestureDetector(
        onTap: () => context.read<SettingsProvider>().setLanguage(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: active ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : p.textMuted,
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
        children: [seg('en', 'EN'), seg('fr', 'FR')],
      ),
    );
  }
}
