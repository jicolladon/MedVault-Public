import 'package:share_plus/share_plus.dart';

typedef SharingSheetOpener =
    Future<void> Function(String text, {String? subject});

class SharingMessageRequest {
  const SharingMessageRequest({required this.subject, required this.body});

  final String subject;
  final String body;
}

abstract interface class SharingMessageLauncher {
  Future<bool> openShareSheet(SharingMessageRequest request);
}

class SharePlusSharingMessageLauncher implements SharingMessageLauncher {
  const SharePlusSharingMessageLauncher({
    SharingSheetOpener shareFn = _defaultShare,
  }) : _share = shareFn;

  final SharingSheetOpener _share;

  @override
  Future<bool> openShareSheet(SharingMessageRequest request) async {
    try {
      await _share(request.body, subject: request.subject);
      return true;
    } on Exception {
      return false;
    }
  }

  static Future<void> _defaultShare(String text, {String? subject}) {
    return Share.share(text, subject: subject);
  }
}
