import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/post.dart';
import '../../providers/feed_provider.dart';
import 'create_post_sheet.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().load();
    });
  }

  Future<void> _openComposer() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FeedProvider>(),
        child: const CreatePostSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    return RefreshIndicator(
      onRefresh: () => context.read<FeedProvider>().load(),
      child: _body(provider),
    );
  }

  Widget _body(FeedProvider provider) {
    if (provider.loading && provider.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.posts.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 48, color: context.palette.textMuted),
        const SizedBox(height: 12),
        Center(child: Text(provider.error!, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(child: OutlinedButton(onPressed: () => context.read<FeedProvider>().load(), child: const Text('Réessayer'))),
      ]);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _QuickPostBar(onTap: _openComposer),
        const SizedBox(height: 12),
        if (provider.posts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(child: Text('Aucun post pour le moment.', style: TextStyle(color: context.palette.textMuted))),
          )
        else
          for (final p in provider.posts) ...[
            _PostCard(post: p, onLike: () => context.read<FeedProvider>().toggleLike(p)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _QuickPostBar extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickPostBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: context.palette.slate100, borderRadius: BorderRadius.circular(14)),
              child: Text('Partage quelque chose...', style: TextStyle(color: context.palette.textMuted)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

const _typeMeta = {
  'project_launch': (Icons.bolt, 'project launch'),
  'team_update': (Icons.groups_outlined, 'team update'),
  'looking_for': (Icons.search, 'looking for'),
  'milestone': (Icons.flag_outlined, 'milestone'),
  'general': (Icons.notes, 'general'),
};

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  const _PostCard({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _typeMeta[post.type] ?? (Icons.notes, post.type);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientAvatar(name: post.authorName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        TypeBadge(type: post.type, label: label, icon: icon),
                      ],
                    ),
                    Text(_ago(post.createdAt), style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content, style: const TextStyle(height: 1.4)),
          if (post.projectTitle != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: context.palette.itemHoverBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 14, color: context.palette.primaryHover),
                  const SizedBox(width: 6),
                  Flexible(child: Text(post.projectTitle!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.palette.primaryHover), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: context.palette.slate100, height: 1),
          const SizedBox(height: 4),
          Row(
            children: [
              _action(
                icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                label: '${post.likeCount}',
                color: post.likedByMe ? const Color(0xFFE11D48) : context.palette.textMuted,
                onTap: onLike,
              ),
              _action(icon: Icons.mode_comment_outlined, label: '${post.commentCount}', color: context.palette.textMuted, onTap: () {}),
              _action(icon: Icons.share_outlined, label: 'Partager', color: context.palette.textMuted, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return "à l'instant";
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    return 'il y a ${d.inDays} j';
  }
}
