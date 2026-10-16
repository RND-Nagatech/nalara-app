import 'package:flutter/material.dart';
import 'students_style.dart';

class StudentsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final bool showAction;
  const StudentsEmptyState({
    super.key,
    required this.onAdd,
    this.showAction = true,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 30, 22, 38),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Image.asset(
            StudentsStyle.emptyArtwork,
            key: const ValueKey('students-empty-artwork'),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'Belum ada siswa yang sesuai pencarian.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: StudentsStyle.ink,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          showAction
              ? 'Mulai tambahkan siswa untuk mengelola jadwal, materi, dan perkembangan mereka.'
              : 'Data anak yang terhubung ke keluarga Anda akan muncul di sini.',
          textAlign: TextAlign.center,
          style: StudentsStyle.body,
        ),
        if (showAction) ...[
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('students-add-empty'),
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: StudentsStyle.green,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(0, 46),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle, size: 23),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Tambah sekarang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
