import 'package:flutter/material.dart';
import 'student_form_style.dart';

class StudentFormField extends StatelessWidget {
  final String fieldId, label, hint;
  final TextEditingController controller;
  final int maxLength;
  final bool requiredField;
  final int minLines, maxLines;
  final String? Function(String?)? validator;
  const StudentFormField({
    super.key,
    required this.fieldId,
    required this.label,
    required this.hint,
    required this.controller,
    required this.maxLength,
    this.requiredField = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (requiredField)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                const TextSpan(
                  text: ' (opsional)',
                  style: TextStyle(color: StudentFormStyle.muted),
                ),
            ],
          ),
          style: StudentFormStyle.label,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: requiredField ? '$label, wajib diisi' : '$label, opsional',
          child: TextFormField(
            key: ValueKey('student-$fieldId'),
            controller: controller,
            style: StudentFormStyle.input,
            decoration: InputDecoration(hintText: hint),
            validator: validator,
            maxLength: maxLength,
            minLines: minLines,
            maxLines: maxLines,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: maxLines > 1
                ? TextInputType.multiline
                : TextInputType.text,
            textInputAction: maxLines > 1
                ? TextInputAction.newline
                : TextInputAction.next,
          ),
        ),
      ],
    ),
  );
}
