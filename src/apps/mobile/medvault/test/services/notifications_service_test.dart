import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/models/notifications_models.dart';
import 'package:medvault/services/api/notifications_api.dart';
import 'package:medvault/services/auth_service.dart';
import 'package:medvault/services/database.dart';
import 'package:medvault/services/notifications_service.dart';

class _FakeNotificationsApiClient implements NotificationsApiClient {
  List<MedVaultNotification> remoteNotifications = const [];
  NotificationSettings? remoteSettings;
  NotificationSettings? savedSettings;
  final List<String> markAsReadIds = [];
  bool markAllCalled = false;
  bool throwOnFetch = false;

  @override
  Future<List<MedVaultNotification>> fetchNotifications() async {
    if (throwOnFetch) {
      throw Exception('network failure');
    }
    return remoteNotifications;
  }

  @override
  Future<NotificationSettings?> loadSettings() async {
    return remoteSettings;
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    markAllCalled = true;
  }

  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {
    markAsReadIds.add(notificationId);
  }

  @override
  Future<void> saveSettings(
    NotificationSettings settings, {
    String? pushDeviceToken,
  }) async {
    savedSettings = settings;
  }
}

void main() {
  group('NotificationsService', () {
    late AppDatabase database;
    late _FakeNotificationsApiClient apiClient;

    Future<AuthUser?> currentUser() async {
      return const AuthUser(email: 'demo.user@medvault.local');
    }

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      apiClient = _FakeNotificationsApiClient();
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'initialize seeds demo notifications once and keeps mixed states',
      () async {
        final service = NotificationsService(
          currentUserProvider: currentUser,
          demoMode: true,
          apiClient: apiClient,
          database: database,
        );

        await service.initialize();
        final firstCount = service.notifications.length;
        final firstUnread = service.unreadCount;

        expect(firstCount, greaterThanOrEqualTo(4));
        expect(firstUnread, greaterThan(0));

        await service.seedDemoNotificationsData();
        expect(service.notifications.length, firstCount);
        expect(service.unreadCount, firstUnread);
      },
    );

    test('markAsRead updates local unread state', () async {
      final service = NotificationsService(
        currentUserProvider: currentUser,
        demoMode: true,
        apiClient: apiClient,
        database: database,
      );

      await service.initialize();
      final unread = service.notifications.firstWhere((item) => !item.isRead);
      final before = service.unreadCount;

      await service.markAsRead(unread.id);

      final updated = service.notifications.firstWhere(
        (item) => item.id == unread.id,
      );
      expect(updated.isRead, isTrue);
      expect(service.unreadCount, before - 1);
    });

    test(
      'non-demo initialize syncs settings and fetches remote notifications',
      () async {
        apiClient.remoteSettings = const NotificationSettings(
          pushEnabled: true,
        );

        apiClient.remoteNotifications = [
          MedVaultNotification(
            id: 'remote-1',
            type: NotificationType.securityAlert,
            language: 'en-US',
            title: 'Security alert',
            subtitle: 'You have {unreadCount} unread notifications',
            description: 'A security event was detected.',
            actorName: null,
            createdAt: DateTime.now(),
            isRead: false,
          ),
        ];

        final service = NotificationsService(
          currentUserProvider: currentUser,
          demoMode: false,
          apiClient: apiClient,
          database: database,
        );

        await service.initialize();

        expect(service.settings.pushEnabled, isTrue);
        expect(service.notifications.length, 1);
        expect(service.notifications.first.id, 'remote-1');
      },
    );

    test(
      'updateSettings and markAsRead call remote API in non-demo mode',
      () async {
        apiClient.remoteNotifications = [
          MedVaultNotification(
            id: 'remote-2',
            type: NotificationType.shareRequest,
            language: 'en-US',
            title: 'Share request',
            subtitle: 'You have {unreadCount} unread notifications',
            description: 'Dr. Jane Smith requested access.',
            actorName: 'Dr. Jane Smith',
            createdAt: DateTime.now(),
            isRead: false,
          ),
        ];

        final service = NotificationsService(
          currentUserProvider: currentUser,
          demoMode: false,
          apiClient: apiClient,
          database: database,
        );

        await service.initialize();
        await service.updateSettings(
          service.settings.copyWith(pushEnabled: true),
        );
        await service.markAsRead('remote-2');

        expect(apiClient.savedSettings, isNotNull);
        expect(apiClient.savedSettings!.pushEnabled, isTrue);
        expect(apiClient.markAsReadIds, contains('remote-2'));
      },
    );

    test(
      'fetchNotifications clears local cache when backend returns empty list',
      () async {
        apiClient.remoteNotifications = [
          MedVaultNotification(
            id: 'remote-3',
            type: NotificationType.securityAlert,
            language: 'en-US',
            title: 'Security alert',
            subtitle: 'You have {unreadCount} unread notifications',
            description: 'A security event was detected.',
            actorName: null,
            createdAt: DateTime.now(),
            isRead: false,
          ),
        ];

        final service = NotificationsService(
          currentUserProvider: currentUser,
          demoMode: false,
          apiClient: apiClient,
          database: database,
        );

        await service.initialize();
        expect(service.notifications.length, 1);

        apiClient.remoteNotifications = const [];
        await service.fetchNotifications(showLoading: false);

        expect(service.notifications, isEmpty);
      },
    );

    test('fetchNotifications reports sync errors without crashing', () async {
      apiClient.remoteNotifications = [
        MedVaultNotification(
          id: 'remote-4',
          type: NotificationType.shareRequest,
          language: 'en-US',
          title: 'Share request',
          subtitle: 'You have {unreadCount} unread notifications',
          description: 'Dr. Smith requested access.',
          actorName: 'Dr. Smith',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];

      final service = NotificationsService(
        currentUserProvider: currentUser,
        demoMode: false,
        apiClient: apiClient,
        database: database,
      );

      await service.initialize();
      expect(service.hasSyncError, isFalse);

      apiClient.throwOnFetch = true;
      await service.fetchNotifications(showLoading: false);

      expect(service.hasSyncError, isTrue);
      expect(service.notifications.length, 1);
    });
  });
}
