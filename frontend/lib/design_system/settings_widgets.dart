// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'screen_header.dart';

/// Standard sub-page wrapper: sticky header with a back chevron + scrolling body.
class SettingsScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingsScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uppercase muted group label (mockup: text-xs slate-400 uppercase tracking-wider).
/// Optional [subtitle] renders a normal-case descriptive line below (mockup
/// SectionHeader subtitle).
class SettingsSectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;
  const SettingsSectionLabel(this.text, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: muted,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A tappable settings row: circular icon, label, optional subtitle, trailing.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = danger ? const Color(0xFFDC2626) : p.textPrimary;
    final iconFg = danger ? const Color(0xFFDC2626) : p.textMuted;
    final iconBg = danger ? const Color(0xFFFEE2E2) : p.slate100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.slate200),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: iconFg),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(fontSize: 12, color: p.textMuted),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    (onTap != null
                        ? Icon(Icons.chevron_right, size: 20, color: p.textMuted)
                        : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A settings row whose trailing is a Switch (icon + label + desc + toggle).
class SettingToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  const SettingToggleTile({
    super.key,
    required this.icon,
    required this.label,
    this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.slate200),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.slate100, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: p.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: p.textPrimary)),
                  if (desc != null) ...[
                    const SizedBox(height: 2),
                    Text(desc!, style: TextStyle(fontSize: 12, color: p.textMuted)),
                  ],
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
