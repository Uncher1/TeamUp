import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/project.dart';
import '../../providers/projects_provider.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().loadMine();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();
    if (provider.loadingMine && provider.myProjects.isEmpty) {
      return const SingleChildScrollView(child: SkeletonList());
    }
    if (provider.mineError != null && provider.myProjects.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 48, color: context.palette.textMuted),
        const SizedBox(height: 12),
        Center(child: Text(provider.mineError!, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(child: OutlinedButton(onPressed: () => context.read<ProjectsProvider>().loadMine(), child: Text(context.tr('feed.retry')))),
      ]);
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ProjectsProvider>().loadMine(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          GradientBanner(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('mt.partOf'),
                        style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('${provider.myProjects.length} ${context.tr(provider.myProjects.length > 1 ? 'mt.teamsP' : 'mt.team')}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
                  ],
                ),
                const Icon(Icons.groups_outlined, color: Colors.white, size: 36),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (provider.myProjects.isEmpty)
            EmptyState(
              icon: Icons.groups_2_outlined,
              title: context.tr('mt.emptyTitle'),
              subtitle: context.tr('mt.emptySub'),
            )
          else
            for (final p in provider.myProjects) ...[
              _TeamCard(project: p),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

(Color, Color) _statusColors(BuildContext context, String status) {
  switch (status) {
    case 'active':
    case 'open':
      return (const Color(0xFFD1FAE5), const Color(0xFF059669));
    case 'completed':
      return (const Color(0xFFE0E7FF), const Color(0xFF4F46E5));
    case 'paused':
      return (const Color(0xFFFEF3C7), const Color(0xFFD97706));
    default:
      return (context.palette.slate100, context.palette.textMuted);
  }
}

class _TeamCard extends StatelessWidget {
  final Project project;
  const _TeamCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors(context, project.status);
    final palette = context.palette;

    // Build meta items (only when non-null)
    final metaItems = <_MetaItem>[
      if (project.category != null)
        _MetaItem(icon: Icons.category_outlined, label: project.category!),
      if (project.teamSize != null)
        _MetaItem(
            icon: Icons.group_outlined,
            label: '${project.teamSize} ${context.tr(project.teamSize! > 1 ? 'mt.membersP' : 'mt.member')}'),
      if (project.timeline != null)
        _MetaItem(
            icon: Icons.schedule,
            label: context.tr('timeline.${project.timeline}')),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientAvatar(name: project.title, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (project.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(project.description,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: palette.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: context.tr('status.${project.status}'), bg: bg, fg: fg),
            ],
          ),
          if (metaItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final item in metaItems)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 13, color: palette.textMuted),
                      const SizedBox(width: 4),
                      Text(item.label,
                          style: TextStyle(fontSize: 12, color: palette.textMuted)),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text('${project.members.length} ${context.tr(project.members.length > 1 ? 'mt.membersP' : 'mt.member')}',
              style: TextStyle(fontSize: 12, color: palette.textMuted)),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: Stack(
              children: [
                for (final entry in project.members.take(5).toList().asMap().entries)
                  Positioned(
                    left: entry.key * 22.0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: palette.surface, shape: BoxShape.circle),
                      child: GradientAvatar(name: entry.value.fullName, size: 30),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});
}

