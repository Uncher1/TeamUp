import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'pressable.dart';

/// "Continuer avec Google" button (Google-styled white/outlined).
///
/// The Google "G" logo and "Google" wordmark are Google's official trademarked
/// brand assets — they are NOT recreated in code. Drop the official files in
/// `assets/` (see assets/README.md) and they appear automatically:
///   - assets/google_logo.png    (the multicolour "G")
///   - assets/google_wordmark.png (the "Google" wordmark, optional)
/// Until then, a graceful fallback is shown. Real OAuth is wired in Tier C.
class GoogleAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleAuthButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final labelStyle = TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary);

    // Official "G" logo if present, else a neutral fallback mark.
    final logo = Image.asset(
      'assets/google_logo.png',
      height: 20,
      width: 20,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF4285F4)),
    );

    // Official "Google" wordmark if present, else plain text.
    final wordmark = Image.asset(
      'assets/google_wordmark.png',
      height: 16,
      errorBuilder: (_, _, _) => Text('Google', style: labelStyle),
    );

    return PressableScale(
      onPressed: onPressed,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.slate200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            logo,
            const SizedBox(width: 8),
            Text('Continuer avec ', style: labelStyle),
            wordmark,
          ],
        ),
      ),
    );
  }
}

/// A simple "ou" separator with hairlines on each side.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.slate200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou', style: TextStyle(fontSize: 12, color: p.textMuted)),
        ),
        Expanded(child: Divider(color: p.slate200)),
      ],
    );
  }
}
