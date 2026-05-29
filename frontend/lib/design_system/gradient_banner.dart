import 'package:flutter/material.dart';

/// Indigo→purple rounded banner used for hero headers (Create Project, My Teams, Profile).
class GradientBanner extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GradientBanner({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
        ),
      ),
      child: child,
    );
  }
}
