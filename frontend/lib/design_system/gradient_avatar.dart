// TeamUp - team-matching social network
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

  /// When true, a small "group" badge is drawn (bottom-right) to mark this
  /// avatar as a team - so a team chat is never confused with a 1:1 DM.
  final bool isTeam;

  const GradientAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.imageUrl,
    this.presenceStatus,
    this.isTeam = false,
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
    // Nothing to overlay → plain avatar.
    if (dotColor == null && !isTeam) return avatar;
    // Ring matches the surrounding surface so the badge reads as "on top of".
    final ring = context.palette.surface;
    // The team badge is a touch bigger than a presence dot (it holds an icon).
    final badge = size * (isTeam ? 0.40 : 0.30);
    final primary = Theme.of(context).colorScheme.primary;
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
              width: badge,
              height: badge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isTeam ? primary : dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: badge * (isTeam ? 0.12 : 0.18)),
              ),
              child: isTeam
                  ? Icon(Icons.groups, size: badge * 0.62, color: Colors.white)
                  : null,
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

/// Opens a black [Dialog] viewer for a profile/team photo with BOTH
/// pinch-to-zoom and double-tap-to-zoom. No-op when there's no actual photo.
void showZoomableImage(BuildContext context, {required String? imageUrl}) {
  if (imageUrl == null || imageUrl.isEmpty) return;
  final Widget image = imageUrl.startsWith('data:')
      ? Image.memory(base64Decode(imageUrl.split(',').last),
          gaplessPlayback: true, errorBuilder: (_, _, _) => const SizedBox.shrink())
      : Image.network(imageUrl, errorBuilder: (_, _, _) => const SizedBox.shrink());
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: _ZoomBody(image: image),
    ),
  );
}

/// Pinch (InteractiveViewer) + double-tap (TransformationController) zoom.
/// The double-tap GestureDetector wraps the viewer; double-tap and the scale
/// recognizer use different pointer counts, so they don't fight (the standard
/// Flutter "zoom a photo" recipe).
class _ZoomBody extends StatefulWidget {
  final Widget image;
  const _ZoomBody({required this.image});

  @override
  State<_ZoomBody> createState() => _ZoomBodyState();
}

class _ZoomBodyState extends State<_ZoomBody> {
  final TransformationController _tc = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_tc.value != Matrix4.identity()) {
      _tc.value = Matrix4.identity(); // already zoomed → reset
      return;
    }
    final pos = _doubleTapDetails?.localPosition ?? Offset.zero;
    const scale = 2.5;
    _tc.value = Matrix4.identity()
      ..translateByDouble(-pos.dx * (scale - 1), -pos.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapDetails = d,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _tc,
        minScale: 1,
        maxScale: 5,
        child: widget.image,
      ),
    );
  }
}

/// Private helper - gradient circle with white initial. Extracted so both the
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
