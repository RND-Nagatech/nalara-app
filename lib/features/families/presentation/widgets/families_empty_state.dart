import 'package:flutter/material.dart';
import 'families_style.dart';

class FamiliesEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const FamiliesEmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 28, 22, 38),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Image.asset(
            FamiliesStyle.emptyArtwork,
            key: const ValueKey('families-empty-artwork'),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'Belum ada keluarga',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: FamiliesStyle.ink,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Kelompokkan anak berdasarkan Orang Tua\nuntuk membuat satu kode keluarga.',
          textAlign: TextAlign.center,
          style: FamiliesStyle.body,
        ),
        const SizedBox(height: 19),
        FilledButton(
          key: const ValueKey('families-add-empty'),
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            backgroundColor: FamiliesStyle.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(198, 54),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Tambah sekarang',
            style: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
