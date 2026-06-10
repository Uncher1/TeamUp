// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/app_strings.dart';

/// Small role glyph shown next to a user's name. The icon ITSELF is colored
/// with a gradient (no background container): red shield-with-person = admin,
/// dark-blue crossed tools = moderator. Tapping it reveals the localized role
/// label just above, for ~2s. Renders nothing for a regular user.
class RoleBadge extends StatelessWidget {
  final String role;
  final double size;
  const RoleBadge({super.key, required this.role, this.size = 17});

  static const _adminGradient = [Color(0xFFF43F5E), Color(0xFFB91C1C)]; // red
  static const _modGradient = [Color(0xFF2563EB), Color(0xFF1E3A8A)]; // dark blue

  @override
  Widget build(BuildContext context) {
    final List<Color> colors;
    final IconData icon;
    final String label;
    if (role == 'admin') {
      colors = _adminGradient;
      icon = Symbols.crown; // crown → top authority
      label = context.tr('role.admin');
    } else if (role == 'moderator') {
      colors = _modGradient;
      icon = Symbols.handyman; // crossed tools (hammer & pick)
      label = context.tr('role.moderator');
    } else {
      return const SizedBox.shrink();
    }
    final gradient = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Tooltip(
        message: label,
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 2),
        preferBelow: false,
        decoration: BoxDecoration(
          color: colors.last,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        // Color the glyph itself with the gradient; no background container.
        child: ShaderMask(
          shaderCallback: (rect) => gradient.createShader(rect),
          blendMode: BlendMode.srcIn,
          child: Icon(icon, size: size, color: Colors.white, fill: 1),
        ),
      ),
    );
  }
}
