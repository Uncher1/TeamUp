import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'pressable.dart';

/// "Continuer avec Google" button (Google-styled white/outlined). The real
/// OAuth flow is wired later (needs a Google Cloud client id) — for now [onPressed]
/// typically shows a "bientôt" message.
class GoogleAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleAuthButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
            const Icon(Icons.g_mobiledata, size: 30, color: Color(0xFF4285F4)),
            const SizedBox(width: 6),
            Text('Continuer avec Google',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary)),
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
