import 'dart:convert';
import '../api_client.dart';
import '../../models/api_models.dart';
import 'auth_api.dart';

class NotificationPreferencesConfig {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool securityAlerts;
  final bool dataSharingNotifications;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? language;

  const NotificationPreferencesConfig({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.securityAlerts,
    required this.dataSharingNotifications,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.language,
  });

  factory NotificationPreferencesConfig.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesConfig(
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? true,
      securityAlerts: json['securityAlerts'] ?? true,
      dataSharingNotifications: json['dataSharingNotifications'] ?? true,
      quietHoursStart: json['quietHoursStart']?.toString(),
      quietHoursEnd: json['quietHoursEnd']?.toString(),
      language: json['language']?.toString(),
    );
  }
}

class SharingPreferencesConfig {
  final bool emergencySharingEnabled;
  final bool physicianSharingEnabled;
  final int maxSharingLinksPerUser;
  final int maxDocumentsToShare;
  final int minDocumentsToShareLimit;
  final int maxDocumentsToShareLimit;
  final int maxSharedDocumentBytes;

  const SharingPreferencesConfig({
    required this.emergencySharingEnabled,
    required this.physicianSharingEnabled,
    required this.maxSharingLinksPerUser,
    required this.maxDocumentsToShare,
    required this.minDocumentsToShareLimit,
    required this.maxDocumentsToShareLimit,
    required this.maxSharedDocumentBytes,
  });

  factory SharingPreferencesConfig.fromJson(Map<String, dynamic> json) {
    return SharingPreferencesConfig(
      emergencySharingEnabled: json['emergencySharingEnabled'] == true,
      physicianSharingEnabled: json['physicianSharingEnabled'] != false,
      maxSharingLinksPerUser:
          int.tryParse(json['maxSharingLinksPerUser']?.toString() ?? '') ?? 5,
      maxDocumentsToShare:
          int.tryParse(json['maxDocumentsToShare']?.toString() ?? '') ?? 10,
      minDocumentsToShareLimit:
          int.tryParse(json['minDocumentsToShareLimit']?.toString() ?? '') ?? 0,
      maxDocumentsToShareLimit:
          int.tryParse(json['maxDocumentsToShareLimit']?.toString() ?? '') ??
          10,
      maxSharedDocumentBytes:
          int.tryParse(json['maxSharedDocumentBytes']?.toString() ?? '') ??
          (10 * 1024 * 1024),
    );
  }
}

class DocumentFeatureSettingsConfig {
  final bool documentExtractDataEnabled;
  final int? maxFilesPerDocument;

  const DocumentFeatureSettingsConfig({
    required this.documentExtractDataEnabled,
    required this.maxFilesPerDocument,
  });

  factory DocumentFeatureSettingsConfig.fromJson(Map<String, dynamic> json) {
    final maxFiles = int.tryParse(
      json['maxFilesPerDocument']?.toString() ?? '',
    );

    return DocumentFeatureSettingsConfig(
      documentExtractDataEnabled: json['documentExtractDataEnabled'] != false,
      maxFilesPerDocument: maxFiles != null && maxFiles > 0 ? maxFiles : null,
    );
  }
}

class ConfigApi {
  final ApiClient _client;

  ConfigApi(this._client);

  Future<void> saveNotificationPreferences({
    bool pushEnabled = true,
    bool emailEnabled = true,
    bool securityAlerts = true,
    bool dataSharingNotifications = true,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? language,
    String? pushDeviceToken,
  }) async {
    final response = await _client.post(
      '/api/configuration/notifications',
      body: {
        'pushEnabled': pushEnabled,
        'pushDeviceToken': pushDeviceToken,
        'emailEnabled': emailEnabled,
        'securityAlerts': securityAlerts,
        'dataSharingNotifications': dataSharingNotifications,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'language': language,
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to save notification preferences',
      );
    }
  }

  Future<NotificationPreferencesConfig?> getNotificationPreferences() async {
    final response = await _client.get('/api/configuration/notifications');

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to load notification preferences',
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;

    if (data is! Map<String, dynamic>) {
      return null;
    }

    return NotificationPreferencesConfig.fromJson(data);
  }

  Future<void> enableCloudSync({
    required String provider,
    required bool autoBackupEnabled,
  }) async {
    final response = await _client.post(
      '/api/configuration/cloud-sync',
      body: {'provider': provider, 'autoBackupEnabled': autoBackupEnabled},
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to enable cloud sync');
    }
  }

  Future<SharingPreferencesConfig?> getSharingPreferences() async {
    final systemConfigurationResponse = await _client.get(
      '/api/system-configuration',
    );

    if (systemConfigurationResponse.statusCode == 200) {
      final json = jsonDecode(systemConfigurationResponse.body);
      final data = json['data'] ?? json;

      if (data is Map<String, dynamic>) {
        final sharing = data['sharing'];
        if (sharing is Map<String, dynamic>) {
          return SharingPreferencesConfig.fromJson(sharing);
        }
      }
    } else if (systemConfigurationResponse.statusCode != 404) {
      throw ApiException(
        systemConfigurationResponse.statusCode,
        'Failed to load system configuration',
      );
    }

    final response = await _client.get('/api/configuration/sharing');

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to load sharing preferences',
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;

    if (data is! Map<String, dynamic>) {
      return null;
    }

    return SharingPreferencesConfig.fromJson(data);
  }

  Future<DocumentFeatureSettingsConfig?> getDocumentFeatureSettings() async {
    final response = await _client.get('/api/system-configuration');

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to load system configuration',
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;

    if (data is! Map<String, dynamic>) {
      return null;
    }

    final documents = data['documents'];
    if (documents is Map<String, dynamic>) {
      return DocumentFeatureSettingsConfig.fromJson(documents);
    }

    return null;
  }

  Future<ConfigurationStatus> getStatus() async {
    final response = await _client.get('/api/configuration/status');

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to load configuration status',
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return ConfigurationStatus.fromJson(data);
  }
}
