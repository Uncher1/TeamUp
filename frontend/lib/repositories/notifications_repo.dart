import '../core/api_client.dart';
import '../models/app_notification.dart';

class NotificationsRepository {
  final ApiClient api;
  NotificationsRepository(this.api);

  Future<List<AppNotification>> list() async {
    final res = await api.dio.get('/notifications');
    return (res.data as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final res = await api.dio.get('/notifications/unread-count');
    return ((res.data as Map<String, dynamic>)['count'] as num).toInt();
  }

  Future<void> markRead(int id) async {
    await api.dio.post('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await api.dio.post('/notifications/read-all');
  }
}
