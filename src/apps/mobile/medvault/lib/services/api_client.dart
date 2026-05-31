import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'connectivity_service.dart';

typedef OnlineStatusProvider = bool Function();

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _storage;
  final http.Client _httpClient;
  final Duration defaultTimeout;
  final OnlineStatusProvider? _isOnlineProvider;

  static const _accessTokenKey = 'jwt_access_token';
  static const _refreshTokenKey = 'jwt_refresh_token';

  ApiClient({
    required this.baseUrl,
    FlutterSecureStorage? storage,
    http.Client? httpClient,
    OnlineStatusProvider? isOnlineProvider,
    bool allowInsecureCertificates = false,
    this.defaultTimeout = const Duration(seconds: 30),
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _isOnlineProvider = isOnlineProvider,
       _httpClient =
           httpClient ??
           _buildHttpClient(
             allowInsecureCertificates: allowInsecureCertificates && kDebugMode,
           );

  static http.Client _buildHttpClient({
    required bool allowInsecureCertificates,
  }) {
    if (!allowInsecureCertificates) {
      return http.Client();
    }

    final ioHttpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    return IOClient(ioHttpClient);
  }

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> get hasTokens async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String>> _authHeaders({
    bool includeContentType = true,
  }) async {
    final token = await accessToken;
    return {
      if (includeContentType) HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<http.Response> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
    Duration? timeout,
  }) async {
    _ensureOnline();
    Future<http.Response> sendOnce() async {
      final headers = await _authHeaders(includeContentType: false);
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers.addAll(headers)
        ..fields.addAll(fields)
        ..files.addAll(files);

      final streamed = await _httpClient
          .send(request)
          .timeout(timeout ?? defaultTimeout);
      return http.Response.fromStream(streamed);
    }

    var response = await sendOnce();
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        response = await sendOnce();
      }
    }

    return response;
  }

  Future<http.Response> get(String path) async {
    _ensureOnline();
    final headers = await _authHeaders();
    var response = await _httpClient
        .get(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(defaultTimeout);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        response = await _httpClient
            .get(Uri.parse('$baseUrl$path'), headers: newHeaders)
            .timeout(defaultTimeout);
      }
    }
    return response;
  }

  Future<http.Response> post(String path, {Object? body}) async {
    _ensureOnline();
    final headers = await _authHeaders();
    var response = await _httpClient
        .post(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(defaultTimeout);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        response = await _httpClient
            .post(
              Uri.parse('$baseUrl$path'),
              headers: newHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(defaultTimeout);
      }
    }
    return response;
  }

  Future<http.Response> put(String path, {Object? body}) async {
    _ensureOnline();
    final headers = await _authHeaders();
    var response = await _httpClient
        .put(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(defaultTimeout);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        response = await _httpClient
            .put(
              Uri.parse('$baseUrl$path'),
              headers: newHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(defaultTimeout);
      }
    }
    return response;
  }

  Future<http.Response> delete(String path) async {
    _ensureOnline();
    final headers = await _authHeaders();
    var response = await _httpClient
        .delete(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(defaultTimeout);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        response = await _httpClient
            .delete(Uri.parse('$baseUrl$path'), headers: newHeaders)
            .timeout(defaultTimeout);
      }
    }
    return response;
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await refreshToken;
    if (refresh == null) return false;

    try {
      _ensureOnline();
      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl/auth/refresh-token'),
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['data'] ?? data;
        await saveTokens(result['accessToken'], result['refreshToken']);
        return true;
      }
    } on OfflineModeException {
      return false;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {}

    await clearTokens();
    return false;
  }

  void _ensureOnline() {
    final isOnline = _isOnlineProvider?.call();
    if (isOnline == null || isOnline) {
      return;
    }

    throw const OfflineModeException();
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final List<String> errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors = const [],
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      message: json['message'],
      errors: (json['errors'] as List?)?.cast<String>() ?? [],
    );
  }
}
