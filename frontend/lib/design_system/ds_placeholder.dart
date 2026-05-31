// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Temporary styled placeholder for sections rebuilt in a later wave.
class DSPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  const DSPlaceholder({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Bientôt disponible', style: TextStyle(color: context.palette.textMuted)),
        ],
      ),
    );
  }
}
