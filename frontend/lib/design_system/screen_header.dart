import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Sticky in-phone screen header with a back chevron + title (for sub-screens).
class ScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const ScreenHeader({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.slate100)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...actions,
        ],
      ),
    );
  }
}
