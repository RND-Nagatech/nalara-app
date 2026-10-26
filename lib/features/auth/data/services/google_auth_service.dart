import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../shared/errors/app_failure.dart';

class GoogleAuthService {
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  FirebaseAuth get firebaseAuth => _firebaseAuth ?? FirebaseAuth.instance;
  GoogleSignIn get googleSignIn => _googleSignIn ?? GoogleSignIn.instance;
  bool _initialized = false;

  factory GoogleAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) => GoogleAuthService._(firebaseAuth, googleSignIn);
  GoogleAuthService._(this._firebaseAuth, this._googleSignIn);

  Future<String> signIn() async {
    try {
      User? firebaseUser;
      if (kIsWeb) {
        if (_firebaseAuth == null && Firebase.apps.isEmpty) {
          throw const AppFailure(
            'Login Google di web belum dikonfigurasi. Gunakan email atau nomor HP terlebih dahulu.',
            code: 'GOOGLE_WEB_NOT_CONFIGURED',
          );
        }
        final result = await firebaseAuth.signInWithPopup(
          GoogleAuthProvider()
            ..setCustomParameters({'prompt': 'select_account'}),
        );
        firebaseUser = result.user;
      } else {
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
        firebaseUser = firebaseAuth.currentUser;
      }
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
    } on FirebaseAuthException catch (error) {
      if ([
        'popup-closed-by-user',
        'cancelled-popup-request',
      ].contains(error.code)) {
        throw const AppFailure(
          'Login Google dibatalkan.',
          code: 'AUTH_CANCELLED',
        );
      }
      if (error.code == 'popup-blocked') {
        throw const AppFailure(
          'Izinkan pop-up di browser untuk melanjutkan login Google.',
          code: 'GOOGLE_POPUP_BLOCKED',
        );
      }
      if (error.code == 'unauthorized-domain') {
        throw const AppFailure(
          'Domain web ini belum diizinkan untuk login Google. Gunakan email atau nomor HP.',
          code: 'GOOGLE_WEB_DOMAIN_NOT_ALLOWED',
        );
      }
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
    if (_firebaseAuth == null && Firebase.apps.isEmpty) return;
    await Future.wait([
      firebaseAuth.signOut(),
      if (!kIsWeb) googleSignIn.signOut(),
    ]);
  }
}
