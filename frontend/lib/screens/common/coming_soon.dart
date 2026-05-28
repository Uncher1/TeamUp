import 'package:flutter/material.dart';

import '../../core/theme.dart';

class ComingSoon extends StatelessWidget {
  final String title;
  final IconData icon;
  final String note;
  const ComingSoon({
    super.key,
    required this.title,
    required this.icon,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(note, style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
