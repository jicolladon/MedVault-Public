import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PkcePair {
  final String codeVerifier;
  final String codeChallenge;

  const PkcePair({required this.codeVerifier, required this.codeChallenge});
}

class PkceHelper {
  static const _allowed =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  static PkcePair generate() {
    final verifier = _generateCodeVerifier();
    final challenge = _toCodeChallenge(verifier);
    return PkcePair(codeVerifier: verifier, codeChallenge: challenge);
  }

  static String _generateCodeVerifier({int length = 64}) {
    final random = Random.secure();
    final buffer = StringBuffer();

    for (var i = 0; i < length; i++) {
      buffer.write(_allowed[random.nextInt(_allowed.length)]);
    }

    return buffer.toString();
  }

  static String _toCodeChallenge(String verifier) {
    final bytes = ascii.encode(verifier);
    final digest = sha256.convert(bytes).bytes;
    return base64Url.encode(digest).replaceAll('=', '');
  }
}
