import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'app dropdown UIs use the shared NalaraDropdown, not native menu widgets',
    () {
      final nativeDropdown = RegExp(
        r'\b(?:DropdownButton(?:FormField)?|DropdownMenu(?:Item|Entry)?)\s*(?:<|\()',
      );
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => nativeDropdown.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();
      expect(
        offenders,
        isEmpty,
        reason:
            'Gunakan shared/widgets/nalara_dropdown.dart untuk dropdown baru.',
      );
    },
  );
}
