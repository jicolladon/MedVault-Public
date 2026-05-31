import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/features/notifications/domain/entities/notification_item.dart';
import 'package:medvault/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:medvault/features/notifications/domain/repositories/sharing_link_repository.dart';
import 'package:medvault/features/notifications/domain/use_cases/initialize_notifications_use_case.dart';
import 'package:medvault/features/notifications/domain/use_cases/mark_notification_read_use_case.dart';
import 'package:medvault/features/notifications/domain/use_cases/refresh_notifications_use_case.dart';
import 'package:medvault/features/notifications/domain/use_cases/revoke_sharing_link_use_case.dart';
import 'package:medvault/features/notifications/presentation/view_models/notifications_view_model.dart';
import 'package:medvault/services/connectivity_service.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();
  List<NotificationItem> _notifications = const [];

  int initializeCallCount = 0;
  int refreshCallCount = 0;
  int markAsReadCallCount = 0;
  String? lastReadId;

  @override
  Stream<void> get changes => _changesController.stream;

  @override
  bool get hasSyncError => false;

  @override
  bool get isLoading => false;

  @override
  List<NotificationItem> get notifications => _notifications;

  @override
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  @override
  Future<void> initialize() async {
    initializeCallCount += 1;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    markAsReadCallCount += 1;
    lastReadId = notificationId;
    _notifications = _notifications
        .map(
          (item) => item.id == notificationId
              ? NotificationItem(
                  id: item.id,
                  type: item.type,
                  relatedLinkId: item.relatedLinkId,
                  language: item.language,
                  title: item.title,
                  subtitle: item.subtitle,
                  description: item.description,
                  actorName: item.actorName,
                  createdAt: item.createdAt,
                  isRead: true,
                )
              : item,
        )
        .toList(growable: false);
    _changesController.add(null);
  }

  @override
  Future<void> refresh({bool showLoading = true}) async {
    refreshCallCount += 1;
  }

  void setNotifications(List<NotificationItem> items) {
    _notifications = List<NotificationItem>.from(items, growable: false);
    _changesController.add(null);
  }

  Future<void> dispose() async {
    await _changesController.close();
  }
}

class _FakeSharingLinkRepository implements SharingLinkRepository {
  int revokeCallCount = 0;
  String? lastRevokedId;
  bool throwOnRevoke = false;

  @override
  Future<void> revokeLink(String linkId) async {
    if (throwOnRevoke) {
      throw Exception('revoke failed');
    }
    revokeCallCount += 1;
    lastRevokedId = linkId;
  }
}

void main() {
  group('NotificationsViewModel', () {
    late _FakeNotificationsRepository notificationsRepository;
    late _FakeSharingLinkRepository sharingLinkRepository;
    late NotificationsViewModel viewModel;

    setUp(() {
      notificationsRepository = _FakeNotificationsRepository();
      sharingLinkRepository = _FakeSharingLinkRepository();
      viewModel = NotificationsViewModel(
        notificationsRepository: notificationsRepository,
        connectivityService: ConnectivityService(),
        initializeNotifications: InitializeNotificationsUseCase(
          notificationsRepository,
        ),
        refreshNotifications: RefreshNotificationsUseCase(
          notificationsRepository,
        ),
        markNotificationRead: MarkNotificationReadUseCase(
          notificationsRepository,
        ),
        revokeSharingLink: RevokeSharingLinkUseCase(sharingLinkRepository),
      );
    });

    tearDown(() async {
      viewModel.dispose();
      await notificationsRepository.dispose();
    });

    test('filters visible notifications by selected tab', () async {
      final now = DateTime.now();
      notificationsRepository.setNotifications([
        NotificationItem(
          id: 'n1',
          type: NotificationItemType.shareRequest,
          relatedLinkId: null,
          language: 'en-US',
          title: 'One',
          subtitle: null,
          description: null,
          actorName: null,
          createdAt: now,
          isRead: false,
        ),
        NotificationItem(
          id: 'n2',
          type: NotificationItemType.securityAlert,
          relatedLinkId: null,
          language: 'en-US',
          title: 'Two',
          subtitle: null,
          description: null,
          actorName: null,
          createdAt: now,
          isRead: true,
        ),
      ]);

      expect(viewModel.visibleNotifications.length, 2);
      viewModel.selectTab(NotificationsTab.unread);
      expect(viewModel.visibleNotifications.length, 1);
      expect(viewModel.visibleNotifications.first.id, 'n1');
    });

    test(
      'delegates initialize, refresh, and mark-as-read to use cases',
      () async {
        final now = DateTime.now();
        notificationsRepository.setNotifications([
          NotificationItem(
            id: 'n1',
            type: NotificationItemType.shareRequest,
            relatedLinkId: null,
            language: 'en-US',
            title: 'One',
            subtitle: null,
            description: null,
            actorName: null,
            createdAt: now,
            isRead: false,
          ),
        ]);

        await viewModel.initialize();
        await viewModel.refresh();
        await viewModel.markAsRead('n1');

        expect(notificationsRepository.initializeCallCount, 1);
        expect(notificationsRepository.refreshCallCount, 1);
        expect(notificationsRepository.markAsReadCallCount, 1);
        expect(notificationsRepository.lastReadId, 'n1');
        expect(viewModel.unreadCount, 0);
      },
    );

    test(
      'returns missing-link result when notification has no link id',
      () async {
        final result = await viewModel.revokeSharingLink(null);

        expect(result, RevokeSharingLinkResult.missingLink);
        expect(sharingLinkRepository.revokeCallCount, 0);
      },
    );

    test('returns failed result when revoke throws', () async {
      sharingLinkRepository.throwOnRevoke = true;

      final result = await viewModel.revokeSharingLink('link-1');

      expect(result, RevokeSharingLinkResult.failed);
      expect(sharingLinkRepository.revokeCallCount, 0);
    });

    test('returns success when revoke succeeds', () async {
      final result = await viewModel.revokeSharingLink('link-1');

      expect(result, RevokeSharingLinkResult.success);
      expect(sharingLinkRepository.revokeCallCount, 1);
      expect(sharingLinkRepository.lastRevokedId, 'link-1');
    });
  });
}
