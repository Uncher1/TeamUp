// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Small coloured pill (icon + label) keyed off a post/notification type.
class TypeBadge extends StatelessWidget {
  final String type;
  final String label;
  final IconData icon;
  const TypeBadge({super.key, required this.type, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppTheme.typeColors(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
