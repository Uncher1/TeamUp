class AppNotification {
  final int id;
  final String type;
  final String title;
  final String? body;
  final String? linkType;
  final int? linkId;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.linkType,
    this.linkId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int,
        type: j['type'] as String? ?? 'project_update',
        title: j['title'] as String? ?? '',
        body: j['body'] as String?,
        linkType: j['link_type'] as String?,
        linkId: j['link_id'] as int?,
        isRead: j['is_read'] == true || j['is_read'] == 1,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
