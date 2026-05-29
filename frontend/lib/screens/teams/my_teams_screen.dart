import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.mineError != null && provider.myProjects.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
        const SizedBox(height: 12),
        Center(child: Text(provider.mineError!, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(child: OutlinedButton(onPressed: () => context.read<ProjectsProvider>().loadMine(), child: const Text('Réessayer'))),
      ]);
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ProjectsProvider>().loadMine(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          GradientBanner(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tu fais partie de',
                        style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('${provider.myProjects.length} équipe${provider.myProjects.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
                  ],
                ),
                const Icon(Icons.groups_outlined, color: Colors.white, size: 36),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (provider.myProjects.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(child: Text('Tu ne fais partie d\'aucune équipe.', style: TextStyle(color: AppTheme.textMuted))),
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

(Color, Color) _statusColors(String status) {
  switch (status) {
    case 'active':
    case 'open':
      return (const Color(0xFFD1FAE5), const Color(0xFF059669));
    case 'completed':
      return (const Color(0xFFE0E7FF), const Color(0xFF4F46E5));
    case 'paused':
      return (const Color(0xFFFEF3C7), const Color(0xFFD97706));
    default:
      return (AppTheme.slate100, const Color(0xFF475569));
  }
}

class _TeamCard extends StatelessWidget {
  final Project project;
  const _TeamCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors(project.status);
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
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: project.status, bg: bg, fg: fg),
            ],
          ),
          const SizedBox(height: 12),
          Text('${project.members.length} membre${project.members.length > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: -10,
            children: [
              for (final m in project.members.take(5))
                Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: GradientAvatar(name: m.fullName, size: 32),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
