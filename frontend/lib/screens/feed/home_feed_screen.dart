import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/post.dart';
import '../../providers/feed_provider.dart';
import '../../repositories/feed_repo.dart';
import 'comments_sheet.dart';
import 'create_post_sheet.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<FeedProvider>().loadMore();
    }
  }

  Future<void> _openComments(Post post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<FeedProvider>()),
          Provider.value(value: context.read<FeedRepository>()),
        ],
        child: CommentsSheet(postId: post.id),
      ),
    );
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
      return const SingleChildScrollView(child: SkeletonList());
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

    final hasPosts = provider.posts.isNotEmpty;
    // Item count: header bar + (posts * 2 items each with spacer) + optional footer
    // We use a flat children list instead of itemBuilder for simplicity, same as before,
    // but switch to ListView.builder for the scroll controller to attach properly.
    final postItems = hasPosts ? provider.posts : <Post>[];
    // Build item count: 1 (quick post bar) + 1 (spacer) + posts*2 (card + spacer) + 1 empty/footer
    final baseCount = 2 + (hasPosts ? postItems.length * 2 : 1);
    final showFooter = hasPosts && (provider.loadingMore || !provider.hasMore);
    final itemCount = baseCount + (showFooter ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // index 0: quick post bar
        if (index == 0) return _QuickPostBar(onTap: _openComposer);
        // index 1: spacer after bar
        if (index == 1) {
          if (!hasPosts) {
            return EmptyState(
              icon: Icons.dynamic_feed_outlined,
              title: 'Aucun post pour l\'instant',
              subtitle: 'Sois le premier à partager quelque chose avec ta communauté.',
            );
          }
          return const SizedBox(height: 12);
        }
        // posts start at index 2
        if (hasPosts) {
          final postIndex = index - 2;
          final cardIndex = postIndex ~/ 2;
          final isSpacer = postIndex.isOdd;
          if (cardIndex < postItems.length) {
            if (isSpacer) return const SizedBox(height: 12);
            final p = postItems[cardIndex];
            return _PostCard(
                post: p,
                onLike: () => context.read<FeedProvider>().toggleLike(p),
                onComment: () => _openComments(p),
                onShare: () => Share.share('${p.authorName}: ${p.content}'),
              );
          }
        }
        // Footer: loading more indicator or end marker
        if (provider.loadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        // !hasMore — minimal end marker
        return const SizedBox.shrink();
      },
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
          child: PressableScale(
            onPressed: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: context.palette.slate100, borderRadius: BorderRadius.circular(14)),
              child: Text('Partage quelque chose...', style: TextStyle(color: context.palette.textMuted)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        PressableScale(
          onPressed: onTap,
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
  final VoidCallback onComment;
  final VoidCallback onShare;
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

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
              _action(icon: Icons.mode_comment_outlined, label: '${post.commentCount}', color: context.palette.textMuted, onTap: onComment),
              _action(icon: Icons.share_outlined, label: 'Partager', color: context.palette.textMuted, onTap: onShare),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: PressableScale(
        onPressed: onTap,
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
