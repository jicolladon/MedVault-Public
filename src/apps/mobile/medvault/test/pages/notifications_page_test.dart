import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/core/di/service_locator.dart';
import 'package:medvault/l10n/app_localizations.dart';
import 'package:medvault/models/notifications_models.dart';
import 'package:medvault/pages/notifications_page.dart';
import 'package:medvault/services/api/notifications_api.dart';
import 'package:medvault/services/auth_service.dart';
import 'package:medvault/services/database.dart';
import 'package:medvault/services/notifications_service.dart';

class _FakeNotificationsApiClient implements NotificationsApiClient {
  @override
  Future<List<MedVaultNotification>> fetchNotifications() async {
    return const [];
  }

  @override
  Future<NotificationSettings?> loadSettings() async {
    return null;
  }

  @override
  Future<void> markAllNotificationsAsRead() async {}

  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {}

  @override
  Future<void> saveSettings(
    NotificationSettings settings, {
    String? pushDeviceToken,
  }) async {}
}

void main() {
  group('NotificationsPage', () {
    late AppDatabase database;
    late NotificationsService notificationsService;

    Future<AuthUser?> currentUser() async {
      return const AuthUser(email: 'widget.notifications@medvault.local');
    }

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      notificationsService = NotificationsService(
        currentUserProvider: currentUser,
        demoMode: true,
        apiClient: _FakeNotificationsApiClient(),
        database: database,
        deviceLanguageProvider: () => 'en-US',
      );

      ServiceLocator.instance.notificationsService = notificationsService;
    });

    tearDown(() async {
      notificationsService.dispose();
      await database.close();
    });

    testWidgets('opens detail dialog when notification is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('3 unread'), findsOneWidget);

      await tester.tap(find.text('Share request').first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('notification_detail_dialog')),
        findsOneWidget,
      );
      expect(find.text('Notification Details'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('View sharing details'), findsOneWidget);
      expect(find.text('Revoke sharing link'), findsOneWidget);

      expect(find.text('2 unread'), findsOneWidget);
    });

    testWidgets('shows feedback when revoke is unavailable for notification', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share request').first);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('notification_detail_action_revoke_sharing')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This notification does not include a sharing link to revoke.',
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _buildTestApp() {
  return const MaterialApp(
    locale: Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: NotificationsPage(),
  );
}
