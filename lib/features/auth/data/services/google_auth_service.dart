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
    var stage = 'initialize';
    try {
      User? firebaseUser;
      if (kIsWeb) {
        if (_firebaseAuth == null && Firebase.apps.isEmpty) {
          throw const AppFailure(
            'Login Google di web belum dikonfigurasi. Gunakan email atau nomor HP terlebih dahulu.',
            code: 'GOOGLE_WEB_NOT_CONFIGURED',
          );
        }
        stage = 'web-popup';
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

        stage = 'account-selection';
        final account = await googleSignIn.authenticate();
        final googleIdToken = account.authentication.idToken;
        if (googleIdToken == null || googleIdToken.isEmpty) {
          throw const AppFailure(
            'Token Google tidak tersedia. Coba pilih akun lagi.',
            code: 'GOOGLE_TOKEN_MISSING',
          );
        }

        stage = 'firebase-auth';
        await firebaseAuth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: googleIdToken),
        );
        firebaseUser = firebaseAuth.currentUser;
      }
      stage = 'firebase-token';
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
      // Keep release diagnostics useful without logging tokens or account data.
      debugPrint(
        'Google Sign-In gagal (tahap: $stage, kode: ${error.code.name}).',
      );
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const AppFailure(
          'Login Google belum tersedia pada versi aplikasi ini. '
          'Silakan masuk menggunakan email atau nomor HP.',
          code: 'GOOGLE_CONFIGURATION_ERROR',
        );
      }
      if (error.code == GoogleSignInExceptionCode.canceled) {
        // Android can also report configuration failures as canceled.
        throw const AppFailure(
          'Login Google belum selesai. Silakan coba lagi.',
          code: 'AUTH_CANCELLED',
        );
      }
      if (error.code == GoogleSignInExceptionCode.interrupted ||
          error.code == GoogleSignInExceptionCode.uiUnavailable) {
        throw const AppFailure(
          'Pilihan akun Google belum dapat dibuka. Silakan coba lagi.',
          code: 'GOOGLE_UI_UNAVAILABLE',
        );
      }
      throw const AppFailure(
        'Login Google gagal. Periksa konfigurasi Google Sign-In lalu coba lagi.',
        code: 'GOOGLE_SIGN_IN_FAILED',
      );
    } on FirebaseAuthException catch (error) {
      debugPrint('Firebase Auth gagal (tahap: $stage, kode: ${error.code}).');
      if (error.code == 'operation-not-allowed' ||
          error.code == 'app-not-authorized' ||
          error.code == 'invalid-api-key') {
        throw const AppFailure(
          'Login Google belum tersedia pada versi aplikasi ini. '
          'Silakan masuk menggunakan email atau nomor HP.',
          code: 'GOOGLE_CONFIGURATION_ERROR',
        );
      }
      if (error.code == 'network-request-failed') {
        throw const AppFailure(
          'Tidak dapat terhubung ke Google. Periksa koneksi lalu coba lagi.',
          code: 'GOOGLE_NETWORK_ERROR',
        );
      }
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
    } catch (error) {
      debugPrint(
        'Google Sign-In gagal (tahap: $stage, jenis: ${error.runtimeType}).',
      );
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
