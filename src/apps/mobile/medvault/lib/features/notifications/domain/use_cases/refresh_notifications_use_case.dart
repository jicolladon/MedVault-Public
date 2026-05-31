import '../repositories/notifications_repository.dart';

class RefreshNotificationsUseCase {
  const RefreshNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<void> call({bool showLoading = true}) {
    return _repository.refresh(showLoading: showLoading);
  }
}
