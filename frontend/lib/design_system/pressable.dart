// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// A tap-owning wrapper that scales its child down while pressed.
/// When [onPressed] is null the widget is disabled: no animation, no callback.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onPressed,
    this.scale = 0.96,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: (enabled && _pressed) ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Standard primary CTA button, built on [PressableScale] for a tactile press
/// animation. Visually matches the themed ElevatedButton (height 52, radius 14,
/// seed-color fill, white Outfit-600 label). Pass [onPressed] = null to disable.
///
/// [color] overrides the enabled fill color (e.g. use red for destructive actions).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.expand = true,
    this.color,
  });

  final VoidCallback? onPressed;
  final Widget child;

  /// When true (default) the button stretches to full available width.
  final bool expand;

  /// Optional override for the enabled fill color. Defaults to [ColorScheme.primary].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colorScheme = Theme.of(context).colorScheme;
    final p = context.palette;

    final fillColor = enabled ? (color ?? colorScheme.primary) : p.slate200;
    final contentColor = enabled ? Colors.white : p.textMuted;

    final button = Container(
      height: 52,
      width: expand ? double.infinity : null,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: DefaultTextStyle(
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: contentColor,
        ),
        child: IconTheme(
          data: IconThemeData(color: contentColor),
          child: child,
        ),
      ),
    );

    return PressableScale(
      onPressed: onPressed,
      child: button,
    );
  }
}
