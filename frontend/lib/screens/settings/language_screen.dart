import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/settings_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  // (code, name, flag)
  static const _languages = [
    ('fr', 'Français', '🇫🇷'),
    ('en', 'English', '🇬🇧'),
    ('es', 'Español', '🇪🇸'),
    ('de', 'Deutsch', '🇩🇪'),
    ('it', 'Italiano', '🇮🇹'),
    ('pt', 'Português', '🇵🇹'),
    ('zh', '中文', '🇨🇳'),
    ('ja', '日本語', '🇯🇵'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.watch<SettingsProvider>();
    return SettingsScaffold(
      title: 'Langue',
      children: [
        const SettingsSectionLabel('Choisir une langue'),
        for (final (code, name, flag) in _languages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.read<SettingsProvider>().setLanguage(code),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: s.language == code ? context.palette.itemHoverBg : p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: s.language == code
                          ? Theme.of(context).colorScheme.primary
                          : p.slate200),
                ),
                child: Row(children: [
                  Text(flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(name,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500, color: p.textPrimary)),
                  ),
                  if (s.language == code)
                    Icon(Icons.check_circle,
                        size: 22, color: Theme.of(context).colorScheme.primary),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.slate100, borderRadius: BorderRadius.circular(14)),
          child: Text(
            'La sélection est enregistrée. La traduction complète de l\'interface arrivera dans une prochaine version.',
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}
