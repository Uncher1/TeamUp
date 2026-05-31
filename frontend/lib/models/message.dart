// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final String? attachmentType; // 'image' | 'file' | 'audio' | 'poll'
  final String? attachmentName;
  final String? attachmentData; // base64 data URL, or poll id for polls
  final Map<String, dynamic>? poll; // present on poll messages
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderRole = 'user',
    required this.content,
    this.attachmentType,
    this.attachmentName,
    this.attachmentData,
    this.poll,
    required this.createdAt,
  });

  bool get hasImage => attachmentType == 'image' && (attachmentData?.isNotEmpty ?? false);
  bool get hasFile => attachmentType == 'file' && (attachmentData?.isNotEmpty ?? false);
  bool get hasAudio => attachmentType == 'audio' && (attachmentData?.isNotEmpty ?? false);
  bool get hasPoll => attachmentType == 'poll' && poll != null;

  Message copyWith({Map<String, dynamic>? poll}) => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: content,
        attachmentType: attachmentType,
        attachmentName: attachmentName,
        attachmentData: attachmentData,
        poll: poll ?? this.poll,
        createdAt: createdAt,
      );

  factory Message.fromJson(Map<String, dynamic> j, {int fallbackConvId = 0}) => Message(
        id: j['id'] as int,
        conversationId: (j['conversation_id'] as int?) ?? fallbackConvId,
        senderId: j['sender_id'] as int,
        senderName: j['sender_name'] as String? ?? '',
        senderRole: j['sender_role'] as String? ?? 'user',
        content: j['content'] as String? ?? '',
        attachmentType: j['attachment_type'] as String?,
        attachmentName: j['attachment_name'] as String?,
        attachmentData: j['attachment_data'] as String?,
        poll: j['poll'] is Map ? Map<String, dynamic>.from(j['poll'] as Map) : null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
