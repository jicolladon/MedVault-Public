import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging;

  FirebaseMessaging? _messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  String? _cachedToken;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await _initializeFirebaseApp();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Push notifications disabled: Firebase init failed: $error');
      }
      return;
    }

    try {
      final messaging = _resolveMessaging();

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _cachedToken = await messaging.getToken();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
        _cachedToken = token;
      });
      _initialized = true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Push notifications disabled: token setup failed: $error');
      }
    }
  }

  Future<String?> getDeviceToken() async {
    if (!_initialized) {
      await initialize();
    }

    if (!_initialized) {
      return null;
    }

    if (_cachedToken != null && _cachedToken!.trim().isNotEmpty) {
      return _cachedToken;
    }

    try {
      _cachedToken = await _resolveMessaging().getToken();
      return _cachedToken;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to resolve FCM token: $error');
      }
      return null;
    }
  }

  FirebaseMessaging _resolveMessaging() {
    return _messaging ??= FirebaseMessaging.instance;
  }

  Future<void> _initializeFirebaseApp() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    final options = _buildFirebaseOptionsFromEnvironment();
    if (options == null) {
      throw StateError(
        'Missing Firebase configuration values. Define FIREBASE_API_KEY, '
        'FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID and FIREBASE_PROJECT_ID.',
      );
    }

    await Firebase.initializeApp(options: options);
  }

  FirebaseOptions? _buildFirebaseOptionsFromEnvironment() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
    const appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    );
    const projectId = String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: '',
    );
    const storageBucket = String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    );
    const iosBundleId = String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.application.medvault',
    );

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId,
    );
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
