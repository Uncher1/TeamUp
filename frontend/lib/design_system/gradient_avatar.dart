// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Circular avatar with the mockup's indigo→purple gradient and a white initial.
/// When [imageUrl] is provided and non-empty, the photo is displayed instead.
class GradientAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;

  /// Discord-style presence: 'online' (green), 'dnd' (red), 'offline' (grey).
  /// When null, no status dot is drawn.
  final String? presenceStatus;

  const GradientAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.imageUrl,
    this.presenceStatus,
  });

  /// Color for a presence value, or null if it should not be shown.
  static Color? presenceColor(String? status) {
    switch (status) {
      case 'online':
        return const Color(0xFF22C55E); // green
      case 'dnd':
        return const Color(0xFFEF4444); // red
      case 'offline':
        return const Color(0xFF94A3B8); // grey
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();
    final dotColor = presenceColor(presenceStatus);
    if (dotColor == null) return avatar;
    // Ring matches the surrounding surface so the dot reads as "on top of".
    final ring = context.palette.surface;
    final dot = size * 0.30;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: dot * 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
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
