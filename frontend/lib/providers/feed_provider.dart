import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/post.dart';
import '../repositories/feed_repo.dart';

class FeedProvider extends ChangeNotifier {
  final FeedRepository _repo;
  FeedProvider(this._repo);

  List<Post> posts = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      posts = await _repo.list();
    } catch (e) {
      error = ApiClient.messageFromError(e);
    } finally {
      loading = false;
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
