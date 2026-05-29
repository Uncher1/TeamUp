import 'package:flutter/material.dart';
import '../core/theme.dart';

/// White rounded card with a soft slate border, matching the mockup.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.slate200),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: card);
  }
}
