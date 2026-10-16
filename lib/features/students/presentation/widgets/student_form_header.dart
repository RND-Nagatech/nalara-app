import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_page_header.dart';
import 'student_form_style.dart';

class StudentFormHeader extends StatelessWidget {
  final bool editing;
  final VoidCallback onBack;
  const StudentFormHeader({
    super.key,
    required this.editing,
    required this.onBack,
  });
  @override
  Widget build(BuildContext context) => NalaraPageHeader(
    title: editing ? 'Edit siswa' : 'Tambah siswa',
    backKey: const ValueKey('student-form-back'),
    onBack: onBack,
  );
}

class StudentFormIntro extends StatelessWidget {
  const StudentFormIntro({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(13) > 18;
      final artwork = Image.asset(
        StudentFormStyle.headerArtwork,
        key: const ValueKey('student-form-artwork'),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (!stacked)
            Positioned(
              right: -18,
              top: 32,
              width: math.min(210, constraints.maxWidth * .53),
              child: IgnorePointer(child: artwork),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data siswa',
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: StudentFormStyle.ink,
                  ),
                ),
                const SizedBox(height: 7),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: stacked ? double.infinity : 204,
                  ),
                  child: const Text(
                    'Isi data yang diperlukan untuk pembelajaran saja.',
                    style: TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 13,
                      height: 1.45,
                      color: StudentFormStyle.muted,
                    ),
                  ),
                ),
                if (stacked)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 180, child: artwork),
                  )
                else
                  const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      );
    },
  );
}
