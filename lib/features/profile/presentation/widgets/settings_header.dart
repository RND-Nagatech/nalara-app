import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'more_style.dart';
import 'settings_style.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

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
            'Preferensi & keamanan',
            style: TextStyle(
              fontFamily: 'NalaraInter',
              color: SettingsStyle.ink,
              fontSize: 25,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Informasi aplikasi dan privasi belajar dalam satu tempat.',
            style: SettingsStyle.body,
          ),
        ],
      );
      final artwork = Image.asset(
        MoreStyle.headerArtwork,
        key: const ValueKey('settings-artwork'),
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
