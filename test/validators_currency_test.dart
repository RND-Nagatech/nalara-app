import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/utils/currency_input.dart';
import 'package:nalara/utils/validators.dart';

void main() {
  test('email and required names', () {
    expect(Validators.email('bad'), isNotNull);
    expect(Validators.email('guru@example.com'), isNull);
    expect(Validators.name(' '), isNotNull);
  });
  test('password length and integer progress boundaries', () {
    expect(Validators.password('short'), isNotNull);
    expect(Validators.progress('20.5'), isNotNull);
    expect(Validators.progress('-1'), isNotNull);
    expect(Validators.progress('101'), isNotNull);
    expect(Validators.progress('0'), isNull);
    expect(Validators.progress('100'), isNull);
  });
  test('Rupiah format and parsing', () {
    expect(RupiahInputFormatter.format(1250000), '1.250.000');
    expect(RupiahInputFormatter.parse('Rp 1.250.000'), 1250000);
    expect(RupiahInputFormatter.parse(''), 0);
  });
  test('Rupiah formatter preserves caret when editing in the middle', () {
    final formatter = RupiahInputFormatter();
    final value = formatter.formatEditUpdate(
      const TextEditingValue(text: '1.000'),
      const TextEditingValue(
        text: '12000',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(value.text, '12.000');
    expect(value.selection.extentOffset, 2);
    expect(
      formatter.formatEditUpdate(value, const TextEditingValue()).text,
      '',
    );
  });
  test('leading zero and large values', () {
    final value = RupiahInputFormatter().formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '000123',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(value.text, '123');
    expect(value.selection.extentOffset, 3);
  });
}
