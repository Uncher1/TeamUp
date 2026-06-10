// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/link_launcher.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: context.tr('prof.title'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: user == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
              ],
            ),
            if (user == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    GradientBanner(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => showZoomableImage(context, imageUrl: user.avatarUrl),
                            child: GradientAvatar(name: user.fullName, size: 64, imageUrl: user.avatarUrl),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(user.fullName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    RoleBadge(role: user.role, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(user.email,
                                    style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 13),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      SectionLabel(context.tr('prof.about')),
                      const SizedBox(height: 8),
                      Text(user.bio!, style: const TextStyle(height: 1.4)),
                    ],

                    // ── Info block (academic + contact) ──────────────────
                    if (_hasInfoFields(user)) ...[
                      const SizedBox(height: 20),
                      SectionLabel(context.tr('prof.info')),
                      const SizedBox(height: 8),
                      AppCard(
                        child: Column(
                          children: [
                            if (user.isStudent && user.school != null && user.school!.isNotEmpty)
                              _InfoRow(icon: Icons.school_outlined, text: user.school!),
                            if (user.isStudent && user.department != null && user.department!.isNotEmpty)
                              _InfoRow(icon: Icons.account_tree_outlined, text: user.department!),
                            if (user.isStudent && user.studyYear != null && user.studyYear!.isNotEmpty)
                              _InfoRow(icon: Icons.calendar_today_outlined, text: user.studyYear!),
                            if (user.location != null && user.location!.isNotEmpty)
                              _InfoRow(icon: Icons.location_on_outlined, text: user.location!),
                            if (user.phone != null && user.phone!.isNotEmpty)
                              _InfoRow(icon: Icons.phone_outlined, text: user.phone!, isLast: true),
                          ],
                        ),
                      ),
                    ],

                    // ── Social links ─────────────────────────────────────
                    if (_hasSocialFields(user)) ...[
                      const SizedBox(height: 20),
                      SectionLabel(context.tr('prof.links')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.github != null && user.github!.isNotEmpty)
                            _SocialChip(
                              icon: Icons.code,
                              label: 'GitHub',
                              value: user.github!,
                              context: context,
                            ),
                          if (user.linkedin != null && user.linkedin!.isNotEmpty)
                            _SocialChip(
                              icon: Icons.business_center_outlined,
                              label: 'LinkedIn',
                              value: user.linkedin!,
                              context: context,
                            ),
                          if (user.twitter != null && user.twitter!.isNotEmpty)
                            _SocialChip(
                              icon: Icons.alternate_email,
                              label: 'Twitter / X',
                              value: user.twitter!,
                              context: context,
                            ),
                          if (user.website != null && user.website!.isNotEmpty)
                            _SocialChip(
                              icon: Icons.link,
                              label: context.tr('help.website'),
                              value: user.website!,
                              context: context,
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                    SectionLabel(context.tr('cp.skills')),
                    const SizedBox(height: 8),
                    if (user.skills.isEmpty)
                      Text(context.tr('prof.noSkills'), style: TextStyle(color: context.palette.textMuted))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in user.skills)
                            StatusPill(label: '${s.name} · ${s.level}', bg: context.palette.itemHoverBg, fg: context.palette.primaryHover),
                        ],
                      ),
                    const SizedBox(height: 20),
                    SectionLabel(context.tr('proj.themes')),
                    const SizedBox(height: 8),
                    if (user.interests.isEmpty)
                      Text(context.tr('prof.noThemes'), style: TextStyle(color: context.palette.textMuted))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final i in user.interests)
                            StatusPill(label: i.name, bg: context.palette.slate100, fg: context.palette.textMuted),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasInfoFields(User user) =>
      (user.isStudent &&
              ((user.school != null && user.school!.isNotEmpty) ||
                  (user.department != null && user.department!.isNotEmpty) ||
                  (user.studyYear != null && user.studyYear!.isNotEmpty))) ||
      (user.location != null && user.location!.isNotEmpty) ||
      (user.phone != null && user.phone!.isNotEmpty);

  bool _hasSocialFields(User user) =>
      (user.github != null && user.github!.isNotEmpty) ||
      (user.linkedin != null && user.linkedin!.isNotEmpty) ||
      (user.twitter != null && user.twitter!.isNotEmpty) ||
      (user.website != null && user.website!.isNotEmpty);
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLast;

  const _InfoRow({required this.icon, required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.palette.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: context.palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BuildContext context;

  const _SocialChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () => openExternalLink(ctx, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ctx.palette.slate100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: ctx.palette.textMuted),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, color: ctx.palette.textMuted)),
          ],
        ),
      ),
    );
  }
}
