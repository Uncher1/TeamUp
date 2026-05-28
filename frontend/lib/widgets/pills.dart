import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A small rounded label used for skills and interests.
class Pill extends StatelessWidget {
  final String text;
  final bool accent;
  const Pill(this.text, {super.key, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? AppTheme.primary.withValues(alpha: 0.10) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent ? AppTheme.primary.withValues(alpha: 0.30) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: accent ? AppTheme.primary : AppTheme.textPrimary,
        ),
      ),
    );
  }
}
