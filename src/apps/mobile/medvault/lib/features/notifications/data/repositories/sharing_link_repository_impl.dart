import '../../domain/repositories/sharing_link_repository.dart';
import '../../../../services/sharing_service.dart';

class SharingLinkRepositoryImpl implements SharingLinkRepository {
  const SharingLinkRepositoryImpl({required SharingService sharingService})
    : _sharingService = sharingService;

  final SharingService _sharingService;

  @override
  Future<void> revokeLink(String linkId) {
    return _sharingService.revokeLink(linkId: linkId);
  }
}
