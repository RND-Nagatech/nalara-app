import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'help_center_style.dart';
import 'more_style.dart';

class HelpCenterHeader extends StatelessWidget {
  const HelpCenterHeader({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 330 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      const intro = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ada yang bisa dibantu?',
            style: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 26,
              height: 1.22,
              fontWeight: FontWeight.w700,
              color: HelpCenterStyle.ink,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Temukan panduan untuk aktivitas belajar Anda di NALARA.',
            style: HelpCenterStyle.body,
          ),
        ],
      );
      final artwork = Image.asset(
        MoreStyle.headerArtwork,
        key: const ValueKey('help-artwork'),
        width: stacked ? 170 : math.min(180, constraints.maxWidth * .43),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 26),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  intro,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: artwork),
                ],
              )
            : Row(
                children: [
                  const Expanded(child: intro),
                  const SizedBox(width: 12),
                  artwork,
                ],
              ),
      );
    },
  );
}
