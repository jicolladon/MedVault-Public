import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/env/app_environment.dart';
import '../../services/api/sharing_api.dart';
import '../../services/auth_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/database.dart';
import '../../services/documents_service.dart';
import '../../services/medical_data_service.dart';
import '../../services/api/documents_api.dart';
import '../../services/api/notifications_api.dart';
import '../../services/notifications_service.dart';
import '../../services/profile_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/sharing_service.dart';
import '../../services/settings_service.dart';
import '../../services/theme_controller.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late AppEnvironment environment;
  late ConnectivityService connectivityService;
  late AppDatabase database;
  late SettingsService settingsService;
  late ThemeController themeController;
  late AuthService authService;
  late MedicalDataService medicalDataService;
  late DocumentsService documentsService;
  late NotificationsService notificationsService;
  late PushNotificationService pushNotificationService;
  late ProfileService profileService;
  late SharingService sharingService;
  bool _lastKnownOnlineStatus = true;

  Future<void> init(AppEnvironment env) async {
    environment = env;

    connectivityService = ConnectivityService();
    await connectivityService.initialize();
    _lastKnownOnlineStatus = connectivityService.isOnline;

    database = AppDatabase();

    settingsService = SettingsService(database: database);

    authService = AuthService(
      settingsService: settingsService,
      googleClientId: const String.fromEnvironment(
        'GOOGLE_CLIENT_ID',
        defaultValue: '',
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://localhost:7200',
      ),
      demoMode: env == AppEnvironment.demo,
      isOnlineProvider: () => connectivityService.isOnline,
      allowInsecureCertificates: env == AppEnvironment.development,
    );

    medicalDataService = MedicalDataService(
      currentUserProvider: authService.getCurrentUser,
      database: database,
    );

    documentsService = DocumentsService(
      currentUserProvider: authService.getCurrentUser,
      demoMode: env == AppEnvironment.demo,
      apiClient: PendingDocumentsApiClient(apiClient: authService.apiClient),
      configApi: authService.configApi,
      database: database,
      connectivityService: connectivityService,
    );

    pushNotificationService = PushNotificationService();
    if (env != AppEnvironment.demo) {
      await pushNotificationService.initialize();
    }

    notificationsService = NotificationsService(
      currentUserProvider: authService.getCurrentUser,
      demoMode: env == AppEnvironment.demo,
      apiClient: PendingNotificationsApiClient(
        apiClient: authService.apiClient,
        configApi: authService.configApi,
      ),
      database: database,
      pushTokenProvider: pushNotificationService.getDeviceToken,
    );

    profileService = ProfileService(
      authService: authService,
      database: database,
    );

    sharingService = SharingService(
      currentUserProvider: authService.getCurrentUser,
      demoMode: env == AppEnvironment.demo,
      apiClient: PendingSharingApiClient(apiClient: authService.apiClient),
      configApi: authService.configApi,
      documentsService: documentsService,
      medicalDataService: medicalDataService,
      profileService: profileService,
      database: database,
    );

    authService.attachMedicalDataCallbacks(
      clearMedicalData: medicalDataService.clear,
      refreshMedicalData: medicalDataService.reload,
      saveOnboardingMedicalInfo: medicalDataService.updateBloodType,
    );

    themeController = ThemeController(settingsService: settingsService);

    await themeController.load();
    connectivityService.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    final isOnline = connectivityService.isOnline;
    if (isOnline && !_lastKnownOnlineStatus) {
      unawaited(_syncAfterReconnect());
    }

    _lastKnownOnlineStatus = isOnline;
  }

  Future<void> _syncAfterReconnect() async {
    try {
      await documentsService.initialize();
    } catch (error, stackTrace) {
      debugPrint(
        'Reconnect sync: failed to refresh documents settings: '
        '$error\n$stackTrace',
      );
    }

    try {
      await notificationsService.syncPendingChanges();
      await notificationsService.fetchNotifications(showLoading: false);
    } catch (error, stackTrace) {
      debugPrint(
        'Reconnect sync: failed to refresh notifications: '
        '$error\n$stackTrace',
      );
    }

    try {
      await sharingService.initialize();
    } catch (error, stackTrace) {
      debugPrint(
        'Reconnect sync: failed to refresh sharing data: '
        '$error\n$stackTrace',
      );
    }

    try {
      await profileService.syncPendingChanges();
    } catch (error, stackTrace) {
      debugPrint(
        'Reconnect sync: failed to flush profile pending changes: '
        '$error\n$stackTrace',
      );
    }
  }
}
