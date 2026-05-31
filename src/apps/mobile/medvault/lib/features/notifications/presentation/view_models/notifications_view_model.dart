import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../services/connectivity_service.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/use_cases/initialize_notifications_use_case.dart';
import '../../domain/use_cases/mark_notification_read_use_case.dart';
import '../../domain/use_cases/refresh_notifications_use_case.dart';
import '../../domain/use_cases/revoke_sharing_link_use_case.dart';

enum NotificationsTab { all, unread }

enum RevokeSharingLinkResult { success, missingLink, failed }

class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    required NotificationsRepository notificationsRepository,
    required ConnectivityService connectivityService,
    required InitializeNotificationsUseCase initializeNotifications,
    required RefreshNotificationsUseCase refreshNotifications,
    required MarkNotificationReadUseCase markNotificationRead,
    required RevokeSharingLinkUseCase revokeSharingLink,
  }) : _notificationsRepository = notificationsRepository,
       _connectivityService = connectivityService,
       _initializeNotifications = initializeNotifications,
       _refreshNotifications = refreshNotifications,
       _markNotificationRead = markNotificationRead,
       _revokeSharingLink = revokeSharingLink {
    _changesSubscription = _notificationsRepository.changes.listen((_) {
      notifyListeners();
    });
    _connectivityService.addListener(_onConnectivityChanged);
  }

  final NotificationsRepository _notificationsRepository;
  final ConnectivityService _connectivityService;
  final InitializeNotificationsUseCase _initializeNotifications;
  final RefreshNotificationsUseCase _refreshNotifications;
  final MarkNotificationReadUseCase _markNotificationRead;
  final RevokeSharingLinkUseCase _revokeSharingLink;

  StreamSubscription<void>? _changesSubscription;
  NotificationsTab _selectedTab = NotificationsTab.all;

  NotificationsTab get selectedTab => _selectedTab;

  bool get isOffline => _connectivityService.isOffline;

  bool get isLoading => _notificationsRepository.isLoading;

  bool get hasSyncError => _notificationsRepository.hasSyncError;

  int get unreadCount => _notificationsRepository.unreadCount;

  List<NotificationItem> get notifications =>
      _notificationsRepository.notifications;

  List<NotificationItem> get visibleNotifications {
    if (_selectedTab == NotificationsTab.unread) {
      return notifications
          .where((notification) => !notification.isRead)
          .toList(growable: false);
    }

    return notifications;
  }

  Future<void> initialize() {
    return _initializeNotifications();
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (isOffline) {
      return;
    }

    await _refreshNotifications(showLoading: showLoading);
  }

  Future<void> markAsRead(String notificationId) {
    return _markNotificationRead(notificationId);
  }

  Future<RevokeSharingLinkResult> revokeSharingLink(String? linkId) async {
    final normalizedId = linkId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) {
      return RevokeSharingLinkResult.missingLink;
    }

    try {
      await _revokeSharingLink(normalizedId);
      return RevokeSharingLinkResult.success;
    } catch (_) {
      return RevokeSharingLinkResult.failed;
    }
  }

  void selectTab(NotificationsTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    _selectedTab = tab;
    notifyListeners();
  }

  void _onConnectivityChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    _changesSubscription = null;
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
