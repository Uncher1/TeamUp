// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

class Conversation {
  final int id;
  final String type;
  final int? projectId;
  final String? projectTitle;
  final String? otherUserName;
  final String? otherUserAvatar;
  final int? otherUserId;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    required this.type,
    this.projectId,
    this.projectTitle,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserId,
    this.lastMessage,
    this.lastMessageAt,
  });

  String get displayName {
    if (type == 'project' && projectTitle != null) return projectTitle!;
    if (otherUserName != null) return otherUserName!;
    return 'Conversation #$id';
  }

  /// Avatar photo for the conversation row — only direct chats have a person's
  /// photo; project conversations fall back to the gradient initial.
  String? get avatarImageUrl => type == 'direct' ? otherUserAvatar : null;

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as int,
        type: j['type'] as String? ?? 'direct',
        projectId: j['project_id'] as int?,
        projectTitle: j['project_title'] as String?,
        otherUserName: j['other_user_name'] as String?,
        otherUserAvatar: j['other_user_avatar'] as String?,
        otherUserId: j['other_user_id'] as int?,
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.parse(j['last_message_at'] as String)
            : null,
      );
}
