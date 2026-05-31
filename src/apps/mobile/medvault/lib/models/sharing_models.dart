import 'dart:convert';

enum SharingType { emergency, physician }

enum SharingScope {
  personalInformation,
  medicalInformation,
  bloodType,
  allergies,
  medications,
  diagnoses,
  vaccines,
  emergencyContact,
  labResults,
  medicalDocuments,
  medicalHistory,
}

extension SharingScopeWireName on SharingScope {
  String get wireName {
    switch (this) {
      case SharingScope.personalInformation:
        return 'personalInformation';
      case SharingScope.medicalInformation:
        return 'medicalInformation';
      case SharingScope.bloodType:
        return 'bloodType';
      case SharingScope.allergies:
        return 'allergies';
      case SharingScope.medications:
        return 'medications';
      case SharingScope.diagnoses:
        return 'diagnoses';
      case SharingScope.vaccines:
        return 'vaccines';
      case SharingScope.emergencyContact:
        return 'emergencyContact';
      case SharingScope.labResults:
        return 'labResults';
      case SharingScope.medicalDocuments:
        return 'medicalDocuments';
      case SharingScope.medicalHistory:
        return 'medicalHistory';
    }
  }

  static SharingScope fromWireName(String? rawScope) {
    final normalized = rawScope?.trim();
    if (normalized == null || normalized.isEmpty) {
      return SharingScope.medicalInformation;
    }

    switch (normalized) {
      case 'personalInformation':
        return SharingScope.personalInformation;
      case 'medicalInformation':
        return SharingScope.medicalInformation;
      case 'bloodType':
        return SharingScope.bloodType;
      case 'allergies':
        return SharingScope.allergies;
      case 'medications':
        return SharingScope.medications;
      case 'diagnoses':
      case 'chronicConditions':
        return SharingScope.diagnoses;
      case 'vaccines':
      case 'vaccinations':
        return SharingScope.vaccines;
      case 'emergencyContact':
        return SharingScope.emergencyContact;
      case 'labResults':
        return SharingScope.labResults;
      case 'medicalDocuments':
        return SharingScope.medicalDocuments;
      case 'medicalHistory':
        return SharingScope.medicalHistory;
      default:
        return SharingScope.medicalInformation;
    }
  }
}

enum SharingActivityType {
  linkCreated,
  linkAccessed,
  linkRevoked,
  permissionsUpdated,
  loginSuccess,
  loginFailed,
}

enum ShareApprovalStatus { pending, approved, denied, expired, unknown }

extension ShareApprovalStatusWireName on ShareApprovalStatus {
  static ShareApprovalStatus fromWireName(String? rawStatus) {
    switch (rawStatus?.trim().toLowerCase()) {
      case 'pending':
        return ShareApprovalStatus.pending;
      case 'approved':
        return ShareApprovalStatus.approved;
      case 'denied':
        return ShareApprovalStatus.denied;
      case 'expired':
        return ShareApprovalStatus.expired;
      default:
        return ShareApprovalStatus.unknown;
    }
  }
}

class PendingShareApprovalRequest {
  final String requestId;
  final String shareLinkId;
  final String shareCode;
  final String viewerName;
  final String? viewerIpAddress;
  final DateTime requestedAt;
  final DateTime expiresAt;
  final ShareApprovalStatus status;

  const PendingShareApprovalRequest({
    required this.requestId,
    required this.shareLinkId,
    required this.shareCode,
    required this.viewerName,
    required this.viewerIpAddress,
    required this.requestedAt,
    required this.expiresAt,
    required this.status,
  });
}

class ShareApprovalDecisionResult {
  final String requestId;
  final String shareLinkId;
  final ShareApprovalStatus status;
  final DateTime decisionAt;

  const ShareApprovalDecisionResult({
    required this.requestId,
    required this.shareLinkId,
    required this.status,
    required this.decisionAt,
  });
}

class SharingSecuritySettings {
  final Duration accessDuration;
  final bool passwordProtected;
  final bool requiresTwoFactorApproval;
  final bool allowDownload;
  final bool notifyOnAccess;
  final String? accessPassword;
  final String? verificationCode;

  const SharingSecuritySettings({
    required this.accessDuration,
    this.passwordProtected = false,
    this.requiresTwoFactorApproval = false,
    this.allowDownload = false,
    this.notifyOnAccess = true,
    this.accessPassword,
    this.verificationCode,
  });

  DateTime resolveExpiry(DateTime createdAt) {
    return createdAt.add(accessDuration);
  }

  SharingSecuritySettings copyWith({
    Duration? accessDuration,
    bool? passwordProtected,
    bool? requiresTwoFactorApproval,
    bool? allowDownload,
    bool? notifyOnAccess,
    String? accessPassword,
    String? verificationCode,
  }) {
    return SharingSecuritySettings(
      accessDuration: accessDuration ?? this.accessDuration,
      passwordProtected: passwordProtected ?? this.passwordProtected,
      requiresTwoFactorApproval:
          requiresTwoFactorApproval ?? this.requiresTwoFactorApproval,
      allowDownload: allowDownload ?? this.allowDownload,
      notifyOnAccess: notifyOnAccess ?? this.notifyOnAccess,
      accessPassword: accessPassword ?? this.accessPassword,
      verificationCode: verificationCode ?? this.verificationCode,
    );
  }

  SharingSecuritySettings withoutSecrets() {
    return SharingSecuritySettings(
      accessDuration: accessDuration,
      passwordProtected: passwordProtected,
      requiresTwoFactorApproval: requiresTwoFactorApproval,
      allowDownload: allowDownload,
      notifyOnAccess: notifyOnAccess,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessDurationMinutes': accessDuration.inMinutes,
      'passwordProtected': passwordProtected,
      'requiresTwoFactorApproval': requiresTwoFactorApproval,
      'allowDownload': allowDownload,
      'notifyOnAccess': notifyOnAccess,
    };
  }

  factory SharingSecuritySettings.fromJson(Map<String, dynamic> json) {
    return SharingSecuritySettings(
      accessDuration: Duration(minutes: json['accessDurationMinutes'] ?? 60),
      passwordProtected: json['passwordProtected'] ?? false,
      requiresTwoFactorApproval: json['requiresTwoFactorApproval'] ?? false,
      allowDownload: json['allowDownload'] ?? false,
      notifyOnAccess: json['notifyOnAccess'] ?? true,
    );
  }
}

class ShareSnapshotPayload {
  final SharePatientInfoPayload? patientInfo;
  final ShareMedicalSummaryPayload medicalSummary;
  final List<ShareMedicalHistoryEntryPayload> medicalHistory;
  final List<ShareDocumentPayload> documents;

  const ShareSnapshotPayload({
    required this.patientInfo,
    required this.medicalSummary,
    required this.medicalHistory,
    required this.documents,
  });

  bool get hasAnyContent {
    return (patientInfo?.hasAnyField ?? false) ||
        medicalSummary.hasAnyContent ||
        medicalHistory.isNotEmpty ||
        documents.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'patientInfo': patientInfo?.toJson(),
      'medicalSummary': medicalSummary.toJson(),
      'medicalHistory': medicalHistory
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'documents': documents
          .map((document) => document.toJson())
          .toList(growable: false),
    };
  }
}

class SharePatientInfoPayload {
  final String displayName;
  final String initials;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;

  const SharePatientInfoPayload({
    required this.displayName,
    required this.initials,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodType,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelationship,
  });

  bool get hasAnyField {
    return dateOfBirth != null ||
        gender != null ||
        bloodType != null ||
        emergencyContactName != null ||
        emergencyContactPhone != null ||
        emergencyContactRelationship != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'initials': initials,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'bloodType': bloodType,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelationship': emergencyContactRelationship,
    };
  }
}

class ShareMedicalSummaryPayload {
  final List<ShareAllergyPayload> allergies;
  final List<ShareMedicationPayload> activeMedications;
  final List<ShareConditionPayload> conditions;
  final List<ShareVaccinationPayload> vaccinations;

  const ShareMedicalSummaryPayload({
    required this.allergies,
    required this.activeMedications,
    required this.conditions,
    required this.vaccinations,
  });

  bool get hasAnyContent {
    return allergies.isNotEmpty ||
        activeMedications.isNotEmpty ||
        conditions.isNotEmpty ||
        vaccinations.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'allergies': allergies
          .map((item) => item.toJson())
          .toList(growable: false),
      'activeMedications': activeMedications
          .map((item) => item.toJson())
          .toList(growable: false),
      'conditions': conditions
          .map((item) => item.toJson())
          .toList(growable: false),
      'vaccinations': vaccinations
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}

class ShareAllergyPayload {
  final String id;
  final String allergenName;
  final String allergyType;
  final String severity;
  final String? reaction;
  final String? diagnosedDate;
  final bool isActive;

  const ShareAllergyPayload({
    required this.id,
    required this.allergenName,
    required this.allergyType,
    required this.severity,
    required this.reaction,
    required this.diagnosedDate,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'allergenName': allergenName,
      'allergyType': allergyType,
      'severity': severity,
      'reaction': reaction,
      'diagnosedDate': diagnosedDate,
      'isActive': isActive,
    };
  }
}

class ShareMedicationPayload {
  final String id;
  final String medicationName;
  final String? genericName;
  final String? dosage;
  final String? frequency;
  final String? route;
  final String? prescribedBy;
  final String? startDate;
  final String? endDate;
  final bool isActive;

  const ShareMedicationPayload({
    required this.id,
    required this.medicationName,
    required this.genericName,
    required this.dosage,
    required this.frequency,
    required this.route,
    required this.prescribedBy,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationName': medicationName,
      'genericName': genericName,
      'dosage': dosage,
      'frequency': frequency,
      'route': route,
      'prescribedBy': prescribedBy,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
    };
  }
}

class ShareConditionPayload {
  final String id;
  final String conditionName;
  final String? icdCode;
  final String? diagnosedDate;
  final String status;
  final String? treatmentPlan;

  const ShareConditionPayload({
    required this.id,
    required this.conditionName,
    required this.icdCode,
    required this.diagnosedDate,
    required this.status,
    required this.treatmentPlan,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conditionName': conditionName,
      'icdCode': icdCode,
      'diagnosedDate': diagnosedDate,
      'status': status,
      'treatmentPlan': treatmentPlan,
    };
  }
}

class ShareVaccinationPayload {
  final String id;
  final String vaccineName;
  final String? manufacturer;
  final String? lotNumber;
  final String administeredDate;
  final int doseNumber;
  final String? administeredBy;
  final String? nextDoseDate;

  const ShareVaccinationPayload({
    required this.id,
    required this.vaccineName,
    required this.manufacturer,
    required this.lotNumber,
    required this.administeredDate,
    required this.doseNumber,
    required this.administeredBy,
    required this.nextDoseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vaccineName': vaccineName,
      'manufacturer': manufacturer,
      'lotNumber': lotNumber,
      'administeredDate': administeredDate,
      'doseNumber': doseNumber,
      'administeredBy': administeredBy,
      'nextDoseDate': nextDoseDate,
    };
  }
}

class ShareMedicalHistoryEntryPayload {
  final String id;
  final String date;
  final String type;
  final String title;
  final String? description;
  final String? provider;
  final String? facility;
  final String? notes;
  final String? severity;

  const ShareMedicalHistoryEntryPayload({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.description,
    required this.provider,
    required this.facility,
    required this.notes,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'title': title,
      'description': description,
      'provider': provider,
      'facility': facility,
      'notes': notes,
      'severity': severity,
    };
  }
}

class ShareDocumentPayload {
  final String id;
  final String title;
  final String? category;
  final String? description;
  final String? fileName;
  final String? contentType;
  final int? fileSizeBytes;
  final String? contentBase64;
  final String? contentFileId;
  final String? downloadUrl;
  final String? uploadedAt;

  const ShareDocumentPayload({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.fileName,
    required this.contentType,
    this.fileSizeBytes,
    this.contentBase64,
    this.contentFileId,
    required this.downloadUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'fileName': fileName,
      'contentType': contentType,
      'fileSizeBytes': fileSizeBytes,
      'contentBase64': contentBase64,
      'contentFileId': contentFileId,
      'downloadUrl': downloadUrl,
      'uploadedAt': uploadedAt,
    };
  }

  factory ShareDocumentPayload.fromJson(Map<String, dynamic> json) {
    return ShareDocumentPayload(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'],
      description: json['description'],
      fileName: json['fileName'],
      contentType: json['contentType'],
      fileSizeBytes: json['fileSizeBytes'],
      contentBase64: json['contentBase64'],
      contentFileId: json['contentFileId'],
      downloadUrl: json['downloadUrl'],
      uploadedAt: json['uploadedAt'],
    );
  }
}

class SharingLinkGrant {
  final String id;
  final SharingType type;
  final String targetName;
  final String? targetEmail;
  final String? notes;
  final Set<SharingScope> scopes;
  final SharingSecuritySettings securitySettings;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final String shareCode;
  final String shareUrl;
  final String qrPayload;
  final int accessCount;
  final DateTime? lastAccessAt;

  const SharingLinkGrant({
    required this.id,
    required this.type,
    required this.targetName,
    required this.targetEmail,
    required this.notes,
    required this.scopes,
    required this.securitySettings,
    required this.createdAt,
    required this.expiresAt,
    required this.revokedAt,
    required this.shareCode,
    required this.shareUrl,
    required this.qrPayload,
    required this.accessCount,
    required this.lastAccessAt,
  });

  bool isActive([DateTime? now]) {
    final reference = now ?? DateTime.now();
    return revokedAt == null && !expiresAt.isBefore(reference);
  }

  bool isExpired([DateTime? now]) {
    final reference = now ?? DateTime.now();
    return expiresAt.isBefore(reference);
  }

  SharingLinkGrant copyWith({
    String? id,
    SharingType? type,
    String? targetName,
    String? targetEmail,
    String? notes,
    Set<SharingScope>? scopes,
    SharingSecuritySettings? securitySettings,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
    bool clearRevokedAt = false,
    String? shareCode,
    String? shareUrl,
    String? qrPayload,
    int? accessCount,
    DateTime? lastAccessAt,
    bool clearLastAccessAt = false,
  }) {
    return SharingLinkGrant(
      id: id ?? this.id,
      type: type ?? this.type,
      targetName: targetName ?? this.targetName,
      targetEmail: targetEmail ?? this.targetEmail,
      notes: notes ?? this.notes,
      scopes: scopes ?? this.scopes,
      securitySettings: securitySettings ?? this.securitySettings,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: clearRevokedAt ? null : (revokedAt ?? this.revokedAt),
      shareCode: shareCode ?? this.shareCode,
      shareUrl: shareUrl ?? this.shareUrl,
      qrPayload: qrPayload ?? this.qrPayload,
      accessCount: accessCount ?? this.accessCount,
      lastAccessAt: clearLastAccessAt
          ? null
          : (lastAccessAt ?? this.lastAccessAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'targetName': targetName,
      'targetEmail': targetEmail,
      'notes': notes,
      'scopes': scopes.map((scope) => scope.wireName).toList(growable: false),
      'securitySettings': securitySettings.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
      'shareCode': shareCode,
      'shareUrl': shareUrl,
      'qrPayload': qrPayload,
      'accessCount': accessCount,
      'lastAccessAt': lastAccessAt?.toIso8601String(),
    };
  }

  factory SharingLinkGrant.fromJson(Map<String, dynamic> json) {
    return SharingLinkGrant(
      id: json['id']?.toString() ?? '',
      type: SharingType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SharingType.emergency,
      ),
      targetName: json['targetName']?.toString() ?? '',
      targetEmail: json['targetEmail']?.toString(),
      notes: json['notes']?.toString(),
      scopes: (json['scopes'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .map(SharingScopeWireName.fromWireName)
          .toSet(),
      securitySettings: SharingSecuritySettings.fromJson(
        Map<String, dynamic>.from(
          json['securitySettings'] as Map<String, dynamic>? ?? const {},
        ),
      ),
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        json['expiresAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      revokedAt: json['revokedAt'] != null
          ? DateTime.tryParse(json['revokedAt'].toString())
          : null,
      shareCode: json['shareCode']?.toString() ?? '',
      shareUrl: json['shareUrl']?.toString() ?? '',
      qrPayload: json['qrPayload']?.toString() ?? '',
      accessCount: json['accessCount'] is int
          ? json['accessCount'] as int
          : int.tryParse(json['accessCount']?.toString() ?? '') ?? 0,
      lastAccessAt: json['lastAccessAt'] != null
          ? DateTime.tryParse(json['lastAccessAt'].toString())
          : null,
    );
  }

  static String encodeList(List<SharingLinkGrant> values) {
    return jsonEncode(values.map((value) => value.toJson()).toList());
  }

  static List<SharingLinkGrant> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (value) =>
              SharingLinkGrant.fromJson(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }
}

class SharingActivityEntry {
  final String id;
  final String linkId;
  final SharingActivityType type;
  final String title;
  final String details;
  final String actorName;
  final String? location;
  final String? ipAddress;
  final DateTime occurredAt;
  final bool highRisk;

  const SharingActivityEntry({
    required this.id,
    required this.linkId,
    required this.type,
    required this.title,
    required this.details,
    required this.actorName,
    required this.location,
    required this.ipAddress,
    required this.occurredAt,
    required this.highRisk,
  });

  SharingActivityEntry copyWith({
    String? id,
    String? linkId,
    SharingActivityType? type,
    String? title,
    String? details,
    String? actorName,
    String? location,
    bool clearLocation = false,
    String? ipAddress,
    bool clearIpAddress = false,
    DateTime? occurredAt,
    bool? highRisk,
  }) {
    return SharingActivityEntry(
      id: id ?? this.id,
      linkId: linkId ?? this.linkId,
      type: type ?? this.type,
      title: title ?? this.title,
      details: details ?? this.details,
      actorName: actorName ?? this.actorName,
      location: clearLocation ? null : (location ?? this.location),
      ipAddress: clearIpAddress ? null : (ipAddress ?? this.ipAddress),
      occurredAt: occurredAt ?? this.occurredAt,
      highRisk: highRisk ?? this.highRisk,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'linkId': linkId,
      'type': type.name,
      'title': title,
      'details': details,
      'actorName': actorName,
      'location': location,
      'ipAddress': ipAddress,
      'occurredAt': occurredAt.toIso8601String(),
      'highRisk': highRisk,
    };
  }

  factory SharingActivityEntry.fromJson(Map<String, dynamic> json) {
    return SharingActivityEntry(
      id: json['id']?.toString() ?? '',
      linkId: json['linkId']?.toString() ?? '',
      type: SharingActivityType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SharingActivityType.linkAccessed,
      ),
      title: json['title']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      actorName: json['actorName']?.toString() ?? '',
      location: json['location']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      occurredAt: DateTime.parse(
        json['occurredAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      highRisk: json['highRisk'] ?? false,
    );
  }

  static String encodeList(List<SharingActivityEntry> values) {
    return jsonEncode(values.map((value) => value.toJson()).toList());
  }

  static List<SharingActivityEntry> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (value) =>
              SharingActivityEntry.fromJson(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }
}
