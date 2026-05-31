// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

class Comment {
  final int id;
  final String content;
  final DateTime createdAt;
  final int authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole = 'user',
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] as int,
        content: j['content'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        authorId: j['author_id'] as int,
        authorName: j['author_name'] as String? ?? '',
        authorAvatar: j['author_avatar'] as String?,
        authorRole: j['author_role'] as String? ?? 'user',
      );
}
