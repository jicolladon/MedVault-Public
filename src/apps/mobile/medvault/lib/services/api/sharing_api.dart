import 'dart:convert';

import '../../models/sharing_models.dart';
import '../api_client.dart';
import 'auth_api.dart';

class SharingApiLinkResponse {
  final String linkId;
  final String shareCode;
  final String shareUrl;
  final String qrPayload;
  final DateTime expiresAt;

  const SharingApiLinkResponse({
    required this.linkId,
    required this.shareCode,
    required this.shareUrl,
    required this.qrPayload,
    required this.expiresAt,
  });
}

abstract class SharingApiClient {
  Future<List<SharingLinkGrant>> fetchLinks();

  Future<List<PendingShareApprovalRequest>> fetchPendingApprovals();

  Future<ShareApprovalDecisionResult> decidePendingApproval({
    required String requestId,
    required bool approved,
  });

  Future<SharingApiLinkResponse?> createEmergencyLink({
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
    required ShareSnapshotPayload sharedSnapshot,
  });

  Future<SharingApiLinkResponse?> createPhysicianLink({
    required String physicianName,
    required String? physicianEmail,
    required String? notes,
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
    required ShareSnapshotPayload sharedSnapshot,
  });

  Future<void> updateLinkPermissions({
    required String linkId,
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
  });

  Future<void> revokeLink({required String linkId});

  Future<void> logActivity(SharingActivityEntry activity);
}

class PendingSharingApiClient implements SharingApiClient {
  const PendingSharingApiClient({ApiClient? apiClient})
    : _apiClient = apiClient;

  final ApiClient? _apiClient;

  @override
  Future<List<SharingLinkGrant>> fetchLinks() async {
    final apiClient = _requireApiClient();
    final response = await apiClient.get('/api/user/sharing/links');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to load sharing links');
    }

    final payload = _unwrapEnvelope(response.body);
    if (payload is! List) {
      return const [];
    }

    return payload
        .whereType<Map>()
        .map((value) => _toSharingLinkGrant(Map<String, dynamic>.from(value)))
        .toList(growable: false);
  }

  @override
  Future<List<PendingShareApprovalRequest>> fetchPendingApprovals() async {
    final apiClient = _requireApiClient();
    final response = await apiClient.get(
      '/api/user/sharing/two-factor-requests/pending',
    );
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to load pending two-factor approvals',
      );
    }

    final payload = _unwrapEnvelope(response.body);
    if (payload is! List) {
      return const [];
    }

    return payload
        .whereType<Map>()
        .map(
          (value) =>
              _toPendingApprovalRequest(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }

  @override
  Future<ShareApprovalDecisionResult> decidePendingApproval({
    required String requestId,
    required bool approved,
  }) async {
    final apiClient = _requireApiClient();
    final response = await apiClient.post(
      '/api/user/sharing/two-factor-requests/$requestId/decision',
      body: {'approved': approved},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to submit two-factor approval decision',
      );
    }

    return _toApprovalDecision(_requireDataMap(response.body));
  }

  @override
  Future<SharingApiLinkResponse?> createEmergencyLink({
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
    required ShareSnapshotPayload sharedSnapshot,
  }) async {
    final apiClient = _requireApiClient();
    final response = await apiClient.post(
      '/api/user/sharing/emergency-links',
      body: {
        'scopes': scopes.map((scope) => scope.wireName).toList(growable: false),
        'securitySettings': {
          'accessDurationMinutes': securitySettings.accessDuration.inMinutes,
          'passwordProtected': securitySettings.passwordProtected,
          'requiresTwoFactorApproval':
              securitySettings.requiresTwoFactorApproval,
          'allowDownload': securitySettings.allowDownload,
          'notifyOnAccess': securitySettings.notifyOnAccess,
          if (securitySettings.accessPassword != null)
            'accessPassword': securitySettings.accessPassword,
          if (securitySettings.verificationCode != null)
            'verificationCode': securitySettings.verificationCode,
        },
        'sharedSnapshot': sharedSnapshot.toJson(),
      },
    );

    if (!_isSuccess(response.statusCode, allowCreated: true)) {
      throw ApiException(
        response.statusCode,
        'Failed to create emergency sharing link',
      );
    }

    return _toLinkResponse(_requireDataMap(response.body));
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
    final apiClient = _requireApiClient();
    final response = await apiClient.post(
      '/api/user/sharing/physician-links',
      body: {
        'physicianName': physicianName,
        'physicianEmail': physicianEmail,
        'notes': notes,
        'scopes': scopes.map((scope) => scope.wireName).toList(growable: false),
        'securitySettings': {
          'accessDurationMinutes': securitySettings.accessDuration.inMinutes,
          'passwordProtected': securitySettings.passwordProtected,
          'requiresTwoFactorApproval':
              securitySettings.requiresTwoFactorApproval,
          'allowDownload': securitySettings.allowDownload,
          'notifyOnAccess': securitySettings.notifyOnAccess,
          if (securitySettings.accessPassword != null)
            'accessPassword': securitySettings.accessPassword,
          if (securitySettings.verificationCode != null)
            'verificationCode': securitySettings.verificationCode,
        },
        'sharedSnapshot': sharedSnapshot.toJson(),
      },
    );

    if (!_isSuccess(response.statusCode, allowCreated: true)) {
      throw ApiException(
        response.statusCode,
        'Failed to create physician sharing link',
      );
    }

    return _toLinkResponse(_requireDataMap(response.body));
  }

  @override
  Future<void> updateLinkPermissions({
    required String linkId,
    required Set<SharingScope> scopes,
    required SharingSecuritySettings securitySettings,
  }) async {
    final apiClient = _requireApiClient();
    final response = await apiClient.put(
      '/api/user/sharing/links/$linkId',
      body: {
        'scopes': scopes.map((scope) => scope.wireName).toList(growable: false),
        'securitySettings': {
          'accessDurationMinutes': securitySettings.accessDuration.inMinutes,
          'passwordProtected': securitySettings.passwordProtected,
          'requiresTwoFactorApproval':
              securitySettings.requiresTwoFactorApproval,
          'allowDownload': securitySettings.allowDownload,
          'notifyOnAccess': securitySettings.notifyOnAccess,
          if (securitySettings.accessPassword != null)
            'accessPassword': securitySettings.accessPassword,
          if (securitySettings.verificationCode != null)
            'verificationCode': securitySettings.verificationCode,
        },
      },
    );

    if (!_isSuccess(response.statusCode, allowNoContent: true)) {
      throw ApiException(
        response.statusCode,
        'Failed to update sharing permissions',
      );
    }
  }

  @override
  Future<void> revokeLink({required String linkId}) async {
    final apiClient = _requireApiClient();
    final response = await apiClient.delete('/api/user/sharing/links/$linkId');
    if (!_isSuccess(response.statusCode, allowNoContent: true)) {
      throw ApiException(response.statusCode, 'Failed to revoke sharing link');
    }
  }

  bool _isSuccess(
    int statusCode, {
    bool allowCreated = false,
    bool allowNoContent = false,
  }) {
    if (statusCode == 200) {
      return true;
    }
    if (allowCreated && statusCode == 201) {
      return true;
    }
    if (allowNoContent && statusCode == 204) {
      return true;
    }
    return false;
  }

  @override
  Future<void> logActivity(SharingActivityEntry activity) async {
    await Future<void>.value();
  }

  Map<String, dynamic> _requireDataMap(String responseBody) {
    final payload = _unwrapEnvelope(responseBody);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Unexpected sharing API payload format.');
    }

    return payload;
  }

  Object? _unwrapEnvelope(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      return decoded;
    }

    return decoded['data'] ?? decoded;
  }

  SharingApiLinkResponse _toLinkResponse(Map<String, dynamic> json) {
    final linkId = json['linkId']?.toString() ?? '';
    final shareCode = json['shareCode']?.toString() ?? '';
    final shareUrl = json['shareUrl']?.toString() ?? '';
    final qrPayload = json['qrPayload']?.toString() ?? shareUrl;
    final expiresAtRaw = json['expiresAt']?.toString();
    final expiresAt = expiresAtRaw != null
        ? DateTime.tryParse(expiresAtRaw)
        : null;

    if (linkId.isEmpty ||
        shareCode.isEmpty ||
        shareUrl.isEmpty ||
        expiresAt == null) {
      throw const FormatException('Incomplete sharing link response payload.');
    }

    return SharingApiLinkResponse(
      linkId: linkId,
      shareCode: shareCode,
      shareUrl: shareUrl,
      qrPayload: qrPayload,
      expiresAt: expiresAt,
    );
  }

  SharingLinkGrant _toSharingLinkGrant(Map<String, dynamic> json) {
    final type = _toSharingType(json['shareType']?.toString());
    final recipientName = json['recipientName']?.toString();
    final recipientEmail = json['recipientEmail']?.toString();
    final notes = json['notes']?.toString();
    final scopes = _parseScopes(json['scopes']);
    final securitySettings = _parseSecuritySettings(json['securitySettings']);

    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final expiresAt =
        DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
        securitySettings.resolveExpiry(createdAt);
    final revokedAt = DateTime.tryParse(json['revokedAt']?.toString() ?? '');
    final accessCount =
        int.tryParse(json['accessCount']?.toString() ?? '') ?? 0;
    final lastAccessAt = DateTime.tryParse(
      json['lastAccessedAt']?.toString() ?? '',
    );

    final targetName = recipientName?.trim().isNotEmpty == true
        ? recipientName!.trim()
        : (type == SharingType.emergency
              ? 'Emergency Access QR'
              : 'Healthcare Provider');

    final shareUrl = json['shareUrl']?.toString() ?? '';
    final qrPayload = json['qrPayload']?.toString() ?? shareUrl;
    final shareCode = json['shareCode']?.toString() ?? '';

    return SharingLinkGrant(
      id: json['linkId']?.toString() ?? '',
      type: type,
      targetName: targetName,
      targetEmail: recipientEmail,
      notes: notes,
      scopes: scopes,
      securitySettings: securitySettings,
      createdAt: createdAt,
      expiresAt: expiresAt,
      revokedAt: revokedAt,
      shareCode: shareCode,
      shareUrl: shareUrl,
      qrPayload: qrPayload,
      accessCount: accessCount,
      lastAccessAt: lastAccessAt,
    );
  }

  PendingShareApprovalRequest _toPendingApprovalRequest(
    Map<String, dynamic> json,
  ) {
    final requestId = json['requestId']?.toString() ?? '';
    final shareLinkId = json['shareLinkId']?.toString() ?? '';
    final shareCode = json['shareCode']?.toString() ?? '';
    final viewerName = json['viewerName']?.toString() ?? '';
    final viewerIpAddress = json['viewerIpAddress']?.toString();
    final requestedAt =
        DateTime.tryParse(json['requestedAt']?.toString() ?? '') ??
        DateTime.now();
    final expiresAt =
        DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? requestedAt;
    final status = ShareApprovalStatusWireName.fromWireName(
      json['status']?.toString(),
    );

    if (requestId.isEmpty || shareLinkId.isEmpty || viewerName.isEmpty) {
      throw const FormatException(
        'Incomplete pending approval response payload.',
      );
    }

    return PendingShareApprovalRequest(
      requestId: requestId,
      shareLinkId: shareLinkId,
      shareCode: shareCode,
      viewerName: viewerName,
      viewerIpAddress: viewerIpAddress,
      requestedAt: requestedAt,
      expiresAt: expiresAt,
      status: status,
    );
  }

  ShareApprovalDecisionResult _toApprovalDecision(Map<String, dynamic> json) {
    final requestId = json['requestId']?.toString() ?? '';
    final shareLinkId = json['shareLinkId']?.toString() ?? '';
    final status = ShareApprovalStatusWireName.fromWireName(
      json['status']?.toString(),
    );
    final decisionAt =
        DateTime.tryParse(json['decisionAt']?.toString() ?? '') ??
        DateTime.now();

    if (requestId.isEmpty || shareLinkId.isEmpty) {
      throw const FormatException('Incomplete approval decision payload.');
    }

    return ShareApprovalDecisionResult(
      requestId: requestId,
      shareLinkId: shareLinkId,
      status: status,
      decisionAt: decisionAt,
    );
  }

  SharingType _toSharingType(String? rawType) {
    if (rawType == null) {
      return SharingType.physician;
    }

    final normalized = rawType.trim().toLowerCase();
    if (normalized == 'emergency') {
      return SharingType.emergency;
    }

    return SharingType.physician;
  }

  Set<SharingScope> _parseScopes(Object? rawScopes) {
    if (rawScopes is! List) {
      return const {};
    }

    return rawScopes
        .map((value) => value?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .map(SharingScopeWireName.fromWireName)
        .toSet();
  }

  SharingSecuritySettings _parseSecuritySettings(Object? rawSecuritySettings) {
    if (rawSecuritySettings is! Map) {
      return const SharingSecuritySettings(accessDuration: Duration(hours: 1));
    }

    final json = Map<String, dynamic>.from(rawSecuritySettings);
    return SharingSecuritySettings(
      accessDuration: Duration(
        minutes:
            int.tryParse(json['accessDurationMinutes']?.toString() ?? '') ?? 60,
      ),
      passwordProtected: json['passwordProtected'] == true,
      requiresTwoFactorApproval: json['requiresTwoFactorApproval'] == true,
      allowDownload: json['allowDownload'] == true,
      notifyOnAccess: json['notifyOnAccess'] != false,
    );
  }

  ApiClient _requireApiClient() {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw UnsupportedError('Sharing API client is not configured.');
    }

    return apiClient;
  }
}
