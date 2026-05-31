import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../models/api_models.dart';
import '../models/documents_models.dart';
import '../models/gender.dart';
import '../models/medical_models.dart';
import '../models/profile_models.dart';
import '../models/sharing_models.dart';
import 'api/config_api.dart';
import 'api/sharing_api.dart';
import 'auth_service.dart';
import 'database.dart' as db;
import 'documents_service.dart';
import 'medical_data_service.dart';
import 'profile_service.dart';

typedef SharingCurrentUserProvider = Future<AuthUser?> Function();

class SharingSummary {
  final int active;
  final int used;
  final int expired;

  const SharingSummary({
    required this.active,
    required this.used,
    required this.expired,
  });
}

class SharingFeatureSettings {
  final bool emergencySharingEnabled;
  final bool physicianSharingEnabled;
  final int maxSharingLinksPerUser;
  final int maxDocumentsToShare;
  final int minDocumentsToShareLimit;
  final int maxDocumentsToShareLimit;
  final int maxSharedDocumentBytes;

  const SharingFeatureSettings({
    required this.emergencySharingEnabled,
    required this.physicianSharingEnabled,
    required this.maxSharingLinksPerUser,
    required this.maxDocumentsToShare,
    required this.minDocumentsToShareLimit,
    required this.maxDocumentsToShareLimit,
    required this.maxSharedDocumentBytes,
  });
}

class SharingService extends ChangeNotifier {
  static const int maxSharedFiles = 10;
  static const int defaultMaxSharingLinksPerUser = 5;
  static const int absoluteMaxSharingLinksPerUser = 100;
  static const int defaultMaxSharedDocumentBytes = 10 * 1024 * 1024;

  SharingService({
    required SharingCurrentUserProvider currentUserProvider,
    required bool demoMode,
    SharingApiClient? apiClient,
    ConfigApi? configApi,
    DocumentsService? documentsService,
    MedicalDataService? medicalDataService,
    ProfileService? profileService,
    db.AppDatabase? database,
  }) : _currentUserProvider = currentUserProvider,
       _demoMode = demoMode,
       _apiClient = apiClient ?? const PendingSharingApiClient(),
       _configApi = configApi,
       _documentsService = documentsService,
       _medicalDataService = medicalDataService,
       _profileService = profileService,
       _db = database ?? db.AppDatabase();

  final SharingCurrentUserProvider _currentUserProvider;
  final bool _demoMode;
  final SharingApiClient _apiClient;
  final ConfigApi? _configApi;
  final DocumentsService? _documentsService;
  final MedicalDataService? _medicalDataService;
  final ProfileService? _profileService;
  final db.AppDatabase _db;

  String? _currentUserId;
  List<SharingLinkGrant> _links = const [];
  List<PendingShareApprovalRequest> _pendingApprovals = const [];
  List<SharingActivityEntry> _activityLog = const [];
  SharingFeatureSettings _featureSettings = const SharingFeatureSettings(
    emergencySharingEnabled: true,
    physicianSharingEnabled: true,
    maxSharingLinksPerUser: defaultMaxSharingLinksPerUser,
    maxDocumentsToShare: maxSharedFiles,
    minDocumentsToShareLimit: 0,
    maxDocumentsToShareLimit: maxSharedFiles,
    maxSharedDocumentBytes: defaultMaxSharedDocumentBytes,
  );

  SharingFeatureSettings get featureSettings => _featureSettings;

  bool get emergencySharingEnabled => _featureSettings.emergencySharingEnabled;

  bool get physicianSharingEnabled => _featureSettings.physicianSharingEnabled;

  int get maxSharingLinksPerUser => _featureSettings.maxSharingLinksPerUser;

  int get maxDocumentsToShare => _featureSettings.maxDocumentsToShare;

  int get maxSharedDocumentBytes => _featureSettings.maxSharedDocumentBytes;

  int get activeLinksCount {
    final now = DateTime.now();
    return _links.where((link) => link.isActive(now)).length;
  }

  bool get hasReachedSharingLinksLimit {
    final maxLinks = _featureSettings.maxSharingLinksPerUser;
    return maxLinks == 0 || activeLinksCount >= maxLinks;
  }

  List<SharingLinkGrant> get links {
    final copy = List<SharingLinkGrant>.from(_links);
    copy.sort((left, right) {
      final leftActive = left.isActive();
      final rightActive = right.isActive();
      if (leftActive != rightActive) {
        return rightActive ? 1 : -1;
      }
      return right.createdAt.compareTo(left.createdAt);
    });
    return copy;
  }

  List<SharingActivityEntry> get activityLog {
    final copy = List<SharingActivityEntry>.from(_activityLog);
    copy.sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
    return copy;
  }

  List<PendingShareApprovalRequest> get pendingApprovals {
    final copy = List<PendingShareApprovalRequest>.from(_pendingApprovals);
    copy.sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
    return copy;
  }

  SharingSummary get summary {
    final now = DateTime.now();
    final active = _links.where((link) => link.isActive(now)).length;
    final used = _links.where((link) => link.accessCount > 0).length;
    final expired = _links.where((link) => link.isExpired(now)).length;

    return SharingSummary(active: active, used: used, expired: expired);
  }

  int get highRiskEventsCount {
    return _activityLog.where((entry) => entry.highRisk).length;
  }

  Future<void> initialize({bool refreshRemoteLinks = true}) async {
    final user = await _currentUserProvider();
    if (user == null) {
      _currentUserId = null;
      _links = const [];
      _pendingApprovals = const [];
      _activityLog = const [];
      _featureSettings = const SharingFeatureSettings(
        emergencySharingEnabled: true,
        physicianSharingEnabled: true,
        maxSharingLinksPerUser: defaultMaxSharingLinksPerUser,
        maxDocumentsToShare: maxSharedFiles,
        minDocumentsToShareLimit: 0,
        maxDocumentsToShareLimit: maxSharedFiles,
        maxSharedDocumentBytes: defaultMaxSharedDocumentBytes,
      );
      notifyListeners();
      return;
    }

    final userId = user.email.trim();
    if (userId.isEmpty) {
      _currentUserId = null;
      _links = const [];
      _pendingApprovals = const [];
      _activityLog = const [];
      _featureSettings = const SharingFeatureSettings(
        emergencySharingEnabled: true,
        physicianSharingEnabled: true,
        maxSharingLinksPerUser: defaultMaxSharingLinksPerUser,
        maxDocumentsToShare: maxSharedFiles,
        minDocumentsToShareLimit: 0,
        maxDocumentsToShareLimit: maxSharedFiles,
        maxSharedDocumentBytes: defaultMaxSharedDocumentBytes,
      );
      notifyListeners();
      return;
    }

    final shouldReload = _currentUserId != userId;
    if (shouldReload) {
      _currentUserId = userId;
      await _loadFromDatabase(userId);
    }

    final beforeSettings = _featureSettings;
    final beforeLinks = _links;
    final beforePendingApprovals = _pendingApprovals;

    if (_demoMode) {
      _featureSettings = const SharingFeatureSettings(
        emergencySharingEnabled: true,
        physicianSharingEnabled: true,
        maxSharingLinksPerUser: defaultMaxSharingLinksPerUser,
        maxDocumentsToShare: maxSharedFiles,
        minDocumentsToShareLimit: 0,
        maxDocumentsToShareLimit: maxSharedFiles,
        maxSharedDocumentBytes: defaultMaxSharedDocumentBytes,
      );
      await seedDemoSharingData(userId: userId);
    } else {
      await _syncFeatureSettingsFromRemote();
      if (refreshRemoteLinks) {
        await _syncLinksFromRemote();
      }

      await _syncPendingApprovalsFromRemote();
    }

    if (shouldReload ||
        !_sameLinks(beforeLinks, _links) ||
        !_samePendingApprovals(beforePendingApprovals, _pendingApprovals) ||
        !_sameFeatureSettings(beforeSettings, _featureSettings)) {
      notifyListeners();
    }
  }

  Future<void> _syncFeatureSettingsFromRemote() async {
    final configApi = _configApi;
    if (configApi == null) {
      return;
    }

    try {
      final remote = await configApi.getSharingPreferences();
      _featureSettings = _normalizeFeatureSettings(remote);
    } on Exception catch (error, stackTrace) {
      debugPrint('Failed to load sharing settings: $error\n$stackTrace');
    }
  }

  Future<void> _syncLinksFromRemote() async {
    try {
      final remoteLinks = await _apiClient.fetchLinks();
      if (_sameLinks(_links, remoteLinks)) {
        return;
      }

      _links = List<SharingLinkGrant>.from(remoteLinks, growable: false);
      await _persistLinks();
    } on Exception catch (error, stackTrace) {
      debugPrint('Failed to load sharing links: $error\n$stackTrace');
    }
  }

  Future<void> _syncPendingApprovalsFromRemote() async {
    try {
      final remoteRequests = await _apiClient.fetchPendingApprovals();
      if (_samePendingApprovals(_pendingApprovals, remoteRequests)) {
        return;
      }

      _pendingApprovals = List<PendingShareApprovalRequest>.from(
        remoteRequests,
        growable: false,
      );
    } on Exception catch (error, stackTrace) {
      debugPrint(
        'Failed to load pending two-factor approvals: $error\n$stackTrace',
      );
    }
  }

  Future<void> refreshPendingApprovals() async {
    final before = _pendingApprovals;
    await _syncPendingApprovalsFromRemote();
    if (!_samePendingApprovals(before, _pendingApprovals)) {
      notifyListeners();
    }
  }

  Future<ShareApprovalDecisionResult> approvePendingApproval({
    required String requestId,
  }) async {
    return _submitPendingApprovalDecision(requestId: requestId, approved: true);
  }

  Future<ShareApprovalDecisionResult> denyPendingApproval({
    required String requestId,
  }) async {
    return _submitPendingApprovalDecision(
      requestId: requestId,
      approved: false,
    );
  }

  Future<ShareApprovalDecisionResult> _submitPendingApprovalDecision({
    required String requestId,
    required bool approved,
  }) async {
    final decision = await _apiClient.decidePendingApproval(
      requestId: requestId,
      approved: approved,
    );

    final before = _pendingApprovals;
    await _syncPendingApprovalsFromRemote();
    if (!_samePendingApprovals(before, _pendingApprovals)) {
      notifyListeners();
    }

    return decision;
  }

  SharingFeatureSettings _normalizeFeatureSettings(
    SharingPreferencesConfig? remote,
  ) {
    final maxSharingLinksPerUser =
        (remote?.maxSharingLinksPerUser ?? defaultMaxSharingLinksPerUser).clamp(
          0,
          absoluteMaxSharingLinksPerUser,
        );

    final minLimit = (remote?.minDocumentsToShareLimit ?? 0).clamp(
      0,
      maxSharedFiles,
    );
    final maxLimitCandidate =
        (remote?.maxDocumentsToShareLimit ?? maxSharedFiles).clamp(
          0,
          maxSharedFiles,
        );
    final maxLimit = max(minLimit, maxLimitCandidate);
    final selected = (remote?.maxDocumentsToShare ?? maxLimit).clamp(
      minLimit,
      maxLimit,
    );
    final maxDocumentBytes =
        (remote?.maxSharedDocumentBytes ?? defaultMaxSharedDocumentBytes).clamp(
          1,
          defaultMaxSharedDocumentBytes,
        );

    return SharingFeatureSettings(
      emergencySharingEnabled: remote?.emergencySharingEnabled ?? true,
      physicianSharingEnabled: remote?.physicianSharingEnabled ?? true,
      maxSharingLinksPerUser: maxSharingLinksPerUser,
      maxDocumentsToShare: selected,
      minDocumentsToShareLimit: minLimit,
      maxDocumentsToShareLimit: maxLimit,
      maxSharedDocumentBytes: maxDocumentBytes,
    );
  }

  Future<void> seedDemoSharingData({String? userId}) async {
    if (!_demoMode) {
      return;
    }

    final resolvedUserId = userId ?? await _resolveCurrentUserId();
    if (resolvedUserId == null) {
      return;
    }

    if (await _isDemoSeeded(resolvedUserId)) {
      return;
    }

    if (_links.isNotEmpty || _activityLog.isNotEmpty) {
      await _setDemoSeeded(resolvedUserId, seeded: true);
      return;
    }

    final now = DateTime.now();
    final physicianSecurity = SharingSecuritySettings(
      accessDuration: const Duration(days: 30),
      allowDownload: true,
      passwordProtected: true,
    );
    final emergencySecurity = SharingSecuritySettings(
      accessDuration: const Duration(hours: 8),
      allowDownload: false,
      passwordProtected: false,
    );

    final physicianLink = SharingLinkGrant(
      id: _newId('share'),
      type: SharingType.physician,
      targetName: 'Dr. Jane Smith',
      targetEmail: 'jane.smith@hospital.com',
      notes: 'Follow-up visit records',
      scopes: {
        SharingScope.personalInformation,
        SharingScope.medicalInformation,
        SharingScope.allergies,
        SharingScope.medications,
        SharingScope.diagnoses,
        SharingScope.vaccines,
        SharingScope.labResults,
      },
      securitySettings: physicianSecurity,
      createdAt: now.subtract(const Duration(days: 5)),
      expiresAt: now.add(const Duration(days: 25)),
      revokedAt: null,
      shareCode: _newCode(),
      shareUrl: _buildDemoUrl(SharingType.physician, _newCode()),
      qrPayload: _buildDemoUrl(SharingType.physician, _newCode()),
      accessCount: 2,
      lastAccessAt: now.subtract(const Duration(days: 1)),
    );

    final emergencyLink = SharingLinkGrant(
      id: _newId('share'),
      type: SharingType.emergency,
      targetName: 'Emergency Access QR',
      targetEmail: null,
      notes: 'Created for urgent responders',
      scopes: {
        SharingScope.bloodType,
        SharingScope.allergies,
        SharingScope.medications,
        SharingScope.diagnoses,
        SharingScope.vaccines,
        SharingScope.emergencyContact,
      },
      securitySettings: emergencySecurity,
      createdAt: now.subtract(const Duration(hours: 2)),
      expiresAt: now.add(const Duration(hours: 6)),
      revokedAt: null,
      shareCode: _newCode(),
      shareUrl: _buildDemoUrl(SharingType.emergency, _newCode()),
      qrPayload: _buildDemoUrl(SharingType.emergency, _newCode()),
      accessCount: 0,
      lastAccessAt: null,
    );

    final expiredLink = SharingLinkGrant(
      id: _newId('share'),
      type: SharingType.physician,
      targetName: 'Dr. Robert Brown',
      targetEmail: 'r.brown@clinic.com',
      notes: 'One-time consultation',
      scopes: {SharingScope.medicalInformation, SharingScope.labResults},
      securitySettings: SharingSecuritySettings(
        accessDuration: const Duration(days: 14),
      ),
      createdAt: now.subtract(const Duration(days: 30)),
      expiresAt: now.subtract(const Duration(days: 10)),
      revokedAt: null,
      shareCode: _newCode(),
      shareUrl: _buildDemoUrl(SharingType.physician, _newCode()),
      qrPayload: _buildDemoUrl(SharingType.physician, _newCode()),
      accessCount: 1,
      lastAccessAt: now.subtract(const Duration(days: 12)),
    );

    _links = [physicianLink, emergencyLink, expiredLink];
    _activityLog = [
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: emergencyLink.id,
        type: SharingActivityType.loginFailed,
        title: 'Emergency QR Code Scanned',
        details: 'Unknown user attempted to access emergency records.',
        actorName: 'Unknown user',
        location: 'New York, NY',
        ipAddress: '192.168.1.100',
        occurredAt: now.subtract(const Duration(hours: 3)),
        highRisk: true,
      ),
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: physicianLink.id,
        type: SharingActivityType.linkAccessed,
        title: 'Provider Viewed Records',
        details: 'Accessed lab results and medication history.',
        actorName: 'Dr. Jane Smith',
        location: null,
        ipAddress: null,
        occurredAt: now.subtract(const Duration(hours: 6)),
        highRisk: false,
      ),
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: physicianLink.id,
        type: SharingActivityType.linkCreated,
        title: 'Shared Records with Provider',
        details: 'Created secure physician sharing link.',
        actorName: 'You',
        location: null,
        ipAddress: null,
        occurredAt: now.subtract(const Duration(days: 1)),
        highRisk: false,
      ),
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: expiredLink.id,
        type: SharingActivityType.permissionsUpdated,
        title: 'Medical Information Updated',
        details: 'Adjusted shared fields and removed documents.',
        actorName: 'You',
        location: null,
        ipAddress: null,
        occurredAt: now.subtract(const Duration(days: 2)),
        highRisk: false,
      ),
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: emergencyLink.id,
        type: SharingActivityType.loginFailed,
        title: 'Failed Login Attempt',
        details: 'Wrong OTP while opening secure share.',
        actorName: 'Unknown',
        location: 'Unknown Location',
        ipAddress: '203.0.113.42',
        occurredAt: now.subtract(const Duration(days: 3)),
        highRisk: true,
      ),
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: physicianLink.id,
        type: SharingActivityType.loginSuccess,
        title: 'Successfully Logged In',
        details: 'Provider authenticated successfully.',
        actorName: 'Dr. Robert Brown',
        location: 'New York, NY',
        ipAddress: '192.168.1.100',
        occurredAt: now.subtract(const Duration(days: 4)),
        highRisk: false,
      ),
    ];

    await _persistAll();
    await _setDemoSeeded(resolvedUserId, seeded: true);
    notifyListeners();
  }

  Future<SharingLinkGrant> createEmergencySharingLink({
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
    Set<String> selectedFileIds = const {},
  }) async {
    await initialize();
    if (!emergencySharingEnabled) {
      throw StateError('Emergency sharing is disabled by your settings.');
    }

    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('No authenticated user for sharing flow.');
    }

    _ensureCanCreateSharingLink();

    final createdAt = DateTime.now();
    final localId = _newId('share');
    final localCode = _newCode();
    final localUrl = _buildDemoUrl(SharingType.emergency, localCode);

    final snapshot = _demoMode
        ? const ShareSnapshotPayload(
            patientInfo: null,
            medicalSummary: ShareMedicalSummaryPayload(
              allergies: <ShareAllergyPayload>[],
              activeMedications: <ShareMedicationPayload>[],
              conditions: <ShareConditionPayload>[],
              vaccinations: <ShareVaccinationPayload>[],
            ),
            medicalHistory: <ShareMedicalHistoryEntryPayload>[],
            documents: <ShareDocumentPayload>[],
          )
        : await _buildSharedSnapshot(
            user: await _currentUserProvider(),
            scopes: scopes,
            selectedFileIds: selectedFileIds,
          );

    final remote = _demoMode
        ? null
        : await _apiClient.createEmergencyLink(
            scopes: scopes,
            securitySettings: securitySettings,
            sharedSnapshot: snapshot,
          );

    if (!_demoMode && remote == null) {
      throw StateError('Sharing API did not return emergency link details.');
    }

    final link = SharingLinkGrant(
      id: remote?.linkId ?? localId,
      type: SharingType.emergency,
      targetName: 'Emergency Access QR',
      targetEmail: null,
      notes: 'Emergency responders access',
      scopes: scopes,
      securitySettings: securitySettings.withoutSecrets(),
      createdAt: createdAt,
      expiresAt: remote?.expiresAt ?? securitySettings.resolveExpiry(createdAt),
      revokedAt: null,
      shareCode: remote?.shareCode ?? localCode,
      shareUrl: remote?.shareUrl ?? localUrl,
      qrPayload: remote?.qrPayload ?? localUrl,
      accessCount: 0,
      lastAccessAt: null,
    );

    _links = [link, ..._links];
    await _persistLinks();

    if (!_demoMode) {
      await _appendActivity(
        SharingActivityEntry(
          id: _newId('evt'),
          linkId: link.id,
          type: SharingActivityType.linkCreated,
          title: 'Emergency access link generated',
          details: 'Generated emergency QR with scoped permissions.',
          actorName: 'You',
          location: null,
          ipAddress: null,
          occurredAt: createdAt,
          highRisk: false,
        ),
      );
    }

    notifyListeners();
    return link;
  }

  Future<SharingLinkGrant> createPhysicianSharingLink({
    required String physicianName,
    required String? physicianEmail,
    required String? notes,
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
    Set<String> selectedFileIds = const {},
  }) async {
    await initialize();
    if (!physicianSharingEnabled) {
      throw StateError('Physician sharing is disabled by your settings.');
    }

    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('No authenticated user for sharing flow.');
    }

    _ensureCanCreateSharingLink();

    final createdAt = DateTime.now();
    final localId = _newId('share');
    final localCode = _newCode();
    final localUrl = _buildDemoUrl(SharingType.physician, localCode);

    final snapshot = _demoMode
        ? const ShareSnapshotPayload(
            patientInfo: null,
            medicalSummary: ShareMedicalSummaryPayload(
              allergies: <ShareAllergyPayload>[],
              activeMedications: <ShareMedicationPayload>[],
              conditions: <ShareConditionPayload>[],
              vaccinations: <ShareVaccinationPayload>[],
            ),
            medicalHistory: <ShareMedicalHistoryEntryPayload>[],
            documents: <ShareDocumentPayload>[],
          )
        : await _buildSharedSnapshot(
            user: await _currentUserProvider(),
            scopes: scopes,
            selectedFileIds: selectedFileIds,
          );

    final remote = _demoMode
        ? null
        : await _apiClient.createPhysicianLink(
            physicianName: physicianName,
            physicianEmail: physicianEmail,
            notes: notes,
            scopes: scopes,
            securitySettings: securitySettings,
            sharedSnapshot: snapshot,
          );

    final normalizedPhysicianEmail = physicianEmail?.trim();
    final targetEmail =
        normalizedPhysicianEmail == null || normalizedPhysicianEmail.isEmpty
        ? null
        : normalizedPhysicianEmail;

    if (!_demoMode && remote == null) {
      throw StateError('Sharing API did not return physician link details.');
    }

    final link = SharingLinkGrant(
      id: remote?.linkId ?? localId,
      type: SharingType.physician,
      targetName: physicianName,
      targetEmail: targetEmail,
      notes: notes,
      scopes: scopes,
      securitySettings: securitySettings.withoutSecrets(),
      createdAt: createdAt,
      expiresAt: remote?.expiresAt ?? securitySettings.resolveExpiry(createdAt),
      revokedAt: null,
      shareCode: remote?.shareCode ?? localCode,
      shareUrl: remote?.shareUrl ?? localUrl,
      qrPayload: remote?.qrPayload ?? localUrl,
      accessCount: 0,
      lastAccessAt: null,
    );

    _links = [link, ..._links];
    await _persistLinks();

    if (!_demoMode) {
      await _appendActivity(
        SharingActivityEntry(
          id: _newId('evt'),
          linkId: link.id,
          type: SharingActivityType.linkCreated,
          title: 'Physician sharing link created',
          details: 'Shared medical records with $physicianName.',
          actorName: 'You',
          location: null,
          ipAddress: null,
          occurredAt: createdAt,
          highRisk: false,
        ),
      );
    }

    notifyListeners();
    return link;
  }

  Future<ShareSnapshotPayload> _buildSharedSnapshot({
    required AuthUser? user,
    required Set<SharingScope> scopes,
    required Set<String> selectedFileIds,
  }) async {
    if (user == null) {
      throw StateError('No authenticated user for sharing flow.');
    }

    if (selectedFileIds.length > maxDocumentsToShare) {
      throw StateError(
        'A maximum of $maxDocumentsToShare files can be shared.',
      );
    }

    final includePersonalInfo = _hasAnyScope(scopes, {
      SharingScope.personalInformation,
      SharingScope.medicalInformation,
    });
    final includeBloodType = _hasAnyScope(scopes, {
      SharingScope.bloodType,
      SharingScope.medicalInformation,
    });
    final includeEmergencyContact = _hasAnyScope(scopes, {
      SharingScope.emergencyContact,
      SharingScope.medicalInformation,
    });
    final includeAllergies = _hasAnyScope(scopes, {
      SharingScope.allergies,
      SharingScope.medicalInformation,
    });
    final includeMedications = _hasAnyScope(scopes, {
      SharingScope.medications,
      SharingScope.medicalInformation,
    });
    final includeConditions = _hasAnyScope(scopes, {
      SharingScope.diagnoses,
      SharingScope.medicalInformation,
    });
    final includeVaccinations = _hasAnyScope(scopes, {
      SharingScope.vaccines,
      SharingScope.medicalInformation,
    });
    final includeHistory = _hasAnyScope(scopes, {
      SharingScope.medicalHistory,
      SharingScope.labResults,
      SharingScope.medicalInformation,
    });
    final includeDocuments = _hasAnyScope(scopes, {
      SharingScope.medicalDocuments,
    });
    final profileData = await _loadProfileDataForSnapshot();
    final profile = profileData?.profile;
    final primaryEmergencyContact = _selectPrimaryEmergencyContact(
      profileData?.emergencyContacts ?? const <EmergencyContact>[],
    );

    final medicalData = _medicalDataService;
    final bloodType = medicalData?.bloodType;
    final normalizedBloodType =
        bloodType == null || bloodType == BloodGroup.unknown.value
        ? null
        : bloodType;

    final displayName = _normalizeDisplayName(user, profile: profile);
    final patientInfo =
        (includePersonalInfo || includeBloodType || includeEmergencyContact)
        ? SharePatientInfoPayload(
            displayName: displayName,
            initials: _toInitials(displayName),
            dateOfBirth: includePersonalInfo
                ? _normalizeOptionalText(profile?.dateOfBirth)
                : null,
            gender: includePersonalInfo ? profile?.gender?.apiValue : null,
            bloodType: includeBloodType ? normalizedBloodType : null,
            emergencyContactName: includeEmergencyContact
                ? _normalizeOptionalText(
                    primaryEmergencyContact?.name ??
                        profile?.emergencyContactName,
                  )
                : null,
            emergencyContactPhone: includeEmergencyContact
                ? _normalizeOptionalText(
                    primaryEmergencyContact?.phone ??
                        profile?.emergencyContactPhone,
                  )
                : null,
            emergencyContactRelationship: includeEmergencyContact
                ? _normalizeOptionalText(
                    primaryEmergencyContact?.relationship.apiValue ??
                        profile?.emergencyContactRelationship,
                  )
                : null,
          )
        : null;

    final summary = ShareMedicalSummaryPayload(
      allergies: includeAllergies
          ? (medicalData?.allergies ?? const <Allergy>[])
                .map(
                  (allergy) => ShareAllergyPayload(
                    id: allergy.id,
                    allergenName: allergy.substance,
                    allergyType: allergy.reaction,
                    severity: allergy.severity.name,
                    reaction: allergy.reaction,
                    diagnosedDate: allergy.createdAt.toIso8601String(),
                    isActive: allergy.status == AllergyStatus.active,
                  ),
                )
                .toList(growable: false)
          : const <ShareAllergyPayload>[],
      activeMedications: includeMedications
          ? (medicalData?.medications ?? const <Medication>[])
                .map(
                  (medication) => ShareMedicationPayload(
                    id: medication.id,
                    medicationName: medication.name,
                    genericName: null,
                    dosage: medication.dosage,
                    frequency: medication.frequency,
                    route: null,
                    prescribedBy: null,
                    startDate: medication.startDate.toIso8601String(),
                    endDate: medication.endDate?.toIso8601String(),
                    isActive: medication.status == MedicationStatus.active,
                  ),
                )
                .toList(growable: false)
          : const <ShareMedicationPayload>[],
      conditions: includeConditions
          ? (medicalData?.diagnoses ?? const <Diagnosis>[])
                .map(
                  (condition) => ShareConditionPayload(
                    id: condition.id,
                    conditionName: condition.name,
                    icdCode: null,
                    diagnosedDate: condition.date.toIso8601String(),
                    status: condition.status.name,
                    treatmentPlan: condition.notes,
                  ),
                )
                .toList(growable: false)
          : const <ShareConditionPayload>[],
      vaccinations: includeVaccinations
          ? (medicalData?.vaccinations ?? const <Vaccination>[])
                .map(
                  (vaccination) => ShareVaccinationPayload(
                    id: vaccination.id,
                    vaccineName: vaccination.vaccineName,
                    manufacturer: null,
                    lotNumber: null,
                    administeredDate: vaccination.dates.isEmpty
                        ? vaccination.createdAt.toIso8601String()
                        : vaccination.dates.first.toIso8601String(),
                    doseNumber: vaccination.dates.length,
                    administeredBy: null,
                    nextDoseDate: null,
                  ),
                )
                .toList(growable: false)
          : const <ShareVaccinationPayload>[],
    );

    final history = includeHistory
        ? (medicalData?.labResults ?? const <LabResult>[])
              .map(
                (result) => ShareMedicalHistoryEntryPayload(
                  id: result.id,
                  date: result.testDate.toIso8601String(),
                  type: 'LabResult',
                  title: result.testName,
                  description: result.values
                      .map(
                        (value) =>
                            '${value.name}: ${value.value} ${value.unit}',
                      )
                      .join('; '),
                  provider: null,
                  facility: null,
                  notes: result.notes,
                  severity:
                      result.values.any(
                        (value) => value.status == TestResultStatus.abnormal,
                      )
                      ? 'Abnormal'
                      : null,
                ),
              )
              .toList(growable: false)
        : const <ShareMedicalHistoryEntryPayload>[];

    final documents = await _buildSelectedDocumentPayload(
      includeDocuments: includeDocuments,
      selectedFileIds: selectedFileIds,
    );

    final snapshot = ShareSnapshotPayload(
      patientInfo: patientInfo,
      medicalSummary: summary,
      medicalHistory: history,
      documents: documents,
    );

    if (!snapshot.hasAnyContent) {
      throw StateError('Select at least one data section to share.');
    }

    return snapshot;
  }

  Future<List<ShareDocumentPayload>> _buildSelectedDocumentPayload({
    required bool includeDocuments,
    required Set<String> selectedFileIds,
  }) async {
    if (!includeDocuments) {
      return const <ShareDocumentPayload>[];
    }

    if (maxDocumentsToShare == 0) {
      throw StateError('Document sharing is disabled by your settings.');
    }

    if (selectedFileIds.isEmpty) {
      throw StateError('Select at least one file to share.');
    }

    final documentsService = _documentsService;
    if (documentsService == null) {
      throw StateError('Documents service is not available for sharing.');
    }

    await documentsService.initialize();

    final selected = <ShareDocumentPayload>[];
    for (final document in documentsService.documents) {
      for (final file in document.files) {
        if (!selectedFileIds.contains(file.id)) {
          continue;
        }

        selected.add(
          ShareDocumentPayload(
            id: file.id,
            title: document.title,
            category: document.category.name,
            description: document.description,
            fileName: file.fileName,
            contentType: file.mimeType,
            fileSizeBytes: file.fileSizeBytes,
            contentBase64: _encodeSharedDocumentContent(file),
            downloadUrl: null,
            uploadedAt: file.createdAt.toIso8601String(),
          ),
        );

        if (selected.length == maxDocumentsToShare) {
          return selected;
        }
      }
    }

    if (selected.isEmpty) {
      throw StateError('No matching selected files were found.');
    }

    return selected;
  }

  String _encodeSharedDocumentContent(MedicalDocumentFile file) {
    if (file.encryptedPayload.isEmpty) {
      throw StateError(
        'Document ${file.fileName} is empty and cannot be shared.',
      );
    }

    if (file.fileSizeBytes > maxSharedDocumentBytes) {
      throw StateError(
        'Cannot share "${file.fileName}" (${_formatBytes(file.fileSizeBytes)}). '
        'Maximum allowed file size is ${_formatBytes(maxSharedDocumentBytes)}.',
      );
    }

    return base64Encode(file.encryptedPayload);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb < 100 ? 1 : 0)} KB';
    }

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 100 ? 1 : 0)} MB';
  }

  bool _hasAnyScope(Set<SharingScope> scopes, Set<SharingScope> expected) {
    if (scopes.isEmpty) {
      return true;
    }

    return scopes.any(expected.contains);
  }

  String _normalizeDisplayName(AuthUser user, {UserProfile? profile}) {
    final profileName = [profile?.firstName, profile?.lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();
    if (profileName.isNotEmpty) {
      return profileName;
    }

    final profileDisplayName = profile?.displayName?.trim();
    if (profileDisplayName != null && profileDisplayName.isNotEmpty) {
      return profileDisplayName;
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return user.email;
  }

  String _toInitials(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) {
      return 'MV';
    }

    if (words.length == 1) {
      final token = words.first.trim();
      if (token.isEmpty) {
        return 'MV';
      }

      if (token.length == 1) {
        return token.toUpperCase();
      }

      return token.substring(0, 2).toUpperCase();
    }

    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Future<ProfileData?> _loadProfileDataForSnapshot() async {
    final profileService = _profileService;
    if (profileService == null || _demoMode) {
      return null;
    }

    try {
      return await profileService.loadProfileData();
    } on Exception catch (error, stackTrace) {
      debugPrint(
        'Failed to load profile for sharing snapshot: $error\n$stackTrace',
      );
      return null;
    }
  }

  EmergencyContact? _selectPrimaryEmergencyContact(
    List<EmergencyContact> contacts,
  ) {
    if (contacts.isEmpty) {
      return null;
    }

    for (final contact in contacts) {
      if (contact.isPrimary) {
        return contact;
      }
    }

    return contacts.first;
  }

  String? _normalizeOptionalText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  Future<void> updateLinkPermissions({
    required String linkId,
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
  }) async {
    await initialize(refreshRemoteLinks: false);

    if (!_demoMode) {
      await _safeUpdatePermissions(
        linkId: linkId,
        scopes: scopes,
        securitySettings: securitySettings,
      );
    }

    final index = _links.indexWhere((link) => link.id == linkId);
    if (index == -1) {
      return;
    }

    final updated = _links[index].copyWith(
      scopes: scopes,
      securitySettings: securitySettings.withoutSecrets(),
      expiresAt: securitySettings.resolveExpiry(_links[index].createdAt),
    );

    final next = List<SharingLinkGrant>.from(_links);
    next[index] = updated;
    _links = next;
    await _persistLinks();

    await _appendActivity(
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: linkId,
        type: SharingActivityType.permissionsUpdated,
        title: 'Sharing permissions updated',
        details: 'Updated data visibility and security options.',
        actorName: 'You',
        location: null,
        ipAddress: null,
        occurredAt: DateTime.now(),
        highRisk: false,
      ),
    );

    notifyListeners();
  }

  Future<void> revokeLink({required String linkId}) async {
    await initialize(refreshRemoteLinks: false);

    if (!_demoMode) {
      await _safeRevokeLink(linkId: linkId);
    }

    final index = _links.indexWhere((link) => link.id == linkId);
    if (index == -1) {
      return;
    }

    final current = _links[index];
    if (current.revokedAt != null) {
      return;
    }

    final revoked = current.copyWith(revokedAt: DateTime.now());
    final next = List<SharingLinkGrant>.from(_links);
    next[index] = revoked;
    _links = next;
    await _persistLinks();

    await _appendActivity(
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: linkId,
        type: SharingActivityType.linkRevoked,
        title: 'Access revoked',
        details: 'The sharing link was revoked by the owner.',
        actorName: 'You',
        location: null,
        ipAddress: null,
        occurredAt: DateTime.now(),
        highRisk: false,
      ),
    );

    notifyListeners();
  }

  Future<void> recordAccess({
    required String linkId,
    required String actorName,
    required String details,
    required bool highRisk,
    String? location,
    String? ipAddress,
  }) async {
    await initialize(refreshRemoteLinks: false);

    final index = _links.indexWhere((link) => link.id == linkId);
    if (index == -1) {
      return;
    }

    final current = _links[index];
    final updated = current.copyWith(
      accessCount: current.accessCount + 1,
      lastAccessAt: DateTime.now(),
    );

    final next = List<SharingLinkGrant>.from(_links);
    next[index] = updated;
    _links = next;
    await _persistLinks();

    await _appendActivity(
      SharingActivityEntry(
        id: _newId('evt'),
        linkId: linkId,
        type: SharingActivityType.linkAccessed,
        title: highRisk ? 'Emergency link accessed' : 'Shared records accessed',
        details: details,
        actorName: actorName,
        location: location,
        ipAddress: ipAddress,
        occurredAt: DateTime.now(),
        highRisk: highRisk,
      ),
    );

    notifyListeners();
  }

  Future<void> _appendActivity(SharingActivityEntry entry) async {
    _activityLog = [entry, ..._activityLog];
    await _persistActivity();

    if (!_demoMode) {
      await _safeLogActivity(entry);
    }
  }

  Future<void> _loadFromDatabase(String userId) async {
    final linksRaw = await _readSetting(_linksStorageKey(userId));
    final activityRaw = await _readSetting(_activityStorageKey(userId));

    _links = SharingLinkGrant.decodeList(linksRaw);
    _activityLog = SharingActivityEntry.decodeList(activityRaw);
  }

  Future<void> _persistAll() async {
    await _persistLinks();
    await _persistActivity();
  }

  Future<void> _persistLinks() async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    await _writeSetting(
      _linksStorageKey(userId),
      SharingLinkGrant.encodeList(_links),
    );
  }

  Future<void> _persistActivity() async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    await _writeSetting(
      _activityStorageKey(userId),
      SharingActivityEntry.encodeList(_activityLog),
    );
  }

  String _linksStorageKey(String userId) {
    return 'sharing_links_$userId';
  }

  String _activityStorageKey(String userId) {
    return 'sharing_activity_$userId';
  }

  String _demoSeedKey(String userId) {
    return 'sharing_demo_seeded_$userId';
  }

  Future<bool> _isDemoSeeded(String userId) async {
    final raw = await _readSetting(_demoSeedKey(userId));
    return raw == '1';
  }

  Future<void> _setDemoSeeded(String userId, {required bool seeded}) async {
    await _writeSetting(_demoSeedKey(userId), seeded ? '1' : '0');
  }

  Future<String?> _resolveCurrentUserId() async {
    final user = await _currentUserProvider();
    final userId = user?.email.trim();
    if (userId == null || userId.isEmpty) {
      return null;
    }

    return userId;
  }

  Future<String?> _readSetting(String key) async {
    final query = _db.select(_db.settings)..where((tbl) => tbl.key.equals(key));
    final setting = await query.getSingleOrNull();
    return setting?.value;
  }

  Future<void> _writeSetting(String key, String value) async {
    await _db
        .into(_db.settings)
        .insert(
          db.SettingsCompanion(key: Value(key), value: Value(value)),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> _safeUpdatePermissions({
    required String linkId,
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
  }) async {
    await _apiClient.updateLinkPermissions(
      linkId: linkId,
      scopes: scopes,
      securitySettings: securitySettings,
    );
  }

  Future<void> _safeRevokeLink({required String linkId}) async {
    await _apiClient.revokeLink(linkId: linkId);
  }

  Future<void> _safeLogActivity(SharingActivityEntry activity) async {
    try {
      await _apiClient.logActivity(activity);
    } on Exception catch (error, stackTrace) {
      debugPrint('Failed to sync sharing activity: $error\n$stackTrace');
    }
  }

  String _newId(String prefix) {
    final random = Random.secure();
    final now = DateTime.now().millisecondsSinceEpoch;
    final suffix = random.nextInt(1 << 31).toRadixString(16);
    return '$prefix-$now-$suffix';
  }

  String _newCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final buffer = StringBuffer();

    for (var i = 0; i < 8; i++) {
      final index = random.nextInt(alphabet.length);
      buffer.write(alphabet[index]);
    }

    return buffer.toString();
  }

  String _buildDemoUrl(SharingType type, String code) {
    final segment = type == SharingType.emergency ? 'emergency' : 'provider';
    return 'https://demo.medvault.app/$segment/$code';
  }

  void _ensureCanCreateSharingLink() {
    final maxLinks = _featureSettings.maxSharingLinksPerUser;
    if (maxLinks == 0) {
      throw StateError('Sharing link creation is disabled by your settings.');
    }

    if (activeLinksCount >= maxLinks) {
      throw StateError(
        'You have reached the maximum of $maxLinks active sharing links. Revoke an existing link to create a new one.',
      );
    }
  }

  bool _sameLinks(List<SharingLinkGrant> left, List<SharingLinkGrant> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var i = 0; i < left.length; i++) {
      final leftJson = left[i].toJson();
      final rightJson = right[i].toJson();
      if (!mapEquals(leftJson, rightJson)) {
        return false;
      }
    }

    return true;
  }

  bool _samePendingApprovals(
    List<PendingShareApprovalRequest> left,
    List<PendingShareApprovalRequest> right,
  ) {
    if (left.length != right.length) {
      return false;
    }

    for (var i = 0; i < left.length; i++) {
      final leftItem = left[i];
      final rightItem = right[i];
      if (leftItem.requestId != rightItem.requestId ||
          leftItem.status != rightItem.status ||
          leftItem.expiresAt != rightItem.expiresAt ||
          leftItem.viewerName != rightItem.viewerName) {
        return false;
      }
    }

    return true;
  }

  bool _sameFeatureSettings(
    SharingFeatureSettings left,
    SharingFeatureSettings right,
  ) {
    return left.emergencySharingEnabled == right.emergencySharingEnabled &&
        left.physicianSharingEnabled == right.physicianSharingEnabled &&
        left.maxSharingLinksPerUser == right.maxSharingLinksPerUser &&
        left.maxDocumentsToShare == right.maxDocumentsToShare &&
        left.minDocumentsToShareLimit == right.minDocumentsToShareLimit &&
        left.maxDocumentsToShareLimit == right.maxDocumentsToShareLimit &&
        left.maxSharedDocumentBytes == right.maxSharedDocumentBytes;
  }
}
