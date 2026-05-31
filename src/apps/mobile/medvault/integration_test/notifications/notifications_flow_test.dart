import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medvault/core/di/service_locator.dart';

import '../helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Notifications flow integration tests', () {
    testWidgets('opens alerts tab, marks item read, and shows push status', (
      tester,
    ) async {
      await pumpApp(tester);

      final alertsTab = find.text('Alerts');
      expect(alertsTab, findsWidgets);
      await tester.tap(alertsTab.last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('notifications_tab_all')), findsOneWidget);
      expect(find.byKey(const Key('notifications_tab_settings')), findsNothing);

      expect(
        find.byKey(const Key('notifications_push_status')),
        findsOneWidget,
      );

      final service = ServiceLocator.instance.notificationsService;
      final unreadBefore = service.unreadCount;
      if (unreadBefore > 0) {
        await tester.tap(find.byType(ListTile).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(service.unreadCount, lessThan(unreadBefore));
      }
    });
  });
}
