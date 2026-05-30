class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderRole = 'user',
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j, {int fallbackConvId = 0}) => Message(
        id: j['id'] as int,
        conversationId: (j['conversation_id'] as int?) ?? fallbackConvId,
        senderId: j['sender_id'] as int,
        senderName: j['sender_name'] as String? ?? '',
        senderRole: j['sender_role'] as String? ?? 'user',
        content: j['content'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
