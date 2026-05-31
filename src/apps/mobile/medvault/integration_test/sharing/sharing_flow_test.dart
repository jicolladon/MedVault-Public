import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sharing flow integration tests', () {
    testWidgets('opens share tab and starts emergency sharing flow', (
      tester,
    ) async {
      await pumpApp(tester);

      final shareTab = find.text('Share');
      expect(shareTab, findsWidgets);
      await tester.tap(shareTab.last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Sharing & Collaboration'), findsOneWidget);
      expect(find.text('Emergency QR'), findsOneWidget);
      expect(find.text('Share with Physician'), findsOneWidget);

      await tester.tap(find.text('Emergency QR'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Emergency Sharing'), findsOneWidget);
      expect(find.text('Select Information to Share'), findsOneWidget);
    });
  });
}
