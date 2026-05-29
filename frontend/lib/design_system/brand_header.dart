import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// "⬡ TeamUp" brand lockup used in the app header and auth screens.
class BrandHeader extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  const BrandHeader({super.key, this.iconSize = 28, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hexagon_outlined, size: iconSize, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text('TeamUp',
            style: GoogleFonts.outfit(
                fontSize: fontSize, fontWeight: FontWeight.w700, color: context.palette.textPrimary)),
      ],
    );
  }
}
