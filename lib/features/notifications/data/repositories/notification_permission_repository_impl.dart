import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../shared/notifications/push_notification_service.dart';
import '../../domain/repositories/notification_permission_repository.dart';

const notificationPermissionPromptKey = 'notification-permission-prompt-v1';

class NotificationPermissionRepositoryImpl
    implements NotificationPermissionRepository {
  final PushNotificationService push;
  final FlutterSecureStorage storage;
  const NotificationPermissionRepositoryImpl(this.push, this.storage);

  @override
  bool get canRequestWhenDenied =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  NotificationPermissionStatus _map(
    AuthorizationStatus? value,
  ) => switch (value) {
    AuthorizationStatus.authorized => NotificationPermissionStatus.authorized,
    AuthorizationStatus.provisional => NotificationPermissionStatus.provisional,
    AuthorizationStatus.denied => NotificationPermissionStatus.denied,
    AuthorizationStatus.deniedPermanently =>
      NotificationPermissionStatus.deniedPermanently,
    AuthorizationStatus.notDetermined =>
      NotificationPermissionStatus.notDetermined,
    null => NotificationPermissionStatus.unavailable,
  };

  @override
  Future<NotificationPermissionStatus> status() async =>
      _map(await push.authorizationStatus());
  @override
  Future<NotificationPermissionStatus> request() async =>
      _map(await push.requestUserPermission());
  @override
  Future<bool> wasPrompted() async =>
      await storage.read(key: notificationPermissionPromptKey) == 'true';
  @override
  Future<void> rememberPrompt() =>
      storage.write(key: notificationPermissionPromptKey, value: 'true');
  @override
  Future<void> synchronizeRegistration() =>
      push.refreshPermissionRegistration();
}
