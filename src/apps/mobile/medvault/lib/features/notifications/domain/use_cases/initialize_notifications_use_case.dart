import '../repositories/notifications_repository.dart';

class InitializeNotificationsUseCase {
  const InitializeNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<void> call() {
    return _repository.initialize();
  }
}
