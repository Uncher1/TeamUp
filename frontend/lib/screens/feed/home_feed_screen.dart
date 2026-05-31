// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../repositories/feed_repo.dart';
import '../profile/user_profile_screen.dart';
import 'comments_sheet.dart';
import 'create_post_sheet.dart';

/// Opens a post author's public profile.
void _openAuthor(BuildContext context, Post post) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => UserProfileScreen(
      userId: post.authorId,
      initialName: post.authorName,
      initialAvatar: post.authorAvatar,
    ),
  ));
}

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

  Future<void> _deletePost(Post p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('mod.deletePost')),
        content: Text(context.tr('mod.deletePostConfirm')),
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
    if (confirmed == true && mounted) {
      await context.read<FeedProvider>().deletePost(p.id);
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

  Future<void> _share(Post p) async {
    final text = '${p.authorName}: ${p.content}';
    // Native share sheet on Android/iOS (the APK target).
    if (!kIsWeb) {
      await Share.share(text);
      return;
    }
    // Web: a desktop browser often has no native share sheet, so show our own
    // bottom sheet with the text + a copy action (always visible feedback).
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ShareSheet(text: text),
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
        Center(child: OutlinedButton(onPressed: () => context.read<FeedProvider>().load(), child: Text(context.tr('feed.retry')))),
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
              title: context.tr('feed.emptyTitle'),
              subtitle: context.tr('feed.emptySub'),
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
            final me = context.read<AuthProvider>().user;
            final canDelete = me != null &&
                (me.role == 'moderator' || me.role == 'admin' || p.authorId == me.id);
            return _PostCard(
                post: p,
                onLike: () => context.read<FeedProvider>().toggleLike(p),
                onComment: () => _openComments(p),
                onShare: () => _share(p),
                onDelete: canDelete ? () => _deletePost(p) : null,
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
              child: Text(context.tr('feed.composeHint'), style: TextStyle(color: context.palette.textMuted)),
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

const _typeIcons = {
  'project_launch': Icons.bolt,
  'team_update': Icons.groups_outlined,
  'looking_for': Icons.search,
  'milestone': Icons.flag_outlined,
  'general': Icons.notes,
};

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onDelete; // null = viewer can't delete this post
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcons[post.type] ?? Icons.notes;
    final label = context.tr('posttype.${post.type}');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openAuthor(context, post),
                child: GradientAvatar(
                    name: post.authorName, size: 44, imageUrl: post.authorAvatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                            child: GestureDetector(
                                onTap: () => _openAuthor(context, post),
                                child: Text(post.authorName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis))),
                        RoleBadge(role: post.authorRole),
                        const SizedBox(width: 8),
                        TypeBadge(type: post.type, label: label, icon: icon),
                      ],
                    ),
                    Text(timeAgo(context, post.createdAt), style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
                  ],
                ),
              ),
              if (onDelete != null)
                PopupMenuButton<int>(
                  icon: Icon(Icons.more_horiz, size: 20, color: context.palette.textMuted),
                  padding: EdgeInsets.zero,
                  onSelected: (_) => onDelete!(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 0,
                      child: Text(context.tr('mod.deletePost'),
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
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
              _action(icon: Icons.share_outlined, label: context.tr('feed.share'), color: context.palette.textMuted, onTap: onShare),
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

}

/// Web share sheet: shows the post text + a copy action (desktop browsers
/// usually have no native share sheet).
class _ShareSheet extends StatelessWidget {
  final String text;
  const _ShareSheet({required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: p.slate200, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.tr('feed.shareTitle'),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: p.slate100, borderRadius: BorderRadius.circular(12)),
              child: Text(text, style: TextStyle(fontSize: 13, color: p.textPrimary)),
            ),
            const SizedBox(height: 16),
            AppButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final copiedMsg = context.tr('feed.copied');
                try {
                  await Clipboard.setData(ClipboardData(text: text));
                } catch (_) {}
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(copiedMsg)),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.copy, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(context.tr('feed.copy')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
