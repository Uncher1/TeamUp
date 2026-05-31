import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/post.dart';
import '../repositories/feed_repo.dart';

class FeedProvider extends ChangeNotifier {
  final FeedRepository _repo;
  FeedProvider(this._repo);

  static const _pageSize = 10;

  List<Post> posts = [];
  bool loading = false;
  String? error;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  Future<void> load() async {
    loading = true;
    error = null;
    _hasMore = true;
    notifyListeners();
    try {
      final result = await _repo.list(limit: _pageSize);
      posts = result;
      _hasMore = result.length == _pageSize;
    } catch (e) {
      error = ApiClient.messageFromError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || posts.isEmpty) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _repo.list(before: posts.last.id, limit: _pageSize);
      // Dedupe by id defensively
      final existingIds = posts.map((p) => p.id).toSet();
      final newPosts = result.where((p) => !existingIds.contains(p.id)).toList();
      posts = [...posts, ...newPosts];
      _hasMore = result.length == _pageSize;
    } catch (e) {
      // Surface error the same way load() does, but don't wipe existing posts
      error = ApiClient.messageFromError(e);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(Post post) async {
    final wasLiked = post.likedByMe;
    post.likedByMe = !wasLiked;
    post.likeCount += wasLiked ? -1 : 1;
    notifyListeners();
    try {
      final (liked, count) = await _repo.toggleLike(post.id);
      post.likedByMe = liked;
      post.likeCount = count;
    } catch (_) {
      post.likedByMe = wasLiked;
      post.likeCount += wasLiked ? 1 : -1;
    }
    notifyListeners();
  }

  void bumpCommentCount(int postId) {
    for (final p in posts) {
      if (p.id == postId) p.commentCount++;
    }
    notifyListeners();
  }

  void decrementCommentCount(int postId) {
    for (final p in posts) {
      if (p.id == postId && p.commentCount > 0) p.commentCount--;
    }
    notifyListeners();
  }

  /// Deletes a post (own, or any if moderator/admin) and drops it from the feed.
  Future<bool> deletePost(int postId) async {
    try {
      await _repo.deletePost(postId);
      posts = posts.where((p) => p.id != postId).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createPost({required String type, required String content}) async {
    try {
      final created = await _repo.create(type: type, content: content);
      posts.insert(0, created);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
