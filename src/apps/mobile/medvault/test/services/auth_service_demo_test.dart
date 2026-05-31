import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/models/api_models.dart';
import 'package:medvault/services/auth_service.dart';
import 'package:medvault/services/database.dart';
import 'package:medvault/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService demo mode', () {
    late AuthService service;
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      service = AuthService(
        settingsService: SettingsService(database: database),
        demoMode: true,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('starts without an active session', () async {
      final hasSession = await service.hasValidSession();
      expect(hasSession, isFalse);
    });

    test('supports demo registration and onboarding lifecycle', () async {
      final loginResult = await service.signInWithGoogleAndBackend();
      expect(loginResult.success, isTrue);
      expect(loginResult.isNewUser, isTrue);

      final registerResult = await service.registerWithGoogleAndBackend(
        request: RegisterRequest(
          googleIdToken: 'demo-google-id-token',
          firstName: 'Demo',
          lastName: 'User',
          dateOfBirth: DateTime(1990, 1, 1).toIso8601String(),
          termsAccepted: true,
          privacyPolicyAccepted: true,
        ),
      );

      expect(registerResult.success, isTrue);
      expect(await service.hasValidSession(), isTrue);

      final firstDecision = await service.determinePostAuthDestination();
      expect(firstDecision.destination, PostAuthDestination.onboarding);

      await service.markOnboardingComplete();
      final secondDecision = await service.determinePostAuthDestination();
      expect(secondDecision.destination, PostAuthDestination.home);

      final currentUser = await service.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.email, isNotEmpty);

      await service.signOut();
      expect(await service.hasValidSession(), isFalse);
    });
  });
}
