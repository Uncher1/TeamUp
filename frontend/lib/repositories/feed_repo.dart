import '../core/api_client.dart';
import '../models/post.dart';

class FeedRepository {
  final ApiClient api;
  FeedRepository(this.api);

  Future<List<Post>> list({int? before, int limit = 50}) async {
    final Map<String, dynamic> qp = {'limit': limit};
    if (before != null) qp['before'] = before;
    final res = await api.dio.get('/posts', queryParameters: qp);
    return (res.data as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Post> create({required String type, required String content, int? projectId}) async {
    final res = await api.dio.post('/posts', data: {
      'type': type,
      'content': content,
      'project_id': projectId,
    });
    return Post.fromJson(res.data as Map<String, dynamic>);
  }

  /// Toggles the like; returns (liked, likeCount).
  Future<(bool, int)> toggleLike(int postId) async {
    final res = await api.dio.post('/posts/$postId/like');
    final data = res.data as Map<String, dynamic>;
    return (data['liked'] == true, (data['like_count'] as num).toInt());
  }
}
