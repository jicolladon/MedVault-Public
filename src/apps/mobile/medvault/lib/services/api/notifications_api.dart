import 'dart:convert';

import '../../models/notifications_models.dart';
import '../api_client.dart';
import 'auth_api.dart';
import 'config_api.dart';

abstract class NotificationsApiClient {
  Future<List<MedVaultNotification>> fetchNotifications();

  Future<void> markNotificationAsRead({required String notificationId});

  Future<void> markAllNotificationsAsRead();

  Future<NotificationSettings?> loadSettings();

  Future<void> saveSettings(
    NotificationSettings settings, {
    String? pushDeviceToken,
  });
}

class PendingNotificationsApiClient implements NotificationsApiClient {
  const PendingNotificationsApiClient({
    required ApiClient apiClient,
    required ConfigApi configApi,
  }) : _apiClient = apiClient,
       _configApi = configApi;

  final ApiClient _apiClient;
  final ConfigApi _configApi;

  @override
  Future<List<MedVaultNotification>> fetchNotifications() async {
    final response = await _apiClient.get('/api/notifications');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to load notifications');
    }

    final payload = _unwrapEnvelope(response.body);
    if (payload is! List) {
      return const [];
    }

    return payload
        .whereType<Map>()
        .map((value) => MedVaultNotification.fromJson(_normalizeJson(value)))
        .toList(growable: false);
  }

  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {
    final response = await _apiClient.post(
      '/api/notifications/$notificationId/read',
    );
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to mark notification as read',
      );
    }
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    final response = await _apiClient.post('/api/notifications/read-all');
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to mark all notifications as read',
      );
    }
  }

  @override
  Future<NotificationSettings?> loadSettings() async {
    try {
      final remote = await _configApi.getNotificationPreferences();
      if (remote == null) {
        return null;
      }

      return NotificationSettings(
        pushEnabled: remote.pushEnabled,
        emailEnabled: remote.emailEnabled,
        securityAlerts: remote.securityAlerts,
        dataSharingNotifications: remote.dataSharingNotifications,
        quietHoursStart: remote.quietHoursStart,
        quietHoursEnd: remote.quietHoursEnd,
        language: remote.language,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSettings(
    NotificationSettings settings, {
    String? pushDeviceToken,
  }) async {
    await _configApi.saveNotificationPreferences(
      pushEnabled: settings.pushEnabled,
      emailEnabled: settings.emailEnabled,
      securityAlerts: settings.securityAlerts,
      dataSharingNotifications: settings.dataSharingNotifications,
      quietHoursStart: settings.quietHoursStart,
      quietHoursEnd: settings.quietHoursEnd,
      language: settings.language,
      pushDeviceToken: pushDeviceToken,
    );
  }

  Object? _unwrapEnvelope(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) {
      return decoded;
    }

    return decoded['data'] ?? decoded;
  }

  Map<String, dynamic> _normalizeJson(Map value) {
    final json = Map<String, dynamic>.from(value);
    final type = json['type']?.toString();
    if (type != null && type.isNotEmpty) {
      json['type'] = type[0].toLowerCase() + type.substring(1);
    }
    return json;
  }
}
