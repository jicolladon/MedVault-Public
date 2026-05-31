abstract interface class SharingLinkRepository {
  Future<void> revokeLink(String linkId);
}
