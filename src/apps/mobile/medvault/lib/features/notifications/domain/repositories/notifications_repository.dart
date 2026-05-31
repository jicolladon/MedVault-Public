import '../entities/notification_item.dart';

abstract interface class NotificationsRepository {
  Stream<void> get changes;

  bool get isLoading;

  bool get hasSyncError;

  int get unreadCount;

  List<NotificationItem> get notifications;

  Future<void> initialize();

  Future<void> refresh({bool showLoading = true});

  Future<void> markAsRead(String notificationId);
}
