import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().loadMine();
    });
  }

  Future<void> _message(MatchedUser u) async {
    final repo = context.read<ChatRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final conv = await repo.getOrCreateDirect(u.id);
      if (!mounted) return;
      navigator.push(MaterialPageRoute(builder: (_) => ChatThreadScreen(conversation: conv)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir la conversation")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectsProvider>();
    final matching = context.watch<MatchingProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Choisis un de tes projets pour voir les profils les mieux classés.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        if (projects.loadingMine && projects.myProjects.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
        else if (projects.myProjects.isEmpty)
          AppCard(
            child: Text('Crée d\'abord un projet pour trouver des coéquipiers.',
                style: TextStyle(color: AppTheme.textMuted)),
          )
        else
          DropdownButtonFormField<int>(
            initialValue: matching.selectedProjectId,
            decoration: const InputDecoration(labelText: 'Mon projet'),
            items: [
              for (final p in projects.myProjects)
                DropdownMenuItem(value: p.id, child: Text(p.title, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (id) {
              if (id != null) context.read<MatchingProvider>().loadCandidates(id);
            },
          ),
        const SizedBox(height: 16),
        ..._results(matching),
      ],
    );
  }

  List<Widget> _results(MatchingProvider matching) {
    if (matching.selectedProjectId == null) return const [];
    if (matching.loadingCandidates) {
      return const [Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))];
    }
    if (matching.candidatesError != null) {
      return [Center(child: Text(matching.candidatesError!, style: TextStyle(color: AppTheme.textMuted)))];
    }
    if (matching.candidates.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(child: Text('Aucun profil classé pour ce projet.', style: TextStyle(color: AppTheme.textMuted))),
        ),
      ];
    }
    final widgets = <Widget>[];
    for (final u in matching.candidates) {
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
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: '$scorePct%', bg: AppTheme.itemHoverBg, fg: AppTheme.primaryHover),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _matchChip('Compétences', user.skillMatch),
              const SizedBox(width: 8),
              _matchChip('Intérêts', user.interestMatch),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.slate100, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitations à venir')),
                  ),
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('Inviter'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _matchChip(String label, double value) {
    final pct = (value * 100).clamp(0, 100).round();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
