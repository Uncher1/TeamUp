import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/app_notification.dart';
import '../repositories/notifications_repo.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationsRepository _repo;
  NotificationsProvider(this._repo);

  List<AppNotification> items = [];
  int unread = 0;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repo.list();
      unread = items.where((n) => !n.isRead).length;
    } catch (e) {
      error = ApiClient.messageFromError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnread() async {
    try {
      unread = await _repo.unreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    for (final n in items) {
      n.isRead = true;
    }
    unread = 0;
    notifyListeners();
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }
}
