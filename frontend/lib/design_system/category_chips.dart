import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Renders catalog items (skills / interests) grouped by category, with a small
/// category header and the chips sorted alphabetically within each category.
/// The chip itself is provided by [chipBuilder] so callers control add/toggle.
class CategoryChips extends StatelessWidget {
  final List<({int id, String name, String? category})> items;
  final Widget Function(int id, String name) chipBuilder;

  const CategoryChips({super.key, required this.items, required this.chipBuilder});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final groups = <String, List<({int id, String name, String? category})>>{};
    for (final it in items) {
      groups.putIfAbsent(it.category ?? 'Autre', () => []).add(it);
    }
    final cats = groups.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in cats) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              cat.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: p.textMuted,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final it in (groups[cat]!..sort((a, b) => a.name.compareTo(b.name))))
                chipBuilder(it.id, it.name),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
