// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Sticky in-phone screen header with a back chevron + title (for sub-screens).
class ScreenHeader extends StatelessWidget {
  final String title;

  /// Optional custom title (e.g. avatar + name). Takes precedence over [title].
  final Widget? titleWidget;
  final List<Widget> actions;
  const ScreenHeader({
    super.key,
    this.title = '',
    this.titleWidget,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(bottom: BorderSide(color: context.palette.slate100)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: titleWidget ??
                Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...actions,
        ],
      ),
    );
  }
}
