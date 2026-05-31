import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class OfflineModeException implements Exception {
  const OfflineModeException([
    this.message =
        'No internet connection. This feature requires online access.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class ConnectivityService extends ChangeNotifier {
  ConnectivityService({
    Connectivity? connectivity,
    String probeHost = 'one.one.one.one',
    Duration probeTimeout = const Duration(seconds: 3),
  }) : _connectivity = connectivity ?? Connectivity(),
       _probeHost = probeHost,
       _probeTimeout = probeTimeout;

  final Connectivity _connectivity;
  final String _probeHost;
  final Duration _probeTimeout;

  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _initialized = false;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  bool get isOffline => !_isOnline;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (_isRunningInTestEnvironment()) {
      _initialized = true;
      _updateConnectivityState(true);
      return;
    }

    _initialized = true;
    await _refreshConnectivityState();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((_) {
      unawaited(_refreshConnectivityState());
    });
  }

  bool _isRunningInTestEnvironment() {
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  Future<void> _refreshConnectivityState() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final hasNetwork = _hasNetworkTransport(connectivityResult);
    final reachable = hasNetwork ? await _hasInternetReachability() : false;
    _updateConnectivityState(reachable);
  }

  bool _hasNetworkTransport(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }

    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<bool> _hasInternetReachability() async {
    try {
      final lookup = await InternetAddress.lookup(
        _probeHost,
      ).timeout(_probeTimeout);
      return lookup.any((entry) => entry.rawAddress.isNotEmpty);
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  void _updateConnectivityState(bool nextState) {
    if (_isOnline == nextState) {
      return;
    }

    _isOnline = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }
}
