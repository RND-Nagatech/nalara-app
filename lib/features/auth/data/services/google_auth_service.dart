import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../shared/errors/app_failure.dart';

class GoogleAuthService {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  bool _initialized = false;

  GoogleAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<String> signIn() async {
    try {
      if (!_initialized) {
        await googleSignIn.initialize();
        _initialized = true;
      }

      final account = await googleSignIn.authenticate();
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) {
        throw const AppFailure(
          'Token Google tidak tersedia. Coba pilih akun lagi.',
          code: 'GOOGLE_TOKEN_MISSING',
        );
      }

      await firebaseAuth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: googleIdToken),
      );
      final firebaseUser = firebaseAuth.currentUser;
      final firebaseIdToken = await firebaseUser?.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const AppFailure(
          'Token Firebase tidak tersedia. Coba lagi.',
          code: 'FIREBASE_TOKEN_MISSING',
        );
      }
      return firebaseIdToken;
    } on AppFailure {
      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AppFailure(
          'Login Google dibatalkan.',
          code: 'AUTH_CANCELLED',
        );
      }
      throw const AppFailure(
        'Login Google gagal. Periksa konfigurasi Google Sign-In lalu coba lagi.',
        code: 'GOOGLE_SIGN_IN_FAILED',
      );
    } on FirebaseAuthException {
      throw const AppFailure(
        'Login Firebase gagal. Coba lagi.',
        code: 'FIREBASE_AUTH_FAILED',
      );
    } catch (_) {
      throw const AppFailure(
        'Login Google gagal. Coba lagi.',
        code: 'GOOGLE_SIGN_IN_FAILED',
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait([firebaseAuth.signOut(), googleSignIn.signOut()]);
  }
}
