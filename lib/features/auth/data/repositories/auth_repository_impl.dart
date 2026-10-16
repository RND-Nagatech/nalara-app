import '../../../../shared/errors/app_failure.dart';
import '../../../../shared/network/token_store.dart';
import '../datasources/remembered_login_local_source.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/phone_number.dart';
import '../datasources/auth_remote_source.dart';
import '../models/teacher_model.dart';
import '../services/google_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource remote;
  final TokenStore store;
  final GoogleAuthService? googleAuth;
  final RememberedLoginLocalSource? rememberedLogin;
  AuthRepositoryImpl(
    this.remote,
    this.store, {
    this.googleAuth,
    this.rememberedLogin,
  });
  Future<Teacher> _authenticate(
    Future<Map<String, dynamic>> Function() request, {
    bool rememberMe = true,
  }) async {
    final json = await request();
    final teacher = TeacherModel(
      Map<String, dynamic>.from(json['user']),
    ).toEntity();
    await store.save(
      json['accessToken'] as String,
      json['refreshToken'] as String,
      persist: rememberMe,
    );
    return teacher;
  }

  @override
  Future<Teacher> login(
    String identifier,
    String password, {
    bool rememberMe = true,
    LoginMethod method = LoginMethod.email,
  }) async {
    final value = identifier.trim();
    final phone = PhoneNumber.normalize(value) ?? value;
    final teacher = await _authenticate(
      () => remote.login({
        if (method == LoginMethod.email)
          'email': value.toLowerCase()
        else
          'phone': phone,
        'password': password,
      }),
      rememberMe: rememberMe,
    );
    await _updateRememberedLogin(
      rememberMe: rememberMe,
      method: method,
      identifier: value,
      password: password,
    );
    return teacher;
  }

  Future<void> _updateRememberedLogin({
    required bool rememberMe,
    required LoginMethod method,
    required String identifier,
    required String password,
  }) async {
    final source = rememberedLogin;
    if (source == null) return;
    try {
      if (rememberMe) {
        await source.save(
          method: method,
          identifier: identifier,
          password: password,
        );
      } else {
        await source.clear();
      }
    } catch (_) {
      // Secure-storage availability must not turn a successful login into an error.
    }
  }

  @override
  Future<Teacher> loginWithGoogle({bool rememberMe = true}) async {
    final auth = googleAuth;
    if (auth == null) {
      throw const AppFailure(
        'Login Google belum dikonfigurasi di aplikasi.',
        code: 'CONFIGURATION_ERROR',
      );
    }
    final idToken = await auth.signIn();
    try {
      return await _authenticate(
        () => remote.loginWithGoogle(idToken),
        rememberMe: rememberMe,
      );
    } catch (error) {
      try {
        await auth.signOut();
      } catch (_) {
        // The backend error is more useful to the user than a cleanup error.
      }
      rethrow;
    }
  }

  @override
  Future<Teacher> register(
    String name,
    String email,
    String password, {
    required String phone,
    required String passwordConfirmation,
  }) async {
    final json = await remote.register({
      'name': name.trim(),
      'email': email.trim(),
      'phone': PhoneNumber.normalize(phone) ?? phone.trim(),
      'password': password,
      'passwordConfirmation': passwordConfirmation,
    });
    // The register response may contain legacy session tokens, but they are
    // deliberately not saved. The user must explicitly sign in after the
    // success notice is shown.
    return TeacherModel(Map<String, dynamic>.from(json['user'])).toEntity();
  }

  @override
  Future<Teacher?> restore() async {
    await store.restore();
    if (store.refreshToken == null) return null;
    try {
      return TeacherModel(await remote.me()).toEntity();
    } on AppFailure catch (error) {
      if (error.code == 'UNAUTHENTICATED') return null;
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remote.logout();
    } on AppFailure catch (error) {
      if (error.code != 'UNAUTHENTICATED') rethrow;
    }
    await store.clear();
    if (googleAuth != null) {
      try {
        await googleAuth!.signOut();
      } catch (_) {
        // Local tokens are already cleared; social cleanup is best effort.
      }
    }
  }

  @override
  Future<int> requestPasswordReset(String email) async {
    final data = await remote.forgotPassword({'email': email.trim()});
    final expires = data['otpExpiresInSeconds'];
    if (expires is num && expires > 0) return expires.toInt();
    throw const AppFailure(
      'OTP reset belum dikonfigurasi dengan benar.',
      code: 'INVALID_RESPONSE',
    );
  }

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final data = await remote.verifyResetOtp({
      'email': email.trim(),
      'otp': otp.trim(),
    });
    final resetToken = data['resetToken'];
    if (resetToken is String && resetToken.isNotEmpty) return resetToken;
    throw const AppFailure(
      'Token reset tidak ditemukan pada respons server.',
      code: 'INVALID_RESPONSE',
    );
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await remote.resetPassword({
      'resetToken': resetToken.trim(),
      'newPassword': newPassword,
    });
  }

  @override
  Future<String?> forgot(String email) async {
    await requestPasswordReset(email);
    return null;
  }

  @override
  Future<void> reset(String token, String password) =>
      resetPassword(resetToken: token, newPassword: password);

  @override
  Future<bool> onboardingSeen() => store.onboardingSeen;
  @override
  Future<void> completeOnboarding() => store.completeOnboarding();
}
