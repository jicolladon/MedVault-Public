import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:medvault/models/medical_models.dart';

import '../models/api_models.dart';
import 'api_client.dart';
import 'connectivity_service.dart';
import 'api/auth_api.dart';
import 'api/config_api.dart';
import 'api/medical_api.dart';
import 'api/profile_api.dart';
import 'settings_service.dart';
import '../utils/pkce_helper.dart';

enum PostAuthDestination { home, onboarding }

class PostAuthDecision {
  final PostAuthDestination destination;

  const PostAuthDecision._({required this.destination});

  const PostAuthDecision.home() : this._(destination: PostAuthDestination.home);

  const PostAuthDecision.onboarding()
    : this._(destination: PostAuthDestination.onboarding);
}

class AuthUser {
  final String email;
  final String? displayName;
  final String? photoUrl;

  const AuthUser({required this.email, this.displayName, this.photoUrl});
}

class LoginResult {
  final bool success;
  final bool isNewUser;
  final String? googleIdToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? error;

  const LoginResult({
    this.success = false,
    this.isNewUser = false,
    this.googleIdToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.error,
  });
}

class AuthService {
  static const _keyAccessToken = 'google_access_token';
  static const _keyIdToken = 'google_id_token';
  static const _keySignedInAt = 'signed_in_at';

  final bool demoMode;
  final SettingsService _settingsService;

  static const _googleSignInConfigError =
      'Google Sign-In configuration issue (ApiException 10). '
      'Verify Android package name, SHA-1/SHA-256 fingerprints, and OAuth client IDs.';

  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  bool _demoSessionActive = false;
  bool _demoRegistered = false;

  AuthUser? _demoUser;
  Future<void> Function()? _clearMedicalData;
  Future<void> Function()? _refreshMedicalData;
  Future<void> Function(String bloodType)? _saveOnboardingMedicalInfo;

  late final ApiClient apiClient;
  late final AuthApi authApi;
  late final ProfileApi profileApi;
  late final ConfigApi configApi;
  late final MedicalApi medicalApi;

  AuthService({
    required SettingsService settingsService,
    GoogleSignIn? googleSignIn,
    FlutterSecureStorage? secureStorage,
    String? googleClientId,
    String? apiBaseUrl,
    this.demoMode = false,
    OnlineStatusProvider? isOnlineProvider,
    bool allowInsecureCertificates = false,
  }) : _settingsService = settingsService,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: const ['email', 'profile'],
             serverClientId: _normalizeGoogleClientId(googleClientId),
           ),
       _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    apiClient = ApiClient(
      baseUrl:
          apiBaseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://localhost:7200',
          ),
      storage: _secureStorage,
      isOnlineProvider: isOnlineProvider,
      allowInsecureCertificates: allowInsecureCertificates,
    );
    authApi = AuthApi(apiClient);
    profileApi = ProfileApi(apiClient);
    configApi = ConfigApi(apiClient);
    medicalApi = MedicalApi(apiClient);
  }

  void attachMedicalDataCallbacks({
    Future<void> Function()? clearMedicalData,
    Future<void> Function()? refreshMedicalData,
    Future<void> Function(String bloodType)? saveOnboardingMedicalInfo,
  }) {
    _clearMedicalData = clearMedicalData;
    _refreshMedicalData = refreshMedicalData;
    _saveOnboardingMedicalInfo = saveOnboardingMedicalInfo;
  }

  static String? _normalizeGoogleClientId(String? googleClientId) {
    if (googleClientId == null) {
      return null;
    }

    final normalized = googleClientId.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static bool _isGoogleSignInDeveloperError(PlatformException exception) {
    if (exception.code != 'sign_in_failed') {
      return false;
    }

    final message = exception.message ?? '';
    final details = exception.details?.toString() ?? '';
    return message.contains('ApiException: 10') ||
        details.contains('ApiException: 10');
  }

  Future<bool> hasValidSession() async {
    if (demoMode) {
      return _demoSessionActive;
    }

    try {
      if (await apiClient.hasTokens) {
        try {
          await profileApi.getProfile();
          return true;
        } on OfflineModeException {
          return true;
        }
      }

      final refresh = await apiClient.refreshToken;
      if (refresh != null && refresh.isNotEmpty) {
        try {
          await authApi.refreshToken();
          if (await apiClient.hasTokens) {
            await profileApi.getProfile();
            return true;
          }
        } on OfflineModeException {
          return true;
        } catch (_) {}
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('hasValidSession error: $e');
      return false;
    }
  }

  Future<LoginResult> signInWithGoogleAndBackend() async {
    if (demoMode) {
      _demoSessionActive = true;
      _demoUser ??= const AuthUser(
        email: 'demo.user@medvault.local',
        displayName: 'Demo User',
      );
      await _refreshMedicalData?.call();
      return LoginResult(
        success: true,
        isNewUser: !(await _settingsService.isDemoModeInit()),
        email: _demoUser!.email,
        displayName: _demoUser!.displayName,
        photoUrl: _demoUser!.photoUrl,
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const LoginResult(error: 'Sign-in cancelled');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return const LoginResult(error: 'No ID token received from Google');
      }

      await _cacheTokens();

      try {
        final response = await authApi.loginWithGoogle(idToken);
        await apiClient.saveTokens(response.accessToken, response.refreshToken);
        await _refreshMedicalData?.call();

        return LoginResult(
          success: true,
          isNewUser: response.isNewUser,
          googleIdToken: idToken,
          email: response.email,
          displayName: response.fullName,
          photoUrl: response.profilePictureUrl,
        );
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 401) {
          return LoginResult(
            success: false,
            isNewUser: true,
            googleIdToken: idToken,
            email: account.email,
            displayName: account.displayName,
            photoUrl: account.photoUrl,
          );
        }
        return LoginResult(error: e.message);
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'signInWithGoogleAndBackend PlatformException '
          '[code=${e.code}, message=${e.message}, details=${e.details}]',
        );
      }

      if (_isGoogleSignInDeveloperError(e)) {
        return const LoginResult(error: _googleSignInConfigError);
      }

      return const LoginResult(error: 'Sign-in failed. Please try again.');
    } catch (e) {
      if (kDebugMode) debugPrint('signInWithGoogleAndBackend error: $e');
      return LoginResult(error: 'Sign-in failed. Please try again.');
    }
  }

  Future<LoginResult> registerWithGoogleAndBackend({
    required RegisterRequest request,
  }) async {
    if (demoMode) {
      _demoRegistered = true;
      _demoSessionActive = true;

      _demoUser = AuthUser(
        email: 'demo.user@medvault.local',
        displayName: _composeDisplayName(request.firstName, request.lastName),
      );
      await _settingsService.setDemoModeInit(true);
      return LoginResult(
        success: true,
        isNewUser: true,
        email: _demoUser!.email,
        displayName: _demoUser!.displayName,
      );
    }

    try {
      await authApi.register(request);
      final loginResponse = await authApi.loginWithGoogle(
        request.googleIdToken,
      );
      await apiClient.saveTokens(
        loginResponse.accessToken,
        loginResponse.refreshToken,
      );

      final resolvedDisplayName =
          loginResponse.fullName?.trim().isNotEmpty == true
          ? loginResponse.fullName
          : _composeDisplayName(request.firstName, request.lastName);

      return LoginResult(
        success: true,
        isNewUser: true,
        googleIdToken: request.googleIdToken,
        email: loginResponse.email,
        displayName: resolvedDisplayName,
        photoUrl: loginResponse.profilePictureUrl,
      );
    } on ApiException catch (e) {
      return LoginResult(error: e.message);
    } catch (e) {
      if (kDebugMode) debugPrint('registerWithGoogleAndBackend error: $e');
      return const LoginResult(error: 'Registration failed. Please try again.');
    }
  }

  Future<LoginResult> signInWithEmailAndBackend({
    required String email,
    required String password,
  }) async {
    if (demoMode) {
      if (!_demoRegistered) {
        return const LoginResult(
          error: 'No demo account yet. Register first in demo mode.',
        );
      }

      _demoSessionActive = true;
      _demoUser = AuthUser(email: email, displayName: _demoUser?.displayName);
      await _refreshMedicalData?.call();
      return LoginResult(
        success: true,
        isNewUser: false,
        email: email,
        displayName: _demoUser?.displayName,
      );
    }

    try {
      final pkce = PkceHelper.generate();

      final authCode = await authApi.loginWithEmail(
        email: email,
        password: password,
        codeChallenge: pkce.codeChallenge,
      );

      final tokens = await authApi.exchangePkceCode(
        authorizationCode: authCode.authorizationCode,
        codeVerifier: pkce.codeVerifier,
      );

      await apiClient.saveTokens(tokens.accessToken, tokens.refreshToken);
      await _refreshMedicalData?.call();

      return LoginResult(
        success: true,
        isNewUser: authCode.isNewUser,
        email: tokens.email ?? email,
        displayName: [
          tokens.firstName,
          tokens.lastName,
        ].where((p) => p != null && p.trim().isNotEmpty).join(' ').trim(),
        photoUrl: tokens.profilePictureUrl,
      );
    } on ApiException catch (e) {
      return LoginResult(error: e.message);
    } catch (e) {
      if (kDebugMode) debugPrint('signInWithEmailAndBackend error: $e');
      return const LoginResult(
        error: 'Email sign-in failed. Please try again.',
      );
    }
  }

  Future<LoginResult> registerWithEmailAndBackend({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required bool termsAccepted,
    required bool privacyPolicyAccepted,
  }) async {
    if (demoMode) {
      _demoRegistered = true;
      _demoSessionActive = true;

      _demoUser = AuthUser(
        email: email,
        displayName: _composeDisplayName(firstName, lastName),
      );
      await _refreshMedicalData?.call();
      return LoginResult(
        success: true,
        isNewUser: true,
        email: email,
        displayName: _demoUser?.displayName,
      );
    }

    try {
      final pkce = PkceHelper.generate();

      final authCode = await authApi.registerWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        termsAccepted: termsAccepted,
        privacyPolicyAccepted: privacyPolicyAccepted,
        codeChallenge: pkce.codeChallenge,
      );

      final tokens = await authApi.exchangePkceCode(
        authorizationCode: authCode.authorizationCode,
        codeVerifier: pkce.codeVerifier,
      );

      await apiClient.saveTokens(tokens.accessToken, tokens.refreshToken);
      await _refreshMedicalData?.call();

      return LoginResult(
        success: true,
        isNewUser: true,
        email: tokens.email ?? email,
        displayName: [
          tokens.firstName,
          tokens.lastName,
        ].where((p) => p != null && p.trim().isNotEmpty).join(' ').trim(),
        photoUrl: tokens.profilePictureUrl,
      );
    } on ApiException catch (e) {
      return LoginResult(error: e.message);
    } catch (e) {
      if (kDebugMode) debugPrint('registerWithEmailAndBackend error: $e');
      return const LoginResult(
        error: 'Email registration failed. Please try again.',
      );
    }
  }

  Future<void> resetData() async {
    await _clearMedicalData?.call();
    await _settingsService.resetSettings();
  }

  Future<bool> signInWithGoogle() async {
    if (demoMode) {
      _demoSessionActive = true;
      _demoRegistered = true;
      _demoUser ??= const AuthUser(
        email: 'demo.user@medvault.local',
        displayName: 'Demo User',
      );
      await _refreshMedicalData?.call();
      return true;
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      await _cacheTokens();
      await _secureStorage.write(
        key: _keySignedInAt,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      await _refreshMedicalData?.call();
      return true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Google sign-in PlatformException '
          '[code=${e.code}, message=${e.message}, details=${e.details}]',
        );
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    if (demoMode) {
      _demoSessionActive = false;
      _demoRegistered = false;

      _demoUser = null;
      return;
    }

    try {
      if (await apiClient.hasTokens) {
        try {
          await authApi.logout();
        } catch (_) {}
      }
      await _googleSignIn.disconnect();
    } finally {
      await apiClient.clearTokens();
      await _secureStorage.deleteAll();
      await _clearMedicalData?.call();
    }
  }

  Future<void> refreshSession() async {
    if (demoMode) {
      return;
    }
    await authApi.refreshToken();
  }

  Future<PostAuthDecision> determinePostAuthDestination() async {
    try {
      final isFirstTime = await _settingsService.getAceFirstTime(
        defaultValue: true,
      );
      if (isFirstTime) {
        return const PostAuthDecision.onboarding();
      }
      return const PostAuthDecision.home();
    } catch (e) {
      if (kDebugMode) debugPrint('determinePostAuthDestination error: $e');
      return const PostAuthDecision.home();
    }
  }

  Future<void> saveBiometricConfig({
    required String biometricType,
    required bool isEnabled,
  }) async {
    if (demoMode) {
      return;
    }
    await _settingsService.setUseBiometric(isEnabled);
  }

  Future<void> saveNotificationPreferences({required bool pushEnabled}) async {
    if (demoMode) {
      return;
    }
    await configApi.saveNotificationPreferences(pushEnabled: pushEnabled);
  }

  Future<void> enableCloudSync({
    required String provider,
    required bool autoBackupEnabled,
  }) async {
    if (demoMode) {
      return;
    }
    await configApi.enableCloudSync(
      provider: provider,
      autoBackupEnabled: autoBackupEnabled,
    );
  }

  Future<void> saveOnboardingMedicalInfo({String? bloodType}) async {
    await _saveOnboardingMedicalInfo?.call(
      bloodType ?? BloodGroup.unknown.value,
    );
  }

  Future<void> markOnboardingComplete() async {
    await _settingsService.setAceFirstTime(false);
  }

  Future<UserProfile> getProfile() async {
    if (demoMode) {
      final user = _demoUser;
      final fullNameParts = (user?.displayName ?? 'Demo User').split(' ');
      final firstName = fullNameParts.isNotEmpty ? fullNameParts.first : 'Demo';
      final lastName = fullNameParts.length > 1
          ? fullNameParts.sublist(1).join(' ')
          : 'User';
      return UserProfile(
        userId: 'demo-user-001',
        email: user?.email ?? 'demo.user@medvault.local',
        displayName: user?.displayName ?? 'Demo User',
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: '1985-06-15',
        phoneNumber: '+1 (555) 123-4567',
        addressLine1: '123 Main St',
        city: 'New York',
        state: 'NY',
        postalCode: '10001',
        country: 'USA',
        emergencyContactName: 'Jane Doe',
        emergencyContactPhone: '+1 (555) 987-6543',
        emergencyContactRelationship: 'spouse',
        profileCompleteness: 90,
        privacyLevel: 'Standard',
      );
    }
    return profileApi.getProfile();
  }

  Future<List<ProfileEmergencyContact>> getEmergencyContacts() async {
    if (demoMode) {
      return const [];
    }

    return profileApi.getEmergencyContacts();
  }

  Future<List<ProfileEmergencyContact>> replaceEmergencyContacts({
    required List<ProfileEmergencyContact> contacts,
  }) async {
    if (demoMode) {
      return contacts;
    }

    return profileApi.replaceEmergencyContacts(contacts: contacts);
  }

  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    if (demoMode) {
      final current = await getProfile();
      final updated = UserProfile(
        userId: current.userId,
        email: current.email,
        displayName: request.displayName ?? current.displayName,
        firstName: request.firstName ?? current.firstName,
        lastName: request.lastName ?? current.lastName,
        dateOfBirth: request.dateOfBirth ?? current.dateOfBirth,
        gender: request.gender ?? current.gender,
        profilePictureUrl:
            request.profilePictureUrl ?? current.profilePictureUrl,
        phoneNumber: request.phoneNumber,
        addressLine1: request.addressLine1 ?? current.addressLine1,
        addressLine2: request.addressLine2 ?? current.addressLine2,
        city: request.city ?? current.city,
        state: request.state ?? current.state,
        postalCode: request.postalCode ?? current.postalCode,
        country: request.country ?? current.country,
        bloodType: request.bloodType ?? current.bloodType,
        profileCompleteness: current.profileCompleteness,
        privacyLevel: current.privacyLevel,
      );

      final name = _composeDisplayName(updated.firstName, updated.lastName);
      _demoUser = AuthUser(
        email: updated.email,
        displayName: name.isEmpty ? null : name,
        photoUrl: updated.profilePictureUrl,
      );
      return updated;
    }
    return profileApi.updateProfile(request);
  }

  Future<AuthUser?> getCurrentUser() async {
    if (demoMode) {
      if (!_demoSessionActive) {
        return null;
      }
      return _demoUser ??
          const AuthUser(
            email: 'demo.user@medvault.local',
            displayName: 'Demo User',
          );
    }

    try {
      final account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account != null) {
        return AuthUser(
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        );
      }

      final profile = await profileApi.getProfile();
      return AuthUser(
        email: profile.email,
        displayName: _composeDisplayName(profile.firstName, profile.lastName),
        photoUrl: profile.profilePictureUrl,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('getCurrentUser error: $e');
      return null;
    }
  }

  Future<String?> getIdToken() async => _secureStorage.read(key: _keyIdToken);
  Future<String?> getAccessToken() async =>
      _secureStorage.read(key: _keyAccessToken);

  Future<GoogleSignInAccount?> getUserInfo() async {
    if (demoMode) {
      return null;
    }

    try {
      return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    } catch (e) {
      if (kDebugMode) debugPrint('getUserInfo error: $e');
      return null;
    }
  }

  Future<void> _cacheTokens() async {
    try {
      final user = _googleSignIn.currentUser;
      if (user == null) return;

      final auth = await user.authentication;

      if (auth.idToken != null) {
        await _secureStorage.write(key: _keyIdToken, value: auth.idToken);
      }
      if (auth.accessToken != null) {
        await _secureStorage.write(
          key: _keyAccessToken,
          value: auth.accessToken,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Cache tokens error: $e');
    }
  }

  String _composeDisplayName(String? firstName, String? lastName) {
    return [firstName, lastName]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' ')
        .trim();
  }
}
