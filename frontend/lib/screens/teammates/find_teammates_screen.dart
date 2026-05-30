import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/match.dart';
import '../../providers/matching_provider.dart';
import '../../providers/projects_provider.dart';
import '../../repositories/chat_repo.dart';
import '../chat/chat_thread_screen.dart';

class FindTeammatesScreen extends StatefulWidget {
  const FindTeammatesScreen({super.key});

  @override
  State<FindTeammatesScreen> createState() => _FindTeammatesScreenState();
}

class _FindTeammatesScreenState extends State<FindTeammatesScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().loadMine();
      final sid = context.read<MatchingProvider>().selectedProjectId;
      if (sid != null) context.read<MatchingProvider>().loadCandidates(sid);
    });
  }

  Future<void> _message(MatchedUser u) async {
    final repo = context.read<ChatRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errMsg = context.tr('ft.convErr');
    try {
      final conv = await repo.getOrCreateDirect(u.id);
      if (!mounted) return;
      navigator.push(MaterialPageRoute(builder: (_) => ChatThreadScreen(conversation: conv)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectsProvider>();
    final matching = context.watch<MatchingProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(context.tr('ft.intro'),
            style: TextStyle(fontSize: 13, color: context.palette.textMuted)),
        const SizedBox(height: 12),
        if (projects.loadingMine && projects.myProjects.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
        else if (projects.mineError != null && projects.myProjects.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(projects.mineError!, style: TextStyle(color: context.palette.textMuted)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.read<ProjectsProvider>().loadMine(),
                  child: Text(context.tr('feed.retry')),
                ),
              ],
            ),
          )
        else if (projects.myProjects.isEmpty)
          AppCard(
            child: Text(context.tr('ft.noProjects'),
                style: TextStyle(color: context.palette.textMuted)),
          )
        else
          DropdownButtonFormField<int>(
            initialValue: matching.selectedProjectId,
            decoration: InputDecoration(labelText: context.tr('ft.myProject')),
            items: [
              for (final p in projects.myProjects)
                DropdownMenuItem(value: p.id, child: Text(p.title, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (id) {
              if (id != null) context.read<MatchingProvider>().loadCandidates(id);
            },
          ),
        if (matching.selectedProjectId != null &&
            !matching.loadingCandidates &&
            matching.candidates.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: context.tr('ft.searchHint'),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ..._results(context, matching),
      ],
    );
  }

  List<Widget> _results(BuildContext context, MatchingProvider matching) {
    if (matching.selectedProjectId == null) return const [];
    if (matching.loadingCandidates) {
      return const [SkeletonList()];
    }
    if (matching.candidatesError != null) {
      return [Center(child: Text(matching.candidatesError!, style: TextStyle(color: context.palette.textMuted)))];
    }
    if (matching.candidates.isEmpty) {
      return [
        EmptyState(
          icon: Icons.person_search_outlined,
          title: context.tr('ft.emptyTitle'),
          subtitle: context.tr('ft.emptySub'),
        ),
      ];
    }
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? matching.candidates
        : matching.candidates
            .where((u) =>
                u.fullName.toLowerCase().contains(q) ||
                (u.email?.toLowerCase().contains(q) ?? false))
            .toList();
    if (filtered.isEmpty) {
      return [
        EmptyState(
          icon: Icons.search_off,
          title: context.tr('ft.noResultTitle'),
          subtitle: context.tr('ft.noResultSub', {'q': _query}),
        ),
      ];
    }
    final widgets = <Widget>[];
    for (final u in filtered) {
      widgets.add(_CandidateCard(user: u, onMessage: () => _message(u)));
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }
}

class _CandidateCard extends StatelessWidget {
  final MatchedUser user;
  final VoidCallback onMessage;
  const _CandidateCard({required this.user, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final scorePct = (user.score * 100).clamp(0, 100).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientAvatar(name: user.fullName, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (user.email != null) ...[
                      const SizedBox(height: 2),
                      Text(user.email!,
                          style: TextStyle(fontSize: 12, color: context.palette.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: '$scorePct%', bg: context.palette.itemHoverBg, fg: context.palette.primaryHover),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _matchChip(context, context.tr('ft.skills'), user.skillMatch),
              const SizedBox(width: 8),
              _matchChip(context, context.tr('ft.interests'), user.interestMatch),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: context.palette.slate100, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('ft.invitesSoon'))),
                  ),
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: Text(context.tr('ft.invite')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(context.tr('ft.message')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _matchChip(BuildContext context, String label, double value) {
    final pct = (value * 100).clamp(0, 100).round();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: context.palette.slate100, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: context.palette.textMuted)),
            const SizedBox(height: 2),
            Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
