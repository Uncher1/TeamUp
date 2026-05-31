// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';

import '../core/app_strings.dart';

/// Small colored role badge shown next to a user's name:
/// red medal = admin, blue gavel = moderator. Tapping it reveals the localized
/// role label ("Administrator" / "Moderator") just above, for ~2s. Renders
/// nothing for a regular user.
class RoleBadge extends StatelessWidget {
  final String role;
  final double size;
  const RoleBadge({super.key, required this.role, this.size = 13});

  static const _adminColor = Color(0xFFDC2626); // red
  static const _modColor = Color(0xFF2563EB); // blue

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;
    if (role == 'admin') {
      color = _adminColor;
      icon = Icons.workspace_premium; // medal/crown → authority
      label = context.tr('role.admin');
    } else if (role == 'moderator') {
      color = _modColor;
      icon = Icons.gavel; // gavel → moderation
      label = context.tr('role.moderator');
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Tooltip(
        message: label,
        triggerMode: TooltipTriggerMode.tap, // show on tap (mobile)
        showDuration: const Duration(seconds: 2),
        preferBelow: false, // appear just above the badge
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        child: Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ),
    );
  }
}
