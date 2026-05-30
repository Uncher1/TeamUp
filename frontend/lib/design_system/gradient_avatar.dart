import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Circular avatar with the mockup's indigo→purple gradient and a white initial.
/// When [imageUrl] is provided and non-empty, the photo is displayed instead.
class GradientAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;

  const GradientAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      Widget photo;
      if (imageUrl!.startsWith('data:')) {
        final bytes = base64Decode(imageUrl!.split(',').last);
        photo = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, a, b) => _GradientInitial(name: name, size: size),
        );
      } else {
        photo = Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, a, b) => _GradientInitial(name: name, size: size),
        );
      }
      return ClipOval(
        child: SizedBox(width: size, height: size, child: photo),
      );
    }
    return _GradientInitial(name: name, size: size);
  }
}

/// Private helper — gradient circle with white initial. Extracted so both the
/// no-image path and error-fallback paths reuse identical rendering.
class _GradientInitial extends StatelessWidget {
  final String name;
  final double size;

  const _GradientInitial({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientFor(Theme.of(context).colorScheme.primary),
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
