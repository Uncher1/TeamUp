import 'package:flutter/material.dart';

import '../core/app_strings.dart';

/// Small shield shown next to a user's name to mark their moderation role:
/// dark-blue shield = moderator, red shield = admin (Discord-style). Renders
/// nothing for a regular user.
class RoleBadge extends StatelessWidget {
  final String role;
  final double size;
  const RoleBadge({super.key, required this.role, this.size = 15});

  static const _adminColor = Color(0xFFDC2626); // red
  static const _modColor = Color(0xFF1E40AF); // dark blue

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (role == 'admin') {
      color = _adminColor;
      label = context.tr('role.admin');
    } else if (role == 'moderator') {
      color = _modColor;
      label = context.tr('role.moderator');
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Tooltip(
        message: label,
        child: Icon(Icons.shield, size: size, color: color),
      ),
    );
  }
}
