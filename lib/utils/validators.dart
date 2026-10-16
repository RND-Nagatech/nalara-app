import '../features/auth/domain/value_objects/phone_number.dart';

class Validators {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;
  static String? name(String? value) =>
      value == null || value.trim().length < 2 ? 'Minimal 2 karakter' : null;
  static String? email(String? value) =>
      value == null ||
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? 'Email tidak valid'
      : null;
  static String? password(String? value) => value == null || value.length < 8
      ? 'Minimal 8 karakter'
      : value.length > 128
      ? 'Maksimal 128 karakter'
      : null;
  static String? phone(String? value) => PhoneNumber.normalize(value) == null
      ? 'Masukkan nomor HP Indonesia yang valid (08… atau +628…)'
      : null;
  static String? progress(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number < 0 || number > 100
        ? 'Masukkan bilangan bulat 0–100'
        : null;
  }
}
