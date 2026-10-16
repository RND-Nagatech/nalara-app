import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'subject_form_style.dart';

class SubjectsHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onRefresh;

  const SubjectsHeader({
    super.key,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _action(
              key: const ValueKey('subjects-back'),
              tooltip: 'Kembali',
              onPressed: onBack,
              icon: Icons.arrow_back_rounded,
            ),
            _action(
              key: const ValueKey('subjects-refresh'),
              tooltip: 'Muat ulang bidang belajar',
              onPressed: onRefresh,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 18;
            const text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bidang belajar',
                  style: TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: SubjectFormStyle.ink,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Kelola bidang dan keterampilan yang Anda ajarkan.',
                  style: TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 13,
                    height: 1.5,
                    color: SubjectFormStyle.muted,
                  ),
                ),
              ],
            );
            final artwork = Image.asset(
              SubjectFormStyle.artwork,
              key: const ValueKey('subjects-header-artwork'),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  text,
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 200, child: artwork),
                  ),
                ],
              );
            }
            return Row(
              children: [
                const Expanded(child: text),
                const SizedBox(width: 4),
                SizedBox(
                  width: math.min(210, constraints.maxWidth * .46),
                  child: artwork,
                ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _action({
    required Key key,
    required String tooltip,
    required VoidCallback? onPressed,
    required IconData icon,
  }) => IconButton(
    key: key,
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: SubjectFormStyle.green,
      minimumSize: const Size(44, 44),
      shape: const CircleBorder(),
    ),
    icon: Icon(icon, size: 25),
  );
}
