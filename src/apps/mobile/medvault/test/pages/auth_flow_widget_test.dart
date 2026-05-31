import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/core/di/service_locator.dart';
import 'package:medvault/core/env/app_environment.dart';
import 'package:medvault/l10n/app_localizations.dart';
import 'package:medvault/pages/landing_page.dart';
import 'package:medvault/pages/registration_page.dart';
import 'package:medvault/services/auth_service.dart';
import 'package:medvault/services/settings_service.dart';

void _configureLocator(AuthService service) {
  final locator = ServiceLocator.instance;
  locator.environment = AppEnvironment.demo;
  locator.authService = service;
}

Future<void> _pumpLandingPage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const LandingPage(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Auth flow widgets', () {
    testWidgets('hides email auth actions on the landing page', (tester) async {
      _configureLocator(
        AuthService(settingsService: SettingsService(), demoMode: true),
      );

      await _pumpLandingPage(tester);

      expect(find.text('Sign in with Email'), findsNothing);
      expect(find.text('Create account with Email'), findsNothing);
      expect(find.text('Continue without sign-in'), findsNothing);
    });

    testWidgets('navigates to registration for unregistered demo user', (
      tester,
    ) async {
      _configureLocator(
        AuthService(settingsService: SettingsService(), demoMode: true),
      );

      await _pumpLandingPage(tester);
      await tester.tap(find.text('Continue with Demo Google'));
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationPage), findsOneWidget);
    });
  });
}
