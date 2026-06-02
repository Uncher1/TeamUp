// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

class Conversation {
  final int id;
  final String type;
  final int? projectId;
  final int? projectOwnerId;
  final String? projectTitle;
  final String? projectAvatar;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? otherUserStatus;
  final int? otherUserId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int? lastSenderId;
  final String? lastSenderName;
  final String? lastAttachmentType;

  const Conversation({
    required this.id,
    required this.type,
    this.projectId,
    this.projectOwnerId,
    this.projectTitle,
    this.projectAvatar,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserStatus,
    this.otherUserId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.lastSenderName,
    this.lastAttachmentType,
  });

  bool get isTeam => type == 'project';

  String get displayName {
    if (type == 'project' && projectTitle != null) return projectTitle!;
    if (otherUserName != null) return otherUserName!;
    return 'Conversation #$id';
  }

  /// Avatar photo for the conversation row - the team photo for project chats,
  /// the other person's photo for direct chats.
  String? get avatarImageUrl => type == 'direct' ? otherUserAvatar : projectAvatar;

  /// Presence dot for the row - only meaningful for direct (1:1) chats.
  String? get avatarStatus => type == 'direct' ? otherUserStatus : null;

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as int,
        type: j['type'] as String? ?? 'direct',
        projectId: j['project_id'] as int?,
        projectOwnerId: j['project_owner_id'] as int?,
        projectTitle: j['project_title'] as String?,
        projectAvatar: j['project_avatar'] as String?,
        otherUserName: j['other_user_name'] as String?,
        otherUserAvatar: j['other_user_avatar'] as String?,
        otherUserStatus: j['other_user_status'] as String?,
        otherUserId: j['other_user_id'] as int?,
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.parse(j['last_message_at'] as String)
            : null,
        lastSenderId: j['last_sender_id'] as int?,
        lastSenderName: j['last_sender_name'] as String?,
        lastAttachmentType: j['last_attachment_type'] as String?,
      );
}
