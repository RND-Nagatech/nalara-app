import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_page_header.dart';
import 'subject_form_style.dart';

class SubjectFormHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final bool editing;
  const SubjectFormHeader({
    super.key,
    required this.onBack,
    this.editing = false,
  });
  @override
  Widget build(BuildContext context) => NalaraPageHeader(
    title: editing ? 'Edit bidang belajar' : 'Tambah bidang belajar',
    backKey: const ValueKey('subject-form-back'),
    onBack: onBack,
    backEnabled: onBack != null,
  );
}

class SubjectFormHero extends StatelessWidget {
  final bool editing;
  const SubjectFormHero({super.key, this.editing = false});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      final artwork = Image.asset(
        SubjectFormStyle.artwork,
        key: const ValueKey('subject-form-artwork'),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (!stacked)
            Positioned(
              right: -30,
              top: 18,
              width: math.min(270, constraints.maxWidth * .66),
              child: IgnorePointer(child: artwork),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: stacked
                        ? double.infinity
                        : math.min(290, constraints.maxWidth * .52),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing
                            ? 'Edit\nbidang belajar'
                            : 'Tambah\nbidang belajar',
                        style: const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: SubjectFormStyle.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        editing
                            ? 'Perubahan nama diterapkan ke seluruh data yang terhubung.'
                            : 'Tambahkan bidang atau keterampilan yang Anda ajarkan.',
                        style: const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 13.5,
                          height: 1.45,
                          color: SubjectFormStyle.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (stacked) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 240, child: artwork),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}
