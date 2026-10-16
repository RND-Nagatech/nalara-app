import '../entities/teacher.dart';

enum LoginMethod { email, phone }

abstract class AuthRepository {
  Future<Teacher?> restore();
  Future<Teacher> login(
    String identifier,
    String password, {
    bool rememberMe = true,
    LoginMethod method = LoginMethod.email,
  });
  Future<Teacher> loginWithGoogle({bool rememberMe = true});
  Future<Teacher> register(
    String name,
    String email,
    String password, {
    required String phone,
    required String passwordConfirmation,
  });
  Future<void> logout();
  Future<int> requestPasswordReset(String email);
  Future<String> verifyResetOtp({required String email, required String otp});
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });
  @Deprecated('Gunakan requestPasswordReset')
  Future<String?> forgot(String email);
  @Deprecated('Gunakan resetPassword')
  Future<void> reset(String token, String password);
  Future<bool> onboardingSeen();
  Future<void> completeOnboarding();
}
