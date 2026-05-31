import '../repositories/sharing_link_repository.dart';

class RevokeSharingLinkUseCase {
  const RevokeSharingLinkUseCase(this._repository);

  final SharingLinkRepository _repository;

  Future<void> call(String linkId) {
    return _repository.revokeLink(linkId);
  }
}
