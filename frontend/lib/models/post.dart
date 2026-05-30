class Post {
  final int id;
  final String type;
  final String content;
  int commentCount;
  final DateTime createdAt;
  final int authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final int? projectId;
  final String? projectTitle;
  int likeCount;
  bool likedByMe;

  Post({
    required this.id,
    required this.type,
    required this.content,
    required this.commentCount,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole = 'user',
    this.projectId,
    this.projectTitle,
    required this.likeCount,
    required this.likedByMe,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as int,
        type: j['type'] as String? ?? 'general',
        content: j['content'] as String? ?? '',
        commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
        authorId: j['author_id'] as int,
        authorName: j['author_name'] as String? ?? '',
        authorAvatar: j['author_avatar'] as String?,
        authorRole: j['author_role'] as String? ?? 'user',
        projectId: j['project_id'] as int?,
        projectTitle: j['project_title'] as String?,
        likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
        likedByMe: j['liked_by_me'] == true || j['liked_by_me'] == 1,
      );
}
