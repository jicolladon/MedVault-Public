import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/models/sharing_models.dart';
import 'package:medvault/services/api/sharing_api.dart';
import 'package:medvault/services/auth_service.dart';
import 'package:medvault/services/database.dart';
import 'package:medvault/services/medical_data_service.dart';
import 'package:medvault/services/sharing_service.dart';

void main() {
  group('SharingService', () {
    late AppDatabase database;
    late SharingService service;

    Future<AuthUser?> currentUser() async {
      return const AuthUser(email: 'demo.user@medvault.local');
    }

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      service = SharingService(
        currentUserProvider: currentUser,
        demoMode: true,
        database: database,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'seedDemoSharingData populates links and activity data once',
      () async {
        await service.initialize();
        final firstLinks = service.links;
        final firstActivity = service.activityLog;

        expect(firstLinks.length, greaterThanOrEqualTo(2));
        expect(firstActivity.length, greaterThanOrEqualTo(1));

        await service.seedDemoSharingData();
        expect(service.links.length, equals(firstLinks.length));
        expect(service.activityLog.length, equals(firstActivity.length));
      },
    );

    test(
      'createEmergencySharingLink returns dummy link and skips activity log in demo mode',
      () async {
        await service.initialize();
        final baselineActivityCount = service.activityLog.length;

        final grant = await service.createEmergencySharingLink(
          scopes: {
            SharingScope.bloodType,
            SharingScope.allergies,
            SharingScope.emergencyContact,
          },
          securitySettings: const SharingSecuritySettings(
            accessDuration: Duration(hours: 1),
          ),
        );

        expect(grant.type, SharingType.emergency);
        expect(grant.shareUrl, contains('demo.medvault.app/emergency'));
        expect(grant.shareCode.length, 8);
        expect(grant.isActive(), isTrue);
        expect(service.activityLog.length, equals(baselineActivityCount));
      },
    );

    test('createPhysicianSharingLink allows empty physician email', () async {
      await service.initialize();

      final link = await service.createPhysicianSharingLink(
        physicianName: 'Dr. Optional Email',
        physicianEmail: null,
        notes: null,
        scopes: {SharingScope.medicalInformation, SharingScope.diagnoses},
        securitySettings: const SharingSecuritySettings(
          accessDuration: Duration(days: 7),
        ),
      );

      expect(link.type, SharingType.physician);
      expect(link.targetEmail, isNull);
    });

    test(
      'createEmergencySharingLink fails when max active link limit is reached',
      () async {
        await service.initialize();

        final activeLinksBefore = service.activeLinksCount;
        final maxLinks = service.maxSharingLinksPerUser;
        final availableSlots = maxLinks - activeLinksBefore;

        for (var index = 0; index < availableSlots; index++) {
          await service.createEmergencySharingLink(
            scopes: {
              SharingScope.bloodType,
              SharingScope.allergies,
              SharingScope.emergencyContact,
            },
            securitySettings: const SharingSecuritySettings(
              accessDuration: Duration(hours: 1),
            ),
          );
        }

        expect(
          () => service.createEmergencySharingLink(
            scopes: {SharingScope.bloodType, SharingScope.allergies},
            securitySettings: const SharingSecuritySettings(
              accessDuration: Duration(hours: 1),
            ),
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('maximum of $maxLinks active sharing links'),
            ),
          ),
        );
      },
    );

    test(
      'revoking an active link frees one slot for creating a new link',
      () async {
        await service.initialize();

        final activeLink = service.links.firstWhere(
          (entry) => entry.isActive(),
        );
        final activeBefore = service.activeLinksCount;

        await service.revokeLink(linkId: activeLink.id);

        expect(service.activeLinksCount, equals(activeBefore - 1));

        final created = await service.createEmergencySharingLink(
          scopes: {
            SharingScope.bloodType,
            SharingScope.allergies,
            SharingScope.emergencyContact,
          },
          securitySettings: const SharingSecuritySettings(
            accessDuration: Duration(hours: 1),
          ),
        );

        expect(created.id, isNotEmpty);
        expect(service.activeLinksCount, equals(activeBefore));
      },
    );

    test('updateLinkPermissions updates scopes and security', () async {
      await service.initialize();
      final initial = service.links.first;

      await service.updateLinkPermissions(
        linkId: initial.id,
        scopes: {SharingScope.medicalInformation, SharingScope.labResults},
        securitySettings: const SharingSecuritySettings(
          accessDuration: Duration(days: 7),
          allowDownload: true,
          passwordProtected: true,
          requiresTwoFactorApproval: true,
        ),
      );

      final updated = service.links.firstWhere(
        (entry) => entry.id == initial.id,
      );
      expect(updated.scopes.length, 2);
      expect(updated.scopes.contains(SharingScope.labResults), isTrue);
      expect(updated.securitySettings.allowDownload, isTrue);
      expect(updated.securitySettings.passwordProtected, isTrue);
      expect(updated.securitySettings.requiresTwoFactorApproval, isTrue);
    });

    test('revokeLink marks link as revoked and logs event', () async {
      await service.initialize();
      final link = service.links.firstWhere((entry) => entry.isActive());
      final baselineActivity = service.activityLog.length;

      await service.revokeLink(linkId: link.id);

      final revoked = service.links.firstWhere((entry) => entry.id == link.id);
      expect(revoked.revokedAt, isNotNull);
      expect(service.activityLog.length, equals(baselineActivity + 1));
      expect(service.activityLog.first.type, SharingActivityType.linkRevoked);
    });

    test('recordAccess increments link usage and appends event', () async {
      await service.initialize();
      final link = service.links.firstWhere((entry) => entry.isActive());
      final baselineCount = link.accessCount;

      await service.recordAccess(
        linkId: link.id,
        actorName: 'Dr. Test',
        details: 'Viewed medication history',
        highRisk: false,
        location: 'Barcelona',
      );

      final updated = service.links.firstWhere((entry) => entry.id == link.id);
      expect(updated.accessCount, equals(baselineCount + 1));
      expect(updated.lastAccessAt, isNotNull);
      expect(service.activityLog.first.type, SharingActivityType.linkAccessed);
    });

    group('non-demo backend integration', () {
      late AppDatabase nonDemoDatabase;
      late _FakeSharingApiClient fakeApi;
      late SharingService nonDemoService;
      late MedicalDataService nonDemoMedicalDataService;

      Future<AuthUser?> currentUser() async {
        return const AuthUser(email: 'regular.user@medvault.local');
      }

      setUp(() {
        nonDemoDatabase = AppDatabase(executor: NativeDatabase.memory());
        fakeApi = _FakeSharingApiClient();
        nonDemoMedicalDataService = MedicalDataService(
          currentUserProvider: currentUser,
          database: nonDemoDatabase,
        );
        nonDemoService = SharingService(
          currentUserProvider: currentUser,
          demoMode: false,
          apiClient: fakeApi,
          medicalDataService: nonDemoMedicalDataService,
          database: nonDemoDatabase,
        );
      });

      tearDown(() async {
        await nonDemoDatabase.close();
      });

      test(
        'createEmergencySharingLink uses backend response in non-demo',
        () async {
          await nonDemoMedicalDataService.updateBloodType('A+');
          await nonDemoService.initialize();

          final link = await nonDemoService.createEmergencySharingLink(
            scopes: {
              SharingScope.bloodType,
              SharingScope.allergies,
              SharingScope.emergencyContact,
            },
            securitySettings: const SharingSecuritySettings(
              accessDuration: Duration(hours: 2),
            ),
          );

          expect(link.id, equals(fakeApi.emergencyResponse.linkId));
          expect(link.shareCode, equals(fakeApi.emergencyResponse.shareCode));
          expect(link.shareUrl, equals(fakeApi.emergencyResponse.shareUrl));
        },
      );

      test(
        'createPhysicianSharingLink propagates API errors in non-demo',
        () async {
          await nonDemoMedicalDataService.updateBloodType('A+');
          await nonDemoService.initialize();
          fakeApi.throwOnCreatePhysician = true;

          expect(
            () => nonDemoService.createPhysicianSharingLink(
              physicianName: 'Dr. Test',
              physicianEmail: 'dr.test@example.com',
              notes: null,
              scopes: {SharingScope.medicalInformation},
              securitySettings: const SharingSecuritySettings(
                accessDuration: Duration(days: 1),
              ),
            ),
            throwsA(isA<Exception>()),
          );

          expect(nonDemoService.links, isEmpty);
        },
      );

      test(
        'createPhysicianSharingLink forwards security secrets and redacts them locally',
        () async {
          await nonDemoMedicalDataService.updateBloodType('A+');
          await nonDemoService.initialize();

          final link = await nonDemoService.createPhysicianSharingLink(
            physicianName: 'Dr. Secure',
            physicianEmail: 'secure@example.com',
            notes: 'Confidential review',
            scopes: {SharingScope.medicalInformation},
            securitySettings: const SharingSecuritySettings(
              accessDuration: Duration(days: 1),
              passwordProtected: true,
              requiresTwoFactorApproval: true,
              accessPassword: 'StrongPass2026',
            ),
          );

          expect(fakeApi.lastPhysicianSecuritySettings, isNotNull);
          expect(
            fakeApi.lastPhysicianSecuritySettings!.accessPassword,
            equals('StrongPass2026'),
          );
          expect(fakeApi.lastPhysicianSecuritySettings!.verificationCode, isNull);

          expect(link.securitySettings.accessPassword, isNull);
          expect(link.securitySettings.verificationCode, isNull);
        },
      );

      test('revokeLink does not mutate local state when API fails', () async {
        await nonDemoMedicalDataService.updateBloodType('A+');
        await nonDemoService.initialize();
        final link = await nonDemoService.createEmergencySharingLink(
          scopes: {SharingScope.bloodType},
          securitySettings: const SharingSecuritySettings(
            accessDuration: Duration(hours: 1),
          ),
        );

        fakeApi.throwOnRevoke = true;

        expect(
          () => nonDemoService.revokeLink(linkId: link.id),
          throwsA(isA<Exception>()),
        );

        final current = nonDemoService.links.firstWhere(
          (entry) => entry.id == link.id,
        );
        expect(current.revokedAt, isNull);
      });
    });

    group('non-demo link status sync', () {
      late AppDatabase syncDatabase;
      late _FakeSharingApiClient fakeApi;
      late SharingService syncService;

      Future<AuthUser?> currentUser() async {
        return const AuthUser(email: 'sync.user@medvault.local');
      }

      setUp(() {
        syncDatabase = AppDatabase(executor: NativeDatabase.memory());
        fakeApi = _FakeSharingApiClient();
        syncService = SharingService(
          currentUserProvider: currentUser,
          demoMode: false,
          apiClient: fakeApi,
          database: syncDatabase,
        );
      });

      tearDown(() async {
        await syncDatabase.close();
      });

      test(
        'initialize syncs sharing links status from api in non-demo',
        () async {
          fakeApi.fetchLinksResponse = [
            SharingLinkGrant(
              id: 'remote-link-1',
              type: SharingType.physician,
              targetName: 'Dr. Synced',
              targetEmail: 'synced@example.com',
              notes: 'Synced from backend',
              scopes: {SharingScope.medicalInformation},
              securitySettings: const SharingSecuritySettings(
                accessDuration: Duration(days: 1),
              ),
              createdAt: DateTime.utc(2030, 1, 1),
              expiresAt: DateTime.utc(2030, 1, 2),
              revokedAt: null,
              shareCode: 'SYNC1234',
              shareUrl: 'https://api.medvault.test/share/remote-link-1',
              qrPayload: 'https://api.medvault.test/share/remote-link-1',
              accessCount: 0,
              lastAccessAt: null,
            ),
          ];

          await syncService.initialize();

          expect(fakeApi.fetchLinksCallCount, equals(1));
          expect(syncService.links.length, equals(1));
          expect(syncService.links.first.id, equals('remote-link-1'));
        },
      );
    });
  });
}

class _FakeSharingApiClient implements SharingApiClient {
  bool throwOnCreatePhysician = false;
  bool throwOnRevoke = false;
  int fetchLinksCallCount = 0;
  List<SharingLinkGrant> fetchLinksResponse = const [];
  SharingSecuritySettings? lastPhysicianSecuritySettings;
  List<PendingShareApprovalRequest> pendingApprovalsResponse = const [];

  final SharingApiLinkResponse emergencyResponse = SharingApiLinkResponse(
    linkId: 'remote-emergency-id',
    shareCode: 'EMERG123',
    shareUrl: 'https://api.medvault.test/share/emergency-1',
    qrPayload: 'https://api.medvault.test/share/emergency-1',
    expiresAt: DateTime.utc(2030, 1, 1),
  );

  final SharingApiLinkResponse physicianResponse = SharingApiLinkResponse(
    linkId: 'remote-physician-id',
    shareCode: 'PHYS1234',
    shareUrl: 'https://api.medvault.test/share/physician-1',
    qrPayload: 'https://api.medvault.test/share/physician-1',
    expiresAt: DateTime.utc(2030, 1, 2),
  );

  @override
  Future<SharingApiLinkResponse?> createEmergencyLink({
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
    required ShareSnapshotPayload sharedSnapshot,
  }) async {
    return emergencyResponse;
  }

  @override
  Future<SharingApiLinkResponse?> createPhysicianLink({
    required String physicianName,
    required String? physicianEmail,
    required String? notes,
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
    required ShareSnapshotPayload sharedSnapshot,
  }) async {
    if (throwOnCreatePhysician) {
      throw Exception('create physician failed');
    }

    lastPhysicianSecuritySettings = securitySettings;

    return physicianResponse;
  }

  @override
  Future<List<SharingLinkGrant>> fetchLinks() async {
    fetchLinksCallCount += 1;
    return List<SharingLinkGrant>.from(fetchLinksResponse);
  }

  @override
  Future<List<PendingShareApprovalRequest>> fetchPendingApprovals() async {
    return List<PendingShareApprovalRequest>.from(pendingApprovalsResponse);
  }

  @override
  Future<ShareApprovalDecisionResult> decidePendingApproval({
    required String requestId,
    required bool approved,
  }) async {
    return ShareApprovalDecisionResult(
      requestId: requestId,
      shareLinkId: 'test-share-link',
      status: approved ? ShareApprovalStatus.approved : ShareApprovalStatus.denied,
      decisionAt: DateTime.now(),
    );
  }

  @override
  Future<void> logActivity(SharingActivityEntry activity) async {}

  @override
  Future<void> revokeLink({required String linkId}) async {
    if (throwOnRevoke) {
      throw Exception('revoke failed');
    }
  }

  @override
  Future<void> updateLinkPermissions({
    required String linkId,
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
  }) async {}
}
