import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'schedule_form_style.dart';

class ScheduleFormHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showIntro;

  const ScheduleFormHeader({
    super.key,
    required this.onBack,
    this.showIntro = false,
  });

  @override
  Widget build(BuildContext context) => showIntro
      ? _intro(context)
      : Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Row(
            children: [
              _back(),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Tambah jadwal',
                  style: TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 21,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: ScheduleFormStyle.ink,
                  ),
                ),
              ),
            ],
          ),
        );

  Widget _back() => IconButton(
    key: const ValueKey('schedule-form-back'),
    tooltip: 'Kembali ke jadwal',
    onPressed: onBack,
    style: IconButton.styleFrom(
      foregroundColor: ScheduleFormStyle.green,
      minimumSize: const Size(44, 44),
      shape: const CircleBorder(),
    ),
    icon: const Icon(Icons.arrow_back_rounded, size: 25),
  );

  Widget _intro(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      final artwork = Image.asset(
        ScheduleFormStyle.artwork,
        key: const ValueKey('schedule-form-artwork'),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (!stacked)
            Positioned(
              right: -20,
              top: 20,
              width: math.min(270, constraints.maxWidth * .58),
              child: IgnorePointer(child: artwork),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: stacked
                        ? double.infinity
                        : math.min(330, constraints.maxWidth * .58),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atur jadwal les',
                        style: TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: ScheduleFormStyle.ink,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Atur jadwal les untuk siswa dengan bidang belajar yang dipilih.',
                        style: TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 13.5,
                          height: 1.5,
                          color: ScheduleFormStyle.muted,
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
