library;

import 'gender.dart';


class GoogleLoginResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;
  final String email;
  final String? fullName;
  final String? profilePictureUrl;
  final bool isNewUser;

  GoogleLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    required this.email,
    this.fullName,
    this.profilePictureUrl,
    required this.isNewUser,
  });

  factory GoogleLoginResponse.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    return GoogleLoginResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresAt: DateTime.parse(
        json['accessTokenExpiresAt']?.toString() ??
            json['expiresAt']?.toString() ??
            DateTime.now().toIso8601String(),
      ),
      userId: json['userId']?.toString() ?? user['id']?.toString() ?? '',
      email: json['email']?.toString() ?? user['email']?.toString() ?? '',
      fullName:
          json['fullName']?.toString() ??
          [user['firstName'], user['lastName']]
              .where((value) => value != null && value.toString().isNotEmpty)
              .join(' ')
              .trim(),
      profilePictureUrl:
          json['profilePictureUrl']?.toString() ??
          user['profilePictureUrl']?.toString(),
      isNewUser: json['isNewUser'] ?? false,
    );
  }
}

class RegisterRequest {
  final String googleIdToken;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final Gender? gender;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final bool termsAccepted;
  final bool privacyPolicyAccepted;

  RegisterRequest({
    required this.googleIdToken,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.termsAccepted = false,
    this.privacyPolicyAccepted = false,
  });

  Map<String, dynamic> toJson() => {
    'googleIdToken': googleIdToken,
    'firstName': firstName,
    'lastName': lastName,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    if (gender != null) 'gender': gender!.apiValue,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (zipCode != null) 'zipCode': zipCode,
    if (country != null) 'country': country,
    'termsAccepted': termsAccepted,
    'privacyPolicyAccepted': privacyPolicyAccepted,
  };
}

class UserSummaryDto {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;
  final int profileCompleteness;

  UserSummaryDto({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
    required this.profileCompleteness,
  });

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) {
    return UserSummaryDto(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      profilePictureUrl: json['profilePictureUrl']?.toString(),
      profileCompleteness: (json['profileCompleteness'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'profilePictureUrl': profilePictureUrl,
    'profileCompleteness': profileCompleteness,
  };
}

class RegisterResponse {
  final UserSummaryDto user;

  RegisterResponse({required this.user});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final userJson = (json['user'] as Map<String, dynamic>?) ?? const {};
    return RegisterResponse(user: UserSummaryDto.fromJson(userJson));
  }
}

class PkceAuthorizationCodeResponse {
  final String authorizationCode;
  final int expiresInSeconds;
  final bool isNewUser;

  PkceAuthorizationCodeResponse({
    required this.authorizationCode,
    required this.expiresInSeconds,
    required this.isNewUser,
  });

  factory PkceAuthorizationCodeResponse.fromJson(Map<String, dynamic> json) {
    return PkceAuthorizationCodeResponse(
      authorizationCode: json['authorizationCode'] ?? '',
      expiresInSeconds: json['expiresInSeconds'] ?? 300,
      isNewUser: json['isNewUser'] ?? false,
    );
  }
}

class PkceTokenResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final String? userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;

  PkceTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    this.userId,
    this.email,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
  });

  factory PkceTokenResponse.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    return PkceTokenResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      accessTokenExpiresAt: DateTime.parse(
        json['accessTokenExpiresAt'] ?? DateTime.now().toIso8601String(),
      ),
      userId: user['id']?.toString(),
      email: user['email']?.toString(),
      firstName: user['firstName']?.toString(),
      lastName: user['lastName']?.toString(),
      profilePictureUrl: user['profilePictureUrl']?.toString(),
    );
  }
}


class UserProfile {
  final String userId;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final Gender? gender;
  final String? profilePictureUrl;
  final String? phoneNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? bloodType;
  final int profileCompleteness;
  final String privacyLevel;

  UserProfile({
    required this.userId,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.profilePictureUrl,
    this.phoneNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.bloodType,
    this.profileCompleteness = 0,
    this.privacyLevel = 'Standard',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString();
    final lastName = json['lastName']?.toString();
    final computedDisplayName = [firstName, lastName]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' ')
        .trim();

    return UserProfile(
      userId: json['userId'],
      email: json['email'],
      displayName:
          json['displayName']?.toString() ??
          (computedDisplayName.isEmpty ? null : computedDisplayName),
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: json['dateOfBirth'],
      gender: genderFromApiValue(json['gender']?.toString()),
      profilePictureUrl: json['profilePictureUrl'],
      phoneNumber: json['phoneNumber'],
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      emergencyContactName: json['emergencyContactName'],
      emergencyContactPhone: json['emergencyContactPhone'],
      emergencyContactRelationship: json['emergencyContactRelationship'],
      bloodType: json['bloodType'],
      profileCompleteness: json['profileCompleteness'] ?? 0,
      privacyLevel: json['privacyLevel'] ?? 'Standard',
    );
  }
}

class UpdateProfileRequest {
  final String? displayName;
  final String? email;
  final String? profilePictureUrl;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final Gender? gender;
  final String? phoneNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? bloodType;

  UpdateProfileRequest({
    this.displayName,
    this.email,
    this.profilePictureUrl,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.bloodType,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    _addIfNotBlank(map, 'displayName', displayName);
    _addIfNotBlank(map, 'email', email);
    _addIfNotBlank(map, 'profilePictureUrl', profilePictureUrl);
    _addIfNotBlank(map, 'firstName', firstName);
    _addIfNotBlank(map, 'lastName', lastName);
    _addIfNotBlank(map, 'dateOfBirth', dateOfBirth);
    if (gender != null) map['gender'] = gender!.apiValue;
    _addIfNotBlank(map, 'phoneNumber', phoneNumber);
    _addIfNotBlank(map, 'addressLine1', addressLine1);
    _addIfNotBlank(map, 'addressLine2', addressLine2);
    _addIfNotBlank(map, 'city', city);
    _addIfNotBlank(map, 'state', state);
    _addIfNotBlank(map, 'postalCode', postalCode);
    _addIfNotBlank(map, 'country', country);
    _addIfNotBlank(map, 'emergencyContactName', emergencyContactName);
    _addIfNotBlank(map, 'emergencyContactPhone', emergencyContactPhone);
    _addIfNotBlank(
      map,
      'emergencyContactRelationship',
      emergencyContactRelationship,
    );
    _addIfNotBlank(map, 'bloodType', bloodType);
    return map;
  }

  static void _addIfNotBlank(
    Map<String, dynamic> map,
    String key,
    String? value,
  ) {
    if (value == null) {
      return;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }

    map[key] = normalized;
  }
}

class ProfileEmergencyContact {
  final String contactId;
  final String name;
  final String relationship;
  final String phone;
  final String? email;
  final bool isPrimary;

  ProfileEmergencyContact({
    required this.contactId,
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
    required this.isPrimary,
  });

  factory ProfileEmergencyContact.fromJson(Map<String, dynamic> json) {
    return ProfileEmergencyContact(
      contactId: json['contactId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? 'other',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final normalizedContactId = contactId.trim();
    final normalizedName = name.trim();
    final normalizedRelationship = relationship.trim();
    final normalizedPhone = phone.trim();
    final normalizedEmail = email?.trim();

    return {
      if (normalizedContactId.isNotEmpty) 'contactId': normalizedContactId,
      if (normalizedName.isNotEmpty) 'name': normalizedName,
      if (normalizedRelationship.isNotEmpty)
        'relationship': normalizedRelationship,
      if (normalizedPhone.isNotEmpty) 'phone': normalizedPhone,
      if (normalizedEmail != null && normalizedEmail.isNotEmpty)
        'email': normalizedEmail,
      'isPrimary': isPrimary,
    };
  }
}


class ConfigurationStatus {
  final bool biometricConfigured;
  final bool notificationsConfigured;
  final bool cloudSyncConfigured;
  final bool medicalInfoProvided;
  final int completedSteps;
  final int totalSteps;
  final bool allComplete;

  ConfigurationStatus({
    required this.biometricConfigured,
    required this.notificationsConfigured,
    required this.cloudSyncConfigured,
    required this.medicalInfoProvided,
    required this.completedSteps,
    required this.totalSteps,
    required this.allComplete,
  });

  factory ConfigurationStatus.fromJson(Map<String, dynamic> json) {
    return ConfigurationStatus(
      biometricConfigured: json['biometricConfigured'] ?? false,
      notificationsConfigured: json['notificationsConfigured'] ?? false,
      cloudSyncConfigured: json['cloudSyncConfigured'] ?? false,
      medicalInfoProvided: json['medicalInfoProvided'] ?? false,
      completedSteps: json['completedSteps'] ?? 0,
      totalSteps: json['totalSteps'] ?? 4,
      allComplete: json['allComplete'] ?? false,
    );
  }
}


class MedicalSummary {
  final String? bloodType;
  final List<AllergyDto> allergies;
  final List<MedicationDto> medications;
  final List<DiagnosisDto> diagnoses;
  final List<VaccinationDto> vaccinations;

  MedicalSummary({
    this.bloodType,
    this.allergies = const [],
    this.medications = const [],
    this.diagnoses = const [],
    this.vaccinations = const [],
  });

  List<MedicationDto> get activeMedications => medications;

  List<DiagnosisDto> get conditions => diagnoses;

  factory MedicalSummary.fromJson(Map<String, dynamic> json) {
    return MedicalSummary(
      bloodType: json['bloodType'],
      allergies:
          (json['allergies'] as List?)
              ?.map((e) => AllergyDto.fromJson(e))
              .toList() ??
          [],
      medications:
          ((json['medications'] ?? json['activeMedications']) as List?)
              ?.map((e) => MedicationDto.fromJson(e))
              .toList() ??
          [],
      diagnoses:
          ((json['diagnoses'] ?? json['conditions']) as List?)
              ?.map((e) => DiagnosisDto.fromJson(e))
              .toList() ??
          [],
      vaccinations:
          (json['vaccinations'] as List?)
              ?.map((e) => VaccinationDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AllergyDto {
  final String id;
  final String substance;
  final String reaction;
  final String severity;
  final String status;
  final String? notes;
  final String? documentAttachment;

  AllergyDto({
    required this.id,
    required this.substance,
    required this.reaction,
    required this.severity,
    required this.status,
    this.notes,
    this.documentAttachment,
  });

  factory AllergyDto.fromJson(Map<String, dynamic> json) {
    return AllergyDto(
      id: json['id'],
      substance: json['substance'] ?? json['allergenName'] ?? json['name'],
      reaction: json['reaction'] ?? json['allergyType'] ?? json['description'],
      severity: json['severity'] ?? 'moderate',
      status:
          json['status'] ?? (json['isActive'] == false ? 'resolved' : 'active'),
      notes: json['notes'],
      documentAttachment: json['documentAttachment'] ?? json['documentUrls'],
    );
  }
}

class MedicationDto {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String startDate;
  final String? endDate;
  final String status;
  final String? documentAttachment;
  final String? notes;

  MedicationDto({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.status,
    this.documentAttachment,
    this.notes,
  });

  factory MedicationDto.fromJson(Map<String, dynamic> json) {
    return MedicationDto(
      id: json['id'],
      name: json['name'] ?? json['medicationName'],
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? 'Once daily',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      status:
          json['status'] ??
          (json['isActive'] == false ? 'completed' : 'active'),
      documentAttachment: json['documentAttachment'] ?? json['documentUrls'],
      notes: json['notes'],
    );
  }
}

class DiagnosisDto {
  final String id;
  final String name;
  final String date;
  final String? duration;
  final String status;
  final String? notes;
  final String? documentAttachment;

  DiagnosisDto({
    required this.id,
    required this.name,
    required this.date,
    this.duration,
    required this.status,
    this.notes,
    this.documentAttachment,
  });

  factory DiagnosisDto.fromJson(Map<String, dynamic> json) {
    return DiagnosisDto(
      id: json['id'],
      name: json['name'] ?? json['conditionName'],
      date: json['date'] ?? json['diagnosedDate'],
      duration: json['duration'],
      status: json['status'] ?? 'active',
      notes: json['notes'] ?? json['description'],
      documentAttachment: json['documentAttachment'] ?? json['documentUrls'],
    );
  }
}

typedef ConditionDto = DiagnosisDto;

class VaccinationDto {
  final String id;
  final String vaccineName;
  final List<String> dates;
  final String? documentAttachment;

  VaccinationDto({
    required this.id,
    required this.vaccineName,
    required this.dates,
    this.documentAttachment,
  });

  factory VaccinationDto.fromJson(Map<String, dynamic> json) {
    return VaccinationDto(
      id: json['id'],
      vaccineName: json['vaccineName'] ?? json['name'],
      dates:
          (json['dates'] as List?)
              ?.map((date) => date.toString())
              .toList(growable: false) ??
          <String>[
            json['dateReceived']?.toString() ??
                json['administeredDate']?.toString() ??
                '',
          ],
      documentAttachment: json['documentAttachment'] ?? json['documentUrls'],
    );
  }
}
