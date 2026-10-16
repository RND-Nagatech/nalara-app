import 'package:flutter/material.dart';
import 'family_form_style.dart';

class FamilyFormHeader extends StatelessWidget {
  final bool editing;
  final VoidCallback? onBack;

  const FamilyFormHeader({
    super.key,
    required this.editing,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('family-form-back'),
          tooltip: 'Kembali',
          onPressed: onBack,
          style: IconButton.styleFrom(
            foregroundColor: FamilyFormStyle.green,
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 27),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            editing ? 'Edit Orang Tua' : 'Tambah Orang Tua',
            style: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: FamilyFormStyle.ink,
            ),
          ),
        ),
      ],
    ),
  );
}
