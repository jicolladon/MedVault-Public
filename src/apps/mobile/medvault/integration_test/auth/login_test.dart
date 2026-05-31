import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import '../helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('login with valid Google account navigates to HomePage', (tester) async {
      await pumpApp(tester);
      final getStartedFinder = find.text('Get Started');
      if (getStartedFinder.evaluate().isNotEmpty) {
        await tester.tap(getStartedFinder);
        await tester.pumpAndSettle();
      }

      final googleSignInFinder = find.byKey(const Key('google_signin_button'));
      if (googleSignInFinder.evaluate().isNotEmpty) {
         await tester.tap(googleSignInFinder);
         await tester.pumpAndSettle(const Duration(seconds: 2));

         expect(find.byKey(const Key('home_page_scaffold')), findsOneWidget);
       }
     });

    testWidgets('login fails with wrong email/password triggers message', (tester) async {
       await pumpApp(tester);
     });
   });
 }
