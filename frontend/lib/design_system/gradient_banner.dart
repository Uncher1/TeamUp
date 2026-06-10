// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Theme-coordinated rounded banner used for hero headers (Create Project, My Teams, Profile).
/// The gradient derives from the active seed color so it stays on-theme when the
/// user picks a different Theme Color.
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientFor(Theme.of(context).colorScheme.primary),
        ),
      ),
      child: child,
    );
  }
}
