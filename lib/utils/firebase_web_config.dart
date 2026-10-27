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
      defaultValue: 'AIzaSyAYTIAmif-ipHfGguuNCnENsixW3lVd6YE',
    ),
    this.appId = const String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: '1:177575580722:web:eeb34b5b74ed48f16cd82b',
    ),
    this.messagingSenderId = const String.fromEnvironment(
      'FIREBASE_WEB_MESSAGING_SENDER_ID',
      defaultValue: '177575580722',
    ),
    this.projectId = const String.fromEnvironment(
      'FIREBASE_WEB_PROJECT_ID',
      defaultValue: 'nalara-gia',
    ),
    this.authDomain = const String.fromEnvironment(
      'FIREBASE_WEB_AUTH_DOMAIN',
      defaultValue: 'nalara-gia.firebaseapp.com',
    ),
    this.storageBucket = const String.fromEnvironment(
      'FIREBASE_WEB_STORAGE_BUCKET',
      defaultValue: 'nalara-gia.firebasestorage.app',
    ),
    this.vapidKey = const String.fromEnvironment(
      'FIREBASE_WEB_VAPID_KEY',
      // Must be supplied from Firebase Console for project nalara-gia.
      defaultValue:
          'BEtOyaNcdsXKHFYKoy2BlV4wTQ0gmLUywrOYCKGUSGetXQ-exKcqRZ15lXBWwZqcDJ5IpCPcXLm0FxKEn_E7Db8',
    ),
    this.measurementId = const String.fromEnvironment(
      'FIREBASE_WEB_MEASUREMENT_ID',
      defaultValue: 'G-XXXXXXXXXX',
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
