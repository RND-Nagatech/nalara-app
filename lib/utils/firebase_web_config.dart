import 'package:firebase_core/firebase_core.dart';

/// Public Firebase Web app settings, never Firebase Admin/service-account keys.
class FirebaseWebConfig {
  final String apiKey,
      appId,
      messagingSenderId,
      projectId,
      authDomain,
      storageBucket,
      vapidKey,
      measurementId;
  const FirebaseWebConfig({
    this.apiKey = const String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIzaSyCIXGBwByUApP3MMMZK8A9DhRLlTxGqiYU',
    ),
    this.appId = const String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: '1:1009544957636:web:e9c52d4971683e880f4391',
    ),
    this.messagingSenderId = const String.fromEnvironment(
      'FIREBASE_WEB_MESSAGING_SENDER_ID',
      defaultValue: '1009544957636',
    ),
    this.projectId = const String.fromEnvironment(
      'FIREBASE_WEB_PROJECT_ID',
      defaultValue: 'nalara-749db',
    ),
    this.authDomain = const String.fromEnvironment(
      'FIREBASE_WEB_AUTH_DOMAIN',
      defaultValue: 'nalara-749db.firebaseapp.com',
    ),
    this.storageBucket = const String.fromEnvironment(
      'FIREBASE_WEB_STORAGE_BUCKET',
      defaultValue: 'nalara-749db.firebasestorage.app',
    ),
    this.vapidKey = const String.fromEnvironment(
      'FIREBASE_WEB_VAPID_KEY',
      defaultValue:
          'BDLMfDrHg9gjd21mKhvmOQXn6NZi-o3D5hs7KXZV19UtGBe3VeIS4gWahUfPmKE_3-VcpNzYA8-IWSN76_3bbH0',
    ),
    this.measurementId = const String.fromEnvironment(
      'FIREBASE_WEB_MEASUREMENT_ID',
      defaultValue: 'G-20JJK23SMW',
    ),
  });

  bool get isConfigured => [
    apiKey,
    appId,
    messagingSenderId,
    projectId,
    authDomain,
  ].every((value) => value.trim().isNotEmpty);

  FirebaseOptions? get options => isConfigured
      ? FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          authDomain: authDomain,
          storageBucket: storageBucket,
          measurementId: measurementId,
        )
      : null;
}
