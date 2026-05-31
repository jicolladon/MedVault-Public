import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/l10n/app_localizations.dart';
import 'package:medvault/models/sharing_models.dart';
import 'package:medvault/pages/sharing_page.dart';
import 'package:medvault/services/auth_service.dart';
import 'package:medvault/services/database.dart';
import 'package:medvault/services/sharing_email_launcher.dart';
import 'package:medvault/services/sharing_service.dart';

void main() {
  group('PhysicianSharingReviewPage', () {
    late AppDatabase database;
    late SharingService sharingService;

    Future<AuthUser?> currentUser() async {
      return const AuthUser(
        email: 'widget.user@medvault.local',
        displayName: 'Patient Test',
      );
    }

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      sharingService = SharingService(
        currentUserProvider: currentUser,
        demoMode: true,
        database: database,
      );
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('opens sharing options with physician content', (tester) async {
      final messageLauncher = _FakeMessageLauncher(openResult: true);

      await tester.pumpWidget(
        _buildTestApp(
          child: PhysicianSharingReviewPage(
            sharingService: sharingService,
            draft: const PhysicianSharingDraft(
              physicianName: 'Dr. Jane Smith',
              physicianEmail: 'jane.smith@hospital.com',
              notes: 'Follow-up visit records',
              scopes: {
                SharingScope.medicalInformation,
                SharingScope.labResults,
              },
            ),
            securitySettings: const SharingSecuritySettings(
              accessDuration: Duration(days: 30),
              passwordProtected: true,
            ),
            messageLauncher: messageLauncher,
            patientNameProvider: () async => 'Patient Test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      expect(messageLauncher.callCount, equals(1));
      expect(
        messageLauncher.lastRequest?.subject,
        equals('MedVault secure medical information sharing'),
      );
      expect(
        messageLauncher.lastRequest?.body,
        contains('https://demo.medvault.app/provider/'),
      );
      expect(
        messageLauncher.lastRequest?.body,
        contains('Patient: Patient Test'),
      );
    });

    testWidgets('copies link when sharing options cannot open', (tester) async {
      final messageLauncher = _FakeMessageLauncher(openResult: false);

      await tester.pumpWidget(
        _buildTestApp(
          child: PhysicianSharingReviewPage(
            sharingService: sharingService,
            draft: const PhysicianSharingDraft(
              physicianName: 'Dr. Jane Smith',
              physicianEmail: 'jane.smith@hospital.com',
              notes: null,
              scopes: {SharingScope.medicalInformation},
            ),
            securitySettings: const SharingSecuritySettings(
              accessDuration: Duration(days: 7),
            ),
            messageLauncher: messageLauncher,
            patientNameProvider: () async => 'Patient Test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      expect(messageLauncher.callCount, equals(1));
      expect(
        messageLauncher.lastRequest?.body,
        contains('https://demo.medvault.app/provider/'),
      );
      expect(
        messageLauncher.lastRequest?.body,
        contains('Patient: Patient Test'),
      );
    });
  });
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

class _FakeMessageLauncher implements SharingMessageLauncher {
  _FakeMessageLauncher({required this.openResult});

  final bool openResult;

  int callCount = 0;
  SharingMessageRequest? lastRequest;

  @override
  Future<bool> openShareSheet(SharingMessageRequest request) async {
    callCount += 1;
    lastRequest = request;
    return openResult;
  }
}
