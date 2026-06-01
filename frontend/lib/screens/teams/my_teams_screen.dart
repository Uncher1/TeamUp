// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/conversation.dart';
import '../../models/project.dart';
import '../../providers/auth_provider.dart';
import '../../providers/projects_provider.dart';
import '../../repositories/chat_repo.dart';
import '../../repositories/project_repo.dart';
import '../chat/chat_thread_screen.dart';

/// Opens (find-or-create) the project's team chat.
Future<void> _openProjectChat(BuildContext context, Project p) async {
  final chat = context.read<ChatRepository>();
  final navigator = Navigator.of(context);
  try {
    final convId = await chat.projectConversationId(p.id);
    navigator.push(MaterialPageRoute(
      builder: (_) => ChatThreadScreen(
        conversation: Conversation(
          id: convId,
          type: 'project',
          projectId: p.id,
          projectOwnerId: p.ownerId,
          projectTitle: p.title,
          projectAvatar: p.avatarUrl,
        ),
      ),
    ));
  } catch (_) {/* ignore — tapping again retries */}
}

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  List<Map<String, dynamic>> _invites = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().loadMine();
      _loadInvites();
    });
  }

  Future<void> _loadInvites() async {
    try {
      final inv = await context.read<ProjectRepository>().myTeamInvites();
      if (mounted) setState(() => _invites = inv);
    } catch (_) {}
  }

  Future<void> _acceptInvite(int projectId) async {
    final projects = context.read<ProjectRepository>();
    final provider = context.read<ProjectsProvider>();
    try {
      await projects.acceptTeamInvite(projectId);
    } catch (_) {}
    await provider.loadMine();
    await _loadInvites();
  }

  Future<void> _declineInvite(int projectId) async {
    try {
      await context.read<ProjectRepository>().declineTeamInvite(projectId);
    } catch (_) {}
    await _loadInvites();
  }

  Widget _inviteCard(BuildContext context, Map<String, dynamic> inv) {
    final projectId = inv['project_id'] as int;
    final title = inv['title'] as String? ?? '';
    final inviter = inv['inviter_name'] as String? ?? '';
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            GradientAvatar(name: title, size: 44, imageUrl: inv['avatar_url'] as String?),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('team.invitedYou', {'name': inviter}),
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
              tooltip: context.tr('team.accept'),
              onPressed: () => _acceptInvite(projectId),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: context.tr('team.decline'),
              onPressed: () => _declineInvite(projectId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Project p) async {
    final provider = context.read<ProjectsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('mod.deleteProject')),
        content: Text(context.tr('mod.deleteProjectConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.deleteProject(p.id);
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
          if (_invites.isNotEmpty) ...[
            SectionLabel(context.tr('team.invitesTitle')),
            const SizedBox(height: 8),
            for (final inv in _invites) _inviteCard(context, inv),
            const SizedBox(height: 16),
          ],
          if (provider.myProjects.isEmpty)
            EmptyState(
              icon: Icons.groups_2_outlined,
              title: context.tr('mt.emptyTitle'),
              subtitle: context.tr('mt.emptySub'),
            )
          else
            for (final p in provider.myProjects) ...[
              Builder(builder: (context) {
                final me = context.read<AuthProvider>().user;
                final canDelete = me != null &&
                    (me.role == 'moderator' || me.role == 'admin' || p.ownerId == me.id);
                return _TeamCard(
                  project: p,
                  onDelete: canDelete ? () => _confirmDelete(context, p) : null,
                );
              }),
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
  final VoidCallback? onDelete; // null = viewer can't delete this project
  const _TeamCard({required this.project, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors(context, project.status);
    final palette = context.palette;

    // Build meta items (only when non-null)
    final metaItems = <_MetaItem>[
      if (project.category != null)
        _MetaItem(
            icon: Icons.category_outlined,
            label: () {
              final l = context.tr('category.${project.category}');
              return l.startsWith('category.') ? project.category! : l;
            }()),
      if (project.teamSize != null)
        _MetaItem(
            icon: Icons.group_outlined,
            label: '${project.teamSize} ${context.tr(project.teamSize! > 1 ? 'mt.membersP' : 'mt.member')}'),
      if (project.timeline != null)
        _MetaItem(
            icon: Icons.schedule,
            label: context.tr('timeline.${project.timeline}')),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openProjectChat(context, project),
      child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientAvatar(name: project.title, size: 48, imageUrl: project.avatarUrl),
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
              if (onDelete != null)
                PopupMenuButton<int>(
                  icon: Icon(Icons.more_horiz, size: 20, color: palette.textMuted),
                  padding: EdgeInsets.zero,
                  onSelected: (_) => onDelete!(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 0,
                      child: Text(context.tr('mod.deleteProject'),
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
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
                      child: GradientAvatar(
                          name: entry.value.fullName,
                          size: 30,
                          imageUrl: entry.value.avatarUrl,
                          presenceStatus: entry.value.presenceStatus),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _MetaItem {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});
}

