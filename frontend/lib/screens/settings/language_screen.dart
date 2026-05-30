import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/settings_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  // (code, labelKey, flagAsset) — the app ships in French + English.
  static const _languages = [
    ('en', 'lang.en', 'assets/flag_en.png'),
    ('fr', 'lang.fr', 'assets/flag_fr.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.watch<SettingsProvider>();
    return SettingsScaffold(
      title: context.tr('lang.title'),
      children: [
        SettingsSectionLabel(context.tr('lang.choose')),
        for (final (code, labelKey, flag) in _languages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.read<SettingsProvider>().setLanguage(code),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: s.language == code ? p.itemHoverBg : p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: s.language == code
                          ? Theme.of(context).colorScheme.primary
                          : p.slate200),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(flag, width: 30, height: 20, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(context.tr(labelKey),
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
            context.tr('lang.note'),
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}
