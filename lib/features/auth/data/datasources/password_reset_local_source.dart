import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PasswordResetDraft {
  final String step;
  final String email;
  final int otpExpiresAt;
  final String? resetToken;

  const PasswordResetDraft({
    required this.step,
    required this.email,
    required this.otpExpiresAt,
    this.resetToken,
  });
}

class PasswordResetLocalSource {
  static const _stepKey = 'nalara-password-reset-step';
  static const _emailKey = 'nalara-password-reset-email';
  static const _otpExpiresAtKey = 'nalara-password-reset-otp-expires-at';
  static const _resetTokenKey = 'nalara-password-reset-token';

  final FlutterSecureStorage storage;

  const PasswordResetLocalSource(this.storage);

  Future<PasswordResetDraft?> read() async {
    final step = await storage.read(key: _stepKey);
    final email = await storage.read(key: _emailKey);

    if (email == null || email.isEmpty) return null;
    if (step != 'otp' && step != 'new-password') return null;

    return PasswordResetDraft(
      step: step!,
      email: email,
      otpExpiresAt:
          int.tryParse(await storage.read(key: _otpExpiresAtKey) ?? '') ?? 0,
      resetToken: await storage.read(key: _resetTokenKey),
    );
  }

  Future<void> saveOtp({
    required String email,
    required DateTime expiresAt,
  }) async {
    await Future.wait([
      storage.write(key: _stepKey, value: 'otp'),
      storage.write(key: _emailKey, value: email),
      storage.write(
        key: _otpExpiresAtKey,
        value: expiresAt.millisecondsSinceEpoch.toString(),
      ),
      storage.delete(key: _resetTokenKey),
    ]);
  }

  Future<void> saveNewPassword({
    required String email,
    required String resetToken,
  }) async {
    await Future.wait([
      storage.write(key: _stepKey, value: 'new-password'),
      storage.write(key: _emailKey, value: email),
      storage.write(key: _resetTokenKey, value: resetToken),
      storage.delete(key: _otpExpiresAtKey),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      storage.delete(key: _stepKey),
      storage.delete(key: _emailKey),
      storage.delete(key: _otpExpiresAtKey),
      storage.delete(key: _resetTokenKey),
    ]);
  }
}
