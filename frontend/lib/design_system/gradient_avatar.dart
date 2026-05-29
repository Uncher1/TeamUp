import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Circular avatar with the mockup's indigo→purple gradient and a white initial.
class GradientAvatar extends StatelessWidget {
  final String name;
  final double size;
  const GradientAvatar({super.key, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.avatarGradient,
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
