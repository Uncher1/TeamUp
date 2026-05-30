import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../repositories/feed_repo.dart';

class CommentsSheet extends StatefulWidget {
  final int postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  List<Comment> _comments = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadComments());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final repo = context.read<FeedRepository>();
    try {
      final comments = await repo.listComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.messageFromError(e);
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    final repo = context.read<FeedRepository>();
    final feedProvider = context.read<FeedProvider>();

    setState(() => _sending = true);
    try {
      final comment = await repo.addComment(widget.postId, text);
      if (!mounted) return;
      _textController.clear();
      setState(() {
        _comments = [..._comments, comment];
        _sending = false;
      });
      feedProvider.bumpCommentCount(widget.postId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    }
  }

  Future<void> _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    // Hoist context reads before any await
    final repo = context.read<FeedRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('feed.editComment')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(hintText: context.tr('feed.commentContent')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('common.save')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final newText = controller.text.trim();
    if (newText.isEmpty) return;

    try {
      final updated = await repo.editComment(widget.postId, comment.id, newText);
      if (!mounted) return;
      setState(() {
        final idx = _comments.indexWhere((c) => c.id == comment.id);
        if (idx != -1) _comments = [..._comments]..[idx] = updated;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    // Hoist context reads before any await
    final repo = context.read<FeedRepository>();
    final feedProvider = context.read<FeedProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('feed.deleteCommentTitle')),
        content: Text(context.tr('feed.irreversible')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await repo.deleteComment(widget.postId, comment.id);
      if (!mounted) return;
      setState(() {
        _comments = _comments.where((c) => c.id != comment.id).toList();
      });
      feedProvider.decrementCommentCount(widget.postId);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.slate200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr('feed.commentsTitle'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: context.palette.slate100, height: 1),
          // Comments list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _buildList(),
          ),
          Divider(color: context.palette.slate100, height: 1),
          // Input row
          _buildInputRow(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const SingleChildScrollView(child: SkeletonList(count: 3));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: TextStyle(color: context.palette.textMuted), textAlign: TextAlign.center),
        ),
      );
    }
    if (_comments.isEmpty) {
      return EmptyState(
        icon: Icons.mode_comment_outlined,
        title: context.tr('feed.noCommentsTitle'),
        subtitle: context.tr('feed.noCommentsSub'),
      );
    }
    final myId = context.read<AuthProvider>().user?.id;
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: _comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = _comments[i];
        return _CommentRow(
          comment: c,
          isOwn: myId != null && c.authorId == myId,
          onEdit: () => _editComment(c),
          onDelete: () => _deleteComment(c),
        );
      },
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: context.tr('feed.commentHint'),
                hintStyle: TextStyle(color: context.palette.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: context.palette.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: context.palette.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: context.palette.slate100,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              maxLines: null,
              minLines: 1,
            ),
          ),
          PressableScale(
            onPressed: _send,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: _sending
                    ? context.palette.slate200
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CommentAction { edit, delete }

class _CommentRow extends StatelessWidget {
  final Comment comment;
  final bool isOwn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommentRow({
    required this.comment,
    required this.isOwn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientAvatar(
          name: comment.authorName,
          imageUrl: comment.authorAvatar,
          size: 36,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  RoleBadge(role: comment.authorRole, size: 13),
                ],
              ),
              const SizedBox(height: 2),
              Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.4)),
              const SizedBox(height: 2),
              Text(
                timeAgo(context, comment.createdAt),
                style: TextStyle(fontSize: 11, color: context.palette.textMuted),
              ),
            ],
          ),
        ),
        if (isOwn)
          PopupMenuButton<_CommentAction>(
            icon: Icon(Icons.more_horiz, size: 18, color: context.palette.textMuted),
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == _CommentAction.edit) {
                onEdit();
              } else {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _CommentAction.edit,
                child: Text(context.tr('common.edit')),
              ),
              PopupMenuItem(
                value: _CommentAction.delete,
                child: Text(context.tr('common.delete'),
                    style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
      ],
    );
  }

}
