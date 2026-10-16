class PhoneNumber {
  /// Canonical Indonesian mobile key shared by registration and phone login.
  static String? normalize(String? value) {
    if (value == null ||
        value.length > 32 ||
        !RegExp(r'^[+\d\s()-]+$').hasMatch(value)) {
      return null;
    }
    var phone = value.replaceAll(RegExp(r'[\s()-]'), '');
    if (phone.startsWith('0')) {
      phone = '+62${phone.substring(1)}';
    } else if (phone.startsWith('62')) {
      phone = '+$phone';
    }
    return RegExp(r'^\+628[1-9]\d{7,10}$').hasMatch(phone) ? phone : null;
  }
}
