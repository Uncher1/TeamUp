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
  final String? attachmentType; // 'image' | 'file'
  final String? attachmentName;
  final String? attachmentData; // base64 data URL
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
    required this.createdAt,
  });

  bool get hasImage => attachmentType == 'image' && (attachmentData?.isNotEmpty ?? false);
  bool get hasFile => attachmentType == 'file' && (attachmentData?.isNotEmpty ?? false);
  bool get hasAudio => attachmentType == 'audio' && (attachmentData?.isNotEmpty ?? false);

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
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
