import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../models/notifications_models.dart';
import 'api/notifications_api.dart';
import 'auth_service.dart';
import 'database.dart' as db;

typedef NotificationsCurrentUserProvider = Future<AuthUser?> Function();
typedef NotificationsDeviceLanguageProvider = String Function();
typedef NotificationsPushTokenProvider = Future<String?> Function();

class NotificationsService extends ChangeNotifier {
  NotificationsService({
    required NotificationsCurrentUserProvider currentUserProvider,
    required bool demoMode,
    required NotificationsApiClient apiClient,
    db.AppDatabase? database,
    NotificationsDeviceLanguageProvider? deviceLanguageProvider,
    NotificationsPushTokenProvider? pushTokenProvider,
  }) : _currentUserProvider = currentUserProvider,
       _demoMode = demoMode,
       _apiClient = apiClient,
       _db = database ?? db.AppDatabase(),
       _deviceLanguageProvider =
           deviceLanguageProvider ?? _defaultDeviceLanguageTag,
       _pushTokenProvider = pushTokenProvider;

  final NotificationsCurrentUserProvider _currentUserProvider;
  final bool _demoMode;
  final NotificationsApiClient _apiClient;
  final db.AppDatabase _db;
  final NotificationsDeviceLanguageProvider _deviceLanguageProvider;
  final NotificationsPushTokenProvider? _pushTokenProvider;
  final Set<String> _demoSeededUsers = <String>{};
  final Duration _pollingInterval = const Duration(seconds: 30);

  Timer? _pollingTimer;
  String? _currentUserId;
  bool _isLoading = false;
  bool _isRefreshingFromRemote = false;
  bool _hasSyncError = false;
  final Set<String> _pendingReadNotificationIds = <String>{};
  bool _pendingMarkAllAsRead = false;
  NotificationSettings? _pendingSettingsSync;
  List<MedVaultNotification> _notifications = const [];
  NotificationSettings _settings = const NotificationSettings();

  bool get isLoading => _isLoading;

  bool get hasSyncError => _hasSyncError;

  List<MedVaultNotification> get notifications {
    final copy = List<MedVaultNotification>.from(_notifications);
    copy.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return copy;
  }

  NotificationSettings get settings => _settings;

  int get unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  static String _defaultDeviceLanguageTag() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode.trim();
    if (languageCode.isEmpty) {
      return 'en';
    }

    final countryCode = locale.countryCode?.trim();
    if (countryCode == null || countryCode.isEmpty) {
      return languageCode.toLowerCase();
    }

    return '${languageCode.toLowerCase()}-${countryCode.toUpperCase()}';
  }

  Future<void> initialize() async {
    _isLoading = true;
    _hasSyncError = false;
    notifyListeners();

    final userId = await _resolveCurrentUserId();
    if (userId == null) {
      _stopRealtimeSync();
      _currentUserId = null;
      _notifications = const [];
      _settings = const NotificationSettings();
      _isLoading = false;
      notifyListeners();
      return;
    }

    final shouldReload = _currentUserId != userId;
    _currentUserId = userId;

    if (shouldReload) {
      if (_demoMode) {
        _notifications = const [];
        _settings = const NotificationSettings();
      } else {
        await _loadFromDatabase(userId);
      }
    }

    if (_demoMode) {
      _stopRealtimeSync();
      await seedDemoNotificationsData(userId: userId);
    } else {
      await _syncSettingsFromRemote();
      await _ensureDeviceLanguagePreference();
      await _syncPushDeviceToken();
      await fetchNotifications(showLoading: false);
      _startRealtimeSync();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNotifications({bool showLoading = true}) async {
    final userId = _currentUserId;
    if (userId == null || _demoMode || _isRefreshingFromRemote) {
      return;
    }

    _isRefreshingFromRemote = true;
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final remote = await _apiClient.fetchNotifications();
      _notifications = remote;
      await _persistNotifications();
      _hasSyncError = false;
    } catch (error) {
      _hasSyncError = true;
      if (kDebugMode) {
        debugPrint('Notifications fetch failed: $error');
      }
    } finally {
      _isRefreshingFromRemote = false;
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0) {
      return;
    }

    final current = _notifications[index];
    if (current.isRead) {
      return;
    }

    final updated = current.copyWith(isRead: true);
    final next = List<MedVaultNotification>.from(_notifications);
    next[index] = updated;
    _notifications = next;

    await _persistNotifications();
    notifyListeners();

    if (!_demoMode) {
      try {
        await _apiClient.markNotificationAsRead(notificationId: notificationId);
        _pendingReadNotificationIds.remove(notificationId);
        _hasSyncError = false;
      } catch (error) {
        _pendingReadNotificationIds.add(notificationId);
        _hasSyncError = true;
        if (kDebugMode) {
          debugPrint('Mark notification as read failed: $error');
        }
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.every((item) => item.isRead)) {
      return;
    }

    _notifications = _notifications
        .map((item) => item.isRead ? item : item.copyWith(isRead: true))
        .toList(growable: false);

    await _persistNotifications();
    notifyListeners();

    if (!_demoMode) {
      try {
        await _apiClient.markAllNotificationsAsRead();
        _pendingMarkAllAsRead = false;
        _pendingReadNotificationIds.clear();
        _hasSyncError = false;
      } catch (error) {
        _pendingMarkAllAsRead = true;
        _hasSyncError = true;
        if (kDebugMode) {
          debugPrint('Mark all notifications as read failed: $error');
        }
        notifyListeners();
      }
    }
  }

  Future<void> updateSettings(NotificationSettings value) async {
    _settings = _normalizeSettings(value);
    await _persistSettings();
    notifyListeners();

    if (!_demoMode) {
      try {
        final token = await _resolvePushDeviceToken();
        await _apiClient.saveSettings(_settings, pushDeviceToken: token);
        await _cachePushDeviceToken(token);
        _pendingSettingsSync = null;
        _hasSyncError = false;
      } catch (error) {
        _pendingSettingsSync = _settings;
        _hasSyncError = true;
        if (kDebugMode) {
          debugPrint('Update notification settings failed: $error');
        }
        notifyListeners();
      }
    }
  }

  Future<void> _syncPushDeviceToken() async {
    if (_demoMode || _currentUserId == null || _pushTokenProvider == null) {
      return;
    }

    final token = await _resolvePushDeviceToken();
    if (token == null) {
      return;
    }

    final userId = _currentUserId!;
    final cachedToken = await _readSetting(_pushTokenStorageKey(userId));
    if (cachedToken == token) {
      return;
    }

    try {
      await _apiClient.saveSettings(_settings, pushDeviceToken: token);
      await _cachePushDeviceToken(token);
      _hasSyncError = false;
    } catch (error) {
      _pendingSettingsSync = _settings;
      _hasSyncError = true;
      if (kDebugMode) {
        debugPrint('Sync push device token failed: $error');
      }
    }
  }

  Future<void> syncPendingChanges() async {
    if (_demoMode || _currentUserId == null) {
      return;
    }

    try {
      if (_pendingSettingsSync != null) {
        final token = await _resolvePushDeviceToken();
        await _apiClient.saveSettings(
          _pendingSettingsSync!,
          pushDeviceToken: token,
        );
        await _cachePushDeviceToken(token);
        _pendingSettingsSync = null;
      }

      if (_pendingMarkAllAsRead) {
        await _apiClient.markAllNotificationsAsRead();
        _pendingMarkAllAsRead = false;
        _pendingReadNotificationIds.clear();
      } else if (_pendingReadNotificationIds.isNotEmpty) {
        final ids = List<String>.from(
          _pendingReadNotificationIds,
          growable: false,
        );
        for (final id in ids) {
          await _apiClient.markNotificationAsRead(notificationId: id);
          _pendingReadNotificationIds.remove(id);
        }
      }

      _hasSyncError = false;
      notifyListeners();
    } catch (error) {
      _hasSyncError = true;
      if (kDebugMode) {
        debugPrint('Sync pending notification changes failed: $error');
      }
      notifyListeners();
    }
  }

  Future<void> seedDemoNotificationsData({String? userId}) async {
    if (!_demoMode) {
      return;
    }

    final resolvedUserId = userId ?? await _resolveCurrentUserId();
    if (resolvedUserId == null) {
      return;
    }

    if (_demoSeededUsers.contains(resolvedUserId)) {
      return;
    }

    if (_notifications.isNotEmpty) {
      _demoSeededUsers.add(resolvedUserId);
      return;
    }

    final now = DateTime.now();
    final language = _normalizeLanguageTag(_deviceLanguageProvider()) ?? 'en';
    _notifications = [
      MedVaultNotification(
        id: _newId('notif'),
        type: NotificationType.emergencyQrAccessed,
        language: language,
        title: null,
        subtitle: null,
        description: null,
        actorName: null,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      MedVaultNotification(
        id: _newId('notif'),
        type: NotificationType.shareRequest,
        language: language,
        title: null,
        subtitle: null,
        description: null,
        actorName: 'Dr. Jane Smith',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: false,
      ),
      MedVaultNotification(
        id: _newId('notif'),
        type: NotificationType.profileUpdated,
        language: language,
        title: null,
        subtitle: null,
        description: null,
        actorName: null,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      MedVaultNotification(
        id: _newId('notif'),
        type: NotificationType.providerAccess,
        language: language,
        title: null,
        subtitle: null,
        description: null,
        actorName: 'Dr. Robert Brown',
        createdAt: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
      MedVaultNotification(
        id: _newId('notif'),
        type: NotificationType.medicationReminder,
        language: language,
        title: null,
        subtitle: null,
        description: null,
        actorName: null,
        createdAt: now.subtract(const Duration(hours: 9)),
        isRead: false,
      ),
      MedVaultNotification(
        id: _newId('notif'),
        type: NotificationType.appointmentAlert,
        language: language,
        title: null,
        subtitle: null,
        description: null,
        actorName: null,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];

    _settings = NotificationSettings(pushEnabled: true, language: language);

    _demoSeededUsers.add(resolvedUserId);
    notifyListeners();
  }

  Future<void> _syncSettingsFromRemote() async {
    try {
      final remote = await _apiClient.loadSettings();
      if (remote == null) {
        return;
      }

      _settings = _normalizeSettings(remote);
      await _persistSettings();
      _hasSyncError = false;
    } catch (error) {
      _hasSyncError = true;
      if (kDebugMode) {
        debugPrint('Load notification settings failed: $error');
      }
    }
  }

  Future<void> _ensureDeviceLanguagePreference() async {
    if (_demoMode || _currentUserId == null) {
      return;
    }

    final deviceLanguage = _normalizeLanguageTag(_deviceLanguageProvider());
    if (deviceLanguage == null || _settings.language == deviceLanguage) {
      return;
    }

    final updated = _settings.copyWith(language: deviceLanguage);
    _settings = updated;
    await _persistSettings();

    try {
      await _apiClient.saveSettings(updated);
      _hasSyncError = false;
    } catch (error) {
      _hasSyncError = true;
      if (kDebugMode) {
        debugPrint('Sync notification language preference failed: $error');
      }
    }
  }

  void _startRealtimeSync() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(fetchNotifications(showLoading: false));
    });
  }

  void _stopRealtimeSync() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _loadFromDatabase(String userId) async {
    final notificationsRaw = await _readSetting(
      _notificationsStorageKey(userId),
    );
    final settingsRaw = await _readSetting(_settingsStorageKey(userId));

    _notifications = MedVaultNotification.decodeList(notificationsRaw);
    _settings = _normalizeSettings(NotificationSettings.decode(settingsRaw));
  }

  Future<void> _persistNotifications() async {
    if (_demoMode) {
      return;
    }

    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    await _writeSetting(
      _notificationsStorageKey(userId),
      MedVaultNotification.encodeList(_notifications),
    );
  }

  Future<void> _persistSettings() async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    await _writeSetting(
      _settingsStorageKey(userId),
      NotificationSettings.encode(_settings),
    );
  }

  String _notificationsStorageKey(String userId) {
    return 'notifications_items_$userId';
  }

  String _settingsStorageKey(String userId) {
    return 'notifications_settings_$userId';
  }

  String _pushTokenStorageKey(String userId) {
    return 'notifications_push_token_$userId';
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

  Future<String?> _resolvePushDeviceToken() async {
    if (_pushTokenProvider == null) {
      return null;
    }

    try {
      final token = await _pushTokenProvider.call();
      if (token == null || token.trim().isEmpty) {
        return null;
      }

      return token.trim();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Resolve push token failed: $error');
      }
      return null;
    }
  }

  Future<void> _cachePushDeviceToken(String? token) async {
    final userId = _currentUserId;
    if (userId == null || token == null || token.isEmpty) {
      return;
    }

    await _writeSetting(_pushTokenStorageKey(userId), token);
  }

  String _newId(String prefix) {
    final random = Random.secure().nextInt(1 << 20).toRadixString(16);
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  NotificationSettings _normalizeSettings(NotificationSettings value) {
    final normalizedLanguage = _normalizeLanguageTag(value.language);
    return value.copyWith(language: normalizedLanguage, clearLanguage: false);
  }

  String? _normalizeLanguageTag(String? language) {
    if (language == null || language.trim().isEmpty) {
      return null;
    }

    final normalized = language.trim().replaceAll('_', '-');
    final segments = normalized.split('-');
    if (segments.length == 1) {
      return segments.first.toLowerCase();
    }

    return '${segments.first.toLowerCase()}-${segments[1].toUpperCase()}';
  }

  @override
  void dispose() {
    _stopRealtimeSync();
    super.dispose();
  }
}
