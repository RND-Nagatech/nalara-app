enum NotificationPermissionStatus {
  unavailable,
  notDetermined,
  denied,
  deniedPermanently,
  authorized,
  provisional;

  bool get granted => this == authorized || this == provisional;
}

abstract class NotificationPermissionRepository {
  /// Android can report denied before the first runtime permission request.
  bool get canRequestWhenDenied;
  Future<NotificationPermissionStatus> status();
  Future<NotificationPermissionStatus> request();
  Future<bool> wasPrompted();
  Future<void> rememberPrompt();
  Future<void> synchronizeRegistration();
}
