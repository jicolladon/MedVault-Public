import 'dart:async';

import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../mappers/notification_item_mapper.dart';
import '../../../../services/notifications_service.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({required NotificationsService service})
    : _service = service {
    _service.addListener(_onServiceChanged);
  }

  final NotificationsService _service;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();
  bool _disposed = false;

  @override
  Stream<void> get changes => _changesController.stream;

  @override
  bool get isLoading => _service.isLoading;

  @override
  bool get hasSyncError => _service.hasSyncError;

  @override
  int get unreadCount => _service.unreadCount;

  @override
  List<NotificationItem> get notifications {
    return _service.notifications
        .map(mapNotificationItem)
        .toList(growable: false);
  }

  @override
  Future<void> initialize() {
    return _service.initialize();
  }

  @override
  Future<void> refresh({bool showLoading = true}) {
    return _service.fetchNotifications(showLoading: showLoading);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _service.markAsRead(notificationId);
  }

  void _onServiceChanged() {
    if (_changesController.isClosed) {
      return;
    }
    _changesController.add(null);
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _service.removeListener(_onServiceChanged);
    _changesController.close();
  }
}
