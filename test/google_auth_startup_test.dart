import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/auth/data/services/google_auth_service.dart';
import 'package:nalara/utils/firebase_web_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Google service construction and sign-out do not require a default Firebase app',
    () async {
      expect(Firebase.apps, isEmpty);
      final service = GoogleAuthService();
      await expectLater(service.signOut(), completes);
      expect(Firebase.apps, isEmpty);
    },
  );

  test(
    'absent or partial Web settings do not pretend Firebase is configured',
    () {
      const empty = FirebaseWebConfig(
        apiKey: '',
        appId: '',
        messagingSenderId: '',
        projectId: '',
        authDomain: '',
      );
      const partial = FirebaseWebConfig(
        apiKey: 'public-key',
        appId: '',
        messagingSenderId: '',
        projectId: 'test-project',
        authDomain: '',
      );
      expect(empty.isConfigured, isFalse);
      expect(empty.options, isNull);
      expect(partial.options, isNull);
    },
  );

  test(
    'complete public Web settings map to the supplied Firebase Web app only',
    () {
      const config = FirebaseWebConfig(
        apiKey: 'public-key',
        appId: '1:123:web:test-app',
        messagingSenderId: '123',
        projectId: 'test-project',
        authDomain: 'test-project.firebaseapp.com',
      );
      final options = config.options!;
      expect(options.apiKey, 'public-key');
      expect(options.appId, '1:123:web:test-app');
      expect(options.projectId, 'test-project');
      expect(options.authDomain, 'test-project.firebaseapp.com');
    },
  );
}
