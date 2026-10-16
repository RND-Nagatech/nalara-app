import 'package:flutter/services.dart';

class RupiahInputFormatter extends TextInputFormatter {
  static int parse(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  static String format(int value) {
    final digits = value.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > 15) return oldValue;
    final caret = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final beforeCount = newValue.text
        .substring(0, caret)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    final normalized = int.parse(digits).toString();
    final output = format(int.parse(digits));
    final count = (beforeCount - (digits.length - normalized.length)).clamp(
      0,
      normalized.length,
    );
    var position = 0, seen = 0;
    while (position < output.length && seen < count) {
      if (output[position] != '.') seen++;
      position++;
    }
    return TextEditingValue(
      text: output,
      selection: TextSelection.collapsed(offset: position),
    );
  }
}
