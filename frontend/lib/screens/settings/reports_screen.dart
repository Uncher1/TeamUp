// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../repositories/admin_repo.dart';
import '../profile/user_profile_screen.dart';

/// Admin-only queue of user reports: who reported whom, why, with details.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>>? _reports;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final r = await context.read<AdminRepository>().listReports();
      if (!mounted) return;
      setState(() {
        _reports = r;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reports = _reports ?? [];
    return SettingsScaffold(
      title: context.tr('admin.reports'),
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (reports.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(context.tr('admin.reportsEmpty'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.textMuted)),
          )
        else
          for (final r in reports) _card(context, r),
      ],
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> r) {
    final p = context.palette;
    final reason = r['reason'] as String? ?? 'other';
    final details = (r['details'] as String? ?? '').trim();
    final reportedId = r['reported_user_id'] as int;
    final created = DateTime.tryParse(r['created_at']?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientAvatar(
                    name: r['reported_name'] as String? ?? '?',
                    size: 40,
                    imageUrl: r['reported_avatar'] as String?),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['reported_name'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      StatusPill(
                          label: context.tr('report.$reason'),
                          bg: const Color(0xFFFEE2E2),
                          fg: const Color(0xFFDC2626)),
                    ],
                  ),
                ),
                if (created != null)
                  Text(timeAgo(context, created),
                      style: TextStyle(fontSize: 11, color: p.textMuted)),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(details, style: const TextStyle(fontSize: 13, height: 1.4)),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${context.tr('admin.reportBy')}: ${r['reporter_name'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserProfileScreen(
                      userId: reportedId,
                      initialName: r['reported_name'] as String?,
                      initialAvatar: r['reported_avatar'] as String?,
                    ),
                  )),
                  child: Text(context.tr('admin.viewProfile')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
