import 'dart:developer';

import 'package:local_auth/local_auth.dart';

enum BiometricAvailabilityStatus {
  available,
  unsupported,
  notEnrolled,
  unavailable,
}

class BiometricAuth {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<BiometricAvailabilityStatus> checkAvailability() async {
    try {
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) {
        return BiometricAvailabilityStatus.unsupported;
      }

      final List<BiometricType> availableBiometrics = await _auth
          .getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return BiometricAvailabilityStatus.notEnrolled;
      }

      return BiometricAvailabilityStatus.available;
    } catch (_) {
      return BiometricAvailabilityStatus.unavailable;
    }
  }

  Future<bool> get isBiometricAvailable async =>
      (await checkAvailability()) == BiometricAvailabilityStatus.available;

  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    bool allowDeviceCredential = true,
    bool stickyAuth = false,
    bool useErrorDialogs = true,
  }) async {
    try {
      final BiometricAvailabilityStatus availability =
          await checkAvailability();
      if (availability != BiometricAvailabilityStatus.available) {
        return false;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
      );

      return didAuthenticate;
    } on Exception catch (e) {
      log('Biometric error: ${e.toString()}');
      return false;
    }
  }
}
