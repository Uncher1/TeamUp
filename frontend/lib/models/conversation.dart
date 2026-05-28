class Conversation {
  final int id;
  final String type;
  final int? projectId;
  final String? projectTitle;
  final String? otherUserName;
  final int? otherUserId;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    required this.type,
    this.projectId,
    this.projectTitle,
    this.otherUserName,
    this.otherUserId,
    this.lastMessage,
    this.lastMessageAt,
  });

  String get displayName {
    if (type == 'project' && projectTitle != null) return projectTitle!;
    if (otherUserName != null) return otherUserName!;
    return 'Conversation #$id';
  }

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as int,
        type: j['type'] as String? ?? 'direct',
        projectId: j['project_id'] as int?,
        projectTitle: j['project_title'] as String?,
        otherUserName: j['other_user_name'] as String?,
        otherUserId: j['other_user_id'] as int?,
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.parse(j['last_message_at'] as String)
            : null,
      );
}
