import 'dart:convert';

import '../api_client.dart';
import '../../models/api_models.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<GoogleLoginResponse> loginWithGoogle(String googleIdToken) async {
    final response = await _client.post(
      '/auth/google',
      body: {'idToken': googleIdToken},
    );

    if (response.statusCode != 200) {
      final error = _extractError(response.body);
      throw ApiException(response.statusCode, error);
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return GoogleLoginResponse.fromJson(data);
  }

  Future<PkceAuthorizationCodeResponse> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required bool termsAccepted,
    required bool privacyPolicyAccepted,
    required String codeChallenge,
    String codeChallengeMethod = 'S256',
  }) async {
    final response = await _client.post(
      '/auth/email/register',
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'termsAccepted': termsAccepted,
        'privacyPolicyAccepted': privacyPolicyAccepted,
        'codeChallenge': codeChallenge,
        'codeChallengeMethod': codeChallengeMethod,
      },
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final error = _extractError(response.body);
      throw ApiException(response.statusCode, error);
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return PkceAuthorizationCodeResponse.fromJson(data);
  }

  Future<PkceAuthorizationCodeResponse> loginWithEmail({
    required String email,
    required String password,
    required String codeChallenge,
    String codeChallengeMethod = 'S256',
  }) async {
    final response = await _client.post(
      '/auth/email/login',
      body: {
        'email': email,
        'password': password,
        'codeChallenge': codeChallenge,
        'codeChallengeMethod': codeChallengeMethod,
      },
    );

    if (response.statusCode != 200) {
      final error = _extractError(response.body);
      throw ApiException(response.statusCode, error);
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return PkceAuthorizationCodeResponse.fromJson(data);
  }

  Future<PkceTokenResponse> exchangePkceCode({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    final response = await _client.post(
      '/auth/pkce/token',
      body: {
        'authorizationCode': authorizationCode,
        'codeVerifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      final error = _extractError(response.body);
      throw ApiException(response.statusCode, error);
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return PkceTokenResponse.fromJson(data);
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await _client.post(
      '/auth/google/register',
      body: request.toJson(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = _extractError(response.body);
      throw ApiException(response.statusCode, error);
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return RegisterResponse.fromJson(data);
  }

  Future<void> refreshToken() async {
    final refresh = await _client.refreshToken;
    if (refresh == null) throw ApiException(401, 'No refresh token available');

    final response = await _client.post(
      '/auth/refresh-token',
      body: {'refreshToken': refresh},
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Token refresh failed');
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    await _client.saveTokens(data['accessToken'], data['refreshToken']);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } finally {
      await _client.clearTokens();
    }
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? json['errors']?.first ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
