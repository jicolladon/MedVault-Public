import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/services/sharing_email_launcher.dart';

void main() {
  group('SharingMessageRequest', () {
    test('stores subject and body values', () {
      const request = SharingMessageRequest(
        subject: 'Secure access request',
        body: 'Line 1\nLine 2 with spaces',
      );

      expect(request.subject, equals('Secure access request'));
      expect(request.body, equals('Line 1\nLine 2 with spaces'));
    });
  });

  group('SharePlusSharingMessageLauncher', () {
    test('returns true when share sheet is available', () async {
      String? capturedText;
      String? capturedSubject;
      final launcher = SharePlusSharingMessageLauncher(
        shareFn: (text, {subject}) async {
          capturedText = text;
          capturedSubject = subject;
        },
      );

      const request = SharingMessageRequest(subject: 'Subject', body: 'Body');

      final result = await launcher.openShareSheet(request);

      expect(result, isTrue);
      expect(capturedSubject, equals('Subject'));
      expect(capturedText, equals('Body'));
    });

    test('returns false when share throws', () async {
      final launcher = SharePlusSharingMessageLauncher(
        shareFn: (_, {subject}) async {
          throw Exception('share failed');
        },
      );

      const request = SharingMessageRequest(subject: 'Subject', body: 'Body');

      final result = await launcher.openShareSheet(request);

      expect(result, isFalse);
    });
  });
}
